_Owner of CLAUDE.md **Section 13**. Loaded every session. Added 2026-08-18._

## 13. The Reviewer Workflow

Section 12 (`.claude/rules/13-reviewer-path.md`) owns **what** a review finds, how severe each
finding is, and how the answer is written. This file owns the **order it happens in and what gets
written down**. Where the two touch, Section 12 wins on substance and this file wins on sequence.
Nothing here replaces a Section 12 rule; every step below names the Section 12 subsection it runs.

The submitter path has twelve numbered entries, a gate before the upload, four bookkeeping tables and
a close-out. The reviewer path had none of that until this file: it was one unnumbered section, so
every review re-derived its own order, and the two blocking defects on mithril.js 2021 were found by
runs that no amount of re-reading the notes would have reached (`learning/audit-the-finished-review-not-just-each-finding.md`).
A numbered spine is what makes a missing step visible.

---

### The reviewer spine

| Step | What happens | Never |
| ---- | ------------ | ----- |
| **R1** | Session start. `learning/LEDGER.md` first and in full, then the rest of `learning/`, then `INDEX.md`, then scan **both** `tasks/` and `review_tasks/`. Reconcile and report | Write a single finding before `LEDGER.md` has been read (L64) |
| **R1.5** | Ask the user for **both zips and the whole reviewer page**, in one message. Wait | Record anything as unavailable before you have asked for it and said what you did to get it (`docs/reviewer-rubric.md:123`) |
| **R2** | Extract, freeze, working copy, and write down the bundle's identity: zip sha256, entry count, mtime spread | Run any command inside `download/original/` or `download/seed/`, git included |
| **R3** | The submitter's own diff, and their claims turned into a verification table. On a second round, the previous reviewer's findings become the same kind of table | Re-file a finding the submitter already fixed, or one a previous round already raised and they answered |
| **R4** | The mechanical sweep. Pillar 5, git state, runs **first and alone**, because the rubric calls it an early gate (`docs/reviewer-rubric.md:95`) | Collapse the `Meets` line and the Needs Revision trigger into one bar, which manufactures a Major out of a noisy `fsck` |
| **R5** | PR comparability, hunk level, both directions | Compare by file list. It is worthless and it is what takes a quality score of 1 off the table in one step |
| **R6** | The measurement battery in the container. Eight runs, every one with the network off | Report `solve.sh` three times as an oracle result (L69), or hand-roll a mutation probe (12.6) |
| **R7** | The content read: the requirement-to-test mapping, instruction quality, leakage, the difficulty read | Read for content before R4 to R6 have run. A read finding is a Minor until it is measured (12.2) |
| **R8** | Filing discipline. The stock-defect sweep, then the six per-finding checks over every candidate | File a finding without a baseline, or promote a read to Major (12.7) |
| **R9** | Grade and count. Severity per finding, the bucket, then the verdict as arithmetic | Read the verdict off how the notes feel. It is a count, and the count lives in the record block |
| **R10** | Write the answer against the seven live questions, run `humanizer`, then the Section 5 greps and the 5.1 soft-signal check | Ship a review in the shape of a template. Four soft signals in one review is a Major **against the reviewer** (`docs/reviewer-rubric.md:121`) |
| **R11** | Audit the finished review as its own pass, submit, then close: outcome into `task.md`, the `INDEX.md` row, the harvest, **the accepted-bundle harvest when the verdict was Accept**, the calibration row, the archive move | Treat per-finding rigour as covering the finished document (12.10). Harvest an Accept you reached by reading, or merge a foreign bundle into `accepted-bundle-reference.md` |

**The Fixable-submission sequence is always: intake, extract, their diff, mechanics, PR, measure,
read, file, count, write, audit.** The verdict is R9 and never earlier.

---

### Where this deliberately breaks from the submitter's spine

Four of the submitter's steps have no reviewer equivalent, and copying them is how a review turns
into a second submission.

- **The submitter decides the verdict at Step 4, before the work. A reviewer decides at R9, after
  it.** The submitter's verdict picks which path they then execute; the reviewer's verdict is the
  output of a count that does not exist until every finding has a severity. Deciding early is how a
  review goes looking for evidence for a conclusion it already has
- **There is no Phase A / Phase B split and no zip.** The submitter splits cheap gates on `work/`
  from the battery against the built zip, because the artifact that ships has to be the artifact that
  was measured. A reviewer builds nothing, so `work/` **is** the artifact and R4 and R6 both run
  against it. `review_tasks/<name>/` has no `upload/` for the same reason
- **A reviewer edits nothing.** `work/` exists to run git, patch and docker commands in. Every hard
  boundary on `download/original/` from the submitter path applies here unchanged, and `work/` gains
  one of its own: a change you make in `work/` to test a theory is a probe, it gets recorded as a
  probe, and it is never the basis for a sentence describing what the bundle does
- **One handling-time field, not four.** The live form asks how long the review took and nothing
  else (`sample_review_page.md:467`). There is no rewrite time, no revision time and no computed
  total, so the Step 8 arithmetic and its 180-240 band do not apply

Two of the submitter's steps DO carry over with their reasoning intact, and both are new here:

- **Step 10's "from about round 4, add the bundle's own diff to what you review"** becomes R3, and
  for a reviewer it is available on round 1. The page carries the seed zip beside the submitted one,
  so the submitter's entire change is one `diff -rq` away (`sample_review_page.md:62` and `:141`).
  `learning/self-inflicted-defects-dominate-late-rounds.md` measured that on one task **all five
  findings of the accepted round had been authored by earlier rounds of that same task**. That diff
  is the reviewer's highest-yield read and nothing before this file told anyone to take it
- **Step 11's close-out** becomes R11's tail. A review that ends by pasting an answer and closing the
  tab leaves the register, the learning index and the calibration row exactly as drifted as a task
  that ends the same way

---

### R1: Session start (shared with the submitter path, plus one line)

Run the submitter's Step 1 unchanged (`.claude/rules/01-workflow-steps-1-to-5.5.md`), with two
differences:

1. **`learning/LEDGER.md` is opened first and in full, before `learning/README.md`.** This is not a
   preference. L64 is the row where a review read the index, never opened the LEDGER, and then
   re-derived, re-filed and shipped to the user a finding that L58 had already measured and written
   down with its command eleven hours earlier. `bin/learning-query.sh` skips `LEDGER.md` by name, so
   it can never return a LEDGER row: open the file
2. **Scan `review_tasks/` as well as `tasks/`.** A folder under either with no `INDEX.md` row is
   drift and gets reported rather than silently fixed

