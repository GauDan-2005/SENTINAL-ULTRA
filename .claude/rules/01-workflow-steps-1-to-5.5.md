_Owner of CLAUDE.md **Section 1**, Steps 1 through 5.5. Loaded every session. Steps 6 to 11 are in `.claude/rules/02-workflow-steps-6-to-10.md`._

## 1. Submission Workflow

### Timed peer-review carve-out

When the user asks for a **peer review**, do not enter the submitter Step 1 corpus-read workflow.
Section 13 is the controlling timed workflow: it begins after bootstrap and page evidence are ready,
uses `bin/learning-query.sh --candidate` only after a concrete reviewer candidate exists, and does not
run a routine local battery. This carve-out applies only to `review_tasks/`; every submitter task still
uses Steps 1 through 5.5 exactly as written below.

When the user says "inspect", "submit", or starts a new submitter task:

### STEP 1: Read `learning/`, then scan the workspace (session start, no user input needed)

When a new task session begins, before asking for anything:

1. **Read every file in `learning/` - this is mandatory and comes first.** Start with `learning/README.md`, then read each note it indexes. These are verified findings from real platform runs, recording where the actual behaviour differs from what `docs/` and this file say. Apply them for the rest of the session without being asked. If a note contradicts this file on a matter of fact about what the platform does, the note wins and the drift gets flagged to the user
2. **Read `INDEX.md`** at the workspace root. It is the cross-task register - one row per task with its verdict, status and submission id. It tells you what is already in flight before you touch anything
3. Scan `tasks/` for the per-task folders. Each one holds everything for a single task: `task.md`, `task_details.md`, `download/`, `work/`, `upload/`, `answers/`. Ignore everything else at the root by name: the directories `.claude/`, `.cursor/`, `.git/`, `_archive/`, `bin/`, `chat_transcripts/`, `docs/`, `learning/`, `review_tasks/`, and the files `AGENTS.md`, `CLAUDE.md`, `INDEX.md`, `README.md`, `facts.yml`, `prompts.md`, `TODO.md`, `TODO_review.md`, `sample_review_page.md`, `.gitignore`. **`sample_review_page.md` is platform evidence, not drift**: it is a markdown conversion of the whole live reviewer page and it is what LEDGER L100 and L101 rest on, so it is cited by line from `.claude/rules/13-reviewer-path.md`, `.claude/rules/14-reviewer-workflow.md`, `facts.yml` and `learning/reviewer-page-carries-the-whole-submission.md`. Do not move it without repointing those
4. Reconcile `INDEX.md` against what is actually on disk. A folder under `tasks/` with no row, or a row whose status no longer matches the files, is drift - report it rather than silently fixing it
5. **Throughput rule - a hard stop, not a note.** At most **two** tasks may sit in `pending-revision` at once, or the platform blocks a new claim. Count it, do not eyeball it, and anchor the pattern to the table rows or the count comes back wrong - a bare `grep -c 'pending-revision'` also matches the status-vocabulary table and the surrounding prose. Use the form `INDEX.md` itself documents: `grep -c '^| \[.*| pending-revision |' INDEX.md`. `INDEX.md` also carries a `pending-revision: N of 2` line under its `## Active` heading, updated by the same action that changes any row's status. If the count is already 2, **refuse to start a new claim** and say which task has to be submitted or parked first. If the count is 3 or more, that is drift and it gets resolved with the user before anything else happens
6. Report what was found, then write the applicable `learning/` notes into the task's `task.md` before Step 3 begins - a chat message does not satisfy this. The section is mandatory and takes the shape below, one line per note, naming the specific thing the note predicts for THIS task and the command that will confirm or refute it. Then move to Step 1.5

```
## learning/ notes applied
| Note | What it predicts here | Command that settles it |
|---|---|---|
| unreachable-git-blobs.md | golden and patched-test blobs dangling in environment/repo/.git | git fsck --unreachable --no-progress |
| verifier-fail-open.md | stock test.sh writes reward 1.0 without reading raw_exit_code | grep -n raw_exit_code tests/test.sh |
| solve-sh-idempotency.md | reverse-apply fallback inverts the tree on the second oracle run | run solve.sh three times in one container |
```

**Writing back to `learning/`.** When something in this workspace costs real time and would cost it again - a platform check that rejected a bundle, an environment quirk, a rule whose real behaviour differs from its documented wording - add or update a note in `learning/` and index it in `learning/README.md`. Record what happened with the exact error text, why it happened, the rule to apply next time, and the date and task it came from. Do not log anything already covered by `docs/` or this file; log the gap between them and reality. **A task that closes triggers this rule on its own. See Step 11.**

### STEP 1.5: Ask the user for the task zip and the platform task data (every task, do not skip)

Ask for BOTH in a single message:

**1. The task zip.** Ask the user to drop the downloaded zip into `tasks/<Original Directory Name>/download/`, then to find the directory inside the zip that holds `instruction.md`, `task.toml`, `environment/`, `solution/` and `tests/` together and extract THAT to `tasks/<Original Directory Name>/download/original/`, so `original/` always holds those five entries at its top level. **Ask shape-independently, because the packaging varies** - `docs/harbor-framework.md` (the components list, "How your download is packaged can vary") and `docs/tasking-guide.md` quick start step 2 both say the files may sit at the zip root or inside a wrapper such as `task/` or `seed/`, and that a `runs/` logs folder may or may not be included. Whatever shape arrives, `download/original/` ends up flat. Nothing goes to the workspace root. If Step 1 already found an extracted task in that shape, ask the user to confirm it is the one to work on.

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

