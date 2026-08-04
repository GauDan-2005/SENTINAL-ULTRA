#!/usr/bin/env bash
#
# 60-answers.sh — lint the answers file the submitter pastes into the platform.
#
# Read-only. It never writes to the task tree.
#
# The two things it exists for:
#
#   Hard wrapping. A newline inserted mid-sentence travels with the paste, and
#   the reviewer reads prose chopped in half. The detector fires on the real
#   signature — a line that does not end a sentence followed by a line that
#   continues it — so a lead-in to a code block and a one-word answer do not
#   trip it.
#
#   Em dashes, counted bare. The workspace's own record says a previous
#   verification excluded the template markers by design, so it could never fail
#   on them. This one is `grep -c` with no exclusions, and any nonzero result is
#   shown rather than reasoned away.
#
# Calibrated against the accepted kvdex answers file, which is why two things
# here are WARN rather than FAIL:
#   - the time bands. kvdex shipped 260 total and 195 revisions, both outside
#     the target bands, and was accepted.
#   - the issue-block category strings. kvdex leads six of its ten blocks with
#     its own wording rather than one of the seven platform strings.
# Arithmetic is a FAIL either way, because it is either right or wrong.
#
# usage: 60-answers.sh <task-dir|answers-file>
# exit:  0 clean, 1 a real defect, 2 could not run

# shellcheck source=_common.inc
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.inc"

if parse_mode "${1-}"; then shift; fi
ARG="${1-}"
[ -n "$ARG" ] || usage_die "answers.args" "no task directory or answers file given"

need python3 || { skip "answers.python3" "python3 is not available"; summary || true; exit 2; }

FILE=""
if [ -f "$ARG" ]; then
  FILE="$ARG"
else
  for cand in "$ARG/answers/submission_answer.txt" "$ARG/answers/submission_answer.md" \
              "$ARG/submission_answer.txt"; do
    if [ -f "$cand" ]; then FILE="$cand"; break; fi
  done
  # the answers file is per task and there is exactly one of it
  n_ans=0
  if [ -d "$ARG/answers" ]; then
    n_ans="$(find "$ARG/answers" -maxdepth 1 -type f \( -name 'submission_answer.*' \) 2>/dev/null | wc -l | tr -d ' ')"
  fi
  if [ "${n_ans:-0}" -gt 1 ]; then
    warn "answers.single-file" "$n_ans submission_answer.* files under $ARG/answers — one of them is stale and the wrong one will get pasted"
  fi
fi

if [ -z "$FILE" ]; then
  skip "answers.present" "no submission_answer file found under $ARG"
  summary || true
  exit 2
fi
note "answers file: $FILE"

TOTAL_MIN_LO="$(fact total_submission_min 180)"
TOTAL_MIN_HI="$(fact total_submission_max 240)"
REV_LO="$(fact revision_min 60)"
REV_HI="$(fact revision_max 120)"

OUT="$(mktempdir)/out"
python3 - "$FILE" "$TOTAL_MIN_LO" "$TOTAL_MIN_HI" "$REV_LO" "$REV_HI" > "$OUT" <<'PY' || true
import re, sys

path = sys.argv[1]
tot_lo, tot_hi, rev_lo, rev_hi = (int(x) for x in sys.argv[2:6])
raw = open(path, encoding="utf-8", errors="replace").read()
lines = raw.split("\n")

res = []
def emit(v, cid, msg, *det):
    res.append((v, cid, msg, det))

# --------------------------------------------------------------- em dashes ---
# Bare count. No exclusions of any kind, including the template markers.
n_em = raw.count("—")
if n_em:
    where = [(i + 1, l.strip()[:100]) for i, l in enumerate(lines) if "—" in l]
    emit("FAIL", "answers.em-dash",
         "%d em dash(es) in the file. Section 5 bans them and exempts only code examples, so use "
         "a hyphen for the issue-block and sub-answer markers" % n_em,
         *["line %d: %s" % w for w in where[:6]])
else:
    emit("PASS", "answers.em-dash", "no em dashes")

for ch, name in (("–", "en dash"), ("“", "curly quote"), ("’", "curly apostrophe")):
    n = raw.count(ch)
    if n:
        emit("WARN", "answers.smart-punctuation",
             "%d %s(es) in the file, these usually arrive from an editor rather than from typing" % (n, name))
        break
else:
    emit("PASS", "answers.smart-punctuation", "no en dashes or curly quotes")

# ------------------------------------------------------------- hard wrapping --
STRUCT = re.compile(r'^\s*(?:-\s*\[[ xX]\]|\[[ xX]\]|\d+[\)\.]\s|-\s|\*\s|#|---|===|\||>)')
END = re.compile(r'[.!?:;\)\]"”]\s*$')
CONT = re.compile(r'(?:,|\b(?:and|or|the|a|an|to|of|in|that|which|with|for|from|but|is|was|'
                  r'were|are|it|this|as|by|on|at|not|no)\b)\s*$', re.I)

