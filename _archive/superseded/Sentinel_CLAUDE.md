> # DEPRECATED — DO NOT FOLLOW THIS FILE
>
> **Superseded by `CLAUDE.md` at the workspace root, on 2026-08-04.** This was the predecessor
> submitter manual. It sat at the workspace root until then, where it read as a second master
> file, and it is kept here for history only.
>
> **It is specifically wrong on five points**, each of which is recorded with its refutation in
> `learning/LEDGER.md` (rows L12 to L16):
>
> - `tests.patch` must only add new files and must never touch a pre-existing test file. The
>   accepted kvdex 245 bundle patched 44 of them.
> - Set `allow_extra_failures: false` on every task. Only set it when the shipped `config.json`
>   already carries the field and the run executes exactly the graded set.
> - Align the `task.toml` difficulty fields to the Difficulty Check result. `docs/faq.md` and
>   `CLAUDE.md` section 8 both forbid hand-editing that metadata to satisfy a check.
> - Delete the downloaded platform zip after extraction. `CLAUDE.md` keeps it, and it is what the
>   pristine reference gets re-extracted from.
> - `problem_statement.md` lives at the bundle root. The current spec puts the copy at
>   `task/environment/problem_statement.md`.
>
> It also cites two rule files that do not exist in this workspace
> (`.cursor/rules/humanizer-output.mdc`, `.cursor/rules/sentinel-form-answers.mdc`) and a
> directory layout from a different machine (`extracts/`, `Fixable_tasks/`, `Tasks_zip/`,
> `/home/adity/TERMINUS/...`).
>
> **Where its content went.** Section 9, the peer-review lessons from
> `teslamotors/fixed-containers#67`, `foliojs/pdfkit#1002`, `d4vinci/scrapling#14` and
> `datarecce/recce#1399`, is now `learning/peer-review-bounces.md`. Everything else was either
> already in `CLAUDE.md` or is refuted above. Nothing else here needs mining.

# Project Sentinel 2.0 — Claude Code Rules (Submitter Mode)

This workspace — the `sentinel-ultra-submission` folder opened in Cursor (WSL: Ubuntu-22.04) — is used for **Project Sentinel 2.0** task submissions. Unpack platform zips into `extracts/<Original Directory Name>/` (not loose UUID folders at the root). Working edits live under `Fixable_tasks/`. Paths in this file are relative to this workspace root unless noted. See `README.md` for the folder map. Claude acts as the **submitter**: inspect the task, decide the verdict (**Valid as-is / Fixable / Invalid-Not Fixable**), apply corrections when Fixable, and produce every answer the submitter form asks for.

**Companion rule files** (full detail lives there; this file orchestrates):
- `.cursor/rules/sentinel-task-check.mdc` — verdict criteria, the four core principles, per-principle check lists
- `.cursor/rules/sentinel-task-fixing.mdc` — how to execute edits on a Fixable task, allowed Dockerfile fixes, git cleanup
- `.cursor/rules/sentinel-difficulty-scope.mdc` — difficulty handling and PR scope rules
- `.cursor/rules/humanizer-output.mdc` — every user-facing paragraph through Humanizer
- `.cursor/rules/sentinel-form-answers.mdc` — always draft difficulty / senior estimate / reviewer comments / handling times

