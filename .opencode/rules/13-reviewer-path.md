_Owner of CLAUDE.md **Section 12**. Loaded every session._

## 12. The Reviewer Path

Peer review is **in scope**. It was not until 2026-08-11, and `CLAUDE.md` still said so while two
reviews were being run; that line is now corrected. Everything here was established on mithril.js
2021, expressa 132 and cista 172. The **sequence** those three reviews had to improvise is now
Section 13, `.claude/rules/14-reviewer-workflow.md`, as steps R1 to R11, and two of the form findings
they produced were reversed on 2026-08-18 by a capture of the whole reviewer page (12.2, 12.3). Evidence and open caveats in `learning/reviewer-path.md`.

The reviewer is a second Expert Contributor who repeats the submitter's document and logic review,
reaches an **independent** verdict, and returns Accept / Needs Revision / Reject plus a 1-5
Submission Quality Score. Two `docs/` tabs govern this path and they do not overlap.
`docs/tasking-guide.md:345-459` is the source of truth for the **form** - the questions, the 19 error
categories and the 1-5 score table. `docs/reviewer-rubric.md`, added to the Hub on 2026-08-12 and
arriving here in the 2026-08-13 re-export, is the source of truth for the **verdict** - what counts
as a defect, how severe it is, and the arithmetic that turns a pile of findings into Accept or Needs
Revision. It also sets a bar on the reviewer's own written assessment (12.8). Until it existed this
section had a run list and no threshold behind it, so every Major, Minor and count below is
documented policy rather than a workspace convention.

### 12.1 Folder discipline

Reviews live in `review_tasks/<Original Directory Name>/`, a sibling of `tasks/`. `CLAUDE.md` used
to propose `reviews/`; the name in use is `review_tasks/` and it is gitignored the same way `tasks/`
is. The shape is the submitter shape minus `upload/`:

```
review_tasks/<Original Directory Name>/
  task.md                    # the evidence record behind the answer
  download/
    <seed_id>_submission.zip        # the task as ISSUED to the submitter, from the page's first zip field
    <submission_id>_submission.zip  # what the submitter built, from the re-upload field
    seed/                    # pristine extract of the SEED. NEVER edited, no commands run in it
    original/                # pristine extract of the SUBMITTED bundle. NEVER edited, no commands
  work/                      # copy of original/, every command runs here
  answers/
    review_answer.txt        # the Path D template, Section 6
```

Every hard boundary from the submitter path still applies to `download/original/`. A reviewer does
not fix the bundle, so `work/` exists to run git and patch commands in, not to edit.

### 12.2 The live form, and how findings become a verdict

The form is **seven** questions, exactly the seven `docs/tasking-guide.md:401-459` describes. This
section said four until 2026-08-18 and that was wrong. The rule that decides the verdict is the
second half of this section.

| # | Question | Notes |
|---|---|---|
| 1 | Verdict: Accept / Needs Revision / Reject | **Reject only** when the "maximum revision reached" dialog is showing AND it still needs work |
| 2a | If Accept: confirm the six requirements | conditional on Q1. Tick only what you verified. Two of the six are absolute and four are not, see the Accept-branch note below |
| 2b | If Needs Revision: Error Categories | conditional on Q1. The 19 labels at `docs/tasking-guide.md:418-436`, internal tracking only |
| 3 | Explain in more detail what revisions are needed | conditional on Q1. The written answer, and the whole substance of the review |
| 4 | **Acknowledgement of Submitter Rebuttal** | `sample_review_page.md:433-441`. Three options: it did not change the outcome, it changed the outcome, or no rebuttal comments available. Open the left-hand panel and read their notes first, which is what the question is for |
| 5 | Overall quality of the submission, x/5 | 1-2 send back, 3-5 accept |
| 6 | **How long did it take you to complete this review**, in minutes | `sample_review_page.md:467`. From the user. Never invent it |

**The four-question claim is retired and its mechanism is understood** (LEDGER **L100**). Two captures
on 2026-08-11 showed neither the rebuttal field nor the duration field, and this section read that as
the live form disagreeing with `docs/`. `sample_review_page.md`, a conversion of the whole reviewer
page taken 2026-08-18, carries both. Both 2026-08-11 pastes were **visibly truncated documents** -
`learning/reviewer-path.md` says so about them for a different reason, and one of them breaks mid-word
at "Oracle solution matches the inst" - and truncation drops trailing fields, which is exactly where
those two sit. So the absences were an artefact of the capture and `docs/` was right throughout.
**Answer both fields rather than carrying them as unanswerable.**

The same capture explains the other open caveat without settling it. Q2a, Q2b and Q3 are **conditional
on the verdict radio** and do not render until one is picked, which is why the 2026-08-18 capture,
taken with no verdict selected, shows none of the three. So an Accept-branch item count still cannot be
read off it, and the cista reading of five confirmation items rather than six stays open. Keep all six
in the template; the cost of carrying the sixth is zero because the branch only matters on an Accept.

The Q2b list is exactly the 19 labels at `docs/tasking-guide.md:418-436`, in that order, and the
platform calls them "for internal tracking only", which is worth knowing before agonising over a
borderline tick.

**Picking the Q2b boxes.** `docs/tasking-guide.md:416` adds that the labels do not replace the notes,
so tick the smallest set that covers findings you actually wrote a note about, and never tick one for
something you only suspected. They are ticks and they do
not get narrated: walking the label list box by box inside the Q3 answer is the rubric-aware framing
`docs/reviewer-rubric.md:121` scores against you. Three of the nineteen sit on checks this path runs
and are otherwise unglossed here. A wrong `network_mode` or a widened `allowed_hosts` is
**Environment**, with **Uses Internet** as well when a graded test needs egress (12.4 item 4). An
unpinned base image or dependency is **Pinning Issues** (Secondary Requirement 2, 12.11). A
`tests.patch` that does not apply, or no restore before it, is **Test Build Issues**. Reach for
**Other** when nothing fits rather than stretching a label onto a finding it does not name. The
selection discipline is technique from an external reviewer prompt pack, not from `docs/`.

