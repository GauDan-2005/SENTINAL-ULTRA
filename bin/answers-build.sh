#!/usr/bin/env bash
# answers-build.sh - generate submission_answer.txt from structured data.
#
# The form arithmetic is the most mechanical thing on the submission and it has been got
# wrong (jqno shipped 205 against a real 220). The checkbox blocks are hand-typed and have
# collapsed into a comma-joined line. Both classes disappear if the file is rendered.
#
# Usage:
#   bin/answers-build.sh <task-dir>              read <task-dir>/answers/answers.yml
#   bin/answers-build.sh --in <answers.yml>      read an explicit file
#   bin/answers-build.sh <task-dir> -o <file>    write instead of printing
#   bin/answers-build.sh --schema                print the answers.yml schema
#   bin/answers-build.sh --example               print a worked answers.yml (kvdex, accepted)
#   bin/answers-build.sh <task-dir> --lint       validate only, render nothing
#
# What it enforces, none of which is negotiable at render time:
#   total = review + rewrite + form, computed here. A hand-entered total that disagrees is a
#     hard failure rather than a silent overwrite.
#   the four where-issue and seven what-issue platform strings, verbatim, every option
#     rendered with [x] or [ ] so a block is always 4 lines and 7 lines.
#   every checked what-issue has a numbered issue block, and every block a checked box.
#   Files Changed renders as a NUMBERED LIST. The platform field is plain text and a markdown
#     table pastes as pipes.
#   prose is emitted UNWRAPPED, one paragraph per line, however long it runs.
#   no em dash anywhere in free text. Bare count, no exclusions (CLAUDE.md Section 5).
#
# Exit: 0 rendered, 1 a validation failure (nothing is written), 2 cannot run, 3 misuse.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

IN=""; OUT=""; TASK_DIR=""; MODE="render"
while [ $# -gt 0 ]; do
  case "$1" in
    --in)      IN="${2:-}"; shift 2 ;;
    -o|--out)  OUT="${2:-}"; shift 2 ;;
    --schema)  MODE="schema"; shift ;;
    --example) MODE="example"; shift ;;
    --lint)    MODE="lint"; shift ;;
    -h|--help) sed -n '2,29p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        echo "SKIP unknown argument: $1" >&2; exit 3 ;;
    *)         TASK_DIR="$1"; shift ;;
  esac
done

if [ "$MODE" = "schema" ]; then
cat <<'SCHEMA'
# answers/answers.yml - the structured source for submission_answer.txt.
# Render with: bin/answers-build.sh <task-dir> -o answers/submission_answer.txt
#
# Prose fields are written as ordinary YAML block scalars. Wrapping here is fine: the
# renderer joins each paragraph back into one unwrapped line, which is what the platform
# text fields need. A blank line starts a new paragraph. A line starting with "- " stays on
# its own line so Comments for Reviewer can list points.

task: 20260719_045042__oliver-oloughlin_kvdex__245
verdict: fixable                 # fixable | valid-as-is | invalid

# ---- Path B only -----------------------------------------------------------------------
where_issues:                    # all four keys required, true or false
  instructions: true
  tests: true
  oracle: true
  environment: true

what_issues:                     # all seven keys required, true or false
  requirements_not_tested: true          # Every requirement in the instructions is not properly tested
  tests_not_specified: true              # All test requirements are not properly specified in the instructions
  llm_generated: true                    # The instructions appear LLM generated
  overly_prescriptive: true              # The instructions are overly-prescriptive
  leaks_solution: false                  # The task leaks solution information
  oracle_mismatch: false                 # The oracle does not implement the solution following the instructions
  under_ten_f2p: false                   # Less than 10 fail-to-pass tests in the test suite

issues:                          # one block per checked what_issue, same key
  - category: tests_not_specified
    detail: |
      What is wrong, with file paths and line numbers. Code examples are exempt from the
      style rules and may be indented under this field.
    fixable: true
    how: |
      What was actually done about it.