1. Locate the extracted task. It is `tasks/<Original Directory Name>/download/original/` with `instruction.md`, `task.toml`, `environment/`, `solution/` and `tests/` at its top level. **The download's own shape varies, and that is documented behaviour rather than a legacy quirk** - `docs/harbor-framework.md` (the components list, "How your download is packaged can vary") and `docs/tasking-guide.md` quick start step 2 both say the five entries may sit at the zip root or inside a wrapper such as `task/` or `seed/`. Bundles in this workspace also ship a `*_harborized/` directory, sometimes nested inside a `<submission_id>/` folder. The fix is the same for every wrapper: re-extract the directory that actually holds the five entries into `download/original/` so the pristine extract is always flat, never work inside the wrapper
2. Read ALL of, relative to `download/original/`:
   - `instruction.md` AND `problem_statement.md` - then `diff` them; they must be byte-identical. The current spec puts the copy at `environment/problem_statement.md`; older bundles keep it at the top level. Diff whichever one ships, and if both exist all three files must match
   - `task.toml` (schema_version, `[environment]` / `[agent]` / `[verifier]` / `[metadata]`, source URL, base commit, timeouts, network_mode per block - see Section 8 for the field limits)
   - `solution/solve.sh` and its patch (`golden.patch`). If it ships as `solution.patch` or `init_state.patch`, both are dead names for the same file - record it, read the diff direction rather than trusting the name (Section 9), and rename it to `golden.patch` on the Fixable path
   - `tests/test.sh`, `tests/tests.patch`, `config.json` (wherever it ships). Note that `tests/` accepts **only** `config.json`, `grade.py`, `test.sh` and `tests.patch` - a `tests/files/` directory is rejected by the static checker even though older layout docs list it, so if you find one it is a finding (`learning/static-checks.md`)
   - `environment/Dockerfile`
   - `runs/*/*/result.json`; `verifier/test-stdout.txt` for ALL failing trials and at least one passing trial. `runs/` is not guaranteed to be in the download (`docs/harbor-framework.md`, the components list) - when the bundle ships without it, record that there is no trial evidence rather than reasoning from trials you never read
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
9. **Diff the golden patch's file list against the PR's file list.** List the paths `solution/golden.patch` touches and compare them to the files the source PR actually changed. `docs/guidelines.md` requires the patch to contain "only what's needed to resolve the task" with no drive-by edits, and `docs/tasking-guide.md` step 2 requires no unrelated scope. A golden patch spanning far more files than the PR is a polluted oracle and a Fixable finding. **The other direction is not a finding.** A docs or changelog file the PR touched and golden omits is the normal accepted shape, measured at **7 of 8** archived goldens ship no `.md` or docs file at all, accepted kvdex 245 included at 38 golden files against a 198-file PR, and the eighth is AltBeacon 1177, which ships its `CHANGELOG.md` and was accepted too, so neither direction is a finding (LEDGER L59). **Compare hunk bodies, not just file lists.** A second PR welded into golden can put extra hunks inside files the PR does legitimately touch, where a file-list diff cannot see them: on elfuse 162 that hid 3 of 11 extra hunks. The per-file changed-line comparison is in `learning/source-pr-cross-check.md`. Non-test files only - test changes belong in `tests.patch`
10. **Read the grader in `tests/test.sh` for fail-open behavior.** Trace how the reward is decided. If it parses stdout for test names, check whether it also gates on the test command's exit status. `docs/guidelines.md` states the invariant plainly - "the exit code should match the reward it writes" - and a parse-only grader breaks it: a compile failure, timeout, crash or partial run can leave the expected lines in the log and still award `1.0`. See `learning/verifier-fail-open.md`
11. **If the bundle says the verifier cannot build, run or even load part of the software, measure it before believing it.** Three tasks have made this claim and all three were wrong, so treat it as a measurement rather than a premise. The forms it takes are the program not running on this host, a requirement needing a live service, and a module the test runner cannot import (`learning/bundler-resolved-modules-are-gradeable.md`). For the import case the ladder is shorter than the cross-compile one: attempt the load and read the error, fix that one thing, repeat. On a bundler-resolved renderer module that was four steps, none of them TypeScript, and the fix was a `registerHooks` resolve hook doing the two jobs the app's own bundler does, extension resolution and a declared json import attribute. Stub the environment, never the module under test. The tell is a graded suite that asserts on source text, or a stated requirement left ungraded, with the reason written into a docstring or a comment. Split the claim in two, because it is almost always true of the *program* and false of its *translation units*: a macOS Hypervisor.framework binary genuinely cannot run on an `ubuntu:24.04` verifier, and its syscall handlers compiled and ran there behind a thirty-line stand-in for the framework header. Run the five-step ladder in `learning/platform-locked-repos-are-still-testable.md` - syntax-check one unit behind a stand-in header, then every unit the feature touches, then **`gcc -c` rather than `-fsyntax-only`** because one unguarded target instruction passes the second and fails the first, then cross-compile for the repo's real arch and run something trivial under `qemu-user-static`, then link. Twenty minutes, and it decides whether the task is a rewrite or an argument. **`docs/` is silent on repositories targeting a platform the verifier is not**, so a Not Fixable verdict on that ground is an inference, not a rule (Section 3)
12. Skim `environment/repo/` as needed based on instruction scope

