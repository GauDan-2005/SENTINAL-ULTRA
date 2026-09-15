_Owner of CLAUDE.md **Section 6**. Loaded every session._

## 6. submission_answer.txt templates

Created in Step 9 as `tasks/<Original Directory Name>/answers/submission_answer.txt` - only after every step for the current task is complete and the user has provided the time numbers.

Six rules for building these templates - the three submitter paths below and the Path D reviewer template at the end of this file. The first five hold for all four; the sixth describes a field that only Path B carries:

- **Humanized last.** Once the file is filled in, run the `humanizer` skill over every free-text answer in it and save the result back. Paths, names, commands, code, checkbox lines and the time numbers stay verbatim. A template filled in but not yet humanized is not a finished file.
- **The file is living, not a one-time artifact.** Every revision round edits it (Step 10) and re-humanizes what changed. It must always describe the bundle currently sitting in `tasks/<name>/upload/`.
- **No word wrap.** Each paragraph is one unbroken line. The placeholders below are short only because they are placeholders; the real text replacing them runs as long as it needs to on a single line.
- **No em dashes anywhere in these templates or in the file built from them.** The issue-block and sub-answer markers are hyphens. Section 5 bans em dashes and exempts only code examples, and a template that shows one is where the wrong inference starts. Verify with a bare count and no exclusions: `grep -cP '\x{2014}' <file>` must return 0.
- **The handling-time block is four asked numbers plus a computed total** (Step 8). The total is fields 1 + 2 + 3 and the revision figure is tracked separately - an inference, not verified behaviour, see Step 8 before writing it. The ranges printed below are sanity hints, not limits: the accepted bundles run 195 to 260 on the total and 0 to 370 on revisions, kvdex at 260 and 195.
- **The pre-submit gate decision is a stored field**, filled from the Step 7 gate, and it appears on Path B only. It used to be called Send to reviewer, after a checkbox that was removed from the form on 2026-08-05 (`docs/tasking-guide.md:251`). A submission whose evals pass now reaches the reviewer queue on its own, and one whose evals fail comes back to you, so there is nothing to paste and nothing to tick. The field is a record of whether the gate was clear at the moment the task was submitted, which is what the next round has to re-read. The platform's own eval summary panels (Static, Difficulty, Oracle, Quality) are read-only outputs and are deliberately NOT template fields - their results belong in `task.md` and in Comments for Reviewer, not copied into an answers slot nobody pastes them into.

### Path A - Valid as-is

```
Submitter Answers - Valid as-is
Task: [Original Directory Name from Step 1.5]

What is your analysis of the Sentinel task? (both occurrences)
Valid as-is
[Internal] Validity: Valid-as-is

Compliance checklist (each verified against the files):
[x] Every requirement in the instructions is properly tested
[x] All test requirements are properly specified in the instructions
[x] The instructions do not sound like an LLM generated them
[x] The instructions are not overly-prescriptive
[x] The task does not leak solution information
[x] The oracle implements the solution following the instructions
[x] Contains more than 10 fail-to-pass tests in test suite (counted: N)

Local oracle and NOP run: [user-reported result]

What makes this task difficult?
[1 short paragraph]

Senior engineer estimate: [<10 / 10-20 / 20-40 / 40+ minutes]

Comments for Reviewer:
[1 short paragraph]

Handling time

How long did it take you to review the initial task and determine its validity?
[user number] minutes

How long did it take you to complete the initial task rewrite only?
[user number] minutes
(pre-first-upload edits only, Fixable path. 0 on Valid as-is and Invalid)

How long did it take you to complete the additional questions on the form?
[user number] minutes

Total submission time: [sum of the three fields above] minutes
(the three fields above only. The revision time below is NOT part of this, which is an inference and not verified platform behaviour, see Step 8. 180-240 is a shape hint, not a limit)

How long did it take you to complete all revisions?
[user number] minutes
(post-first-upload rounds only, tracked separately from the total. 0 before the first bounce. Copy the last Cumulative cell of the task.md handling-time ledger, do not estimate it)
```

