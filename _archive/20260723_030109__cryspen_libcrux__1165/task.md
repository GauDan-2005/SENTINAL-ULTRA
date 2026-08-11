# 20260723_030109__cryspen_libcrux__1165

| Field | Value |
|---|---|
| Original Directory Name | `20260723_030109__cryspen_libcrux__1165` |
| Submission id | `51077619-056b-487d-9ed1-4d89555d7d62` (short `51077619`) |
| Repo / PR | cryspen/libcrux [PR 1165](https://github.com/cryspen/libcrux/pull/1165) |
| Base commit | `6146075b6ea0b52da9304eea1086505c3eb5270b` |
| Category | implementation / feature |
| Difficulty | medium (`model_difficulty` also medium) |
| Languages | C, Rust (`coding_language = "rust"`) |
| Tags | ml-kem, pqcp, cryptography, public-api, feature-flag, rust |
| Verdict | **Invalid / Not Fixable** (round 5, PR scope). Fixable on every other axis and 17 issues were fixed across rounds 1 to 4 |
| Status | `accepted` 2026-08-11. Closed at round 5 as Invalid / Not Fixable (Step 11) |
| Claimed | 2026-08-02 |

Platform data block is in [task_details.md](task_details.md), pasted verbatim.

## Bundle layout as received

The zip unpacks flat, with no `task/` wrapper and no `runs/` directory. 1681 files,
153 MB, almost all of it `environment/repo`.

```
instruction.md
task.toml
environment/Dockerfile
environment/problem_statement.md
environment/repo/            (full git checkout, ~40 MB pack)
solution/golden.patch
solution/solve.sh
tests/config.json
tests/test.sh
tests/tests.patch
```

No `runs/` means there are no agent trial logs to read for the difficulty question, so
`pass_at_k_opus_4_8 = "2/3"` and `pass_at_k_gpt_5_5 = "2/3"` in `task.toml` are the only
trial evidence available.

## Notes carried in from `learning/` before analysis starts

- `environment/repo/.git/refs/remotes/origin/HEAD` is present in the zip listing. That is
  the exact leak path in `learning/unreachable-git-blobs.md` — invisible to `git remote`
  and to `for-each-ref`, only `git fsck` catches it. Confirm during the Step 2 git sweep.
- `tests/test.sh` ships from the stock harness, so assume the fail-open grader in
  `learning/verifier-fail-open.md` until the file has been read.
- `solution/solve.sh` needs the reverse-apply check from `learning/solve-sh-idempotency.md`
  (`grep -n 'apply.* -R' solution/solve.sh`).
- Rust plus a `medium` public-API feature is the task shape that scored best on the
  prescriptiveness check, per `learning/prescriptiveness-check.md`.

## History

| Date | Round | What happened |
|---|---|---|
| 2026-08-02 | setup | Task folder created, zip extracted to `download/original/`, working copy made in `work/`. `diff -rq download/original work` is clean. Analysis not started. |

## Setup note: an empty `.git/FETCH_HEAD` appeared on its own

Right after `cp -a` made the working copy, `diff -rq download/original work` reported
`Only in work/environment/repo/.git: FETCH_HEAD`. The file is zero bytes, it is not in the
zip, and it is not in `download/original/`. Nothing in this session ran git. So something
else on the machine, most likely an editor git watcher picking up the new checkout, writes
into `work/environment/repo/.git`.

Deleted it, and the trees match again. Two things follow for later rounds. `diff -rq`
against the pristine extract can report a file nobody touched, so check what the file is
before assuming a mistake. And the pre-zip cleanup already removes `FETCH_HEAD` by name,
which is what makes this harmless rather than a leak.

## Verdict and local results (2026-08-02)

**Fixable.** Ten findings, all corrected in `work/`. Run against the exact zip in `upload/`,
extracted to the scratchpad, image rebuilt from that extract, airgapped with `--network none`
at the declared `cpus=4 / 8 GB`.

| Check | Reward | Required | Raw exit | Time |
|---|---|---|---|---|
| NOP | 0 | 0 of 40 | 101 | 0.5 s |
| Oracle (solve.sh run twice, then verify) | 1 | 40 of 40 | 0 | 8 s of 900 s |
| Hostile delete (`crypto_kem_pk_from_sk` stubbed) | **0** | 16 of 40 | 101 | 8 s |
| Committing agent (own `tests/pqcp.rs`, renamed a test, deleted `ml-kem.rs`) | 1 | 40 of 40 | 0 | 9 s |
| Feature-gate break (all graded tests pass, no-pqcp build fails) | **0** | **40 of 40** | 101 | 9 s |

Cold `docker build --no-cache` from the zip: **3 m 10 s** against `build_timeout_sec = 900`.
`fail_to_pass` 19, `pass_to_pass` 21, `allow_extra_failures` false.

**The NOP is 0 for the right reason.** With `tests.patch` applied at the base commit and only
the `rand` feature on, the graded file compiles to zero tests, so no f2p test can pass before
the fix. Verified directly, not argued from the reward.

**The feature-gate row is the one that matters.** All 40 graded tests passed and the reward
was still 0, because the third command (`cargo build -p libcrux-ml-kem`, no pqcp) failed and
the new exit-code gate caught it. The same break scored **1.0** on the bundle as received.

## Findings

1. `solution/solve.sh` reverse-applied on a second run and exited 0. Reproduced: 1st run leaves
   `libcrux-ml-kem/src/pqcp.rs`, 2nd run reports success and the file plus the Cargo feature are
   gone. This is `learning/solve-sh-idempotency.md` exactly, and the platform runs the oracle 3x.
2. `tests.patch` added `libcrux-ml-kem/tests/pqcp.rs`, the file an agent writes for itself.
   Reproduced against the shipped bundle with a committing agent:
   `infrastructure_error: tests.patch did not apply`, reward 0, trial invalid.
3. Fail-open grader. `raw_exit_code` recorded, never consulted. The stock harness defect.
4. No regression guard. `pass_to_pass: []`, `allow_extra_failures: true`, one command running
   only the new target.
5. Constraint 1 (feature off, crate unchanged) had no test at all.
6. The graded tests import `libcrux_ml_kem::<variant>::unpacked`, a path the instruction called
   an existing fact. At base the unpacked types sit under the per-backend modules, so the
   solution has to add that re-export and the instruction never asked for it.
7. `Do not modify the test files` in the instruction is verifier mechanics.
8. Dirty git tree (28 lost mode bits, 7 flattened symlinks) and a broken
   `refs/remotes/origin/HEAD` that only `git fsck` catches.
9. `task.toml`: no `[environment] os`, agent timeout 1800, verifier timeout 300 against
   `execution.timeout_sec` 1800.
10. `tests/test.sh` and `solution/solve.sh` shipped at mode 0644.

## Source PR cross-check

PR 1165 "PQCP APIs", 6 files, base `6146075b...` which matches `task.toml`. `golden.patch`
touches exactly those 6 files and no others. Fetched through `gh api --paginate`, so the list is
complete rather than a first page.

The shipped `golden.patch` is 350 lines against the PR's 335 for `src/pqcp.rs`. The extra 15 are
two re-export blocks that the PR does not ship: the unpacked module at the variant path, and the
struct functions pulled into the `pqcp` module. They came with the bundle, they are what make the
instruction's module paths real, and they are expansion rather than reduction. Left as received.

## Deliberately not changed

- The Dockerfile's `cargo test -p libcrux-ml-kem --no-run || true`. Fail open, but the warm-up
  genuinely succeeds (552 MB `target/`, re-running finishes in 0.14 s) and nothing downstream
  breaks, so it is not a listed allowed fix.
- `cargo install cargo-llvm-cov --locked`. Nothing in the verifier uses it and the cold build
  still fits the limit with room to spare.
- The three `*_avx2` tests are skipped by name in the regression command. They are compiled in
  through feature unification and call AVX2 paths directly, so grading them would tie the reward
  to the host CPU.
- Difficulty metadata. `difficulty` and `model_difficulty` agree at medium, so there is nothing
  to reconcile, and the FAQ rule against hand-editing applies anyway.

## Packaging

Git hygiene run last, immediately before zipping. `git fsck --unreachable` printed a dangling
blob (`5113158a`, the graded test file, left by regenerating `tests.patch`) plus the broken
`origin/HEAD`; both cleared and fsck is now silent. `.git` holds exactly `config description HEAD
hooks index info objects packed-refs refs`, HEAD equals base, tree clean, no remotes, 41 MB.

Zipped with `zip -rXy`. The `-y` is needed here: without it zip follows the 7 symlinks and
flattens them again, which is how the tree got dirty in the first place. Verified after
extraction: 1954 entries, top level is `environment/ instruction.md solution/ task.toml tests/`,
no `runs/`, no `task/` wrapper, `.git/refs/` and `refs/heads/` present, 7 symlinks intact, both
scripts 0755, `git status` clean, fsck silent. All 20 static checks simulated against the
extracted zip: pass.

## Open

- Not yet uploaded. Phase 1 answers go in before the zip, per the form order.
- Handling times recorded: 45 review, 120 rewrite, 35 form, total 200. Revisions 0 until the
  first bounce.

---

# Revision round 1 — feedback received 2026-08-03

Two separate failures, one blocking each way.

## Feedback, verbatim

```
Agent Runner Summary: Evaluation FAILED. Rubric panel judge: DISCUSS (NEEDS_REVISION)
Agent Runner Summary: Evaluation FAILED. Difficulty: easy, Solvable: False

Difficulty: FAIL EASY - Requires at least MEDIUM
Agent Performance:
  - claude-opus-4-8: 100.0% (8/8 runs)
  - codex-gpt-5-5: 100.0% (8/8 runs)
Reference Agents: nop 0.0% (0/1), oracle 100.0% (3/3)

Rubric panel: DISCUSS, reason oracle_spec_gap
  oracle_spec_faithfulness 3.0/5  (claude 5, gpt 2)
  test_coverage 3.5/5             (claude 5, gpt 3)
  everything else 4.5 to 5.0
```

gpt's driving rationale, in two parts:

1. "the required public `PQCPError` is placed in a `pub(crate)` root module and only privately
   imported into the public API, despite the instruction requiring a single public enum"
2. "the unpacked macro re-exports constants via `super::super::pqcp`, which from
   `portable::unpacked::pqcp` points at a non-existent `portable::pqcp` module ... so the
   required struct API is materially broken"

## Findings split into items

| # | Item | Verdict |
|---|---|---|
| 1 | `PQCPError` not nameable outside the crate | **real**, fixed |
| 2 | `super::super::pqcp` resolves to nothing, struct API broken | **false**, refuted by measurement |
| 3 | pqcp not checked to be off by default / inaccessible without the feature | real, fixed |
| 4 | rand-gated functions not checked to be absent without `rand` | real, fixed |
| 5 | `Result<(), PQCPError>` payload and the three unused variants unenforced | real, fixed |
| 6 | validation only spot-checked with all-`0xff` keys | real, fixed |
| 7 | difficulty easy at 8/8 | real, scope expanded |

**Item 1 confirmed by compiling against it:**

```
error[E0603]: module `pqcp` is private
```

`lib.rs` has `pub(crate) mod pqcp;` and the packed module only did `use crate::pqcp::PQCPError;`,
so a caller could receive the error and print it but could not name the type or match a variant.
It comes from PR 1165 rather than from the bundle, so per `learning/source-pr-cross-check.md` the
question was whether to narrow the instruction or expand the oracle. Expanded, because the same
round needed difficulty anyway and expansion is the allowed direction.

**Item 2 refuted in the task image.** `portable` carries a `use super::*;` glob, and a private
import is visible to that module's descendants, so `super::super::pqcp` from
`portable::unpacked::pqcp` lands on the variant-level `pqcp` module. Measured through the exact
path the judge names:

```
packed PK_LEN=1184 struct-module PK_LEN=1184
```

Every struct function is reached through that module by the graded tests, which pass. Not acted
on, written up in Comments for Reviewer instead.

## Difficulty: what was ruled out before expanding

Trimming the instruction (troubleshooting step 1) is not available here. The PQCP names and
signatures are the integration contract, the graded tests call them by name, and both judges
scored prescriptiveness 5/5 and clarity 4.5/5. Cutting them trades a difficulty finding for a
blocking `test_faithfulness` one.

Two expansions were prototyped and rejected on evidence:

| Candidate | Why not |
|---|---|
| C ABI layer (`#[export_name]` + `extern "C"`), which fits the "reference C interface" framing | `libcrux-ml-kem/src/lib.rs:68` sets `#![deny(unsafe_code)]`. A C entry point needs raw pointers, so the task would force weakening a crate-wide lint in a cryptography library. Prototype produced 15 compile errors against that lint |
| Backend-aware `unpacked` alias (simd256 > simd128 > portable) | `simd256` is force-enabled workspace-wide (virtual manifest, resolver v1, `libcrux-psq` pulls it in). The graded struct tests would then execute AVX2 code and the task would depend on the grading host having AVX2 |

## What round 1 changed

Oracle, all additive, still the same six files as PR 1165:

- `pub use crate::pqcp::PQCPError;` so the enum is reachable at `mlkem<variant>::pqcp::PQCPError`
- `crypto_kem_check_pk` and `crypto_kem_check_sk`, the validation entry points the packed API
  lacked given that encaps and decaps are specified not to validate

Instruction, in lockstep: the enum has to be nameable and matchable from outside; the two check
functions; a rejected parse leaves its destination untouched; the rand-off and no-default-features
configurations are stated.

Tests: regrouped to 14 ids (4 per parameter set plus 2 whole-API tests) to make room under the 20
cap. Error variants asserted by `matches!` rather than by Debug string. Validation now runs the
repo's own `tests/kats/invalid_modulus` vectors, **780 per parameter set**, each required to be
rejected by both the check and the parse path. New `parse_failures_leave_output_unchanged`. New
`error_type_is_public_and_matchable` with an exhaustive five-arm match.

Verifier: three more commands. Build with default features (pqcp off), build with
`--no-default-features --features ...,pqcp` (rand off, no std), and a negative check that compiles
`sentinel_pqcp_absent.rs` in a config without the feature and fails the run if it compiles.

## Round 1 verification

Against the exact zip in `upload/`, airgapped, `--cpus=4 --memory=8g`.

| Check | Reward | Required | Raw exit | Note |
|---|---|---|---|---|
| NOP | 0 | 0 of 35 | 101 | no f2p can pass at base, verified separately |
| Oracle (solve.sh twice, then verify) | 1 | 35 of 35 | 0 | 20 s of 900 s |
| Atomicity broken (parse writes before validating) | **0** | 11 of 35 | 101 | the three `parse_failures_leave_output_unchanged` fail |
| Error type made private again | **0** | 0 of 35 | 101 | graded target stops compiling |
| rand gate dropped | **0** | **35 of 35** | 101 | no-rand build fails |
| pqcp gates removed entirely | **0** | **35 of 35** | 1 | absence probe compiles, guard fires |
| Committing agent (own `tests/pqcp.rs`, renamed a test, deleted `ml-kem.rs`) | 1 | 35 of 35 | 0 | restore step holds |

The two rows with 35 of 35 and reward 0 are the point: those requirements are compile-time
properties that no assertion can reach, and the exit-code gate is what makes them graded.

All 20 static checks simulated against the extracted zip: pass. `fail_to_pass` 14,
`pass_to_pass` 21, `allow_extra_failures` false, tree clean, `fsck` silent, 7 symlinks intact,
both scripts 0755.

## Workspace note: the zip was assembled off the mount

Mid-round the NTFS mount wedged. Two `rm -rf .next` processes from another project have been in
uninterruptible `vfs_unlink` for about 11 hours, load average was 19, and a `git reflog expire`
started in `work/environment/repo` went into `D` state behind them and cannot be killed
(`learning/local-runs.md`). An earlier `git reset` on the same tree had already segfaulted and
left `.git/refs/heads/main.lock`, which got baked into a test image and blocked a simulated
agent's commit until it was found.

So the shipped bundle was rebuilt on `/tmp` from `download/original/` plus the seven edited files,
where the same hygiene ran in seconds. The zip in `upload/` is that tree, md5 `8cde105ad1f01087`,
verified byte for byte after the copy.

**Open:** `work/environment/repo` still has an uncleaned `.git` and a stuck git process against
it. It needs a reboot, then `sudo ntfsfix /dev/nvme0n1p5`, before `work/` is usable again. Nothing
in `upload/` depends on it.

## Open

- Difficulty cannot be measured locally. If the next run still says easy, the honest reading is
  that reaching MEDIUM needs a different, harder PR, which is the Not Fixable condition rather
  than something to keep patching.
- Handling times: revisions now 110 minutes. The other three are first-pass numbers and do not move.

---

# Round 1 re-verification, 2026-08-04

Nothing in the bundle changed. This session re-ran the whole battery because the round-1 numbers
had been measured against a `work/`-built image *before* the bundle was reassembled on `/tmp`,
so "against the exact zip in upload" was not yet literally true. It is now.

## The workspace moved off NTFS

The whole tree is now at `/home/gaurav-s-ubuntu/Work/Work/AirDawg/SENTINAL-ULTRA` on **ext4**,
not `/media/.../COLLEGE MATERIAL` on ntfs3. Load average 2.2, no stuck processes, git works in
seconds. The reboot-and-`ntfsfix` item from round 1 is closed by the move.

**The move damaged `work/`, and only `work/`.** `environment/repo` came across with the 7
symlinks flattened back into regular files, three symlinked directories under
`extracts/c_header_only/generated/` dropped outright, and `.git` still carrying `logs`,
`ORIG_HEAD`, `FETCH_HEAD` and a stale `HEAD.lock`. `git status --porcelain` listed 7 changes.
Repaired with `find .git -name '*.lock' -delete`, `git checkout -- .`, the reflog/gc pair and
`rm -rf .git/refs/remotes`. Now 7 symlinks, clean tree, HEAD at base, `.git` exactly
`config description HEAD hooks index info objects packed-refs refs`, `fsck` silent, both
patches apply.

**The shipped zip was untouched by any of it.** md5 still `8cde105ad1f010873e8beab1294f4139`,
7 symlinks, clean tree, fsck silent, all 9 bundle files byte-identical to `work/`.

## Battery re-run against the extracted zip, image rebuilt from that extract

Airgapped, `--cpus=4 --memory=8g`. Cold `docker build --no-cache` 190 s against
`build_timeout_sec = 900`.

| Check | Reward | Passed | Raw exit | vs round-1 claim |
|---|---|---|---|---|
| NOP | 0 | 0 of 35 | 101 | same |
| Oracle (`solve.sh` twice, then verify) | 1 | 35 of 35 | 0 | same, 23 s not 20 s |
| Atomicity broken (parse writes before validating) | 0 | 11 of 35 | 101 | same to the number |
| Error type made private again | 0 | 0 of 35 | 101 | same |
| rand gate dropped | 0 | **35 of 35** | 101 | same |
| pqcp gates removed entirely | 0 | **35 of 35** | 1 | same, guard message fires |
| Committing agent | 1 | 35 of 35 | 0 | same |
| **new** Hostile delete (`crypto_kem_check_pk` stubbed to accept) | 0 | 10 of 35 | 101 | 4 graded tests FAILED |
| **new** Committing agent that also removes `.git` | 0 | 14 of 35 | 101 | see below |

All 20 static checks pass against the extract. `fail_to_pass` 14, `pass_to_pass` 21.

## The NOP is 0 for a different reason than round 1 wrote down

Round 1 said the graded file "compiles to zero tests" at base. The run never gets that far.
It stops at the **first** command with

```
error: the package 'libcrux-ml-kem' does not contain this feature: pqcp
```

zero bytes of stdout, `raw_exit_code 101`. So the NOP is a build-tool refusal, which is a third
shape of the `verify-in-the-image.md` problem and proves nothing on its own. Both hidden facts
were then measured directly, with `tests.patch` applied at base:

- `cargo test --features rand --test sentinel_pqcp_verifier -- --list` reports
  **`0 tests, 0 benchmarks`**, so no f2p test exists before the fix, let alone passes.
- `cargo test --features rand --test self --test ml-kem -- --skip _avx2 --skip _neon` passes
  **21 of 21**, so every `pass_to_pass` id is a real guard and none is an accidental f2p.

Comments for Reviewer was rewritten to say what actually happens, because a reviewer who
reproduces the NOP sees an empty log and the old sentence read as false.

## Residual worth knowing

An agent that deletes one of the crate's own test files **and** removes `.git` scores 0 with all
14 f2p passing: the restore step is skipped and the regression command dies on
`no test target named ml-kem`. With `.git` present the same agent scores 1 with 35 of 35. The
graded new tests survive either way because `tests.patch` is create-only with names no agent
picks, so the kvdex "patch did not apply" failure cannot happen here. Disclosed in Comments.

## Answers file corrections (Step 10 item 5)

Round 1 changed the graded set from 40 to 35 and `fail_to_pass` from 19 to 14, and four answers
still carried the old numbers.

| Where | Was | Now |
|---|---|---|
| Issue 2 | reward 1 with 40 of 40 | 35 of 35 |
| Issue 5 | All 40 graded tests still passed | 35 |
| Files Changed 4 | `fail_to_pass` is 19 | points at entry 11, which has the current list |
| Files Changed 6 | problem_statement md5 `d5c71d61bc0c` | `d195d97d4d66` |
| Comments | NOP claim, oracle 20 s, five hostile runs | accurate NOP mechanism, 23 s, six runs plus the residual |

Humanized after editing. All 28 em dashes in the file are the mandated `— Is this issue fixable`
form scaffolding, no prose line is wrapped, no curly quotes, no semicolons in prose.

---

# Revision round 2 — 2026-08-04

## The "round 2 feedback" was the round 0 report re-pasted

Checked before doing any work, per Step 10 item 0. Four independent tells, all consistent:

| The report cites | The round-1 bundle |
|---|---|
| `packed_derand_roundtrip`, `packed_rand_roundtrip`, `parse_pk_rejects_invalid`, `parse_sk_rejects_invalid`, `unpacked_seed_marshal_parse` | none of those ids exist; regrouped in round 1 |
| `tests.patch:6-202`, interop at `:164-202` | `tests.patch` is 343 lines |
| `config.json:4-8` commands, `pass_to_pass:39-61`, `allow_extra_failures:63` | commands 4-11 (6 of them), p2p 37-59, flag at 61 |
| "only runs the sentinel test with `--features pqcp,rand` and a plain build" | 6 commands, including the no-rand build and the absence probe |

Every one of gpt's four `test_coverage` complaints is already implemented in round 1: the
off-by-default probe, the rand-off build, the exhaustive five-variant match, and KAT-vector
validation replacing the all-`0xff` spot check. It is also byte-identical to the report already
recorded above under round 1, down to the 3.0/3.5 splits and the 8/8. **Round 1 had never been
uploaded**, so no new result existed. No rework was done against it.

## What round 2 actually changed, and why

Not from the feedback. From the rules update after kvdex 245 was accepted: `CLAUDE.md` 10.3 now
says a test-tree restore must not touch git, because the verify-time workspace is not a git
repository. `tests/test.sh` had exactly the forbidden pattern behind `[ -d .git ]`.

Exposure here was smaller than kvdex's and was measured, not assumed. `tests.patch` is
create-only with `sentinel_`-prefixed names, so the `tests.patch did not apply` failure class
cannot occur. What was exposed is the 21 `pass_to_pass` guards, which live in `self.rs` and
`ml-kem.rs` — files the patch does not touch. With the restore skipped they ran against the
agent's copies.

The 10.3 one-liner reads **35 of 35** on this task, which is a false reading: cargo ids are
`module::test`, not `path::test`, so `i.split('::')[0]` can never match a file path. Hand
resolved it is **21 of 35** outside, which is still "anything above zero" → payload restore.

Whole-tree payload was not viable (20 MB of tests, 19 MB of it KAT vectors, 9.0 MB base64).
Only two files carry graded ids, and those are **4.9 KB of base64**. So the payload is scoped to
`self.rs` + `ml-kem.rs`, verified to contain all 21 p2p ids, and round-tripped back out of
`test.sh` before any container time was spent.

Two further changes fell out of it:

- `test.sh` now also deletes anything at a path `tests.patch` creates, read from the patch with
  `sed -n 's|^+++ b/||p'`. That closes the create-only collision case without git.
- The KAT fixtures cannot be embedded, so the graded tests assert the vector count. **The counts
  are 775 / 780 / 1040, not "780 per parameter set"** as round 1 wrote in both this file and the
  answers. Corrected in both.

## Round 2 verification

New zip built with `zip -rXy`, md5 `d4f9c0de2520b59a3d1856fc0f5c44bd`, 1954 entries. Image
rebuilt `--no-cache` from that extract in **128 s** against `build_timeout_sec = 900`. All runs
airgapped at `--cpus=4 --memory=8g`.

| Check | Reward | Passed | Raw exit | Note |
|---|---|---|---|---|
| NOP | 0 | 0 of 35 | 101 | cargo refuses `--features pqcp` at base |
| Oracle (`solve.sh` twice, then verify) | 1 | 35 of 35 | 0 | 22 s of 900 s |
| Committing agent | 1 | 35 of 35 | 0 | |
| Committing agent **+ `.git` deleted** | **1** | **35 of 35** | 0 | **was 0 / 14 of 35** |
| Agent writes its own copy of the graded file, no `.git` | **1** | 35 of 35 | 0 | new case |
| Atomicity broken | 0 | 11 of 35 | 101 | |
| Error type private again | 0 | 0 of 35 | 101 | |
| `crypto_kem_check_pk` stubbed to accept | 0 | 10 of 35 | 101 | |
| rand gate dropped | 0 | **35 of 35** | 101 | |
| pqcp gates removed | 0 | **35 of 35** | 1 | |
| **KAT vectors trimmed to one line** | **0** | 11 of 35 | 101 | new guard, previously tolerated |

NOP still 0 for the right reason, re-measured on the new `tests.patch`: graded file compiles to
`0 tests, 0 benchmarks` at base, and the 21 p2p ids pass 6 + 15 at base.

Payload round-tripped **out of `test.sh`** before any container time, byte-identical to base, and
confirmed to contain all 21 p2p ids. Git hygiene run last: `fsck` had two unreachable blobs from
regenerating the patch (the two graded test files), cleared, now silent. All 20 static checks pass
on the extract, 7 symlinks, tree clean, both scripts 0755.

## Handling times after round 2

Revisions **110 → 175**, applying the submitter's rule that each revision round adds 50 to 70
minutes to the cumulative revision figure. Round 2 took the upper end of that (+65) because it
carried two cold image builds, eleven verification runs, the payload design and a `tests.patch`
regeneration. The other three fields are first-pass numbers and do not move, so the total stays
45 + 120 + 35 = 200.

175 is above this workspace's stated 60 to 120 revision band. That band is guidance rather than a
gate: `learning/accepted-bundle-reference.md` records the accepted kvdex bundle shipping 195
minutes of revision time against the same band without it costing the acceptance.

---

# Revision round 3 — difficulty, 2026-08-04

## Feedback

```
Review gate blocked at the difficulty screen (cheap single-arm rollout)
Difficulty: FAIL EASY - Requires at least MEDIUM
  claude-opus-4-8: 100.0% (4/4)    codex-gpt-5-5: 100.0% (4/4)
  nop 0.0% (0/1)   oracle 100.0% (3/3)
```

**The agentic judge passed.** The feedback states the screen runs only if the judge passed, so
round 1's oracle fix settled the DISCUSS and difficulty is the only open axis.

## Why round 1's expansion did not move the number, measured

Round 1 added the three things `raising-difficulty-on-a-wrapper-task.md` says earn failures, and
the result went 8/8 to 4/4 with both models still at 100 percent. That is strike two, so instead
of a third expansion I measured the task's shape. Every entry point in the oracle:

| body length | count |
|---|---|
| 1 line | 5 |
| 2 to 4 lines | 8 |
| 5 to 7 lines | 5 |

Eighteen functions, longest body 7 lines, every one delegating to something libcrux exports at the
base commit. **The PR is a naming layer over a complete implementation**, which is why adding API
surface cannot make it hard.

## What round 3 added, and why these two

Requirements sourced from FIPS 203 rather than from the crate, so getting them right needs domain
knowledge and the natural answer is wrong. Both probed in the image before being designed in.

1. **Implicit rejection.** Decapsulation does not report failure. A foreign ciphertext yields a
   secret that is stable for that key and ciphertext, differs from the sender's, and depends on
   the key's own rejection secret rather than the ciphertext alone. Probe confirmed all four
   properties hold in the crate, and that a genuine ciphertext is unaffected by the rejection
   secret.
2. **Pairwise binding in `crypto_kem_check_sk`.** A private key carries the matching encapsulation
   key beside a digest of it and is well formed only while those agree. The rejection secret is
   outside the binding, so a key differing only there stays valid.

**Oracle unchanged.** Both are already satisfied by what PR 1165 delegates to, so round 3 is
instruction plus tests only and `golden.patch` is byte for byte what it was. That also preserves
the judge's 5.0 on `oracle_no_gaming` and `oracle_robustness`.

## Both new requirements discriminate, measured

| Simulated wrong implementation | Reward | Failing tests |
|---|---|---|
| Decapsulation that does not carry the rejection secret through | **0** | exactly the 3 `implicit_rejection_is_stable_and_key_bound` |
| `check_sk` that validates the embedded encapsulation key but skips the digest binding | **0** | exactly the 3 `key_checks_reject_invalid_keys` |

The second is the one that matters. "Validate the public key inside the private key" is a
reasonable thing to write, it rejects every obviously broken key including the all-`0xff` one, and
**it scored 1.0 on the round-2 bundle and 0.0 on this one.**

## Round 3 verification

Zip md5 `c05caaa475f92642de2a3cc7417bc690`, 1954 entries. `fail_to_pass` 14 → **17**, still inside
the 10 to 20 range. Graded set 38.

| Check | Reward | Passed | Raw exit |
|---|---|---|---|
| NOP | 0 | 0 of 38 | 101 |
| Oracle (`solve.sh` twice, then verify) | 1 | 38 of 38 | 0 |
| Committing agent | 1 | 38 of 38 | 0 |
| Committing agent + `.git` deleted | 1 | 38 of 38 | 0 |
| Agent owns the graded file path, no `.git` | 1 | 38 of 38 | 0 |
| Atomicity broken | 0 | 14 of 38 | 101 |
| Error type private again | 0 | 0 of 38 | 101 |
| `check_pk` stubbed | 0 | 13 of 38 | 101 |
| rand gate dropped | 0 | **38 of 38** | 101 |
| pqcp gates removed | 0 | **38 of 38** | 1 |
| KAT vectors trimmed | 0 | 14 of 38 | 101 |
| **no rejection secret in dec** | **0** | 14 of 38 | 101 |
| **check_sk without the digest binding** | **0** | 14 of 38 | 101 |

All 20 static checks pass on the extract, payload still round-trips out of the shipped `test.sh`,
7 symlinks, tree clean, `fsck` silent, both scripts 0755. `golden.patch` deletes no file, so the
`solve-sh-idempotency.md` deleted-file variant of the idempotency check does not apply here.

## The honest ceiling

This is the second difficulty round on a task whose source PR is a wrapper. Round 3 makes the task
genuinely harder and I can prove two plausible implementations that now fail and previously
passed, but I do not expect it to reach medium, because the measurement above says the difficulty
is capped by the PR rather than by the requirements layered on top of it. If the screen returns
easy a third time the documented answer is that PR scope needs replacing, which is the Not Fixable
condition, and that is written into Comments for Reviewer rather than left as a surprise.

## Handling times after round 3

Revisions **175 → 240**, applying the submitter's +50 to 70 per round rule (+65). The file was
carrying 110 when this round started, so the round-2 increment had been lost somewhere; 240 is the
correct cumulative figure for three rounds (110, 175, 240). First three fields unchanged, total
still 200.

---

# Revision round 4 — agentic judge REMOVE, 2026-08-05

## Feedback

```
Review gate blocked at the agentic judge
Agentic judge verdict: remove (oracle_spec_gap)
  oracle_spec_faithfulness 2.0/5   (claude 5, gpt 2)
  test_coverage            4.0/5   (claude 5, gpt 3)
  everything else 4.5 to 5.0
```

Difficulty screen did not run. The judge gates it, so round 3's difficulty work is unmeasured.

## The blocking finding was one I had already refuted twice

gpt's rationale is the **same `super::super::pqcp` claim** as round 0. I reproduced it in round 1,
measured it false (`PK_LEN` 1184 through both paths, every struct function exercised), and wrote
the refutation into Comments for Reviewer. It came back in round 3's report and again here, and
the verdict moved DISCUSS then REMOVE.

**Why the refutation never worked:** the panel reads the instruction, the tests, the oracle and the
task directory. Comments for Reviewer is a submitter form field and is not among them. The
refutation was invisible to the thing that had to be convinced. Two strikes on the same finding,
so per `diagnosing-platform-only-failures.md` the move is to remove the dependency rather than
refine the argument. Recorded as `LEDGER.md` L18, and the rule in `quality-check-criteria.md` that
told me to refute in Comments has been corrected.

## The fix, and why it does not touch PR scope

`super::super::pqcp` is **upstream PR code**, confirmed through the GitHub API: it lives in
`libcrux-ml-kem/src/pqcp.rs` in PR 1165 itself. So the options were narrow. `source-pr-cross-check.md`
says a PR-inherited gap is fixed by narrowing the instruction, but nothing is over-promised here,
because the struct API genuinely works.

What shipped is a behaviour-preserving rewrite. `pqcp_unpacked_api!` now takes the parameter set as
an `ident` and imports the constants through `crate::$variant_mod::pqcp`, which is the same module
the relative path resolved to. Measured identical:

| | before | after |
|---|---|---|
| `mlkem768::pqcp::PK_LEN` vs `mlkem768::unpacked::pqcp::PK_LEN` | 1184 / 1184 | 1184 / 1184 |
| four build configurations | all compile | all compile |
| graded suite | 38 of 38 | 38 of 38 |
| files in `golden.patch` | 6 (= the PR's) | 6 |

Nothing reduced, nothing replaced, so the expansion-only rule is not engaged.

## The two coverage gaps gpt named, both closed

| Gap | Fix | Proven by |
|---|---|---|
| rand-sampling functions not checked to be **absent** when `rand` is off, only built | new probe `sentinel_rand_absent.rs` imports all four, compiled with pqcp on and rand off, plus a seventh command that fails if it compiles | against an implementation that makes `rand` a hard dependency and drops the gate: **reward 0 with all 38 graded tests passing**, `raw_exit 1`. The probe is the only thing that catches it |
| enc/dec specified to skip per-operation validation, but only `check_*`/`parse_*` were exercised | the key-check tests now push a rejected public key through `crypto_kem_enc_derand` and a rejected private key through `crypto_kem_dec`, packed and struct, and require success | oracle 38 of 38 |

A measurement worth keeping: `std = ["alloc", "rand/std", ...]`, so **`--features mlkem768,std` has
the `rand` feature ON**. The genuine rand-off config is
`--no-default-features --features mlkem512,mlkem768,mlkem1024,pqcp`, which is what the new guard
uses. Checked with a `cfg!` probe rather than reasoning about Cargo semantics.

## Round 4 verification

Zip md5 `3d2332614966e3794a1901e233071cce`, 1954 entries. `fail_to_pass` 17, commands 7, graded 38.

| Check | Reward | Passed | Raw exit |
|---|---|---|---|
| NOP | 0 | 0 of 38 | 101 |
| Oracle (`solve.sh` twice, then verify) | 1 | 38 of 38 | 0 |
| Committing agent | 1 | 38 of 38 | 0 |
| Committing agent + `.git` deleted | 1 | 38 of 38 | 0 |
| Agent owns the graded file path, no `.git` | 1 | 38 of 38 | 0 |
| Atomicity broken | 0 | 14 of 38 | 101 |
| Error type private again | 0 | 0 of 38 | 101 |
| `check_pk` stubbed | 0 | 13 of 38 | 101 |
| rand gate dropped | 0 | 38 of 38 | 101 |
| **rand ungated but crate still builds** | **0** | **38 of 38** | **1** |
| pqcp gates removed | 0 | 38 of 38 | 1 |
| KAT vectors trimmed | 0 | 14 of 38 | 101 |
| no rejection secret in dec | 0 | 14 of 38 | 101 |
| `check_sk` without the digest binding | 0 | 14 of 38 | 101 |

All 20 static checks pass on the extract, payload round-trips out of the shipped `test.sh`,
7 symlinks, tree clean, `fsck` silent, both scripts 0755.

## Quality rehearsal before zipping

Ran the `quality-rehearsal` skill. Q9 returned one candidate, `instruction.md:19` "encapsulation
key **alongside** a digest of it", triaged as a true negative: it describes a key's data layout,
not where code lives or goes. Q10 returned five hits, all `PQCPError` variant names, which are
required public names the agent must create and therefore the deliverable row of the triage table.
No auto-REMOVE pattern; the one `|| true` in `test.sh` is on a config read, not the suite line.

## Handling times after round 4

Revisions **240 → 305** (+65, the submitter's rule). First three fields unchanged, total 200.

## `download/original` is no longer a valid diff target

The filesystem move flattened its symlinks too: `find download/original/environment/repo -type l`
returns **0** where `work/` returns 7. So `diff -rq download/original work -x .git` reports three
phantom entries (`benches`, `intrinsics`, `tests` under `extracts/c_header_only/generated/`) that
are symlinks correctly present in `work/` and missing from the reference, not changes. The eight
real file differences are the ones intended. Re-extract `download/original` from
`download/*_submission.zip` before trusting that diff again.

---

# Round 5 — the difficulty verdict, 2026-08-05

## Feedback

```
Review gate blocked at the difficulty screen (cheap single-arm rollout)
Difficulty: FAIL EASY - Requires at least MEDIUM
  claude-opus-4-8: 100.0% (4/4)    codex-gpt-5-5: 100.0% (4/4)
  nop 0.0% (0/1)   oracle 100.0% (3/3)
```

**The agentic judge passed**, so round 4's path fix cleared the REMOVE and difficulty is the only
red gate. Third difficulty failure.

## What was done before deciding

An eight-lever exploration was run as a workflow, each lever measured in the task image, each
viable one then adversarially refuted. 11 agents, 317 tool calls, 1.6M tokens, 28 minutes.

| Lever | Verdict | Measured basis |
|---|---|---|
| instruction underspecification | large effect but **banned** | `docs/guidelines.md:197` forbids difficulty from underspecification. Also overshoots: one argument-order difference takes the suite 17 passed to **0**, one compilation unit |
| eurydice C-extraction gate | 0 | agent self-verifies offline in 7 s; repo shows the idiom **10/10, no counter-example** |
| wycheproof KAT conformance | 0 | **six independent keygen routes measured byte-identical**, so any delegating impl is conformant by construction |
| cross-variant length dispatch | 0 | base already returns `InvalidEncapsKeyLength`; prototype 38 lines, compiled first try |
| trait genericity | 0 | three incompatible designs each compiled and passed **first attempt** |
| incremental API wrapper | 0 | full simulated layer compiled and passed first try, bodies 1 to 6 lines |
| zeroization on drop | 0 | correct answer measured at **three lines** |
| no-std / alloc-free | 0 | already enforced by command 4; zero `Vec`/`vec!` in 100% of source |

Two partials, both **refuted** under adversarial verification. Zero survivors. Killed in earlier
rounds on evidence: C ABI (`deny(unsafe_code)`) and backend-aware alias (workspace-wide simd256).
Ten expansions tried or prototyped in total.

## The verdict, reasoned from the guidelines

`docs/guidelines.md:217` is decisive and names difficulty explicitly:

> If the only way to make a task solvable, **difficult enough**, or valid is to reduce or replace
> the PR scope, the task is **Not Fixable**.

and the Fixable row at `:65` is conditional in the matching way, "Overall task is too easy **but
you can raise difficulty by adding to the PR scope**". So the verdict turns on one empirical
question: can difficulty be raised by *adding*? Evidence that it cannot:

1. **It arrived easy and the platform had already tried.** `download/original/task.toml`:
   `pass_at_k_opus_4_8 = "2/3"`, `pass_at_k_gpt_5_5 = "2/3"` (67% against a bar needing ≤50%),
   `agent_hardened = "true"`, `hardening_cycles = "1"`.
2. **Two expansions shipped, neither moved it.** 8/8 → 4/4 → 4/4, both models 100% throughout.
   Both verified to fail plausible wrong implementations that previously scored 1.0, so the
   requirements discriminate; they do not make the work hard.
3. **Eight more prototyped, all zero**, three passing on the first attempt.
4. **Structural cause.** 18 oracle bodies of 1 to 7 lines, all delegating to base-commit exports.
   `removed/added = 0.01` against 0.60 to 0.79 for the two `hard` tasks; `pass_to_pass` 21 against
   112 to 1204. Nothing existing can break, so the failure class that makes those tasks hard is
   absent.
5. **Not sampling noise.** 16 successes across two models and three screens.

Trigger box: **PR scope needs to be changed or reduced**. Environment Issues deliberately left
blank and said so in the answers, since the environment is healthy (image builds, oracle 3/3,
NOP 0, 20/20 static checks, no network dependency, git clean).

## Supersedes the two earlier Not-Fixable passages in this file

The round-3 and round-4 blocks above say a third easy screen makes the documented answer Not
Fixable. That was an overclaim on its own terms and `learning/platform-announcements.md` says so
directly: a failed Difficulty Check is never automatically a Not Fixable verdict, because a
difficulty result is not on the `docs/guidelines.md` list. The verdict now reached is **not** that
one. It rests on the PR-scope trigger at `guidelines.md:217`, backed by the measured cause and the
exhausted option space above. The Comments for Reviewer sentence carrying the old inference was
rewritten before this round shipped.

## What carries over if the task is re-scoped

The bundle is not wasted. 17 issues were found and fixed across rounds 1 to 4 and every local check
passes on the round-4 zip `3d2332614966e3794a1901e233071cce`: oracle 38/38 with `solve.sh` applied
twice, NOP 0/38 verified for the right reason, nine hostile probes all reward 0 with the failing
test named, three agent-hostile runs at 38/38, 20/20 static checks. The git-free test-tree restore,
the fail-closed grader and the command-as-requirement technique are all reusable.

Two measured findings left unshipped because neither is a difficulty lever, both documented for
whoever picks up a replacement PR: a solution gating the new module only on the cargo feature
(without the `not(eurydice)` conjunct the rest of the crate uses) currently earns reward 1 while
breaking C extraction; and the repo's own invalid-key vectors can drive a conformance suite.

## Handling times after round 5

Revisions **305 → 370** (+65, the submitter's rule). Fields 1 to 3 unchanged, total 200. The
difficulty question is not asked on this path (`docs/tasking-guide.md:214`). The answers file had
silently reverted to 200 on the revisions field for a second time, so it was re-read from the
ledger rather than from the file.

---

# Closed: ACCEPTED, 2026-08-11 (Step 11)

The reviewer accepted the submission. Final round **5**, verdict **Invalid / Not Fixable**, trigger
box "PR scope needs to be changed or reduced", every Environment Issues sub-box left blank on
purpose. No Submission Quality Score was relayed.

Handling-time ledger closes at **370** minutes of revisions (rounds 1 to 5). Fields 1 to 3 never
moved: 45 review, 120 rewrite, 35 form, total 200.

**What the reviewer saw.** Path C has no zip upload field, so the accepted submission was four
things: the verdict, the two checkbox groups, a 4929-character seven-block unfixable explanation
and 2172 characters of Comments for Reviewer. The round-4 zip
`3d2332614966e3794a1901e233071cce` was never uploaded and never graded.

**Harvest (Step 11 item 4).** New note `learning/not-fixable-is-a-written-argument.md`, carrying
what the reviewer saw, the seven-block structure that was accepted, and the validated versus
not-validated split. `learning/raising-difficulty-on-a-wrapper-task.md` gained the outcome and
keeps the evidence. LEDGER **L45** (the `instr_max_para_chars` script bug), **L46** (a difficulty
result alone is not the verdict, but a measured inability to raise it is) and **L47** (a verdict
path change destroys the answers file). `.claude/rules/` gained Step 11, the Path C evidence bar,
the "difficult enough" limb in the verdict criteria, and the answers-file lifecycle rule.

**Superseded in this file.** The round-3 and round-4 blocks above say a third easy screen makes
Not Fixable the documented answer. That was an overclaim on its own terms and is recorded as
LEDGER L46. The verdict that was accepted rests on the PR-scope trigger at `docs/guidelines.md:217`
plus a measured cause plus an exhausted option space, not on the red screen.
