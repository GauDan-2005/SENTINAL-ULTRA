---
id: clarity-fixes-spend-difficulty
status: platform-confirmed
last_verified: 2026-08-16
verified_by:
  - 20260805_080500__hyperledger-firefly_firefly__1123
  - 20260805_220102__xaaha_hulak__118
evidence: "Five rounds of judge and reviewer clarity fixes, then a difficulty screen returning FAIL EASY with codex-gpt-5-5 at 100% (4/4). Reading the instruction back, every divergence in the source PR had become an explicit checklist item. Second mechanism on hulak 118: a solvability fix moved the same needle in one step, 0/3 on both models to 75%/75% FAIL EASY, with no requirement removed and nothing clarified."
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty, quality, revision]
blocks_submission: false
fails_gate: [difficulty]
---

# A task can be clarified until it is easy, and nothing measures that until the screen runs

`difficulty-is-divergence-not-volume.md` ends with the warning that answering judge clarity findings
quietly spends difficulty. firefly 1123 is what that looks like when it runs to completion.

## The arc

| Round | What it answered | What it cost |
|---|---|---|
| 1 | judge, coverage and clarity | spelled out what an ABI entry is |
| 3 | reviewer, an ungraded stated clause | added the API input-schema requirement in full |
| 4 | judge, a coverage gap | stated the contracts manager lookups outright |
| 5 | reviewer, a false justification | no difficulty cost, correctness only |
| 6 | **difficulty screen, FAIL EASY, 4 of 4** | - |

No single round was wrong. Each finding was real and each fix was the right fix. The instruction that
came out the other end reads as a complete specification, and the graded model implemented it four times
out of four.

Read back at round 6, every divergence in the PR was being handed over: where the new constructor
parameter goes, that resolution works on the caller's reference in place, that each operation sends the
entry under its own key, that an unusable format is rejected before anything is sent, and the exact
three conditions on the announcement gate. Those are precisely the places a natural implementation goes
wrong, which is the xlwings failure in `difficulty-levers-must-discriminate.md` arriving by a different
road: there one requirement's wording enumerated the call sites a naive attempt would miss, here five
rounds of small clarifications did the same thing to a whole task.

## The counter-move is not more scope, and it is not un-clarifying either

Deleting the clarifications is not available. Each one is load-bearing for a graded assertion, so
removing it trades a difficulty problem for an alignment defect, which is the trade
`prescriptiveness-check.md` warns about from the other side.

What is available is **the divergences nobody stated yet**. A PR of any size contains behaviour that is
real, ungraded and unstated, and the rounds that clarify a task never touch it, because nothing ever
pointed at it. Sweep for that instead:

```bash
# exported things the oracle adds that no graded test names
grep -oP '^\+func (?:\([^)]*\) )?\K[A-Z]\w+(?=\()' solution/golden.patch | sort -u
# then, per hit, ask whether instruction.md states it at all
```

On firefly that returned one symbol, `GetFFIEvents`, which round 4 had found and deliberately left
ungraded **because the instruction did not state it**. That decision was right at the time and it is also
where the next round's difficulty came from. An ungraded symbol is a lever in waiting, so record it as
that rather than only as a closed coverage question.

## The best lever was a code move, not a code addition

The strongest one was not a symbol at all. `golden.patch` **moves** the asset-manager construction from
before the contracts manager to after it. Nothing in the diff looks like behaviour, and the failure it
guards is completely silent:

- the constructor's nil-dependency check does not cover the new dependency, so it accepts nil and starts
- the consuming path carries an `!= nil` guard, so it resolves nothing rather than crashing
- every graded unit test builds that manager directly with a double, so none of them can see it

An implementation that adds the parameter and passes the dependency without moving the block is passing
nil, forever, in production only. Measured: it passes assets, connector, events, database and contracts,
and fails only the new test.

**So diff the hunks that move code, not just the hunks that add it.** A relocation with no content change
is invisible to a file-list comparison and to a symbol sweep, and it is exactly where an ordering
contract hides.

## State it as an outcome or you have just written the next checklist item

The fix for both levers had to go into `instruction.md`, and the obvious wording rebuilds the problem:

- checklist: "construct the asset manager after the contracts manager"
- outcome: "whatever builds a namespace's managers has to hand it a contracts manager that already exists
  by then. Nothing complains if it does not, and every pool in that namespace then resolves no methods at
  all for as long as it runs"

