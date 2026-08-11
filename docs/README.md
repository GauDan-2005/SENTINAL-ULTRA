# Sentinel Ultra Hub — Documentation

Source site: https://snorkel-ai.github.io/Sentinel_Ultra_Hub/

Exported: 2026-08-06T08:15:55Z. Five tabs changed in this re-export and were overwritten
(`whats-new.md`, `tasking-guide.md`, `harbor-framework.md`, `faq.md`, `changelog.md`);
`guidelines.md`, `glossary.md` and `quick-links.md` were unchanged upstream and keep their
2026-07-31 export date. There is no single export date — `manifest.json` carries the real
date, size and SHA-256 per file, and is the thing to trust.

The Hub is a single-page app whose content is compiled into its JS bundle — there are no
per-page Markdown endpoints. These files were produced by rendering each tab in a headless
browser and converting the resulting DOM to Markdown, so they mirror the site exactly.

Read [ALL_DOCUMENTATION.md](ALL_DOCUMENTATION.md) for a single combined copy, or browse the
individual tabs below. `manifest.json` lists each file with its export date, byte size,
SHA-256 and any local edit.

> The **Changelog** tab is hidden in the live site's navigation (it only appears with the
> `?changelog` query parameter); it is included here for completeness.

## Staleness and refresh

`docs/` is the declared source of truth for policy, so a stale copy is a silent correctness
problem — the Jul 27 build-time-network correction is exactly the kind of Hub change that
invalidates a rule written against the older text. Two things can go wrong, and they have
different checks.

**1. Has the Hub changed since this export?** The Hub ships its content inside a
content-hashed JS bundle, so the bundle filename changes whenever any tab's text changes.
That makes it a reliable one-request sentinel:

```sh
curl -s https://snorkel-ai.github.io/Sentinel_Ultra_Hub/ \
  | grep -o 'assets/index-[0-9a-f]\{8\}\.js'
```

Compare the result against `hub_bundle` in [manifest.json](manifest.json). Same string means
nothing on the Hub has changed and this export is current. A different string means at least
one tab was edited and `docs/` needs re-exporting.

**2. Has anything here been edited locally?** Verify the recorded hashes:

```sh
cd docs && python3 - <<'PY'
import json, hashlib
m = json.load(open('manifest.json'))
bad = 0
for e in m['files'] + m['derived']:
    if hashlib.sha256(open(e['local_path'], 'rb').read()).hexdigest() != e['sha256']:
        print('CHANGED', e['local_path']); bad += 1
print('ok' if not bad else f'{bad} file(s) differ from the manifest')
PY
```

`guidelines.md` is expected to carry a local edit (see its `local_edits` entry); anything else
reporting CHANGED was modified without the manifest being updated.

### Reapply after any re-export

A re-export overwrites the file and silently loses these local repairs. Reapply each one, or
the workspace goes back to prescribing broken shell. Both files carry the SAME table and both
must be repaired - `ALL_DOCUMENTATION.md` is not manifest-tracked, so nothing detects it.

**This has now happened once, exactly as predicted.** The 2026-08-06 re-export left
`guidelines.md` byte-identical to the repaired copy — that tab did not change upstream, so it
was not overwritten and its repair survived untouched — while `ALL_DOCUMENTATION.md` WAS
regenerated and came back carrying all five damaged rows. The repair was re-applied to it the
same day. The lesson is that the two files can fall out of step on a partial re-export, so run
the two verification commands below over BOTH of them, every time, rather than checking the one
you happened to overwrite.

In `guidelines.md` and `ALL_DOCUMENTATION.md`, "Fixable environment issues" table, Fix column:

| Damaged in the Hub export | Correct command |
|---|---|
| `apk add -no-cache bash` | `apk add --no-cache bash` |
| `apt-get install y tmux` / `apk add -no-cache tmux` | `apt-get install -y tmux` / `apk add --no-cache tmux` |
| `apt-get install y asciinema` | `apt-get install -y asciinema` |
| `cpus/memorymb/storagemb` | `cpus` / `memory_mb` / `storage_mb` |
| `chmod x` | `chmod +x` |

The damage is in the Hub's own page bundle, not in the export tooling, so it will come back
every time. Verify the repair held by checking the TABLE ROWS, anchored on the leading pipe.
A bare grep for the damaged strings does NOT work here and must not be used: both files carry
a repair note that quotes the damaged strings on purpose, so a bare grep always reports hits
and can never pass.

```
awk '/^\|/ && (/apk add -no-cache/||/install y /||/chmod x/||/memorymb/)' \
    docs/guidelines.md docs/ALL_DOCUMENTATION.md
```

It must return nothing. Then confirm the repaired forms are actually present:

```
grep -c 'apk add --no-cache bash\|apt-get install -y tmux\|chmod +x' \
    docs/guidelines.md docs/ALL_DOCUMENTATION.md
```

Both files must report 3. Checking only the first command would pass on a file where the
whole table had been deleted, which is why the second one exists.

**Re-exporting.** No exporter script is checked into this workspace, so this is a manual step:
render each tab of the Hub in a headless browser, convert the DOM to Markdown, and write it
over the matching file, keeping the `<!-- Source: ... -->` header line at the top. Then
regenerate `manifest.json` (dates, sizes, hashes, `hub_bundle`) and re-concatenate
`ALL_DOCUMENTATION.md`.

**After any re-export, re-diff these before trusting the workspace rules**, because they are
transcribed into `CLAUDE.md` and the `.cursor` / `.claude` rule files rather than read from
`docs/` at run time:

- the verdict table rows in [guidelines.md](guidelines.md#task-verdicts)
- the `task.toml` field limits in [harbor-framework.md](harbor-framework.md#task-metadata)
- the submitter and reviewer form question lists in
  [tasking-guide.md](tasking-guide.md#step-by-step-submitter-form-questions)
- the two compliance checklists, whose wording must stay byte-identical to the platform's

**Known upstream defect.** The Fix column of the "Fixable environment issues" table in
`guidelines.md` is mistyped on the Hub itself — flags lose a hyphen (`apk add -no-cache`,
`apt-get install y`), `chmod +x` loses its `+`, and `memory_mb`/`storage_mb` lose their
underscores. It is corrected in our copy and flagged there. A re-export will bring the broken
commands back, so re-apply the correction.

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
  - [An eval failed with an infra/platform error, or came back with blank feedback — is my task broken?](faq.md#an-eval-failed-with-an-infra-platform-error-or-came-back-with-blank-feedback-is-my-task-broken)
  - [My eval says "Review gate blocked at the agentic judge / difficulty screen" — what does that mean?](faq.md#my-eval-says-review-gate-blocked-at-the-agentic-judge-difficulty-screen-what-does-that-mean)
  - [The linter rejects my task as "easy" after a difficulty downgrade — what do I do?](faq.md#the-linter-rejects-my-task-as-easy-after-a-difficulty-downgrade-what-do-i-do)
  - [Do I need to run the oracle and NOP tests locally?](faq.md#do-i-need-to-run-the-oracle-and-nop-tests-locally)
  - [What counts as "changing the PR scope" vs. "adding complexity"?](faq.md#what-counts-as-changing-the-pr-scope-vs-adding-complexity)
  - [A task came back too easy — can I adapt a change from a related PR to add complexity?](faq.md#a-task-came-back-too-easy-can-i-adapt-a-change-from-a-related-pr-to-add-complexity)

- **[Quick Links](quick-links.md)**

- **[Changelog](changelog.md)**
  - Aug 5, 2026
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
