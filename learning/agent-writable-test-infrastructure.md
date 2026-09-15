---
id: agent-writable-test-infrastructure
status: locally-verified
last_verified: 2026-08-18
verified_by:
  - 20260803_111822__nolabs-ai_deepfabric__297
  - 20260805_220102__xaaha_hulak__118
  - 20260723_030152__mithriljs_mithril.js__2021
  - 20260720_144200__thomas4019_expressa__132
  - 20260724_132921__gnmyt_MySpeed__1536
evidence: "render/render.js left at base, one clause added to ospec/ospec.js record(), verifier returned reward 1.0 with 15/15 and git diff on render.js empty"
applies_to:
  languages: [any]
  runners: [any]
  phases: [analysis, fixing, local-runs, peer-review]
blocks_submission: true
fails_gate: [quality-check, peer-review]
supersedes: []
contradicts: []
---

# The agent can rewrite the thing that grades it

`tests.patch` protects the **graded test bodies**. Nothing protects the **assertion library those
bodies call**, and on most repositories that library lives in the agent's own writable checkout.
An agent that edits it wins without doing the task.

Measured on mithril.js 2021, in the built image, `--network none`:

```
render/render.js left at the BASE commit. No solution applied.
Agent edits ONE clause in ospec/ospec.js:
    function record(message, error) { message = null; ...

  test.sh exit = 0
  reward     = 1
  passed     = 15 / 15
  unexpected = 0
  git diff --stat render/render.js  ->  (empty, never touched)
```

The same route was open through `test-utils/domMock.js` and `test-utils/components.js`, which the
graded specs also `require` from the agent's tree.

## Why the existing Section 10.3 measurement does not catch it

`.claude/rules/11-verifier-hardening.md` Section 10.3 ships a snippet that counts **how many graded
ids live in files `tests.patch` does not touch**, and picks the restore shape from the answer. On
mithril it returned `0 of 15 graded ids live outside the patched files`, whose documented reading is
"create-only patch would suffice".

That answer is correct **for collisions** and says nothing about this. The gaming route runs through
`ospec/` and `test-utils/`, which `tests.patch` never touches at all, so they are invisible to a
count over patched files. Two different questions:

| Question | Answered by | Fix |
|---|---|---|
| Can an agent's own edit break the patch apply? | the 10.3 snippet, counting graded ids outside patched files | create-only `tests.patch`, or a full-tree payload |
| Can an agent's own edit **fake a pass**? | the probe below | restore the test **infrastructure**, not just the specs |

A create-only `tests.patch` scores perfectly on the first and leaves the second wide open.

## The probe. Run it on every task, submitter or reviewer

Cheap, about two minutes once the image exists. Leave the solution **unapplied** so any reward above
zero is unearned.

```bash
# in the built image, with /tests and /solution mounted
cd /app && git reset --hard HEAD && git clean -fdq      # base tree, NO solve.sh
python3 /probe/sabotage.py <assertion-lib-path> "<exact needle>" " <neutering clause>"
bash /tests/test.sh
#   reward 1  -> the suite is gameable. Finding.
#   reward 0  -> report how far it got; partial credit is still information.
```

**The needle must be asserted**, exactly as `bin/hostile-probe.sh` does with its exit code 3. Two
hand-rolled `sed` probes in this session silently matched nothing and produced a confident wrong
answer both times, one of which nearly shipped as a blocking reviewer finding. Use
`bin/hostile-probe.sh`, or copy its assertion:

```python
assert needle in s, "NEEDLE NOT FOUND: " + needle[:70]
```

Where the library lives, per ecosystem: `ospec/ospec.js` and `test-utils/` (mithril), `chai`/`expect`
under `node_modules` or a vendored `test/helpers`, `conftest.py` and any local `assert_*` helper
(pytest), a `testify` vendor directory or an in-repo `assert` package (Go), `src/test/.../TestUtils`
(JVM). The tell is any path the graded test `require`s or imports that `tests.patch` does not create.

## Four data points, and they differ

| Task | assertion library neutered | Reading |
|---|---|---|
| mithril.js 2021 | base tree, **reward 1.0, 15 of 15** | fully gameable, filed as the review's lead finding |
| expressa 132 | base tree, reached **15 of 21**, reward 0 | not trivially gameable, and the reviewer said so in the "what is right" section |
| cista 172 | golden plus a broken stamp, **reward 1.0, 21 of 21** | partially gameable, and the split is the interesting part |
| hulak 118 | **never run** | Go, where the route has no analogue and the residue is at its purest. Below |

So the probe discriminates rather than always firing, which is what makes it worth running. A bundle
that resists it has earned the sentence saying so.

