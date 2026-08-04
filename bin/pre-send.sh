#!/usr/bin/env bash
# pre-send.sh - the single command that must exit 0 before Send to reviewer is checked.
#
# The send conditions are scattered across CLAUDE.md Step 7, Section 4 and Section 10, and some
# of them the workspace barely records - the Oracle 3 of 3 bar among them. There is no one
# command that says yes or no, so Send gets checked from memory of which gates were green, on a
# form where a wrong answer costs a revision slot.
#
# Gates, in order:
#   1  bin/preflight.sh --zip <task-dir>            exits 0
#   2  the latest rounds.jsonl record               static PASS, oracle 3 of 3, quality all
#                                                   must-have criteria, difficulty 0 invalid
#   3  bin/rounds.sh <task-dir>                     does not exit 4 (two strikes)
#   4  bin/checks/60-answers.sh <task-dir>          exits 0
#   5  answers/submission_answer.txt                newer than the zip it describes
#   6  task.state.json                              status is checks-green
#   7  task.md                                      a humanizer pass recorded for this round
#
# A gate whose tool is missing BLOCKS. Not being able to check something is not the same as it
# passing. If you mean to send anyway, name the gate with --without and declare it in Comments
# for Reviewer - that is what exit 2 means.
#
# Usage:
#   bin/pre-send.sh <task-dir>
#   bin/pre-send.sh <task-dir> --without preflight,answers
#
# Exit: 0 GO, 1 NO-GO with the blocking item named, 2 GO WITH DECLARATIONS, 3 misuse.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TASK_ARG=""; WITHOUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --without) WITHOUT="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        echo "SKIP unknown argument: $1" >&2; exit 3 ;;
    *)         TASK_ARG="$1"; shift ;;
  esac
done
[ -n "$TASK_ARG" ] || { echo "SKIP usage: bin/pre-send.sh <task-dir>" >&2; exit 3; }
TASK_DIR="$(cd "$TASK_ARG" 2>/dev/null && pwd || true)"
[ -n "$TASK_DIR" ] || { echo "SKIP no such directory: $TASK_ARG" >&2; exit 3; }
TASK_NAME="$(basename "$TASK_DIR")"

waived() {   # waived <name>
  case ",$WITHOUT," in *",$1,"*) return 0 ;; esac
  return 1
}

BLOCKERS=(); DECLARATIONS=(); LINES=()
gate() {   # gate <status> <name> <message>
  local st="$1" name="$2" msg="$3"
  LINES+=("$(printf '  [%s] %-12s %s' "$st" "$name" "$msg")")
  case "$st" in
    x) ;;
    "!") BLOCKERS+=("$name: $msg") ;;
    "~") DECLARATIONS+=("$name: $msg") ;;   # quoted: an unquoted ~ tilde-expands in a case pattern
  esac
}

echo "# pre-send  $TASK_NAME"

# ---- the zip under test -------------------------------------------------------------------------
shopt -s nullglob; ZIPS=("$TASK_DIR/upload/"*.zip); shopt -u nullglob
ZIP=""
if [ ${#ZIPS[@]} -gt 0 ]; then
  ZIP="${ZIPS[0]}"
  for z in "${ZIPS[@]}"; do [ "$z" -nt "$ZIP" ] && ZIP="$z"; done
fi

# 1 - preflight ------------------------------------------------------------------------------------
if waived preflight; then
  gate "~" preflight "waived with --without"
elif [ ! -x "$ROOT/bin/preflight.sh" ]; then
  gate "!" preflight "bin/preflight.sh is not present, so the bundle is unverified"
elif [ -z "$ZIP" ]; then
  gate "!" preflight "no zip under $TASK_DIR/upload/ - there is nothing to send"
else
  if "$ROOT/bin/preflight.sh" --zip "$TASK_DIR" > /tmp/pre-send-preflight.$$ 2>&1; then
    gate x preflight "exit 0 against the zip"
  else
    rc=$?
    if [ "$rc" = "2" ]; then
      gate "~" preflight "exit 2, warnings only (declare them)"
    else
      gate "!" preflight "exit $rc - see /tmp/pre-send-preflight.$$"
    fi
  fi
fi

# 2 and 3 - the round record -------------------------------------------------------------------------
LEDGER="$TASK_DIR/rounds.jsonl"
if waived rounds; then
  gate "~" rounds "waived with --without"
elif [ ! -f "$LEDGER" ]; then
  # Bootstrap, not a defect: the round ledger was introduced 2026-08-04 and a task
  # claimed before that has none. Declare it so the gate stays usable on existing
  # tasks. Once the file exists, every check below it is blocking again.
  gate "~" rounds "no rounds.jsonl yet - seed it with bin/rounds.sh; blocking once it exists"
else
  set +e
  ROUNDS_OUT="$("$ROOT/bin/rounds.sh" "$TASK_DIR" 2>&1)"; ROUNDS_RC=$?
  set -e
  if [ "$ROUNDS_RC" = "4" ]; then
    gate "!" two-strikes "the same check failed twice under different fixes - remove the dependency"
  else
    gate x two-strikes "no repeated failure under different fixes"
  fi
  CHECKS="$(python3 - "$LEDGER" <<'PY'
import json, sys
rounds = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
if not rounds:
    print("!|no round records"); raise SystemExit
r = max(rounds, key=lambda x: int(x.get("round", 0)))
c = r.get("checks") or {}
bad = []
if str(c.get("static", "")).upper() != "PASS":
    bad.append(f"static={c.get('static', 'not run')}")
o = c.get("oracle") or {}
if not (isinstance(o, dict) and int(o.get("passed", -1)) >= int(o.get("of", 3))):
    bad.append(f"oracle={o or 'not run'} (the platform runs it 3 times and needs 3 of 3)")
d = c.get("difficulty") or {}
if not isinstance(d, dict) or d.get("error") or d.get("valid_trials") is None \
   or int(d["valid_trials"]) < int(d.get("total", 0)):
    bad.append(f"difficulty={d or 'not run'} (zero invalid trials required)")
q = c.get("quality") or {}
if not isinstance(q, dict) or (q.get("failed_ids") or []) or \
   q.get("criteria_pass") is None or int(q["criteria_pass"]) < int(q.get("of", 15)):
    bad.append(f"quality={q or 'not run'}")
print(("!|round " + str(r.get("round")) + ": " + "; ".join(bad)) if bad
      else ("x|round " + str(r.get("round")) + " is green on static, difficulty, oracle 3 of 3 and quality"))
PY
)"
  gate "${CHECKS%%|*}" checks "${CHECKS#*|}"
fi

# 4 - the answers lint ---------------------------------------------------------------------------------
ANSWERS="$TASK_DIR/answers/submission_answer.txt"
if waived answers; then
  gate "~" answers "waived with --without"
elif [ ! -x "$ROOT/bin/checks/60-answers.sh" ]; then
  gate "!" answers "bin/checks/60-answers.sh is not present, so the form answers are unchecked"
elif [ ! -f "$ANSWERS" ]; then
  gate "!" answers "no answers/submission_answer.txt"
else
  set +e
  "$ROOT/bin/checks/60-answers.sh" "$TASK_DIR" > /tmp/pre-send-answers.$$ 2>&1; ARC=$?
  set -e
  case "$ARC" in
    0) gate x answers "exit 0" ;;
    2) gate "~" answers "exit 2, warnings only (declare them)" ;;
    *) gate "!" answers "exit $ARC - see /tmp/pre-send-answers.$$" ;;
  esac
