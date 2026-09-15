# 20260727_135618__AltBeacon_android-beacon-library__1177

| Field | Value |
|---|---|
| Submission id | a1bcc8a9-8c08-4a41-83c2-6659dff2978b |
| Repo / PR | AltBeacon/android-beacon-library PR 1177 "New Configuration API for 3.0" |
| Category | implementation / feature |
| Difficulty | hard (`model_difficulty` says medium) |
| Language | Kotlin + Java, Android, Gradle 8, Robolectric |
| Base commit | de166a040a0252edba9cf760273666003c5da5ed |
| Verdict | **Fixable** |
| Status | **accepted 2026-08-14, on round 8 / upload 12.** The second bundle in this workspace to clear every gate |
| Claimed | 2026-08-01 |

## Upload ledger

Rows 1 to 6 predate this ledger, so their hashes were never recorded. The zip is overwritten
every round by design, which is exactly why the hash is the only proof of what the platform
actually graded. Reconstructed rows say so rather than carrying an invented hash.

| # | Date | Zip sha256 | Size | Checks returned | Outcome |
|---|---|---|---|---|---|
| 1-3 | 2026-08-01/02 | not recorded | - | static, instruction score | instruction score 0.38, 0.45, then pass |
| 4 | 2026-08-02 | not recorded | - | static, difficulty, oracle, quality | oracle 0/3, quality bounce on test coverage |
| 5 | 2026-08-03 | not recorded | - | static, instruction score | 0.50, non-blocking, left outstanding |
| 6 | 2026-08-04 | not recorded | - | static, difficulty, oracle, quality | oracle 0/3, quality REMOVE on oracle spec |
| 7 | 2026-08-04 | not recorded | - | static, difficulty, oracle, quality | quality PASSED, screen blocked on oracle 0/3 |
| 8 | 2026-08-05 | md5 `63752048223394b297c551131f6f2c04` | 2.6 MB | static, quality | quality DISCUSS on the oracle spec axis |
| 9 | 2026-08-05 | `5f2eb38b5b758e961dd11b2841f578ea230661849efd80f45449ffd09386349c` | 2603512 B | static, quality | quality REMOVE, oracle against instruction. Optional instruction check 0.30 with 1 high |
| 10 | 2026-08-05 | `07de50a84fa958b49d0b42d253eab3524140a67d598f2e979d99dea9567bb33e` | 2604113 B | static, quality | quality DISCUSS `coverage_gap`, two stated requirements ungraded |
| 11 | 2026-08-06 | `37dc2f7818fa45d589164aba...` md5 `2e07b34a1c080c602eda7a22a7cf5d2a` | 2604630 B | **all evaluation checks passed**, sent to a human reviewer | reviewer returned Needs Revision with 4 findings. **The oracle question is settled: the checks passed** |
| 12 | 2026-08-14 | `20d55c97cc8c384373b87688...` md5 `5e7be003adece4f08316ff7a196177e6` | 2605430 B | all checks passed, reviewer | **ACCEPTED** |

## learning/ notes applied

| Note | What it predicts here | Command that settles it | Outcome |
|---|---|---|---|
| tests-patch-vs-agent-edits.md | an agent editing `lib/src/test` kills the trial and a git restore will not save it | run the verifier after committing an agent edit | confirmed. Git restore replaced with a base64 tarball inside `test.sh` |
| verifier-fail-open.md | stock `test.sh` writes reward 1.0 without reading `raw_exit_code` | `grep -n raw_exit_code tests/test.sh` | confirmed and gated. NOP now reports reward 0 with raw exit 1 |
| solve-sh-idempotency.md | a reverse-apply fallback inverts the tree on the second oracle run | run `solve.sh` three times in one container | not present. Three runs give 230/230. The earlier claim that this caused the 0/3 was wrong and is retracted in the note |
| unreachable-git-blobs.md | golden and patched-test blobs dangle in `environment/repo/.git` after a clean-looking gc | `git fsck --unreachable --no-progress` | confirmed once, scrubbed. Silent every round since |
| stale-test-reports.md | a build-time test report makes the NOP reward look meaningful | read per-test outcomes, not the reward | confirmed. The NOP dies at `compileDebugUnitTestKotlin`, so the zero was verified by symbol audit instead |
| verify-in-the-image.md | the bundle claims things on disk the image does not do | rebuild from the extracted zip and re-run | used every round. Caught the `.gradle` cache twice |
| quality-check-criteria.md | instruction findings block on their own, whatever the test axes say | read the report's own criterion groups | confirmed across five reports |
| source-pr-cross-check.md | a coverage or spec finding describes PR 1177 rather than this bundle | diff the cited behaviour against the PR diff | confirmed six times. Every oracle finding on this task has been PR-inherited |
| diagnosing-platform-only-failures.md | the 0/3 will not yield to a third locally-verified theory | count strikes before choosing a fix | confirmed. See the strike table |
| accepted-bundle-reference.md | the accepted bundle's shape is the calibration for clarity | measure its paragraph sizes | confirmed. 717 characters against this task's 2724 |

## Failure signatures

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Oracle Check 0/3 | 1, 2, 3 | git-based test restore removed; `solve.sh` rewritten git-free; `GRADLE_USER_HOME` pinned; `build_timeout_sec` raised to 1800 | **RETIRED at round 8. Upload 11 passed every evaluation check**, so the signature is gone. It had not reproduced since round 3 and its last appearance carried no per-test output, which is the infra shape. 3, capped. Two strikes forced the remove-the-dependency path and it was taken. Nothing further ships against this theory without the difficulty artifact |
| Quality panel bounce on instruction against oracle | 1, 2, 4, 5, 6, 7 | narrowed the instruction six separate times, always in `instruction.md`, never in the patch | **6. Round 6's audit was still a narrowing, and its rewrite is what round 7 had to fix** - it replaced a false claim with a stronger false claim ("it is the only one"). Round 7 removed the unbounded universals instead of narrowing them. The class is closed, not the instance |
| Quality panel bounce on test coverage | 1, 5 | round 1 added assertions; round 5 bound a real consumer | 2. The round 5 fix is the first that exercises the claim rather than restating it |

## Handling time ledger

Rounds 1 to 4 were never split per round, so they are carried as the single cumulative figure
the answers file already held. This ledger exists so round 5 onward is derived rather than
remembered.

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 1-4 | 2026-08-02 to 2026-08-05 | 110 (not split) | 110 |
| 5 | 2026-08-05 | 60 | 170 |
| 6 | 2026-08-05 | 60 | 230 |
| 7 | 2026-08-06 | 60 | 290 |
| 8 | 2026-08-14 | 60 | 350 |

## Check history

| Upload | Platform result | Action |
|---|---|---|
| 1 | Static checks passed. `prescriptiveness: score=0.38, 5 findings (0 high, 3 medium)` | took 4 of 5, see below. Non-blocking, but addressed before review |
| 2 | `prescriptiveness: score=0.45, 5 findings (0 high, 4 medium)` | score up, severity down, mostly *different* findings. Took 4 of 5 again. Only the `Settings.Builder` is left refused |
| 3 | **prescriptiveness passed** | green with the `Settings.Builder` paragraph still in place, so the check is a score threshold rather than a zero-findings bar. Written up in `learning/prescriptiveness-check.md` |
| 4 | Full eval. **Oracle 0/3**, rubric panel **DISCUSS** on `test_coverage` 2.5 | revision round 1, see below |
| 5 | `prescriptiveness: score=0.50, 3 findings (0 high, 1 medium)` on the round 1 re-upload | all three quote text unchanged since upload 3. Non-blocking, left outstanding |
| 6 | Full eval. **Oracle 0/3 again**, rubric panel **REMOVE** on `oracle_spec_faithfulness` 2.0 | revision round 2, see below. Oracle gap held pending the 0/3 |

**Prescriptiveness scoreboard: 0.38, 0.45, pass, 0.50.** A pass does not stick and the
findings rotate on unchanged text. Threshold is above 0.50. See
`learning/prescriptiveness-check.md`.

Platform data block is in `task_details.md`. Form answers are in
`answers/submission_answer.txt`.

## Local check results

Run against the exact bundle in `upload/`, unpacked to a scratch directory, airgapped with
`--network none`, at the declared `cpus=4 / 8 GB`.

| Check | Reward | Required | Suite | Time |
|---|---|---|---|---|
| NOP | 0 | 0 of 229 | 0 tests reported, the test module does not compile | 23 s |
| Oracle | 1 | 229 of 229 | 229 pass, 0 fail, 32 classes | 32 s of 1800 s |

fail_to_pass 19, pass_to_pass 210, `allow_extra_failures` false. Two oracle runs produced
identical pass sets across every round. The host was not idle, so 32 s is an upper bound.

A third run simulated an agent that had been in the repo (see finding 6). Reward 1, 229 of
229. The same run against the **shipped** `test.sh` gives an infra error and reward 0.

**The NOP graded nothing, so its reward needed a second look** (`learning/verify-in-the-image.md`,
finding 2). It failed at `compileDebugUnitTestKotlin`, which takes down the whole test source
set, so a reward of 0 with every id missing proves the run died rather than that each test
failed. Kotlin gives no per-file subset to re-run the way pytest does, so it was verified by
symbol instead: all 19 f2p test bodies reference `Settings`, `adjustSettings`,
`replaceSettings`, `revertSettings`, `activeSettings` or `DistanceCalculatorFactory`, and
none of those exist at the base commit. The only base-repo matches are `SettingsData` in
`beacon/service/` and `IntentScanStrategyCoordinator`, neither of which any test touches.
So no f2p test can already pass, and the count of 19 is genuine.

## Findings and what was done

**1. `fail_to_pass` had 3 ids. Blocking.** The static check rejects anything outside 10 to
20 and the floor is 10. The three were `SettingsTest::setSettingsTest`,
`SettingsTest::configureCustomDistanceCalculatorTest` and
`SettingsJavaTest::setSettingsTest`. Rewrote both test files to 19 ids.

**2. The suite held two assertions in total.** `SettingsJavaTest::setSettingsTest` had
**none** — it called methods and passed as long as nothing threw. Four more functions in
`SettingsTest.kt` were declared without `@Test` (`configureScheduledJobStrategyTest`,
`configureJobServiceStrategyTest`, `configureBackgroundServiceStrategyTest`,
`configureIntentScanStrategyTest`) so they never ran.

That left almost the whole instruction ungraded: the 14 optional fields, the `ScanPeriods`
defaults and named-argument form, the `Builder`, the `Defaults` singleton, the difference
between `adjustSettings` and `replaceSettings`, `revertSettings`, strategy equality, and the
snapshot-copy semantics of `getActiveSettings()`. Rewrote to 16 Kotlin plus 3 Java tests,
each tied to a sentence in the instruction. The four dead functions came back as real tests.

**3. A hidden dependency-bump requirement.** `SettingsTest.kt` shipped with no `@Config`, so
Robolectric ran it at the module target of SDK 34. Base `lib/build.gradle` pins
`robolectric:4.9`, which does not support SDK 34. Passing therefore required editing
`lib/build.gradle` to `4.11.1` — and to that exact version, because it is the only one the
Dockerfile warms into the offline cache at lines 50 to 71. The instruction says nothing
about dependency versions. All 28 pre-existing test classes use `@Config(sdk = 28)`; the new
ones now do too, which makes the bump optional rather than undiscoverable.

**4. The oracle did not implement the instruction, in two places.** `replaceSettings` was
byte for byte identical to `adjustSettings`, so it merged onto the current values instead of
resetting unset fields to defaults. And `setBackgroundBetweenScanPeriod(sp.getBackgroundScanPeriodMillis())`
fed the background scan period into the between-scan period, so any faithful test of the
four periods would have failed a *correct* agent. Two one-line fixes inside `golden.patch`.
Nothing removed from the PR.

**5. No regression guard.** `pass_to_pass` was empty with `allow_extra_failures: true`, and
the command ran only the two Settings classes, so it could not have seen a regression
anyway. Now runs the whole suite with 210 pass-to-pass ids and extra failures disallowed.

**6. `tests.patch` fails to apply once an agent has been in the repo. Most damaging.**
The patch adds `lib/src/test/java/org/altbeacon/beacon/SettingsTest.kt` as a new file. An
agent asked to build a `Settings` class in `org.altbeacon.beacon` will plausibly write its
own test with that name in that package, and `git apply` then refuses:

```
error: lib/src/test/java/org/altbeacon/beacon/SettingsTest.kt: already exists in working directory
ERROR: failed to apply tests/tests.patch
```

The trial is recorded as an infra error instead of being scored on merit. Reproduced locally
with a control run. Fixed by restoring the test tree in `tests/test.sh` immediately before
applying the patch. This is a refinement of `learning/tests-patch-vs-agent-edits.md`, which
said a patch of only brand-new files does not need the restore step — written back there.

**7. Stale test results readable from the image.** The Dockerfile runs the suite at build
time and the grader globs `lib/build/test-results/testDebugUnitTest/*.xml`, leaving
`TEST-org.altbeacon.warmup.WarmupTest.xml` readable with no test run at all. Mild here since
`WarmupTest` is in no grading list, but it matters now that `pass_to_pass` is populated. The
command clears the directory first. The NOP run reports 0 tests as a result.

**8. Over-prescription in the instruction.** "a Kotlin data class is the intended shape"
names the language construct. "you must not modify the test files under `lib/src/test`" is
verifier mechanics, which is the thing the prescriptiveness checker flags — and finding 6
made it unnecessary, since the harness now enforces it. Also dropped the unbind-and-rebind
sentence and "knows how to configure the manager", both internal mechanism that no test can
reach, and a duplicated `setScanStrategy` in the builder list.

The platform check then came back at **0.38 with 5 findings and none high**, against 0.10
with five high on equalsverifier — a public library API is exactly the case the checker says
belongs in an instruction. Took four of the five:

| Finding | Action |
|---|---|
| P2, enumerating which internal fields `adjustSettings` writes | replaced with the post-condition it stood for. Tests already asserted that, so no test change |
| P4, the literal `"www.google.com"` assertion | removed; the test supplies its own value |
| P3, naming `ModelSpecificDistanceCalculatorFactory` | now asks for a default factory producing the library's **existing** `ModelSpecificDistanceCalculator`. `Settings.Defaults.distanceCalculatorFactory is …Factory` dropped from the test, since `theDefaultFactoryProducesAModelSpecificCalculator` already covers it |
| P5, "a `Settings.Defaults` singleton" | "singleton" cut. `Settings.Defaults` and `INSTANCE` stay — all three Java tests need them |
| P1, the `Settings.Builder` | refused. 19 of 19 graded tests call it by name |

That pass also caught a derivability bug of my own: `Settings.Defaults.debug` and
`.distanceModelUpdateUrl` only compile from Java when those members are `const val`, which
the instruction never states.

Round two came back **0.45, 5 findings, none high** — score up, severity down, and mostly
*different* findings from round one. Took four again:

