# SENTINAL-ULTRA

Working repo for **Project Sentinel 2.0** task submissions. The job is to take a task bundle
downloaded from the platform, decide whether it is **Valid as-is**, **Fixable** or
**Invalid / Not Fixable**, correct it when it is Fixable, prove it locally, upload it, get it
through the platform's checks, answer the submitter form, and survive a peer EC's review.

This file is the map. `CLAUDE.md` is the manual. `AGENTS.md` is the short contract an agent
reads before it touches anything.

## Where things are

```
README.md            this file
AGENTS.md            the hard locks, tool-neutral, under 60 lines
CLAUDE.md            the full workflow, Steps 1 to 10, plus the form answers
INDEX.md             the cross-task register, one row per task
prompts.md           reusable prompt templates for the submitter
facts.yml            every platform number and enumeration, machine-readable
bin/                 the check and build scripts
bin/checks/          the numbered pre-upload checks that bin/preflight.sh runs
docs/                dated local export of the Sentinel Ultra Hub
learning/            verified findings from real platform runs
chat_transcripts/    session records kept as evidence, indexed in its own README
tasks/               one folder per live task
_archive/            finished tasks, and superseded/ for retired root files
comparison-report/   the audit that explains why the workspace is shaped this way
.claude/skills/      the Claude Code copies of the companion rules
.cursor/rules/       the Cursor copies of the same rules, kept byte-identical
```

Anything at the root that is not in that list is drift. Report it rather than working from it,
and check `_archive/superseded/` for what replaced it.

Each task folder has the same shape, and everything about one task lives inside it:

```
tasks/<Original Directory Name>/
  task.md              the record: ids, verdict, status, check history, every round
  task_details.md      the platform data block, pasted verbatim
  download/            the platform's zip, and original/ the pristine never-edited extract
  work/                the working copy, every edit happens here
  upload/              the bundle you re-upload
  answers/             submission_answer.txt, one file only
```

## Source precedence

When two of these disagree the higher one wins, and the conflict gets reported rather than
quietly reconciled. **`docs/`** owns policy and judgment, being the Hub export. **`learning/`**
owns what the platform and this machine actually do, since every note is backed by a build log
or a container run, so a note beats `CLAUDE.md` on a matter of observed fact. **`facts.yml`**
owns the numbers and enumerations, and `bin/doclint.sh` fails on prose that contradicts it.
**`CLAUDE.md`** owns the workflow that stitches all of it together.

## Starting a session

1. Read **every file in `learning/`**, starting with `learning/README.md`. This is not
   optional and it comes first.
2. Read **`INDEX.md`** to see what is already in flight and whether the throughput rule (at
   most two tasks in `pending-revision`) is already at its limit.
3. Read the task folders under `tasks/` and reconcile them against `INDEX.md`. A folder with
   no row, or a row whose status no longer matches the files, is drift.

`bin/session-start.sh` produces that brief as generated output.

## The lifecycle of one task

Claim and bootstrap the folder, analyse the bundle against the four core principles, decide
the verdict, apply corrections in `work/` if it is Fixable, run the local NOP and oracle
checks on disposable copies, zip, upload, work the eval loop until the checks pass, write the
answers, send to reviewer, then run the revision rounds that come back. `CLAUDE.md` Steps 1
to 10 spell every one of those out. The two orderings that are never negotiable: the zip is
built only after the local checks pass, and the answers are written only after the zip exists.

## Commands

Every script takes the task directory as its first argument, is read-only with respect to the
bundle unless its name says otherwise, and uses one exit-code contract: **0** the check
passed, **1** a real defect was found, **2** the check could not run. `1` and `2` are never
conflated, so a missing tool never reads as a clean bundle.

| Command | What it does |
|---|---|
| `bin/session-start.sh` | The Step 1 brief: which learning notes apply, what `INDEX.md` says, what is drifting |
| `bin/new-task.sh` | Bootstraps a task folder from a downloaded zip, extracts `download/original/`, seeds `task.md` and adds the `INDEX.md` row |
| `bin/task-doctor.sh` | Reconciles disk, task state and `INDEX.md`, and enforces the throughput rule |
| `bin/local-run.sh` | The disposable NOP and oracle harness. Never runs anything inside `work/` |
| `bin/preflight.sh` | Runs the whole pre-upload checklist through `bin/checks/`. Must exit 0 before the zip |
| `bin/rezip.sh` | The re-zip rule: git scrub, gates, then `zip -rXy` into `upload/` |
| `bin/pre-send.sh` | The single gate that must exit 0 before Send to reviewer is checked |
| `bin/doclint.sh` | Lints the workspace's own prose: rule twins in sync, no dead paths, no dead cross-references, no numbers that contradict `facts.yml` |
| `bin/selftest.sh` | Runs every check against the one platform-accepted bundle. A check that fails it is a bug in the check |

Run `bin/doclint.sh` and `bin/selftest.sh` after editing any rule file. The rest of `bin/` is
self-documenting from its header comment.

## Why the workspace looks like this

`comparison-report/` is a 192-finding audit of this workspace against a second Sentinel repo,
with the conflicts adjudicated. Read `comparison-report/00-EXECUTIVE-SUMMARY.md` before
arguing that a rule here is wrong. Several places where the two repos disagree are places
where this one is right.
