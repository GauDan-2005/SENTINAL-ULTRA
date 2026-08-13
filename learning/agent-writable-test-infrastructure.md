---
id: agent-writable-test-infrastructure
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260723_030152__mithriljs_mithril.js__2021
  - 20260720_144200__thomas4019_expressa__132
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

## Three data points, and they differ

| Task | assertion library neutered | Reading |
|---|---|---|
| mithril.js 2021 | base tree, **reward 1.0, 15 of 15** | fully gameable, filed as the review's lead finding |
| expressa 132 | base tree, reached **15 of 21**, reward 0 | not trivially gameable, and the reviewer said so in the "what is right" section |
| cista 172 | golden plus a broken stamp, **reward 1.0, 21 of 21** | partially gameable, and the split is the interesting part |

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


## Related

- [tests-patch-vs-agent-edits.md](tests-patch-vs-agent-edits.md) - the collision half of the same
  missing restore. Both halves are fixed by one payload
- [verifier-fail-open.md](verifier-fail-open.md) - the grader-side family
- [verify-in-the-image.md](verify-in-the-image.md) - the sed-did-not-land guard this probe reuses
- `docs/guidelines.md:135` and the outcome-based tests section - assertions "must not be satisfiable
  by hardcoding or special-casing expected values", which is what a neutered library does globally