**The six are not six equal bars, and the rubric below is what tells them apart.** Two of them
restate Major Pillars and are absolute: *Does not leak solution information* is Pillar 3
(`docs/reviewer-rubric.md:61-71`) and *Oracle solution matches the instruction requirements* is
Pillar 1 (`:37-47`), so either one being false is Needs Revision whatever the rest of the bundle
looks like. The other four restate things the rubric scores as Minor - a coverage gap (`:104`)
against *Tests every requirement in the instructions*, ambiguity (`:108`) against *Test requirements
are specified in the instructions*, a templated instruction (`:107`) against *Does not appear
generated by an LLM*, and over-prescription (`:106`) against *Instructions are not overly-prescriptive*.
A task carrying one to four Minors is a real Accept (`:99`), so a bundle you are correctly accepting
can leave one of those four boxes false. Tick what you verified and nothing else, leave that box
unticked, and write the Minor into the answer as the coaching comment the rubric makes mandatory. The
form reads stricter than the rubric on those four, so name the box you left and why rather than
ticking it to make the page look finished.

**The verdict rule, which this section did not have until the 2026-08-13 export.**
`docs/reviewer-rubric.md:15-19` gives two independent paths to Needs Revision and **both** have to be
clear before you may accept:

- **One confirmed Major.** A single violation of any of the five Major Pillars is Needs Revision on
  its own, whatever else the task gets right. `:17` defines Major as the task being gameable,
  unsolvable, or not verifying what it claims, and says severity overrides everything else
- **Five or more Minor.** Five violations across any combination of the eleven Secondary Requirements
  is Needs Revision on systemic low quality (`:19`). They accumulate across different requirements,
  so one problem found in four places is one Minor and four different requirements is four
- **Zero Minor is an Accept too, and the rule reads that way rather than the other way.** `:19` says
  tasks with 1 to 4 Minors **may** be accepted with mandatory coaching, which sets what a small pile
  costs and does not make Minors a precondition for accepting. A bundle with no Major and no Minor is
  the score 4 or 5 case at `docs/tasking-guide.md:458-459`, "no significant issues" and
  "reference-quality". Do not go looking for a Minor to justify an Accept
- **One to four Minor is an Accept, and the coaching comments are mandatory** (`:19` and `:158`).
  This is the clause that changes the shape of an Accept here. An Accept is no longer a short
  paragraph saying the bundle looks sound: the Minors go into the written field carrying the same
  evidence a Needs Revision note carries, worded as coaching rather than as a required change

So count before you write, and keep the count where you can check it. The five pillars, the eleven
requirements and which of them a review here already runs are in 12.11.

**The three severity words, and what each one does.** This is where a finding gets graded, not in
12.8 where it gets written up. Two of the words decide the verdict and one decides nothing.
**Major** is a violation of one of the five pillars and a single one is Needs Revision by itself, so
a Major leads the answer and its note says plainly that this one item blocks acceptance. **Minor** is
one of the eleven Secondary Requirements and they accumulate, so what a Minor needs is a place in
your count rather than a label in the paste. **Observation** is this workspace's own extra word and
it earns its place, because the rubric has no bucket for something true and not actionable: say
plainly that an observation is not counted toward the five, or a careful review that files six of
them reads as the systemic-quality failure it did not find. The old word **blocking** retires into
Major, and its test survives as an ordering rule, so the Major that would fail a platform check on
its own is the one that leads.

**Where a finding came from decides how far it can travel.** 12.11 applies this twice already, where
a coverage gap you read is Minor and one the hostile probe proves by holding reward at 1.0 is Pillar
2, and it holds generally. A Major rests on something you ran in the container or on something the
artifact shows. A finding you reached by reading the files is a Minor or an Observation until it is
measured, and an older broken version of the repo, a warning in an automated report, or a defect
another bundle carried is not evidence about this one. One Major is the whole verdict, so a suspicion
promoted to Major invents a Needs Revision that nothing supports. Two things follow. Accept is an
outcome to reach when the counts allow it, not a failure to find enough, and a bundle that never made
you run anything is a bundle whose findings are all reads. And the provenance goes per finding in the
record block, beside the severity, because the single measured-versus-read sentence 12.8 asks for in
the paste tells the submitter that some notes were measured and not which. Saying inside a note, in
plain words, that you reproduced the thing is fine and is the point of that sentence. The intake bar
is technique from an external reviewer prompt pack rather than from `docs/`; the promotion mechanic
under it is the rubric's.

**Keep the tally in your record and out of the paste.** `docs/reviewer-rubric.md:121` lists
rubric-aware framing among the six soft signals of an LLM-written review, and four signals in one
review is a Major against the reviewer (12.8, and Section 5.1). "Three Minor violations across
Secondary Requirements 2, 5 and 9" is exactly that framing. The pillar name and the requirement
number are part of the tally, so they stay in the record with it and never appear in the sentence
that states the defect. Do the arithmetic in `task.md` and in the record block of
`review_answer.txt`, then say the same thing to the submitter in ordinary words: how much is wrong,
whether any single item blocks acceptance on its own, and what the shortest route to an Accept is.

**Three buckets, not two, and the live form has a control for none of them**
(`docs/reviewer-rubric.md:25-31`). Before assigning severity, decide whether the task is **Fixable**
(mechanical or content-level, and the EC can correct it inside scope), **Unfixable - Structure** (the
only fix changes or reduces the source PR, or the environment holds something ECs may not touch), or
**Unfixable - Difficulty** (genuinely too easy or too hard and not recalibratable inside the PR
scope). `:31` is blunt about why the split matters: lumping the two Unfixable kinds together as
"invalid" is what sends ECs into three or more unpaid revision loops on tasks that were never
fixable. Q1 offers Accept, Needs Revision and Reject and nothing else, so the bucket is carried by
the answer rather than by a button. Choose Needs Revision (Reject only under the maximum-revisions
dialog), tag **PR Scope Violation** in Q2b for Structure or **Task Difficulty** for Difficulty, name
the bucket in the first line of the written answer, and do not ask for a revision the EC is not
allowed to make.

