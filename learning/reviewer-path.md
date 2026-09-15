---
id: reviewer-path
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260723_030152__mithriljs_mithril.js__2021
  - 20260720_144200__thomas4019_expressa__132
  - 20260717_182400__felixguendling_cista__172
evidence: "Three peer reviews run on this workspace on 2026-08-11. Its run list, stock-defect sweep and severity discipline stand; its two form findings were reversed on 2026-08-18 by a capture of the whole reviewer page (LEDGER L100, L101)"
applies_to:
  languages: [any]
  runners: [any]
  phases: [peer-review]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts:
  - "CLAUDE.md, 'Peer review is out of scope for this workspace'"
superseded_in_part_by:
  - reviewer-page-carries-the-whole-submission.md
---
> **Process scope, 2026-08-19.** This note preserves measurements from the legacy deep-battery reviewer workflow. New reviews use the timed platform-first static path in Section 13. Docker, Harbor, Oracle, NOP, container, mutation, and full-audit work are no longer routine review steps. Consult a measured legacy case only after a recorded timed-review trigger or in a separately requested diagnostic.


# Reviewing, when the workspace was built for submitting

`CLAUDE.md` said peer review was out of scope and described the scaffolding to add "if review is
ever assigned". It has been assigned twice on 2026-08-11, mithril.js 2021 and expressa 132. This
note is what the two runs established. The rule text now lives in
`.claude/rules/13-reviewer-path.md`; this is the evidence behind it.

## The 2026-08-13 export added the verdict rule this note never had

Everything below was measured before `docs/reviewer-rubric.md` existed. The tab was announced on
2026-08-12 and landed here in the 2026-08-13 re-export. It touches no measurement in this note. What
it supplies is the thing all three reviews had to invent, the arithmetic between a pile of findings
and a verdict: one confirmed Major Pillar violation is Needs Revision, five or more Minor violations
of the Secondary Requirements is Needs Revision, and one to four Minors is an Accept that owes
mandatory coaching comments. The rule is Section 12.2 and the pillar mapping is Section 12.11.

Three things it changes about the reviews recorded here, two of them reclassifications rather than
new findings:

- **The `[verifier] 300` against `execution 1800` mismatch is a finding again.** The measurement in
  LEDGER L58 still holds, and it now reads at 10 of 11 arriving bundles. What changed is that
  `docs/reviewer-rubric.md:101` names it Secondary Requirement 1 at an 18% flag rate, and `docs/`
  wins on policy. So it is a Minor, it is mechanical, you name both numbers, and because it arrives
  as the generator's default you word it as the arriving default the submitter did not correct rather
  than as something they broke, which is the L61 discipline unchanged (LEDGER **L73**)
- **The agent-writable test infrastructure probe is a Major, not colour.** `docs/reviewer-rubric.md:71`
  makes tests that can be satisfied by editing them rather than solving the task a Pillar 3 Needs
  Revision. mithril's reward 1.0 with the solution never applied is that trigger exactly, and it was
  written up here as one finding among eleven
- **A graded test that reaches the deliverable by its path is a Major too.** cista 172's 4 of 21 was
  filed as an instruction and naming defect. Under `docs/reviewer-rubric.md:47`, an oracle depending
  on a path that appears only in the golden patch and is not stated or derivable is Pillar 1

And three things the rubric asks for that none of the three reviews ran: network integrity, a Major
pillar flagged in 41% of reviewer comments, base image and dependency pinning, and a determinism
read of the graded tests. Nothing here was measured about any of them, which is the honest status rather than a
clean sheet.

## SUPERSEDED 2026-08-18: the live form has seven questions after all

Everything in this section below the next paragraph is kept as the record of what was measured and
how the wrong conclusion was reached. **Do not act on it.**
`reviewer-page-carries-the-whole-submission.md` carries the correction and LEDGER **L100** carries the
row. In one line: a conversion of the **whole** reviewer page shows the Acknowledgement of Submitter
Rebuttal at `sample_review_page.md:433-441` and the review-duration field at `:467`, both 2026-08-11
captures were truncated documents, and truncation drops trailing fields, which is exactly where those
two sit. Two truncated captures agreeing about an absence is one mechanism firing twice and not two
witnesses, so the retiring condition this section set for itself was never actually met. The rule that
replaces it: **an absence is retired only by a capture that could have shown the thing.**

