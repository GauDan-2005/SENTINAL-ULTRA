---
id: difficulty-levers-must-discriminate
status: locally-verified
last_verified: 2026-08-07
verified_by:
  - 20260803_111822__xlwings_xlwings__2719
evidence: "15 candidate behaviours run against 6 independent implementations of the same feature. 13 produced identical results everywhere and were discarded. The 2 that separated implementations were shipped, and one of them is a bug the upstream PR author wrote"
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty, quality]
blocks_submission: false
fails_gate: [difficulty]
supersedes: []
contradicts: []
---

# A difficulty lever is only real if honest implementations disagree about it

## The mistake this replaces

The obvious way to answer `Difficulty: FAIL EASY` is to think hard about the feature, pick a
requirement that *sounds* subtle, write it into `instruction.md`, add a graded test, and ship.

That is how xlwings 2719 spent a round. The lever was real work, the test was sound, the expansion
was sanctioned, and its measured difficulty value was **approximately zero**. An independent
implementation passed the whole suite first try with no debugging. The requirement's own wording
turned out to enumerate, in order, the exact three call sites a naive attempt would miss, so it
functioned as a checklist rather than a problem.

The failure is not that the lever was badly written. It is that **nothing measured whether it
separated anybody from anybody** before it shipped.

## The method

Difficulty is a statement about the gap between what an agent writes and what the task requires. So
measure that gap directly, on implementations you already have.

1. **Collect independent implementations of the feature.** The golden oracle counts. Any alternative
   implementation written to prove a test is not overfitted counts (`non-derivable-private-names.md`
   makes you write those anyway). A deliberately partial one, building the whole public API while
   skipping the part that costs real thought, is the most valuable of the set.
2. **Write candidate behaviours as a probe script, not as tests.** One function per behaviour,
   returning a short token. No pytest, no fixtures, no harness. They are throwaway.
3. **Run every probe against every implementation and print the matrix.**
4. **Discard every row where all implementations agree.** A behaviour they already agree on cannot
   separate an agent from the oracle, however subtle it reads. On xlwings 2719 that killed 13 of 15,
   including several that had felt like obvious wins when they were written.
5. **Ship the rows that disagree**, then confirm with the hostile-delete gate that the new assertion
   is what catches the regression.

Cost: one container run. It replaced a whole round of reasoning that had produced a dud.

## What the disagreement is telling you

The measured matrix on xlwings 2719, trimmed to the rows that mattered:

| Candidate behaviour | oracle as shipped | v1 | v2 | v3 | v5 | vmin |
|---|---|---|---|---|---|---|
| new sheet arrives on a metadata-only load | KeyError | KeyError | KeyError | ok | ok | KeyError |
| bare load must not ask the host for values | lazy | lazy | lazy | lazy | lazy | **asks** |

Two different signals, and they are worth different things.

**Row 1 splits the honest implementations against each other.** That is difficulty. The natural way
to satisfy one stated requirement (do not let a metadata-only refresh wipe values already loaded) is
to drop the value payload from every incoming sheet, which breaks another stated requirement (a
sheet arriving for the first time has to be usable). Both are derivable, so the task is fair. The
work is noticing the interaction.

**The strongest evidence a lever is real is that the upstream author got it wrong.** `PR 2719`
itself raises `KeyError` on that sheet. When the person who wrote the feature writes the bug, "the
natural implementation is the wrong one" stops being a claim about hypothetical agents.

**Row 2 splits the partial implementation off from all the honest ones.** That is not difficulty, it
is a **coverage gap**, and it is worth closing for a different reason: `vmin` built the entire public
API, never sent the wire flag, pulled every cell down on every load, and scored **41 of 41**. A
judge can find that on its own without ever thinking about difficulty. Fixing it also blocks the
most plausible agent shortcut, which is implement the surface and skip the protocol change.

Keep the two apart when writing Comments for Reviewer. Claiming a coverage close as a difficulty
raise is the overstatement that got retracted the round before.

## The id budget is the real constraint, and padding is where the slack is

`fail_to_pass` is capped at 20 by the static check. xlwings 2719 sat at 19, so exactly one graded id
was available and both levers needed one each.

The slack came from **auditing what was already there**. Four ids were asserting four spellings of a
single contract, which Section 10.8 calls padding rather than distinct contracts. Merging them into
one case with every assertion preserved is exactly what Step 2 item 3 prescribes for regrouping, and
it freed three slots. Two were spent and one was deliberately left unused, because the sweep found
nothing else that discriminates and filling it would re-add the padding just removed.

**Check the existing f2p list for padding before concluding you have no budget.** A cap of 20 is not
a cap of 20 useful contracts.

## The control that stops this from happening again

Before a lever ships, name a plausible implementation it newly fails, **write that implementation,
run it, and watch it fail**. If you cannot make anything fail it, it is not a lever, whatever the
requirement text says. A lever whose only evidence is that it sounds hard is the dud from the
previous round wearing new words.

The hostile-delete gate is the same control from the other side, and it must name the catching test.
On this bundle, reverting the fix to what the upstream PR does drops the reward to `0.0` and is
caught by exactly the new test, which is what makes the row above a measurement rather than a story.

See also [[raising-difficulty-on-a-wrapper-task]], [[non-derivable-private-names]],
[[diagnosing-platform-only-failures]], [[source-pr-cross-check]].
