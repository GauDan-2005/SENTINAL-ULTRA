---
id: answers-file-drift
status: platform-confirmed
last_verified: 2026-08-16
verified_by:
  - 20260805_220102__xaaha_hulak__118
  - 20260805_080500__statrs-dev_statrs__315
  - 20260807_080545__tair-opensource_redisshake__1005
  - 20260803_111822__xlwings_xlwings__2719
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
| **A round credited with work it did not do** | "Round 4 widened the restore again for the contracts package and rebuilt the payload" | Round 3 had already widened it to seven packages including that one. Round 4 changed nothing there | Attribution |

Two of the nine were numbers written as words. **A digits-only sweep cannot find those**, which is
the single most useful mechanical fact in this note.

## The six lenses, run separately

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
6. **Attribution.** Added 2026-08-11 from firefly 1123. For every sentence of the form "round N
   did X", check that round N actually did X. This is a *sixth* lens and not a variant of Numbers,
   because the sentence contains no number to re-measure and no name that fails to resolve. It is
   a true statement about the bundle attached to the wrong round, and every other lens passes it.

   It is generated by the revision loop itself. A round that adds a graded test to package P
   writes "widened the restore for P" from memory of the shape of the work, without checking that
   P was already covered two rounds ago. The check is mechanical and takes one command, because
   what the round changed is on disk:

   ```bash
   # what this round actually touched in the bundle
   find work -newermt "<date of the previous zip>" -type f -not -path "*/environment/repo/*"
   ```

   Anything the answers credit to this round that is not in that list is either false or was
   already true. On firefly 1123 the list held five files, `tests/test.sh` among them, and the
   claim was *still* false: the file had been rewritten with a byte-identical payload, so its
   mtime moved and its content did not. **Presence in the changed list is necessary and not
   sufficient.** Confirm the substance, by reading the thing the sentence claims changed:

   ```bash
   # the restore payload's real coverage, decoded rather than described
   grep -o 'SENTINEL_TEST_DIRS="[^"]*"' work/tests/test.sh
   ```

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
the pre-submit gate line, Comments for Reviewer, and the difficulty answer. Editing a paragraph
written for a previous round leaves the previous round's reasoning underneath the new sentence,
which is exactly how that line drifted here. It was called the Send-to-reviewer line until the
platform removed the checkbox on 2026-08-05, and the field survives as the record of whether the
pre-submit gate was clear when the task was submitted.

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

As of the 2026-08-13 export this is a named defect rather than only a workspace habit.
`docs/reviewer-rubric.md:105` makes files-changed counts or a writeup that do not match the actual
diff **Secondary Requirement 5**, a Minor violation flagged in 10% of reviewer comments, and five
Minors across any combination is Needs Revision. So the counts below are worth a Minor each to the
next reviewer who does open the config.

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

**And re-decide the pre-submit gate line every round.** redisshake's accepted file still read
`Send to reviewer: No. This is the round 4 resubmission and the checks have not run against it`
while the task was in front of a reviewer. That field was named for a checkbox the platform removed
on 2026-08-05. It is now the record of whether the pre-submit gate was clear at submit time, and it
goes stale in exactly the same way.

## Your own six lenses are not an independent read

Added 2026-08-11 from firefly 1123, round 4.

The six lenses above were run over that round's answers file by the person who had just written it,
and they found five real defects. An **independent** adversarial pass over the same finished file
then found **seven more**, from 30 candidates with 12 refuted at verification.

That is the same result `audit-the-finished-review-not-just-each-finding.md` measured on the
reviewer side, arriving from the other direction. Careful per-lens work on text you wrote minutes
ago does not substitute for a reader who has no memory of writing it. The defects it caught were
not subtle, and that is the uncomfortable part:

| What the author's own pass missed | Why the author could not see it |
|---|---|
| `all 55 required tests still pass`, in a live evidence sentence, against a required set of 59 | 55 was correct when it was written, at round 0. The author reads the sentence as a thing they already checked |
| `The four new verifier-only files`, against six | Spelled out, and the next sentence in the same entry says "the sixth verifier-only file" |
| `nothing this round touches what they measure`, on the Send line, in the round that changed `tests.patch` and `config.json` | The author knows what they meant by it |
| `23 files plus hand-maintained mocks`, when the three mocks are inside the 23 | Reads as true if you know the shape and never count |