## The original section, kept as the record: the live form has four questions, not seven

`docs/tasking-guide.md:401-459` lists seven reviewer questions, including **Acknowledgement of
Submitter Rebuttal** and **How long did it take you to complete this review**. The form pasted from
the platform on 2026-08-11 has neither:

| # | Live question | In `docs/`? |
|---|---|---|
| 1 | What is your verdict for this Submission? Accept / Needs Revision / Reject | yes |
| 2a | If Accept: confirm the six requirements | yes |
| 2b | If Needs Revision: Error Categories, the same 19 labels | yes |
| 3 | Explain in more detail what revisions are needed (written) | yes |
| 4 | What is the overall quality of the submission, x/5 | yes |
| - | Acknowledgement of Submitter Rebuttal | **in docs, absent from the paste** |
| - | How long did it take you to complete this review | **in docs, absent from the paste** |

**Caveat, RETIRED 2026-08-11 by a second independent capture** (cista 172). The condition this note
set was "a second paste, or a screenshot of the live form", and the cista capture is a second paste
from a different assignment. It agrees with the first on all four questions and on the absence of
**Acknowledgement of Submitter Rebuttal** and **How long did it take you to complete this review**.
Two captures is enough to stop treating those two as merely unseen. **Stop carrying them as `PENDING`
form fields.** Where the submitter's answers were genuinely unavailable, say so in a record block
below the answer instead, because that is a real limit on the review and still needs stating.

**New caveat, open, from the same capture.** The cista paste shows **five** confirmation items under
the Accept branch where `docs/tasking-guide.md` lists six, and the absent one is *Tests every
requirement in the instructions*. That paste is visibly truncated in several other places
("Oracle solution matches the inst", "The task is correc issues are too minor"), so this may be a
capture artifact rather than a form change. Keep all six in the template. What would retire it: a
capture of the Accept branch that is not truncated, which needs a review that actually accepts.

Both 2026-08-11 captures also confirm the **Q2 error-category list is exactly the 19 labels** at
`docs/tasking-guide.md:418-436`, in that order, and that the platform describes them as "for internal
tracking only", which is worth knowing before agonising over a borderline tick.

**Third capture, 2026-08-11, pasted by the user during the mithril verification audit.** Same four
questions again, and neither absent field reappeared, so the retirement above holds at n=3. One
detail worth carrying: this capture's **Accept branch again showed five confirmation items rather
than six**, missing *Tests every requirement in the instructions*, which is what the cista capture
showed. It is still not decisive, because this paste is visibly truncated elsewhere (one of its own
five items reads "Oracle solution matches the inst" and three of the five Q4 definitions break
mid-word). So two captures now agree on five and both are truncated documents. Keep all six in the
Path D template until an untruncated Accept-branch capture arrives, and note that the branch only
matters on an Accept, so the cost of carrying the sixth is zero.

## SUPERSEDED 2026-08-18: the reviewer page carries the submitter's answers and every eval panel

Kept below as the record. **Do not act on it.** The same capture shows the reviewer is given the seed
zip (`sample_review_page.md:62`), the submitted zip (`:141`), the submitter's verdict and both
checkbox groups and their numbered issue details (`:56-148`), Files Changed, PR additions, the eight
confirmations, the difficulty answer and the senior estimate (`:323-379`), Comments for Reviewer
(`:383-415`), all six evaluation panels with their contents (`:179-321`), the four difficulty counters
(`:149-177`) and any previous round's reviewer feedback (`:15`). LEDGER **L101**.

What the three reviews below measured was what arrived in a chat message, not what the platform shows,
and one submitter's "there is only zip present in the platform nothing else" was about the same
message rather than about the page. **Ask for all of it** (Section 13 R1.5). The advice to word a
finding against the bundle is still good writing; the reason given for it is gone.

## The original section, kept as the record: the submitter's Comments for Reviewer do not arrive with the zip

Three reviews now, three bare submission zips, none with the submitter's form answers. On cista 172
the submitter confirmed it directly, "There is only zip present in the platform nothing else", so this
is the normal case rather than three accidents. The live form has no field showing their verdict
either, even though the Accept option is worded as agreeing with it.

