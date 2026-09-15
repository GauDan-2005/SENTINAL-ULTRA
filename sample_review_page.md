# Snorkel AI Experts Portal

# Review

UID:

1f5ffbd1-489c-49c3-8c5b-695895bde5fc

Task Notes

Automated feedback

All checks have passed

Reviewer Feedback

8/16/26, 8:37 PM

The 8/11 review asked for an observable instruction, fuller negative coverage, an end-of-value position check, stronger hash/zset cases, collision-safe test filenames, a fail-closed reward, and two task.toml fields. This zip fixed the coverage and filename items. The instruction rewrite and the grader did not. Quality Check is 14/15 and still fails Q9. The Interface section names the packages to edit and the functions and types to create: internal/rdb/structure, ReadModuleUnsigned, ReadModuleSigned, ReadModuleString, ReadModuleDouble, ReadModuleFloat, ReadModuleEof, TairStringObject, TairHashObject, TairZsetObject, ParseObject, and CalcKeys in internal/commands. That is the navigation the judge quoted. Take out the package paths and the "create these symbols here" wording. Keep instruction.md identical to environment/problem_statement.md. The hidden tests still compile against those exact reader names. If you only delete the Interface block, the next judge will fail faithfulness. The 8/11 review already said to loosen those tests instead of writing a test-compatibility contract. Drive the suite through LoadFromBuffer, Rewrite, and CalcKeys: corrupt encodings must abort, the rewritten commands and routing groups must match, and the stream must sit on the sentinel after the end-of-value marker. Do not put a new "these helpers must exist" list back into the instruction. The reward hole is still in the embedded grader in tests/test.sh. raw_exit_code is recorded and passed through, but success is only not missing_required and not unexpected. parse_go_test also skips JSON events that have no Test field, so a package-level build or setup failure can leave every required id PASSED while go test exits 1, and the grader still writes reward 1. Require raw_exit_code == 0 before success. Also set solution/solve.sh and tests/test.sh to mode 755 in the zip. They are 644 now. Static already passed, so this is hygiene in the same upload. What already looks good and should stay: TestNegativeCases now rejects a bad opcode on all five readers and a non-zero EOF; the three object types leave only a sentinel byte after LoadFromBuffer; TairHash uses rdbkey vs hkey; TairZset single-score has two members in payload order; the injected Go tests use \*\_verifier_gen_test.go names. instruction.md matches problem_statement.md. HEAD is the declared base. Oracle 3/3 and NOP 0/1 on the platform. I did not rerun Harbor locally. Guidelines: Instruction must-haves (Q9, no file/package navigation) and the fail-closed verifier rule (any nonzero test-process exit forces reward 0).

### Original Directory Name

20260806_080603\_\_tair-opensource_redisshake\_\_657

### Category

implementation

### Difficulty

medium

### Task Tags

1.  redis
2.  tair-modules
3.  rdb-parsing
4.  data-migration
5.  go

### Languages

1.  JSON
2.  Go

### Metadata

schema_version = "1.3" \[metadata\] pass_at_k_opus_4_8 = "2/3" pass_at_k_gpt_5_5 = "2/3" hardening_cycles = "1" agent_hardened = "true" author_name = "anonymous" author_email = "anonymous@snorkel.ai" # --- swe_ultra_requirements §4 field names --- category = "implementation" subcategory = "feature" coding_language = "go" repo_name = "redisshake" repo_license = "" source_pr_url = "[https://github.com/tair-opensource/redisshake/pull/657](https://github.com/tair-opensource/redisshake/pull/657)" base_commit_sha = "037dbe373a51d0580e98ccde23e2e516f3d7de51" model_difficulty = "medium" tags = \["redis", "tair-modules", "rdb-parsing", "data-migration", "go"\] # --- legacy aliases (kept for backward-compatible internal consumers) --- difficulty = "medium" task_type = "implementation" task_subtype = "feature" source = "[https://github.com/tair-opensource/redisshake/pull/657](https://github.com/tair-opensource/redisshake/pull/657)" language = "go" expert_time_estimate_min = 120.0 junior_time_estimate_min = 360.0 pr_created_at = "2023-08-24T12:15:23Z" pr_merged_at = "2023-08-25T06:11:37Z" \[verifier\] timeout_sec = 300.0 network_mode = "no-network" \[agent\] timeout_sec = 1800.0 network_mode = "allowlist" allowed_hosts = \[ "api.portkey.ai", \] \[environment\] build_timeout_sec = 900.0 cpus = 4 memory_mb = 8192 storage_mb = 10240 gpus = 0 network_mode = "public"

