---
id: platform-announcements
status: reported
last_verified: 2026-08-06
verified_by:
  - "none in this workspace — relayed from a sibling workspace's notes and from Slack"
evidence: "Operational rules that reach ECs through Slack and never appear in the exported Hub tabs"
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty, oracle, process]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts: []
---

# Platform announcements and operating rules that never reached `docs/`

**Provenance and rank, read this first.** Everything in this file arrived through Slack or
through another EC's workspace notes. None of it has been reproduced on this machine, and none
of it is in the nine Hub tabs under `docs/`, apart from the last section, which is the dated log
of announcements the export has since carried and is marked as such. That makes this file
**subordinate to `docs/` on policy and subordinate to the run-backed notes in this folder on
observed behaviour.** When it disagrees with either, they win and the entry here gets corrected or
deleted.

It exists because the alternative is worse. Rules that only ever get announced in a channel
have nowhere else to live, so they get remembered by one person and lost by everyone else.

Each entry says where it came from and whether it carries a date. An undated entry is marked as
such, because a rule with no date cannot be checked against a changelog later.

---

## The difficulty rerun ladder

**Source:** sibling workspace notes, relayed via Slack. **Date: not recorded.**
**Status: reported, not reproduced here.**

A failed Difficulty Check on an unchanged bundle is not a verdict. The ladder is:

1. **Rerun it once.** Difficulty runs are agent simulations and they are noisy. Trials get
   scored invalid for reasons that have nothing to do with the bundle.
2. **If it fails again, rerun it a second time.** Two independent runs of the same bundle
   returning the same result is the first evidence worth acting on.
3. **Only then diagnose, or escalate** on Slack with the submission UID, the exact result text
   and whether it is intermittent.

**A failed Difficulty Check is never automatically a Not Fixable verdict.** `docs/guidelines.md`
lists what makes a task Not Fixable and a difficulty result is not on the list.

### Where this stops and the two-strikes rule starts

The two-strikes rule in
[diagnosing-platform-only-failures.md](diagnosing-platform-only-failures.md) governs a bundle
you have **changed**: a fix you verified locally comes back failing a second time, so stop
refining the theory and remove the dependency. It assumes a fix has shipped between the runs.

The ladder here governs a bundle you have **not** changed: same zip, same local checks green,
the screen came back red once. Rerun before diagnosing anything.

The two rules are about different things and the boundary is whether a fix shipped between the
two results. Reruns come first, two strikes comes after.

### Where the ladder does NOT apply: a review-gate difficulty screen

