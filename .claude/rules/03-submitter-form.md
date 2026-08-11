_Owner of CLAUDE.md **Section 2**. Loaded every session._

## 2. The Submitter Form - every question and how to answer it

### Section 1 · Task Metadata

Download the task zip into `tasks/<Original Directory Name>/download/` and extract to `download/original/` the directory that holds `instruction.md`, `task.toml`, `environment/`, `solution/` and `tests/`. **How the download is packaged varies:** those files may sit at the zip root, or inside a wrapper such as `task/` or `seed/`, and a `runs/` logs folder may or may not be included (`docs/harbor-framework.md`, task structure; `docs/tasking-guide.md` quick start step 2). Find them wherever they land and extract that directory, so `download/original/` always comes out in the same flat shape whatever the zip looked like. Step 1.5 asks the user for this, and nothing lands in the workspace root. The platform also displays the task data here - Original Directory Name, Category, Difficulty, Task Tags, Languages, and the Metadata (task.toml) block. Step 1.5 collects this from the user along with the zip itself and Step 2 cross-checks it against the extracted files.

### Section 2 · Task Analysis

**Q: "What is your analysis of the Sentinel task you downloaded above?"**
Appears twice, both required, both answers must match exactly.

- **Fixable** - issues in the instructions, tests, and/or oracle, but all can be corrected
- **Invalid/Not Fixable** - requires changes outside instructions/tests/oracle, or invalid for other reasons
- **Valid as-is** - valid without changes

Basis: the Step 4 verdict against Section 3 criteria.

#### Path A - Valid as-is

**Compliance checklist - must check ALL 7, and each may only be checked after verifying it is actually true against the files:**

1. Every requirement in the instructions is properly tested → verified via the requirement→test mapping
2. All test requirements are properly specified in the instructions → verified via the assertion→instruction mapping (no hidden requirements, no non-derivable names)
3. The instructions do not sound like an LLM generated them → persona check, no robotic phrasing
4. The instructions are not overly-prescriptive → over-prescription sign list is clean
5. The task does not leak solution information → no PR refs, no environment spoilers, no test-gaming
6. The oracle implements the solution following the instructions → solve.sh/patch vs instruction vs source PR
7. Contains more than 10 fail-to-pass tests in the test suite → actually counted in Step 2

Never check a box that was not verified. If ANY item fails, the verdict is not Valid as-is.

**Local run:** the user must run the oracle and NOP tests locally before submitting - this is the only check on Valid as-is tasks. Remind them and record the outcome. Cursor can run them on request using the Step 5.5 method.

#### Path B - Fixable

The form presents Path B in two phases: everything from the verdict down through the issue details sits ABOVE the zip upload field and must be answered BEFORE uploading (Phase 1); Files Changed onward is completed after the evals pass (Phase 2).

Answer these three in the platform's own order - the two checkbox lists first, the pastebox last.

**1. "Select where the task had issues" (check all that apply)** - render every option with its box, derived from where the recorded findings live:

```
Select where the task had issues (check all that apply):
- [ ] Instructions
- [ ] Tests
- [ ] Oracle Solution
- [ ] Environment/Dockerfile
```

**2. "What issues did you find with the task?" (check all that apply)** - same treatment, all seven options shown:

```
What issues did you find with the task?
- [ ] Every requirement in the instructions is not properly tested
- [ ] All test requirements are not properly specified in the instructions
- [ ] The instructions appear LLM generated
- [ ] The instructions are overly-prescriptive
- [ ] The task leaks solution information
- [ ] The oracle does not implement the solution following the instructions
- [ ] Less than 10 fail-to-pass tests in the test suite
```

Mapping: (1) coverage gaps; (2) faithfulness gaps, hidden checks, non-derivable names; (3)–(5) instruction tone and leakage; (6) the golden patch or solve.sh does not match the instruction; (7) the Step 2 f2p count came in under 10.

**3. "Describe each issue in detail" - only after both checkbox blocks. Use exactly this format, one numbered block per selected category:**