files_changed:                   # rendered as a numbered list, never a table
  - path: tests/tests.patch
    changed: regenerated against the base commit
    why: the shipped patch deleted tests/test.deps.ts and moved 117 files onto bare specifiers

pr_additions: "NA"               # or how the PR scope was expanded. "NA" when untouched.

post_fix_confirmations:          # Path B, all eight required and all must be true
  requirements_tested: true
  requirements_specified: true
  not_llm: true
  not_prescriptive: true
  no_leakage: true
  oracle_follows_instructions: true
  pr_unmodified: true
  more_than_ten_f2p: true

# ---- Path A only -----------------------------------------------------------------------
compliance:                      # the seven Valid as-is boxes, all must be true
  requirements_tested: true
  requirements_specified: true
  not_llm: true
  not_prescriptive: true
  no_leakage: true
  oracle_follows_instructions: true
  more_than_ten_f2p: true
local_run: "oracle 1.0, NOP 0.0, run 2026-08-04 in the task image"

# ---- Path C only -----------------------------------------------------------------------
invalid_issues: []               # e.g. ["PR scope needs to be changed or reduced"]
environment_issues: []           # e.g. ["Image/Dependency Build Failures"]
unfixable_reasons: []            # list of strings, rendered numbered

# ---- all paths ---------------------------------------------------------------------------
f2p_count: 20                    # must land in 10..20, the hard static-check range
difficulty: |
  What makes this task difficult, grounded in named files and tests.
senior_estimate: "40+ minutes"   # <10 minutes | 10-20 minutes | 20-40 minutes | 40+ minutes
comments: |
  Comments for Reviewer. On a revision round say which round it is, what changed, what you
  deliberately did not change and why, and the fresh oracle and NOP numbers.

times:                           # minutes, from the user, never invented
  review: 90                     # Step 2 to 4, the analysis and the verdict
  rewrite: 150                   # the Step 5 edits before the FIRST upload. 0 on Path A and C
  form: 20                       # filling in the rest of the form
  revisions: 195                 # post-first-upload rounds only, NEVER part of the total
# total is computed as review + rewrite + form. Setting it here is allowed only as a
# cross-check: a value that disagrees with the sum is a hard failure.
SCHEMA
exit 0
fi

if [ "$MODE" = "example" ]; then
cat <<'EXAMPLE'
task: 20260719_045042__oliver-oloughlin_kvdex__245
verdict: fixable
where_issues:
  instructions: true
  tests: true
  oracle: true
  environment: true
what_issues:
  requirements_not_tested: true
  tests_not_specified: true
  llm_generated: true
  overly_prescriptive: true
  leaks_solution: false
  oracle_mismatch: false
  under_ten_f2p: false
issues:
  - category: tests_not_specified
    detail: |
      The shipped tests/tests.patch deleted tests/test.deps.ts and moved 117 test files onto
      bare specifiers. A bare specifier only resolves if deno.json carries an imports map, and
      the only place that map shows up is solution/golden.patch. instruction.md never asks for
      it, so an engineer who built the encoder exactly as the instruction describes still
      scored 0 out of 16.
    fixable: true
    how: |
      I regenerated tests/tests.patch so the test tree keeps tests/test.deps.ts and its
      original imports. No test depends on a deno.json change now. The same rewrite dropped
      modified pre-existing test files from 157 to 40.
  - category: requirements_not_tested
    detail: |
      v8Encoder had zero references anywhere in the test tree, so an agent could skip that
      factory outright and still score 1.0. tests/config.json also shipped pass_to_pass empty
      with allow_extra_failures true, which left 16 of 148 tests gating the reward.
    fixable: true
    how: |
      I added four top-level tests in tests/ext/encoder.test.ts, filled pass_to_pass with 112
      deterministic tests and set allow_extra_failures false. Fail-to-pass went from 16 to 20
      and graded tests from 16 to 132.
  - category: llm_generated
    detail: |
      The instruction was assembled from bolded spec labels like Summary., Source state. and
      Observable behavior required., and line 9 described a module tree that does not exist yet
      in the present tense.
    fixable: true
    how: |
      Rewritten as a maintainer ticket, with the false premise about serializer injection
      removed.
  - category: overly_prescriptive
    detail: |
      The old text named the internal file each piece of code lives in today, which the
      prescriptiveness check flags under its Rule 2.
    fixable: true
    how: |
      Cut the internal paths and kept the public surface the graded tests call by name.
