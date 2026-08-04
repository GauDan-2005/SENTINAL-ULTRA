#!/usr/bin/env bash
# session-start.sh [<task-dir>] [--full] [--no-drift]
#
# The CLAUDE.md Step 1 report, generated instead of re-derived.
#
# Step 1 asks for the whole learning/ corpus, then INDEX.md, then a reconciliation of the
# register against disk, then the throughput count. Four of those five are mechanical and
# get short-cut on a busy day. This prints them in Step 1's order.
#
# The digest is not a substitute for the notes. It sequences them, so the full text of the
# ones that matter for the task in hand is read on purpose rather than in file order, and a
# note still beats CLAUDE.md on any matter of fact about what the platform does.
#
# Sections:
#   1  learning digest, sequenced, with stale and refuted called out
#   2  the INDEX.md register
#   3  reconciliation, from bin/task-doctor.sh
#   4  the throughput count against the limit of two
#   5  the named task's brief: applicable notes, rounds trend, last preflight
#
# READ-ONLY.
#
# Exit codes:
#   0  nothing needs attention
#   1  the reconciliation found a contradiction, or a refuted note matched the task
#   2  cannot run (missing workspace, missing tool)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
usage: session-start.sh [<task-dir>] [--full] [--no-drift]
  --full       print each note's whole one-line lesson instead of truncating it
  --no-drift   skip the slow work/ against zip comparison in the reconciliation
EOF
}

TASK_DIR=""
FULL=0
NO_DRIFT=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --full) FULL=1; shift ;;
    --no-drift) NO_DRIFT=1; shift ;;
    -*) echo "SKIP unknown option $1" >&2; usage; exit 2 ;;
    *)
      if [ -n "$TASK_DIR" ]; then echo "SKIP more than one task directory given" >&2; exit 2; fi
      TASK_DIR="$1"; shift ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "SKIP python3 not found"; exit 2; }
[ -d "$ROOT_DIR/learning" ] || { echo "SKIP no learning/ under $ROOT_DIR"; exit 2; }
if [ -n "$TASK_DIR" ] && [ ! -d "$TASK_DIR" ]; then
  echo "SKIP $TASK_DIR is not a directory"; exit 2
fi

RC=0

echo "================================================================"
echo " SESSION START  $(date -u +%Y-%m-%d)  $(basename "$ROOT_DIR")"
echo "================================================================"

# ------------------------------------------------------------- 1. learning digest
echo
echo "-- 1. learning digest ($(find "$ROOT_DIR/learning" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ') files)"
echo

LEARNING_DIR="$ROOT_DIR/learning" FULL="$FULL" TODAY="$(date -u +%Y-%m-%d)" python3 - <<'PY'
import datetime, os, re, sys

d = os.environ["LEARNING_DIR"]
full = os.environ["FULL"] == "1"
today = datetime.date.fromisoformat(os.environ["TODAY"])

# One-line lessons live in README.md's index table, last column.
lessons = {}
readme = os.path.join(d, "README.md")
if os.path.exists(readme):
    for line in open(readme, encoding="utf-8"):
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 4:
            continue
        m = re.search(r"\]\(([^)]+)\)", cells[0])
        if m:
            lessons[os.path.basename(m.group(1))] = cells[-1]


def frontmatter(path):
    fm = {}
    with open(path, encoding="utf-8") as fh:
        first = fh.readline()
        if first.strip() != "---":
            return None
        key = None
        for line in fh:
            if line.strip() == "---":
                break
            if line.startswith((" ", "\t", "-")) and key:
                continue
            if ":" in line:
                key, _, value = line.partition(":")
                key = key.strip()
                fm[key] = value.split("#")[0].strip().strip('"').strip("'")
    return fm


rows = []
for name in sorted(os.listdir(d)):
    if not name.endswith(".md") or name == "README.md":
        continue
    path = os.path.join(d, name)
    fm = frontmatter(path)
    if fm is None:
        rows.append((name, "UNCLASSIFIED", "", None, False, lessons.get(name, "")))
        continue
    status = fm.get("status", "?")
    verified = fm.get("last_verified", "")
    age = None
    try:
        age = (today - datetime.date.fromisoformat(verified)).days
    except Exception:
        age = None
    blocks = fm.get("blocks_submission", "").lower() == "true"
    rows.append((name, status, verified, age, blocks, lessons.get(name, "")))

FIRST = ("LEDGER.md", "stock-bundle-defect-baseline.md")
order = {"platform-confirmed": 0, "locally-verified": 1, "reported": 2,
         "UNCLASSIFIED": 3, "superseded": 4, "refuted": 5}
rows.sort(key=lambda r: (r[0] not in FIRST, not r[4], order.get(r[1], 3), r[0]))

width = 0 if full else 96
print("  %-46s %-19s %-11s %s" % ("note", "status", "verified", "blocks"))
print("  " + "-" * 92)
stale, bad = [], []
for name, status, verified, age, blocks, lesson in rows:
    age_txt = verified if verified else "-"
    if age is not None:
        age_txt = "%s (%dd)" % (verified, age)
    print("  %-46s %-19s %-11s %s" % (name[:46], status, age_txt[:11], "BLOCKS" if blocks else ""))
    if lesson:
        text = re.sub(r"[*`]", "", lesson)
        if width and len(text) > width:
            text = text[: width - 1] + "…"
        print("      %s" % text)
    if age is not None and age > 60:
        stale.append("%s (%dd old)" % (name, age))
    if status in ("refuted", "superseded"):
        bad.append("%s is %s" % (name, status))

