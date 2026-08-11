---
id: not-fixable-is-a-written-argument
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260723_030109__cryspen_libcrux__1165
evidence: "Submitted Invalid / Not Fixable on the PR-scope trigger with no zip upload, so the reviewer saw only the verdict, two checkbox groups, a 4929-character seven-block unfixable explanation and 2172 characters of Comments for Reviewer. Accepted 2026-08-11, the first accepted Not Fixable in this workspace and the first acceptance of a submission with no bundle attached"
applies_to:
  languages: [any]
  runners: [any]
  phases: [analysis, difficulty, peer-review]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts: []
---

# On Path C the write-up is the whole submission

`raising-difficulty-on-a-wrapper-task.md` owns **why** the libcrux verdict was right. This note
owns **how it was written** and what its acceptance does and does not prove. Neither repeats the
other.

## What the reviewer actually saw

Four things, and nothing else:

- the verdict, in both occurrences, plus the `[Internal] Validity` field (`answers/submission_answer.txt:1-6`)
- the two checkbox groups, one of them entirely unticked (`:8-17`)
- the unfixable explanation, **4929 characters in seven numbered blocks** (`:19-32`)
- Comments for Reviewer, **2172 characters in five paragraphs** (`:34-39`)

That is an 8317-byte text file. **The Path C form has no zip upload field**, so nothing in
`upload/` was graded, no eval ran on the closing round, and none of the four rounds of verifier
hardening was visible to anyone. `docs/tasking-guide.md:209` warns that a vague or incomplete
description may lead to rejection, and on this path there is no bundle to make up the difference.

## The shape of the explanation that was accepted

This is the reusable part. Seven blocks, each an independent leg that still stands if the others
fall, and each one claim plus the measurement behind it:

| Block | The claim | The measurement behind it |
|---|---|---|
| 1 | the PR is a naming layer over a finished implementation | 18 oracle bodies of 1 to 7 lines, five of them one line, all forwarding to base-commit exports; +450 / -4 lines |
| 2 | it was already easy before anyone here touched it | `pass_at_k` 2/3 both models, `agent_hardened = true`, `hardening_cycles = 1`, read out of the pristine `task.toml` |
| 3 | expansions were shipped and did not move it | 8/8 then 4/4 then 4/4, both models 100 percent, each expansion verified to fail an implementation that previously scored 1.0 |
| 4 | eight more were prototyped and measured | every one zero, three compiling and passing on the first attempt |
| 5 | two stronger candidates were killed on evidence | `deny(unsafe_code)` at `lib.rs:68`; workspace-wide `simd256` under resolver v1 |
| 6 | the one lever that would work is banned and overshoots | `docs/guidelines.md:197`; and 17 passing to 0 on a single argument-order difference |
| 7 | therefore the only route left is replacing the PR | `docs/guidelines.md:217` |

**The rule: every block names a number or a file:line, and no block is an opinion.** A block that
only asserts the task cannot be made harder is exactly the vague description
`docs/tasking-guide.md:209` is about. Blocks 5 and 6 matter more than they look, because they are
the ones that show the search was real rather than abandoned early.

## The verdict chain

`docs/guidelines.md:217` names difficulty explicitly, "If the only way to make a task solvable,
**difficult enough**, or valid is to reduce or replace the PR scope, the task is Not Fixable", and
the Fixable row at `:65` is a conditional, "too easy **but you can raise difficulty by adding to
the PR scope**". So the verdict turns on one empirical question: can difficulty be raised by
adding. The evidence that answered it here is in
[raising-difficulty-on-a-wrapper-task.md](raising-difficulty-on-a-wrapper-task.md) and is not
repeated in this note.

## The checkbox left blank on purpose

Environment Issues was unticked, with a parenthetical saying so and why
(`answers/submission_answer.txt:12-17`): the environment was healthy, so ticking a sub-box to
strengthen the case would have been false. **On Path C, say why you did not check a box.** An
unchecked box and an overlooked box look identical to a reviewer, and there is no bundle for them
to check your judgement against.

## What the acceptance validated, and what it did not

Read this section before citing the task anywhere.

**Validated**, because each was the thing actually put in front of the reviewer:

- the verdict on the PR-scope trigger, for a difficulty ceiling rather than a defect
- the trigger choice, with every Environment sub-box left blank
- the evidence standard: seven blocks and about 4900 characters cleared a field the docs say gets
  rejected when it is vague, and this is the only calibration point the workspace has for it
- stopping after expansion was **exhausted** rather than after it was attempted

**Not validated**, and this half is unusually large here:

- **anything about the bundle.** No zip was uploaded. The 17 defects fixed across rounds 1 to 4,
  the git-free test-tree restore, the fail-closed grader, the nine hostile probes: none of it was
  reviewed. On a Fixable acceptance the rule is that everything not previously failing merely was
  not caught. Here it was never looked at, which is weaker still.
- **that the task is objectively unfixable.** A reviewer accepted the case as argued. That is
  evidence the argument was sufficient, not that the conclusion is a fact about the world.
- **that five rounds were necessary.** The structural measurement that carried the verdict was
  available at the first difficulty failure. Whether the same verdict would have been accepted at
  round 3 is unknown and cannot be inferred from this outcome. The acceptance says the case was
  sufficient. It says nothing about whether it was minimal, and two rounds may have been spent
  proving something already provable.
- **the difficulty metrics themselves.** `removed/added` separated the easy task from the hard ones
  across the bundles here, but the direction was chosen after seeing the data and no platform check
  consumes that number.
- **any general rule about wrapper PRs.** One PR, one crate that happened to implement the whole
  algorithm already. The next wrapper task may have a real gap underneath and be perfectly hard.

**The rule this produces: an acceptance on Path C validates the argument, not the bundle and not
the effort spent reaching it.** Cite this task for the evidence standard and the reasoning chain.
Do not cite it as proof the verifier hardening was correct, because nobody looked, and do not cite
it as proof that five rounds was right, because nobody was asked.

## Calibrating a Path C row

Most `calibration.tsv` columns describe a bundle. On Path C no bundle was graded, so on this row
read them as what was built rather than as what passed. The `verdict` column records the path
submitted and `outcome` records what the reviewer returned; the two are not the same question and
should never be folded into one cell.

See also: [raising-difficulty-on-a-wrapper-task.md](raising-difficulty-on-a-wrapper-task.md),
[accepted-bundle-reference.md](accepted-bundle-reference.md),
[platform-announcements.md](platform-announcements.md), and LEDGER L19 and L47.
