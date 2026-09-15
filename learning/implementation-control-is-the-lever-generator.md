---
id: implementation-control-is-the-lever-generator
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260808_213817__openziti_ziti-sdk-c__668
evidence: "Rounds 4 and 5 each shipped a difficulty lever chosen by reasoning and each measured zero, three screens reading 7/8, 6/8, 7/8. Round 6 first generated four implementations from instruction.md alone: all four scored 26 of 26, proving nothing in the suite discriminated, and three of the four volunteered the same unasked-for gap, which became the lever. With it graded, the oracle held 26 of 26 and all four dropped to 25 of 26. The task was accepted on that round"
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty, verifier-design, quality-check]
blocks_submission: false
fails_gate: [difficulty]
supersedes: []
contradicts: []
---

# Answer a repeated FAIL EASY by building implementations, not by thinking harder

## The distinction this adds to the existing rule

[[difficulty-levers-must-discriminate]] says a lever is only real if independent implementations
disagree about it, and step 1 of its method is "collect independent implementations". In practice
that has always meant implementations **you** wrote: the oracle, plus a few alternatives authored
to prove a test is not overfitted.

[[LEDGER]] L30 is the reason that is not enough. Implementations you write to be wrong measure
your imagination, not an agent's behaviour, and L30 records four of them failing a trap that all
four honest agent implementations sailed through.

The move that works is narrower and it is cheap: **generate implementations of the feature from
`instruction.md` and nothing else.** No sight of `golden.patch`, no sight of `tests.patch` or
`config.json`, and an explicit instruction not to go and read the upstream commit. That last
clause matters more than it looks: an implementer who finds the real PR stops being a measurement.

What comes back is the closest local proxy for an agent trial that exists, because it is doing the
same task from the same words.

## What it answers, and all three are worth the run

**1. Does the suite discriminate at all.** This is the question three rounds of reasoning could not
settle. Four implementations, four different internal designs, **all 26 of 26**. Put beside the
platform's seven agent runs at 26 of 26, that is eleven implementations with no failed requirement
anywhere, and it converts "I think this task is easy" into a measurement.

**2. Is the suite overfitted to the oracle.** All four invented their own type for the endpoint
map's values, and three of them flagged it as a guess they expected to be caught on. None was.
That is the graded assertions reading keys, size, membership and observable behaviour instead of
the oracle's internals, and it is the strongest evidence of test quality this workspace has
produced. Run it before a coverage argument with a judge, not only when difficulty is the problem.

**3. Where the lever is.** See below. This is the part that was not expected.

## The honest-gaps report is the lever generator

Ask each implementation, in the prompt, to end with **an explicit list of every requirement it was
unsure about or did not implement**, and to be blunt that an inflated report ruins the measurement.

Those lists are a ranked catalogue of candidate levers, written by something that has just done
the task and has no idea what is graded. On ziti-sdk-c 668, **three of four independently
volunteered the same gap in almost the same words**: nothing re-reads the controller version after
the endpoint in use changes. Nobody asked about versions. It was the lever, it had a matching
upstream fix in a related later PR, and it took one round to confirm:

| tree | before | after grading the gap |
|---|---|---|
| oracle | 26 of 26 | 26 of 26 |
| impl 1 to 4 | 26 of 26 each | **25 of 26 each**, on that id and nothing else |

Three independent implementers converging on the same omission is a much stronger signal than one
reviewer's intuition, and it costs a sentence in the prompt.

**Where they merely differ is not a lever.** The same four disagreed about which endpoint is
picked first, whether a mid-response read failure also triggers failover, and whether an endpoint
is marked healthy again on success. Every one of those sits where the instruction deliberately
says nothing. Grading them is overreach; stating them first is handing over the answer, which is
the trap L29 to L33 measured four times on redisshake 1005. A disagreement is a lever only when
the instruction can state the **outcome** without the implementation following from it.

## Two ways a candidate lever is not what it looks like, both caught by measuring

Both of these were live on this task, both looked convincing, and both died in one container run.

**The defect may be yours rather than the bundle's.** Closing the controller from inside its own
response callback aborted on every implementation *and* on the oracle, which reads exactly like a
real upstream defect, and upstream's own commit message for the nearby fix even says *controller
may be disposed in callback*. It was `assert(ctrl->active_reqs > 0)` firing, and that assert is
added by `golden.patch`. The base tree has no such counter. Grading it would have invented a
requirement the source PR never had. **Check whether the failing line exists at the base commit
before building a round on it.**

**The upstream fix may defeat the requirement in your context.** The neighbouring commit reorders
the response callback to run after the address handling. Applied here it makes things worse, not
better, because the version is stored by that very callback, so clearing the version before it
runs throws away the new value and keeps the stale one. Correct upstream, wrong here.

## Adapt, and say why you adapted

`docs/faq.md` permits adapting a change from a **related** later PR. Adapting means the reason is
recorded, not that the diff was retyped. Upstream re-requests the version eagerly at the switch
site. Copying that here risks a switch, a request, a failure and another switch without end
against `uv_run`, which is the exact hazard that got a different candidate PR rejected two rounds
earlier. Clearing the cached value and letting the next caller ask gives the same guarantee with
no traffic and no hang. That sentence belongs in Comments for Reviewer, because a reviewer
comparing against upstream will otherwise read the difference as sloppiness.

## Cost, measured

Four implementations in parallel, roughly twenty minutes of wall clock each, against a prebuilt
image where an incremental build is two seconds. The whole control, including evaluating all four
against the graded suite, cost less than one bounced round, and rounds 4 and 5 each cost a full
round to learn nothing.

**Run it before the first difficulty lever, not after the second one fails.**

See also [[difficulty-levers-must-discriminate]], [[when-fail-easy-is-not-not-fixable]],
[[probe-the-instruction-you-already-wrote]], [[difficulty-screen-unit-table]],
[[related-pr-carries-its-own-bug]], [[LEDGER]].
