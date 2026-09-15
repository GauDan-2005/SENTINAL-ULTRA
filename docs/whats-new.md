<!-- Source: https://snorkel-ai.github.io/Sentinel_Ultra_Hub/ — tab: What's New -->

# What's New

Latest updates to the Sentinel Ultra contributor guidelines

📢 Latest update

Difficulty checks are now capped

As of **August 14, 2026**, once **4 difficulty checks** have run on a task without passing, it's automatically classified as **Invalid Difficulty** and goes to review as it stands — **not** a rejection, and not applied retroactively. You'll see two new read-only fields (*Difficulty checks run* / *remaining*); at the limit, we set the verdict for you — resubmit as-is and leave it in place.

[What is Invalid Difficulty? →](faq.md#difficulty-checks-are-now-capped-what-is-invalid-difficulty)

## Recent updates <a id="recent-updates"></a>

-   Aug 14, 2026

    **Difficulty checks capped at 4 → "Invalid Difficulty."** Once 4 difficulty checks run on a task without passing, it's automatically classified **Invalid Difficulty** and goes to review as-is (not a rejection, not retroactive). At the limit we set the verdict for you — resubmit without changes and leave it in place. [FAQ →](faq.md#difficulty-checks-are-now-capped-what-is-invalid-difficulty)

-   Aug 12, 2026

    **New: Reviewer Rubric tab.** A dedicated tab defining the technical bar every task must clear and how to assess it — the two paths to Needs Revision, the five Major Pillars, the accumulating Secondary Requirements, and reviewer integrity. [Reviewer Rubric →](reviewer-rubric.md)

-   Aug 5, 2026

    **"Send to Reviewer" checkbox removed.** Passing post-submission evals now route your task to the reviewer queue automatically; failing ones come back to fix and resubmit. No box to check, and the `AlwaysNoPass` message is gone. [Submission flow →](tasking-guide.md#section-3-run-evals)

-   Aug 5, 2026

    **Task came back too easy?** You can look at later PRs in the repo and adapt a change from a *related* one for inspiration to add complexity — just don't use unrelated PRs, don't copy a PR wholesale, and don't change the scope or feature of the original PR/task. [FAQ →](faq.md#a-task-came-back-too-easy-can-i-adapt-a-change-from-a-related-pr-to-add-complexity)

-   Aug 5, 2026

    **Reviewers: cite the Guidelines in revision notes.** When sending a task back for Needs Revision, point the submitter to the relevant Guidelines section for specific or easily-missed rules. It's not required for every note, but a pointer to the exact rule makes revisions faster and removes ambiguity. [Reviewer form questions →](tasking-guide.md#reviewer-form-questions)

-   Aug 5, 2026

    **Review-gate blocked at the agentic judge?** The one-line summary only names the stage — the reasons (`DISCUSS`/`REMOVE` + cited axes/files) live in the **"Agentic Judge Quality Report"** field on your submission. It's collapsed and marked optional, so expand it, fix what it flags, and resubmit. [FAQ →](faq.md#my-eval-says-review-gate-blocked-at-the-agentic-judge-difficulty-screen-what-does-that-mean)

-   Jul 27, 2026

    **Network fields in `task.toml` changed.** Network access is now set **per block** — `[environment]` `"public"`, `[agent]` `"allowlist"` with `allowed_hosts`, and `[verifier]` `"no-network"`. Also remove `network_mode = "none"` from `docker_compose.yaml` if present. [task.toml structure →](harbor-framework.md#task-metadata)

-   Jul 31, 2026

    **Quality Check pass bar clarified.** On coverage and faithfulness (scored 1–5), a task must land *above 3* on both axes to pass — exactly 3 (or any single judge at 2 or below) sends it to needs-revision, and 2 or below is a hard fail. Don't ship borderline. [Quality Check judge →](tasking-guide.md#quality-check-agentic-judge)

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
