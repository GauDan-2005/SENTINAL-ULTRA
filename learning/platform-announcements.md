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
of it is in the eight Hub tabs under `docs/`. That makes this file **subordinate to `docs/` on
policy and subordinate to the run-backed notes in this folder on observed behaviour.** When it
disagrees with either, they win and the entry here gets corrected or deleted.

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

## How to add an entry here

Same shape as the rest of `learning/`, plus one extra field. Say **where it came from and
when** in the entry itself, not only in the frontmatter, and mark it explicitly when the date is
unknown. If an entry later gets reproduced on this machine, move it into a proper note and leave
a one-line pointer behind. This file is a holding area for second-hand operational rules and it
should stay small.
