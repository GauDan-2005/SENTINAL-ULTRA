---
id: stock-bundle-defect-baseline
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260719_045042__oliver-oloughlin_kvdex__245
  - 20260723_030109__cryspen_libcrux__1165
  - 20260727_135618__AltBeacon_android-beacon-library__1177
  - 20260728_153118__jqno_equalsverifier__1166
  - 20260723_030152__mithriljs_mithril.js__2021
  - 20260720_144200__thomas4019_expressa__132
  - 20260717_182400__felixguendling_cista__172
evidence: "Six defects found independently on the first four bundles, two more added by peer review, and cista 172 measured six of the eight with the other two ruled out structurally"
applies_to:
  languages: [any]
  runners: [any]
  phases: [analysis, fixing, local-runs]
blocks_submission: true
fails_gate: [difficulty, oracle, quality-check, peer-review]
supersedes: []
contradicts: []
---

# Eight defects every arriving bundle has until you prove otherwise

Sources: all four tasks handled in this workspace, 2026-07-31 to 2026-08-04.
`_archive/20260719_045042__oliver-oloughlin_kvdex__245/task.md`,
`_archive/20260723_030109__cryspen_libcrux__1165/task.md`,
`tasks/20260727_135618__AltBeacon_android-beacon-library__1177/task.md` and
`tasks/20260728_153118__jqno_equalsverifier__1166/task.md`.

Four tasks, four different languages, four different build systems, and the same six findings
every time, with two more added later by peer review and a seventh bundle measuring six of the eight. They are not coincidences between bundles. They come from the stock Harbor scaffold
the task generator emits, so a bundle carries them the moment it is created and it keeps them
until an EC takes them out.

The cost of rediscovering them is not the reading. It is that each one was found late on at
least one task, after a round had already been spent, and two of them are the reason kvdex 245
took six rounds instead of two.

**Treat all six as present until a command or a file and line says otherwise.** Filling this
table is a Step 2 job, before any verdict.

**Amended 2026-08-11, cista 172.** Across seven bundles the count is now six or seven of eight rather
than eight of eight, and the section near the end of this note names the two that are **structurally**
ruled out by properties you can read in a minute. So the presumption still stands and the wording
sharpens: treat every row as present until you have either the command output or the structural
reason. What changed is that "absent" is now an answer a row can legitimately have, and a review that
says so has told the submitter something useful.

| # | Defect | Verdict | What decides it |
|---|---|---|---|
| 1 | Fail-open grader. `test.sh` records `raw_exit_code` and never branches on it | Present / Absent / NA | `grep -n 'raw_exit_code' tests/test.sh` and read whether the success expression uses it |
| 2 | No regression guard. `pass_to_pass` empty, `allow_extra_failures` true | Present / Absent / NA | `python3 -c "import json;g=json.load(open('tests/config.json'))['grading'];print(len(g['pass_to_pass']),g.get('allow_extra_failures'))"` |
| 3 | Stale test results baked into the image at build time and read by the grader | Present / Absent / NA | Does the Dockerfile run the suite? Does the grader glob a report directory the build wrote? Confirm in the NOP run, not on paper |
| 4 | `solve.sh` not idempotent, usually a reverse-apply fallback that reports success | Present / Absent / NA | Read `solution/solve.sh`, then run it twice in one container and diff the tree |
| 5 | Graded test files carry the name an agent would choose for its own test | Present / Absent / NA | Read the paths `tests.patch` creates against the class the instruction asks for |
| 6 | No test-tree restore before `tests.patch` is applied, or one built on git | Present / Absent / NA | `grep -n 'git\|rm -rf\|base64' tests/test.sh` around the apply step |
| 7 | A verifier dependency reaches the image only through an install chain ending in `\|\| true` | Present / Absent / NA | `grep -n 'python3' tests/test.sh` for what the verifier needs, then check whether the base image ships it: `docker run --rm <base-image> sh -c 'which python3'` |
| 8 | The runner prints its report to the same stdout the agent's code writes to, and the grader finds it by brace-slicing | Present / Absent / NA | Read `_find_json` in the embedded grader, then run the oracle once with a `console.log`/`print` of an **object** added to the code under test |

`NA` is a real answer and needs the same evidence as the other two. A task whose Dockerfile
never runs the suite genuinely cannot have defect 3.

**Defects 7 and 8 were added 2026-08-11** from two peer reviews of unrelated bundles, mithril.js
2021 and expressa 132, which found the same five stock defects independently. Both are on the
verifier side, both survive a green oracle run, and neither is visible without building the image.

