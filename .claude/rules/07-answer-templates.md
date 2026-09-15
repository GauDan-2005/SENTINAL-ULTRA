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

Created at `review_tasks/<Original Directory Name>/answers/review_answer.txt`. The standard reviewer
path is a five-minute platform-first static review, with one recorded five-minute static extension at
most. Form-ready completion ends the timer. Section 12 owns verdict substance and Section 13 owns the
timed sequence.

Same writing requirements as the submitter templates apply here: one unwrapped paragraph per line, no
em dash or scoring vocabulary in the paste, and **humanized last**. The humanizer edits reviewer-written
prose only. It never changes facts, citations, remedies, score, verdict, or duration. Do not modify the
humanizer skill or its Cursor twin for this path.

The reviewer page has seven questions. Q2a, Q2b, and Q3 are conditional on the verdict radio, so only
the applicable branch is pasted. Read the rebuttal before Q4 and record the actual elapsed time in Q6.

```text
Reviewer Answers
Task: [Original Directory Name]
Original task zip: [original id and timestamp]
Reviewed artifact: [submitted zip when supplied, otherwise original task zip]
Track: [timed-static-v1]
Review duration: [actual elapsed minutes]

Q1. What is your verdict for this Submission?

[Accept / Needs Revision / Reject]
(Reject only when the maximum-revisions dialog is visible and the task still needs work.)


Q2a. If Accept - confirm the task meets all the following requirements

[ ] Tests every requirement in the instructions
[ ] Test requirements are specified in the instructions
[ ] Does not appear generated by an LLM
[ ] Does not leak solution information
[ ] Oracle solution matches the instruction requirements
[ ] Instructions are not overly-prescriptive

(Tick only what this review verified. An Accept with one to four smaller confirmed issues leaves the
relevant non-absolute box unticked and explains the coaching in Q3.)


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

(Tick the smallest set covering notes actually written.)


Q3. Please explain in more detail what revisions are needed

[When the Reviewer Feedback block exists, begin with "Previous reviewer feedback follow-up". For every
earlier item, reproduce the feedback detail briefly, give direct current evidence, and label it Done,
Partly done, Not done, or Not assessed. Then begin "New findings from this review" and number only
confirmed new issues. Each note names the direct file, line, archive entry, page panel, or submitter
statement that supports it and gives the smallest remedy. State a Fixable or Unfixable bucket when it
matters. For an Accept with one to four confirmed smaller issues, write concrete coaching here. Do not
put rubric labels, pillar names, requirement numbers, or tally counts in this paste.]


Q4. Acknowledgement of Submitter Rebuttal

- [ ] I read the submitter's rebuttal and it does not change my review outcome.
- [ ] I read the submitter's rebuttal and revised my review outcome accordingly.
- [ ] No rebuttal comments available.


Q5. What is the overall quality of the submission?

[1-5] / 5

[One short paragraph tying the score to the confirmed evidence. Scores 1 and 2 pair with Needs
Revision. Scores 3 through 5 pair with Accept.]


Q6. How long (in minutes) did it take you to complete this review?

[actual timer value] minutes


--- Not part of the paste. Record only. ---

## Review timer
Track: timed-static-v1
Review UUID: [exact platform review task UUID, or NOT SUPPLIED]
Started: [timestamp after bootstrap]
Base deadline: [timestamp]
Extension used: [no / trigger class and timestamp]
Form-ready: [timestamp]
Actual elapsed: [minutes]

## Evidence reviewed
Original task zip: [id, timestamp, sha256]
Submitted task zip: [id, timestamp, sha256, or NOT SUPPLIED]
Reviewed artifact: [submitted zip when supplied, otherwise original task zip]
Reviewer page: [branch, panels, submitter answers, rebuttal, prior feedback actually read]

## Previous reviewer feedback
[For every item in the Reviewer Feedback block: item, direct current evidence, and one mark: fixed / partial / still open / not assessed. Reconcile this checklist before listing new items. No Accept while a required item is not assessed.]

## Fast static gate
[PASS / FAIL / SKIP names only]

## In-depth extension
[Not used, or the one trigger, the narrow static question, command/read performed, and result. No
Docker, Harbor, Oracle, NOP, container, mutation, or battery entry belongs here.]

## Rubric tally
[Confirmed findings only. Plain record vocabulary is allowed here: severity, the supporting pillar or
secondary requirement, provenance, bucket, verdict, and score. Observations are named as non-counting.]

## Deferred maintenance
[If previous reviewer feedback was present, record one evidence or clarity lesson for future review
writing without copying its boilerplate. If this verdict is Accept, add or update the task learning in
`learning/bundles-i-accepted-as-reviewer.md` and any genuinely new learning note. Append the exact
Review UUID once to root `review_tally.md`. After matching sha256 confirms the retained
`review_tasks/<name>/download/` copies, remove the original ZIP source copy and any submitted ZIP source copy that
sit directly in the workspace root. Never remove retained downloads, archives, or `logs_artifact.zip`.
Then record register, calibration, root-ZIP cleanup, and archive status. This work starts after
form-ready and never changes the recorded review duration.]
```
