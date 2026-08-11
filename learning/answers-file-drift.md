---
id: answers-file-drift
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260805_080500__statrs-dev_statrs__315
  - 20260807_080545__tair-opensource_redisshake__1005
evidence: "One submission_answer.txt edited across five rounds. An adversarial audit run as five independent lenses returned 34 findings that deduplicated to about nine real ones, and several would have shipped. Separately, two batches of edits were silently discarded by a python script that asserted its way to an error before its single write at the end, both caught only by a later re-read"
applies_to:
  languages: [any]
  runners: [any]
  phases: [answers, revision-rounds, peer-review]
blocks_submission: false
fails_gate: [peer-review]
supersedes: []
contradicts: []
---

# submission_answer.txt rots every round, and only a hostile re-read finds it

## What happened

statrs 315 ran five rounds. The answers file was edited in every one of them, under the Step 10
rule that says to edit the answers a round affected and leave the rest alone. That rule is right
and it is also the mechanism of the rot: **the sentences a round does not touch are exactly the
sentences that quietly stopped being true.**

At the end, before the last upload, the file was audited adversarially. Five independent lenses
returned **34 findings**, which deduplicated to about **nine real ones**. Several would have
shipped to the reviewer as written.

None of them were sloppiness in the round that wrote them. Every one was a true sentence that a
later round falsified without visiting it.

## The nine, by class

| Class | What the file said | What the bundle was | The lens that caught it |
|---|---|---|---|
| Merged-away id | An issue block listed the eight tests added in round 1 by name, as the current graded set | Round 3 had merged three pairs of error cases into single ids, so two of the names no longer existed anywhere in `config.json` | Names |
| Count stale by two rounds | "assertions went from 26 to 90" | 132, after two further passes folded assertions into existing ids | Numbers |
| A "still" that stopped being true | "the file list is still the same six files as the PR" | Seven, after round 3 added a sixth module and its registration | Tense |
| Field carrying last round's reasoning | The Send-to-reviewer line argued the previous round's gate state | A different round with a different gate result | Tense |
| Number spelled as a word | The difficulty answer described "five hypothesis tests" | Six, since the scope expansion | Numbers |
| Unnamed source | The scope expansion was described as adapted from a *related* later PR, with the PR never named | PR 346, with PR 336 considered and rejected | Verifiability |
| Unverifiable headline claim | "nine hostile probes each name the test that caught it", with no test ids given | Nine probes, nine catching ids, all knowable | Verifiability |

Two of the nine were numbers written as words. **A digits-only sweep cannot find those**, which is
the single most useful mechanical fact in this note.

## The five lenses, run separately

Do not run one careful read. A file read once is a file believed once. Run five passes, each with
one job and no memory of the others, then deduplicate. The overlap is signal: a sentence three
lenses hit is the one most likely to be wrong.

1. **Numbers.** Every count, size, range and version in the file, re-measured against the bundle
   sitting in `upload/` right now. Digits and words both.
2. **Names.** Every test id, file path, symbol, module and URL resolved in the current bundle. A
   name that resolves nowhere is either stale or invented, and the reviewer finds out which.
3. **Tense.** Every sentence containing `still`, `now`, `unchanged`, `remains`, `the same`, `as
   shipped`, `this round`. Each one asserts a state, and states expire.
4. **Verifiability.** For every claim, ask what the reviewer would type to check it. If the answer
   is nothing, the claim is finished or deleted. See the next section.
5. **Contradiction.** Read the file against itself, block against block. Two sentences that cannot
   both be true is what an appended round looks like from the reviewer's chair, and Step 10's
   supersede rule exists because that has shipped before.

## A claim the reviewer cannot check is worse than no claim

Two of the nine are this failure, and it is the one worth changing behaviour over.

