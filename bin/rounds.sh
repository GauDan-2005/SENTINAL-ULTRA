#!/usr/bin/env bash
# rounds.sh - the round-over-round trend, and the two-strikes rule fired mechanically.
#
# learning/diagnosing-platform-only-failures.md: 13 of 16 invalid, then 16 of 16, then 15 of
# 16, across three locally-verified fixes to three real defects, none of which was the defect.
# That is a flat line, the signal was free from round 4, and nobody read it. This reads it.
#
# Usage:
#   bin/rounds.sh <task-dir>                     render the trend and apply the rule
#   bin/rounds.sh --file <rounds.jsonl>          same, against an explicit ledger
#   bin/rounds.sh <task-dir> --through 4         evaluate as of round 4 (what did we know then)
#   bin/rounds.sh --schema                       print the rounds.jsonl schema
#   bin/rounds.sh --example                      print the worked kvdex backfill on stdout
#   bin/rounds.sh <task-dir> --append '<json>'   validate and append one round record
#
# The ledger lives at <task-dir>/rounds.jsonl, one JSON object per upload round.
#
# Exit: 0 trend clean, 1 the ledger is malformed or a record failed validation,
#       2 no ledger found, 3 misuse, 4 TWO STRIKES - the same check failed twice running.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TASK_DIR=""; FILE=""; THROUGH=""; APPEND=""; MODE="report"
while [ $# -gt 0 ]; do
  case "$1" in
    --file)     FILE="${2:-}"; shift 2 ;;
    --through)  THROUGH="${2:-}"; shift 2 ;;
    --append)   APPEND="${2:-}"; MODE="append"; shift 2 ;;
    --schema)   MODE="schema"; shift ;;
    --example)  MODE="example"; shift ;;
    -h|--help)  sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)         echo "SKIP unknown argument: $1" >&2; exit 3 ;;
    *)          TASK_DIR="$1"; shift ;;
  esac
done

if [ "$MODE" = "schema" ]; then
cat <<'SCHEMA'
# rounds.jsonl - one JSON object per upload round, appended after each platform result.
# Lives at <task-dir>/rounds.jsonl. Newline-delimited JSON, never rewritten in place.
#
# Required: round (int, 1-based), date (YYYY-MM-DD), fix_applied (string - what this round
# CHANGED, not what it kept). Everything else is optional but a missing check reads as
# "not run", never as "passed".
{
  "round": 3,
  "date": "2026-08-01",
  "zip_sha256": "<sha256 of the uploaded zip>",
  "zip_entries": 309,
  "checks": {
    "static":           "PASS",              // PASS | FAIL | not-run
    "prescriptiveness": {"score": 0.25, "findings": 4, "result": "FAIL"},
    "difficulty":       {"valid_trials": 3, "total": 16, "pass_rate": "1/3",
                         "checks_run": 2, "checks_remaining": 2,
                         "error": "tests.patch did not apply"},
    "oracle":           {"passed": 3, "of": 3},
    "quality":          {"criteria_pass": 15, "of": 15, "failed_ids": []}
  },
  "fix_applied": "restore the test tree with git checkout before applying tests.patch",
  "hypothesis":  "the agent edits the visible tests, so tests.patch conflicts",
  "local_matrix": {"nop": "0", "oracle": "1", "hostile": "0", "agent_edited": "1"},
  "outcome": "INCOMPLETE - difficulty check returned 13 of 16 trials invalid"
}
#
# How each check is read as failing:
#   static            != PASS
#   prescriptiveness  never a strike - it is a non-blocking build-phase score. Displayed only.
#   difficulty        valid_trials < total, or an error string present
#   oracle            passed < of  (the platform runs the oracle 3 times and needs 3 of 3)
#   quality           criteria_pass < of, or failed_ids non-empty
#
# THE DIFFICULTY BUDGET: checks_run and checks_remaining are the two read-only fields the
# platform added on 2026-08-14 (docs/faq.md, "Difficulty checks are now capped"). Copy them off
# the live submission every round, because nothing else records them and they cannot be
# reconstructed later. Four difficulty checks that RUN AND RETURN A RESULT exhaust the budget
# and the platform then sets the verdict to Invalid Difficulty itself. Both keys are optional
# and a missing one reads as unknown, never as a full budget. A reviewer sending the task back
# resets the count to zero, so checks_run can legitimately go DOWN between rounds.
#
# TWO STRIKES: the same check fails in two consecutive rounds whose fix_applied differ. That
# means two different locally-verified fixes both missed, so the model of the environment is
# wrong. Remove the dependency instead of refining the theory. With the budget at four, two
# strikes now costs half of it, which is the argument for measuring a lever before spending a
# check on it rather than after.
SCHEMA
exit 0
fi

