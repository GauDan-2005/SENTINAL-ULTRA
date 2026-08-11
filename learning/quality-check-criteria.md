---
id: quality-check-criteria
status: platform-confirmed
last_verified: 2026-08-04
verified_by:
  - 20260728_153118__jqno_equalsverifier__1166
  - 20260723_030109__cryspen_libcrux__1165
evidence: "Quality Check feedback text quoted verbatim across three rounds"
applies_to:
  languages: [any]
  runners: [any]
  phases: [quality-check, fixing]
blocks_submission: true
fails_gate: [quality-check]
supersedes:
  - "its own round-1 rule 3, which said placement relative to a class existing at base is safe — see 'Q9 rejects the replacement too'"
contradicts:
  - "docs/tasking-guide.md — describes 10 scored axes; the check returns 15 must-have criteria and instruction criteria block on their own"
---

# The Quality Check runs 15 must-have criteria, and instruction criteria block

Source: platform evaluation of `20260728_153118__jqno_equalsverifier__1166`, 2026-08-02.
Verified against the real feedback text, not inferred.

## What it actually returns

```
❌ 2 must-have quality criteria failed (13/15 criteria pass).
  • [Q9] The instruction gives explicit navigation hand-holding, e.g. 'Where to look: <files>' or 'start by modifying <method>'.
      criterion: Instructions
      judge: The instruction explicitly places implementation artifacts in named packages: 'In nl.jqno.equalsverifier.internal.instantiation: AbstractValueProvider...' ...
  • [Q10] The instruction leaks hidden test information, e.g. specific status codes, assertions, or internal test logic.
      criterion: Instructions
      judge: The instruction specifies exact error message strings: ... These are the precise strings that the tests assert ...
```

Numbered criteria `Q1`..`Q15`, each tagged with a `criterion:` group, each either a must-have
or not, plus a per-finding `judge:` justification quoting the offending text.

## Why this matters more than the format change

`docs/tasking-guide.md` describes something different: two judges, four rubrics, **10 axes**
scored 1 to 5, an adjudicator on 2-point disagreements, and REMOVE / DISCUSS / OK. It states
plainly that only `test_coverage` and `test_faithfulness` flip the verdict, and that the eight
other axes "are scored and shown in the report ... but they don't flip the verdict on their
own." `CLAUDE.md` section 4 repeats that.

**Both failing criteria here were `criterion: Instructions`, and both were must-have.** The
task's test axes were fine. It failed on instruction quality alone.

Nothing in `docs/`, `CLAUDE.md` or the rest of `learning/` mentions `must-have`, a 15-criteria
report or `[Q<n>]` ids. Checked with a grep across all three.

## What it invalidates

The strategy this workspace had been running on refactor tasks, written up in
[prescriptiveness-check.md](prescriptiveness-check.md), was:

> Stop when the only remaining findings are names the graded tests call. Both `test_faithfulness`
> and the `fail_to_pass` floor block, this one does not.

That reasoning was about the **prescriptiveness build-phase check**, which really is
non-blocking and says so in its own output. It does not transfer to the Quality Check. Over-
prescription and leakage in `instruction.md` now have a blocking path, through Q9 and Q10.

On the equalsverifier task that stance had shaped three earlier rounds and was written into
Comments for Reviewer as "expect it to still report findings, it is advisory". That sentence
was wrong about the check that actually blocked.

## Two different checkers, easy to confuse

| | Prescriptiveness check | Quality Check |
|---|---|---|
| Runs at | CodeBuild BUILD phase, on upload | after the bundle runs |
| Output | `score=0.42, 6 finding(s) (2 high, 3 medium)` with `P1`..`Pn` | `13/15 criteria pass` with `Q1`..`Q15` |
| Blocks? | **No.** Says so in its own message | **Yes**, on must-have criteria |
| Overlap | both read `instruction.md` and object to the same kinds of text | |

