# Graders that award reward 1.0 while the test command exited nonzero

Source: peer-review notes on task `20260716_114438__ETLCPP_etl__1466` (ETLCPP/etl PR 1466),
reviewed 2026-08-02. **Provenance:** a reviewer's finding on another EC's bundle, read from
their session transcript, not reproduced on this machine. The reviewer says they reproduced
it directly, and the shape is easy to check on any task, so treat it as a standing audit
step rather than a one-off.

## What happened

The bundle cleared every platform eval and came back with this:

> The embedded grader records `raw_exit_code` but does not use it when determining success.
> I reproduced reward 1 with all required test lines present and `raw_exit_code = 1`. Any
> nonzero test command exit, including compilation failure, timeout, crash or partial
> execution, must fail closed with reward 0.

The grader was not sloppy in an obvious way. It ran the suite, captured the output, scanned
it for the fail-to-pass test names, and wrote `1.0` when it found them all. It even recorded
the process exit status into the result JSON. It just never branched on it.

## Why it matters

A parse-only grader is satisfied by the *text* of a successful run, which is not the same as
a successful run:

- A C++ suite that compiles some translation units, prints their passing lines, then fails
  the build on a later file — expected lines present, exit nonzero, reward 1.0.
- A suite killed by the verifier timeout after the graded tests happen to print first.
- A crash or OOM partway through, where the graded names appear before the process dies.
- A harness that exits nonzero because *setup* failed while a stale or partial log satisfies
  the parser. This is the same failure surface as `learning/stale-test-reports.md`.

`docs/guidelines.md` states the invariant directly under its example `test.sh`: **"The exit
code should match the reward it writes."** The reference implementation is a plain
`if pytest; then echo 1.0; else echo 0.0; exit 1; fi`. A grader that reaches `1.0` on a
nonzero exit contradicts it. It is also the `Fail-open` auto-REMOVE pattern from
`docs/tasking-guide.md` — "a missing or malformed artifact must fail the suite, never pass
it" — applied one level up, to the run itself rather than an output file.

Recording the status without gating on it is worse than not recording it, because it looks
deliberate to a reviewer.

## The rule

Read the grader on **every** task, not just Fixable ones, and trace how the reward is
decided. Three things must hold:

1. Reward `1.0` requires the test command's exit status to be zero **and** every
   fail-to-pass id to have passed. Either one failing means `0.0`.
2. `test.sh` itself exits nonzero whenever it writes `0.0`.
3. `set -euo pipefail`, and nothing on the line that runs the suite ends in `|| true`. If the
   suite must be allowed to fail so its output can be parsed, capture the status explicitly
   and branch on it later — do not discard it.

Shape that satisfies all three when the run has to be parsed rather than trusted wholesale:

```bash
set -euo pipefail

set +e
<test command> 2>&1 | tee /logs/verifier/test-stdout.txt
raw_exit=${PIPESTATUS[0]}
set -e

if [ "$raw_exit" -ne 0 ]; then
  echo "0.0" > /logs/verifier/reward.txt
  exit 1
fi
# only now parse the log for the graded ids
```

Note `${PIPESTATUS[0]}` — with `tee` in the pipeline, `$?` is `tee`'s status and is
essentially always zero. A grader that reads `$?` after a pipe is fail-open even when it
looks like it is checking.

## It is the stock harness, not one EC's mistake

Source: `20260728_153118__jqno_equalsverifier__1166`, 2026-08-02, and confirmed by reading the
other two bundles in this workspace.

The note above reads as a warning about someone else's grader. It is not. The generic
`tests/test.sh` that ships with these tasks has the defect **as delivered**, in the embedded
`grade.py`:

```python
    "raw_exit_code": args.raw_exit_code,     # recorded in base_report
    ...
    success = not missing_required and not unexpected     # never consults it
    reward = 1.0 if success else 0.0
```

That is the reviewer's finding word for word, in the file every task starts from. All three
tasks in this workspace shipped it. If you did not edit `test.sh`, your task has it.

The `execution.commands` layer throws the status away too, in a different way per task:
kvdex pipes `deno test | python3 …` so the runner's status is python's, android-beacon ends
its gradle line with `|| true`, equalsverifier uses `-Dmaven.test.failure.ignore=true`.

### The runner runs several commands, so `set -e` is part of the fix

`execution.commands` is a list, and the generated `/tmp/run_tests.sh` runs them in sequence.
Its exit status is therefore the **last** command's. On a task whose commands are "run the
suite" then "parse the results into the graded format", a failing suite followed by a
successful parser gives status 0 and the gate never fires. Emit `set -e` at the top of the
generated script so the first failure propagates:

```python
print("set -e")
for cmd in commands:
    print(cmd.replace("${TEST_FILES}", files_arg))
```

### `set -e` is not enough when the command is a pipeline

Source: `20260719_045042__oliver-oloughlin_kvdex__245`, 2026-08-02, measured in the task image.

The `set -e` fix above covers a *list* of commands. It does nothing for a single command that
is itself a pipeline, and that is the shape kvdex ships:

```
NO_COLOR=1 deno test --cached-only ... | python3 -c '<result parser>'
```

`set -e` does not fail a pipeline whose last element succeeds. The parser always succeeds, so
the status stays 0 no matter what the runner did. You need `pipefail` as well.

The trap underneath it: `test.sh` already opens with `set -uo pipefail`, which looks like it
covers this and does not. The generated script runs as a **separate `bash` invocation**
(`bash /tmp/run_tests.sh`), and shell options are not inherited by a child shell. So the
pipeline runs with default options however carefully `test.sh` was written.

