# Project Sentinel 2.0 - Claude Code Rules (Submitter Mode)

This workspace - the `SENTINAL-ULTRA` folder opened in Cursor (WSL: Ubuntu-22.04, ext4) - is used for **Project Sentinel 2.0** task submissions. Every path in this file is relative to the workspace root. **Nothing is ever extracted into the workspace root.** Each task lives in one folder under `tasks/<Original Directory Name>/`: the downloaded zip goes in `download/`, the directory inside it that holds `instruction.md`, `task.toml`, `environment/`, `solution/` and `tests/` together is extracted to `download/original/` as the pristine never-edited reference, and every edit happens in `work/`. **Find that directory by its contents, not by its name** - `docs/harbor-framework.md` says the download's packaging varies, so those files may sit at the zip root or inside a wrapper such as `task/` or `seed/`, and a `runs/` folder may or may not be there. However the zip arrives, `download/original/` always ends up flat, and the zip you upload back is always flat too. Claude acts as the **submitter**: inspect the task, decide the verdict (**Valid as-is / Fixable / Invalid-Not Fixable**), apply corrections when Fixable, and produce every answer the submitter form asks for.

**Peer review is out of scope for this workspace.** This file, the companion rules and the templates cover the submitter side only. The official reviewer form lives at `docs/tasking-guide.md:345-459` and is there for reference - to write submissions that survive it, not to fill it in. If review is ever assigned, add a `reviews/<task>/` sibling to `tasks/` with the same folder discipline, a Section 6 Path D `review_answer.txt` template built from `docs/tasking-guide.md:401-459`, and a fourth rule plus skill twin pair.
**Rule files - `.claude/rules/`.** The eleven numbered sections this file used to carry inline now live one-per-file in `.claude/rules/`. They are not optional reading and they are not loaded on demand: every `.md` file in that directory with no `paths` frontmatter is loaded into context at the start of every session, at the same priority as this file. Nothing was cut in the move, so a rule that used to be in Section N is now in the file the routing table below names, under the same `## N.` heading and with the same wording. A cross-reference anywhere in this workspace that says "Section 8" still means Section 8 - look it up in the table. **When this file and a rule file disagree, the rule file wins**, because it holds the full text and this one holds the summary.

**Companion rules** (full detail lives there; this file orchestrates). Each one exists twice - as a Cursor rule and as a Claude Code skill with identical content. Cursor loads the `.mdc`, Claude Code loads the `SKILL.md`. **Any edit to one must be made to its twin in the same pass.**

| Rules                                                                                             | Cursor                                        | Claude Code skill           |
| ------------------------------------------------------------------------------------------------- | --------------------------------------------- | --------------------------- |
| Verdict criteria, the four core principles, per-principle check lists                             | `.cursor/rules/sentinel-task-check.mdc`       | `sentinel-task-check`       |
| How to execute edits on a Fixable task, allowed Dockerfile fixes, task.toml, git cleanup, zipping | `.cursor/rules/sentinel-task-fixing.mdc`      | `sentinel-task-fixing`      |
| Difficulty handling and PR scope rules                                                            | `.cursor/rules/sentinel-difficulty-scope.mdc` | `sentinel-difficulty-scope` |

Two further pairs are tools rather than rules and so are not in the table above, but they follow the same twinning discipline: `humanizer` (mandated by Step 9 and Step 10) and `quality-rehearsal`, each existing as both `.cursor/rules/<name>.mdc` and `.claude/skills/<name>/SKILL.md`. **Any edit to one must be made to its twin in the same pass** applies to these too.

