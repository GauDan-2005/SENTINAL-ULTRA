#!/usr/bin/env bash
# task-doctor.sh [--root DIR] [--task NAME] [--quiet] [--no-drift]
#
# Reconcile three things that are supposed to say the same thing and regularly do not:
# what is on disk, what tasks/<name>/task.state.json claims, and what INDEX.md says.
#
# READ-ONLY. It reports drift and never fixes it, because a silent fix is how the register
# and the disk got out of step in the first place.
#
# What it looks at, per task:
#   the five folders and task.md / task_details.md
#   task.state.json, and its status against what is actually on disk
#   an INDEX.md row, and an INDEX.md row with no folder behind it
#   bin/pristine-verify.sh on download/original
#   bin/work-vs-zip-drift.sh on work/ against the uploaded zip
#   answers/submission_answer.txt older than the zip it claims to describe
# and once, globally, the pending-revision count against the throughput rule.
#
# Exit codes:
#   0  everything reconciles
#   1  at least one contradiction, including the pending-revision count being over the limit
#   2  cannot run (bad arguments, missing tool, no workspace)
#
# Note on the throughput rule: sitting exactly at the limit of two is legal, so it is a WARN.
# Being over it is a contradiction with a documented rule, so it is a FAIL. This follows the
# workspace-wide exit contract where 2 means the check could not run, not a finding.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
usage: task-doctor.sh [options]
  --root DIR    workspace root, defaults to the parent of bin/
  --task NAME   check only this task folder name
  --quiet       print findings only, no per-task PASS lines
  --no-drift    skip the work/ against zip comparison, which is the slow check
EOF
}

WORKSPACE="$ROOT_DIR"
ONLY_TASK=""
QUIET=0
NO_DRIFT=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --root) WORKSPACE="${2:-}"; shift 2 ;;
    --task) ONLY_TASK="${2:-}"; shift 2 ;;
    -q|--quiet) QUIET=1; shift ;;
    --no-drift) NO_DRIFT=1; shift ;;
    *) echo "SKIP unexpected argument $1" >&2; usage; exit 2 ;;
  esac
done

[ -d "$WORKSPACE" ] || { echo "SKIP $WORKSPACE is not a directory"; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "SKIP python3 not found"; exit 2; }
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

PASSED=0
FAILED=0
WARNED=0
pass() { [ "$QUIET" -eq 1 ] || echo "PASS $*"; PASSED=$((PASSED + 1)); }
fail() { echo "FAIL $*"; FAILED=$((FAILED + 1)); }
warn() { echo "WARN $*"; WARNED=$((WARNED + 1)); }

# ------------------------------------------------------------------ read INDEX.md rows
INDEX="$WORKSPACE/INDEX.md"
INDEX_ROWS=""
if [ -f "$INDEX" ]; then
  INDEX_ROWS="$(INDEX="$INDEX" python3 - <<'PY'
import os, re

statuses = {
    "claimed", "analysing", "analyzing", "fixing", "checks-green", "uploaded",
    "pending-revision", "sent-to-reviewer", "accepted", "rejected",
}

for raw in open(os.environ["INDEX"], encoding="utf-8"):
    line = raw.strip()
    if not line.startswith("|"):
        continue
    cells = [c.strip() for c in line.strip("|").split("|")]
    if not cells:
        continue
    m = re.search(r"\]\(([^)]+)\)", cells[0])
    if not m:
        continue
    path = m.group(1)
    name = os.path.basename(os.path.dirname(path)) if path.endswith(".md") else os.path.basename(path.rstrip("/"))
    status = ""
    for cell in cells[1:]:
        token = cell.strip().strip("*`").split()[0].strip("*`") if cell.strip() else ""
        if token in statuses:
            status = token
            break
    print("%s\t%s" % (name, status or "?"))
PY
)"
fi

INDEX_NAMES="$(printf '%s\n' "$INDEX_ROWS" | awk -F'\t' 'NF{print $1}' | sort -u)"

# ------------------------------------------------------------------ find task folders
# A directory counts as a task when it holds any of the load-bearing pieces. _archive holds
# other things too, and flagging those as broken tasks is noise.
mapfile -t TASK_DIRS < <(
  for base in "$WORKSPACE/tasks" "$WORKSPACE/_archive"; do
    [ -d "$base" ] || continue
    while IFS= read -r d; do
      if [ -d "$d/work" ] || [ -d "$d/download" ] || [ -f "$d/task.md" ]; then
        printf '%s\n' "$d"
      fi
    done < <(find "$base" -mindepth 1 -maxdepth 1 -type d | sort)
  done
)

