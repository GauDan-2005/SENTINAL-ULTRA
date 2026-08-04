---
id: solve-sh-under-sh
status: reported
last_verified: 2026-08-04
verified_by:
  - "none in this workspace — imported from a sibling workspace's records"
evidence: "A sibling Sentinel workspace records solve.sh executed under sh/dash as a cause of Oracle 0/3. Not reproduced here"
applies_to:
  languages: [any]
  runners: [sh, dash, bash]
  phases: [oracle, local-runs, packaging]
blocks_submission: true
fails_gate: [oracle]
supersedes: []
contradicts: []
---

# solve.sh run under `sh` instead of bash

**Provenance, read this first.** This note is imported from a sibling Sentinel workspace's
records, not from a run on this machine. Nothing in this workspace has reproduced it, and the
grep that would have found it (`BASH_VERSION`, `exec bash`) returns zero hits across
`CLAUDE.md`, `learning/`, `.cursor/rules/` and `.claude/skills/`. It is written up because the
failure it describes is invisible to every check this workspace currently runs, and because the
mitigation costs one line. Status stays `reported` until an oracle here fails this way.

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
