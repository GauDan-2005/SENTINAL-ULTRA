# Sentinel Ultra Hub — Documentation

Source site: https://snorkel-ai.github.io/Sentinel_Ultra_Hub/

Exported: 2026-08-18T01:10:00+05:30 (2026-08-17T19:40:00Z). Two tabs moved in this re-export,
`whats-new.md` and `faq.md`, and both carry the same single policy change, dated 2026-08-14:
**difficulty checks are capped at 4, after which the platform classifies the task Invalid
Difficulty on its own.** `guidelines.md`, `tasking-guide.md`, `reviewer-rubric.md`,
`harbor-framework.md`, `glossary.md`, `quick-links.md` and `changelog.md` were unchanged
upstream and keep their earlier export dates. All nine tabs were rendered and diffed, so the
seven unchanged ones are verified unchanged rather than assumed. There is no single export
date, so `manifest.json` carries the real date, size and SHA-256 per file, and is the thing to
trust.

**The Hub's own Changelog tab was not updated for this release** - its newest entry is still
Aug 5, 2026. The Aug 14 change reaches you through What's New and the FAQ only. That is the
second release running where the Changelog lagged, so do not read it as a complete history of
policy changes, and do not read a missing Changelog entry as evidence that nothing shipped.

The Hub is a single-page app whose content is compiled into its JS bundle, so there are no
per-page Markdown endpoints. These files were produced by rendering each tab in a headless
browser and converting the resulting DOM to Markdown, so they mirror the site exactly.

**The Hub is now behind a login.** The SPA carries a `/login` route and an email gate: it
holds a hardcoded list of SHA-256 hashes of approved contributor emails, checks the address
you type against that list in the browser, and keeps the result in `sessionStorage` under
`sentinel-ultra-auth`. There is no server call, but there is also no way to render a tab
without an approved address. Any future re-export needs one.

Read [ALL_DOCUMENTATION.md](ALL_DOCUMENTATION.md) for a single combined copy, or browse the
individual tabs below. `manifest.json` lists each file with its export date, byte size,
SHA-256 and any local edit.

> The **Changelog** tab is hidden in the live site's navigation (it only appears with the
> `?changelog` query parameter); it is included here for completeness.

## Staleness and refresh

`docs/` is the declared source of truth for policy, so a stale copy is a silent correctness
problem. The Jul 27 build-time-network correction is exactly the kind of Hub change that
invalidates a rule written against the older text, and the Aug 12 Reviewer Rubric tab is the
larger kind: a whole new policy page that no rule file knew existed until somebody read it.
Two things can go wrong, and they have different checks.

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

**`hub_bundle` is populated again and the check works.** It reads
`assets/index-a1d87e7a.js`, recorded 2026-08-18 in `hub_bundle_checked`. It was `null` for the
2026-08-13 export because nobody wrote the filename down, which is what let the Aug 14 change
sit unnoticed on the Hub. The observed sequence is `index-77c1ec94.js` up to 2026-08-04,
`index-d251bfe7.js` on 2026-08-06, `index-b68068d8.js` on 2026-08-12 (recorded in the sync
report of the `DOCS/sentinal_documentation` mirror rather than here), and `index-a1d87e7a.js`
now. Write the new filename into `hub_bundle` on every re-export, because the one time it was
skipped is the one time the check could not run.

Nothing else depends on this. `bin/docs-freshness.sh` fetches the Hub index and reads the
bundle filename out of it directly, so it works either way. It does read `export_date` from
`manifest.json` in preference to the `Exported:` line above, and that field now reads
2026-08-18.

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

The loop reads the `files` and `derived` arrays, so it covers all nine tabs plus
`ALL_DOCUMENTATION.md`. It prints `ok` on the tree as it stands. Every recorded hash covers the
file as it sits on disk, `guidelines.md` included, so the local repair there is inside the hash
rather than an expected mismatch. Anything reporting CHANGED was modified without the manifest
being updated.

`manifest.json` was regenerated for this export on 2026-08-18: `export_date` and
`manifest_generated` both read 2026-08-18, `hub_bundle` and `hub_bundle_checked` are populated
again, and `whats-new.md`, `faq.md` and `ALL_DOCUMENTATION.md` carry fresh export dates, sizes
and hashes. The other seven keep their earlier dates because they were diffed and found
unchanged. An entry for a new tab needs the same fields the others carry: `tab_id`,
`navigation_title`, `local_path`, `source_url`, `exported`, `verbatim`, `bytes`, `line_count`,
`character_count` and `sha256`. Note that the tab count appears twice in the `derived` entry
for `ALL_DOCUMENTATION.md`, once in its `description` field and once in its `note` field, and
both have to move together. Both read nine.

### Reapply after any re-export

A re-export overwrites whichever file it regenerates and silently loses that file's local
repairs. Reapply each one, or the workspace goes back to prescribing broken shell. Both files carry the SAME table and both
must be repaired. `ALL_DOCUMENTATION.md` does have a manifest entry with a SHA-256, so the hash
loop above does cover it, but that hash is regenerated from whatever is on disk at the same
time the file is. It catches a later hand edit and can never tell a repaired regeneration from
a damaged one. The table check below is the only thing that can.