if [ "$MODE" = "example" ]; then
cat <<'EXAMPLE'
{"round":1,"date":"2026-07-31","fix_applied":"first fixed bundle: instruction rewrite, tests.patch regenerated, 22 fail_to_pass","hypothesis":"the shipped bundle's defects are the instruction and the thin graded set","checks":{"static":"FAIL"},"outcome":"static check rejected fail_to_pass 22, outside the hard 10 to 20 range"}
{"round":2,"date":"2026-07-31","fix_applied":"fail_to_pass cut from 22 to 20 by regrouping cases as sub-steps","hypothesis":"the count is the only static blocker","checks":{"static":"PASS","prescriptiveness":{"score":0.25,"findings":4,"result":"FAIL"}},"outcome":"static passed, prescriptiveness scored 0.25 with 4 findings"}
{"round":3,"date":"2026-08-01","fix_applied":"instruction rewritten against the prescriptiveness findings","hypothesis":"the remaining blocker is instruction wording","checks":{"static":"PASS","prescriptiveness":{"score":0.75,"result":"PASS"},"difficulty":{"valid_trials":3,"total":16,"error":"tests.patch did not apply"},"oracle":{"passed":3,"of":3},"quality":{"criteria_pass":15,"of":15,"failed_ids":[]}},"local_matrix":{"nop":"0","oracle":"1"},"outcome":"difficulty INCOMPLETE, 13 of 16 trials invalid"}
{"round":4,"date":"2026-08-02","fix_applied":"test.sh restores the test tree with git checkout -- tests/ plus git clean","hypothesis":"the agent edits the visible tests, so restoring them before applying tests.patch fixes it","checks":{"static":"PASS","difficulty":{"valid_trials":0,"total":16,"error":"tests.patch did not apply"},"oracle":{"passed":3,"of":3}},"local_matrix":{"nop":"0","oracle":"1","agent_edited":"1"},"outcome":"worse - 16 of 16 trials invalid"}
{"round":5,"date":"2026-08-03","fix_applied":"test.sh does rm -rf tests then git checkout <base sha> -- tests","hypothesis":"git checkout reads the index, so a staged edit defeats it - restore from the base commit instead","checks":{"static":"PASS","difficulty":{"valid_trials":1,"total":16,"error":"tests.patch did not apply"},"oracle":{"passed":3,"of":3}},"local_matrix":{"nop":"0","oracle":"1","agent_edited":"1","collision":"1"},"outcome":"15 of 16 trials invalid - the same band for the third round running"}
{"round":6,"date":"2026-08-04","fix_applied":"test.sh restores from a base64 tarball of the base test tree embedded in test.sh, no git at all","hypothesis":"the verify-time workspace is not a git repository, so remove the git dependency rather than refine it","checks":{"static":"PASS","prescriptiveness":{"score":0.75,"result":"PASS"},"difficulty":{"valid_trials":16,"total":16},"oracle":{"passed":3,"of":3},"quality":{"criteria_pass":15,"of":15,"failed_ids":[]}},"local_matrix":{"nop":"0","oracle":"1","hostile":"0","agent_edited":"1","collision":"1"},"outcome":"passed, accepted"}
EXAMPLE
exit 0
fi