**7. A verifier dependency behind an `|| true`.** The stock `test.sh` calls `python3` in four
places (lines 48, 89, 131 and 530 on both bundles). `node:20-slim` does not ship python3, checked
against a bare pull. It reaches the image only as a transitive dependency of `asciinema` on
`environment/Dockerfile:9`, whose whole chain ends in `|| true`. Rebuilt with that one line absent,
which the chain expressly permits:

```
BUILD OK (green)
python3 present? NO
test.sh exit=127        /tests/test.sh: line 48: python3: command not found
reward.txt = 0          report.json: not written
```

Every trial including the oracle scores 0 with no report to diagnose from. Section 10.7 says not to
strip `; exit 0` as pure hygiene, and this is the case where it is not hygiene: the swallowed
install is load-bearing for the verifier, which is the listed row. Fix by installing the dependency
in its own `RUN` that is allowed to fail the build.

**8. The report shares stdout with the code under test.** The embedded grader locates its JSON by
slicing stdout from the first `{` to the last `}`. Measured on mithril, correct solution applied in
every row:

| leftover debug line in the function under test | reward | passed |
|---|---|---|
| none | 1 | 15/15 |
| `console.log("hi")` | 1 | 15/15 |
| `console.log({a:1})` | **0** | **0/15** |
| `console.log(String.fromCharCode(123))` | **0** | **0/15** |

A plain string survives. Logging an **object** does not, and logging the data structure under
repair is how anybody debugs one. This is a false negative against correct work, not a fail-open,
so it is the opposite failure direction from defect 1 and needs its own check. Fix by writing the
report to a file the grader reads, to fd 3, or between unique markers the parser anchors on.

## What each one was on the four tasks

**1. Fail-open grader.** Present on all four. The stock `test.sh` computes
`success = not missing_required and not unexpected`, three lines after recording
`raw_exit_code`, and never reads it. libcrux finding 3 calls it "the stock harness defect" in
so many words. On kvdex it was demonstrated rather than argued: the NOP reported
`raw_exit_code 0` on a run where zero tests executed, because the single command was a pipeline
and the status belonged to the parser. Full mechanism and the two-part fix in
[verifier-fail-open.md](verifier-fail-open.md).

**2. No regression guard.** Present on all four as shipped. kvdex arrived with
`pass_to_pass` empty and closed at 112. libcrux finding 4 is `pass_to_pass: []` with
`allow_extra_failures: true` and one command running only the new target, which means nothing
outside the new feature could fail the reward. equalsverifier arrived with 21 graded ids and
closed with 1223. Populate from ids that passed in two consecutive oracle runs, and only set
`allow_extra_failures` to `false` when the field is already in the shipped config.

**3. Stale build-time test reports.** Present on the two JVM tasks, and it is the one that
cannot be seen statically. equalsverifier's Dockerfile warms the Maven cache with a real
`mvn -B test`, leaving 136 surefire XML files that the grader then globs, so a fresh container
with no Maven invocation at all reported 1284 testcases. Two of the 21 fail-to-pass tests
reported PASS on an unmodified repo. Fix is a `rm -rf` of the report directory at the head of
the test command. Full write-up in [stale-test-reports.md](stale-test-reports.md).

**4. Non-idempotent `solve.sh`.** Present on kvdex, libcrux and android-beacon. The shape is
always the same: apply forward, and on failure reverse-apply and report success. On libcrux the
first run created `libcrux-ml-kem/src/pqcp.rs` and the second run deleted it while exiting 0.
The platform runs the oracle three times, so this is a live risk rather than a tidiness point.
See [solve-sh-idempotency.md](solve-sh-idempotency.md), including the correction about what it
does and does not cause.

**5. Predictably named graded test files.** Present on all four. `tests.patch` adds
`libcrux-ml-kem/tests/pqcp.rs` for a task about a `pqcp` module, and
`lib/src/test/java/org/altbeacon/beacon/SettingsTest.kt` for a task about a `Settings` class.
An agent writes that exact path as a matter of course, `git apply` refuses with
`already exists in working directory`, and the trial is scored as infra rather than on merit.
A `Sentinel` prefix on the file and on the identifiers costs nothing and cannot collide.

**6. Missing or git-based test-tree restore.** Present on all four. This is the expensive one:
three git-based restore designs shipped on kvdex across three rounds and none of them worked,
because the verify-time workspace is not a git repository. Read
[tests-patch-vs-agent-edits.md](tests-patch-vs-agent-edits.md) before writing a restore step,
and measure which shape you need rather than assuming, because the create-only patch and the
embedded base64 payload are not interchangeable.

## Two of the eight are structurally scoped, and cista 172 is where that showed