**cista 172 also changes how the probe is run on a compiled language, and what its result means.** The
"leave the solution unapplied" form is not available there: the graded translation units name symbols the
base commit does not have, so the compile fails before any assertion runs and the probe measures a build
error. Apply golden first, then break **one** stated requirement, then neuter the library, and read the
delta against the same break without the neuter. Measured, `tools/doctest/doctest.h` and `doctest.cc`
tracked in the repo and pulled in by the graded compile line itself:

| tree | reward | passed |
|---|---|---|
| golden, stamp value off by one | 0 | 20 of 21 |
| the same, plus `CHECK` and `REQUIRE` redefined to `((void)0)` | **1** | **21 of 21** |

**And the compile-time layer is a speed bump, not a wall.** The first version of this section said the
`static_assert` ids were "immune for free". That is wrong, and the correction is measured. Of cista's 21
ids, **15** carry a `static_assert` mirroring their `CHECK` and **6** are runtime-only (the 4 graph ids
plus `hash is written as first bytes of buffer` and `output larger than without version stamp`). With
the array `Size` dropped from the hash so the implementation is genuinely broken:

| edit | reward | passed |
|---|---|---|
| doctest neutered only | 0 | 4 of 21 (the compile fails, so the 15 still bite) |
| `#undef static_assert` plus `#define static_assert(...) static_assert(true, "")` appended to `include/cista/type_hash/static_type_hash.h`, only | 0 | 20 of 21 (the mirroring `CHECK`s still bite) |
| **both** | **1** | **21 of 21** |

Neither layer alone is enough and both together are. The macro goes into a header the **solution**
creates, so the agent owns that file outright and no restore payload can protect it without deleting the
agent's own work. So mirroring a `CHECK` with a `static_assert` is worth doing, because it costs the
attacker a second edit, and it is not a defence you can claim in an answer. It also follows that the
runtime-only minority is where the cheapest attack lands, not where the only one does.

## The fix, and it is not the create-only patch

Restore the test infrastructure at the top of `tests/test.sh`, before `tests.patch` is applied, from
a base64 payload embedded in `test.sh` (Section 10.3 shape). Cover the graded spec directory **and**
every path those specs import: on mithril that is `render/tests`, `ospec` and `test-utils`. Delete
then unpack, then apply the patch. Do not build it on git, for the reason L1 to L3 already record.

## Three files measured, not one, and the restore has a bound (mithril.js 2021, re-measured 2026-08-11)

The first pass measured `ospec/ospec.js` and **read** the other two off the require lines. Both are
now run, with `render/render.js` at the base commit and no solution applied:

| file the agent edits | reward | passed |
|---|---|---|
| `ospec/ospec.js`, `record()` forced to pass | 1.0 | 15 of 15 |
| `test-utils/domMock.js`, wrapper rebinding the assertion prototype on first call | 1.0 | 15 of 15 |
| `test-utils/components.js`, same wrapper on each kind's `create` | 1.0 | 15 of 15 |

One failed attempt is worth recording because it looks like a closed route and is not. Patching
domMock at **module load** throws `Assertions should not occur outside test definitions` and scores
0 of 15. Doing it inside `o.beforeEach`, where assertions are legal, scores 15 of 15. A probe that
fails is not evidence the route is closed.

**Two bounds on the restore, both measured.**

- **The delete list must come from the patch, not from a directory list.** With all three
  directories restored pristine, an agent-written `ospec-json-runner.js` at the **repo root** still
  breaks `git apply`, `git apply --3way` and `patch -p1 --forward`. `tests.patch` creates that file
  outside every directory the restore covers. Read the creates out of the patch:
  `sed -n 's|^+++ b/||p' /tests/tests.patch`. LEDGER **L71**.
- **A restore cannot close the class, only narrow it.** The graded specs load six agent-writable
  files into one process and three are library source (`render/render.js`, `render/vnode.js`,
  `render/hyperscript.js`) that no verifier may restore, since a correct solution is allowed to
  touch them. Measured: 13 lines added to `render/render.js` alone, rebinding the ospec assertion
  methods to self-comparisons at the first `render()` call, gives reward 1.0 at 15 of 15 with
  `ospec/` and `test-utils/` byte identical to base. The blunt version that no-ops every assertion
  method scores 0 of 15, because it also kills the runner's own marker assertions, which is why the
  naive attack fails and the surgical one does not. **Do not answer this by lengthening the restore
  list.** What covers the residue is the exit-code gate in `verifier-fail-open.md`.


## Go has no assertion-library route, and that is not the same as being safe (hulak 118, accepted 2026-08-16)

The first Go bundle to meet this note, and it meets it by having nothing for the probe to aim at.
The assertion layer is the stdlib `testing` package, which does not live in the agent's checkout, so
the mithril route has no analogue: there is nothing under `environment/repo` to neuter. Measured on
the accepted bundle, the two graded files import only `strings`, `testing`, `time`, bubbletea,
lipgloss and two in-repo product packages, and `tests/test.sh` deletes every `*_test.go` and unpacks
all 46 base test files before applying the patch.