# ---- locate the ledger ---------------------------------------------------------------------
if [ -z "$FILE" ]; then
  if [ -z "$TASK_DIR" ]; then
    echo "SKIP usage: bin/rounds.sh <task-dir> | --file <rounds.jsonl> | --schema | --example" >&2
    exit 3
  fi
  if [ -f "$TASK_DIR/rounds.jsonl" ]; then FILE="$TASK_DIR/rounds.jsonl"
  elif [ -f "$TASK_DIR" ];             then FILE="$TASK_DIR"
  else
    echo "SKIP no rounds.jsonl at $TASK_DIR/rounds.jsonl"
    echo "SKIP     seed it with:  bin/rounds.sh --schema"
    exit 2
  fi
fi

if [ "$MODE" = "append" ]; then
  export RS_APPEND="$APPEND" RS_FILE="$FILE"
  python3 - <<'PY' || exit 1
import json, os, sys
rec = os.environ["RS_APPEND"]
try:
    obj = json.loads(rec)
except Exception as exc:
    print(f"FAIL record is not valid JSON: {exc}"); sys.exit(1)
missing = [k for k in ("round", "date", "fix_applied") if not obj.get(k)]
if missing:
    print(f"FAIL record is missing required fields: {', '.join(missing)}"); sys.exit(1)
path = os.environ["RS_FILE"]
existing = []
if os.path.isfile(path):
    existing = [json.loads(l) for l in open(path, encoding="utf-8") if l.strip()]
if any(int(e.get("round", -1)) == int(obj["round"]) for e in existing):
    print(f"FAIL round {obj['round']} is already in the ledger"); sys.exit(1)
with open(path, "a", encoding="utf-8") as fh:
    fh.write(json.dumps(obj, separators=(",", ":")) + "\n")
print(f"PASS appended round {obj['round']} to {path}")
PY
  exit 0
fi

export RS_FILE="$FILE" RS_THROUGH="${THROUGH:-}"

python3 - <<'PY'
import json, os, sys

path    = os.environ["RS_FILE"]
through = os.environ.get("RS_THROUGH") or ""

rounds, bad = [], []
for n, line in enumerate(open(path, encoding="utf-8"), 1):
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    try:
        rounds.append(json.loads(line))
    except Exception as exc:
        bad.append((n, str(exc)))

if bad:
    for n, exc in bad:
        print(f"FAIL {path}:{n} is not valid JSON: {exc}")
    sys.exit(1)
if not rounds:
    print(f"SKIP {path} has no round records")
    sys.exit(2)

rounds.sort(key=lambda r: int(r.get("round", 0)))
if through:
    rounds = [r for r in rounds if int(r.get("round", 0)) <= int(through)]
    if not rounds:
        print(f"SKIP no rounds at or before {through}")
        sys.exit(2)

CHECKS = ["static", "prescriptiveness", "difficulty", "oracle", "quality"]

def cell(r, name):
    c = (r.get("checks") or {}).get(name)
    if c is None:
        return "-"
    if name == "static":
        return str(c)
    if name == "prescriptiveness":
        if isinstance(c, dict):
            return f"{c.get('score', '?')}"
        return str(c)
    if name == "difficulty":
        if isinstance(c, dict):
            # the platform's own budget, added 2026-08-14. Optional, and shown whenever it was
            # recorded, because a round with one check left is not the same round as a round
            # with four however the trials came out.
            # kept short on purpose: the trend table pads its cells to a fixed width, so a
            # longer suffix silently pushes every column out of alignment.
            run, left = c.get("checks_run"), c.get("checks_remaining")
            budget = ""
            if run is not None:
                budget = " [{}/4]".format(run)
            elif left is not None:
                budget = " [{}left]".format(left)
            v, t = c.get("valid_trials"), c.get("total")
            if v is None or t is None:
                return str(c) if not budget else str(c) + budget
            return f"{int(t) - int(v)}/{t} inv" + budget
        return str(c)
    if name == "oracle":
        if isinstance(c, dict):
            return f"{c.get('passed', '?')}/{c.get('of', 3)}"
        return str(c)
    if name == "quality":
        if isinstance(c, dict):
            fid = c.get("failed_ids") or []
            s = f"{c.get('criteria_pass', '?')}/{c.get('of', 15)}"
            return s + (f" {','.join(map(str, fid))}" if fid else "")
        return str(c)
    return str(c)

