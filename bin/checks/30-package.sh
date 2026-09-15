#!/usr/bin/env bash
#
# 30-package.sh — everything that is only true of the ZIP.
#
# This check reads the zip and not the working copy on purpose. Both times a
# static check failed on a real upload the working copy looked clean and the zip
# did not, and the same asymmetry produces the other packaging defects: `zip -rD`
# drops the empty .git/refs/ entries, a GUI compress tool flattens symlinks into
# regular files, and a 0644 verifier entrypoint fails at run time rather than at
# build time so nothing local notices.
#
# usage: 30-package.sh <task-dir|zip>
# exit:  0 clean, 1 a real defect, 2 could not run

# shellcheck source=_common.inc
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.inc"

if parse_mode "${1-}"; then shift; fi
ARG="${1-}"
[ -n "$ARG" ] || usage_die "pkg.args" "no task directory or zip given"

need unzip || { skip "pkg.tool" "unzip is not available"; summary || true; exit 2; }

# Resolve without extracting: we want the archive listing, not its contents.
if [ -f "$ARG" ] && case "$ARG" in *.zip) true ;; *) false ;; esac; then
  ZIP_PATH="$ARG"
  TASK_DIR="$(cd "$(dirname "$ARG")/.." 2>/dev/null && pwd || true)"