| Finding | Action |
|---|---|
| P2, the `Settings.Defaults.INSTANCE` example | it reveals `Defaults` must be a Kotlin `object`. Example dropped; `defaultsAreReadableFromJava` now reads the defaults off the resolved snapshot |
| P3, naming the **existing** `ModelSpecificDistanceCalculator` | this flagged my own round-one fix. Class names gone entirely; the instruction asks for the distance calculation to be preserved and `theDefaultFactoryPreservesTheLibraryDistanceCalculation` asserts that calculation instead of a type |
| P4, "naming just the fields they care about" hinting at a data class | reworded to the checker's own suggested phrasing |
| P5, the bare package `org.altbeacon.beacon.distance` | now a placement tied to the `DistanceCalculator` the factory returns, which keeps the Kotlin test's import derivable |
| P1, the `Settings.Builder` | refused again. All three Java tests construct through it and it is the Java half of the PR |

The round-two P3 corrects something I had written into
`learning/prescriptiveness-check.md`: swapping a new class name for an existing one buys
nothing, because the checker objects to naming any internal class the agent should reach for.
Replace the class name with the behaviour instead. Both the correction and the
`INSTANCE` finding are written up there.

**9. Packaging and metadata.** `gradlew` had lost its executable bit in the delivered zip,
which left `git status` dirty (` M gradlew`). `solve.sh` and `test.sh` shipped mode 644.
`task.toml` had no `[environment] os` and no `difficulty_explanation`; `[agent] timeout_sec`
was 1800 of a 7200 ceiling on a feature that adds 351 lines of `Settings.kt` plus 174 of
`BeaconManager` with both models at 0/3; `[verifier] timeout_sec` was 300.

**10. No `runs/` folder.** No agent trials to read. Only `pass_at_k_opus_4_8 = 0/3` and
`pass_at_k_gpt_5_5 = 0/3`.

## Verified clean

- `instruction.md` byte-identical to `environment/problem_statement.md`, md5 `5dd419d5ce56`
- `task.toml` on disk matched the platform's metadata block byte for byte before edits
- git: HEAD equals the declared base commit, no remote, no refs past HEAD, no `filter.*`,
  no reflog, clean tree, `.git` 2.5 MB, contents exactly `config description HEAD hooks
  index info objects packed-refs refs`
- both patches apply at base and touch disjoint file sets
- `tests.patch` adds two brand-new files and modifies no pre-existing test
- no leakage: `adjustSettings`, `replaceSettings`, `revertSettings`, `getActiveSettings`,
  `DistanceCalculatorFactory` and `AppliedSettings` appear nowhere in the shipped repo. No
  PR URL, number or SHA in the instruction, problem statement or Dockerfile
- source PR 1177 is "New Configuration API for 3.0", merged 2024-10-21. The oracle also
  carries the BeaconRegion half of that PR, which the instruction does not describe. Allowed
  under the "oracle may be larger" rule
- stray-artifact sweep empty
- Dockerfile builds (exit 0), pins `eclipse-temurin:17-jdk` and the cmdline-tools zip,
  installs git, tmux, asciinema and patch, warms the Gradle and Robolectric caches so the
  verifier runs offline. No change needed
- all 20 static checks simulated against the **extracted zip**, not the working copy: pass

## Files changed

| File | Change |
|---|---|
| `instruction.md` | prescriptiveness pass, scan-period and snapshot semantics made explicit |
| `environment/problem_statement.md` | re-copied, md5 `5dd419d5ce56` |
| `tests/tests.patch` | both test files rewritten, `@Config(sdk = 28)` added, regenerated at base |
| `tests/config.json` | f2p 3→19, p2p 0→210, `allow_extra_failures` → false, stale-result purge, whole suite runs |
| `tests/test.sh` | test-tree restore before applying `tests.patch` |
| `solution/golden.patch` | `replaceSettings` resets to defaults, background between-scan period fixed |
| `task.toml` | added `os` and `difficulty_explanation`, agent 1800→7200, verifier 300→1800 |
| `environment/repo/.git/` | reflog expired, gc, cruft removed, `gradlew` exec bit restored |

No tracked source file inside `environment/repo` was touched. PR scope unchanged.

---

# Revision round 1 — feedback received 2026-08-02

Source: platform eval loop (Step 7), first run of Difficulty / Oracle / Quality on this task.
Pasted verbatim below per CLAUDE.md Step 10.1. Status set to `pending-revision` in `INDEX.md`.

## Feedback, verbatim

```
## Automated feedback

Agent Runner Summary: Evaluation FAILED. Rubric panel judge: DISCUSS (NEEDS_REVISION)

Agent Runner Summary: Evaluation FAILED. Validation failed: Oracle did not pass all runs: 0/3. Task may be flaky or has infra issues.

## Difficulty Check

Oracle did not pass all runs: 0/3. Task may be flaky or has infra issues.

## Oracle Check

Oracle did not pass all runs: 0/3. Task may be flaky or has infra issues.
```

Agentic Judge Quality Report — status **DISCUSS**, reason **coverage_gap**.

| Axis | Adjudicated | claude | gpt |
|---|---|---|---|
| clarity | 3.5 | 3 | 4 |
| oracle_no_gaming | 5.0 | 5 | 5 |
| oracle_robustness | 4.5 | 5 | 4 |
| oracle_spec_faithfulness | 3.5 | 4 | 3 |
| packaging | 5.0 | 5 | 5 |
| prescriptiveness | 4.5 | 4 | 5 |
| realism | 5.0 | 5 | 5 |
| self_containedness | 4.0 | 4 | 4 |
| **test_coverage** | **2.5** | 5 | **2** |
| test_faithfulness | 4.0 | 4 | 4 |

Driving judge rationale, verbatim:

> The prompt requires Defaults entries and application/readback semantics for every named
> field [instruction.md:3-7], but the tests only assert `beaconSimulator` and
> `rssiFilterImplClass` are null on a fresh `Settings` [tests/tests.patch:146-163] and never
> verify their defaults or that `adjustSettings`/`replaceSettings`/`revertSettings` apply
> them; the application tests cover only selected fields such as URL, scan periods,
> hardware/region options, debug, and distance factory [tests/tests.patch:302-385]. The
> prompt also says a change made to an active-settings snapshot must not reach live
> configuration [instruction.md:7], while the snapshot test only checks that later live
> changes do not alter an earlier snapshot [tests/tests.patch:363-376].

Other flagged items, verbatim from the per-axis justifications:

- **oracle_spec_faithfulness, gpt (3/5):** "it explicitly leaves named settings unapplied
  (`longScanForcingEnabled`, `rssiFilterImplClass`, and `scanStrategy`, with
  `useTrackingCache`/`maxTrackingAgeMillis` also never applied) despite the instruction
  requiring all applied fields to be observable ... `Defaults.regionStatePersistenceEnabled`
  is misspelled as `regionStatePeristenceEnabled`, so the exact requested default field is
  missing ... `ForegroundServiceScanStrategy.equals` ignores the `notification` value even
  though equality must reflect strategies configured the same way"
- **oracle_spec_faithfulness, claude (4/5):** "`applySettingsChange` explicitly TODOs
  `longScanForcingEnabled` and `rssiFilterImplClass` [solution/golden.patch:193-196], and
  `useTrackingCache`/`maxTrackingAgeMillis` are stored on AppliedSettings but not propagated
  to BeaconManager"
- **oracle_robustness, gpt (4/5):** "the final fallback reverse-applies the patch if both
  forward apply attempts fail, so rerunning in an already-patched working tree could silently
  undo the solution rather than being idempotent [solution/solve.sh:4-10]"
- **test_faithfulness, claude (4/5):** "[tests/tests.patch:366] uses `assertNotSame(snapshot,
  beaconManager.activeSettings)` ... a memoized immutable snapshot would satisfy the spec yet
  fail this identity check; and [tests/tests.patch:391] pins the default distance-calculation
  output to `1.0 ± 0.1` at `rssi=-59, txPower=-59`"
- **test_faithfulness, gpt (4/5):** "the verifier also requires a large legacy `pass_to_pass`
  set, including unrelated parser, URL-compressor, and Bluetooth tests, with
  `allow_extra_failures=false` [tests/config.json:36-249]"
- **clarity, claude (3/5):** "no defaults are stated for `scanPeriods`, `scanStrategy`,
  `beaconSimulator`, `rssiFilterImplClass`, or `distanceCalculatorFactory` in `Defaults`, the
  type of `scanStrategy` is unspecified, and 'the configuration surface the library already
  has' [instruction.md:7] isn't enumerated"

## Local reproduction of the oracle failure — DID NOT REPRODUCE

Run 2026-08-02 against the **exact uploaded zip**, extracted to the session scratchpad,
`--network none`, `--cpus=4 --memory=8g`, using the image built from the bundle's own
`environment/`.

| Check | Reward | Required | raw_exit_code | Infra error |
|---|---|---|---|---|
| Oracle | **1** | **229 of 229** | 0 | none |

`missing_required_tests` and `unexpected_failures` were both empty. So the graded set is
intact and the tests are not the cause. The platform's 0/3 is therefore an image-build or
runner difference, not a test failure.

## The feedback as a numbered item list (Step 10.2)

| # | Item | Source | Blocking | Action |
|---|---|---|---|---|
| 1 | Oracle 0/3 on the platform, passes 229/229 here | Oracle Check | **yes** | root cause under measurement, see above |
| 2 | `beaconSimulator` / `rssiFilterImplClass` have no Defaults assertion and no apply/readback | test_coverage, driving rationale | **yes** | add to `defaultsHoldTheLibraryDefaultForEachField`; add apply/readback for `beaconSimulator` (the oracle does push it, `BeaconManager.setBeaconSimulator`) |
| 3 | Snapshot isolation only tested one way | test_coverage, driving rationale | **yes** | extend `activeSettingsHandsOutAnIndependentSnapshot` with the snapshot-to-live direction |
| 4 | `regionStatePersistenceEnabled` default never asserted | found here, corroborates item 6 | **yes** | add the assertion; it is why the oracle typo survived |
| 5 | `useTrackingCache` / `maxTrackingAgeMillis` / `longScanForcingEnabled` / `rssiFilterImplClass` unasserted | test_coverage | **yes** | assert they round-trip through `activeSettings`, which is what the oracle actually supports |
| 6 | Oracle misspells `Defaults.regionStatePeristenceEnabled` | oracle_spec_faithfulness (gpt) | no | fix in `golden.patch`; the instruction names the correct spelling, so this is "oracle does not implement the instruction" |
| 7 | Oracle leaves `longScanForcingEnabled`, `rssiFilterImplClass`, `useTrackingCache`, `maxTrackingAgeMillis` unapplied | oracle_spec_faithfulness | no | upstream PR carries the same `TODO: apply all other settings`. Do **not** extend the oracle; narrow the instruction's "every field it applied has to be observable" claim so it stops over-promising |
| 8 | `solve.sh` reverse-apply fallback is not idempotent | oracle_robustness (gpt) | no | make it forward-only per CLAUDE.md 10.6 |
| 9 | `assertNotSame(snapshot, activeSettings)` over-strict | test_faithfulness (claude) | no | replace with a behavioural independence check |
| 10 | `1.0 ± 0.1` distance figure pinned | test_faithfulness (claude) | no | **keep**. It is the repo's own existing assertion in `ModelSpecificDistanceCalculatorTest`, so it is an established convention rather than an oracle-derived constant. Document in Comments for Reviewer |
| 11 | Broad `pass_to_pass` with `allow_extra_failures=false` | test_faithfulness (gpt) | no | **keep**. CLAUDE.md 10.2 wants a populated regression guard. Document |
| 12 | `ForegroundServiceScanStrategy.equals` ignores `notification` | oracle_spec_faithfulness (gpt) | no | **refuse**. Android `Notification` has no value equality, so comparing it would make two identically configured strategies unequal and break the instruction's contract in the other direction. `notificationId` is the configured identity. Document |
| 13 | Defaults not stated for `scanPeriods`, `scanStrategy`, `beaconSimulator`, `rssiFilterImplClass`, `distanceCalculatorFactory`; `scanStrategy` type unstated | clarity (claude) | no | state them in `instruction.md`, which also makes items 2 and 4 derivable |

**`fail_to_pass` budget: 19 of a hard ceiling of 20.** Only one new top-level id is available,
so items 2 to 5 land as extra assertions inside existing tests plus at most one new test.

## Root cause of the oracle 0/3 — FOUND

`solution/solve.sh` was not idempotent. It tried forward apply, then `--3way`, and if both
failed it ran `git apply -R` and reported success. Reproduced in a container:

```
first apply OK
1                                     <- adjustSettings present
second apply exit 0                   <- solve.sh "succeeded"
adjustSettings occurrences after 2nd run: 0
Settings.kt GONE — solution was reversed
```

A second invocation destroys the solution and still exits 0, so the verifier grades an
unsolved tree and returns 0 on every run. That matches `0/3` exactly. Rewritten forward-only:
already-applied is a no-op exit 0, nothing-applies is a loud exit 1, the reverse fallback is
gone. Three consecutive applies now leave the solution intact and the verifier at reward 1.

Ruled out along the way, each with a measurement rather than a guess:

| Hypothesis | Result |
|---|---|
| `build_timeout_sec = 900` too low | cold `docker build --no-cache` from the zip: **exit 0 in 316s** |
| Offline Gradle cache missing the patched deps | image cache holds core-ktx 1.12.0 and robolectric 4.11.1 |
| Verifier timeout | oracle run takes **30s** against 1500s |
| Flaky graded tests | 3 fresh runs on the cold image, all reward 1, 229/229 |

## What round 1 changed

| File | Change |
|---|---|
| `solution/solve.sh` | forward-only and idempotent, reverse-apply fallback removed |
| `solution/golden.patch` | `Defaults.regionStatePeristenceEnabled` renamed to `regionStatePersistenceEnabled` plus its three references |
| `tests/tests.patch` | `defaultsHoldTheLibraryDefaultForEachField` now covers all 14 fields; `activeSettingsHandsOutAnIndependentSnapshot` tests the snapshot-to-live direction and drops `assertNotSame`; new `theRemainingFieldsAreAppliedAndReadableBack` |
| `tests/config.json` | `fail_to_pass` 19 → 20 |
| `instruction.md` | defaults stated for `beaconSimulator` and `rssiFilterImplClass`; the "every field observable on the existing surface" claim narrowed to match what the PR actually pushes through |
| `environment/problem_statement.md` | re-copied, md5 `f0eb5ded7556` |
| `environment/repo/.git` | reflog expired, gc, 2 unreachable blobs of the patched test files cleared, `FETCH_HEAD` removed |
| `environment/repo/.gradle` | build-cache lock files removed from both `work/` and `download/original/` |

Refused, with reasons recorded in Comments for Reviewer: the `ForegroundServiceScanStrategy.equals`
notification change (Android `Notification` has no value equality), the `1.0 ± 0.1` figure (it is
the repo's own existing assertion), the broad `pass_to_pass` (it is the regression guard), and
extending the oracle to apply the four fields upstream left on a TODO.

## Round 1 verification

| Check | Reward | Required | Exit | Time |
|---|---|---|---|---|
| NOP | 0 | 0 of 230 | 1 | — |
| Oracle | 1 | **230 of 230** | 0 | 30s of 1800s |
| Hostile delete (stub the simulator push-through) | **0** | 229 of 230 | 1 | — |

The hostile-delete run reports `theRemainingFieldsAreAppliedAndReadableBack` as the missing
test, so the new coverage is load-bearing rather than decorative.

Git after cleanup: `fsck --unreachable` silent, `.git` contents exactly `config description
HEAD hooks index info objects packed-refs refs`, HEAD at the base commit, no remotes, clean
tree, 2.5 MB. All 20 static checks simulated against the **extracted zip**: pass. Zip rebuilt
at `upload/`, no `runs/`, no `task/` wrapper, `.git` and `refs/` present, both scripts 0755,
no `.gradle` and no stray artifacts.

## Round 1 upload — prescriptiveness result (2026-08-02, non-blocking)

Re-uploaded after the fixes above. Prescriptiveness came back red again but milder than any
previous run, and it does not block submission.

```
❌ prescriptiveness: score=0.50, 3 finding(s) (0 high, 1 medium)
```

| Round | Score | Findings |
|---|---|---|
| 1 | 0.38 | 5 (3 medium) |
| 2 | 0.45 | 5 (4 medium) |
| 3 | **passed** | — |
| 4 (this one) | 0.50 | 3 (1 medium, 2 low) |

Round 3 passed and 0.50 fails, so the threshold sits above 0.50.

| # | Sev | Objects to | Test references | Decision |
|---|---|---|---|---|
| P1 | medium | the `Settings.Builder` paragraph and its five setter signatures | 4 `Settings.Builder` call sites, all five setters called by name, `builderReturnsItselfAndSetsOnlyTheFieldsItWasGiven` asserts the fluent return per setter | refuse, same as rounds 1 and 2 |
| P2 | low | stating both directions of snapshot isolation | the direction it wants removed is the one the rubric panel failed us for not testing | hold, see conflict below |
| P3 | low | naming `Settings.Defaults` and the `Defaults.distanceModelUpdateUrl` example | **15** references, 5 of them added this round to close the coverage gap | refuse |

**None of the three were caused by this round's edits.** All quote text that predates it and
that was present, unchanged, when the check passed at round 3. Paragraph 3 was edited only to
add the `beaconSimulator` and `rssiFilterImplClass` default parentheticals; paragraph 7 only
in the "observable" clause, which no finding quotes. This is the finding rotation already
documented in `learning/prescriptiveness-check.md`.

**P2 puts two graders in direct conflict.** The rubric panel's driving rationale for the
`test_coverage` 2.5 failure was that "the prompt also says a change made to an active-settings
snapshot must not reach live configuration [instruction.md:7], while the snapshot test only
checks that later live changes do not alter an earlier snapshot". It failed the task for not
testing that direction, which it could only demand because the instruction states it.
Prescriptiveness now calls stating it over-prescription. Only the rubric panel blocks. If this
is taken, the judge's own phrasing ("snapshots must be independent of the live configuration")
still supports a both-directions test, so the fix exists but is not free.

Submitted as-is on 2026-08-02 with all three findings outstanding and documented in Comments
for Reviewer. Revisit only if a reviewer raises them.

## Open after round 1

- Handling times: the "all revisions" field needs a fresh number from the submitter. It reads
  55 minutes from round 0, which is already under the 60 to 120 band, and this round added
  work. The other three fields are first-pass numbers and do not move.
- Not changed this round: the embedded grader records `raw_exit_code` without branching on it.
  It fails closed here in practice because the test command clears the results directory
  first, so a dead build produces no XML and no passes. Flagged in Comments for Reviewer.

---

# Revision round 2 — feedback received 2026-08-03

Source: platform eval loop (Step 7), second full run of Difficulty / Oracle / Quality after the
round 1 re-upload. Pasted verbatim below per CLAUDE.md Step 10.1.

**Task identity confirmed from the report itself** (Step 10.0): the justifications cite
`solution/golden.patch:135-198` (`applySettingsChange`), `739-761`
(`JobServiceScanStrategy`), `tests/tests.patch:394-399` (`activeSettings.copy`) and the
`Settings`/`ScanPeriods`/`ScanStrategy` API. That is this bundle and no other.

## Feedback, verbatim

```
## Automated feedback