The strongest signal was not severity. It was **independent agreement**: the `55` was hit by all six
lenses separately, and that is what a number nobody has re-derived in four rounds looks like from
outside. When several independent checks converge on one sentence, fix that sentence first.

**Run the audit as a separate pass, by something that did not write the file.** A subagent fan-out
works, one lens each, with adversarial verification after, because the refutation rate is high
(12 of 30 here) and unverified candidates would otherwise cost more than they save.

## Never write a test id you have not just grepped

Same round, and the failure happened **during the fix rather than during the drafting**. Closing a
finding that a probe claim named no test id, the fix named three. Two existed. The third,
`TestSentinelCheckInterfaceRejectsUnusableFormat`, did not; the real id is
`TestSentinelCheckInterfaceUnusableFormat`. It is the plausible name rather than the one in the file,
and it was written with complete confidence.

```bash
# after writing any test id into an answer, before moving on
for id in $(grep -oE 'Test[A-Za-z]+' answers/submission_answer.txt | sort -u); do
  printf '%-52s %s\n' "$id" "$(grep -c "$id" work/tests/config.json)"
done
```

Two rules follow, and the second is the one that costs discipline:

- **Naming a test that does not exist is worse than naming none.** An unnamed claim is weak. A named
  wrong one is checkable, wrong, and reads as fabrication to a reviewer who greps for it.
- **A probe re-run to recover a forgotten id is only evidence if the break lands.** Re-running the
  one here returned reward 1.0, meaning the edit missed its target and the run measured nothing
  (`bin/hostile-probe.sh` exits 3 for exactly this). The correct response was to state the measured
  reward drop and name only the ids that resolve, not to keep guessing at the name.

## The console prints OK for edits that were never written

Third instance, firefly 1123 round 5. The one-write-per-edit rule above exists because two edit
batches were silently dropped. Here is the mechanism, which neither earlier instance recorded, and
it is the reason the rule cannot be satisfied by "being careful".

Three replacements went into one `python3` block, each printing a confirmation as it ran:

```python
s = read(p)
rep(a1, b1, 'edit 1')   # prints OK
rep(a2, b2, 'edit 2')   # prints OK
rep(a3, b3, 'edit 3')   # AssertionError: anchor no longer present
write(p, s)             # never reached
```

The console showed **OK for edits 1 and 2**, and neither reached the file, because the single
`write()` sits after all three and the exception jumped over it. The transcript is then actively
misleading rather than merely incomplete: a later audit that greps for edit 1 and finds it missing
reads as drift that reappeared, when it never landed at all.

Two rules, and the second is the one that catches it when the first is forgotten:

- **One write per edit.** Each replacement reads, replaces and writes on its own, so a failure can
  only lose the edit that failed. The output line is then evidence, because it is printed after the
  write rather than before it.
- **Grep the file for what you just changed, not the console.** `grep -c` on the new string, per
  edit, after the batch. A count of zero means it did not land whatever the log said.

The audit that caught it also shows why this matters more than it looks. Both dropped edits were
Files Changed entries recording what the round changed. Losing them does not corrupt a number, it
makes the round's own work invisible in the field the reviewer reads to see what moved, which is
indistinguishable from not having done it.


## Third instance, and the finding is that a careful re-read is not a check (xlwings 2719, accepted 2026-08-16)

Nine rounds of editing, six of Check feedback and three of revision. The file was audited three
separate times against measured ground truth, each audit run **after** a hand pass I had judged
clean. They returned **9, then 11, then 6** confirmed defects, and the hand pass had missed every
single one.

**The defect is almost never a wrong number. It is a sentence that was true when written.** That is
why re-reading fails: a sentence you wrote correctly does not look wrong when you scan past it, and
a grep for numbers cannot see it at all. The three audits between them caught:

