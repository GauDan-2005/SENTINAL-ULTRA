---
id: verify-in-the-image
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260809_080653__sysprog21_elfuse__162
  - 20260718_044820__alishahryar1_free-claude-code__929
  - 20260727_135618__AltBeacon_android-beacon-library__1177
  - 20260723_030109__cryspen_libcrux__1165
evidence: "Four static conclusions overturned by re-running the same check inside the task's own container"
applies_to:
  languages: [any]
  runners: [docker]
  phases: [analysis, local-runs]
blocks_submission: false
fails_gate: [peer-review]
supersedes: []
contradicts: []
---

# Verify in the task's image, not on the host

Source: 2026-08-01, task `20260718_044820__alishahryar1_free-claude-code__929`
(`d3797a81`, a Python provider-refactor). The task was analysed from a root-level extract
that has since been removed from the workspace, but both findings below generalise.

Two confident static conclusions in one session, both wrong, both overturned by running the
same check inside the task's own container. The cost each time was a wasted finding written
into a draft report. The rule that comes out of it is one line: **do not report a fact about
the repo until the check that produced it has run inside the image.**

## A third option: build the probe so it compiles at the base commit (elfuse 162, 2026-08-11)

This note tells you to split the graded ids by whether their module compiles at base and run the
ones that do, and CLAUDE.md Step 5.5 offers a symbol audit for the toolchains where you cannot.
Both are recovery moves after the fact. **There is a design that removes the problem instead.**

On `20260809_080653__sysprog21_elfuse__162` the graded harness is a probe that reaches the
feature through a numeric dispatch table rather than by symbol name, so it references nothing the
solution creates and therefore compiles and links against the **unsolved** tree. The NOP then
reads:

```
reward 0, raw_exit 1, infrastructure_error None, passed 8 of 24, missing 16
```

What is **measured** there is that eight ids passed at base, which can only happen if the probe
built, linked and ran against the unsolved tree. That the sixteen failed on behaviour rather than
on a build error is the **inference** that follows, and it is a strong one for exactly that
reason, but it is still an inference and the task's own record carries it as an open caveat. No
split to perform and no symbol audit to disclose; state the eight and let the reader draw the
sixteen.

**The design rule.** When you write a harness from scratch, ask whether it references any symbol
the solution has to introduce. If it does, the base run is compile-bound and every zero you get
from it proves nothing on its own. If it does not, you get the split for free and the NOP becomes
real evidence. This is the same property that let the instruction stop naming internal symbols
(`platform-locked-repos-are-still-testable.md`), so it is usually worth having twice over.

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

## A probe can land and still prove nothing, if it lands on the wrong code path

Added 2026-08-05, `20260727_135618__AltBeacon_android-beacon-library__1177` round 6.

The existing rule here is that a probe has two assertions and the first is that the break landed.
That is necessary and it is not sufficient. Round 6 stubbed the consumer rebind to check the
hostile-delete gate, confirmed the edit had landed (`this.bindInternal(consumer);` went from 2
occurrences to 1, and line 666 read `/* STUBBED */`), ran the suite, and got **230/230 with reward
1**. Read literally that says the rebind requirement has no enforcing assertion.

It was the wrong `bindInternal`. Line 666 is inside a `shouldFailover` branch. The path the graded
test actually drives is `configureScanStrategyWhenConsumersUnbound`, whose rebind is
`BeaconManager.this.bindInternal(consumer)` a few hundred lines earlier. Stubbing that one drops the
reward to 0 and fails `everyScanStrategyCanBeAppliedAndReadBack`.

**So the probe has three assertions, not two:**

1. the edit landed (occurrence count went down, and the new text is on the line you expected)
2. it landed on the code path the graded test reaches
3. the reward moved

Assertion 2 is the one with no cheap mechanical check. When a symbol appears more than once, print
every occurrence with context and pick by reading the call chain from the assertion backwards. A
green suite after a landed stub is ambiguous between "no coverage" and "wrong line", and reporting
it as the first is how a task ships with a coverage claim that is not true.

## A probe guard has to match the direction of the edit

Added 2026-08-06, android-beacon 1177 round 7. Companion to the three-assertion rule above.

The rule says assert the break landed before trusting a green suite. Round 7 wrote that guard as
`occurrences must decrease` and reused it for a probe that **inserts** code - restoring a deleted
lazy-initialisation block. The count went 3 to 3, the guard fired `ABORT: break did not land`, and
the probe reported nothing. The break was fine; the guard was backwards.

So the assertion is not "the count went down", it is "the count moved the way this edit moves it":

| Probe shape | Guard |
|---|---|
| delete or stub a call | occurrences **decrease** |
| restore or inject a block | occurrences **increase** |
| replace a condition | the old text is gone **and** the new text is present |

An aborted probe is not a passing probe, and it is not a failing one either. It is no result, and it
looks exactly like a careful check if nobody reads the line.

## A probe can report "no failures" because nothing compiled (hulak 118, 2026-08-09)

A fourth way a run looks healthy while measuring nothing, and the cheapest to fall for.

While measuring whether a candidate difficulty lever discriminated, one probe removed a block of
Go source and reported **PASSES ALL**, which reads as "this behaviour is not worth grading" and
would have discarded a real lever. The removal had left an `argRequired :=` binding with no
remaining use, which is a **compile error** in Go, so `go test -json` emitted no test events at
all. A harness that counts `Action == "fail"` events sees zero failures and prints success.

The corrected probe fails the named test, so the lever was real and nearly got thrown away.

**The fix is one line in the probe harness, before the test run:**

```bash
if ! go build ./... >/tmp/b 2>&1; then echo "BUILD FAILED, probe invalid: $(head -1 /tmp/b)"; exit 0; fi
```

Generalising past Go: **a probe must distinguish "the suite ran and nothing failed" from "the
suite never ran".** Counting failure events cannot tell those apart. Assert that the run produced
the expected number of test events, or check the build separately. The same reasoning already
appears in this note for a collection abort and for a build tool rejecting a flag; the new part
is that it bites hardest when the probe is the thing deciding whether a lever ships.

Related: the `assert old in s, 'SABOTAGE DID NOT LAND'` guard catches an edit that never applied,
and it did its job in the same session. It cannot catch an edit that applied and then broke the
build, so both checks are needed.