They flag overlapping text and disagree about how far to go. On this task the Quality Check Q9
objected to literal package paths, those were replaced with placement relative to a class that
exists at base, and the next prescriptiveness run flagged **the replacement** as P4. Fixing for
the blocking one is correct. Do not chase both to zero.

### The conflict also runs the other way, over whether a requirement may be stated at all

Source: `20260727_135618__AltBeacon_android-beacon-library__1177`, 2026-08-02. The sharper case,
because here the two checks want opposite things about the *same sentence*.

The rubric panel failed that task at `test_coverage` 2.5. Its driving rationale, verbatim:

> The prompt also says a change made to an active-settings snapshot must not reach live
> configuration [instruction.md:7], while the snapshot test only checks that later live changes
> do not alter an earlier snapshot.

So it failed the task **for not testing a requirement the instruction states**. The fix was to
add the missing direction to the test. The very next prescriptiveness run then flagged the
instruction sentence itself:

```
[low] P2: Rule 5 — pre-answers a concurrency/isolation edge case that the agent should reason
about independently.
  evidence: "a later change to the live configuration must not show up in a snapshot already
  handed out, and a change made to a snapshot must not reach the live configuration"
  suggestion: Express this as a high-level correctness property — e.g., "snapshots must be
  independent of the live configuration" — rather than spelling out both directions.
```

Taking P2 literally would delete the sentence that made the blocking coverage fix defensible.
A requirement the instruction does not state is a requirement the tests must not assert, which
is the `test_faithfulness` overreach rule. Cutting it does not remove the problem, it moves it
to the axis that blocks.

**Rule: when a prescriptiveness finding quotes a requirement that a graded test asserts, the
finding is asking you to break `test_faithfulness`. Refuse it and say so in Comments for
Reviewer.** The safe middle, when one exists, is the judge's own suggested phrasing if it still
carries the requirement. Here "snapshots must be independent of the live configuration" does
still support a both-directions test, so P2 has a real fix. P1 and P3 on that same report quoted
`Settings.Builder` and `Settings.Defaults`, which the graded tests call by name 4 and 15 times,
and those have no such middle. Refuse and document.

## An oracle axis can REMOVE a task on its own, with both test axes clear

Source: `20260727_135618__AltBeacon_android-beacon-library__1177`, rubric panel 2026-08-03,
second round on the same bundle.

`docs/tasking-guide.md` and `CLAUDE.md` section 4 both state the verdict logic in terms of the two
test axes only: REMOVE needs an adjudicated `test_coverage` or `test_faithfulness` at or below
2.0, DISCUSS at or below 3.0, and the other eight axes "don't flip the verdict on their own".
This report does not fit that:

```
Status: ❌ REMOVE
Reason: oracle_spec_gap
```

| Axis | Round 1 | Round 2 |
|---|---|---|
| test_coverage | 2.5 | **3.5** |
| test_faithfulness | 4.0 | **3.5** |
| oracle_spec_faithfulness | 3.5 | **2.0** |
| clarity | 3.5 | 4.0 |
| verdict | DISCUSS | **REMOVE** |

Both test axes are above the DISCUSS line. Round 1's fixes did exactly what they were aimed at,
`test_coverage` went 2.5 to 3.5 and clarity 3.5 to 4.0, and the verdict got **worse** because
`oracle_spec_faithfulness` collapsed to 2.0. The `Reason:` field names the axis directly, so this
is not an adjudication artefact — the panel is reporting an oracle axis as the deciding one.

**Rule: read `Reason:` first and treat whichever axis it names as blocking, whatever the
documented verdict logic says about test axes.** Do not skim the oracle and instruction axes as
advisory because the two test axes came back clean. The practical shape of an
`oracle_spec_gap`: the instruction promises behaviour the golden patch does not implement. There
are only two honest fixes, extend the oracle or narrow the instruction, and
[source-pr-cross-check.md](source-pr-cross-check.md) decides which — if the gap is inherited from
the upstream PR the instruction is what is over-promising, and if the PR left it on a TODO that
the instruction then promised, completing the TODO is an allowed additive oracle edit.