files_changed:
  - path: instruction.md
    changed: rewritten as a maintainer ticket and narrowed to what the PR actually does
    why: read as generated documentation and over-promised behaviour the PR never adds
  - path: environment/problem_statement.md
    changed: re-copied from instruction.md
    why: the two must be byte-identical
  - path: tests/tests.patch
    changed: regenerated against the base commit, 45 files instead of 158
    why: the shipped patch made every graded test depend on a deno.json change the instruction never asks for
  - path: tests/config.json
    changed: fail_to_pass 20, pass_to_pass 112, allow_extra_failures false
    why: 16 of 148 tests gated the reward and the field was already present in the config
  - path: tests/test.sh
    changed: restores the base test tree from an embedded base64 payload, grader gates on raw_exit_code
    why: three git-based restores never worked on the platform, and the stock grader is fail-open
  - path: solution/solve.sh
    changed: forward-only and idempotent, mode 755
    why: the reverse-apply fallback inverted the tree on a second oracle run
  - path: task.toml
    changed: verifier timeout 900, agent timeout 7200, difficulty_explanation added
    why: 3 of 8 trials hit the old agent ceiling and the oracle needs 138 s
pr_additions: "NA"
post_fix_confirmations:
  requirements_tested: true
  requirements_specified: true
  not_llm: true
  not_prescriptive: true
  no_leakage: true
  oracle_follows_instructions: true
  pr_unmodified: true
  more_than_ten_f2p: true
f2p_count: 20
difficulty: |
  The agent has to design an Encoder, Serializer and Compressor contract from scratch, build
  the src/ext/encoding tree with three sub-encoders and their barrels, rewrite every
  serializer call site in src/collection.ts to encode then compress on write and decompress
  then decode on read, and switch the kvdex() factory to a single options object. Every KV
  value type still has to round-trip. Touching part of that surface leaves the suite red, and
  the custom-encoder test uses a compressor that is its own inverse, so a collection that
  skips decompress before deserialize cannot read the value back.
senior_estimate: "40+ minutes"
comments: |
  Fixable throughout and the PR scope was never touched.

  Local runs on the exact bundle in upload/, airgapped in the task image at cpus 4 and 8 GB. NOP reward 0 with raw_exit_code 1 and no f2p passing at base. Oracle reward 1, 132 of 132 required, 152 pass and 0 fail, 138 s of the 900 s verifier timeout.

  I left .vscode/settings.json in place because it is tracked upstream at the base commit and removing it means editing tracked repo files.

  model_difficulty reads medium against difficulty hard. Both are legacy fields and the FAQ says to escalate that conflict rather than tune it, so I left them and am flagging it here.
times:
  review: 90
  rewrite: 150
  form: 20
  revisions: 195
EXAMPLE
exit 0
fi

# ---- locate the input ----------------------------------------------------------------------
if [ -z "$IN" ]; then
  if [ -z "$TASK_DIR" ]; then
    echo "SKIP usage: bin/answers-build.sh <task-dir> | --in <answers.yml> | --schema | --example" >&2
    exit 3
  fi
  for c in "$TASK_DIR/answers/answers.yml" "$TASK_DIR/answers.yml" "$TASK_DIR"; do
    if [ -f "$c" ]; then IN="$c"; break; fi
  done
fi
if [ -z "$IN" ] || [ ! -f "$IN" ]; then
  echo "SKIP no answers.yml found (looked under $TASK_DIR/answers/)"
  echo "SKIP     seed one with:  bin/answers-build.sh --schema > answers/answers.yml"
  exit 2
fi

if ! python3 -c "import yaml" 2>/dev/null; then
  echo "SKIP python3 yaml module not installed, cannot read answers.yml"
  exit 2
fi

