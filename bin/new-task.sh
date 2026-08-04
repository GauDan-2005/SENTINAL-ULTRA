#!/usr/bin/env bash
# new-task.sh <zip> <original-dir-name> [--dest DIR] [--go] [--i-am-starting-a-real-task]
#
# The Step 1.5 and Section 7 bootstrap in one command, so the extraction that lost mode bits
# and symlinks on three of four tasks is done once, by a tool, and verified.
#
#   1. create download/ work/ upload/ answers/
#   2. copy the zip into download/
#   3. bin/pristine-freeze.sh - extract, manifest, verify against the zip, freeze read-only
#   4. cp -a download/original/. work/ then chmod -R u+w work
#   5. scaffold task.md, task_details.md and task.state.json
#   6. print the INDEX.md row to paste, or run bin/index-render.sh when it exists
#
# It is a DRY RUN unless --go is passed. Writing under tasks/ needs --go AND
# --i-am-starting-a-real-task, because a half-bootstrapped folder there is worse than none.
#
# Exit codes:
#   0  bootstrapped, or the dry run printed its plan
#   1  the freeze did not verify, or the copy to work/ does not match the pristine tree
#   2  cannot run (bad arguments, missing zip, missing tool, refusing to write under tasks/)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
usage: new-task.sh <zip> <original-dir-name> [options]
  --dest DIR                    parent directory for the task folder, default <root>/tasks
  --go                          actually do it, instead of printing the plan
  --i-am-starting-a-real-task   required with --go when the target is under tasks/
EOF
}

ZIP=""
NAME=""
DEST_PARENT=""
GO=0
REAL=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dest) DEST_PARENT="${2:-}"; shift 2 ;;
    --go) GO=1; shift ;;
    --i-am-starting-a-real-task) REAL=1; shift ;;
    -*) echo "SKIP unknown option $1" >&2; usage; exit 2 ;;
    *)
      if [ -z "$ZIP" ]; then ZIP="$1"
      elif [ -z "$NAME" ]; then NAME="$1"
      else echo "SKIP unexpected argument $1" >&2; usage; exit 2; fi
      shift ;;
  esac
done

[ -n "$ZIP" ] && [ -n "$NAME" ] || { usage; exit 2; }
[ -f "$ZIP" ] || { echo "SKIP zip $ZIP not found"; exit 2; }
for tool in python3 unzip zip; do
  command -v "$tool" >/dev/null 2>&1 || { echo "SKIP $tool not found"; exit 2; }