**Narrowing an instruction to fit a partial oracle usually needs a second attempt.** Round 1 here
narrowed "every field it applied has to be observable" to "settings the library already models on
its existing static configuration are pushed through to it as well". The unapplied fields
`useTrackingCache` and `maxTrackingAgeMillis` *do* have existing static setters, so the narrowed
sentence still promised exactly what the oracle skipped, and the axis fell rather than rose.
Before shipping a narrowing, take the new sentence and the list of unapplied fields and check
each one against it by hand.

## The rule

1. Treat leakage and navigation in `instruction.md` as **blocking** until proven otherwise.
   Budget for it during the first pass rather than deferring it as advisory.
2. Q10 is specifically "the precise strings that the tests assert". Before writing any literal
   into an instruction, ask whether a test asserts it. If yes, that is the leak. Relax the
   assertion to something derivable and drop the literal, rather than keeping both.
3. Q9 is navigation, and it rejects placement in **any** form, including placement stated
   relative to a class that already exists at the base commit. Saying nothing at all about where
   things live is the only thing that clears it. See "Q9 rejects the replacement too" below.
4. Read the `judge:` text. It quotes the exact sentence, which makes the fix targetable in a way
   the prescriptiveness score never is.

## Q9 rejects the replacement too

Source: `20260728_153118__jqno_equalsverifier__1166`, revision round 2, 2026-08-02. **This
corrects rule 3 above**, which was written after round 1 and claimed the opposite.

Round 1 replaced `In nl.jqno.equalsverifier.internal.instantiation: AbstractValueProvider...`
with `It belongs with the other ValueProvider implementations, alongside ObjectValueProvider`,
on the theory that naming a type which already exists at base is derivable rather than
navigational. The next Quality Check failed Q9 again and quoted the replacement:

> judge: The instruction explicitly tells the implementer where to place new classes: 'It
> belongs with the other ValueProvider implementations, alongside ObjectValueProvider' ... and
> 'SubtypeManager owns subtype resolution...and sits alongside Instantiator' ... These are
> direct navigation hints to specific file locations.

Both clauses were then deleted and the instruction now says nothing about placement.

**Rule: there is no safe phrasing for placement under Q9. Delete it and let the tests' imports
rest on repo convention.** Measure how strong that convention actually is first, because the
cost lands on a correct agent that picks a different package and fails to compile. On
equalsverifier all 12 `implements ValueProvider` classes at base sit in one package, so
`AbstractValueProvider` is well determined. `SubtypeManager` has no equivalent, and that
asymmetry belongs in Comments for Reviewer rather than being glossed as one convention.

The alternative, restructuring the graded set onto classes that already exist at base, took
`fail_to_pass` from 19 to 9 there, under the static-check floor of 10. That trades one blocking
criterion for another.

## Clearing Q10 by relaxing assertions opens a coverage_gap two rounds later

Source: `20260728_153118__jqno_equalsverifier__1166`, round 1 fix, round 3 consequence, 2026-08-04.
The sharpest instance of the two-checkers conflict so far, because the same person caused both
halves and two rounds passed in between.

Round 1 failed Q10 for quoting four exact error strings the tests asserted. The fix followed rule
2 above: drop the literals from the instruction **and** relax the assertions. The relaxed pair
became `assertMessageContains(<type>, "sealed")` plus an `assertMessageDoesNotContain` on the old
wording. Rounds 1 and 2 passed on leakage. Round 3 then returned `DISCUSS`, `Reason: coverage_gap`:

> a core message requirement from [instruction.md:9] is only partially checked ... they never
> assert that it explains "no usable non-recursive subclass was found" or uses the library's
> no-value phrasing, so an underspecified error message would pass.

Measured both ways by weakening the oracle's message to just `": it is sealed."`:

| Assertions | Reward |
|---|---|
| after the Q10 fix | **1.0** — the gap was real and reachable |
| after the coverage fix | **0.0**, both sealed ids failing |

**The instruction still stated all four clauses the whole time.** Only the assertions shrank. So
this is not the instruction over-promising (`source-pr-cross-check.md`), it is the tests
under-checking a requirement that never moved.

