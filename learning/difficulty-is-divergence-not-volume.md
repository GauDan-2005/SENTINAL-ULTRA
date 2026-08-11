---
id: difficulty-is-divergence-not-volume
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260805_080500__statrs-dev_statrs__315
evidence: "Two difficulty screens returned FAIL EASY with byte-identical numbers (opus 100% 4/4, codex 75% 3/4, aggregate 7/8) across a round that added a whole extra statistical test adapted from a related later PR. The added feature converted zero agents: it appears 14 to 33 times per trajectory and all 8 trials implemented it correctly. The only assertion that ever failed an agent, on either screen, was one place where the library deliberately contradicts the textbook transform"
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty, quality, instruction]
blocks_submission: false
fails_gate: [difficulty]
supersedes: []
contradicts:
  - ".claude/rules/04-verdict-criteria.md Fixable trigger 8, read as 'more PR scope means more difficulty'"
  - "docs/faq.md, 'A task came back too easy - can I adapt a change from a related PR', read as a remedy rather than as a permission"
---

# Difficulty scaled with contradicted expectations, not with how much there was to build

## The belief this measures

`Difficulty: FAIL EASY` reads like a size complaint, and both the rule file and the FAQ answer it with
scope. Trigger 8 says raise difficulty by expanding PR scope; `docs/faq.md` says material for that
expansion may be adapted from a related later PR. Neither sentence promises that added scope raises
difficulty, but that is how they get read, and it is how statrs 315 read them for a round.

statrs 315 tested it properly, because the screen ran twice with the expansion sitting between the two
runs.

## The measurement

| Screen | Bundle | opus | codex | Aggregate | Verdict |
|---|---|---|---|---|---|
| round 3 | zip 6, five statistical tests | 100%, 4/4 | 75%, 3/4 | 7 of 8 | FAIL EASY |
| round 4 | zip 7, **six** statistical tests | 100%, 4/4 | 75%, 3/4 | 7 of 8 | FAIL EASY |

The numbers are byte identical, which is exactly the shape of a re-pasted report, so freshness was
checked rather than assumed. The round-4 results artifact names
`anderson_darling_matches_the_reference_statistic` and `anderson_darling_error_cases` among its 127
required tests and carries none of the three ids round 3 merged away. It ran the round-3 bundle. The
identical numbers are real.

What sat between those two screens was not a small addition. Round 3 adapted a whole further
statistical test, Anderson-Darling, from statrs **PR 346**, a related later PR in the same module and
feature family, joined to the task's own `NaNPolicy` and error conventions rather than lifted. It was
measured before it shipped exactly as `difficulty-levers-must-discriminate.md` requires, against four
wrong implementations of the statistic:

| implementation | A squared | separates |
|---|---|---|
| correct | 0.162246714297 | - |
| no index reversal in the second term | 11.864083635259 | yes |
| both terms reversed | 22.761831919637 | yes |
| weight `2i` instead of `2i-1` | 2.117416657378 | yes |
| returns the adjusted statistic | 0.174922238852 | yes |

All four separate. The lever passed the discrimination control and **still converted zero agents.**
Anderson-Darling appears 14 to 33 times per trajectory in the round-4 artifact and all 8 trials
implemented it correctly. The control was not wrong about the implementations it tested. It was
measuring the wrong population, which is the L35 point: a local control is a ceiling, never a forecast.

## The one thing that ever failed an agent

Across both screens, one assertion, in one trial:

```
thread 'skewtest_scipy_example' panicked at tests/stats_tests_pr315.rs:287:5:
assertion failed: z_sym != 0.0
```

A sample with exactly zero skew must not return a zero score. The failing agent had written the
textbook D'Agostino transform, correctly: on symmetric data `skew = 0`, `y = 0`, and the statistic
collapses to `delta * ln(1) = 0`. It failed because the library deliberately does something else and
special-cases that input.

**It was punished for being right about the mathematics and wrong about this library.** That is the
entire difficulty signal the task ever produced, on either run, from either model.

