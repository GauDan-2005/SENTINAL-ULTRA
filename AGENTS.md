# AGENTS.md

The contract for any agent working this repo, whatever tool it runs in. Read this, then read
`README.md` for the map and `CLAUDE.md` for the workflow. Rules below cite the step or section
that owns them, because line numbers rot.

**The numbered sections live in `.claude/rules/`, one file per section**, and `CLAUDE.md` holds
the spine plus a routing table naming which file owns which. Claude Code loads every file in
that directory automatically at session start. **No other tool does**, so if you are not Claude
Code, a step or section cited below is an instruction to open the rule file the routing table
names and read it before acting. A summary in `CLAUDE.md` is never the whole rule.

## Before anything

1. For a submitter task, read **every file in `learning/`**, starting with `learning/README.md`, then read
   `INDEX.md`. For a timed peer review, follow Section 13 instead: use candidate-specific learning and
   LEDGER lookup only after a concrete review candidate exists. (Step 1 / Section 13)
2. Never invent the platform task data or the handling times. Both come from the submitter.
   (Step 1.5, Step 8)
3. One folder per task under `tasks/<Original Directory Name>/`. Nothing about a task lives
   outside its folder. (Section 7)

## Never

- **Never edit anything under `download/original/`, and never run any command inside it.** It
  is the pristine extract and the only diff target you have. Build tools write gitignored
  caches that no `git status` will warn you about. (Step 5)
- **Never edit tracked source files under `environment/repo/`.** Git metadata cleanup is
  allowed and expected. Source edits are not. (Step 5)
- **Never modify a pre-existing test file in the shipped repo tree.** It stays byte-identical
  to base. Test changes arrive through `tests/tests.patch`, which is allowed to edit a
  pre-existing test file - the accepted kvdex bundle patched 44 of them. (Step 5)
- **Never reduce or replace the source PR's scope.** Expansion only, and only to raise
  difficulty. If a fix would require reducing it, the verdict is Invalid / Not Fixable.
  (Section 3, and the `sentinel-difficulty-scope` rule)
- **Never build the zip before the Phase A gates pass, and never run the Phase B battery on
  `work/`.** The battery runs on fresh extracts of the built zip, so the artifact that ships
  is the artifact that was measured. Any edit after it voids it. (Step 5.5)
- **Never write form answers before the verified zip exists** in `tasks/<name>/upload/`.
  (Step 6)
- **Never run `solve.sh` or `test.sh` inside `work/`.** They mutate the tree. Use disposable
  extracts of the built zip in the session scratchpad. (Step 5.5)
- **Never edit a `.cursor/rules/*.mdc` without making the identical edit to its
  `.claude/skills/*/SKILL.md` twin**, or the reverse. (CLAUDE.md header)
- **Never mark a task Invalid over a platform or infra failure.** Rate limits, sandbox errors,
  a one-off nonzero exit and blank feedback are never Not Fixable conditions. (Section 3)
- **Never rewrite a bundle that came back with `Invalid Difficulty` already on it.** As of
  2026-08-14 the platform sets that answer on the validity question itself once four
  difficulty checks have run without passing, and hands the task back once carrying it.
  Resubmit unchanged and leave the verdict where the platform put it. It is not a rejection
  and a human reviewer still reads it (`docs/faq.md`, "Difficulty checks are now capped"). It
  is also the only situation in this workspace where resubmitting an untouched bundle is the
  correct action. Your own verdict discipline does not move with it: a repeated `FAIL EASY`
  is still not yours to turn into Unfixable - Difficulty. (Section 3)
- **Never submit with a pre-submit condition still failing.** There is no box to tick and no
  way to send anyway with an explanation attached. Evals that pass route the task to the
  reviewer queue on their own, and evals that fail return it to you, so a bad submit burns a
  round with nobody reading the task. Clear all eight conditions first. (Step 7)

## Always

- The sequence on a Fixable task is fixed: **fixes, then Phase A gates, then zip, then the
  Phase B battery, then answers.** No step moves. (Step 5.5)
