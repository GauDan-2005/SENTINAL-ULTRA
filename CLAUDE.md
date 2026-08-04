# Project Sentinel 2.0 - Claude Code Rules (Submitter Mode)

This workspace - the `SENTINAL-ULTRA` folder opened in Cursor (WSL: Ubuntu-22.04, ext4) - is used for **Project Sentinel 2.0** task submissions. Every path in this file is relative to the workspace root. **Nothing is ever extracted into the workspace root.** Each task lives in one folder under `tasks/<Original Directory Name>/`: the downloaded zip goes in `download/`, its inner `task/` directory is extracted to `download/original/` as the pristine never-edited reference, and every edit happens in `work/`. Claude acts as the **submitter**: inspect the task, decide the verdict (**Valid as-is / Fixable / Invalid-Not Fixable**), apply corrections when Fixable, and produce every answer the submitter form asks for.

**Peer review is out of scope for this workspace.** This file, the companion rules and the templates cover the submitter side only. The official reviewer form lives at `docs/tasking-guide.md:345-459` and is there for reference - to write submissions that survive it, not to fill it in. If review is ever assigned, add a `reviews/<task>/` sibling to `tasks/` with the same folder discipline, a Section 6 Path D `review_answer.txt` template built from `docs/tasking-guide.md:401-459`, and a fourth rule plus skill twin pair.

**Companion rules** (full detail lives there; this file orchestrates). Each one exists twice - as a Cursor rule and as a Claude Code skill with identical content. Cursor loads the `.mdc`, Claude Code loads the `SKILL.md`. **Any edit to one must be made to its twin in the same pass.**

| Rules                                                                                             | Cursor                                        | Claude Code skill           |
| ------------------------------------------------------------------------------------------------- | --------------------------------------------- | --------------------------- |
| Verdict criteria, the four core principles, per-principle check lists                             | `.cursor/rules/sentinel-task-check.mdc`       | `sentinel-task-check`       |
| How to execute edits on a Fixable task, allowed Dockerfile fixes, task.toml, git cleanup, zipping | `.cursor/rules/sentinel-task-fixing.mdc`      | `sentinel-task-fixing`      |
| Difficulty handling and PR scope rules                                                            | `.cursor/rules/sentinel-difficulty-scope.mdc` | `sentinel-difficulty-scope` |

Two further pairs are tools rather than rules and so are not in the table above, but they follow the same twinning discipline: `humanizer` (mandated by Step 9 and Step 10) and `quality-rehearsal`, each existing as both `.cursor/rules/<name>.mdc` and `.claude/skills/<name>/SKILL.md`. **Any edit to one must be made to its twin in the same pass** applies to these too.

