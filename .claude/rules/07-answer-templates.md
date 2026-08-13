_Owner of CLAUDE.md **Section 6**. Loaded every session._

## 6. submission_answer.txt templates

Created in Step 9 as `tasks/<Original Directory Name>/answers/submission_answer.txt` - only after every step for the current task is complete and the user has provided the time numbers.

Six rules that apply to all four templates - the three submitter paths below and the Path D reviewer template at the end of this file:

- **Humanized last.** Once the file is filled in, run the `humanizer` skill over every free-text answer in it and save the result back. Paths, names, commands, code, checkbox lines and the time numbers stay verbatim. A template filled in but not yet humanized is not a finished file.
- **The file is living, not a one-time artifact.** Every revision round edits it (Step 10) and re-humanizes what changed. It must always describe the bundle currently sitting in `tasks/<name>/upload/`.
- **No word wrap.** Each paragraph is one unbroken line. The placeholders below are short only because they are placeholders; the real text replacing them runs as long as it needs to on a single line.
- **No em dashes anywhere in these templates or in the file built from them.** The issue-block and sub-answer markers are hyphens. Section 5 bans em dashes and exempts only code examples, and a template that shows one is where the wrong inference starts. Verify with a bare count and no exclusions: `grep -cP '\x{2014}' <file>` must return 0.
- **The handling-time block is four asked numbers plus a computed total** (Step 8). The total is fields 1 + 2 + 3 and the revision figure is tracked separately - an inference, not verified behaviour, see Step 8 before writing it. The ranges printed below are sanity hints, not limits: the one accepted bundle shipped 260 and 195.
- **The Send-to-reviewer decision is a stored field**, filled from the Step 7 gate. The platform's own eval summary panels (Static, Difficulty, Oracle, Quality) are read-only outputs and are deliberately NOT template fields - their results belong in `task.md` and in Comments for Reviewer, not copied into an answers slot nobody pastes them into.

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
[x] Contains more than 10 fail-to-pass tests in the test suite (counted: N)

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
- [ ] Less than 10 fail-to-pass tests in the test suite

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
[x] More than 10 fail-to-pass tests in the test suite (counted: N)

Send to reviewer: [Yes / No - which Step 7 gate condition failed, why you sent anyway, and what you tried]

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
when a review is assigned. Full workflow in Section 12. Same six rules as the submitter templates above:
humanized last, living across rounds, no word wrap, **no em dashes anywhere**, and the Section 5
writing rules in full.

The live form has **four** questions where `docs/tasking-guide.md:401-459` describes seven. Confirmed by
two independent captures on 2026-08-11 (mithril/expressa, then cista 172), so the two extra fields are
**not** template fields any more. Where the submitter's answers were unavailable, record that under the
answer rather than inventing a `PENDING` form field for it.

```
Reviewer Answers
Task: [Original Directory Name]
Submission zip: [the zip you were given]


Q1. What is your verdict for this Submission?

[Accept / Needs Revision / Reject]
(Reject ONLY when the "maximum revision reached" dialog is showing AND it still needs work)


Q2a. If Accept - confirm the task meets all the following requirements
(the 2026-08-11 cista capture showed only the last five of these six, missing the first, but that
paste was visibly truncated elsewhere. Keep all six until an untruncated Accept-branch capture says
otherwise, and tick only what you verified.)
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

[Open with what is RIGHT, with the measurements, before any note. Then one line saying which
findings are measured and which are read.]

Note 1. [one line stating the finding]
[the evidence, with the numbers if you measured it]
Guidelines reference. [the docs/ section that makes it a defect, where one does]
What to do. [the fix]

Note 2. ...

Note N. [the closing note: what you looked at and are NOT asking to change, including any
finding you filed and withdrew, with why. An unticked box and an overlooked one look identical
to a submitter.]


Q4. What is the overall quality of the submission?

[1-5] / 5

[one paragraph. A bundle whose golden and tests reproduce the PR exactly cannot be a 1, however
many verifier defects it carries.]


--- Not part of the paste. Record only. ---

Submitter answers. [Whether they were supplied. Three reviews now have received the zip alone, and
on cista 172 the submitter confirmed the platform shows nothing else, so this is the normal case.
Name the one or two notes their answers could already have closed. Every other note has to stand on
the bundle, which is what makes it safe to hand over unread.]

Form shape. [Anything the live form did today that the template does not predict. Two captures on
2026-08-11 agree on four questions and on the absence of the Acknowledgement of Submitter Rebuttal
and review-duration fields that docs/tasking-guide.md:401-459 describes, so their absence is settled
and does not need re-recording. A NEW difference does.]
```
