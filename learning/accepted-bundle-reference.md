# What an accepted bundle actually looked like

Source: `20260719_045042__oliver-oloughlin_kvdex__245`, accepted 2026-08-04 after six rounds.
Deno/TypeScript, `evolution_and_maintenance / migration`, difficulty hard, verdict Fixable
throughout, PR scope never touched.

The first task in this workspace to clear every gate. `CLAUDE.md` says what the rules are;
this note is the one worked example of a bundle that satisfied all of them at once, with the
measured numbers, so the next task has something to calibrate against instead of a checklist.

**Read the last section first if you are short on time.** The point of this note is the
distinction between the hardening that acceptance actually validated and the hardening that
merely did not get caught.

## The measured shape

| Dimension | Value |
|---|---|
| `fail_to_pass` | 20 (the hard ceiling; 22 was rejected at the static phase in round 1) |
| `pass_to_pass` | 112 |
| graded ids total | 132 |
| suite at oracle | 152 pass, 0 fail, 2 ignored |
| `allow_extra_failures` | `false` |
| files in `tests.patch` | 45 |
| pre-existing test files modified | 40 |
| graded ids outside the patched files | 102 of 132 (this is what forced the full-tree restore) |
| files changed vs the pristine extract | 7 |
| zip | 309 entries, 1.8 MB, `zip -rX` |
| `.git` | 1.6 MB, exactly `config description HEAD hooks index info objects packed-refs refs` |
| `test.sh` | 93 KB, mode 755, carries a 70 KB base64 payload |
| `solve.sh` | mode 755, forward-only and idempotent |

`task.toml` at close: `[verifier] timeout_sec = 900` (raised from 300, oracle uses 138),
`[agent] timeout_sec = 7200` (raised from 1800 after 3 of 8 trials timed out),
`[environment] os = "linux"`, `cpus = 4`, `memory_mb = 8192`, `storage_mb = 10240`,
`gpus = 0`, `network_mode` present in all three blocks, `difficulty_explanation` added.

## The verification matrix that preceded acceptance

Five runs, airgapped, in the task's own image at the declared `cpus=4 / 8 GB`.

| Scenario | Reward | Required | Notes |
|---|---|---|---|
| NOP | 0 | 0 of 132 | `raw_exit_code 1`, `infrastructure_error: None`, 0 unexpected |
| Oracle, clean tree | 1 | 132 of 132 | 152 pass, 0 fail, 2 ignored, 138 s of 900 s |
| Agent edited tests, `.git` removed | 1 | 132 of 132 | the case that reproduced the platform failure |
| Agent committed + wrote its own `tests/ext/encoder.test.ts`, `.git` removed | 1 | 132 of 132 | collision case |
| Hostile delete, brotli default 1 → 6 | **0** | 131 of 132 | `ext - brotliCompressor` fails |

Two properties of this matrix are worth copying rather than the numbers themselves. The
agent-hostile rows **outnumber** the clean rows, and the NOP row is checked for the right
reason rather than for a reward of 0 (no f2p passing at base, no collection abort, and a
nonzero `raw_exit_code`).

## The answer set that went with it

10 numbered issue blocks, 8 Files Changed entries, both Phase 1 checkbox lists rendered with
`[x]`/`[ ]` (4 options and 7 options), 8 of 8 post-fix confirmations, all free text humanized
and unwrapped. Handling times 90 review / 150 rewrite / 20 form, total 260, revisions 195.

Both time figures sit **above** this workspace's target bands (180–240 and 60–120). That was
the submitter's call, the reason is stated in Comments for Reviewer, and it did not cost the
acceptance. Worth knowing the bands are guidance rather than a gate.

## What acceptance actually validated

Only these. Everything here was exercised by a gate that had previously failed, so acceptance
is real evidence:

- **The git-independent test-tree restore.** Three git-based designs failed the difficulty
  check across three rounds; this one passed first time. See
  `tests-patch-vs-agent-edits.md`.
- **The payload living inside `test.sh`.** The static checker rejected `tests/files/` on the
  previous upload and passed this.
- **`fail_to_pass` at exactly 20.** Rejected at 22 in round 1, passed at 20.
- **Narrowing the instruction rather than touching the oracle** to clear a `test_coverage` 3.0
  DISCUSS. The judge's three complaints all traced to PR 245 itself, so the spec was
  over-promising. `test_faithfulness` stayed at 5.0 and PR scope was untouched. See
  `source-pr-cross-check.md`.
- **`allow_extra_failures: false`** with 20 ungraded top-level tests in the suite, measured
  safe first.
- **`[agent] timeout_sec = 7200`**, after 3 of 8 opus trials hit the old 1800 ceiling.

## What acceptance did NOT validate

This is the honest half, and the more useful one. These shipped, they are defensible, and
**nothing in the result confirms any of them was necessary or sufficient.** Do not cite this
task as proof of them:

- **The fail-closed grader** (`success = ... and args.raw_exit_code == 0`, runner under
  `bash -o pipefail`). It was never the reason a round bounced. It is right on the documented
  invariant in `docs/guidelines.md`, and a reviewer would have found the fail-open version,
  but acceptance is not evidence it mattered here.
- **The idempotent `solve.sh`.** Flagged advisory at `oracle_robustness` 4/5 by both judges,
  never blocking.
- **Script modes 755.** Fixed late; the bundle had passed oracle runs at 644 in earlier rounds,
  so the practical impact on this task is unclear.
- **The 102-of-132 measurement.** It correctly ruled out the create-only patch *for this task*.
  It has not been tested the other way round, i.e. nobody has shipped a create-only patch on a
  task measuring zero and had it accepted.
- **Leaving `.vscode/settings.json` in place.** One judge scored packaging 1/5 for it and the
  other scored 5/5. Adjudicated 3.0, advisory, so the disagreement was never resolved. The
  reasoning for leaving it (tracked upstream at base, removing it means editing tracked repo
  files) still stands, but it is unadjudicated.
- **`model_difficulty = "medium"` against `difficulty = "hard"`.** Left alone per the FAQ rule,
  declared to the reviewer, and never queried.

**Rule: an acceptance validates the things that had previously failed and were then changed.
Everything else in the bundle merely was not caught. Keep the two lists separate when citing
this task, or advisory choices start getting quoted as proven practice.**

## The one thing that would have saved three rounds

Not a hardening measure. Reading the round-over-round trend. 13 of 16 invalid, then 16 of 16,
then 15 of 16 is a flat line across two different locally-verified fixes, and a flat line
means the fixes are not landing on the cause. That signal was free and available from round 4.
See `diagnosing-platform-only-failures.md`.