**Official documentation - `docs/`** is a local export of the Sentinel Ultra Hub (https://snorkel-ai.github.io/Sentinel_Ultra_Hub/), exported 2026-07-31. It is the source of truth. When this file or a companion rule file disagrees with `docs/`, `docs/` wins - follow it and flag the drift to the user. **`docs/` stays a clean verbatim export: material from any source other than a Hub re-export - Slack, another workspace, a platform report, your own measurement - goes into `CLAUDE.md`, `learning/` or the skills, never into `docs/`.** The single sanctioned exception is repairing a defect in the export itself (a truncated table, a mangled character), and that repair must be annotated in place with its date.

- `docs/guidelines.md` - verdicts, the four core principles, PR scope and difficulty, what you can edit (instructions, tests, oracle, environment, git)
- `docs/tasking-guide.md` - Before You Upload checklist, detailed tasking steps, the zip command, submitter and reviewer form questions, Run Evals, the Quality Check judge
- `docs/harbor-framework.md` - task structure and the full `task.toml` field and limit reference
- `docs/faq.md` - troubleshooting (broken environments, agent errors, network_mode, agent timeouts, PR scope vs added complexity)
- `docs/glossary.md`, `docs/whats-new.md`, `docs/changelog.md` - terms, latest changes, and dated history of every guideline change
- `docs/ALL_DOCUMENTATION.md` - every tab in one file

**Learning log - `learning/`** holds verified findings from real platform runs on this workspace: what a check actually rejected, what an environment actually did, and where that differs from the wording in `docs/` or this file. **Read all of it at session start (Step 1) and apply it without being asked.** `docs/` remains the source of truth for policy and judgment; `learning/` is the source of truth for observed platform and machine behaviour, because each note is backed by a build log or a container run. Keep it current - see the write-back rule in Step 1.

- `learning/README.md` - index and the format every note follows
- `learning/static-checks.md` - the 20 checks run on upload, and the hard 10–20 `fail_to_pass` range
- `learning/prescriptiveness-check.md` - the instruction-scoring build phase, its two rules, and the test-derivability trap when fixing it
- `learning/tests-patch-vs-agent-edits.md` - `tests.patch` breaking after agent edits; the failure that invalidates most difficulty trials
- `learning/stale-test-reports.md` - verifiers reading build-time test results; why a NOP reward of 0 is not enough
- `learning/local-runs.md` - running the oracle and NOP locally on this machine, and the filesystem pitfalls
- `learning/verify-in-the-image.md` - confirming inside the built image what the bundle only claims on disk
- `learning/unreachable-git-blobs.md` - solution and hidden-test blobs surviving in `.git` after a clean-looking gc, plus the broken `refs/remotes/origin/HEAD` that no other check catches
- `learning/verifier-fail-open.md` - graders that award reward 1.0 while the test command exited nonzero. The stock harness ships this defect
- `learning/solve-sh-idempotency.md` - a reverse-apply fallback that undoes the solution on the second oracle run
- `learning/quality-check-criteria.md` - the Quality Check's 15 must-have criteria, and the fact that instruction leakage and navigation block on their own
- `learning/source-pr-cross-check.md` - a coverage finding that describes the upstream PR rather than your tests, and the GitHub API paging trap
- `learning/dirty-repo-and-symlinks.md` - a shipped repo already dirty, lost mode bits and flattened symlinks, and the `zip -y` flag
- `learning/raising-difficulty-on-a-wrapper-task.md` - a task measured easy where the instruction cannot be trimmed because the API names are the deliverable
- `learning/diagnosing-platform-only-failures.md` - **how to work a failure that reproduces on the platform and nowhere else.** The two-strikes rule, why a local reproduction proves sufficiency and never necessity, and the evidence hierarchy. Three rounds on kvdex 245 went to fixing real defects that were not the defect
- `learning/accepted-bundle-reference.md` - the one bundle that cleared every gate, with measured numbers, separating what acceptance validated from what merely was not caught

**Operating constraints:**

- The analysis phase (Steps 1–4) is a static document and logic review with read-only shell/git inspection - no builds, no test runs.
- **No command of any kind runs inside `download/original/` after the extract - git included.** `git status`, `git fsck` and `git apply --check` all rewrite `.git/index`, so running them there mutates the tree this file calls pristine. Step 2 makes the working copy first and inspects `tasks/<name>/work/environment/repo` instead. The pristine extract is the diff target and nothing else.
- **Stop if unsure.** When a fix depends on a fact you have not opened a file to confirm, stop and ask rather than editing. Cite the path and the line you read for every claim you make. Never implement a fix from memory of how a similar task behaved - the last task's environment is not evidence about this one. An unverified fact is a question for the user, not an assumption to ship.
- The local **verification battery** (NOP, oracle 3/3, hostile delete): on the **Fixable** path Cursor runs it ITSELF after applying the fixes (Step 5.5), on disposable extracts of the built zip, and no answers are written until all three pass. For **Valid as-is** the oracle and NOP run is MANDATORY before submitting (the platform's difficulty evals do not re-run Valid as-is tasks, so it is the only check on them) - ask the user to run and report, or run it the same way as Step 5.5 if the user asks. (The Hub calls the Fixable-path local run optional since the platform evals run it; this workspace is deliberately stricter - it saves an eval round trip.)
- Every finding must cite a file path and, where possible, a line number.
- Never invent platform-provided values: the task data block (Step 1.5) and the handling-time numbers must always come from the user.

---

## 1. Submission Workflow

When the user says "review", "inspect", "submit", or starts a new task:

### STEP 1: Read `learning/`, then scan the workspace (session start, no user input needed)

When a new task session begins, before asking for anything:

1. **Read every file in `learning/` - this is mandatory and comes first.** Start with `learning/README.md`, then read each note it indexes. These are verified findings from real platform runs, recording where the actual behaviour differs from what `docs/` and this file say. Apply them for the rest of the session without being asked. If a note contradicts this file on a matter of fact about what the platform does, the note wins and the drift gets flagged to the user
2. **Read `INDEX.md`** at the workspace root. It is the cross-task register - one row per task with its verdict, status and submission id. It tells you what is already in flight before you touch anything
3. Scan `tasks/` for the per-task folders. Each one holds everything for a single task: `task.md`, `task_details.md`, `download/`, `work/`, `upload/`, `answers/`. Ignore everything else at the root by name: the directories `.claude/`, `.cursor/`, `.git/`, `_archive/`, `bin/`, `chat_transcripts/`, `comparison-report/`, `docs/`, `learning/`, and the files `AGENTS.md`, `CLAUDE.md`, `INDEX.md`, `README.md`, `facts.yml`, `prompts.md`, `.gitignore`
4. Reconcile `INDEX.md` against what is actually on disk. A folder under `tasks/` with no row, or a row whose status no longer matches the files, is drift - report it rather than silently fixing it
5. **Throughput rule - a hard stop, not a note.** At most **two** tasks may sit in `pending-revision` at once, or the platform blocks a new claim. Count it, do not eyeball it, and anchor the pattern to the table rows or the count comes back wrong - a bare `grep -c 'pending-revision'` also matches the status-vocabulary table and the surrounding prose. Use the form `INDEX.md` itself documents: `grep -c '^| \[.*| pending-revision |' INDEX.md`. `INDEX.md` also carries a `pending-revision: N of 2` line under its `## Active` heading, updated by the same action that changes any row's status. If the count is already 2, **refuse to start a new claim** and say which task has to be sent to reviewer or parked first. If the count is 3 or more, that is drift and it gets resolved with the user before anything else happens
6. Report what was found, then write the applicable `learning/` notes into the task's `task.md` before Step 3 begins - a chat message does not satisfy this. The section is mandatory and takes the shape below, one line per note, naming the specific thing the note predicts for THIS task and the command that will confirm or refute it. Then move to Step 1.5

```
## learning/ notes applied
| Note | What it predicts here | Command that settles it |
|---|---|---|
| unreachable-git-blobs.md | golden and patched-test blobs dangling in environment/repo/.git | git fsck --unreachable --no-progress |
| verifier-fail-open.md | stock test.sh writes reward 1.0 without reading raw_exit_code | grep -n raw_exit_code tests/test.sh |
| solve-sh-idempotency.md | reverse-apply fallback inverts the tree on the second oracle run | run solve.sh three times in one container |
```

**Writing back to `learning/`.** When something in this workspace costs real time and would cost it again - a platform check that rejected a bundle, an environment quirk, a rule whose real behaviour differs from its documented wording - add or update a note in `learning/` and index it in `learning/README.md`. Record what happened with the exact error text, why it happened, the rule to apply next time, and the date and task it came from. Do not log anything already covered by `docs/` or this file; log the gap between them and reality.

### STEP 1.5: Ask the user for the task zip and the platform task data (every task, do not skip)

Ask for BOTH in a single message:

**1. The task zip.** Ask the user to drop the downloaded zip into `tasks/<Original Directory Name>/download/` and to extract its inner `task/` directory to `tasks/<Original Directory Name>/download/original/`, so that `original/` holds `instruction.md`, `task.toml`, `environment/`, `solution/` and `tests/` at its top level. Nothing goes to the workspace root. If Step 1 already found an extracted task in that shape, ask the user to confirm it is the one to work on.

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

0. **Make the working copy before running anything.** Every command in this step that touches git or a patch runs against the working copy, never the pristine extract. Create the folders if they are missing and copy the extract across, preserving `.git` and every dotfile:

   ```bash
   mkdir -p "tasks/<Original Directory Name>"/{download,work,upload,answers}
   cp -a "tasks/<Original Directory Name>/download/original/." "tasks/<Original Directory Name>/work/"
   ```

   `download/original/` is now frozen for the rest of the task. Reads are fine; commands are not. The inspection target from here on is `tasks/<Original Directory Name>/work/environment/repo`

1. Locate the extracted task. It is `tasks/<Original Directory Name>/download/original/` with `instruction.md`, `task.toml`, `environment/`, `solution/` and `tests/` at its top level. Older bundles wrap everything in a `*_harborized/` directory, sometimes nested inside a `<submission_id>/` folder - that is the legacy shape, and the fix is to re-extract the inner `task/` into `download/original/` so the layout matches, not to work inside the wrapper
2. Read ALL of, relative to `download/original/`:
   - `instruction.md` AND `problem_statement.md` - then `diff` them; they must be byte-identical. The current spec puts the copy at `environment/problem_statement.md`; older bundles keep it at the top level. Diff whichever one ships, and if both exist all three files must match
   - `task.toml` (schema_version, `[environment]` / `[agent]` / `[verifier]` / `[metadata]`, source URL, base commit, timeouts, network_mode per block - see Section 8 for the field limits)
   - `solution/solve.sh` and its patch (`golden.patch`). If it ships as `solution.patch` or `init_state.patch`, both are dead names for the same file - record it, read the diff direction rather than trusting the name (Section 9), and rename it to `golden.patch` on the Fixable path
   - `tests/test.sh`, `tests/tests.patch`, `config.json` (wherever it ships). Note that `tests/` accepts **only** `config.json`, `grade.py`, `test.sh` and `tests.patch` - a `tests/files/` directory is rejected by the static checker even though older layout docs list it, so if you find one it is a finding (`learning/static-checks.md`)
   - `environment/Dockerfile`
   - `runs/*/*/result.json`; `verifier/test-stdout.txt` for ALL failing trials and at least one passing trial
3. **Count the fail-to-pass tests**: enumerate the cases in tests.patch and `grading.fail_to_pass` in config.json, confirm against a passing trial's stdout. **The platform's static check enforces a hard 10–20 range and fails the build outside it** (verified - see `learning/static-checks.md`). The guidelines wording ("at least 10, ideally 10–20") and the form checkbox ("more than 10") both read as floors, but 21+ is rejected. Target **11–20**, and if a rewrite pushes the count over 20, regroup cases as sub-steps under fewer top-level tests rather than deleting assertions
4. **Git hygiene** (inside `tasks/<Original Directory Name>/work/environment/repo`, never inside `download/original/` - these commands write `.git/index`): `git log --oneline -n 20`, `git remote -v`, `git reflog` / `ls .git/logs`, `git rev-parse HEAD` vs task.toml base commit, `git rev-list --all --not HEAD`, `git config --local --get-regexp '^filter\.'`, `git status --porcelain`, `du -sh .git`, and `git fsck --unreachable --no-progress`. Unreachable objects are not covered by any of the other lines: a repo with no reflog, no stray refs and a clean tree can still hold dangling blobs of the golden file and the patched test file, readable with `git cat-file -p`. `docs/guidelines.md` prescribes the remedy (`reflog expire --all` + `gc --prune=now`) but never the check, and `docs/tasking-guide.md` step 5 requires that no solution material be readable from agent paths - `.git` is an agent path. See `learning/unreachable-git-blobs.md`
5. **tests.patch applies to the base commit**: `git apply --check ../../tests/tests.patch` inside `tasks/<Original Directory Name>/work/environment/repo` at HEAD. A patch cut against a different base fails every trial and shows up as "0/8 valid trials - infra/harness failure" in the difficulty check
6. **Pre-existing test files untouched IN THE SHIPPED TREE - which is not the same as untouched by `tests.patch`.** Two separate rules, and collapsing them into one is how a healthy bundle gets judged Fixable over a non-defect:
   - **The shipped tree is byte-identical to base.** Every test file under `environment/repo` matches its content at the base commit. Check it mechanically: `git -C tasks/<name>/work/environment/repo status --porcelain` prints nothing, and `git -C ... diff --stat HEAD -- <test paths>` is empty. This is the rule `docs/tasking-guide.md:39` is really about, and the harness enforces it
   - **`tests.patch` MAY edit pre-existing test files.** It is applied at verify time, on top of that clean tree, and editing an existing test file is a normal thing for it to do. Measured on the one platform-ACCEPTED bundle: kvdex 245's `tests.patch` has 45 `diff --git` headers and 1 `new file mode`, so 44 pre-existing test files are edited by the patch and the bundle was accepted. `docs/tasking-guide.md:39` reads "new functions or new files only", which is good advice for keeping collisions down and is not what the harness checks. Flag the drift, do not rewrite a working patch into a create-only shape to satisfy the narrow reading
   - Giving graded tests their own file with a distinctive prefix stays the **recommended practice** for collision safety (Section 10.3), not a rule the patch is judged against
7. **Stray-artifact sweep** (in `tasks/<Original Directory Name>/work/`): look for `__pycache__/`, `*.pyc`, `.DS_Store`, `.venv/`, `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `.idea/`, `.vscode/`, editor swap files, `*.orig`, `*.bak`, `node_modules/`, `.pnpm-store/`, `.gradle/`, `target/`, and stray build lock files (`*.lock` written by a build tool, e.g. `.gradle/8.0/fileHashes/fileHashes.lock`) - a single one shipping into the container hard-caps the packaging axis at 1. Intentional dotfiles (`.gitignore`, `.dockerignore`, `.gitattributes`, `.gitkeep`, `.github/`) are fine.

   **Protect tracked paths before you delete anything.** Run `git ls-files` at the base commit first and keep every path it lists, including ones that look like artifacts - `.claude/`, `.vscode/`, `.python-version`, a committed lockfile. Deleting a tracked file is editing tracked source inside `environment/repo/`, which is a hard boundary (Step 5). If a swept artifact turns out to be tracked, do not delete it: exclude it from the image with `.dockerignore` or an `rm -rf` in the Dockerfile after the `COPY`, and say so in Comments for Reviewer. `grep -n 'rm -rf' environment/Dockerfile` should show that removal sitting after the COPY, or the exclusion never happened
8. Fetch the source PR from task.toml (`[metadata] source`, or `source_pr_url` on older tasks); summarize its type (bug fix / feature / refactor), module/area, and the behavior it changes. **Fetch the file list through the API and page it** - `curl "https://api.github.com/repos/<owner>/<repo>/pulls/<n>/files?per_page=100&page=N"`, repeating until a page returns under 100. The `.diff` URL redirects to a host that may not resolve, and a 100-row page 1 of a 198-file PR produced a confidently wrong finding on kvdex 245. Keep the full list: Step 2 item 9, the difficulty scope rules and any judge finding you cross-check all depend on it being complete. See `learning/source-pr-cross-check.md`
9. **Diff the golden patch's file list against the PR's file list.** List the paths `solution/golden.patch` touches and compare them to the files the source PR actually changed. `docs/guidelines.md` requires the patch to contain "only what's needed to resolve the task" with no drive-by edits, and `docs/tasking-guide.md` step 2 requires no unrelated scope. A golden patch spanning far more files than the PR is a polluted oracle and a Fixable finding; files the PR changed but golden omits (docs, changelogs) are the same finding in the other direction. Non-test files only - test changes belong in `tests.patch`
10. **Read the grader in `tests/test.sh` for fail-open behavior.** Trace how the reward is decided. If it parses stdout for test names, check whether it also gates on the test command's exit status. `docs/guidelines.md` states the invariant plainly - "the exit code should match the reward it writes" - and a parse-only grader breaks it: a compile failure, timeout, crash or partial run can leave the expected lines in the log and still award `1.0`. See `learning/verifier-fail-open.md`
11. Skim `environment/repo/` as needed based on instruction scope

**Cross-check the pasted platform data (from Step 1.5) against the extracted task:**

- Original Directory Name ↔ the actual extracted directory name
- Category ↔ task.toml `category` / `task_type` ↔ the source PR type
- Difficulty ↔ task.toml `difficulty` (the `model_difficulty` field is separate and may differ - flag it only if it clashes badly with the runs/ results)
- Task Tags ↔ task.toml `tags` (3–6 relevant tags)
- Languages ↔ task.toml `coding_language` / `language` ↔ the actual code in `environment/repo/`
- Metadata block ↔ the `task.toml` file on disk - diff them ("same as file" means use the file)
- Source URL resolves to the right repo and PR; base commit ↔ `git rev-parse HEAD` (on mismatch HEAD wins - realign task.toml per the git rules)
- `[metadata] repo_license` holds a real SPDX id and matches the licence file in `environment/repo`; `repo_name`, `base_commit_sha` and `source_pr_url` agree with the repo and the PR. These four are undocumented in `docs/harbor-framework.md` and populated in every bundle measured here (Section 8)
- Every `task.toml` limit in Section 8 holds: cpus, memory_mb, storage_mb, gpus = 0, build/agent/verifier timeouts, and `network_mode` present in all three blocks with the right value. Missing or stripped `network_mode` fields are a finding
- Legacy fields (`pass_at_k_*`, `expert_time_estimate_min`, `junior_time_estimate_min`, `tags`, `coding_language`, `model_difficulty`) were dropped from the current schema but still appear on older tasks. Cross-check them when present - `pass_at_k_*` against the actual pass rates in `runs/*/*/result.json`, `expert_time_estimate_min` feeds the senior-engineer estimate answer - and never add them to a task that lacks them

**On mismatch:** record it as a finding. Fix task.toml where the editing rules allow (base-commit realignment to HEAD, strictly-metadata cleanup); flag anything unresolved in Comments for Reviewer.

### STEP 3: Independent analysis

Run the four core principles (Solvability, Clarity & No Leakage, Verifiability, Authenticity - full lists in sentinel-task-check) plus a scan for the six auto-REMOVE test patterns (Section 4 below). For EVERY issue record: file:line, what is wrong, which Fixable trigger or Not Fixable condition it maps to (Section 3), and the minimal fix. Include the Step 2 cross-check results - platform-vs-file metadata mismatches are findings too.

Do NOT re-judge difficulty from scratch - arriving tasks have already passed the difficulty checks. Difficulty only re-enters if your fixes lower it, in which case the platform evals bounce the task back (see sentinel-difficulty-scope). For reference, the bar is a pass@k threshold: a frontier model solves a Medium task in at most 4 of 8 attempts and a Hard task in at most 2 of 8 - compare it against the trial outcomes in `runs/` when a difficulty claim needs grounding.

### STEP 4: Decide the verdict

Pick exactly one of **Valid as-is / Fixable / Invalid-Not Fixable** using Section 3 criteria.

The analysis question appears TWICE in the platform and both are required - the two answers must be identical. The [For internal use] Validity field must also match, mapped as: Fixable → Fixable, Invalid/Not Fixable → Invalid, Valid as-is → Valid-as-is.

### STEP 5: Apply corrections (Fixable only)

**The working copy already exists - never edit the original extract:**

1. `tasks/<Original Directory Name>/{download,work,upload,answers}` were created in Step 2 item 0
2. `work/` was populated from `download/original/` in Step 2 item 0 and Steps 2 to 4 ran against it. **Do NOT re-make the copy here** - that would discard nothing on a clean pass and silently discard your inspection state on a resumed one. If `work/` is genuinely empty or missing, go back and run Step 2 item 0 rather than copying ad hoc
3. ALL edits happen inside `tasks/<Original Directory Name>/work/`. `download/original/` stays untouched as the pristine reference. At any point, `diff -rq download/original work -x '.git'` from the task folder lists exactly the files you changed - run it before zipping and confirm every line is a change you meant to make. Paths in sentinel-task-fixing (e.g. `environment/repo`) refer to the working copy
   - **Never run the project's build tool inside `download/original/`, and never inside `work/` either.** Gradle, Maven, npm and cargo all write caches and lock files into the checkout (`.gradle/`, `target/`, `node_modules/`). Those paths are gitignored, so `git status` stays clean and nothing warns you. Two things then break quietly: `diff -rq download/original work` starts reporting files you never touched, and the next `zip -rXy .` ships the cache into the container, which hard-caps the packaging axis at 1. Verified 2026-08-02, where a Gradle run left `.gradle/8.0/fileHashes/fileHashes.lock` in both trees. Builds and test runs belong in disposable scratchpad copies (Step 5.5). If a cache does appear, delete it before the stray-artifact sweep and re-run the sweep
4. Add or update the task's row in `INDEX.md` and its `task.md` as the verdict and status change

Follow sentinel-task-fixing in full. Hard boundaries, always in force:

- NEVER edit tracked source files inside `environment/repo/` - git metadata cleanup is allowed and expected, source edits are not
- NEVER leave a pre-existing test file modified **in the shipped tree** - the harness checks that every test file under `environment/repo` is byte-identical to its content at the base commit. `git -C environment/repo status --porcelain` prints nothing before the zip. Editing one of those files in place is the boundary violation
- `tests/tests.patch` is a different thing and it MAY edit pre-existing test files. It is applied at verify time on top of the clean tree, so an added function inside an existing test file is legitimate: kvdex 245, the one accepted bundle, edits 44 pre-existing test files that way. Prefer a separate prefixed file for the graded tests (Section 10.3) because it removes the agent-collision surface, not because in-place edits are banned
- Editable: `instruction.md` (+ its exact copy `problem_statement.md`), tests (test.sh, tests.patch, config.json - those three and `grade.py` are the ONLY entries `tests/` may contain, verified by a rejected upload), oracle (solve.sh + patch), the LISTED Dockerfile fixes only, task.toml metadata and limits, git metadata in the repo
- Oracle edits only in two cases: the oracle does not implement the instruction, or you are expanding PR scope to raise difficulty. Expansion = original PR + additions. Never reduce or replace the PR
- If any fix would require reducing or replacing PR behavior → STOP and reclassify as Invalid/Not Fixable

Work in this order: git hygiene → instruction rewrite → sync problem_statement.md → oracle (if an allowed case applies) → tests (regenerate tests.patch against clean HEAD, register new test ids in `fail_to_pass`) → allowed Dockerfile fixes → task.toml sanity (Section 8) → pre-upload checklist.

Write tests to clear the Quality Check bar (Section 4): no silent skips, no fail-open, invoke the actual CLI/entry point when one is asked for, pair every existence check with a content assertion, enumerate expected items from the instruction/environment (never from agent output), no overreach beyond stated requirements. Then apply Section 10 - the defects that pass every eval and still come back from the reviewer.

**Regenerating `tests.patch`** when it does not apply: from `environment/repo` at the base commit, confirm the target test files are in their original state (they must NOT already contain the new f2p tests - the patch is what adds them), apply the test additions by hand, then `git add -A && git diff --cached -- <test paths> > ../../tests/tests.patch` and `git checkout .` to restore the repo to base. Re-verify with `git apply --check`. Common traps: the repo copy already includes the new tests (the patch re-adds them and conflicts), or the patch touches a non-test file such as `CMakeLists.txt` that has since changed.

**Pre-upload checklist - these are the Phase A gates. Run all of it on `work/` before the zip is built and before the Step 5.5 battery runs:**

1. `tests.patch` applies cleanly to `environment/repo` at the base commit (`git apply --check`)
2. The shipped tree is clean: `git -C environment/repo status --porcelain` prints nothing and no test file differs from base. `tests.patch` editing a pre-existing test file is fine and expected (Step 2 item 6); a pre-existing test file left edited **in the tree** is the defect
3. `docker build environment/` succeeds and is reproducible. The build MAY use the network; run `apt-get update` before installs, use packages that exist in the base image distro, pin the base image to a concrete tag, and bake test dependencies into the image instead of fetching them at test time. Run time is what stays restricted - the agent reaches only the model gateway and the verifier is airgapped. Four **reproducibility** checks on top of the base-image tag, none of them a network restriction:
   - `grep -nE 'apt-get +(dist-)?upgrade|apk upgrade|yum upgrade' environment/Dockerfile` is empty. An upgrade step re-resolves the whole package set on whatever day the image is built, so the difficulty run and the oracle run can get different toolchains
   - every bare `pip install <pkg>` carries `==`, and the npm, gem and cargo equivalents carry an explicit version. `grep -nE 'pip3? install' environment/Dockerfile` then read each line
   - every `pip install -e <dir>` target exists inside `environment/repo`. A path that does not resolve fails at build time on the platform and passes locally when a stale directory happens to be lying around
   - any `git+https://` requirement is pinned to a tag or a sha, never a bare branch. Fetching from git at build time is allowed; fetching a moving branch is what makes the build unreproducible
4. Git hygiene clean per the checklist in sentinel-task-fixing (HEAD == base commit, no refs past HEAD, no remotes, no `filter.*`, clean tree, no reflog, `.git` under 100 MB) **and `git fsck --unreachable --no-progress` prints nothing**
5. Stray-artifact sweep is empty, no solution material readable from agent paths, `problem_statement.md` re-copied from `instruction.md`, and `solution/solution.patch` renamed to `golden.patch` if the bundle shipped that name
6. `task.toml` sanity per Section 8 - limits, `gpus = 0`, `network_mode` in all three blocks, accurate `category` / `difficulty_explanation` / source URL, `[environment] os` present, and `[metadata] repo_license` / `repo_name` / `base_commit_sha` / `source_pr_url` populated and correct. Remove `network_mode = "none"` from `docker_compose.yaml` if present
7. **Script modes.** `tests/test.sh` and `solution/solve.sh` are executable (`0755`). A `0644` verifier entrypoint is the "non-executable scripts" row of the allowed-fix table in `docs/guidelines.md` and fails at run time, not at build time, so nothing local catches it for you. Check the mode in the extracted zip, not only the working copy
8. **Grader fails closed.** `tests/test.sh` writes reward `1.0` only when the test command also exited zero (Section 10). A parse-only grader is the `Fail-open` auto-REMOVE pattern wearing a different hat
9. **No source-shape grading.** `grep -rnE 'getsource|getsourcelines|inspect\.|readFileSync|read_text\(|Files\.readString|open\(.*\.(py|ts|java|rs|kt)' tests/` turns up nothing that reads a source file to assert on its text, and no assertion greps for a private helper name. Pass condition: the graded tests call the public API and assert on behaviour. A test that scans source text passes for a solution that writes the right words and fails one that writes correct different code, which is the `Don't` at the top of the Section 4 test-writing checklist and a judge finding when it ships
10. **Instruction and tests name the same things.** For every public identifier `instruction.md` names as a deliverable, confirm it appears in both `tests/tests.patch` and `solution/golden.patch`. Pass condition: no name in the instruction that nothing grades, and no graded name the instruction never states. A name that is in the tests and not the instruction is a `test_faithfulness` finding; one that is in the instruction and not the patch is the `Task Instruction Sufficiency: FAIL` signature from the other side (Section 4)
11. **No unguarded bashisms.** `grep -n '\[\[\|BASH_SOURCE\|\${.*\[@\]}\|<(' solution/solve.sh tests/test.sh`. Pass condition: every hit sits in a script whose shebang is `#!/usr/bin/env bash` or `#!/bin/bash`, or which re-execs itself under bash. A `#!/bin/sh` script full of `[[` runs fine on this machine, where `/bin/sh` is bash or a bash-compatible shell, and dies inside an image whose `/bin/sh` is dash or ash. That failure surfaces as `DownloadVerifierDirError` or a missing verifier output, never as a clear message
12. **Hostile-delete gate** - not here. It needs a built image and a passing oracle, so it runs as the third check of the Step 5.5 Phase B battery against the extracted zip. See Step 5.5
13. Full local dry run - that is Step 5.5 Phase B

**Re-zip rule (run only after the fixes and the Phase A pre-upload checklist pass - the zip is what the Step 5.5 Phase B battery then runs against):**

1. **Re-do git hygiene FIRST, immediately before zipping.** Checklist item 4 above is not enough on its own: regenerating `tests.patch` and running the local checks both use git inside `environment/repo`, and `logallrefupdates = true` recreates `.git/logs` (plus `ORIG_HEAD` / `FETCH_HEAD`) every time. A reflog fails the platform's `git: no reflog` static check and leaks your git identity. Run the full scrub, including the stash - a stash ref keeps its blobs reachable, so `gc` will never prune them and `--prune=now` alone leaves them behind:

   ```bash
   git stash clear && rm -f .git/refs/stash
   git reflog expire --expire=now --expire-unreachable=now --all
   git gc --prune=now
   rm -rf .git/logs .git/ORIG_HEAD .git/FETCH_HEAD .git/refs/remotes
   ```

   Then re-confirm both patches still apply. `.git` should contain exactly `config description HEAD hooks index info objects packed-refs refs`. **Then verify, do not assume:** `git fsck --unreachable --no-progress` must print nothing. If it lists blobs, read a couple with `git cat-file -p <sha>` - regenerating `tests.patch` and running the local checks both write objects that the gc above may leave dangling, and those blobs are the golden file and the patched test file. Re-run the scrub until fsck is silent
2. Check `tasks/<Original Directory Name>/upload/` exists - create it if missing
3. Zip from INSIDE the working copy so it unpacks DIRECTLY to `instruction.md`, `task.toml`, `environment/`, `solution/`, `tests/` with no `runs/` and no `task/` wrapper:
   `cd "tasks/<Original Directory Name>/work" && zip -rXy "../upload/<Original Directory Name>.zip" . -x '*.DS_Store' '__MACOSX/*'`
4. Use `zip -rXy` - never `zip -rD` and never a GUI compress tool. Each flag does a different job, and it is easy to state this wrongly (`docs/tasking-guide.md:99` and `:104` are the source of truth): `-r` recurses and writes directory entries **by default**, so it is the ABSENCE of `-D` that keeps the empty `.git/refs/` that `git gc` leaves behind - add `-D` and the repo unpacks broken on the platform even though the local copy works. `-X` strips extra file attributes (resource forks, UID/GID) for a portable archive. `-y` stores symlinks as symlinks; without it zip follows them and flattens the link into a copy of its target, which is how libcrux lost all 7 of its repo symlinks
5. Verify with `unzip -l "tasks/<Original Directory Name>/upload/<Original Directory Name>.zip"`: files sit at the top level, no `runs/`, no `task/` prefix, `environment/repo/.git/` IS present, and `unzip -l ... | grep 'refs/'` lists the empty git directories. **Then assert the symlink count**, because a flattened symlink looks perfectly healthy in a listing:
   `unzip -Z "<zip>" | grep -c '^l'` must equal `find work -type l | wc -l`
6. **Run the static-check simulation from `learning/static-checks.md` against the EXTRACTED ZIP, not the working copy.** Unpack the zip to a scratch directory and check all 20 items there. Both times a static check failed on a real upload, the working copy looked clean and the zip did not
7. **Write the upload-ledger row in `task.md` before the zip goes anywhere.** Every zip that is uploaded gets a row, written after step 6 verifies it, in the table Step 7 requires:

   ```
   ## Upload ledger
   | # | Date | Zip sha256 | Size | Checks returned | Outcome |
   |---|---|---|---|---|---|
   | 1 | 2026-08-04 | a1b2c3… | 4.1 MB | static, difficulty, oracle, quality | quality DISCUSS coverage_gap |
   ```

   The zip is overwritten every round by design, so the hash is the only record of what the platform actually evaluated. Without it you end up proving which bundle was graded by quoting instruction phrasing back at a report

Keep a change log per file (path, what changed, why) - it feeds the Files Changed answer.

### STEP 5.5: The verification battery (Fixable only, after the fixes)

Cursor runs these ITSELF - do not hand them to the user, and do not write any answers until the whole battery passes.

**The battery runs in two phases, and the order is the point.**

- **Phase A - cheap gates on `work/`.** All 13 items of the pre-upload checklist above: patch applies, shipped tree clean, image builds and is pinned, git hygiene clean and `fsck` silent, stray sweep empty, task.toml sane, script modes `0755`, grader fails closed, and the three mechanical greps (no source-shape grading, instruction and tests naming the same things, no unguarded bashisms). Then build the zip with the Step 5 re-zip rule
- **Phase B - the three required runs, against the EXTRACTED ZIP.** Extract the zip to the scratchpad, build the image from that extract, and run NOP, oracle and hostile-delete there

**Why the zip and not `work/`.** The artifact that ships has to be the artifact that was measured. A battery run on `work/` measures a tree that no longer exists once `zip` has followed a symlink, dropped a directory entry or lost a mode bit - the libcrux task burned a whole re-verification session on exactly that gap. **Any edit after Phase B voids Phase B**: a fresh zip and a fresh battery, no exceptions and no "it was only the instruction".

**Phase B setup - never run inside the working copy** (solve.sh and test.sh mutate the tree):

1. A run directory in the session scratchpad (ignored by Step 1, deleted after, never zipped)
2. Extract the built zip three times, once per run: `unzip -q "tasks/<Original Directory Name>/upload/<Original Directory Name>.zip" -d "<scratchpad>/run-nop"`, and the same into `<scratchpad>/run-oracle` and `<scratchpad>/run-hostile`. Copying from `work/` instead is the defect this phase exists to catch
3. Build the image from the extracted `environment/Dockerfile`, not from `work/environment/`
4. The shipped scripts may assume container paths (`/workspace/repo`, `/tests`, `/logs/verifier`) - recreate those paths with directories or symlinks pointing into the disposable copy. NEVER edit the scripts just to make them run locally

**Execution environment, in order of preference:**

- Harbor installed → run the checks through Harbor as usual
- Docker available → `docker build` the extracted `environment/Dockerfile`, run the checks inside the container against the disposable copies
- Neither → replicate the Dockerfile's toolchain and dependencies on the host inside the disposable copies; if the environment genuinely cannot be replicated, stop, ask the user to run the checks, and record their reported results

**Run 1 - NOP check (must FAIL):** on the `run-nop` copy, run `tests/test.sh` against the UNMODIFIED base repo with no solution applied. Expected: reward `0.0`, non-zero exit, and the fail-to-pass tests actually failing - ideally all of them, and at minimum the regression test that reproduces the original issue. If the suite passes without the fix, the task grades a no-op as success → back to Step 5.

**A NOP reward of 0 is necessary, never sufficient - confirm it is 0 for the right reason.** Three separate mechanisms produce a textbook-looking 0 while grading nothing: stale result files baked in at build time (`learning/stale-test-reports.md`), a collection abort, and a module whose test sources do not compile at base so the runner never reaches the rest of the graded set. In all three, every f2p id lands in `missing_required_tests` whether it would have passed or not, and `set(required) - set(missing)` reads as a clean all-clear. So **split the graded ids by whether their module compiles at base and actually run the ones that do**: revert the uncompilable test sources to base, run the remainder, and read per-test outcomes rather than the reward. Anything that PASSES there is not a fail-to-pass test - move it to `pass_to_pass` and re-count against the 10–20 range. This has caught a real one (`learning/verify-in-the-image.md`), and it is most likely to bite on ids whose assertions you relaxed while fixing something else.

**When the toolchain cannot run a per-file subset, audit the symbols instead.** The split above assumes you can run part of the graded set. Gradle with Kotlin gives you no such handle: the module compiles as a unit, so reverting the uncompilable sources and running the remainder is not available, and AltBeacon 1177 had to improvise a substitute mid-round. The named fallback, so nobody improvises it again:

- Read every f2p test body and list the symbols it touches that do not exist at the base commit - the new class, the new method, the new constructor argument
- Prove each one absent with a grep against the base tree, and record the grep and its empty output. `git -C environment/repo grep -n '<symbol>' $(git -C environment/repo rev-parse HEAD)` printing nothing is the evidence
- A test whose body only touches symbols that DO exist at base is not a fail-to-pass test, whatever the reward says. Move it to `pass_to_pass` and re-count
- Write in `task.md` and in Comments for Reviewer that genuineness rests on the symbol audit rather than on an executed subset, and name the symbols. Do not report an audit as if it were a run

Both paths are acceptable. Silence about which one you used is not, because a reader cannot tell an audited zero from an executed one, and the whole point of the rule is that a zero proves nothing on its own.

**Run 2 - Oracle check (must PASS, three times):** on the `run-oracle` copy, run `solution/solve.sh`, then `tests/test.sh`. Expected: reward `1.0`, zero exit, every fail-to-pass test passing, the pass_to_pass regression guard still green, all inside the `[verifier] timeout_sec`.

**Run `solve.sh` three times in one container, because the platform does.** The Oracle Check runs the golden solution three times and the pass bar is **3/3** (Section 4). Runs two and three execute against the already-patched tree, which is where a non-idempotent script inverts its own fix. Record all three rewards for Comments for Reviewer. A pass on run one followed by a failure on run two is exactly the `1/3` signature - do not ship it and call it green.

**Run 3 - Hostile-delete gate (reward must DROP to 0.0):** on the `run-hostile` copy, apply the oracle, then stub or delete one requirement the instruction actually states, and re-run the verifier. The Quality Check coverage axis is scored on this exact property - "a broken or stub solution must fail at least one test" (`docs/tasking-guide.md`). Pick the requirement you are least sure is tested, not the easiest one.

**Name the test that caught it.** The record has to read "stubbed X, `<test id>` failed, reward 0.0", not "reward dropped". A reward that drops for some other reason (a compile break introduced by the stub) proves nothing about coverage, and the test id is what separates the two.

**If any of the three FAILS:** go back to Step 5, resolve the issue in the working copy (`tasks/<Original Directory Name>/work/`), rebuild the zip with the re-zip rule, and re-run the WHOLE battery from fresh extracts. Loop fix → re-zip → re-check until the NOP fails as expected, the oracle passes 3/3, and the hostile run drops to `0.0` naming its test. No answers are written until then.

**Record for the answers:** all three oracle rewards, the NOP reward and the list of tests that failed in it, the hostile-delete test id, and total runtime vs the verifier timeout - these go into Comments for Reviewer.

**After the battery passes - strict order, never deviate:**

1. Delete the `<scratchpad>/run-*` disposable copies
2. Confirm the zip in `tasks/<Original Directory Name>/upload/` is still the exact one the battery ran against - nothing in `work/` may have been touched since it was built. `find tasks/<name>/work -newer tasks/<name>/upload/<name>.zip` must print nothing
3. Only then → move on to the answers (Steps 6–9)

The Fixable sequence is always: fixes → Phase A gates → zip → Phase B battery → resolve failures, re-zip, re-run the battery → answers. Never run the battery on `work/`. Never write answers before the battery passes against the zip that will actually be uploaded.

### STEP 6: Draft the form answers

On the Fixable path, do NOT start this step until the whole Step 5.5 battery has passed against the built zip (oracle 3/3 at 1.0, NOP 0.0, hostile-delete 0.0 with its test id named, failures resolved) and that zip is still the newest thing in `tasks/<name>/upload/`. Use Section 2 of this file - it lists every question per path and the basis for answering it.

The Fixable form is answered in TWO phases, because the zip upload field sits BELOW the first set of questions:

- **Phase 1 - before the zip upload:** the analysis verdict (both occurrences + the [Internal] Validity field), "Select where the task had issues", "What issues did you find", and the numbered issue details. Draft these now - they must be entered in the platform BEFORE the fixed zip can be uploaded for Check feedback
- **Phase 2 - after Check feedback and the evals pass, in this order:** Files Changed → PR additions (or "NA") → the post-fix confirmation checklist (all 8) → the rewrite-only time → the difficulty question → the senior-engineer estimate → then the Final Comment and Handling Time section: Comments for Reviewer, review time, total submission time (Steps 7–9 cover when these happen)

**Delivery order when showing Phase 1 to the user (hard rule).** Output in the same order the platform asks: (1) the verdict, (2) the "Select where the task had issues" list rendered with `[x]` / `[ ]` for all four options, (3) the "What issues did you find" list rendered with `[x]` / `[ ]` for all seven options, (4) only then the numbered issue-details pastebox. That is the documented form order in `docs/tasking-guide.md`. Never jump straight to the pastebox - the user is filling checkboxes first and has to scroll back.

**Always draft, never wait to be asked.** Every task, both Valid as-is and Fixable, produce paste-ready text for the difficulty question, the senior-engineer estimate, and Comments for Reviewer alongside the rest of the answers. The only things to wait on are the handling-time numbers, which must come from the user (Step 8).

**Files Changed is a numbered list**, one entry per file with indented `Changed:` and `Why:` lines, matching the Section 6 Path B template. Not a markdown table - the platform field is plain text and a table pastes as pipes.

### STEP 7: Eval loop (Fixable only)

Before uploading the fixed zip for Check feedback, enter the Phase 1 answers in the platform - the verdict (both occurrences + [Internal] Validity), where-issues, what-issues, and the numbered issue details all sit ABOVE the upload field and must be answered first. Then write the upload-ledger row in `task.md` (Step 5 re-zip item 7) and upload the zip from `tasks/<name>/upload/` as `<all-task-content>`. After upload the platform runs Static Checks, Difficulty Check, Oracle Check, and the Quality Check judge. Iterate per Section 4 until the Send gate below is fully green. Expect that the Phase 2 answers are only completed AFTER the checks pass. Every revision round happens in the working copy under `tasks/<name>/work/` and produces a fresh zip into `tasks/<name>/upload/` via the Step 5 re-zip rule, overwriting the previous one - which is why each round needs its own ledger row. Once `submission_answer.txt` exists, every round through this loop also updates it - that is Step 10.

**The Send-to-reviewer gate.** Read this list before checking the box. Any single unmet condition means Send = No, and the reason gets recorded on the `Send to reviewer:` line of the answers file:

1. **Static Checks green.** The build stops at the first failing phase, so a green static check only means the next phase could run - it is a precondition, not a pass
2. **Difficulty Check green with ZERO invalid trials.** An `invalid trial` / `harness failure` count above zero voids the round: you learn nothing about difficulty, nothing about the quality panel's test axes and nothing about agent behaviour, so a "passing" difficulty summary alongside invalid trials is not a pass
3. **Oracle Check 3/3.** Anything below 3/3 blocks. On the Fixable path it is a task defect, not flake - see Section 4 for what 0/3 versus 1/3 tells you
4. **Quality Check pass.** Both test axes above 3.0 with no judge at ≤ 2, AND zero failing must-have criteria - a `criterion: Instructions` failure blocks on its own even with clean test axes
5. **Task Instruction Sufficiency is not FAIL.** See Section 4 troubleshooting for the 0%-agents / 100%-oracle signature
6. **The Step 5.5 battery passed against the CURRENT zip.** NOP 0.0, oracle 3/3 at 1.0, hostile-delete 0.0 naming its test id, all run on an extract of the zip now sitting in `tasks/<name>/upload/`
7. **The zip is newer than every file in `work/`.** `find tasks/<name>/work -newer tasks/<name>/upload/<name>.zip` prints nothing. If it prints anything, an edit landed after the battery and both the zip and the battery are void
8. **The upload ledger in `task.md` has a row for this zip**, with its sha256 and the checks it returned

Sending with a failing condition is allowed only deliberately, and then Comments for Reviewer must say which condition failed, why you sent anyway, and what you tried. Checking the box with unexplained failing checks always comes back as revision.

### STEP 8: Ask for the handling times

Ask the user for the real numbers - never generate them. The live form shows **five** time
lines: four independently asked fields, plus the total, which is computed from three of them
(verified on a real submission, 2026-08-01 - `docs/tasking-guide.md` documents fewer). The
Section 6 templates print all five for that reason:

| # | Field | Asked or computed | What it covers |
|---|---|---|---|
| 1 | Minutes to review the initial task and determine its validity | asked | Steps 2–4 - the analysis and the verdict, nothing else. All paths |
| 2 | Minutes to complete the initial task rewrite only | asked | The Step 5 edits made before the FIRST upload - instruction, tests, oracle, git, Dockerfile. Fixable path only. Not revision rounds |
| 3 | Minutes to complete the additional questions on the form | asked | Filling in the rest of the form - difficulty, senior estimate, checklists, Comments for Reviewer |
| 4 | Minutes to complete all revisions | asked | **Post-first-upload rounds only** - a failed check or a reviewer bounce, then edit, re-zip, re-upload. Update this number every revision round |
| 5 | Total submission time | computed | Fields 1 + 2 + 3. Not an independent number to invent |

**Total submission time is fields 1 + 2 + 3 only. Field 4 is tracked separately.**
**This is an INFERENCE, not verified platform behaviour, and `docs/` reads the other way.**
`docs/tasking-guide.md:229` - the source of truth per the top of this file - describes the
total as "How long did it take you to complete this entire submission? (in minutes - if the
task is sent back for revision, adjust this number to include the additional time)". That
wording says to fold revision time IN. The exclusion here is inferred from the existence of a
separate fourth field on the live form, which the docs export predates. It has not been
confirmed against the live helper text.

Resolve it rather than carrying it: ask the user to screenshot the live total field's helper
text, then record what it says with its observation date in a `learning/` note. If the live
text matches `docs/tasking-guide.md:229`, reverse this rule and re-total every answers file.
Until that is done, apply the exclusion and say in Comments for Reviewer if the number could
be read either way.

Sanity hints for splitting a stated total - **hints, not gates. A figure outside them is not
an error**:

- **Total submission time (1 + 2 + 3): 180 to 240 minutes** is the usual shape of a
  first pass. The one platform-ACCEPTED bundle shipped **260** minutes
  (`_archive/20260719_045042__oliver-oloughlin_kvdex__245/answers/submission_answer.txt:190`),
  so the band describes typical work rather than a permitted range.
- **All revisions (4)** starts at zero and grows **50 to 70 minutes per round** after the
  first. The accepted bundle shipped **195** minutes of revision time across its rounds
  (same file, line 193) and libcrux is at 240. Do not clamp a real cumulative figure into a
  60 to 120 window - read it off the task's handling-time ledger (Step 10) instead.

Sanity-check before writing anything: the total has to equal fields 1 + 2 + 3 exactly, and it
must exceed the review and rewrite components on its own. If the user gives only an overall
number, propose a split across the three fields that matches what actually happened rather
than padding one to hit a round total, and say which field you put the slack in. Never invent
any of the four asked numbers.

### STEP 9: Create submission_answer.txt (end of the first pass, not the end of the task)

Only after EVERY previous step for the current task is complete - verdict locked, fixes applied in `tasks/<name>/work/`, the task zipped into `tasks/<name>/upload/` (Fixable path), the whole Step 5.5 battery passing against that zip, platform evals passing (Fixable path), and all handling times received from the user - create `tasks/<Original Directory Name>/answers/submission_answer.txt` using the matching Section 6 template. It stores the full answer set for the task Cursor is currently working on. If a submission_answer.txt from a previous task still exists, confirm with the user before overwriting it.

This closes the first submission, not the task. Most tasks come back at least once - see Step 10, which keeps this file in step with every revision.

**Humanize the file as the last action, after it is written.** Draft the answers, write the file, then run the `humanizer` skill over every free-text answer in it - the issue descriptions, the difficulty paragraph, the unfixable explanation, and Comments for Reviewer - and save the humanized text back. Do this even when the same paragraphs were already humanized in chat, because they get edited, merged and re-ordered on the way into the file, and the pass that matters is the one over the text the user actually pastes. The file is not finished until that pass has run.

What the pass must not change: file paths, function and test names, commands, diffs, code examples, the checkbox lines, and the handling-time numbers. Those stay verbatim. What it removes is the LLM tells listed in Section 5 - em dashes, colons and semicolons in prose, comma pile-ups, filler, and any phrasing that does not read like a person wrote it. Re-check the Section 5 rules after the pass, since humanizing can reintroduce a wrapped line or a dash.

**Write the file unwrapped, and keep it unwrapped after humanizing.** Every paragraph is one single line, however long it runs - no hard wrap at 80 columns or any other width, and no editor reflow. The file exists to be copied out of and pasted into platform text fields, and a newline inserted mid-sentence travels with the paste. Section 5 lists the only places a line break is allowed. Check the file after writing it: if any prose line ends without the sentence ending, it was wrapped and needs rejoining.

### STEP 10: Revision rounds (expect at least one - this is the normal path)

A task is rarely done in one pass. It comes back either from a failing platform check during the Step 7 eval loop, or from the reviewing EC with **Needs Revision** and a list of findings after Send to reviewer. Both are the same job: address the feedback, re-validate, re-zip, and bring the answers back in line with what the task now is.

Run this loop every time feedback arrives, however small it looks.

**0. Confirm WHICH task the feedback belongs to, from the feedback itself.** Do not trust the path or task name in the message that carries it. Feedback gets pasted with the previous task's path attached, and the `__` in a directory name renders as markdown bold, so `20260728_153118__jqno_equalsverifier__1166` arrives as `20260728_153118**jqno_equalsverifier**1166` and is easy to mistake for a different task. The report always identifies itself: judge justifications cite `task.toml` line numbers with the source PR, repo paths under `environment/repo/`, and file names from the bundle. Match those against the task folders before touching anything, and say plainly which task you concluded it is. Working the wrong folder costs a whole round.

**0b. Check the report is FRESH before acting on it.** Confirming the right task is not enough - two rounds have been spent on stale reports for the right task, including an entire "round 2 feedback" that turned out to be the round 0 report re-pasted (libcrux `task.md`, caught only by four independent tells). Check the report against the bundle currently in `work/` on four axes and record the result at the top of the round block in `task.md`:

| Axis | What to compare |
|---|---|
| Test ids | Every test id the report names exists in the current `tests/config.json` |
| Line numbers | Line numbers it cites fall inside the current `tests.patch` and `config.json` lengths |
| Commands | The command list it describes matches the current `execution.commands` |
| Instruction text | Any instruction phrase it quotes is still present in the current `instruction.md` |

Any mismatch means the report predates your last upload. Ask for the current one before touching a file. A stale report sends you to fix something you already fixed, and the round returns unchanged.

**1. Capture the feedback before touching anything.**

**First action on any failed check: ask the submitter for the downloadable results artifact**, in the same message that captures the feedback. The difficulty-check download carries the platform-side verifier stdout, which sits above local reproduction in the evidence hierarchy (`learning/diagnosing-platform-only-failures.md`) - a local reproduction only ever proves a condition is sufficient, while the artifact says what actually happened. AltBeacon spent three rounds and roughly 35 local oracle runs before concluding that asking for the artifact was the next step. Record in `task.md` whether it was supplied, so the next round knows whether that avenue is open or already closed.

Paste the feedback verbatim into the task's `task.md` under a dated revision heading, alongside which round it is and where it came from (which check, or the reviewer). Verbatim matters - reviewer notes are the defect list you will be graded against, and paraphrasing loses the specific ask. Set the task's status to `pending-revision` in `INDEX.md`, update the `pending-revision: N of 2` count, and stop if that count would exceed two.

**Elided reports are not evidence.** When a pasted report contains an elision marker (`… 172 lines omitted …`, a truncation notice) or shows an axis with no quoted justification, mark those axes **UNVERIFIED** in `task.md` and ask the submitter for the untruncated report. Do not ship a change whose only justification is an unverified axis. A score you remember from reading a previous session's report counts as unverified too - memory of a number is not a re-readable citation, and the blocking axes are exactly the ones worth being wrong about.

**One round counter per task, shared by all three files.** The counter increments **once per platform feedback received** - not per fix, not per re-upload, not per part of a bundled report. No part-numbered sub-headings (`round 2-part-3`); if new feedback arrives, that is the next round, and if it does not, it is the same round. The highest round heading in `task.md`, the round number in the answers `Comments for Reviewer` opener, and the number in the `INDEX.md` status cell must all read the same.

**2. Turn the feedback into a numbered item list, then work it.** One line per finding, each with the file it touches and the fix. Findings arrive in prose and bundle several asks into one paragraph - split them, or you will address four of six and think you are done. Reply to every item, including the ones you decide not to act on, with the reason.

**Count the strikes before choosing a fix.** Every `task.md` carries a strike table, updated here, before any fix is chosen:

```
## Failure signatures
| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Oracle Check 0/3 | 2, 3, 4 | solve.sh idempotency; -3way apply; mode fix | 3 |
```

A strike count of **2 forces the remove-the-dependency path**. It is not a nudge: a fix you verified locally that comes back failing a second time means your model of the environment is wrong, so shipping a third variation of the same theory is forbidden. Remove whatever the failure depends on instead (Section 4, two strikes). AltBeacon ran oracle 0/3 across three consecutive rounds and only invoked the rule afterwards, because nothing was counting.

**Change only what the finding requires.** A revision round is not a tidy-up. Every file you touch that no numbered finding named has to be justified in Comments for Reviewer. Workspace bookkeeping - `task.md`, `INDEX.md`, `learning/` write-backs, rule files - is never part of the bundle diff and never appears in Files Changed.

**3. Make the edits in `tasks/<name>/work/`, under the same rules as the first pass.** Every hard boundary from Step 5 still applies - no tracked source edits, no pre-existing test file left modified in the shipped tree, no PR reduction, only the listed Dockerfile fixes. Feedback from a reviewer does not widen what you are allowed to edit. If a requested change would cross one of those lines, say so plainly in Comments for Reviewer and explain what you did instead.

**4. Re-run everything, not just the part you touched.** The full Step 5 Phase A pre-upload checklist including `git fsck --unreachable`, then the Step 5 re-zip rule into `tasks/<name>/upload/` overwriting the previous zip, then the WHOLE Step 5.5 Phase B battery - NOP, oracle 3/3, hostile delete - from fresh extracts of that new zip. Git hygiene comes immediately before zipping, every round, because the revision work recreates `.git/logs`, a stash and dangling objects exactly the way the first pass did. Write the new upload-ledger row after the zip verifies.

**5. Update `submission_answer.txt` - this is the step that gets skipped.** The file has to describe the bundle you are actually uploading now, not the one you uploaded last week. Do not regenerate it from scratch and do not leave it alone: edit the answers your changes affected and add the ones the changes created, and leave everything else as it stands.

**Supersede, do not only append.** A round that replaces a mechanism makes every earlier block describing that mechanism false, and appending a new block does not repair them - the file then describes two mutually exclusive verifiers, which is what a reviewer reads. Before adding anything, grep the answers file for the mechanism you replaced and edit **every** block that still describes it, noting the superseded design in a single clause rather than deleting the history. libcrux shipped a round where issue 2 and Files Changed entry 2 still described a git-based test-tree restore that a later entry in the same file explained had been removed. List the greps you ran in `task.md`, so the next round can see what was checked.

What typically moves after a revision round:

| Answer | When it changes |
|---|---|
| "Select where the task had issues" | A round that touched a new component - a Dockerfile or task.toml fix means the Environment box now applies |
| "What issues did you find" | A newly found defect maps to a category not yet checked |
| Numbered issue details | A new numbered block per newly addressed finding, and edits to existing blocks whose fix changed |
| Files Changed | Every **bundle** file the round touched - new entries, and edits where the "what changed" is now different. Workspace bookkeeping never appears here |
| PR additions | Only if the round expanded scope. Otherwise it stays "NA" |
| Post-fix confirmation (all 8) | Re-verify each box against the current files. A box checked two rounds ago is not evidence about the bundle you are shipping now |
| What makes this task difficult | If the fixes changed what the task actually demands |
| Comments for Reviewer | Every round. Say which revision this is, what you changed, what you deliberately did not change and why, and the fresh oracle/NOP numbers |
| Handling times | The revision field only, **copied from the last Cumulative cell of the task.md ledger**, never remembered. The other three are first-pass numbers and do not move |
| Send to reviewer | Re-decide it against the Step 7 gate every round. It is a template line, so it always carries either Yes or No with a reason |

**6. Re-humanize the file after editing it.** Run the `humanizer` skill over the answers you touched, and re-check the whole file against Section 5 afterwards - the same no-wrap and no-LLM-tells rules, on the edited text and on the joins where new text meets old. New text pasted next to already-humanized text is where the tells reappear. Same exempt list: paths, test names, commands, code, checkbox lines, and the numbers.

**7. Record the round in `task.md` and update `submission_answer.txt` in the SAME action.** These were two separate steps and they drifted apart every time - AltBeacon's answers file carried a revision figure its own `task.md` still flagged as needing a fresh number after five rounds, and libcrux recorded outright that "the round-2 increment had been lost somewhere". Treat them as one write, never one after the other with thinking in between.

Into `task.md`: what the feedback said, the freshness-check result, what you changed, the new NOP / oracle 3/3 / hostile-delete results, the check outcomes, the updated strike table, and the new upload-ledger row. Plus the handling-time ledger, which is the only place the revision number is derived from:

```
## Handling time ledger
| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 1 | 2026-07-30 | 65 | 65 |
| 2 | 2026-08-02 | 60 | 125 |
```

The answers file's "all revisions" figure is **copied from the last Cumulative cell**, not recalled and not re-estimated. Then update the status and the round number in `INDEX.md`. The record is what makes the next round cheap; without it you re-derive the history every time.

Then hand the user the changed answers, in the platform's order, saying which ones moved since the last round so they only have to re-paste those.

---

## 2. The Submitter Form - every question and how to answer it

### Section 1 · Task Metadata

Download the task zip into `tasks/<Original Directory Name>/download/` and extract its inner `task/` to `download/original/` - Step 1.5 asks the user for this, and nothing lands in the workspace root. The platform also displays the task data here - Original Directory Name, Category, Difficulty, Task Tags, Languages, and the Metadata (task.toml) block. Step 1.5 collects this from the user along with the zip itself and Step 2 cross-checks it against the extracted files.

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

---

## 3. Verdict criteria (official)

**Valid as-is:** instruction, tests, and oracle all align with each other and with the source PR. No edits required. All 7 compliance items are genuinely true.

**Fixable** - any of:

1. Instructions overly prescriptive or exposing verifier internals
2. Instruction reads as templated/AI-generated
3. Tests miss requirements stated in the instruction
4. Tests grade undescribed behavior or rely on arbitrary (non-derivable) names
5. Fewer fail-to-pass tests than the bar → add tests to reach it (11–20; the static check rejects anything outside 10–20)
6. Solution leakage (PR URL in instruction, environment spoilers, test-gaming shortcuts)
7. Oracle does not implement the instruction
8. Task too easy → raise difficulty by expanding PR scope
9. A specific, LISTED Dockerfile issue (allowed-fix table in sentinel-task-fixing)
10. A git-hygiene issue in the shipped repo (leaked history, remote, HEAD/base mismatch, reflog, oversized .git)
11. A `task.toml` problem measured against the Section 8 limits - a value out of range, `gpus` not 0, a missing or stripped `network_mode` block, an agent timeout too low for the runs, inaccurate `category` / `difficulty_explanation` / source URL
12. Packaging problems - `tests.patch` cut against the wrong base, a pre-existing test file left modified in the shipped tree (not one that `tests.patch` edits, which is allowed), stray dev artifacts, `solution.patch` instead of `golden.patch`, `problem_statement.md` out of sync with `instruction.md`

**Invalid/Not Fixable** - either of:

1. PR scope needs to be changed or reduced - the only path to validity is reducing or replacing the PR scope entirely
2. Environment issues ECs cannot fix: tangled image/dependency build failures, an oracle timeout that bumping cannot resolve, an agent that genuinely cannot finish within the 7200 s ceiling, heavy external-network dependency, genuinely unrecoverable git corruption

**NOT a Not Fixable condition - platform and infra failures.** A failed eval is only a verdict input when it is caused by the task. `DaytonaRateLimitError` / `ApiRateLimitError`, sandbox auth or connection errors, a one-off `NonZeroAgentExitCode`, and a run that returns blank feedback or "No evaluation information available" are all platform-side. **Infra and platform failures never make a task Unfixable.** The tell is inconsistency - the same task passes on one run and errors on another, or only 1 of N agent trials fails while the rest are clean. Retry rather than reworking; do not burn a revision slot resubmitting blindly; if it persists, tell the user to flag it on Slack with the task/submission UID, the exact error, and whether it is intermittent (that is what separates an outage from a real defect). Before concluding anything from a red eval, separate a platform failure from a task defect that merely looks like one - `tests.patch did not apply` after an agent edited the tests reproduces on every run and IS a task defect (see Section 4 and `learning/tests-patch-vs-agent-edits.md`).

Rules: a single Not Fixable condition overrides everything. Fixable requires every issue actually fixed - a Fixable verdict with unfixed issues is never allowed. Full detail: sentinel-task-check and sentinel-task-fixing.

---

## 4. Evals and the Quality Check (Fixable path)

### The loop

- **Pre-upload answers first:** the analysis verdict (both occurrences + [Internal] Validity), where-issues, what-issues, and the numbered issue details sit above the upload field - enter them before uploading the zip for Check feedback
- **Static Checks** ("Check feedback"): instant structure + Dockerfile validation. Must pass for the task to be eligible for submission. The build runs its phases in order and stops at the first failure, so problems surface one at a time - a green static check only means the _next_ phase can now run (verified - see `learning/static-checks.md`)
- **Prescriptiveness check** (`cdg_sentinel_ultra.prescriptiveness`): scores `instruction.md` 0–1 and lists findings with severity and rule numbers. It fails the BUILD phase but is explicitly non-blocking for submission ("please address the findings before sending the task to review"). Two rules do the work - Rule 3 catches naming the library or built-in to use (`node:v8`, `node:zlib`), Rule 2 catches naming internal file paths or where existing code lives today (`src/utils.ts`). Public surface is fine: module trees, `mod.ts` barrels, required symbol names, type shapes and export-map entries all pass. **Before deleting any path or name from the instruction to satisfy this check, grep the tests for it** - if a test depends on it, repoint the test at something the instruction still states, or you trade a non-blocking finding for a blocking `test_faithfulness` one. Full detail in `learning/prescriptiveness-check.md`. **This bullet is about the build-phase score only.** Instruction quality has a separate blocking path through the Quality Check's must-have `criterion: Instructions` items - see `learning/quality-check-criteria.md` and the rubric-panel section below. Non-blocking here never means instruction quality is advisory
- After the bundle runs, three read-only summaries populate: **Difficulty Check** (agent simulation + verifier stats), **Oracle Check** (golden solution vs verifiers), **Quality Check** (blocking rubric-panel judge). **Download the difficulty results artifact** - it carries the platform-side verifier stdout, and asking for it is the first action on any failed check (Step 10 item 1), above local reproduction in the evidence hierarchy
- **Oracle Check: the bar is 3/3.** The platform runs the golden solution **three times** and anything below 3/3 blocks Send. On the Fixable path a sub-3/3 result is a task defect, not flake. Read the number before theorising, because `0/3`, `1/3` and `2/3` are different failures:
  - **1/3 or 2/3** - run one passed and a later one did not, so state accumulated between runs. Reproduce it by running `solve.sh` twice in one local container. A reverse-apply fallback in `solve.sh` is the classic cause
  - **0/3** - run one already failed, which rules out every state-accumulation theory in a single step. Do not go looking at idempotency; the first invocation is broken
  - **Task defect vs infra:** real per-test output alongside an `N/3` line means task defect. Blank or null results with no verifier output at all means infra. See the "Why this was NOT the 0/3" section of `learning/solve-sh-idempotency.md`, where a correct fix to a genuine idempotency defect was shipped against a `0/3` that arithmetic had already ruled it out of
- **Send to reviewer** only once every condition in the Step 7 Send gate is green - Static Checks, Difficulty with zero invalid trials, Oracle 3/3, Quality Check including the must-have criteria, Instruction Sufficiency not FAIL, the Step 5.5 battery against the current zip, the zip newer than `work/`, and the upload-ledger row written. Checking it with failing checks always results in revision - if sending with failing checks intentionally, leave detailed reviewer comments explaining why
- In-app checks have a **5-minute runtime limit** - iterate with the box unchecked first
- Protocol when checks fail: read summaries and logs → revise within the editing rules → re-upload and re-run with the box unchecked → repeat until passing
- **Two strikes on the same failure.** That loop assumes each round teaches you something. When a fix you verified locally comes back failing a **second** time, it is not teaching you anything and the next variation will not either. Stop refining the theory and remove the dependency instead. A local reproduction proves a condition is *sufficient* to cause the symptom, never that it is the one the platform is applying, so a third locally-verified hypothesis is the same trap wearing a new hat. Read the round-over-round trend as evidence in its own right: a number that does not move across two different fixes means neither fix touched the cause. kvdex 245 went 13 of 16 invalid, then 16 of 16, then 15 of 16, on three correct fixes to three genuine defects, none of which was the defect. Full protocol and the evidence hierarchy in `learning/diagnosing-platform-only-failures.md`
- **A harness failure voids the whole round.** `invalid trial` / `harness failure` is not one bad result among several: when trials are scored invalid you learn nothing about difficulty, nothing about the quality panel's test axes, and nothing about agent behaviour, so every other check that ran becomes uninformative. Budget diagnosis accordingly. The choice is not "an hour of diagnosis or ship now", it is "an hour of diagnosis or a whole round that teaches you nothing" → check the box and submit
- Throughput rule: no daily task cap, but at most **two tasks in "pending revision" at once** - the platform blocks a new claim until one clears

### Troubleshooting known failures

- **"0/8 valid trials - infra/harness failure"** or **"tests.patch did not apply"**: check the base-commit apply first (`git apply --check`), but if that already passes, the cause is almost certainly that an **agent edited or created a file `tests.patch` also touches**. Guaranteed on an API migration, since the visible tests stop compiling and the agent fixes them, and just as likely on a feature task where the agent writes its own test for the class it was asked to build. A clean oracle run never catches it. Fix it in `tests/test.sh` by restoring the test tree immediately before applying the patch, and **do not build that restore on git** - see Section 10.3 for the two shapes that work (create-only patch, or a base64 payload embedded in `test.sh`) and the one-liner that tells you which. Three git-based restores shipped on kvdex 245 across three rounds and none of them measurably worked, because the verify-time workspace is not a git repository; the git-independent one was accepted first time. Verified - see `learning/tests-patch-vs-agent-edits.md`. Other causes: a broken repo (dropped `.git/refs/` from a bad zip), or missing tmux/asciinema/bash in the image
- **`Task Instruction Sufficiency: FAIL`**: the signature is agents at **0%** with module-not-found, import or unresolved-symbol errors while the **oracle passes 100%**. That combination says a fail-to-pass test imports a name the instruction no longer declares as a deliverable - the oracle knows the name because the golden patch creates it, and no agent can, because nothing told them to build it. It is what you get after stripping a path or a symbol from `instruction.md` to satisfy a Q9 or prescriptiveness finding while a graded test still depends on it, which is the exact trade the prescriptiveness bullet above warns about from the other direction. **The fix is to re-anchor the graded ids onto symbols the instruction still names as deliverables, not to put the path back** - restoring it re-opens the Q9 finding and you loop. Do not Send while Sufficiency reads FAIL, however green the other panels look. See `learning/prescriptiveness-check.md`. Distinguish this from `NOT_APPLICABLE`, which only means the harness did not evaluate sufficiency on this run and is not a result
- **Agent timeout**: raise `[agent] timeout_sec` up to the 7200 max. If it still times out, open `runs/` to see WHERE the time went - usually one slow step, not the whole task. If it genuinely cannot fit in 7200 and the only remedy would be shrinking the PR, the task is Not Fixable
- **Nonzero exit-code agent error**: work the usual checks first (local Docker build, tests.patch applies to base, agent timeout, `network_mode` per block). If it persists, remove the `curl` package install from `environment/Dockerfile` and rebuild - a known Harbor edge-case bug. If the task genuinely needs curl, flag it to the user for the Slack channel with the submission UID
- **DownloadVerifierDirError / verifier-output-not-found**: fix the upstream cause (bash vs ash shebang, missing artifact path, missing tmux or asciinema)
- **Linter rejects the task as "easy" after a difficulty downgrade**: a known platform issue. Do NOT hand-edit the pass-rate or difficulty fields in `task.toml` to satisfy a reviewer - the linter rejects anything it reads as easy, so matching the metadata to the measured difficulty and satisfying the linter pull in opposite directions. Never tweak the metadata back and forth; tell the user to flag it on Slack with the task/submission UID and the two conflicting values (the linter's difficulty floor vs the measured metadata). This is a tooling gap, not a task defect
- **Checking submission status**: `stb submissions list` from the CLI is the source of truth. The GUI lags and can make a task flicker in and out; if the CLI and GUI disagree or a submission is stuck, flag it on Slack with the submission UID
- **Infra/platform error, or blank feedback**: `DaytonaRateLimitError` / `ApiRateLimitError`, sandbox auth or connection errors, a one-off `NonZeroAgentExitCode`, and "No evaluation information available" are platform failures, NOT task defects. Do not mark the task Not Fixable over one, and do not burn a revision slot resubmitting blindly - blank feedback usually means the eval output never came through, not that the task failed. The tell is inconsistency: the same task passes on one run and errors on the next, or 1 of N trials fails while the rest are clean. Retry; if it persists, have the user flag it on Slack with the task/submission UID, the exact error, and whether it is intermittent. Check `stb submissions list` for where the task actually is. **Distinguish this from a reproducible failure that only looks like infra** - "0/8 valid trials - tests.patch did not apply" fails identically every run and is a real defect with a real fix (first bullet above)

### The rubric-panel judge

**Two descriptions of the same check, and they disagree. Both are here on purpose:**

| Description | Status | What it says | How to use it |
|---|---|---|---|
| **15 numbered must-have criteria** (`Q1`..`Q15`), each tagged with a `criterion:` group, reported as `N/15 criteria pass` | **MEASURED - this is the current behaviour** (observed 2026-08-02 on `20260728_153118__jqno_equalsverifier__1166`) | A failing must-have criterion blocks the task on its own, whatever the axis scores say | This is what the report you receive will actually look like. Read the criterion numbers and the `judge:` justifications |
| **10 axes scored 1–5 across four rubrics**, with REMOVE / DISCUSS / OK verdicts driven by the two test axes | **OLDER Hub description** - still what `docs/tasking-guide.md` says, and the axis scores do still appear in reports | Only `test_coverage` and `test_faithfulness` flip the verdict | Keep applying it to the test axes. Do NOT read "only the test axes matter" as covering instruction quality |

Reconciled: the must-have criteria are an additional blocking layer on top of the axis logic, not a replacement for it. Treat a task as failing the Quality Check if **either** the axis logic returns REMOVE or DISCUSS **or** any must-have criterion fails. Flag the drift to the user when a report's shape does not match what `docs/` describes.

**What it returns in practice differs from the docs, and instruction quality can block.** Observed 2026-08-02 on `20260728_153118__jqno_equalsverifier__1166`: the Quality Check reported `❌ 2 must-have quality criteria failed (13/15 criteria pass)`, with numbered criteria (`[Q9]`, `[Q10]`), a `criterion:` group per finding, and a `judge:` justification quoting the offending sentence. Both failures were `criterion: Instructions` - Q9 navigation hand-holding, Q10 leaking the exact strings the tests assert - and both were must-have. The test axes were fine and the task still failed. Treat instruction leakage and navigation as **blocking**, and do not carry over the "prescriptiveness is advisory, keep the residual findings" reasoning, which belongs to the separate non-blocking build-phase check. Full detail and the two-checker comparison in `learning/quality-check-criteria.md`. The 10-axis description below is what `docs/tasking-guide.md` still says; keep applying it for the test axes, and flag the drift to the user.

Two independent LLM judges (Claude Opus and GPT-5.5) read the instruction, tests, oracle, and task directory and score 10 axes (1–5) across four rubrics: instruction quality (realism, clarity, self-containedness, prescriptiveness), test quality (test_coverage, test_faithfulness), oracle quality (spec faithfulness, no gaming, robustness/reproducibility), packaging. Where they disagree by 2+ on an axis, a blinded adjudicator settles it.

**Among the axis scores, only the two test axes flip the verdict - but the must-have criteria flip it independently.** Verdict logic:

- **REMOVE** (fails): adjudicated score on either test axis ≤ 2.0, OR either judge scored an axis ≤ 2 with the failure matching one of the six essential patterns below
- **DISCUSS** (fails): any single judge scored either test axis ≤ 2, OR the adjudicated score on either axis is ≤ 3.0
- **FAILS REGARDLESS OF THE AXES**: any must-have criterion fails. `criterion: Instructions` items block on their own - jqno 1166 failed with `13/15 criteria pass` and clean test axes. Instruction leakage (Q10) and navigation hand-holding (Q9) are the two that have actually fired
- **OK** (passes): both test axes above 3.0, no judge at ≤ 2, AND zero failing must-have criteria

Practical bar: both judges need a solid 4+ on coverage and faithfulness. One "3 with reservations" bounces the task. Borderline scores round down by design - don't argue with a 3, fix it.

- **Coverage (Instruction → Tests):** every stated requirement has a real enforcing assertion; a broken or stub solution must fail at least one test. Gaps = false positives
- **Faithfulness (Tests → Instruction):** every assertion maps to something stated or reasonably implied. Hidden requirements = false negatives

### Six auto-REMOVE patterns (never ship these)

| Pattern                       | What it looks like                                                                                                                                                                 |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Silent skip                   | `@pytest.mark.skip`, `skipif`, catching ImportError and setting the module to None - anything letting substantive tests silently not run. A missing dependency must FAIL, not skip |
| No CLI/entry-point invocation | Instruction asks for a CLI/service/script, but test.sh only runs pytest against library internals and never invokes the thing being built                                          |
| Pre-created artifact passes   | `path.exists()` / `is_file()` without content checks, so `touch`-ing the filename passes. Pair every existence check with a content/behavior assertion                             |
| Agent controls coverage       | Tests iterate over the agent's own output (loop over its JSON entries), letting the agent shrink the test surface. Enumerate expected items from the instruction/environment       |
| Fail-open                     | `if not output.exists(): return`, `try/except: pass`, assertions gated behind preconditions. A missing or malformed artifact must fail the suite                                   |
| Overreach                     | Enforcing names, formats, thresholds, paths, or conventions the instruction never states                                                                                           |

### Test-writing checklist

**Do:** map every imperative, named output field, named edge case, and named threshold to at least one assertion (build the bipartite mapping yourself first); test at the instruction's stated strictness ("all rows" means all rows, a named threshold means assert the threshold); include the regression test that reproduces the original failure (fails pre-patch, passes post-patch); keep tests deterministic (fixed seeds, no order/wall-clock/network dependence); commit fixtures and mock data into the verifier image; if a specific output format is required, state it in the instruction so the format assertions are faithful.

**Don't:** assert on source-code text (substring/keyword scans); embed verifier-only constants the agent can't derive (`EXPECTED_COUNT = 47`); compare against hidden golden files never foreshadowed; compute expected values from the agent's own output (circular); require exact error strings, JSON key orderings, whitespace, tolerances, or file paths unless the instruction or an existing convention fixes them; wrap test bodies in broad try/except - ever.

### The advisory axes still matter (reviewers read them)

- **Instruction axes:** reward instructions that read like a real ticket, fully specify success, reference only artifacts that exist in the repo, and state requirements not procedure. Detailed output schemas score well; ordered how-to steps, file localization hints ("the bug is in helpers/queue.py"), and pre-answered edge cases score badly. Two specific triggers the prescriptiveness checker flags: naming the library or built-in the agent should have chosen, and naming an internal implementation file or the current home of code being migrated
- **Oracle axes:** implement every requirement with correct logic; no gaming - no hardcoded answers, fabricated tool output, reading test-side ground truth, or fixture-specific shortcuts (e.g. treating `df['Date'].max()` as "today"); reproducible - seeded randomness, no live network calls, timeouts on subprocesses. Litmus test: "if the inputs were reshuffled within the spec, would this oracle still produce the right answer?"
- **Packaging:** one stray dev artifact shipping into the container (`__pycache__/`, `.DS_Store`, `.venv/`, `.pytest_cache/`, `.idea/`, `.vscode/`, swap files, `.ruff_cache/`, `node_modules/`) hard-caps the axis at 1, as does any solution leakage into agent-readable paths

### If the Quality Check fails

Download the report and read the per-axis justifications - they cite exact files, line ranges, and quoted instruction text. Keep instruction, tests, and oracle in lockstep, re-upload, and re-run with Send to reviewer unchecked until it passes.

**Reason-to-Fix.** The report names a `Reason:` or `reason:` string. Each one has a different fix and a different target file, and picking the wrong file is how a round gets spent moving a problem rather than closing it:

| Reason | What the judge is saying | The fix | Lands in |
|---|---|---|---|
| `coverage_gap` | A requirement the instruction states has no assertion that would fail if it were removed | **First check whether it describes the source PR, not your tests** (see below). If it is genuinely your gap, add or strengthen an assertion and re-run the hostile-delete gate against that exact requirement | `tests/tests.patch` - or `instruction.md`, when the instruction over-promised |
| `oracle_spec_gap` | The instruction promises behaviour the golden patch does not implement | **Almost always an instruction defect, not an oracle defect.** Narrow the instruction to what the PR actually does. Changing the oracle to satisfy a judge is reducing or replacing PR behaviour, which is an Invalid condition and not available to you (`learning/source-pr-cross-check.md`) | `instruction.md` |
| `overreach` | A test enforces a name, format, threshold, path or convention the instruction never states | Either state the requirement in the instruction or relax the assertion. Do not add the requirement to the instruction just to keep a test - only do it if the requirement is genuinely part of the task | `tests/tests.patch`, or `instruction.md` |
| `weak_check` | An assertion exists but cannot fail - an existence check with no content assertion, a fixture that cannot violate the constraint it names, a test iterating the agent's own output | Rebuild the fixture so a broken implementation actually fails it (Section 10.4), then prove it with the hostile-delete gate | `tests/tests.patch` |
| Instruction leakage or hand-holding (`criterion: Instructions`, Q9 / Q10) | The instruction leaks the strings the tests assert, or tells the agent where to look | Delete the navigation and the quoted assertions outright. There is no safe rephrasing of placement under Q9, and grep the tests before deleting a name so you do not trade this for a `test_faithfulness` failure | `instruction.md` (and its `problem_statement.md` copy) |

`overreach` and `weak_check` are **second-hand** - they are named in the rubric vocabulary and this workspace has not seen either in its own reports, so the fixes above are reasoned from the axis definitions rather than measured. `coverage_gap`, `oracle_spec_gap` and the Q9 / Q10 criteria have all fired on real rounds and are worked as cases in `learning/quality-check-criteria.md`.

**First, check whether the finding describes the source PR rather than your work.** A judge reads the instruction as the spec and the bundle as the implementation, so when the bundle faithfully reproduces a PR that does less than the instruction promises, it reports a test gap. It is a spec gap, and the fix is in `instruction.md`. On kvdex 245 all three coverage complaints - a disabled `Float16Array`, an ignored secondary-order test, `RegExp` losing its flags - came from the PR or from base, and narrowing two instruction sentences cleared the finding without touching a graded assertion. Changing the oracle to satisfy a judge is reducing or replacing PR behavior, which is an Invalid condition, not a fix. Verify against the complete PR file list (Step 2 item 8, and page the API) before concluding anything. See `learning/source-pr-cross-check.md`.

---

## 5. Writing Rules for Free-Text Answers

Applies to issue descriptions, the unfixable explanation, "What makes this task difficult", and Comments for Reviewer:

- **Simple 8th-grade English** - basic plain easy to read
- **100% humanized** writing
- **NO LLM artifacts**: no em dashes (the long dash, U+2014), no en dashes (U+2013), no arrows (U+2192, U+2190, U+2194), no markdown symbols in the answer body (`**`, `##`, backticks around prose), minimize commas, no colons, no semicolons (code examples are exempt from these style rules)
- **NO internal check vocabulary.** The reviewer sees your answer with none of the context this workspace has. Never write a criterion label (`Q9`, `Q10`, `Q13`, `Q15`), a judge axis name (`test_coverage`, `oracle_spec_faithfulness`, `test_faithfulness`), a reason string (`coverage_gap`, `oracle_spec_gap`), or a fraction score (`13/15`, `2 of 15`) in an answer. Say what the defect was in plain words instead - "the instruction quoted the exact error text the tests check for", not "Q10 leakage". Real answers files have shipped both. The mechanical check is a bare grep for `Q9`, `Q1[0-5]`, `→`, `–` and `/15` over the whole file, and any hit outside a code example is a defect
- The one exception is a **verbatim quoted report line** inside a code block, where the labels are part of the quote. Quote it as a block, do not paraphrase its vocabulary into your own prose
- Reference specific things verified from the task files (file names, function names, test names, line numbers, patch details)
- Issue descriptions follow the numbered form format exactly and may include code examples
- Difficulty and Comments are one short paragraph each (Comments may be a few short lines when listing several points)
- Never pad with generic filler like "this task tests real-world skills"
- **NO word wrap in `submission_answer.txt`** - every paragraph is ONE long line, however long it runs. Never hard-wrap at 80 columns or any other width, and never let an editor reflow the file. Break lines only where the form itself breaks: between list items, between checkbox lines, between the `- Is this issue fixable` sub-answers, between the separate short lines of Comments for Reviewer, and inside code examples. Everywhere else a newline is a defect, because pasting into a platform text field carries it across and the reviewer reads prose chopped mid-sentence. Verify after writing the file: any prose line that ends without the sentence ending was wrapped, and the lines have to be rejoined
- Declare what you deliberately did NOT fix. If the prescriptiveness check still has residual findings, say in Comments for Reviewer which names stayed and that the graded tests call them by name, so nobody reads it as the report being ignored (`learning/prescriptiveness-check.md`)
- **Run the `humanizer` skill over every paragraph the user will paste into the platform** - the issue descriptions, the difficulty answer, the unfixable explanation, and Comments for Reviewer - at both points it matters: when the text is first drafted in a chat message, and again over the finished `submission_answer.txt` as the closing action of Step 9. The second pass is not redundant, because answers get edited, merged and re-ordered on the way into the file. Code, file paths, test names, commands, diffs, checkbox lines, and the handling-time numbers are exempt and stay verbatim

---

## 6. submission_answer.txt templates

Created in Step 9 as `tasks/<Original Directory Name>/answers/submission_answer.txt` - only after every step for the current task is complete and the user has provided the time numbers.

Six rules that apply to all three templates:

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
1) [issue with evidence from files]
2) ...