**Official documentation - `docs/`** is a local export of the Sentinel Ultra Hub (https://snorkel-ai.github.io/Sentinel_Ultra_Hub/), re-exported 2026-08-06. `docs/manifest.json` carries the real per-file export date, size and hash and is the thing to trust; `docs/README.md` says how to check whether the Hub has moved since, and `bin/docs-freshness.sh` runs that check. It is the source of truth. When this file or a companion rule file disagrees with `docs/`, `docs/` wins - follow it and flag the drift to the user. **`docs/` stays a clean verbatim export: material from any source other than a Hub re-export - Slack, another workspace, a platform report, your own measurement - goes into `CLAUDE.md`, `.claude/rules/`, `learning/` or the skills, never into `docs/`.** The single sanctioned exception is repairing a defect in the export itself (a truncated table, a mangled character), and that repair must be annotated in place with its date.

- `docs/guidelines.md` - verdicts, the four core principles, PR scope and difficulty, what you can edit (instructions, tests, oracle, environment, git)
- `docs/tasking-guide.md` - Before You Upload checklist, detailed tasking steps, the zip command, submitter and reviewer form questions, Run Evals, the Quality Check judge
- `docs/harbor-framework.md` - task structure and the full `task.toml` field and limit reference
- `docs/faq.md` - troubleshooting (broken environments, agent errors, network_mode, agent timeouts, PR scope vs added complexity). Two entries added 2026-08-05 and both change how a red eval is read: the **review gate** (a two-stage check that runs before the task reaches a reviewer, agentic judge then a cheap single-arm difficulty screen, with the per-axis reasons in the collapsed "Agentic Judge Quality Report" field on the submission), and the fact that a **later, related PR** in the same repo may be adapted for difficulty material
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
- `learning/difficulty-is-divergence-not-volume.md` - **`FAIL EASY` is not a size complaint.** A whole extra feature, adapted by the sanctioned related-PR route and pre-measured against four wrong implementations, converted zero of eight agents. The lever class that works is a documented behaviour that contradicts what a competent implementer naturally writes. Also: answering judge clarity findings quietly spends difficulty, and nothing measures that until the screen runs
- `learning/answers-file-drift.md` - what many rounds of editing does to `submission_answer.txt`, the per-round grep checklist that catches it, and the one-write-per-edit rule that two silently-dropped edit batches earned
- `learning/accepted-bundle-reference.md` - the two bundles that cleared every gate, with measured numbers, separating what acceptance validated from what merely was not caught

**Operating constraints:**

- The analysis phase (Steps 1–4) is a static document and logic review with read-only shell/git inspection - no builds, no test runs.
- **No command of any kind runs inside `download/original/` after the extract - git included.** `git status`, `git fsck` and `git apply --check` all rewrite `.git/index`, so running them there mutates the tree this file calls pristine. Step 2 makes the working copy first and inspects `tasks/<name>/work/environment/repo` instead. The pristine extract is the diff target and nothing else.
- **Stop if unsure.** When a fix depends on a fact you have not opened a file to confirm, stop and ask rather than editing. Cite the path and the line you read for every claim you make. Never implement a fix from memory of how a similar task behaved - the last task's environment is not evidence about this one. An unverified fact is a question for the user, not an assumption to ship.
- The local **verification battery** (NOP, oracle 3/3, hostile delete): on the **Fixable** path Cursor runs it ITSELF after applying the fixes (Step 5.5), on disposable extracts of the built zip, and no answers are written until all three pass. For **Valid as-is** the oracle and NOP run is MANDATORY before submitting (the platform's difficulty evals do not re-run Valid as-is tasks, so it is the only check on them) - ask the user to run and report, or run it the same way as Step 5.5 if the user asks. (The Hub calls the Fixable-path local run optional since the platform evals run it; this workspace is deliberately stricter - it saves an eval round trip.)
- Every finding must cite a file path and, where possible, a line number.
- Never invent platform-provided values: the task data block (Step 1.5) and the handling-time numbers must always come from the user.
---

## Where every rule lives

One file per section, in load order. The `## N.` heading inside each file is the original one, so every "Section N" cross-reference in this workspace - in `AGENTS.md`, in the skills, in a `task.md` - still resolves through this table.

| Section | What it owns | File |
| ------- | ------------ | ---- |
| 1 (Steps 1 to 5.5) | Session start, the task-data ask, reading the task, analysis, the verdict, applying fixes, the verification battery | `.claude/rules/01-workflow-steps-1-to-5.5.md` |
| 1 (Steps 6 to 11) | Drafting the answers, the eval loop and Send gate, handling times, `submission_answer.txt`, revision rounds, closing an accepted or rejected task | `.claude/rules/02-workflow-steps-6-to-10.md` (filename unchanged; it owns Step 11 too) |
| 2 | The submitter form - every question, per path, and the basis for answering it | `.claude/rules/03-submitter-form.md` |
| 3 | Verdict criteria - what makes a task Valid as-is, Fixable, or Invalid | `.claude/rules/04-verdict-criteria.md` |
| 4 | The platform evals, the rubric-panel judge, the six auto-REMOVE patterns, troubleshooting | `.claude/rules/05-evals-and-quality-check.md` |
| 5 | Writing rules for free-text answers - plain English, no LLM tells, no internal check vocabulary, no wrapping | `.claude/rules/06-writing-rules.md` |
| 6 | The three `submission_answer.txt` templates | `.claude/rules/07-answer-templates.md` |
| 7 | Task directory structure and where a local run is allowed to happen | `.claude/rules/08-workspace-layout.md` |
| 8 | `task.toml` field and limit reference | `.claude/rules/09-task-toml-reference.md` |
| 9 | Reading the solution patch and its three names | `.claude/rules/10-solution-patch.md` |
| 10 | Verifier hardening - what passes every eval and still comes back from the reviewer | `.claude/rules/11-verifier-hardening.md` |
| 11 | Common mistakes to avoid | `.claude/rules/12-common-mistakes.md` |

**Keeping them in sync.** A rule file is edited in place, the same way this file used to be. The `.cursor/rules/*.mdc` and `.claude/skills/*/SKILL.md` twinning discipline described above is a separate thing and is unaffected - `.claude/rules/` has no Cursor twin, because Cursor reads `.cursor/rules/` and Claude Code reads both `CLAUDE.md` and `.claude/rules/`. A Cursor session therefore gets this file plus the three `.mdc` companions and does not get `.claude/rules/`; when working in Cursor, open the rule file the table names before acting on the step it owns.

---

## The workflow spine

The full text of each step is in the rule file named above. This is the sequence and the order, which never changes.

| Step | What happens | Never |
| ---- | ------------ | ----- |
| **1** | Read every file in `learning/` first, then `INDEX.md`, then scan `tasks/`. Reconcile `INDEX.md` against disk and report drift. Count `pending-revision` rows with `grep -c '^\| \[.*\| pending-revision \|' INDEX.md` | Start a new claim when the count is already 2 |
| **1.5** | Ask the user for the task zip AND the platform task data block, in one message. Ask for the extract by CONTENTS - the directory holding the five task entries - not by wrapper name. Wait | Generate any of those values, assume an inner `task/`, or start Step 2 before both arrive |
| **2** | Make the working copy FIRST (`cp -a download/original/. work/`), then read the whole bundle and cross-check the pasted platform data against it | Run any command inside `download/original/` after the extract, git included |
| **3** | Independent analysis: the four core principles plus the six auto-REMOVE patterns. Every finding gets a file:line, a Fixable trigger, and a minimal fix | Re-judge difficulty from scratch |
| **4** | Decide the verdict. Both occurrences of the analysis question and the internal Validity field must agree | Give the two occurrences different answers |
| **5** | Apply corrections, in `tasks/<name>/work/` only. Order: git hygiene, instruction, `problem_statement.md`, oracle, tests, allowed Dockerfile fixes, `task.toml`, pre-upload checklist | Edit the pristine extract, or run a build tool inside either tree |
| **5.5** | Phase A: the 14 pre-upload gates on `work/`, then build the zip. Phase B: NOP, oracle three times, hostile delete, each on its own fresh extract of that zip | Run the battery on `work/`. Any edit after Phase B voids Phase B |
| **6** | Draft every answer. On the Fixable path, Phase 1 answers go into the platform before the zip upload field, Phase 2 after the evals pass | Write answers before the battery passes against the current zip |
| **7** | The eval loop, then the eight-condition Send-to-reviewer gate | Check Send with a failing condition and no explanation |
| **8** | Ask the user for the four handling-time numbers. The total is fields 1 + 2 + 3 | Invent any of the four |
| **9** | Write `tasks/<name>/answers/submission_answer.txt`, then run `humanizer` over the text in the file as the closing action | Treat the chat-time humanizer pass as covering the file |
| **10** | Every revision round: confirm which task the feedback is for and that it is fresh, count strikes, fix, re-run Phase A and the whole Phase B battery, update the answers file and `task.md` in one action | Ship a third variation of a fix that has already failed twice |
| **11** | Close the task: the outcome into `task.md`, `INDEX.md` set to accepted or rejected with the `pending-revision` count dropped, the learnings and the calibration row harvested, then the whole folder moved to `_archive/` | Leave a closed task in `tasks/`, where it is gitignored and one delete from gone |

The Fixable sequence is always: **fixes, then Phase A gates, then zip, then the Phase B battery, then answers.** No step moves.

---

## Hard boundaries

These are in force on every path, in every round, and reviewer feedback does not widen them. Full reasoning in the rule files; the constraint itself is here so it survives a context compaction.

- **Never edit anything under `download/original/`, and never run a command there.** It is the pristine extract and the only diff target.
- **Never edit tracked source files inside `environment/repo/`.** Git metadata cleanup is allowed and expected. Source edits are not.
- **Never leave a pre-existing test file modified in the shipped tree.** `git -C environment/repo status --porcelain` prints nothing before the zip. `tests/tests.patch` editing a pre-existing test file is a different thing and is allowed - the one accepted bundle patches 44 of them.
- **Never reduce or replace the source PR's scope.** Expansion only. A fix that would require reducing it makes the task Invalid / Not Fixable.
- **Never run `solve.sh` or `test.sh` inside `work/`.** They mutate the tree. Use disposable extracts of the built zip in the session scratchpad.
- **Never write form answers before the verified zip exists** in `tasks/<name>/upload/` and the battery has passed against an extract of that exact zip.
- **Never mark a task Invalid over a platform or infra failure.** Rate limits, sandbox errors, a one-off nonzero exit and blank feedback are never Not Fixable conditions. **A review-gate block is not one of these** - per `docs/faq.md` a block at the agentic judge or at the difficulty screen is a content-side result to act on, and the only infra case is a message that explicitly says the difficulty screen failed with an infra error.
- **Never invent a platform-provided value.** The task data block and all four handling-time numbers come from the user.
- **Never edit a `.cursor/rules/*.mdc` without making the identical edit to its `.claude/skills/*/SKILL.md` twin**, or the reverse.
- **Stop if unsure.** An unverified fact is a question for the user, not an assumption to ship.