**Cross-check the pasted platform data (from Step 1.5) against the extracted task:**

- Original Directory Name ↔ the actual extracted directory name
- Category ↔ task.toml `category` / `task_type` ↔ the source PR type
- Difficulty ↔ task.toml `difficulty` (the `model_difficulty` field is separate and may differ - flag it only if it clashes badly with the runs/ results)
- Task Tags ↔ task.toml `tags` (3–6 relevant tags)
- Languages ↔ task.toml `coding_language` / `language` ↔ the actual code in `environment/repo/`
- Metadata block ↔ the `task.toml` file on disk - diff them ("same as file" means use the file)
- Source URL resolves to the right repo and PR; base commit ↔ `git rev-parse HEAD` (on mismatch HEAD wins - realign task.toml per the git rules)
- `[metadata] repo_license` holds a real SPDX id and matches the licence file in `environment/repo`; `repo_name`, `base_commit_sha` and `source_pr_url` agree with the repo and the PR. These four are undocumented in `docs/harbor-framework.md` and populated in every bundle measured here (Section 8)
- Every `task.toml` limit in Section 8 holds: cpus, memory_mb, storage_mb, gpus = 0, build/agent/verifier timeouts, and `network_mode` present in all three blocks with the right value. Missing or stripped `network_mode` fields are a finding, and so is a `[verifier] timeout_sec` smaller than `tests/config.json` `execution.timeout_sec` - it arrives that way in 10 of 11 bundles measured here and `docs/reviewer-rubric.md:101` makes it a Minor violation, so it maps to Fixable trigger 11 and gets fixed rather than noted
- Legacy fields (`pass_at_k_*`, `expert_time_estimate_min`, `junior_time_estimate_min`, `tags`, `coding_language`, `model_difficulty`) were dropped from the current schema but still appear on older tasks. Cross-check them when present - `pass_at_k_*` against the actual pass rates in `runs/*/*/result.json`, `expert_time_estimate_min` feeds the senior-engineer estimate answer - and never add them to a task that lacks them

**On mismatch:** record it as a finding. Fix task.toml where the editing rules allow (base-commit realignment to HEAD, strictly-metadata cleanup); flag anything unresolved in Comments for Reviewer.

### STEP 3: Independent analysis

Run the four core principles (Solvability, Clarity & No Leakage, Verifiability, Authenticity - full lists in sentinel-task-check) plus a scan for the six auto-REMOVE test patterns (Section 4 below). For EVERY issue record: file:line, what is wrong, which Fixable trigger or Not Fixable condition it maps to (Section 3), and the minimal fix. Include the Step 2 cross-check results - platform-vs-file metadata mismatches are findings too.

Do NOT re-judge difficulty from scratch - arriving tasks have already passed the difficulty checks. Difficulty only re-enters if your fixes lower it, in which case the platform evals bounce the task back (see sentinel-difficulty-scope). For reference, the bar is a pass@k threshold: a frontier model solves a Medium task in at most 4 of 8 attempts and a Hard task in at most 2 of 8 - compare it against the trial outcomes in `runs/` when a difficulty claim needs grounding.

### STEP 4: Decide the verdict

Pick exactly one of **Valid as-is / Fixable / Invalid-Not Fixable** using Section 3 criteria.

The analysis question appears TWICE in the platform and both are required - the two answers must be identical. The [For internal use] Validity field must also match, mapped as: Fixable → Fixable, Invalid/Not Fixable → Invalid, Valid as-is → Valid-as-is.

**A fourth value can appear on the analysis question and you never put it there.** As of 2026-08-14 the platform reaches a difficulty verdict of its own: once four difficulty checks have run on a task without passing, it writes **Invalid Difficulty** into the validity question itself and routes the task to review as it stands (`docs/faq.md`, "Difficulty checks are now capped"). The FAQ said nothing about what the separate [For internal use] Validity field shows when that happens; a capture of the live page on 2026-08-18 settles it, because **Invalid Difficulty is an option in that radio too** (`sample_review_page.md:79`, beside `:69` and `:93` for the analysis question and its duplicate). So all three controls carry the same four values and the pairing rule below is unchanged. That changes nothing about the choice you make here, which is still exactly one of the three above on the Section 3 criteria. What it changes is what happens after the budget runs out, and Section 3 owns that, along with the unchanged rule that you do not reach Unfixable - Difficulty yourself off a repeated `FAIL EASY`. Step 7 carries the budget itself, because the gate is where a check gets spent.

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
- `tests/tests.patch` is a different thing and it MAY edit pre-existing test files. It is applied at verify time on top of the clean tree, so an added function inside an existing test file is legitimate: kvdex 245, the longest-standing accepted reference, edits 44 pre-existing test files that way. Prefer a separate prefixed file for the graded tests (Section 10.3) because it removes the agent-collision surface, not because in-place edits are banned
- Editable: `instruction.md` (+ its exact copy `problem_statement.md`), tests (test.sh, tests.patch, config.json - those three and `grade.py` are the ONLY entries `tests/` may contain, verified by a rejected upload), oracle (solve.sh + patch), the LISTED Dockerfile fixes only, task.toml metadata and limits, git metadata in the repo
- Oracle edits only in two cases: the oracle does not implement the instruction, or you are expanding PR scope to raise difficulty. Expansion = original PR + additions. Never reduce or replace the PR
- If any fix would require reducing or replacing PR behavior → STOP and reclassify as Invalid/Not Fixable