**Ask for their answers in the same message that receives the zip**, and when they do not arrive, plan
the review so nothing depends on them. Two practical consequences, both learned on cista 172:

- **Word every finding against the bundle, not against the submitter.** "golden.patch differs from the
  PR by one line and nothing in the zip records it" is checkable and survives. "You failed to declare
  it" is a guess about a document you have not read. Add one clause saying the note is closed if their
  answers already cover it
- **Say once, near the top, that you only had the zip.** It is a real limit on the review and it
  belongs where a reader meets it, not buried at the end

## What a reviewer should actually run

`docs/tasking-guide.md:349` says a reviewer is not required to run Harbor, the oracle, the NOP or a
Docker build. Both reviews ran them anyway and it was decisive both times: on mithril, three of the
eleven notes were measurements no amount of reading would have produced, and two of them were the
lead findings. Budget the build.

The order that worked:

1. Extract the zip to `review_tasks/<name>/download/original/`, copy to `work/`, and run every
   command against `work/` (the same pristine-extract discipline as the submitter path)
2. Mechanical sweep on `work/`: git hygiene, `fsck`, both patches apply, `unzip -Z` for the script
   modes and the symlink count, stray artifacts, `instruction.md` against `problem_statement.md`
3. **PR comparability at hunk level, never file list.** Fetch the PR's per-file patches through the
   API and compare changed-line sets in both directions. On mithril this returned 304 changed lines
   each way with zero unique to either side, which is what took quality score 1 off the table in one
   step
4. Build the image and run NOP, the oracle cycle 3x, hostile delete
5. **The two invocations, added 2026-08-11 after both produced a blocking finding on a bundle three
   passes had already cleared.** They are runs rather than findings, which is exactly why re-reading
   your notes never surfaces them (`learning/audit-the-finished-review-not-just-each-finding.md`):
   - `sh /tests/test.sh`, never only `bash`. On mithril, dash rejected `set -uo pipefail` at line 9,
     which sits **before** the trap that guarantees a reward file, so the run wrote **no reward file
     at all** rather than reward 0. Read it with the script modes: a bundle at `0644` cannot be
     exec'd by shebang, so the harness must choose an interpreter (`learning/solve-sh-under-sh.md`)
   - The oracle cycle is `solve.sh` **then `test.sh`**, three times, one container. Not `solve.sh`
     three times, which measures the oracle *script*. mithril replays `solve.sh` 3 of 3 and scores
     **1 of 3** on the protocol (`learning/oracle-protocol-is-solve-then-verify.md`)
6. The stock-defect sweep below
7. Only then read for instruction quality, coverage and faithfulness

**And then audit the finished answer, as its own pass.** Every finding here passed its per-finding
checks and the document still came back **1 note confirmed, 9 weakened** under adversarial review,
with two contradicting remedies, one unreproducible number and one disproved mechanism. That pass is
Section 12.10 and `learning/audit-the-finished-review-not-just-each-finding.md`.

## The stock-defect sweep, which is most of a review

Two independent reviews of two unrelated bundles, a JavaScript vdom task and a Node API task,
converged on **five identical findings**. They are properties of the Harbor scaffold, so the
reviewer meets them on nearly every bundle and should check them first rather than discover them:

| Defect | mithril 2021 | expressa 132 | cista 172 |
|---|---|---|---|
| Grader never gates on `raw_exit_code` | present | present | present |
| `python3` reaches the image only behind an `\|\| true` | present | present | **absent** |
| A correct solution that logs an object scores zero | present | present | **absent** |
| `tests/test.sh` and `solution/solve.sh` ship `0644` | present | present | present |
| No restore of the test tree before `tests.patch` | present | present | present |

**cista 172 is why "nearly every bundle" is the right phrase and "every bundle" is not.** Its two
absences are structural rather than lucky, and each is decided by one command before any container
run. The object-logging defect cannot fire because `grading.parser.framework` is `custom`, and the
brace-slicing in `_find_json` is only reached for `jest` and `mocha`. The `python3` defect does not
apply because the verifier's dependency is a hard dependency of `meson` and `gcovr` on an install
line whose failure fails the build, rather than a passenger on an `|| true` chain. Report an absence
with its reason, because it tells the submitter which of the usual suspects they can stop worrying
about (LEDGER **L66**).

