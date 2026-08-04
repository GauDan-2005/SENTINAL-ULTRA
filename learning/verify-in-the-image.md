# Verify in the task's image, not on the host

Source: 2026-08-01, task `20260718_044820__alishahryar1_free-claude-code__929`
(`d3797a81`, a Python provider-refactor). The task was analysed from a root-level extract
that has since been removed from the workspace, but both findings below generalise.

Two confident static conclusions in one session, both wrong, both overturned by running the
same check inside the task's own container. The cost each time was a wasted finding written
into a draft report. The rule that comes out of it is one line: **do not report a fact about
the repo until the check that produced it has run inside the image.**

## 1. The host interpreter is not the task's interpreter

The base repo carried seven files with Python 2 style handlers:

```python
except ValueError, RuntimeError:          # providers/error_mapping.py:61
except TypeError, ValueError:             # core/anthropic/tokens.py:103
except asyncio.CancelledError, GeneratorExit:   # providers/transports/openai_chat/stream.py:216
```

Host `python3` is 3.12 and flags all seven:

```
$ python3 -c "import ast; ast.parse(open('providers/error_mapping.py').read())"
SyntaxError: multiple exception types must be parenthesized
```

From that I concluded the Dockerfile's build-time sanity step

```dockerfile
RUN python -m pytest --collect-only -q >/dev/null && ...
```

would abort collection and fail the build. It does not. The image is `python:3.14-slim` and
the repo declares `requires-python = ">=3.14.0"`. **PEP 758 landed in Python 3.14 and makes
unparenthesized `except A, B:` valid** when there is no `as` clause. Inside the image:

```
$ docker run --rm <image> bash -c '/app/.venv/bin/python -VV'
Python 3.14.0
$ docker run --rm <image> bash -c 'cd /app && /app/.venv/bin/python -m pytest --collect-only -q | tail -1'
1673 tests collected in 1.35s        # exit 0, zero collection errors
```

An `ast.parse` sweep of the whole tree inside the container reports **0** files with syntax
errors against the host's 7.

### What it changed

The finding flipped rather than disappeared, which is why this is worth logging. It was not
"the environment is broken". It was "the instruction asserts something false about its own
environment": the instruction told the agent these handlers had to be parenthesized so the
modules would be "valid Python 3.11+" and that any left unparenthesized would "abort the
suite". Neither holds under 3.14. The oracle's three parenthesisation edits are cosmetic
no-ops that are also absent from the source PR.

### Rule

Before treating any syntax, lint, type or import result as a fact about the task, read the
runtime the image actually uses — `FROM` in the Dockerfile, `.python-version`,
`requires-python` in `pyproject.toml`, the toolchain version in `package.json` / `go.mod` —
and re-run the check there. Language-version-dependent syntax is the trap; a repo pinned
ahead of the host toolchain will look broken and is not.

### Gotcha: `bash -lc` hides the venv

```
$ docker run --rm <image> bash -lc 'python -m pytest --collect-only -q'
/usr/local/bin/python: No module named pytest        # WRONG
```

A login shell re-sources `/etc/profile` and drops the `ENV PATH="/app/.venv/bin:..."` the
Dockerfile set. Use `bash -c`, or call the interpreter by absolute path
(`/app/.venv/bin/python`). This looks exactly like a broken image and is not one.

## 2. A NOP reward of 0 also hides f2p tests that already pass

`stale-test-reports.md` covers the case where stale result files make tests report PASS with
nothing run. This is the opposite mechanism reaching the same blind spot, and its check does
not catch it.

The NOP run looked textbook — reward `0`, exit 1, all 17 fail-to-pass ids listed in
`missing_required_tests`. But the run had not graded anything:

```
=========================== short test summary info ============================
ERROR tests/providers/test_gemini.py
ERROR tests/providers/test_nim_request_clone.py
ERROR tests/providers/test_nvidia_nim.py
ERROR tests/providers/test_nvidia_nim_request.py
!!!!!!!!!!!!!!!!!!! Interrupted: 4 errors during collection !!!!!!!!!!!!!!!!!!!!
```

Four modules import the refactor's target modules, which do not exist at base, so pytest
aborted the session. Nothing ran. Every f2p id was reported missing because the run died,
not because the test failed.

Running the four files that *do* import, directly against the base repo with `tests.patch`
applied, showed **3 of the 17 f2p tests already pass before any fix** — all three in
`tests/providers/test_open_router.py`, because the behaviour they assert
(`OPENROUTER_DEFAULT_MAX_TOKENS` is an aliased import of `ANTHROPIC_DEFAULT_MAX_OUTPUT_TOKENS`,
and the reserved-field rejection) already existed at base. Genuine f2p count was 14, not 17.

Why the existing check misses it: with everything marked missing,

```python
set(r['required_tests']) - set(r['missing_required_tests'])   # -> empty set
```

returns empty and reads as a clean all-clear.

### Rule

On every NOP run, read the pytest summary line before the per-test breakdown:

```bash
grep -E 'Interrupted|errors during collection|short test summary' logs-nop/test-stdout.txt
```

If collection aborted, the reward is meaningless as a per-test signal. Re-run the f2p files
that import cleanly, on their own, against the base repo:

```bash
docker run --rm --network none -v "$SP/run/tests:/tests:ro" <image> bash -c '
  cd /app && git apply /tests/tests.patch &&
  /app/.venv/bin/python -m pytest -v -n0 <files that import cleanly>' | grep -E 'PASSED|FAILED'
```

Anything `PASSED` there is not a fail-to-pass test. Move it to `pass_to_pass` or replace it,
and re-count against the 10–20 static-check range in [static-checks.md](static-checks.md).

