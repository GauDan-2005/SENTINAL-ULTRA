#!/usr/bin/env bash
#
# 20-git.sh — git hygiene on environment/repo, including the two things no other
# check in this workspace catches.
#
#   `git fsck --unreachable` — a repo with no reflog, no stray refs and a clean
#   tree can still hold dangling blobs of the golden file and of the patched test
#   file, readable with `git cat-file -p`. .git is an agent path, so that is a
#   live solution leak. learning/unreachable-git-blobs.md.
#
#   `.git/refs/remotes/origin/HEAD` — `git remote` prints nothing, for-each-ref
#   does not list it, and the platform's no-remote check passes. Only fsck and a
#   directory listing find it.
#
# Read-only with respect to the bundle: GIT_OPTIONAL_LOCKS=0 keeps `git status`
# from rewriting the index stat cache, and nothing else here writes.
#
# usage: 20-git.sh [--work|--zip] <task-dir|bundle-dir|zip>
# exit:  0 clean, 1 a real defect, 2 could not run

# shellcheck source=_common.inc
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.inc"

if parse_mode "${1-}"; then shift; fi
ARG="${1-}"
[ -n "$ARG" ] || usage_die "git.args" "no task directory given"

need git || { skip "git.tool" "git is not available"; summary || true; exit 2; }

resolve_input "$PREFER" "$ARG" || usage_die "git.args" "cannot resolve a bundle from $ARG"
B="$BUNDLE_DIR"
report_source
REPO="$B/environment/repo"
GITDIR="$REPO/.git"

if [ ! -d "$GITDIR" ]; then
  fail "git.present" "environment/repo/.git is missing"
  summary || true
  exit 1
fi

export GIT_OPTIONAL_LOCKS=0
G=(git --no-optional-locks -C "$REPO")

GIT_MAX_MB="$(fact git_max_mb 100)"

# --------------------------------------------------------------- unreachable --

FSCK_OUT="$("${G[@]}" fsck --unreachable --no-progress 2>/dev/null || true)"
if [ -n "$FSCK_OUT" ]; then
  N="$(printf '%s\n' "$FSCK_OUT" | grep -c .)"
  fail "git.fsck-unreachable" "$N unreachable object(s) survive in .git — re-run reflog expire + gc --prune=now until this is silent"
  printf '%s\n' "$FSCK_OUT" | sed -n '1,5p' | while read -r _u kind sha _rest; do
    [ -n "${sha:-}" ] || continue
    line="$("${G[@]}" cat-file -p "$sha" 2>/dev/null | sed -n '1s/\(.\{0,100\}\).*/\1/p' || true)"
    note "$kind $sha  ${line:-<binary or empty>}"
  done
  note "read these with: git -C $REPO cat-file -p <sha>"
else
  pass "git.fsck-unreachable" "fsck reports no unreachable objects"
fi

# ------------------------------------------------------------ refs/remotes --

if [ -e "$GITDIR/refs/remotes" ]; then
  fail "git.refs-remotes" ".git/refs/remotes exists — rm -rf .git/refs/remotes"
  find "$GITDIR/refs/remotes" -type f 2>/dev/null | sed -n '1,5p' | while read -r f; do
    note "${f#"$GITDIR/"} -> $(head -c 80 "$f" 2>/dev/null | tr -d '\n')"
  done
else
  pass "git.refs-remotes" "no .git/refs/remotes"
fi

if [ -n "$("${G[@]}" remote 2>/dev/null)" ]; then
  fail "git.remote" "a remote is configured: $("${G[@]}" remote | tr '\n' ' ')"
else
  pass "git.remote" "no remote configured"
fi

# ------------------------------------------------- .git entry whitelist ------
# learning/static-checks.md: .git should contain exactly these nine entries.

ALLOWED_GIT_ENTRIES="config description HEAD hooks index info objects packed-refs refs"
extra=""
while IFS= read -r e; do
  [ -n "$e" ] || continue
  case " $ALLOWED_GIT_ENTRIES " in
    *" $e "*) ;;
    *) extra="$extra $e" ;;
  esac
done < <(ls -A "$GITDIR" 2>/dev/null)
if [ -n "$extra" ]; then
  fail "git.entries" ".git holds entries outside the whitelist:$extra"
  note "allowed: $ALLOWED_GIT_ENTRIES"
else
  pass "git.entries" ".git holds exactly the nine allowed entries"
fi

# The three that the whitelist covers but that are worth naming on their own,
# because each has its own remedy and its own way of coming back.
for junk in logs ORIG_HEAD FETCH_HEAD; do
  if [ -e "$GITDIR/$junk" ]; then
    fail "git.$junk" ".git/$junk is present — any git command in the repo recreates it, so scrub immediately before zipping"
  else
    pass "git.$junk" "absent"
  fi
done

# ------------------------------------------------------------ refs and HEAD --

if [ -n "$("${G[@]}" rev-list --all --not HEAD 2>/dev/null | head -1)" ]; then
  fail "git.refs-past-head" "commits exist on refs beyond HEAD"
  "${G[@]}" for-each-ref --format='%(refname) %(objectname:short)' 2>/dev/null | sed -n '1,5p' | while read -r l; do note "$l"; done