done
case "$NAME" in
  */*|"") echo "SKIP <original-dir-name> must be a folder name, not a path"; exit 2 ;;
esac

ZIP="$(cd "$(dirname "$ZIP")" && pwd)/$(basename "$ZIP")"
[ -n "$DEST_PARENT" ] || DEST_PARENT="$ROOT_DIR/tasks"
mkdir -p "$DEST_PARENT" 2>/dev/null || true
[ -d "$DEST_PARENT" ] || { echo "SKIP $DEST_PARENT does not exist"; exit 2; }
DEST_PARENT="$(cd "$DEST_PARENT" && pwd)"
TD="$DEST_PARENT/$NAME"

UNDER_TASKS=0
case "$TD/" in
  "$ROOT_DIR/tasks/"*) UNDER_TASKS=1 ;;
esac

if [ "$GO" -eq 1 ] && [ "$UNDER_TASKS" -eq 1 ] && [ "$REAL" -ne 1 ]; then
  echo "SKIP $TD is under tasks/ - pass --i-am-starting-a-real-task to confirm"
  exit 2
fi
if [ -e "$TD" ]; then
  echo "SKIP $TD already exists - bootstrap into a fresh folder"
  exit 2
fi

SUBMISSION_ID="$(basename "$ZIP" | sed -e 's/_submission\.zip$//' -e 's/\.zip$//')"
TODAY="$(date -u +%Y-%m-%d)"

echo "-- plan"
echo "   zip           $ZIP"
echo "   task folder   $TD"
echo "   submission id $SUBMISSION_ID"
echo "   claimed       $TODAY"

if [ "$GO" -ne 1 ]; then
  cat <<EOF

DRY RUN. Nothing was written. It would:
  mkdir -p $TD/{download,work,upload,answers}
  cp $(basename "$ZIP") into $TD/download/
  bin/pristine-freeze.sh $TD          # extract, manifest, verify, freeze read-only
  cp -a $TD/download/original/. $TD/work/ && chmod -R u+w $TD/work
  write task.md, task_details.md, task.state.json
  print the INDEX.md row

Re-run with --go$([ "$UNDER_TASKS" -eq 1 ] && echo " --i-am-starting-a-real-task") to do it.
EOF
  exit 0
fi

# ------------------------------------------------------------------------------- do it
mkdir -p "$TD"/{download,work,upload,answers}
cp "$ZIP" "$TD/download/"
echo "PASS FOLDERS created $TD with download/ work/ upload/ answers/"

if ! "$ROOT_DIR/bin/pristine-freeze.sh" "$TD"; then
  echo "FAIL FREEZE the extract does not match the zip - a lossy extraction was caught at minute one"
  echo "0 passed, 1 failed, 0 skipped"
  exit 1
fi

cp -a "$TD/download/original/." "$TD/work/"
# The pristine tree is frozen read-only and cp -a carries that across, so put the write bits
# back or the first edit fails with permission denied.
chmod -R u+w "$TD/work"
echo "PASS WORK working copy created from the frozen pristine tree"

if diff -rq "$TD/download/original" "$TD/work" -x '.git' >/dev/null 2>&1; then
  echo "PASS COPY work/ matches download/original outside .git"
else
  echo "FAIL COPY work/ already differs from download/original"
  diff -rq "$TD/download/original" "$TD/work" -x '.git' | head -5 | sed 's/^/     /'
  echo "0 passed, 1 failed, 0 skipped"
  exit 1
fi

LINKS_ORIG="$(find "$TD/download/original" -type l | wc -l | tr -d ' ')"
LINKS_WORK="$(find "$TD/work" -type l | wc -l | tr -d ' ')"
if [ "$LINKS_ORIG" = "$LINKS_WORK" ]; then
  echo "PASS SYMLINKS $LINKS_ORIG symlinks in both trees"
else
  echo "FAIL SYMLINKS download/original has $LINKS_ORIG symlinks, work/ has $LINKS_WORK"
  echo "0 passed, 1 failed, 0 skipped"
  exit 1
fi

# ------------------------------------------------------------------------- scaffolding
cat > "$TD/task_details.md" <<EOF
# $NAME

The platform data block, pasted verbatim. Do not fill any of this in from the files - it
comes from the platform and Step 2 cross-checks the files against it.

\`\`\`
Original Directory Name: $NAME
Category:
Difficulty:
Task Tags:
Languages:
Metadata:
\`\`\`

Source PR:
Base commit:
EOF

cat > "$TD/task.md" <<EOF
# $NAME

Submission id: $SUBMISSION_ID
Claimed: $TODAY
Verdict:
Status: claimed

## Upload ledger

A row goes in after each zip is verified, before it is uploaded.

| # | Date | Zip sha256 | Size | Checks returned | Outcome |
|---|---|---|---|---|---|

## Handling-time ledger

The answers form's revision figure is copied from the last Cumulative cell, never remembered.

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|

## Strike counter

Two strikes on one signature forces the remove-the-dependency path. A third variation of the
same theory does not get shipped.

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|

## Learning notes carried in

Which notes in learning/ apply to this task and what each one says to do here.

## Stock-defect baseline

What the shipped bundle does wrong before any edit - the fail-open grader, the restore step,
the pass_to_pass list, the script modes.

## Check history

One block per round: what the platform returned, verbatim.

## Findings

Numbered, each with a file and a line.

## Files changed

Numbered, one entry per file, with Changed: and Why: lines.
EOF

cat > "$TD/task.state.json" <<EOF
{
  "original_dir": "$NAME",
  "submission_id": "$SUBMISSION_ID",
  "repo": "",
  "pr": "",
  "verdict": "",
  "status": "claimed",
  "claimed": "$TODAY",
  "rounds": 0,
  "last_upload": null,
  "checks": {
    "static": null,
    "prescriptiveness": null,
    "difficulty": null,
    "oracle": null,
    "quality": null
  },
  "blocking": null,
  "next_action": "Step 2: read the bundle and cross-check the platform data block"
}
EOF
echo "PASS SCAFFOLD wrote task.md, task_details.md and task.state.json"

# --------------------------------------------------------------------------- register
RENDER="$ROOT_DIR/bin/index-render.sh"
REL="${TD#"$ROOT_DIR"/}"
if [ -x "$RENDER" ]; then
  "$RENDER" || echo "WARN INDEX bin/index-render.sh returned nonzero"
  echo "PASS INDEX register re-rendered"
else
  cat <<EOF
NOTE add this row to INDEX.md under Active:

| [$NAME]($REL/task.md) | ${SUBMISSION_ID:0:8} | <repo> <pr> | | claimed | 0 | $TODAY | |
EOF
fi

echo "5 passed, 0 failed, 0 skipped"