"Nine hostile probes each name the test that caught it" names no test. The sentence advertises the
exact evidence it withholds. The reviewer has two moves: disbelieve it, or ask, and both cost more
than the sentence bought. Compare it to the repaired version, which spends four extra lines saying
that making the ANOVA call error only when every group is constant is caught by
`nan_policy_emit_drops_nans_before_computing`, that reinstating the tail inversion is caught by
`mannwhitneyu_asymptotic_variants_differ_by_the_continuity_correction`, and so on for all nine.
Same claim, now checkable in one `grep`.

The scope-expansion one is worse, because the unnamed thing is load-bearing. The legality of the
whole expansion rests on the adapted PR being **related**, and the file asserted related without
naming the PR. That is the one fact a reviewer must confirm and the one fact they were not given.
A claim about legality that cannot be checked reads as a claim hoping not to be.

**The rule: every claim in the file either carries its own evidence, or it comes out.** A file path,
a test id, a URL, a number you measured. Not "the tests cover the error ordering" but which test and
which ordering. Deleting an unverifiable sentence costs nothing, because it was persuading nobody.

## One write per edit

Two separate times on this task, a batch of answers-file edits was applied by a python script that
built the new text in memory, asserted after each replacement that the old string had been found,
printed a line per applied edit, and wrote the file **once at the end**. Both times a later
assertion failed, the script exited nonzero, and the file on disk still held the pre-batch text.
Every edit the script had already printed as applied was gone.

Both times it was caught only by a later verification pass that re-read the file. Nothing in the
moment looked wrong, because the progress log was accurate about the in-memory copy and silent
about disk.

- **Write after each edit, never once at the end.** A crash then costs one edit instead of the
  batch, and the file on disk is always a state you can read.
- **Prefer the `Edit` tool over a script.** It fails per edit and cannot batch-discard.
- **A script's own stdout is not evidence about a file.** Evidence about a file is a read of that
  file. After any scripted edit, re-read and `grep` for each new string.
- This is the same shape as the Step 10 item 7 rule that `task.md` and the answers file are one
  write and not two. **Any two-phase process whose first phase reports success will eventually
  report a success the second phase never delivered.**

## The per-round checklist

Runs every round, as part of Step 10 item 5, before the `humanizer` pass. Start by reading the file
top to bottom, not the parts you changed.

```bash
cd tasks/<name>/work        # the bundle the answers must describe
A=../answers/submission_answer.txt

# 1. NUMBERS - measure first, then grep the file for what it claims
python3 -c "import json;g=json.load(open('tests/config.json'))['grading'];print('f2p',len(g['fail_to_pass']),'p2p',len(g.get('pass_to_pass',[])))"
grep -c '^+.*assert' tests/tests.patch                    # assertion count
grep -c '^diff --git' solution/golden.patch               # files golden touches
grep -nE '\b[0-9]+\b' "$A"                                # every digit claim
grep -nEi '\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\b' "$A"   # word numbers

# 2. NAMES - any snake_case token in the answers that the bundle no longer knows
python3 - <<'PY'
import json, re
cfg = json.load(open('tests/config.json'))['grading']
live = {i.rsplit('::',1)[-1].rsplit('#',1)[-1]
        for i in cfg['fail_to_pass'] + cfg.get('pass_to_pass', [])}
patch = open('tests/tests.patch', encoding='utf-8', errors='replace').read()
txt = open('../answers/submission_answer.txt', encoding='utf-8').read()
for tok in sorted(set(re.findall(r'\b[a-z][a-z0-9]*(?:_[a-z0-9]+){2,}\b', txt))):
    if tok not in live and tok not in patch:
        print('NOT IN THE CURRENT BUNDLE:', tok)
PY
# camelCase runners need the pattern swapped: r'\b[a-z]+(?:[A-Z][a-z0-9]+){2,}\b'

# 3. TENSE - every sentence asserting a state
grep -nEi '\b(still|now|unchanged|remains?|as shipped|the same|this round|no longer)\b' "$A"

# 4. VERIFIABILITY - claims that advertise evidence they do not carry
grep -nEi 'each name|names the test|caught by|hostile|probe|related (pull request|PR)|adapted from|covers|verified' "$A"
#    every hit must be followed by a test id, a file path, a URL or a measured number

# 5. FILE PATHS named in the answers that do not exist in the bundle
grep -ohE '\b(tests|solution|environment)/[A-Za-z0-9_./-]+' "$A" | sort -u | while read p; do
  [ -e "$p" ] || echo "PATH GONE: $p"; done
```

