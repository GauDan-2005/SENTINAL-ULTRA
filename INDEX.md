# Sentinel Ultra submissions

One row per task. Full detail lives in each task's own `task.md`.

Status values: `claimed`, `analysing`, `fixing`, `checks-green`, `uploaded`,
`pending-revision`, `sent-to-reviewer`, `accepted`, `rejected`.

Throughput rule: at most **two** tasks sitting in `pending-revision` at once, or the
platform blocks a new claim.

## Active

| Task | Submission id | Repo / PR | Verdict | Status | Claimed |
|---|---|---|---|---|---|
| [20260728_153118__jqno_equalsverifier__1166](tasks/20260728_153118__jqno_equalsverifier__1166/task.md) | 7f75eb9d | jqno/equalsverifier 1166 | Fixable | pending-revision (round 3 applied and verified 2026-08-04, zip rebuilt, ready to re-upload) | 2026-08-01 |
| [20260727_135618__AltBeacon_android-beacon-library__1177](tasks/20260727_135618__AltBeacon_android-beacon-library__1177/task.md) | a1bcc8a9 | AltBeacon/android-beacon-library 1177 | Fixable | pending-revision (**judge PASSED** 2026-08-04, all judge items fixed; blocked only on oracle 0/3, need the difficulty artifact) | 2026-08-01 |
| [20260723_030109__cryspen_libcrux__1165](tasks/20260723_030109__cryspen_libcrux__1165/task.md) | 51077619 | cryspen/libcrux 1165 | Fixable | pending-revision (round 3 applied and verified 2026-08-04, difficulty expansion, judge already passing; **escalate to Not Fixable if the screen returns easy again**) | 2026-08-02 |

## Done

| Task | Submission id | Repo / PR | Verdict | Outcome | Closed |
|---|---|---|---|---|---|
| [20260719_045042__oliver-oloughlin_kvdex__245](_archive/20260719_045042__oliver-oloughlin_kvdex__245/task.md) | 05589b6f | oliver-oloughlin/kvdex 245 | Fixable | **accepted** on round 6 | 2026-08-04 |

kvdex took six rounds, five of them spent on one defect: `tests.patch` not applying after an
agent had edited the tests. Three git-based restores passed every local scenario and none of
them worked on the platform, because the verify-time workspace is not a git repository. The
design that worked embeds a base64 archive of the base test tree inside `test.sh`. Full write-up
in `learning/tests-patch-vs-agent-edits.md`, which is now platform-confirmed rather than only
locally verified. **Read that note before writing a restore step on any new task.**

## Layout

Everything for one task sits in one folder, so nothing has to be hunted across the
workspace:

```
tasks/<Original Directory Name>/
  task.md              record: ids, verdict, status, check history, what changed
  task_details.md      the platform data block, pasted verbatim
  download/
    <submission_id>_submission.zip    exactly what the platform gave you
    original/                          pristine extract, never edited, diff target
  work/                                the working copy, ALL edits happen here
  upload/
    <Original Directory Name>.zip      the bundle you re-upload
  answers/
    submission_answer.txt              the form answers
```

Shared across every task:

```
CLAUDE.md     the workflow
docs/         local export of the Hub, source of truth for policy
learning/     verified findings from real runs, read all of it at session start
INDEX.md      this file
```

Local oracle and NOP runs use disposable copies in the **session scratchpad**, never a
folder inside the workspace. The workspace moved to ext4 on 2026-08-04, so the old NTFS
bulk-delete hazard no longer applies here. See `learning/local-runs.md`.

## Starting a new task

1. Make `tasks/<Original Directory Name>/` with the five subfolders above.
2. Drop the downloaded zip in `download/`, extract the inner `task/` to `download/original/`.
3. Paste the platform data block into `task_details.md`.
4. Copy `download/original/` to `work/` with `cp -a` so `.git` and dotfiles survive.
5. Add a row to the Active table here.