**Do not tag Unfixable - Difficulty from your own reading or your own run.** A control you run scores
your model, not the ones the difficulty screen grades, so it is a ceiling and never a forecast.
redisshake 1005 carried a complete four-lever Not Fixable dossier with every lever measured at 0 of 4
and was **accepted** on that round (`learning/when-fail-easy-is-not-not-fixable.md`). Run the cheap
tell first: a source PR whose own author got something subtly wrong contains a trap, and a trap means
the ceiling is not structural.

**And do not lean on the bundle's own numbers either, once you have found the grader broken.** A
verifier that writes reward 1.0 on a nonzero exit, or that loses its report to a stray log line,
produces pass rates wrong in both directions, so a recorded rate on a bundle carrying one of those
defects measures the grader rather than the task. LEDGER L27 and L44 are the hard direction of the
same thing, a package that did not compile producing `pass_at_k` 0/3 and an arrival rating that never
described the problem. File the grader finding first and say the difficulty numbers cannot be read
until it is fixed, rather than reading them and calling the result drift. The framing is from an
external reviewer prompt pack, the measurements are ours.

**A validity answer reading Invalid Difficulty is the platform's verdict, not the submitter's.** As of
2026-08-14 a task gets four difficulty checks per review cycle, and at the fourth one that returns a
result without passing the platform changes the submitter's answer on the validity question to **Invalid Difficulty**
itself and routes the task to review as it stands (`docs/faq.md`, "Difficulty checks are now capped").
The submitter is told to resubmit unchanged and leave that verdict alone, so a bundle arriving that way
carries no argument from them and none was owed. Do not read it as a Not Fixable case they made and
then find thin, and do not treat the missing dossier as a finding. It is not a rejection either, and
the FAQ says a human reviewer still reads it, which is you, so review the bundle on its own terms and
let the counts above decide the verdict the way they always did. One thing worth knowing before you
look the value up: `docs/tasking-guide.md` was not updated in that release and still lists exactly three
answers to the validity question, so a fourth value on the form is drift in the docs rather than
something the submitter invented. Nobody here has yet been handed a task in this state, so this
paragraph is documented policy read forward, not experience.

**Sending the task back restarts the submitter's difficulty budget at zero.** The count runs within one
review cycle and a reviewer bounce restarts it (`docs/faq.md`), which makes a Needs Revision materially
cheaper for the submitter than a fourth difficulty check, since the fourth check ends the cycle at
Invalid Difficulty whatever the bundle deserved. That is not licence to send a sound bundle back, and
it does not move a single count in 12.2. It is the reason not to soften a Needs Revision the counts
already support on the grounds that it looks expensive to them, because on this policy it is the
cheaper of the two things that can happen next.

### 12.3 What arrives with the zip, and what a second round adds

**The zip does not arrive alone, and this section said it did until 2026-08-18** (LEDGER **L101**).
Three reviews here received a bare zip and one submitter confirmed the platform showed nothing else,
so the belief was reasonable and it is still wrong about the page. `sample_review_page.md`, a
conversion of the whole reviewer page, shows the reviewer is given all of this:

| On the page | Line | What it is |
|---|---|---|
| The seed zip, "Download Sentinel 2.0 task here" | `:62` | the task as issued to the submitter |
| The submitted zip, from the re-upload field, with its timestamp | `:141` | what they built |
| Their verdict, the internal Validity radio, and the duplicate question | `:64-95` | including **Invalid Difficulty** as a live fourth option |
| Both checkbox groups and the numbered issue details | `:99-139` | their own analysis, in their words |
| Files Changed, PR additions, the eight confirmations, the difficulty answer, the senior estimate | `:323-379` | |
| Comments for Reviewer | `:383-415` | the field `docs/tasking-guide.md` requires you to read |
| Static Checks, Prescriptiveness, the difficulty results download, Difficulty Check, Agentic Judge Quality Report, Oracle Check, Quality Check | `:179-321` | all six eval panels, with their contents |
| Difficulty checks run, remaining, last counted submission version, last result | `:149-177` | all four counters, and the FAQ named only two of them |
| Any previous round's Reviewer Feedback, dated | `:15` | this round's checklist |
| Automated feedback, "All checks have passed" | `:11-13` | |

**One zip on the page does not mean the capture is short.** The re-upload field at `:141` is
conditional on the verdict radio, so a submitter who set no verdict leaves only the seed rendered, and
the rest of the page still shows `All checks have passed`, the difficulty counters and any previous
reviewer feedback. Check which bundle you hold against that previous feedback and against the archive's
mtime spread before writing a word, and note that R3 then has nothing to diff (`learning/reviewer-can-be-handed-the-seed.md`, LEDGER L107).

**So ask for all of it in one message** (Section 13, R1.5), and do not plan a review around not having
it. `docs/reviewer-rubric.md:123` makes "claiming logs are inaccessible when they are visibly present"
a flaggable integrity item, which is what "the submitter's answers did not arrive with the zip" would
now be on a page that renders them. When something genuinely is missing, say what you did to get it.

**Two consequences worth taking rather than noticing.** The seed zip beside the submitted one makes
the submitter's whole change one `diff -rq` away, which is the highest-yield read available and is
Section 13 R3. And their numbered issue list plus Files Changed is a set of claims to verify one by
one, which is what `docs/tasking-guide.md` actually defines the reviewer's job as.