```
1) [Issue Category] - describe the specific issue, with code examples where helpful
- Is this issue fixable or not fixable?
- If fixable, how? If not, why not?
2) [Issue Category 2] - ...
```

**`[Issue Category]` must be one of the seven exact strings from the "What issues did you find with the task?" list above** - copied verbatim, not paraphrased and not invented. The reviewer reads these blocks against the checkboxes you ticked, so a block headed with a category that is not on the list has nothing to line up with. Real answers files have shipped invented headings on a dozen blocks across three tasks.

Defects that genuinely fall outside the seven go in a separated trailing group, after the numbered blocks, under the heading **"Additional findings outside the listed categories"**. Keep the same numbered shape inside it. The existing blocks that already say a finding "does not map to a checkbox" are the model to follow.

Every description cites files and lines. Code examples are welcome here.

**Re-upload (the upload field appears when Fixable is selected, BELOW the questions above):** the zip built into `tasks/<name>/upload/` by the Step 5 re-zip rule (no runs/, no task/ wrapper), submitted as `<all-task-content>`. Upload it only after the Phase 1 answers above are entered in the platform.

**Phase 2 - answer these AFTER Check feedback and once the evals pass:**

**"Files Changed":** every changed file - file path, what changed, why. Comes straight from the Step 5 change log. No need to repeat validation details already given above. **Scope: paths inside the upload zip for this task, and nothing else.** Never `CLAUDE.md`, `INDEX.md`, `task.md`, `learning/`, `docs/`, `.cursor/rules/` or `.claude/skills/` - those are workspace bookkeeping, they are not in the bundle, and listing them tells the reviewer you changed files they cannot see. Paths are written as they appear in the zip (`tests/test.sh`, not `tasks/<name>/work/tests/test.sh`).

**PR additions:** if the PR scope was expanded in any way, explain how (must be original PR + additions). If the PR was not modified at all, write exactly **"NA"**.

**Post-fix confirmation - the platform requires ALL 8 selected for the task to count as valid. Check each only after verifying it is true post-fix:**

1. Every requirement in the instructions is properly tested
2. All test requirements are properly specified in the instructions
3. The instructions do not sound like an LLM generated them
4. The instructions are not overly-prescriptive
5. The task does not leak solution information
6. The oracle implements the solution following the instructions
7. The PR was not modified in any way beyond what is allowed by the guidelines
8. More than 10 fail-to-pass tests in the test suite

**"How long did it take you to complete the initial task rewrite only?"** - minutes, from the user.

#### Path C - Invalid/Not Fixable

**"What issue did you find with the task/components?" (check all that apply):**

- PR scope needs to be changed or reduced
- Environment Issues

**If Environment Issues, the specific issues (check all that apply):**

- Image/Dependency Build Failures
- Oracle timeout
- External-network dependency at build/solve time
- Dirty git history that can't be recovered - RARE: most git issues are fixable per the Git rules, so select this only for genuinely unrecoverable corruption

**"Explain in more detail why this task is unfixable":** describe each issue clearly with evidence. Vague or incomplete descriptions may lead to rejection. For build failures, show why it is a tangled toolchain/version conflict and not a one-package fix. For network dependencies, show why the resource cannot be vendored (e.g. multi-GB model, live service).

**On Path C there is no zip, so the prose is the whole submission.** The upload field only appears when Fixable is selected (Path B above), which means nothing you inspected, measured or verified in `work/` is visible to anyone. The reviewer sees the verdict, the two checkbox groups, this explanation and Comments for Reviewer, and nothing else. `docs/tasking-guide.md:209` warns that a vague or incomplete description may lead to rejection, and on this path there is no bundle to make up the difference. Measured on the one accepted Not Fixable, libcrux 1165: seven numbered blocks and about 4900 characters of explanation, plus about 2200 characters of Comments for Reviewer. Treat those as the working shape, not as an upper bound.