Agent Runner Summary: Evaluation FAILED. Rubric panel judge: REMOVE (NEEDS_REVISION)

Agent Runner Summary: Evaluation FAILED. Validation failed: Oracle did not pass all runs: 0/3. Task may be flaky or has infra issues.

## Difficulty Check

Oracle did not pass all runs: 0/3. Task may be flaky or has infra issues.

## Agentic Judge Quality Report

================================================================================
                  AGENTIC JUDGE REVIEW: task
================================================================================

Status: ❌ REMOVE
Reason: oracle_spec_gap

Per-axis review (rating out of 5, with judge justifications):

clarity — 4.0/5
claude (4/5): The prompt at [instruction.md:1-7] is dense but internally consistent: it names
every field, its default, the exact constructor parameter order for `ScanPeriods`, the exact
strategy class names and constructor signatures, the three `BeaconManager` methods and their
differing merge semantics, and the snapshot copy-independence contract. Minor ambiguities
remain (e.g., whether `Settings.Defaults` is a Kotlin `object` or a nested class, the exact
package for `DistanceCalculatorFactory` beyond 'same package as the DistanceCalculator', and
Builder method signature list qualified with 'at least'), but nothing material to success is
left undefined.
gpt (4/5): The prompt specifies the public API surface, field names, defaults, builder methods,
scan strategy variants, merge/reset semantics, and snapshot behavior in detail
[instruction.md:3-7]. Minor ambiguity remains around implementation-observable terms like
applying settings "as one transaction" and the exact extent of Java builder support because it
says the builder supports "at least" a subset of fields [instruction.md:3] while many
additional fields are listed.

oracle_no_gaming — 5.0/5
claude (5/5): The oracle is a real source patch of ~1100 lines implementing the described
Kotlin/Java API on the AltBeacon repository; there are no hardcoded expected values, no
fabricated tool outputs, and no reads from `tests/`. `solve.sh` simply applies the patch to
`/app` [solution/solve.sh:8-23] with an idempotent already-applied check and a 3-way fallback;
the answer is produced by legitimate cod
──── (172 lines hidden) ─────────────────────────────────────────────────────

[instruction.md:7].

test_faithfulness — 3.5/5
claude (5/5): Every asserted value maps directly to phrasing in [instruction.md]: field
names/defaults are quoted verbatim (e.g., regionExitPeriodMillis default 30000,
maxTrackingAgeMillis default 10000, distance URL default empty string), the
JobServiceScanStrategy default assertion [tests/tests.patch:179] is grounded in 'the default
strategy on Android 8+' combined with the @Config(sdk=28) runtime, snapshot independence checks
[tests/tests.patch:381-402] mirror the two-directional independence requirement, and the
0.1-meter tolerance on the default distance calc [tests/tests.patch:452,458] is loose enough to
match the prompt's 'preserve the distance calculation the library already performs today'. No
hidden output keys, no undocumented canonicalization, and the push-through targets are all
methods the instruction explicitly names ('reading such a property back off BeaconManager or
Beacon').
gpt (3/5): Most assertions are grounded in the prompt's exact field names, defaults, builder
setters, scan-period values, and BeaconManager methods [instruction.md:3-7]. One significant
hidden API requirement is that active settings/snapshots must provide a Kotlin `copy(...)`
method: the test mutates a snapshot via `beaconManager.activeSettings.copy(...)`
[tests/tests.patch:394-399], while the prompt requires only that snapshots be independent
copies and does not require `Settings` to be a data class or expose a `copy` method
[instruction.md:7].

Rationale (from driving judge):
The instruction requires all explicitly set fields to be applied through
`adjustSettings`/`replaceSettings` and existing static configuration to reflect just-applied
values [instruction.md:7], but `applySettingsChange` only pushes a subset and explicitly leaves
`longScanForcingEnabled`, `rssiFilterImplClass`, and `scanStrategy` as TODOs while also
omitting existing setters for `useTrackingCache` and `maxTrackingAgeMillis`
[solution/golden.patch:135-198]. The scan strategy API is present, but `JobServiceScanStrategy`
stores `immediateJobId`, `periodicJobId`, and `jobPersistenceEnabled` while `configure` ignores
those configured values [solution/golden.patch:739-761], so several named settings are
observable in snapshots but do not actually affect library behavior as required.

================================================================================

## Oracle Check

Oracle did not pass all runs: 0/3. Task may be flaky or has infra issues.
```

**The report arrived truncated** — 172 lines of per-axis justification were elided by the
paste. What is known about the hidden block comes from the round-2 session's own reading of it
before truncation: `oracle_spec_faithfulness` adjudicated **2.0** (claude 5, gpt 2) and
`test_coverage` **3.5**. Ask the submitter for the untruncated report if any decision turns on
an axis not quoted above.

| Axis | Adjudicated | Source |
|---|---|---|
| clarity | 4.0 | quoted above, up from 3.5 in round 1 |
| oracle_no_gaming | 5.0 | quoted above |
| **oracle_spec_faithfulness** | **2.0** | in the elided block, claude 5 / gpt 2 |
| test_coverage | 3.5 | in the elided block, up from 2.5 in round 1 |
| test_faithfulness | 3.5 | quoted above, claude 5 / gpt 3 |

## What moved since round 1

Round 1's edits worked on the axes they targeted. `test_coverage` went 2.5 → 3.5 and clarity
3.5 → 4.0, so the coverage gap that drove the round 1 DISCUSS is closed. The verdict got
**worse** anyway, DISCUSS → REMOVE, because a different axis collapsed:
`oracle_spec_faithfulness` 3.5 → 2.0.

**That is a drift finding on its own.** `docs/tasking-guide.md` says only the two test axes flip
the verdict. Here both test axes sit at 3.5, above the DISCUSS line, and the task was REMOVEd on
an oracle axis. Written up in `learning/quality-check-criteria.md`.

## Correction owed from round 1

Round 1 root-caused the oracle 0/3 to the non-idempotent `solve.sh` and wrote that up as fact in
`learning/solve-sh-idempotency.md`. **That causal claim is wrong**, on two independent grounds:

- `20260728_153118__jqno_equalsverifier__1166` ships the *old* reverse-apply script and its
  oracle passed 3/3 on the platform. The script was never the discriminator.
- 0/3 means run 1 failed too. The old script only breaks from the *second* invocation onward, so
  it would have produced 1/3 at worst, not 0/3.

The fix was still correct on its own merits — CLAUDE.md 10.6 mandates it and this round's judge
scores `oracle_no_gaming` 5/5 citing the new script by line — but it did not address the 0/3,
which reproduced identically after it. The note has been corrected.

## The feedback as a numbered item list (Step 10.2)

| # | Item | Source | Blocking | Action |
|---|---|---|---|---|
| 1 | Oracle 0/3 on the platform for the second round running, still passes locally | Oracle Check | **yes** | see the elimination table below |
| 2 | `applySettingsChange` leaves `longScanForcingEnabled` and `rssiFilterImplClass` on a TODO | oracle_spec_faithfulness, driving rationale | **yes** | pending decision, see the fork |
| 3 | `useTrackingCache` / `maxTrackingAgeMillis` never reach their existing setters | oracle_spec_faithfulness, driving rationale | **yes** | pending decision, see the fork |
| 4 | `JobServiceScanStrategy.configure` ignores `immediateJobId`, `periodicJobId`, `jobPersistenceEnabled` | oracle_spec_faithfulness, driving rationale | **yes** | pending decision, see the fork |
| 5 | The rationale also lists `scanStrategy` as a TODO | oracle_spec_faithfulness, driving rationale | no | **misreading, but self-inflicted.** `applySettingsChange` does call `settings.getScanStrategy().configure(this)`. The judge is reading the commented-out `//settings.getScanStrategy()` under `// TODO: apply all other settings`. Delete the stale TODO block whatever else is decided |
| 6 | Snapshot test depends on a `copy(...)` method the instruction never asks for | test_faithfulness (gpt) | no | real. Either state the capability in `instruction.md` or drop the dependency from the test |
| 7 | `Settings.Defaults` shape (Kotlin `object` vs nested class) left ambiguous | clarity (claude) | no | deliberate. The `Defaults.INSTANCE` example was cut in round 0 precisely because prescriptiveness P2 flagged it as revealing the `object` declaration. Leave it and document |
| 8 | Builder "supports at least" reads as open-ended | clarity (both judges) | no | deliberate. The five named setters are the graded contract; "at least" keeps a wider builder legal. Leave it and document |

## Oracle 0/3 — reproduction attempts, all negative

Five clean oracle runs across round 1 and round 2, three of them on an image cold-built
`--no-cache` from the uploaded zip. It will not reproduce here.

| Hypothesis | Measurement | Verdict |
|---|---|---|
| Non-idempotent `solve.sh` | equalsverifier ships the unsafe version and passes 3/3 | dead |
| Ungraded test flake against `allow_extra_failures = false` | suite reports exactly the 230 graded ids, no ungraded surface | dead |
| Locale or timezone | oracle under `TZ=UTC LANG=C LC_ALL=C`: reward 1, 230/230 | dead |
| Offline Gradle cache missing the deps `golden.patch` bumps | image cache holds core-ktx 1.12.0 and robolectric 4.11.1 | dead |
| Verifier timeout | oracle run is 30s against `execution.timeout_sec` 1500 | dead |
| `build_timeout_sec = 900` too low | cold `docker build --no-cache` exits 0 in 316s; `gradlew test` alone is 52s at the declared 4 cpus, so the 316s is download-bound | weak, not dead |
| Non-root execution | `--user 1000:1000` makes git refuse the repo outright, but that would break all four bundles and three pass | dead |
| Container `CMD` exiting | all four Dockerfiles have the same run-then-exit shape and Harbor overrides it | dead |

The one surface that cannot be tested from here is **the platform building the image itself**.
AltBeacon has by far the largest build-time network footprint of the four bundles (Android SDK
from dl.google.com, roughly 1.5 GB of Gradle cache, 400 MB of Robolectric jars) against the same
`build_timeout_sec = 900` as the lightest, and the verifier then runs `--offline`. A partial
cache from their builder fails silently at verify time with no XML, which grades 0 on every run
and is invisible from here. That is a hypothesis, not a finding.



## What round 2 did (this session, 2026-08-04)

The user's call was **hold the oracle-gap rewrite until the 0/3 is resolved**, and ship only the
free, no-risk items. So this round is deliberately small.

| File | Change |
|---|---|
| `task.toml` | `[environment] build_timeout_sec` 900 → **1800** (Section 8 ceiling) |
| `instruction.md` | snapshot sentence now states that adjusting a snapshot with `copy(...)`, naming just the fields to change, must not reach the live configuration either |
| `environment/problem_statement.md` | re-copied, md5 `d587d441b6dc` |
| `solution/golden.patch` | PR's `CHANGELOG.md` hunk added back at the top |
| `work/` and `download/original/` | `.gradle/` build-cache files deleted from **both** trees (they were back, 5 files each) |
| `environment/repo/.git` | reflog expired, gc, `FETCH_HEAD` and `refs/remotes` removed, `*.lock` swept |

`instruction.md` closes the `test_faithfulness` gpt 3/5 finding (item 6). `golden.patch` now
touches exactly the 14 non-test files PR 1177 touches, which closes the Step 2 item 9
cross-check in the omission direction.

**`build_timeout_sec` is the only thing shipped that could plausibly move the 0/3.** It is a
mitigation, not a fix, and it is free: this bundle downloads the Android SDK plus roughly 2 GB
of Gradle and Robolectric cache against the same 900 s budget the lightest bundle in the set
gets. Local cold build is 347 s with a warm base image and a good connection, and only 52 s of
that is Gradle at the declared 4 cpus, so nearly all of it is download time on someone else's
network.

### Round 2 verification (image built from the bundle, `--network none`, cpus=4, 8 GB)

| Check | Reward | Required | Exit | Time |
|---|---|---|---|---|
| NOP | 0 | 0 of 230 | 1 | 23 s |
| Oracle | **1** | **230 of 230** | 0 | 33 s of 1800 s |
| Hostile delete (stub the simulator push-through) | **0** | 229 of 230 | 1 | — |

Hostile delete names exactly one missing id, `theRemainingFieldsAreAppliedAndReadableBack`.

All 20 static checks pass against the **extracted zip**. Git: `fsck --unreachable` silent,
`.git` exactly the seven documented entries, HEAD at base, no remote, clean tree, 2.5 MB. Zip
rebuilt at `upload/`, unpacks to `instruction.md task.toml environment/ solution/ tests/`, no
`runs/`, no `task/` wrapper, `.git` and the empty `refs/` dir entries present, both scripts 0755,
no `.gradle` and no strays. `tests/` holds only `config.json test.sh tests.patch`.

### New environment hypotheses tested and eliminated this round

Added to the table above. All against an image cold-built from the uploaded bundle.

| Hypothesis | Measurement | Verdict |
|---|---|---|
| 8 GB cap with no swap to fall back on | `--memory=8g --memory-swap=8g` | reward 1, 230/230 |
| CPU starvation | `--cpus=1` | reward 1, 230/230 |
| Container hostname not resolvable (Java `InetAddress.getLocalHost()`) | `--hostname sandbox-xyz` + hosts entry deleted, confirmed non-resolving | reward 1, 230/230 |
| Small `/tmp` (Robolectric extracts jars there) | `--tmpfs /tmp:size=64m` | reward 1, 230/230 |
| Three oracle runs sharing one container | solve+test twice in one container | reward 1, 230/230 |
| Image exceeds `storage_mb = 10240` | image is **2.98 GB** | dead |

That is 6 more shapes on top of the 8 already ruled out. Nothing reproduces.

## NEW finding — the test-tree restore in `test.sh` is inert on the platform

Found while re-reading `learning/tests-patch-vs-agent-edits.md`, which was updated 2026-08-04
after kvdex 245 spent five rounds on exactly this.

Round 0's finding 6 shipped a restore in `tests/test.sh`:

```
if command -v git >/dev/null 2>&1 && [ -d .git ]; then
  git checkout -- lib/src/test/ ... || true
  git clean -fdq lib/src/test/ ... || true
fi
```

**The platform's verify-time workspace is not a git repository** (kvdex reproduced it locally;
four independent codex trial analyses on equalsverifier 1166 name the mechanism in words). So
the `[ -d .git ]` guard fails, the restore is skipped, and an agent that wrote its own
`SettingsTest.kt` still kills the trial with `tests.patch did not apply`. It is also defeated by
an agent that merely stages, because a bare `git checkout --` reads the index.