### Path B - Fixable

```
Submitter Answers - Fixable
Task: [Original Directory Name from Step 1.5]

What is your analysis of the Sentinel task? (both occurrences)
Fixable
[Internal] Validity: Fixable

Select where the task had issues (check all that apply):
- [ ] Instructions
- [ ] Tests
- [ ] Oracle Solution
- [ ] Environment/Dockerfile

What issues did you find with the task?
- [ ] Every requirement in the instructions is not properly tested
- [ ] All test requirements are not properly specified in the instructions
- [ ] The instructions appear LLM generated
- [ ] The instructions are overly-prescriptive
- [ ] The task leaks solution information
- [ ] The oracle does not implement the solution following the instructions
- [ ] Less than 10 fail-to-pass tests in test suite

Issue details (pastebox, comes after both checkbox lists):
[Issue Category] must be one of the seven exact strings from the list above, copied verbatim.
1) [Issue Category] - [specific issue, code examples where helpful]
- Is this issue fixable or not fixable? [answer]
- If fixable, how? [answer]
2) ...

Additional findings outside the listed categories:
[only if a real defect maps to none of the seven. Same numbered shape. Omit this heading entirely when there are none]

--- Phase 2 (completed after the evals pass) ---

Files Changed:
(paths inside the upload zip only. Never CLAUDE.md, INDEX.md, task.md, learning/, docs/, .cursor/rules or .claude/skills)
1. [file path as it appears in the zip, e.g. tests/test.sh]
   Changed: [what]
   Why: [reason]

PR additions:
[how the PR scope was expanded, or "NA"]

Post-fix confirmation (each verified after fixes):
[x] Every requirement in the instructions is properly tested
[x] All test requirements are properly specified in the instructions
[x] The instructions do not sound like an LLM generated them
[x] The instructions are not overly-prescriptive
[x] The task does not leak solution information
[x] The oracle implements the solution following the instructions
[x] The PR was not modified in any way beyond what is allowed by the guidelines
[x] More than 10 fail-to-pass tests in test suite (counted: N)

Pre-submit gate: [Clear / Not clear - which Step 7 condition was unmet, what was still outstanding, and what happened next. Record only. There is no checkbox on the form, and a submission that fails an eval is returned to you instead of reaching a reviewer, so a Not clear line names work still to do and never a reason for going ahead anyway]

What makes this task difficult?
[1 short paragraph]

Senior engineer estimate: [<10 / 10-20 / 20-40 / 40+ minutes]

Comments for Reviewer:
[1 short paragraph]

Handling time

How long did it take you to review the initial task and determine its validity?
[user number] minutes

How long did it take you to complete the initial task rewrite only?
[user number] minutes
(pre-first-upload edits only, Fixable path. 0 on Valid as-is and Invalid)

How long did it take you to complete the additional questions on the form?
[user number] minutes

Total submission time: [sum of the three fields above] minutes
(the three fields above only. The revision time below is NOT part of this, which is an inference and not verified platform behaviour, see Step 8. 180-240 is a shape hint, not a limit)

How long did it take you to complete all revisions?
[user number] minutes
(post-first-upload rounds only, tracked separately from the total. 0 before the first bounce. Copy the last Cumulative cell of the task.md handling-time ledger, do not estimate it)
```

### Path C - Invalid/Not Fixable

