---
id: solve-sh-under-sh
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - "solve.sh half: none here - imported from a sibling workspace's records"
  - 20260809_080653__sysprog21_elfuse__162
  - 20260723_030152__mithriljs_mithril.js__2021 (test.sh, dies on `set -o pipefail` at line 9)
evidence: "solve.sh half still second-hand. The test.sh half is now reproduced here: sh /tests/test.sh wrote NO reward file at all, and a one-line re-exec guard took the same case to reward 1.0"
applies_to:
  languages: [any]
  runners: [sh, dash, bash]
  phases: [oracle, local-runs, packaging]
blocks_submission: true
fails_gate: [oracle, verifier-output]
supersedes: []
contradicts: []
---

# solve.sh run under `sh` instead of bash

## `test.sh` is the worse half, and that half is measured (elfuse 162, 2026-08-11)

The provenance note below still stands for `solve.sh`. **The verifier entrypoint was measured
here and it fails harder than the oracle does.**

On `20260809_080653__sysprog21_elfuse__162`, running `sh /tests/test.sh` inside the task image
produced **no `reward.txt` at all**. Not reward 0. Nothing. The stock `test.sh` builds a bash
array (`RUNNER=(timeout "$T" bash /tmp/run_tests.sh)`), dash aborts at that line with
`Syntax error: "(" unexpected`, and it dies **before** reaching the `trap ... EXIT` that exists
specifically to guarantee a reward file. A platform that reads a missing verifier output as
`DownloadVerifierDirError` or `verifier-output-not-found` will not tell you a shell mismatch
caused it.

The guard is one line, goes immediately after the shebang comment in **both** entrypoints, and
costs nothing:

```bash
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
```

Two things worth knowing about testing it. `dash -n /tests/test.sh` still reports the array
syntax error, because `-n` parses the whole file while a real run never reaches that line, so a
failed `dash -n` is not evidence the guard is broken. And the case only shows up if you actually
invoke it as `sh /tests/test.sh`: a shebang is ignored when the file is handed to an
interpreter, so every `bash /tests/test.sh` in your battery hides it. After the guard, the same
`sh` invocation returned reward 1.0 with 24 of 24.


**Provenance, read this first, and it now has two halves.** The `solve.sh` half below is still
imported from a sibling Sentinel workspace's records: no oracle on this machine has failed that
way, so treat it as second-hand. The **`test.sh` half is measured here**, first on
`20260806` go-task work (`go-task-verifier-gotchas.md`, the same one-line guard) and then
directly on elfuse 162, where `sh /tests/test.sh` wrote no reward file at all. The note's status
moved to `locally-verified` on the strength of that half only. It stays worth reading because
the failure is invisible to every check that invokes the scripts with `bash`, and because the
mitigation costs one line.

## Second measurement, a different image and a different failure line (mithril.js 2021, 2026-08-11)

elfuse dies on `RUNNER=(...)`, a bash array. mithril dies **earlier and on a different construct**,
so the guard matters for a reason that is not specific to arrays. `node:20-slim` is Debian bookworm
and `/bin/sh` is dash. On a fully green oracle tree:

```
sh /tests/test.sh        exit=2
stderr: /tests/test.sh: 9: set: Illegal option -o pipefail
/logs/verifier           No such file or directory
reward.txt               NO REWARD FILE
```

`test.sh:9` is `set -uo pipefail` and it sits **before** the `trap write_zero_reward_if_missing EXIT`
on line 25. Same outcome as elfuse, missing verifier output rather than reward 0, reached sixteen
lines sooner. The one-line guard fixes it completely:

```
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
sh /tests/test.sh WITH GUARD   exit=0   reward=1   15 of 15
```

`solution/solve.sh` on that bundle is clean under dash, so the exposure was `test.sh` alone.

**The compounding fact, which is why this belongs on the reviewer run list.** mithril ships both
scripts at mode **0644**, so the harness cannot exec them by shebang and has to hand them to an
interpreter, and `sh` is one of the two candidates. The script-mode finding and the dash finding had
been filed as separate notes in the same review, neither citing the other. They are one finding.
`docs/guidelines.md:323` names `bash/sh mismatch` under the verifier-output-not-found row, and
`:325` covers bad shebang and non-executable scripts in the same table.


## The symptom

Oracle passes locally, every time, on every rerun. The platform returns:

```
Oracle did not pass all runs: 0/3. Task may be flaky or has infra issues.
```