print()
if bad:
    for line in bad:
        print("  WARN RETIRED %s - read LEDGER.md before reusing anything from it" % line)
if stale:
    for line in stale:
        print("  WARN STALE %s - over 60 days since its evidence was gathered" % line)
if not bad and not stale:
    print("  PASS LEARNING every note is current and none is retired")
PY

# ------------------------------------------------------------------ 2. the register
echo
echo "-- 2. register (INDEX.md)"
echo
if [ -f "$ROOT_DIR/INDEX.md" ]; then
  # From ## Active up to the first heading that is neither Active nor Done, and only the
  # table rows plus the headings - the prose under the tables belongs to the note it is in.
  awk '
    /^## / { p = ($0 ~ /^## (Active|Done)/) ? 1 : 0 }
    p && (/^## / || /^\|/) { print }
  ' "$ROOT_DIR/INDEX.md" | sed 's/^/  /'
else
  echo "  WARN no INDEX.md at the workspace root"
fi

# ----------------------------------------------------------- 3. the reconciliation
echo
echo "-- 3. reconciliation (bin/task-doctor.sh)"
echo
DOCTOR="$ROOT_DIR/bin/task-doctor.sh"
PENDING_LINE=""
if [ -x "$DOCTOR" ]; then
  DOCTOR_ARGS=()
  [ "$NO_DRIFT" -eq 1 ] && DOCTOR_ARGS+=(--no-drift)
  set +e
  DOCTOR_OUT="$("$DOCTOR" --quiet "${DOCTOR_ARGS[@]+"${DOCTOR_ARGS[@]}"}" 2>&1)"
  DOCTOR_RC=$?
  set -e
  printf '%s\n' "$DOCTOR_OUT" | sed 's/^/  /'
  PENDING_LINE="$(printf '%s\n' "$DOCTOR_OUT" | grep 'THROUGHPUT' || true)"
  [ "$DOCTOR_RC" -eq 1 ] && RC=1
else
  echo "  WARN bin/task-doctor.sh is not executable, the reconciliation did not run"
fi

# ------------------------------------------------------------------ 4. throughput
echo
echo "-- 4. throughput"
echo
if [ -n "$PENDING_LINE" ]; then
  printf '%s\n' "$PENDING_LINE" | sed 's/^/  /'
else
  COUNT="$(grep -c '| pending-revision |' "$ROOT_DIR/INDEX.md" 2>/dev/null || echo 0)"
  echo "  $COUNT of 2 pending-revision slots used (counted from INDEX.md)"
fi
echo "  At two, the platform blocks a new claim until one clears."

# --------------------------------------------------------------- 5. the task brief
echo
if [ -z "$TASK_DIR" ]; then
  echo "-- 5. task brief"
  echo
  echo "  no task named. Re-run as: bin/session-start.sh tasks/<name>"
  echo
  echo "$([ "$RC" -eq 0 ] && echo "nothing needs attention" || echo "see the FAIL lines above")"
  exit "$RC"
fi

TASK_DIR="$(cd "$TASK_DIR" && pwd)"
NAME="$(basename "$TASK_DIR")"
echo "-- 5. task brief: $NAME"
echo

if [ -f "$TASK_DIR/task.state.json" ]; then
  STATE="$TASK_DIR/task.state.json" python3 - <<'PY' | sed 's/^/  /'
import json, os
d = json.load(open(os.environ["STATE"], encoding="utf-8"))
for key in ("verdict", "status", "rounds", "blocking", "next_action"):
    if key in d:
        print("%-12s %s" % (key, d[key]))
PY
else
  echo "  no task.state.json - status read from INDEX.md instead"
  grep -F "$NAME" "$ROOT_DIR/INDEX.md" 2>/dev/null | head -1 | sed 's/^/  /' || true
fi

echo
echo "  applicable learning notes:"
QUERY="$ROOT_DIR/bin/learning-query.sh"
if [ -x "$QUERY" ]; then
  set +e
  "$QUERY" --task "$TASK_DIR" 2>&1 | sed 's/^/    /'
  Q_RC=${PIPESTATUS[0]}
  set -e
  [ "$Q_RC" -eq 2 ] && { echo "    WARN a matched note is REFUTED - read learning/LEDGER.md"; RC=1; }
else
  echo "    WARN bin/learning-query.sh is not executable"
fi

echo
echo "  rounds trend:"
ROUNDS="$ROOT_DIR/bin/rounds.sh"
if [ -x "$ROUNDS" ] && [ -f "$TASK_DIR/rounds.jsonl" ]; then
  set +e
  "$ROUNDS" "$TASK_DIR" 2>&1 | sed 's/^/    /'
  R_RC=${PIPESTATUS[0]}
  set -e
  [ "$R_RC" -eq 4 ] && { echo "    FAIL TWO STRIKES - remove the dependency, do not refine the theory"; RC=1; }
elif [ ! -f "$TASK_DIR/rounds.jsonl" ]; then
  echo "    no rounds.jsonl yet, so no trend to read"
else
  echo "    WARN bin/rounds.sh is not executable"
fi

echo
echo "  last preflight:"
if [ -f "$TASK_DIR/.preflight.last" ]; then
  tail -5 "$TASK_DIR/.preflight.last" | sed 's/^/    /'
else
  echo "    none recorded. Run: bin/preflight.sh --work $TASK_DIR"
fi

echo
echo "$([ "$RC" -eq 0 ] && echo "nothing needs attention" || echo "see the FAIL lines above")"
exit "$RC"
