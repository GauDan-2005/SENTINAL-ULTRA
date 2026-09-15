# SENTINAL-ULTRA

Working repo for **Project Sentinel 2.0** task submissions. The job is to take a task bundle
downloaded from the platform, decide whether it is **Valid as-is**, **Fixable** or
**Invalid / Not Fixable**, correct it when it is Fixable, prove it locally, upload it, get it
through the platform's checks, answer the submitter form, and survive a peer EC's review.

This file is the map. `CLAUDE.md` plus `.claude/rules/` is the manual, split so the always-loaded
index stays short and each numbered section is its own file. `AGENTS.md` is the short contract an
agent reads before it touches anything.

## Where things are

```
README.md            this file
AGENTS.md            the hard locks, tool-neutral, under 60 lines
CLAUDE.md            the index: the workflow spine, the hard boundaries, and which rule file owns what
INDEX.md             the cross-task register, one row per task
prompts.md           reusable prompt templates for the submitter
facts.yml            every platform number and enumeration, machine-readable
sample_review_page.md  the whole live reviewer page for one submission, converted to markdown.
                     Platform evidence, cited by line from the rules and learning/, not drift
bin/                 the check and build scripts
bin/checks/          the numbered pre-upload checks that bin/preflight.sh runs
docs/                dated local export of the Sentinel Ultra Hub
learning/            verified findings from real platform runs
chat_transcripts/    session records kept as evidence, indexed in its own README
tasks/               one folder per live task
review_tasks/        one folder per peer review, the same shape minus upload/ and plus
                     download/seed/ (Sections 12 and 13)
_archive/            finished tasks, and superseded/ for retired root files
comparison-report/   the audit that explains why the workspace is shaped this way
.claude/rules/       the thirteen numbered sections, one file each, loaded every session
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

A review folder is the same shape with `upload/` empty, because a reviewer ships no bundle, and
with a second pristine extract, because the reviewer page hands over the **seed** zip as well as
the submitted one:

```
review_tasks/<Original Directory Name>/
  task.md              timed evidence record: timer, page evidence, fast gate, optional extension, tally
  task_details.md      the platform block AND the submitter's own answers, verbatim
  download/            original task ZIP always, optional submitted ZIP, seed/ only when submitted is under review, original/ the artifact under review
  work/                copy of original/. Static timed-review inspection only. A reviewer does NOT edit
  answers/             review_answer.txt, the Path D template, seven questions
