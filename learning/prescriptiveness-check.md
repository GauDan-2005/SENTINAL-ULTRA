# The prescriptiveness check

Sources: real CodeBuild logs from three tasks.

- 2026-07-31, `20260719_045042__oliver-oloughlin_kvdex__245`, score 0.25, 4 findings.
  A TypeScript migration. Covered in "What it flagged" below.
- 2026-08-01, `20260728_153118__jqno_equalsverifier__1166`, score 0.10, 6 findings
  (5 high). A Java refactor. Covered in "When the whole instruction is the problem".
- 2026-08-01, `20260727_135618__AltBeacon_android-beacon-library__1177`, 0.38 then 0.45
  then **passed**. A Kotlin/Java public API feature. Covered in "It can pass" immediately
  below, which is the section to read first.

Read all of it. The equalsverifier half is the pathological case and its conclusions do not
generalise, which took a third task to find out.

## It can pass

**Verified 2026-08-01 on `20260727_135618__AltBeacon_android-beacon-library__1177`.** Third
upload, check green. Every earlier note in this file was written from tasks where it never
went green, so the tone below is more pessimistic than the evidence now supports.

The route was three uploads:

| Upload | Result |
|---|---|
| 1 | `score=0.38, 5 finding(s) (0 high, 3 medium)` |
| 2 | `score=0.45, 5 finding(s) (0 high, 4 medium)` |
| 3 | passed |

Two things about that table matter more than the numbers.

**The findings rotate.** Round two had almost entirely different findings from round one, on
text that had not changed in those spots. Clearing four does not leave one. It leaves a new
five. Budget three uploads on any task where the first score is above ~0.3, and do not read
a same-size finding list as "no progress".

**It is a score threshold, not a zero-findings bar.** The `Settings.Builder` paragraph was
flagged at medium in *both* failing rounds and was still in the instruction, unchanged, when
the check passed. So stop cutting once the remaining findings are ones the graded tests pin.
Gutting the instruction to chase an empty report is how you break `test_faithfulness`, which
does block.

### What actually moved it

Nine findings taken across two rounds. The ones that generalise:

| Pattern in the instruction | What replaced it |
|---|---|
| Enumerating which internal fields a method writes | the observable post-condition. "Reading any affected property back off `BeaconManager` or `Beacon` gives the value that was just applied" |
| A worked example with a literal (`distanceModelUpdateUrl = "www.google.com"` must return `"www.google.com"`) | nothing. It was a ready-made test assertion. The test supplies its own value now |
| Naming a class the agent must produce or call | the behaviour that has to survive. See the correction below, this is the one I got wrong twice |
| A Java example expression, `Settings.Defaults.INSTANCE.getScanPeriods()` | "readable without instantiating anything". The expression leaked that `Defaults` must be a Kotlin `object` |
| "a Kotlin data class is the intended shape" | "configure only the subset of fields they want in a single expression, with anything unspecified treated as absent" |
| A bare package path for a new interface | placement relative to the type it returns, "in the same package as the `DistanceCalculator` it returns". Keeps the test's import derivable without stating a path |
| "you must not modify the test files under `lib/src/test`" | nothing in the instruction. Moved into `tests/test.sh`, see `tests-patch-vs-agent-edits.md` |
| Internal mechanism ("unbind and rebind the consumers", "knows how to configure the manager") | nothing. No test could reach it |

The through-line: **every fix replaced a HOW with a WHAT, and the test moved with it.** Not
one of them was solved by deleting a sentence on its own.

### The recipe

1. Take every finding whose evidence text is not referenced by a graded test. Free.
2. For each remaining finding, ask whether the test can assert the *behaviour* instead of the
   *name*. Usually it can, and the test gets better for it.
3. Stop when the only findings left quote symbols the graded tests call by name. Write those
   up in Comments for Reviewer so nobody thinks the report was ignored.
4. Expect two or three rounds. Re-run the local oracle and NOP after every pass, because
   every one of these changes touches the tests as well as the instruction.

The exact passing score was not captured from the build log. Worth pasting it in here if the
check ever passes again, to learn where the threshold sits.

### A pass is not sticky, and the threshold is above 0.50

**Verified 2026-08-02 on the same task, one revision round later.** The bundle that passed at
round 3 was edited for an unrelated reason (a Quality Check coverage failure), re-uploaded, and
the check came back red:

```
❌ prescriptiveness: score=0.50, 3 finding(s) (0 high, 1 medium)
```

Two things fall out of that, and both were guesses before.

