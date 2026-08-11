---
id: rust-cargo-verifier-gotchas
status: locally-verified
last_verified: 2026-08-05
verified_by:
  - 20260805_080500__statrs-dev_statrs__315
evidence: "49 of 629 lib tests print as `test NAME - should panic ... ok` and match neither
  config.json pattern; `cargo fetch` writes a Cargo.lock into the image that the repo does not
  carry, so bind-mounting /app breaks offline resolution and a local run fails for a reason the
  platform would never hit"
applies_to:
  languages: [rust]
  runners: [cargo, docker]
  phases: [verifier-design, local-runs, packaging]
blocks_submission: false
fails_gate: []
supersedes: []
contradicts: []
---

# Rust and cargo verifier gotchas

Three things measured on statrs 315 that cost time and would cost it again on any cargo task.

## 1. `#[should_panic]` tests are invisible to the stock parser, in both directions

The stock `tests/config.json` ships these patterns:

```json
"pass_regex": "^test (?P<name>\\S+) \\.\\.\\. ok",
"fail_regex": "^test (?P<name>\\S+) \\.\\.\\. FAILED"
```

libtest prints an ordinary test as `test foo ... ok`, which matches. It prints a
`#[should_panic]` test as:

```
test distribution::categorical::tests::test_inverse_cdf_input_high - should panic ... ok
```

The ` - should panic ` sits between the name and the dots, so `\S+ \.\.\. ok` does not match.
Measured on statrs at base: **629 lines begin with `test `, 580 match the pass pattern, 628
actually passed.** The 49-test gap is entirely `#[should_panic]`.

The consequence runs both ways and the second one is the dangerous half:

- A should-panic test that PASSES is never counted, so it can never be a useful `pass_to_pass`
  entry. Putting one in `pass_to_pass` makes it permanently `missing_required` and the oracle
  can never reach reward 1.
- A should-panic test that FAILS prints `... - should panic ... FAILED`, matches neither
  pattern, and so never appears in `results`. `allow_extra_failures: false` cannot see it,
  because `unexpected` is computed only over parsed results.

**The exit-code gate from `verifier-fail-open.md` is what closes this.** cargo still exits
nonzero when a should-panic test fails, so gating the reward on `raw_exit_code == 0` catches
exactly the case the parser is blind to. This is a concrete second reason to add that gate
beyond the documented one, and it is why widening the regex was not necessary on statrs 315.

If you do widen it, `^test (?P<name>\S+)(?: - should panic)? \.\.\. ok` is the shape, but
verify against a real run rather than reasoning about it.

## 2. `Cargo.lock` is generated into the image and the repo does not carry it

statrs is a library, so upstream does not commit `Cargo.lock`, and `.gitignore` excludes
`*.lock`. The bundle ships only `Cargo.lock.MSRV`. The Dockerfile runs `cargo fetch`, which
**writes a real `Cargo.lock` into `/app` at image build time**.

Two things follow.

**The local-run trap.** Bind-mounting a copy of `environment/repo` over `/app` replaces the
image's `/app`, and with it the generated lock. cargo then has to re-resolve the graph, which
needs the network, and with `--network none` the run dies:

```
failed to download from `https://index.crates.io/config.json`
Could not resolve host: index.crates.io
```

This looks like an airgap defect in the bundle and is not one. **Run against the image's own
`/app` and mount only `/solution` and `/tests`**, which is also what the platform does. Only
mount over `/app` if you have deliberately reproduced the lock first.

**The reproducibility finding.** Because the lock is created at build time rather than
committed, the dependency graph resolves to semver-latest on whatever day the image is built,
so the difficulty run and a later oracle run can compile different code, and a future release
with a raised MSRV can break a build that passes today. Report it. Do **not** fix it by adding
a `Cargo.lock` to `environment/repo`: that puts a file into the source tree upstream
deliberately does not carry, and the repo is meant to be byte-identical to the base commit.

## 3. Adding a regression guard without grading the agent's own unit tests

Rust puts unit tests inside the source files, so `cargo test --lib` runs whatever the agent
wrote in the modules it was asked to create. Turning on a regression guard naively
(`--lib` plus `allow_extra_failures: false`) therefore makes an agent's own failing unit test
zero its reward even when the graded behaviour is correct. The exit-code gate makes this worse,
not better, because cargo exits nonzero for the agent's test too.

The fix is to run the library suite while skipping exactly the modules the task asks the agent
to create:

```
cargo test --lib --test <graded_target> -- \
  --skip stats_tests::chisquare --skip stats_tests::f_oneway \
  --skip stats_tests::mannwhitneyu --skip stats_tests::skewtest \
  --skip stats_tests::ttest_onesample
```

Measured on statrs 315: 628 pre-existing tests still run as guards, 32 inline tests in the five
new modules are filtered out, and the graded integration target is unaffected because `--skip`
matches substrings and no graded id contains those module paths. It stays a single non-piped
command, so `TEST_EXIT_CODE` is still cargo's own status and the exit-code gate reads the right
value.

Proven both ways: stubbing `Normal::sf` was caught by `distribution::normal::tests::test_sf`
with 628 tests executed and no compile abort, and the five new modules' own tests never
appeared in the graded set.

## 4. Timing, for calibration

`rust:1.89`, 4 cpus, `--network none`, statrs 0.18 with `nalgebra` and `rand`:

| Step | Wall |
|---|---|
| `docker build` from the extracted bundle | 9 to 13 s |
| cold `cargo test --lib` including compiling all deps | 21 s |
| oracle run 1 (solve + full verifier, cold) | 20 s |
| oracle runs 2 and 3 (warm) | 1 to 2 s |

A 300 s `[verifier] timeout_sec` is comfortable for a crate this size. Measure before raising
it; kvdex raising 300 to 900 was about a different workload, not a general rule.