Source: `review_tasks/20260717_182400__felixguendling_cista__172`, peer review 2026-08-11. A C++
header-only library graded by a bespoke `g++` line and doctest. Six of the eight fired, and the two
that did not were not luck. Each was **ruled out by a property of the bundle you can read in one
minute**, which is worth knowing before you spend a container run looking for it.

| # | cista 172 | Why |
|---|---|---|
| 1 fail-open grader | **Present** | NOP returned reward 0 with `raw_exit_code 0`. Worse than usual here, see below |
| 2 no regression guard | **Present** | `pass_to_pass []`, `allow_extra_failures true`. Gutting the runtime `type_hash` to a constant kept reward 1, 21 of 21, while the repo's own `test/type_hash_test.cc` failed 3 of 3 |
| 3 stale build-time reports | **Absent** | The Dockerfile only *configures* cmake, never runs the suite, and the grader parses fresh stdout rather than globbing a report directory |
| 4 non-idempotent `solve.sh` | **Present** | Byte-identical to 5 of 5 pristine bundles. Measured 1 of 3 |
| 5 predictably named graded files | **Present** | `test/static_type_hash_test.cc` beside the existing `test/type_hash_test.cc`. Invalid trial in 3 of 3 staging states |
| 6 no test-tree restore | **Present** | And it is what makes run 2 of the oracle report `tests.patch did not apply` |
| 7 dependency behind `\|\| true` | **Absent** | `python3` arrives as a hard dependency of `meson` and `gcovr` on the **non-optional** apt line. Measured in the image: `dpkg -s meson` and `dpkg -s gcovr` both list `python3:any`. `ninja-build` does **not**, despite the obvious guess, its `Depends` is only `libc6` and `libstdc++6`. The `\|\| true` chains here cover only `patch`, `tmux` and `asciinema` |
| 8 report shares stdout | **Absent** | `grading.parser.framework` is `custom` |

**Defect 8 cannot fire on a `custom` parser, and that is structural rather than lucky.** The
brace-slicing lives in `_find_json`, and `parse_results` only routes to it for `jest` and `mocha`. A
`custom` framework goes to `parse_custom`, which is a line-anchored regex over stdout plus stderr. So
one `python3 -c "import json;print(json.load(open('tests/config.json'))['grading']['parser'])"` tells
you whether the probe is worth running at all. On cista the graded binaries also write to
`/tmp/tc.out` and only the shell loop echoes to stdout, so nothing the agent's code prints reaches the
parsed stream in the first place.

**Defect 7's real question is not "is it behind `|| true`", it is "which line installs it".** Both
bundles that had it were Node images where `python3` was an accident of `asciinema`. Here the base is
`ubuntu:24.04` and the verifier's dependency rides in on a build toolchain the task genuinely needs,
on a line whose failure fails the build. Still worth a note to the submitter, because nothing in the
Dockerfile *asks* for `python3` and a future trim of that package list would take the verifier out,
but it is an observation rather than the blocking finding it was on mithril and expressa.

**Name the package from `dpkg -s`, never from the guess.** The first version of this row credited
`ninja-build` and boost, and both are wrong: `ninja-build` depends only on `libc6` and `libstdc++6`.
It is `meson` and `gcovr`, each of which lists `python3:any` directly. A row that names the wrong
package reads as measured and is not, and the submitter who checks it stops trusting the page.

**And defect 1 has a third mechanism, on top of the two already recorded.** `verifier-fail-open.md`
covers the runner-level pipeline and the multi-command `set -e` gap. cista adds a **pipe written into
`execution.commands` itself**:

```
g++ -std=c++17 ... test/static_type_hash_test.cc tools/doctest/doctest.cc -o /tmp/stht 2>&1 | tail -n 80
```

There are four commands, two of those compile pipes and two `for` loops ending in `echo`. The status
the runner sees belongs to `tail`, so `set -e` on its own never sees the compile failure, and the
trailing `echo`s make the runner's last-command status 0, so `bash -o pipefail` on its own is masked
too. **`pipefail` does reach a pipeline written inside the generated runner**, contrary to the first
version of this paragraph: it is an option of the shell executing the script, so it governs every
pipeline that shell runs. Measured in the image against a tree where nothing compiles:

| invocation | runner exit |
|---|---|
| `bash /tmp/run_tests.sh`, as shipped | 0 |
| `bash -o pipefail /tmp/run_tests.sh` | 0 |
| `set -e` prepended, plain `bash` | 127 |
| `set -e` prepended, `bash -o pipefail` | **1** |

So this config needs **both** halves of the Section 10.1 fix rather than either one, and the gate does
fire once they are both in. Read `execution.commands` for pipes and trailing `echo` to find that out,
not to conclude the gate is pointless.

## Two rows the eight-row table does not have, and both are blocking (added 2026-08-11)