## The theory that replaces it

Difficulty on this task did not scale with how much there was to implement. Eight of eight trials
implemented six statistical tests correctly from a complete specification. It scaled with **how many
documented behaviours contradict the implementation a competent engineer would naturally write.**

One such behaviour converted roughly one agent in eight. Round 4 therefore stopped adding surface and
swept the oracle for every remaining divergence, grading three of them, each measured against the
natural implementation it fails:

| Graded divergence | What the oracle does | What a natural implementation does |
|---|---|---|
| one group constant, others vary | `SampleContainsSameConstants` | computes a valid F, as scipy does |
| a size-1 group beside a bigger one | accepted | rejects, requiring every group to hold two |
| `Exact` forced above the dispatch threshold | works, no size limit of its own | refuses, reading the threshold as global |

Each was checked by writing the implementation it is supposed to fail and watching it fail, with the
zero-skew case included as a control because codex trial 4 had already written it:

| natural implementation | result |
|---|---|
| f_oneway errors only when EVERY group is constant | reward **0** |
| f_oneway requires every group to hold at least two | reward **0** |
| mannwhitneyu `Exact` refuses samples over eight | reward **0** |
| skewtest without the zero-skew guard, which is literally codex trial 4 | reward **0** |

Two further divergences were found and deliberately left ungraded: an all-tied sample returning `p = 1.0`
through an infinite z, and `ttest_onesample` panicking on zero variance inside `function/beta.rs:125`.
A panic is not a sensible assertion, and fixing it would change PR behaviour past what
`docs/guidelines.md:286` case 1 authorises. Reported in Comments for Reviewer, not fixed.

## The second finding, which is subtler and costs more

Rounds 0 to 2 each answered a judge finding by making the instruction more complete, and each answer
was individually correct:

| Round | Finding | What was added to `instruction.md` |
|---|---|---|
| 1 | clarity 4.0, `SampleTooSmall` vs `SampleContainsSameConstants` ordering only implicit | the full error precedence for three functions |
| 1 | self_containedness 3.0 from gpt, "roughly nine decimal places" is not a checkable contract | an absolute 1e-9 tolerance contract |
| 1 | oracle_spec_faithfulness, two undocumented departures from scipy | both departures named outright |
| 1 | oracle_spec_faithfulness, the `Automatic` dispatch sentence misstated the oracle | the corrected dispatch threshold |
| 2 | reviewer, coverage still incomplete | the `Emit` ordering |

The cumulative effect was a near-complete specification of standard algorithms, and frontier models
transcribe those. **Answering clarity and self-containedness findings costs difficulty, and nothing in
the loop measures that until the screen runs.** The judge scores clarity, the Quality Check blocks on
instruction criteria, the prescriptiveness check pushes the same way, and not one of them can see what
the trade is costing.

The same lesson arrived from the other direction one round earlier, and the before-and-after is on the
record:

| zip | difficulty screen |
|---|---|
| 2, round 1 | **passed**, every check green, reached a peer reviewer |
| 4, round 2 | **FAIL EASY** |

Round 2 corrected a genuine inverted-tail bug in the exact Mann-Whitney p-value, under
`docs/guidelines.md:286` case 1, still present on statrs master today. Round 1's thresholds had been
tuned to that bug, so an agent implementing Mann-Whitney correctly had been **failing**. The bug was
doing the discriminating. Fixing it was right and it deleted the discriminator.

So a divergence is worth difficulty whether it is deliberate or accidental, and removing an accidental
one is still removing a lever. Fix the bug. Then budget a replacement lever in the same round rather
than discovering the hole two screens later.

## What is not known

**Whether round 4's three divergence levers moved the screen is unknown.** The acceptance arrived on
2026-08-11, after round 4, and this workspace never saw a round-4 screen result. Two readings fit
everything visible: the levers worked, or the task was accepted with the screen still red. Nothing here
distinguishes them and this note is not evidence for the first.

