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

**The platform may overwrite this answer, as of 2026-08-14.** `docs/faq.md`, "Difficulty checks are now capped - what is Invalid Difficulty?", gives a task **four difficulty checks**. A check spends one only when it runs and returns a result, so a submission that comes back before the check runs costs nothing, a technical issue that prevents a result costs nothing, and a reviewer sending the task back restarts the count at zero, which makes it a budget per review cycle and not a limit on the task's whole life. Once four have run without passing, the platform changes your answer on this question to **Invalid Difficulty** by itself and sends the task to review as it stands. It is not a rejection, it does not apply retroactively to tasks that closed before that date, and a human reviewer still reads it. Before 2026-08-14 there was no limit at all and a task could cycle through the difficulty check indefinitely.

**When it comes back with that verdict on it, the correct action is to resubmit an unchanged bundle, and this is the only place in this workspace where that is true.** The FAQ is explicit about the sequence: the task returns to you once with the verdict already set, and you submit it again without changing anything and leave the verdict as the platform set it. So do not rewrite the bundle, do not restore the verdict you had chosen, do not open a revision round against it, and do not read it as a bounce to fix (Step 10). There is nothing to work here. Read "without changing anything" as covering the form answers as well as the bundle, so the answers go back up as they stand and Step 10's rewrite of Comments for Reviewer does not fire on this one - that is a reading of the FAQ sentence rather than something anyone here has watched happen, so if the platform asks for a fresh answer at that point, take the platform's word and tell the user the reading was wrong.

**Four new read-only fields arrive with it and all four are now named**, measured off a capture of the live page on 2026-08-18 (`sample_review_page.md:149-177`), where `docs/faq.md` named only the first two. Nothing here fills any of them in, because they are read-only, but read them before spending a check: this is the only place the budget left in this review cycle is visible, and the measurement work that finds a difficulty lever belongs in front of the upload rather than in a check (Section 3, Fixable trigger 8).

| Field | The platform's own helper text | What it settles |
|---|---|---|
| **Difficulty checks run** | "How many times the difficulty check has run on this task **since the last review**. Maintained by the submission eval; not editable" | The per-review-cycle reset was inferred here from one FAQ sentence. "Since the last review" is the platform saying it |
| **Difficulty checks remaining** | "Difficulty-check runs left before this task is classified as unfixable on difficulty" | The budget, straight |
| **Last counted submission version** | "Bookkeeping for the difficulty-run counter: the submission version id the last increment was charged to, which is what makes a platform retry of the evaluation cost no run" | The mechanism behind "a technical issue that prevents a result costs nothing", which this file carried as a reading. An increment charged to a submission version cannot be charged to it twice |
| **Last difficulty check result** | "What the difficulty check last graded this task ... Persisted so the unfixable verdict can be re-applied if it is changed by the EC in the radio button" | That the platform will **re-apply** its verdict if you change the radio back. The instruction to leave Invalid Difficulty where the platform put it is enforced, not merely asked for |

**A blank counter is not a zero.** On the one page captured, the two fields `docs/faq.md` names are exactly the two that render **empty** (`sample_review_page.md:153-159`), while the two it does not name both carry values (`:165` and `:171`). The capture is genuinely silent on why, and the same conversion renders all four submitter handling-time inputs label-only, so a blank input is indistinguishable from an absent value in that format. Ask the user for the number rather than reading a blank as none spent.

**Drift, RESOLVED 2026-08-18, and recorded here because this file owns what the form actually shows.** The FAQ said the platform writes **Invalid Difficulty** into the validity question while `docs/tasking-guide.md:124-126` still listed exactly three answers, and this file's instruction was not to invent a fourth option nobody had seen. It has now been seen. `sample_review_page.md` shows it on the analysis question at `:69`, on the duplicate at `:93`, and in the `[For internal use]` Validity radio at `:79`, worded **"Invalid Difficulty (Difficulty runs have been exhausted and task is auto marked as invalid)"**. So the option is real and selectable in the same control as the other three. What has **not** changed is who picks it: `docs/faq.md` says the platform sets the value at the cap, the Last-difficulty-check-result field exists so the platform can re-apply it if an EC moves the radio, and nothing anywhere says a submitter chooses it. The remaining drift is in `docs/`, whose tasking-guide list and Changelog tab were both left at three options and at Aug 5, 2026.

#### Path A - Valid as-is

**Compliance checklist - must check ALL 7, and each may only be checked after verifying it is actually true against the files:**

