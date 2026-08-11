# 20260805_080500__statrs-dev_statrs__315

| Field | Value |
|---|---|
| Repo / PR | statrs-dev/statrs [315](https://github.com/statrs-dev/statrs/pull/315) |
| Submission id | 8b7cc519-d8a3-49f7-9d5f-0c51c048058a |
| Base commit | `a8fe65cdeb10548b01ad8897a17b0a9bfdfbf0af` (equals `git rev-parse HEAD`) |
| Category | implementation / feature |
| Declared difficulty | hard (`model_difficulty` says medium, see observation 16) |
| Language | Rust, cargo, `rust:1.89` |
| Claimed | 2026-08-05 |
| Verdict | **Fixable** |
| Status | `accepted` |
| Round | 4 |

Source zip as received: `8b7cc519-d8a3-49f7-9d5f-0c51c048058a_submission.zip`, sha256
`42d30f41b61bc20987e12221dd1d3abdcf65dc844fe8010ecd94001a9f2cc67f`, 3454577 bytes, 108
entries, 0 symlinks, no `runs/` directory and no `task/` wrapper. It unpacks straight to
`instruction.md`, `task.toml`, `environment/`, `solution/`, `tests/`.

## Arrangement record

Arranged 2026-08-05 per CLAUDE.md Step 1.5 and Step 2 item 0. `download/original/` holds the
pristine extract and is frozen from that point. `work/` was made with
`cp -a download/original/. work/` before any command ran, and `diff -rq download/original work`
reported the trees identical afterwards. All inspection below ran against `work/`, never
against the pristine extract.

**Throughput.** This task was claimed while `INDEX.md` read `pending-revision: 3 of 2`, which
CLAUDE.md Step 1 item 5 treats as drift to resolve before anything else happens. It resolved
during arrangement: libcrux 1165 had already moved to `sent-to-reviewer` as Invalid / Not
Fixable and the register had not recorded it, so the true count was 2 and this claim was
legitimate. The count now sits **at** the cap, so no further task may be claimed until jqno
1166 or AltBeacon 1177 clears. Those two rows are still unconfirmed against
`stb submissions list`, which has not been run and is the only thing that would confirm them.

## Upload ledger

| # | Date | Zip sha256 | Size | Checks returned | Outcome |
|---|---|---|---|---|---|
| 1 | 2026-08-05 | `ebcad9efe872ba68db1b7c0cceacd2112b4a2b1c2ebbfc6b46c05bb2ac917068` | 2652838 bytes, 126 entries | review gate | Blocked at the **agentic judge**. DISCUSS, reason `coverage_gap`, `test_coverage` 3.0. Difficulty screen not run |
| 2 | 2026-08-06 | `f7a1c14c90765ce8218b246f7d5ed88aeade8e954089f1dfdb29cbbc2816756e` | 2654992 bytes, 126 entries | all evaluation checks PASSED; peer reviewer returned feedback | Exact Mann-Whitney tails inverted whenever n1 <= n2, and the round-1 swapped block asserted the inverted values as correct |
| 3 | 2026-08-07 | `39f5cc265e1f4ec03c29ea4c304221d439823579d74bd8f7a02062baa57d50b3` | superseded before upload | Round 2 first build. Replaced by zip 4 after the dash guard went in |
| 4 | 2026-08-07 | `2684c13077f9159db993834942e16171001b654453ac9a8941fb6aea532c4716` | agentic judge PASSED, difficulty screen **FAIL EASY** | Round 2 final. Oracle bug fixed under `guidelines.md:286` case 1, reference values pinned, ties coverage added, loose git ref written back, dash re-exec guard on both entrypoints |
| 5 | 2026-08-07 | `03f209da…` | superseded before upload | Round 3 first build. Replaced by zip 6 after the anderson_darling skip went in |
| 6 | 2026-08-07 | `da7254bfe2462258071c337e08672de508e410b987161126f70b45e4193fed2f` | agentic judge PASSED, difficulty screen **FAIL EASY** again, 7/8 | Round 3 final. PR scope expanded with an adapted Anderson-Darling test, f2p 19 to 18 after merging padded ids, lever measured against four wrong implementations. Full battery green |

Source zip as received: `42d30f41b61bc20987e12221dd1d3abdcf65dc844fe8010ecd94001a9f2cc67f`,
3454577 bytes, 108 entries, 0 symlinks.

## Verdict basis

**Fixable.** Every defect sits inside the editable surface: `instruction.md` and its
`problem_statement.md` copy, the three `tests/` files, `solution/solve.sh`, `task.toml`
metadata, git metadata, and two mode bits. Every tracked source file under `environment/repo`
is byte-identical to the base commit, so PR scope is unchanged. **Superseded in round 2 on one
point:** `solution/golden.patch` was untouched through rounds 0 and 1, and round 2 edited it in
two hunks to correct an inverted exact Mann-Whitney tail, which `docs/guidelines.md:286` permits
as case 1, an oracle that does not implement the instruction. The file list is still the PR's
same 6 files and no feature was added or removed. Confirmed against the live PR: it changes exactly 6 files, golden's 6 paths match
that list exactly, and the API answer was corroborated a second time against `changed_files: 6`.
The PR is +1471 -0, purely additive, so every unasserted variant was already implemented and
the coverage gap was a test gap rather than the instruction over-promising the PR.

## The headline defects

Four, all measured rather than argued.

1. **`solve.sh` reverse-applied its own patch as the success path.** Replayed three times over
   a scratch copy: SOLVED, BASE, SOLVED. A predicted Oracle 2/3 on the platform, which is a
   prediction from a local replay and not a platform result (LEDGER L5).
2. **The grader was fail-open**, the stock defect verbatim at `test.sh:507`. Proven by running
   the extracted grader twice over one passing log: reward 1 at exit 0, reward 1 at exit 1.
   After the fix the same experiment returns reward 1 then reward 0.
3. **No regression guard at all.** `pass_to_pass` empty, `allow_extra_failures` true, and the
   command ran only the new integration file, leaving 628 existing tests ungraded.
4. **The instruction published the answer key.** All seven full-precision constants appeared
   verbatim in `tests.patch`, so 5 of the 11 graded tests were passable by a lookup table.

## Fixes applied

| File | What changed | Why |
|---|---|---|
| `instruction.md` | Rewritten. All 7 constants, the quoted assertion, 8 internal `src/` paths, the two layout sentences and the verifier-describing sentence removed. Restructured into short paragraphs. Longest paragraph 2312 to 709 chars. Now plain ASCII | Q9 and Q10 are must-have criteria and block on their own |
| `environment/problem_statement.md` | Byte-identical copy re-taken | Must match |
| `solution/solve.sh` | Four-step shape: reverse `--check` probe, plain apply, `--3way`, loud failure. `set -euo pipefail` | The reverse-apply fallback undid the solution on run 2 |
| `tests/test.sh` | Exit status added to the success expression. Pre-delete of the paths `tests.patch` creates, git-independent, limited to `new file mode` entries | Fail-open grader; create-only patch could not survive an agent writing the same path |
| `tests/tests.patch` | 8 new graded tests (11 to 19). 5 statistic tolerances 1e-1 to 1e-9/1e-12, 2 rounded values replaced with measured full precision | 6 stated requirements had no enforcing assertion |
| `tests/config.json` | f2p 11 to 19, p2p 0 to 109, `allow_extra_failures` true to false, command now runs the lib suite while skipping the 5 new modules, inner timeout 1800 to 240 | No regression guard; the two declared timeouts disagreed 6x |
| `task.toml` | `repo_license` "" to "MIT", added `os = "linux"`, added `difficulty_explanation` | Blank licence against an MIT repo; two documented fields missing |
| `environment/repo/.git` | Removed `refs/remotes/origin/HEAD` and stale `COMMIT_EDITMSG`, expired reflog, pruned | fsck reported an invalid sha1 pointer; the commit message named the removal of eval tests in an agent-readable path |
| `environment/repo/tests/gather_nist_data.sh` | Mode restored to 0755 | git records 100755; the shipped tree was dirty before any edit |
| `solution/solve.sh`, `tests/test.sh` | Modes 0644 to 0755 | Non-executable entrypoints fail at run time |
| `solution/golden.patch` **(round 2)** | `calc_mwu_exact_pvalue` returns `numerator / total` unconditionally, dropping the `if k == n1` inversion. The PR's own `test_calc_mwu_exact_pvalue` expectation moved 0.6 to 0.4 in lockstep | The exact one-sided p-values were inverted whenever `n1 <= n2`, so the oracle did not meet the instruction's scipy parity contract. `guidelines.md:286` case 1. Upstream fix genuinely unavailable, statrs master still carries the branch |
| `environment/repo/.git/refs/heads/main` **(round 2)** | Loose ref written back after the gc | `learning/empty-git-refs.md`. `git gc` left `.git/refs` as nothing but empty directories, which any extractor that drops empty dirs turns into `fatal: not a git repository` |

## Step 5.5 battery, against a fresh extract of zip 1

| Run | Result |
|---|---|
| NOP | reward **0**, `raw_exit_code` **101**, `infrastructure_error: None`. 128 of 128 required missing |
| NOP split A (executed) | The 109 `pass_to_pass` guards DO compile at base and **109 of 109 pass**, so they are genuine |
| NOP split B (symbol audit, not a run) | All five modules absent at base. `git ls-tree -r HEAD -- src/stats_tests` prints only `fisher.rs` and `mod.rs`; `NaNPolicy` occurs in 0 files under `src/` |
| Oracle | **3/3 at reward 1.0**, 128/128 required passing each run, `raw_exit 0`. Wall 20s cold then 1s and 2s, against a 300s budget |
| Hostile 1 | ddof stubbed, reward **0**, caught by `chisquare_ddof_reduces_the_degrees_of_freedom` |
| Hostile 2 | `Emit` stops filtering, reward **0**, caught by `nan_policy_emit_drops_nans_before_computing` |
| Hostile 3 | continuity correction dropped, reward **0**, caught by `mannwhitneyu_asymptotic_variants_differ_by_the_continuity_correction` |
| Hostile 4 | one `Display` impl prints nothing, reward **0**, caught by `error_enums_implement_display_and_the_error_trait` |
| Hostile 5 | `Normal::sf` stubbed, reward **0**, caught by `distribution::normal::tests::test_sf`, a NEW regression guard. 628 tests ran, so this was a real guard failure and not a compile abort |

**A self-inflicted trap worth recording.** The first hostile run reported all four probes
surviving. That was a harness bug in the probe wrapper (`name="$1"; shift` then `$1`), so no
`sed` ever ran and the break never landed. `learning/verify-in-the-image.md` names this exact
failure. Every probe now asserts its pattern was found before the run proceeds.

## Things deliberately NOT changed

- **`environment/Dockerfile` is untouched.** Its `patch(1)` install chain ends in `|| true`, but
  `git` is installed unconditionally and `/app` is a real git repository, so the fallback is
  never needed. Section 10.7 says report rather than fix when nothing downstream breaks
- **No `Cargo.lock` added.** Only `Cargo.lock.MSRV` ships and `.gitignore` excludes `*.lock`, so
  the graph resolves fresh at build time. Adding one means putting a file in the source tree
  upstream deliberately does not carry
- **`model_difficulty = "medium"` vs `difficulty = "hard"` left contradictory**, per Section 8
  and LEDGER L14: report, never quietly reconcile
- **`config.json` parser patterns left alone.** They cannot see the 49 `#[should_panic]` tests,
  which print as `test NAME - should panic ... ok` and match neither pattern. The new exit-code
  gate already covers a should-panic test failing, so changing the regex would exceed the finding
- **`[verifier] timeout_sec` left at 300.** Measured oracle wall time is 20s cold, so the budget
  is ample and raising it would be unjustified

## Failure signatures

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Agentic judge DISCUSS, `coverage_gap`, `test_coverage` 3.0 | 1 | round 1: direction-sensitive one-sided assertions, MWU `Less`/`Greater`, chi-square multi-error precedence, Emit-shrink edges | 1 |
| Peer reviewer: Mann-Whitney exact coverage | 2 | round 2: oracle inversion fixed, reference values pinned for both sample orders, ties coverage added | 1 |
| Difficulty screen FAIL EASY | 3, 4 | round 3: PR scope expanded with an Anderson-Darling test adapted from PR 346, lever measured against four wrong implementations before shipping; round 4: theory replaced after the expansion measured at zero, three oracle-versus-natural divergences graded instead | **2** |

`Not run: difficulty screen` is **not** a row here. The review gate runs the agentic judge
first and the difficulty screen second, so a judge block means the screen never started. A
stage that never ran is not a failure signature (`docs/faq.md`, review-gate FAQ).

## Handling time ledger

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 0 (first pass) | 2026-08-05 | 195 | 195 |
| 1 | 2026-08-06 | 60 | 60 |
| 2 | 2026-08-07 | 65 | 125 |
| 3 | 2026-08-07 | 65 | 190 |
| 4 | 2026-08-07 | 65 | 255 |

The first-pass row is fields 1 + 2 + 3 and is the **total submission time**, which stays at
**195** and does not move on a revision round. Every later row is the **revisions** field, which
is tracked separately and accumulates. So after round 2 the answers file carries **195** as the
total and **125** as the revisions figure, never 320. The revisions number is copied from the
last Cumulative cell above rather than re-estimated.

Fields 1, 2 and 3 are 45, 105 and 45.

## learning/ notes applied

Written before Step 3, as Step 1 item 6 requires. Status is what the recon actually settled,
not what the note says in general.

| Note | What it predicts here | Command that settles it | Status |
|---|---|---|---|
| solve-sh-idempotency.md | `solution/solve.sh:9` is a bare `git apply -p1 -R` as the `else` branch, with no `--reverse --check` probe and no `exit 1`, so a second invocation reverse-applies golden.patch and exits 0 | replay the three branches three times over a scratch copy of `environment/repo` | **CONFIRMED and measured.** Replay gave SOLVED, BASE, SOLVED. See observation 1 for why that is a predicted 2/3 and not the 1/3 an earlier draft claimed |
| verifier-fail-open.md | `tests/test.sh:507` is `success = not missing_required and not unexpected`; `raw_exit_code` appears only at :446 and :470 as report fields | `grep -n 'raw_exit_code\|success = ' tests/test.sh` | **CONFIRMED.** The stock defect verbatim. `execution.commands` is one non-piped entry, so `TEST_EXIT_CODE` at :139 is already cargo's own status and a gate would read the right value |
| stock-bundle-defect-baseline.md | 4 of the 6 stock rows present: fail-open grader, no regression guard, non-idempotent solve.sh, no test-tree restore | the three greps in the note | **CONFIRMED 4 present, 2 absent.** Stale build-time reports absent (Dockerfile:6 is `cargo fetch` only); predictable test-file name absent (`pr315` suffix) |
| quality-check-criteria.md | Both blocking `criterion: Instructions` defects present: the instruction transcribes the graded constants, and it names internal source paths | per-constant `grep -c` over `instruction.md` and `tests/tests.patch` | **CONFIRMED.** 7 of 7 full-precision constants hit exactly once in each file; 8 `src/stats_tests/` path mentions |
| dirty-repo-and-symlinks.md | Mode half fires, symlink half does not | `git -C environment/repo status --porcelain; find . -type l \| wc -l` | **CONFIRMED.** One row, ` M tests/gather_nist_data.sh`, `mode change 100755 => 100644`, 0 insertions 0 deletions. Zero symlinks anywhere, so the `zip -y` assertion is a free 0 == 0 |
| unreachable-git-blobs.md | Dangling-blob half refuted, fsck-only half fires | `git -C environment/repo fsck --unreachable --no-progress` | **CONFIRMED for the broken ref, REFUTED for blobs.** fsck errors on `refs/remotes/origin/HEAD` invalid sha1 pointer; reachable and total object counts match at 5765, so no golden or test blob is dangling |
| source-pr-cross-check.md | The paging trap could produce a wrong file list | `curl` the API with `per_page=100`, page until short, then diff against golden's paths | **CONFIRMED CLEAN.** PR 315 is 6 files, corroborated by `changed_files: 6` from the metadata endpoint. Golden's six paths match exactly. The PR is +1471 -0, purely additive |
| tests-patch-vs-agent-edits.md | The shape choice is already settled and the restore is missing | `sed -n 's\|^+++ b/\|\|p' tests/tests.patch; grep -nE 'rm -f\|rm -rf\|checkout\|base64\|tar ' tests/test.sh` | **CONFIRMED.** 0 of 11 graded ids live outside the patched file with an empty UNRESOLVED list, so create-only suffices and no base64 payload is needed. No pre-delete exists anywhere in `test.sh` |
| static-checks.md | All 20 upload checks pass as it stands, which says nothing about the blocking defects | the file-presence loop, f2p count, `ls -A tests/`, `git remote`, `du -sh .git` | **CONFIRMED all green.** f2p 11 inside the hard 10-20 band; `tests/` holds exactly the three legal names; `instruction.md` and `environment/problem_statement.md` byte-identical; `.git` 2.6M with no reflog. `core.logallrefupdates` is true, so any git command run while fixing recreates `.git/logs` before the zip |
| prescriptiveness-check.md | AltBeacon shape rather than equalsverifier: the module paths are genuine public API, but the six `src/` file paths and the where-the-code-lives clauses are Rule 2 findings | per-symbol `grep -c` over the instruction, the added lines of `tests.patch`, and golden | **CONFIRMED split.** Five instruction-named symbols have zero references in the graded tests; the five function names, `NaNPolicy`, `SampleTooSmall` and `ExactMethodWithTiesInData` are all called. The score itself is only observable on a build round |
| peer-review-bounces.md | The `git apply -R` success path and the 0644 script modes are both rules a reviewer has already bounced a green bundle for | `stat -c '%a %n' solution/solve.sh tests/test.sh` | **CONFIRMED both.** 644 on each, and the shipped zip stores them `?rw-r--r--`, so the loss originates in packaging and not in local extraction |
| accepted-bundle-reference.md | The instruction's paragraph shape sits in the bounced band | paragraph-length measure over `instruction.md` | **CONFIRMED.** Longest paragraph 2312 chars against kvdex 717 accepted, equalsverifier 447, libcrux 791, and AltBeacon bounced twice at 2724 |
| calibration.tsv | statrs enters as an outlier on several columns | config dump, `stat`, `grep -n timeout_sec task.toml` | **CONFIRMED on six columns.** `pass_to_pass` 0 against 21/112/210/1204; graded-outside-patched 0 of 11, the first ever zero here, so create-only has never been validated on this workspace; `allow_extra_failures` true where three of four rows are false; both script modes 0644 where all four rows are 0755; verifier timeout 300 where every row is 900 or 1800; f2p 11 against 17/19/20/20 |
| LEDGER.md | Four rows fire | the greps in each row | **CONFIRMED.** L9 create-only patch with no pre-delete; L13 `allow_extra_failures` may go false because the field already ships; L14 report the `model_difficulty` / `difficulty` clash rather than reconcile it; **L5 do not write the solve.sh reverse-apply up as the cause of an Oracle result nobody has measured** |
| raising-difficulty-on-a-wrapper-task.md | Same language and runner, and the ratio metrics say this should measure easy | add/remove ratio and per-function body length over golden | **CONFIRMED, and it argues against opening a difficulty round.** Golden is +1471 -0 so removed/added is 0.00, below libcrux's 0.01 which measured easy three times. But `pass_at_k_opus_4_8` is already `0/3` and `pass_at_k_gpt_5_5` is `1/3`. The discriminator is oracle body length: five modules of 177 to 534 lines of real numeric work against libcrux's 18 delegating functions |
| stale-test-reports.md | Predicts absent | `grep -nE '^RUN .*(cargo (test\|build))' environment/Dockerfile` | **REFUTED, both halves.** The Dockerfile never runs the suite at build time and the grader never reads a result file. The corollary still binds through the compile-failure route, see observation 21 |
| solve-sh-under-sh.md | Bashisms in a script the harness may run under `sh` | `grep -nE '\[\[\|BASH_SOURCE\|pipefail' solution/solve.sh tests/test.sh; sh -n` both | **REFUTED for `solve.sh`, fires for `test.sh`.** `solve.sh` is dash-safe and `sh -n` exits 0. `sh -n tests/test.sh` dies at :132 on `RUNNER=(bash /tmp/run_tests.sh)`. Both files carry a bash shebang, but both are 0644, so whatever invokes them chooses the interpreter |
| verify-in-the-image.md | The NOP target will not compile at base, so every graded id lands in `missing_required` regardless of merit | `docker build` then `cargo test --test stats_tests_pr315 -- --list` inside the image | **OPEN on the run, CONFIRMED on the symbols.** `git ls-tree -r HEAD -- src/stats_tests` shows only `fisher.rs` and `mod.rs`, so all five imported modules are absent at base. No cargo or rustc on this host, so no compile claim can be made outside the image |
| local-runs.md | The ext4 update holds and the disposable copy is small | `df -Th .` | **OPEN on timing, CONFIRMED on environment.** ext4 on `/dev/nvme0n1p5`, so the NTFS wedge is history. The timing risk is a cold cargo compile against `[verifier] timeout_sec = 300.0` |
| diagnosing-platform-only-failures.md | The platform-only risk here is time, not path | `grep -nE 'CARGO_HOME\|cargo (fetch\|build\|test)' environment/Dockerfile` | **OPEN.** `rust:1.89` sets `CARGO_HOME` absolutely so the AltBeacon relative-cache trap is safe by inheritance. Two-strikes applies pre-emptively: four blocking defects are locally verifiable, so any surviving platform failure is strike one on a new signature |
| git-autofetch-watcher.md | An editor's periodic fetch rewrites `.git/FETCH_HEAD` inside every checkout | `find tasks _archive -name FETCH_HEAD`; `ls -A environment/repo/.git` | **OPEN, clean at recon time.** No `FETCH_HEAD` and no `ORIG_HEAD` anywhere. The result must be re-taken immediately before any zip rather than carried forward, because `diff -rq download/original work -x '.git'` cannot see it |

## Step 2 observations (pre-analysis)

Observation log only. No fix is proposed and no verdict is stated; Step 3 works from here.

1. **`solve.sh` reverse-applies golden.patch as its success fallback.** `solution/solve.sh` is ten lines: `:4` plain forward apply, `:6` `--3way` retry, `:8-9` `else` / `git apply -p1 -R --whitespace=nowarn /solution/golden.patch`. No `--reverse --check` probe, no `exit 1`, no `>&2`, nothing after `fi`. Replayed three times over a scratch copy of `environment/repo`: run 1 forward-applied and `src/stats_tests/` held 7 files, run 2 fell through to the reverse branch and it dropped to 2 files, run 3 forward-applied back to 7. **Predicted platform result is Oracle 2/3, not 1/3 and not 0/3**, on the reading that the platform runs solve-then-test three times. That number is a prediction from a local replay, and per LEDGER L5 it must not be written up as the cause of any Oracle result until the platform has actually returned one. Maps to Fixable trigger 7.
2. **The grader is fail-open, the stock defect verbatim.** `tests/test.sh:507` is `success = not missing_required and not unexpected` and `:508` `reward = 1.0 if success else 0.0`. `raw_exit_code` occurs only at `:446` and `:470` as report entries. The status is captured at `:139` `TEST_EXIT_CODE=$?` and passed in at `:534` `--raw-exit-code "$TEST_EXIT_CODE"`, then never read by the decision. A cargo compile failure or a timeout that still prints the eleven `test <name> ... ok` lines writes reward 1.0 alongside a nonzero exit. Closest fit is Fixable trigger 12; Section 10.1 covers the invariant directly.
3. **The shipped tree is dirty on a tracked pre-existing test file.** `git -C environment/repo status --porcelain` prints ` M tests/gather_nist_data.sh`. `git diff --summary HEAD` says `mode change 100755 => 100644` with 0 insertions and 0 deletions, so the delta is the exec bit only and no content edit is involved. This fails the Phase A gate that requires porcelain to print nothing. Maps to Fixable trigger 12.
4. **Both entrypoint scripts ship non-executable.** `stat -c '%a %n' solution/solve.sh tests/test.sh` returns 644 for each, and `zipinfo` shows `?rw-r--r--` for `solution/solve.sh`, `tests/test.sh` and `environment/repo/tests/gather_nist_data.sh`, so one packaging event stripped the bit off all three and observations 3 and 4 share a root cause. This is the non-executable-scripts row of the allowed-fix table and it fails at run time, not build time. Maps to Fixable trigger 9.
5. **A broken remote ref ships inside the repo.** `environment/repo/.git/refs/remotes/origin/HEAD` contains `ref: refs/remotes/origin/main` while `packed-refs` holds only `refs/heads/main`. `git fsck` prints `error: refs/remotes/origin/HEAD: invalid sha1 pointer 0000...`. `git remote -v` is empty, so the platform's no-remote check passes over it and `for-each-ref` does not list it. Maps to Fixable trigger 10.
6. **The instruction transcribes the graded assertion values.** All seven full-precision constants on `instruction.md:5` grep to exactly one hit each in `tests/tests.patch`. The instruction also states `chisquare(&[16], None, None)` must be `Err(ChiSquareTestError::FObsInvalid)`, which is `tests/tests.patch:38-41` verbatim, and quotes "about `9.3`" and "about `0.002`" matching the 1e-1 and 1e-3 tolerances at `:69-70`. Maps to Fixable triggers 6 and 1, and to the blocking Q10 criterion.
7. **The instruction names internal source paths and the file layout.** Eight `src/` hits on lines 1 and 3: two bare `src/stats_tests/`, `src/stats_tests/mod.rs`, and the five creation targets. Line 1 also carries "These additions live within the structure established by the Fisher module: one file per test under `src/stats_tests/` ... with every new module registered in `src/stats_tests/mod.rs`." Maps to Fixable trigger 1 and to the blocking Q9 criterion.
8. **The instruction tells the agent where existing code lives today.** `instruction.md:1` reads "right now `src/stats_tests/` only offers Fisher's exact test" and "a sibling of the existing `Alternative` enum". Same prescriptiveness rule from the other direction. Maps to Fixable trigger 1.
9. **The instruction describes the verifier to the agent.** `instruction.md:1` reads "Comparisons in the accompanying tests go through the crate's existing `statrs::prec::almost_eq` helper, so the results must land within the stated tolerances; the test files remain unmodified." That names the comparison helper and promises the test files will not change. Maps to Fixable triggers 6 and 1.
10. **Six stated requirements have no enforcing assertion.** Zero hits in `tests/tests.patch` for `MannWhitneyUError::UncomparableData`, both `MannWhitneyUMethod::Asymptotic*` variants, `NaNPolicy::Propogate`, `NaNPolicy::Emit`, and the `std::error::Error` plus `Display` requirement. `FOneWayTestError::SampleTooSmall` is in the instruction's enum while `f_oneway_error_cases` asserts only the other three variants. The graded tests only ever pass `NaNPolicy::Error` and `Alternative::TwoSided`. All of these are implemented in golden and by the PR, so this is a test gap and **not** the instruction over-promising the PR. Maps to Fixable trigger 3.
11. **No regression guard at all.** `grading` has `"pass_to_pass": []`, `"required_pass": []` and `"allow_extra_failures": true`, and `execution.commands` is the single entry `cargo test --test stats_tests_pr315`, so the repo's own suite is never graded. The base tree carries **613** `#[test]` functions across 44 inline `#[cfg(test)]` modules plus `tests/nist_tests.rs`, none of them guarding anything. A solution that compiles but breaks behaviour elsewhere in the crate still scores 1.0. The `allow_extra_failures` field already ships, and the run executes exactly the eleven graded ids. Maps to Fixable trigger 12.
12. **`test.sh` has no pre-delete before applying a create-only patch.** `tests/tests.patch` has 1 `diff --git`, 1 `new file mode 100644`, 1 `--- /dev/null`, creating `tests/stats_tests_pr315.rs`. `grep -nE 'rm -f|rm -rf|checkout|base64|tar |stats_tests_pr315' tests/test.sh` returns nothing, and `:66-85` goes straight to `git apply`, then `--3way`, then `patch -p1 --forward`, then `infrastructure_error`. `tests.patch:3` is `index 0000000..0000000`, so `--3way` has no blob to merge against. An agent that creates that path kills the apply and the trial scores invalid rather than on merit. Collision odds are low given the `pr315` suffix, but the cost when it fires is a whole round. Maps to Fixable trigger 12.
13. **`[metadata] repo_license` is an empty string.** `task.toml:15` is `repo_license = ""` while `environment/repo/LICENSE.md:1` is "MIT License" and `Cargo.toml:6` is `license = "MIT"`. Maps to Fixable trigger 11.
14. **`[environment] os` is absent.** The whole block is `task.toml:42-48` and holds only `build_timeout_sec`, `cpus`, `memory_mb`, `storage_mb`, `gpus`, `network_mode`. It is a documented Harbor field present in the reference `task.toml`. Maps to Fixable trigger 11.
15. **`[metadata] difficulty_explanation` is absent**, so nothing in the bundle justifies the declared tier. Maps to Fixable trigger 11.
16. **The two difficulty fields contradict each other.** `task.toml:18` is `model_difficulty = "medium"`, `:21` is `difficulty = "hard"`. Section 8 and LEDGER L14 both say report it rather than quietly reconcile it. Maps to Fixable trigger 11.
17. **The two declared verifier timeouts contradict each other and the smaller one is tight.** `task.toml [verifier] timeout_sec = 300.0` against `tests/config.json:13 "timeout_sec": 1800`, a 6x gap. `environment/Dockerfile:6` runs only `cargo fetch` with no `cargo build` and no `cargo test --no-run`, so verify time pays a full cold compile of statrs, its dependency tree and the test binary inside 300 s. calibration records 128 s cold for libcrux and 360 s for AltBeacon, and kvdex explicitly raised its verifier timeout from 300 to 900. Maps to Fixable trigger 11 for the field clash; the oracle-timeout risk stays a watch item until the Phase B timing run.
18. **Task-construction residue in an agent-readable path.** `environment/repo/.git/COMMIT_EDITMSG` reads "remove eval tests" while HEAD is `a8fe65c ci: update lockfile to use statrs@0.18.0`. The message does not match HEAD, so it is left over from the author's own commit stripping the evaluation tests, and it tells a reading agent that eval tests were removed from this checkout. `.git` is an agent path. Maps to Fixable trigger 10, arguably 6.
19. **The Dockerfile ends its `patch(1)` install chain in `|| true`.** `environment/Dockerfile:9`, so an image where every install path fails still builds green without `patch(1)`, silently removing the `test.sh:74-75` `patch -p1 --forward` fallback. `git` is installed unconditionally at `:2` and `/app` really is a git repo, so the primary apply path survives. Per Section 10.7 this is reportable rather than automatically fixable. No trigger yet.
20. **No `Cargo.lock` is committed, so the build is not reproducible.** Only `Cargo.lock.MSRV` exists, `.gitignore` contains `*.lock`, and `Dockerfile:6` runs `cargo fetch` in a retry loop. The dependency graph re-resolves to semver-latest on whatever day the image is built, so the difficulty run and the oracle run can get different toolchains, and a future release with a higher MSRV can break a `rust:1.89` build that passes today. A reproducibility gap, not a network problem. No trigger yet.
21. **The NOP zero will be structurally uninformative.** All eleven graded ids live in one integration target whose `use` lines import five modules that `git ls-tree -r HEAD -- src/stats_tests` shows absent at base (only `fisher.rs` and `mod.rs`). The target fails to compile, zero tests execute, and every id lands in `missing_required` whatever its merit. Rust compiles the integration target as one unit, so **there is no per-file subset to split** and the symbol audit is what genuineness rests on, exactly as on AltBeacon. That has to be said plainly in Comments for Reviewer rather than reported as an executed run. No trigger yet; it constrains how Phase B is reported.
22. **Assertion tolerances are far looser than the precision the instruction advertises.** `tests.patch:155` asserts `almost_eq(statistic, 3.066831635284081, 1e-1)`, `:23` `(statistic, 2.0, 1e-1)` and `:69` `(statistic, 9.3, 1e-1)`, while the p-values beside them are checked at 1e-12 and 1e-9. A wrong-but-close statistic survives every statistic assertion and is caught only by the p-value. This picks the hostile-delete target. No trigger yet.
23. **The generated runner gets no `set -e` and no `-o pipefail`.** `test.sh:132` is `RUNNER=(bash /tmp/run_tests.sh)` and the generator at `:89-127` prints only the raw command lines. Harmless as configured, because `execution.commands` holds one non-piped command so `TEST_EXIT_CODE` is cargo's own status and a gate would read the right value today. It becomes wrong the moment a second command or a pipe enters `execution.commands`. No trigger yet.
24. **The instruction's paragraph shape is well outside the accepted band.** 5559 bytes over 3 paragraphs on physical lines 1, 3 and 5, with no headings and no lists. Paragraph lengths 1672 / 2312 / 1563. The 2312-char Requirements paragraph carries five full Rust signatures and six enums on one line. Accepted bundles measure 717, 447 and 791; AltBeacon bounced twice on clarity at 2724. No trigger on its own; it feeds the instruction-quality assessment.
25. **Three em dashes in the instruction prose**, plus one U+2264, all on line 1. The prose otherwise reads hand-written, with a motivation paragraph and a real forum link, so the LLM-tell signal is low to moderate. No trigger yet.
26. **`[agent] timeout_sec` is 1800** against `expert_time_estimate_min = 180.0` and a declared `pass_at_k_opus_4_8` of `0/3`. Well inside the 7200 ceiling but low relative to the declared expert estimate, and an agent timeout surfaces as a difficulty-check failure rather than a clear message. No trigger yet.
27. **Measured clean, recorded so Step 3 does not re-derive it.** `instruction.md` and `environment/problem_statement.md` are byte-identical at sha256 `edb4e5e1a6458d99b0eb8748e5faacf238e27caf140dd6504d8d8de08fb729f` with no second top-level copy, and neither leaks the PR URL. Golden's six paths match PR 315's complete six-file list exactly, corroborated against `changed_files: 6` from a second endpoint, and golden carries no test file. `git apply --check` on `tests.patch` at HEAD exits 0. HEAD equals `base_commit_sha`. Object reachability is 5765 = 5765 with 0 loose and 0 garbage, no reflog, no remotes, no `filter.*` config, `.git` 2.6M. The stray-artifact sweep is empty and there are no symlinks. `tests/` holds exactly `config.json`, `test.sh` and `tests.patch`. `fail_to_pass` is 11, matching the 11 `#[test]` functions in the patch with none ungraded. No silent skip, no source-shape grading, no agent-controlled coverage, no existence-only check, and no overreach: every symbol the tests assert on is named in `instruction.md`. The base image is a concrete `FROM rust:1.89` with no upgrade step, and tmux and asciinema are verified fail-closed at `Dockerfile:3`.

## Rounds

### Round 0 - first pass, 2026-08-05

Steps 1 through 9 complete. Verdict Fixable. Fixes applied per the table above, zip built into
`upload/`, and the whole Phase B battery run against a fresh extract of that exact zip rather
than against `work/`. `answers/submission_answer.txt` written and humanized.

Not yet uploaded, so the Step 7 Send gate stands at 3 of 8: the battery passed against the
current zip, the zip is newer than every file in `work/`, and the upload-ledger row exists.
The other five conditions need platform results that do not exist yet. **Send to reviewer is
No** on this round and the answers file says so with the reason.

### Round 1 - agentic judge block, 2026-08-06

**Where it came from.** The review gate. It is a two-stage check and the agentic judge is the
first stage, so the difficulty screen never ran. Per `docs/faq.md` and
`.claude/rules/02-workflow-steps-6-to-10.md`, a stage that never ran is **not** a second failure
and gets no strike-table row. The judge block is the only signature this round scored.

**Freshness check, all four axes PASS.** The report was written against zip `ebcad9ef`, the round-0
upload.

| Axis | Result |
|---|---|
| Test ids | Every id it names exists in the current `tests/config.json` |
| Line numbers | `instruction.md` is 80 lines and every cited line (7, 13, 25, 36, 41, 49, 78, 80) matches what the report says sits there. `tests.patch` is 437 lines and cites up to 436 |
| Commands | `config.json:149` is `"allow_extra_failures": false`, which round 0 introduced |
| Instruction text | Every phrase it quotes is present verbatim |

**Results artifact.** Not requested this round and not needed: a judge block returns its reasons
in the report itself rather than in a downloadable verifier artifact, and the full per-axis
report was supplied.

#### Verbatim feedback

```
================================================================================
                  AGENTIC JUDGE REVIEW: task
================================================================================

Status:    DISCUSS
Reason:    coverage_gap

Per-axis review (rating out of 5, with judge justifications):

  clarity  -  4.0/5
      claude (4/5): The spec is thorough: each public function signature, error
        variant, precedence order [instruction.md:25], NaN policy semantics
        [instruction.md:13], numerical tolerance [instruction.md:78], and re-
        export paths [instruction.md:80] are named. A minor typo (`Propogate`
        [instruction.md:7]) doubles as a required spelling, and a few small
        interactions (e.g., ordering of `SampleTooSmall` vs
        `SampleContainsSameConstants` after Emit filtering [instruction.md:36])
        are only implicitly resolved, but intent is nearly always unambiguous.
      gpt (4/5): The prompt clearly enumerates the five required public
        functions, signatures, error variants, NaN handling, alternative
        handling, and module exports [instruction.md:15-80]. One material
        ambiguity remains around numerical behavior because it requires matching
        SciPy "tight enough that a p-value matches to roughly nine decimal
        places" without spelling out tolerances/formulas for all tests,
        especially exact Mann-Whitney and skewness [instruction.md:78].

  oracle_no_gaming  -  5.0/5
  oracle_robustness  -  5.0/5
  packaging  -  5.0/5
  prescriptiveness  -  5.0/5
  realism  -  5.0/5

  oracle_spec_faithfulness  -  4.0/5
      claude (5/5): [full pass, all five modules and signatures match]
      gpt (3/5): The solution implements all five modules and the public
        `NaNPolicy`, but several named requirements are miscoded: the
        instruction requires Mann-Whitney `Automatic` to use exact only when
        both samples have at most eight values [instruction.md:49], while the
        patch uses asymptotic only when both are greater than eight, so mixed
        sizes like 9 and 5 incorrectly use exact
        [solution/golden.patch:756-762]. The scipy-agreement requirement is
        explicit [instruction.md:78], but `skewtest` special-cases zero skew by
        changing `y` from 0 to 1 [solution/golden.patch:1147-1158], producing a
        nonzero statistic for symmetric data, and chi-square validates expected
        totals by truncating the `f_exp` sum to `usize`
        [solution/golden.patch:81-90], accepting mismatched non-integer totals.

  self_containedness  -  4.0/5
      claude (5/5): Every referenced artifact is present.
      gpt (3/5): All referenced in-repo artifacts needed to start are present.
        However, the decisive correctness standard is external SciPy behavior to
        roughly nine decimal places, and the prompt does not fully specify the
        formulas or numerical conventions needed to reproduce every counterpart
        without outside knowledge [instruction.md:78].

  test_coverage  -  3.0/5          <-- THE BLOCKING AXIS
      claude (5/5): Every imperative in [instruction.md:1-80] has a direct Rust
        assertion in [tests/tests.patch:20-436] ... no vacuous or fallback
        assertions anywhere.
      gpt (3/5): The suite exercises all five required public functions with
        scipy-derived numeric examples and many named error/NaN cases ...
        However, several explicit requirements are only weakly or not asserted:
        the prompt says `Alternative::{Less,Greater}` selects the requested tail
        for tests offering one [instruction.md:13] and for Mann-Whitney
        specifically [instruction.md:41-49], but all Mann-Whitney calls are
        two-sided [tests/tests.patch:100-105] [tests/tests.patch:289-301], and
        the t/skew one-sided test checks only probability identities that would
        still pass if Less and Greater were swapped [tests/tests.patch:372-394].
        The suite also does not test chi-square multi-error precedence promised
        by the prompt [instruction.md:25] and only partially tests other
        precedence/Emit-shrink edge cases, so a plausible implementation can
        violate named functional edges while passing.

  test_faithfulness  -  4.0/5
      claude (4/5): Minor over-strictness: the prompt says the p-value must
        match scipy 'to roughly nine decimal places' ([instruction.md:78]), but
        a few assertions use 1e-12 tolerance on statistics or on p-values
        ([tests/tests.patch:23, 32, 156, 231-260]); most such 1e-12 checks
        compare an agent output to another agent output (Emit-vs-clean,
        p_less+p_greater=1) where tightness is mathematically justified, but
        [tests/tests.patch:23, 32] use 1e-12 on the chi-square statistic against
        a scipy constant, slightly stricter than the prompt's nine-decimal
        wording.
      gpt (4/5): The main over-strictness is numerical tolerance ... at least
        one p-value is asserted at `1e-12` [tests/tests.patch:153-156] and some
        internal equality checks use `1e-12` [tests/tests.patch:241-260].

Rationale (from driving judge):
  [as quoted under test_coverage gpt above]
================================================================================
```

#### The findings as a numbered work list

| # | Finding | Axis | File | Verdict |
|---|---|---|---|---|
| 1 | Mann-Whitney `Less` and `Greater` never exercised; every call is two-sided | test_coverage | `tests/tests.patch` | ACT |
| 2 | The one-sided t and skew test is swap-invariant. `p_less + p_greater == 1` and `p_two == 2*min` both survive swapping `Less` and `Greater` | test_coverage | `tests/tests.patch` | ACT |
| 3 | Chi-square multi-error precedence never pinned | test_coverage | `tests/tests.patch` | ACT |
| 4 | Emit-shrink and other precedence edges only partly covered | test_coverage | `tests/tests.patch` | ACT |
| 5 | The `Automatic` dispatch sentence misstates the oracle | oracle_spec_faithfulness | `instruction.md` | ACT, my error |
| 6 | `skewtest` zero-skew special case, and chi-square `f_exp` sum truncation | oracle_spec_faithfulness | `instruction.md` | ACT instruction-side only. Both are upstream PR behaviour and the oracle is untouchable |
| 7 | `SampleTooSmall` vs `SampleContainsSameConstants` ordering after Emit only implicit | clarity | `instruction.md` | ACT |
| 8 | "roughly nine decimal places" is not a checkable contract, and the formulas are not fully specified | clarity, self_containedness | `instruction.md` | ACT |
| 9 | `1e-12` on the chi-square statistic against a scipy constant is stricter than the stated wording | test_faithfulness | both | ACT, reconcile the two |

#### Measured before any edit

Both decisive oracle claims checked in the container against the applied golden patch rather
than read off the source.

- **Finding 5 CONFIRMED.** `mannwhitneyu` on 9 values against 5, no ties, `Automatic`, returns
  the same p-value as `Exact` (`0.36363636363636365`) and a different one from
  `AsymptoticInclContinuityCorrection` (`0.35064788973554206`). So exact is used unless BOTH
  samples exceed eight. My round-0 sentence said exact only when both are at most eight, which
  predicts asymptotic for 9 against 5. The instruction was wrong, not the oracle.
- **A related claim REFUTED before acting on it.** The returned statistic does NOT vary with the
  alternative. `Greater`, `Less` and `TwoSided` on the same inputs all return `17`, because the
  function returns `u1` and uses the per-alternative `u` only to compute the p-value. The
  round-0 sentence "It returns the U statistic for `x`" is accurate and stays.
- **Direction data for finding 2.** A sample with mean 12 against a population mean of 5 gives
  `p_greater = 0.00029220530765139` and `p_less = 0.99970779469234861`. Those separate a correct
  implementation from one with `Less` and `Greater` swapped, which the current identity
  assertions cannot do.

#### What round 1 changed, and the evidence

| Judge finding | Fix | Mutation that proves it bites |
|---|---|---|
| MWU `Less`/`Greater` never exercised | Folded one-sided Mann-Whitney coverage into the renamed direction test | swap `(u1,1)`/`(u2,1)` in `mannwhitneyu` -> reward 0, `one_sided_alternatives_pick_the_requested_tail` |
| One-sided t/skew test swap-invariant | Renamed to `one_sided_alternatives_pick_the_requested_tail`; every block now pins which tail is small, and a second dataset moves the small tail to the other side | swap `Alternative::Less`/`Greater` in `ttest_onesample` -> reward 0, same test |
| chi-square multi-error precedence untested | Four inputs that each break more than one rule at once, folded into `chisquare_invalid_inputs` | reorder validation so ddof is checked before f_exp -> reward 0, `chisquare_invalid_inputs` |
| Emit-shrink and other precedence edges partial | Emptied group vs constant group separated, plus group-count outranking the NaN rules, folded into the Emit test | make `Emit` stop filtering in `f_oneway` -> reward 0, `nan_policy_emit_drops_nans_before_computing` |
| `Automatic` dispatch sentence misstated | Corrected: exact unless BOTH samples exceed eight. Nine against five now graded | force `Automatic` down the asymptotic branch -> reward 0, `mannwhitneyu_asymptotic_variants_differ_by_the_continuity_correction` |
| skewtest zero-skew and chisquare total truncation unstated | Both named in `instruction.md` as deliberate departures, and both now graded | covered by the folded assertions in `skewtest_scipy_example` and `chisquare_fexp_invalid` |
| `1e-12` on scipy constants stricter than the stated wording | Three assertions moved to `1e-9`; the instruction now states an absolute 1e-9 contract on statistic and p-value | n/a, this is a faithfulness fix |

**`fail_to_pass` stayed at 19.** Every addition folded into a test that already existed, which
keeps the count clear of the hard 10 to 20 range. Assertions went from 26 as shipped to **90**.

#### Round 1 battery, against a fresh extract of zip 2

| Run | Result |
|---|---|
| NOP | reward **0**, `raw_exit_code` **101**, `infrastructure_error: None`, 128 of 128 missing |
| NOP split A (executed) | 109 of 109 `pass_to_pass` guards compile and pass at base |
| NOP split B (symbol audit, not a run) | all five modules and `NaNPolicy` absent at base; `src/stats_tests` holds only `fisher.rs` and `mod.rs` |
| Oracle | **3/3 at reward 1.0**, 128/128 each run, `raw_exit 0`, 22s cold then 1s and 2s |
| Hostile x7 | every probe drops the reward to 0 and names its test. Four of the seven are the round-1 coverage |

#### Local rehearsal before the zip

Q9 navigation detector: 0 candidates. Q10 leaked-literal detector: 0 of 0 long literals, and 0
of 9 high-precision constants. Requirement map: 35 of 35 contract elements have an enforcing
assertion, none unasserted. Six auto-REMOVE patterns: none present, and the one `|| true` hit in
`test.sh` is on a config read at line 147, not the suite line at 154, whose status is captured
at 155 and gated at 558.

#### A self-inflicted error, recorded

The `Automatic` dispatch sentence was **my** round-0 wording, not a defect in the arriving task.
I wrote that the exact route is taken when both samples hold at most eight values. The oracle
takes it unless both exceed eight, which is the opposite for mixed sizes. Measured rather than
read: nine values against five with no ties returns `0.36363636363636365` under both `Automatic`
and `Exact`, and `0.35064788973554206` under the corrected asymptotic branch. A related claim in
the same report was **refuted** before acting on it: the returned statistic does not vary with
the alternative, since all three alternatives return `17` on the same inputs.

#### Difficulty

The review gate never ran its difficulty screen, because the agentic judge blocks first and the
second stage only starts if the first passed. That is expected and is not a second finding
(`docs/faq.md`, review-gate FAQ). Nothing was done for it and nothing should be. On direction:
every round-1 change adds or tightens a constraint and none relaxes one, so the graded surface
only grew. The counter-pressure is that a more precise instruction can make a task marginally
easier to solve, and that is unmeasured, so it is flagged in Comments for Reviewer rather than
claimed either way.

### Round 2 - peer reviewer, 2026-08-07

**Where it came from.** A peer reviewer, not the agentic judge. All platform evaluation checks
PASSED this round, so this is the first round whose feedback came from a person rather than a
gate. Freshness: the reviewer quotes `instruction.md`'s 1e-9 parity wording and the exact
thresholds `Greater below 0.06` and `Less above 0.9` from the round-1
`one_sided_alternatives_pick_the_requested_tail`, both present verbatim in zip `f7a1c14c`. Fresh.

#### Verbatim feedback

```
Exact Mann-Whitney tails are flipped when x is the smaller sample. instruction.md calls for
scipy parity within 1e-9, but golden.patch gives Less as 0.9 instead of 0.1 for x [1, 2] and
y [3, 4, 5]. tests.patch doesn't catch it. The swapped-sample block repeats the same reversal,
still expecting Greater below 0.06 and Less above 0.9. Fix the exact probability calculation
and pin exact scipy values for both sample orders across all three alternatives. And coverage
still isn't done. tests.patch has no Automatic case with pooled ties, while the asymptotic
checks only test direction or compare the code with itself.
```

#### The claim, measured before acting on it

**CONFIRMED, and wider than reported.** Measured in the image against the shipped oracle:

| Input | statrs | correct | |
|---|---|---|---|
| `x=[1,2] y=[3,4,5]` Less | 0.9 | **0.1** | flipped |
| same, Greater | 0.0 | **1.0** | flipped |
| same, TwoSided | 1.0 | **0.2** | wrong |
| `x=[3,4,5] y=[1,2]` all three | 1.0 / 0.1 / 0.2 | same | correct |
| `x=[1,2,3] y=[4,5,6]` Less | 0.95 | **0.05** | flipped |

So it is not only "x is the smaller sample": equal sizes break too. The correct values come from
an **independent enumeration of the exact null distribution written from the definition**, not
from statrs and not from the reviewer.

**Root cause.** `calc_mwu_exact_pvalue` ends with `if k == n1 { 1.0 - p } else { p }` where
`k = n1.min(n2)`. The enumeration already yields `P(U >= u)`, and the null distribution of U is
symmetric in n1 and n2, so no inversion is ever correct. The branch fires whenever `n1 <= n2`.
Every PR-authored test uses `n1 > n2`, which is why it never showed.

**My round-1 test asserted the bug as correct.** The swapped block carried the comment "Exchanging
the two samples has to move the small tail to the other side" and then asserted
`p_greater_swapped < 0.06`, which is the same side. The comment and the assertion disagreed and
the oracle's bug made the assertion pass.

#### The oracle edit, and why it is allowed

`docs/guidelines.md:284-291` permits editing `solve.sh` / `golden.patch` in two cases, the first
being **"to correct an oracle that does not implement the instruction"**. The instruction states
scipy parity to an absolute 1e-9 and the oracle does not deliver it, so case 1 applies. The same
section says to match the canonical upstream fix and to **"Only diverge if the upstream fix is
genuinely unavailable or unsuitable, and document why"**. It is genuinely unavailable:
`statrs-dev/statrs` master still carries the identical `if k == n1` branch today, fetched and
checked this round, so there is no upstream fix to adopt.

The edit is two hunks and nothing else:
1. `calc_mwu_exact_pvalue` returns `numerator / total` unconditionally.
2. The PR's own `test_calc_mwu_exact_pvalue` expected `0.6` for `(4.0, 2, 3)` against `0.4` for
   `(4.0, 3, 2)`. Both are `P(U >= 4)` over the same distribution, so they have to be equal.
   Updated to `0.4`, in lockstep as `guidelines.md:291` requires.

Scope is unchanged: still the same 6 files, still matching the PR's file list, no feature added
or removed. `cargo test --lib` on the fixed tree is **660 passed, 0 failed**, and the three
public-API tests the PR shipped (`test_scipy_example`, `test_wikipedia_example`,
`test_automatic_asymptotic`) pass untouched.

#### Coverage added

| Reviewer sentence | Fix |
|---|---|
| "pin exact scipy values for both sample orders across all three alternatives" | Both orders of the 5v4 pair and of `[1,2]` / `[3,4,5]`, plus the equal-size 3v3 case, all three alternatives, pinned at 1e-9 against the independent reference |
| "The swapped-sample block repeats the same reversal" | That block is gone. It now pins values instead of thresholds |
| "no Automatic case with pooled ties" | `[1,2,3]` against `[3,4,5]`, both samples under the size threshold with one shared value. Automatic equals the corrected asymptotic branch AND Exact returns `ExactMethodWithTiesInData` on the same input |
| "asymptotic checks only test direction or compare the code with itself" | Six asymptotic reference values pinned, both continuity settings across all three alternatives, computed outside the crate from the normal approximation with tie correction |

`fail_to_pass` stayed at **19**. Assertions went from 90 to **111**.

#### Round 2 battery, against a fresh extract of zip 3 `39f5cc26`

| Run | Result |
|---|---|
| git usable in the built image | `git rev-parse HEAD` resolves, `.git/refs/heads/main` is a real file |
| NOP | reward **0**, `raw_exit_code` **101**, `infrastructure_error: None` |
| NOP split A | 109 of 109 guards compile and pass at base |
| Oracle | **3/3 at reward 1.0**, 128/128 each run, 21s cold then 2s and 1s |
| Hostile R2-A | reinstate the `k == n1` inversion, reward **0**, caught by TWO tests |
| Hostile R2-B | Automatic ignores pooled ties, reward **0** |
| Hostile R2-C | drop the tie correction from the variance, reward **0** |
| Hostile R2-D | swap Less and Greater, reward **0**, caught by two tests |
| Hostile R0-E | ddof no longer reduces dof, reward **0** |
| Hostile R0-F | `Normal::sf` stubbed, reward **0** via the regression guard |

**Regression proof.** With the round-2 tests in place and the bug reinstated, 2 of 19 fail. The
round-1 suite passed that same tree, which is exactly the reviewer's point.

#### A new learning note applied this round

`learning/empty-git-refs.md` (platform-confirmed, `blocks_submission: true`) landed after round 1
and applies here. `git gc` had left `.git/refs/heads` empty, so the whole of `.git/refs` was
nothing but empty directories. `unzip` preserves those and the local check stayed green, but any
extractor that drops empty directories removes git from the agent workspace, which reproduces as
`fatal: not a git repository` and was counted 134 times on a sibling task. The remedy from that
note is applied: the loose ref is written back after the gc, so `.git/refs/heads/main` is a real
file and no extractor can drop it. Verified inside the built image.

#### Three more checks run this round, two of which changed the bundle

**1. The shipped verifier died under `sh`, and the guard is load-bearing.** `solve-sh-under-sh.md`
is `reported` rather than reproduced here, so it was worth testing rather than assuming.
Measured in the image, where `/bin/sh` is dash:

| | `sh /tests/test.sh` |
|---|---|
| without the guard | exit **2**, reward **0**, dies at `test.sh:60` on `source: not found` |
| with the guard | exit **0**, reward **1** |

It fails on `source` well before reaching the `RUNNER=(...)` array at 151, so the array was not
even the first hazard. Both entrypoints now carry
`[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"` immediately after the shebang. Note that
`sh -n` still reports a syntax error on `test.sh`, because `-n` is parse-only and never executes
the guard. The execution result above is the one that matters.

**2. The Go note's VCS hazard was checked for cargo and measured ABSENT.** `LEDGER` L26 attaches
a correction to `empty-git-refs.md` saying a half-present `.git` is fatal on Go. A four-state
matrix inside this task's own image, with `--network none`, returned cargo **exit 0 with 625
passing test lines and zero VCS errors in all four states**, including `.git` absent entirely.
The structural reason is that statrs has no `build.rs` and its `Cargo.toml` names no `vergen`,
`built`, `git2`, `git-version` or `shadow-rs`, so nothing in the build graph reads VCS state.
**So no cargo analogue of `-buildvcs=false` was invented**, and the loose-ref fix here is about
the agent's experience rather than about oracle exposure. Recorded so the next round does not
re-derive it.

**3. The golden-omits-a-PR-file check was run and is clean.** `go-task-verifier-gotchas.md`
section 2 describes a golden patch that omits a file the PR carries, turning a green pre-existing
test red. Both halves run here. The PR file list fetched through the API and paged returns 6
files on page 1, and the set difference against `golden.patch` is empty in **both** directions.
And the base-versus-oracle failing-set diff in the image gives **628 ok / 0 failed at base** and
**660 ok / 0 failed after the oracle**, with an empty green-at-base-red-after-oracle set. Nothing
pre-existing is broken by the patch.

### Round 3 - difficulty screen, 2026-08-07

**Where it came from.** The review gate again, but the other stage. The agentic judge PASSED
this time and the **difficulty screen** blocked: `Difficulty: FAIL EASY - Requires at least
MEDIUM`. claude-opus-4-8 100% (4/4), codex-gpt-5-5 75% (3/4), nop 0%, oracle 100% (3/3). The
only test any agent failed was `skewtest_scipy_example`, 0 passed of 1 run.

#### Was it caused by the round-2 reviewer fix? Yes, and there is a measured before and after

| zip | difficulty screen |
|---|---|
| 1, round 0 | never ran, the judge blocked first |
| **2, round 1** | **passed**, every evaluation check green and it reached a peer reviewer |
| 4, round 2 | **FAIL EASY** |

The screen passed on the pre-fix bundle and fails on the post-fix one, so the delta is the
round-2 change set. The mechanism is specific. Round 1's Mann-Whitney assertions were
**thresholds tuned to the buggy oracle** (`p_greater_swapped < 0.06`, where the correct value is
`0.968`). An agent that implemented Mann-Whitney correctly therefore **failed**. That was doing
the discriminating, by requiring agents to reproduce the PR author's bug. Fixing the bug, which
was the right thing to do, let correct implementations pass and the discriminator disappeared.

A contributing cause, worth recording because it is the more general lesson: rounds 0 to 2
progressively turned `instruction.md` into a near-complete specification. Error precedence for
three functions, the `Automatic` dispatch threshold, the 1e-9 tolerance contract, both scipy
departures, the `Emit` ordering. **Every one of those was added to answer a judge finding**, and
each was individually right. Together they left very little to work out. Answering clarity and
self-containedness findings costs difficulty, and nothing in the loop measures that until the
screen runs.

#### The lever, measured before it shipped

`learning/difficulty-levers-must-discriminate.md` requires that a lever be shown to separate
implementations rather than merely sound subtle. Four candidate wrong implementations of the
Anderson-Darling statistic, scored against the correct one on the same sample:

| implementation | A squared | difference |
|---|---|---|
| correct | 0.162246714297 | - |
| no index reversal in the second term | 11.864083635259 | 1.2e+01 |
| both terms reversed | 22.761831919637 | 2.3e+01 |
| weight `2i` instead of `2i-1` | 2.117416657378 | 2.0e+00 |
| returns the adjusted statistic | 0.174922238852 | 1.3e-02 |

The p-value moves from `0.925` to `0.000` under the no-reversal error. All four separate, so the
lever is real. `PR 336`, the other candidate, was **rejected on evidence**: it is a pure
performance refactor with no observable behaviour change, so every implementation agrees about it
and its difficulty value is zero.

#### The expansion

Adapted from statrs **PR 346** (Anderson-Darling), a later PR in the same module and the same
feature family. **Adapted, not lifted**: upstream takes no NaN policy and has a single error
variant, while this one joins the PR 315 family conventions with a `NaNPolicy` parameter and a
two-variant error enum, in the same shape as the five tests PR 315 already adds.

Scope check per the difficulty-scope skill:

| | |
|---|---|
| PR 315 intent | feature. Grow `stats_tests` into a hypothesis-testing toolkit: five tests, each a pub fn plus its own error enum, registered in `mod.rs`, sharing a new `NaNPolicy` |
| Task now | the same five plus a sixth in the identical shape, sharing the same `NaNPolicy` and error conventions |
| Anchor | fully contained. The addition builds on PR 315's own `NaNPolicy` rather than sitting beside it |
| Classification | **Valid expansion**, original PR plus additions. Not a reduction, not a replacement |

What is stated in `instruction.md` and what is not, deliberately: the signature, the error
variants, the NaN ordering, the small-sample adjustment and the four-branch p-value constants are
all stated, because none of them is derivable. **The A squared formula itself is NOT stated.** It
is the standard named statistic, so a competent implementation derives it, and the forward
against reversed index pairing is where the difficulty lives.

#### The id budget

`fail_to_pass` was 19 against a cap of 20. Rather than concluding there was no room, the existing
list was audited for padding as the note prescribes. Three error-taxonomy pairs were each
asserting one contract across two ids, so they were merged with **every assertion preserved**:
`chisquare_fexp_invalid` into `chisquare_invalid_inputs`,
`f_oneway_reports_samples_that_are_too_small` into `f_oneway_error_cases`, and
`mannwhitneyu_rejects_unorderable_data_and_reports_an_empty_sample_first` into
`mannwhitneyu_error_cases`. That freed three slots, two were spent on the new module, and the
count came out at **18** with headroom rather than back on the boundary.

#### A defect the probes caught

The first hostile run showed the Anderson-Darling probes zeroing every id rather than one. Cause:
`execution.commands` skips the five modules PR 315 adds so that an agent's own inline tests cannot
sink its trial, and the new module was **not** in that skip list. So the agent's own unit tests in
`anderson_darling.rs` would have been graded, which is exactly the trap closed in round 0 for the
other five. `--skip stats_tests::anderson_darling` added, and the probes then isolate cleanly.

#### Round 3 battery, against a fresh extract of zip 6 `da7254bf`

| Run | Result |
|---|---|
| NOP | reward **0**, `raw_exit_code` **101**, `infrastructure_error: None` |
| NOP split A | 109 of 109 guards compile and pass at base |
| Oracle | **3/3 at reward 1.0**, 127/127 each run, 28s cold then 1s and 1s against a 300s budget |
| Hostile x9 | every probe drops the reward to 0 and names its test. Four are the new module |

**`task.toml` difficulty fields untouched.** `difficulty`, `model_difficulty` and the `pass_at_k_*`
values are exactly as they shipped. Only `difficulty_explanation` prose was updated, to stay
accurate to what the task now requires. Hand-tuning the difficulty metadata to answer a difficulty
result is forbidden and is escalated instead.

### Round 4 - difficulty screen again, 2026-08-07

**The report is FRESH, and I checked rather than assumed.** The headline numbers are byte
identical to round 3 (opus 100% 4/4, codex 75% 3/4, same single `skewtest_scipy_example`
failure), which is exactly the shape of a re-pasted report. The **results artifact settles it**:
its verifier report lists `anderson_darling_matches_the_reference_statistic` and
`anderson_darling_error_cases` among 127 required tests, and none of the three ids round 3 merged
away. So it ran the round-3 bundle and the identical numbers are real.

**That means the round-3 expansion converted exactly zero agents.** Anderson-Darling appears 14
to 33 times per trajectory and every one of the 8 trials got it right. `FAIL EASY` is now at
**strike 2**.

#### What the artifact actually shows

Aggregate 7 of 8 = 87.5%. The bar is at most 4 of 8 for MEDIUM. The single failure, codex trial
4, is worth reading in full:

```
thread 'skewtest_scipy_example' panicked at tests/stats_tests_pr315.rs:287:5:
assertion failed: z_sym != 0.0
```

Its `skewtest` is the textbook D'Agostino transform with no zero-skew guard, so on symmetric data
`skew = 0`, `y = 0`, and the statistic collapses to `delta * ln(1) = 0`. **It wrote the
mathematically correct, scipy-faithful implementation and failed because the oracle has a quirk.**

So the only lever that has ever converted an agent on this task is of one shape: **a place where
the oracle diverges from what a competent implementer naturally writes**. Not "more functions".
Adding a sixth test was more work of a kind these models already do perfectly.

#### The refined theory, and why it is not a third variation of the same one

Strike 2 forbids shipping another variation of a theory that has failed twice. The failed theory
is *difficulty scales with how much there is to implement*. It does not: eight of eight trials
implemented six statistical tests correctly from a complete specification.

The replacement theory comes from the one measured data point: difficulty here scales with **how
many documented behaviours contradict the natural implementation**. One such behaviour converts
roughly 1 agent in 8. So the round-4 work was a systematic hunt for more of them rather than more
surface.

#### The divergence sweep

Every candidate probed against the oracle in its own image:

| probe | oracle | what a natural implementation does |
|---|---|---|
| `[[1,2],[3,3]]`, one group constant, other varies | `SampleContainsSameConstants` | computes a valid F, scipy does |
| `[[1,2],[3,4],[5,5]]`, one constant of three | `SampleContainsSameConstants` | computes |
| `[[1],[2,3]]`, size-1 group beside a bigger one | accepted | many reject, requiring every group to hold two |
| `Exact` forced at 9 against 9 | works, no size limit | many refuse, reading the threshold as global |
| all values tied | `p = 1.0` through an infinite z | NaN |
| `ttest_onesample` on zero variance | **panics** in `beta.rs:125` | returns NaN |

Three were graded, folded into existing tests so `fail_to_pass` stayed at **18**. Assertions went
from 111 to **132**. The all-tied and zero-variance rows were left alone and are recorded under
what was deliberately not done, below.

#### Every lever measured before shipping, per difficulty-levers-must-discriminate

Each new assertion was checked by writing the natural implementation it is supposed to fail and
watching it fail:

| natural implementation | result |
|---|---|
| f_oneway errors only when EVERY group is constant | reward **0** |
| f_oneway requires every group to hold at least two | reward **0** |
| mannwhitneyu `Exact` refuses samples over eight | reward **0** |
| skewtest without the zero-skew guard, which is literally codex trial 4 | reward **0** |

#### Instruction changes, in lockstep

Two clauses made explicit, because the new assertions grade them hard and an ambiguous reading
would be unfair rather than difficult. `SampleContainsSameConstants` now says one such group is
enough on its own even when every other group varies, and `Exact` now says it carries no size
limit of its own because the threshold belongs to `Automatic`. Both paragraphs were split to stay
under the 800 character shape target; longest is now 769.

#### Round 4 battery, against a fresh extract of zip 7 `fe241712`

| Run | Result |
|---|---|
| NOP | reward **0**, `raw_exit_code` **101**, `infrastructure_error: None` |
| Oracle | **3/3 at reward 1.0**, 127/127 each run |
| Hostile x9 | every probe drops the reward to 0 and names its test |

#### Deliberately not done, and the honest position

- **`ttest_onesample` panics on a zero-variance sample** (`function/beta.rs:125`). That is a real
  robustness defect inherited from the PR. Grading a panic is not a sensible assertion and fixing
  it would change PR behaviour beyond the `guidelines.md:286` case-1 authorisation, which covers
  an oracle that does not implement the instruction rather than one that crashes on an input the
  instruction never mentions. Reported, not fixed.
- **`task.toml` difficulty and pass-rate fields untouched**, as in every prior round.
- **If this round also measures easy, the option space is close to exhausted.** The state of the
  evidence would then be: one related later PR adapted and measured at zero (346), one rejected on
  evidence as behaviour-neutral (336), one substantial candidate never tried (329, the KS test at
  1095 lines), and a measured task-side cause, that a complete specification of standard algorithms
  is not difficult for frontier models however many algorithms it names. That is **not** yet the
  libcrux bar, which took ten measured levers, and `LEDGER` L19 is explicit that a red screen is
  never automatically Not Fixable. PR 329 is the next lever, not the verdict.

| 7 | 2026-08-07 | `fe241712563c27312036fbbab3c1b10339489ae94ccf3207926f8aa0b1cd44ed` | 2659959 bytes, 127 entries | not uploaded yet | Round 4. Three oracle-versus-natural divergences graded, each measured against the natural implementation it fails. f2p still 18, assertions 111 to 132. Battery green |

## Closed - ACCEPTED, 2026-08-11

The reviewer accepted the task. No Submission Quality Score was reported to this workspace.

| Field | Value |
|---|---|
| Outcome | **accepted** |
| Final round | 4 |
| Uploads | 5 (zips 1, 2, 4, 6, 7; zips 3 and 5 were superseded before upload) |
| Handling time, total submission | 195 minutes (fields 1 + 2 + 3) |
| Handling time, all revisions | 255 minutes, the last Cumulative cell of the ledger above |

**What the acceptance does and does not tell us.** It arrived after round 4, and this workspace
never saw a round-4 difficulty screen result. So it is **not** established that round 4's three
divergence levers moved the screen from EASY. The two possibilities are that they did, or that
the task was accepted with the screen still red. Both are consistent with what we can see, and
the record should not be read as proof of the first. What IS established is everything that was
measured directly: the round-3 expansion converted zero agents, and the only assertion that ever
failed an agent was the zero-skew one.

**The arc, for the next reader.** Round 0 found four stock defects and rewrote the instruction.
Round 1 was an agentic judge DISCUSS on coverage. Round 2 was a peer reviewer who found a real
inverted tail in the oracle, still present on statrs master today, which was corrected under
`docs/guidelines.md:286` case 1. Rounds 3 and 4 were the difficulty screen twice. The single most
useful artefact in the whole task was the round-4 results archive, because it carried the agent
trajectories and those named the lever shape that reasoning had not.
