---
id: when-fail-easy-is-not-not-fixable
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260807_080545__tair-opensource_redisshake__1005
evidence: "Four consecutive FAIL EASY screens, four lever classes each measured at 0 of 4 locally, a completed Not Fixable dossier, and the task was ACCEPTED on round 4"
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty, verdict, evals]
blocks_submission: false
fails_gate: [difficulty-screen]
supersedes: []
contradicts:
  - "LEDGER L34, whose replacement text reads as: when four measured levers return zero, the task has no lever"
---

# Four easy screens, four measured zeroes, and the task was accepted

The companion to `not-fixable-is-a-written-argument.md`. That note records libcrux 1165, where a
difficulty ceiling really was the verdict. This one records the task that looked identical from
the inside and was not, so the two can be told apart before a verdict is written.

## What the dossier said, and why it was believable

redisshake 1005 was blocked at the review gate's difficulty screen **four times**. The agentic
judge passed every round (`verdict: ok`, test_faithfulness 5.0, oracle axes 5.0, packaging 5.0,
test_coverage 3.5), so the screen was the only thing standing in the way, and each round answered
it with a different class of lever:

| Round | Lever | Class | Local control |
|---|---|---|---|
| 1 | PR 1038 adapted, server type detection | more scope to specify | **0 of 4** |
| 2 | withheld the two pre-solved answers from `instruction.md` | less handed over | **0 of 4** |
| 3 | PR 1048 adapted, a real upstream defect in the AOF reader | a defect, not a format | **0 of 4** |
| 4 | PR 1043's writer half, a liveness bug that spins forever | a hang, not a wrong value | **0 of 4** |

Sixteen independent implementations written from `instruction.md` alone, every one scoring 1.0.
Six further merged PRs surveyed and rejected, several with measurements of their own. Every leg
LEDGER L21 says a Not Fixable verdict needs was held: a measured task-side cause, an exhausted
option space including related later PRs rejected on evidence.

**Round 4 was accepted.** The dossier was complete, internally consistent, and wrong.

## The two things that made it wrong

**1. Every local zero was measured against a stronger model than the screen grades.** Stated
plainly in round 2, allowed to decay into a footnote by round 3, and by round 4 argued into its
opposite ("two independent measurement systems now agree"). They never agreed. See
`stated-caveats-decay.md`, which is the general form of this failure, and LEDGER L52.

**2. The lever that actually bit was the one dismissed as not a lever.** Round 2's withholding
of the never-expires marker was written off in the answers file as "removing hand-holding rather
than adding difficulty ... only one sensible value for a reserved marker in a signed millisecond
field, and I am not going to claim otherwise." The platform artifact for the round-3 bundle shows
gpt-5.5 losing **seven graded assertions** to exactly that marker, reading the all-ones pattern
as unsigned and gating on `!= 0`:

```
got:  hpexpireat h 18446744073709551615 fields 1 b
want: (no expire command at all)
```

Everything else in the task it got right. Opus 5 found the marker in 16 of 16 local
implementations. gpt-5.5 did not.

## Telling this task from libcrux 1165

Both had a difficulty ceiling that resisted every lever. One is Not Fixable and one was
accepted, and the discriminator is **the substance of the source PR**, not the number of failed
screens or the size of the dossier.

| | libcrux 1165 (Not Fixable, accepted as such) | redisshake 1005 (Fixable, accepted) |
|---|---|---|
| What the PR does | wraps existing functions. 18 oracle bodies of 1 to 7 lines, removed/added ratio 0.01 | a format branch plus command routing, 24 files in golden |
| Is there real work behind the instruction | no, the API names **are** the deliverable | yes, a flavor has to travel from a 9-byte header down to a decoder |
| Does the PR's own author get anything wrong | no | **three times**, all three still on the default branch today |
| Where the ceiling comes from | the PR has no depth to expose | the implementer's model is good enough to find the traps |

The third row is the practical test. **A PR whose own author got something subtly wrong has a
trap in it, and a trap you have found is a trap a weaker model can fall into.** A PR with no such
place is where the ceiling is structural.

## The rule this produces

**Ship the better bundle even when its difficulty lever is unmeasured.** Round 4's own record
said it: "worth shipping regardless: the append-only command stream is now graded where it was
not, two padding ids were merged with every assertion surviving, and `golden.patch` carries a
second documented upstream defect fix." That reasoning was right and it is the reasoning that got
the task accepted.

The difficulty verdict is not yours to compute. What is yours to compute is whether this round's
bundle is more correct, better covered and more authentic than the last one. When the answer is
yes, upload it and let the screen answer its own question.

Three corollaries:

- **A local control that returns all-pass is a ceiling, never a forecast.** Record it as "n of n
  against <model>", never as "the task is easy". `n of n` from a model stronger than the graded
  ones is compatible with the graded ones failing, and on this task it was
- **A repeated `FAIL EASY` is not a strike count that terminates.** The two-strikes rule
  (Section 4) tells you to stop refining one theory and remove the dependency. It does not tell
  you to stop shipping. Four screens on four different lever classes is four theories, not four
  variations of one
- **Do not write the Not Fixable recommendation into the answers while the dossier is still
  yours alone.** This task left the verdict to the submitter and said so in `task.md`, which is
  why the wrong conclusion cost nothing. Had it gone into Comments for Reviewer it would have
  been a false claim in front of the person who accepted the task

## What acceptance did and did not settle

`docs/faq.md` puts the review gate before a reviewer, so a reviewer accepting the task implies
the round-4 bundle cleared the screen. **That is an inference from the documented ordering, not a
number anyone read** - no round-4 panel text or artifact was supplied. Cite it as "the bundle
carrying the writer lever was accepted", never as "the writer lever cleared the screen".