export AB_IN="$IN" AB_OUT="$OUT" AB_MODE="$MODE"

python3 - <<'PY'
import os, re, sys, yaml

src   = os.environ["AB_IN"]
out   = os.environ.get("AB_OUT") or ""
mode  = os.environ.get("AB_MODE") or "render"

data = yaml.safe_load(open(src, encoding="utf-8")) or {}
errors, warns = [], []

WHERE = [
    ("instructions", "Instructions"),
    ("tests",        "Tests"),
    ("oracle",       "Oracle Solution"),
    ("environment",  "Environment/Dockerfile"),
]
WHAT = [
    ("requirements_not_tested", "Every requirement in the instructions is not properly tested"),
    ("tests_not_specified",     "All test requirements are not properly specified in the instructions"),
    ("llm_generated",           "The instructions appear LLM generated"),
    ("overly_prescriptive",     "The instructions are overly-prescriptive"),
    ("leaks_solution",          "The task leaks solution information"),
    ("oracle_mismatch",         "The oracle does not implement the solution following the instructions"),
    ("under_ten_f2p",           "Less than 10 fail-to-pass tests in the test suite"),
]
POST = [
    ("requirements_tested",         "Every requirement in the instructions is properly tested"),
    ("requirements_specified",      "All test requirements are properly specified in the instructions"),
    ("not_llm",                     "The instructions do not sound like an LLM generated them"),
    ("not_prescriptive",            "The instructions are not overly-prescriptive"),
    ("no_leakage",                  "The task does not leak solution information"),
    ("oracle_follows_instructions", "The oracle implements the solution following the instructions"),
    ("pr_unmodified",               "The PR was not modified in any way beyond what is allowed by the guidelines"),
    ("more_than_ten_f2p",           "More than 10 fail-to-pass tests"),
]
COMPLY = [
    ("requirements_tested",         "Every requirement in the instructions is properly tested"),
    ("requirements_specified",      "All test requirements are properly specified in the instructions"),
    ("not_llm",                     "The instructions do not sound like an LLM generated them"),
    ("not_prescriptive",            "The instructions are not overly-prescriptive"),
    ("no_leakage",                  "The task does not leak solution information"),
    ("oracle_follows_instructions", "The oracle implements the solution following the instructions"),
    ("more_than_ten_f2p",           "Contains more than 10 fail-to-pass tests"),
]
WHAT_BY_KEY = dict(WHAT)

verdict = str(data.get("verdict", "")).strip().lower().replace("_", "-")
if verdict in ("valid", "valid-as-is", "valid as-is"):      path, verdict = "A", "valid-as-is"
elif verdict in ("fixable",):                                path = "B"
elif verdict in ("invalid", "not-fixable", "invalid-not-fixable"): path, verdict = "C", "invalid"
else:
    errors.append(f"verdict must be fixable, valid-as-is or invalid (got {data.get('verdict')!r})")
    path = None

PLACEHOLDER = re.compile(r"(?:^|\s)(TODO|TBD|FIXME|XXX|\.\.\.)(?:\s|$)|<[a-z_ ]{3,}>|\[(?:your|the )?[a-z ]+\]",
                         re.IGNORECASE)

def unwrap(text):
    """One paragraph per line, unwrapped. A blank line starts a new paragraph, a '- ' line
    keeps its own line, and a line indented four spaces or more is code and survives verbatim
    (Section 5 exempts code examples)."""
    lines, cur = [], []
    for raw in str(text).splitlines():
        s = raw.strip()
        if not s:
            if cur: lines.append(" ".join(cur)); cur = []
            elif lines and lines[-1] != "": lines.append("")
            continue
        if raw.startswith("    ") or raw.startswith("\t"):
            if cur: lines.append(" ".join(cur)); cur = []
            lines.append(raw.rstrip())
            continue
        if s.startswith("- ") or s.startswith("* "):
            if cur: lines.append(" ".join(cur)); cur = []
            lines.append(s)
            continue
        cur.append(s)
    if cur: lines.append(" ".join(cur))
    while lines and lines[-1] == "":
        lines.pop()
    return lines

