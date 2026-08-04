#!/usr/bin/env bash
# rezip.sh <task-dir> [--dry-run] [--skip-preflight] [--name NAME]
#
# The CLAUDE.md Step 5 re-zip rule, executed in the mandated order and refusing to build
# a zip when any gate before it fails.
#
#   0. git hygiene FIRST, in a loop, until `git fsck --unreachable` prints nothing.
#      Regenerating tests.patch and running the local checks both write objects that a
#      single gc leaves dangling, so one pass is not enough.
#   1. re-confirm tests.patch and the solution patch still apply at HEAD.
#   2. Phase A gates via bin/preflight.sh --work.
#   3. zip from INSIDE the working copy with `zip -rXy`.
#         -X keeps the directory entries. A missing empty .git/refs/ unpacks broken on the
#            platform even though the local copy works.
#         -y stores symlinks as symlinks instead of copying what they point at.
#   4. verify the built zip: top-level layout, no runs/, no task/ wrapper, .git present,
#      refs/ entries listed, symlink count preserved, both scripts at 0755.
#   5. record the zip fingerprint for bin/work-vs-zip-drift.sh.
#
# Exit codes:
#   0  zip built and verified
#   1  a gate failed - no zip was built, or the zip that was built did not verify
#   2  cannot run (bad arguments, missing directory, missing tool)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
usage: rezip.sh <task-dir> [options]
  --dry-run          print every step and change nothing
  --skip-preflight   do not run bin/preflight.sh (declare this in Comments for Reviewer)
  --name NAME        zip basename without .zip, defaults to the task directory name
EOF
}

TASK_DIR=""
DRY_RUN=0
SKIP_PREFLIGHT=0
NAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dry-run|-n) DRY_RUN=1; shift ;;
    --skip-preflight) SKIP_PREFLIGHT=1; shift ;;
    --name) NAME="${2:-}"; shift 2 ;;
    -*) echo "SKIP unknown option $1" >&2; usage; exit 2 ;;
    *)
      if [ -n "$TASK_DIR" ]; then echo "SKIP more than one task directory given" >&2; exit 2; fi
      TASK_DIR="$1"; shift ;;
  esac
done

[ -n "$TASK_DIR" ] || { usage; exit 2; }
[ -d "$TASK_DIR" ] || { echo "SKIP $TASK_DIR is not a directory"; exit 2; }
for tool in git zip unzip python3; do
  command -v "$tool" >/dev/null 2>&1 || { echo "SKIP $tool not found"; exit 2; }
done

TASK_DIR="$(cd "$TASK_DIR" && pwd)"
WORK="$TASK_DIR/work"
UPLOAD="$TASK_DIR/upload"
[ -d "$WORK" ] || { echo "SKIP $WORK does not exist"; exit 2; }
[ -n "$NAME" ] || NAME="$(basename "$TASK_DIR")"
ZIP="$UPLOAD/$NAME.zip"

PASSED=0
FAILED=0
SKIPPED=0
pass() { echo "PASS $*"; PASSED=$((PASSED + 1)); }
fail() { echo "FAIL $*"; FAILED=$((FAILED + 1)); }
warn() { echo "WARN $*"; }
skip() { echo "SKIP $*"; SKIPPED=$((SKIPPED + 1)); }
summary() { echo "$PASSED passed, $FAILED failed, $SKIPPED skipped"; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "     would run: $*"
    return 0
  fi
  "$@"
}

# ------------------------------------------------------------------ 0. git hygiene first
REPO="$WORK/environment/repo"
if [ ! -d "$REPO/.git" ]; then
  skip "GIT no git repository at work/environment/repo"