What is established is only what was measured directly:

- The round-3 expansion converted zero agents, from two screens and the trajectories in the artifact.
- The only assertion that ever failed an agent was the zero-skew one, twice out of two.
- Each of round 4's three levers fails the natural implementation it names, locally, at reward 0.

The conversion rate of one divergence, roughly 1 agent in 8, is a single observation. Per L43 the screen
runs 4 trials per model, so one flipped run is inside the noise and two points are not a trend. Do not
plan a round around "three divergences will convert three agents".

## The method

The sweep that produced round 4, generalised. It costs one container run.

1. **List every public entry point the task grades**, and for each one enumerate its degenerate and
   boundary inputs. The productive families on statrs 315 were: one element of a collection constant
   while the others vary, a minimum-size member beside a larger one, a mode forced exactly at a
   dispatch threshold, all values identical, zero variance, empty, and the NaN policies.
2. **Write down what the natural implementation returns for each, independently and first.** Read the
   reference the instruction names (scipy, the standard definition, the language's own stdlib), not the
   oracle. Deriving the expectation from the oracle is the trap in `oracle-bug-vs-pr-scope.md`: a
   prediction taken from the oracle can never disagree with it.
3. **Run the oracle in its own image and print the actual result per row.** Static reading is not
   enough (`verify-in-the-image.md`).
4. **Every row where the two differ is a candidate lever.** Rows where they agree are worth nothing,
   however much code sits behind them.
5. **Discard the candidates you cannot grade fairly.** A panic is not an assertion. A divergence on an
   input the instruction never mentions is overreach and needs the instruction changed first, which is
   a cost, not a free lever.
6. **For each survivor, write the natural implementation and run the graded suite against it.** Require
   reward 0 and record which test id caught it. A candidate that does not fail anything is not a lever
   (`difficulty-levers-must-discriminate.md`).
7. **State the divergence in `instruction.md` in the same round**, in the smallest wording that makes
   the graded behaviour unambiguous. Grading an undocumented divergence is a `test_faithfulness`
   failure, and the whole point is that it is documented and still contradicts instinct.
8. **Fold the assertions into existing ids.** statrs 315 held `fail_to_pass` at 18 against the cap of 20
   while assertions went from 111 to 132.

## Checklist before spending a round on a FAIL EASY

- [ ] Read the failing trial in the artifact, not the headline. Which single assertion failed, and what
      had the agent actually written? On this task that one stack trace named the lever shape that two
      rounds of reasoning had not.
- [ ] Count how often the thing you are about to add already appears in the passing trajectories. If
      the agents are doing that kind of work fluently, more of it converts nobody.
- [ ] Before adding surface, run the divergence sweep above. A place where the library contradicts the
      textbook is worth more than a whole extra feature.
- [ ] Before adding surface, run the clause pass from `probe-the-instruction-you-already-wrote.md`. An
      ungraded clause you already shipped is cheaper than anything new.
- [ ] Check what recent rounds added to `instruction.md` to answer clarity or self-containedness
      findings. If the instruction now specifies a standard algorithm end to end, that is where the
      difficulty went.
- [ ] If this round removes a divergence, whether it is an oracle bug being fixed or an ambiguity being
      resolved, name the lever that replaces it in the same round.
- [ ] Measure each lever against the natural implementation it is supposed to fail, and record the test
      id that caught it. State which model wrote the control implementations, because a control is a
      ceiling and not a forecast (L35).
- [ ] Keep `fail_to_pass` off the boundary by folding into existing ids, and never touch the `task.toml`
      difficulty or pass-rate fields to answer a difficulty result.

See also [[difficulty-levers-must-discriminate]], [[probe-the-instruction-you-already-wrote]],
[[related-pr-carries-its-own-bug]], [[oracle-bug-vs-pr-scope]], [[difficulty-screen-unit-table]],
[[raising-difficulty-on-a-wrapper-task]], [[quality-check-criteria]].