**What survives is the Section 10.11 residue in its purest form.** `tests/tests.patch` declares
`package gqlexplorer` and `package tui`, so both graded files are **internal-package** tests, and
every `.go` file the agent writes in those two directories compiles into the same test binary.
`go.mod` and `go.sum` are not restored either. So the agent cannot touch the assertion library and
does not need to: it shares a process, a package scope and a module graph with the thing grading it.

That residue is closed only by the exit-code gate, and on a `-json` runner that is an **argument
rather than a measurement**. This bundle's parser is `go-test` reading `stdout_stderr`, and
`parse_go_test` accepts any `{`-leading line carrying an `Action` of pass, fail or skip from either
stream. The open question nobody has run is whether a product-source `init()` can suppress the real
run and emit output `test2json` converts into pass events while `go` still exits 0.

**So on a Go task, Run 4 has a specific shape and it is not the JS one.** Solution unapplied, one
`init()` added to a **non-test** file in a graded package that rewrites `os.Args` to
`-test.run=^$` and prints `=== RUN` and `--- PASS:` lines for every graded id, then
`sh /tests/test.sh`, reading `reward.txt` and `raw_exit_code`. Use `bin/hostile-probe.sh` so the
edit proves it landed.

**And the reason this row says "never run" is the finding.** hulak ran five batteries across four
rounds. Run 4 appears in none of them, under any name. Four rounds of platform checks and two human-reviewer
rounds passed it anyway, because **nothing in the loop reads a battery table for missing rows** -
a table with three green rows looks exactly like a table with four minus one. Write the four Phase B
runs by name into every round record, with a result or the words NOT RUN beside each, so an absent
run is visible as an absence.

## The pytest shape, and why the exit-code gate does not close it

Fifth data point, deepfabric 297, measured 2026-08-17 with the solution never applied. On pytest the
assertion library is the interpreter, so there is no `ospec.js` to neuter. The route is `conftest.py`,
which pytest auto-loads from the rootdir and from the directory of every collected test file with no
flag at all, and which nothing in a stock bundle creates, restores or deletes.

```python
# /app/conftest.py, six lines, no solution applied
import pytest

@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    rep = outcome.get_result()
    rep.outcome = "passed"
    rep.longrepr = None
```

`reward 1.0, 16 of 16, raw_exit_code 0`.

**Read that exit code before assuming the Section 10.1 gate covers this.** It does not. The run really
does succeed, because the hook rewrites the outcome before pytest counts failures, so there is no
nonzero status for a gate to read. The neighbouring route on the same bundle, an `atexit` print of the
graded ids each followed by `PASSED` from product source, exits **1** and the gate does close that one,
which is exactly what makes the conftest route easy to believe is already covered.

Four routes were enumerated by running them rather than by reading imports, and all four are closed by
the same two changes:

| Route | Before | After |
|---|---|---|
| `atexit` print of `<id> PASSED` from `deepfabric/__init__.py` | reward 1.0, `raw_exit 1` | reward 0 |
| `conftest.py` hookwrapper, at the root and under `tests/` | **reward 1.0, `raw_exit 0`** | reward 0 |
| `tests/__init__.py` rewritten, which runs before every graded module | n/a, tracked and unrestored | reward 0, file back at 0 bytes |
| `/app/pytest.ini` added | n/a, absent at base | reward 0, file deleted before the run |

The two changes are `--noconftest` on the graded command, which costs nothing when the base tree has no
conftest, and a restore that removes the pytest hook and config surface that does not exist at the base
commit before unpacking the base test tree: `conftest.py`, `tests/conftest.py`, `pytest.ini`,
`setup.cfg`, `tox.ini`, `sitecustomize.py`, `usercustomize.py`. Deleting a path the base commit does
not contain is restore-to-base rather than overreach.

One design note that falls out of this. Restore the **whole** test directory rather than only the files
`tests.patch` touches. `tests/__init__.py` is tracked, runs before every graded module and is not in the
patch, so a targeted payload leaves it writable. On this bundle the whole tree gzips to 9.7 KB and
base64s to 13 KB, so there is no reason to be selective.

What remains open is the same residue as everywhere else. The graded tests import product source the
agent legitimately owns, and site-packages is writable in the container. Neither can be restored. Say so
rather than lengthening the delete list.

### The route no restore can reach, and the check that does

Sixth data point, deepfabric 297 round 1, measured 2026-08-17 with the solution never applied. The
section above closes four pytest routes by deleting files. It does not close the fifth, and the fifth
is the strongest, because it lives in **product source the agent owns outright**.

The graded tests import the package under test at module scope, so `deepfabric/__init__.py` runs while
pytest is still collecting, before any test executes. Ten lines appended there:

```python
try:
    import _pytest.reports as _rep
    _orig_init = _rep.TestReport.__init__
    def _init(self, *a, **k):
        _orig_init(self, *a, **k); self.outcome = "passed"; self.longrepr = None
    _rep.TestReport.__init__ = _init
except Exception:
    pass
```

`reward 1.0, 44 of 44, raw_exit_code 0`. The exit-code gate cannot see it because the run genuinely
succeeds. `--noconftest` does not apply. No restore can help, because a verifier may not restore
product source.

**Two weaker variants failed, and they are worth recording so nobody re-derives them.** Rebinding
`_pytest.runner.pytest_runtest_makereport` from product source does nothing at all, because that hook
is registered with the plugin manager before the package under test is imported, so rebinding the
module attribute afterwards is a no-op. The `atexit` print of fake `PASSED` lines does work as a
parse-level attack but exits nonzero, so the Section 10.1 gate already closes it.

**The fix is to stop trusting the run to report on itself.** After the graded run, `test.sh` runs one
deliberately failing test in a **second process that imports the same tree first**, so any import-time
tampering is in force there too:

```bash
cat > "$CANARY_DIR/test_zz_runner_integrity.py" <<'CANARY_EOF'
import deepfabric  # noqa: F401  - import-time effects of the tree under test apply here too


def test_this_must_be_reported_as_a_failure():
    assert False, "canary"
CANARY_EOF
python3 -m pytest -o addopts= --noconftest -q "$CANARY_DIR/test_zz_runner_integrity.py" > "$CANARY_DIR/canary.log" 2>&1
CANARY_EXIT=$?
```

A canary exit of 0 means the runner called a deliberate failure a pass, so the graded results are
worthless too. Write reward 0 with a named reason and `infrastructure_error: null`, so it reads as a
grading failure rather than an invalid trial, which is the Section 10.1 rule about not poisoning the
difficulty run.

Measured on that bundle: oracle unaffected at 44 of 44 three cycles running, NOP unaffected at 24 of
44, tampering caught at reward 0 with `runner_integrity: failed`. Cost is roughly two seconds.

Import the package under test **by name** in the canary rather than importing nothing, or the canary
runs in a clean interpreter and proves nothing about the tree that was graded.

### Seventh data point, the transport itself: MySpeed 1536, measured 2026-08-18

The routes above all attack the assertion layer or the report object. The node compact scaffold has a
simpler exposure one level down: **the graded results travel on the runner's stdout, and the module
under test can write to that stream directly**. The graded file imports the deliverable, the
deliverable runs in a child of the runner, and the child's own prints are safe because the TAP
reporter wraps them as comments. The parent's descriptor is not safe:

```js
import fs from "node:fs";
// the whole of the deliverable, evaluated at import time
fs.writeFileSync("/proc/" + process.ppid + "/fd/1", forged);  // 18 forged `ok N - <id>` lines
process.exit(0);
```

Measured through the real `test.sh` in the bundle's own image, `--network none`, no implementation
anywhere. The naive version scores **13 of 18, reward 0**: the write lands raw on the graded stream,
but the reporter's trailing output lands on top of the forged block and tears its first few lines.
That race is luck, not design. Front-pad the forged block with 60 decoy `ok` lines whose names match
nothing required, and the pad absorbs the overwrite: **reward 1.0, 18 of 18, `raw_exit_code` 0**.

Three things that do NOT close it, all measured on the same bundle. The exit-code gate does not,
because the module exits itself cleanly at import and the runner reports 0. `allow_extra_failures:
false` does not, because nothing is ever reported FAILED. And `--test-reporter-destination` does not:
the child reads the destination path out of `/proc/<ppid>/cmdline`, waits 150 ms for the real report,
and overwrites it, which also scored reward 1.0 at 18 of 18 on a probe copy of the verifier. What
closes the class is a channel the child cannot address at all: a descriptor the harness opens and
does not hand down, or hiding other processes under `/proc` in the verifier image. Until then the
gate and the flag are narrowings worth taking, measured as narrowings.

One recording caution from the same review. The two child-side routes (console.log and a direct fd-2
write) were measured closed twice and written up as "the injection route is closed", and that sentence
was wrong about the class while being right about both transports. A closed route is a fact about a
transport; the class stays open until somebody has tried the descriptor the reporter itself writes to.

## Related

- [tests-patch-vs-agent-edits.md](tests-patch-vs-agent-edits.md) - the collision half of the same
  missing restore. Both halves are fixed by one payload
- [verifier-fail-open.md](verifier-fail-open.md) - the grader-side family
- [verify-in-the-image.md](verify-in-the-image.md) - the sed-did-not-land guard this probe reuses
- `docs/guidelines.md:135` and the outcome-based tests section - assertions "must not be satisfiable
  by hardcoding or special-casing expected values", which is what a neutered library does globally