fi

# 5 - the answers describe THIS zip ----------------------------------------------------------------------
if waived freshness; then
  gate "~" freshness "waived with --without"
elif [ -z "$ZIP" ] || [ ! -f "$ANSWERS" ]; then
  gate "!" freshness "need both a zip and answers/submission_answer.txt to compare"
elif [ "$ANSWERS" -nt "$ZIP" ]; then
  gate x freshness "the answers file is newer than $(basename "$ZIP")"
else
  gate "!" freshness "$(basename "$ZIP") is newer than the answers file - the answers describe an older bundle"
fi

# 6 - task state ------------------------------------------------------------------------------------------
STATE="$TASK_DIR/task.state.json"
if waived state; then
  gate "~" state "waived with --without"
elif [ ! -f "$STATE" ]; then
  # Bootstrap, same reasoning as rounds above.
  gate "~" state "no task.state.json yet - bin/new-task.sh seeds it; blocking once it exists"
else
  ST="$(python3 -c "import json,sys;print((json.load(open(sys.argv[1])) or {}).get('status',''))" "$STATE" 2>/dev/null || true)"
  if [ "$ST" = "checks-green" ]; then
    gate x state "status is checks-green"
  else
    gate "!" state "status is '${ST:-unset}', not checks-green"
  fi
fi

# 7 - the humanizer pass for THIS round ---------------------------------------------------------------------
TASKMD="$TASK_DIR/task.md"
if waived humanizer; then
  gate "~" humanizer "waived with --without"
elif [ ! -f "$TASKMD" ]; then
  gate "~" humanizer "no task.md yet, so no record of a humanizer pass"
elif grep -qi "humaniz" "$TASKMD"; then
  LASTROUND="$(python3 - "$TASK_DIR" <<'PY'
import json, os, sys
p = os.path.join(sys.argv[1], "rounds.jsonl")
try:
    rounds = [json.loads(l) for l in open(p, encoding="utf-8") if l.strip()]
    print(max(int(r.get("round", 0)) for r in rounds))
except Exception:
    print("")
PY
)"
  if [ -n "$LASTROUND" ] && ! grep -qiE "humaniz.*(round )?$LASTROUND|(round )?$LASTROUND.*humaniz" "$TASKMD"; then
    gate "~" humanizer "task.md records a humanizer pass, but not one tied to round $LASTROUND"
  else
    gate x humanizer "a humanizer pass is recorded"
  fi
elif [ -f "$LEDGER" ]; then
  gate "!" humanizer "task.md records no humanizer pass over the answers"
else
  # Task predates the round ledger, so it predates the recording convention too.
  gate "~" humanizer "task.md records no humanizer pass - blocking once rounds.jsonl exists"
fi

# ---- the rendered checklist -----------------------------------------------------------------------------
echo
echo "Send to reviewer - go/no-go"
echo
for l in "${LINES[@]}"; do echo "$l"; done
echo
echo "  legend: [x] verified   [!] blocking   [~] declared"
echo
if [ ${#BLOCKERS[@]} -gt 0 ]; then
  echo "NO-GO. ${#BLOCKERS[@]} blocking item(s):"
  for b in "${BLOCKERS[@]}"; do echo "  - $b"; done
  echo
  echo "Checking Send with a failing gate always comes back as revision. If you are sending"
  echo "anyway, waive the gate explicitly with --without and say why in Comments for Reviewer."
  exit 1
fi
if [ ${#DECLARATIONS[@]} -gt 0 ]; then
  echo "GO WITH DECLARATIONS. Put each of these in Comments for Reviewer:"
  for d in "${DECLARATIONS[@]}"; do echo "  - $d"; done
  exit 2
fi
echo "GO. Every gate verified against the zip in upload/."
exit 0