**The threshold is above 0.50.** Round 3 passed at an unrecorded score, round 4 failed at 0.50.
So the passing score on round 3 was higher than 0.50. That is the first real bound this log has
on where the bar sits. Narrow it further the next time a run passes and the score is visible.

**Any edit to `instruction.md` re-runs the check, and a previously passing instruction can
fail.** The full round history on this task:

| Upload | Score | Findings |
|---|---|---|
| 1 | 0.38 | 5 (0 high, 3 medium) |
| 2 | 0.45 | 5 (0 high, 4 medium) |
| 3 | **passed** | — |
| 4 | 0.50 | 3 (0 high, 1 medium) |

Round 4 has the best score and the mildest report of the four, and it still failed. More
importantly, **all three findings quoted text that had not changed since the round that
passed.** P1 was the `Settings.Builder` paragraph, which the note above already records as
having been flagged in both failing rounds and still present when the check went green. It came
back. The round-4 edits touched two other spots that no finding mentions.

So the rotation described above is not just "clearing four leaves a new five" within a losing
streak. It also runs in the other direction: a green result does not certify the text, it
certifies one sampling of an LLM judge on that text. Do not treat a past pass as a reason to
skip re-reading the report after an unrelated instruction edit, and do not read a fresh red as
evidence that your latest edit broke something. Diff the quoted evidence against what you
actually changed before touching anything.

There is a second CodeBuild phase beyond the structure checks:
`scripts.harbor.checks.cdg_sentinel_ultra.prescriptiveness`. It reads `instruction.md`,
scores it 0 to 1, and lists findings with a severity and an id. On the kvdex run the ids
carried explicit rule numbers ("Rule 3 violated"); on the equalsverifier run they were bare
`P1`..`P6` with free-text categories. Do not rely on the rule numbering being present.

```
❌ prescriptiveness: score=0.25, 4 finding(s) (2 high, 2 medium)
```

It exits 1 and fails the BUILD phase, but the message says plainly:

> This check is optional and does not block submission, but please address the findings
> above before sending the task to review.

So a red build here is not the same as a red static check. It still needs fixing before
review, and each finding arrives with quoted evidence and a concrete suggestion.

## What it flagged on the kvdex run

**Rule 3, naming the library or built-in to use. Both scored high.**

| Evidence quoted from the instruction | Why |
|---|---|
| "v8Serialize and v8Deserialize build on the `node:v8` built-in" | prescribes the exact module, removing the design decision |
| "a `Compressor` backed by the `node:zlib` brotli functions" | same |

The fix is to state the behavioural contract and let the agent pick the module. The
factory names (`v8Encoder`, `brotliCompressor`) already carry enough signal that the agent
reaches for the obvious built-in on its own.

**Rule 2, naming internal file paths or the current home of code. Both scored medium.**

| Evidence quoted | Why |
|---|---|
| "brotliCompressor from `src/ext/encoding/brotli/brotli_compressor.ts`" | an internal implementation filename, not a public export path |
| "The serialization helpers currently exported from `src/utils.ts` move to..." | hands the agent the investigation step of finding the existing code |

## What it did NOT flag on that run

Useful for knowing where the line sits. All of this survived untouched:

- the module tree `src/ext/encoding` and the per-directory `mod.ts` barrels
- required symbol names: `jsonEncoder`, `v8Encoder`, `brotliCompressor`, `jsonSerialize`,
  `KvdexOptions`
- the type shapes `Encoder`, `Serializer`, `Compressor`
- the package export map entries `./encoding`, `./encoding/json`, `./encoding/v8`,
  `./encoding/brotli`

Public API surface is fine. Internal file layout and library choices are not. A barrel is
public surface; the file behind it is an implementation detail.

## The trap: fixing this can break test-name derivability

This is the part worth remembering, because the two checks pull against each other.

The instruction named `src/ext/encoding/brotli/brotli_compressor.ts` for a reason. The test
tree imported `brotliCompressor` from exactly that path. Deleting the line from the
instruction to satisfy prescriptiveness would have left a test demanding a path the agent
could not derive, which is the arbitrary naming problem and a `test_faithfulness` hit on
the Quality Check, which *is* blocking.

**Rule: when you remove a path or a name from the instruction, grep the tests for it
first.** If a test depends on it, change both together. Repoint the test at something the
instruction still states.

Here that meant folding the import into the public barrel that the instruction already
documents:

```ts
// tests/utils.ts, before
import { brotliCompressor } from "../src/ext/encoding/brotli/brotli_compressor.ts";
import { jsonEncoder } from "../src/ext/encoding/mod.ts";

// after
import { brotliCompressor, jsonEncoder } from "../src/ext/encoding/mod.ts";
```