```

The workflow is `.claude/rules/14-reviewer-workflow.md` (Section 13): five active minutes,
plus one recorded static five-minute extension when a concrete trigger exists. Section 12 owns the
form and tally. `bin/new-review.sh` bootstraps safely, and `bin/preflight.sh --review-fast` provides
the ZIP-only static gate. `bin/local-run.sh` is a submitter or explicitly requested diagnostic tool,
not normal reviewer work.

## Source precedence

When two of these disagree the higher one wins, and the conflict gets reported rather than
quietly reconciled. **`docs/`** owns policy and judgment, being the Hub export, and its
`reviewer-rubric.md` tab is the bar on both sides at once, the one a task must clear to be
accepted and the one a review's own writing has to meet (`docs/reviewer-rubric.md:9`).
**`learning/`** owns what the platform and this machine actually do, since every note is backed
by a build log or a container run, so a note beats `CLAUDE.md` on observed fact. **`facts.yml`**
owns the numbers and enumerations, and `bin/doclint.sh` fails on prose that contradicts it.
**`CLAUDE.md` and `.claude/rules/`** own the workflow that stitches all of it together, the
first holding the spine and the routing table and the second holding the full text of each
numbered section. Where those two disagree the rule file wins, because it is the full text.

## Starting a session

1. For a submitter task, read **every file in `learning/`**, starting with `learning/README.md`.
   For a timed peer review, Section 13 uses a candidate-specific lookup instead of a corpus read.
2. Read **`INDEX.md`** to see what is already in flight and whether the throughput rule (at
   most two tasks in `pending-revision`) is already at its limit.
3. Read the task folders under `tasks/` and reconcile them against `INDEX.md`. A folder with
   no row, or a row whose status no longer matches the files, is drift.

`bin/session-start.sh` produces that brief as generated output.

## The lifecycle of one task

Claim and bootstrap the folder, analyse the bundle against the four core principles, decide
the verdict, apply corrections in `work/` if it is Fixable, run the local NOP and oracle
checks on disposable copies, zip, upload, work the eval loop until the checks pass, write the
answers, submit it, then run the revision rounds that come back. A submission whose evals pass
goes to the reviewer queue on its own and one whose evals fail comes back to you, so there is
no send step of your own to perform. That eval loop stopped being unbounded on the difficulty
side on 2026-08-14. A task now gets four difficulty checks per review cycle, spent by any check
that runs and returns a result, so a submission that comes back before the check runs costs
nothing and a reviewer sending the task back restarts the count at zero. At the fourth
non-passing check the platform sets the validity answer to Invalid Difficulty itself and returns the task once with
that verdict on it, to be resubmitted unchanged; it is not a rejection and a human reviewer
still reads it (`docs/faq.md`, "Difficulty checks are now capped"). The working consequence,
which follows from the size of that budget rather than from any run recorded here, is that the
measurement which finds a difficulty lever moves in front of the upload, because spending a
check to learn whether a lever chosen by reasoning works costs a quarter of the budget. Steps 1
to 10 spell every one of those out, summarised in
`CLAUDE.md` and written in full in `.claude/rules/01-workflow-steps-1-to-5.5.md` and
`.claude/rules/02-workflow-steps-6-to-10.md`. The two orderings that are never negotiable: the
zip is built only after the local checks pass, and the answers are written only after the zip
exists.

## Commands

Every script takes the task directory as its first argument, is read-only with respect to the
bundle unless its name says otherwise, and uses one exit-code contract: **0** the check
passed, **1** a real defect was found, **2** the check could not run. `1` and `2` are never
conflated, so a missing tool never reads as a clean bundle.

| Command | What it does |
|---|---|
| `bin/session-start.sh` | The Step 1 brief: which learning notes apply, what `INDEX.md` says, what is drifting |
| `bin/new-task.sh` | Bootstraps a task folder from a downloaded zip, extracts `download/original/`, seeds `task.md` and adds the `INDEX.md` row |
| `bin/new-review.sh` | Bootstraps a review before its timer starts, preserves the optional seed safely, and creates the compact timed-review record |
| `bin/task-doctor.sh` | Reconciles disk, task state and `INDEX.md`, and enforces the throughput rule |
| `bin/local-run.sh` | Submitter or explicitly requested diagnostic NOP/oracle harness. Never normal timed-review work |
| `bin/preflight.sh` | Runs staged checks. `--review-fast <submitted.zip>` selects the reviewer ZIP-only static profile |
| `bin/rezip.sh` | The re-zip rule: git scrub, gates, then `zip -rXy` into `upload/` |
| `bin/pre-send.sh` | The pre-submit gate. Must exit 0 before you submit. Its name, its header comment and the text it prints at run time all predate the removal of the Send to reviewer checkbox on 2026-08-05, and none of it has been rewritten. A run still heads its checklist "Send to reviewer - go/no-go" (`bin/pre-send.sh:215`) and still offers to waive a blocking gate with `--without` and explain the failure in Comments for Reviewer (`:225-226`). There is no such route any more: submit with a failing check and the platform returns the submission to you (`docs/tasking-guide.md:251`). Read a nonzero exit as fix it, never as declare it |
| `bin/doclint.sh` | Lints the workspace's own prose: rule twins in sync, no dead paths, no dead cross-references, no numbers that contradict `facts.yml` |
| `bin/selftest.sh` | Runs every check against the one platform-accepted bundle. A check that fails it is a bug in the check |

Run `bin/doclint.sh` and `bin/selftest.sh` after editing any rule file. The rest of `bin/` is
self-documenting from its header comment.

## Why the workspace looks like this

Many rules here look over-specified until you find the round they were paid for. A 192-finding
audit of this workspace against a second Sentinel repo once lived here in a comparison-report
directory; it has since been deleted and its conclusions folded into `.claude/rules/` and
`learning/`. So before arguing that a rule here is wrong, look for the note or the `LEDGER.md`
row behind it. `learning/LEDGER.md` in particular is the list of things this workspace believed,
shipped, and then disproved, and it is read first and in full.