elif [ -d "$ARG" ]; then
  if [ -f "$ARG/task.toml" ]; then
    TASK_DIR="$(cd "$ARG/.." && pwd)"
  else
    TASK_DIR="$(cd "$ARG" && pwd)"
  fi
  ZIP_PATH=""
  for f in "$TASK_DIR"/upload/*.zip; do
    [ -f "$f" ] || continue
    if [ -z "$ZIP_PATH" ] || [ "$f" -nt "$ZIP_PATH" ]; then ZIP_PATH="$f"; fi
  done
else
  usage_die "pkg.args" "$ARG is neither a directory nor a zip"
fi

SRC_TREE=""
for cand in "$TASK_DIR/work" "$TASK_DIR"; do
  if [ -f "$cand/task.toml" ]; then SRC_TREE="$cand"; break; fi
done

# ------------------------------------------- build caches in the source tree --
# These paths are gitignored, so `git status` stays clean and nothing warns you.
# Running gradle, maven, npm or cargo inside work/ or download/original/ is what
# puts them there, and the next zip ships them. A timed reviewer check inspects
# only the submitted archive, so it never reads sibling work or pristine trees.

if [ "${PREFLIGHT_REVIEW_FAST:-0}" = "1" ]; then
  SRC_TREE=""
  pass "pkg.build-cache" "review-fast inspects the submitted zip only"
else
  CACHE_PATHS=".gradle target node_modules .pnpm-store .venv __pycache__ .pytest_cache .mypy_cache .ruff_cache build/tmp"
  if [ -n "$TASK_DIR" ] && [ -d "$TASK_DIR" ]; then
    found_cache=""
    for sub in work download/original; do
      [ -d "$TASK_DIR/$sub" ] || continue
      for c in $CACHE_PATHS; do
        while IFS= read -r hit; do
          [ -n "$hit" ] || continue
          found_cache="$found_cache ${hit#"$TASK_DIR/"}"
        done < <(find "$TASK_DIR/$sub" -maxdepth 6 -name "$(basename "$c")" 2>/dev/null || true)
      done
    done
    if [ -n "$found_cache" ]; then
      fail "pkg.build-cache" "build-tool cache under the task tree:$found_cache"
      note "delete it, then re-run the stray sweep. Builds belong in a disposable scratchpad copy, never in work/ or download/original/"
    else
      pass "pkg.build-cache" "no build-tool cache under work/ or download/original/"
    fi
  fi
fi

if [ -z "$ZIP_PATH" ] || [ ! -f "$ZIP_PATH" ]; then
  skip "pkg.zip" "no zip found under $TASK_DIR/upload — build it before this check means anything"
  summary || true
  exit 2
fi
note "zip: $ZIP_PATH"

LIST="$(mktempdir)/list"
unzip -Z "$ZIP_PATH" > "$LIST" 2>/dev/null || { skip "pkg.zip" "cannot read $ZIP_PATH"; summary || true; exit 2; }
# strip the two zipinfo header lines and the trailing total line
NAMES="$(mktempdir)/names"
# zipinfo long format: perms  ver  os  size  text/bin  method  date  time  name
# The name is everything after the 8th field. Skipping the fields by hand keeps
# this working on mawk, which does not do {n} interval expressions.
awk 'NF>=9 && $1 ~ /^[-dl]/ {
       p = 1
       for (k = 1; k <= 8; k++) {
         while (substr($0, p, 1) == " ") p++
         while (p <= length($0) && substr($0, p, 1) != " ") p++
       }
       while (substr($0, p, 1) == " ") p++
       print substr($1, 1, 1) "\t" substr($1, 2, 9) "\t" substr($0, p)
     }' "$LIST" > "$NAMES"

# Names go to their own file rather than through `cut | grep -q`. Under
# `set -o pipefail` a `grep -q` that matches early kills the left-hand side with
# SIGPIPE, the pipeline reports 141, and the check reads as a miss roughly at
# random. That produced two different verdicts on the same zip.
ONLY="$(mktempdir)/only"
cut -f3 "$NAMES" > "$ONLY"
zname() { cat "$ONLY"; }

# ------------------------------------------------------------ zip layout -----

if grep -q '^task/' "$ONLY"; then
  fail "pkg.layout.wrapper" "the zip has a task/ wrapper directory — zip from INSIDE the working copy"
else
  pass "pkg.layout.wrapper" "no task/ wrapper"
fi

if grep -q '^runs/' "$ONLY"; then
  fail "pkg.layout.runs" "runs/ is inside the zip — agent trial logs are never re-uploaded"
else
  pass "pkg.layout.runs" "no runs/"
fi

missing_top=""
for t in task.toml instruction.md environment/ solution/ tests/; do
  grep -q "^$t" "$ONLY" || missing_top="$missing_top $t"
done
if [ -n "$missing_top" ]; then
  fail "pkg.layout.toplevel" "the zip does not unpack directly to:$missing_top"
else
  pass "pkg.layout.toplevel" "files sit at the top level"
fi

# ------------------------------------------------------------ .git survival --

if grep -q '^environment/repo/\.git/' "$ONLY"; then
  pass "pkg.git.present" "environment/repo/.git/ is inside the zip"
else
  fail "pkg.git.present" "environment/repo/.git/ is NOT in the zip — the zip dropped dotfiles"
fi

# git gc packs the refs, which leaves .git/refs/ and .git/refs/heads/ empty.
# `zip -rD` and GUI compress tools skip directory entries, so those two vanish
# and the repo unpacks broken on the platform while the local copy still works.
if grep -q '^environment/repo/\.git/refs/$' "$ONLY"; then
  pass "pkg.git.refs-dir" ".git/refs/ directory entry survived"
else
  fail "pkg.git.refs-dir" ".git/refs/ directory entry is missing — re-zip with zip -rXy, never -rD and never a GUI tool"
fi
if grep -q '^environment/repo/\.git/refs/heads/$' "$ONLY"; then
  pass "pkg.git.refs-heads-dir" ".git/refs/heads/ directory entry survived"
else
  warn "pkg.git.refs-heads-dir" ".git/refs/heads/ directory entry is missing"
fi

# ---------------------------------------------------------------- modes ------

check_mode() {
  local path="$1" want="$2" line perms
  line="$(awk -F'\t' -v p="$path" '$3==p {print $2; exit}' "$NAMES")"
  if [ -z "$line" ]; then
    fail "pkg.mode.$path" "not present in the zip"
    return
  fi
  perms="$line"
  case "$perms" in
    "$want") pass "pkg.mode.$path" "$perms" ;;
    *)
      case "$perms" in
        *x*) warn "pkg.mode.$path" "$perms, expected $want (executable but not exactly 0755)" ;;
        *)   fail "pkg.mode.$path" "$perms — a non-executable entrypoint fails at run time, not at build time. chmod 0755 and re-zip" ;;
      esac
      ;;
  esac
}
check_mode "tests/test.sh"     "rwxr-xr-x"
check_mode "solution/solve.sh" "rwxr-xr-x"

# --------------------------------------------------------------- symlinks ----

ZIP_LINKS="$(awk -F'\t' '$1=="l"' "$NAMES" | wc -l | tr -d ' ')"
if [ -n "$SRC_TREE" ] && [ -d "$SRC_TREE" ]; then
  SRC_LINKS="$(find "$SRC_TREE" -type l 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$ZIP_LINKS" -eq "$SRC_LINKS" ]; then
    pass "pkg.symlinks" "$ZIP_LINKS symlink(s) in the zip, $SRC_LINKS in $SRC_TREE"
  else
    fail "pkg.symlinks" "$SRC_LINKS symlink(s) in $SRC_TREE but $ZIP_LINKS stored as links in the zip — re-zip with zip -rXy"
    find "$SRC_TREE" -type l 2>/dev/null | while read -r l; do note "${l#"$SRC_TREE/"} -> $(readlink "$l")"; done | head -5 || true
  fi
else
  if [ "$ZIP_LINKS" -gt 0 ]; then
    pass "pkg.symlinks" "$ZIP_LINKS symlink(s) stored as links (no source tree to compare against)"
  else
    warn "pkg.symlinks" "no source tree to compare against and no symlinks in the zip, cannot tell flattening from a tree that has none"
  fi
fi

# ---------------------------------------------------------- stray artifacts --

# Intentional dotfiles are fine. So is an artifact the upstream repo genuinely
# tracks: some projects commit a directory called target/ or a .vscode/ folder,
# and flagging those means asking for a tracked source file to be deleted.
tracked_upstream() {
  local path="$1" rel
  [ -n "$SRC_TREE" ] || return 1
  case "$path" in environment/repo/*) rel="${path#environment/repo/}" ;; *) return 1 ;; esac
  need git || return 1
  [ -d "$SRC_TREE/environment/repo/.git" ] || return 1
  git --no-optional-locks -C "$SRC_TREE/environment/repo" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1
}

STRAY_DIRS="__pycache__ .venv venv .pytest_cache .mypy_cache .ruff_cache .idea .vscode node_modules .pnpm-store .gradle"
STRAY_GLOBS='\.pyc$|\.DS_Store$|\.orig$|\.bak$|\.swp$|\.swo$|~$'

strays=""
while IFS= read -r n; do
  [ -n "$n" ] || continue
  hit=""
  for d in $STRAY_DIRS; do
    case "/$n" in */"$d"/*|*/"$d") hit="$d"; break ;; esac
  done
  if [ -z "$hit" ] && printf '%s' "$n" | grep -Eq "$STRAY_GLOBS"; then hit="pattern"; fi
  [ -n "$hit" ] || continue
  tracked_upstream "$n" && continue
  strays="$strays $n"