- Run `bin/preflight.sh <task dir>` and get exit 0 before building the zip. Run
  `bin/pre-send.sh <task dir>` and get exit 0 before you submit. It is the pre-submit gate
  now: there is no Send to reviewer checkbox any more, so a submission whose evals pass goes
  to the reviewer queue on its own and one that fails comes straight back to you
  (`docs/tasking-guide.md:251`). The script keeps its old name. (Step 7)
- **Four difficulty checks per review cycle is the budget**, and it is spent by any check that
  runs and returns a result. A submission that comes back before the check runs costs nothing,
  a technical issue that prevents a result costs nothing, and a reviewer sending the task back
  restarts the count at zero, so it is a limit per review cycle and not per task lifetime
  (`docs/faq.md`). What follows from that budget, by reasoning rather than from any run here,
  is that the measuring moves in front of the upload: build implementations from
  `instruction.md` alone, run the discriminate matrix over the candidate levers, and check
  that every clause you already wrote is graded, all before the zip goes up. Spending a check
  to find out whether a lever picked by reasoning works costs a quarter of the budget.
  (Step 7, and the `sentinel-difficulty-scope` rule)
- Every finding cites a file path and, where possible, a line number. (Step 3)
- Record every revision round in the task's `task.md` with the feedback pasted verbatim, and
  update `INDEX.md`. (Step 10)
- Update `answers/submission_answer.txt` on every round so it describes the zip currently in
  `upload/`. One file, no second copy. (Step 10)

## If you are reviewing rather than submitting

Everything above is the submitter path. Timed peer review is the five-minute platform-first workflow in
`.claude/rules/14-reviewer-workflow.md` (Section 13), with one recorded five-minute static extension
at most. `.claude/rules/13-reviewer-path.md` (Section 12) owns the form, evidence, and tally. The timer
ends once the humanized answer is form-ready; archive and calibration work happen after that.

- **Reconcile `Reviewer Feedback` before new review work.** Mark every earlier required item fixed,
  partial, still open, or not assessed against current evidence. Then scan for new issues. No Accept
  while a prior required item remains not assessed.
- **Read the current reviewer page, not just a zip.** Read the relevant submitter answer, Comments for
  Reviewer, rebuttal, prior feedback when shown, and all displayed evaluation panels.
- **Use the ZIP-only fast gate.** `bin/preflight.sh --review-fast <submitted.zip>` is standard. Do not
  routinely run Docker, Harbor, Oracle, NOP, a verifier, containers, or mutation probes. The platform
  evaluation phase already owns those checks.
- **Extend only for a recorded concrete trigger.** Identity conflict, evidence contradiction, direct
  Major or PR-scope signal, or a named coverage/faithfulness discrepancy earns one static-only
  five-minute extension. Curiosity and a large repository do not.
- **Decide from confirmed evidence.** One Major or five Minors means Needs Revision. One to four Minors
  may be Accept with coaching. Invalid Difficulty is not an automatic Accept.
- **Never fix the bundle.** `work/` supports static inspection in the timed path.
- **Humanize every form-ready answer.** Keep evidence, verdict, score, citations, and actual elapsed
  minutes unchanged through the pass.
- **Do the three deferred document actions.** Study previous reviewer-feedback writing when present,
  update `learning/` from an accepted task, append the exact review UUID once to `review_tally.md`,
  and delete only matching root original and any supplied submitted ZIP source copies after form-ready verification.

## When sources disagree, and when you are unsure

`docs/` beats everything on policy, and `docs/reviewer-rubric.md` is the tab that states the
bar: one confirmed Major Pillar violation, or five Minor ones, is a Needs Revision, and it
grades the reviewer's own write-up as well as the task. `learning/` beats `CLAUDE.md` on what
the platform actually does, because every note is backed by a run. `facts.yml` owns the
numbers. Report
the conflict, do not quietly reconcile it. If you are unsure, stop and ask the submitter. A
wrong guess costs a whole eval round, and at most two tasks may sit in `pending-revision` at
once, so a burnt round blocks new work.