**The submitter has two surfaces and this section used to treat them as one.**
`docs/tasking-guide.md` question 5 is not about the Comments for Reviewer field on their form: it
tells the reviewer to open the **rebuttal comments in the left-hand panel** and read the submitter's
notes in full. That question **is** on the live form after all (`sample_review_page.md:433-441`), so
it is answered rather than skipped. Look for the panel before recording anything as unavailable, and
say which of the two surfaces you found.

**The second and later rounds, where two bundles exist.** Revision cycles reach reviewers, which is
what the maximum-revisions dialog behind Q1 exists for, so a review is not always a first pass. All
three reviews here were, and 12.1 to 12.11 assume one zip with no prior findings until this
paragraph. Keep the artifacts separate and identified: each zip lands as
`download/<submission_id>_submission.zip` under its own id, gets a `sha256sum` recorded in `task.md`
before it is extracted, and `download/original/` is re-extracted from the newest one rather than
unpacked on top of the previous bundle. Name the zip you reviewed, by id and hash, in the record
block. The previous round's findings are this round's checklist, so mark each one fixed, still open
or answered, and do not re-file a note the submitter has already addressed. The round discipline is
technique from an external reviewer prompt pack, not from `docs/`.

### 12.4 What to run, and in what order

`docs/tasking-guide.md:349` says a reviewer need not run Harbor, the oracle, the NOP or a build.
Run them anyway. On mithril three of eleven notes were measurements no reading would have produced,
and two were the lead findings.

**Section 13 owns the sequence and this list is what its steps run.** The mapping, so a reader can
follow either: item 1 is R2, items 2 and 3 are R3, item 4 is R4, item 5 is R5, items 6 to 9 are R6,
item 10 is R8 and item 11 is R7.

1. Extract the SUBMITTED zip to `download/original/`, `cp -a` to `work/`, freeze the extract, and
   extract the SEED zip to `download/seed/` and freeze that too. `bin/new-review.sh` does both
2. **The seed-versus-submitted diff, which is the read this list did not have.**
   `diff -rq download/seed download/original -x '.git'` is the submitter's entire change, and the
   page carries both zips (`sample_review_page.md:62` and `:141`). Every line in it is a fix they
   claim, a fix they did not claim, or a change nobody asked for, and a file they claim to have
   changed that is NOT in the diff is the other half of the check. Then verify their numbered issue
   list claim by claim, which is what `docs/tasking-guide.md` defines the reviewer's job as
3. **mtime forensics, and it is now the fallback rather than the opening move.** Use it when no seed
   zip was supplied. A reviewer gets a zip and no diff, and the archive contains one anyway: the generator stamps every file at build time, so only what the submitter
   rewrote carries a later mtime. `unzip -l <zip>` and read the dates. On expressa 132 all 188
   entries read `2026-07-20 14:42` except `task.toml` at `2026-07-22 02:20`, which answered "what did
   this submitter actually do" in one command and framed the whole review. Two caveats to state
   whenever it is used: a tool that preserves mtimes leaves no trace, and an unchanged mtime supports
   "they did not rewrite this" but never "the content is wrong"
4. **Git state, on its own and before any content read, because it is the one pillar the rubric calls
   an early gate.** `docs/reviewer-rubric.md:95` says to check it *before* assessing content. This
   order already did, but it sat inside a mixed sweep with no severity attached, which is not the
   same as treating it as a gate. Read the result against `:91`: `git fsck --unreachable
   --no-progress` silent, no stash and no `.git/logs`, no extra remotes or worktrees, `HEAD` equal to
   the declared base commit. That is the `Meets` line, and the Needs Revision trigger at `:95` sits
   one step further out, at dangling commits, stash entries or a reflog **that expose the fix**, plus
   leftover remotes or worktrees and a HEAD or base-commit mismatch. Two bars, and this item used to
   collapse them, which manufactures a Major out of a noisy `fsck` on a repo that leaks nothing. So
   when `fsck` prints objects, read a couple with `git cat-file -p <sha>` before writing anything,
   the same read the submitter path requires of itself immediately before the re-zip, and say what
   they are. Golden content, a patched test file or the fix in any form is the Major and it stands
   alone without the rest of the review. Objects carrying nothing about the solution fall short of
   Meets and are worth a note rather than the verdict. The remotes, worktrees and HEAD-mismatch limbs
   are Major with no read needed. Expect the read to pay, because
   `learning/unreachable-git-blobs.md` is the case that `fsck` line is about, a repo with no reflog,
   no stray refs and a clean tree still holding dangling blobs of the golden file, plus the broken
   `refs/remotes/origin/HEAD` that `git remote` never shows. Local
   artifacts left in the tree with no history leakage are the Soft signal at `:93` rather than a
   Major, though they still hard-cap the packaging axis on the platform's own Quality Check. Then the
   rest of the mechanical sweep on `work/`: both patches apply at base, `unzip -Z` for script modes
   and the symlink count, stray artifacts, `instruction.md` vs `problem_statement.md`, and the three
   `network_mode` values and `allowed_hosts` read against the Section 8 baseline, which is Pillar 4
   and is the one Major pillar nothing on this path checked in three reviews (12.11)
5. **PR comparability at hunk level, never file list.** Page the GitHub API for the PR's per-file
   patches and compare changed-line sets **in both directions**. On mithril this returned 304
   changed lines each way with zero unique to either side, which removes quality score 1 in one step
6. Build the image; run NOP, oracle 3x, hostile delete. Use `bin/hostile-probe.sh`, never a
   hand-rolled `sed` (12.6)
7. **The forced-test-edit run.** Apply `golden.patch` alone, without `tests.patch`, and run the
   repo's own full test command. Compare against the same command at base. Any test green at base and
   red after golden is an edit the instruction may be forcing the agent to make, and every file
   holding one is a collision surface. expressa went 117 passing / 0 failing to 113 / **4**, and the
   compliant edit that follows was measured as an invalid trial
   (`learning/instruction-promises-the-suite-keeps-passing.md`)