```
Submitter Answers - Invalid/Not Fixable
Task: [Original Directory Name from Step 1.5]

What is your analysis of the Sentinel task? (both occurrences)
Invalid/Not Fixable
[Internal] Validity: Invalid

Issues found with the task/components:
[PR scope needs to be changed or reduced / Environment Issues]

Specific environment issues (if applicable):
[Image/Dependency Build Failures / Oracle timeout / External-network dependency / Dirty git history that can't be recovered]

Why this task is unfixable:
(there is no zip on this path, so this field and Comments for Reviewer are the entire
submission - Section 2, Path C. One numbered block per issue, each citing files and lines, and for a
scope or difficulty limb the measurement and the number it returned)
1) [issue, with the file:line evidence and any measured number]
2) ...

Comments for Reviewer:
[1 short paragraph on Valid as-is and Fixable. On this path it runs longer, because there is no
bundle, no difficulty answer and no Files Changed behind it]

Senior engineer estimate: [<10 / 10-20 / 20-40 / 40+ minutes]
Handling time

How long did it take you to review the initial task and determine its validity?
[user number] minutes

How long did it take you to complete the initial task rewrite only?
[user number] minutes
(pre-first-upload edits only, Fixable path. 0 on Valid as-is and Invalid)

How long did it take you to complete the additional questions on the form?
[user number] minutes

Total submission time: [sum of the three fields above] minutes
(the three fields above only. The revision time below is NOT part of this, which is an inference and not verified platform behaviour, see Step 8. 180-240 is a shape hint, not a limit)

How long did it take you to complete all revisions?
[user number] minutes
(post-first-upload rounds only, tracked separately from the total. 0 before the first bounce. Copy the last Cumulative cell of the task.md handling-time ledger, do not estimate it)
```

### Path D - Peer review (`review_answer.txt`)

Not a submitter path. Created at `review_tasks/<Original Directory Name>/answers/review_answer.txt`
when a review is assigned. What a finding is and how it is written is Section 12; the order the review
runs in, R1 to R11, is Section 13. Same first five rules as the submitter templates above:
humanized last, living across rounds, no word wrap, **no em dashes anywhere**, and the Section 5
writing rules in full.

The live form has **seven** questions, exactly the seven `docs/tasking-guide.md:401-459` describes.
This template said four until 2026-08-18, on two captures from 2026-08-11 that showed neither the
rebuttal acknowledgement nor the review-duration field. Both were truncated pastes, and
`sample_review_page.md`, a conversion of the whole reviewer page, carries the rebuttal field at
`:433-441` and the duration field at `:467` (LEDGER **L100**). Both are answered here. Q2a, Q2b and Q3
are conditional on the verdict radio and only one branch of Q2 ever renders.

Those seven questions are the form. What decides the answer inside them is `docs/reviewer-rubric.md`,
added to the Hub on 2026-08-12. One confirmed Major Pillar violation is Needs Revision on its own
(`docs/reviewer-rubric.md:17`). Five or more Minor violations across the eleven Secondary Requirements
is Needs Revision too (`:19`). One to four Minors is an Accept and the coaching comments are
**mandatory** (`:99`), so Q3 gets written on an Accept as well and is not a field that only appears on
the way back. Before counting anything, decide which of three buckets the task is in - Fixable,
Unfixable - Structure, Unfixable - Difficulty - and never lump the last two together as invalid, which
is what sends submitters into unpaid revision loops on tasks that were never fixable (`:31`). The
pillars and the requirements are Section 12.