def prose(field, required=True):
    raw = data.get(field)
    if raw is None or str(raw).strip() == "":
        if required:
            errors.append(f"{field} is empty")
        return ""
    text = str(raw)
    if "—" in text:
        n = text.count("—")
        errors.append(f"{field} contains {n} em dash(es) - Section 5 bans them, use a hyphen")
    if PLACEHOLDER.search(text):
        errors.append(f"{field} still contains a placeholder")
    return "\n".join(unwrap(text))

def boolmap(field, keys, required):
    m = data.get(field) or {}
    if not isinstance(m, dict):
        if required: errors.append(f"{field} must be a mapping of the exact keys")
        return {}
    missing = [k for k, _ in keys if k not in m]
    if missing and required:
        errors.append(f"{field} is missing {len(missing)} key(s): {', '.join(missing)}")
    return {k: bool(m.get(k, False)) for k, _ in keys}

def box(flag):
    return "[x]" if flag else "[ ]"

# ---- times ---------------------------------------------------------------------------------
times = data.get("times") or {}
def minutes(k, required=True):
    v = times.get(k)
    if v is None:
        if required: errors.append(f"times.{k} is missing - the handling numbers come from the user, never invented")
        return 0
    try:
        return int(v)
    except Exception:
        errors.append(f"times.{k} is not a number: {v!r}")
        return 0

review    = minutes("review")
rewrite   = minutes("rewrite", required=(path == "B"))
form      = minutes("form")
revisions = minutes("revisions", required=False)
total     = review + rewrite + form
if times.get("total") is not None:
    try:
        stated = int(times["total"])
        if stated != total:
            errors.append(f"times.total says {stated} but review + rewrite + form is {total}. "
                          f"The total is those three fields and never includes revisions.")
    except Exception:
        errors.append("times.total is not a number")
if path == "B" and rewrite == 0:
    warns.append("times.rewrite is 0 on a Fixable task - field 2 is the pre-first-upload edits")
if total and not (180 <= total <= 240):
    warns.append(f"total {total} is outside the 180 to 240 band (guidance, not a gate - the "
                 f"accepted kvdex bundle shipped 260)")
if revisions and not (60 <= revisions <= 120):
    warns.append(f"revisions {revisions} is outside the 60 to 120 band (guidance, not a gate)")

# ---- counts and cross-checks ---------------------------------------------------------------
f2p = data.get("f2p_count")
try:
    f2p = int(f2p)
except Exception:
    f2p = None
    errors.append("f2p_count is missing or not a number")
if f2p is not None and not (10 <= f2p <= 20):
    errors.append(f"f2p_count {f2p} is outside the hard 10 to 20 static-check range")

where = boolmap("where_issues", WHERE, path == "B")
what  = boolmap("what_issues",  WHAT,  path == "B")
post  = boolmap("post_fix_confirmations", POST, path == "B")
comply= boolmap("compliance", COMPLY, path == "A")

issues = data.get("issues") or []
if path == "B":
    if not issues:
        errors.append("issues is empty on a Fixable task")
    seen = []
    for i, it in enumerate(issues, 1):
        if not isinstance(it, dict):
            errors.append(f"issues[{i}] is not a mapping"); continue
        cat = str(it.get("category", "")).strip()
        if cat not in WHAT_BY_KEY:
            errors.append(f"issues[{i}].category {cat!r} is not one of the seven platform "
                          f"categories: {', '.join(WHAT_BY_KEY)}")
        else:
            seen.append(cat)
            if not what.get(cat):
                errors.append(f"issues[{i}] describes {cat} but that what_issues box is not checked")
        for f in ("detail", "how"):
            v = str(it.get(f, "") or "")
            if not v.strip():
                errors.append(f"issues[{i}].{f} is empty")
            if "—" in v:
                errors.append(f"issues[{i}].{f} contains an em dash")
            if PLACEHOLDER.search(v):
                errors.append(f"issues[{i}].{f} still contains a placeholder")
    for k, label in WHAT:
        if what.get(k) and k not in seen:
            errors.append(f"what_issues.{k} is checked but no numbered issue block describes it")
    if any(not v for v in post.values()):
        errors.append("all eight post-fix confirmations must be true for the task to count as "
                      "valid - fix the task or change the verdict")
    fc = data.get("files_changed") or []
    if not fc:
        errors.append("files_changed is empty on a Fixable task")
    for i, f in enumerate(fc, 1):
        if not isinstance(f, dict) or not f.get("path"):
            errors.append(f"files_changed[{i}] needs a path")
        for k in ("changed", "why"):
            if not str((f or {}).get(k, "")).strip():
                errors.append(f"files_changed[{i}].{k} is empty")
    if not str(data.get("pr_additions", "")).strip():
        errors.append('pr_additions is empty - write "NA" when the PR was not modified')