**Operating constraints:**
- The analysis phase (Steps 1–4) is a static document and logic review with read-only shell/git inspection — no builds, no test runs.
- Local **oracle and NOP** runs: on the **Fixable** path Cursor runs them ITSELF after applying the fixes (Step 5.5), on disposable copies, and no answers are written until both pass. For **Valid as-is** the run is MANDATORY before submitting (the platform's difficulty evals do not re-run Valid as-is tasks, so it is the only check on them) — ask the user to run and report, or run it the same way as Step 5.5 if the user asks.
- Every finding must cite a file path and, where possible, a line number.
- Never invent platform-provided values: the task data block (Step 1.5) and the handling-time numbers must always come from the user.
- **Humanizer (required):** before sending any user-facing prose (form answers, comments, difficulty text, status updates), run it through the Humanizer skill at `~/.claude/skills/humanizer/SKILL.md`. No em/en dashes; strip AI tells; keep technical facts. Code, paths, commands, and diffs stay as-is.
- **Form fields (required every task):** always draft paste-ready answers for (1) What makes this task difficult?, (2) senior-engineer time estimate, (3) Comments for Reviewer, and (4) all handling-time minute fields. Do not wait for the user to ask for each one separately.
- **Fixable Phase 1 delivery order (hard rule):** when showing Fixable findings to the user, always output in this order: (1) verdict, (2) "Select where the task had issues" checkbox list with `[x]`/`[ ]`, (3) "What issues did you find with the task?" checkbox list with `[x]`/`[ ]`, (4) only then the numbered "Issues found" / "Describe each issue in detail" pastebox. Never jump straight to the numbered pastebox.
- **Files Changed format (hard rule):** numbered list only — `1. [path]` then indented `Changed:` / `Why:` lines. Never a markdown table. Match Section 6 Path B template.
- **Peer-review lessons (hard):** before declaring a Fixable task ready, apply Section 9 (Lessons from shipped tasks). Those rules come from real revision notes on fixed-containers, pdfkit, scrapling, and recce.

---

## 1. Submission Workflow

When the user says "review", "inspect", "submit", or starts a new task:

### STEP 1: Scan the workspace (session start, no user input needed)

When a new task session begins, before asking for anything:

1. Scan the workspace root (ignore `.cursor/`, `CLAUDE.md`, `Sentinel_CLAUDE.md`, `README.md`, `sentinel.md`, prompt files, `review_answer.txt`, `submission_answer.txt`, `Fixable_tasks/`, `Tasks_zip/`, `local_runs/`, `downloads/`, `airdawgsSentinel/`)
2. Check whether a task is already extracted under `extracts/<Original Directory Name>/` (look for `task/` and optional `runs/`; legacy `*_harborized/` or UUID folders at the root should be moved into `extracts/` before editing)
3. Check whether `Fixable_tasks/`, `Tasks_zip/`, `extracts/`, and `downloads/` exist — if missing that is fine, they are created on demand
4. If leftovers from a PREVIOUS task are still present (stale root UUID dirs, a stale `submission_answer.txt`), list them and ask whether to clear them — never delete anything without the user's confirmation
5. Report what was found, then move to Step 1.5

### STEP 1.5: Ask the user for the task zip and the platform task data (every task, do not skip)

Ask for BOTH in a single message:

**1. The task zip.** Ask the user to drop the downloaded zip in `downloads/` and unpack into `extracts/<Original Directory Name>/` (or, if Step 1 already found an extract there, to confirm it is the one to work on). Prefer the CH workspace `/home/adity/TERMINUS/Sentinel_Ultra_CH_Task` when the session is CH-only; same `extracts/` + `Fixable_tasks/` layout applies.

**Delete the downloaded zip once extraction is confirmed.** After the platform zip is unpacked and `extracts/<name>/task/` is readable (instruction.md, task.toml, environment/, solution/, tests/ all present), remove the source zip from `downloads/` so only the extract remains. Confirm with the user before deleting, and keep any zip you built in `Tasks_zip/` or `Sentinel_Ultra_CH_Task/` — that rule applies to platform downloads only. The task can be re-downloaded from the platform if needed.

**2. The platform task data.** Ask the user to paste the block shown in the platform for this zip:

```
Original Directory Name:
Category:
Difficulty:
Task Tags:
Languages:
Metadata: (paste the full task.toml shown in the platform, or say "same as file")
```

Do NOT generate any of these values, and do NOT start Step 2 until the task is in the workspace and the data block is pasted. Wait for the user.

### STEP 2: Auto-read the task and cross-check the platform data

1. Find the pristine extract under `extracts/<Original Directory Name>/task/` (or legacy `*_harborized/task/` / root UUID folder — relocate into `extracts/` first)
2. Read ALL of:
   - `extracts/.../task/instruction.md` AND `.../problem_statement.md` — then `diff` them; they must be byte-identical
   - `.../task.toml` (metadata, source PR URL, base_commit_sha, timeouts)
   - `.../solution/solve.sh` and its patch (`golden.patch`, or `init_state.patch` in reverse-diff tasks)
   - `.../tests/test.sh`, `.../tests/tests.patch`, `config.json` (wherever it ships), everything under `.../tests/files/`
   - `.../environment/Dockerfile`
   - `extracts/.../runs/*/*/result.json` when present; `verifier/test-stdout.txt` for ALL failing trials and at least one passing trial
3. **Count the fail-to-pass tests**: enumerate the cases in tests.patch and `grading.fail_to_pass` in config.json, confirm against a passing trial's stdout. **Hard static-check range: `grading.fail_to_pass` length must be 10–20 inclusive** (platform rejects outside that). Prefer the high end of the band when covering a large instruction; never ship 21+. Form checkbox still says "more than 10".
4. **Git hygiene** (read-only, inside `environment/repo`): `git log --oneline -n 20`, `git remote -v`, `git reflog` / `ls .git/logs`, `git rev-parse HEAD` vs task.toml base commit, `du -sh .git`
5. **Stray-artifact sweep**: look for `__pycache__/`, `.DS_Store`, `.venv/`, `.pytest_cache/`, `.idea/`, `.vscode/`, editor swap files, `.ruff_cache/`, `node_modules/` — a single one shipping into the container hard-caps the packaging axis at 1
6. Fetch the source PR from task.toml; summarize its type (bug fix / feature / refactor), module/area, and the behavior it changes
7. Skim `task/environment/repo/` as needed based on instruction scope

**Cross-check the pasted platform data (from Step 1.5) against the extracted task:**
- Original Directory Name ↔ the actual extracted directory name under `extracts/`
- Category ↔ task.toml `category` / `task_type` ↔ the source PR type
- Difficulty ↔ task.toml `difficulty` (the `model_difficulty` field is separate and may differ — flag it only if it clashes badly with the runs/ results)
- Task Tags ↔ task.toml `tags` (3–6 relevant tags)
- Languages ↔ task.toml `coding_language` / `language` ↔ the actual code in `environment/repo/`
- Metadata block ↔ the `task.toml` file on disk — diff them ("same as file" means use the file)
- `pass_at_k_*` fields ↔ actual pass rates in `runs/*/*/result.json`
- `source_pr_url` resolves to the right repo and PR; `base_commit_sha` ↔ `git rev-parse HEAD` (on mismatch HEAD wins — realign task.toml per the git rules)
- Timeouts and resource limits (`[verifier]`, `[agent]`, `[environment]`) plausible against runs/
- Keep `expert_time_estimate_min` / `junior_time_estimate_min` handy — they feed the senior-engineer estimate answer

**On mismatch:** record it as a finding. Fix task.toml where the editing rules allow (base-commit realignment to HEAD, strictly-metadata cleanup); flag anything unresolved in Comments for Reviewer.

### STEP 3: Independent analysis

Run the four core principles (Solvability, Clarity & No Leakage, Verifiability, Authenticity — full lists in sentinel-task-check) plus a scan for the six auto-REMOVE test patterns (Section 4 below). For EVERY issue record: file:line, what is wrong, which Fixable trigger or Not Fixable condition it maps to (Section 3), and the minimal fix. Include the Step 2 cross-check results — platform-vs-file metadata mismatches are findings too.

Do NOT re-judge difficulty from scratch — arriving tasks have already passed the difficulty checks. Difficulty only re-enters if your fixes lower it, in which case the platform evals bounce the task back (see sentinel-difficulty-scope).

### STEP 4: Decide the verdict

Pick exactly one of **Valid as-is / Fixable / Invalid-Not Fixable** using Section 3 criteria.

The analysis question appears TWICE in the platform and both are required — the two answers must be identical. The [For internal use] Validity field must also match, mapped as: Fixable → Fixable, Invalid/Not Fixable → Invalid, Valid as-is → Valid-as-is.

### STEP 5: Apply corrections (Fixable only)

**Set up the working copy FIRST — never edit the original extract:**

1. Check that the folders exist, creating them if missing: `mkdir -p Fixable_tasks Tasks_zip extracts downloads`
2. Copy the task into the working folder, preserving `.git` and every dotfile: `mkdir -p "Fixable_tasks/<Original Directory Name>" && cp -a "extracts/<Original Directory Name>/task/." "Fixable_tasks/<Original Directory Name>/"`
3. ALL edits happen inside `Fixable_tasks/<Original Directory Name>/`. The extract under `extracts/` stays untouched as the pristine reference for diffing. Paths in sentinel-task-fixing (e.g. `environment/repo`) refer to this working copy

Follow sentinel-task-fixing in full. Hard boundaries, always in force:

- NEVER edit tracked source files inside `environment/repo/` — git metadata cleanup is allowed and expected, source edits are not
- Editable: `instruction.md` (+ its exact copy `problem_statement.md`), tests (test.sh, tests.patch, config.json, tests/files/), oracle (solve.sh + patch), the LISTED Dockerfile fixes only, git metadata in the repo
- Oracle edits only in two cases: the oracle does not implement the instruction, or you are expanding PR scope to raise difficulty. Expansion = original PR + additions. Never reduce or replace the PR
- If any fix would require reducing or replacing PR behavior → STOP and reclassify as Invalid/Not Fixable

Work in this order: git hygiene → instruction rewrite → sync problem_statement.md → oracle (if an allowed case applies) → tests (regenerate tests.patch against clean HEAD, register new test ids in `fail_to_pass`) → allowed Dockerfile fixes → Section 9.6 pre-upload mini checklist → pre-submission checklist.

Write tests to clear the Quality Check bar (Section 4): no silent skips, no fail-open, invoke the actual CLI/entry point when one is asked for, pair every existence check with a content assertion, enumerate expected items from the instruction/environment (never from agent output), no overreach beyond stated requirements. Also apply Section 9 (hostile-delete coverage, flexible matchers, distinct f2p contracts, named public APIs).

**Re-zip rule (run only after the fixes, the pre-submission checklist, AND the Step 5.5 oracle/NOP runs all pass):**
1. Prefer the CH upload root for new platform tasks: `/home/adity/TERMINUS/Sentinel_Ultra_CH_Task/<Original Directory Name>.zip`. If the session is entirely inside `sentinel-ultra-submission/` and you need a local copy, also `mkdir -p Tasks_zip` and write there.
2. Zip from INSIDE the working copy so it unpacks DIRECTLY to `instruction.md`, `task.toml`, `environment/`, `solution/`, `tests/` (plus `problem_statement.md`) with no `runs/` and no `task/` wrapper:
   - CH: `cd "…/Sentinel_Ultra_CH_Task/Fixable_tasks/<Original Directory Name>" && zip -rX "/home/adity/TERMINUS/Sentinel_Ultra_CH_Task/<Original Directory Name>.zip" . -x '*.DS_Store' '__MACOSX/*'`
   - Local copy only: `cd "Fixable_tasks/<Original Directory Name>" && zip -rX "../../Tasks_zip/<Original Directory Name>.zip" . -x '*.DS_Store' '__MACOSX/*'`
3. Verify with `unzip -l` on the upload zip: files sit at the top level, no `runs/`, no `task/` prefix, and `environment/repo/.git/` IS present — a zip tool that drops dotfiles ships a broken repo

Keep a change log per file (path, what changed, why) — it feeds the Files Changed answer.

### STEP 5.5: Run the oracle and NOP checks locally (Fixable only, after the fixes)

Cursor runs these ITSELF — do not hand them to the user, and do not write any answers until both pass.

**Setup — never run inside the working copy** (solve.sh and test.sh mutate the tree):
1. `mkdir -p local_runs` at the workspace root (ignored by Step 1, deleted after, never zipped)
2. Make two disposable copies of the fixed task: `cp -a "Fixable_tasks/<Original Directory Name>/." "local_runs/<name>-nop/"` and the same into `local_runs/<name>-oracle/`
3. The shipped scripts may assume container paths (`/workspace/repo`, `/tests`, `/logs/verifier`) — recreate those paths with directories or symlinks pointing into the disposable copy. NEVER edit the scripts just to make them run locally

**Execution environment, in order of preference:**
- Harbor installed → run the NOP and oracle checks through Harbor as usual
- Docker available → `docker build` the task's `environment/Dockerfile`, run both checks inside the container against the disposable copies
- Neither → replicate the Dockerfile's toolchain and dependencies on the host inside the disposable copies; if the environment genuinely cannot be replicated, stop, ask the user to run the checks, and record their reported results

**NOP check (must FAIL):** on the `-nop` copy, run `tests/test.sh` against the UNMODIFIED base repo with no solution applied. Expected: reward `0.0`, non-zero exit, and the fail-to-pass tests actually failing — ideally all of them, and at minimum the regression test that reproduces the original issue. If the suite passes without the fix, the task grades a no-op as success → back to Step 5.

**Oracle check (must PASS):** on the `-oracle` copy, run `solution/solve.sh`, then `tests/test.sh`. Expected: reward `1.0`, zero exit, every fail-to-pass test passing, the pass_to_pass regression guard still green, all inside the `[verifier] timeout_sec`. Any failure → back to Step 5, fix, then re-run BOTH checks from fresh copies.

**If either check FAILS:** go back to Step 5, resolve the issue in the working copy (`Fixable_tasks/<Original Directory Name>/`), then re-run BOTH checks from fresh disposable copies. Loop fix → re-check until the NOP fails as expected and the oracle passes. No zip is created and no answers are written until then.

**Record for the answers:** both rewards, the list of tests that failed in the NOP run, and total runtime vs the verifier timeout — these results go into Comments for Reviewer.

**After BOTH checks pass — strict order, never deviate:**
1. Delete the `local_runs/<name>-*` disposable copies
2. Create the zip: execute the Step 5 re-zip rule to build and verify `Tasks_zip/<Original Directory Name>.zip`
3. Only after the zip exists and is verified → move on to the answers (Steps 6–9)

The Fixable sequence is always: fixes → oracle/NOP checks → resolve failures and re-check → zip → answers. Never zip before both checks pass. Never write answers before the zip exists.

### STEP 6: Draft the form answers

On the Fixable path, do NOT start this step until Step 5.5 has passed (oracle 1.0, NOP 0.0, failures resolved) and the verified zip exists in `Tasks_zip/`. Use Section 2 of this file — it lists every question per path and the basis for answering it.

The Fixable form is answered in TWO phases, because the zip upload field sits BELOW the first set of questions:
- **Phase 1 — before the zip upload:** the analysis verdict (both occurrences + the [Internal] Validity field), then the "Select where the task had issues" checkboxes, then the "What issues did you find" checkboxes, then the numbered issue-details pastebox (never pastebox before checkboxes). Draft these now — they must be entered in the platform BEFORE the fixed zip can be uploaded for Check feedback
- **Phase 2 — after Check feedback and the evals pass, in this order:** Files Changed → PR additions (or "NA") → the post-fix confirmation checklist (all 8) → What makes this task difficult? → senior-engineer estimate → Final Comment and Handling Time (Comments for Reviewer + the four minute fields in Step 8). Draft all of these when Phase 2 is due; Humanizer-clean every paragraph.

### STEP 7: Eval loop (Fixable only)

Before uploading the fixed zip for Check feedback, enter the Phase 1 answers in the platform — the verdict (both occurrences + [Internal] Validity), where-issues, what-issues, and the numbered issue details all sit ABOVE the upload field and must be answered first. Then upload the zip from `Tasks_zip/` as `<all-task-content>`. After upload the platform runs Static Checks, Difficulty Check, Oracle Check, and the Quality Check judge. Iterate per Section 4 until everything passes, then Send to reviewer. Expect that the Phase 2 answers are only completed AFTER the checks pass. Every revision round happens in the working copy under `Fixable_tasks/` and produces a fresh zip into `Tasks_zip/` via the Step 5 re-zip rule, overwriting the previous one.

### STEP 8: Handling times + always-draft Phase 2 prose

Ask the user for real wall-clock totals when unknown (e.g. "about how long for the whole task?"). Never invent a total. Once the user gives an overall time (or per-field times), draft/split the platform fields honestly:

| Field | What it means |
|---|---|
| Review the initial task and determine validity | Analysis / verdict only (Steps 2–4) |
| Initial task rewrite only | Fixable edits before first upload (instruction/tests/oracle/git). Not revision rounds |
| Additional questions on the form | Filling difficulty, senior estimate, checklist, reviewer comments, etc. |
| All revisions | **Post-first-upload** fix rounds only (static/oracle/quality bounces → edit → re-zip → re-upload). Update this number after every revision. Do **not** put the whole-task time here |

If the user gives only a total (e.g. "~2 hours"), propose a split across the four fields that sums to that total and matches what actually happened. Do not pad "all revisions" to force a round number.

**Also draft in the same Step 8 / Phase 2 answer block (every task, Valid as-is and Fixable):**
- What makes this task difficult? (grounded in files/symbols/traps/pass@k)
- Senior engineer estimate (`<10` / `10–20` / `20–40` / `40+`; use patch size + `expert_time_estimate_min`)
- Comments for Reviewer (non-obvious decisions, files not changed, oracle/NOP results, judgment calls)

All of that prose must pass Humanizer before the user pastes it.

### STEP 9: Create submission_answer.txt (final step)

Only after EVERY previous step for the current task is complete — verdict locked, fixes applied in `Fixable_tasks/`, the Step 5.5 oracle and NOP runs both passing, the task zipped into `Tasks_zip/` (Fixable path), platform evals passing (Fixable path), and all handling times received from the user — create `submission_answer.txt` at the workspace root using the matching Section 6 template. It stores the full answer set for the task Cursor is currently working on. If a submission_answer.txt from a previous task still exists, confirm with the user before overwriting it.

---

## 2. The Submitter Form — every question and how to answer it

### Section 1 · Task Metadata
Download the task zip into `downloads/` and unpack into `extracts/<Original Directory Name>/` — Step 1.5 asks the user for this. The platform also displays the task data here — Original Directory Name, Category, Difficulty, Task Tags, Languages, and the Metadata (task.toml) block. Step 1.5 collects this from the user along with the zip itself and Step 2 cross-checks it against the extracted files.

### Section 2 · Task Analysis

**Q: "What is your analysis of the Sentinel task you downloaded above?"**
Appears twice, both required, both answers must match exactly.
- **Fixable** — issues in the instructions, tests, and/or oracle, but all can be corrected
- **Invalid/Not Fixable** — requires changes outside instructions/tests/oracle, or invalid for other reasons
- **Valid as-is** — valid without changes

Basis: the Step 4 verdict against Section 3 criteria.

#### Path A — Valid as-is

**Compliance checklist — must check ALL 7, and each may only be checked after verifying it is actually true against the files:**
1. Every requirement in the instructions is properly tested → verified via the requirement→test mapping
2. All test requirements are properly specified in the instructions → verified via the assertion→instruction mapping (no hidden requirements, no non-derivable names)
3. The instructions do not sound like an LLM generated them → persona check, no robotic phrasing
4. The instructions are not overly-prescriptive → over-prescription sign list is clean
5. The task does not leak solution information → no PR refs, no environment spoilers, no test-gaming
6. The oracle implements the solution following the instructions → solve.sh/patch vs instruction vs source PR
7. Contains more than 10 fail-to-pass tests → actually counted in Step 2

Never check a box that was not verified. If ANY item fails, the verdict is not Valid as-is.

**Local run:** the user must run the oracle and NOP tests locally before submitting — this is the only check on Valid as-is tasks. Remind them and record the outcome. Cursor can run them on request using the Step 5.5 method.

#### Path B — Fixable

The form presents Path B in two phases: everything from the verdict down through the issue details sits ABOVE the zip upload field and must be answered BEFORE uploading (Phase 1); Files Changed onward is completed after the evals pass (Phase 2).

**Phase 1 user-facing order (mandatory):** checkbox lists first, numbered pastebox second. Do not reverse this.

**1. "Select where the task had issues" (check all that apply)** — mark with `[x]` / `[ ]` exactly like the platform UI:

```
Select where the task had issues (check all that apply):
- [ ] Instructions
- [ ] Tests
- [ ] Oracle Solution
- [ ] Environment/Dockerfile
```

Derived from where the recorded findings live (Instructions / Tests / Oracle Solution / Environment-Dockerfile).

**2. "What issues did you find with the task?" (check all that apply)** — mark with `[x]` / `[ ]` immediately after the where-list:

```
What issues did you find with the task?
- [ ] Every requirement in the instructions is not properly tested
- [ ] All test requirements are not properly specified in the instructions
- [ ] The instructions appear LLM generated
- [ ] The instructions are overly-prescriptive
- [ ] The task leaks solution information
- [ ] The oracle does not implement the solution following the instructions.
- [ ] Less than 10 fail-to-pass tests in test suite
```

Mapping hints: (1) coverage gaps → first box; (2) faithfulness / hidden checks / non-derivable names → second; (3)–(5) instruction tone/leakage; (6) golden/solve does not match instruction; (7) Step 2 f2p count under 10.

**3. "Describe each issue in detail" / Issues found pastebox — only AFTER the two checkbox blocks above.** Use exactly this format, one numbered block per finding:

```
1) [Issue Category] — describe the specific issue, with code examples where helpful
— Is this issue fixable or not fixable?
— If fixable, how? If not, why not?
2) [Issue Category 2] — ...
```

Every description cites files and lines. Code examples are welcome here.

**Re-upload (the upload field appears when Fixable is selected, BELOW the questions above):** the zip built into `Tasks_zip/` by the Step 5 re-zip rule (no runs/, no task/ wrapper), submitted as `<all-task-content>`. Upload it only after the Phase 1 answers above are entered in the platform.

**Phase 2 — answer these AFTER Check feedback and once the evals pass:**

**"Files Changed":** every changed file — file path, what changed, why. Comes straight from the Step 5 change log. No need to repeat validation details already given above.

**PR additions:** if the PR scope was expanded in any way, explain how (must be original PR + additions). If the PR was not modified at all, write exactly **"NA"**.

**Post-fix confirmation — the platform requires ALL 8 selected for the task to count as valid. Check each only after verifying it is true post-fix:**
1. Every requirement in the instructions is properly tested
2. All test requirements are properly specified in the instructions
3. The instructions do not sound like an LLM generated them
4. The instructions are not overly-prescriptive
5. The task does not leak solution information
6. The oracle implements the solution following the instructions
7. The PR was not modified in any way beyond what is allowed by the guidelines
8. More than 10 fail-to-pass tests in test suite

**"How long did it take you to complete the initial task rewrite only?"** — minutes, from the user.

#### Path C — Invalid/Not Fixable

**"What issue did you find with the task/components?" (check all that apply):**
- PR scope needs to be changed or reduced
- Environment Issues

**If Environment Issues, the specific issues (check all that apply):**
- Image/Dependency Build Failures
- Oracle timeout
- External-network dependency at build/solve time
- Dirty git history that can't be recovered — RARE: most git issues are fixable per the Git rules, so select this only for genuinely unrecoverable corruption

**"Explain in more detail why this task is unfixable":** describe each issue clearly with evidence. Vague or incomplete descriptions may lead to rejection. For build failures, show why it is a tangled toolchain/version conflict and not a one-package fix. For network dependencies, show why the resource cannot be vendored (e.g. multi-GB model, live service).

#### Difficulty question — Valid as-is AND Fixable ONLY (not asked for Invalid)

**"What makes this task difficult?"** Always draft this without waiting to be asked. Describe the genuine technical challenge: edge cases, implementation dependencies, requirements that may be overlooked on first reading, complexity in the test setup. Good difficulty comes from the problem itself (complex debugging, root-cause analysis, a substantial feature, hard domain/security work), never from vagueness or bolt-ons. Ground every claim in named files, functions, and tests; failing trials' `test-stdout.txt` shows what agents actually got wrong. Humanizer-clean before delivery.

#### Senior engineer estimate — Valid as-is AND Fixable

Always draft. Choices: `<10 minutes` / `10–20 minutes` / `20–40 minutes` / `40+ minutes`. Base on gold-patch size and spread, files/functions touched, subtlety, agent pass rates in `runs/`, and `expert_time_estimate_min` when present (e.g. 150 min → `40+ minutes`).

#### Final Comment and Handling Time — ALL paths

Always draft these together when the form reaches this section:

- **Comments for Reviewer:** assumptions, edge cases, reasons a file was NOT changed, judgment calls, second-opinion asks. Include oracle/NOP results (Step 5.5 for Fixable, user-run for Valid as-is). Humanizer-clean.
- **Minutes — review / determine validity** — from the user (or split from their stated total)
- **Minutes — initial task rewrite only** — Fixable first-pass edits only
- **Minutes — additional questions on the form** — filling the remaining form fields
- **Minutes — all revisions** — post-first-upload revision rounds only; update after each bounce. Not the whole-task total

---

## 3. Verdict criteria (official)

**Valid as-is:** instruction, tests, and oracle all align with each other and with the source PR. No edits required. All 7 compliance items are genuinely true.

**Fixable** — any of:
1. Instructions overly prescriptive or exposing verifier internals
2. Instruction reads as templated/AI-generated
3. Tests miss requirements stated in the instruction
4. Tests grade undescribed behavior or rely on arbitrary (non-derivable) names
5. Fewer fail-to-pass tests than the bar → add tests to reach it (10–20 ideal)
6. Solution leakage (PR URL in instruction, environment spoilers, test-gaming shortcuts)
7. Oracle does not implement the instruction
8. Task too easy → raise difficulty by expanding PR scope
9. A specific, LISTED Dockerfile issue (allowed-fix table in sentinel-task-fixing)
10. A git-hygiene issue in the shipped repo (leaked history, remote, HEAD/base mismatch, reflog, oversized .git)

**Invalid/Not Fixable** — either of:
1. PR scope needs to be changed or reduced — the only path to validity is reducing or replacing the PR scope entirely
2. Environment issues ECs cannot fix: tangled image/dependency build failures, an oracle timeout that bumping cannot resolve, heavy external-network dependency, genuinely unrecoverable git corruption

Rules: a single Not Fixable condition overrides everything. Fixable requires every issue actually fixed — a Fixable verdict with unfixed issues is never allowed. Full detail: sentinel-task-check and sentinel-task-fixing.

---

## 4. Evals and the Quality Check (Fixable path)

### The loop
- **Pre-upload answers first:** the analysis verdict (both occurrences + [Internal] Validity), where-issues, what-issues, and the numbered issue details sit above the upload field — enter them before uploading the zip for Check feedback
- **Static Checks** ("Check feedback"): instant structure + Dockerfile validation. Must pass for the task to be eligible for submission
- After the bundle runs, three read-only summaries populate: **Difficulty Check** (agent simulation + verifier stats), **Oracle Check** (golden solution vs verifiers), **Quality Check** (blocking rubric-panel judge). Download the difficulty results for full logs
- **Send to reviewer** only once difficulty and quality checks pass. Checking it with failing checks always results in revision — if sending with failing checks intentionally, leave detailed reviewer comments explaining why
- In-app checks have a **5-minute runtime limit** — iterate with the box unchecked first
- Protocol when checks fail: read summaries and logs → revise within the editing rules → re-upload and re-run with the box unchecked → repeat until passing → check the box and submit

### The rubric-panel judge
Two independent LLM judges (Claude Opus and GPT-5.5) read the instruction, tests, oracle, and task directory and score 10 axes (1–5) across four rubrics: instruction quality (realism, clarity, self-containedness, prescriptiveness), test quality (test_coverage, test_faithfulness), oracle quality (spec faithfulness, no gaming, robustness/reproducibility), packaging. Where they disagree by 2+ on an axis, a blinded adjudicator settles it.

**Only the two test axes flip the verdict.** Verdict logic:
- **REMOVE** (fails): adjudicated score on either test axis ≤ 2.0, OR either judge scored an axis ≤ 2 with the failure matching one of the six essential patterns below
- **DISCUSS** (fails): any single judge scored either test axis ≤ 2, OR the adjudicated score on either axis is ≤ 3.0
- **OK** (passes): both test axes above 3.0 with no judge at ≤ 2

Practical bar: both judges need a solid 4+ on coverage and faithfulness. One "3 with reservations" bounces the task. Borderline scores round down by design — don't argue with a 3, fix it.

- **Coverage (Instruction → Tests):** every stated requirement has a real enforcing assertion; a broken or stub solution must fail at least one test. Gaps = false positives
- **Faithfulness (Tests → Instruction):** every assertion maps to something stated or reasonably implied. Hidden requirements = false negatives

### Six auto-REMOVE patterns (never ship these)

| Pattern | What it looks like |
|---|---|
| Silent skip | `@pytest.mark.skip`, `skipif`, catching ImportError and setting the module to None — anything letting substantive tests silently not run. A missing dependency must FAIL, not skip |
| No CLI/entry-point invocation | Instruction asks for a CLI/service/script, but test.sh only runs pytest against library internals and never invokes the thing being built |
| Pre-created artifact passes | `path.exists()` / `is_file()` without content checks, so `touch`-ing the filename passes. Pair every existence check with a content/behavior assertion |
| Agent controls coverage | Tests iterate over the agent's own output (loop over its JSON entries), letting the agent shrink the test surface. Enumerate expected items from the instruction/environment |
| Fail-open | `if not output.exists(): return`, `try/except: pass`, assertions gated behind preconditions. A missing or malformed artifact must fail the suite |
| Overreach | Enforcing names, formats, thresholds, paths, or conventions the instruction never states |

### Test-writing checklist
**Do:** map every imperative, named output field, named edge case, and named threshold to at least one assertion (build the bipartite mapping yourself first); test at the instruction's stated strictness ("all rows" means all rows, a named threshold means assert the threshold); include the regression test that reproduces the original failure (fails pre-patch, passes post-patch); keep tests deterministic (fixed seeds, no order/wall-clock/network dependence); commit fixtures and mock data into the verifier image; if a specific output format is required, state it in the instruction so the format assertions are faithful; **hostile-delete check** before zip (Section 9): temporarily remove or stub one stated requirement in a throwaway oracle copy and confirm a f2p fails and reward drops; when the instruction allows "equivalent wording," every accepted phrase must pass the matcher.

**Don't:** assert on source-code text (substring/keyword scans); embed verifier-only constants the agent can't derive (`EXPECTED_COUNT = 47`); compare against hidden golden files never foreshadowed; compute expected values from the agent's own output (circular); require exact error strings, JSON key orderings, whitespace, tolerances, serialization object IDs, or file paths unless the instruction or an existing convention fixes them; pad `fail_to_pass` by cloning the same contract across N sizes/shapes; wrap test bodies in broad try/except — ever; unit-test only a new helper when the PR's point is wiring that helper into Response/CLI/engine paths.

### The advisory axes still matter (reviewers read them)
- **Instruction axes:** reward instructions that read like a real ticket, fully specify success, reference only artifacts that exist in the repo, and state requirements not procedure. Detailed output schemas score well; ordered how-to steps, file localization hints ("the bug is in helpers/queue.py"), and pre-answered edge cases score badly
- **Oracle axes:** implement every requirement with correct logic; no gaming — no hardcoded answers, fabricated tool output, reading test-side ground truth, or fixture-specific shortcuts (e.g. treating `df['Date'].max()` as "today"); reproducible — seeded randomness, no live network calls, timeouts on subprocesses. Litmus test: "if the inputs were reshuffled within the spec, would this oracle still produce the right answer?"
- **Packaging:** one stray dev artifact shipping into the container (`__pycache__/`, `.DS_Store`, `.venv/`, `.pytest_cache/`, `.idea/`, `.vscode/`, swap files, `.ruff_cache/`, `node_modules/`) hard-caps the axis at 1, as does any solution leakage into agent-readable paths

### If the Quality Check fails
Download the report and read the per-axis justifications — they cite exact files, line ranges, and quoted instruction text. For coverage gaps: add or strengthen assertions. For faithfulness defects: either move the requirement into the instruction or relax the assertion. Keep instruction, tests, and oracle in lockstep, re-upload, and re-run with Send to reviewer unchecked until it passes.

---

## 5. Writing Rules for Free-Text Answers

Applies to issue descriptions, the unfixable explanation, "What makes this task difficult", and Comments for Reviewer:

- **Simple 8th-grade English** — basic plain easy to read
- **100% humanized** writing
- **NO LLM artifacts**: no emdashes (—), minimize commas, no colons, no semicolons (code examples are exempt from these style rules)
- Reference specific things verified from the task files (file names, function names, test names, line numbers, patch details)
- Issue descriptions follow the numbered form format exactly and may include code examples
- Difficulty and Comments are one short paragraph each (Comments may be a few short lines when listing several points)
- Never pad with generic filler like "this task tests real-world skills"

---

## 6. submission_answer.txt templates

Created in Step 9 as `submission_answer.txt` at the workspace root — only after every step for the current task is complete and the user has provided the time numbers.

### Path A — Valid as-is

```
Submitter Answers — Valid as-is
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
[x] Contains more than 10 fail-to-pass tests (counted: N)

Local oracle and NOP run: [user-reported result]

What makes this task difficult?
[1 short paragraph]

Senior engineer estimate: [<10 / 10-20 / 20-40 / 40+ minutes]

Comments for Reviewer:
[1 short paragraph]

Time to review and determine validity: [user number] minutes
Total submission time: [user number] minutes
```

### Path B — Fixable

```
Submitter Answers — Fixable
Task: [Original Directory Name from Step 1.5]

What is your analysis of the Sentinel task? (both occurrences)
Fixable
[Internal] Validity: Fixable

Select where the task had issues (check all that apply):
- [x] Instructions   # or [ ] if not
- [x] Tests
- [x] Oracle Solution
- [x] Environment/Dockerfile

What issues did you find with the task?
- [x] Every requirement in the instructions is not properly tested
- [ ] All test requirements are not properly specified in the instructions
- [x] The instructions appear LLM generated
- [x] The instructions are overly-prescriptive
- [ ] The task leaks solution information
- [ ] The oracle does not implement the solution following the instructions.
- [ ] Less than 10 fail-to-pass tests in test suite

Issues found / Describe each issue in detail (pastebox — AFTER the checkboxes above):
1) [Issue Category] — [specific issue, code examples where helpful]
— Is this issue fixable or not fixable? [answer]
— If fixable, how? [answer]
2) ...

--- Phase 2 (completed after the evals pass) ---

Files Changed:
1. [file path]
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
[x] More than 10 fail-to-pass tests (counted: N)

Initial task rewrite time: [user number] minutes

What makes this task difficult?
[1 short paragraph]

Senior engineer estimate: [<10 / 10-20 / 20-40 / 40+ minutes]

Comments for Reviewer:
[1 short paragraph]

Time to review and determine validity: [user number] minutes
Total submission time: [user number] minutes
```

### Path C — Invalid/Not Fixable

```
Submitter Answers — Invalid/Not Fixable
Task: [Original Directory Name from Step 1.5]

What is your analysis of the Sentinel task? (both occurrences)
Invalid/Not Fixable
[Internal] Validity: Invalid

Issues found with the task/components:
[PR scope needs to be changed or reduced / Environment Issues]

Specific environment issues (if applicable):
[Image/Dependency Build Failures / Oracle timeout / External-network dependency / Dirty git history that can't be recovered]

Why this task is unfixable:
1) [issue with evidence from files]
2) ...

Comments for Reviewer:
[1 short paragraph]

Senior engineer estimate: [<10 / 10-20 / 20-40 / 40+ minutes]
Time to review and determine validity: [user number] minutes
Total submission time: [user number] minutes
```

---

## 7. Task Directory Structure

Two CH-related roots exist. Prefer **`Sentinel_Ultra_CH_Task`** for new platform downloads and their upload zips. `sentinel-ultra-submission/` still holds this CLAUDE file, companion rules, and airdawgs work; you may also keep Fixable working copies there when a session started there.

### A. CH upload workspace (`TERMINUS/Sentinel_Ultra_CH_Task/`)

Canonical layout (see that folder's `README.md` and `~/.cursor/rules/sentinel-zip-paths.mdc`):

```
Sentinel_Ultra_CH_Task/
  extracts/<Original Directory Name>/   # Pristine unpack (task/ + optional runs/). Do not edit.
  Fixable_tasks/<Original Directory Name>/  # Working copy — ALL edits here (flat task contents)
  local_runs/                           # Disposable oracle/NOP copies — never zip
  <Original Directory Name>.zip         # Upload zip at folder ROOT (not under Tasks_zip/)
  README.md
```

Re-zip for CH (after Step 5.5 passes):

```bash
cd "/home/adity/TERMINUS/Sentinel_Ultra_CH_Task/Fixable_tasks/<Original Directory Name>"
zip -rX "/home/adity/TERMINUS/Sentinel_Ultra_CH_Task/<Original Directory Name>.zip" . \
  -x '*.DS_Store' '__MACOSX/*'
```

### B. Submission workspace (`sentinel-ultra-submission/`)

Canonical layout (see this folder's `README.md`):

```
sentinel-ultra-submission/           # Workspace root (WSL: Ubuntu-22.04)
  .cursor/rules/                     # Companion rule files
  Sentinel_CLAUDE.md                 # This file
  README.md
  sentinel.md                        # Full guidelines dump
  extracts/<Original Directory Name>/
    task/                            # Pristine flat task contents — do not edit
      instruction.md
      problem_statement.md           # MUST stay byte-identical to instruction.md after sync from working copy
      task.toml
      environment/Dockerfile
      environment/repo/              # NEVER edit tracked source
      solution/                      # solve.sh + golden.patch / init_state.patch
      tests/                         # test.sh, tests.patch, config.json, optional files/
    runs/                            # Optional; NEVER included in the re-upload zip
    .submission_id                   # Original platform submission UUID
  Fixable_tasks/<Original Directory Name>/  # Working copy — ALL edits here (flat)
  Tasks_zip/<Original Directory Name>.zip   # Local re-upload staging
  downloads/                         # Raw platform download zips (was dowloadedzipsCH)
  local_runs/                        # Disposable oracle/NOP copies — never zip
  airdawgsSentinel/                  # airdawgs workstream (uploads → aridawgs_Sentinel_Zips)
  submission_answer.txt              # Final answers (Step 9)
```

Re-upload zip unpacks directly to `instruction.md`, `task.toml`, `environment/`, `solution/`, `tests/` (plus `problem_statement.md`) — no `runs/`, no `task/` wrapper. For CH tasks, place that zip at `Sentinel_Ultra_CH_Task/<Original Directory Name>.zip` even if the working copy lived under this workspace.

---

## 8. Understanding the solution patch

- `golden.patch` is the forward fix: applying it produces the solved state
- `init_state.patch` is a reverse diff: lines added (`+`) = code REMOVED from the solution (broken state); lines removed (`-`) = code ADDED by the solution. solve.sh runs `patch -p1 -R < init_state.patch`
- A missing patch alone is NOT a defect if solve.sh implements the fix

---

## 9. Lessons from shipped tasks (peer review)

Captured from EC submissions that cleared platform evals and sat in `REVIEW_PENDING` (and from peer revision notes on the same set). Source tasks: `teslamotors/fixed-containers#67`, `foliojs/pdfkit#1002`, `d4vinci/scrapling#14`, `datarecce/recce#1399`. Apply these on every future Fixable before zip / Send to reviewer.

### 9.1 Instruction: name the graded API, not the recipe

- **Solvability symbols:** if `tests.patch` imports `ResponseEncoding.get_value`, `form.text(...)`, or a TS `RunType` name, the instruction MUST state that public contract. Vague "standalone utility in the toolbelt" language makes a correct alternate name score 0 on every f2p (scrapling; matched `pass_at_k_* = 0/3`).
- **Over-prescription:** do NOT name exact source paths or private helpers the agent must open (`include/fixed_containers/reflection.hpp`, `for_each_field_entry`, mixin wiring under `lib/mixins/...`). Behavioral ask + public API is enough.
- **Assert / death diagnostics:** if tests regex the abort message, say the wording lands in the **assertion / process abort output**, not a nearby comment. Difficulty judges split on this for fixed-containers.
- **"Flexible wording" is a contract:** if the instruction says any clear equivalent is fine, every accepted phrase must pass the matcher. Peer bounce: agent wrote "field count grows large enough" (faithful to the instruction) but `OverLimitDeathMentionsFieldLimit` still required the literal pair `field` + `limit` within 40 characters. Also make every instruction *example* pass its own compiler-version / theme checks, or remove the example and sync `problem_statement.md`.

### 9.2 Tests: distinct contracts, real coverage, no accidents

- **f2p count 10–20 with distinct behaviors.** Do not pad with `EXPECT_LT(193, 194)` style tautologies or the same death regex reminted across many struct sizes. Reviewers want independent contracts (ceiling constant, live recursive count at the ceiling, hostile `operator&` on count and field_info, over-limit diagnostics, etc.).
- **Hostile-delete gate (mandatory before zip):** in a throwaway copy, undo or stub one *stated* requirement (e.g. skip AcroForm font registration, skip wiring the helper into `Response`). Re-run the verifier. If reward stays `1.0`, that requirement is unenforced. Pdfkit peer note: form-level font registry fell from three fonts to one while all 16 tests still passed because the suite only grepped `/DR` and `/DA` somewhere in the PDF (field dicts already have those). Assert the **form-level** resource map after `doc.end`, not a loose whole-document scrape.
- **Integration, not only the helper:** if the PR's point is "engines stop crashing / Response uses the resolver," at least one f2p must build a `Response` or engine path. A perfect helper that is never wired can still green the suite (scrapling).
- **No serialization accidents:** do not pin PDF object numbers (`10 0 obj`), absolute byte offsets, or creation-order IDs. Test dictionaries, parent/Kids links, action bodies, resource membership, observable values.
- **Never edit pre-existing tests.** Add new files/functions via `tests.patch` only. Dropping JS registry hunks that the Python verifier never runs is still required hygiene (recce).
- **`allow_extra_failures: false`** when the run executes exactly the graded set. Empty `pass_to_pass` with `allow_extra_failures: true` is a free pass for accidental extras.
- **Death / diagnostic matchers:** prefer theme checks (compiler version, unit-test context, field-count failure) over brittle literal pairs when the instruction allows equivalents.

### 9.3 Oracle, git, Dockerfile, task.toml

- **`solve.sh` forward-only and idempotent.** Never use `git apply -R` as a success path; it inverts a correctly applied tree on rerun and fails oracle robustness. Pattern: apply if needed, no-op if already applied, fail on partial state. Mode `0755`.
- **Git hygiene every task:** clean tree at `base_commit_sha`, no origin/remotes/reflog leakage, no mode-only dirt, no working-tree "env workaround" edits that look tracked (recce `pytest-flake8` deletion). Handle env pins in the Dockerfile allowlist, not by dirtying `pyproject.toml` in the shipped repo.
- **Align difficulty fields:** if Difficulty Check returns HARD, do not leave `model_difficulty = "medium"` (or the reverse) without a reason called out in Comments for Reviewer (pdfkit).
- **Timeouts:** bump `[verifier]` / `[agent]` `timeout_sec` when the full suite + image install cannot finish under the shipped limits (recce DuckDB). Record the change in Files Changed.

### 9.4 Difficulty and scope

- **Naming the API can flip FAIL EASY.** After solvability fixes, re-check difficulty. If agents one-shot it, expand **PR-adjacent** scope (same PR intent + additions): extra engine handoff, re-exports, Stage B frontend contracts, stricter outcomes. Never shrink or replace the PR (scrapling → StaticEngine / re-exports; recce → Stage B TS + harder top-K).
- **Good difficulty** comes from multi-mechanism features, easy-to-miss wiring, and hostile edge cases — not from vague instructions or brittle object IDs.

### 9.5 Platform / eval noise

- **Infra exceptions are not task defects.** `ApiRateLimitError` / incomplete difficulty (e.g. 7/8 valid trials) → re-run Check feedback; do not rewrite the task for rate limits (scrapling).
- **Early oracle 0/3** is often packaging or reverse-apply `solve.sh`, not a bad golden patch. Fix hygiene first, then re-run oracle 3× on fresh containers.
- **Peer review can still bounce a green eval.** Packaging and oracle may already be correct while one coverage hole remains (pdfkit fonts; fixed-containers FieldLimit regex). Read revision notes literally; do not re-open settled packaging work when the note says not to.

### 9.6 Pre-upload mini checklist (add to Step 5 / 5.5)

Before building the upload zip:

1. Bipartite map: every instruction requirement ↔ assertion; every assertion ↔ stated or implied requirement.
2. Hostile-delete one stated requirement → reward must drop.
3. f2p length in `10..20` with distinct contracts (no padding).
4. Public symbols tests import are named in the instruction; private paths/helpers are not.
5. Flexible-wording matchers accept every instruction example and the peer-likely paraphrases.
6. `solve.sh` forward-only; script modes `0755`; `allow_extra_failures: false`.
7. Git clean + fsck quiet; `problem_statement.md` byte-identical to `instruction.md`.
8. `task.toml` difficulty fields consistent with Difficulty Check; timeouts plausible.
9. Local NOP `0.0` and oracle `1.0` on disposable copies (Step 5.5).

---

## 10. Common Mistakes (Avoid)

- Skipping the Step 5.5 local oracle and NOP runs on a Fixable task, or writing answers before both pass
- Creating the zip before both Step 5.5 checks pass, or drafting answers before the zip exists in Tasks_zip/
- Uploading the fixed zip to the platform before entering the Phase 1 answers (verdict, where/what issues, issue details)
- Skipping the where/what checkbox lists and jumping straight to the numbered Issues found pastebox when presenting Fixable findings to the user
- Running solve.sh or test.sh inside the working copy instead of the disposable local_runs/ copies (they mutate the tree)
- Editing shipped scripts just to make them run locally — recreate the container paths instead
- Finalizing Valid as-is without a local oracle + NOP run — it's the only check on those tasks
- Checking a compliance/confirmation box that was not actually verified against the files
- Giving different answers to the two occurrences of the analysis question
- Editing tracked source files inside environment/repo/
- Calling a task Fixable without applying every fix, or faking a fix
- Reducing or replacing PR scope (expansion only — and then re-run the difficulty eval)
- Forgetting to sync problem_statement.md after editing instruction.md
- Including runs/ or a task/ wrapper directory in the re-upload zip
- Editing the original extract instead of the working copy in Fixable_tasks/
- Zipping in a way that drops dotfiles — environment/repo/.git must be inside the zip
- Using Fixable_tasks/ or Tasks_zip/ without checking they exist first (always mkdir -p)
- Creating submission_answer.txt before every step for the task is complete
- Leaving stray dev artifacts (__pycache__, .DS_Store, .venv, node_modules, etc.) in the zip — hard-caps packaging at 1
- Shipping any of the six auto-REMOVE test patterns (silent skip, no CLI invocation, existence-only checks, agent-controlled coverage, fail-open, overreach)
- Not registering added tests in config.json fail_to_pass, or leaving tests.patch cut against the wrong base
- Answering the difficulty question for an Invalid/Not Fixable task (it is only asked for Valid as-is and Fixable)
- Selecting "Dirty git history that can't be recovered" for ordinary git issues — most are fixable
- Vague issue descriptions or unfixable explanations (these get submissions rejected)
- Skipping the Step 1.5 ask for the task zip and platform data, or generating those values instead of waiting for the user
- Leaving the downloaded platform zip in the workspace after extraction, or deleting a zip from Tasks_zip/ by mistake
- Not cross-checking platform Category, Difficulty, Tags, and Languages against task.toml and the actual repo code
- Inventing any of the handling-time numbers instead of asking the user
- Arguing with a borderline Quality Check score instead of fixing the cited defect
- Checking Send to reviewer while checks are failing without detailed explanatory comments
- Writing LLM-sounding output in the free-text answers
- Skipping Section 9 lessons: no hostile-delete coverage check before zip
- Claiming "flexible diagnostic wording" while matchers still require brittle literal tokens
- Padding fail_to_pass with tautologies or the same check across N sizes instead of distinct contracts
- Leaving public API names the tests import out of the instruction (or the reverse: shipping path/function cookbooks)
- Testing only a new helper while the PR requires wiring it into Response / engines / CLI
- Pinning PDF object numbers, creation-order IDs, or other serialization accidents
- Shipping `solve.sh` that succeeds via `git apply -R` / reverse apply
- Leaving `allow_extra_failures: true` with an empty or weak pass_to_pass when only graded tests run
- Leaving `model_difficulty` mismatched to the Difficulty Check result without calling it out
- Rewriting the task for platform infra noise (rate limits, incomplete trials) instead of re-running evals
- Re-opening settled packaging work when peer notes only ask for a test/instruction tweak