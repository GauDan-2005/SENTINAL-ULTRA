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

1. Read **every file in `learning/`**, starting with `learning/README.md`, then read
   `INDEX.md`. Do this before asking a question or opening a task. (Step 1)
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
- **Never zip before the local NOP and oracle checks both pass.** NOP reward `0.0`, oracle
  reward `1.0`. (Step 5.5)
- **Never write form answers before the verified zip exists** in `tasks/<name>/upload/`.
  (Step 6)
- **Never run `solve.sh` or `test.sh` inside `work/`.** They mutate the tree. Use disposable
  copies in the session scratchpad. (Step 5.5)
- **Never edit a `.cursor/rules/*.mdc` without making the identical edit to its
  `.claude/skills/*/SKILL.md` twin**, or the reverse. (CLAUDE.md header)
- **Never mark a task Invalid over a platform or infra failure.** Rate limits, sandbox errors,
  a one-off nonzero exit and blank feedback are never Not Fixable conditions. (Section 3)

## Always

- The sequence on a Fixable task is fixed: **fixes, then local checks, then zip, then
  answers.** No step moves. (Step 5.5)
- Run `bin/preflight.sh <task dir>` and get exit 0 before building the zip. Run
  `bin/pre-send.sh <task dir>` and get exit 0 before checking Send to reviewer.
- Every finding cites a file path and, where possible, a line number. (Step 3)
- Record every revision round in the task's `task.md` with the feedback pasted verbatim, and
  update `INDEX.md`. (Step 10)
- Update `answers/submission_answer.txt` on every round so it describes the zip currently in
  `upload/`. One file, no second copy. (Step 10)

## When sources disagree, and when you are unsure

`docs/` beats everything on policy. `learning/` beats `CLAUDE.md` on what the platform
actually does, because every note is backed by a run. `facts.yml` owns the numbers. Report
the conflict, do not quietly reconcile it. If you are unsure, stop and ask the submitter. A
wrong guess costs a whole eval round, and at most two tasks may sit in `pending-revision` at
once, so a burnt round blocks new work.
