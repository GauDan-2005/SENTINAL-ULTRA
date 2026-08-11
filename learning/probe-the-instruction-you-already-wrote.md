---
id: probe-the-instruction-you-already-wrote
status: platform-confirmed
last_verified: 2026-08-09
verified_by:
  - 20260803_111822__xlwings_xlwings__2719
evidence: "Difficulty screen went 87.5% to 75% to 37.5% solves. The round that cleared it added no requirement at all: it graded the untested half of a sentence the instruction already carried. The platform artifact names that new id in two of the three opus failures"
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty, quality, verifier-design]
blocks_submission: false
fails_gate: [difficulty, quality]
supersedes: []
contradicts: []
---

# The difficulty you need is often an ungraded clause in the instruction you already shipped

## The pattern

When a task comes back `FAIL EASY`, the instinct is to add something: a new requirement, a lever
adapted from a related PR, more surface. [difficulty-levers-must-discriminate.md](difficulty-levers-must-discriminate.md)
already says most of those measure zero. This note is the other half of the answer.

**Before adding a requirement, take the instruction you have already written, split every sentence
into its separate clauses, and check that a test fails when each clause is violated.** The clauses
nothing grades are free difficulty: the behaviour is already stated so the task is fair, the agent is
already told to build it, and closing the hole costs one graded id and no new instruction text.

## The measurement

xlwings 2719, three rounds against the review-gate difficulty screen:

| Round | What it added | Combined solve rate |
|---|---|---|
| submission | - | 7 of 8, **87.5%** |
| round 1 | selective sheet loading, adapted from a related later PR | 6 of 8, 75% |
| round 2 | **one assertion on a clause already in requirement 13** | 3 of 8, **37.5%**, screen PASSED |

Requirement 13 read "Every other sheet keeps the values **and the loaded state** it already had".
The first half was tested and the second half was not. Making a selective load re-decide which sheets
count as loaded is a fair reading of "load these sheets", and it left the whole graded suite passing
at reward 1 with a stated rule broken.

**The platform artifact confirms the attribution rather than leaving it as a story.** Two of the
three failing opus trials list the id that round added among their missing tests. The clause that was
missing a test was also the thing agents got wrong.

## Why it beats an added requirement

- **It is fair by construction.** The agent was already told to do it, so nothing about the task got
  more obscure. Difficulty from a stated-but-unenforced rule is the good kind, not vagueness.
- **It costs no instruction surface.** No new sentence means no new chance of a leak finding, an
  over-prescription finding, or a `test_faithfulness` mismatch. On a task sitting at the twenty id
  ceiling this matters even more, since a guard for behaviour that already works at base goes in
  `pass_to_pass` and does not touch the cap at all.
- **A reviewer will find it if you do not.** The same task's first human review returned exactly one
  finding, and it was this shape: requirement 4 stated two branches of a default and the suite held
  only one. The reviewer broke the unheld branch and got a clean 42 of 42.

## How to run it

For each sentence in `instruction.md`, list its clauses. For each clause, write the smallest edit to
the oracle that violates that clause and nothing else, apply it in a container, and run the graded
suite. Any clause where the suite stays green is a hole.

Two mechanics that decide whether the result means anything:

- **Assert the sabotage landed before reading the reward.** `assert s.count(old) == 1` in the probe.
  A pattern that no longer matches gives a green suite that looks like coverage. On this task two
  carried-forward probes silently stopped matching after a later round rewrote the code they patched,
  and only the assert turned that into a refusal instead of a false all-clear. **Re-verify every
  probe each round**; a probe rots against the tree it patches.
- **Decide `fail_to_pass` versus `pass_to_pass` by running the new test at the base commit**, not by
  where it feels like it belongs. If it passes at base it is a regression guard. On this task that
  check is what kept a guard out of an f2p list already at the hard ceiling of 20.

See also [[difficulty-levers-must-discriminate]], [[related-pr-carries-its-own-bug]],
[[quality-check-criteria]], [[peer-review-bounces]].