if [ "${#TASK_DIRS[@]}" -eq 0 ]; then
  echo "SKIP no task folders under $WORKSPACE/tasks or $WORKSPACE/_archive"
  exit 2
fi

DISK_NAMES=""
PENDING=0

for TD in "${TASK_DIRS[@]}"; do
  NAME="$(basename "$TD")"
  DISK_NAMES="$DISK_NAMES$NAME"$'\n'
  if [ -n "$ONLY_TASK" ] && [ "$NAME" != "$ONLY_TASK" ]; then continue; fi

  echo "== $NAME"

  # -- structure
  MISSING=""
  for sub in download work upload answers; do
    [ -d "$TD/$sub" ] || MISSING="$MISSING $sub/"
  done
  for f in task.md task_details.md; do
    [ -f "$TD/$f" ] || MISSING="$MISSING $f"
  done
  if [ -n "$MISSING" ]; then
    fail "STRUCTURE $NAME is missing:$MISSING"
  else
    pass "STRUCTURE all five folders and both records present"
  fi

  # -- state file and the status it declares
  STATE="$TD/task.state.json"
  STATUS=""
  if [ -f "$STATE" ]; then
    STATUS="$(STATE="$STATE" python3 - <<'PY'
import json, os
try:
    d = json.load(open(os.environ["STATE"], encoding="utf-8"))
except Exception as exc:
    print("!parse-error: %s" % exc)
else:
    print(d.get("status", "") or "?")