Then write the `## learning/ notes applied` table into the review's `task.md` before R3 begins, in
the same shape the submitter path uses: one row per note, naming what it predicts **for this bundle**
and the command that settles it. The three finished reviews all carry one and it is the section that
most reliably pays.

**The throughput rule is UNSETTLED for reviews.** `INDEX.md` caps `pending-revision` at two because
the platform blocks a new *task* claim, and nothing in `docs/` says a review counts against that or
against any cap of its own. Do not invent one, and do not assume a review is free either. What would
settle it: `stb submissions list`, or the platform refusing a review assignment with a count visible.

---

### R1.5: Intake. Ask for both zips and the whole reviewer page

**This is the step that changed most, and the change is in your favour.** Until 2026-08-18 this
workspace believed a reviewer gets the submission zip and nothing else, and three reviews were
written on that belief. `sample_review_page.md`, a capture of the live reviewer page for one
submission, shows the reviewer is given the seed zip, the submitted zip, every one of the submitter's
form answers, all six evaluation panels, the difficulty-check counters and any previous round's
reviewer feedback. `docs/reviewer-rubric.md:123` makes "claiming logs are inaccessible when they are
visibly present" a flaggable integrity item, which is what writing "the submitter's answers did not
arrive" on a page that renders them would now be.

Ask for all of it in **one** message, and wait:

```
1. The ORIGINAL task zip, from "Download Sentinel 2.0 task here"          (sample_review_page.md:62)
2. The SUBMITTED zip, from the re-upload field, with its timestamp        (:141)
3. The submitter's answers, verbatim: their verdict and [internal] Validity, both checkbox
   groups, the numbered issue details, Files Changed, PR additions, the eight confirmations,
   the difficulty answer, the senior estimate, and Comments for Reviewer   (:56-148, :323-415)
4. The evaluation panels, pasted whole: Static Checks, Prescriptiveness, Difficulty Check,
   Agentic Judge Quality Report, Oracle Check, Quality Check                (:179-321)
5. The Difficulty Checks block, all four fields                             (:149-177)
6. Any previous Reviewer Feedback shown on the page, with its date          (:15)
7. The rebuttal comments in the left-hand panel                             (:435)
8. Whether the "maximum revision reached" dialog is showing
```

- **Ask for the zips by their field, not by name.** Both fields render a zip with a submission id and
  they are different artifacts: the first is the task as issued, the second is what the submitter
  built. Record which id is which in `task.md` before extracting either
- **Item 8 decides whether Reject is even available.** `docs/tasking-guide.md` reserves Reject for a
  submission that has exhausted its revision cycles, and says you know because Needs Revision is no
  longer selectable and the platform blocks you with a "Maximum Revisions Reached" dialog. Without
  that dialog the answer is Needs Revision, however bad the bundle is
- **A missing item is recorded with what you did to get it**, per `docs/reviewer-rubric.md:123`, and
  never as a bare "not available". If the seed zip is genuinely absent, say so and fall back to the
  R3 mtime reading, which supports "this was not rewritten" and never "the content is right"
- **Never generate any of these values.** Same rule as the submitter's Step 1.5