if path == "A":
    if any(not v for v in comply.values()):
        errors.append("every compliance box must be true for a Valid as-is verdict")
    if not str(data.get("local_run", "")).strip():
        errors.append("local_run is empty - the oracle and NOP run is the only check on a "
                      "Valid as-is task")

if path == "C":
    if not (data.get("unfixable_reasons") or []):
        errors.append("unfixable_reasons is empty - a vague explanation gets the submission rejected")

difficulty = prose("difficulty", required=(path in ("A", "B")))
comments   = prose("comments")
senior     = str(data.get("senior_estimate", "")).strip()
if not senior:
    errors.append("senior_estimate is missing")
task_name  = str(data.get("task", "")).strip()
if not task_name:
    errors.append("task is missing")

# em dash sweep over every rendered string, bare count and no exclusions
def sweep(node, where_):
    if isinstance(node, str):
        if "—" in node:
            errors.append(f"em dash in {where_}")
    elif isinstance(node, dict):
        for k, v in node.items(): sweep(v, f"{where_}.{k}")
    elif isinstance(node, list):
        for i, v in enumerate(node): sweep(v, f"{where_}[{i}]")
sweep(data, "answers.yml")

if errors:
    for e in dict.fromkeys(errors):
        print(f"FAIL {e}")
    for w in dict.fromkeys(warns):
        print(f"WARN {w}")
    print(f"\n{len(set(errors))} failed, {len(set(warns))} warnings - nothing written")
    sys.exit(1)

# ---- render --------------------------------------------------------------------------------
L = []
def add(s=""): L.append(s)

TIMEBLOCK = [
    "Handling time",
    "",
    "How long did it take you to review the initial task and determine its validity?",
    f"{review} minutes",
    "",
    "How long did it take you to complete the initial task rewrite only?",
    f"{rewrite} minutes",
    "(pre-first-upload edits only - Fixable path; 0 on Valid as-is and Invalid)",
    "",
    "How long did it take you to complete the additional questions on the form?",
    f"{form} minutes",
    "",
    f"Total submission time: {total} minutes",
    "(the three fields above only - the revision time below is NOT part of this)",
    "",
    "How long did it take you to complete all revisions?",
    f"{revisions} minutes",
    "(post-first-upload rounds only, tracked separately from the total)",
]

if path == "A":
    add("Submitter Answers - Valid as-is")
    add(f"Task: {task_name}")
    add("")
    add("What is your analysis of the Sentinel task? (both occurrences)")
    add("Valid as-is")
    add("[Internal] Validity: Valid-as-is")
    add("")
    add("Compliance checklist (each verified against the files):")
    for k, label in COMPLY:
        suffix = f" (counted: {f2p})" if k == "more_than_ten_f2p" else ""
        add(f"{box(comply.get(k))} {label}{suffix}")
    add("")
    add(f"Local oracle and NOP run: {str(data.get('local_run')).strip()}")
    add("")
    add("What makes this task difficult?")
    add(difficulty)
    add("")
    add(f"Senior engineer estimate: {senior}")
    add("")
    add("Comments for Reviewer:")
    add(comments)
    add("")
    L.extend(TIMEBLOCK)