Work in this order: git hygiene → instruction rewrite → sync problem_statement.md → oracle (if an allowed case applies) → tests (regenerate tests.patch against clean HEAD, register new test ids in `fail_to_pass`) → allowed Dockerfile fixes → task.toml sanity (Section 8) → pre-upload checklist.

Write tests to clear the Quality Check bar (Section 4): no silent skips, no fail-open, invoke the actual CLI/entry point when one is asked for, pair every existence check with a content assertion, enumerate expected items from the instruction/environment (never from agent output), no overreach beyond stated requirements. Then apply Section 10 - the defects that pass every eval and still come back from the reviewer.

**Regenerating `tests.patch`** when it does not apply: from `environment/repo` at the base commit, confirm the target test files are in their original state (they must NOT already contain the new f2p tests - the patch is what adds them), apply the test additions by hand, then `git add -A && git diff --cached -- <test paths> > ../../tests/tests.patch` and `git checkout .` to restore the repo to base. Re-verify with `git apply --check`. Common traps: the repo copy already includes the new tests (the patch re-adds them and conflicts), or the patch touches a non-test file such as `CMakeLists.txt` that has since changed.

**The five Major Pillars, and where this checklist answers each one.** `docs/reviewer-rubric.md:9` makes the rubric the technical bar every task must clear to be accepted, so it is a submitter document and not only a reviewer's reading list, and `:35` makes one confirmed pillar violation Needs Revision whatever else the bundle gets right. All five are answerable before the zip exists. Rows follow the rubric's own pillar numbering, with the share of reviewer comments it prints for each. `:35` claims that numbering is ordered by reviewer-flag frequency and it is not, because the printed figures run 51, 45, 21, 41, 31, so read the percentage rather than the row position when deciding what is most likely to bounce a bundle:

| Pillar | What answers it here |
|---|---|
| 1. Oracle and golden correctness, 51% | Phase B Run 2 for an oracle that fails its own tests, Run 1 for a NOP that passes, Phase A items 10 and 15 for a golden-only path or symbol the instruction never states, Step 2 item 9 for golden against the PR |
| 2. `fail_to_pass` and `pass_to_pass` integrity, 45% | Step 2 item 3 for the count and the 10 to 20 range, Phase A item 9 for outcome-based tests, the Run 1 NOP audit for whether each declared id is genuinely fail-to-pass, and the declared-against-executed read in Run 2 |
| 3. No leakage and not reward-hackable, 21% | Phase A items 4 and 5 for solution material readable from an agent path, and Phase B Run 4, the gaming probe, for whether the suite can be passed by editing what grades it |
| 4. Airgapped verifier and network integrity, 41% | Phase A item 6 for the declared `network_mode` values, and every Phase B run executing with `--network none` for the half that has to be measured |
| 5. Git state and repo cleanliness, 31% | Step 2 item 4, Phase A item 4, then the re-zip scrub. The rubric calls it an early gate, "Check this before assessing content" (`:95`), which is where Step 2 item 4 already sits |

The eleven Secondary Requirements are Minor and they accumulate, and five of them is Needs Revision on its own (`docs/reviewer-rubric.md:99`), so the small stuff is not free. Most have an owner here already: pinning is Phase A item 3, the timeout pair is Phase A item 6, an ungraded instructed behaviour is what the hostile-delete gate is for, over-prescription and a templated instruction are the Quality Check work in Section 4, a flaky test and a missing regression test are its test-writing checklist, and a Files Changed count that no longer matches the diff is the re-derivation in Step 10.

**Pre-upload checklist - these are the Phase A gates. Run all of it on `work/` before the zip is built and before the Step 5.5 battery runs:**

1. `tests.patch` applies cleanly to `environment/repo` at the base commit (`git apply --check`)
2. The shipped tree is clean: `git -C environment/repo status --porcelain` prints nothing and no test file differs from base. `tests.patch` editing a pre-existing test file is fine and expected (Step 2 item 6); a pre-existing test file left edited **in the tree** is the defect
3. `docker build environment/` succeeds and is reproducible. The build MAY use the network; run `apt-get update` before installs, use packages that exist in the base image distro, pin the base image to a concrete tag, and bake test dependencies into the image instead of fetching them at test time. Run time is what stays restricted - the agent reaches only the model gateway and the verifier is airgapped. Four **reproducibility** checks on top of the base-image tag, none of them a network restriction:
   - `grep -nE 'apt-get +(dist-)?upgrade|apk upgrade|yum upgrade' environment/Dockerfile` is empty. An upgrade step re-resolves the whole package set on whatever day the image is built, so the difficulty run and the oracle run can get different toolchains
   - every bare `pip install <pkg>` carries `==`, and the npm, gem and cargo equivalents carry an explicit version. `grep -nE 'pip3? install' environment/Dockerfile` then read each line
   - every `pip install -e <dir>` target exists inside `environment/repo`. A path that does not resolve fails at build time on the platform and passes locally when a stale directory happens to be lying around
   - any `git+https://` requirement is pinned to a tag or a sha, never a bare branch. Fetching from git at build time is allowed; fetching a moving branch is what makes the build unreproducible