else
  pass "git.refs-past-head" "no commits reachable past HEAD"
fi

if "${G[@]}" rev-parse --verify --quiet refs/stash >/dev/null 2>&1 || [ -e "$GITDIR/refs/stash" ]; then
  fail "git.stash" "refs/stash exists — a stash keeps whole working trees alive inside .git"
else
  pass "git.stash" "no stash"
fi

HEAD_SHA="$("${G[@]}" rev-parse HEAD 2>/dev/null || true)"
BASE_SHA="$(python3 - "$B/task.toml" <<'PY' 2>/dev/null || true
import re, sys
try:
    text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
except Exception:
    raise SystemExit(0)
for key in ("base_commit_sha", "base_commit", "base_commit_hash"):
    m = re.search(r"^\s*" + key + r'\s*=\s*"([0-9a-fA-F]{7,40})"', text, re.M)
    if m:
        print(m.group(1))
        break
PY
)"
if [ -z "$BASE_SHA" ]; then
  warn "git.head-vs-base" "task.toml declares no base commit sha, cannot compare (HEAD is $HEAD_SHA)"
elif [ "$HEAD_SHA" = "$BASE_SHA" ]; then
  pass "git.head-vs-base" "HEAD matches task.toml base_commit_sha"
elif [ "${HEAD_SHA:0:${#BASE_SHA}}" = "$BASE_SHA" ]; then
  pass "git.head-vs-base" "HEAD matches the abbreviated base_commit_sha in task.toml"
else
  fail "git.head-vs-base" "HEAD $HEAD_SHA does not match task.toml base_commit_sha $BASE_SHA"
fi

# ------------------------------------------------------------- clean tree ----

DIRTY="$("${G[@]}" status --porcelain 2>/dev/null || true)"
if [ -n "$DIRTY" ]; then
  fail "git.clean-tree" "the shipped repo is already dirty ($(printf '%s\n' "$DIRTY" | grep -c .) path(s))"
  printf '%s\n' "$DIRTY" | sed -n '1,5p' | while read -r l; do note "$l"; done
else
  pass "git.clean-tree" "working tree is clean"
fi

# ------------------------------------------------------------ local config ---

FILTERS="$("${G[@]}" config --local --get-regexp '^filter\.' 2>/dev/null || true)"
if [ -n "$FILTERS" ]; then
  fail "git.filters" "local filter.* config present, a smudge or clean filter can rewrite files at checkout"
  printf '%s\n' "$FILTERS" | sed -n '1,5p' | while read -r l; do note "$l"; done
else
  pass "git.filters" "no filter.* in the local config"
fi

# ----------------------------------------------------------------- size ------

SZ_KB="$(du -sk "$GITDIR" 2>/dev/null | cut -f1)"
SZ_MB=$(( ${SZ_KB:-0} / 1024 ))
if [ "$SZ_MB" -gt "$GIT_MAX_MB" ]; then
  fail "git.size" ".git is ${SZ_MB} MB, over the ${GIT_MAX_MB} MB limit"
else
  pass "git.size" ".git is ${SZ_MB} MB (limit ${GIT_MAX_MB} MB)"
fi

# ------------------------------------------------- patches still apply -------
# gc can leave a repo that looks fine and a patch that no longer applies. Cheap
# to confirm here, and both patches are checked against the same HEAD.

for p in tests/tests.patch solution/golden.patch; do
  [ -f "$B/$p" ] || continue
  if "${G[@]}" apply --check "$B/$p" >/dev/null 2>&1; then
    pass "git.apply.$(basename "$p")" "applies cleanly at HEAD"
    continue
  fi

  ERR="$({ "${G[@]}" apply --check "$B/$p" 2>&1 || true; })"

  # A create-only tests.patch re-creates files that DO exist at base, and
  # test.sh deletes those paths before applying. `git apply --check` at HEAD
  # therefore fails by design, with nothing but "already exists" errors. That is
  # the shape the workspace prescribes, not a patch cut against the wrong base.
  if [ "$p" = "tests/tests.patch" ] \
     && [ -n "$ERR" ] \
     && ! printf '%s\n' "$ERR" | grep -qv 'already exists in working directory' \
     && [ -f "$B/tests/test.sh" ] \
     && grep -q 's|\^+++ b/||p\|^\s*rm -f ' "$B/tests/test.sh"; then
    n_exists="$(printf '%s\n' "$ERR" | grep -c 'already exists in working directory')"
    pass "git.apply.tests.patch" "create-only patch: $n_exists path(s) already exist at base and tests/test.sh deletes them before applying"
    continue
  fi

  if [ "$p" = "solution/golden.patch" ] && "${G[@]}" apply --check -R "$B/$p" >/dev/null 2>&1; then
    warn "git.apply.$(basename "$p")" "does not apply forward but reverse-applies, so the repo is already in the solved state"
  else
    fail "git.apply.$(basename "$p")" "does not apply at HEAD — regenerate it against the base commit"
    printf '%s\n' "$ERR" | sed -n '1,3p' | while read -r l; do note "$l"; done
  fi
done

summary