**Keep Path B's numbered shape here even though the platform gives you one free-text box, and give the PR-scope limb the same evidence the environment limbs get.** One numbered block per issue, each citing files and lines. For a scope or difficulty limb, show what you measured and what it returned: what the oracle actually does, how the PR compares with tasks that measured hard, the pass rate as received, and every difficulty lever you prototyped with the number each one scored. A block that only asserts the task cannot be made harder is the vague description `docs/tasking-guide.md:209` is about. Say why you left a checkbox blank as well, because an unchecked box and an overlooked box look identical to a reviewer. See `learning/not-fixable-is-a-written-argument.md`.

**Never reach Path C on the strength of a failed eval alone.** Infra and platform failures never make a task Unfixable (Section 3). Confirm the failure is caused by the task and reproduces every run before selecting any of the boxes above.

#### Difficulty question - Valid as-is AND Fixable ONLY (not asked for Invalid)

**"What makes this task difficult?"** Describe the genuine technical challenge: edge cases, implementation dependencies, requirements that may be overlooked on first reading, complexity in the test setup. Good difficulty comes from the problem itself (complex debugging, root-cause analysis, a substantial feature, hard domain/security work) - never from vagueness or bolt-ons. Ground every claim in named files, functions, and tests; failing trials' `test-stdout.txt` shows what agents actually got wrong.

#### Final Comment and Handling Time - ALL paths

- **Comments for Reviewer:** assumptions made, edge cases considered, reasons a file was NOT changed, judgment calls, anything warranting reviewer judgment or a second opinion. Include the oracle/NOP results (Step 5.5 for Fixable, user-run for Valid as-is) where relevant. On a revision round this field is rewritten every time (Step 10): say which round it is, what the round changed, what you deliberately did not change and why, and the fresh oracle/NOP numbers.
- **Senior engineer estimate:** `<10 minutes` / `10–20 minutes` / `20–40 minutes` / `40+ minutes` - in the platform this appears right after the difficulty question, before the Final Comment section (for Valid as-is and Fixable). Based on the size and spread of the gold patch, files and functions touched, subtlety of the fix, agent pass rates in runs/, and the task.toml `expert_time_estimate_min` when present (e.g. 150 min → the 40+ bucket)
- **Time to review the initial task and determine validity** - minutes, from the user
- **Time to complete the entire submission** - minutes, from the user. Read as fields 1 + 2 + 3 from the Step 8 table, **excluding** the revision time which has its own field. That exclusion is an inference and `docs/tasking-guide.md:229` reads the other way - see Step 8 before writing a number. 180–240 is the usual shape of a first pass and not a limit; the accepted kvdex bundle shipped 260 with 195 minutes of revisions

#### What the reviewer will check (write the submission to survive this)

A second EC repeats the same document and logic review, reads Comments for Reviewer, and returns Accept / Needs Revision / Reject, plus a 1–5 Submission Quality Score. Scores 1–2 send the task back, 3–5 accept. A 1 means the source content was deviated from (wrong PR, substituted repo code) or the submission looks low-effort; a 2 means real gaps such as untested requirements, instruction-test misalignment, or a bundle mismatch.

Their Needs Revision tags are the defect list to pre-empt: Instruction Styling, Instruction Prescriptiveness, Test ↔ Instruction Misalignment, Test Coverage Issues, Exposing Hints/Answers, Oracle Solution Issues, PR Scope Violation, Test Build Issues, Time-Based Tests, Task Difficulty, Metadata Issues, Uses Internet, Agent Timeout, Wrong Coding Language, Test Dependency Location, Pinning Issues, Environment, PR Relevancy, Other. That is the full list of 19 as it appears at `docs/tasking-guide.md:418-436`.

Reviewers are also asked to **cite the relevant section of the Guidelines** in their notes for specific or easily-missed rules (`docs/tasking-guide.md`, reviewer form question 4), so an incoming Needs Revision note may name the exact rule behind a finding. Read the cited section before reworking anything - it is the quickest way to settle what the finding is asking for.