The second states the requirement and the consequence, and leaves the mechanism to be worked out. Same
for the enrichment lever, stated as "the events come back the way the existing read of an interface with
its children already hands them over" rather than as "generate a signature for each event", so the work
is going and reading that code.

## The second mechanism: a SOLVABILITY fix spends difficulty in one step (hulak 118, accepted 2026-08-16)

Clarity is the slow way to arrive here. There is a fast one, and it is worse because the round that
does it is unambiguously right and the cost lands two rounds later.

`20260805_220102__xaaha_hulak__118` arrived carrying `pass_at_k_opus_4_8 = "0/3"` and
`pass_at_k_gpt_5_5 = "0/3"`, plus `agent_hardened = "true"` and `hardening_cycles = "2"`. Those are
the numbers of a hard task. They were the numbers of an **impossible** one: six unexported Go method
names existed only in the reference solution, and on a per-package compiler one wrong name takes the
whole test binary down, so a spec-complete implementation scored 0 of 17 by construction
([[non-derivable-private-names]]).

Round 0 fixed it. Round 2's difficulty screen then returned:

```
Difficulty: FAIL EASY - Requires at least MEDIUM
  claude-opus-4-8: 75.0% (3/4 runs)
  codex-gpt-5-5:   75.0% (3/4 runs)
```

**0 of 3 on arrival to 3 of 4 on the round-1 output, with no requirement removed.** Round 1 sits
inside that bracket and added coverage plus one bounded rewording, both of which push the other way,
so the swing is round 0's solvability fix plus a round that made nothing easier. What changed is that the measurement stopped measuring a build failure. LEDGER **L27** says
this in one line off redisshake 1005 and it is worth saying with a second number attached, because
the size of the swing is the part nobody budgets for.

**The rule, and it is cheap.** A round that fixes a solvability defect is a round whose difficulty
metadata has just become meaningless, so **budget a lever into that same round**. Two rounds were
spent on hulak learning this: round 2 for the screen to say so, round 3 for the judge block the
round-2 lever's own test edit created. Concretely, at the moment you conclude "the arrival pass rate
measured a build failure, not difficulty", do all three of these before the zip:

- Delete the arrival `pass_at_k_*` from your reasoning entirely. It described a different bundle
- Run the [[probe-the-instruction-you-already-wrote]] clause sweep **now**, not after a FAIL EASY.
  It is free, it costs no instruction surface, and it is the only lever available before you have a
  screen number to aim at
- Look for the trap in the source PR, per [[related-pr-carries-its-own-bug]]. On hulak it was sitting
  in a later PR that exists **because the PR 118 author got this wrong**, and finding it after the
  screen block rather than before it is what cost the round

`non-derivable-private-names.md` warns that the arrival metadata is indistinguishable from
difficulty. This is the other half of that warning: once you can distinguish them, you have also
learned that the task's real difficulty is unmeasured and probably low.

### What that lever then did, worded carefully

The round-2 lever was added scope adapted from a later related PR, pre-measured against five
implementations **written on purpose to be wrong**, which is the weak matrix shape
([[difficulty-levers-must-discriminate]]) and carries no model name, so it bounds the lever from
above and forecasts nothing. Round 4 reached a reviewer and was
accepted, and `docs/faq.md:70` puts the review gate before a reviewer, so both stages passed on it by inference, not by a number anyone read.

**Cite that as "the bundle carrying the lever was accepted", never as "the lever cleared the
screen"** ([[when-fail-easy-is-not-not-fixable]]). Nobody here read a round-4 number. And the
attribution is genuinely split: round 3 was a quality round answering a judge block, and its clause
sweep found one ungraded clause and asserted it, which is the xlwings lever class arriving by
accident. **A quality round can be a difficulty round without anyone deciding it should be.** That
cuts both ways and it is the cheerful direction of this note.

## Related

- [[difficulty-is-divergence-not-volume]] for the lever class and the statrs measurement
- [[difficulty-levers-must-discriminate]] for the matrix, and for honest builds being the right population
- [[when-fail-easy-is-not-not-fixable]] before anyone reads a repeated FAIL EASY as a verdict
- [[non-derivable-private-names]] for the solvability defect whose fix opens the hole above
- [[probe-the-instruction-you-already-wrote]] for the lever to run before the screen ever fires