### The rule

Rule 2 says relax the assertion and drop the literal. It is right, and it is only half an
instruction. **Relax to the requirement, not below it.** After removing a literal, re-read the
instruction sentence it came from, list every clause in it, and check each clause still has an
assertion. Here line 9 carried four (names the type, says sealed, says no usable non-recursive
subclass, drops the old wording) and the relaxed pair covered two.

What to relax *to*, and why it does not re-leak:

- **Content words the instruction states in prose are safe.** The test already asserted `sealed`
  from that sentence and Q10 never flagged it across two rounds, so asserting `non-recursive` and
  `subclass` from the same sentence is the same construction.
- **A literal the instruction does not contain but the repo does is also safe**, and is the right
  home for "uses the library's existing phrasing". `prefab values` appears 0 times in the
  instruction and verbatim in `ValueProvider.java`, so the agent derives it from the code it has.
- **What Q10 actually objected to was whole quoted message sentences** presented as the text to
  emit. Prose requirements are not that.

Check it mechanically before shipping: for each fragment the tests assert, `grep -c` it in
`instruction.md`. A count above zero is fine when the fragment is a content word inside a stated
requirement, and a red flag when it is a quoted message string.

## Criteria observed elsewhere, not yet seen in our own reports

A report only prints the criteria that **failed**, so `13/15 criteria pass` tells you nothing
about what the other 13 are. What follows is second-hand: criterion numbers reported by other
ECs and by a sibling workspace, with no report in this workspace confirming the number, the
wording or whether the criterion is must-have.

**Every row here is unverified.** Treat a row as a thing worth checking your bundle against, not
as a criterion you know exists. If a real report ever prints one of these numbers, replace the
row with the quoted text and move it into the verified section above.

| Criterion | Reported wording | Group | Must-have? | Source | Status |
|---|---|---|---|---|---|
| Q13 | `solve.sh` mutates tracked files outside `golden.patch`, e.g. deleting or renaming paths directly in the script | Oracle | unknown | sibling workspace, relayed | **unverified** |
| Q15 | Dockerfile dependencies are unpinned, so the image is not reproducible | Environment | unknown | sibling workspace, relayed | **unverified** |
| Q9 | Instruction gives explicit navigation hand-holding | Instructions | **yes** | our own report, 2026-08-02 | verified, see above |
| Q10 | Instruction leaks hidden test information | Instructions | **yes** | our own report, 2026-08-02 | verified, see above |

Q13 is worth acting on whether or not the criterion is real, because the underlying rule stands
on its own: **`solve.sh` applies `golden.patch` and does nothing else.** Every delete, rename and
edit of a tracked path belongs inside the patch. A script that `rm`s a file directly passes every
check this workspace runs, and it means the golden patch is not the solution, which breaks the
one thing a reviewer can check by reading.

Q15 overlaps the reproducibility requirement in `docs/tasking-guide.md`, so pinning the base
image to a concrete tag and baking test dependencies into the image covers it either way.

Still genuinely unknown: what the remaining criteria are, how many of the 15 are must-have, and
whether any group other than `Instructions` blocks on its own. Paste a fuller report in here the
first time one appears.

## A judge's mechanical claim can simply be wrong. Measure it

Source: `20260723_030109__cryspen_libcrux__1165`, rubric panel 2026-08-03.

The panel returned DISCUSS with `reason: oracle_spec_gap`, driven by two claims in one paragraph.
One was right and one was false, and they needed opposite responses.

**Right:** "the required public `PQCPError` is placed in a `pub(crate)` root module". Confirmed by
compiling a test against it, `error[E0603]: module 'pqcp' is private`. Real oracle-to-instruction
gap, fixed by re-exporting.

**False:** "the unpacked macro re-exports constants via `super::super::pqcp`, which from
`portable::unpacked::pqcp` points at a non-existent `portable::pqcp` module ... so the required
struct API is materially broken". The parent module has a `use super::*;` glob, and a private
import is visible to that module's **descendants**, so the path resolves to the variant-level
module. Measured through the exact path the judge named:

```
packed PK_LEN=1184 struct-module PK_LEN=1184
```

Acting on it would have meant rewriting working PR code to satisfy a misreading.

**Rule: split a judge's rationale into individual claims and reproduce each one before touching
anything.** A claim about resolution, linkage, visibility or types is a two-minute check in the
task image. Fix the ones that reproduce.

**Correction, 2026-08-05: refuting the others in Comments for Reviewer does not clear them.** That
is what this note used to advise and it cost libcrux 1165 two further rounds. The panel reads the
instruction, the tests, the oracle and the task directory. Comments for Reviewer is a form field
and is not one of them, so the refutation is invisible to the judge and the finding returns. It
returned three times here and went from DISCUSS to REMOVE. When a false claim blocks and the code
can be changed so the misreading is impossible without changing behaviour, change the code and
prove the equivalence. See `LEDGER.md` L18. The judges disagreed here too, 5/5 against 2/5 on
the same axis, which is itself a signal to go and measure.

## Making an instruction truthful creates coverage debt

Measured 2026-08-06 on `20260727_135618__AltBeacon_android-beacon-library__1177` round 7, whose
`coverage_gap` named exactly two requirements: long scan forcing being consulted by the scanning
code, and no default distance calculator for a caller who never applies settings.

**Both were sentences earlier rounds had added**, to stop the instruction claiming things PR 1177
does not do. Round 5 added the first, round 6 the second. Neither round added a matching assertion.

That is a loop with a name now. An `oracle_spec_gap` is fixed by narrowing the instruction to what
the patch really does. Every such narrowing that *states a new behaviour* is a new requirement, and
the coverage axis grades stated requirements. So the next report comes back `coverage_gap` on the
sentence you just wrote to fix the last one.

**Rule: when a narrowing adds a sentence describing behaviour, add the assertion in the same round,
or do not state the behaviour at all.** The second option is legitimate - Section 9 says an oracle
may implement more than the instruction requires - and it is the right call when the behaviour has
no observable a test can reach. Decide which by looking for the observable *before* writing the
sentence, not after the next report.

The cheap check, run over any instruction sentence you add during a narrowing: name the assertion
that would fail if the behaviour were removed. If you cannot, the sentence is coverage debt.

## When a stated requirement has no public observable

Same round. The judge asked for long scan forcing to be *consulted* by the scanning code and not
merely stored. There is no public reader for the consumed state anywhere in that library:
`ScanHelper.getCycledScanner()` is package-private and `CycledLeScanner.mLongScanForcingEnabled` is
private with a setter and no getter. The obvious readings are "narrow the requirement away" or "add a
getter to the oracle". Both are worse than the third option.

**Reflective assertion over base-commit names is defensible, under four conditions.** All four held
here and all four are worth checking before reaching for it:

1. **The drive path is already proven.** `BeaconServiceTest::beaconScanCallbackTest` was already in
   `pass_to_pass`, so building the service and calling `onCreate()` was known green in that image.
2. **Every reflected name exists at the base commit and the golden patch never touches it.** The test
   then constrains the wiring an implementer adds, not a name they must invent. That is what keeps it
   off the `overreach` axis.
3. **It reads runtime state, not source text.** `getDeclaredField` is not `inspect.getsource`, so the
   no-source-shape-grading gate still passes on its own terms rather than by luck.
4. **A negative control rules out the unconditional cheat.** This is the one that is easy to miss.
   The first version asserted only that the flag was ON after applying the setting, which an
   implementation that switched it on always would also pass. The fix is to assert it is OFF before
   anything asks for it, in the same test. Proved by a probe that replaces the consult with an
   unconditional switch-on: without the control it passes, with it the reward drops to 0.

Add a fifth in practice: **say you did it in Comments for Reviewer.** A reflective test that a
reviewer finds for themselves reads as sleight of hand; one you declare reads as the only available
way to grade a real requirement.