8. **The move-the-created-file probe.** Apply `golden.patch`, move every file it **creates** to another
   location the instruction also permits, repoint whatever the solution itself imports it from, and re-run
   the verifier. The reward must not move. On cista 172 it went from 21 of 21 to **4 of 21**, because the
   graded test file opens with `#include "cista/type_hash/static_type_hash.h"` and `instruction.md` names no
   path anywhere. The bipartite mapping and pre-upload item 10 both miss this, since they walk identifiers
   rather than paths, and the oracle can never reproduce it
   (`learning/graded-tests-that-import-the-deliverable.md`)
9. **The two invocations, which are runs rather than findings and so get missed by re-reading notes.**
   Both are one command and both have produced a blocking defect on the one bundle where they were
   finally tried (`learning/audit-the-finished-review-not-just-each-finding.md`):
   - **`sh /tests/test.sh`**, never only `bash`. On mithril.js 2021 dash rejected `set -uo pipefail`
     at line 9, which sits **before** the `trap` that guarantees a reward file, so the run wrote
     **no `reward.txt` at all** rather than reward 0. Read it together with the script modes: a
     bundle shipping `0644` cannot be exec'd by shebang, so the harness must pick an interpreter and
     `sh` is a candidate. Those two are one finding, not two (`learning/solve-sh-under-sh.md`)
   - **The real oracle protocol, `solve.sh` then `test.sh`, three cycles in one container.** Not
     `solve.sh` three times, which is a weaker check about the oracle *script*. mithril.js 2021
     replays `solve.sh` 3 of 3 and scores **1 of 3** on the protocol, because `test.sh` applies
     `tests.patch` every run and restores nothing. A missing restore is an Oracle Check defect and
     not only an agent-collision defect (`learning/oracle-protocol-is-solve-then-verify.md`)
10. The stock-defect sweep (12.5)
11. Only then read for instruction quality, coverage and faithfulness. Read `instruction.md`,
    `problem_statement.md`, `task.toml`, `tests/config.json`, `tests/test.sh`, `tests/tests.patch`
    and `solution/golden.patch` end to end rather than by grep, then map the instruction onto the
    graded tests before writing anything about coverage. One row per stated requirement, marked
    covered, weakly covered, uncovered, or graded more strictly than the instruction states. The last
    two carry different remedies and that is what the marks are for: uncovered is the coverage gap
    that promotes to Pillar 2 once the hostile probe holds reward at 1.0 with the requirement stubbed
    out, and graded more strictly is overreach, fixed in the tests rather than by writing the
    requirement into the instruction to justify the assertion. The table stays in `task.md`, because
    it is what 12.11 counts requirements 4, 6 and 8 from. The four marks are technique from an
    external reviewer prompt pack; the mapping under them is the bipartite mapping
    `.claude/rules/05-evals-and-quality-check.md` asks a submitter to build before writing tests

### 12.5 The stock-defect sweep is most of a review

Two independent reviews of two unrelated bundles found the **same five defects**, and a third found
six of eight. Check these first rather than discovering them, using the eight-row table in
`learning/stock-bundle-defect-baseline.md`:

| Defect | Check |
|---|---|
| Grader never gates on `raw_exit_code` | `grep -n raw_exit_code tests/test.sh`, then read the success expression |
| `python3` behind an `\|\| true` | `docker run --rm <base-image> sh -c 'which python3'`, then rebuild without the swallowed install |
| A correct solution that logs an object scores zero | oracle run with a `console.log({...})` added to the code under test |
| Scripts ship `0644` | `unzip -Z <zip> 'tests/test.sh' 'solution/solve.sh'` |
| No restore before `tests.patch` | `grep -n 'rm -rf\|base64\|tar -xz\|checkout' tests/test.sh` |

Plus the one that discriminates rather than always firing, and which `docs/reviewer-rubric.md:71` has
promoted from colour to a **Major**: tests that can be satisfied by editing them rather than solving
the task are Pillar 3's own Needs Revision trigger, so a probe that comes back positive settles the
verdict by itself. The check is **can an agent fake a pass by editing the assertion library it is
graded by** (`learning/agent-writable-test-infrastructure.md`). mithril: reward 1.0 with the solution
unapplied.
expressa: 15 of 21, reward 0, and the review said so in its opening. cista: reward 1.0 with a broken
stamp, but only the 4 runtime-checked ids were defeated because the other 17 are `static_assert`s.
On a compiled language run the probe **on top of golden plus one break that still compiles**, since
leaving the solution unapplied only measures a build error there.

**Two rows are decided structurally, in a minute, before any container run** (LEDGER L66). Row 8
cannot fire when `grading.parser.framework` is `custom`, because the brace-slicing in `_find_json` is
only reached for `jest` and `mocha`. Row 7 does not apply when the verifier's `python3` is a hard
dependency of a **non-optional** install line rather than a passenger on an `|| true` chain. Report
those as absent with the reason. **An "absent" that you can justify is worth writing down**, because it
tells the submitter which of the usual suspects they do not have to go and look at.

### 12.6 Never hand-roll a mutation probe

Both wrong conclusions in the mithril review came from a `sed` that silently matched nothing, one of
them drafted as a **blocking** finding. `bin/hostile-probe.sh` already exits **3** with
`THE BREAK DID NOT LAND`, and `learning/verify-in-the-image.md:328,366` already records two earlier
instances. The knowledge was never missing; the reviewer path just had no hookup to the tooling. Use
the script, or copy its guard:

```python
assert needle in s, "NEEDLE NOT FOUND: " + needle[:70]
```

A probe that cannot prove it changed the tree measured nothing, and its result is not evidence.

### 12.7 Check a finding before filing it

An 8-dimension fan-out over mithril produced 77 candidates and adversarial verification refuted
**40**, four of them already written into the answer file. Every one of them failed a check in the
list below.