A test in `tests/ext/encoder.test.ts` asserting the symbol was importable from its own
internal file also went, since the barrel assertion right next to it already covers the
public contract.

After any such edit, regenerate `tests.patch`, re-run NOP and oracle, redo git hygiene and
re-zip. Changing the instruction alone is never the whole job.

## When the whole instruction is the problem

The equalsverifier round is the harder case. I applied the fix pattern above (drop the
localisation, the library name, the verifier note) and the judge came back **worse**:

```
❌ prescriptiveness: score=0.10, 6 finding(s) (5 high, 1 medium)
```

It was not objecting to those details. It was objecting to the instruction being a
component-by-component specification at all. The six findings were not Rule 2 or Rule 3
violations, so **do not assume the two rules are the whole checker**. What it flagged:

| Finding | What it objects to |
|---|---|
| P1 | naming the exact new classes, packages and symbols to create |
| P2 | prescribing the design patterns: delegate constructor, static factories replacing a public constructor, final utility class, idempotency guarantee |
| P3 | prescribing exact method signatures, return types and parameter lists |
| P4 | prescribing where the new component slots into an existing chain, naming the chain class and its neighbours |
| P5 | pre-answering edge cases the agent should discover (no-package classes, bootstrap-classloader types, traversal order) |
| P6 | naming the internal callers that must be updated |

Each finding quotes the offending sentence and suggests a rewrite, so read the report
rather than guessing.

## The symbol audit: how to cut safely

Do not guess which sentences to cut. Check every symbol in the instruction against what the
**graded tests** reference, and remove everything with zero references. This will not clear
the check on its own (see below), but it is how you cut without breaking anything:

```bash
for s in SubtypeManager ValueProviderBuilder HierarchyChecker ofExact giveDynamicSubclass ...; do
  printf "  %-40s %s\n" "$s" "$(grep -E '^\+' tests/tests.patch | grep -c "$s")"
done
```

On equalsverifier that split the six findings cleanly:

| Symbol | Test refs | Action |
|---|---|---|
| `SubtypeManager` | 21 | keep |
| `ofAllowSubtype` | 10 | keep |
| `giveDynamicSubclass` | 8 | keep |
| `ValueProviderBuilder` | **0** | cut, and P4 disappears entirely |
| `HierarchyChecker`, `JpaLazyGetterFieldCheck` | **0** | cut, P6 gone |
| `SealedTypesFinder` | **0** | cut |
| "final, non-instantiable", "constructor is private" | **0** | cut, most of P2 gone |

That took the instruction from 9516 to 5222 bytes without touching anything the suite
needs. For P5, keep the *requirement* and drop the *mechanism*: "works for JDK interface
types loaded by the bootstrap classloader" stays, "generated into a fallback package rather
than their own" goes. The judge's own suggestion says exactly this.

## The floor you cannot go below

On a refactor or new-API task the check can never come back clean, and it is important to
know that rather than keep cutting.

`SubtypeManagerTest` is declared `package nl.jqno.equalsverifier.internal.reflection;` and
calls `SubtypeManager.findInstantiableSubclass(...)` unqualified. The class must have that
name in that package or the suite does not compile. Same for `AbstractValueProvider`,
`InstanceCreator.ofExact`, and both exception message literals that the tests assert.

So P1 and P3 cannot be fully satisfied. Removing those names would satisfy an **advisory**
check by breaking `test_faithfulness`, which is **blocking**. Take the residual findings,
and say so in Comments for Reviewer so nobody thinks you simply ignored the report.

Rule of thumb: cut until the only things left are symbols the test suite calls by name, then
stop.

## Verified outcome: the score did not move

I predicted the audit above would improve the score. It did not. Third run on the same task,
after cutting 9516 bytes down to 5222:

```
❌ prescriptiveness: score=0.10, 7 finding(s) (5 high, 2 medium)
```

Same score, one *more* finding. The report explained why, in the P3 suggestion:

> These are **newly introduced internal classes (not a preserved public API)**. Remove the
> package paths, class names, method names and signatures.

The checker does not accept "this is the public API contract" as a defence for anything it
considers internal. Its line is **user-visible behaviour through the project's public
entry point**. It said so explicitly in P5: the user-facing sealed-type error message is "a
legitimate contract requirement", while the internal exception class names and their package
"are implementation choices that should be left to the agent".

For a task whose graded tests are unit tests against new internal classes, that line cannot
be reached. Proof for equalsverifier:

| | count |
|---|---|
| graded tests calling internal names directly | 16 of 20 |
| graded tests using only the public API | 4 |
| static-check floor for `fail_to_pass` | 10 |

Dropping the internal names makes 16 tests underivable. Dropping those tests instead puts
`fail_to_pass` at 4, under the floor, and guts `test_coverage` of the actual refactor. Both
of those checks block; this one does not.

**So on a refactor whose graded tests are unit tests against new internal classes, this check
cannot be made green. Stop when the only remaining findings are names the graded tests call.**

Scope that claim to this task shape. It is about equalsverifier, where 16 of 20 graded tests
call internal names, not about the check in general. On a task whose tests exercise a public
API the same check passed on the third upload, so do not read the paragraph above as "never
bother trying". See "It can pass" at the top.

### Correction: the score did move, on the same task, from 0.10 to 0.42

Source: fourth run on `20260728_153118__jqno_equalsverifier__1166`, 2026-08-02, after the
revision round.

```
❌ prescriptiveness: score=0.42, 6 finding(s) (2 high, 3 medium)
```

Against `0.10` with five high on each of the three previous runs. So "this check cannot be made
green on a refactor whose graded tests are unit tests against new internal classes" was too
strong. What was actually holding the score down was not the internal class names.

**What moved it, and neither change was made for this checker.** Both were made to clear
Quality Check Q9 and Q10, which do block (see
[quality-check-criteria.md](quality-check-criteria.md)):

| Removed from the instruction | Effect |
|---|---|
| four exact error-message literals the tests asserted | no finding on messages at all in the new report |
| the two `In <package>:` headings, replaced by placement relative to a class that exists at base | the two Rule 2 findings on package paths are gone |

The internal class names, the method signatures and the API contracts all stayed. The score
still went up 0.32. The lesson is that **the literals and the package paths were the expensive
part**, not the names, and the symbol audit in this file was aimed at the wrong target.

**Two observations about the new report's quality**, worth knowing before spending a round on it:

- It flagged "`AbstractValueProvider` … belongs with the other `ValueProvider` implementations,
  alongside `ObjectValueProvider`" as P4, and said nothing about "`SubtypeManager` … sits
  alongside `Instantiator`" one line later. Same rule, same construction, one flagged.
- Its suggestions for the two high findings describe what the flagged text already does. P1
  quotes a per-input-kind return contract and suggests "state what it must return for abstract
  vs. sealed vs. concrete inputs, and what error it raises", which is that sentence's structure.

And the rotation pattern held again. P4 flags the *replacement* text written to satisfy Quality
Check Q9. Fixing for the blocking checker and then being flagged by the advisory one is the
normal path, not a mistake.

**Revised rule for this task shape.** Cut literals and paths first, they are worth real score
and they are also what the blocking check objects to. Expect to keep the internal names, and
expect the residual findings to be return contracts the graded tests assert. Stop there and
document, as before, but do not assume the score is stuck at the floor before trying.

## A public library API scores far better, and most findings are real

Source: `20260727_135618__AltBeacon_android-beacon-library__1177`, 2026-08-01. First run of
the check on that task.

```
❌ prescriptiveness: score=0.38, 5 finding(s) (0 high, 3 medium)
```

**0.38 with zero high findings**, against 0.10 with five high on equalsverifier. The
difference is not effort, it is what the graded tests are testing. equalsverifier's suite
calls new *internal* classes, which the checker will never accept being named.
android-beacon-library's suite calls a new *public* API on a library, which is the one thing
the checker says does belong in an instruction. Expect a much better starting score on a
public-API feature task, and expect the findings to be worth acting on rather than
structural.

Four of the five were actionable, which is the opposite of the equalsverifier round:

| Finding | Verdict | What happened |
|---|---|---|
| P2, Rule 5, enumerating which internal fields `adjustSettings` writes | took it | replaced the list with the post-condition it stood for, "reading any affected property back off `BeaconManager` or `Beacon` gives the value just applied". The tests already asserted exactly that, so nothing changed on the test side |
| P4, Rule 6, a literal `"www.google.com"` assertion in the instruction | took it | it really was a ready-made test case. Removed, and the test now supplies its own value |
| P3, Rule 3, naming `ModelSpecificDistanceCalculatorFactory` | took it | asked instead for a default factory producing the library's **existing** `ModelSpecificDistanceCalculator`. Naming a class that already exists at the base commit is derivable and is not new-API prescription |
| P5, Rule 3, "a `Settings.Defaults` singleton" | took half | "singleton" was pure design vocabulary with zero test references. `Settings.Defaults` and `INSTANCE` stayed, see below |
| P1, Rule 3, the `Settings.Builder` and its setters | refused | all three Java tests construct through `new Settings.Builder()`, the Kotlin tests call the setters by name |

