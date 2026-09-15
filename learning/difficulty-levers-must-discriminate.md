---
id: difficulty-levers-must-discriminate
status: locally-verified
last_verified: 2026-08-16
verified_by:
  - 20260805_220102__xaaha_hulak__118
  - 20260803_111822__xlwings_xlwings__2719
  - 20260805_080500__statrs-dev_statrs__315
  - 20260807_080545__tair-opensource_redisshake__1005
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

## The matrix is a ceiling, not a forecast, and statrs 315 measured the gap

This note's method says ship the rows that disagree, and that a lever you cannot make anything
fail is not a lever. Both halves still hold. What statrs 315 added is the other direction:
**a lever can pass the whole control and still convert zero agents.**

Round 3 added an Anderson-Darling test and pre-measured it exactly as prescribed. Four wrong but
reasonable implementations, scored against the correct A squared of `0.162246714297`: no index
reversal gave `11.86`, both terms reversed gave `22.76`, weighting by `2i` gave `2.12`, returning
the adjusted figure gave `0.175`. The p-value moved from `0.925` to `0.000`. Every one was caught
by the new test, and the hostile-delete gate named it. By this note's standard that is a real
lever.

**It converted nobody.** The next screen returned byte-identical numbers, 7 of 8, and the agent
trajectories show the new test mentioned 14 to 33 times per run with all 8 trials implementing it
correctly.

**Why the control passed and the lever did not.** Look at whose implementations the two matrices
used. The xlwings matrix ran `oracle as shipped, v1, v2, v3, v5, vmin` - five honest builds of the
feature plus one deliberately partial one. The statrs matrix ran the oracle against four
implementations **written specifically to be wrong**. Those two measure different things. Breaking
a correct implementation on purpose proves an assertion has teeth; it says nothing about whether a
competent agent would ever write that mistake. Step 1 of The method says to collect *independent
implementations of the feature*, and honest is the load-bearing word.

**Third instance, and it is the one where the shape distinction cost something (hulak 118, accepted
2026-08-16).** That task answered a `FAIL EASY` with scope adapted from a related later PR and
pre-measured it: six rows, five plausible implementations plus the shipped oracle, five of them
failing the new graded id. It reads like the xlwings matrix and it is the statrs one. All five were
**written on purpose to be wrong** - copy the base keyboard path, fix only the mouse path, always
switch the single row, keep each field's own required flag, clear `required` along with `enabled` -
and not one is an independent honest build of the feature. No model was recorded against the number
either, so it is not even a labelled ceiling.

The bundle was accepted, and that settles nothing about the lever: no screen number was ever read for it
after the round that added it, its round 3 carried four more difficulty-relevant changes, and two
of those pull the other way. **Take the shape check as the cheap part of this note.** Asking "are
these five honest builds or five sabotages" costs one sentence and would have told that round its
own evidence was weaker than it looked.

So the matrix bounds difficulty from above. A row where every honest implementation agrees cannot
discriminate, which is what it is for. A row where hand-broken implementations disagree may still
discriminate nothing, because no agent writes hand-broken code. **Where an honest independent
build is unavailable, the closest substitute is the failing agent's own transcript from a previous
screen artifact**, which is a real implementation written without knowing the answer. See
[[difficulty-is-divergence-not-volume]] for the lever class that did convert on statrs, and
[[difficulty-screen-unit-table]] for how to get the artifact that carries those transcripts.

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

## The lever-class catalogue, with what each one measured (redisshake 1005)

Four rounds, four classes, deliberately different each time so a zero would mean something. All
four returned **0 of 4 against a local control**, and the task was then **accepted** carrying the
fourth. Read the classes as a search order, and read every number in the last column as a ceiling
(LEDGER L35, L51).

| Class | What it does | Measured | Worth trying again? |
|---|---|---|---|
| **More scope** | adapt a related later PR that adds surface to specify | 0 of 4 | Last resort. Once a format is written down, implementing it is mechanical. Same finding as statrs 315 and LEDGER L50 |
| **Less handed over** | delete the sentences where the instruction states the answer to its own hard parts | 0 of 4 locally, and **it is the one that actually bit on the platform** | **Yes, first.** Costs no id budget, no scope, no reviewer risk |
| **A real upstream defect** | adapt a later PR that fixes a genuine bug, so the natural implementation is the wrong one | 0 of 4 | Yes. Cheap and it improves the bundle whatever the screen says |
| **A liveness bug** | a loop condition that can never become false, so nothing fails, nothing logs, the run just stops | 0 of 4 | Yes, and it is the class that most deserves a re-measure against the graded models |

## Which withheld facts are levers, and which are not

The round-2 withholding was written off in this task's own answers as *"only one sensible value
for a reserved marker in a signed millisecond field, and I am not going to claim otherwise."* The
platform artifact then showed gpt-5.5 losing **seven graded assertions** to exactly that marker.

The dismissal was not wrong about the reasoning, it was wrong about the question. The test is not
*is there a sensible value*, it is:

> **Does the natural wrong reading compile, run, and produce output that looks plausible?**

`-1` in a signed 8-byte field read as unsigned is `18446744073709551615`. That is not zero, so a
`!= 0` guard passes, the code compiles, the test data flows, and the field gets an expiry instead
of being left alone. Nothing crashes. That is a lever.

Contrast it with the same task's header-length digits, also withheld, which no implementation ever
got wrong: getting that wrong fails immediately and loudly on the first byte, so the implementer
fixes it in the same minute they write it.

**So the rule for withholding: keep it withheld when the wrong reading is silent, and state it
when the wrong reading is loud.** A loud wrong reading is not difficulty, it is a debugging speed
bump, and stating it costs nothing.