The bundle looks fine. `solve.sh` is mode 0755, the patch applies, the tests pass, and running
the whole thing again in a fresh container reproduces nothing. That combination is the signature.

## The mechanism

The shebang is only consulted when a file is executed directly. When something invokes the
script as an argument to an interpreter, the shebang is a comment:

```sh
sh /solution/solve.sh          # shebang ignored, runs under dash on Debian and Ubuntu
bash /solution/solve.sh        # shebang ignored, runs under bash
/solution/solve.sh             # shebang honoured
```

On Debian-family images `/bin/sh` is dash, which does not have:

- `[[ ... ]]`
- arrays, `${arr[@]}`, `${arr[0]}`
- `local` outside a function, and several `local` forms dash rejects
- `set -o pipefail`
- `$BASH_SOURCE`, `${var^^}`, `<<<` here-strings, `function name()`
- process substitution `<(...)`

Every one of those is a syntax error or a silent behaviour change under dash, and the failure
lands wherever the parser reaches it, which on a syntax error is before the first line runs.
A `set -e` script that dies at parse time produces almost no output, so the platform reports
flakiness rather than a script error.

`learning/local-runs.md` and `learning/solve-sh-idempotency.md` both invoke `bash /solution/solve.sh`
in their recipes. That is a fine way to run it and it is also the exact invocation that hides
this defect.

## The rule

Two halves, and both are cheap.

**1. Make the shebang irrelevant.** Either the script contains no bashisms at all, or it
re-execs itself under bash at the top:

```bash
#!/usr/bin/env bash
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
set -euo pipefail
```

The guard is a no-op under bash and a one-line fix under dash, and it survives whatever the
harness decides to do with the file.

**2. Test the oracle the way the platform might invoke it, not the way that is convenient.**
Of the runs made in a Step 5.5 session, make at least one of them:

```bash
sh /solution/solve.sh && bash /tests/test.sh
```

If that run fails while `bash /solution/solve.sh` succeeds, this is the defect.

A cheap pre-zip grep catches most of it without a container:

```bash
grep -nE '\[\[|\$\{[A-Za-z_]+\[[@*]\]\}|BASH_SOURCE|<<<|\bfunction +[A-Za-z_]+ *\(\)|pipefail' \
  solution/solve.sh tests/test.sh
```

`tests/test.sh` is in the grep because the same trap applies to it, and on a bundle carrying an
embedded base64 restore payload the heredoc and the `base64 -d` fallback chain are exactly the
kind of code that behaves differently under dash.

## What this workspace actually measures, which is the counterweight

Run that grep over the four bundles here and it hits everywhere:

| Bundle | `solve.sh` hits | `test.sh` hits | Shebang | Outcome |
|---|---|---|---|---|
| kvdex 245 | 0 | 6 | `#!/usr/bin/env bash` | **accepted** |
| libcrux 1165 | 1 | 6 | `#!/usr/bin/env bash` | in review |
| android-beacon 1177 | 1 | 2 | `#!/usr/bin/env bash` | in review |
| equalsverifier 1166 | 1 | 2 | `#!/usr/bin/env bash` | in review |

**The accepted bundle carries bashisms with a bash shebang and no re-exec guard, and it passed
every oracle run the platform made.** That is direct evidence that the harness honours the
shebang, or invokes with bash, at least for the paths those bundles exercise.

So the grep is not a defect finding and a hit is not a bug. Read it this way:

- Hits **plus a bash shebang** is the normal, accepted state. Leave it alone.
- Hits plus a `#!/bin/sh` shebang is a real finding, and the fix is the shebang.
- The re-exec guard is cheap insurance against an invocation nobody here has observed. Add it if
  you are already editing the file; it is not worth a round on its own.

A check that flags the one bundle that was accepted is measuring the wrong thing. This section
exists so the next reader does not turn a sibling workspace's report into a rule that fails our
own reference.

## What this is not

It is not the same as [solve-sh-idempotency.md](solve-sh-idempotency.md), which is also a cause
of a platform-only oracle failure and was also once blamed for a 0/3 it did not cause. Both
produce a green local run and a red platform run, so on an oracle 0/3 check both, plus the
packaging and hygiene routes in
[diagnosing-platform-only-failures.md](diagnosing-platform-only-failures.md). Two strikes still
applies: a second locally-verified fix that fails on the platform means the model of the
environment is wrong, and the answer is to remove the dependency rather than to refine the
theory.