**Step 0, before the first finding is written: read `learning/LEDGER.md` itself.** Not
`learning/README.md`, which only describes it. The LEDGER is the list of claims this workspace has
already disproved and it is the one file whose entire purpose is to stop you writing something, so
reading it late means it cannot work. Measured: expressa 132 re-derived and re-filed the
`[verifier] 300` against `execution 1800` finding from scratch, eleven hours after the mithril review
had measured the same pair across the five `_archive/*/download/original/` extracts and written the
result down as **L58** with the exact command. That row has since been superseded by **L73**, because
`docs/reviewer-rubric.md:101` makes the pair a documented Minor violation, so the finding is real and
the verdict L58 reached was the wrong half. The measurement is still the point: a session that opens
the row gets the numbers, the wording rule and the reversal in one read, and a session that does not
spends its budget re-deriving the numbers and still words it wrong. Open `learning/LEDGER.md`
directly. `bin/learning-query.sh` is the fast lookup for the **notes** and it skips `LEDGER.md` by
name at lines 179 and 236, so it can never return a LEDGER row.

Then, per finding:

1. **Open the cited file at the cited line.** A wrong quote or line is grounds to drop it
2. **Read the cited rule's actual sentence.** Watch for a rule paraphrased stronger than it reads,
   and for a **practice** read as a rule. `.claude/rules/11-verifier-hardening.md:7` defines practice
   as "not in `docs/` ... applied with judgment", and Section 10.6 is headed `(mixed)`
3. **Check scope.** The em-dash ban is scoped by `.claude/rules/06-writing-rules.md:5` to form
   answers, not to `instruction.md`. Applying it to an instruction is L57
4. **Check the arriving bundles.** There are eleven of them on this machine, the eight under
   `_archive/*/download/original/` and the three under `review_tasks/*/download/original/`, and
   Section 8 names both trees. A value identical across all eleven is the generator's default and not
   a submitter act (L61 to L63). Present in the accepted `_archive/*/work/` bundles means it is the
   accepted shape (L59). Measure the baseline against `download/original/`, never against `work/`, or
   you are comparing this bundle to other people's rewrites and calling the difference a defect.
   Section 8 now carries the measured `task.toml` baseline so it does not need re-measuring. **A
   generator default is not automatically a non-finding, and that is L73.** When `docs/` names the
   value as a defect the baseline does not overrule it, so the arriving bundles decide the wording
   and not the verdict. The verifier-timeout pair arrives at 300 against 1800 in 10 of 11 bundles and
   `docs/reviewer-rubric.md:101` still makes it a Minor, so it is filed as the arriving default the
   submitter did not correct, with both numbers named
5. **Check the remedy.** The remedy in a note is an instruction someone will follow, so it can be
   wrong in a way an observation cannot. Before telling a submitter to delete a name or a literal
   from `instruction.md`, grep the graded tests for it and split the list. On expressa, thirteen file
   paths had zero graded references and were safe to cut, while six literals had a graded assertion
   behind them, so the draft advice to "delete the error strings" would have traded a non-blocking
   instruction finding for a blocking alignment one. `docs/guidelines.md:99` exempts strings that are
   a genuine public or API contract and `:101` requires stating a required response shape. Hand the
   submitter both halves

Then ask whether the remedy would make the bundle worse. L60 is a finding whose fix would have
weakened the verifier.

A finding that survives all six is worth filing even when it is uncomfortable. The same review filed
eleven notes that all survived adversarial verification, five of them measured in a container. The
discipline is not fewer findings, it is a baseline per finding. See
`learning/reviewer-findings-need-a-baseline.md`.

### 12.8 Writing the answer

`review_answer.txt` follows the **Section 5 writing rules in full**, the same as
`submission_answer.txt`: plain English, no em or en dashes, no internal check vocabulary, no
markdown symbols in prose, one unwrapped line per paragraph. **Section 5.1 applies only here and it
is not optional**, because `docs/reviewer-rubric.md:113-123` scores an LLM-generated review as a
**Major** against the reviewer, with six soft signals of which any four in one review is Major on its
own. The fixed note shape this section used to prescribe was carrying two of the six by itself,
exhaustive parallel bullet lists and rubric-aware framing, before a reviewer wrote a word. Section
5.1 has the per-signal measurement across the three reviews in `review_tasks/` and the boilerplate
grep. Run `humanizer` as the closing action, then the Section 5 greps and the 5.1 check.

What every review carries, whatever shape the notes take:

- **Open with what is right**, with the measurements, before any note. It stops a revision round
  undoing what already works, and it is the evidence for not scoring 1. Write that opener out of this
  bundle's own numbers. All three reviews here open on the same ten words, "Start with what is right,
  because none of it should", which is the mirrored-language signal, and it came from this list
  rather than from any of the bundles
- **One numbered finding per defect, each carrying its file, its line and its measured number.** That
  much is fixed, because it is the `Meets` line at `docs/reviewer-rubric.md:119`. The packaging
  around it is not. Cite a Guidelines section when one genuinely backs the finding and leave the line
  out when none does, which is what reviewers are asked for anyway (`docs/tasking-guide.md`, reviewer
  form question 4). Put the remedy in the sentence that names the defect when it is a one-line
  change, and in its own paragraph when it has a sequence or a payload behind it. Nineteen of the
  thirty nine notes written here carry no Guidelines citation and six carry no labelled remedy line,
  and those are not worse notes
- A closing note listing what you looked at and are **not** asking to change, so an unticked box is
  not read as an oversight. Include findings you filed and withdrew, with why
- Say which findings you measured and which you read. It earns the measured ones their weight. All
  three reviews here say it in one shared verbatim sentence, so write your own
- Severity is decided in 12.2 and it does not travel into the paste. What reaches the submitter is
  the defect in ordinary words and the order, with the item that blocks acceptance on its own coming
  first and the rest following it. The pillar name, the requirement number and the running count stay
  in the record block at the bottom, because putting them in a note is the rubric-aware framing
  `docs/reviewer-rubric.md:121` scores against you (12.2, and Section 5.1). Say that an observation is
  not something you are asking to have changed, in those words rather than as a severity label