| Sentence | Why it went false |
|---|---|
| "the golden patch now carries **one** addition" | a later round made it two, then three. **The most scope-sensitive claim in a submission** and it was understated twice |
| "pinning the base image removes the drift" | the pin was reverted three rounds earlier, and the same file said so three times |
| "**Nothing here has been submitted yet**" | the task had been submitted, and the same field said so three lines lower |
| "five rounds of Check feedback, four returned results" | six did, and two other counts of the same thing disagreed |
| "twenty two guards" / "forty one of forty one" | later rounds moved them to 23 and 43 |
| "the three that pass" | in the same clause as "four passes" |

### Two false statements I created while fixing other ones

This is the part worth carrying. Fixing the base-image finding I wrote that **pinning the image is
what broke the platform build**, when the cause was a `git -C /app update-index` call exiting 128
under a non-owning uid, recorded in the same `task.md`. And fixing the round-count staleness I
**added** a correct sentence without deleting the one that contradicted it, which is the
supersede-do-not-append failure committed inside the pass meant to fix it.

**A fix written quickly is where the next false statement comes from.** Verify each finding against
the bundle yourself before acting, and re-read the sentence you just wrote against the record.

### Annotating a superseded number is not removing it

An earlier round's figures were relabelled "numbers from that round, kept as the record" and pointed
forward to the current ones. That is not enough. A reviewer skimming a reviewer-facing field sees
`forty one of forty one` and has to work out it is history. Superseded figures belong in `task.md`.
The mechanical check below failed on the annotated version, correctly.

## Two checks that catch this class mechanically, in `bin/checks/60-answers.sh`

The per-round checklist above is a human procedure and it missed all of the above. These do not
depend on anyone remembering:

- **`answers.count-*`** reconciles any count stated in more than one place: additions to the source
  PR, Check-feedback rounds, hostile probes. A disagreement is a FAIL. Added after the additions
  count went wrong **three rounds running**, always in the same buried prose sentence while the two
  prominent ones were updated.
- **`answers.graded-total`** does not guess wording at all. It reads `tests/config.json`, computes
  the graded total, and fails on any total-sized `N of N` in the prose that disagrees. This exists
  because `answers.count-*` could not catch spelled-out figures like "forty one of forty one", and
  guessing phrasings is a losing game.

**Both were negative-tested when added**, by re-breaking the sentence in a scratch copy and
confirming a FAIL. A check that has never failed is not evidence, and this workspace already has a
rule about verifications built so they cannot fail on the thing they exist to catch.

## Fourth instance, and the four classes a self-audit structurally cannot reach (hulak 118, accepted 2026-08-16)

Four upload rounds, and the file was audited by three independent readers before the last one.
Thirteen defects survived verification. The author's own mechanical pass had already caught **nine**,
and the four it had not are the ones worth naming, because each is invisible to a whole lens rather
than missed by a tired reader.

**1. A sentence the author wrote in the same session.** "The tier itself has not been edited in any
round" denies a change round 1 made at a reviewer's direct request. Every lens above measures the
answers against the bundle in `upload/`, and **none of them measures against `download/original/`**,
so a claim about what has NOT changed has nothing to fail against. The Attribution lens is the near
miss and it runs one way only, checking work a round is credited with. Add the other direction: any
sentence saying something was **not** touched gets `diff -rq download/original work -x '.git'` run
against it before it ships.

**2 and 3. Two counts nobody thought to derive.** "331 of the 350 graded ids live outside the
patched files" is off by one, because one `pass_to_pass` entry is created **by** the patch, and "all
331 measured passing at the base commit" inherits the same error. The Numbers checklist measures
`fail_to_pass` and `pass_to_pass` lengths and file counts and stops there. The outside-the-patch
figure has a command already, the Section 10.3 snippet, and the base-commit figure needs the tests
run at base. **A count that took a script to produce needs that script re-run, not a re-read.**

**4. A fact about somebody else's pull request.** The file said PR 155's "own tests and its second
file are left out" when PR 155 has two files and the second one **is** its tests, so the sentence
invented a third and double-counted. The Verifiability lens passes it, because that lens asks
whether a claim names its source and this claim named PR 155. **Naming the source is not fetching
it.** Any sentence describing what an upstream PR contains gets the API paged again before it ships.