4. Git hygiene clean per the checklist in sentinel-task-fixing (HEAD == base commit, no refs past HEAD, no remotes, no `filter.*`, clean tree, no reflog, `.git` under 100 MB) **and `git fsck --unreachable --no-progress` prints nothing**. One line that checklist does not carry: `git -C environment/repo worktree list` prints the shipped repo and nothing else, and `environment/repo/.git/worktrees` does not exist. `docs/reviewer-rubric.md:89-95` names a stray worktree next to remotes and stash inside a Major early gate, and nothing else here looks for one, because a linked worktree keeps its own HEAD so its commits stay reachable and `fsck --unreachable` has nothing to say about them
5. Stray-artifact sweep is empty, no solution material readable from agent paths, `problem_statement.md` re-copied from `instruction.md`, and `solution/solution.patch` renamed to `golden.patch` if the bundle shipped that name
6. `task.toml` sanity per Section 8 - limits, `gpus = 0`, `network_mode` in all three blocks, accurate `category` / `difficulty_explanation` / source URL, `[environment] os` present, and `[metadata] repo_license` / `repo_name` / `base_commit_sha` / `source_pr_url` populated and correct. Remove `network_mode = "none"` from `docker_compose.yaml` if present. **And `[verifier] timeout_sec` is not smaller than `tests/config.json` `execution.timeout_sec`** - 10 of the 11 bundles measured here arrive at `300` against `1800`, so it is a defect you inherit rather than one you make, and `docs/reviewer-rubric.md:101` makes it a Minor violation to name by its two numbers:

    ```bash
    python3 -c "
    import json,re
    t=open('task.toml').read()
    v=float(re.search(r'\[verifier\][\s\S]*?timeout_sec\s*=\s*([\d.]+)',t).group(1))
    e=json.load(open('tests/config.json'))['execution']['timeout_sec']
    print('verifier',v,'execution',e,'ok' if v>=e else 'FIX: the outer budget must not be the smaller')"
    ```

    Pass condition: `[verifier] timeout_sec` is at or above `execution.timeout_sec`. The verifier value is the platform's whole-step budget and the execution value wraps only the test command, so a smaller outer budget kills a slow but correct run before the inner one fires. Decide from the measured oracle wall time, then either raise the verifier value up to the documented 1800 ceiling or bring `execution.timeout_sec` under it. Both routes were accepted: elfuse 162 shipped 1200 against 900, and statrs 315 kept the verifier at 300 and dropped execution to 240
7. **Script modes.** `tests/test.sh` and `solution/solve.sh` are executable (`0755`). A `0644` verifier entrypoint is the "non-executable scripts" row of the allowed-fix table in `docs/guidelines.md` and fails at run time, not at build time, so nothing local catches it for you. Check the mode in the extracted zip, not only the working copy
8. **Grader fails closed.** `tests/test.sh` writes reward `1.0` only when the test command also exited zero (Section 10). A parse-only grader is the `Fail-open` auto-REMOVE pattern wearing a different hat
9. **No source-shape grading.** `grep -rnE 'getsource|getsourcelines|inspect\.|readFileSync|read_text\(|Files\.readString|open\(.*\.(py|ts|java|rs|kt)' tests/` turns up nothing that reads a source file to assert on its text, and no assertion greps for a private helper name. Pass condition: the graded tests call the public API and assert on behaviour. A test that scans source text passes for a solution that writes the right words and fails one that writes correct different code, which is the `Don't` at the top of the Section 4 test-writing checklist and a judge finding when it ships
10. **Instruction and tests name the same things.** For every public identifier `instruction.md` names as a deliverable, confirm it appears in both `tests/tests.patch` and `solution/golden.patch`. Pass condition: no name in the instruction that nothing grades, and no graded name the instruction never states. A name that is in the tests and not the instruction is a `test_faithfulness` finding; one that is in the instruction and not the patch is the `Task Instruction Sufficiency: FAIL` signature from the other side (Section 4).

    **Read the HELPERS the graded tests call as part of this, not only the assertions.** A barrier, a `waitFor`, a fixture builder or a coordinate finder can require a behaviour no assertion mentions, and for a failing implementation that precondition grades exactly like an assertion. hulak 118 shipped a barrier that waited for an earlier region to **disappear**, which silently required a scan semantic the instruction never stated, so an implementation satisfying every written word would have failed most of the graded set. It was found by auditing, not by any report, and it is the same defect class an agentic judge blocks on. The remedy is one of two things and never a third: **state the rule in the instruction, or stop depending on it** (`learning/non-derivable-private-names.md`, LEDGER L38).

    **And run the identifier audit over every graded file, every round, not only the round a report names one in.** An audit an earlier round invented is a standing audit (LEDGER L83):

    ```bash
    # for every identifier the graded tests touch:
    git -C environment/repo grep -c -- "<name>" HEAD -- "<glob>"   # empty means the symbol is new
    grep -c -- "<name>" instruction.md                              # 0 means it is unstated
    #   absent at base AND unstated  ->  overreach, and by round 2 it is usually yours
    ```