See [stock-bundle-defect-baseline.md](stock-bundle-defect-baseline.md), where the last two of these
are now defects 7 and 8, and [agent-writable-test-infrastructure.md](agent-writable-test-infrastructure.md)
for the probe that discriminated between the two bundles rather than firing on both.

## Do not hand-roll the mutation probes

Both wrong conclusions in the mithril session came from a `sed` that silently matched nothing:

- an agent-edit matrix whose "correct solution scores 0/15" row was a broken JS append, not a defect
- a "thrown exception is scored as a pass" result, drafted as **blocking**, that was a `sed` pattern
  that never fired against the golden-applied file

`bin/hostile-probe.sh` already solves this and exits **3** with `THE BREAK DID NOT LAND`, and its own
header cites the two earlier instances in `verify-in-the-image.md:328,366`. The knowledge was not
missing; the reviewer path just had no hookup to the tooling, so it got improvised. Use the script,
or copy its `assert needle in s` guard into whatever you improvise.

## Answer-file conventions both reviews converged on

Stored at `review_tasks/<name>/answers/review_answer.txt`, and the Section 5 writing rules apply to
it exactly as they do to `submission_answer.txt` (plain English, no em or en dashes, no internal
check vocabulary, one unwrapped line per paragraph).

- Open with what is **right**, with the measurements, before the notes. Both files do. It stops a
  revision round undoing the parts that already work, and it is the evidence for not scoring 1.
  **Superseded in part on 2026-08-14.** All three finished reviews open with the same sentence, the
  first ten words identical, and `docs/reviewer-rubric.md:119` asks for comments that are specific
  and idiosyncratic. The opener stays; its wording is written fresh from each bundle's own numbers
- One numbered note per finding, each with the evidence, a `Guidelines reference.` line where a
  section supports it, and a `What to do.` line. Reviewers are asked to cite Guidelines sections for
  specific or easily-missed rules (`docs/tasking-guide.md`, reviewer form question 4).
  **Superseded on 2026-08-14.** The measurement holds, 20 of the 39 notes across the three reviews
  carry the Guidelines line and 33 carry the remedy line, but the fixed labelled block is the
  "exhaustive parallel bullet lists" half of `docs/reviewer-rubric.md:121`. The evidence per note is
  unchanged and mandatory; the labels are not. See `.claude/rules/06-writing-rules.md` Section 5.1
- A closing note listing what you looked at and are **not** asking to change, so an unticked box is
  not read as an oversight
- Say which findings are measured and which are read, because a reader cannot otherwise tell a
  container run from a careful read. **Superseded in part on 2026-08-14.** The measurement holds and
  is itself the problem: all three reviews carry the sentence "I built the image and ran the bundle,
  which a reviewer is not required to do" verbatim, and three unrelated bundles sharing one sentence
  is the mirrored-language soft signal at `docs/reviewer-rubric.md:121`. The distinction stays and is
  mandatory; that sentence does not. Make the point out of this bundle's own runs, naming what you
  built and what you ran, so the wording is new every time. See `.claude/rules/06-writing-rules.md`
  Section 5.1

## Severity discipline, because half of what a first pass produces is wrong

An 8-dimension fan-out over mithril produced 77 candidate findings. Adversarial verification refuted
**40**, and four of the survivors' refutations were of findings the reviewer had already written into
the answer file. The pattern in the refutations, worth pre-empting:

- a workspace rule applied outside its stated scope (the em-dash ban is scoped by
  `.claude/rules/06-writing-rules.md:5` to form answers, not to `instruction.md`)
- a "practice" in `.claude/rules/11-verifier-hardening.md` read as a rule, when the section legend at
  its line 7 says practice is "not in `docs/` ... applied with judgment"
- a stock generator default reported as a submitter act, without checking `_archive/*/download/original/`
- a real mechanism whose remedy would make the bundle worse

Before filing, check the finding against `_archive/*/download/original/` for "is this just the
generator default" and against `_archive/*/work/` for "did the accepted bundles do it too". Four
LEDGER rows, L57 to L60, are the ones that failed those checks.