```
Reviewer Answers
Task: [Original Directory Name]
Seed zip: [the zip from "Download Sentinel 2.0 task here", the task as issued]
Submitted zip: [the zip from the re-upload field, with its timestamp]
Round: [which submission of this task you are reviewing]


Q1. What is your verdict for this Submission?

[Accept / Needs Revision / Reject]
(Reject ONLY when the "maximum revision reached" dialog is showing AND it still needs work)
(Read the verdict off the tally in the record block at the bottom, not off how the notes feel on the
way out. One Major is Needs Revision. Five Minors is Needs Revision. One to four Minors is Accept, with
the coaching comments in Q3.)
(Name the bucket as well - Fixable, or Unfixable - Structure, or Unfixable - Difficulty. The form has
no control for the last two, so the bucket goes in the first line of Q3 and gets tagged in Q2b, PR
Scope Violation for Structure and Task Difficulty for Difficulty.)


Q2a. If Accept - confirm the task meets all the following requirements
(the 2026-08-11 cista capture showed only the last five of these six, missing the first, but that
paste was visibly truncated elsewhere. Keep all six until an untruncated Accept-branch capture says
otherwise, and tick only what you verified.)
(An Accept carrying one to four Minor violations still owes written coaching comments, per
docs/reviewer-rubric.md:99, so Q3 is filled in on this branch too. Six ticks and an empty Q3 is not an
Accept, it is an unfinished review.)
(These six are what the form shows; the rubric is what decides the verdict, so they are not six
absolute bars. Four of the eleven Secondary Requirements falsify one of them on their own and stay
Minor: a coverage gap (docs/reviewer-rubric.md:104) falsifies the first, instruction ambiguity (:108)
the second, a templated instruction (:107) the third, an over-prescriptive instruction (:106) the
sixth. Leave that box unticked, keep the verdict at Accept while the Minor count is one to four, and
say in the first line of Q3 which box you left unticked and which Minor is behind it. Never tick a box
you know is false to make the branch submit. The other two boxes, leaking solution information and the
oracle matching the instruction, sit on Pillars 3 and 1, so a false one there is a Major and the
verdict is Needs Revision rather than Accept.)
[ ] Tests every requirement in the instructions
[ ] Test requirements are specified in the instructions
[ ] Does not appear generated by an LLM
[ ] Does not leak solution information
[ ] Oracle solution matches the instruction requirements
[ ] Instructions are not overly-prescriptive

Q2b. If Needs Revision - Error Categories (select all that apply)
- [ ] Instruction Styling
- [ ] Instruction Prescriptiveness
- [ ] Test <-> Instruction Misalignment
- [ ] Test Coverage Issues
- [ ] Exposing Hints/Answers
- [ ] Oracle Solution Issues
- [ ] PR Scope Violation
- [ ] Test Build Issues
- [ ] Time-Based Tests
- [ ] Task Difficulty
- [ ] Metadata Issues
- [ ] Uses Internet
- [ ] Agent Timeout
- [ ] Wrong Coding Language
- [ ] Test Dependency Location
- [ ] Pinning Issues
- [ ] Environment
- [ ] PR Relevancy
- [ ] Other


Q3. Please explain in more detail what revisions are needed
(written on an Accept as well, whenever there is at least one Minor. On that branch it is coaching
rather than a required change, and the opening line says which it is.)

[Open with what is RIGHT, with the measurements, before any note, and write that opening out of this
bundle's own numbers. All three reviews in review_tasks/ open with the same ten words, "Start with what
is right, because none of it should", and only part company at word eleven, and all three then carry
the sentence "I built the image and ran the bundle, which a reviewer is not required to do" verbatim.
Three independent reviews landing on a ten word opening and one identical sentence is the
mirrored-language signal at docs/reviewer-rubric.md:121. Say which findings you measured and which you
read in your own words rather than in the wording all three of them reuse. Then say plainly how much is
wrong and whether any single item blocks acceptance on its own, and name anything you are only
recording as an observation so it does not read as one more thing
to fix. Keep the counting vocabulary out of the paste and in the record block at the bottom.]

Note 1. [the finding in one line, in ordinary words, saying whether it blocks acceptance on its own or
is a smaller thing]
[the evidence, with the file, the line and the number. Every note carries this much, because it is the
Meets line at docs/reviewer-rubric.md:119 and no note is worth losing a citation over.]
[the docs/ section that makes it a defect, when one genuinely backs it. Twenty of the thirty nine notes
written here have one, so it is a real citation and not a slot to fill.]
[the fix. In the sentence that names the defect when it is a one-line change, in a paragraph of its own
when it has a sequence, a payload or a measurement behind it.]

Note 2. ...

Note N. [the closing note: what you looked at and are NOT asking to change, including any
finding you filed and withdrew, with why. An unticked box and an overlooked one look identical
to a submitter.]

[Do NOT give every note the same three labelled lines. A fixed Note, evidence, Guidelines reference,
What to do block repeated N times is the exhaustive parallel list at docs/reviewer-rubric.md:121, and
any four of those six signals in one review is a Major against the reviewer. Vary the shape with what
each finding actually needs, and keep the evidence in every one of them.]


Q4. Acknowledgement of Submitter Rebuttal

(sample_review_page.md:433-441. Open the rebuttal comments in the left-hand panel and read the
submitter's notes in full BEFORE answering. This is a real field, not a formality: their notes are
the one place a judgment call gets explained, and a finding their rebuttal already answers is a
finding you withdraw rather than file. Pick exactly one.)

- [ ] I read the submitter's rebuttal and it does not change my review outcome.
- [ ] I read the submitter's rebuttal and revised my review outcome accordingly.
- [ ] No rebuttal comments available.

(If you picked the second, say in Q3 which note moved and why, because the submitter cannot see the
radio. If you picked the third, that is a statement about the panel and not about their Comments for
Reviewer field, which is a different surface and IS rendered on the page.)


Q5. What is the overall quality of the submission?

[1-5] / 5

[one paragraph. A bundle whose golden and tests reproduce the PR exactly cannot be a 1, however
many verifier defects it carries.]

[The score has to agree with Q1. Scores 1 and 2 are Needs Revision and 3 to 5 are Accept
(docs/tasking-guide.md:453-459), so a confirmed Major or five Minors lands at 2, with 1 reserved for
deviation from the source content. An Accept carrying one to four Minors is a 3, because 4 and 5 both
say nothing significant is left. Read the two answers against each other before pasting.]


Q6. How long (in minutes) did it take you to complete this review?

[user number] minutes

(sample_review_page.md:467. From the user, never invented, the same rule as every handling-time field
on the submitter paths. A review has only this one: no rewrite time, no revision time and no computed
total, so the Step 8 arithmetic and its bands do not apply here.)


--- Not part of the paste. Record only. ---

Submitter answers. [What you were given and what you asked for. The reviewer page renders their
verdict, both checkbox groups, the numbered issue details, Files Changed, PR additions, the eight
confirmations, the difficulty answer, the senior estimate and Comments for Reviewer
(sample_review_page.md:56-148 and :323-415), so the 2026-08-11 reading that the zip arrives alone is
retired (LEDGER L101). Name anything that genuinely was not there AND what you did to get it, because
docs/reviewer-rubric.md:123 makes claiming something is inaccessible when it is visibly present a
flaggable item. Then name the notes their answers already close, which are the notes you withdraw.]

Claims verified. [Their numbered issues and Files Changed entries, each marked HOLDS, DOES NOT HOLD
or NOT CHECKABLE HERE against the seed-versus-submitted diff. A claim that does not hold is its own
finding and it is Secondary Requirement 5, separate from whatever defect sits under it.]

Eval panels. [What Static, Prescriptiveness, Difficulty, Agentic Judge, Oracle and Quality returned on
the page (sample_review_page.md:179-321), and the four difficulty counters (:149-177), read against
your own runs. Where the platform and your container disagree, say which is which and do not average
them. A bundle whose grader you have found broken produces pass rates wrong in both directions, so
file the grader finding first and say the difficulty numbers cannot be read until it is fixed.]

Form shape. [Anything the live form did today that the template does not predict. Settled and not
worth re-recording: seven questions, with Q2a, Q2b and Q3 conditional on the verdict radio; the
validity question carrying Invalid Difficulty as a live fourth option; and the four difficulty
counters. A NEW difference does get recorded, and so does an UNTRUNCATED capture of the Accept branch,
which is the one open caveat: two truncated pastes showed five confirmation items where docs lists
six, and no capture since has had a verdict selected, so the branch has never actually been seen.]

Rubric tally. [The arithmetic, kept here and NOT pasted. Majors, each named with the pillar it violates.
Minors, each named with the secondary requirement it is. Observations, listed and marked as not counting
toward the five. The bucket, Fixable or Unfixable - Structure or Unfixable - Difficulty. Then the verdict
those counts give, read against the one actually entered in Q1, and the score read against it as well.
It stays out of the paste because rubric-aware framing is one of the six soft signals of an LLM-written
review at docs/reviewer-rubric.md:121, and four signals in one review is a Major against the reviewer.]

```
