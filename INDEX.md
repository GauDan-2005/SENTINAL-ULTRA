# Sentinel Ultra submissions

One row per task. Full detail lives in each task's own `task.md`.

## Row format

Three separate cells carry what used to be one sentence, so the register can be read by eye
and counted by a script.

**Status** holds one token and nothing else. No parentheses, no dates, no bold. The vocabulary
is fixed:

| Status | Means |
|---|---|
| `claimed` | The zip is downloaded and the folder exists. Nothing read yet |
| `analysing` | Steps 2 to 4 are running. No verdict yet |
| `fixing` | Verdict is Fixable and edits are in progress in `work/` |
| `checks-green` | Local oracle and NOP both pass and the zip is built. Not uploaded yet |
| `uploaded` | The zip is on the platform and the checks are running |
| `pending-revision` | A check or a reviewer sent it back. Counts against the throughput rule |
| `sent-to-reviewer` | Send to reviewer is checked and the task is with the peer EC |
| `accepted` | The reviewer accepted it. Task is closed |
| `rejected` | The reviewer rejected it. Task is closed |

**Round** is the revision-round number as an integer. `0` means the task has not been sent
back yet. It matches the `Revision round N` headings in the task's own `task.md`.

**Note** is free text and carries everything else. It never carries the status or the round.

Throughput rule: at most **two** tasks sitting in `pending-revision` at once, or the
platform blocks a new claim. Count it with

```
grep -c '^| \[.*| pending-revision |' INDEX.md
```

which only works because the Status cell holds nothing but the token. The leading `^| \[`
anchors on a real row, so this line of documentation does not count itself.

## Active

pending-revision: 3 of 2 - OVER THE CAP. The platform blocks a new claim until this is
2 or fewer. Resolve before claiming anything: send one task to reviewer or park it.
Update this line in the same action that changes any row's Status.

| Task | Submission id | Repo / PR | Verdict | Status | Round | Claimed | Note |
|---|---|---|---|---|---|---|---|
| [20260728_153118__jqno_equalsverifier__1166](tasks/20260728_153118__jqno_equalsverifier__1166/task.md) | 7f75eb9d | jqno/equalsverifier 1166 | Fixable | pending-revision | 3 | 2026-08-01 | Round 3 applied and verified 2026-08-04. Zip rebuilt, ready to re-upload |
| [20260727_135618__AltBeacon_android-beacon-library__1177](tasks/20260727_135618__AltBeacon_android-beacon-library__1177/task.md) | a1bcc8a9 | AltBeacon/android-beacon-library 1177 | Fixable | pending-revision | 2 | 2026-08-01 | Judge **PASSED** 2026-08-04 and all judge items are fixed. Blocked only on oracle 0/3, need the difficulty artifact |
| [20260723_030109__cryspen_libcrux__1165](tasks/20260723_030109__cryspen_libcrux__1165/task.md) | 51077619 | cryspen/libcrux 1165 | Fixable | pending-revision | 3 | 2026-08-02 | Round 3 applied and verified 2026-08-04, difficulty expansion, judge already passing. **Escalate to Not Fixable if the screen returns easy again** |

## Done

| Task | Submission id | Repo / PR | Verdict | Status | Round | Closed | Note |
|---|---|---|---|---|---|---|---|
| [20260719_045042__oliver-oloughlin_kvdex__245](_archive/20260719_045042__oliver-oloughlin_kvdex__245/task.md) | 05589b6f | oliver-oloughlin/kvdex 245 | Fixable | accepted | 6 | 2026-08-04 | Accepted on round 6. The one bundle that cleared every gate, written up in `learning/accepted-bundle-reference.md` |

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
README.md          orientation, the folder map and the bin/ command table
AGENTS.md          the short contract every agent reads before touching anything
CLAUDE.md          the workflow
docs/              local export of the Hub, source of truth for policy
learning/          verified findings from real runs, read all of it at session start
bin/               the check and build scripts
chat_transcripts/  session transcripts kept as evidence, indexed in its own README
INDEX.md           this file
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