Comments for Reviewer:
[1 short paragraph]

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

---

## 7. Task Directory Structure

```
SENTINAL-ULTRA/                      # Workspace root (WSL: Ubuntu-22.04, ext4)
  .cursor/
    rules/
      sentinel-difficulty-scope.mdc  # Companion rules - Cursor copy
      sentinel-task-check.mdc
      sentinel-task-fixing.mdc
      humanizer.mdc                  # Tool rules, same twinning discipline
      quality-rehearsal.mdc
  .claude/
    skills/                          # One SKILL.md per .mdc above - keep every pair in sync
      sentinel-difficulty-scope/SKILL.md   # Same rules - Claude Code copy, keep in sync
      sentinel-task-check/SKILL.md
      sentinel-task-fixing/SKILL.md
      humanizer/SKILL.md             # Mandated by Step 9 and Step 10
      quality-rehearsal/SKILL.md     # Local Quality Check rehearsal before zipping
  bin/                               # Workspace scripts and the pre-upload check suite
  docs/                              # Local export of the Sentinel Ultra Hub - source of truth
    guidelines.md  tasking-guide.md  harbor-framework.md
    faq.md  glossary.md  whats-new.md  changelog.md  ALL_DOCUMENTATION.md
  learning/                          # Verified findings from real runs - READ ALL AT SESSION START (Step 1)
    README.md                        # Index and note format
    static-checks.md                 # The 20 upload checks; hard 10–20 fail_to_pass range
    prescriptiveness-check.md        # Instruction scoring phase; library and internal-path rules
    tests-patch-vs-agent-edits.md    # tests.patch vs agent edits; invalid difficulty trials
    stale-test-reports.md            # Build-time test results faking pass_to_pass
    local-runs.md                    # Local oracle/NOP on this machine; filesystem pitfalls
    verify-in-the-image.md           # Checking in the built image what the bundle only claims
    unreachable-git-blobs.md         # Solution/test blobs surviving a clean-looking gc
    verifier-fail-open.md            # Reward 1.0 with a nonzero test-command exit
    solve-sh-idempotency.md          # Reverse-apply fallback undoing the fix on the 2nd oracle run
    quality-check-criteria.md        # The 15 must-have criteria; instruction findings block
    source-pr-cross-check.md         # Coverage findings that describe the PR; API paging trap
    dirty-repo-and-symlinks.md       # Dirty shipped tree, lost mode bits, zip -y
    raising-difficulty-on-a-wrapper-task.md  # When the API names ARE the deliverable
    diagnosing-platform-only-failures.md     # Two-strikes rule; evidence hierarchy
    accepted-bundle-reference.md     # The bundle that cleared every gate, measured
    <and any note added since>       # learning/README.md is the authoritative index, not this tree
  chat_transcripts/                  # Raw session transcripts kept for evidence
    alt.txt  cryspen.txt  jqno.txt  oliver.txt  cursor_etlcpp.md  revision.md  README.md
  comparison-report/                 # The audit that produced the current rule set
  AGENTS.md                          # Entry point for non-Claude agents
  CLAUDE.md                          # This file
  README.md                          # Workspace orientation
  INDEX.md                           # Cross-task register - one row per task, read at session start
  facts.yml                          # The settled facts, machine-readable
  prompts.md                         # Reusable prompt templates for the submitter
  .gitignore
  _archive/                          # Finished tasks moved here whole, same folder shape
    20260719_045042__oliver-oloughlin_kvdex__245/   # The one platform-ACCEPTED bundle. READ-ONLY reference
    superseded/                      # Retired root documents (Sentinel_CLAUDE.md, res.md). TODO.md was
                                     # rewritten as root prompts.md; revision.md moved to chat_transcripts/
  tasks/                             # ONE FOLDER PER TASK - everything for a task lives together
    <Original Directory Name>/
      task.md                        # Record. Carries, in this order: the upload ledger, the
                                     # learning/ notes applied, the failure-signature strike
                                     # table, the handling-time ledger, then one block per round
      task_details.md                # The platform data block, pasted verbatim (Step 1.5)
      download/
        <submission_id>_submission.zip   # Exactly what the platform gave you
        original/                    # Pristine extract, NEVER edited, the diff target
          instruction.md             # Problem statement given to the agent
          task.toml                  # schema_version + [environment] [agent] [verifier] [metadata] - see Section 8
          environment/
            Dockerfile               # Container build (only LISTED fixes allowed)
            problem_statement.md     # MUST be a byte-identical copy of instruction.md
            repo/                    # Real git checkout - NEVER edit tracked source files
          solution/
            solve.sh                 # Oracle solution
            golden.patch / init_state.patch  # Fix patch (init_state.patch = reverse form). OPTIONAL
          tests/                     # ONLY these four names are legal inside tests/
            test.sh                  # Verifier: applies tests, runs suite, writes reward
            tests.patch              # Fail-to-pass test patch (must apply at the base commit)
            config.json              # Harness run + grading config (fail_to_pass / pass_to_pass)
            grade.py                 # Allowed but usually absent - most tasks grade inside test.sh
            files/                   # DOES NOT SHIP. The static check allows only the four names
                                     # above inside tests/, and a files/ directory is rejected
                                     # even though older layout docs list it - see
                                     # learning/static-checks.md
        runs/                        # Agent trial logs when the bundle ships them. NEVER re-zipped
          <agent_name>/<timestamp>/
            result.json
            harborized__<id>/verifier/
              reward.txt             # 0 or 1
              test-stdout.txt        # Full test output - KEY for failure analysis
      work/                          # THE WORKING COPY - all edits happen here, same shape as original/
      upload/
        <Original Directory Name>.zip    # The bundle you re-upload
      answers/
        submission_answer.txt        # Form answers (Step 9)
```