else
  echo "-- step 0: git hygiene"
  SCRUB_CLEAN=0
  for attempt in 1 2 3 4 5; do
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "     would run: reflog expire + stash clear + gc --prune=now + rm logs/ORIG_HEAD/FETCH_HEAD (attempt loop)"
      SCRUB_CLEAN=1
      break
    fi
    git -C "$REPO" reflog expire --expire=now --expire-unreachable=now --all >/dev/null 2>&1 || true
    git -C "$REPO" stash clear >/dev/null 2>&1 || true
    git -C "$REPO" gc --prune=now --quiet >/dev/null 2>&1 || true
    rm -rf "$REPO/.git/logs" "$REPO/.git/ORIG_HEAD" "$REPO/.git/FETCH_HEAD" \
           "$REPO/.git/MERGE_HEAD" "$REPO/.git/CHERRY_PICK_HEAD" "$REPO/.git/refs/remotes" \
           "$REPO/.git/COMMIT_EDITMSG"
    # refs/remotes/origin/HEAD is the one no other check catches: git remote is empty so the
    # static check passes, and for-each-ref does not list it.
    rmdir "$REPO/.git/branches" 2>/dev/null || true
    UNREACHABLE="$(git -C "$REPO" fsck --unreachable --no-progress 2>/dev/null || true)"
    if [ -z "$UNREACHABLE" ]; then
      pass "GIT-FSCK clean after $attempt pass(es), no unreachable objects"
      SCRUB_CLEAN=1
      break
    fi
    echo "     attempt $attempt left $(printf '%s\n' "$UNREACHABLE" | wc -l) unreachable object(s), repeating"
  done

  if [ "$SCRUB_CLEAN" -ne 1 ]; then
    fail "GIT-FSCK unreachable objects survive five expire/gc passes - read a few with 'git cat-file -p <sha>' before zipping"
    printf '%s\n' "$UNREACHABLE" | head -10
    summary
    exit 1
  fi

  if [ "$DRY_RUN" -ne 1 ]; then
    STRAY="$(cd "$REPO/.git" && ls -A | grep -vxE 'config|description|HEAD|hooks|index|info|objects|packed-refs|refs' || true)"
    if [ -n "$STRAY" ]; then
      warn "GIT-CONTENTS .git holds entries beyond the expected set: $(echo "$STRAY" | tr '\n' ' ')"
    else
      pass "GIT-CONTENTS .git holds only config description HEAD hooks index info objects packed-refs refs"
    fi
    if [ -n "$(git -C "$REPO" status --porcelain 2>/dev/null || true)" ]; then
      fail "GIT-STATUS the shipped repo has uncommitted changes"
    else
      pass "GIT-STATUS working tree is clean"
    fi
    if [ -n "$(git -C "$REPO" remote 2>/dev/null || true)" ]; then
      fail "GIT-REMOTE the shipped repo still has a remote configured"
    else
      pass "GIT-REMOTE no remotes"
    fi
  fi
fi

# ------------------------------------------------------- 1. both patches still apply
echo "-- step 1: patches still apply at HEAD"
if [ -d "$REPO/.git" ] && [ "$DRY_RUN" -ne 1 ]; then
  TP="$TASK_DIR/work/tests/tests.patch"
  if [ -f "$TP" ]; then
    if git -C "$REPO" apply --check "$TP" >/dev/null 2>&1; then
      pass "TESTS-PATCH tests.patch applies at the base commit"
    else
      fail "TESTS-PATCH tests.patch does not apply at the base commit"
      git -C "$REPO" apply --check "$TP" 2>&1 | head -5 | sed 's/^/     /'
    fi
  else
    skip "TESTS-PATCH no tests/tests.patch in the working copy"
  fi

  for candidate in golden.patch init_state.patch solution.patch; do
    SP="$TASK_DIR/work/solution/$candidate"
    [ -f "$SP" ] || continue
    if [ "$candidate" = "init_state.patch" ]; then
      if git -C "$REPO" apply --check -R "$SP" >/dev/null 2>&1; then
        pass "SOLUTION-PATCH $candidate reverse-applies at the base commit"
      else
        fail "SOLUTION-PATCH $candidate does not reverse-apply at the base commit"
      fi
    else
      if git -C "$REPO" apply --check "$SP" >/dev/null 2>&1; then
        pass "SOLUTION-PATCH $candidate applies at the base commit"
      elif git -C "$REPO" apply --3way --check "$SP" >/dev/null 2>&1; then
        warn "SOLUTION-PATCH $candidate needs --3way, which solve.sh must use"
      else
        fail "SOLUTION-PATCH $candidate applies neither directly nor with --3way"
      fi
    fi
    if [ "$candidate" = "solution.patch" ]; then
      warn "SOLUTION-PATCH solution.patch is a dead draft name, rename it to golden.patch"
    fi
  done
elif [ "$DRY_RUN" -eq 1 ]; then
  echo "     would run: git apply --check on tests/tests.patch and the solution patch"
else
  skip "PATCHES no repo to apply against"
fi

if [ "$FAILED" -gt 0 ]; then
  echo "REFUSING to zip - fix the failures above and run this again"
  summary
  exit 1
fi

# ------------------------------------------------------------ 2. Phase A gates
echo "-- step 2: Phase A gates"
PREFLIGHT="$ROOT_DIR/bin/preflight.sh"
if [ "$SKIP_PREFLIGHT" -eq 1 ]; then
  skip "PREFLIGHT skipped on request - say so in Comments for Reviewer"
elif [ ! -x "$PREFLIGHT" ]; then
  skip "PREFLIGHT bin/preflight.sh is not present, the static gates did not run"
elif [ "$DRY_RUN" -eq 1 ]; then
  echo "     would run: $PREFLIGHT --work $TASK_DIR"