PY
)"
    case "$STATUS" in
      "!parse-error"*) fail "STATE task.state.json does not parse ($STATUS)"; STATUS="" ;;
      "?"|"") warn "STATE task.state.json carries no status"; STATUS="" ;;
      *) pass "STATE task.state.json says status=$STATUS" ;;
    esac
  else
    warn "STATE no task.state.json, falling back to the INDEX.md row"
  fi

  # -- INDEX row
  INDEX_STATUS="$(printf '%s\n' "$INDEX_ROWS" | awk -F'\t' -v n="$NAME" '$1==n{print $2; exit}')"
  if [ -z "$INDEX_STATUS" ]; then
    fail "INDEX no row in INDEX.md for $NAME"
  else
    pass "INDEX row present with status=$INDEX_STATUS"
    if [ -n "$STATUS" ] && [ "$STATUS" != "$INDEX_STATUS" ] && [ "$INDEX_STATUS" != "?" ]; then
      fail "INDEX-STATE INDEX.md says $INDEX_STATUS, task.state.json says $STATUS"
    fi
  fi

  EFFECTIVE="${STATUS:-$INDEX_STATUS}"
  [ "$EFFECTIVE" = "pending-revision" ] && PENDING=$((PENDING + 1))

  # -- the zip the status implies
  ZIP="$(find "$TD/upload" -maxdepth 1 -type f -name '*.zip' 2>/dev/null | sort | head -1 || true)"
  case "$EFFECTIVE" in
    checks-green|uploaded|pending-revision|sent-to-reviewer|accepted|rejected)
      if [ -z "$ZIP" ]; then
        fail "ZIP status is $EFFECTIVE but upload/ holds no zip"
      else
        pass "ZIP $(basename "$ZIP") present as status $EFFECTIVE implies"
      fi
      ;;
    *)
      [ -n "$ZIP" ] && warn "ZIP a zip exists but status is ${EFFECTIVE:-unknown}"
      ;;
  esac

  # -- work/ newer than the zip
  if [ -n "$ZIP" ] && [ -d "$TD/work" ]; then
    NEWER="$(find "$TD/work" -newer "$ZIP" 2>/dev/null | head -3 || true)"
    if [ -n "$NEWER" ]; then
      # A newer mtime is a hint, not proof - a directory mtime moves for reasons that never
      # reach the bundle. WORK-VS-ZIP below compares content and is the check that fails.
      COUNT="$(find "$TD/work" -newer "$ZIP" 2>/dev/null | wc -l | tr -d ' ')"
      warn "WORK-MTIME $COUNT paths in work/ are newer than $(basename "$ZIP"), first: $(printf '%s' "$NEWER" | head -1 | sed "s|$TD/||")"
    else
      pass "WORK-MTIME nothing in work/ is newer than the zip"
    fi
  fi

  # -- answers older than the zip
  ANSWER="$TD/answers/submission_answer.txt"
  if [ -n "$ZIP" ] && [ -f "$ANSWER" ]; then
    if [ "$ANSWER" -ot "$ZIP" ]; then
      fail "ANSWERS submission_answer.txt is older than $(basename "$ZIP") - it describes a bundle that no longer exists"
    else
      pass "ANSWERS submission_answer.txt is at least as new as the zip"
    fi
  elif [ -z "${ANSWER:-}" ] || [ ! -f "$ANSWER" ]; then
    case "$EFFECTIVE" in
      uploaded|pending-revision|sent-to-reviewer|accepted)
        warn "ANSWERS no answers/submission_answer.txt at status $EFFECTIVE" ;;
    esac
  fi
  if [ -d "$TD/answers" ]; then
    EXTRA="$(find "$TD/answers" -mindepth 1 ! -name submission_answer.txt 2>/dev/null | head -3 || true)"
    [ -n "$EXTRA" ] && warn "ANSWERS answers/ should hold only submission_answer.txt, also found: $(printf '%s' "$EXTRA" | tr '\n' ' ' | sed "s|$TD/answers/||g")"
  fi

  # -- pristine baseline
  if [ -x "$ROOT_DIR/bin/pristine-verify.sh" ]; then
    set +e
    PV_OUT="$("$ROOT_DIR/bin/pristine-verify.sh" "$TD" --quiet 2>&1)"
    PV_RC=$?
    set -e
    case "$PV_RC" in
      0) pass "PRISTINE download/original matches its manifest" ;;
      3) warn "PRISTINE no manifest - run bin/pristine-freeze.sh $NAME" ;;
      2) warn "PRISTINE could not run: $(printf '%s' "$PV_OUT" | head -1)" ;;
      *) fail "PRISTINE download/original has drifted from the shipped zip"
         printf '%s\n' "$PV_OUT" | grep '^FAIL' | head -3 | sed 's/^/     /' ;;
    esac
  else
    warn "PRISTINE bin/pristine-verify.sh is not executable"
  fi

  # -- work/ against the uploaded zip
  if [ "$NO_DRIFT" -eq 0 ] && [ -n "$ZIP" ] && [ -x "$ROOT_DIR/bin/work-vs-zip-drift.sh" ]; then
    set +e
    WD_OUT="$("$ROOT_DIR/bin/work-vs-zip-drift.sh" "$TD" --quiet --max-report 3 2>&1)"
    WD_RC=$?
    set -e
    case "$WD_RC" in
      0) pass "WORK-VS-ZIP work/ still matches the uploaded zip" ;;
      2) warn "WORK-VS-ZIP could not run: $(printf '%s' "$WD_OUT" | head -1)" ;;
      *) fail "WORK-VS-ZIP work/ has drifted from the uploaded zip"
         printf '%s\n' "$WD_OUT" | grep '^FAIL' | head -3 | sed 's/^/     /' ;;
    esac
  fi
done

# --------------------------------------------------------------- workspace-wide checks
echo "== workspace"

ORPHANS=""
while IFS= read -r n; do
  [ -n "$n" ] || continue
  printf '%s\n' "$DISK_NAMES" | grep -qxF "$n" || ORPHANS="$ORPHANS $n"
done <<< "$INDEX_NAMES"
if [ -n "$ORPHANS" ]; then
  fail "INDEX-ORPHAN INDEX.md has rows with no folder on disk:$ORPHANS"
else
  pass "INDEX-ORPHAN every INDEX.md row has a folder"
fi

if [ -n "$ONLY_TASK" ]; then
  PENDING="$(printf '%s\n' "$INDEX_ROWS" | awk -F'\t' '$2=="pending-revision"' | wc -l | tr -d ' ')"
fi
if [ "$PENDING" -gt 2 ]; then
  fail "THROUGHPUT $PENDING tasks are pending-revision, the platform allows two - one has to clear before a new claim"
elif [ "$PENDING" -eq 2 ]; then
  warn "THROUGHPUT 2 tasks are pending-revision, at the limit, no new task can be claimed"
else
  pass "THROUGHPUT $PENDING of 2 pending-revision slots used"
fi

echo "$PASSED passed, $FAILED failed, $WARNED skipped"
[ "$FAILED" -eq 0 ]