Re-upload zip unpacks directly to `instruction.md`, `task.toml`, `environment/`, `solution/`, `tests/` - no `runs/`, no `task/` wrapper.

**Local oracle and NOP runs use the session scratchpad, never a folder inside the workspace.** The reason is that `solve.sh` and `test.sh` mutate the tree they run in, so a run inside the workspace destroys the thing being measured. The workspace is on **ext4** as of 2026-08-04 (it was previously on an NTFS mount that handled bulk deletes badly, and that constraint no longer applies) - check with `df -Th .` before assuming either way. See `learning/local-runs.md`.

**Starting a new task:** create `tasks/<Original Directory Name>/{download,work,upload,answers}`, drop the downloaded zip in `download/`, extract its inner `task/` to `download/original/`, paste the platform data block into `task_details.md`, then add a row to `INDEX.md`. Step 2 item 0 copies `download/original/` to `work/` before any command runs, and `download/original/` is frozen from that point on.

---

## 8. task.toml reference (check on EVERY task)

`schema_version` is the Harbor format version, not the task version. Four blocks, with hard limits:

| Block           | Field                      | Required value / limit                               |
| --------------- | -------------------------- | ---------------------------------------------------- |
| `[environment]` | `os`                       | container OS, e.g. `linux`                           |
|                 | `cpus`                     | `2` or `4`                                           |
|                 | `memory_mb`                | min `2048`, max `16384`                              |
|                 | `storage_mb`               | min `5120`, max `10240`                              |
|                 | `gpus`                     | always `0`                                           |
|                 | `build_timeout_sec`        | max `1800`                                           |
|                 | `network_mode`             | `"public"`                                           |
| `[agent]`       | `network_mode`             | `"allowlist"`                                        |
|                 | `allowed_hosts`            | `["api.portkey.ai"]`                                 |
|                 | `timeout_sec`              | max `7200` - raise it when runs/ show agent timeouts |
| `[verifier]`    | `network_mode`             | `"no-network"`                                       |
|                 | `timeout_sec`              | max `1800`                                           |
| `[metadata]`    | `category` (+ subcategory) | primary classification - editable                    |
|                 | `difficulty_explanation`   | why the task warrants its tier - editable            |
|                 | `source`                   | URL of the source PR / commit / issue                |
|                 | `repo_name`                | short repo name, e.g. `kvdex`                        |
|                 | `repo_license`             | a real SPDX id, never blank                          |
|                 | `base_commit_sha`          | must equal `git rev-parse HEAD` in the shipped repo  |
|                 | `source_pr_url`            | same URL as `source` on every bundle measured        |