Added 2026-08-06, when the Hub documented the review gate (`docs/faq.md`, "My eval says Review
gate blocked at the agentic judge / difficulty screen"). Read this before rerunning anything,
because the ladder above was written when a red difficulty result was assumed to be noise, and the
Hub now says that a review-gate block usually is not.

The ladder is about **noise**: trials scored invalid, a harness failure, a result that does not
reproduce. A review-gate difficulty screen that reports the task **trivially easy, the model solved
every attempt** is not noise. It is a measurement, it will reproduce, and rerunning it burns a
round to be told the same thing. The answer is added difficulty, per Fixable trigger 8.

Read the message, not the colour:

| What the result says | Is it the ladder's case? | What to do |
|---|---|---|
| invalid trials, harness failure, a result that did not reproduce | yes | rerun once, then again, then diagnose |
| blocked at the difficulty screen, model solved every attempt | no | raise difficulty, do not rerun |
| blocked at the agentic judge | no | get the "Agentic Judge Quality Report" field and fix what it cites |
| the difficulty screen failed with an infra error, said explicitly | yes | retry, no verdict was produced |

**What survives unchanged:** a failed Difficulty Check is still never *automatically* a Not Fixable
verdict. `docs/faq.md` answers a difficulty-screen block with "add difficulty, then resubmit", which
is the Fixable path, not the Invalid one. That claim in the section above is confirmed rather than
weakened, and `raising-difficulty-on-a-wrapper-task.md` is still the note that says what a complete
Not Fixable answer has to contain.

**One thing this file can now stop guessing about.** The single-arm screen and its ordering behind
the agentic judge were recorded here and in `README.md` as observation from this workspace's own
runs. They are documented Hub behaviour as of 2026-08-05 and no longer second-hand, so the rule now
lives in `.claude/rules/05-evals-and-quality-check.md` under the review gate, sourced to `docs/`.

### What the ladder costs now that difficulty checks are capped

**Source:** `docs/faq.md`, "Difficulty checks are now capped - what is Invalid Difficulty?".
**Date: 2026-08-14**, recorded here 2026-08-18.
**Status: documented policy, not reproduced here.** Nothing in this workspace has watched a
difficulty counter move, and the interaction with the ladder below is a **reading** of the FAQ's own
sentence rather than a measurement. Keep the two apart before acting on either.

Before 2026-08-14 a task could cycle through the difficulty check with no limit, which is the era
the ladder above was written in, when a rerun cost wall clock and nothing else. From 2026-08-14 a
task gets **four** difficulty checks. Once four have run without passing, the platform sets your
answer on the validity question to **Invalid Difficulty** itself and sends the task to review as it
stands. That is not a rejection, it does not apply retroactively to earlier tasks, and a human
reviewer still reads it. The task comes back to you once with the verdict already on it, and the
correct action then is to submit it again unchanged and leave the verdict as the platform set it.

The budget is per **review cycle** rather than per task lifetime. `docs/faq.md` says the count
restarts at zero when a reviewer sends the task back, so four is what one trip through the checks is
worth, not what the task gets for its whole life. Two of the four new read-only fields, Difficulty
checks run and Difficulty checks remaining, are where the number is read.

**What the ladder still buys.** Its subject has not changed. A red difficulty result on a bundle you
have not touched can still be noise, and two independent runs of the same bundle returning the same
result is still the first evidence worth acting on. The table above still decides whether a result
is the ladder's case at all, and a review-gate screen reporting the task trivially easy was never in
it.

**What it now costs, and this is a reading and not a measurement.** `docs/faq.md` says the counter
"only increases when a difficulty check runs and returns a result". Taken at its word, a rerun that
comes back with a result is a difficulty check that ran and returned one, so step 1 of the ladder
spends a quarter of the cycle's budget and step 2 spends half of it. Nobody here has seen that
happen, so read the Difficulty checks remaining field before rerunning anything and trust it over
this paragraph.

**The ladder's own escape hatch is the case the FAQ exempts.** The last row of the table above is a
difficulty screen that says explicitly it failed with an infra error, which is a run that produced
no verdict. `docs/faq.md` says a submission that comes back before the check runs, or one where a
technical issue prevents a result, does not count against you. That is the same case in the FAQ's
own words, so retrying a run that produced no verdict is still free. A run that produced a verdict
you did not want is not.

**One claim in the rule set is superseded here.** "A repeated `FAIL EASY` does not terminate" was
true until 2026-08-14 and is false from that date, because it terminates at the fourth check.
The reasoning under it survives untouched: four screens answered by four genuinely different lever
classes is four theories rather than four variations of one, and the two-strikes rule still does not
apply to it the way it looks like it should. What went away is the unlimited supply of attempts to
work through those theories. Recorded as LEDGER **L99**.

**Where the time goes instead.** Reruns and levers chosen by reasoning were affordable while rounds
were free. With four checks in the cycle, the work that finds a lever belongs before the upload, and
this workspace already knows which work that is: build implementations from `instruction.md` alone
([implementation-control-is-the-lever-generator.md](implementation-control-is-the-lever-generator.md)),
run the candidate levers as throwaway probes against every implementation you have and discard the
rows they all agree on ([difficulty-levers-must-discriminate.md](difficulty-levers-must-discriminate.md)),
and split the instruction you already wrote into clauses to check that violating each one fails a
test ([probe-the-instruction-you-already-wrote.md](probe-the-instruction-you-already-wrote.md)).
Spending a check to find out whether a lever chosen by reasoning works is a quarter of the budget.

**What the cap does not change.** Invalid Difficulty is the platform's verdict, not yours. Reaching
Unfixable - Difficulty yourself still needs what it always needed: the source-PR tell, whether the
PR's own author got something subtly wrong, and the knowledge that a local control runs on a newer
model than the screen grades, so it is a ceiling and never a forecast
([when-fail-easy-is-not-not-fixable.md](when-fail-easy-is-not-not-fixable.md)). What ends at four
checks is the platform's patience, not the verdict discipline in
[raising-difficulty-on-a-wrapper-task.md](raising-difficulty-on-a-wrapper-task.md).

---

## The oracle bar is 3 of 3

**Source:** the platform's own result text, seen on this workspace.
**Status: confirmed here.** Included because it is what the rerun ladder is usually
about.

The platform runs the oracle **three times** and requires all three to pass. The failure text
is:

```
Oracle did not pass all runs: 0/3. Task may be flaky or has infra issues.
```

Two consequences that a single local run cannot see:

- Any per-run state change in `solve.sh` fails this even when run one is perfect
  ([solve-sh-idempotency.md](solve-sh-idempotency.md)).
- The wording blames flakiness and infra, which reads as a platform problem and usually is not.
  Both times a 0/3 appeared in this workspace it survived a rerun.

So on a 0/3: rerun per the ladder, and while it runs, invoke `solve.sh` twice in one container
and check whether the second run is a no-op. That covers the two commonest causes at once.

---

## Dated announcements that `docs/` now carries

**Source:** `docs/whats-new.md`, read in the 2026-08-18 re-export, which re-rendered whats-new.md
and faq.md from the live Hub and is the export the Aug 14 entry arrived in.
**Status: documented.** Kept here only so the dated log stays complete. `docs/` is the authority
for all of it, and none of these entries is second-hand.

- **2026-08-05, the "Send to reviewer" checkbox was removed.** Passing post-submission evals route
  the task to the reviewer queue by themselves and a failing one comes back to fix and resubmit, so
  there is no box and the `AlwaysNoPass` message is gone (`docs/whats-new.md`, Aug 5 entry;
  `docs/tasking-guide.md:251`). The eight conditions that used to be the Send gate are unchanged and
  are now the **pre-submit gate**, cleared before pressing Submit, because a failing submission
  bounces back automatically and spends a round with nobody reading it.
- **2026-08-12, the Reviewer Rubric tab was announced**, for a tab whose own header reads "Last
  updated: August 7, 2026" (`docs/whats-new.md`, Aug 12 entry; `docs/reviewer-rubric.md:7`). It is
  the documented bar for both sides: one confirmed Major Pillar violation is Needs Revision, five or
  more Minor violations of the Secondary Requirements is Needs Revision, and one to four Minors is
  an Accept owing coaching comments. It also reversed one workspace conclusion, the verifier against
  config timeout mismatch, which is LEDGER **L73**.
- **2026-08-14, difficulty checks were capped at four, and a task that has spent all four without
  passing is classified Invalid Difficulty by the platform** (`docs/whats-new.md`, Aug 14 entry;
  `docs/faq.md`, "Difficulty checks are now capped"). It is the one announcement in this log that
  changes what the section above tells you to do, so the ladder carries it in full under "What the
  ladder costs now that difficulty checks are capped" rather than here.
  A claim it superseded, that a repeated `FAIL EASY` does not terminate, is LEDGER **L99**.

---

## How to add an entry here

Same shape as the rest of `learning/`, plus one extra field. Say **where it came from and
when** in the entry itself, not only in the frontmatter, and mark it explicitly when the date is
unknown. If an entry later gets reproduced on this machine, move it into a proper note and leave
a one-line pointer behind. This file is a holding area for second-hand operational rules and it
should stay small.