The lesson is one line and it is the same one xlwings measured from the other side. **A self-audit
checks the claims it thought to make.** Every number verified was a number chosen for verification,
and the four that got through were a sentence written minutes earlier, two counts nobody had derived
separately, and an upstream fact recalled instead of re-fetched.

## The pre-submit gate line is the field that goes stale most often

Measured 2026-08-16 across all **eight** accepted answers files in `_archive/`. Two carry no such
line, kvdex 245 because it predates the field and libcrux 1165 because Path C has none. Of the six
that do:

| Bundle | Line | Reads |
|---|---|---|
| statrs 315 | :119 | `Send to reviewer: No, for one pass.` |
| xlwings 2719 | :122 | `Send to reviewer: Yes, once the checks come back green on this exact zip.` |
| redisshake 1005 | :137 | `Send to reviewer: No. ... the checks have not run against it` |
| elfuse 162 | :126 | `Send to reviewer: No. The zip has not been uploaded yet` |
| hulak 118 | :129 | `Send to reviewer: No, not yet.` |
| AltBeacon 1177 | :334 | `Send to reviewer: Yes. Every evaluation check passed on the last upload` |

**Four of the six say No in a file that reached a reviewer and was accepted.** A fifth ships a Yes
conditioned on checks that had not run. Only AltBeacon's is settled at the moment it shipped.

And **all six use the retired name.** The checkbox was removed from the form on 2026-08-05
(`docs/tasking-guide.md:251`) and the template at `.claude/rules/07-answer-templates.md` has said
`Pre-submit gate:` ever since, so four of the six promise to tick a box that no longer exists, in
front of the person deciding whether to accept the task.

Nothing catches it. `bin/checks/60-answers.sh` has no check that reads this field, and the pre-send
check only compares the file's mtime against the zip. **Rewrite this line every round rather than
editing it**, and rename it while you are there. It is the one line in the file whose whole content
is a statement about a moment that has already passed.

See also [[self-inflicted-defects-dominate-late-rounds]], [[probe-the-instruction-you-already-wrote]].

## Fifth instance, ziti-sdk-c 668, and it names an operation that invalidates a whole class of sentence

The four earlier instances are stale **counts**. This one is a stale **enumeration**, and it has a
trigger that can be written down.

Round 6 folded `sentinel_ctrl_failover_stays_in_endpoint_set` into
`sentinel_ctrl_failover_switches_endpoint`, keeping every assertion, to free a slot under the
20-id ceiling. That edit silently falsified a sentence written in round 1: an issue block listing
every graded id by name. It still named the folded test as current and it never named the id that
took the slot. Both halves were wrong, and the file had already passed the per-round grep
checklist, a full humanizer pass, and my own read.

**The rule: any operation that merges, splits, renames or retires a graded id invalidates every
enumeration of the graded set, not just every count of it.** Counts are what the checklist looks
for and enumerations are what it misses, because an enumeration has no number in it to compare.

The check is a set comparison rather than a grep, and it is worth running every round:

```python
import json, re
cfg = json.load(open('work/tests/config.json'))['grading']
a   = open('answers/submission_answer.txt', encoding='utf-8').read()
graded = set(cfg['fail_to_pass']) | set(cfg['pass_to_pass'])
named  = set(re.findall(r'\b(?:sentinel_[a-z_]+|invalid_controller)\b', a))   # your id shape
print("named but not graded :", sorted(named - graded))    # ghosts
print("graded but never named:", sorted(graded - named))   # omissions
```

Read both directions. Ghosts are the stale half and omissions are the missing half, and this fold
produced one of each in the same sentence.

**Two refinements from running it.** A ghost is not automatically a defect: the Files Changed entry
that *explains* the fold names the retired id on purpose, and that mention is correct. Judge each
hit rather than deleting on sight. And the omission side reported all six `pass_to_pass` ids as
never named when the prose names every one of them in its runner form, `parse model_list` against
the config's `parse_model_list`, so reconcile id spellings before believing that half.

**Where it was caught.** Not by the checklist and not by reading. By a scripted audit run against
`tests/config.json` after the file had already been declared finished, which is the same finding as
the xlwings measurement above: the recurring defect is a sentence that was true when written and a
later round made false, and that does not read as wrong when you scan past it.