**The last four rows are observed, not documented.** `docs/harbor-framework.md:74-78` lists only `category`, `difficulty_explanation` and `source` under `[metadata]`, yet all four bundles on this machine ship `repo_name`, `repo_license`, `source_pr_url` and `base_commit_sha` populated, alongside `author_name`, `author_email`, `subcategory` and `coding_language`. Measured 2026-08-04: `repo_license` is `MIT` on kvdex 245 (`_archive/20260719_045042__oliver-oloughlin_kvdex__245/work/task.toml:13`) and `Apache-2.0` on libcrux 1165, AltBeacon 1177 and equalsverifier 1166. Check all four on every task, in the Step 2 cross-check:

- `repo_license` holds a real SPDX identifier and matches the licence file in `environment/repo`. A blank, missing or invented value is a Metadata Issues finding
- `repo_name` matches the repo directory and the repo half of the source URL
- `base_commit_sha` equals `git rev-parse HEAD` in the working copy. On a mismatch HEAD wins and the field gets realigned
- `source_pr_url` and `source` resolve to the same PR

Network rules that changed recently and are easy to get wrong:

- `network_mode` is a **per-block** field. Do NOT strip it - older guidance said to remove `network_mode` / `allowed_hosts` and that guidance is dead
- Separately, remove `network_mode = "none"` from `docker_compose.yaml` if it is present
- The Dockerfile MAY use the network at build time. Only run time is restricted - the agent reaches the model gateway only, the verifier is airgapped. Never flag a build-time network install as an issue; flag non-reproducible builds and run-time fetches instead