11. **No comment that contradicts its own assertion.** For every graded assertion, read the comment above it and ask whether the two say the same thing. `grep -n -B2 'assert' tests/tests.patch` and skim. Pass condition: no block where the prose states an intent the assertion does not check. This is the cheapest real defect in the list and it has shipped twice here: a Mann-Whitney block commented "Exchanging the two samples has to move the small tail to the other side" then asserted the tail stayed put, and the oracle's own bug made it pass. A peer reviewer caught it. The comment is what you meant; the assertion is what you wrote; when they disagree the assertion is usually wrong and the oracle is usually why it passed anyway (`learning/oracle-bug-vs-pr-scope.md`)
12. **No unguarded bashisms.** `grep -n '\[\[\|BASH_SOURCE\|\${.*\[@\]}\|<(' solution/solve.sh tests/test.sh`. Pass condition: every hit sits in a script whose shebang is `#!/usr/bin/env bash` or `#!/bin/bash`, or which re-execs itself under bash. A `#!/bin/sh` script full of `[[` runs fine on this machine, where `/bin/sh` is bash or a bash-compatible shell, and dies inside an image whose `/bin/sh` is dash or ash. That failure surfaces as `DownloadVerifierDirError` or a missing verifier output, never as a clear message
13. **Hostile-delete gate** - not here. It needs a built image and a passing oracle, so it runs as Run 3 of the four Step 5.5 Phase B runs against the extracted zip. See Step 5.5
14. **The instruction does not ask the agent to touch a path `tests.patch` writes to.** For every target of the patch, check whether `instruction.md` names it:

    ```bash
    sed -n 's|^+++ b/||p' tests/tests.patch | while IFS= read -r p; do
      for n in "$p" "$(basename "$p")"; do
        if grep -Fq "$n" instruction.md; then echo "COLLISION RISK: instruction.md names $n"; fi
      done
    done
    ```

    Pass condition: no hit where the instruction asks the agent to **write** to a path the patch also writes to. Naming a public artifact that happens to live under `tests/` is fine; ordering an edit to one is not. An instruction that does order it makes every compliant agent an invalid trial, the three apply routes in `test.sh` all fail into `infrastructure_error`, and the oracle never reproduces it because the golden patch does not follow instructions. Delete the request from the instruction and keep the restore step anyway (`learning/tests-patch-vs-agent-edits.md`)
15. **No graded test reaches the deliverable by its file path.** List the files `golden.patch` **creates** - the paths carrying a `new file mode` line, not every path it touches, because a path that already exists in the base tree is derivable under `docs/guidelines.md:155` - then check whether any graded test names one of them in an `#include`, `import`, `require` or `use`. **Match by path suffix**, because an import resolves against a source root (`include/`, `src/`, `lib/`) and not against the repo root:

    ```bash
    awk '/^diff --git/{f=$4; sub(/^b\//,"",f)} /^new file mode/{print f}' solution/golden.patch |
    while IFS= read -r p; do
      s="$p"
      while [ -n "$s" ]; do
        if grep -Fq "$s" tests/tests.patch; then
          printf 'PATH PINNED: golden creates %s, tests.patch names it as "%s"\n' "$p" "$s"
          grep -Fq "$s" instruction.md \
            && echo '  instruction.md states it literally' \
            || echo '  instruction.md does NOT state it literally - go read the instruction'
          break
        fi
        case "$s" in */*) s="${s#*/}";; *) s="";; esac
      done
    done
    ```

    **This grep is a first pass, never the verdict.** A path can be derivable without appearing as a literal: kvdex 245, the accepted reference bundle, fires six times here, and its instruction states the layout compositionally at `instruction.md:23` ("Serialization moves into a new `src/ext/encoding` module tree. Each of the three encoders lives in its own directory with a `mod.ts` barrel"), which makes `src/ext/encoding/v8/mod.ts` derivable under `docs/guidelines.md:157` without ever naming it. The suffix walk also matches a bare basename, so `utils.ts` will hit on almost anything. Read the instruction for every path it prints.

    Pass condition: for every created path a graded test names, `instruction.md` makes the location derivable, either literally or as a stated layout rule. `docs/guidelines.md:149-159` lists a new module or file name among the names that must be derivable, and a path the agent has to invent is not one. The cost is not a lost assertion, it is the whole translation unit: a correct cista 172 solution placed one directory away scored **4 of 21**. Fix it by routing the graded test through a public entry point the instruction already names. **The oracle cannot catch this for you**, because `golden.patch` puts the file exactly where the test expects, so a green Oracle Check is not evidence. The deciding test is behavioural - move every created file somewhere else the instruction also permits and re-run the verifier, and the reward must not move (`learning/graded-tests-that-import-the-deliverable.md`, Section 10.13)
16. **Every behaviour sentence added to `instruction.md` this round has an assertion that would fail without it.** Diff the instruction against the previous round and read only the added prose:

    ```bash
    diff <(git show HEAD:instruction.md 2>/dev/null || cat ../download/original/instruction.md) instruction.md | grep '^>'
    ```

    Pass condition: for each added sentence that describes behaviour, you can name the graded assertion that fails if the behaviour is removed. If you cannot, either add the assertion in this round or delete the sentence. **This is a gate rather than a note because the round that derived the rule was measurably not protected by it** - android-beacon 1177 wrote the coverage-debt finding in round 7 and, in the same round, added a scan-strategy default to the field table with nothing testing it, which came back as the next round's coverage finding (`learning/quality-check-criteria.md`). A narrowing that states a behaviour is a new requirement, and the coverage axis grades stated requirements.

17. **Every structural requirement is graded by mutation, not only by instance.** If `instruction.md` says a thing is defined exactly once, or that adding one entry is all it takes, or that a layer derives from a shared definition, then a suite grading each existing instance does not cover it. Add an entry that exists nowhere else, drop the consumers from the module cache, reload, and require them to have followed. Pass condition: an implementation that declares the shared definition and hand-writes the instances beside it FAILS. Measured on openwhispr 1002, where exactly that implementation scored 13 of 13 before this check existed and fails precisely the two derivation ids after (Section 10.14)

18. Full local dry run - that is Step 5.5 Phase B

