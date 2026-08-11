---
id: stated-caveats-decay
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260807_080545__tair-opensource_redisshake__1005
  - 20260727_135618__AltBeacon_android-beacon-library__1177
evidence: "A caveat stated plainly in round 2 became a footnote in round 3 and its own opposite in round 4, with no evidence in between. The platform artifact then refuted the round-4 position"
applies_to:
  languages: [any]
  runners: [any]
  phases: [all]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts: []
---

# A caveat you stop repeating turns into its opposite

Not a platform behaviour. A reasoning failure this workspace has now made twice, with a
mechanical fix, kept in `learning/` because it cost more than most of the platform facts here.

## The instance, in three quotes from one `task.md`

redisshake 1005 ran a local control every round: hand `instruction.md` to independent
implementers with no sight of the tests, and count how many pass. Four rounds, four levers, every
control 4 of 4.

**Round 2, stated correctly:**

> the control runs on a newer model than the screen, so 4 of 4 is a ceiling not a forecast

**Round 3, demoted to a closing hedge:**

> The one caveat that keeps me from calling it settled is that my four engineers run on a newer
> model than the two the difficulty check uses

**Round 4, inverted:**

> **Two independent measurement systems now agree.** The platform screen has said easy four
> times and this workspace's own control has said easy four times. The earlier hedge ... no
> longer buys anything.

Nothing happened between round 2 and round 4 to retire the caveat. No model was checked, no run
was compared. It simply stopped being repeated, and the absence of the sentence was then read as
the absence of the doubt.

**The platform refuted the round-4 position directly.** The difficulty artifact shows gpt-5.5
losing seven graded assertions to a trap that Opus 5 found in 16 of 16 local implementations. The
two systems were measuring different things the whole time, exactly as round 2 had said.

## Why it is hard to see from the inside

A caveat has no owner. A finding gets a file:line and a probe; a caveat gets a clause at the end
of a paragraph. Each round rewrites the paragraph, the clause gets shorter because it was in the
last one too, and the shortening reads as consolidation rather than loss. By the time it is gone,
the position it was qualifying has been restated so often that it looks measured.

The second instance in this workspace has the same shape. AltBeacon 1177 read an `Oracle 0/3` as
an infra signature and carried "unmeasured for 3 rounds" as a note that grew quieter each round
while the conclusion built on it grew louder.

## The rule

**A caveat is retired by evidence, and the retirement is written down with the evidence.** Three
mechanics that make that enforceable:

1. **Give the caveat a home, not a clause.** It goes in the `task.md` round block as its own
   line under a fixed heading, so the next round has to look at it rather than inherit it.
   Suggested shape:

   ```
   ## Open caveats
   | Caveat | Stated in round | What would retire it | Retired? |
   |---|---|---|---|
   | control model is newer than the graded models, so n of n is a ceiling | 2 | a control run on the graded models, or an artifact showing a graded model failing | NO, still open at round 4 |
   ```

2. **A number that a caveat qualifies never travels without it.** Write "4 of 4 against Opus 5"
   rather than "4 of 4". The qualifier being part of the value is what stops the value being
   quoted bare three rounds later. Same discipline as `difficulty-screen-unit-table.md` asking
   which shape a difficulty number came from.

3. **Grep the round for the strengthening.** Before shipping a round's answers, search for the
   phrases that mark a caveat having been argued away rather than measured away:

   ```bash
   grep -niE 'no longer buys|now agree|is settled|beyond doubt|conclusively|the earlier hedge|nothing left to' \
     tasks/<name>/task.md tasks/<name>/answers/submission_answer.txt
   ```

   Every hit needs a measurement on the same line or the sentence comes out.

## The wider form

Any qualifier that limits what a measurement means is load-bearing until something retires it,
and this workspace has several in flight at any time:

- a local reproduction proves sufficiency, never necessity (`diagnosing-platform-only-failures.md`)
- a discriminate matrix built from implementations you wrote to be wrong is a ceiling (LEDGER L49)
- a single step of the difficulty screen is inside the noise at 4 trials per model (LEDGER L43)
- an acceptance validates what previously failed and was changed, and nothing else
  (`accepted-bundle-reference.md`)

Every one of those is a sentence that gets shorter each time it is written. When it disappears,
the claim it was holding up has not become stronger.