1. Every requirement in the instructions is properly tested → verified via the requirement→test mapping
2. All test requirements are properly specified in the instructions → verified via the assertion→instruction mapping (no hidden requirements, no non-derivable names)
3. The instructions do not sound like an LLM generated them → persona check, no robotic phrasing
4. The instructions are not overly-prescriptive → over-prescription sign list is clean
5. The task does not leak solution information → no PR refs, no environment spoilers, no test-gaming
6. The oracle implements the solution following the instructions → solve.sh/patch vs instruction vs source PR
7. Contains more than 10 fail-to-pass tests in test suite → actually counted in Step 2

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
- [ ] Less than 10 fail-to-pass tests in test suite
```

Mapping: (1) coverage gaps; (2) faithfulness gaps, hidden checks, non-derivable names; (3)–(5) instruction tone and leakage; (6) the golden patch or solve.sh does not match the instruction; (7) the Step 2 f2p count came in under 10.

**3. "Describe each issue in detail" - only after both checkbox blocks. Use exactly this format, one numbered block per selected category:**

```
1) [Issue Category] - describe the specific issue, with code examples where helpful
- Is this issue fixable or not fixable?
- If fixable, how? If not, why not?
2) [Issue Category 2] - ...
```

**`[Issue Category]` must be one of the seven exact strings from the "What issues did you find with the task?" list above** - copied verbatim, not paraphrased and not invented. **The strings above were themselves off by one word until 2026-08-18**: the platform reads "Less than 10 fail-to-pass tests in test suite" (`sample_review_page.md:119`) and "More than 10 fail-to-pass tests in test suite" (`:357`), and this file carried "in **the** test suite" in three places with `.claude/rules/07-answer-templates.md` carrying it in three more. A one-word paraphrase in the source of truth for a verbatim requirement is self-undermining, so they are now the page's wording. The page also ends "The oracle does not implement the solution following the instructions." with a period (`:117`) where both files do not, which is left alone as punctuation rather than wording. The reviewer reads these blocks against the checkboxes you ticked, so a block headed with a category that is not on the list has nothing to line up with. Real answers files have shipped invented headings on a dozen blocks across three tasks.

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
8. More than 10 fail-to-pass tests in test suite

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

**The form cannot express Structure versus Difficulty, so the explanation has to.** `docs/reviewer-rubric.md:25-31` makes Unfixable two buckets that route and pay differently and tells the reviewer to tag them separately. Neither checkbox above is the difficulty bucket, confirmed against `docs/tasking-guide.md:199-208` where the list is exactly those two options. "PR scope needs to be changed or reduced" is the structure bucket in the rubric's own words (`:28`) and "Environment Issues" is the other half of that same bucket. So a task that is unfixable on difficulty still ticks the PR-scope box, because that is the only box its reasoning sits under, and then the FIRST line of the explanation names the bucket in the rubric's words so the reviewer can tag it correctly. Write it as "Unfixable - Difficulty. The task cannot be recalibrated without leaving the PR scope." or "Unfixable - Structure. The only fix is to reduce the source PR." and then start the numbered blocks. A reviewer left to infer the bucket out of four thousand characters of evidence is the reader `docs/reviewer-rubric.md:31` says ends up sending ECs into three or more unpaid revision loops. Check the other direction before you get here too: a task that is only slightly under-difficult and can still be raised inside the PR scope is Minor difficulty drift (`:111`) and belongs on Path B under Fixable trigger 8, not on this page at all. And none of this is the platform's **Invalid Difficulty** value, which lands on the analysis question at the four-check cap and is set by the platform rather than chosen here (the Task Analysis section above, `docs/faq.md`). The checkbox list on this page is unchanged and still carries no difficulty option.

**"Explain in more detail why this task is unfixable":** describe each issue clearly with evidence. Vague or incomplete descriptions may lead to rejection. For build failures, show why it is a tangled toolchain/version conflict and not a one-package fix. For network dependencies, show why the resource cannot be vendored (e.g. multi-GB model, live service).

**On Path C there is no zip, so the prose is the whole submission.** The upload field only appears when Fixable is selected (Path B above), which means nothing you inspected, measured or verified in `work/` is visible to anyone. The reviewer sees the verdict, the two checkbox groups, this explanation and Comments for Reviewer, and nothing else. `docs/tasking-guide.md:209` warns that a vague or incomplete description may lead to rejection, and on this path there is no bundle to make up the difference. Measured on the one accepted Not Fixable, libcrux 1165: seven numbered blocks and about 4900 characters of explanation, plus about 2200 characters of Comments for Reviewer. Treat those as the working shape, not as an upper bound.

**Keep Path B's numbered shape here even though the platform gives you one free-text box, and give the PR-scope limb the same evidence the environment limbs get.** One numbered block per issue, each citing files and lines. For either bucket, show what you measured and what it returned: what the oracle actually does, how the PR compares with tasks that measured hard, the pass rate as received, and every difficulty lever you prototyped with the number each one scored. A block that only asserts the task cannot be made harder is the vague description `docs/tasking-guide.md:209` is about. Say why you left a checkbox blank as well, because an unchecked box and an overlooked box look identical to a reviewer. See `learning/not-fixable-is-a-written-argument.md`.

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

**How they reach that verdict is now documented, and it is two independent paths.** `docs/reviewer-rubric.md:13-19` makes one confirmed violation of any Major Pillar enough for Needs Revision on its own, and separately makes five or more Minor violations across the eleven Secondary Requirements Needs Revision on systemic low quality. One to four Minor violations are accepted with mandatory coaching comments (`:19`), so a bundle with four small things wrong still passes and a bundle with one Major does not, however clean everything else is. Two things follow for how a round is worth spending. The five Major Pillars are oracle and golden correctness, `fail_to_pass` and `pass_to_pass` integrity, no leakage and not reward-hackable, airgapped verifier and network integrity, and git state, and every one of them is settled before the zip exists by the Step 5 pre-upload checklist and the Step 5.5 battery. And the Minor list is where cheap findings pile up, so count them rather than shrugging at them: a verifier timeout shorter than the config timeout, an unpinned base image, one ungraded instructed behaviour and a Files Changed count that does not match the diff is already four, and one more sends the task back on its own.

Their Needs Revision tags are the defect list to pre-empt: Instruction Styling, Instruction Prescriptiveness, Test ↔ Instruction Misalignment, Test Coverage Issues, Exposing Hints/Answers, Oracle Solution Issues, PR Scope Violation, Test Build Issues, Time-Based Tests, Task Difficulty, Metadata Issues, Uses Internet, Agent Timeout, Wrong Coding Language, Test Dependency Location, Pinning Issues, Environment, PR Relevancy, Other. That is the full list of 19 as it appears at `docs/tasking-guide.md:418-436`.

Reviewers are also asked to **cite the relevant section of the Guidelines** in their notes for specific or easily-missed rules (`docs/tasking-guide.md`, reviewer form question 4), so an incoming Needs Revision note may name the exact rule behind a finding. Read the cited section before reworking anything - it is the quickest way to settle what the finding is asking for.