### 12.9 Scoring

`docs/tasking-guide.md` defines the five points. The two that get confused:

- **1** is reserved for deviation from the source content (wrong PR, substituted repo code) or a
  low-effort submission. A bundle whose golden and tests reproduce the PR exactly cannot be a 1,
  however many verifier defects it carries. Establish this early with the hunk-level comparison
- **2** is source intact, execution has real gaps needing meaningful revision
- **3** is correct and complete with only minor residue, and it accepts
- The score and the verdict cannot disagree, and the rubric now constrains the score once you have
  the counts. `docs/tasking-guide.md:453-459` maps 1 and 2 to needs revision and 3 to 5 to accept,
  and `docs/reviewer-rubric.md:156-158` decides the verdict from the counts, so a confirmed Major or
  five Minors lands the score at 2, with 1 still reserved for deviation from the source content, and
  an Accept carrying one to four Minors is a 3. Read the two answers against each other before
  pasting, because a Needs Revision sitting beside a 3 reads as an unfinished review

Both 2026-08-11 reviews landed on 2, in both cases with perfect PR fidelity and real verifier-side
defects.

### 12.10 Audit the finished answer, as a separate pass

12.7 checks each finding as it is formed. That is necessary and it is measurably not sufficient. An
adversarial pass over a finished, careful 11-note review of mithril.js 2021 left **1 note confirmed
and 9 weakened**, none refuted, and added two blocking findings the review had never run a check for.
Nothing was wrong about whether a defect existed. Everything wrong was in the second sentence of a
note, which is exactly what per-finding rigour does not look at
(`learning/audit-the-finished-review-not-just-each-finding.md`).

Run all five over the whole document, after the findings are written:

1. **Grep your own answer for baseline claims.** Any sentence shaped "N other bundles do X". Name the
   tree each was measured against, in the sentence. That review shipped **two** `work/` baselines
   while using the correct framing eleven lines later in its own closing note, so knowing L61 is not
   the same as running it (LEDGER **L72**)
2. **Read every remedy against every other one**, wherever in its note each one sits. Two notes that are individually right
   can be jointly impossible. There, note 9 asked for the graded tests to be relocated and note 11
   said keep them where the PR author put them, about the same six ids
3. **Re-derive every number from the live bundle.** Not from `task.md`, never from an earlier draft.
   A figure you cannot reproduce on demand comes out, and the file-and-line citations carry the
   finding without it (LEDGER L53 applied to the reviewer side)
4. **Test each stated mechanism by removing the thing it names.** "These survive because `/app` is a
   git repository" died when `/app/.git` was deleted and the case still scored 15 of 15. LEDGER L5
   and L10, pointed at a review instead of at a defect
5. **Walk the run list, not the finding list.** Ask which invocations were never tried. Both new
   blocking defects sat behind 12.4 item 9, and no amount of re-reading the notes would have found
   either

A remedy scoped short and described as complete is its own class and belongs in check 2. "That one
change also fixes note 9" was measured false, because the restore covered three directories and
`tests.patch` creates a file at the repo root (LEDGER **L71**).

### 12.11 The rubric's pillars and requirements, against what this section already runs

`docs/reviewer-rubric.md` arrived with a defect list of its own, ordered by how often reviewers across
the whole programme flag each item rather than by what three reviews on this machine happened to meet.
Most of it is already here under different names. This is the map, so a finished review can be checked
for coverage instead of remembered.

**The five Major Pillars** (`docs/reviewer-rubric.md:33-95`), in the rubric's own frequency order. One
confirmed violation of any of them is Needs Revision.

| Pillar | Flagged in | What already runs here | What does not |
|---|---|---|---|
| 1 Oracle and golden correctness | 51% | 12.4 item 6 (oracle three cycles), item 9 (the real `solve.sh` then `test.sh` protocol), item 5 (hunk-level PR comparability), item 8 (move the created file) | nothing. This is the best covered pillar, and three of those four checks are this workspace's rather than the docs' |
| 2 `fail_to_pass` / `pass_to_pass` integrity | 45% | stock sweep row 2 for an empty `pass_to_pass`, the Section 10.3 id-location count, the 10 to 20 range | the pillar's own trigger, declared lists equal to the verifier's real graded set. Nothing here diffs the ids the oracle run reported against `tests/config.json` |
| 3 No leakage, not reward-hackable | 21% | 12.5's agent-writable probe, the fail-open grader row, the leaked-literal read at item 10 | nothing structural. What changed is severity, see 12.5 |
| 4 Airgapped verifier and network integrity | 41% | **nothing, in three reviews** | the whole pillar. Section 8 carries the measured `network_mode` and `allowed_hosts` baseline and 12.4 never read it until now |
| 5 Git state and repo cleanliness | 31%, early gate | 12.4 item 4 | nothing, once item 4 is run on its own rather than inside the sweep |

**Pillar 4 is the hole, and it is two minutes of work.** Read `[environment]`, `[agent]` and
`[verifier]` `network_mode` and `allowed_hosts` against `docs/harbor-framework.md:59,66` and the
baseline in Section 8, which reads `[environment] network_mode = "public"` in 10 of the 11 pristine
extracts on this machine, then confirm no graded behaviour needs egress. It is blocking
rather than cosmetic: cista 172 ships `[environment] network_mode = "no-network"`, and
`docker build --network=none` on that bundle's own Dockerfile dies on the first `apt-get` layer with
exit 100. The converse mistake is on record too, so do not read a socket as egress. A loopback server
inside the test process is not a network dependency, and calling one is how a whole requirement gets
left ungraded (`learning/airgapped-means-no-egress-not-no-sockets.md`).