done < "$ONLY"

if [ -n "$strays" ]; then
  n=0
  fail "pkg.stray" "dev artifacts inside the zip — one of these hard-caps the packaging axis at 1"
  for s in $strays; do
    n=$((n + 1)); [ "$n" -le 8 ] && note "$s"
  done
  [ "$n" -gt 8 ] && note "... and $((n - 8)) more"
else
  pass "pkg.stray" "no stray dev artifacts"
fi

# ------------------------------------------------- solution readable by agent --
# The agent gets environment/repo and the instruction. Nothing that answers the
# task may be reachable from either.

leaks=""
for f in golden.patch init_state.patch solution.patch solve.sh tests.patch config.json; do
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    leaks="$leaks $n"
  done < <(grep "^environment/repo/.*/$f\$" "$ONLY" || true)
  grep -q "^environment/repo/$f\$" "$ONLY" && leaks="$leaks environment/repo/$f"
done
if [ -n "$leaks" ]; then
  fail "pkg.leak.repo" "solution or verifier material sits inside the agent's checkout:$leaks"
else
  pass "pkg.leak.repo" "no solution or verifier file inside environment/repo"
fi

D="$(mktempdir)"
if unzip -qq -o -j "$ZIP_PATH" instruction.md -d "$D" 2>/dev/null && [ -f "$D/instruction.md" ]; then
  hits=""
  grep -qiE 'golden\.patch|tests\.patch|fail_to_pass|solve\.sh|/tests/config\.json' "$D/instruction.md" && hits="$hits verifier-internals"
  grep -qE 'github\.com/[^ )]+/(pull|commit)/' "$D/instruction.md" && hits="$hits source-pr-url"
  if [ -n "$hits" ]; then
    fail "pkg.leak.instruction" "instruction.md names:$hits"
    grep -niE 'golden\.patch|tests\.patch|fail_to_pass|solve\.sh|github\.com/[^ )]+/(pull|commit)/' "$D/instruction.md" | while read -r l; do note "$l"; done | head -4 || true
  else
    pass "pkg.leak.instruction" "instruction.md names no verifier internals and no source PR"
  fi
else
  skip "pkg.leak.instruction" "instruction.md not readable from the zip"
fi

summary