## Questions to answer

All form questions are required unless marked as optional.

###

### Submitter Questions

Download Sentinel 2.0 task here (zip file). This is the task you'll inspect and make corrections to (optional)

Download Sentinel 2.0 task here (zip file). This is the task you'll inspect and make corrections to \*

b9857740-b724-4f45-8b77-ee55235d1777_submission.zip

(SEGMENTS) What is your analysis of the Sentinel task you downloaded above? (optional)

- **Fixable** (The task has issues in the instructions, tests, and/or oracle but you can correct all issues)
- **Invalid/Not Fixable** (The task is invalid and/or unfixable, as it requires changes outside of the instructions/tests/oracle, or is invalid due to other reasons)
- **Valid as-is** (The task is valid without changes)
- **Invalid Difficulty** (Difficulty runs have been exhausted and task is auto marked as invalid)

\[For internal use\]

Validity required

Fixable

Invalid

Invalid Difficulty

Valid-as-is

\[Duplicate\] What is your analysis of the Sentinel task you downloaded above? (optional)

Ensure your selection matches the question above

**Fixable** (The task has issues in the instructions, tests, and/or oracle but you can correct all issues)

**Invalid/\*\***Not Fixable\*\* (The task is invalid and/or unfixable, as it requires changes outside of the instructions/tests/oracle, or is invalid due to other reasons)

**Valid-as-is** (The task is valid without changes)

**Invalid Difficulty** (Difficulty runs have been exhausted and task is auto marked as invalid)

Select where the task had issues (check all that apply) (optional)

Instructions

Tests

Oracle Solution

Environment/Dockerfile

What issues did you find with the task? (optional)

Every requirement in the instructions is not properly tested

All test requirements are not properly specified in the instructions

The instructions appear LLM generated

The instructions are overly-prescriptive

The task leaks solution information

The oracle does not implement the solution following the instructions.

Less than 10 fail-to-pass tests in test suite

Describe each issue in detail: (optional)

For each issue category selected, please give details in this format:

1. \[Issue Category 1 - the first category you selected above\]

- Issue Description/explanation - give specific examples in the code when helpful
- Is the issue fixable or not fixable?
- If it IS fixable, how could this be fixed? If not, explain why not.

2. \[Issue Category 2\]...

The human reviewer returned the task for three issues. First, the instruction was too benchmark-facing: it gave implementation-level root-cause detail and a "Test contract" section that said the graded tests compile against the implementation and pinned internal packages, function names, concrete types, method shapes, and dispatch. Second, the negative coverage was incomplete: only ReadModuleUnsigned was tested against a bad opcode, so the other readers and the invalid end-of-value path could skip validation and still pass. Third, object loading was never checked to consume the trailing end-of-value marker, so an implementation could leave it unread and still satisfy every assertion.

If "Fixable" is selected, please re-upload the entire task as a zip file with the corrected instructions, tests, or oracle below, ensuring the task remains valid. (optional)

Use your zip file uploader. Ensure the upload is submitted as <all-task-content>. Do not include runs/ or task/directory

If "Fixable" is selected, please re-upload the entire task as a zip file with the corrected instructions, tests, or oracle below, ensuring the task remains valid. \*

0471bff0-fb42-4ca2-b934-90ff5b49c43a_submission.zip

8/17/2026, 4:37:33 AM

Next section

###

### Difficulty Checks

Helps track how many difficulty runs have completed

Difficulty checks run (optional)

How many times the difficulty check has run on this task since the last review. Maintained by the submission eval; not editable.

Difficulty checks remaining (optional)

Difficulty-check runs left before this task is classified as unfixable on difficulty. Maintained by the submission eval; not editable.

Last counted submission version (optional)

Bookkeeping for the difficulty-run counter: the submission version id the last increment was charged to, which is what makes a platform retry of the evaluation cost no run.

bca0e515-3bca-4f14-bcf2-e574c35fae1c

Last difficulty check result (optional)

What the difficulty check last graded this task. Maintained by the submission eval; not editable. Persisted so the unfixable verdict can be re-applied if it is changed by the EC in the radio button.