**Pillar 2's missing half is one diff.** After the oracle run, take the test ids the verifier actually
reported and compare them with `grading.fail_to_pass` and `grading.pass_to_pass`. Count **distinct**
ids against the 10 floor, because a repeated id inflates a static list-length check while the true
graded count is lower, which is the pillar's own Needs Revision trigger at `docs/reviewer-rubric.md:59`.
Do not read that as licence to call duplicated ids padding: listing an id twice is still strictly
stronger than not listing it, since an unlisted test that never runs leaves no trace while an
unreported listed one lands in `missing_required` and forces reward 0 (L60).

**The eleven Secondary Requirements** (`docs/reviewer-rubric.md:97-111`). Each is one Minor and five is
Needs Revision, so the rows with no check are the ones that let a systemic-quality verdict walk past.

| # | Requirement | Covered here by |
|---|---|---|
| 1 | Verifier timeout vs config timeout (18%) | the Section 8 baseline table. The measurement is ours and the conclusion is now the rubric's (L73). File it as the arriving default the submitter did not correct, and name both numbers, because the rubric asks for both |
| 2 | Base image and dependency pinning (17%) | **nothing.** Run the four reproducibility greps under pre-upload checklist item 3 in `.claude/rules/01-workflow-steps-1-to-5.5.md` against the bundle under review |
| 3 | PR-scope violation (13%) | 12.4 item 5. Escalates to Unfixable - Structure when reducing the PR is the only fix |
| 4 | Test coverage gap (13%) | 12.4 item 6 hostile delete, then the read at item 11 |
| 5 | Metadata mismatch (10%) | in part. mtime forensics at item 2 and the golden-versus-PR diff at item 4 cover the diff half. The writeup half is the count drift `learning/answers-file-drift.md` measures from the inside, four stale counts in an accepted answers file, and it is now a named reviewer-flagged Minor rather than an internal habit. It needs the submitter's answers, and the page renders them (12.3), so this is now checkable rather than a row you decline |
| 6 | Over-prescriptive instruction | item 10, with the 12.7 check 5 split run before any advice to delete a name |
| 7 | Templated or AI-generated instruction | item 10. Judge it against the five personas and four red flags at `docs/guidelines.md:169-177`, never against the Section 5 answer-writing rules, which are scoped to form answers (LEDGER L57) |
| 8 | Instruction ambiguity | 12.4 item 8. This is an unstated choice between two readings that are both valid, where the tests silently require one of them. It is **not** a `Task Instruction Sufficiency: FAIL`, which is a deliverable the instruction never names at all, so the agent cannot build it and every trial dies on an unresolved symbol. Ambiguity produces a working solution that grades wrong. Usually promotes, see below |
| 9 | Non-deterministic test | the flakiness run below, two fresh extracts of the same zip compared on their per-test pass sets. Three oracle cycles in one container do not measure it |
| 10 | Missing regression test | stock sweep row 2, an empty `pass_to_pass` with `allow_extra_failures` true |
| 11 | Difficulty drift, recoverable | **nothing, and deliberately.** 12.2 says why a local run cannot support it |

**Requirement 9 needs two runs of its own, because the oracle cycles cannot see it.** Three cycles in
one container run on a tree each cycle mutates, so a difference between them is the missing restore
rather than flakiness. Extract the same zip twice, solve then verify in each, and compare the
per-test pass sets. Read the pass sets and not the rewards, because a reward can hold at 1.0 while a
different id fails each run. Grep the graded tests for a wall clock, an unseeded random source and
cross-test order dependence first, so you know what to look at when the sets differ. The shape has
precedent here and was improvised both times, nine consecutive verifier runs in
`learning/airgapped-means-no-egress-not-no-sockets.md:90` and three fresh runs on a cold image with
identical pass sets in `learning/solve-sh-idempotency.md:190`. Making it a standing step rather than
an improvisation is technique from an external authoring workspace, not from `docs/`.

**Two of the eleven stop being Minor once you measure them, which is the whole return on running the
bundle.** Requirement 8 is worded as guesswork forced on the agent. On cista 172 the same defect
measured as a complete correct solution scoring **4 of 21**, because the graded test reaches the
deliverable by a path the instruction never states. That is Pillar 1's own Needs Revision trigger, an
oracle depending on a value that appears only in the golden patch and is not stated or derivable
(`docs/reviewer-rubric.md:47`), so it is a Major and not one of the five you are counting
(`learning/graded-tests-that-import-the-deliverable.md`). Requirement 4 promotes the same way: a
coverage gap you read is Minor, and a coverage gap the hostile-delete probe proves by holding reward
at 1.0 while a stated requirement is stubbed out is Pillar 2.

**What this workspace measured that the rubric has no row for.** These are real and they get filed
under a pillar rather than invented as a sixth one:

- **The fail-open grader**, reward 1.0 while the test command exited nonzero. The stock harness ships
  it, so it is present on nearly every arriving bundle, and it is exploitable rather than theoretical.
  Two lines added to product source returned reward 1.0 with the bug fully present (LEDGER L70).
  Pillar 3, reward-hackable
- **The report sharing stdout with the code under test.** A correct solution that logs an object
  scores zero. This is a false negative against correct work and no pillar describes that direction.
  Pillar 1, because the oracle stops passing its own tests the moment anybody debugs with a print
- **`sh /tests/test.sh` writing no reward file at all**, because dash rejects line 9 before the trap
  that guarantees one. Pillar 2, since nothing is graded
- **No test-tree restore before `tests.patch`.** Measured 1 of 3 on the real oracle protocol, which is
  Pillar 1 directly, and separately an agent-collision source
- **Scripts at `0644`**, which is what forces the harness to choose an interpreter and makes the line
  above reachable

The rubric's percentages are the programme's, not this machine's. Four of those five are present on
nearly every bundle that arrives here (`learning/stock-bundle-defect-baseline.md`), a higher rate than
any number in `docs/reviewer-rubric.md`. Record them as Major in your tally with the pillar named
there (12.2), and do not soften one to a Minor because the rubric's list has no row with its name on
it.