**Establish WHICH BUNDLE you were handed before anything else, because the page will not tell you.**
The re-upload field is conditional on the verdict radio (`sample_review_page.md:136-141`, "If Fixable
is selected"), so a submitter who has set no verdict leaves **one** zip on the page and it is the
**seed**. Everything else on the page can still argue a corrected bundle exists. On gnmyt/MySpeed 1536
the page carried `All checks have passed`, a last-counted submission version id, and reviewer feedback
dated 8/15/26 describing a zip with real fixes in it, and the zip attached was the task as issued.

Two checks settle it in a minute. Turn the **previous round's reviewer feedback on the same page**
into a checklist against the zip, because it describes the bundle it reviewed and each of its
statements is a test (four for four false there). And read the **mtime spread against the folder
name**, because the generator stamps every entry at build time (all 558 entries at `2026-07-24 13:30`
against a directory named `20260724_132921`).

Ask, and keep measuring while you wait. The seed is R3's baseline either way, so nothing measured on
it is wasted, and only the **wording** depends on the answer. Until it is settled no note may say the
submitter did or failed to do anything. Say the re-upload field did not render, never that their
answers did not arrive, which `docs/reviewer-rubric.md:123` makes a flaggable integrity item
(`learning/reviewer-can-be-handed-the-seed.md`, LEDGER L107).

**Establish the submission shape here, because it changes the whole review.** Read their verdict off
item 3 and route:

| Their verdict | What you are reviewing | Where the shape is |
|---|---|---|
| **Fixable** | A rewritten bundle. The full R2 to R11 sequence | this file, as written |
| **Valid as-is** | The seed bundle unchanged, plus their claim that it needed nothing. R3's verification table has one row and it is the seven compliance boxes | R7 note below |
| **Invalid / Not Fixable** | **Prose only. There is no zip on Path C**, so R2, R4, R5 and R6 have nothing to run against | R7 note below |
| **Invalid Difficulty** | The platform's verdict at the four-check cap, not theirs. Review the bundle on its own terms | 12.2, and the note in R9 |
| **none set, one zip** | The **seed**, and it is what you review. R3 cannot run at all, so say so and word every finding against the bundle | `learning/reviewer-can-be-handed-the-seed.md` |

---

### R2: Extract, freeze, working copy, and record the bundle's identity

The submitter's Step 2 item 0 discipline applies unchanged: the working copy is made **before** any
command runs, and `download/original/` is frozen from that moment.

**One command, and it is a dry run until `--go`:**

```bash
bin/new-review.sh <submitted-zip> "<Original Directory Name>" --seed <seed-zip>          # dry run
bin/new-review.sh <submitted-zip> "<Original Directory Name>" --seed <seed-zip> --go
```

`bin/new-review.sh` wraps `bin/new-task.sh --dest review_tasks`, which already does the right thing
for a review because its `--i-am-starting-a-real-task` guard only fires under `tasks/`. That half
creates the folder, copies the zip in, runs `bin/pristine-freeze.sh` to extract, manifest, verify
against the zip and freeze read-only, then `cp -a` to `work/`. The wrapper then adds the half no
existing tool does: it copies the seed zip in **afterwards**, so the first half's zip discovery
cannot pick the wrong one, extracts the seed **by contents** the way `pristine-freeze.sh` finds an
inner tree, freezes it, and scaffolds `task.md` with the twelve sections a review owes.

**Why it is a wrapper rather than a hand sequence.** A review is the only thing in this workspace
with two pristine extracts, and putting the seed in `download/original/` inverts every diff the
review then makes without any check noticing. Run without `--seed` when the page offered only one
zip; it warns and the review falls back to R3's mtime reading.

Both halves also leave an `upload/` that a review never uses. Leave it empty rather than deleting
it, so the folder shape stays one `ls` away from the submitter's.

**The folder shape, with the one addition this file makes:**

```
review_tasks/<Original Directory Name>/
  task.md                              the evidence record behind the answer
  task_details.md                      the platform block and the submitter's answers, verbatim
  download/
    <seed-id>_submission.zip           the task as issued to the submitter
    <submission-id>_submission.zip     what the submitter built
    seed/                              pristine extract of the seed. NEVER edited, no commands
    original/                          pristine extract of the SUBMITTED bundle. NEVER edited
  work/                                copy of original/. Commands run here. A reviewer does NOT edit
  answers/
    review_answer.txt                  the Section 6 Path D template
```

`original/` keeps its existing meaning, the pristine extract of the thing under review, so the three
finished reviews under `review_tasks/` stay correct. `seed/` is new and is what R3 diffs against.

**Record the identity before reading anything**, because these are the numbers a later round and the
record block both need and neither can reconstruct:

```bash
sha256sum "$R"/download/*_submission.zip
unzip -l "$R/download/<submission-id>_submission.zip" | tail -1
unzip -l "$R/download/<submission-id>_submission.zip" | awk '{print $2}' | sort -u   # the mtime spread
unzip -Z "$R/download/<submission-id>_submission.zip" | grep -c '^l'                  # symlinks
unzip -Z "$R/download/<submission-id>_submission.zip" 'tests/test.sh' 'solution/solve.sh'
```

Then cross-check the platform block against the extracted `task.toml`, exactly as the submitter's
Step 2 does. A metadata mismatch here is Secondary Requirement 5, and the baseline it must be
measured against is in Section 8, against `download/original/` trees and never against `work/` ones
(L61, L72).

---

### R3: The submitter's diff, and their claims as a verification table

`docs/tasking-guide.md` defines the reviewer's job as independently verifying the submitter's
findings and confirming their conclusions are supported by evidence. That is a per-claim job and it
needs a table, not a reading.

**First, the diff.** This is the whole of what the submitter did:

```bash
diff -rq "$R/download/seed" "$R/download/original" -x '.git' | sort
```

Read the new material as an unreviewed submission. Every line is either a fix they claim, a fix they
did not claim, or a change nobody asked for. A file in the diff that no numbered issue of theirs
names is the first thing to ask about, and a file they claim to have changed that is **not** in the
diff is the second.

If no seed zip was supplied, say so and fall back to mtime forensics on the submitted zip (12.4
item 3), stating both its limits in the same sentence: a tool that preserves mtimes leaves no trace,
and an unchanged mtime supports "they did not rewrite this" and never "the content is right".

**Then the table, into `task.md`.** One row per numbered issue in their answer, plus one per Files
Changed entry:

```
## Submitter claims, verified
| # | Their claim | Where it should land | Measured | Verdict |
|---|---|---|---|---|
| 1 | Interface section removed from instruction.md | instruction.md, problem_statement.md | diff shows -31 lines, both files byte-identical | HOLDS |
| 2 | grader now requires raw_exit_code == 0 | tests/test.sh | grep shows raw_exit_code recorded, success expression unchanged | DOES NOT HOLD |
```

`HOLDS`, `DOES NOT HOLD` and `NOT CHECKABLE HERE` are the three values. **A claim that does not hold
is a finding in its own right** and it is a different finding from the underlying defect: the defect
is whatever pillar it violates, and the false claim is Secondary Requirement 5, metadata mismatch,
where `docs/reviewer-rubric.md:105` puts a writeup that does not match the actual diff.

**On a second or later round, the previous reviewer's findings get the same table.** The page renders
them (`sample_review_page.md:15`), and they are this round's checklist. Mark each **fixed**, **still
open** or **answered**, and do not re-file one they have addressed. The sample capture is exactly this
case: a note dated 8/16 listing seven asks, of which the next zip fixed two.

**Keep the round counter honest.** One counter per review, incremented once per submission you are
handed, and it is not the submitter's round number and not the platform's difficulty counter. All
three are different numbers with different reset rules (Step 10's warning, applied here).

---

### R4: The mechanical sweep, with the git gate first and alone

`docs/reviewer-rubric.md:95` says to check git state **before** assessing content, which makes it the
one pillar with an ordering instruction attached. Run it on its own so a result there cannot be
buried inside a sweep.

```bash
W="$R/work/environment/repo"
git -C "$W" fsck --unreachable --no-progress
git -C "$W" rev-parse HEAD                       # against [metadata] base_commit_sha
git -C "$W" remote -v
git -C "$W" worktree list
git -C "$W" stash list; ls "$W/.git/refs/stash" 2>/dev/null
ls "$W/.git/logs" 2>/dev/null
du -sh "$W/.git"
```

**Read the result against two bars, not one.** `:91` is the `Meets` line and `:95` is the Needs
Revision trigger, and they are one step apart. `fsck` printing objects is short of `Meets`. It
becomes the Major when those objects **expose the fix**, so read a couple before writing anything:

```bash
git -C "$W" cat-file -p <sha> | head -40
```

Golden content, a patched test file or the fix in any form is Pillar 5 and it stands alone without
the rest of the review. Objects carrying nothing about the solution are a note, not the verdict.
Remotes, worktrees and a HEAD/base mismatch are the Major with no read needed. Expect the read to
pay: `learning/unreachable-git-blobs.md` is a repo with no reflog, no stray refs and a clean tree
still holding dangling blobs of the golden file.

**Then the rest of the sweep, which `bin/preflight.sh` already runs against a review folder** with no
modification, confirmed 2026-08-18:

```bash
bash bin/preflight.sh "$R/work" -v
```

It runs `10-static`, `20-git`, `30-package`, `40-grader`, `50-restore-shape` and `60-answers` over
the bundle. Exit 0 is every check passing, 1 is a real defect, 2 is a check that could not run, and
**a check that could not run is not a check that passed**. `60-answers` targets a submitter answers
file that a review folder does not have, so expect it to skip.

What preflight does not cover, and this step still owes:

- **Pillar 4, network integrity, which no review on this machine has ever run.** Read the three
  `network_mode` values and `allowed_hosts` against `docs/harbor-framework.md:59,66` and the Section 8
  baseline. It is blocking rather than cosmetic: cista 172 ships `[environment] network_mode =
  "no-network"` and `docker build --network=none` on its own Dockerfile dies on the first `apt-get`
  layer with exit 100. A widened `allowed_hosts` is network left open, not a metadata nit. The other
  half of the pillar is measured in R6, where every run has the network off
- **Secondary Requirement 2, pinning**, which also has no reviewer check. Run the four
  reproducibility greps from pre-upload item 3 of `.claude/rules/01-workflow-steps-1-to-5.5.md`
  against `work/environment/Dockerfile`: no `apt-get upgrade`, every `pip install` pinned, every
  `pip install -e` target resolving inside `environment/repo`, no `git+https://` on a bare branch
- **Secondary Requirement 1, the timeout pair.** `[verifier] timeout_sec` against
  `tests/config.json` `execution.timeout_sec`. It arrives inverted in 10 of the 11 pristine extracts
  here, so it is the generator's default, and `docs/reviewer-rubric.md:101` still makes it a Minor.
  Word it as the arriving default the submitter did not correct, and name both numbers, which is what
  the rubric asks for (L73)

---

### R5: PR comparability, hunk level, both directions

Fetch the source PR's per-file patches through the API, page it, and compare changed-line sets in
**both** directions against `solution/golden.patch` and `tests/tests.patch`.

```bash
curl -s "https://api.github.com/repos/<owner>/<repo>/pulls/<n>/files?per_page=100&page=1"
```

Page until a page returns under 100. A 100-row page 1 of a 198-file PR produced a confidently wrong
finding once already (`learning/source-pr-cross-check.md`).

- A file list comparison is worthless. Three of elfuse 162's eleven out-of-PR hunks sat **inside**
  files the PR does touch, where a file-list diff cannot see them
- **This check runs one way only.** Extra material in golden that the PR never touched is the
  finding. Golden omitting a docs or changelog file the PR touched is the normal accepted shape at
  7 of 8 archived goldens, and it is L59, filed and withdrawn once already
- Getting this clean early is what removes quality score 1 from the table, because score 1 is
  reserved for deviation from the source content

---

### R6: The measurement battery, eight runs, network off

`docs/tasking-guide.md:349` says a reviewer need not run Harbor, the oracle, the NOP or a build.
Run them anyway. On mithril.js 2021 three of eleven notes were measurements no reading would have
produced and two of them were the lead findings.

Build once from `work/environment/Dockerfile`, then run every row on its own fresh copy with
`--network none`. `bin/local-run.sh` works against a review folder unchanged, confirmed 2026-08-18:

```bash
bash bin/local-run.sh "$R" --run
```

**It does not cover run 2, and its `thrice` row looks exactly like the thing that does.** Measured
2026-08-18 at `bin/local-run.sh:268-272`: `thrice` runs `solve.sh` in a `for i in 1 2 3` loop and
then invokes `test.sh` **once**, at `:341`. That is the weaker shape L69 says must never be reported
as an oracle result, because it exercises the oracle script and cannot see a `test.sh` that applies
`tests.patch` every run and restores nothing. No row in that tool runs the real protocol, so run 2 is
done by hand: three cycles of `solve.sh` **then** `test.sh` in one container, reading the reward each
cycle. The tool predates L69 by a week and was never updated (LEDGER L102).

| # | Run | Expected | Where the rule lives |
|---|---|---|---|
| 1 | **NOP**: `test.sh` on the untouched base tree | reward 0.0 AND a nonzero raw exit. A zero for the wrong reason proves nothing, so split the graded ids by whether their module compiles at base, or run the symbol audit and say which you did | Step 5.5 Run 1, `learning/verify-in-the-image.md` |
| 2 | **Oracle, the real protocol**: `solve.sh` **then** `test.sh`, three cycles, one container | 3 of 3 at reward 1.0 | 12.4 item 9, L69 |
| 3 | **Hostile delete**: apply the oracle, stub one stated requirement, re-run | reward 0.0, and **name the test id that caught it** | Step 5.5 Run 3 |
| 4 | **Gaming probe**: leave the solution unapplied, edit the assertion library or harness the graded tests call and `tests.patch` never creates | reward stays 0.0 | 12.5, `learning/agent-writable-test-infrastructure.md` |
| 5 | **`sh /tests/test.sh`**, never only `bash` | a reward file exists. On mithril dash rejected line 9, which sits before the trap, so the run wrote **no reward file at all** | 12.4 item 9, `learning/solve-sh-under-sh.md` |
| 6 | **Forced test edit**: apply `golden.patch` alone, run the repo's own suite, compare against base | no test green at base and red after golden | `learning/instruction-promises-the-suite-keeps-passing.md` |
| 7 | **Move the created file**: apply golden, move every file it creates somewhere the instruction also permits, re-run | the reward does not move. cista 172 went 21 of 21 to **4 of 21** | 12.4 item 8, `learning/graded-tests-that-import-the-deliverable.md` |
| 8 | **Determinism**: two fresh extracts, solve then verify in each, compare the per-test **pass sets** | identical pass sets. Read the sets and not the rewards, because a reward can hold at 1.0 while a different id fails each run | Secondary Requirement 9, 12.11 |

Runs 3, 4 and 7 mutate the tree to prove something. **Use `bin/hostile-probe.sh` and never a
hand-rolled `sed`**: it exits **3** with `THE BREAK DID NOT LAND`, and both wrong conclusions in the
mithril session came from a `sed` that silently matched nothing, one of them drafted as a blocking
finding (12.6).

```bash
bash bin/hostile-probe.sh "$R" --file <path> --break '<sed expr>' --expect-fail '<test id>' --record
```

**Two reads off run 2 that are not the reward.** Put the report's result total next to
`len(fail_to_pass) + len(pass_to_pass)` and count **distinct** ids against the 10 floor, because a
repeated id inflates a static list-length check while the true graded count is lower, which is
Pillar 2's own trigger at `docs/reviewer-rubric.md:59`. A gap is not automatically a defect: accepted
kvdex 245 declares 132 and reports 152 passed with 2 ignored. Materiality is what makes it a finding.
And do **not** read duplicated ids as padding: listing an id twice is strictly stronger than not
listing it, which is L60.

**On a compiled language, run 4's unapplied form is not available**, because the graded units name
symbols the base tree does not have and the compile dies before any assertion runs. Apply golden,
break one stated requirement in a way that still compiles, then neuter the assertion layer, and read
that against the same break without the neuter.

Write every result into `task.md` as it lands, with the number, the exit code and the command. A run
recorded as a sentence is a run somebody will have to repeat.

---

### R7: The content read

Only now read for content, because a finding you reached by reading is a Minor or an Observation
until it is measured, and R4 to R6 is where the measuring happened (12.2).

Read `instruction.md`, `environment/problem_statement.md`, `task.toml`, `tests/config.json`,
`tests/test.sh`, `tests/tests.patch` and `solution/golden.patch` **end to end rather than by grep**,
then build the mapping before writing a word about coverage. One row per stated requirement:

```
## Requirement to test mapping
| # | Requirement, quoted | instruction.md line | Graded by | Mark |
|---|---|---|---|---|
| 1 | "the stream sits on the sentinel after the end-of-value marker" | 24 | TestTairString/parse | covered |
| 2 | "unsupported module names abort the load" | 31 | none | uncovered |
```

Four marks and they carry different remedies. **Covered** and **weakly covered** are reads.
**Uncovered** is the coverage gap that promotes to Pillar 2 once the hostile probe holds reward at
1.0 with that requirement stubbed out. **Graded more strictly than stated** is overreach, fixed in
the tests rather than by writing the requirement into the instruction to justify the assertion.

Also in this step, and each with its own trap:

- **Instruction quality** is judged against the five personas and four red flags at
  `docs/guidelines.md:169-177`, never against the Section 5 answer-writing rules, which are scoped to
  form answers. libcrux 1165 was accepted with 24 em dashes in its instruction (L57)
- **Leakage and over-prescription.** Before advising the submitter to delete any name or literal from
  the instruction, **grep the graded tests for it and split the list**. On expressa 132 thirteen file
  paths had zero graded references and six literals had a graded assertion behind them, so the draft
  advice to delete the error strings would have traded a non-blocking instruction finding for a
  blocking alignment one. `docs/guidelines.md:99` exempts a genuine public or API contract and `:101`
  requires stating a required response shape
- **Read the graded tests' HELPERS, not only their assertions.** A barrier, a `waitFor`, a fixture
  builder or a coordinate finder can require a behaviour no assertion mentions, and for a failing
  implementation that precondition grades exactly like an assertion (pre-upload item 10)
- **The difficulty read, which is the one you do not make yourself.** Read the Difficulty Check panel
  and the counters rather than running a control. A control you run scores your model and not the
  ones the screen grades, so it is a ceiling and never a forecast, and redisshake 1005 carried a
  complete four-lever Not Fixable dossier with every lever at 0 of 4 and was **accepted** on that
  round. And do not read the bundle's own pass rates at all once you have found the grader broken:
  a verifier that writes reward 1.0 on a nonzero exit produces rates wrong in both directions

**The two shapes this file's main sequence does not fit:**

- **Valid as-is.** There is no rewrite, so R3's table has one row: are all seven compliance boxes the
  submitter ticked actually true against the files. `docs/tasking-guide.md` asks the reviewer to
  repeat the content review, sanity-check coherence, verify the metadata and confirm PR comparability
  even here. R4 to R6 still run and are worth more than usual, because the platform's difficulty evals
  do not re-run a Valid as-is task and a local run is the only check it has ever had
- **Invalid / Not Fixable.** **There is no zip on Path C**, so R2, R4, R5 and R6 have nothing to run
  against and the submission is their prose. The job is the three `docs/tasking-guide.md` asks:
  confirm each reported issue holds when you read the same files in the seed bundle, check their
  issue list matches what you see, and confirm the Not Fixable category applies. Then apply Section 12's
  own bar: they owed you a bucket, Structure or Difficulty, and a repeated `FAIL EASY` is not a
  Difficulty verdict on its own. Their evidence is the whole submission, so vague or incomplete is
  itself the finding (`docs/tasking-guide.md:209`)

---

### R8: Filing discipline

Two sweeps, in this order, over everything R3 to R7 produced.

**First the stock-defect sweep (12.5), because it is most of a review and it is checked rather than
discovered.** Eight defects, in `learning/stock-bundle-defect-baseline.md`. Two of the eight are
decided structurally in a minute and before any container run: the brace-sliced report cannot fire
when `grading.parser.framework` is `custom`, and the `python3`-behind-`|| true` defect does not apply
when the verifier's `python3` is a hard dependency of a non-optional install line. cista 172 was six
of eight. **Report an absence with its reason**, because it tells the submitter which of the usual
suspects they can stop worrying about (L66).

**Then the six per-finding checks (12.7) over every candidate**, and the first of them is Step 0:

0. `learning/LEDGER.md` was read at R1, in full. If it was not, stop and read it now
1. Open the cited file at the cited line. A wrong quote or line is grounds to drop the finding
2. Read the cited rule's actual sentence. Watch for a rule paraphrased stronger than it reads, and
   for a **practice** read as a rule: `.claude/rules/11-verifier-hardening.md:7` defines practice as
   "not in `docs/` ... applied with judgment"
3. Check scope. A workspace rule applied outside its stated scope is L57
4. Check the arriving bundles. Eleven pristine extracts on this machine, the eight under
   `_archive/*/download/original/` and the three under `review_tasks/*/download/original/`. A value
   identical across all eleven is the generator's default and not a submitter act (L61 to L63).
   **Measure against `download/original/`, never against `work/`**, or you are comparing this bundle
   to other people's rewrites and calling the difference a defect. A generator default is still a
   finding when `docs/` names the value as a defect: the baseline decides the **wording** and never
   the verdict (L73)
5. Check the remedy. The remedy is an instruction someone will follow, so it can be wrong in a way an
   observation cannot. Would following it make the bundle worse? L60 is a finding whose fix would
   have weakened the verifier
6. Word every finding against the **bundle**, not against the submitter, unless their answers are in
   front of you and you have read them. With the page in hand that is now usually possible, which is
   the one thing R1.5 buys that changes how a note is written

An 8-dimension fan-out over mithril produced 77 candidates and adversarial verification refuted
**40**, four of them already written into the answer file. Every one failed a check on that list.

---

### R9: Grade, count, and derive the verdict

Severity is assigned per finding, the counts are arithmetic, and the arithmetic lives in the record
block at the bottom of `review_answer.txt` and in `task.md`. It never appears in the paste (12.2).

```
## Rubric tally
| # | Finding | Severity | Pillar or requirement | Provenance | Blocks alone? |
|---|---|---|---|---|---|
| 1 | grader writes reward 1.0 on a nonzero exit, exploited | Major | Pillar 3, reward-hackable | measured, run 4 | yes |
| 2 | [verifier] 300 against execution 1800 | Minor | Secondary 1 | read, baseline 10 of 11 | no |
| 3 | golden omits the PR's CHANGELOG | Observation | none, L59 | read | no |
```

**The rule, from `docs/reviewer-rubric.md:15-19`, and both paths must be clear to accept:**

- **One confirmed Major is Needs Revision on its own** (`:17`), whatever else the bundle gets right
- **Five or more Minors across any combination of the eleven Secondary Requirements is Needs
  Revision** on systemic low quality (`:19`). They accumulate across different requirements, so one
  problem found in four places is one Minor and four different requirements is four
- **One to four Minors is an Accept, and the coaching comments are mandatory** (`:19`, `:99`). An
  Accept with an empty written field and four Minors on the page is an unfinished review

**Provenance decides how far a finding can travel.** A Major rests on something you ran in the
container or on something the artifact shows. A finding you reached by reading is a Minor or an
Observation until it is measured. One Major is the whole verdict, so a suspicion promoted to Major
invents a Needs Revision that nothing supports. Two things follow: Accept is an outcome to reach when
the counts allow it and not a failure to find enough, and a bundle that never made you run anything
is a bundle whose findings are all reads.

**Observation is this workspace's own word and it earns its place**, because the rubric has no bucket
for something true and not actionable. Say plainly that an observation is not counted toward the
five, or a careful review that files six of them reads as the systemic-quality failure it did not
find.

**Then the bucket** (`docs/reviewer-rubric.md:25-31`): Fixable, Unfixable - Structure, or
Unfixable - Difficulty. Q1 has no control for the last two, so the bucket goes in the first line of
the written answer and gets tagged in the error categories, **PR Scope Violation** for Structure and
**Task Difficulty** for Difficulty. Lumping the two is what `:31` says sends ECs into three or more
unpaid revision loops on tasks that were never fixable.

**Then the score, which cannot disagree with the verdict.** `docs/tasking-guide.md:453-459` maps 1 and
2 to Needs Revision and 3 to 5 to Accept. A confirmed Major or five Minors lands at 2, with 1 reserved
for deviation from the source content, an Accept carrying one to four Minors is a 3, and an Accept
carrying **none** is the 4 or 5 case, "no significant issues" and "reference-quality" (`:458-459`).
Zero Minors is a real Accept and not an unfinished count, so do not manufacture a Minor to fill the
coaching field. A bundle
whose golden and tests reproduce the PR exactly cannot be a 1 however many verifier defects it
carries, which is what R5 settled.

**Two verdict-shaped things that are not your verdict.** A validity answer already reading **Invalid
Difficulty** is the platform's, written at the four-check cap, and the submitter was told to resubmit
unchanged and leave it alone, so no argument was owed and its absence is not a finding. And a **Needs
Revision restarts their difficulty budget at zero** (`docs/faq.md`), which makes sending a task back
materially cheaper for them than a fourth difficulty check. That is not licence to send a sound bundle
back and it moves no count above. It is the reason not to soften a Needs Revision the counts already
support.

---

### R10: Write the answer

Build `review_tasks/<name>/answers/review_answer.txt` from the Section 6 Path D template, against the
**seven** questions the live form asks. Section 12.8 owns how a note is written; two things belong
here because they are sequence.

**The seven questions, in the live form's order** (`sample_review_page.md:417-467`, and
`docs/tasking-guide.md:401-459` describes the same seven):

1. Verdict: Accept / Needs Revision / Reject
2. If Accept: the six confirmations. Tick only what you verified
3. If Needs Revision: the 19 error categories. Smallest set that covers findings you wrote a note about
4. The written answer. This is the review
5. **Acknowledgement of Submitter Rebuttal.** Three options: it did not change the outcome, it changed
   the outcome, or no rebuttal comments available. Open the left-hand panel and read their notes
   before answering, which is what the question is for
6. Overall quality, x/5
7. How long the review took, in minutes. Ask the user. Never invent it

**Then the closing actions, in this order and none of them optional:**

```bash
# 1. humanizer over every free-text answer in the FILE, not the chat draft
# 2. the Section 5 grep, whole file, no exclusions
grep -nE 'Q(9|1[0-5])\b|/15|→|←|↔|–|—|\*\*|oracle_spec_faithfulness|oracle_spec_gap|test_coverage|test_faithfulness|coverage_gap|weak_check|self_contained|prescriptiveness|\brealism\b|\brubric\b|\baxis\b|\baxes\b|adjudicat|\b(DISCUSS|REMOVE)\b' "$R/answers/review_answer.txt"

# 3. the scoring-ladder grep, over the PASTE only
sed '/Not part of the paste/,$d' "$R/answers/review_answer.txt" |
  grep -nE 'Major Pillar|Secondary Requirement|Pillar [0-9]|soft signal|Minor violation|reviewer.?flag|\brubric\b'

# 4. the boilerplate check: your opener, your measured-versus-read sentence, your closing note
for s in "<opening sentence>" "<measured versus read sentence>" "<closing note first sentence>"; do
  grep -rnF "$s" review_tasks/*/answers/review_answer.txt
done
```

A hit in check 4 against a review of a **different** bundle means the sentence is boilerplate and gets
rewritten. All three finished reviews here open on the same ten words and all three carry "I built the
image and ran the bundle, which a reviewer is not required to do" verbatim, which is the
mirrored-language soft signal at `docs/reviewer-rubric.md:121` (Section 5.1).

---

### R11: Audit, submit, close

**The audit is a separate pass and it is not optional.** Per-finding rigour is measurably not
sufficient: an adversarial pass over a finished, careful 11-note review left **1 note confirmed and 9
weakened**, none refuted, and added two blocking findings the review had never run a check for. Every
error was in the second sentence of a note. Run all five checks from 12.10 over the whole document:

1. **Grep your own answer for baseline claims.** Any sentence shaped "N other bundles do X" names the
   tree it was measured against, in the sentence. That review shipped two `work/` baselines while
   using the correct framing eleven lines later in its own closing note (L72)
2. **Read every remedy against every other one.** Two notes that are individually right can be jointly
   impossible. There, one note asked for the graded tests to be relocated and another said keep them
   where the PR author put them, about the same six ids
3. **Re-derive every number from the live bundle**, not from `task.md` and never from an earlier
   draft. A figure you cannot reproduce on demand comes out
4. **Test each stated mechanism by removing the thing it names.** "These survive because `/app` is a
   git repository" died when `/app/.git` was deleted and the case still scored 15 of 15
5. **Walk the run list, not the finding list.** Ask which invocations were never tried. Both new
   blocking defects sat behind R6 runs 2 and 5, and no amount of re-reading the notes would have
   found either

Then hand the user the answer, in the form's order, saying which findings are measured and which are
read.

**Then close the review, in one action:**

1. The verdict, the score and the date into `task.md` under a dated closing heading, plus the last
   row of every table this file asked for
2. The `INDEX.md` row set to `review-accepted`, `review-needs-revision` or `review-rejected`
3. **Harvest.** Two questions in writing: what did this review prove that no note yet says, and what
   did it disprove that a note still says. A new fact gets a `learning/` note with frontmatter plus a
   row in `learning/README.md`. A disproved claim gets a `LEDGER.md` row, numbered from the **max** of
   the existing ids and never from the count (L78). This is when that rule fires
4. **When the verdict was Accept, harvest the bundle.** A **Fixable** submission you accepted is the
   case worth harvesting, because you hold both zips and R3 has already scored each of their claims
   against the seed-versus-submitted diff. The four headings, the row shape and the reasoning are in
   `learning/bundles-i-accepted-as-reviewer.md`; this step is the trigger. Three lines stay inline
   because they are the ones a hurried close gets wrong:

   - **NEVER harvest a forced Accept.** When the maximum-revisions dialog has fired and Reject is
     unavailable for the workflow, `docs/tasking-guide.md:366` tells you to select Accept and
     document the outstanding issues for the adjudicator. That is an Accept meaning the bundle does
     **not** meet standards, and writing it into a file about what the bar lets through inverts the
     file. Record it in `task.md` and the calibration row, tagged as forced, and harvest nothing
   - **NEVER harvest an Accept you reached by reading.** The harvest is worth more than a received
     acceptance only while the battery table is filled in, and it records the **command** per row
     rather than a tick, because a row that ran the wrong invocation reads exactly like a clean one.
     Run 2 is the live case: `bin/local-run.sh`'s `thrice` row looks like the oracle protocol and is
     not it (L102), and a careful review already reported 3 of 3 from it while the real protocol
     scored 1 of 3
   - **NEVER let the archive move contaminate the Section 8 baseline.** That is item 6, and the
     mechanism is the path rather than anything you write here

5. **Fill in the review's `learning/review-calibration.tsv` row.** Reviews get their own file rather
   than a row in `learning/calibration.tsv`, because that file's 39 columns are bundle-shaped
   (`f2p`, `p2p`, `restore_shape`, `zip_mb`, `t_rewrite`, `upload_rounds`) and a review produces none
   of them. Its eighteen columns are: review, submitted_zip_sha256, seed_supplied, language, runner,
   their_verdict, my_verdict, score_given, majors, minors, observations, findings_filed,
   findings_withdrawn, battery_rows_run_of_8, stock_defects_present_of_8, review_minutes, round,
   outcome. **A row left at its mid-flight values is worse than a missing one**, because the next
   review reads it as measured. The three rows already in it carry `?` in every column nobody
   recorded at the time, which is the honest state and not a placeholder to guess at
6. **Move the folder to `_archive/reviews/<Original Directory Name>/`**, whole, with `git mv`.
   `review_tasks/` is gitignored and `_archive/` is not, so this move is the moment the review
   becomes recoverable. **The `reviews/` level is load-bearing and not tidiness.** A review's `work/`
   is a copy of another EC's submitted bundle, and `.claude/rules/09-task-toml-reference.md` reads
   its column-three baseline off `_archive/*/work/`, so archiving a review flat would silently put
   someone else's tree into the population that answers "what a submitter here shipped". One extra
   path level keeps it out, because `*` does not cross a `/`. Column two is the opposite case and
   wants the bundle, so that file's loop globs `_archive/reviews/*/download/original` explicitly.
   No review has ever been archived, so all four folders under `review_tasks/` are one delete from
   gone, three finished and one that holds a submission zip and nothing else. **Check the zip sizes
   before the move**: GitHub's hard limit is 100 MB and `.gitignore` already carries four
   `_archive/` zips that crossed it, so a review carrying two zips is likelier to hit it than a task
   carrying one. Add any over-limit zip to `.gitignore` the same way, with the same comment, and let
   the extracted `seed/` and `original/` trees carry the record
7. Repoint anything that cited the old path: `grep -rl 'review_tasks/<name>' --include='*.md' .`, then
   re-run `bin/doclint.sh`

---

### The bookkeeping a review owes

All of it lives in `review_tasks/<name>/task.md`, in this order. The three finished reviews carry
between four and seven of these and no two carry the same set, which is what a template is for.

```
# Peer review - <Original Directory Name>

- Seed zip, submitted zip, both sha256, entry counts, mtime spread
- Source PR, base commit, language, runner
- Round N of this review, and the date the submission was handed over

## Submitter answers                 verbatim, or what you did to get them
## learning/ notes applied           | Note | What it predicts here | Command that settles it | Result |
## Submitter claims, verified        | # | Their claim | Where it should land | Measured | Verdict |
## Previous round findings           | # | Their finding | fixed / still open / answered |   (round 2+)
## mtime forensics                   with both limits stated
## Git hygiene                       | Check | Command | Output | Meets (:91) | NR trigger (:95) |
## PR comparability, hunk level      | File | PR | bundle | only in PR | only in bundle |
## Measurement battery               | # | Run | Command | Result | Exit |   all eight rows, NOT RUN where true
## Requirement to test mapping       | # | Requirement | line | Graded by | Mark |
## Stock defect sweep                | Defect | Present | Evidence or the structural reason it cannot fire |
## Rubric tally                      | # | Finding | Severity | Pillar or requirement | Provenance | Blocks alone? |
## Findings withdrawn                | Finding | Why it was dropped | Which 12.7 check caught it |
## Open caveats                      | Caveat | Stated in round | What would retire it | Retired? |
## Superseded answers                | Round | Verdict given | Score | Archived to | Notes moved to task.md |
## Audit pass                        the five 12.10 checks, each with what it changed
## Closing                           verdict, score, date, review minutes, calibration row written,
                                     and on an Accept the harvest row and where it went
```

**`bin/new-review.sh` scaffolds this list and is its twin.** The two move in the same edit, the same
way a `.mdc` and its `SKILL.md` do. Neither says how many sections there are, deliberately, because
a hardcoded count is what desynchronises them on the next addition.

**`## Git hygiene` exists because R4 runs its gate first and alone, and until 2026-08-18 the output
had no named home.** expressa 132 put it near the END of its `task.md`, which is the opposite of an
early gate. Keep the two bars in separate columns, `Meets` at `docs/reviewer-rubric.md:91` and the
Needs Revision trigger at `:95`, so a noisy `fsck` cannot be silently promoted to a Major. Any
dangling object gets a `git cat-file -p <sha> | head -40` and the row records **what it was**.

**`## Open caveats` is not new practice, it is practice this template was missing.** Two of the three
finished reviews carry one anyway, so leaving it out was a regression rather than a simplification. A
finding gets a file:line and a probe; a caveat gets a clause at the end of a paragraph that each
round writes a little shorter because it was in the last one too, until it is gone and its absence
reads as the doubt having been settled (`learning/stated-caveats-decay.md`, L52). Seed it with the
one this workspace is actually carrying:

```
| Caveat | Stated in round | What would retire it | Retired? |
|---|---|---|---|
| the Accept branch shows five confirmation items in two truncated pastes where docs and the template carry six | first stated 2026-08-11, still open 2026-08-18 | an untruncated capture of the Accept branch, taken with the verdict radio set to Accept | NO |
```

**`## Superseded answers` closes the same hole the submitter path already patched.** `grep -in
'supersed'` over this file returned nothing until 2026-08-18. A round-2 review legitimately changes
verdict, Needs Revision then Accept, and `review_tasks/` is gitignored exactly the way `tasks/` is,
so the overwrite is the only copy there was. libcrux 1165 moved Fixable to Invalid in round 5 and
**17 numbered issue blocks stopped existing**, surviving only because `task.md` carried them in
prose. So before writing round N+1's answer, copy the current one to
`answers/superseded/review_answer.round<N>.txt` and confirm every numbered note in it also exists in
`task.md`. The corollary carries straight over: **every number in `review_answer.txt` has to be
re-derivable from `task.md`**, because a full rewrite silently reverts figures and the arithmetic
checks pass on a reverted value.

**Name all eight battery rows every time, with a result or the words NOT RUN beside each.** A table
with six green rows looks exactly like a table with eight minus two, and nothing in the loop reads a
table for missing rows. hulak 118 shipped five batteries across four rounds with the gaming probe
absent from every one of them, through four rounds of platform checks and a human reviewer (L85).

**`## Findings withdrawn` is the highest-value section in the file** and it is the one nobody writes.
Forty of 77 candidates were refuted on one review, and the reason each died is what stops the next
review re-deriving it.

---

### What of `bin/` a reviewer can use

Measured 2026-08-18 by running each one against `review_tasks/20260717_182400__felixguendling_cista__172`.
Most of the suite was written for `tasks/` and works on a review folder unchanged, which is worth
knowing before anybody writes a second copy of it.

| Script | On a review folder | Notes |
|---|---|---|
| `bin/new-review.sh` | the R2 bootstrap | wraps `new-task.sh --dest review_tasks`, adds the seed extract and the `task.md` scaffold |
| `bin/new-task.sh --dest review_tasks` | works | its `--i-am-starting-a-real-task` guard only fires under `tasks/` |
| `bin/pristine-freeze.sh` / `bin/pristine-verify.sh` | work | called by the bootstrap. They only ever target `download/original`, which is why the seed is extracted separately |
| `bin/preflight.sh <review>/work` | works, all six checks | R4. `60-answers` skips, because a review folder has no `submission_answer.txt` |
| `bin/local-run.sh <review> --run` | works | R6 rows 1, 3 and the agent-collision cases. **Not run 2**, see the warning there |
| `bin/hostile-probe.sh <review> ...` | works | R6 rows 3, 4 and 7. Use it rather than a `sed`, always |
| `bin/coverage-map.sh <review>` | works | R7's mapping, as a first pass. Exit 1 means it found gaps, which is a result rather than an error |
| `bin/nop-audit.sh <review>` | works, slow | builds an image, so budget for it |
| `bin/learning-query.sh` | works | remember it skips `LEDGER.md` by name, so it can never return a LEDGER row |
| `bin/doclint.sh` | works | run it after R11 item 7, the repoint |
| `bin/rezip.sh`, `bin/pre-send.sh`, `bin/work-vs-zip-drift.sh`, `bin/answers-build.sh` | **submitter only** | they build, gate or compare an upload zip, and a review has none |
| `bin/task-doctor.sh`, `bin/session-start.sh <dir>` | **submitter only** | they reconcile the `tasks/` register. `session-start.sh` with no argument is still the right R1 command |

**Nothing here needs a reviewer-only rewrite.** The one gap the bootstrap fills is the second pristine
extract, and the one gap left open is run 2 of the battery, which is done by hand.

---

### The register

`INDEX.md` has no row for a review and `_archive/` holds none, so both are added by this file. A
review row goes in the `## Reviews` table with the same discipline as a task row: the Status cell
holds one token and nothing else.

| Status | Means |
|---|---|
| `review-claimed` | The zips are on disk and the folder exists. Nothing read yet |
| `review-measuring` | R2 to R6 are running |
| `review-writing` | The findings are graded and the answer is being written |
| `review-submitted` | The answer is in the platform. Waiting to see whether it comes back |
| `review-accepted` | Submitted as Accept, and closed |
| `review-needs-revision` | Submitted as Needs Revision, and closed |
| `review-rejected` | Submitted as Reject under the maximum-revisions dialog, and closed |

---

### Hard boundaries, reviewer side

In force on every review, in every round.

- **Never edit anything under `download/original/` or `download/seed/`, and never run a command
  there.** Both are pristine extracts and together they are the diff target
- **Never fix the bundle.** `work/` is where git, patch and docker commands run. A change you make
  there is a probe, it is recorded as a probe, and it never becomes a sentence describing what the
  bundle does
- **Never write a finding before `learning/LEDGER.md` has been read in full** (L64)
- **Never file a metadata finding without the eleven-bundle baseline, measured against
  `download/original/`** (L61, L72)
- **Never promote a read to Major.** One Major is the whole verdict
- **Never put the scoring ladder in the paste.** Pillar names, requirement numbers and counts live in
  the record block. Four soft signals in one review is a Major against the reviewer
- **Never hand-roll a mutation probe.** `bin/hostile-probe.sh` exits 3 when the break did not land
- **Never report `solve.sh` three times as an oracle result.** The protocol is solve then verify,
  three cycles, one container (L69)
- **Never select Reject** unless the maximum-revisions dialog is showing AND the submission still
  needs work
- **Never write that something was unavailable without saying what you did to get it**
  (`docs/reviewer-rubric.md:123`). The page renders the submitter's answers and every eval panel, so
  the honest sentence is now almost always a different one
- **Never invent the review-duration number.** It comes from the user