**Restated:** a NOP reward of 0 is necessary, never sufficient. Confirm it is 0 for the right
reason — not from stale results ([stale-test-reports.md](stale-test-reports.md)), and not
from a collection abort.

## 3. The same check on a compiled language, where there is no "files that import cleanly"

Source: `20260728_153118__jqno_equalsverifier__1166`, 2026-08-02. Java and Maven, so the
pytest recipe above does not apply, and the blind spot is worse rather than better.

The NOP looked textbook: reward 0, exit 1, all ids in `missing_required_tests`. It had graded
nothing. The f2p tests reference classes that do not exist at base, so
`equalsverifier-core`'s **test sources do not compile**, Maven fails the module, and the
reactor never reaches the module holding the rest of the graded tests. Every id comes back
missing whether it would have passed or not.

pytest gives you "run the files that import cleanly". A compiled language does not: one broken
file takes down the whole compilation unit. The equivalent move is to **put the uncompilable
sources back and run what is left**:

```bash
cd /app
git apply /tests/tests.patch
git checkout <BASE_COMMIT> -- equalsverifier-core/src/test   # the module that cannot compile
git clean -fdq equalsverifier-core/src/test                  # drop the new files it added
mvn -o -B -pl equalsverifier-test -am test -Dtest=SealedTypesRecursionTest \
    -DfailIfNoTests=false -Dmaven.test.failure.ignore=true
```

Then read per-test outcomes out of the XML rather than trusting the reward.

**It found a real one.** Of the four graded ids in that class, three failed at base and
`succeed_whenSutIsSealed_givenFirstPermittedRefersBackToContainerButSecondIsOk` **passed**. The
recursion bug only bites when a container holds the sealed interface, not when the sealed
interface is the subject itself. So it was never a fail-to-pass test, it had been sitting in
`fail_to_pass` through several rounds, and nothing in the NOP could ever have shown it. Moved
to `pass_to_pass`, count 20 to 19.

### Rule

Split the graded ids by whether their module compiles at base. For the ones that cannot
compile, "no test can pass because the symbol does not exist" is a sound argument and worth
writing down. For every id in a module that **does** compile at base, run it and read the
result. That second group is where an accidental pass-to-pass hides, and it is exactly the
group whose assertions you are most likely to have relaxed while fixing something else.

## 4. A third shape: the build tool refuses the flag before anything compiles

Source: `20260723_030109__cryspen_libcrux__1165`, 2026-08-04, measured in the task image.

pytest gives you a collection abort. Maven gives you a module that will not compile. Cargo gives
you a third thing, and it is the earliest of the three:

```
error: the package 'libcrux-ml-kem' does not contain this feature: pqcp
```

The graded command is `cargo test -p libcrux-ml-kem --features pqcp,rand --test ...`. At base the
feature does not exist yet, because creating it *is* the task, so cargo rejects the command line
itself. Nothing is compiled and nothing is collected. `test-stdout.txt` is **zero bytes**,
`raw_exit_code` is 101, every graded id lands in `missing_required_tests`, and the reward is a
textbook 0.

It looks identical to a healthy NOP and proves even less than the other two shapes, because the
run stopped before the compiler was invoked. Any feature-flag, build-profile, target or
config-file task can produce it. The generic tell is an empty stdout log next to a nonzero exit.

The recovery is the same as the rest of this note, run the checks the NOP could not:

```bash
# does the graded file compile to nothing without the feature?
cargo test -p <crate> --features <base-only features> --test <graded target> -- --list
#   -> "0 tests, 0 benchmarks" means no f2p test exists at base, let alone passes

# do the pass_to_pass ids actually pass at base?
cargo test -p <crate> --features <base-only features> --test <p2p targets> -- --skip ...
```

On this task those answered `0 tests, 0 benchmarks` and `21 of 21 passing`, which is the pair of
facts the NOP was silently standing in for. Note the round before had written "the graded file
compiles to zero tests, so no fail-to-pass test can pass" into Comments for Reviewer as the
*reason* the NOP was 0. The claim happened to be true, but it was not what the NOP measured, and
a reviewer reproducing it would have found an empty log and a cargo error instead.

**Rule: when the NOP's stdout log is empty, do not describe what the tests did. Nothing ran.
Say which command refused and then measure the two things separately.**

## 5. A hostile probe that comes back healthy usually means your break missed

Same task and session, and it cost two wasted container runs.

Two of the probes returned `reward 1.0, 35 of 35`, which reads as "the guard does not work".
Both times the guard was fine and the *probe* was broken. The `perl -0pi` substitutions had been
pointed at `mlkem512.rs` / `mlkem768.rs` / `mlkem1024.rs`, while the lines that mattered were
generated from macros in `src/pqcp.rs`. The edit ran, exited 0, changed nothing relevant, and the
solution stayed correct, so of course the verifier passed it.

That failure is indistinguishable from a real finding unless you check. A `sed`/`perl` that
matches nothing is silent, and a probe that does not break anything always looks like a verifier
that fails to notice.

**Rule: a hostile probe has two assertions, not one. Prove the break landed, then read the
reward.** Print the evidence inside the same container run:

```bash
echo "before: $(grep -c '<the thing you are removing>' <file>)"
perl -0pi -e 's/...//' <file>
echo "after:  $(grep -c '<the thing you are removing>' <file>)"
bash /tests/test.sh
```

`before: 1 / after: 0` and then `reward 0` is a result. `reward 1` with no evidence of the edit
is a bug in your probe. Re-pointed at `src/pqcp.rs`, both probes immediately gave
`reward 0.0` with `0 of 35` and `35 of 35` respectively, matching what the previous round had
recorded.