else
  set +e
  "$PREFLIGHT" --work "$TASK_DIR"
  PF_RC=$?
  set -e
  case "$PF_RC" in
    0) pass "PREFLIGHT --work all gates pass" ;;
    2) warn "PREFLIGHT --work warnings only, declare them in Comments for Reviewer" ;;
    *)
      fail "PREFLIGHT --work exited $PF_RC - no zip built"
      summary
      exit 1
      ;;
  esac
fi

# --------------------------------------------------------------------------- 3. zip
echo "-- step 3: build the zip"
run mkdir -p "$UPLOAD"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "     would run: (cd $WORK && zip -rXy $ZIP . -x '*.DS_Store' '__MACOSX/*')"
else
  rm -f "$ZIP"
  ( cd "$WORK" && zip -rXy "$ZIP" . -x '*.DS_Store' '__MACOSX/*' >/dev/null )
  pass "ZIP built $(basename "$ZIP") ($(du -h "$ZIP" | cut -f1))"
fi

# ------------------------------------------------------------------ 4. verify the zip
echo "-- step 4: verify the zip"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "     would run: layout, runs/, task/, .git, refs/, symlink count and script mode checks"
else
  WORK_LINKS="$(find "$WORK" -type l | wc -l | tr -d ' ')"
  set +e
  ZIP="$ZIP" WORK_LINKS="$WORK_LINKS" python3 - <<'PY'
import os, stat, sys, zipfile

z = zipfile.ZipFile(os.environ["ZIP"])
infos = z.infolist()
names = [i.filename for i in infos]
work_links = int(os.environ["WORK_LINKS"])

problems = []
good = []

top = {n.split("/", 1)[0] for n in names}
for required in ("instruction.md", "task.toml", "environment", "solution", "tests"):
    if required not in top:
        problems.append("LAYOUT %s is not at the top level of the zip" % required)
if not [p for p in problems if p.startswith("LAYOUT")]:
    good.append("LAYOUT instruction.md, task.toml, environment/, solution/ and tests/ sit at the top level")

if any(n.startswith("runs/") or n == "runs" for n in names):
    problems.append("RUNS the zip contains runs/")
else:
    good.append("RUNS no runs/ directory")

if any(n.startswith("task/") for n in names):
    problems.append("WRAPPER the zip has a task/ wrapper directory")
else:
    good.append("WRAPPER no task/ wrapper")

if not any(n.startswith("environment/repo/.git/") for n in names):
    problems.append("GIT environment/repo/.git/ is not in the zip")
else:
    good.append("GIT environment/repo/.git/ is in the zip")

refs = [n for n in names if "/refs/" in n or n.endswith("/refs/")]
if not refs:
    problems.append("REFS no refs/ entries in the zip - it was built without -X")
else:
    good.append("REFS %d refs/ entries present" % len(refs))

zip_links = sum(1 for i in infos if stat.S_ISLNK(i.external_attr >> 16))
if zip_links != work_links:
    problems.append(
        "SYMLINKS work/ holds %d symlinks, the zip holds %d - was it built without -y"
        % (work_links, zip_links)
    )
else:
    good.append("SYMLINKS %d symlinks preserved" % zip_links)

modes = {i.filename: (i.external_attr >> 16) & 0o7777 for i in infos}
for script in ("tests/test.sh", "solution/solve.sh"):
    if script not in modes:
        problems.append("MODE %s is missing from the zip" % script)
    elif modes[script] & 0o111 == 0:
        problems.append("MODE %s is 0%04o in the zip, it must be executable" % (script, modes[script]))
    else:
        good.append("MODE %s is 0%04o" % (script, modes[script]))

for line in good:
    print("PASS " + line)
for line in problems:
    print("FAIL " + line)
print("%d passed, %d failed, 0 skipped" % (len(good), len(problems)))
sys.exit(1 if problems else 0)
PY
  ZIP_RC=$?
  set -e
  if [ "$ZIP_RC" -ne 0 ]; then
    fail "ZIP-VERIFY the built zip did not verify - do not upload it"
    summary
    exit 1
  fi
  pass "ZIP-VERIFY layout, git, refs, symlinks and script modes all check out"
fi

# ------------------------------------------- 5. fingerprint the zip for drift detection
echo "-- step 5: fingerprint"
DRIFT="$ROOT_DIR/bin/work-vs-zip-drift.sh"
if [ ! -x "$DRIFT" ]; then
  skip "FINGERPRINT bin/work-vs-zip-drift.sh not present, no manifest written"
elif [ "$DRY_RUN" -eq 1 ]; then
  echo "     would run: $DRIFT $TASK_DIR --record"
else
  if "$DRIFT" "$TASK_DIR" --record >/dev/null; then
    pass "FINGERPRINT wrote $(basename "$ZIP" .zip).manifest next to the zip"
  else
    warn "FINGERPRINT could not write the zip manifest"
  fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN - nothing was changed"
fi
summary
[ "$FAILED" -eq 0 ]
