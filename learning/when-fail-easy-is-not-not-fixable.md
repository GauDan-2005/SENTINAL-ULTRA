---
id: when-fail-easy-is-not-not-fixable
status: platform-confirmed
last_verified: 2026-08-18
verified_by:
  - 20260807_080545__tair-opensource_redisshake__1005
evidence: "Four consecutive FAIL EASY screens, four lever classes each measured at 0 of 4 locally, a completed Not Fixable dossier, and the task was ACCEPTED on round 4. Recalibrated 2026-08-18 against docs/faq.md, which from 2026-08-14 caps a task at 4 difficulty checks per review cycle and sets Invalid Difficulty at the limit"
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty, verdict, evals]
blocks_submission: false
fails_gate: [difficulty-screen]
supersedes:
  - "its own third corollary as it stood on 2026-08-11, that a repeated FAIL EASY is not a strike count that terminates. Superseded by the four difficulty check cap in docs/faq.md, effective 2026-08-14"
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
- **A repeated `FAIL EASY` terminates at the fourth difficulty check, and until 2026-08-14 it did
  not.** This bullet used to read "not a strike count that terminates", which was true the day it
  was written and is superseded by the cap in `docs/faq.md`, recorded in the dated section below.
  The reasoning under it survives intact: the two-strikes rule (Section 4) tells you to stop
  refining one theory and remove the dependency, four screens on four different lever classes is
  four theories rather than four variations of one, and neither of those is a reason to stop
  shipping. What you no longer get is an unlimited number of attempts to work through them
- **Do not write the Not Fixable recommendation into the answers while the dossier is still
  yours alone.** This task left the verdict to the submitter and said so in `task.md`, which is
  why the wrong conclusion cost nothing. Had it gone into Comments for Reviewer it would have
  been a false claim in front of the person who accepted the task

## What acceptance did and did not settle

`docs/faq.md` puts the review gate before a reviewer, so a reviewer accepting the task implies
the round-4 bundle cleared the screen. **That is an inference from the documented ordering, not a
number anyone read** - no round-4 panel text or artifact was supplied. Cite it as "the bundle
carrying the writer lever was accepted", never as "the writer lever cleared the screen".

## 2026-08-14: the platform terminates this on its own now

Everything above was written on 2026-08-11, when there was no cap on how many times a task could
cycle through the difficulty check. `docs/faq.md`, "Difficulty checks are now capped - what is
Invalid Difficulty?", ends that era. Once **4 difficulty checks** have run on a task without
passing, the platform classifies it **Invalid Difficulty** by itself and sends it to review as it
stands. It is not a rejection, it is not retroactive, and a human reviewer still reads it.

**Nothing in this section is measured.** No task in this workspace has reached the cap, so every
consequence below follows from the wording of that FAQ entry rather than from a run. It is
documented policy, cited as such.

**The budget is four checks per review cycle, and only a check that runs and returns a result
spends one.** A submission that comes back to you before the difficulty check runs costs nothing,
and a technical issue that prevents a result costs nothing. A reviewer sending the task back
restarts the count at zero, which is why this is a budget per review cycle and not a limit on the
task's lifetime. Two of the four new read-only fields, *Difficulty checks run* and *Difficulty
checks remaining*, are where the count is visible.

**The practical consequence is that the measurement work moves in front of the upload.** Three
notes here already say how to find a lever without spending a screen to test it, and all three
were advice while rounds were free. They are now what the budget is for. Build implementations
from `instruction.md` alone and read back what each one was unsure about
(`implementation-control-is-the-lever-generator.md`). Run the candidate levers as throwaway
probes against every implementation you have and discard every row where honest implementations
agree (`difficulty-levers-must-discriminate.md`). Split the instruction you already shipped into
clauses and check that a test fails when each clause is violated
(`probe-the-instruction-you-already-wrote.md`). Spending a check to find out whether a lever
chosen by reasoning works is a quarter of the budget.

**Your own verdict discipline does not change.** Invalid Difficulty is the platform's verdict and
not yours, so you still do not reach Unfixable - Difficulty from a repeated `FAIL EASY` on your
own. The source-PR tell in the table above is still the first thing to run, and a local control
on a model newer than the ones the screen grades is still a ceiling and never a forecast. What
moved is only that the platform now arrives at a difficulty verdict of its own at four checks.

**And the cap creates the one case in this workspace where the right move is to upload an
unchanged bundle.** At the limit the task returns to you once with Invalid Difficulty already set
on the validity question. Submit it again without changing anything and leave the verdict where
the platform put it. It is not a bounce to fix, it is not a rewrite, and it is not your verdict to
restore.

## Where redisshake 1005 sits against the cap

The arc above ran to four `FAIL EASY` screens and an acceptance on round 4, which puts it **at or
past the cap**. Be exact about what that does and does not say. The record here is that the screen
blocked four times; it does not say how many difficulty checks ran in total, and the two need not
be the same number, because a check that returns no result never advances the counter. So write
"at or past the cap" and never "exactly four".

It also predates 2026-08-14 and the policy is not retroactive, so nothing about the arc was
affected by it. Reading the FAQ's wording forward, and assuming no reviewer bounce restarted the
count in between, a task worked this way today would be classified Invalid Difficulty before the
round that was accepted here ever got its passing check. That is a reading and not a measurement.
The lesson is not withdrawn by it. Four measured lever classes and sixteen independent
implementations were affordable when rounds were free, and the same demonstration now has to fit
inside four checks.
