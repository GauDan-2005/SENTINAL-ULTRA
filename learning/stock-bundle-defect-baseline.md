---
id: stock-bundle-defect-baseline
status: locally-verified
last_verified: 2026-08-04
verified_by:
  - 20260719_045042__oliver-oloughlin_kvdex__245
  - 20260723_030109__cryspen_libcrux__1165
  - 20260727_135618__AltBeacon_android-beacon-library__1177
  - 20260728_153118__jqno_equalsverifier__1166
evidence: "The same six defects were found independently on all four bundles this workspace has handled"
applies_to:
  languages: [any]
  runners: [any]
  phases: [analysis, fixing, local-runs]
blocks_submission: true
fails_gate: [difficulty, oracle, quality-check, peer-review]
supersedes: []
contradicts: []
---

# Six defects every arriving bundle has until you prove otherwise

Sources: all four tasks handled in this workspace, 2026-07-31 to 2026-08-04.
`_archive/20260719_045042__oliver-oloughlin_kvdex__245/task.md`,
`tasks/20260723_030109__cryspen_libcrux__1165/task.md`,
`tasks/20260727_135618__AltBeacon_android-beacon-library__1177/task.md` and
`tasks/20260728_153118__jqno_equalsverifier__1166/task.md`.

Four tasks, four different languages, four different build systems, and the same six findings
every time. They are not coincidences between bundles. They come from the stock Harbor scaffold
the task generator emits, so a bundle carries them the moment it is created and it keeps them
until an EC takes them out.

The cost of rediscovering them is not the reading. It is that each one was found late on at
least one task, after a round had already been spent, and two of them are the reason kvdex 245
took six rounds instead of two.

**Treat all six as present until a command or a file and line says otherwise.** Filling this
table is a Step 2 job, before any verdict.

| # | Defect | Verdict | What decides it |
|---|---|---|---|
| 1 | Fail-open grader. `test.sh` records `raw_exit_code` and never branches on it | Present / Absent / NA | `grep -n 'raw_exit_code' tests/test.sh` and read whether the success expression uses it |
| 2 | No regression guard. `pass_to_pass` empty, `allow_extra_failures` true | Present / Absent / NA | `python3 -c "import json;g=json.load(open('tests/config.json'))['grading'];print(len(g['pass_to_pass']),g.get('allow_extra_failures'))"` |
| 3 | Stale test results baked into the image at build time and read by the grader | Present / Absent / NA | Does the Dockerfile run the suite? Does the grader glob a report directory the build wrote? Confirm in the NOP run, not on paper |
| 4 | `solve.sh` not idempotent, usually a reverse-apply fallback that reports success | Present / Absent / NA | Read `solution/solve.sh`, then run it twice in one container and diff the tree |
| 5 | Graded test files carry the name an agent would choose for its own test | Present / Absent / NA | Read the paths `tests.patch` creates against the class the instruction asks for |
| 6 | No test-tree restore before `tests.patch` is applied, or one built on git | Present / Absent / NA | `grep -n 'git\|rm -rf\|base64' tests/test.sh` around the apply step |

`NA` is a real answer and needs the same evidence as the other two. A task whose Dockerfile
never runs the suite genuinely cannot have defect 3.

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
