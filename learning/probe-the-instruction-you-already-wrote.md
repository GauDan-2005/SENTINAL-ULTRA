---
id: probe-the-instruction-you-already-wrote
status: platform-confirmed
last_verified: 2026-08-16
verified_by:
  - 20260805_220102__xaaha_hulak__118
  - 20260803_111822__xlwings_xlwings__2719
  - 20260805_080500__hyperledger-firefly_firefly__1123
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

## Confirmed by a peer reviewer, statrs 315, 2026-08-07

The strongest version of this note's point, because it was found by someone else after every
local gate passed. On the round in question the board read: agentic judge OK, oracle 3/3 at 1.0
with 128 of 128, NOP 0 with raw exit 101, seven hostile probes each naming its catching test, 90
assertions, the Q9 navigation detector at 0 candidates and the Q10 leak detector at 0 of 0.
Nothing local had anything left to say.

A peer reviewer then found that the exact Mann-Whitney one-sided p-values were on the wrong tail
whenever the first sample was not the larger one, a defect still present on the project's master
branch today. **No gate in this battery could have caught it**, because every graded assertion had
been written from the oracle's own observed behaviour, so the tests agreed with the bug by
construction. One block even carried a comment stating the opposite of what its assertion checked,
and the bug is what made the assertion pass.

The transferable rule is the one this note already argues, arriving from the outside: an
assertion whose expected value was read off a run tests only that the run is reproducible. Where
the instruction names an external standard, implement that standard separately and compare. See
[[oracle-bug-vs-pr-scope]] for the full case and the authorisation to fix the oracle when it comes
to that.

## The pattern

When a task comes back `FAIL EASY`, the instinct is to add something: a new requirement, a lever
adapted from a related PR, more surface. [difficulty-levers-must-discriminate.md](difficulty-levers-must-discriminate.md)
already says most of those measure zero. This note is the other half of the answer.

**Before adding a requirement, take the instruction you have already written, split every sentence
into its separate clauses, and check that a test fails when each clause is violated.** The clauses
nothing grades are free difficulty: the behaviour is already stated so the task is fair, the agent is
already told to build it, and closing the hole costs no new instruction text, and often no new
graded id either. See the hulak section below for the third route and why it is the whole decision
when the f2p list is near the cap.

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

## Confirmed again, by a reviewer, 2026-08-08

firefly 1123 passed **every** evaluation check and then came back from peer review with two
findings. The first was exactly this note's shape: the field table said two pool fields were never
accepted as caller input, the oracle implemented it, and nothing asserted it, so an implementation
exposing both as writable API input scored 1.0 on all 18 graded tests.

So the line above, *"a reviewer will find it if you do not"*, is now two for two, and the cost is a
round rather than a rewrite. **Run the clause-by-clause pass before the bundle goes up, not after a
green board.** A full set of green checks is exactly the state in which this defect survives, because
every check is satisfied by the tests you wrote and none of them knows about the clause you did not.

The second finding was the mirror image, an assertion with no clause behind it, which is the same
map read in the other direction. Walking it both ways costs one pass:

| Direction | Failure it finds |
|---|---|
| clause has no assertion | a stated rule an implementation can ignore |
| assertion has no clause | overreach, graded behaviour the agent was never told about |

## Run it BEFORE the board is green, and the closure need not cost an id (hulak 118, accepted 2026-08-16)

The three cases above were all holes found after everything passed, two of them by a reviewer.
hulak 118 is the first record of the sweep being run the way this note asks for: as a pre-upload
pass, on a round that was fixing something else entirely, before any screen had complained. It
found one.

Six clauses were broken one at a time in a throwaway copy and five went red with a named test. The
sixth, "its rendered view marks the search area and every visible row", left the **whole suite
green** when the first row was left unmarked, because no test ever clicked it. That round was
accepted.

**It cost zero graded ids, and the `pass_to_pass` route above was not available.** The clause is
part of the new feature, so an assertion on it fails at base and cannot be a regression guard. The
third route is the one `static-checks.md` records for a different reason: a `fail_to_pass` id maps
to one **top-level test**, not to one assertion, so the closure goes **inside a graded test that
already exists**. Here it was appended to `TestSelectorClickOnARowSelectsAndConfirmsIt`, and
`fail_to_pass` stayed at **19** against the hard ceiling of 20.

Order of preference when a slot is tight:

1. **Fold into an existing `fail_to_pass` id** whose test already exercises that surface. Free
2. **`pass_to_pass`**, if the behaviour already works at the base commit. Also free, and it misses
   the 20-id cap entirely
3. **Spend a new id.** Only when neither of the above reaches the surface

The cost sentence at the top of this note used to assert route 3 unconditionally. It is wrong as
stated: closing a hole costs a graded id only when no existing id is already exercising that
surface, and at 19 of a hard 20 that distinction decides whether the sweep is available at all.

See also [[difficulty-levers-must-discriminate]], [[related-pr-carries-its-own-bug]],
[[quality-check-criteria]], [[peer-review-bounces]], [[static-checks]].
