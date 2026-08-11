---
id: difficulty-screen-unit-table
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260808_213817__openziti_ziti-sdk-c__668
  - 20260805_080500__statrs-dev_statrs__315
evidence: "Three consecutive review-gate difficulty screens reported 7/8, 6/8, 7/8. The per-test table under the headline showed 8, 7 and 7 runs against 8 agent runs, so one or two runs never reached the tests at all. On the third, every id read 7 passed / 7 runs, meaning every agent that built the project scored 26 of 26 and the single failure was a build trap"
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty]
blocks_submission: false
fails_gate: [difficulty]
supersedes: []
contradicts: ["its own original premise that the review-gate difficulty screen produces no downloadable artifact - statrs 315 supplied one, 3415683 bytes and 199 files"]
---

# The difficulty screen's headline hides its denominator. Read the unit table

## Why this note exists and L36 does not cover it

[[LEDGER]] L36 says to open the failing trial's `report.json` and `test-stdout.txt`, because
`4/4` and `3/4` cannot distinguish a compile error from a real assertion failure. That is right,
and it needs an artifact.

> **CORRECTED 2026-08-11, and this was the note's central premise.** It said the review-gate
> difficulty screen produces no downloadable artifact, on the evidence that three rounds of
> asking returned `Task Instruction Sufficiency: NOT_APPLICABLE, debug output not available`.
> **That is wrong.** statrs 315 received one: `logs_artifact.zip`, 3,415,683 bytes, 199 files,
> 14.3 MB uncompressed, holding `difficulty_screen/logs/solve/<model>_<n>/` for all 8 trials
> with `agent/claude-code.txt`, `agent/trajectory.json`, `verifier/report.json`,
> `verifier/test-stdout.txt` and `result.json` in each, plus `difficulty_screen/summary.json`
> and `judge/rubric_panel_judge.json`.
>
> The string that was read as proof of absence **is itself a line inside the artifact**. It is
> the last line of `summary.json`'s own `text_summary` field, and it describes the *sufficiency
> analysis* being unavailable, not the artifact. Reading it as "no artifact exists" is reading a
> field about one thing as a statement about another.
>
> **So ask for the artifact on every screen block, by name.** It is the top of the evidence
> hierarchy for this failure shape and it answers questions no amount of local reasoning can. On
> statrs 315 it settled a freshness question that looked unanswerable (two screens returned
> byte-identical headline numbers, which reads exactly like a re-pasted report; the artifact's
> `verifier/report.json` listed the ids added in the round between them, proving it was fresh)
> and it named the difficulty lever by showing what the one failing agent actually wrote.

The rest of this note still holds: the `Unit Tests Results` block carries more than it looks
like it does, and on a round where the artifact does not arrive it is still all you have.

## The table does not always enumerate every graded id

Second qualification from statrs 315, 2026-08-07. The arithmetic below assumes the block lists
every graded id, because on ziti 668 it did. It does not always. statrs's `summary.json` carried
exactly one entry:

```
Unit Tests Results:
  - test skewtest_scipy_example ...: 0 passed / 1 runs
```

against 18 fail-to-pass and 109 pass-to-pass ids. So the block listed **1 of 127**. The rule that
fits both shapes is that it names the ids that **failed at least once**, and stays silent about
the rest, so a single-row table means the suite discriminated on exactly one assertion and a
denominator of `1 runs` is the number of runs that reached it rather than the number of agent
runs. Do not subtract from 8 unless the table is enumerating the whole set.

The per-trial `verifier/report.json` in the artifact is the reliable version of this. On statrs's
one failing trial it read `required_tests_count: 127`, `passed_tests_count: 126`,
`missing_required_tests: ['skewtest_scipy_example']`, which is the same fact with the denominator
attached.

## What the table actually counts

```
Agent Performance:
  - claude-opus-4-8: 75.0% (3/4 runs)
  - codex-gpt-5-5: 100.0% (4/4 runs)
Reference Agents:
  - nop: 0.0% (0/1 runs)
  - oracle: 100.0% (3/3 runs)

Unit Tests Results:
  - ZITI_TEST sentinel_ctrl_failover_switches_endpoint: 7 passed / 7 runs
  ... every id identical ...
```

**It counts agent runs only.** Prove it on your own bundle rather than assuming, with one step:
compare a `pass_to_pass` id's run count against a `fail_to_pass` id's. NOP passes p2p and fails
f2p by construction, so if NOP were in the table the two would differ. Oracle falls out of the
same arithmetic. Here they were identical at 7, so the table is 8 agent runs with one missing.

Then subtract:

| ok / 8 | runs producing test output | real failures | runs that never reached the tests |
|---|---|---|---|
| 7/8 | 8 | 1 | 0 |
| 6/8 | 7 | 1 | 1 |
| 7/8 | **7** | **0** | 1 |

The third row is the one that mattered. Every agent that got the project to build scored 26 of
26. There was no partial credit anywhere in the table, so no requirement in the bundle was
discriminating against anything, and the single "failure" in the headline never ran a test.

**A run with no test output is not a difficulty datapoint.** Counting it as one inflates the
apparent pass-rate ceiling and hides that the real denominator is smaller than 8.

## The trap that ate the missing run, and how to find yours

Reproduced in the built image with the network off:

```
[1/4] cd /app/build/tests/integ && cmake -E env GOBIN=... go install github.com/openziti/ziti/ziti@v1.1.3
FAILED: tests/integ/CMakeFiles/ziti-cli ...
go: ... dial tcp: lookup proxy.golang.org ...: network is unreachable
ninja: build stopped: subcommand failed.
```

`add_custom_target(ziti-cli ALL ...)` is in the default target and a CMake custom target is
always out of date, so the plain command `cmake --build build` reaches the network on every
invocation. The verifier escapes it because `execution.commands` names its targets. **The agent
does not**, and the agent's allowlist is the model gateway only.

The generic check, which is one line and worth running on every task before reading any
difficulty number:

```bash
docker run --rm --network=none <image> bash -lc 'cd /app && <the build command an agent would type>'
```

Type what an agent would type, not what `execution.commands` says. The gap between those two is
where this hides. Two of four independent implementations run against this bundle reported the
same failure unprompted, which is how much it stands out to someone actually working in the tree.

**It is fixable and it is not a Dockerfile hygiene edit.** `docs/guidelines.md` lists
*External-network dependency at build/solve time* as fixable when the thing can be vendored.
Warm the module cache at image build time, when the network is allowed, then pin the resolver
off at run time:

```dockerfile
RUN go install github.com/openziti/ziti/ziti@v1.1.3   # network is available here
ENV GOPROXY=off                                        # later invocations resolve from cache
```

Measured: `GOPROXY=off` alone is sufficient once the cache is warm, the offline default target
then exits 0, and the cache costs 360 MB. The cache without `GOPROXY=off` does **not** work,
because `go install pkg@version` resolves the version through the proxy before it consults the
cache. Phase A checklist item 3 already requires test dependencies to be baked into the image
rather than fetched at test time, so this is the checklist rather than an exception to it.

## The consequence nobody likes

Fixing the trap makes the headline **worse**, because it converts a poisoned run into a run that
passes. That is the correct trade and it has to be stated in Comments for Reviewer rather than
quietly declined: difficulty that comes from an agent hitting a network wall on the obvious build
command is what `sentinel-difficulty-scope` calls the wrong kind of hard, and shipping it to keep
a number down is not available.

See also [[cmake-reconfigure-needs-network]], [[diagnosing-platform-only-failures]],
[[difficulty-levers-must-discriminate]], [[LEDGER]].
