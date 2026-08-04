# Sentinel Ultra Hub — Documentation

Source site: https://snorkel-ai.github.io/Sentinel_Ultra_Hub/

Exported: 2026-07-31T13:51:23Z

The Hub is a single-page app whose content is compiled into its JS bundle — there are no
per-page Markdown endpoints. These files were produced by rendering each tab in a headless
browser and converting the resulting DOM to Markdown, so they mirror the site exactly.

Read [ALL_DOCUMENTATION.md](ALL_DOCUMENTATION.md) for a single combined copy, or browse the
individual tabs below. `manifest.json` lists each file with its size.

> The **Changelog** tab is hidden in the live site's navigation (it only appears with the
> `?changelog` query parameter); it is included here for completeness.

## Contents

- **[What's New](whats-new.md)**
  - [Recent updates](whats-new.md#recent-updates)

- **[Guidelines](guidelines.md)**
  - [Your Role as an Expert Contributor (EC)](guidelines.md#your-role-as-an-expert-contributor-ec)
  - [Task verdicts](guidelines.md#task-verdicts)
  - [The four core principles](guidelines.md#the-four-core-principles)
  - [PR Scope and Task Difficulty](guidelines.md#pr-scope-and-task-difficulty)
  - [What you can edit in a task, and how](guidelines.md#what-you-can-edit-in-a-task-and-how)

- **[Tasking Guide](tasking-guide.md)**
  - [Submission Quick Start Guide](tasking-guide.md#submission-quick-start-guide)
  - [Before You Upload](tasking-guide.md#before-you-upload)
  - [Detailed Tasking Steps](tasking-guide.md#detailed-tasking-steps)
  - [How to Zip the Task](tasking-guide.md#how-to-zip-the-task)
  - [Step-by-Step Submitter Form Questions](tasking-guide.md#step-by-step-submitter-form-questions)
  - [Step-by-Step Reviewer Form Questions](tasking-guide.md#step-by-step-reviewer-form-questions)

- **[The Harbor Framework](harbor-framework.md)**
  - [Optional context on how tasks are evaluated](harbor-framework.md#optional-context-on-how-tasks-are-evaluated)
  - [Task Structure & Components](harbor-framework.md#task-structure-components)
  - [Task Metadata](harbor-framework.md#task-metadata)

- **[Glossary](glossary.md)**
  - [Roles & workflow](glossary.md#roles-workflow)
  - [Task anatomy](glossary.md#task-anatomy)
  - [Solution (oracle)](glossary.md#solution-oracle)
  - [Tests & grading](glossary.md#tests-grading)
  - [Quality & difficulty](glossary.md#quality-difficulty)

- **[FAQ](faq.md)**
  - [Is there a daily limit to how many tasks I can do?](faq.md#is-there-a-daily-limit-to-how-many-tasks-i-can-do)
  - [How do I decide between Valid as-is, Fixable, and Not Fixable?](faq.md#how-do-i-decide-between-valid-as-is-fixable-and-not-fixable)
  - [A task won't build, or the environment looks broken — what do I do?](faq.md#a-task-won-t-build-or-the-environment-looks-broken-what-do-i-do)
  - [I'm getting a nonzero exit-code agent error — what should I try?](faq.md#i-m-getting-a-nonzero-exit-code-agent-error-what-should-i-try)
  - [Which network_mode should my task.toml use?](faq.md#which-network-mode-should-my-task-toml-use)
  - [How should I set the agent timeout, and what if the task keeps timing out?](faq.md#how-should-i-set-the-agent-timeout-and-what-if-the-task-keeps-timing-out)
  - [How do I check the status of a submission?](faq.md#how-do-i-check-the-status-of-a-submission)
  - [The linter rejects my task as "easy" after a difficulty downgrade — what do I do?](faq.md#the-linter-rejects-my-task-as-easy-after-a-difficulty-downgrade-what-do-i-do)
  - [Do I need to run the oracle and NOP tests locally?](faq.md#do-i-need-to-run-the-oracle-and-nop-tests-locally)
  - [What counts as "changing the PR scope" vs. "adding complexity"?](faq.md#what-counts-as-changing-the-pr-scope-vs-adding-complexity)

- **[Quick Links](quick-links.md)**

- **[Changelog](changelog.md)**
  - Jul 27, 2026
  - Jul 25, 2026
  - Jul 23, 2026
  - Jul 22, 2026
  - Jul 15, 2026
  - Jul 13, 2026
  - Jul 3, 2026
  - Jul 1, 2026
  - Jun 30, 2026
  - Jun 26, 2026
  - Jun 25, 2026
  - Jun 24, 2026