Measured on the NOP run before the fix: `raw_exit_code 0` with **zero tests having run at
all**, because `tests/ext/encoder.test.ts` cannot resolve the encoding module at base and
deno exits nonzero while python exits 0. Reward was still 0, but only because the
required-test check caught it, not because the status did.

One-line fix, at the point the runner is invoked:

```bash
RUNNER=(bash -o pipefail /tmp/run_tests.sh)
if [ -n "${TIMEOUT_SEC:-}" ] && command -v timeout >/dev/null 2>&1; then
  RUNNER=(timeout "${TIMEOUT_SEC}" bash -o pipefail /tmp/run_tests.sh)
fi
```

After it the NOP reports `raw_exit_code 1`. Emitting `set -e` into the generated script and
passing `-o pipefail` to the shell that runs it are complementary, not alternatives. A task
with several commands needs the first, a task whose command is a pipeline needs the second,
and plenty of tasks need both.

### Measure the runner's true exit on a green tree BEFORE you gate on it

Also from the kvdex round, and it is the step that makes the gate safe to add.

Once `pipefail` is on, the status the grader sees is the real one, and gating on it will fail
the oracle if the runner exits nonzero for a reason unrelated to the graded tests. Some
runners do: leak or sanitizer complaints, a nonzero code for skipped tests, a flaky teardown.
Find out before you wire the gate, not after.

```bash
docker run --rm --network none -v "$PWD/tests:/tests:ro" -v "$PWD/solution:/solution:ro" <image> \
  bash -c 'set -o pipefail; cd /app && bash /solution/solve.sh >/dev/null 2>&1 \
    && git apply /tests/tests.patch
    <the exact execution.commands entry, unpiped> ; echo "bare exit=$?"'
```

kvdex answered `bare exit=0` with `ok | 152 passed (500 steps) | 0 failed | 2 ignored`, so the
gate was safe. If it had answered nonzero on a fully green tree, the correct move is to leave
the gate out and write the reason into Comments for Reviewer rather than ship a verifier that
fails the oracle.

Note the `2 ignored` in that line. Tests the runner reports as ignored emit neither a PASS nor
a FAIL through the parser, so an upstream `Deno.test.ignore` is not a hazard when flipping
`allow_extra_failures` to `false`. Confirm the same for whatever runner the task uses before
flipping it.

### Do NOT fail closed by writing an infrastructure_error

This is the part that is easy to get wrong and expensive. The obvious implementation is an
early exit in `test.sh` right after `TEST_EXIT_CODE=$?`, writing the same
`{"infrastructure_error": ...}` report the other bailout paths use. Do not do that.

The difficulty harness reads `infrastructure_error` as **the trial was invalid**, not as
"the agent failed". An agent whose code does not compile produces a non-zero test command, so
every such trial would be scored invalid instead of failed, and the difficulty verdict becomes
untrustworthy in exactly the way `tests-patch-vs-agent-edits.md` describes. You would trade a
fail-open grader for a poisoned difficulty run.

Gate inside the grader instead, so the full per-test report survives and the run is still
classified as an ordinary grading failure:

```python
success = not missing_required and not unexpected and args.raw_exit_code == 0
```

Verified on the NOP run after the change: `reward 0`, `raw_exit_code 1`,
`infrastructure_error: None`, `0 of 1223` — reward 0 for the right reason, still a valid trial.
The oracle is unaffected at `raw_exit_code 0`, `1223 of 1223`.

## How to catch it locally

The NOP run is where this shows. Check both numbers, not just the reward:

```bash
# expected on NOP: reward 0.0 AND a nonzero exit
bash tests/test.sh; echo "test.sh exit: $?"
cat /logs/verifier/reward.txt
```

Then force the case the reviewer used, on a disposable copy: break the build on purpose —
delete a header the suite includes, or add a syntax error to a file the graded tests do not
touch — and run the verifier again. If reward is anything other than `0.0`, the grader is
fail-open. This takes about a minute and is worth doing on any task whose `test.sh` parses
stdout instead of returning the runner's own status.

## The gate also lets a command enforce a requirement no test id can

Source: `20260723_030109__cryspen_libcrux__1165`, 2026-08-02, measured in the task image.

That task's instruction opens its constraints with "with the feature disabled the crate builds
and behaves unchanged". Nothing could test it. The graded suite runs *with* the feature on, so
no assertion inside it can observe the feature being off, and the shipped config ran exactly one
command against exactly one test target.

Once the exit-code gate is in and `set -e` is emitted into the generated runner, a plain build
command becomes a graded requirement:

```json
"commands": [
  "cargo test -p libcrux-ml-kem --features pqcp,rand --test sentinel_pqcp_verifier",
  "cargo test -p libcrux-ml-kem --features pqcp,rand --test self --test ml-kem -- --skip _avx2 --skip _neon",
  "cargo build -p libcrux-ml-kem"
]
```

The third line builds with default features, so without the new one. It emits no test lines and
owns no `fail_to_pass` id. It still decides the reward, because a failure propagates through
`set -e` to the runner's status and the gate turns that into `0.0`.

Proven by breaking exactly that requirement and nothing else: correct solution, one `cfg` gate
dropped so the crate no longer compiles without the feature.

| | graded tests | reward |
|---|---|---|
| bundle as received | 40 of 40 passed | **1.0** |
| after the gate + build command | 40 of 40 passed | **0.0** |

`infrastructure_error` stayed `None`, so the trial is still an ordinary graded failure rather
than an invalid one.

**Rule: when the instruction states a requirement that no assertion can reach (it builds under a
different feature set, it compiles for another target, a lint or a format holds), express it as a
command in `execution.commands` rather than leaving it untested.** It only works if the gate and
the `set -e` are both in place, so wire those first, and confirm on the oracle that the added
command exits 0 on a green tree before trusting it.
