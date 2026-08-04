# Verifiers that read stale test results baked into the image

Source: task `20260728_153118__jqno_equalsverifier__1166`, 2026-08-01. Found during the NOP
run, not by reading the files.

## What happened

Two of the twenty-one fail-to-pass tests reported PASS on the **unmodified** repo. They
should be impossible to pass before the fix.

The cause is a collision between two reasonable-looking things:

1. The Dockerfile warms the dependency cache by running the real test lifecycle at build
   time, which is the right way to guarantee an offline verifier run:

   ```dockerfile
   RUN n=0; until mvn -B test; do ... done
   ```

2. The grader harvests results by globbing the build output:

   ```python
   for path in sorted(glob.glob('**/target/surefire-reports/TEST-*.xml', recursive=True)):
   ```

Step 1 leaves the reports in the image. Step 2 reads them. Proven directly by running the
parser in a fresh container with no Maven invocation at all:

```
$ docker run --rm <image> bash -c 'cd /app && python3 - <<PY ... PY'
testcases readable WITHOUT running any test: 1284
```

## Why it matters

- A fail-to-pass test whose class already existed at the base commit reports PASS from the
  stale XML, so it is not really fail-to-pass.
- Far worse, **`pass_to_pass` becomes an illusion**. An agent whose code does not compile
  produces no fresh reports, so the stale ones stand in and every pass-to-pass test
  "passes". The regression guard silently grades nothing.
- In spirit this is the "pre-created artifact passes" auto-REMOVE pattern: results exist
  before the agent has done anything.

It hides well. The oracle run looks perfect, because a compiling solution overwrites every
report. Only the NOP exposes it, and only if you look at *which* tests passed rather than
just the reward.

## The fix

Purge the stale output before running, in `execution.commands`:

```json
"commands": [
  "rm -rf ./*/target/surefire-reports && mvn -o -B -pl ... test -Dmaven.test.failure.ignore=true",
  ...
]
```

After the change the NOP run reports 0 tests instead of 1282, and the reward-0 result means
what it says. Adding `clean` to the Maven goals also works but throws away the compiled
classes and slows every run.

## How to catch it on any task

The pattern is not Maven-specific. It applies wherever the Dockerfile runs the test suite at
build time and the grader reads result files from a fixed path: pytest with
`--junitxml`, Jest with `--outputFile`, Go with a saved JSON log, and so on.

Two cheap checks:

```bash
# 1. can the grader find results with no test run at all?
docker run --rm <image> bash -c 'ls **/target/surefire-reports/TEST-*.xml 2>/dev/null | wc -l'

# 2. on the NOP run, look at WHICH tests passed, not just the reward
python3 -c "
import json; r=json.load(open('logs-nop/report.json'))
print('passed pre-patch:', set(r['required_tests']) - set(r['missing_required_tests']))"
```

Anything non-empty in either check means the verifier is reading results the agent did not
produce. **A NOP reward of 0 is necessary but not sufficient** — always check that it is 0
for the right reason.