From the verification audit of mithril.js 2021. Neither is a *scaffold defect* in the sense the
eight rows are, so neither gets a row number. Both are **invocations**, they cost one command each,
and each produced a blocking finding on a bundle three careful passes had already been over
(`learning/audit-the-finished-review-not-just-each-finding.md`).

| Check | Command | What mithril.js 2021 returned |
|---|---|---|
| The entrypoint under `sh`, not only `bash` | `sh /tests/test.sh` on a green oracle tree | exit 2, `set: Illegal option -o pipefail`, `/logs/verifier` never created, **no `reward.txt` at all**. One re-exec guard line took it to exit 0, reward 1, 15 of 15 |
| The real oracle cycle, not `solve.sh` alone | `solve.sh` then `test.sh`, 3 cycles, one container | **1 of 3**. Cycles 2 and 3 give `infrastructure_error: tests.patch did not apply`, while `solve.sh` replayed alone is a clean 3 of 3 |

**The second one is defect 6 wearing different clothes, and that is the point.** Row 6 was already
recorded **Present** on mithril, and the cista 172 column of the table above already spells the
consequence out, "it is what makes run 2 of the oracle report `tests.patch did not apply`". The
mithril review marked row 6 Present and still wrote 3/3 into its opening paragraph, because row 6 is
filed under agent collisions and nobody checking an oracle opens that heading. **When row 6 is
Present, the oracle row is decided too.** Write both down.

The first one is the same shape against `learning/solve-sh-under-sh.md`, which has carried
`blocks_submission: true` since elfuse 162. A standing row nobody executes is indistinguishable from
a rule nobody wrote.

**Defect 1 gained an exploit on this bundle, which changes how it should be reported.** The mithril
review wrote "the invariant is broken but I could not build a working exploit", reasoning from the
runner's own `process.exit(failed === 0 ? 0 : 1)`. That is true about the runner and irrelevant,
because `test.sh:306` is `_find_json(stdout) or _find_json(stderr)`. Two lines added to product
source, one logging an object so the stdout parse fails and one forging an all-pass report on
stderr, give **reward 1.0 with `raw_exit_code 1`** and the bug fully present. Read the parser for a
fallback source before calling row 1 theoretical (LEDGER **L70**).

## Why this reads as a baseline rather than a checklist

A checklist item you fail to find is silently absent. A baseline row you fail to fill is
visibly unanswered. All six of these were found on some task only after a wasted round, and in
every one of those cases the earlier session had looked at the same file and not asked the
question.

The three that are invisible on paper are 1, 3 and 4. Each needs a run: read the NOP's
`raw_exit_code`, read what the NOP reports as executed, and invoke `solve.sh` twice. Budget for
that in the Step 5.5 runs rather than treating the reward as the answer.

## A build-time warm-up that looks dead can be insurance for a default-active profile

Source: `20260728_153118__jqno_equalsverifier__1166`, round 6, 2026-08-10. A peer reviewer asked
for an "unused JaCoCo warmup" to be deleted from the Dockerfile. Nothing at verify time
references JaCoCo: `grep -ic 'jacoco|argline|coverage'` over `tests/test.sh` with the base64
payload stripped returns **0**, and the six hits in `tests/config.json` are all test *class
names* (`CoverageNoInheritanceTest` and friends) in `pass_to_pass`. On that evidence the block
is dead weight, and it was deleted.

It is not dead. The repo's `static-analysis` profile activates on `!disableStaticAnalysis`
(`pom.xml:230-235`), which means **active by default**, and the only thing suppressing it is
`ENV MAVEN_ARGS="-DdisableStaticAnalysis"` in the Dockerfile. Measured in the built image:

```
-- with MAVEN_ARGS as shipped --   compile OK
-- with MAVEN_ARGS unset --
   [ERROR] Plugin org.jacoco:jacoco-maven-plugin:0.8.14 ... could not be resolved:
   [ERROR] Cannot access central (...) in offline mode and the artifact ... has not been
           downloaded from it before.
```

The verifier runs `mvn -o`. Without the warm-up, the moment that ENV is absent or overridden the
run dies at plugin resolution rather than at a test, and every graded id comes back missing.

**Rule: before deleting a build-time warm-up because nothing references it, find the flag that
makes it unnecessary and unset it.** A warm-up exists to make an offline run survive a
configuration you are not currently in. Grepping the verifier tells you the happy path; it does
not tell you what the warm-up is insuring against. The two-line check is to run the offline
build once with the suppressing flag removed.

This is the same shape as the `-buildvcs=false` finding in
[empty-git-refs.md](empty-git-refs.md): a build-time behaviour that is invisible until the
environment shifts one notch.