wrapped = []
for i, l in enumerate(lines):
    if not l.strip() or l.startswith(("    ", "\t")):
        continue                      # blank line or an indented code example
    if STRUCT.match(l) or END.search(l):
        continue                      # structural line, or the sentence ended here
    nxt = lines[i + 1] if i + 1 < len(lines) else ""
    if not nxt.strip() or nxt.startswith(("    ", "\t")) or STRUCT.match(nxt):
        continue                      # paragraph break, or a lead-in to a code block
    first = nxt.lstrip()[:1]
    if first.islower() or CONT.search(l):
        wrapped.append((i + 1, l.strip()[:90]))

if wrapped:
    emit("FAIL", "answers.no-wrap",
         "%d line(s) break mid-sentence. Every paragraph is ONE line however long it runs, because "
         "the newline survives the paste into the platform field" % len(wrapped),
         *["line %d: %s" % w for w in wrapped[:6]])
else:
    emit("PASS", "answers.no-wrap", "no paragraph is hard wrapped")

# ---------------------------------------------------------------- checkboxes --
def block_after(pattern, limit=30):
    for i, l in enumerate(lines):
        if re.search(pattern, l, re.I):
            box = []
            for l2 in lines[i + 1:i + 1 + limit]:
                if re.match(r'^\s*(?:-\s*)?\[[ xX]\]', l2):
                    box.append(l2)
                elif box and not l2.strip():
                    break
            return box
    return None

is_fixable = bool(re.search(r'^\s*Fixable\s*$', raw, re.M))
for pat, want, label in (
        (r'Select where the task had issues', 4, "where the task had issues"),
        (r'What issues did you find with the task', 7, "what issues did you find"),
        (r'Post-fix confirmation', 8, "post-fix confirmation"),
        (r'Compliance checklist', 7, "compliance checklist")):
    box = block_after(pat)
    if box is None:
        if is_fixable and want in (4, 7) and label != "compliance checklist":
            emit("WARN", "answers.checkboxes.missing",
                 "the %s block is absent, and it is a required field on the Fixable form" % label)
        continue
    if len(box) == want:
        checked = sum(1 for b in box if re.search(r'\[[xX]\]', b))
        if want in (7, 8) and label in ("post-fix confirmation", "compliance checklist") and checked != want:
            emit("FAIL", "answers.checkboxes",
                 "the %s block has %d of %d boxes checked. The platform requires all of them for "
                 "the task to count as valid" % (label, checked, want))
        else:
            emit("PASS", "answers.checkboxes.%s" % label.split()[0],
                 "%s: %d options, %d checked" % (label, len(box), checked))
    else:
        emit("FAIL", "answers.checkboxes",
             "the %s block lists %d options, the form has %d" % (label, len(box), want))

# ------------------------------------------------------------ issue headings --
CATEGORIES = [
    "Every requirement in the instructions is not properly tested",
    "All test requirements are not properly specified in the instructions",
    "The instructions appear LLM generated",
    "The instructions are overly-prescriptive",
    "The task leaks solution information",
    "The oracle does not implement the solution following the instructions",
    "Less than 10 fail-to-pass tests in the test suite",
]
WHERE = ["Instructions", "Tests", "Oracle Solution", "Environment/Dockerfile", "Environment"]

def leads_with_category(text):
    t = text.strip()
    if t.startswith("["):
        j = t.find("]")
        if j > 0:
            t = t[1:j].strip()
    t = t.lower()
    return any(t.startswith(c.lower()) for c in CATEGORIES + WHERE)

# Never a FAIL. The accepted kvdex file leads six of its ten blocks with its own
# wording and was accepted, so the platform does not enforce this.
blocks = [(i + 1, l) for i, l in enumerate(lines) if re.match(r'^\d+\)\s', l)]
if blocks:
    off = [(n, l) for n, l in blocks if not leads_with_category(l[l.index(")") + 1:])]
    if not off:
        emit("PASS", "answers.issue-headings",
             "all %d issue blocks lead with a platform category string" % len(blocks))
    else:
        emit("WARN", "answers.issue-headings",
             "%d of %d issue blocks use their own wording rather than a platform category string. "
             "Readable either way, but a reviewer matching blocks to the checked boxes has to do it "
             "by hand" % (len(off), len(blocks)),
             *["line %d: %s" % (n, l[:80]) for n, l in off[:4]])