**This has now happened twice, both times exactly as the manifest predicted it would.** On
2026-08-06 the Reviewer Rubric tab did not exist and `guidelines.md` had not changed upstream,
so `guidelines.md` was not overwritten and its repair survived untouched, while
`ALL_DOCUMENTATION.md` was regenerated and came back carrying all five damaged rows. It was
repaired the same day. The 2026-08-13 re-export went the same way move for move: `guidelines.md`
still hashes to `6e070722...` and git reports it unmodified, so it was never overwritten, while
`ALL_DOCUMENTATION.md` was regenerated, came back damaged for the second time, and was repaired
again the same day. Its own inline note records it, at `docs/ALL_DOCUMENTATION.md:395`,
"Re-applied 2026-08-13 after the re-export, which reintroduced the damage for the second time
exactly as predicted." Both verification commands below pass on the tree as it stands.

Two for two is enough to treat this as the normal outcome rather than a surprise, and it is the
reason this section exists. Run the two verification commands over BOTH files, every time,
rather than checking only the one you happened to overwrite. Note which file the damage lands
in: it is whichever one the export actually rewrote, and `ALL_DOCUMENTATION.md` is rewritten on
every export because it is regenerated from the tabs, while `guidelines.md` is only rewritten
when that tab changes upstream. So the day `guidelines.md` does change upstream is the day both
files come back damaged at once.

**The 2026-08-18 export is the first one that did not need the repair re-applied, and the
reason generalises.** Only two tabs had moved, so `ALL_DOCUMENTATION.md` was not regenerated
wholesale: its What's New and FAQ sections were replaced in place and every other byte was left
alone, which meant the repaired table was never overwritten. Both verification commands were
still run and both passed. Prefer the in-place edit whenever a re-export moves only some tabs.
It is less work, it cannot lose a repair, and a wholesale rebuild buys nothing when seven of
the nine inputs are byte-identical to what is already on disk.

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

**Re-exporting.** There is an exporter now, added 2026-08-18. It used to say "no exporter script
is checked into this workspace, so this is a manual step", and that gap is exactly what let the
Aug 14 change sit on the Hub unnoticed: `bin/docs-freshness.sh` could tell that something had
moved, and nothing could turn that into an updated file without rebuilding the pipeline by hand.

```sh
SENTINEL_HUB_EMAIL=you@example.com bin/docs-export.sh
```

`bin/docs-render.mjs` renders every tab in headless Chrome and dumps the `.content` DOM;
`bin/docs-html2md.py` converts one tab's HTML into the convention these files use. The address
is needed because the Hub is behind the email gate described above; it is not a credential and
is deliberately not stored in the repo.

**It diffs, it does not overwrite.** The candidate export goes to a scratch directory and the
script prints, per tab, whether the live site still matches what is on disk. It exits 0 when
every tab matches. `guidelines.md` is reported as `repair` rather than as moved, and the check
behind that word is the repo's own: no damaged table row survives here and the three repaired
forms are present. If that ever fails, the Guidelines tab really did change upstream and the
repair has to be re-applied by hand.

Copy across only the tabs the script reports as MOVED, keeping the `<!-- Source: ... -->` header
line at the top of each. Then update `manifest.json` (dates, sizes, hashes, `hub_bundle`, adding
a `files` entry for any tab the Hub has gained) and replace the moved tab's section inside
`ALL_DOCUMENTATION.md` in place rather than rebuilding that file, for the reason in the section
above.

**After any re-export, re-diff these before trusting the workspace rules**, because they are
transcribed into `CLAUDE.md` and the `.cursor` / `.claude` rule files rather than read from
`docs/` at run time:

- the verdict table rows in [guidelines.md](guidelines.md#task-verdicts)
- the `task.toml` field limits in [harbor-framework.md](harbor-framework.md#task-metadata)
- the submitter and reviewer form question lists in
  [tasking-guide.md](tasking-guide.md#step-by-step-submitter-form-questions)
- the two compliance checklists, whose wording must stay byte-identical to the platform's
- the assessment threshold, the five Major Pillars and the eleven Secondary Requirements in
  [reviewer-rubric.md](reviewer-rubric.md#the-assessment-threshold), which is the documented bar
  for the task AND for the reviewer's own written assessment
- the submission flow in [tasking-guide.md](tasking-guide.md#section-3-run-evals), which lost
  the Send to reviewer checkbox on 2026-08-05

**Known upstream defect.** The Fix column of the "Fixable environment issues" table in
`guidelines.md` is mistyped on the Hub itself. Flags lose a hyphen (`apk add -no-cache`,
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

- **[Reviewer Rubric](reviewer-rubric.md)**
  - [The Assessment Threshold](reviewer-rubric.md#the-assessment-threshold)
  - [Invalid vs. Fixable](reviewer-rubric.md#invalid-vs-fixable)
  - [Major Pillars](reviewer-rubric.md#major-pillars)
  - [Secondary Requirements](reviewer-rubric.md#secondary-requirements)
  - [Reviewer Integrity](reviewer-rubric.md#reviewer-integrity)
  - [Quick Reference](reviewer-rubric.md#quick-reference)

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
  - [Difficulty checks are now capped — what is "Invalid Difficulty"?](faq.md#difficulty-checks-are-now-capped-what-is-invalid-difficulty)
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
