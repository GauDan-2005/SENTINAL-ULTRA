# Sentinel Ultra Hub — Complete Documentation

Source: https://snorkel-ai.github.io/Sentinel_Ultra_Hub/

Exported: 2026-07-31T13:51:23Z
Delta re-checked against the live Hub: 2026-08-01 (2 new What's New entries + 1 new FAQ entry, both dated Jul 31, 2026, merged in below)

Every tab of the Sentinel Ultra Hub, concatenated in navigation order.


---

# What's New

# What's New

Latest updates to the Sentinel Ultra contributor guidelines

📢 Latest update

Network fields in `task.toml` have changed

Network access is now set **per block** — `[environment]` `"public"`, `[agent]` `"allowlist"` with `allowed_hosts`, and `[verifier]` `"no-network"`. Also remove `network_mode = "none"` from `docker_compose.yaml` if present.

[See the updated task.toml structure →](harbor-framework.md#task-metadata)

## Recent updates <a id="recent-updates"></a>

-   Jul 31, 2026

    **Quality Check pass bar clarified.** On coverage and faithfulness (scored 1–5), a task must land **above 3** on both axes to pass — exactly 3 (or any single judge at 2 or below) sends it to needs-revision, and 2 or below is a hard fail. Don't ship borderline. [Quality Check judge →](tasking-guide.md#quality-check-agentic-judge)

-   Jul 31, 2026

    **An eval failed with an infra error, or came back with blank feedback?** A platform failure (Daytona/rate-limit errors, a one-off nonzero exit, "No evaluation information available") is not a task defect — don't mark the task Unfixable and don't burn a revision slot resubmitting blindly. Retry, and flag it with the UID if it persists. [FAQ →](faq.md#an-eval-failed-with-an-infra-platform-error-or-came-back-with-blank-feedback-is-my-task-broken)

-   Jul 30, 2026

    **Linter rejects a task as "easy" after a difficulty downgrade?** Known issue — don't hand-edit the `task.toml` pass-rate/difficulty fields to fight the linter. Flag it on Slack with the UID and the two conflicting values. [FAQ →](faq.md#the-linter-rejects-my-task-as-easy-after-a-difficulty-downgrade-what-do-i-do)

-   Jul 30, 2026

    **Checking submission status.** Use `stb submissions list` from the CLI — it's the source of truth if the GUI is lagging or a task flickers in and out. [FAQ →](faq.md#how-do-i-check-the-status-of-a-submission)

-   Jul 27, 2026

    **Builds can use the network at build time.** Tasks were never required to build offline; the run-time sandbox stays restricted (agent reaches only the model gateway, verifier airgapped). [Before You Upload →](tasking-guide.md#before-you-upload)

-   Jul 27, 2026

    **Nonzero exit-code agent error?** After the usual troubleshooting, try removing `curl` from your `environment/Dockerfile` — a known Harbor edge case. [FAQ →](faq.md#i-m-getting-a-nonzero-exit-code-agent-error-what-should-i-try)

-   Jul 23, 2026

    **Agent timeout ceiling raised to 7200.** The `[agent]` `timeout_sec` max is now 7200 (up from 3600) — update affected tasks and resubmit. [Task Metadata →](harbor-framework.md#agent)

-   Jul 22, 2026

    **Git issues are now fixable.** Leaked history, a remote, a HEAD/base mismatch, a reflog, or an oversized `.git` no longer make a task Not Fixable — fix them in `environment/repo` and re-zip. [Git — fixable in the repo →](guidelines.md#git-fixable)

-   Jul 13, 2026

    **Quality Check is now a blocking agentic judge.** Two LLM judges score your task; a fail sends it to `NEEDS_REVISION`. Driven by test coverage and faithfulness. [Quality Check judge →](tasking-guide.md#quality-check-agentic-judge)


---

# Guidelines

# Sentinel Ultra Contributor Guidelines

Last updated: July 22, 2026

**Welcome to Sentinel Ultra**
Sentinel Ultra is Snorkel AI's initiative to build a high-quality dataset of [Harbor-format](https://harborframework.com/docs) software-engineering tasks, drawn from real open-source pull requests, commits, and issues. The dataset is used to train and evaluate frontier coding agents and models on realistic engineering work.

Because of that purpose, the thing that matters most is that every task is **correct, complete, and impossible to game** — no errors, no gaps in coverage, and no way for an agent to pass without doing the real engineering work. Difficulty matters too, but the platform's evals help confirm a task clears the difficulty bar; your focus is on the errors and gaps that automated checks can't catch.

**How a task reaches you**
Each task starts from a real source (a PR, commit, or issue) and is packaged into the Harbor format. It then moves through:

1.  **Authoring** — the task is created from the source.
2.  **Submission** — an EC (you) reviews the task, decides whether it's valid, and fixes it if needed.
3.  **Review** — a second EC independently verifies the submission.
4.  **Adjudication** — a final pass resolves disagreements between submitter and reviewer.
5.  **Delivery** — accepted tasks are delivered to train and evaluate coding agents.

These guidelines explain how to evaluate a task, identify issues, make corrections, and complete your submission successfully.

*If you are not familiar with the Harbor framework, review the* [Harbor documentation](https://harborframework.com/docs) *for terminology and layout. The [Harbor Framework tab](harbor-framework.md) has important information on task structure and the `task.toml` fields you'll need to check on every task.*

## Your Role as an Expert Contributor (EC) <a id="your-role-as-an-expert-contributor-ec"></a>

You will review Harbor tasks derived from real open-source pull requests and provide feedback through the Snorkel Experts platform. Each task asks an agent to navigate a codebase, understand the requirements, implement changes, and validate behavior through tests.

Your role is to ensure tasks are **solvable, clear, free of leakage, verifiable, and authentic** — the five things the core principles below cover in depth:

-   **Solvable** — completable from the instruction alone, by a competent engineer, within the task's limits.
    -   No arbitrary guesswork: every choice the tests require is stated or reasonably implied.
    -   Claims hold up: the instruction only references behavior, APIs, and files that actually exist in the repo.
-   **Clear** — the instruction describes the problem and the expected behavior, not how to implement it.
    -   Not overly prescriptive (e.g. no "Where to look: \[files\]", no naming the exact functions to edit).
    -   Any required output format or schema is documented, not left to guesswork.
-   **Free of leakage** — nothing in the task lets an agent shortcut the real work.
    -   No solution hints, PR links, or spoilers in the instruction or environment.
    -   No hidden test details exposed, and no way to pass by editing the tests.
-   **Verifiable** — a sound, comprehensive test suite proves the behavior.
    -   At least 10 fail-to-pass tests, outcome-based (they run code and check real behavior).
    -   Includes a regression test, is deterministic, and doesn't depend on the solution.
-   **Authentic** — a realistic, substantial engineering task.
    -   A plausible workflow (bug fix, feature, refactor), typically ~100+ lines across multiple files.
    -   Reads like real engineering communication, not a templated or AI-generated prompt.

You're also responsible for keeping each task **consistent with the scope of the source PR** — you may expand on it to add complexity, but you may not reduce or replace it.

## Task verdicts <a id="task-verdicts"></a>

When you receive a task in platform, you’ll give a verdict on which of the three states below the task falls into.

| Verdict | When it applies |
| --- | --- |
| **Valid as-is** | Instruction, tests, and oracle all align with each other and with the source PR. No rewrite or edits are required. |
| **Fixable** | The task has one or more of the issues below:<br><br>• **Instructions** are overly prescriptive or expose verifier internals<br><br>• **Instruction** reads as templated/AI-generated<br><br>• **Tests** miss requirements stated in the instruction<br><br>• **Tests** grade behavior that is not in the instruction, or rely on arbitrary names<br><br>• **Fewer than 10 fail-to-pass tests** — add tests to reach at least 10 (ideally 10–20)<br><br>• **Task leaks solution information** (e.g. PR URL in instruction, environment spoilers, test-gaming shortcuts)<br><br>• **Oracle does not implement the solution** following the instructions<br><br>• Overall task is too easy — but you can raise difficulty by adding to the PR scope<br><br>• A specific, listed Dockerfile issue (see [Environment](#environment-limited-fixes) section)<br><br>• A git-hygiene issue in the shipped repo — leaked fix history, a remote, a HEAD/base-commit mismatch, reflog, an oversized `.git` (see [Git](#git-fixable) section) |
| **Not Fixable** | Either of:<br><br>• **PR scope needs to be changed or reduced** — the only way to make the task valid is to reduce or replace the PR scope entirely<br><br>• **Environment Issues** — the environment has issues ECs aren't allowed to fix (see [Environment](#environment-limited-fixes) section) |

If Not Fixable, you’ll give the reasons in the submission form (see Part B).

## The four core principles <a id="the-four-core-principles"></a>

Apply these to every task — together they determine the verdict. Two of them — **Clarity & No Leakage** and **Verifiability** — are two sides of the same goal: making a task **impossible to reward-hack**, so an agent has to do the real engineering work to pass.

|  | Principle | What to check |
| --- | --- | --- |
| **1** | **Solvability** | A competent engineer can solve it from the instruction alone, within limits. |
| **2** | **Clarity & No Leakage** | Describes the problem and behavior — not the implementation — and reveals nothing exploitable. |
| **3** | **Verifiability** | A sound, comprehensive, outcome-based test suite that can't be gamed. |
| **4** | **Authenticity** | A realistic, substantial engineering task that reads like real communication and matches the PR. |

### 1 Solvability <a id="1-solvability"></a>

A task is valid only if a competent engineer can solve it from the instruction alone — within the task's time and resource limits, and without guessing arbitrary implementation choices.

**No unsupported claims:** the instruction must only reference behaviors, APIs, files, or repo structure that actually exist in the pinned repository. If it describes something that isn't there, the task isn't solvable as written.

### 2 Clarity & No Leakage <a id="2-clarity-no-leakage"></a>

The instruction should give an engineer enough to solve the task **without telling them how to implement it and without revealing the answer.** This principle has two failure modes — over-prescription and leakage — and together they are how most reward-hacking sneaks in.

#### Signs an instruction is overly prescriptive: <a id="signs-an-instruction-is-overly-prescriptive"></a>

-   Says "Where to look:" followed by a list of the relevant files.
-   Names the exact hidden test, fixture, mock endpoint, cassette, or harness file used to grade the task.
-   Explains how the verifier proves success instead of describing user- or API-visible behavior.
-   Identifies exact internal functions, branches, comprehensions, or callbacks to edit when a behavioral description would do.
-   Provides root-cause analysis that removes the need to inspect the code.
-   Says "the tests reference this name" or "this file validates the fix."
-   Copies exact assertion strings, state paths, or fixture values from tests — unless they're a genuine public/API contract.

**Document required output formats.** If the task requires a specific output format, schema, or API response shape, state that format in the instruction (or a clearly referenced file in the environment). Describing the expected *shape* is necessary and is not leakage — leaving it to guesswork is what breaks solvability.

#### No leakage <a id="no-leakage"></a>

Tasks must not leak the solution. Check for:

-   **PR leakage:** PR URLs, titles, numbers, or commit SHAs in the instruction that let an agent scrape the fix.
-   **Environment spoilers:** commit messages, comments, or docs in the base repo/Docker setup that describe the exact change.
-   **Test-modification gaming:** loose test constraints that can be satisfied by editing the test files instead of the implementation.

### 3 Verifiability <a id="3-verifiability"></a>

Tests are the ground truth for a task. They must comprehensively and fairly verify the required behavior, and they must be impossible to game.

> **Note:** When you run evals, an agentic rubric-panel judge now scores these two directions mechanically as **test_coverage** and **test_faithfulness**, and a failing verdict blocks submission. See [Quality Check — the agentic rubric-panel judge](tasking-guide.md#quality-check-agentic-judge) in the Tasking Guide for the verdict logic, the six auto-fail patterns, and the test-writing checklist.

#### Test ↔ instruction alignment <a id="test-instruction-alignment"></a>

Tests should map 1:1 with the instruction's requirements; the agent must be able to pass them using only the instruction and the environment. Check both directions:

| Direction | Requirement |
| --- | --- |
| Instruction → Tests | Every required behavior is tested. |
| Tests → Instruction | Every assertion maps to something stated or reasonably implied. |
| No hidden checks | Tests don't grade behavior the instruction never asked for. |

Tests likely need a rewrite when they enforce undescribed behavior, require non-derivable names/paths/formats, over-constrain implementation, depend on verifier internals or hidden fixtures, can be passed by editing the tests, or miss/partially cover major requirements.

#### At least 10 fail-to-pass tests <a id="at-least-10-fail-to-pass-tests"></a>

Every task must ship with at least **10 fail-to-pass tests** — the single most important guard against reward hacking and the main way to ensure sufficient behavioral coverage. If the task arrives with fewer than 10, mark it **Fixable** and add tests during your rewrite to reach at least 10 — ideally 10–20. Added tests must cover requirements stated or reasonably implied in the instruction (never undescribed behavior).

#### Outcome-based tests <a id="outcome-based-tests"></a>

Tests must verify **observable behavior** by running code and checking results — invoking the corrected API, querying a service, inspecting runtime output. They must **not** grade by patch structure, diff format, line numbers, file names, or source-code keyword matching, and must not be satisfiable by hardcoding or special-casing expected values.

#### Regression test required <a id="regression-test-required"></a>

The suite must include at least one test that directly reproduces the failure described in the issue — it **fails on the pre-patch repo and passes after the fix.**

#### Deterministic and fast <a id="deterministic-and-fast"></a>

Tests must use deterministic inputs, seeds, and assertions, with no flaky or order-dependent behavior, and must finish within the configured timeout. Scope long suites to the relevant subset.

#### Independent of the oracle <a id="independent-of-the-oracle"></a>

Tests must not import or call the golden solution, compare against files created only by the solution, or otherwise depend on solution-side artifacts. Any fixtures or mock data must be committed into the verifier image so the agent cannot tamper with them.

#### The arbitrary naming problem <a id="the-arbitrary-naming-problem"></a>

A common alignment failure: tests expect a specific name the instruction never gave — a function/method/class name, exact error string, output format (JSON keys, log format), new module/file name, or CLI flag / config key.

A name is **derivable** (and therefore acceptable) only if it:

-   already exists in the base codebase being modified (e.g. an existing parsedate()),
-   follows a standard language/framework convention (e.g. Python str, standard REST resource names), or
-   is explicitly stated in the instruction.

*Example — Invalid but Fixable:* instruction says "Add a feature to validate emails," but the test asserts validateemailaddress(email) = True. The instruction never specified that name → add it in your rewrite.

*To catch it:* list the names/formats the instruction explicitly specifies → scan the tests for expected names → flag any that aren't derivable.

### 4 Authenticity <a id="4-authenticity"></a>

A valid task looks like real engineering work and reads like real engineering communication.

**Substantial and agentic.** The task must require genuine code exploration, multi-step reasoning, and real changes — not a one-line edit or a zero-shot generation. As a rule of thumb, the underlying fix is roughly **100+ lines across two or more files.** A task solvable by a trivial edit, or that is really a contrived puzzle with no real-world analogue, is not authentic.

**Reads like a real engineering ask.** A good instruction matches one natural persona:

-   **Casual/Slack-like** — direct, assumes domain knowledge.
-   **Structured ticket** — Summary / Steps to Reproduce / Expected Behavior.
-   **Technical memo** — professional refactor/logic context.
-   **Prose/email** — a peer or tech lead explaining context and impact.
-   **Acceptance criteria** — bulleted "when X, the system should Y."

*Red flags:* robotic phrasing ("The system shall…", "It is required that…"), tone that mismatches the persona, structure identical across many tasks, or writing that reads like code documentation rather than a task assignment.

**PR ↔ instruction alignment.** The instruction must ask for the same change as the PR (bug X → describes bug X; feature Y → requests feature Y). If you expanded scope, it should still be the original PR *plus* your additions — not a different task.

## PR Scope and Task Difficulty <a id="pr-scope-and-task-difficulty"></a>

### Task difficulty <a id="task-difficulty"></a>

Sentinel tasks train and evaluate frontier coding agents, so they have to be genuinely hard — an easy task gives no useful signal. By the time a task reaches you it has already passed our difficulty checks, so you don't need to judge difficulty from scratch (it's also why the difficulty evals don't re-run on tasks you mark **Valid as-is**).

Clearing the difficulty bar doesn't mean a task is free of *other* issues, though — and fixing those issues can pull difficulty back below the benchmark. When that happens, the platform's evals send the task back to you to raise it again.

#### **Troubleshooting task difficulty** <a id="troubleshooting-task-difficulty"></a>

**First, check for over-prescriptive instructions.** Often an instruction hands the agent context it should have discovered itself — the files to touch, the root cause, or a step-by-step approach. Remove anything the agent could reasonably find by exploring the codebase (and any solution-revealing names or paths, which are also leakage), and describe the behavior you expect instead of the how.

> **Note:** **Balancing context is the crux of this work:** a task needs *enough* context to be solvable, but *not so much* that it becomes instructional.

**If trimming isn't enough, expand the PR scope.** When the source PR simply isn't complex enough, add to its scope so the task is genuinely harder (see the rules below).

**Keep any added difficulty real.** Good difficulty comes from the problem itself — complex debugging, root-cause analysis, a substantial feature, or hard domain/security work. It must **not** come from vague or underspecified requirements, or from stapling unrelated changes together; those make a task confusing, not difficult, and a reviewer will flag them.

### PR scope rules <a id="pr-scope-rules"></a>

When you fix a task, you can change the instruction, tests, and oracle — but you cannot change what the task is about. The source PR anchors what the task is.

You may:
✅ **Add to the scope of the PR** to make the task harder.

-   Example: Original PR adds a `/health` endpoint. You extend it so the endpoint also handles auto-restart on failure.
-   Example: Original PR fixes a single edge case in a date parser. You extend it to handle three additional edge cases.

You **may not:**

❌ Reduce the scope of the PR to make it more concise
❌ Replace the PR with a different feature or task type entirely

-   Example: Original PR is a bug fix. You can't rewrite it as a feature add.
-   Example: Original PR is a refactor of module X. You can't rewrite it as a refactor of module Y.

If the only way to make a task solvable, difficult enough, or valid is to reduce or replace the PR scope, the task is **Not Fixable**.

**Why this matters:** The task is anchored to a real PR via `task.toml`. If the task no longer resembles the PR, the link is misleading and the dataset loses its grounding in real-world engineering work.

## What you can edit in a task, and how <a id="what-you-can-edit-in-a-task-and-how"></a>

You can edit the instruction, tests, and solution, make limited fixes to the Dockerfile, and clean up git issues in the shipped repo — but never edit the repo's tracked source files. Expand each component for how to edit it well.

#### ✅ Instructions — editable <a id="instructions-editable"></a>

Rewrite overly prescriptive instructions to mirror real-world engineering tasks. Focus on expected behavior, constraints, and observable outcomes, while still requiring standard codebase investigation.

| ❌ Overly Prescriptive | ✅ Preferred Instructions |
| --- | --- |
| “The test testdownloadpackagesresumeonmirrorswitch uses /yum/partial and /yum/rangeonly to verify resume behavior.” | “When a resumed download fails after writing a valid partial file, retrying against another mirror should preserve the partial data and request only the remaining bytes.” |
| “Fix the range() call inside the list comprehension that creates schemas.SlotBase\*.\*” | “Generated slots must never extend past the schedule’s availability end time.” |
| “The hook should expose handleScrollContainerWheel because the tests reference this name.” | “The hook should expose a stable wheel handler for the scroll container.” |

#### ✅ Tests — editable <a id="tests-editable"></a>

-   Map tests 1:1 with the instruction's requirements.
-   Ensure the suite has at least 10 fail-to-pass tests (ideally 10–20); if it's short, add tests covering requirements stated or reasonably implied in the instruction.
-   Keep them flexible enough to allow multiple valid implementations where appropriate.
-   Don't introduce arbitrary names, strings, paths, or formats that aren't derivable from the instruction.
-   Validate observable behavior, not implementation details.

**Example `config.json`** — tells the harness **how** to run the suite and **which** test ids decide the reward. `fail_to_pass` is the required, non-empty list; `pass_to_pass` is the regression guard.

```
{
  "execution": {
    "commands": ["python -m pytest -q tests/test_resume.py"],
    "timeout_sec": 1800
  },
  "grading": {
    "fail_to_pass": [
      "tests/test_resume.py::test_partial_file_preserved",
      "tests/test_resume.py::test_range_request_on_retry"
    ],
    "pass_to_pass": [
      "tests/test_resume.py::test_basic_download"
    ],
    "parser": { "framework": "pytest", "result_source": "stdout_stderr" }
  },
  "artifacts": { "reward": "/logs/verifier/reward.txt" }
}
```

**Example `test.sh`** — applies the tests, runs the suite, and writes the reward to the path Harbor reads. The exit code should match the reward it writes.

```
#!/usr/bin/env bash
set -euo pipefail

# Add the fail-to-pass tests to the repo
git apply /tests/tests.patch

# Run the suite; write 1.0 only if it passes, else 0.0
cd /workspace/repo
if python -m pytest -q tests/test_resume.py; then
  echo "1.0" > /logs/verifier/reward.txt
else
  echo "0.0" > /logs/verifier/reward.txt
  exit 1
fi
```

#### ✅ Solution & oracle — editable in two cases <a id="solution-oracle-editable-in-two-cases"></a>

You may edit solve.sh / golden.patch in two cases: (1) to correct an oracle that does not implement the instruction, or (2) to expand PR scope to increase difficulty. When you do:

-   **Match the canonical fix.** The solution should correspond to the actual fix from the source PR — not an alternative you invented. Only diverge if the upstream fix is genuinely unavailable or unsuitable, and document why.
-   **No unnecessary changes.** The patch should contain only what's needed to resolve the task. Don't fold in unrelated refactors, style cleanups, or drive-by edits.
-   The expanded oracle must still resemble the source PR (anchor preserved, with additions) — never reduce or replace its intent.
-   Update the **instruction and tests in lockstep** so the trio stays internally consistent, and the instruction reads as one realistic ask, not a tacked-on list.
-   If you expanded scope, re-run the difficulty eval to confirm the task now clears the bar.

If a fix would require reducing or replacing the PR's behavior, mark the task **Not Fixable** instead.

#### ⚠️ Environment — limited fixes <a id="environment-limited-fixes"></a>

> **Note:** **`problem_statement.md` must be an exact copy of `instruction.md`.** Check before submitting that the two files are identical — if you edit the instruction, copy the same content into `problem_statement.md`. (We're working to automate this so you don't have to do it in future!)

You may make only specific, allowed fixes to the environment (chiefly `environment/Dockerfile`). Use the tables below to decide whether an environment issue is within the limited fixes you can make — otherwise the task is **Not Fixable**.

> **Note:** Many environment failures are catchable before you submit — the local Docker build, the `tests.patch`\-applies-to-base check, git-history hygiene, and the stray-artifact sweep are all in the [Before You Upload](tasking-guide.md#before-you-upload) checklist in the Tasking Guide.

**Fixable environment issues**

| Issue | What's happening | Fix |
| --- | --- | --- |
| Alpine image missing bash | solve.sh/test.sh use a bash shebang but Alpine ships only ash (saw 55x) | `apk add --no-cache bash`. Has autocorrect: alpinebashautocorrect. |
| Missing `environment/frozen-requirements.txt` | Dockerfile COPYs it but it's absent (saw 683x) | Generate it. Has autocorrect: frozenrequirementsautocorrect. |
| `tmux` not installed in the task image | Harbor drives the agent/verifier inside a `tmux` pane; no tmux means the session never starts and the run errors before tests | `apt-get install -y tmux` / `apk add --no-cache tmux`. Good autocorrect candidate. |
| asciinema not installed | Harbor records the terminal session with asciinema; a missing binary breaks the run | `apt-get install -y asciinema` / `pip install asciinema` / `apk add asciinema` |
| Unpinned base image (FROM ...:latest) | Reproducibility failure | Pin to a concrete tag |
| DownloadVerifierDirError / verifier-output-not-found | When caused by the above (bash/sh mismatch, missing artifact path, missing tmux/asciinema) | Fix the upstream cause |
| Resource limits too low | Build OOM / disk-full from undersized `cpus`/`memory_mb`/`storage_mb` | Bump limits |
| Bad shell/shebang, CRLF line endings, non-executable scripts | Script fails to exec | Normalize / `chmod +x` |
| Stray pipeline artifacts / wrong metadata blocking build prep | e.g. metadata.json in root, cpp vs c++, missing language. Strictly metadata, but they gate the task before it builds. | Clean up |

**Not Fixable environment issues**

| Issue | When it's defensible |
| --- | --- |
| Image/dependency build failures | apt/pip/npm/cargo install errors, missing system libs, compiler flags. Adding a missing dev package or flag is under worth fixing; a tangled toolchain/version conflict is not. |
| Oracle timeout | harbor run timed out after n seconds. Can try bumping the timeout. |
| External-network dependency at build/solve time | curl/wget/HF/model pulls against a restricted or flaky sandbox. Vendoring one small file is under fixable; a multi-GB model pull or live external service is not. |

> **Note:** Git-repository problems (leaked fix history, remotes, a HEAD/base-commit mismatch, reflog, an oversized `.git`) are handled separately — see [Git — fixable in the repo](#git-fixable) below. Most of them are fixable.

#### ✅ Git — fixable in the repo <a id="git-fixable"></a>

The shipped repo (`environment/repo/`) is a real git checkout, and its **HEAD is the source of truth** for the task. Git problems are **fixable**: do the git work **inside `environment/repo`**, then re-zip the task. You may clean git metadata (remotes, stray branches/tags, reflog, `.git` size) and realign `task.toml` to HEAD — but you must still **never edit the repo's tracked source files**, since that's what anchors the task to the real PR.

> **Note:** When HEAD and the `base_commit_sha` declared in `task.toml` disagree, the shipped repo (HEAD) wins — realign the declared commit to HEAD. This misalignment mostly shows up on older tasks authored before a static-asset-generation fix; newer tasks generate the two in sync.

**Common git issues and how to fix them**

| Issue | Why it matters | Fix |
| --- | --- | --- |
| `.git` missing | No `.git` means there's no repo for the agent to work in — usually a zip tool that dropped dotfiles | Make sure `environment/repo/` is a real repo and `.git/` is in the zip |
| HEAD doesn't resolve | A detached, empty, or corrupt HEAD can't be checked out | Ensure the repo has at least one commit and HEAD points at it (`git rev-parse --verify HEAD`) |
| HEAD ≠ declared base commit | The agent must start from the commit `task.toml` declares; the shipped repo (HEAD) is the source of truth | `git checkout <base_commit_sha>`, or edit `task.toml` so its base commit equals HEAD |
| Commits / branches / tags beyond HEAD | Any ref past HEAD can carry the fix history and **leak the answer**, making the difficulty signal worthless | Delete them so `git rev-list --all --not HEAD` is empty; ship a single branch at the base commit with no stray tags |
| Remote configured | An escape hatch to external history and an untrusted-config surface; tasks must be self-contained and offline | `git remote remove <name>` for each remote |
| Filter drivers (`filter.*`) | clean/smudge drivers are arbitrary commands git can run (e.g. on `git status`) — a security risk and non-reproducible | Remove every `filter.*` section from `.git/config` |
| Dirty working tree | Uncommitted or untracked changes make the start non-reproducible, and an uncommitted solution leaks the answer | Commit or discard until `git status --porcelain` prints nothing |
| Reflog present (`.git/logs`) | Records rewound commits (like your solution) and bloats the repo | `git reflog expire --expire=now --all && git gc --prune=now`, then remove `.git/logs` |
| `.git` over 100 MB | Almost always accidental large blobs; slows every trial and wastes storage | `git gc --aggressive --prune=now`; if still large, strip big blobs or ship a fresh single-commit base history (then reset the base commit in `task.toml`) |
| `tests/tests.patch` won't apply | A patch cut against a different base fails on *every* trial and invalidates the run | Fix HEAD == base commit first, then regenerate the patch against the shipped repo state |

**Pre-submission checklist** — run inside `environment/repo` before you re-zip; every line should be clean or empty.

```
cd environment/repo

git rev-parse --verify HEAD                   # HEAD resolves
git rev-parse HEAD                            # == base_commit_sha in task.toml?
git rev-list --all --not HEAD                 # MUST be empty (no leaked commits)
git remote                                    # MUST be empty
git config --local --get-regexp '^filter\.'   # MUST be empty
git status --porcelain                        # MUST be empty (clean tree)
ls .git/logs 2>/dev/null                      # MUST NOT exist / be empty
du -sh .git                                   # MUST be < 100 MB
git apply --check ../../tests/tests.patch     # MUST apply cleanly
```

**How to zip the task**

Zip the flat contents of `task/` — not the folder, not `runs/`. Your zip tool must store directory entries (`zip -r` does; some GUI tools and `zip -rD` don't, and silently drop the empty `.git/refs/` that `git gc` leaves behind, which breaks the repo on the platform).

```
cd task
zip -rX ../<your_task>.zip . -x '*.DS_Store' '__MACOSX/*'
```

> **Note:** The [Before You Upload](tasking-guide.md#before-you-upload) checklist in the Tasking Guide has more on regenerating `tests.patch` when it doesn't apply.

#### ❌ Repo source files — never edit <a id="repo-files-never-edit"></a>

Never edit the **tracked source files** inside `environment/repo/`. The task is anchored to the real base repository; changing its code breaks that grounding and is not allowed. This is separate from git hygiene — cleaning `.git` metadata and restoring the tree to the base commit (see [Git — fixable in the repo](#git-fixable)) is allowed and expected.


---

# Tasking Guide

# Tasking Guide

Sentinel Ultra submission and review steps

* * *

## Submission Quick Start Guide <a id="submission-quick-start-guide"></a>

1.  **Log in** — open the [Snorkel Experts platform](https://experts.snorkel-ai.com/home) and open the Submission task (search "Sentinel").
2.  **Download your task zip** — it contains two folders: `task/` (the instruction, environment, solution, and tests you'll review) and `runs/` (agent attempt logs). Everything you'll inspect and edit is inside `task/`.
3.  **Review** — decide Valid / Fixable / Not Fixable.
4.  **If Fixable, rewrite** the instruction, tests, and/or oracle.
    4b. **Prepare your upload:** zip only the contents of the `task/` folder — not the folder itself, and not `runs/`. The zip should unpack directly to `instruction.md`, `task.toml`, `environment/`, `solution/`, and `tests/`.
5.  **Run evals** via the platform button; iterate until checks pass.
6.  **Submit** — check *Send to reviewer* and submit.

📹[Sentinel Ultra Submission Flow Walkthrough](https://www.loom.com/share/52a317cb90674f8eb18b9bd208d7b01a)

* * *

## Before You Upload <a id="before-you-upload"></a>

Run these checks locally before you zip and submit. They're the failures that produce "0/8 valid trials — infra/harness failure" difficulty bounces and packaging-axis failures. They reproduce identically on every run, so resubmitting an unchanged zip will always fail the same way — verify locally first.

1.  **`tests.patch` must apply cleanly to the base commit.** The most common infra failure. The fail-to-pass tests are injected by applying `tests/tests.patch` onto `environment/repo` at `base_commit_sha`. If the repo drifted, the patch was cut against a different base, or the f2p tests are already baked into the repo, every trial fails before any evidence is collected. Verify locally:

    ```
    unzip <your_task>.zip -d task && cd task
    cd environment/repo
    git stash -u 2>/dev/null
    git checkout $(grep base_commit_sha ../../task.toml | cut -d'"' -f2)
    git apply --check ../../tests/tests.patch      # must succeed with no output
    ```

    If it fails (`Hunk #N FAILED` / `does not match index`), regenerate the patch: from the repo at `base_commit_sha`, confirm the target test files are in their original state (they must not already contain the new f2p tests — the patch is what adds them); apply your fail-to-pass test additions by hand; `git add -A && git diff --cached -- <test paths> > ../../tests/tests.patch`, then `git checkout .` to restore the repo to base. Re-verify with `git apply --check`, then run the oracle + tests end to end. Common traps: the repo copy already includes your new tests (patch re-adds them → conflict); the patch touches a non-test file (e.g. `CMakeLists.txt`) that has since changed.

2.  **Never modify pre-existing (regression / pass-to-pass) test files.** The harness checks that pre-existing test files are byte-identical to the base commit. If your fix seems to require changing an existing test, add a new test through `tests/tests.patch` instead (new functions or new files only), and revert the existing file to its `base_commit_sha` content.

3.  **The Dockerfile may use the network at build time**, but the sandbox is network-restricted at run time: the solving agent reaches only the model gateway, and the verifier runs fully airgapped. `docker build environment/` locally and make it reproducible: run `apt-get update` before installs, use packages that exist in the base image's distro, pin the base image to a concrete tag (never `:latest`), bake test dependencies into the image instead of fetching them when the tests run, or switch to a base image that already ships the tools you need.

4.  **Git-history hygiene on `environment/repo`.** The repo must pass all of the git checks — `HEAD` equals `base_commit_sha`, no commits after the base, no remotes, no `filter.*` drivers, a clean working tree, `.git/` under 100 MB, and no reflog. These are **fixable**: do the git work inside `environment/repo` and re-zip — but never edit the repo's tracked source files. See [Git — fixable in the repo](guidelines.md#git-fixable) in the Guidelines for the full issue-by-issue breakdown and a pre-submission checklist.

5.  **No stray artifacts or leakage in the bundle.** Before zipping, sweep the task directory:

    ```
    find . -name '__pycache__' -o -name '*.pyc' -o -name '.DS_Store' \
      -o -name '.pytest_cache' -o -name '.mypy_cache' -o -name '.ruff_cache' \
      -o -name '.venv' -o -name 'node_modules' -o -name '.idea' -o -name '.vscode' \
      -o -name '*.swp' -o -name '*~' -o -name '*.orig' -o -name '*.bak'
    ```

    Delete everything the sweep finds — any one of these shipping into the container hard-caps the packaging score at 1. Confirm no solution material (golden patch content, expected outputs, `ground_truth.*` files) is readable from agent paths in the built image. Intentional dotfiles are fine: `.gitignore`, `.dockerignore`, `.gitattributes`, `.gitkeep`, `.github/`, `.env` when the task warrants them. `environment/problem_statement.md` must be an exact copy of `instruction.md` — re-copy it after any instruction edit. If the downloaded task contains `solution/solution.patch`, rename it to `golden.patch`. Zip the flat contents of `task/` only — no `runs/`, no wrapping `task/` folder; the zip should unpack directly to `instruction.md`, `task.toml`, `environment/`, `solution/`, and `tests/`.

6.  **`task.toml` sanity.** Resource and timeout values within the published limits; `gpus` always `0`. Set `network_mode` in each block — `[environment]` `"public"`, `[agent]` `"allowlist"` with `allowed_hosts`, `[verifier]` `"no-network"` — and remove `network_mode = "none"` from `docker_compose.yaml` if present. `category`, `difficulty_explanation`, and the source URL accurate — the judge's packaging axis cross-checks metadata against the actual task content.

7.  **Full local dry run** (required for Valid as-is, recommended for Fixable).

    ```
    docker build -t task-env environment/            # env builds (network allowed at build time)
    # oracle run: apply golden.patch via solution/solve.sh, then run tests -> reward 1.0
    # NOP run:    run tests on the unsolved repo   -> reward 0.0 (f2p fail, p2p pass)
    ```

    Valid as-is tasks are not re-run by the platform's difficulty evals — your local run is the only check on them. For Fixable tasks the platform runs these on submission, but a local run saves you an eval round-trip.


* * *

## Detailed Tasking Steps <a id="detailed-tasking-steps"></a>

Use these steps for every task. If terminology or steps are unclear, see the Harbor documentation or reach out to fellow ECs or the Snorkel team on the Slack channel.

1.  **Read the instruction** — Start with `instruction.md`. Note requirements, expected behavior, success criteria. (It should describe the problem and contract, not prescribe implementation or expose verifier internals — see [Clarity & No Leakage](guidelines.md#2-clarity-no-leakage).)
2.  **Cross-check the source PR and check `task.toml`** — Confirm that the task reflects the intended change and does not introduce unrelated scope (if expanding scope, confirm it's a natural extension). Also open `task.toml` and confirm its fields meet our requirements: the resource and timeout values are within the allowed limits, `gpus` is `0`, and `network_mode` is set in each block (`[environment]`/`[agent]`/`[verifier]`). See [Task Metadata](harbor-framework.md#task-metadata) for the full list of fields and limits.
3.  **Scan the environment** — Read `environment/Dockerfile` and skim `environment/repo/` to judge whether setup and codebase context look plausible for the instruction. **Build the environment locally in Harbor** (`docker build environment/`) to confirm it builds cleanly and reproducibly. The build step may use the network, but the run-time sandbox is restricted — the agent reaches only the model gateway and the verifier runs airgapped.
4.  **Review the solution artifacts** — Read `solution/solve.sh` and `solution/golden.patch`. Check that they appear to implement the instruction, and that the change is substantive (roughly 100+ lines spanning 2+ files). **Run the oracle locally in Harbor** — apply the golden patch via `solution/solve.sh`, then run the tests and confirm it reaches reward 1.0. (See [Rewriting the Oracle](guidelines.md#solution-oracle-editable-in-two-cases) for what a sound oracle looks like.)
5.  **Review the tests** — Read `tests/test.sh`, `tests.patch`, and `config.json`. The fail-to-pass tests live in `tests.patch`; `config.json` declares which test ids are fail-to-pass and pass-to-pass and how the suite runs. Check that fail-to-pass coverage and assertions map to the instruction's requirements, and confirm your edits don't break any pass-to-pass test. Count the fail-to-pass tests: every task needs **at least 10** (ideally 10–20). If there are fewer, the task is Fixable — add tests covering stated or implied requirements during your rewrite. (See [Verifiability](guidelines.md#3-verifiability) for the full test bar.)
6.  **Review agent runs** — Open the `runs/` folder (it sits alongside `task/` in your downloaded zip) for evidence of timeouts, systematic misinterpretation, or instability. Cite concrete observations when they support your verdict or a timeout/metadata tweak.
7.  **Run evals** before submitting — See [Section 3: Run Evals](#section-3-run-evals). If the task is too easy after your rewrite, consider whether expanding PR scope is appropriate.
8.  **Compile your findings** and submit via the platform.
9.  **Zip the task correctly before re-uploading** — When submitting a corrected task, zip the flat contents of `task/` (not the `task/` folder itself, and not `runs/`) from the terminal: `cd task && zip -rX ../<your_task>.zip . -x '*.DS_Store' '__MACOSX/*'`. Avoid GUI compress tools and `zip -rD`, since both can silently drop empty directory entries (such as `.git/refs/` after `git gc`), which breaks the repository on the platform even though everything still runs fine locally. (See [How to Zip the Task](#how-to-zip-the-task) for the full command breakdown.)

**Remember:** *Your goal is a thorough, exhaustive review of the task's* **logic and content***. Check for coherent instructions, aligned tests and solution artifacts, sensible metadata, and use of runs/ when relevant. If you miss key findings or your submission lacks detail, the task may be sent back for revision.*

## How to Zip the Task <a id="how-to-zip-the-task"></a>

When you re-upload a corrected task, the archive must contain the **flat contents of `task/`** — not the `task/` folder itself, and not `runs/`. Build it from the terminal:

```
cd task
zip -rX ../<your_task>.zip . -x '*.DS_Store' '__MACOSX/*'
```

**Command breakdown:**

-   `cd task` — run from *inside* `task/` so the archive holds its contents at the top level (it unpacks directly to `instruction.md`, `task.toml`, `environment/`, `solution/`, and `tests/`).
-   `zip -rX` — `-r` recurses into subdirectories; `-X` strips the extra macOS attributes (resource forks, UID/GID) for a clean, portable archive.
-   `../<your_task>.zip` — write the archive one level *up*, outside `task/`, so it isn't included in itself.
-   `.` — add everything in the current directory (the contents of `task/`).
-   `-x '*.DS_Store' '__MACOSX/*'` — exclude macOS junk entries.

**Why not GUI compress or `zip -rD`:** GUI "Compress" tools add `__MACOSX/` and `.DS_Store` entries and can omit empty directories. The `-D` flag in `zip -rD` tells zip *not* to create directory entries, so empty directories such as `.git/refs/` (common after `git gc`) are dropped from the archive — the repo then unpacks without them and git operations fail on the platform, even though the uncompressed copy works locally. `-rX` (no `-D`) preserves those directory entries.

**Verify before uploading** — the empty git directories should still be listed in the archive:

```
unzip -l <your_task>.zip | grep 'refs/'
```

## Step-by-Step Submitter Form Questions <a id="step-by-step-submitter-form-questions"></a>

### Section 1 · Task Metadata <a id="section-1-task-metadata"></a>

Download the task zip provided at the top of the form. It contains the task you'll inspect and make corrections to.

### Section 2 · Task Analysis <a id="section-2-task-analysis"></a>

**What is your analysis of the Sentinel task you downloaded above?**

> **Note:** **Note:** This question appears twice in the platform, and both are required. Please make sure that both answers are the same.

-   **Fixable** — The task has issues in the instructions, tests, and/or oracle, but you can correct all issues.
-   **Invalid/Not Fixable** — The task is invalid and/or unfixable, as it requires changes outside of the instructions, tests, or oracle, or is invalid for other reasons.
-   **Valid as-is** — The task is valid without changes.

* * *

**If Valid as-is:**

Confirm the task complies with **all** of the following requirements (you must check every item):

-   Every requirement in the instructions is properly tested
-   All test requirements are properly specified in the instructions
-   The instructions do not sound like an LLM generated them
-   The instructions are not overly-prescriptive
-   The task does not leak solution information
-   The oracle implements the solution following the instructions
-   Contains more than 10 fail-to-pass tests in the test suite

Before submitting, **run the oracle and NOP tests locally** to confirm the task passes. Valid as-is tasks aren't re-run by the platform's difficulty evals, so this is the only check on them.

* * *

**If Fixable:**

1.  **Select where the task had issues** (check all that apply):

    -   Instructions
    -   Tests
    -   Oracle Solution
    -   Environment / Dockerfile
2.  **What issues did you find with the task?** (check all that apply):

    -   Every requirement in the instructions is not properly tested
    -   All test requirements are not properly specified in the instructions
    -   The instructions appear LLM generated
    -   The instructions are overly-prescriptive
    -   The task leaks solution information
    -   The oracle does not implement the solution following the instructions
    -   Less than 10 fail-to-pass tests in the test suite
3.  **Describe each issue in detail** — For each issue category selected above, use this format:

    > **Note:** 1) \[Issue Category\] — describe the specific issue with code examples where helpful
    > — Is this issue fixable or not fixable?
    > — If fixable, how? If not, why not?
    > 2) \[Issue Category 2\]...

4.  **Re-upload the entire corrected task as a single zip file.** Submit it as `<all-task-content>` — do not include `runs/` or the `task/` directory itself. The zip should unpack directly to `instruction.md`, `task.toml`, `environment/`, `solution/`, and `tests/`.

    > **Note:** **After you upload, you'll run evals and iterate right away** — keep re-running and fixing until the checks pass and the task is error-free, then come back and fill in the rest of this form. See [Section 3 · Run Evals](#section-3-run-evals) below. Running the oracle and NOP locally in Harbor is recommended for Fixable tasks — the platform's evals run them when you submit, but a local run saves you an eval round-trip.

5.  **Files Changed** — List every file you changed. For each file, include:

    -   File path
    -   What changed
    -   Why you changed it
        *(You do not need to repeat full validation details here if you already included them in the validation section.)*
6.  **If you added to the PR in any way, explain how.** If you did not modify the PR in any way, write "NA". Remember you may not change or reduce the scope of the PR, but you may expand on it to add complexity.

7.  **Confirm your corrected task meets all the following requirements** (you must select all):

    -   Every requirement in the instructions is properly tested
    -   All test requirements are properly specified in the instructions
    -   The instructions do not sound like an LLM generated them
    -   The instructions are not overly-prescriptive
    -   The task does not leak solution information
    -   The oracle implements the solution following the instructions
    -   The PR was not modified in any way beyond what is allowed by the guidelines
    -   More than 10 fail-to-pass tests in the test suite
8.  **How long did it take you to complete the initial task rewrite only?** (in minutes)


* * *

**If Invalid/Not Fixable:**

1.  **What issue did you find with the task/components?** (check all that apply):

    -   PR scope needs to be changed or reduced
    -   Environment Issues
2.  **If Environment Issues was selected above, what specific issues did you find with the task?** (check all that apply):

    -   Image/Dependency Build Failures
    -   Oracle timeout
    -   External-network dependency at build/solve time
    -   Dirty git history that can't be recovered — rare; most git issues are fixable (see [Git — fixable in the repo](guidelines.md#git-fixable)), so only select this for genuinely unrecoverable corruption
3.  **Explain in more detail why this task is unfixable** — Describe each issue clearly. Vague or incomplete descriptions may lead to the submission being rejected.


* * *

**For Valid as-is and Fixable tasks:**

-   **What makes this task difficult?** Describe what makes the task technically challenging — edge cases, implementation dependencies, requirements that may be overlooked on first reading, or complexity in the test setup. See [PR Scope and Task Difficulty](guidelines.md#pr-scope-and-task-difficulty) in the Guidelines for what counts as good vs. bad difficulty.

* * *

**Final Comment and Handling Time (all paths):**

-   **Comments for Reviewer** — Flag anything that would help the reviewer understand the task and your decisions: assumptions you made, edge cases you considered, reasons you didn't change a file, or parts of the task that may warrant reviewer judgment or a second opinion.
-   **How much time would you estimate a senior engineer, familiar with the codebase, would take to solve this?**
    -   <10 minutes
    -   10–20 minutes
    -   20–40 minutes
    -   40+ minutes
-   **How long did it take you to review the initial task and determine its validity?** (in minutes)
-   **How long did it take you to complete this entire submission?** (in minutes — if the task is sent back for revision, adjust this number to include the additional time)

### Section 3 · Run Evals <a id="section-3-run-evals"></a>

Once you've made changes, the platform runs automated checks on your task and surfaces feedback you can use to iterate. These checks catch issues before your task reaches a reviewer. (This Submission Feedback section appears for Fixable tasks.)

**Static Checks**

Click **Check feedback** under Static Checks for instant feedback on the task (structure and Dockerfile validation). These must pass for the task to be eligible for submission.

**Summary fields**

After your bundle runs, three read-only summaries are populated:

-   **Difficulty Check** — Results of the agent simulation and stats for each verifier.
-   **Oracle Check** — Results of running the golden solution against the verifiers.
-   **Quality Check** — an agentic rubric-panel judge that scores your task and **can block submission**. A failing verdict sends the task to `NEEDS_REVISION` just like a failing difficulty or oracle check. See [Quality Check — the agentic rubric-panel judge](#quality-check-agentic-judge) below.

You can also **Download difficulty check results** for the full logs, useful for debugging specific failures. Run the checks as many times as you need; each run produces fresh feedback.

**Send to Reviewer**

Check **Send to reviewer** to send the task to the reviewer once difficulty and quality checks are passing. If checks are failing when this is checked, the task will always result in revision — if you are intentionally sending it with failing checks, leave detailed comments for the reviewer explaining why.

*Note: In-app checks have a 5-minute runtime limit. If your task needs longer agent runs to fully evaluate, iterate with the box unchecked first.*

**What to Do When Checks Fail**

The goal is to revise and re-run until there are no failures before sending to the reviewer.

1.  Review the summaries and download the full logs to understand the failure.
2.  Revise your task (instruction, tests, solution, or Dockerfile as needed — within editing rules).
3.  Re-upload and re-run with Send to reviewer unchecked.
4.  Repeat until checks pass, then check Send to reviewer and submit.

#### Quality Check — the agentic rubric-panel judge <a id="quality-check-agentic-judge"></a>

When you run evals, an automated rubric panel now reviews your task the same way a human reviewer would. Two independent LLM judges (Claude Opus and GPT-5.5) each read your instruction, tests, oracle solution, and task directory, and score the task against four rubrics (10 axes total, each 1–5). Where the two judges disagree by 2 or more points on an axis, a third blinded adjudicator settles it. The result appears in the Quality Check summary after your bundle runs, with a per-axis report and justifications that cite specific files and lines — read them; they tell you exactly what to fix.

**This is a blocking eval.** A failing verdict sends the task to `NEEDS_REVISION`, just like a failing difficulty or oracle check.

##### The 10 axes <a id="quality-check-the-10-axes"></a>

| Rubric | Axes | What it reads |
| --- | --- | --- |
| Instruction quality | realism, clarity, self-containedness, prescriptiveness | `instruction.md` + environment only |
| Test quality | **test_coverage, test_faithfulness** | instruction + every test file |
| Oracle quality | spec faithfulness, no gaming, robustness/reproducibility | instruction + `solution/` |
| Packaging | packaging | directory listing + `task.toml` + Dockerfile |

##### What actually blocks your submission <a id="quality-check-what-blocks"></a>

The pass/fail verdict is driven by the two test-quality axes only: **test_coverage** and **test_faithfulness**. The other eight axes are scored and shown in the report (fix them — reviewers see them too), but they don't flip the verdict on their own.

The verdict logic:

-   **REMOVE** (fails, `NEEDS_REVISION`) — the adjudicated score on either test axis is ≤ 2.0, or either judge scored an axis ≤ 2 and the failure matches one of the "essential" patterns below.
-   **DISCUSS** (fails, `NEEDS_REVISION`) — any single judge scored either test axis ≤ 2, or the adjudicated score on either axis is ≤ 3.0.
-   **OK** (passes) — both test axes land above 3.0 with no judge at ≤ 2.

> **Note:** **Practical bar:** both judges need to rate your test suite a solid 4+ on coverage and faithfulness. A single "3 with reservations" from one judge is enough to bounce the task. Borderline scores round down by design — don't argue with a 3, fix it.

##### The two questions the judge asks about your tests <a id="quality-check-two-questions"></a>

Both axes are two sides of the same question: *is the verifier a fair grader of the contract written in the instruction?* This is exactly the [Test ↔ instruction alignment](guidelines.md#test-instruction-alignment) principle in the Guidelines — the judge now enforces it mechanically, in both directions:

-   **Coverage (Instruction → Tests):** every requirement stated in the instruction has a real, enforcing assertion. A broken or stub solution must fail at least one test. Gaps here mean **false positives** — an agent gets reward 1.0 without doing the work.
-   **Faithfulness (Tests → Instruction):** every assertion maps back to something stated or reasonably implied in the instruction. Hidden requirements mean **false negatives** — a competent engineer who follows the instruction exactly still fails.

##### Patterns that trigger an automatic REMOVE <a id="quality-check-remove-patterns"></a>

These six patterns are treated as customer-essential defects. If a judge scores a test axis ≤ 2 and cites one of these, the task is removed outright — no "discuss" middle ground:

| Pattern | What it looks like in a task |
| --- | --- |
| Silent skip | `@pytest.mark.skip`, `skipif`, catching `ImportError` and setting the module to `None`, or any construct that lets substantive tests silently not run. If a dependency is missing, the test must fail, not skip. |
| No CLI/entry-point invocation | The instruction asks for a CLI, service, or script, but `test.sh` only runs pytest against library internals and never actually invokes the thing being built. |
| Pre-created artifact passes | Tests assert a file exists (`path.exists()`, `is_file()`) without checking its contents, so `touch`\-ing the right filename passes. Every existence check must be paired with a content/behavior assertion. |
| Agent controls coverage | Tests iterate over whatever the agent's own output reports (e.g. loop over entries in the agent's JSON and validate each) — the agent can shrink its output to shrink the test surface. Enumerate expected items from the instruction/environment, never from agent output. |
| Fail-open | `if not output.exists(): return`, `try: ... except Exception: pass`, assertions gated behind preconditions that may not hold. A missing or malformed artifact must fail the suite, never pass it. |
| Overreach | Tests enforce names, formats, thresholds, paths, or conventions the instruction never states (the [arbitrary naming problem](guidelines.md#the-arbitrary-naming-problem) already in the Guidelines — now machine-checked). |

##### Test-writing checklist <a id="quality-check-test-writing-checklist"></a>

**Do:**

-   Map every imperative, named output field, named edge case, and named threshold in the instruction to at least one assertion. The judge literally builds this bipartite mapping; build it yourself first.
-   Test observable behavior at the instruction's stated strictness — if the instruction says "all rows", don't assert "at least one row"; if it names a threshold, assert the threshold, not just `isinstance(score, float)`.
-   Include the regression test that reproduces the original failure (fails pre-patch, passes post-patch) — already required; the judge checks for it.
-   Keep tests deterministic: fixed seeds, no order dependence, no wall-clock or network dependence.
-   Commit fixtures and mock data into the verifier image so the agent can't tamper with them.
-   If the instruction requires a specific output format/schema, state it in the instruction — that makes your format assertions faithful instead of hidden.

**Don't:**

-   Don't assert on source code text (substring/keyword scans like `"deque" in source`) — the judge flags source-pattern checks as unfaithful, and they're trivially gamed anyway.
-   Don't embed verifier-only constants (`EXPECTED_COUNT = 47`) the agent can't derive from the instruction and environment.
-   Don't compare against hidden golden files the instruction never foreshadows.
-   Don't compute the expected value from the agent's own output (circular checks).
-   Don't require exact error strings, JSON key orderings, whitespace styles, tolerances, or file paths unless the instruction (or an existing codebase/framework convention) fixes them.
-   Don't wrap test bodies in broad `try/except` — ever.

##### The advisory axes still matter <a id="quality-check-advisory-axes"></a>

The other eight axes appear in the Quality Check report and in what your reviewer reads, and they reinforce existing guideline requirements:

-   **Instruction axes** — the judge rewards instructions that read like a real ticket (realism), fully specify success (clarity), reference only artifacts that exist in the repo (self-containedness), and state requirements, not procedure (prescriptiveness). Detailed output schemas and conventions are fine and score well; ordered how-to steps, file localization hints ("the bug is in `helpers/queue.py`"), and pre-answered edge cases score badly — the same over-prescription rules already in [Clarity & No Leakage](guidelines.md#2-clarity-no-leakage).
-   **Oracle axes** — the oracle must implement every instruction requirement with the correct logic (spec faithfulness), must genuinely do the work — no hardcoded answers, no fabricated tool output, no reading test-side ground truth, no fixture-specific shortcuts like treating `df['Date'].max()` as "today" (no gaming) — and must be reproducible: seed randomness, no live network calls, timeouts on subprocesses (robustness). Litmus test the judge applies: *"if the inputs were reshuffled within the spec, would this oracle still produce the right answer?"*
-   **Packaging** — a single stray developer artifact that ships into the container (`__pycache__/`, `.DS_Store`, `.venv/`, `.pytest_cache/`, `.idea/`, `.vscode/`, editor swap files, `.ruff_cache/`, `node_modules/`) hard-caps this axis at 1, as does any solution leakage into agent-readable paths. See the [Before You Upload](#before-you-upload) hygiene checklist.

##### If the Quality Check fails <a id="quality-check-if-it-fails"></a>

1.  Download the report and read the per-axis justifications — they cite the exact files, line ranges, and quoted instruction text behind each score.
2.  Fix the cited defect. For coverage gaps, add or strengthen assertions; for faithfulness defects, either move the requirement into the instruction or relax the assertion.
3.  Keep instruction, tests, and oracle in lockstep (per the existing editing rules), re-upload, and re-run with Send to reviewer unchecked until the check passes.

## Step-by-Step Reviewer Form Questions <a id="step-by-step-reviewer-form-questions"></a>

Each submission is reviewed by another Expert Contributor (EC). The reviewer’s role is to independently verify the submitter’s findings, assess the quality and completeness of the analysis, and confirm that conclusions are supported by evidence from the task files and review process.

Reviewers should repeat the same document and logic review performed by the submitter. You're not required to run Harbor end-to-end, execute the Oracle or NOP tests, or build Docker images locally — but you may if it helps you verify a finding.

### Review Outcomes <a id="review-outcomes"></a>

-   **Accept** — The submission is accurate, complete, and well-supported.
-   **Needs Revision** — The task has authoring errors in the instruction, tests, oracle, or bundle that the original submitter can fix.
    -   Note: Severity of the submitter errors are captured in the [Submission Quality Score](#submission-quality-score)
-   **Reject** — Use this **only** when a submission has already been through the **maximum number of revision cycles** and still needs more work. Reject is not a substitute for Needs Revision: as long as the submitter can still revise, choose **Needs Revision** so they get another chance to fix the task.

You'll know you've reached this case because **Needs Revision** is no longer available. If you select Needs Revision and try to submit, the platform blocks you with a **"Maximum Revisions Reached"** dialog:

> **Note:** **Maximum Revisions Reached**
> This submission has reached its maximum revision limit. The "Needs Revision" option is not available. If the submission does not meet quality standards, select **Reject**. If Reject is not available for this workflow, **Accept** and add notes explaining the issues.
>
> *Reviewer-only note: Your notes will be visible to the adjudicator.*
> \[ I Understand \]

When you see that dialog, click **I Understand**, then select **Reject**. If Reject isn't available for the workflow, select **Accept** and document the outstanding issues in your notes so the adjudicator can see them.

### Reviewer Responsibilities <a id="reviewer-responsibilities"></a>

-   Reviewers reach their own independent assessment of the task, then give a verdict of **Accept**, **Needs Revision**, or **Reject** — regardless of whether it matches the submitter’s original rating. Reject is reserved for submissions that have exhausted their revision cycles (see [Review Outcomes](#review-outcomes)).
-   Reviewers are also evaluated on the quality of their feedback and the thoroughness of their review. Consistently low-quality reviews or feedback that does not meet project standards may result in removal from the project.
-   Reviewers must check the **Comments for Reviewer** field before completing the review and acknowledge whether the submitter's notes changed their decision.

### When the submission is **Valid As-Is** <a id="when-the-submission-is-valid-as-is"></a>

The reviewer should repeat the submitter’s **content review** and confirm the task reads as sound on inspection.

1.  **Repeat the submitter’s workflow** — Download the task package and follow the same steps as in [Detailed Tasking Steps](#detailed-tasking-steps): instruction, PR cross-check, environment skim, solution and test read-through, and runs/ as context. You're not required to run Harbor, the oracle, or NOP locally, but you may if it helps.
2.  **Sanity-check coherence** — Confirm instruction, solution artifacts, and tests appear aligned with each other and with the source PR; flag any logic gaps the submitter missed.
3.  **Verify task metadata** — Confirm that the task task.toml metadata is complete and accurate. Recall that only the source, verifier, agent, and environment timeouts affect validity.
4.  **Confirm PR comparability** — The submitted task should not deviate from the original PR scope. Check this even on Valid as-is submissions.

### When the submission is **Not Fixable/Invalid** <a id="when-the-submission-is-not-fixable-invalid"></a>

The reviewer should try to confirm the submitter’s results and confirm that the submitter’s notes are correct and adequately describe the situation.

1.  **Confirm the reported issues** — Follow the same document review as for a valid submission. For each issue the submitter listed, confirm it holds when you read the same files (e.g. instruction vs tests, patch vs PR, missing coverage, inconsistent solution).
2.  **Compare against the submitter’s findings** — Check that the submission’s issue list (e.g. Issue 1, Issue 2, …) matches what you see on inspection. Verify that categories (instruction, environment, solution, tests, etc.) and descriptions are accurate.
3.  **Confirm the Not Fixable category applies** — Reviewer should agree the reason matches one of the [Not Fixable categories](guidelines.md#task-verdicts) defined in the Guidelines.

### When the submission is Fixable <a id="when-the-submission-is-fixable"></a>

The reviewer should confirm that the submitter correctly identified fixable issues and that the rewritten instructions and/or tests appropriately resolve those issues without introducing new inconsistencies, hidden requirements, or information leakage.

1.  **Review rewritten artifacts** — Inspect the uploaded rewrites and confirm that they resolve the reported issues, preserve instruction ↔ test alignment, maintain solvability, and do not introduce unnecessary implementation constraints or verifier leakage.
2.  **Validate task quality after rewrites** — Confirm that the corrected task still reflects the intended PR behavior, remains realistic and solvable, and does not introduce new hidden requirements or inconsistencies.
3.  **Verify PR comparability —** If the submitter expanded oracle scope, confirm the expansion only adds to the original PR. The task should not have been reduced or changed to a different feature. See [PR scope rules](guidelines.md#pr-scope-rules) in the Guidelines.
4.  **Verify uploaded files —** Confirm that the upload contains the full corrected task bundle.
5.  **Review agent logs —** Where relevant, review the provided agent logs to see how agents interpreted the task and whether the submitter's feedback (e.g. "agent times out" or "instruction ambiguous") is supported by the evidence.

### Reviewer Form Questions <a id="reviewer-form-questions"></a>

1.  **What is your verdict for this submission?**

    -   **Accept** — Agree with the Valid / Invalid selection by the submitter and any applied fixes.
    -   **Needs Revision** — Any task that still contains errors.
    -   **Reject** — Use this **only** if you are seeing the "maximum revision reached" notification **and** the submission still needs more revisions. See [Review Outcomes](#review-outcomes) above.
2.  **If Accept:** Confirm the task meets all of the following requirements (check all that apply):

    -   Tests every requirement in the instructions
    -   Test requirements are specified in the instructions
    -   Does not appear generated by an LLM
    -   Does not leak solution information
    -   Oracle solution matches the instruction requirements
    -   Instructions are not overly-prescriptive
3.  **If Needs Revision — Error Categories:** Tag the issues you found in the submitted task that led to your Needs Revision decision. These may be issues the submitter introduced or base-task issues they failed to catch or correct. Select all that apply — these labels are for internal tracking only and do not replace thorough revision notes.

    -   Instruction Styling
    -   Instruction Prescriptiveness
    -   Test ↔ Instruction Misalignment
    -   Test Coverage Issues
    -   Exposing Hints/Answers
    -   Oracle Solution Issues
    -   PR Scope Violation (e.g., reduced or replaced PR scope rather than adding to it)
    -   Test Build Issues
    -   Time-Based Tests
    -   Task Difficulty
    -   Metadata Issues
    -   Uses Internet
    -   Agent Timeout
    -   Wrong Coding Language
    -   Test Dependency Location
    -   Pinning Issues
    -   Environment
    -   PR Relevancy
    -   Other
4.  **If Needs Revision:** Explain in more detail what revisions are needed from the submitter based on your selection(s) above.

5.  **Acknowledgement of Submitter Rebuttal:** Before submitting, open the rebuttal comments in the left-hand panel and read the submitter's notes in full. Confirm one of the following:

    -   I read the submitter's rebuttal and it does not change my review outcome.
    -   I read the submitter's rebuttal and revised my review outcome accordingly.
    -   No rebuttal comments available.
6.  **What is the overall quality of the submission?** *(Based on Submission Quality Score below)*

7.  **How long (in minutes) did it take you to complete this review?**


### Submission Quality Score <a id="submission-quality-score"></a>

You’ll then give the submission an overall quality score. This rating should reflect the accuracy, completeness, reasoning, and specificity shown in the submission.

| Score | Description | Action |
| --- | --- | --- |
| **1** | The submitter has deviated from the provided source content (e.g., wrong PR, substituted repo code, or otherwise diverging from the source asset), or the submission is low-effort, sloppy, or appears to be spam. | **NEEDS REVISION** |
| **2** | The source material is intact but execution has noticeable gaps — untested requirements, instruction/test misalignment, or bundle mismatches — that need meaningful revision. | **NEEDS REVISION** |
| **3** | The task is correct and complete; any remaining issues are too minor to warrant sending back for revision. | **ACCEPT** |
| **4** | All components (instruction, oracle solution, tests, bundle) are thorough and accurate with no significant issues. | **ACCEPT** |
| **5** | Every component is precise, well-reasoned, and clearly written — a reference-quality submission requiring no changes. | **ACCEPT** |


---

# The Harbor Framework

# The Harbor Framework

Background reference for Sentinel contributors

Tasks follow the [Harbor format](https://harborframework.com/docs) and are evaluated internally using terminal-based execution: Docker environments, solution/solve.sh as the oracle, tests/test.sh for verification, and a reward written by the verifier (e.g. to /logs/verifier/reward.txt). Harbor is a framework for evaluating agents and models in containers.

## Optional context on how tasks are evaluated <a id="optional-context-on-how-tasks-are-evaluated"></a>

-   Terminal-based execution — Tasks run in isolated container environments during internal evaluation
-   Oracle solution — The reference solution is provided as solution/solve.sh, which applies solution/golden.patch (a self-contained patch of all the solution's changes)

**Note — Oracle solutions:** *Task solutions may be larger than strictly necessary or include extra functionality not asked for in the instruction. This is okay as long as the solution does what the instruction requires and tests enforce that. The point of the Oracle is to show that the task is solvable.*

-   Test execution — `tests/test.sh` runs the suite and records the reward outcome
-   Verification — Pass/fail is determined from the test run and reward file
-   Platform-level evals — The platform runs automated checks before tasks reach a reviewer (structure check, Dockerfile check, oracle eval, difficulty eval, general quality).

## Task Structure & Components <a id="task-structure-components"></a>

Each task follows the Harbor format and contains a task directory with the following structure:

```
<task-id>/
├── task/
│   ├── task.toml              # Metadata + pinned image URI, timeouts, resources
│   ├── instruction.md         # Problem statement + measurable success criteria
│   ├── environment/
│   │   ├── Dockerfile         # Container build (base image + setup)
│   │   ├── repo/              # Cloned base repository (agent + verifier run against this)
│   │   └── problem_statement.md  # Restatement of the instruction, set in the environment
│   ├── solution/
│   │   ├── solve.sh           # Applies golden.patch to restore the solved state
│   │   └── golden.patch       # The golden patch — self-contained (all solution changes)
│   └── tests/
│       ├── test.sh            # Runs tests, writes reward to /logs/verifier/reward.txt
│       ├── tests.patch        # Contains the fail-to-pass tests
│       └── config.json        # How to run the suite + which test ids are fail-to-pass / pass-to-pass
└── runs/                      # Execution runs from LLMs/agents (logs, episodes, outcomes)
```

> **Note:** **If the `solution/` folder in your downloaded task contains `solution.patch` instead of `golden.patch`, rename it to `golden.patch`.** `golden.patch` is the current, correct file name — `solution.patch` was a short-lived draft name and shouldn't ship.

The `runs/` folder lives alongside `task/` at the top level of the task directory. It holds the execution runs produced by the LLMs and agents (i.e. the frontier models and agents mentioned in the guidelines). Each subfolder is typically named by model or agent, and contains the logs, episodes, and outcomes for that run. Use this folder as a reference to understand how models run on the task and to identify any task issues.

## Task Metadata <a id="task-metadata"></a>

Each task includes metadata in `task.toml`. The file opens with a `schema_version` (the Harbor format version, **not** the task version) and is organized into `[environment]`, `[agent]`, `[verifier]`, and `[metadata]` sections. **Check these fields on every task** — the resource and timeout values must stay within the limits below.

### **[environment] — resources** <a id="environment-resources"></a>

-   `os` — the container OS (e.g. `linux`).
-   `cpus` — `2` or `4`.
-   `memory_mb` — minimum `2048`, maximum `16384`.
-   `storage_mb` — minimum `5120`, maximum `10240`.
-   `gpus` — always `0`.
-   `build_timeout_sec` — maximum `1800`.
-   `network_mode` — set to `"public"`.

> **Note:** **Network access is set per block — don't strip these fields.** `network_mode` belongs in each of `[environment]`, `[agent]`, and `[verifier]`. Use these values: `[environment]` → `"public"`; `[agent]` → `"allowlist"` with `allowed_hosts = ["api.portkey.ai"]`; `[verifier]` → `"no-network"`. Separately, in `docker_compose.yaml`, remove `network_mode = "none"` entirely if present. A few tasks in certain programming languages may still hit edge cases — if you do, flag the details to the team on Slack.

### **[agent]** <a id="agent"></a>

-   `network_mode` — set to `"allowlist"`.
-   `allowed_hosts` — the hosts the agent may reach; set to `["api.portkey.ai"]`.
-   `timeout_sec` — per-episode limit for the agent; maximum `7200`. Raise it if you see failures caused by agent timeout.

### **[verifier]** <a id="verifier"></a>

-   `network_mode` — set to `"no-network"`.
-   `timeout_sec` — verifier run limit; maximum `1800`.

### **[metadata] — free-form** <a id="metadata-free-form"></a>

-   `category` (and subcategory) — the task's primary classification; edit if needed.
-   `difficulty_explanation` — why the task warrants its difficulty tier; edit if needed.
-   `source` — URL of the source PR / commit / issue the task derives from.

### **Example `task.toml`** <a id="example-task-toml"></a>

```
schema_version = "1.3"            # Harbor format version (NOT the task version)

# ── [environment] ── resources ───────────────────────────────────────
[environment]
os                = "linux"
cpus              = 2          # 2 or 4
memory_mb         = 2048       # min shown; max 16384
storage_mb        = 5120       # min shown; max 10240
gpus              = 0          # always 0
build_timeout_sec = 600        # max 1800
network_mode      = "public"

# ── [agent] ── per-episode ceiling ───────────────────────────────────
[agent]
network_mode  = "allowlist"
allowed_hosts = ["api.portkey.ai"]
timeout_sec   = 300            # max 7200 — raise if you see agent-timeout failures

# ── [verifier] ───────────────────────────────────────────────────────
[verifier]
network_mode = "no-network"
timeout_sec  = 120             # max 1800

# ── [metadata] ── free-form ──────────────────────────────────────────
[metadata]
category               = "security"                            # edit if needed
difficulty_explanation = "expert-level cybersecurity problem"  # edit if needed
source                 = "https://github.com/org/repo/pull/1234"
```


---

# Glossary

# Glossary

Key terms used across Sentinel Ultra

Key terms used across these guidelines, the Tasking Guide, and the platform. Where a different word is sometimes used for the same thing, both are noted. Links point to the section that covers each term in depth.

## Roles & workflow <a id="roles-workflow"></a>

| Term | Meaning |
| --- | --- |
| **EC (Expert Contributor)** | You — the person reviewing, fixing, and validating tasks. Your step-by-step process lives in the [Tasking Guide](tasking-guide.md). |
| **Submitter** | The EC who reviews a task, decides its verdict, and fixes it if needed. See [Submitter form questions](tasking-guide.md#step-by-step-submitter-form-questions). |
| **Reviewer** | A second EC who independently verifies the submitter's work. See [Reviewer form questions](tasking-guide.md#step-by-step-reviewer-form-questions). |
| **Adjudicator** | A final reviewer who resolves disagreements between submitter and reviewer. |
| **Source PR / commit / issue** | The real upstream change a task is derived from and anchored to. Every task comes from a real source — there are no net-new tasks. See [PR Scope and Task Difficulty](guidelines.md#pr-scope-and-task-difficulty). |
| **PR scope** | What the task is fundamentally about. You may *expand* it to add difficulty, but never reduce or replace it — see [PR scope rules](guidelines.md#pr-scope-rules). |

## Task anatomy <a id="task-anatomy"></a>

| Term | Meaning |
| --- | --- |
| **Harbor** | The framework/format every task is built in. See the [Harbor Framework tab](harbor-framework.md) or the [Harbor documentation](https://harborframework.com/docs). |
| **Task** | A single software-engineering problem in Harbor format: instruction, environment, solution, and tests. See [Task Structure](harbor-framework.md#task-structure-components). |
| **`instruction.md`** | The problem statement the agent receives — what to do and how success is measured. |
| **`problem_statement.md`** | A restatement of the instruction placed inside the environment. |
| **`task.toml`** | Task metadata: pinned image URI, resource budget, timeouts, source, and difficulty fields. See [Task Metadata](harbor-framework.md#task-metadata). |
| **Environment** | The container the task runs in — the `Dockerfile` plus `repo/` (the cloned base repository). For what can go wrong here, see [Environment Issues](guidelines.md#environment-limited-fixes). |
| **`runs/`** | Logs of past agent attempts, delivered alongside the task as reference. |

## Solution (oracle) <a id="solution-oracle"></a>

| Term | Meaning |
| --- | --- |
| **Oracle** (a.k.a. golden solution, reference solution) | The known-correct solution that proves the task is solvable. See [Task Structure](harbor-framework.md#task-structure-components) and [Rewriting the Oracle](guidelines.md#solution-oracle-editable-in-two-cases). |
| **`solve.sh`** | Script that applies the golden patch to bring the repo to the solved state. |
| **`golden.patch`** (a.k.a. gold patch; formerly `init_state.patch`) | The self-contained patch containing all of the solution's changes. If a task ships with `solution.patch` instead, rename it to `golden.patch` — that was a short-lived draft name. |

## Tests & grading <a id="tests-grading"></a>

| Term | Meaning |
| --- | --- |
| **Fail-to-pass (f2p) tests** | Tests that fail on the unsolved repo and pass after the fix — the core behavioral checks. At least 10 are required; see [Verifiability](guidelines.md#3-verifiability). They live in `tests.patch`. |
| **Pass-to-pass (p2p) tests** | Tests that must pass both before and after the fix; a regression guard. |
| **`tests.patch`** | The patch containing the fail-to-pass tests. |
| **`config.json`** | Declares how the suite runs and which test ids are fail-to-pass vs pass-to-pass. |
| **`test.sh`** | Runs the suite and writes the reward. |
| **Verifier** | The component that runs the tests and computes the reward. See [how tasks are evaluated](harbor-framework.md#optional-context-on-how-tasks-are-evaluated). |
| **Reward** | The pass/fail signal: 1.0 only if every fail-to-pass test passes and no pass-to-pass test regresses. |

## Quality & difficulty <a id="quality-difficulty"></a>

| Term | Meaning |
| --- | --- |
| **Agent** | The model or coding agent attempting the task. |
| **Reward hacking** | Passing the tests without doing the intended engineering work (e.g. editing the tests, hardcoding outputs). Preventing this is a central goal — see [Verifiability](guidelines.md#3-verifiability). |
| **Difficulty bar / pass@k** | The benchmark threshold a task must clear — e.g. a frontier model solves a Medium task in ≤ 4 of 8 attempts, a Hard task in ≤ 2 of 8. See [Task difficulty](guidelines.md#task-difficulty). |
| **Outcome-based test** | A test that checks observable behavior by running code, not by inspecting diffs, file names, or source keywords. See [outcome-based tests](guidelines.md#outcome-based-tests). |


---

# FAQ

# FAQ

Frequently asked questions

Common questions about working on Sentinel Ultra. If your question isn't here, reach out to the team on the Slack channel.

## Is there a daily limit to how many tasks I can do? <a id="is-there-a-daily-limit-to-how-many-tasks-i-can-do"></a>

As of **July 1, 2026**, there's no daily cap on how many tasks you can complete. There is one throughput rule: you can have at most **two tasks in the "pending revision" stage** at once. While you're at that limit, the platform won't let you claim a new task until one of those clears — so keep your in-revision tasks moving.

## How do I decide between Valid as-is, Fixable, and Not Fixable? <a id="how-do-i-decide-between-valid-as-is-fixable-and-not-fixable"></a>

-   **Valid as-is** — the task already meets every requirement; no changes needed.
-   **Fixable** — the task has issues in the instructions, tests, and/or oracle, but you can correct all of them yourself.
-   **Not Fixable** — the only way to make the task valid would be to reduce or replace the PR scope, or the environment has issues you're not allowed to fix.

See [Task Verdicts](guidelines.md#task-verdicts) and [the four core principles](guidelines.md#the-four-core-principles) in the Guidelines for the full criteria.

## A task won't build, or the environment looks broken — what do I do? <a id="a-task-won-t-build-or-the-environment-looks-broken-what-do-i-do"></a>

Check the **Environment** panel in the Guidelines ([What you can edit → Environment](guidelines.md#environment-limited-fixes)). It lists exactly which environment problems you're allowed to fix (e.g. a missing `bash`, an unpinned base image, missing `tmux`) versus the ones that make a task **Not Fixable** (e.g. tangled dependency/build failures or external-network dependencies). If it's on the fixable list, correct it; if not, mark the task Not Fixable and explain why.

**Git problems are fixable.** Leaked fix history, a remote, a `HEAD`/base-commit mismatch, a reflog, or an oversized `.git` don't make a task Not Fixable — do the git work inside `environment/repo`, re-zip, and realign `task.toml` to `HEAD` if needed (the shipped repo is the source of truth). See the [Git — fixable in the repo](guidelines.md#git-fixable) panel for the issue-by-issue fixes and a checklist. You still may not edit the repo's tracked source files.

## I'm getting a nonzero exit-code agent error — what should I try? <a id="i-m-getting-a-nonzero-exit-code-agent-error-what-should-i-try"></a>

First work through the usual troubleshooting: the [Before You Upload](tasking-guide.md#before-you-upload) checks (build the Dockerfile locally, confirm `tests.patch` applies to the base commit) and raise the [`[agent]` `timeout_sec`](harbor-framework.md#agent) if runs are timing out. Also confirm your `task.toml` [network_mode](#which-network-mode-should-my-task-toml-use) is set correctly per block.

If the task *still* fails with a nonzero exit-code agent error after that, try **removing `curl` from the package installs in your `environment/Dockerfile`** and rebuild. This is a known Harbor edge-case bug the team is working on fixing; for now, dropping the `curl` install is the simplest workaround, and it only affects a small subset of tasks. If removing `curl` doesn't resolve it — or the task genuinely needs `curl` — flag it to the team on the Slack channel with the task/submission UID.

## Which network_mode should my task.toml use? <a id="which-network-mode-should-my-task-toml-use"></a>

Network access is set **per block** — don't strip these fields (older guidance to remove `network_mode`/`allowed_hosts` is outdated):

-   `[environment]` → `"public"`
-   `[agent]` → `"allowlist"` with `allowed_hosts = ["api.portkey.ai"]`
-   `[verifier]` → `"no-network"`

Also, in `docker_compose.yaml`, remove `network_mode = "none"` entirely if present. A few tasks in certain programming languages may still hit edge cases — if you do, flag the details to the team on Slack. See the full example in [Task Metadata](harbor-framework.md#task-metadata). If your agent run is failing, also check the [nonzero exit-code agent error](#i-m-getting-a-nonzero-exit-code-agent-error-what-should-i-try) FAQ.

## How should I set the agent timeout, and what if the task keeps timing out? <a id="how-should-i-set-the-agent-timeout-and-what-if-the-task-keeps-timing-out"></a>

The timeout is the **maximum** time the agent gets — set it generously rather than tight, since a low ceiling fails tasks that would otherwise pass.

-   **If the agent is timing out,** raise [`[agent]` `timeout_sec`](harbor-framework.md#agent) — up to the maximum of **7200**.
-   **If it still times out at 7200,** open the `runs/` logs to see *where* the agent is spending its time — it's often one slow step or a harness issue, not the task as a whole.
-   **If it genuinely can't finish within 7200,** and the only way to make it fit would be reducing or replacing the PR scope (which isn't allowed), mark the task [Not Fixable / Invalid](guidelines.md#task-verdicts) and note where it was timing out.

## How do I check the status of a submission? <a id="how-do-i-check-the-status-of-a-submission"></a>

Use the `stb submissions list` command to see the current status of your submissions from the CLI — it's the fastest way to check where a task is in the pipeline without waiting on the GUI. If a task appears to intermittently disappear and reappear in the GUI, `stb submissions list` is the source of truth for its actual state. If the CLI and the GUI disagree, or a submission is stuck, flag it to the team on the Slack channel with the submission UID.

## An eval failed with an infra/platform error, or came back with blank feedback — is my task broken? <a id="an-eval-failed-with-an-infra-platform-error-or-came-back-with-blank-feedback-is-my-task-broken"></a>

**No — a platform failure is not a task defect.** Errors like `DaytonaRateLimitError` / `ApiRateLimitError`, sandbox auth/connection errors, a one-off `NonZeroAgentExitCode`, or a run that comes back with blank feedback / "No evaluation information available" are infra issues on our side, not something wrong with your task.

The tell is **inconsistency**: the same task passes on one run and errors on another, or only 1 of N agent runs fails while the rest are clean.

What to do:

-   **Don't mark the task Not Fixable / Unfixable over it.** Infra and platform failures never make a task Unfixable — that verdict is for genuine task defects only.
-   **Don't burn a revision slot resubmitting blindly.** Blank feedback or a dropped result usually means the eval output didn't come through, not that your task failed. Re-running is fine, but don't rework a task that isn't actually broken.
-   **Retry later.** Most of these clear on their own once the platform recovers.
-   **If it persists,** flag it to the team on the Slack channel with the task/submission UID and the exact error. Include whether it's intermittent (passes sometimes) so we can tell an outage apart from a real defect.

When in doubt, check the [submission status](#how-do-i-check-the-status-of-a-submission) — the CLI is the source of truth for where the task actually is.

## The linter rejects my task as "easy" after a difficulty downgrade — what do I do? <a id="the-linter-rejects-my-task-as-easy-after-a-difficulty-downgrade-what-do-i-do"></a>

This is a **known issue** the team is working through. If a task's measured difficulty comes back harder than its metadata, the fix is *not* to hand-edit the pass-rate/difficulty fields in `task.toml` to satisfy the reviewer, because the linter rejects tasks it reads as "easy" outright — so changing the metadata to match the measured difficulty and satisfying the linter can pull in opposite directions.

Don't fight the linter by tweaking the metadata back and forth. If you hit this conflict, **flag it to the team on the Slack channel** with the task/submission UID and the two values that disagree (the linter's difficulty floor vs. the measured/updated metadata). This is a process/tooling gap, not something you can resolve on your own by editing the task.

## Do I need to run the oracle and NOP tests locally? <a id="do-i-need-to-run-the-oracle-and-nop-tests-locally"></a>

It depends on your verdict:

-   **Valid as-is — yes.** These tasks aren't re-run by the platform's difficulty evals, so run the oracle and NOP locally before submitting to confirm the task passes.
-   **Fixable — optional.** The platform's evals run them when you submit, so a local run is just for your own confidence.

## What counts as "changing the PR scope" vs. "adding complexity"? <a id="what-counts-as-changing-the-pr-scope-vs-adding-complexity"></a>

You may **add complexity** — build on what the original PR already does. You may **not change the scope** — turn it into a different task or shrink it.

Say the source PR adds **CSV export** to a reports page:

-   ✅ **Adding complexity:** make that same feature more capable or more robust — e.g. also let the user pick which columns to export, or handle edge cases the PR missed (empty results, commas and quotes inside cell values, very large exports).
-   ❌ **Changing the scope:** swap it for a *different* feature (PDF export instead of CSV), replace it with something unrelated, or strip it down to be simpler (export only the current page instead of the full dataset).

Rule of thumb: if the task still clearly maps back to the original PR — just bigger or more thorough — that's adding complexity. If it no longer resembles the PR, or does *less* than the PR, you've changed the scope, which makes it **Not Fixable**. See [PR scope rules](guidelines.md#pr-scope-rules) in the Guidelines.


---

# Quick Links

# Quick Links

Handy shortcuts for Sentinel Ultra contributors

- [Snorkel Experts Platform](https://experts.snorkel-ai.com/) — Log in to pick up, submit, and review Sentinel tasks.
- [Snorkel Expert Network FAQ](https://246379476.fs1.hubspotusercontent-na2.net/hubfs/246379476/Snorkel_Expert_Network_FAQ.pdf) — Answers to common questions about the Snorkel Expert Network (PDF).


---

# Changelog

# Changelog

Sentinel Ultra Contributor Guidelines

## Jul 27, 2026

-   Added an FAQ entry on nonzero exit-code agent errors: after the usual troubleshooting (local Docker build, `tests.patch` applies to base, raising the agent timeout), removing the `curl` package install from `environment/Dockerfile` is the current workaround for a known Harbor edge-case bug affecting a small subset of tasks.
-   Corrected the `task.toml` network guidance (reverses the earlier "remove `network_mode`/`allowed_hosts`" instruction): `network_mode` is a per-block field — set `[environment]` to `"public"`, `[agent]` to `"allowlist"` with `allowed_hosts = ["api.portkey.ai"]`, and `[verifier]` to `"no-network"`. Updated the Harbor `[environment]`/`[agent]`/`[verifier]` reference and example `task.toml`, plus the Tasking Guide checks. Separately, remove `network_mode = "none"` from `docker_compose.yaml` if present.
-   Corrected the environment build guidance: the Dockerfile **may use the network at build time** (tasks were never required to build offline). The run-time sandbox is still restricted — the solving agent reaches only the model gateway and the verifier runs airgapped. Reworded the "build offline" checklist item and Detailed Tasking step 3 to focus on reproducible builds (bake test dependencies into the image); the `curl` workaround is unchanged.

## Jul 25, 2026

-   Added a "How to zip the task" note under Git — fixable in the repo: zip the flat contents of `task/` (not `runs/`) with a tool that preserves directory entries (`zip -r` does; `zip -rD` and some GUI tools don't), since silently dropping the empty `.git/refs/` that `git gc` leaves behind breaks the repo on the platform.

## Jul 23, 2026

-   We've made an update to help unblock tasks affected by the difficulty check / timeout issues: the `[agent]` `timeout_sec` ceiling has been raised to **7200** (up from 3600). Please update your tasks to the new max value and resubmit.

## Jul 22, 2026

-   Git issues are now **fixable** rather than mostly Not Fixable. Added a "Git — fixable in the repo" panel under What you can edit, with an issue → why → fix table and a pre-submission checklist: the shipped repo's `HEAD` is the source of truth, so ECs do git work inside `environment/repo` and re-zip — cleaning metadata (remotes, leaked branches/tags, reflog, oversized `.git`) and realigning `task.toml` to HEAD — but still never edit the repo's tracked source files. Slimmed the Environment panel to Dockerfile/build/resource issues, retitled Repo files → "Repo source files — never edit", and updated the Tasking Guide git-hygiene note and the FAQ to match.

## Jul 15, 2026

-   Tasking Guide: renumbered the Submitter Form sections to be sequential — Section 3 · Run Evals (was Section 4) — and nested Quality Check — the agentic rubric-panel judge underneath it as a subsection. Section 1, Section 2, and Section 3 are now h3 headings (were h4) so they surface in the left-nav table of contents.
-   Extended the left-nav table of contents to a third heading level (h4) nested under h3, so subsections like Quality Check show up indented under their parent section instead of only top-level headings appearing.

## Jul 13, 2026

-   Quality Check is now the agentic rubric-panel judge (blocking). Two LLM judges (Claude Opus + GPT-5.5) score every submission against four rubrics (instruction, tests, oracle, packaging — 10 axes), with a third adjudicator settling disagreements. The verdict is driven by test coverage and test faithfulness: tasks scoring ≤ 3 on either axis return \`NEEDS_REVISION\`, and six patterns (silent skips, no CLI invocation, existence-only checks, agent-controlled coverage, fail-open tests, hidden requirements) fail outright. Added a test-writing Do/Don't checklist under Tasking Guide → Section 3 · Run Evals.
-   Added a "Before You Upload" pre-submission hygiene checklist to the Tasking Guide (tests.patch applies to base, pre-existing regression tests untouched, offline Docker build, clean git history, no stray artifacts, task.toml sanity, full local dry run).
-   Detailed Tasking Steps now direct ECs to test in Harbor locally — build the environment (\`docker build environment/\`) and run the oracle (\`solve.sh\` → tests → reward 1.0) — replacing the earlier "you are not building or running the image" guidance. Local oracle/NOP runs are now recommended (not optional) for Fixable tasks.

## Jul 3, 2026

-   Reverted the solution patch file name back to \`golden.patch\` (it was briefly renamed to \`solution.patch\` on Jul 1). Updated across the task structure tree, Rewriting the Oracle, Harbor evaluation note, Tasking Guide step 4, and the Glossary. Added a note under the task structure tree telling ECs to rename \`solution.patch\` to \`golden.patch\` if they see it in a downloaded task.

## Jul 1, 2026

-   Task difficulty: added guidance that an easy task is often overly prescriptive — remove context the agent should discover, and balance context so the task is passable but not instructional.
-   What you can edit: converted the section into collapsible per-component panels (Instructions, Tests, Solution & oracle, Environment, Repo files), with example \`config.json\` and \`test.sh\` inside the Tests panel and the Fixable / Not-Fixable environment tables folded into the Environment panel.
-   Verifiability: split into collapsible panels (alignment, 10+ fail-to-pass tests, outcome-based, regression, deterministic, oracle-independent, arbitrary naming) for easier scanning.
-   Environment: added a reminder that \`problem_statement.md\` must be an exact copy of \`instruction.md\` until packaging automates it.
-   Clarified local runs: Valid as-is submissions should run the oracle and NOP locally before submitting; for Fixable it's optional since the evals run on submission.
-   Added an FAQ tab (now in the top nav) with starter questions: daily task limits, choosing Valid as-is / Fixable / Not Fixable, broken environments, running the oracle/NOP locally, and PR scope vs. adding complexity. Removed the FAQ shortcut from Quick Links.
-   Sprinkled a few small Dr. Bubbles across the site for fun (Harbor, FAQ, Guidelines, Tasking Guide, Glossary).
-   Renamed the solution patch to \`solution.patch\` (formerly \`init_state.patch\`) across the task structure, Rewriting the Oracle, and Glossary.
-   \`task.toml\`: updated the metadata reference and example to the current structure — dropped the \`\[task\]\` and \`\[solution\]\` sections, the \`docker_image\`/\`workdir\` fields, and the pass@k fields; documented the resource/timeout limits (cpus, memory, storage, gpus, build/agent/verifier timeouts); and noted that \`network_mode\`/\`allowed_hosts\` should be removed. Added a step to check \`task.toml\` on every task.

## Jun 30, 2026

-   Updated the task file layout to match the current client spec: \`solution/\` now holds \`solve.sh\` + \`solution.patch\`; \`tests/\` holds \`test.sh\`, \`tests.patch\`, \`config.json\`, and \`grade.py\` (fail-to-pass/pass-to-pass ids are declared in \`config.json\`); \`environment/\` adds \`problem_statement.md\`.
-   Reworked the \`task.toml\` metadata reference to the current schema (\`\[task\]\`, \`\[environment\]\` with pinned \`docker_image\` and \`no-network\`, \`\[agent\]\`, \`\[verifier\]\`, \`\[solution\]\`, \`\[metadata\]\` with \`category\`, \`difficulty_explanation\`, and \`pass_at_k_\*\`).
-   Listed the exact git-hygiene criteria under the Dirty git history environment issue.
-   Restructured the guide around its purpose: a lifecycle intro, a primed "Your Role" overview, a combined "PR Scope and Task Difficulty" section, and the core principles reorganized into four — Solvability, Clarity & No Leakage, Verifiability, and Authenticity.
-   Added oracle expectations (match the canonical upstream fix; no unnecessary changes) and a new Glossary tab that cross-links each term to the section covering it.
-   Tasking Guide: removed the outdated standalone "Issue categories" block (superseded by the Not Fixable branch, which now matches the platform form), fixed broken Google-Docs cross-references, and linked the "What makes this task difficult?" question to PR Scope and Task Difficulty.

## Jun 26, 2026

-   Added Test Suite Requirements: every task must ship with at least 10 fail-to-pass tests (ideally 10–20). Tasks with fewer are Fixable — add tests covering stated or implied requirements during the rewrite.
-   Synced the Tasking Guide submitter and reviewer walkthroughs with the latest platform form: added the ≥10 fail-to-pass test confirmation/issue items, a "what makes this task difficult?" question, and a free-text "how did you add to the PR?" field; replaced the Fix Validation checklist with the Static Checks / Difficulty / Oracle / Quality submission-feedback flow; added Dirty git history to the Not Fixable environment issues; and updated the reviewer error categories and 1–5 quality scale.
-   Removed the Override Difficulty Evals section from the Run Evals walkthrough (the checkbox was removed from the platform).

## Jun 25, 2026

-   Updated Fixable verdict criteria to include solution leakage and oracle/instruction misalignment as fixable issues
-   Updated Not Fixable criteria to match the two platform categories: PR scope reduction and environment issues
-   Submitter form walkthrough fully restructured to match current platform form: added Valid as-is compliance checklist, Fixable issue checklist and post-fix confirmation, Invalid/Not Fixable primary category selection, and timing questions; removed questions no longer in the form
-   Reviewer form walkthrough updated to include the Accept confirmation checklist
-   Added note that the Task Analysis question appears twice in the platform and both responses must match
-   Upload format clarified: download contains \`task/\` + \`runs/\` folders; upload should be flat contents of \`task/\` only

## Jun 24, 2026

-   Moved sections around: moved Verdict section, PR Scope rules, and Core Principles up; moved editable content and how-to-rewrite sections into one section; moved Harbor background info into appendix
-   Moved some info in Verdict section and Core Principles section into tables
-   Removed duplicate info (test alignment table, some info about oracle writing/PR expansion)
-   Removed reference to 2-hour time limits
-   Added guidance that task validity question will be required twice in the EC form
-   Added new guidance for task uploads: upload should be flat contents of \`task/\` only — do not include \`runs/\` or the \`task/\` folder itself
-   Added references to new AHT questions