Then rewrite, do not edit, the three fields that describe **this round** rather than the bundle:
the Send-to-reviewer line, Comments for Reviewer, and the difficulty answer. Editing a paragraph
written for a previous round leaves the previous round's reasoning underneath the new sentence,
which is exactly how the Send line drifted here.

## The question that was never no

The user asked "does submission_answer.txt need updates?" after three separate rounds. Every single
time the answer was yes, and every single time the check found something real.

**A question whose answer has never been no is not a question. It is a step somebody left out of
the process.** It runs unconditionally now, before the humanizer pass, on every round including the
ones where "nothing in the bundle changed" - because the rounds that changed nothing in the bundle
are the ones where the file is drifting furthest from a set of numbers everyone stopped measuring.

Cost of the audit: under an hour, once, at the end of five rounds. Cost of not running it: a
reviewer reading a file that names a test that does not exist, counts that are two rounds old, and
a legality claim about a PR it never names.

See also [[not-fixable-is-a-written-argument]], [[peer-review-bounces]],
[[accepted-bundle-reference]], [[diagnosing-platform-only-failures]].

## Second instance, and this one SHIPPED and was accepted (redisshake 1005, 2026-08-11)

The statrs audit above caught its findings before upload. redisshake 1005 did not, and the drift
went to a reviewer inside an **accepted** submission. Four stale numbers in one file, all of them
counts, all of them left behind by a later round:

| Where | Says | Live value |
|---|---|---|
| Files Changed entry 5 | `fail_to_pass 10 to 14 and pass_to_pass 1 to 11` | **20 and 13** |
| Files Changed entry 4 | "three new ones replace them", naming three files | `tests.patch` creates **seven** |
| Issue block 13 | "The set is now 19 tests" | **20** |
| Issue block 3 vs Comments | "Twelve separate breaks" vs "I broke the oracle thirteen times" | 13 |

The post-fix checkbox one line below entry 5 reads `counted: 20`, so **the file contradicts
itself on the same page** and neither the round audit nor a reviewer flagged it. Acceptance is
not evidence that this is acceptable (LEDGER L53): it is evidence that a reviewer did not open
`tests/config.json` to check.

**Why the existing checklist missed it.** Lens 1 below measures the live numbers and greps the
file for what it claims, which catches a stale count in a headline sentence. It does not walk
**Files Changed entry by entry**, and Files Changed is where a per-file "changed X to Y" sentence
is written once in round 0 and then never re-read, because the round that changes X to Z edits the
config and the issue block and considers itself done.

**The added step.** Every count in Files Changed is re-derived from the live bundle, never carried
forward from the previous round's prose:

```bash
# the numbers Files Changed is allowed to state, measured fresh
python3 -c "import json;g=json.load(open('tasks/<name>/work/tests/config.json'))['grading'];print('f2p',len(g['fail_to_pass']),'p2p',len(g['pass_to_pass']))"
grep -c '^new file mode' tasks/<name>/work/tests/tests.patch     # graded files created
grep -c '^diff --git'   tasks/<name>/work/solution/golden.patch  # golden file count
# then read every "N to M" and every spelled-out count in the Files Changed block against those
grep -nE '[0-9]+ to [0-9]+|(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty)' tasks/<name>/answers/submission_answer.txt
```

The spelled-out half of that grep is the part that matters. Every one of redisshake's four stale
numbers except entry 5 was a **word**, not a digit, so a numeric grep could never have found them.

**And re-decide the `Send to reviewer:` line every round.** redisshake's accepted file still read
`Send to reviewer: No. This is the round 4 resubmission and the checks have not run against it`
while the task was in front of a reviewer.