I concluded from that round that "an existing class name is not a finding, a new one is."
**That was wrong**, and round two proved it. Correction below.

### The findings rotate, so budget for more than one round

Round two on the same task, after taking those four:

```
❌ prescriptiveness: score=0.45, 5 finding(s) (0 high, 4 medium)
```

Score up, severity down, **same count and almost entirely different findings**. This is not
the equalsverifier case where the score refused to move. Here each pass genuinely improves
the instruction and then exposes the next layer. Two of the five had not been mentioned at
all in round one, despite the text being unchanged in those spots.

The one that matters most is P3, because it flagged *my round-one fix*:

| Round | Instruction said | Verdict |
|---|---|---|
| 1 | "provide a `ModelSpecificDistanceCalculatorFactory` as the default implementation" | flagged, it is a new internal name |
| 2 | "that default one produces the library's existing `ModelSpecificDistanceCalculator`" | flagged again, Rule 2, "names an exact existing internal class ... pointing the agent directly to a specific symbol to call" |

So swapping a new class name for an existing one buys nothing. The checker objects to naming
**any** internal class the agent is supposed to reach for. The fix that actually worked was
dropping class names entirely and stating the behaviour that has to survive: "the default
factory has to preserve the distance calculation the library already performs today." The
test moved with it, from `assertTrue(calc is ModelSpecificDistanceCalculator)` to asserting
the calculation itself, roughly one metre when the measured rssi equals the reference power.
That figure was already the assertion in the repo's own `ModelSpecificDistanceCalculatorTest`,
so it is an established convention rather than a number pulled from the oracle.

**Rule: replace a class name with the observable behaviour, not with a different class name.**
If a test asserts a type, see whether it can assert what that type *does* instead. That
usually satisfies the checker and makes the test better.

Also worth knowing: the checker reads example *expressions*, not just prose. `Settings.Defaults.INSTANCE.getScanPeriods()`
was flagged for revealing that `Defaults` must be a Kotlin `object` rather than a companion
object or a top-level val. A Java call site can leak a language construct that the
surrounding sentence never mentions.

### Cutting a name can break Java derivability in a way Kotlin hides

Worth its own line because it nearly slipped through. The Java test read defaults two ways:

```java
Settings.Defaults.INSTANCE.getScanPeriods().getBackgroundScanPeriodMillis();  // val   -> getter
assertEquals("", Settings.Defaults.distanceModelUpdateUrl);                   // const val -> static field
```

Those are *different* Kotlin declarations. `const val` compiles to a static field with **no**
getter; a plain `val` in an `object` is only reachable through `INSTANCE`. So that second
line silently pinned the oracle's const-vs-val split, which the instruction never states and
an agent cannot derive. From Kotlin both forms read identically, so the problem is invisible
on the Kotlin side.

Fixed by reading every Java-side default through `INSTANCE`, the one access path the
instruction does state, and leaving the value assertions to the Kotlin test.

**Rule: after trimming the instruction, re-read the Java tests specifically.** Kotlin
tolerates shapes Java does not, and a Java call site can encode a language-level
implementation choice you just deleted from the spec.

## What is still worth cutting on the third pass

Not everything was structural. These had zero test dependency and the checker was right
about them:

| Finding | Cut |
|---|---|
| P1, root-cause diagnosis | the whole "the logic is spread out, substitution happens quietly inside instantiation" paragraph. Handing over the root cause is over-prescription under `docs/guidelines.md` too |
| P2, refactoring strategy | "pull that responsibility into one place and make the choice explicit" |
| P7, rationale | "since abstract handling now belongs upstream of it" — the behaviour stays because a graded test asserts it, the justification goes |
| P6, ordering | reworded from an implementation detail into the test expectation it is, which is what the checker suggested |

Worth doing even knowing the score will not clear: it removes real over-prescription, and a
human reviewer reads this report too.

## Check it before uploading

There is no local copy of this checker, so read the instruction by hand against everything
seen so far:

- Does it name a language built-in, package or library the agent should have chosen?
- Does it name an internal file path, or point at where existing code lives today?
- Does it prescribe a design pattern, a class shape, or exact method signatures?
- Does it say where a new component slots into an existing structure, naming its neighbours?
- Does it pre-answer an edge case by naming the mechanism rather than stating the requirement?
- Does it list internal callers that must be updated?

Then run the symbol audit above and cut everything the graded tests never reference. Do not
cut what they do.