**Re-zip rule (run only after the fixes and the Phase A pre-upload checklist pass - the zip is what the Step 5.5 Phase B battery then runs against):**

1. **Re-do git hygiene FIRST, immediately before zipping.** Checklist item 4 above is not enough on its own: regenerating `tests.patch` and running the local checks both use git inside `environment/repo`, and `logallrefupdates = true` recreates `.git/logs` (plus `ORIG_HEAD` / `FETCH_HEAD`) every time. A reflog fails the platform's `git: no reflog` static check and leaks your git identity. Run the full scrub, including the stash - a stash ref keeps its blobs reachable, so `gc` will never prune them and `--prune=now` alone leaves them behind:

   ```bash
   git stash clear && rm -f .git/refs/stash
   git worktree prune
   git reflog expire --expire=now --expire-unreachable=now --all
   git gc --prune=now
   rm -rf .git/logs .git/ORIG_HEAD .git/FETCH_HEAD .git/refs/remotes .git/worktrees
   ```

   **Then write the loose ref back, as the last git operation.** `git gc` packs the refs away and leaves
   `.git/refs/heads/` an **empty directory**. Git itself is satisfied by `packed-refs`, so every local check
   still passes, and the bundle silently comes to depend on empty directory entries surviving the zip round
   trip - which they do not, in every tool that unpacks one. The seed ships a real 41-byte
   `refs/heads/<branch>`, so match it. Compute into a variable first, because redirecting into the file
   being read truncates it and leaves the literal string `HEAD` in the ref (Section 11):

   ```bash
   SHA=$(git rev-parse HEAD)
   BRANCH=$(git symbolic-ref --short HEAD)
   mkdir -p ".git/refs/heads/$(dirname "$BRANCH")"
   printf '%s\n' "$SHA" > ".git/refs/heads/$BRANCH"
   [ "$(stat -c%s ".git/refs/heads/$BRANCH")" -eq 41 ] || { echo "LOOSE REF WRONG SIZE"; exit 1; }
   ```

   Assert the 41 bytes. That is 40 hex plus a newline and it is the size the seed ships, so it doubles as a
   check that the right thing landed. A peer reviewer on android-beacon 1177 reported the shipped repo was
   not a repository at all because of this (`learning/dirty-repo-and-symlinks.md`).

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

- **Phase A - cheap gates on `work/`.** All 17 items of the pre-upload checklist above: patch applies, shipped tree clean, image builds and is pinned, git hygiene clean and `fsck` silent, stray sweep empty, task.toml sane, script modes `0755`, grader fails closed, and the four mechanical greps (no source-shape grading, instruction and tests naming the same things, no unguarded bashisms, no graded test pinning a path `golden.patch` creates). Then build the zip with the Step 5 re-zip rule
- **Phase B - the four required runs, against the EXTRACTED ZIP.** Extract the zip to the scratchpad, build the image from that extract, and run NOP, oracle, the hostile-delete gate and the gaming probe there, each on its own fresh extract and every one of them with the network off. The fourth run asks a different question from the third: not whether a broken solution fails a test, but whether the suite can be passed by editing what grades it

**Why the zip and not `work/`.** The artifact that ships has to be the artifact that was measured. A battery run on `work/` measures a tree that no longer exists once `zip` has followed a symlink, dropped a directory entry or lost a mode bit - the libcrux task burned a whole re-verification session on exactly that gap. **Any edit after Phase B voids Phase B**: a fresh zip and a fresh battery, no exceptions and no "it was only the instruction".

**Phase B setup - never run inside the working copy** (solve.sh and test.sh mutate the tree):

1. A run directory in the session scratchpad (ignored by Step 1, deleted after, never zipped)
2. Extract the built zip four times, once per run: `unzip -q "tasks/<Original Directory Name>/upload/<Original Directory Name>.zip" -d "<scratchpad>/run-nop"`, and the same into `<scratchpad>/run-oracle`, `<scratchpad>/run-hostile` and `<scratchpad>/run-gaming`. Copying from `work/` instead is the defect this phase exists to catch
3. Build the image from the extracted `environment/Dockerfile`, not from `work/environment/`
4. The shipped scripts may assume container paths (`/workspace/repo`, `/tests`, `/logs/verifier`) - recreate those paths with directories or symlinks pointing into the disposable copy. NEVER edit the scripts just to make them run locally

**Execution environment, in order of preference:**

- Harbor installed → run the checks through Harbor as usual
- Docker available - `docker build` the extracted `environment/Dockerfile`, then run every check inside the container with `--network none`, against the disposable copies. The flag is not housekeeping. `docs/reviewer-rubric.md:79` makes "tests pass with networking disabled" the Meets line of a Major pillar flagged in 41% of reviewer comments, and a graded step that quietly reaches a host passes every run you make with the network up and fails inside the real verifier. `learning/local-runs.md:80-107` carries the full invocation with the `--cpus` and `--memory` limits `task.toml` declares, and `learning/cmake-reconfigure-needs-network.md` is the measured case, where applying `tests.patch` re-ran a CMake configure that tried to git-update a dependency and no graded test ran at all
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

**Run the whole cycle three times in one container, because the platform does.** The Oracle Check runs the golden solution three times and the pass bar is **3/3** (Section 4). The cycle is `solve.sh` **then `test.sh`**, three times, and all three rewards come from the combined cycle. Runs two and three execute against the already-patched tree, which is where a non-idempotent script inverts its own fix. Record all three rewards for Comments for Reviewer. A pass on run one followed by a failure on run two is exactly the `1/3` signature - do not ship it and call it green.