# ------------------------------------------------------------ handling time ---
def minutes_after(pattern):
    for i, l in enumerate(lines):
        if re.search(pattern, l, re.I):
            for l2 in lines[i + 1:i + 4]:
                m = re.match(r'^\s*(\d+)\s*minutes?\b', l2)
                if m:
                    return int(m.group(1))
    return None

t_review = minutes_after(r'review the initial task and determine its validity')
t_rewrite = minutes_after(r'complete the initial task rewrite only')
t_form = minutes_after(r'complete the additional questions on the form')
t_rev = minutes_after(r'complete all revisions')

stated = None
for l in lines:
    m = re.search(r'^Total submission time[^:]*:\s*(\d+)\s*minutes?', l, re.I)
    if m:
        stated = int(m.group(1))
        break

parts = [t_review, t_rewrite, t_form]
if stated is None or any(p is None for p in parts):
    missing = [n for n, v in zip(("review", "rewrite", "form", "total"),
                                 (t_review, t_rewrite, t_form, stated)) if v is None]
    emit("WARN", "answers.time-arithmetic",
         "could not read every handling-time field (missing: %s)" % ", ".join(missing))
else:
    s = sum(parts)
    if s == stated:
        emit("PASS", "answers.time-arithmetic",
             "%d + %d + %d = %d, matching the stated total" % (t_review, t_rewrite, t_form, stated))
    else:
        emit("FAIL", "answers.time-arithmetic",
             "the three fields sum to %d but the stated total is %d. The total is fields 1 + 2 + 3 "
             "and never includes the revision time" % (s, stated),
             "review %s, rewrite %s, form %s, stated total %s" % (t_review, t_rewrite, t_form, stated))
    if not (tot_lo <= stated <= tot_hi):
        emit("WARN", "answers.time-band",
             "total submission time %d is outside the %d-%d target band. The accepted bundle "
             "shipped 260, so this is worth a sentence in Comments for Reviewer, not a rewrite"
             % (stated, tot_lo, tot_hi))
    else:
        emit("PASS", "answers.time-band", "total submission time %d is inside %d-%d" % (stated, tot_lo, tot_hi))

if t_rev is None:
    emit("WARN", "answers.revision-time", "the all-revisions field could not be read")
elif t_rev == 0:
    emit("PASS", "answers.revision-time", "0 minutes of revisions, correct before the first bounce")
elif rev_lo <= t_rev <= rev_hi:
    emit("PASS", "answers.revision-time", "%d minutes of revisions, inside %d-%d" % (t_rev, rev_lo, rev_hi))
else:
    emit("WARN", "answers.revision-time",
         "%d minutes of revisions is outside the %d-%d band. The accepted bundle shipped 195"
         % (t_rev, rev_lo, rev_hi))

if stated is not None and t_rev not in (None, 0) and stated >= 0:
    # the classic mistake is folding the revision time into the total
    if t_review is not None and t_rewrite is not None and t_form is not None:
        if stated == t_review + t_rewrite + t_form + t_rev:
            emit("FAIL", "answers.time-arithmetic.revision",
                 "the stated total equals fields 1 + 2 + 3 + 4, so the revision time has been folded "
                 "into it. The revision field is tracked separately")

# ---------------------------------------------------------- required answers --
for pat, cid, label in (
        (r'What makes this task difficult', "difficulty", "the difficulty answer"),
        (r'Senior engineer estimate', "senior-estimate", "the senior engineer estimate"),
        (r'Comments for Reviewer', "comments", "Comments for Reviewer")):
    if re.search(pat, raw, re.I):
        emit("PASS", "answers.%s" % cid, "%s is present" % label)
    else:
        emit("WARN", "answers.%s" % cid, "%s is missing" % label)

if re.search(r'^\s*(Fixable|Valid as-is|Invalid/Not Fixable)\s*$', raw, re.M):
    emit("PASS", "answers.verdict", "a verdict line is present")
else:
    emit("WARN", "answers.verdict", "no standalone verdict line found")

for v, cid, msg, det in res:
    print("%s\t%s\t%s" % (v, cid, msg))
    for d in det:
        print("\t\t%s" % d)
PY

if [ ! -s "$OUT" ]; then
  skip "answers.lint" "the lint produced no output"
  summary || true
  exit 2
fi

while IFS= read -r line; do
  case "$line" in
    $'\t\t'*) note "${line#$'\t\t'}" ;;
    *)
      v="${line%%$'\t'*}"; rest="${line#*$'\t'}"
      cid="${rest%%$'\t'*}"; msg="${rest#*$'\t'}"
      case "$v" in
        PASS) pass "$cid" "$msg" ;;
        FAIL) fail "$cid" "$msg" ;;
        WARN) warn "$cid" "$msg" ;;
        *)    skip "$cid" "$msg" ;;
      esac
      ;;
  esac
done < "$OUT"

summary