hard

Previous section

Next section

###

### Submission Feedback

Static Checks (optional)

Provides instant feedback on the task. These must pass for the task to be eligible for submission.

Check feedback

Prescriptiveness (optional)

Optional LLM-judge check: does the task instruction give away too much about _how_ to solve it (step-by-step procedure, exact files/symbols, solution code) instead of stating the requirements? A failure here does not block submission, but please address the findings before sending the task to review.

Check prescriptiveness

Download difficulty check results (optional)

This field will be populated by the system when your code is run by the system.

Download File

Difficulty Check (optional)

Summary of difficulty check - contains results of agent simulation and stats for each verifier.

Language:

Python

PythonGoSQL (Snowflake)JavaScriptTypeScript

Difficulty Check

WrapExpand

1

2

3

4

5

6

7

Difficulty: PASS HARD

Status: Some tests not passed by any agent run (not blocking; 

require_solvable disabled)

Agent Performance:

  - codex-gpt\-5-5: 25.0% (1/4 runs)

Agentic Judge Quality Report (optional)

Summary of agentic judge quality check - contains results of agent judge evaluation.

Language:

Python

PythonGoSQL (Snowflake)JavaScriptTypeScript

Agentic Judge Quality Report

WrapExpand

1

2

3

4

5

6

\==================================================\============

\==================

                  AGENTIC JUDGE REVIEW: task

\==================================================\============

\==================

Status:    ✅ OK

Reason:    n/a

Oracle Check (optional)

Summary of oracle check - contains results of running the golden solution against the verifiers.

Language:

Python

PythonGoSQL (Snowflake)JavaScriptTypeScript

Oracle Check

WrapExpand

1

2

Oracle: PASS 3/3 runs passed

NOP: PASS 0/1 runs passed (expected 0)

Quality Check (optional)

Summary of quality checks against the task.

Language:

Python

PythonGoSQL (Snowflake)JavaScriptTypeScript

Quality Check

WrapExpand

1

✅ datapoint meets quality bar (15/15 criteria pass)

Previous section

Next section

###

### Additional Submitter Questions

Files Changed - List every file you changed. (optional)

For each file, include: File path, what changed, why you changed it

_You do not need to repeat full validation details here if you already included them in the validation section_

instruction.md and environment/problem_statement.md - removed the Interface section (package paths and the ReadModule\*/TairObject/ParseObject/CalcKeys symbol list); the two files are byte-identical. tests/tests.patch - removed the isolated internal/rdb/structure reader tests (module2_verifier_gen_test.go); rewrote TestNegativeCases to drive corrupt-stream aborts through LoadFromBuffer and ParseObject instead of naming the readers. tests/config.json - fail_to_pass reduced to the 14 public-API tests (dropped the six TestReadModule\* ids). tests/test.sh - embedded grader is now fail-closed: success also requires raw_exit_code == 0.

If you added to the PR in any way, explain how. If you did not modify the PR in any way, write 'NA'. (optional)

Remember you may not change or reduce the scope of the PR, but you may expand on it to add complexity.

NA. I did not add to or modify the PR scope. The oracle (solution/golden.patch) and tests/config.json are unchanged. The changes are a de-prescription rewrite of the instruction, broader negative-case coverage folded into the existing negative test, and end-of-value position assertions folded into the existing object tests. fail_to_pass stays at 20.

Confirm your task meets all the following requirements: (optional)

You must select all for the task to truly be valid

Every requirement in the instructions is properly tested.

All test requirements are properly specified in the instructions.

The instructions do not sound like an LLM generated them.

The instructions are not overly-prescriptive.

The task does not leak solution information.

The oracle implements the solution following the instructions.

The PR was not modified in any way beyond what is allowed by the guidelines.

More than 10 fail-to-pass tests in test suite

What makes this task difficult? (optional)

Describe what makes this task technically challenging. Consider factors such as edge cases, implementation dependencies, requirements that may be overlooked on first reading, or complexity in the test setup.

The task passed the difficulty screen. It requires implementing the annotated RDB module version-2 decoding for three Tair Stack structures, reconstructing the exact EXSET, EXHSET, and EXZADD command streams (including ABS/FLAGS/PXAT arguments and hash-joined multi-score zsets), consuming the end-of-value terminator to stay stream-aligned, and wiring the three new commands into key routing, all asserted behaviorally.