Do NOT hand-edit the difficulty or pass-rate metadata to make a check pass. If the measured difficulty and the declared metadata disagree and the linter then rejects the task as "easy", that conflict is a known tooling gap - escalate it on Slack with the UID rather than tuning the fields (see the troubleshooting list in Section 4).

**Legacy `model_difficulty` vs `difficulty` - report it, do not quietly reconcile it.** Neither field is in the current schema; both only survive on older tasks. When they contradict each other (`model_difficulty = "medium"` against `difficulty = "hard"`), that is a metadata accuracy finding worth naming in Comments for Reviewer, and a reviewer may well ask for them to agree. It is still not licence to edit a difficulty field to satisfy a check or a linter - `docs/faq.md` is explicit that the fix for that conflict is escalation, not tuning. If a reviewer asks directly for the fields to be aligned, do it, and say in Comments for Reviewer that the change came from their note.

`[environment] os` is a documented field (`docs/harbor-framework.md`) and appears in the reference `task.toml`. A bundle missing it is a metadata finding.

---

## 9. Understanding the solution patch

- `golden.patch` is the forward fix: applying it produces the solved state. It is the current, correct name - if the bundle ships `solution.patch` (a short-lived draft name) rename it to `golden.patch`
- **`init_state.patch` is a former NAME for `golden.patch`, not a different format.** `docs/glossary.md:38` reads "`golden.patch` (a.k.a. gold patch; formerly `init_state.patch`)" and `docs/changelog.md:49` records the rename. This file used to describe it as a reverse diff whose polarity is inverted, and nothing in `docs/` says that. No bundle in `tasks/` or `_archive/` ships one, so the claim has never been testable here either. If a bundle ever does ship an `init_state.patch`, **read the diff before assuming its direction**: check whether the `+` lines are the solved state or the broken one, and confirm against `solve.sh` (a lone `patch -p1 -R` or `git apply -R` says reverse, a plain apply says forward). Rename it to `golden.patch` once you know which way it runs. A filename the docs call obsolete is not evidence about polarity
- A missing patch alone is NOT a defect if solve.sh implements the fix
- An oracle may be larger than strictly necessary or include extra functionality the instruction never asked for. That is fine as long as it does what the instruction requires and the tests enforce it - the oracle exists to prove the task is solvable

---

## 10. Verifier hardening - what passes every eval and still comes back

Everything here comes from real submissions that cleared Static Checks, the Difficulty Check, the Oracle Check and the Quality Check judge, and were still sent back by the reviewing EC. The evals grade the task as declared; a reviewer reads what the verifier actually does. Work this list before the Step 5.5 runs, and again before Send to reviewer.

Each item says how far the docs back it. **Docs rule** = stated in `docs/`. **Docs criterion** = the docs state the property and this is the way to verify it. **Practice** = not in `docs/`; a defect-avoidance technique, applied with judgment and disclosed in Comments for Reviewer.

### 10.1 The grader must fail closed (docs rule)

`docs/guidelines.md` states the invariant: *the exit code should match the reward it writes.* A grader that scans stdout for the expected test names and writes `1.0` when it finds them breaks it - a compile failure, a timeout, a crash or a partially executed suite can all leave those lines in the log. Reward `1.0` alongside a nonzero exit is reproducible and a reviewer will reproduce it.

- Any nonzero exit from the test command means reward `0.0` and a nonzero exit from `test.sh`.
- If the script records the raw status (`raw_exit_code` or similar), it must also gate on it. Recording without gating is the defect.
- `set -euo pipefail`, and no `|| true` on the line that runs the suite.
- The NOP run is the check: it must show a nonzero raw exit as well as reward `0.0`. See `learning/verifier-fail-open.md`.

**The stock harness ships this defect.** The generic `test.sh` computes `success = not missing_required and not unexpected` and never reads the `raw_exit_code` it recorded three lines earlier. If you have not edited `test.sh`, your task is fail-open - this is not a hypothetical about someone else's bundle. Two things follow:

- **`execution.commands` is a list, so the runner's exit status is the LAST command's.** On a task that runs the suite and then a parser, a failing suite followed by a healthy parser gives status 0 and any gate you add never fires. Emit `set -e` at the top of the generated runner so the first failure propagates.
- **`set -e` does not cover a command that is itself a pipeline, and `test.sh`'s own `pipefail` does not reach the runner.** `bash /tmp/run_tests.sh` is a separate shell and does not inherit shell options, so a single command like `deno test … | python3 -c '<parser>'` runs with defaults and reports the parser's status however carefully `test.sh` was written. Measured on kvdex: `raw_exit_code 0` on a NOP where **zero tests ran**. Fix at the invocation, `RUNNER=(bash -o pipefail /tmp/run_tests.sh)`, and keep the `set -e` above as well - a multi-command task needs one, a piped task needs the other, and many need both.
- **Measure the runner's bare exit on a green tree before wiring the gate.** Some runners exit nonzero on a fully passing suite (leak or sanitizer complaints, skipped-test codes). Gating without checking fails your own oracle. kvdex answered `bare exit=0` with `ok | 152 passed | 0 failed | 2 ignored`, so the gate was safe. If yours answers nonzero on green, leave the gate out and say why in Comments for Reviewer. Tests the runner reports as *ignored* emit neither PASS nor FAIL, so an upstream skip is not a hazard when flipping `allow_extra_failures` to `false`.
- **Gate inside the grader, never with an early `infrastructure_error` exit.** The difficulty harness reads `infrastructure_error` as *invalid trial*, not *agent failed*. Bailing out on a nonzero exit would reclassify every non-compiling agent as an invalid trial and poison the difficulty verdict the same way a broken `tests.patch` does. Add the condition to the success expression instead (`and args.raw_exit_code == 0`) so the per-test report survives and the run still counts as an ordinary grading failure. Confirm on the NOP: reward `0`, raw exit nonzero, `infrastructure_error: None`.

### 10.2 `pass_to_pass` and unexpected failures (mixed)

`docs/guidelines.md` calls `pass_to_pass` "the regression guard" and ships it populated in the reference `config.json`, but only `fail_to_pass` is described as required - an empty `pass_to_pass` is not a documented violation. It is still a weak verifier, and reviewers treat it as one.

- Populate `pass_to_pass` with existing tests that cover the area the patch touches. Name real test ids and confirm they pass in the oracle run.
- `allow_extra_failures` **does not appear anywhere in `docs/`**. If the shipped `config.json` already carries the field and the run executes exactly the graded set, set it to `false`. Do not add the field to a config that lacks it - same rule as the legacy `task.toml` fields.
- Cross-check against `learning/stale-test-reports.md`: a `pass_to_pass` list that a build-time test report satisfies is not a guard at all.

### 10.3 Where the evaluator's tests live (practice)

`tests.patch` may edit a pre-existing public test file and the accepted kvdex bundle edits 44 of them (Step 2 item 6), so injecting graded tests into an existing suite is permitted. It is also how trials die. This section is a **practice**, not a rule: give the graded tests a file of their own and a distinctive prefix on the suite and test identifiers.

- An agent writing its own test named `partition_move` in the same public suite produces a redefinition error, the build fails, and the trial is scored as a failure for a correct implementation.
- A separate verifier-only source file with prefixed identifiers removes the collision surface and keeps the graded names out of the agent's view.
- This complements, not replaces, the restore step in `learning/tests-patch-vs-agent-edits.md`. Do both: separate file plus restoring the test tree before applying the patch. Measured: each half independently rescued a committing-agent run that the other half alone did not, so the redundancy is real rather than theoretical.
- **Name the new files something no agent would choose.** `SubtypeManagerTest.java` for a class called `SubtypeManager` is the obvious name in the obvious package, and an agent writes it as a matter of course. A `Sentinel`-prefixed verifier-only file cannot collide. Renaming changes the ids in `grading.fail_to_pass` and `execution.selected_test_files_to_run`, so update both, and keep the file matching whatever pattern the runner collects (surefire needs `*Test.java`).
- **The prefix has to be a legal module identifier in the target language, or the file is never collected.** A name the runner cannot import is not a graded test, it is a missing one, and every trial reports the ids missing while the file sits right there in the tree. Work with the language's own rules: `test_foo_sentinel.py` for pytest (a leading digit or a hyphen makes it unimportable), `foo.sentinel.test.ts` for deno and vitest, `SentinelFooTest.java` for surefire, `sentinel_foo.rs` for a cargo integration test. The shipped bundles use `SentinelSubtypeManagerTest.java`, `SettingsJavaTest.java` and `sentinel_pqcp_verifier.rs`. Confirm collection by running the suite once and seeing the new ids reported, not by reading the filename.

**The restore step, written correctly. Do NOT use git.** Three git-based designs shipped on kvdex 245 across three rounds and none of them measurably worked, while every one passed every local scenario that could be constructed. The verify-time workspace is not a git repository: reproduced locally, and named outright by four codex trial analyses in a sibling task's report. A restore that touches git, in any form, is a wasted round. Full history in `learning/tests-patch-vs-agent-edits.md`, now platform-confirmed by kvdex 245's acceptance on 2026-08-04.

Pick the shape by measuring where the graded ids live:

```bash
python3 - <<'PY'
import json, os, re
patch = open('tests/tests.patch', encoding='utf-8', errors='replace').read()
touched = set(re.findall(r'^diff --git a/(\S+)', patch, re.M))
added = '\n'.join(l[1:] for l in patch.splitlines()
                  if l.startswith('+') and not l.startswith('+++'))

# Graded ids come in four shapes and each maps back to a file differently:
#   tests/x.test.ts::name       path::name    (deno, pytest, vitest, jest)
#   pkg.ClassTest::method       fqcn::method  (gradle, kotlin)
#   pkg.ClassTest#method        fqcn#method   (junit, surefire)
#   module::test  /  bare_test  symbol only   (cargo, ctest, go)
# The first three name a file. The fourth does not, so it is resolved by where the
# symbol occurs: only in tests.patch means inside, in an unpatched test file means
# outside, nowhere means UNRESOLVED. Never let a shape you cannot map fall through
# and count as outside - that is the reading that picks the wrong restore design.
stems = set()
for t in touched:
    stems.add(t)                                              # exact path
    stems.add(t.rsplit('/', 1)[-1].rsplit('.', 1)[0])         # simple class / file stem
    parts = t.split('/')
    for lang in ('java', 'kotlin'):                           # FQCN, maven / gradle layout
        if lang in parts:
            stems.add('.'.join(parts[parts.index(lang) + 1:]).rsplit('.', 1)[0])

tokens = set()                                                # every word in the UNPATCHED tests
for root, dirs, files in os.walk('environment/repo'):
    dirs[:] = [d for d in dirs if d not in ('.git', 'node_modules', 'target', 'build')]
    if 'test' not in root.lower():
        continue
    for f in files:
        p = os.path.join(root, f)
        if not os.path.isfile(p) or os.path.relpath(p, 'environment/repo') in touched:
            continue                                          # skips broken symlinks too
        tokens |= set(re.findall(r'[A-Za-z_]\w+',
                                 open(p, encoding='utf-8', errors='replace').read()))

g = json.load(open('tests/config.json'))['grading']
inside, outside, unresolved = [], [], []
for i in g['fail_to_pass'] + g.get('pass_to_pass', []):
    head, name = i.rsplit('#', 1) if '#' in i else (
                 i.rsplit('::', 1) if '::' in i else ('', i))
    if head and ('/' in head or '.' in head):                 # the id names its file or class
        (inside if head in stems else outside).append(i)
        continue
    sym = re.split(r'[ (]', name)[0]                          # symbol-only id: cargo, ctest, go
    if head and re.search(r'\b%s\b' % re.escape(head), added):
        inside.append(i)
    elif re.search(r'\b%s\b' % re.escape(sym), added):
        inside.append(i)
    elif sym in tokens or head in tokens:
        outside.append(i)
    else:
        unresolved.append(i)

print(len(outside), 'of', len(inside) + len(outside) + len(unresolved),
      'graded ids live in files tests.patch does not touch')
if unresolved:
    print('UNRESOLVED:', len(unresolved), 'ids map to no patched file and no known symbol.',
          'Resolve these by hand before choosing a shape:', unresolved[:5])
PY
```

Re-measured 2026-08-04 against every bundle on this machine: `102 of 132` on kvdex 245, `1124 of 1223` on equalsverifier 1166, `210 of 230` on AltBeacon 1177 and `21 of 38` on libcrux 1165. On a synthetic fixture whose id matches neither a patched file nor any symbol it prints `UNRESOLVED` instead of a number. The earlier version of this snippet split every id on `::` and read the left half as a path, which made all 20 of AltBeacon's `pkg.ClassTest::method` ids and all 17 of libcrux's `module::test` ids look like files it had never patched. On libcrux it printed `35 of 35` against the 35-id config of the day, and hand resolution put the real figure at 21 outside. The config has since grown to 38 ids and the corrected snippet reads `21 of 38`, so the outside count is the number that matched. **An UNRESOLVED line means the count is not yet an answer.** Resolve those ids by hand and re-run before you pick a shape, because the whole point of the number is which of the two designs below you build.

**Zero → create-only patch.** Regenerate `tests.patch` so every graded file is a create (`new file mode`, `--- /dev/null`) rather than a diff. A create has no context lines, so nothing can conflict. Delete those paths in `test.sh` first, reading the list out of the patch itself with `sed -n 's|^+++ b/||p' /tests/tests.patch`. No payload needed.

**This is NOT the equalsverifier shape, despite what earlier revisions of this file and of `learning/` said.** equalsverifier 1166 measures **1124 of 1223** outside the patched files: its `fail_to_pass` is fully covered (0 of 19 outside, 10 graded classes protected) but its `pass_to_pass` is 1204 regression guards spread over 129 test classes. Only its f2p set is concentrated, which is what the earlier claim was really describing. A create-only patch there fixes the harness failure and still leaves 1124 guards running the agent's own copies.

**Anything above zero → restore the whole test tree from a payload embedded in `test.sh`.** kvdex was 102 of 132, because `pass_to_pass` was 112 regression guards spread across a suite where only 45 files are patched; a create-only patch would have left 102 graded tests running the agent's own copies, which is a test-gaming route a Quality Check round had already asked to close.

```bash
# build the payload from the pristine base tree, deterministically
tar --sort=name --mtime='<base commit date>' --owner=0 --group=0 --numeric-owner \
    -czf /tmp/tests_base.tar.gz -C environment/repo tests
base64 -w76 /tmp/tests_base.tar.gz     # paste between the heredoc markers below
```

```bash
TEST_TREE="tests"
TEST_TREE_B64="/tmp/tests_base.tar.gz.b64"
TEST_TREE_TGZ="/tmp/tests_base.tar.gz"

cat > "$TEST_TREE_B64" <<'TESTS_BASE_B64_EOF'
<base64 of the gzipped tarball, wrapped at 76 columns>
TESTS_BASE_B64_EOF

if base64 -d "$TEST_TREE_B64" > "$TEST_TREE_TGZ" 2>/dev/null \
   || base64 --decode "$TEST_TREE_B64" > "$TEST_TREE_TGZ" 2>/dev/null; then
  rm -rf "$TEST_TREE"
  tar -xzf "$TEST_TREE_TGZ" -C . || <infra error, reward 0, exit 2>
else
  <infra error, reward 0, exit 2>
fi
```

The payload goes **inside `test.sh`**, not in `tests/files/` - `tests/` accepts only `config.json`, `grade.py`, `test.sh` and `tests.patch`, and a `tests/files/` archive is rejected by the static checker. `test.sh` is read from `/tests`, so it is present whenever the verifier runs at all, which makes it the most dependable restore source available inside the verifier. Deleting the tree first is what removes a file the agent created where `tests.patch` adds one. A failed restore genuinely is a harness failure, so `infrastructure_error` is correct on those two paths only. Cost on kvdex: 158 files and 904 KB of tests became a 52 KB archive, 70 KB of base64 and a 93 KB `test.sh`. It leaks nothing, because it is the tree the agent already has in its checkout. Verify it round-trips **out of the built zip** before spending container time on it.

### 10.4 A test must exercise the constraint it claims (docs criterion)

The coverage axis asks whether a broken or stub solution fails at least one test. A test that names a constraint but uses a fixture that cannot violate it fails that bar while looking like coverage.

- The shipped case: tests labelled bidirectional-iterator coverage built on `std::array`, whose iterators are random access. An implementation illegally depending on random access passed every one of them.
- Same shape elsewhere: "handles empty input" with a one-element fixture, "works without network" with a mock already installed, "rejects oversized payloads" with a payload under the limit.
- For every assertion, ask what implementation defect it would actually catch. If the answer is none, the fixture is wrong.

### 10.5 Hostile-delete before the zip (docs criterion)

Stub out one requirement the instruction states, in a throwaway copy, and re-run the verifier. Reward must drop to `0.0`. If it stays at `1.0`, that requirement has no enforcing assertion and the coverage axis is scoring a false positive. Run it against the requirement you are least sure is tested, not the easiest one.

### 10.6 Oracle shape (mixed)

- **`solve.sh` forward-only and idempotent.** Apply if needed, no-op if already applied, fail loudly when nothing applies. The sanctioned shape is four steps, in this order, and it is the one verified in a container with three consecutive applies (the "The fix" section in `learning/solve-sh-idempotency.md`):

  ```bash
  # 1. idempotency probe: if the REVERSE of the patch fits, the patch is already in
  if git apply -p1 --reverse --check --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
    echo "golden.patch is already applied; nothing to do."; exit 0
  fi
  # 2. plain forward apply
  if git apply -p1 --whitespace=nowarn /solution/golden.patch 2>/dev/null; then exit 0; fi
  # 3. --3way retry, which resolves context drift the plain apply will not
  if git apply -p1 --3way --whitespace=nowarn /solution/golden.patch; then exit 0; fi
  # 4. loud failure
  echo "ERROR: golden.patch did not apply cleanly." >&2; exit 1
  ```

  **`git apply --3way` is the prescribed retry, not a defect.** The banned thing is a reverse apply that counts as SUCCESS after the forward apply failed, because that inverts a correct tree on the second run and hides a patch that never applied. Step 3 above is a forward apply with better merge logic and cannot invert anything. Grep for the tell before you build: `grep -n 'apply.* -R' solution/solve.sh`. A `-R` inside a `--check` probe is the idempotency test and is correct. A `-R` that actually applies, as a fallback, is always the bug.
- **`solve.sh` applies `golden.patch` and does nothing else.** Every delete, rename and content edit of a tracked path lives inside the patch, never as an `rm`, `mv`, `sed` or `cp` line in the script. A script that mutates tracked files outside the patch passes the Oracle Check, because the check only asks whether the verifier goes green, and then the reviewer reads a golden patch that does not describe the solved state. The diff of the patch has to be the whole solution. Setup lines that touch nothing tracked (`cd /app`, `set -euo pipefail`, an echo) are fine.
- **Golden patch scoped to the PR.** `docs/guidelines.md`: only what resolves the task, no drive-by edits. Diff the patch's file list against the PR's (Step 2 item 9). Missing files count too - docs and changelogs the PR touched belong in golden.
- **Test files stay out of golden.** Golden carries non-test changes; graded test changes travel in `tests/tests.patch` (Step 2 item 9). Measured 2026-08-04: not one of the four bundles here has a test file in `solution/golden.patch`, including the accepted kvdex 245.

  **Open question, tested and not confirmed: does a PR-aligned expectation update to a pre-existing test belong in golden?** The claim was that it must, because the Quality Check applies golden alone. Checked against `docs/` and against the four bundles and it does not hold up as stated. `docs/tasking-guide.md:266` says the Quality Check judges READ the instruction, tests, oracle solution and task directory - they score files, they do not apply a patch. The check that does apply golden is the Oracle Check (`docs/tasking-guide.md:244`), and it runs `solve.sh` and then `test.sh`, so `tests.patch` lands there too and an expectation update inside `tests.patch` is present during the oracle run. So there is no measured mechanism that needs the update to travel with golden. Until a real report says otherwise, keep expectation updates in `tests.patch` and let the affected id move from `pass_to_pass` into `fail_to_pass`, since that is what it has become. What would settle it: a downloaded Quality or Oracle report that fails on a pre-existing test whose expectation `tests.patch` updates. Paste that report into `learning/` if it ever arrives.
- **Check the oracle against whatever standard the instruction names.** If the instruction says an API should behave like a known library function, read the oracle against that function's actual contract. The shipped case was a `stable_partition` analogue returning `first` instead of `last` for a single matching element - correct-looking code, wrong at n == 1, and no test caught it.
- Script mode `0755` on both `solve.sh` and `test.sh`.

### 10.7 Fail-open Dockerfiles (limited)

`; exit 0` after a configure step, or an install chain ending in `|| true`, lets the image build green without the tools the agent and verifier need. It is a real defect, but "make the build fail closed" is **not** on the allowed-fix table in `docs/guidelines.md`, and that table is exhaustive.

- Fix it where it causes a listed issue: a swallowed install that leaves tmux, asciinema, bash or a required toolchain missing is the listed row, and installing the tool properly is the allowed fix. `command -v` gates for tools the verifier depends on fall under the same reasoning.
- Do not strip `; exit 0` purely as hygiene when nothing downstream breaks. Record it as a finding and say so in Comments for Reviewer.
- `docs/tasking-guide.md` still requires the build to be reproducible with test dependencies baked into the image; a build that hides its own failures is not.