Every local scenario passes, which is why it was believed for two rounds.

**The fix is not free**, so it is not in this round. `tests.patch` already creates both graded
files, so the cheap half (delete the patch's target paths before applying) would fix the
infra-error case. But 210 of the 230 graded ids live in files `tests.patch` never touches, and
`learning/static-checks.md` is explicit that anything over zero there means create-only is not
sufficient on its own — those 210 would run the agent's own copies. The design that works is a
base64 archive of `lib/src/test` embedded in `test.sh`, because `tests/` accepts only four
filenames. That is a real piece of work and it is queued behind the 0/3.

## Slack escalation text (0/3), ready to paste

```
Task: 20260727_135618__AltBeacon_android-beacon-library__1177
Submission UID: a1bcc8a9-8c08-4a41-83c2-6659dff2978b

Error, byte-identical on two consecutive uploads (2026-08-02 and 2026-08-03):
  Agent Runner Summary: Evaluation FAILED. Validation failed: Oracle did not pass
  all runs: 0/3. Task may be flaky or has infra issues.
Both the Difficulty Check and the Oracle Check print that line and nothing else.

Intermittent? No. Two uploads, 6 platform oracle runs, 0 passes. Fully consistent,
so this is not the inconsistency that marks a transient outage.

Notable: my three other bundles on this harness (kvdex 245, equalsverifier 1166,
libcrux 1165) all report oracle 3/3. AltBeacon is the only 0/3 of the four.

Reproduces locally? No, not once. ~25 oracle runs across three rounds, including
runs on an image cold-built --no-cache from the uploaded zip, all reward 1.0 with
230/230 required tests and exit 0. Ruled out by measurement: solve.sh idempotency,
ungraded test flake vs allow_extra_failures=false, locale/timezone, the offline
Gradle cache, verifier timeout, non-root execution, container CMD, hard 8 GB with
no swap, 1 cpu, non-resolving hostname, 64 MB /tmp, three runs sharing one
container, /app with no .git at all, and /app with the git binary deleted.

Since it will not reproduce, I stopped diagnosing and removed the dependencies
instead. solve.sh no longer uses `git apply --3way` (the one git path needing a
recognised repo, which errors as "'--3way' outside a repository" when git declines
the workspace) and falls back to patch(1). test.sh no longer restores the test tree
with git. Both verified against a workspace with no .git and with git deleted from
PATH: reward 1, 230/230.

One git dependency I can see but am not permitted to change: environment/Dockerfile
line 73 restores lib/build.gradle with `git checkout --` after warming the bumped
dependency set. If that ever failed on your builder, the image would ship with
build.gradle already bumped, golden.patch would not apply cleanly, and solve.sh
would exit 1 on every run. I reproduced that shape deliberately and it does exactly
that. Swapping it for a plain `cp` is one line, but Dockerfile edits are limited to
the allowed-fix table, so I have left it. Worth checking from your side.

What I think is worth checking on your side: this bundle has the largest build-time
network footprint of anything I have submitted. environment/Dockerfile pulls the
Android command line tools and platforms;android-34 from dl.google.com, then warms
~2 GB of Gradle and Robolectric cache so the verifier can run `gradlew --offline`.
If any warm step comes up short on the builder, the offline test run produces no
JUnit XML and grades 0 on every run, with no distinguishing error. build_timeout_sec
was 900 (my cold build is 347s locally, almost all download); I have raised it to
1800. Could someone check whether the image build for this task is completing, and
whether the verifier's `gradlew --offline` step is resolving?
```

## Open

- **Handling times.** The "all revisions" field still reads 55 minutes from round 0. Rounds 1
  and 2 both added real work and 55 is already under the 60 to 120 band. Needs a fresh number
  from the submitter. The other three fields are first-pass numbers and do not move.
- **The oracle-gap rewrite is held**, pending the 0/3. Two options are worked out and costed in
  the round 2 notes above. Recommendation is narrowing the instruction explicitly plus grafting
  upstream master's `rssiFilterImplClass` wiring, since upstream itself never applied the other
  three fields or the job ids.
- **The `test.sh` restore rewrite is held**, same reason. See the finding above.
- Post-fix confirmation box 6 ("the oracle implements the solution following the instructions")
  is the one the panel disputes. Flagged in `answers/submission_answer.txt` right above the
  checklist so nobody ticks it without knowing.
- Not changed: the grader records `raw_exit_code` without branching on it. It fails closed in
  practice because the test command clears `lib/build/test-results` first.

---

## Round 2, continued — after the learning log was updated (2026-08-04)

kvdex 245 was accepted and `learning/` plus `CLAUDE.md` gained two notes that change what to do
here: `diagnosing-platform-only-failures.md` and `accepted-bundle-reference.md`.

**The two-strikes rule applies to this task and says stop diagnosing.** CLAUDE.md 489: when a fix
verified locally comes back failing a *second* time, stop refining the theory and remove the
dependency instead. The round-over-round trend here is `0/3 → 0/3`, a flat line across a
locally-verified fix, which is the exact signal kvdex ignored for two rounds.

### Evidence pass before any more fixing (the hierarchy in the new note)

| Tier | What it gave |
|---|---|
| Own local reproduction | 14 oracle runs, 14 rewards of 1. Proves sufficiency of nothing |
| Round-over-round trend | `0/3` then `0/3`. Flat. The fix did not touch the cause |
| Own difficulty artifact | none exists — the oracle gate fails before agent trials run |
| **Sibling task reports** | **kvdex, equalsverifier and libcrux all report oracle 3/3 on this harness.** AltBeacon is the only 0/3 of four bundles |

### Six more conditions tested, all negative

| Condition | Result |
|---|---|
| `/app` has no `.git` at all | oracle reward **1**, 230/230 |
| Running as uid 1000 against a root-owned `/app` | `solve.sh` exits 1, `'--3way' outside a repository`. Would break all four bundles, three pass |
| `patch -p1 --forward` instead of git | applies `golden.patch` cleanly with no `.git`, exit 0 |
| `lib/build.gradle` already bumped (Dockerfile's `git checkout` restore failed) | `solve.sh` exits **1**. The only condition found that makes the oracle path exit nonzero |
| Hard 8 GB with no swap, 1 cpu, non-resolving hostname, 64 MB `/tmp` | all reward 1 |
| Image size against `storage_mb = 10240` | 2.98 GB |

### What was removed rather than diagnosed

**`solution/solve.sh` — no longer depends on git.** `git apply --3way` is the one git path that
needs a recognised repository; it is what errors under dubious ownership. Now: reverse-check with
git then with `patch` for idempotency, forward apply with `git apply` (atomic) falling back to
`patch`, loud exit 1 otherwise, and no `--3way` anywhere.

**`tests/test.sh` — the test-tree restore no longer depends on git.** The git-based restore
shipped in round 0 is guarded by `[ -d .git ]`, so on the platform it is skipped exactly when it
matters. Replaced with the platform-confirmed design from `tests-patch-vs-agent-edits.md`: a
gzipped tarball of `lib/src/test`, base64'd into a quoted heredoc inside `test.sh`. Also dropped
`git apply --3way` from the `tests.patch` block.

Measured with the corrected script in CLAUDE.md 10.3: **210 of 230 graded ids live outside the
patched files** (f2p 0 of 20 outside, p2p 210 of 210, across 30 classes). Anything above zero means
create-only is not sufficient and the whole tree has to be restored. Payload: 32 files, 292 KB →
24.5 KB tarball → 33 KB base64, taking `test.sh` from 19 KB to 53 KB. Verified by pulling the
payload back out of the **zipped** `test.sh`, decoding and diffing against the shipped base tree:
identical.

### Verification battery — 5 agent-hostile rows against 2 clean

| Scenario | Reward | Required | Exit |
|---|---|---|---|
| NOP | 0 | 0 of 230 | 1 |
| Oracle, clean tree | 1 | 230 of 230 | 0 |
| Agent wrote its own `SettingsTest.kt` | **1** | 230 of 230 | 0 |
| Agent **committed** that file and deleted `AltBeaconParserTest.java` | **1** | 230 of 230 | 0 |
| `.git` removed entirely | **1** | 230 of 230 | 0 |
| `git` binary removed from PATH | **1** | 230 of 230 | 0 |
| Hostile delete (stub the simulator push-through) | **0** | 229 of 230 | 1 |

The committing-agent row is the one the git restore could never pass: it deletes a `pass_to_pass`
class and the payload restore brings it back. Hostile delete names exactly
`theRemainingFieldsAreAppliedAndReadableBack`.

**The NOP was read for the right reason, not just for a reward of 0.** `test-stdout.txt` is 4525
bytes, not empty, and shows `compileDebugUnitTestKotlin FAILED`. The whole test source set fails
to compile at base because `Settings` does not exist, so no f2p test can run at all. Genuineness
of the 20 f2p ids rests on the round-0 symbol audit, not on this run.

### The one git dependency left, and why it stays

`environment/Dockerfile:73` restores `lib/build.gradle` with `git checkout --` after warming the
bumped dependency set. If that failed on the platform builder the image would ship with
`build.gradle` already bumped, `golden.patch` would not apply cleanly, and `solve.sh` would exit 1
every run. That was tested and reproduces exactly. Swapping it for a `cp` from a pre-`sed` backup
is a one-line, zero-risk change, but it is **not on the allowed-fix table** in
`docs/guidelines.md`, and there is no evidence the platform strips `.git` from the build context
(the bundle ships no `.dockerignore` and `COPY repo/ .` carries `.git`). Flagged to the reviewer
and in the Slack escalation rather than changed unilaterally.

### Bundle state

Zip rebuilt with `zip -rXy`, md5 `f2325ba2b4d4059796db92c412ef17c2`. All 20 static checks pass
against the extracted zip. Git: `fsck --unreachable` silent, `.git` exactly the seven documented
entries, HEAD at base, clean tree, no symlinks, `gradlew` 0755, both scripts 0755.

---

## Round 2, continued — every outstanding feedback item taken (2026-08-04)

The submitter's call changed from "hold the oracle gap" to "fix all the items in this revision".
Everything previously held or refused has now been done, except two prescriptiveness findings that
cannot be taken without breaking a blocking check.

### The REMOVE, closed by finishing the PR's own TODO

Chose oracle extension over instruction narrowing. Narrowing had already failed once (round 1) and
the honest narrowed wording would have described a configuration API where four of its own fourteen
fields do nothing.

| Field | Now applied via | Read back in tests by |
|---|---|---|
| `rssiFilterImplClass` | `BeaconManager.setRssiFilterImplClass` | `BeaconManager.getRssiFilterImplClass()` |
| `useTrackingCache` | `BeaconManager.setUseTrackingCache` | `RangeState.getUseTrackingCache()` |
| `maxTrackingAgeMillis` | `setMaxTrackingAge` | `RangedBeacon.maxTrackingAge` |
| `longScanForcingEnabled` | **new** static on `BeaconManager`, read by `BeaconService` | `BeaconManager.getLongScanForcingEnabled()` |
| `immediateJobId` / `periodicJobId` | `ScanJob.setOverride*ScanJobId` from `JobServiceScanStrategy.configure` | `ScanJob.getImmediateScanJobId(context)` / `getPeriodicScanJobId(context)` |
| `jobPersistenceEnabled` | **new** flag on `ScanJob`, read by `ScanJobScheduler` | `ScanJob.getJobPersistenceEnabled()` |

The `// TODO: apply all other settings` block is gone. **`golden.patch` was regenerated from the
base commit, not hand-edited**, so no hunk header was written by hand.

**PR scope is now expanded and must be declared.** `golden.patch` touches 15 files where PR 1177
touches 14. The extra one is `ScanJobScheduler.java`, three sites, each a single argument
(`setPersisted(true)` → `setPersisted(ScanJob.getJobPersistenceEnabled())`). Everything else lives in
files the PR already touches. Checked AltBeacon master first: upstream still has not finished this
TODO ten months on, so it is a genuine addition rather than a later commit that could be grafted.

### Everything else the feedback raised

| Item | Done |
|---|---|
| `ForegroundServiceScanStrategy.equals` ignores `notification` | included in `equals` and `compareTo`. Safe because `clone()` passes the same reference, so read-back still compares equal. Test covers all three cases |
| `1.0 ± 0.1` distance figure pinned | gone from all three sites, replaced by a comparison against the library's own `ModelSpecificDistanceCalculator` to 0.0001 |
| Broad `pass_to_pass` with `allow_extra_failures: false` | kept at 210, and the instruction now earns it by saying this is an addition rather than a replacement and naming the behaviour that must survive |
| clarity: `scanStrategy` type unstated | now "a `Settings.ScanStrategy`, described below" |
| clarity: `Settings.Defaults` shape ambiguous | now explicitly the implementer's choice |
| clarity: Builder "supports at least" | now "provides at minimum these five, and may provide more" |
| Grader never branched on `raw_exit_code` | command propagates gradle's status; `success` requires `raw_exit_code == 0`. Gradle's bare exit measured on a green tree first (0, 230 tests). Gated in the success expression, not via an early `infrastructure_error` |
| `Dockerfile:73` `git checkout` dependency | `cp` to `/tmp` before the sed and back afterwards. Cold build 307 s, exit 0 |
| prescriptiveness P2 | taken, snapshot sentence now uses the checker's own suggested phrasing |

### Refused, and why it is a hard constraint rather than a preference

**Prescriptiveness P1 and P3 only.** They want the `Settings.Builder` paragraph and the
`Settings.Defaults` name out of `instruction.md`. Twenty graded tests call the builder and its five
setters by name; there are 15 references to `Settings.Defaults`. Cutting either moves the problem
onto `test_faithfulness`, which blocks where prescriptiveness does not. This is the rule in
`learning/quality-check-criteria.md` verbatim.

### Verification, 8 scenarios, 5 of them agent-hostile

| Scenario | Reward | Required | raw_exit |
|---|---|---|---|
| NOP | 0 | 0 of 230 | **1** (the new gate) |
| Oracle, clean tree | 1 | 230 of 230 | 0 |
| Agent wrote its own `SettingsTest.kt` | 1 | 230 of 230 | 0 |
| Agent committed it and deleted `AltBeaconParserTest.java` | 1 | 230 of 230 | 0 |
| `.git` removed | 1 | 230 of 230 | 0 |
| `git` binary removed from PATH | 1 | 230 of 230 | 0 |
| `solve.sh` 3x then verify | 1 | 230 of 230 | 0 |
| Hostile delete | 0 | 229 of 230 | **1** |

**The oracle extension carried a real regression risk and did not fire.** Applying
`useTrackingCache` and `maxTrackingAgeMillis` moves `RangeState.sUseTrackingCache` false→true and
`RangedBeacon.maxTrackingAge` 5000→10000 against base, and the ScanJob overrides are now set on every
apply. All 210 `pass_to_pass` ids still pass.

NOP read for the reason, not the reward: `test-stdout.txt` 4525 bytes ending at
`compileDebugUnitTestKotlin FAILED`. Genuineness of the 20 f2p ids still rests on the round-0 symbol
audit.

Re-verified against the **extracted zip**: NOP 0 / raw_exit 1, oracle 1 / 230 of 230 / 31 s,
oracle+collision+no-`.git` 1 / 230 of 230. All 20 static checks pass there. Payload still round-trips
out of the zipped `test.sh` byte for byte. Zip md5 `0c570bde935ad782b5ef0d90cec874b9`.

### Still not fixed

**The oracle 0/3.** Cause never found. Every git dependency on the oracle and verify path has now
been removed (`solve.sh`, `test.sh`, `Dockerfile`), plus `build_timeout_sec` raised to the 1800
ceiling. None of it is a demonstrated fix. Escalation text is above and still applies.

---

## Round 3 — feedback of 2026-08-04 (judge PASSED, screen blocked on the oracle)

```
Agent Runner Summary: Evaluation FAILED. Review gate blocked at the difficulty screen (cheap single-arm rollout)
Blocked at the difficulty screen (cheap single-arm rollout).
This eval runs two checks in order — the agentic judge, then the difficulty screen — and the screen
runs only if the judge passed.
Oracle did not pass all runs: 0/3. Task may be flaky or has infra issues.
```

**The agentic judge passed.** The screen only runs if it did, so the REMOVE and the
`oracle_spec_faithfulness` 2.0 are cleared by the part-3 work. The oracle 0/3 is the only thing
left, and it is now the sole blocker.

### Three more hypotheses killed, none of them shipped as a fix

| Hypothesis | Measurement | Verdict |
|---|---|---|
| Different `HOME` moves the offline cache | **false negative first time**, see below. Re-probed properly | see next section |
| `storage_mb` blown by vfs layer duplication (28.35 GB of full snapshots against a 10.24 GB limit) | libcrux is **30.52 GB** on the same arithmetic and passes 3/3 | dead |
| `local.properties` is untracked, gitignored, and written only by the Dockerfile, so a fresh workspace would lack it. **AltBeacon is the only one of four bundles that writes any file into the workspace at build time** | deleted it and ran the oracle: reward 1.0. AGP falls back to the `ANDROID_HOME` env var | dead |

The `local.properties` one looked like the differential and was not. Worth recording because the
differential was real (only this bundle writes a build-time workspace file) and the conclusion
still did not follow.

### The false-negative probe, and what it hid

The first `HOME` probe ran `-e HOME=/tmp/otherhome`, got reward 1.0, and the hypothesis went in the
dead column. It was worthless:

```
shell HOME     = /tmp/otherhome
java user.home = /root            <- Gradle never looks at $HOME
```

Probing what Gradle actually reads kills the run outright:

```
$ GRADLE_USER_HOME=/tmp/nowhere ./gradlew --no-daemon --offline -q help
Exception in thread "main" java.net.UnknownHostException: services.gradle.org
exit=1
```

Move Gradle's home and the wrapper cannot find the Gradle distribution, tries to download it, and
dies because the verifier has no network. Before a single test runs, identically every time.

**Fix: `ENV GRADLE_USER_HOME=/opt/gradle-home`**, set before any Gradle invocation so the build
warms the caches there and the verifier reads them from there whatever `user.home` resolves to.
This matches the accepted bundle, which pins `DENO_DIR=/deno-dir`. Of the four bundles, this was the
only one leaving its offline cache under `~`.

**Not claimed as the cause.** It is a way for the verifier to fail on every run that I could
remove, and it is gone. Written up in `learning/diagnosing-platform-only-failures.md`.

### Considered and deliberately not shipped

A `chmod -R a+rwX` over the caches and `/app`, to survive a non-root uid. Measured: it fixed
`solve.sh` under `--user 1000:1000` but the tests still failed, because Robolectric's jars follow
`user.home` too. A non-root verifier would break all four bundles and three pass, so the scenario is
not in play. It also cost 1.4 GB when placed in its own layer (2.98 GB → 4.92 GB) because a
recursive chmod rewrites every file into a fresh layer. Dropped; the pin alone is 2.98 GB.

### Verification on the pinned image

| Scenario | Reward | raw_exit |
|---|---|---|
| NOP | 0 | 1 |
| Oracle | 1, 230 of 230 | 0 |
| Agent wrote its own `SettingsTest.kt` | 1, 230 of 230 | 0 |
| Agent committed it and deleted a `pass_to_pass` class | 1, 230 of 230 | 0 |
| `.git` removed | 1, 230 of 230 | 0 |
| `git` binary removed | 1, 230 of 230 | 0 |
| Hostile delete | 0, 229 of 230 | 1 |
| No `local.properties`, `solve.sh` 3x | 1, 230 of 230 | 0 |

Cold `--no-cache` build 360 s of 1800 s. Image 2.98 GB. Zip md5 `9e303baf07f53231f7ee62185d972369`.

### What would end this

Local reproduction is exhausted: roughly 35 oracle runs across every environment shape I can
construct, all reward 1. Per the evidence hierarchy in
`learning/diagnosing-platform-only-failures.md`, the next tier is the platform's own artifact.
**Ask the submitter for the downloadable difficulty-check results for this run.** It carries the
verifier's stdout and stderr from the platform side, which would name the failure in one step
instead of another round of inference from outside.

---

## Round 4 — feedback of 2026-08-05 (DISCUSS, oracle_spec_gap 3.0)

Judge report attached this time. **Citations checked against the bundle before any work**, per the new
habit: `golden.patch` 1247 lines, `solve.sh` 52 with the reverse dry-run at 30-38,
`tests.patch:560-562` the ScanJob assertions added in round 2. It describes the current bundle.

Movement since round 2: `oracle_spec_faithfulness` 2.0 → **3.0**, `oracle_robustness` 3.5 → **5.0**
(both judges), `test_faithfulness` → 4.5, `packaging`/`realism`/`oracle_no_gaming` 5.0. Still bounces,
because 3.0 rounds down.

### The two oracle claims, both verified before acting

| Claim | Verified how | Verdict |
|---|---|---|
| `applySettingsChange` pushes every managed field, so a prior direct static-setter call is overwritten | read the patch: the pushes are unconditional | **true, and self-inflicted** in round 2 |
| The transaction promise is broken by `Handler.postDelayed` rebinding bound consumers after the call returns | `grep -c postDelayed /tmp/pr1177.diff` → present in the upstream PR | **true and PR-inherited → SPEC GAP** |

Both fixed in `instruction.md`, neither in the oracle. Extending the oracle for the second would be
rewriting PR behaviour rather than completing a TODO, which is the distinction
`learning/source-pr-cross-check.md` draws.

**This is the second narrowing on this axis and the first one failed**, so this time every
unimplemented item was walked against the new wording by hand, which is the step the skill says the
first attempt skips.

### What changed

| File | Change |
|---|---|
| `instruction.md` | three headed sections instead of one wall; "unset" defined as absent and null; the transaction guarantee stated concretely **and** the async rebind admitted; the existing configuration each field writes through to enumerated; blanket backward-compatibility replaced with the ownership rule |
| `tests/tests.patch` | scheduler state asserted for all four scan strategies, not just JobService; `manifestCheckingDisabled` push-through and revert; beacon-simulator assertion relaxed to "no simulator or an empty one" |
| `environment/repo/.gradle` | reappeared (dated 2026-08-04 20:50) and removed from **both** trees again. Never reached a zip |

### Quality Check rehearsal, run locally before zipping

```
Status: ✅ OK (rehearsal)
Axes    oracle_spec_faithfulness 4   both claims now stated in instruction.md
        test_coverage            4   both gpt gaps closed, hostile delete confirms
        test_faithfulness        5   both claude nits relaxed to the stated requirement
        clarity                  4   3 sections, unset + transaction defined
        self_containedness       4   configuration surface now enumerated
        packaging                5   .gradle removed, fsck silent, tests/ has 3 files
        oracle_no_gaming 5 | oracle_robustness 5 | realism 5 | prescriptiveness 4
Q9      2 placement sentences kept deliberately, convention measured as strong, declared
Q10     3 long literals added by tests.patch; 0 appear in instruction.md
```

Labelled as a reading, not a measurement, on every axis except `test_coverage`, which the hostile
delete backs.

### Verification

Oracle 230/230 raw_exit 0; NOP 0 with raw_exit 1; agent-collision + no-`.git` 230/230; hostile delete
0 naming `theRemainingFieldsAreAppliedAndReadableBack`. All 20 static checks pass on the extracted
zip, and NOP and oracle re-confirmed there (32 s). Symlinks in zip 0 = symlinks in work 0. Zip md5
`63752048223394b297c551131f6f2c04`.

### Still open

The oracle 0/3, unchanged and undiagnosed. Every git dependency on the path is gone,
`GRADLE_USER_HOME` is pinned, `build_timeout_sec` is at the 1800 ceiling. The difficulty artifact for
one of these runs is still the piece of evidence that would end it.

---

## Round 5 — feedback of 2026-08-05 (DISCUSS, coverage_gap)

### Freshness check before touching a file

| Axis | Result |
|---|---|
| Test ids | every id the report reasons about resolves in the round 4 `tests/config.json`. It cites `tests.patch` ranges up to `:586` against a 586-line patch |
| Line numbers | `[instruction.md:1]`, `:5`, `:9`, `:13` against a 13-line file with paragraphs at exactly those lines. `[solution/solve.sh:30-38]` is the reverse-apply probe, still at 30-38. `[solution/golden.patch:562-923]` sits inside 1247 lines |
| Commands | the gradle invocation it describes matches `execution.commands` as uploaded |
| Instruction text | every phrase it quotes was present in the round 4 `instruction.md` |

Fresh, and it describes upload 8. Recorded before any edit.

### Verbatim feedback

```
## Automated feedback

Agent Runner Summary: Evaluation FAILED. Review gate blocked at the agentic judge

## Difficulty Check

Blocked at the agentic judge. Not run: difficulty screen (cheap single-arm rollout).

This eval runs two checks in order — the agentic judge, then the difficulty screen — and the screen runs only if the judge passed. The full difficulty rollout is a separate check that runs after a reviewer accepts the task.

Agentic judge verdict: discuss (coverage_gap). See the agentic judge report for what to fix, then resubmit.

## Agentic Judge Quality Report

================================================================================
AGENTIC JUDGE REVIEW: task
================================================================================

Status: ⚠️ DISCUSS
Reason: coverage_gap

Per-axis review (rating out of 5, with judge justifications):

clarity — 3.5/5
claude (3/5): The instruction is dense prose packed into three long
paragraphs ([instruction.md:5], [instruction.md:9], [instruction.md:13])
covering many named fields, defaults, method signatures, and semantics.
Requirements are largely explicit (field names, default values, three
method behaviours, transaction semantics), but the wall-of-text format
makes it easy to miss requirements; a few points are only briefly stated
(e.g. `scanPeriods` default type, `Settings.copy(...)` semantics on
snapshots, exactly which fields the `Builder` must minimally expose vs
may expose more) leaving a couple of small interpretive gaps that a
competent agent must guess at.
gpt (4/5): The prompt precisely names the public API surface and required
semantics: optional delta fields and Java builder methods
[instruction.md:5], scan strategy implementations and equality behavior
[instruction.md:9], and the three BeaconManager application methods with
merge/reset behavior [instruction.md:13]. One minor ambiguity remains
around defaults for platform-specific scan strategy behavior beyond the
statement that JobService is default on Android 8+ [instruction.md:9],
so success is not quite crystal clear.

oracle_no_gaming — 5.0/5
claude (5/5): `solution/solve.sh` [solution/solve.sh:19-52] applies
`/solution/golden.patch` idempotently via `git apply` with a `patch(1)`
fallback; the patch contains a real ~1200-line implementation of the
Settings API (new `Settings.kt`, `DistanceCalculatorFactory.kt`, wiring
in `BeaconManager.java`, `BeaconService.java`,
`IntentScanStrategyCoordinator.kt`, etc.). No hardcoded answers, no
fabricated tool output, no reading of tests-side ground truth — this is
the "apply a reference patch" pattern the rubric explicitly allows.
gpt (5/5): The oracle is a source patch application, not a canned
expected-output writer: `solve.sh` only checks and applies
`/solution/golden.patch` [solution/solve.sh:22-48], and the patch
contains real API and behavior changes such as `Settings.kt`, scan
strategies, and `BeaconManager` wiring [solution/golden.patch:562-923].
I did not find test-ground-truth reads, fabricated tool output, or
hardcoded task-answer artifacts.

oracle_robustness — 4.5/5
claude (5/5): `solution/solve.sh` [solution/solve.sh:19-52] is
deterministic: it `cd /app`, checks reverse-application to detect an
already-applied tree [solution/solve.sh:30-38], then forward-applies via
`git apply` with `patch` as fallback [solution/solve.sh:41-49]. No
network calls, no background processes, no RNG, no time-of-day
dependencies, no undocumented env-var reads, no FD leaks. The Dockerfile
pre-warms Gradle caches [environment/Dockerfile:47-83] so no runtime
network dependency exists.
gpt (4/5): The oracle application path is deterministic and local: it uses
`git apply` or `patch` with an already-applied check
[solution/solve.sh:29-48], with no network calls, RNG, background
processes, or environment-variable dependencies. A minor robustness
concern is that the produced library uses delayed polling for rebinding
consumers during scan-strategy changes [solution/golden.patch:220-236],
but this does not make the patch application itself flaky.

oracle_spec_faithfulness — 2.5/5
claude (4/5): The patch introduces `Settings`
[solution/golden.patch:619-716] with every named field and default
(regionExitPeriodMillis=30000, maxTrackingAgeMillis=10000,
useTrackingCache=true, distanceModelUpdateUrl="", etc.), `ScanPeriods`
positional constructor with named params
[solution/golden.patch:767-772], `Settings.Builder` with the five spec-
mandated setters [solution/golden.patch:718-763], all four
`ScanStrategy` classes with equality [solution/golden.patch:781-916],
`DistanceCalculatorFactory` in the `distance` package
[solution/golden.patch:925-937],
`adjustSettings`/`replaceSettings`/`revertSettings` as transactional
deltas [solution/golden.patch:130-146], write-through to legacy
configuration [solution/golden.patch:147-219], strategy-change rebind
[solution/golden.patch:184-201], and `getActiveSettings()` returning a
Kotlin `data class` (thus supporting `copy(...)`)
[solution/golden.patch:245-247, 579-594]. Minor nits: several
`compareTo` implementations return -1 unconditionally on non-matching
type where `equals()` carries the actual spec contract, and the Builder
omits setters for many optional fields (spec says "at minimum these
five, may provide more", so acceptable).
gpt (2/5): The solution implements much of the requested surface—nullable
delta fields and defaults [solution/golden.patch:619-707], a Java
builder with the five required setters [solution/golden.patch:718-763],
scan strategies [solution/golden.patch:773-923], and `BeaconManager`
methods [solution/golden.patch:123-247]. However, there are multiple
significant spec gaps: the `Settings.Defaults` Kotlin object lacks Java-
friendly static field exposure for non-`const` defaults despite the
requirement that defaults read as
`Defaults.distanceModelUpdateUrl`-style from both Kotlin and Java
[instruction.md:5] [solution/golden.patch:693-715]; `ScanStrategy` is a
public interface rather than a closed set [instruction.md:9]
[solution/golden.patch:773-780]; switching to non-foreground strategies
does not clear the existing foreground-service notification, so the
strategy may be recorded without fully taking effect
[solution/golden.patch:834-875]; and the patch changes unrelated
existing behavior such as `Identifier.parse(null)` returning null,
contrary to the requirement that existing behavior remain unchanged for
callers not using the new API [instruction.md:13]
[solution/golden.patch:441-445].

packaging — 5.0/5
claude (5/5): Directory is clean: no developer cruft (`__pycache__`,
`.DS_Store`, `.ruff_cache`, `.venv`, IDE folders) appears in
[_DIRECTORY_LISTING.txt]; the `.git/`, `.circleci/`, `.github/`,
`.gitignore` entries at [_DIRECTORY_LISTING.txt:11-38] belong to the
upstream `android-beacon-library` repo the agent works against and are
legitimately shipped by [environment/Dockerfile:34]. Metadata in
[task.toml:3-28] accurately describes the Kotlin/Android implementation
task in [instruction.md:1] — tags (`android`, `kotlin`, `builder-
        pattern`, `configuration-api`, `beacon-scanning`) match,
`difficulty="hard"` vs `model_difficulty="medium"` is only one step
apart and consistent with the `0/3` pass rates on both frontier models,
and the resource limits at [task.toml:30-48] are plausible for a
Gradle/Android build.
gpt (5/5): Standard task files are present, with `instruction.md`,
`task.toml`, `environment/`, `solution/`, and `tests/` all listed [
_DIRECTORY_LISTING.txt:178-184 ]. The metadata matches the task: it
describes a Kotlin Android beacon-library implementation feature with
relevant tags [task.toml:9-17], consistent with the requested new
`Settings`/`BeaconManager` configuration API [instruction.md:1-13]; the
hard vs medium difficulty is only a one-step divergence
[task.toml:16-19]. The Dockerfile copies only `environment/repo/` into
`/app` [environment/Dockerfile:33-35], and the listing shows no
cache/IDE/virtualenv artifacts or solution/expected-output files inside
that copied tree [ _DIRECTORY_LISTING.txt:9-177 ].

prescriptiveness — 5.0/5
claude (5/5): The prompt specifies contract (field names 'matching the
names used below exactly', defaults, method signatures like
`adjustSettings`/`replaceSettings`/`revertSettings`, equality semantics,
transaction semantics, backward-compatibility constraint) but explicitly
leaves implementation shape open: 'How you shape that holder is up to
you as long as the defaults read that way from both Kotlin and Java'
([instruction.md:5]). There is no ordered step list, no file
localization hints, no named helper libraries — everything specified is
output/behavioural requirements, not procedure.
gpt (5/5): The instruction is mostly a requirements contract: it mandates
API names, fields, default values, merge semantics, and observable
behavior rather than a sequence of implementation steps
[instruction.md:5-13]. It does tell the solver where the API should live
and where to attach methods (`org.altbeacon.beacon`, `BeaconManager`)
[instruction.md:1] [instruction.md:13], but those are public API
requirements rather than file-localization hints, so it remains
minimally prescriptive.

realism — 5.0/5
claude (5/5): Task is drawn from a real merged PR (#1177 in
AltBeacon/android-beacon-library, cited in [task.toml:14]) with the full
repository present in [environment/repo/]. The prompt reads like a
design/RFC for a v3.0 configuration API on a real Kotlin/Java Android
library, discussing manifest declarations, static fields on
`BeaconManager`, scan strategies, ranging/monitoring lifecycle —
indistinguishable from a real ticket ([instruction.md:1]).
gpt (5/5): This is a realistic feature ticket for a real Android/Kotlin
library: the environment contains an Android Gradle library module using
Kotlin and Android SDK 34 [environment/repo/lib/build.gradle:1-14], and
the prompt asks for a coherent configuration API over existing beacon
scanning settings [instruction.md:1]. The repository includes the
concrete existing classes the ticket names, such as `BeaconManager` in
package `org.altbeacon.beacon` [environment/repo/lib/src/main/java/org/a
ltbeacon/beacon/BeaconManager.java:24-60] and `DistanceCalculator` [envi
ronment/repo/lib/src/main/java/org/altbeacon/beacon/distance/DistanceCal
culator.java:1-12], making it look very close to a real PR request.

self_containedness — 4.0/5
claude (4/5): The full repository is staged at [environment/repo/] and
every referenced type (`BeaconManager`, `Beacon`, `DistanceCalculator`
at [environment/repo/lib/src/main/java/org/altbeacon/beacon/distance/Dis
tanceCalculator.java], `BeaconSimulator`, RSSI filters) is present so
the agent can inspect existing state and configuration surfaces. The
instruction does lean on implicit knowledge of the library's current API
surface (which static setters exist, where region exit period lives
today, what the 'running-average rssi filter the library already falls
back to today' is) which the agent must discover from the repo rather
than the prompt — a minor lean, not a material gap.
gpt (4/5): The referenced codebase and named artifacts are present:
`BeaconManager` exists with Android scanning imports and service
dependencies [environment/repo/lib/src/main/java/org/altbeacon/beacon/Be
aconManager.java:24-60], the distance calculator interface exists [envir
onment/repo/lib/src/main/java/org/altbeacon/beacon/distance/DistanceCalc
ulator.java:1-12], and the existing RSSI default class named in the
prompt is present [environment/repo/lib/src/main/java/org/altbeacon/beac
on/service/RunningAverageRssiFilter.java:18-22]. The task still leans on
the agent inspecting current library behavior for phrases like
preserving the distance calculation “already performs today”
[instruction.md:9] and writing through to “configuration the library
already keeps” [instruction.md:13], but that context is available in the
staged repository.

test_coverage — 3.0/5
claude (5/5): The tests exhaustively enforce every named requirement in
[instruction.md]: unset-by-default fields ([tests/tests.patch:160-177]),
each Defaults value ([tests/tests.patch:180-211]), positional and named
ScanPeriods construction ([tests/tests.patch:213-243]), the fluent
Builder returning itself with the five named setters
([tests/tests.patch:245-271]), adjust/replace/revert delta semantics
([tests/tests.patch:273-334]), write-through to every legacy
configuration surface named in the prompt ([tests/tests.patch:336-467]),
snapshot independence including copy() ([tests/tests.patch:396-418]),
factory default preserving library distance
([tests/tests.patch:478-497]), scan-strategy equality across kinds
([tests/tests.patch:499-547]), and each strategy actually taking effect
via scheduledScanJobsEnabled/foregroundServiceNotificationId/ScanJob.get
ImmediateScanJobId ([tests/tests.patch:549-586]); Java usability is
separately enforced in [tests/tests.patch:44-99]. No vacuous asserts, no
broad exception swallowing, no existence-only checks; the only
unenforced spec bits are the internal transaction-atomicity and rebind-
after-return notes, which are not directly observable.
gpt (3/5): The suite covers most of the stated API surface: optional/unset
fields, defaults, and the Java/Kotlin builder are checked in
[tests/tests.patch:160-271], merge/reset/revert and write-through to
existing configuration are checked in [tests/tests.patch:273-467], and
distance calculators plus scan strategies are checked in
[tests/tests.patch:469-586]. However, the instruction explicitly
requires transactional application and special behavior when changing
scan strategy while consumers are bound [instruction.md:13], while the
scan-strategy tests only apply strategies on an unbound manager
[tests/tests.patch:549-586] and there is no assertion that callers
cannot observe a half-applied change, so a plausible implementation
omitting those functional edge cases could pass.

test_faithfulness — 5.0/5
claude (5/5): Every assertion maps to text in [instruction.md]: the field
names and defaults are quoted verbatim in the prompt, the write-through
properties (getRegionExitPeriod, Beacon.getHardwareEqualityEnforced,
RangeState.getUseTrackingCache, RangedBeacon.maxTrackingAge,
ScanJob.getImmediateScanJobId, beaconManager.foregroundScanPeriod, etc.)
are exactly the 'configuration the library already keeps' the
instruction names, and the SDK-28 assumption that Defaults.scanStrategy
is JobServiceScanStrategy ([tests/tests.patch:190-191]) follows the
prompt's 'default strategy on Android 8+'. The 0.0001 distance tolerance
([tests/tests.patch:205-210], [tests/tests.patch:482-496]) is a mild
convenience not spelled out in the prompt but is negligible given the
instruction says the factory must 'preserve the distance calculation the
library already performs' — a competent agent would not be misled.
gpt (5/5): The assertions are grounded in the prompt’s named contract: the
tests use the exact field names/defaults and builder methods described
in [instruction.md:5], the application/readback semantics from
[instruction.md:13], and the scan strategy and distance factory
requirements from [instruction.md:9]. I did not find hidden output
schemas, paths, or canonicalizations; for example, the JobService
default asserted for SDK 28 [tests/tests.patch:190-192] follows the
prompt’s Android 8+ default and the test’s declared SDK
[tests/tests.patch:136-137].

Rationale (from driving judge):
The suite covers most of the stated API surface: optional/unset fields, defaults, and the Java/Kotlin builder are checked in [tests/tests.patch:160-271], merge/reset/revert and write-through to existing configuration are checked in [tests/tests.patch:273-467], and distance calculators plus scan strategies are checked in [tests/tests.patch:469-586]. However, the instruction explicitly requires transactional application and special behavior when changing scan strategy while consumers are bound [instruction.md:13], while the scan-strategy tests only apply strategies on an unbound manager [tests/tests.patch:549-586] and there is no assertion that callers cannot observe a half-applied change, so a plausible implementation omitting those functional edge cases could pass.

================================================================================

## Oracle Check

Not run — an earlier stage of the review gate blocked this submission.
```

### The feedback as a numbered item list

| # | Finding | File it touches | Action |
|---|---|---|---|
| 1 | scan strategies declared as an open interface while the instruction called them a closed set | `instruction.md` | the word closed removed. Sealing would restrict a public API, which is not an additive edit |
| 2 | five of fourteen `Settings.Defaults` entries are plain vals, so Java needs `Defaults.INSTANCE` | `instruction.md` | the Kotlin-and-Java promise narrowed. The report's own example, `distanceModelUpdateUrl`, is one of the nine const ones and was wrong |
| 3 | switching away from the foreground strategy leaves its notification in place | `instruction.md` | reworded to the scheduling mode the strategy describes, which is what the four configure methods do |
| 4 | `Identifier.parse` returns null for a null argument | `instruction.md` | parsing dropped from the backward-compatibility sentence |
| 5 | the transactional claim and the bound-consumer behaviour are described and never tested | `tests/tests.patch` | tested, not deleted. See below |
| 6 | three long paragraphs, three points left implicit | `instruction.md` | restructured against measured sizes. See below |
| 7 | (found here, not reported) two graded assertions call symbols the instruction never names | `instruction.md` | both named as deliverables |

All four oracle findings were diffed against PR 1177 before acting. Every one is inherited, so
every one is answered in `instruction.md` and none in `solution/golden.patch`. That is the sixth
time on this task that an oracle finding has turned out to describe the PR
(`learning/source-pr-cross-check.md`).

### Item 5, the reason string, closed by testing

`everyScanStrategyCanBeAppliedAndReadBack` now binds a `RecordingConsumer`, changes the scan
strategy underneath it, and asserts the consumer is still bound, that it reconnected, and that
`ScanJob.getImmediateScanJobId` reports the new strategy's id. `bindInternal`, `unbindInternal`
and `isAnyConsumerBound` are all public at the base commit, so nothing new is asked of the agent.
No new `@Test`, because `fail_to_pass` is at the hard ceiling of 20.

Negative control: stubbing the rebind branch out of the oracle makes it fail with an
`IllegalStateException` from `setEnableScheduledScanJobs`, which is the naive implementation the
report describes. A class-level `@After` releases the consumer even when an assertion above it
throws, because `BeaconManager` is a process singleton and a bound consumer leaks into the next
test class.

Also removed a contradiction I shipped in round 2: an assertion that two identically-built
`ForegroundServiceScanStrategy` instances compare unequal, against an instruction sentence saying
strategies configured the same way compare equal.

### Item 6, clarity, measured rather than guessed

Round 4 added section headings and the score did not move, so the headings were never the problem.
Measured the longest paragraph in the two bundles of mine that are not bounced on this axis:
**717** characters in the accepted kvdex bundle, **791** in libcrux. This task's `instruction.md`
had a **2724** character paragraph and a **2466** character one. Rewritten to a 14-row field
table, two bullet lists and short paragraphs, longest now **828**, 67 lines against 13.

### Item 7, self-caught, and the most serious thing in the round

`BeaconManager.getLongScanForcingEnabled()` and `ScanJob.getJobPersistenceEnabled()` are graded by
`tests.patch` and exist at neither the base commit nor anywhere in `instruction.md`. I created both
in round 2 when completing the PR's own TODO, then graded them without declaring them.

The real judges scored `test_faithfulness` 5.0 and missed it. My own local rehearsal caught it.
This is the `Task Instruction Sufficiency: FAIL` signature seen from the writing side: the oracle
knows the names because the patch creates them, no agent can, so every agent fails to compile the
graded Kotlin file while the oracle passes 100%. It would have read as difficulty. Written up in
`learning/`.

### Verification, against the extracted zip

| Run | Result |
|---|---|
| Oracle | 230/230, raw exit 0 |
| NOP | reward 0, raw exit 1 (fail-closed gate holds) |
| Agent collision, workspace with no `.git` | 230/230 |
| `solve.sh` three times in one container | 230/230 each time |
| Hostile delete | reward 0, naming two tests |
| Static checks | all 20 pass on the extract, `fsck` silent, seven expected `.git` entries, both patches apply at base |

`fail_to_pass` 20, `pass_to_pass` 210, `allow_extra_failures` false. Zip md5
`d21ea22f6c1aa79e3bc34328b1c7be6d`, sha256 `5f2eb38b…`, 2603512 bytes. `find work -newer
upload/*.zip` prints nothing.

### Answers file

Rewritten in the same action as this block. Issue blocks 24 to 27 added, two Files Changed entries
updated, Comments for Reviewer replaced. The `humanizer` pass then ran over that text, and the
Section 5 re-check was run as a **bare unfiltered count** rather than the filtered grep that hid 40
em dashes on an earlier round. It turned up internal check vocabulary that had been shipping since
round 1 (judge axis names, reason strings and axis scores in the reviewer-facing prose) and all of
it is now written in plain words. Current totals across the whole file: em dashes 0, arrows 0,
axis names 0, reason strings 0, criterion labels 0.

### Still open

The oracle 0/3, unchanged and undiagnosed, at three strikes. It has not run for two rounds because
the judge gate blocked first. Nothing further ships against it without the downloadable difficulty
artifact.

---

## Round 6 — feedback of 2026-08-05 (REMOVE, oracle spec gap)

### Freshness check before touching a file

| Axis | Result |
|---|---|
| Test ids | the ids it reasons about resolve in the current `tests/config.json`, 20 f2p and 210 p2p |
| Line numbers | `[instruction.md:65-67]` and `:26` land on the backward-compatibility paragraph and the rssi row of a 67-line file. `[solution/golden.patch:957-979, 1186-1194, 663]` sit inside 1247 lines. `[tests/tests.patch:599-622]` inside 655 |
| Commands | matches the current `execution.commands` |
| Instruction text | every phrase quoted is present in the round 5 `instruction.md` |

Fresh. It describes upload 9.

### Verbatim feedback

```
AGENTIC JUDGE QUALITY REPORT:
================================================================================
                  AGENTIC JUDGE REVIEW: task
================================================================================

Status:    ❌ REMOVE
Reason:    oracle_spec_gap

Per-axis review (rating out of 5):
  clarity                   4.0/5   (claude 4, gpt 4)
  oracle_no_gaming          5.0/5   (claude 5, gpt 5)
  oracle_robustness         5.0/5   (claude 5, gpt 5)
  oracle_spec_faithfulness  2.5/5   (claude 5, gpt 2)   <-- REMOVE driver
  packaging                 4.5/5   (claude 5, gpt 4)
  prescriptiveness          4.0/5   (claude 4, gpt 4)
  realism                   5.0/5   (claude 5, gpt 5)
  self_containedness        4.5/5   (claude 4, gpt 5)
  test_coverage             4.0/5   (claude 5, gpt 3)
  test_faithfulness         5.0/5   (claude 5, gpt 5)

Rationale (from driving judge):
The patch implements much of the requested surface, including optional `Settings`
fields, defaults, builders, strategies, and `BeaconManager` apply methods
[solution/golden.patch:123-247] [solution/golden.patch:579-923]. However, it violates
the instruction's constraint that existing behavior remain unchanged for callers who
never touch the new API [instruction.md:65-67]: it deletes the existing lazy default
distance-calculator initialization from service/job paths [solution/golden.patch:957-979]
[solution/golden.patch:1186-1194] and only installs a calculator inside
`applySettingsChange` [solution/golden.patch:202-203], so untouched legacy scanning can
lose its previous default calculator. There is also a named type mismatch for
`rssiFilterImplClass`: the instruction requires the class of an RSSI filter
[instruction.md:26], but the implementation narrows it to
`Class<RunningAverageRssiFilter>?`, excluding other filter implementations
[solution/golden.patch:663].

gpt test_coverage (3/5): ...the instruction explicitly requires settings to apply "as one
transaction" and scan-strategy changes with bound consumers to unbind then rebind
[instruction.md:55], while the test only checks the consumer is still bound and connect
count increments [tests/tests.patch:599-622], so a plausible sequential implementation
that never actually unbinds and exposes mixed intermediate state could pass.

gpt clarity (4/5): One minor ambiguity remains where `rssiFilterImplClass` is described as
"the Class of an rssi filter" rather than an exact generic type despite the table saying
types match exactly [instruction.md:26].

claude prescriptiveness (4/5): One mild how-to leak: the strategy-swap mechanism is
prescribed ('unbinding those consumers, putting the new strategy in place and binding them
back') [instruction.md:55], and specific accessor names like getLongScanForcingEnabled()
and getJobPersistenceEnabled() are pinned [instruction.md:63,65].

gpt packaging (4/5): The only minor hygiene concern is an extra
`environment/problem_statement.md` duplicating the prompt in the source listing
[_DIRECTORY_LISTING.txt:9-10], but the Dockerfile only copies `repo/` into `/app`, so it
does not ship that duplicate to the agent runtime [environment/Dockerfile:33-35].
================================================================================
```

### Both reported claims verified against PR 1177 before any edit

| Claim | Check | Verdict |
|---|---|---|
| The patch deletes the lazy default distance-calculator init from the service and job paths | `grep -c 'if (Beacon.getDistanceCalculator() == null)' /tmp/pr1177.diff` returns **3**, and the same three deletions are in `golden.patch` | **True, and PR-inherited** |
| ...so untouched legacy scanning can lose its calculator | `applySettingsChange` is the only caller of `Beacon.setDistanceCalculatorInternal`, and `Beacon.getDistanceCalculator()` at base is a bare `return sDistanceCalculator` with no fallback | **The consequence is real too**, not just the diff |
| `rssiFilterImplClass` narrowed to `Class<RunningAverageRssiFilter>?` | the type appears **3 times** in the PR diff and 3 times in `golden.patch` | **True, and PR-inherited** |

Both are answered in `instruction.md` and neither in the patch. Restoring either would be putting
back behaviour PR 1177 deliberately removed, which is reducing PR scope and is an Invalid
condition, not a fix (`learning/source-pr-cross-check.md`).

### The two-strikes move, applied to the pattern instead of the sentence

Five consecutive rounds have been sent back because the instruction promises something the PR does
not deliver, a different sentence each time. Narrowing the reported sentence and re-uploading is the
fix that has now failed four times. So this round audited **every** absolute claim in
`instruction.md` against `golden.patch` in one pass.

It found a third gap the judges had not reported: `instruction.md:43` said two strategies of the
same kind configured the same way compare equal. `ForegroundServiceScanStrategy.equals` compares
`this.notification == other.notification`, and `android.app.Notification` does not override
`equals`, so that is reference identity. Two notifications built the same way are two objects and
the strategies are **not** equal.

Worse, round 5 had the evidence and drew the wrong conclusion: it **deleted** an
`assertNotEquals` on two separately-built notifications because it "contradicted" the instruction
sentence. The assertion was right and the sentence was wrong. The assertion is restored.

### What changed

| File | Change |
|---|---|
| `instruction.md` | four narrowings. Backward compatibility no longer claims everything the existing methods drive is unchanged, and names the distance calculator as the one behaviour that moves. `rssiFilterImplClass` carries its exact type. Strategy equality states the notification counts by identity. The strategy-change sentence drops the unbind/rebind procedure for the observable outcome |
| `environment/problem_statement.md` | re-copied, md5 `cf1452a0304f` |
| `tests/tests.patch` | restored the separate-notification `assertNotEquals`; added `assertNull(beaconManager.intentScanStrategyCoordinator)` after the rebind so the old mode being shut down is graded; reworded two mechanism comments. Regenerated against the clean base commit. No new `@Test`, f2p stays at the ceiling of 20 |

The strategy-change rewording closes two findings pulling in opposite directions at once: the
optional instruction check called the sentence a procedure (0.30, one high), and a judge called the
matching test too weak to distinguish that procedure from a naive implementation. Stating the
outcome and grading the outcome answers both.

### Verification, against the extracted zip

| Run | Result |
|---|---|
| Oracle | 230/230, reward 1, `raw_exit_code` 0, `success` true |
| `solve.sh` x3 in one container | 230/230 each. Runs 2 and 3 print "already applied", so the idempotency probe fires |
| NOP | reward 0, `raw_exit_code` 1, `infrastructure_error` None, 0/230 |
| Hostile 1 - `equals` stops comparing the notification | reward **0**, 229/230, fails `SettingsTest::scanStrategiesCompareEqualOnlyToAMatchingStrategy` |
| Hostile 2 - consumer never rebound | reward **0**, 229/230, fails `SettingsTest::everyScanStrategyCanBeAppliedAndReadBack` |
| Agent overwrites `SettingsTest.kt`, workspace has no `.git` | 230/230 |
| `bin/preflight.sh` on the extract and on `work/` | 5 stages pass, 0 fail |

**A probe that did not land, recorded because it nearly shipped as a result.** The first rebind
stub edited line 666, which is the `shouldFailover` branch, not the path
`applySettingsChange` uses. The suite stayed at 230/230 and that looked like a coverage hole. The
stub had landed (2 occurrences to 1) but on the wrong code. The real path is
`configureScanStrategyWhenConsumersUnbound`, and stubbing `BeaconManager.this.bindInternal` there
drops the reward to 0. Both hostile numbers above come from runs that asserted the break existed
before running the suite (`learning/verify-in-the-image.md`).

Zip md5 `4014d7070190ad5b2cef686738d05905`, sha256 `07de50a8...`, 2604113 bytes, 0 symlinks
matching `work/`. `find work -newer upload/*.zip` prints nothing.

### Still open

The oracle 0/3. Unchanged, unreproduced, and now not measured for three consecutive rounds because
the judge gate blocked first every time. Nothing this round touched it.

---

## Round 7 — feedback of 2026-08-06 (DISCUSS, coverage_gap)

### Freshness check

Fresh, and it describes upload 10. Confirmed by **content**, not just line counts: the report cites
"notification-by-identity" at `instruction.md:43` and `tests/tests.patch:512-561`, both of which are
round 6 additions. Line counts at the time: `instruction.md` 67, `tests.patch` 663,
`config.json` 264, `golden.patch` 1247, `solve.sh` 52. Every cited range falls inside its file.

### Verbatim feedback

```
Status:    ⚠️  DISCUSS
Reason:    coverage_gap

  clarity 4.0 (claude 4, gpt 4) | oracle_no_gaming 5.0 | oracle_robustness 4.0 (claude 5, gpt 3)
  oracle_spec_faithfulness 3.5 (claude 4, gpt 3) | packaging 4.5 | prescriptiveness 4.5
  realism 5.0 | self_containedness 4.5 | test_coverage 3.0 (claude 5, gpt 3) | test_faithfulness 5.0

Rationale (driving judge):
The suite covers the core Settings schema, defaults, builder chaining, merge/replace/revert
semantics, snapshots, scan strategy equality/application, and most write-through behavior with
direct assertions in [tests/tests.patch:172-223], [tests/tests.patch:257-346], and
[tests/tests.patch:348-631]. However, it never asserts two explicit behavioral requirements:
long-scan forcing must be consulted by scanning code, not merely stored [instruction.md:61-63],
while the tests only check the active setting/getter [tests/tests.patch:441-459], and a caller who
never applies settings should no longer get a default distance calculator installed
[instruction.md:67], while the default-calculator checks run after the test setup calls
revertSettings() [tests/tests.patch:153-162] and then assert the applied default factory
[tests/tests.patch:490-508].

gpt oracle_robustness (3/5): the produced scan-strategy rebinding logic uses asynchronous
Handler().postDelayed(...) polling and can return from applySettingsChange before consumers are
rebound [solution/golden.patch:147-202] [solution/golden.patch:220-236].

gpt oracle_spec_faithfulness (3/5): the prompt requires previously bound consumers to be rebound
"by the time it returns" [instruction.md:49-57], but the solution defers rebinding through
Handler().postDelayed [solution/golden.patch:220-236].

gpt clarity (4/5): scanStrategy specified as JobServiceScanStrategy() only "on Android 8 and
above" without explicitly naming the default below Android 8 [instruction.md:16], and
DistanceCalculatorFactory described relative to the distance package while the overall API is said
to live in org.altbeacon.beacon [instruction.md:1] [instruction.md:45].
```

### The findings, and what each turned out to be

| # | Finding | Verified as | Fix |
|---|---|---|---|
| 1 | long scan forcing consulted by scanning code, not graded | real. A round 5 sentence | tested, with a negative control |
| 2 | no default calculator when settings never applied, not graded | real. A round 6 sentence | tested |
| 3 | async rebind vs "by the time it returns" | `postDelayed` is **1x in the PR diff, 1x in golden** - PR-inherited. The unconditional wording is round 6's | instruction only |
| 4 | scan strategy default below Android 8 unstated | real, `golden.patch:710-713` sets `BackgroundServiceScanStrategy()` | table now gives both |
| 5 | factory package sentence contradicts the opening line | real | reworded |

**Both coverage gaps are requirements earlier rounds added.** Making the instruction truthful is what
created the obligation. That is worth recording as a pattern rather than an accident.

### The structural fix: stop narrowing, remove the unbounded claim

Round 6 audited every absolute claim and still shipped a **narrowing**, and its rewrite is exactly what
this round had to fix. It replaced a false claim with a stronger one:

> "One piece of behaviour does move, and it is the only one." ... "Everything else those existing
> methods drive stays as it is."

Verified false three times over, independently:

| Counter-example | Evidence |
|---|---|
| `setDebug(false)` installs a different logger | `golden.patch:114-115`, `Loggers.empty()` to `Loggers.infoLogger()` |
| `Identifier.parse` contract changed | `golden.patch:443-444`, NPE to `return null` |
| `Region.matchesBeacon` gained a gate | `golden.patch:523-528` |

At six strikes the rule is remove the dependency. The dependency here is **the instruction making
exhaustive claims about library-wide behaviour**. Every unbounded universal is gone from that
paragraph. What remains is what is required and what the 210-id `pass_to_pass` list already guards.

### Why the long-scan test uses reflection, and why that is defensible

There is no public reader for the consumed state: `ScanHelper.getCycledScanner()` is package-private
and `CycledLeScanner.mLongScanForcingEnabled` is private with a setter only. Three facts made the
reflective test worth shipping rather than narrowing the requirement away:

- `BeaconServiceTest::beaconScanCallbackTest` is already in `pass_to_pass`, so
  `Robolectric.buildService(BeaconService).onCreate()` is known green in this image at sdk 28
- the test `AndroidManifest.xml` declares the service with **no** `meta-data`, so
  `getManifestMetadataValue` returns null and the new reader is the only way the flag can go true
- all three reflected names exist at the base commit and `golden.patch` never touches them, so the
  test constrains the wiring, not any name the implementer must invent

It reads runtime state, not source text, so the Phase A no-source-shape-grading gate still passes.
Disclosed in Comments for Reviewer rather than left for a reviewer to find.

### Verification, against the extracted zip

| Run | Result |
|---|---|
| Oracle | 230/230, reward 1, `raw_exit_code` 0 |
| `solve.sh` x3 in one container | 230/230 each, runs 2 and 3 report already applied |
| NOP | reward 0, `raw_exit_code` 1, `infrastructure_error` None |
| Agent overwrites `SettingsTest.kt`, no `.git` | 230/230 - the new service does not leak into the suite |
| H1 remove the long-scan consult | reward **0**, `theRemainingFieldsAreAppliedAndReadableBack` |
| H2 restore the deleted lazy calculator | reward **0**, `configuredDistanceCalculatorFactoryInstallsItsOwnCalculator` |
| H3 `equals` ignores the notification | reward **0**, `scanStrategiesCompareEqualOnlyToAMatchingStrategy` |
| H4 consumer never rebound | reward **0**, `everyScanStrategyCanBeAppliedAndReadBack` |
| H5 switch long scan forcing on unconditionally | reward **0**, `theRemainingFieldsAreAppliedAndReadableBack` |
| `bin/preflight.sh` | 5 stages pass, 0 fail |

H5 exists because the first version of the H1 test passed for an implementation that never consulted
the setting at all. The negative control that closes it was found by an adversarial subagent review,
not by the round's own reasoning.

**A hostile probe whose guard was backwards.** H2 inserts code rather than removing it, so the
`must decrease` assertion was wrong and the probe aborted claiming the break had not landed. Fixed to
assert an increase. Same class as round 6's wrong-code-path probe: the guard has to match the
direction of the edit.

### The oracle 0/3, re-read

Not measured for three rounds - the review gate stops at the judge and the later stages never run.
Re-read the original platform text at `task.md:269`: it carried **no per-test output at all**, on any
of the three panels, and its own wording is "Task may be flaky or has infra issues". Per the
defect-vs-infra tell that is the infra signature, not a task defect. A hypothesis that it was a misread
of `task.toml`'s `pass_at_k_* = "0/3"` was checked and **disproved** - `task.md:269` is the platform's
own Oracle Check text. Nothing further ships against it without the downloadable results.

### Answers file

Updated in the same action: blocks 31 to 33, two Files Changed entries, the Send decision, and
Comments for Reviewer rewritten. `humanizer` run over the new text, then the Section 5 check as a bare
unfiltered count.

---

## Round 8 — human reviewer, 2026-08-14 (all evaluation checks passed)

**This is the first round driven by a human reviewer rather than the automated panel, and the first
where every evaluation check passed.** That settles the oracle 0/3 that held the Send box shut for six
rounds: it is gone, it had not reproduced since round 3, and its last appearance carried no per-test
output at all.

### Verbatim feedback

```
## Reviewer Feedback (human reviewer; all evaluation checks passed)

SettingsTest.kt only compiles against a snapshot whose fields are not optional, and instruction.md
never asks for that. Settings itself has to be all nullable, which the prompt does say, but the
graded file then feeds beaconManager.activeSettings.debug straight into assertTrue and calls toLong
on regionExitPeriodMillis, so returning a filled in Settings from getActiveSettings, which is what
the prompt describes, buys a type error instead of a failing assertion. Seven of the eight difficulty
trials died right there in compileDebugUnitTestKotlin, 24 errors reading inferred type is Boolean?
where a plain Boolean is required, plus the nullable receiver complaint on Int?,
Settings.ScanPeriods? and BeaconSimulator?. Every one of those trials records all 230 required tests
as missing, the 210 regression ids included, because the suite never ran, which also means the hard
tier is measuring a compile target nobody can hit rather than your feature. One sentence in
instruction.md closes it, saying the resolved snapshot is its own type and that reading a field off
it hands back the value and not an optional. Loosening the assertions so both shapes build works
too, though then the snapshot contract stays unwritten.

Two coverage holes are left and each one lets a wrong build through. The field table gives
BackgroundServiceScanStrategy as the default below Android 8 and nothing exercises it, since
SettingsTest.kt and SettingsJavaTest.java both pin sdk 28, so an implementation handing back
JobServiceScanStrategy unconditionally passes everything you have. Mind the offline cache if you
close that by adding a lower sdk, the Dockerfile only warms android-all for 28 and 34. The other is
jobPersistenceEnabled. Both call sites in everyScanStrategyCanBeAppliedAndReadBack apply it as false
and assert false, which a getJobPersistenceEnabled that always returns false will sail through, so
apply it as true once and check it comes back.

Small one to finish. There is no refs directory under environment/repo/.git in the re-upload, and
git wants one before it will treat the tree as a repository, so /app in the image isn't one. You
noticed something in the same area already, your notes say the verify time workspace is not a
repository. The seed shipped it, so repack in a way that keeps the empty refs entries. Credit where
it's due on the harness: tests.patch carries both graded files as whole new files, test.sh wipes
lib/src/test and lays the base tree back down from a payload it carries itself, and solve.sh has no
reverse apply in any branch. A solver rewriting SettingsTest.kt can't knock the apply over, and I
couldn't find a way to forge a pass through the stdout parser either, because the 20 graded ids
never reach the workspace.
```

### The findings

| # | Finding | Verified as | Fix |
|---|---|---|---|
| 1 | graded file only compiles against a non-optional snapshot; **7 of 8 difficulty trials died at `compileDebugUnitTestKotlin`** | real, and present since the first pass. `golden.patch:245` returns `AppliedSettings`; the instruction only said "every field is filled in" | `instruction.md` states the contract |
| 2 | below-Android-8 default never exercised (both classes pin sdk 28) | real. A test merge freed a graded slot; the image warms android-all 24 | test at `@Config(sdk = [24])` |
| 3 | `jobPersistenceEnabled` applied false and asserted false at both sites | real | `true` at one site, `false` at the other |
| 4 | no usable `refs` dir, so `/app` is not a repo | **did not reproduce as written** (the zip carries the entries and an extract here is a working repo) but **right in substance** | loose 41-byte ref restored |
| 5 | *(found here)* `.gradle` cache reappeared in `work/` after round 7's zip | real, gitignored so `git status` is silent | removed; rezip now refuses to build while one is present |

### Finding 1, measured

A subagent enumerated the damage: **24 sites** need a plain `Boolean` (matching the reviewer's 24
errors exactly), 13 need a plain `Int`, 4 need a non-null `ScanPeriods` receiver, 1 a non-null
`BeaconSimulator`.

**The first fix over-promised and was corrected before shipping.** `AppliedSettings` declares
**13 of 14** fields non-optional; `rssiFilterImplClass` is `Class<RunningAverageRssiFilter>?`, and its
graded assertion goes through `assertEquals`, which accepts a nullable, which is why it never appeared
among the 24 errors. The wording now says that field may stay optional and the rest may not, which is
what golden actually does. Without that correction this would have been the seventh instance of the
instruction promising something the PR does not keep.

The instruction does **not** name `AppliedSettings` (0 occurrences in both `instruction.md` and
`tests/tests.patch`), so no non-derivable name was introduced.

### Finding 2, and why it cost a test merge

It cannot be tested at sdk 28, and a per-method `@Config` needs its own `@Test`, which would make **21
graded ids** where the static check rejects anything over 20. So `distanceModelUpdateUrlIsPushedToTheManager`
was merged into `scanPeriodsAndModelUrlArePushedToTheManager`, freeing the slot. **f2p stays 20.**

The Robolectric platform jar for API 24 was not in the offline cache, exactly as the reviewer warned.
The Dockerfile's warm list is now `{24, 28, 34}`. That is **baking a test dependency** under
`docs/tasking-guide.md:41`, not a row of the allowed-fix table, so it is disclosed as an inference in
Comments for Reviewer, per `.claude/rules/11-verifier-hardening.md:233` (the elfuse precedent).
The Dockerfile proves it rather than assuming it: it re-runs the same warm-up **offline** before the
build ends, and that build exited 0.

### Finding 4, and the honest correction

The claim did not reproduce: the zip carries `refs/` and `refs/heads/`, and `git status` on an extract
exits 0. **The reviewer is still right about the cause, and it is mine.** The seed ships
`refs/heads/main` as a real **41-byte file**; the pre-zip `git gc` packs it away and leaves the
directory empty, and an empty directory does not survive every extraction tool. Restored, computing
into a variable first (`.claude/rules/12-common-mistakes.md:42`). The rezip step now refuses to build
unless that file is 41 bytes and HEAD still resolves to the base commit.

### Two agent proposals declined, on this task's own learning note

The snapshot subagent proposed two further clause edits. Both were checked and **declined**:

- "`copy(...)` leaving every other field as it stands" - the graded test asserts only the two fields it
  changed, so this would be an instruction claim nothing grades. That is precisely the coverage-debt
  pattern written into `learning/quality-check-criteria.md` last round
- "from Kotlin or from Java" on the snapshot - `SettingsJavaTest` operates on a delta `Settings`
  (`assertNull(settings.getRegionExitPeriodMillis())`), not the snapshot, so nothing needs it

### Verification, against the shipping zip

| Run | Result |
|---|---|
| Oracle x3 | 230/230, reward 1, `raw_exit_code` 0 |
| NOP | reward 0, `raw_exit_code` 1, `infrastructure_error` None |
| Agent overwrites the graded file, no `.git` | 230/230 |
| H1 long-scan consult removed | reward 0, `theRemainingFieldsAreAppliedAndReadableBack` |
| H2 lazy calculator restored | reward 0, `configuredDistanceCalculatorFactoryInstallsItsOwnCalculator` |
| H3 `equals` ignores the notification | reward 0, `scanStrategiesCompareEqualOnlyToAMatchingStrategy` |
| H4 consumer never rebound | reward 0, `everyScanStrategyCanBeAppliedAndReadBack` |
| H5 long-scan set unconditionally | reward 0, `theRemainingFieldsAreAppliedAndReadableBack` |
| **H6 below-8 default returns the job strategy** | reward 0, `theDefaultScanStrategyBelowAndroid8IsTheBackgroundService` |
| **H7 `getJobPersistenceEnabled` always false** | reward 0, `everyScanStrategyCanBeAppliedAndReadBack` |
| `bin/preflight.sh` | 5 stages pass, 0 fail |
| Extracted tree | git repo, 41-byte loose ref |

**Gate 7 tripped once and was honoured rather than argued around.** After the first zip, preflight's
git commands rewrote `.git/index`, so `find work -newer <zip>` printed. The zip was rebuilt and the
oracle, NOP, collision and both new probes re-run against the artifact that actually ships
(`5e7be003`, 2605430 bytes).

### Answers file

Blocks 34 to 37 added, two Files Changed entries extended, **Send to reviewer flipped to Yes** for the
first time.

**A follow-up audit of the answers file found three gaps the round-8 write had left**, all of them in
files a reviewer diffs. `environment/Dockerfile` had no line for the android-all warm change, which is
the one edit this round that needs reviewer judgement. `tests/config.json` did not record the graded-id
swap, so the changed ids would have appeared unexplained. `environment/repo` did not record the loose-ref
restore, which is the fix for the reviewer's own finding 4. All three added.

The same audit caught a stale count: issue block 1 read "The count is 19 now" while the post-fix
checkbox nine lines later read `counted: 20`. That is the `answers-file-drift` signature exactly, a
per-file sentence written in an early round and never re-read. Reworded to say the first pass reached
19 and later rounds took it to 20. The `Current md5` claim for `problem_statement.md` was re-derived and
matches both the live file and the copy inside the zip, and it is the only md5 claim in the file, so no
second stale one is hiding behind the first. Comments for Reviewer is written as direct replies, because a subagent flagged that
LEDGER **L18** ("the judge does not read Comments for Reviewer") is scoped to the automated panel and
does **not** transfer to a human-reviewer round.

---

## CLOSED — ACCEPTED, 2026-08-14

**Outcome:** accepted. Round 8, upload 12, zip md5 `5e7be003adece4f08316ff7a196177e6`, 2605430 bytes.
No Submission Quality Score was reported to this workspace, so none is recorded here rather than
inferred.

**Final numbers.** 8 revision rounds, 12 uploads, 14 days (2026-08-01 to 2026-08-14). Handling time
ledger closes at **350 minutes of revisions** on top of 205 minutes for the first pass. `fail_to_pass`
20, `pass_to_pass` 210, 230 graded ids total.

**What the last round actually fixed**, since that is what acceptance most directly rewards. A human
reviewer, reading a bundle that had passed every automated check, found that the graded Kotlin file only
ever compiled against a snapshot type whose fields are not optional, which `instruction.md` never asked
for. **Seven of the eight difficulty trials had died in `compileDebugUnitTestKotlin`** with 24 errors,
recording all 230 ids missing, so the hard tier was grading a compile target nobody could hit. Nothing in
the automated pipeline sees that, because the oracle defines the type and therefore compiles.

**The arc, in one line per round.**

| Round | Came back for | Root cause |
|---|---|---|
| 1 | quality bounce on test coverage, oracle 0/3 | seed had 3 f2p ids and 2 real assertions |
| 2 | REMOVE on oracle spec, oracle 0/3 | oracle did not implement the instruction; PR TODO unfinished |
| 3 | screen blocked on oracle 0/3 | never reproduced locally; later read as infra |
| 4 | DISCUSS, oracle spec gap | instruction promised what the PR does not do |
| 5 | DISCUSS, coverage gap | a claim described and never tested |
| 6 | REMOVE, oracle spec gap | two more PR-inherited promises |
| 7 | DISCUSS, coverage gap | **round 6's own rewrite**, and two requirements round 5/6 had added |
| 8 | human reviewer, 4 findings | the compile contract, present since the first pass |

**The measured shape of the accepted bundle** is in `learning/accepted-bundle-reference.md` and its row
in `learning/calibration.tsv`. It is the second accepted bundle here, after kvdex 245, and the first
whose acceptance came after a human reviewer round.

**Two claims this task retired.** The `Oracle Check 0/3` that shaped rounds 1 to 3 and kept the Send box
shut for six rounds was never reproduced locally across roughly 35 runs, and upload 11 passed every
check without anything having been aimed at it since round 3. Its only appearances carried no per-test
output on any panel. `LEDGER.md` L75 records that the defect-vs-infra tell should have been read on the
first occurrence. `LEDGER.md` L76 records the compile-contract class.