def failed(r, name):
    """True = this check failed this round. Missing reads as not-run, never as passed."""
    c = (r.get("checks") or {}).get(name)
    if c is None:
        return None
    if name == "static":
        return str(c).upper() != "PASS"
    if name == "prescriptiveness":
        return False                    # non-blocking build-phase score, never a strike
    if name == "difficulty":
        if not isinstance(c, dict):
            return str(c).upper() != "PASS"
        if c.get("error"):
            return True
        v, t = c.get("valid_trials"), c.get("total")
        return None if v is None or t is None else int(v) < int(t)
    if name == "oracle":
        if not isinstance(c, dict):
            return str(c).upper() != "PASS"
        p, of = c.get("passed"), c.get("of", 3)
        return None if p is None else int(p) < int(of)
    if name == "quality":
        if not isinstance(c, dict):
            return str(c).upper() != "PASS"
        if c.get("failed_ids"):
            return True
        p, of = c.get("criteria_pass"), c.get("of", 15)
        return None if p is None else int(p) < int(of)
    return None

# ---- the trend table, one column per round -------------------------------------------------
cols = [str(r.get("round", "?")) for r in rounds]
w    = max(16, *(len(c) for c in cols))
def row(label, values):
    return f"  {label:<18}" + "".join(f"| {v:<{w}}" for v in values)

print(f"# round-over-round trend  ({path})")
print()
print(row("round", cols))
print(row("date", [str(r.get("date", "-")) for r in rounds]))
print("  " + "-" * (18 + (w + 2) * len(cols)))
for name in CHECKS:
    print(row(name, [cell(r, name) for r in rounds]))
print()
for r in rounds:
    print(f"  round {r.get('round')}: fix   {r.get('fix_applied', '(none recorded)')}")
    if r.get("hypothesis"):
        print(f"           hypo  {r['hypothesis']}")
    if r.get("outcome"):
        print(f"           out   {r['outcome']}")

# ---- two strikes ---------------------------------------------------------------------------
strikes = []
for name in CHECKS:
    run = []                                   # consecutive failing rounds, ending at the last
    for r in rounds:
        f = failed(r, name)
        if f:
            run.append(r)
        elif f is False:
            run = []
        # None (not run) neither extends nor breaks the run
    if len(run) >= 2 and run[-1] is rounds[-1]:
        fixes = [str(r.get("fix_applied", "")) for r in run]
        if len(set(fixes)) >= 2:
            strikes.append((name, run))

print()
if not strikes:
    latest = rounds[-1]
    live = [n for n in CHECKS if failed(latest, n)]
    if live:
        print(f"WARN round {latest.get('round')} still failing: {', '.join(live)} (strike 1)")
    else:
        print(f"PASS round {latest.get('round')} shows no failing check")
    print(f"{len(rounds)} rounds recorded")
    sys.exit(0)

print("=" * 78)
for name, run in strikes:
    nums = ", ".join(str(r.get("round")) for r in run)
    vals = " -> ".join(cell(r, name) for r in run)
    print(f"!! TWO STRIKES on {name}: failed in rounds {nums} under different fixes")
    print(f"   trend: {vals}")
    for r in run:
        print(f"     round {r.get('round')}: {r.get('fix_applied')}")
print()
print("A flat line across two different locally-verified fixes means neither fix touched the")
print("cause. A local reproduction proves a condition is SUFFICIENT to produce the symptom,")
print("never that it is the one the platform is applying, so a third variation is the same")
print("trap wearing a new hat.")
print()
print("MANDATED: stop refining the theory. REMOVE THE DEPENDENCY the fixes keep addressing,")
print("and anchor to something whose presence is implied by your code running at all.")
print("See learning/diagnosing-platform-only-failures.md.")
print("=" * 78)
sys.exit(4)
PY