### 10.8 Test-suite shape (docs criterion)

- **Distinct contracts, not padding.** The f2p count is a coverage floor, not a target to fill. The same assertion reminted across N sizes, or tautologies like asserting a constant against itself, add count and no coverage.
- **Test the wiring, not only the helper.** If the PR's point is that some path now uses a new helper, at least one f2p must go through that path. A perfect helper nobody calls can green the whole suite. This is the same failure the `No CLI/entry-point invocation` auto-REMOVE pattern describes.
- **No serialization accidents.** Do not pin object numbers, byte offsets, creation-order ids or other artifacts of how something happens to be written out. Assert the structure and the observable values.
- **"Any equivalent wording" is a contract.** If the instruction says a message may be phrased freely, the matcher has to accept the paraphrases - including every example the instruction itself gives. A regex demanding two literal tokens within 40 characters is not flexible wording.

---

## 11. Common Mistakes (Avoid)

- Skipping any of the three Step 5.5 Phase B runs on a Fixable task (NOP, oracle 3/3, hostile delete), or writing answers before all three pass
- Drafting answers before the zip exists in tasks/<name>/upload/ and the battery has passed against an extract of that exact zip
- Uploading the fixed zip to the platform before entering the Phase 1 answers (verdict, where/what issues, issue details)
- Running solve.sh or test.sh inside the working copy instead of a disposable scratchpad extract of the built zip (they mutate the tree)
- Editing shipped scripts just to make them run locally - recreate the container paths instead
- Finalizing Valid as-is without a local oracle + NOP run - it's the only check on those tasks
- Checking a compliance/confirmation box that was not actually verified against the files
- Giving different answers to the two occurrences of the analysis question
- Editing tracked source files inside environment/repo/
- Calling a task Fixable without applying every fix, or faking a fix
- Reducing or replacing PR scope (expansion only - and then re-run the difficulty eval)
- Forgetting to sync problem_statement.md after editing instruction.md
- Including runs/ or a task/ wrapper directory in the re-upload zip
- Editing the original extract instead of the working copy in tasks/<name>/work/
- Zipping in a way that drops dotfiles - environment/repo/.git must be inside the zip
- Zipping with `zip -rD` or a GUI compress tool - both drop empty directory entries like `.git/refs/` and break the repo on the platform
- Leaving a pre-existing test file modified in the shipped tree under `environment/repo`, which is what the harness actually checks
- Reading that rule as a ban on `tests.patch` editing pre-existing test files. It is not one - the accepted kvdex bundle edits 44 of them, so rewriting a working patch into a create-only shape on that reasoning wastes a round and judging a healthy bundle Fixable over it is a false finding
- Stripping `network_mode` or `allowed_hosts` from task.toml, or leaving `network_mode = "none"` in docker_compose.yaml
- Flagging build-time network use as an issue - Dockerfile builds may use the network, only run time is restricted
- Leaving a task.toml value outside the Section 8 limits, or `gpus` not set to 0
- Hand-editing the task.toml difficulty or pass-rate fields to satisfy the linter or a reviewer - escalate that conflict instead
- Leaving `solution/solution.patch` unrenamed, or leaving problem_statement.md out of sync after an instruction edit
- Using tasks/<name>/work/ or tasks/<name>/upload/ without checking they exist first (always mkdir -p)
- Creating submission_answer.txt before every step for the task is complete
- Leaving stray dev artifacts (**pycache**, .DS_Store, .venv, node_modules, etc.) in the zip - hard-caps packaging at 1
- Shipping any of the six auto-REMOVE test patterns (silent skip, no CLI invocation, existence-only checks, agent-controlled coverage, fail-open, overreach)
- Not registering added tests in config.json fail_to_pass, or leaving tests.patch cut against the wrong base
- Answering the difficulty question for an Invalid/Not Fixable task (it is only asked for Valid as-is and Fixable)
- Selecting "Dirty git history that can't be recovered" for ordinary git issues - most are fixable
- Marking a task Not Fixable over an infra or platform failure (Daytona/rate-limit errors, sandbox auth errors, a one-off nonzero exit, blank feedback) - those are never a Not Fixable condition, retry and escalate instead
- Reworking a task after blank feedback or a dropped eval result, or resubmitting blindly and burning a revision slot, before checking whether the failure even reproduces
- Vague issue descriptions or unfixable explanations (these get submissions rejected)
- Skipping the Step 1.5 ask for the task zip and platform data, or generating those values instead of waiting for the user
- Not cross-checking platform Category, Difficulty, Tags, and Languages against task.toml and the actual repo code
- Inventing any of the handling-time numbers instead of asking the user
- Folding the revision time into the total submission time - the total is fields 1 + 2 + 3 only, and the revision number is always tracked on its own
- Treating 180–240 and the old 60–120 revision window as gates and bending a real number to fit them. They are shape hints. The one platform-ACCEPTED bundle shipped a 260-minute total and 195 minutes of revisions, so a figure outside the bands is not an error - an invented one is. Read the revision figure off the task.md handling-time ledger, which grows 50 to 70 minutes per round
- Putting whole-task time in the "all revisions" field, or forgetting to update that field after a new revision round
- Charging Step 5 rewrite time to the revision field, or revision-round edits to the rewrite field - field 2 is pre-first-upload only
- Hard-wrapping prose in submission_answer.txt, or letting an editor reflow it - the newlines survive the paste into the platform
- Finishing submission_answer.txt without a final humanizer pass over the text actually in the file, or assuming the chat-time pass covered it
- Letting the humanizer pass touch file paths, test names, commands, code examples, checkbox lines, or the handling-time numbers
- Leaving em dashes in `submission_answer.txt` on the grounds that they are the issue-block and sub-answer markers rather than prose. Section 5 bans them and exempts only code examples. **Use a hyphen for those markers.** The one accepted bundle, kvdex 245, has zero em dashes in its answers file. The Section 2 and Section 6 templates showed them until 2026-08-04, which is where the wrong inference came from, and they now show hyphens throughout - a bare count inside the Section 6 template fences returns 0
- **Writing a verification that filters out the thing it is supposed to catch.** The em dashes above survived a "Section 5 re-check" because the grep excluded the template markers by design, so it could never fail on them. A check built around your own conclusion confirms the conclusion. When a rule says *zero* of something, the check is a bare count with no exclusions, and any nonzero result gets shown rather than reasoned away
- Substituting a grep for the `humanizer` skill on a later editing round. The grep catches the mechanical rules (dashes, quotes, semicolons, wrapping) and none of the writing patterns (manufactured one-line closers, negative parallelism, aphorism formulas, announced candour). Both passes are required every round, in that order
- Treating submission_answer.txt as written once - every revision round edits it, so it always describes the zip currently in tasks/<name>/upload/
- Shipping a revision round without re-humanizing the answers you changed, or without re-checking the joins where new text meets already-humanized text
- Regenerating submission_answer.txt from scratch after a revision instead of editing the answers the round actually affected
- Listing workspace bookkeeping in Files Changed. That field is bundle paths only - never CLAUDE.md, INDEX.md, task.md, learning/, docs/, .cursor/rules or .claude/skills. A round that touches a bundle file no numbered finding named still has to be explained in Comments for Reviewer
- Appending a new round block to submission_answer.txt without editing the earlier blocks the round made false, so the file describes two mutually exclusive verifiers
- Heading an issue-detail block with an invented category instead of one of the seven exact platform strings, leaving the reviewer nothing to match your checkboxes against
- Running the Step 5.5 battery on `work/` instead of an extract of the built zip, so the artifact that ships was never the artifact that was measured
- Treating an Oracle Check below 3/3 as flake, or reaching for an idempotency theory on a 0/3 that arithmetic already ruled out
- Acting on a report that names test ids, line numbers, commands or instruction text that no longer match the current bundle - check freshness on those four axes before touching a file
- Deciding a blocking axis from a report whose justification was elided by the paste, or from a score remembered out of a previous session
- Working three rounds on the same failure signature because nothing was counting strikes, or shipping a third variation after two
- Deleting a swept artifact that `git ls-files` shows tracked at the base commit - exclude it from the image instead, and say so in Comments for Reviewer
- Zipping without `-y`, which follows symlinks and flattens them, or skipping the symlink-count assertion that is the only way to notice
- Scrubbing git before the zip without clearing the stash - a stash ref keeps its blobs reachable, so `gc --prune=now` never touches them and `fsck` still finds the golden file
- Re-checking the post-fix confirmation boxes from memory after a revision instead of re-verifying them against the current files
- Addressing part of a reviewer's feedback because several asks were bundled into one paragraph - split it into numbered items and answer every one, including the ones you decline
- Treating reviewer feedback as permission to cross an editing boundary (tracked source, pre-existing tests, PR scope) - explain the constraint in Comments for Reviewer instead
- Re-zipping a revision without re-running the full Phase A checklist and the whole Phase B battery against the new zip, or without redoing git hygiene immediately before the zip
- Losing the feedback text - paste it verbatim into task.md before starting, since the reviewer's notes are the list you are graded against
- Arguing with a borderline Quality Check score instead of fixing the cited defect
- Checking Send to reviewer while checks are failing without detailed explanatory comments
- Writing LLM-sounding output in the free-text answers
- Editing a `.cursor/rules/*.mdc` without making the same edit in its `.claude/skills/*/SKILL.md` twin, or the other way round
- Trusting `git gc --prune=now` without running `git fsck --unreachable` afterwards - a clean tree with no reflog can still hold dangling golden and test blobs
- Leaving a broken `refs/remotes/origin/HEAD` in the repo - `git remote` is empty so the static check passes, `for-each-ref` does not list it, and only `git fsck` catches it. `rm -rf .git/refs/remotes` is part of the cleanup
- Shipping a grader that awards reward 1.0 while the test command exited nonzero, or that records a raw exit status without gating on it. **The stock `test.sh` does exactly this**, so an untouched harness is already defective
- Making the grader fail closed with an early `infrastructure_error` exit - that reclassifies every non-compiling agent as an invalid trial and poisons the difficulty run. Gate inside the grader's success expression instead
- Adding an exit-code gate without `set -e` in the generated runner - `execution.commands` is a list and the status you get is the last command's, not the suite's
- Relying on `set -e` alone when a command is a pipeline, or assuming `test.sh`'s own `set -o pipefail` reaches the runner - `bash /tmp/run_tests.sh` is a child shell and inherits no shell options, so the gate reads the parser's status and never fires. Pass `bash -o pipefail`
- Wiring the exit-code gate without first measuring the runner's bare exit on a green tree - a runner that exits nonzero on a fully passing suite turns the gate into a failing oracle
- Acting on a Quality Check coverage finding before checking whether it describes the source PR - if it does, the instruction is over-promising and the oracle must not be touched
- Reading a PR's file list off page 1 of the GitHub API - it caps at 100, and a 198-file PR answered the opposite question on page 2
- Building a test-tree restore on git **in any form**. Three designs shipped on kvdex 245 and none worked, because the verify-time workspace is not a git repository. `git checkout -- <dir>` reads the INDEX so staging defeats it, `git checkout <sha> -- <dir>` leaves files the agent added, and both are moot when there is no repo to read. Use a create-only `tests.patch` or a base64 payload embedded in `test.sh` (Section 10.3)
- Shipping the restore payload as `tests/files/<archive>` - `tests/` accepts only `config.json`, `grade.py`, `test.sh` and `tests.patch`, and that upload is rejected at the static phase
- Choosing between the create-only patch and a full-tree payload by assuming instead of counting. Measure how many graded ids live outside the patched files. Zero means create-only; kvdex was 102 of 132 and needed the payload
- Concluding you have no evidence when your own difficulty report says `Task Instruction Sufficiency: NOT_APPLICABLE`. The harness is shared, so a sibling task's per-trial analysis is evidence about your task's environment
- Shipping a third variation of a fix that already failed on the platform twice. Two failures on a locally-verified fix means the model of the environment is wrong, so remove the dependency instead of refining the theory (`learning/diagnosing-platform-only-failures.md`)
- Simulating an agent with unstaged edits only. Stage and commit in the simulation, or the restore step looks green and fails on the platform
- Giving the graded test files the names an agent would pick for its own tests, when a verifier-only prefix costs nothing
- Treating instruction over-prescription and leakage as advisory because the prescriptiveness build check says so - the Quality Check's `criterion: Instructions` items are must-have and block on their own (`learning/quality-check-criteria.md`)
- Reading a NOP reward of 0 as proof the f2p set is genuine, when a compile failure or collection abort marks every id missing regardless
- Leaving `pass_to_pass` empty when existing tests cover the area the patch touches, or adding `allow_extra_failures` to a config.json that never had it
- Injecting graded tests into an existing public test suite under predictable names, so an agent's own test collides and kills the trial
- Writing a test that names a constraint but uses a fixture which cannot violate it (bidirectional coverage on a random-access container)
- Uploading without the hostile-delete run, or recording it as "reward dropped" without naming the test id that caught the stub - an unenforced requirement reads as coverage right up until the reviewer stubs it
- Shipping `tests/test.sh` or `solution/solve.sh` at mode 0644
- A `solve.sh` whose reverse-apply fallback counts as success, hiding a golden patch that did not apply
- Stripping the `git apply --3way` retry out of a `solve.sh` on the belief that it is the same defect. It is the prescribed third step of the sanctioned shape (Section 10.6, the "The fix" section in `learning/solve-sh-idempotency.md`) and it applies forward, so it cannot invert a tree. The bug is a reverse apply that reports success
- A `solve.sh` that deletes, renames or edits a tracked path with its own `rm`, `mv` or `sed` line instead of inside `golden.patch`. The Oracle Check still goes green and the patch no longer describes the solution
- Treating `init_state.patch` as a reverse-diff format on the strength of its name. `docs/glossary.md:38` calls it a former name for `golden.patch`, so read the diff direction before applying anything
- Leaving `[metadata] repo_license` blank or invented, or letting `repo_name`, `base_commit_sha` and `source_pr_url` drift from the repo and the PR. All four ship populated in every bundle measured here and none of them is in `docs/harbor-framework.md`, so nothing but your own check catches them
- Splitting a graded id on `::` and reading the left half as a file path. That is right for deno and pytest and wrong for gradle, cargo and ctest, and it reported all 35 of libcrux's ids as outside when 21 were. Use the Section 10.3 snippet, and treat an `UNRESOLVED` line as "not an answer yet" rather than a rounding error
- Renaming a graded test file to something the runner cannot import - a prefix has to be a legal module identifier in the target language, or every trial reports the ids missing while the file sits in the tree
- Accepting a NOP zero on a compiled-language task with no per-file subset and no symbol audit either. Say which of the two you did, and never report an audit as a run
- Shipping a Dockerfile with `apt-get upgrade`, an unpinned `pip install <pkg>`, a `pip install -e <dir>` whose target is not in `environment/repo`, or a `git+https://` on a bare branch. All four are reproducibility defects and none of them is a network problem - build-time network use is allowed
- Grading the shape of the source instead of its behaviour: `inspect.getsource`, reading a source file and asserting on substrings, or requiring a private helper name. It passes a solution that writes the right words and fails correct different code
- Shipping a golden patch whose file list does not match the source PR's, in either direction
- Padding fail_to_pass with tautologies or one contract repeated across N shapes instead of distinct behaviors
- Testing only a new helper when the PR's point is wiring that helper into the CLI, engine, or response path
- Pinning serialization accidents (object numbers, byte offsets, creation-order ids) instead of structure and values
- Claiming flexible wording in the instruction while the matcher still demands literal tokens
- Rewriting fail-open Dockerfile steps as pure hygiene - fix them where they cause a listed issue, report the rest
- Quietly reconciling `model_difficulty` with `difficulty` to satisfy a check instead of reporting the mismatch
- Showing Phase 1 findings as a pastebox first - the two checkbox lists come before it, in the platform's order
- Waiting to be asked for the difficulty answer, the senior estimate, or Comments for Reviewer instead of drafting them with everything else
- Trusting the task path pasted alongside feedback instead of identifying the task from the report's own citations - `__` renders as bold, so directory names arrive mangled and one task's path gets attached to another task's feedback
- Running gradle, maven, npm or cargo inside `work/` or `download/original/` - the caches are gitignored, so nothing warns you until `diff -rq` reports files you never touched or the zip ships the cache
- Concluding "flaky or infra" from a platform message that says so, when the failure is identical on every run - reproduce the oracle *script* twice in one container before blaming the environment
- Chasing a prescriptiveness finding that quotes a requirement a graded test asserts - that finding is asking you to break `test_faithfulness`, which blocks
- Treating a past prescriptiveness pass as settled - any later instruction edit re-runs it, and it has come back red on text unchanged since the passing round
- Diagnosing a non-reproducing platform failure by guessing - measure each hypothesis (time the cold build, read the offline cache, time the verifier) and record the dead ends so nobody repeats the sweep