**`solve.sh` three times is a different, weaker check and must never be reported as an oracle result.** It exercises the oracle *script*, which is the `solve-sh-idempotency.md` defect. The second mechanism with the identical `1/3` signature sits one file over, in `test.sh`, which applies `tests.patch` on every invocation: with no restore step, the second apply lands on a tree that already carries the patch and returns `infrastructure_error: tests.patch did not apply`. Measured on mithril.js 2021, where `solve.sh` is the correct reverse-**check** shape and replays 3 of 3 while the real protocol returns **1 of 3**, and independently on cista 172 (`learning/stock-bundle-defect-baseline.md`, defect 6, "it is what makes run 2 of the oracle report `tests.patch did not apply`"). So a missing restore is an Oracle Check defect and not only the agent-collision defect Section 10.3 treats it as. When a platform Oracle Check comes back below 3/3, check both mechanisms (`learning/oracle-protocol-is-solve-then-verify.md`).

**Read the declared set against what the runner actually executed, off that same oracle report.** `docs/reviewer-rubric.md:53` sets the standard as the declared `fail_to_pass` and `pass_to_pass` lists matching what the verifier actually grades, and `:59` makes "a static list-length check passes while the true graded count differs materially" a Needs Revision trigger on a Major pillar. Counting the declared list is not that check, and a green oracle is not either: a declared id the runner never collects lands in `missing_required` and forces reward 0, so the oracle only ever proves the declared set is a subset of what ran and passed. Put the report's result total next to `len(fail_to_pass) + len(pass_to_pass)`. A gap is not automatically a defect, because the accepted kvdex 245 declares 132 graded ids and its runner reports 152 passed with 2 ignored (`learning/accepted-bundle-reference.md:78`). What makes it a finding is materiality: a suite executing far more cases than the two lists name is graded largely through the `unexpected` set, which `test.sh` builds only from FAILED and ERROR results, so undeclared cases gate the reward while nothing declares them. Write both figures into `task.md` and name them in Comments for Reviewer.

**Run 3 - Hostile-delete gate (reward must DROP to 0.0):** on the `run-hostile` copy, apply the oracle, then stub or delete one requirement the instruction actually states, and re-run the verifier. The Quality Check coverage axis is scored on this exact property - "a broken or stub solution must fail at least one test" (`docs/tasking-guide.md`). Pick the requirement you are least sure is tested, not the easiest one.

**Name the test that caught it.** The record has to read "stubbed X, `<test id>` failed, reward 0.0", not "reward dropped". A reward that drops for some other reason (a compile break introduced by the stub) proves nothing about coverage, and the test id is what separates the two.

**Run 4 - Gaming probe (reward must STAY 0.0).** It asks a different question from Run 3. The delete gate asks whether a broken solution fails a test. This one asks whether a pass can be bought by editing the thing that grades you, which is `docs/reviewer-rubric.md:71` word for word, "the tests can be satisfied by editing them rather than solving the task", and a Major on its own. On the `run-gaming` copy, leave the solution unapplied and edit the test infrastructure the graded tests call but `tests.patch` never creates: the assertion library, the fixture or DOM helpers, the harness the specs import. The reward must stay `0.0`. Use `bin/hostile-probe.sh` rather than a hand-rolled `sed`, because a probe that cannot prove its edit landed measured nothing (Section 10.11, and Section 12.6 for the two wrong conclusions one produced). Enumerate the candidate paths by running each one, never by reading the import lines, because all three of mithril's reached reward 1.0 and only one had been measured. On a compiled language the unapplied form is not available, since the graded units name symbols the base tree does not have and the compile dies before any assertion runs: apply golden, break one stated requirement in a way that still compiles, then neuter the assertion layer, and read that against the same break without the neuter.

**If any of the four runs FAILS, the gaming probe included:** go back to Step 5, resolve the issue in the working copy (`tasks/<Original Directory Name>/work/`), rebuild the zip with the re-zip rule, and re-run the WHOLE battery from fresh extracts. Loop fix, re-zip, re-check until the NOP fails as expected, the oracle passes 3/3, the hostile run drops to `0.0` naming its test, and the gaming probe leaves the reward at `0.0`. No answers are written until then.

**Record for the answers:** all three oracle rewards, the NOP reward and the list of tests that failed in it, the hostile-delete test id, the gaming probe's reward and the exact file it edited, the declared id count against the count the runner actually executed, and total runtime vs the verifier timeout - these go into Comments for Reviewer.

**After the battery passes - strict order, never deviate:**

1. Delete the `<scratchpad>/run-*` disposable copies
2. Confirm the zip in `tasks/<Original Directory Name>/upload/` is still the exact one the battery ran against - nothing in `work/` may have been touched since it was built. `find tasks/<name>/work -newer tasks/<name>/upload/<name>.zip` must print nothing. If it prints only `environment/repo/.git`, that is a directory mtime from a git read and not an edit - prove it with `diff -rq` against a fresh extract, then rebuild rather than re-run the battery (Step 7 condition 7, LEDGER L82). **Do the git reads before the zip**, and the gate stays clean on the first attempt
3. Only then → move on to the answers (Steps 6–9)

The Fixable sequence is always: fixes → Phase A gates → zip → Phase B battery → resolve failures, re-zip, re-run the battery → answers. Never run the battery on `work/`. Never write answers before the battery passes against the zip that will actually be uploaded.