How much time would you estimate a senior engineer familiar with the codebase would take to solve this? (optional)

<10 minutes

10-20 minutes

20-40 minutes

40+ minutes

Previous section

Next section

###

### Final Comment and Handling Time

Comments for Reviewer (optional)

Is there anything else you might want to flag to the reviewers that might help them better understand the task and your thinking on certain decisions you made?

Use this field to explain anything that is not obvious from the changed files. For example, note any assumptions you made, edge cases you considered, reasons you did not change a file, or parts of the task that may require reviewer judgment or a second opinion on.

REV-PUBLIC-API

Revision addressing the three points from the last note.

1. Prescriptiveness (Q9). The Interface section that named the package paths and the exact symbols to create (internal/rdb/structure, the ReadModule\* readers, the TairObject types, ParseObject, CalcKeys, internal/commands) is removed from both instruction.md and environment/problem_statement.md; the two files are byte-identical again. The prose keeps only the observable contract: the module-2 field encoding, the three Tair structures, the emitted EXSET/EXHSET/EXZADD commands, and the routing groups.

2. Faithfulness. The hidden suite no longer compiles against the internal reader names. The isolated internal/rdb/structure reader tests (TestReadModule\*) are removed; the unsigned, string, double, and end-of-value reader behavior is covered through the public path by the TairString/TairHash/TairZset parse-and-rewrite tests, which build module-2 payloads, call the object's LoadFromBuffer, assert the stream is left on the sentinel after the end-of-value marker, and assert the rewritten commands. TestNegativeCases now drives the corrupt-stream aborts (opcode mismatch on an unsigned field, opcode mismatch on a string field, a non-zero end-of-value terminator, and an unsupported module name) through LoadFromBuffer and ParseObject in child processes, so no test references a reader by name. The new type names (TairStringObject and siblings) follow the repo's existing RedisObject naming convention (StringObject, HashObject, ZsetObject), and ParseObject/CalcKeys are existing entry points.

3. Grader fail-closed. The embedded grader now requires a zero test exit: success is gated on not missing_required, not unexpected, and raw_exit_code == 0 (require_zero_exit defaults true). A package-level build or setup failure, whose go-test JSON events carry no Test field and so are invisible to the per-test parser, now zeros the reward through the non-zero exit rather than passing silently.

Validated in the task image: Oracle reward 1 with 14/14 required passing, 0 unexpected; NOP reward 0.

How long (in minutes) did it take you to review the initial task and determine its validity? (optional)

How long (in minutes) did it take you to complete the initial task rewrite only? (optional)

How long (in minutes) did it take you to complete the additional questions on the form? (optional)

How long (in minutes) did it take you to complete all revisions? (optional)

Please **update** this number **every** time you complete a new revision

Previous section

Next section

###

### Reviewer Feedback

What is your verdict for this Submission?

Accept = **Agree** with **Valid / Invalid** selection by **Submitter** and any applied fixes

Needs Revision = Any task that still contains errors

Reject= Use this **ONLY** if you are seeing the "_maximum revision reached_" notification **AND** the submission still needs more revisions

Accept

Needs Revision

Reject

Acknowledgement of Submitter Rebuttal

Before submitting your review, open the rebuttal comments in the left-hand panel and read the submitter's notes in full. Please confirm the following:

I read the submitter's rebuttal and it does not change my review outcome.

I read the submitter's rebuttal and revised my review outcome accordingly.

No rebuttal comments available

What is the overall quality of the submission?

**1\. (Needs Revision) —** The submitter has deviated from the provided source content (e.g., wrong PR, substituted repo code, or otherwise diverging from the source asset), or the submission is low-effort, sloppy, or appears to be spam.

**2\. (Needs Revision) —** The source material is intact but execution has noticeable gaps — untested requirements, instruction/test misalignment, or bundle mismatches — that need meaningful revision.

**3\. (Accept)** — The task is correct and complete; any remaining issues are too minor to warrant sending back for revision.

**4\. (Accept) —** All components (instruction, oracle solution, tests, bundle) are thorough and accurate with no significant issues.

**5\. (Accept) —** Every component is precise, well-reasoned, and clearly written — a reference-quality submission requiring no changes.

Needs Revision | Accept

1

2

3

4

5

How long (in minutes) did it take you to complete this review?

Previous section

SkipSubmit

## Embedded Content