elif path == "B":
    add("Submitter Answers - Fixable")
    add(f"Task: {task_name}")
    add("")
    add("What is your analysis of the Sentinel task? (both occurrences)")
    add("Fixable")
    add("[Internal] Validity: Fixable")
    add("")
    add("Select where the task had issues (check all that apply):")
    for k, label in WHERE:
        add(f"- {box(where.get(k))} {label}")
    add("")
    add("What issues did you find with the task?")
    for k, label in WHAT:
        add(f"- {box(what.get(k))} {label}")
    add("")
    add("Issue details:")
    add("")
    for i, it in enumerate(issues, 1):
        detail = unwrap(it.get("detail", ""))
        head   = detail[0] if detail else ""
        add(f"{i}) {WHAT_BY_KEY[it['category']]} - {head}".rstrip())
        for line in detail[1:]:
            add(line)
        fixable = bool(it.get("fixable", True))
        add(f"- Is this issue fixable or not fixable? {'Fixable.' if fixable else 'Not fixable.'}")
        how = unwrap(it.get("how", ""))
        lead = "- If fixable, how?" if fixable else "- Why not?"
        add(f"{lead} {how[0] if how else ''}".rstrip())
        for line in how[1:]:
            add(line)
        add("")
    add("--- Phase 2 (completed after the evals pass) ---")
    add("")
    add("Files Changed:")
    for i, f in enumerate(data.get("files_changed") or [], 1):
        add(f"{i}. {f['path']}")
        add(f"   Changed: {' '.join(str(f['changed']).split())}")
        add(f"   Why: {' '.join(str(f['why']).split())}")
    add("")
    add("PR additions:")
    add(str(data.get("pr_additions")).strip())
    add("")
    add("Post-fix confirmation (each verified after fixes):")
    for k, label in POST:
        suffix = f" (counted: {f2p})" if k == "more_than_ten_f2p" else ""
        add(f"{box(post.get(k))} {label}{suffix}")
    add("")
    add("What makes this task difficult?")
    add(difficulty)
    add("")
    add(f"Senior engineer estimate: {senior}")
    add("")
    add("Comments for Reviewer:")
    add(comments)
    add("")
    L.extend(TIMEBLOCK)

else:
    add("Submitter Answers - Invalid/Not Fixable")
    add(f"Task: {task_name}")
    add("")
    add("What is your analysis of the Sentinel task? (both occurrences)")
    add("Invalid/Not Fixable")
    add("[Internal] Validity: Invalid")
    add("")
    add("Issues found with the task/components:")
    for s in data.get("invalid_issues") or []:
        add(str(s))
    add("")
    add("Specific environment issues (if applicable):")
    for s in data.get("environment_issues") or []:
        add(str(s))
    add("")
    add("Why this task is unfixable:")
    for i, s in enumerate(data.get("unfixable_reasons") or [], 1):
        add(f"{i}) {' '.join(str(s).split())}")
    add("")
    add("Comments for Reviewer:")
    add(comments)
    add("")
    add(f"Senior engineer estimate: {senior}")
    L.extend(TIMEBLOCK)

text = "\n".join(L).rstrip() + "\n"

# last-line defence: the rendered file must carry no em dash at all
if "—" in text:
    print(f"FAIL rendered output still contains {text.count(chr(0x2014))} em dash(es)")
    sys.exit(1)

if mode == "lint":
    for w in dict.fromkeys(warns):
        print(f"WARN {w}")
    print(f"PASS answers.yml is renderable  (total {total} = {review} + {rewrite} + {form}, "
          f"revisions {revisions} separate, f2p {f2p})")
    sys.exit(0)

if out:
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(text)
    for w in dict.fromkeys(warns):
        print(f"WARN {w}", file=sys.stderr)
    print(f"PASS wrote {out}  (total {total} = {review} + {rewrite} + {form}, revisions "
          f"{revisions} separate)", file=sys.stderr)
else:
    for w in dict.fromkeys(warns):
        print(f"WARN {w}", file=sys.stderr)
    sys.stdout.write(text)
PY
