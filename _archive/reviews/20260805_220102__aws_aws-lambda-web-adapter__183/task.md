# Peer review - 20260805_220102__aws_aws-lambda-web-adapter__183

Section 13, `.claude/rules/14-reviewer-workflow.md`. Started 2026-08-18.

- Seed zip: `2c330de7-4b1b-4c5c-a5f4-25516ab8e732_submission.zip`, sha256 `748c6818e5c5222071647eb071902758db733ee248bb22db74eb3714b9ef53d4`, 249 entries, single mtime 2026-08-05 (generator stamp; folder name 20260805_220102 agrees)
- Submitted zip: `68455bcb-e7b8-4b4a-b38b-f4273a2a4ac5_submission_2026-08-15T11_11_28.084Z.zip`, sha256 `b571e2c10b59d3bdd4641471b4434cdb4517263646beec721e5120a1d97f9ef1`, 361 entries, mtime spread 2026-08-05 to 2026-08-14, 0 symlinks, `tests/test.sh` and `solution/solve.sh` both stored `rwxrwxrwx`
- Page field for the re-upload reads `2c330de7-4b1b-4c5c-a5f4-25516ab8e732_v8.zip`, 8/15/2026 4:42:09 PM
- Source PR: aws/aws-lambda-web-adapter #183. Base commit `acf214e56091b3a421d38dd6994625a4070f464b`. Language rust, runner cargo, verifier `custom` parser over cargo test output
- Round 1 of THIS review (first submission handed to me); the bundle itself is the submitter's second revision, answering a reviewer note dated 8/14/26
- The page's Metadata block matches the SEED task.toml (verifier 300, model_difficulty medium, license blank), not the submission. The platform block describes the task as issued

## Submitter answers

Pasted verbatim into task_details.md: verdict Fixable/Fixable, four numbered issue details, Files Changed, PR additions, difficulty answer, Comments for Reviewer, all six eval panels, previous reviewer feedback. Still open: difficulty checks run/remaining (blank in paste), rebuttal panel contents, maximum-revisions dialog state, review duration. Asked for 2026-08-18.

## learning/ notes applied

| Note | What it predicts here | Command that settles it | Result |
|---|---|---|---|
| verifier-fail-open.md | previous round's finding 1: grader rewarded on nonzero exit | read tests/test.sh success path; reproduce the reviewer's fake-log probe in R6 | gate present at test.sh:554-556 (`nonzero_exit_forced_zero`); container check pending |
| solve-sh-idempotency.md | previous round's finding 2: second run exited 1 | run solve.sh three times in one container (R6) | pending |
| oracle-protocol-is-solve-then-verify.md (L69, L102) | the real protocol is solve then verify, 3 cycles; local-run.sh's `thrice` is the wrong shape | hand-run 3 cycles of solve.sh then test.sh in one container | pending |
| agent-writable-test-infrastructure.md | tests.patch protects test bodies; what do the graded tests call that the agent owns? | the graded tests are integration tests calling the crate as a library; run 4 shape is the compiled-language one | pending |
| unreachable-git-blobs.md | fsck silent is not enough on reworked bundles | R4 git gate, then cat-file anything it prints | fsck silent; `.git/gk/config` extra entry found instead |
| empty-git-refs.md (L26) | a gc'd bundle losing its loose ref depends on empty-dir preservation | unzip -l the submitted zip for refs/heads entries | CONFIRMED: seed ships refs/heads/main (41 bytes), the submission ships only the empty directory |
| stock-bundle-defect-baseline.md | eight scaffold defects, counted per row | R8 sweep table | pending |
| reviewer-findings-need-a-baseline.md (L61-L63, L73) | metadata findings need the download/original baseline | Section 8 baseline in 09-task-toml-reference.md, read off the seed | os/difficulty_explanation/repo_license arrive absent/blank; verifier timeout arrives inverted; all corrected in the submission |
| source-pr-cross-check.md | page the GitHub API | fetched pages until a short page: 35 files, 1 page | done |
| rust-cargo-verifier-gotchas.md | cargo parser blindness is should_panic; the exit-code gate is what closes it | the suite has no should_panic tests; gate present | holds |
| airgapped-means-no-egress-not-no-sockets.md | loopback servers inside the test process are legal in a no-network verifier | the TLS fixtures bind 127.0.0.1:0 and spawn openssl s_server | legal shape, confirmed by reading |
| mock-standing-in-for-the-deliverable.md | a mock of the graded thing is not coverage | graded TLS tests drive a real openssl s_server and a real native-tls acceptor, not a mock | holds by reading; container-confirmed in R6 |

## Submitter claims, verified

| # | Their claim | Where it should land | Measured | Verdict |
|---|---|---|---|---|
| 1 | instruction rewritten to a behavioural contract; no internal symbols remain | instruction.md, problem_statement.md | seed named AdapterOptions fields/types; submitted instruction names only the five env vars and behaviour; the two files are byte-identical | HOLDS |
| 2 | suite drives the adapter through env vars, real TLS handshakes, 17 f2p / 19 p2p, aef false, stub now 0/17 | tests/* | tests.patch is 3 new files, 0 deletions, 0 renames; env-driven; real openssl s_server + native-tls acceptor; config.json has 17 f2p and **21** p2p entries (20 behavioural + suite_completed sentinel), aef false | HOLDS except the p2p count: 21 in the file, 19 in the writeup |
| 3 | solve.sh idempotent forward-only; golden ships the pinned Cargo.lock and omitted PR files | solution/ | solve.sh reverse-checks then forward-applies, no -R. golden.patch carries src/lib.rs, Cargo.toml, README, 8 example files, tests/integ_tests.rs. **No Cargo.lock hunk**; offline resolution is carried by the Dockerfile cache + an offline resolve probe instead | HOLDS for solve.sh and the PR files; DOES NOT HOLD as written for the Cargo.lock half |
| 4 | Dockerfile prefetch is a version-ranged menu across both TLS families, fetch-only, target/ wiped, hard no-leak assertion | environment/Dockerfile | :29 menus hyper-rustls 0.23, tokio-rustls 0.23, native-tls 0.2 (minor ranges, not 0.23.2); :28-35 fetch-only, restores pristine manifests, wipes target, rebuilds from pristine manifest, ends with an unguarded no-fingerprint assertion | HOLDS |
| 5 | task.toml: license + os filled, difficulty_explanation added, timeouts nested, pass_at_k labelled; "difficulty and model_difficulty left as inherited (not hand-edited)" | task.toml | license Apache-2.0, os linux, difficulty_explanation present, verifier 1500 vs execution 1200 (cleared), agent 7200, build 1800. **BUT the diff shows model_difficulty medium->hard and pass_at_k_gpt_5_5 0/3->0/4**, both hand-edits, and Comments for Reviewer says the mismatch "still" exists and pass_at_k was "left" alone | DOES NOT HOLD for the two difficulty fields |
| 6 | "Oracle still scores 36/36" | container | pending; the live config grades 37 tests + sentinel = 38 ids | pending, count looks stale by the two switch-off nodes the difficulty_explanation itself says this revision added |

## Previous round findings (8/14/26 reviewer note) as this round's checklist

| # | Their finding | This zip | Verdict |
|---|---|---|---|
| 1 | grader records raw_exit_code but does not gate on it; fake all-ok log with exit 1 or 124 still rewarded 1 | grade.py (embedded test.sh:548-557) forces success False and reward 0 on any nonzero raw_exit_code; config.json propagates each cargo binary's PIPESTATUS through an explicit exit 1; sentinel covers truncation | FIXED by reading; container repro of their exact probe pending in R6 |
| 2 | solve.sh second run exits 1 leaving the solution in place | solve.sh reverse-checks first and no-ops exit 0 | FIXED by reading; 3-run container check pending |
| 3 | Dockerfile prefetched hyper-rustls = "0.23.2" exactly | menu across hyper-rustls 0.23 / tokio-rustls 0.23 / native-tls 0.2, ranges not exact pins; manifests restored, target/ wiped, no-leak assertion | FIXED by reading; residual judgement call: the warm cache still enumerates the rustls family, see R7/R8 |

## mtime forensics

Not the opening move (both zips in hand), recorded anyway: the seed is a single-stamp generator archive (249 entries, all 2026-08-05). The submission spreads 2026-08-05 to 2026-08-14, and the late stamps land on exactly the nine files their Files Changed lists. Consistent with the diff.

## Git hygiene (R4, gate run first and alone)

| Check | Command | Output | Meets (:91) | NR trigger (:95) |
|---|---|---|---|---|
| fsck | `git -C work/environment/repo fsck --unreachable --no-progress` | silent | yes | clear |
| HEAD vs base | rev-parse HEAD | acf214e56091b3a421d38dd6994625a4070f464b == task.toml | yes | clear |
| remotes | remote -v | none | yes | clear |
| worktrees | worktree list | the one | yes | clear |
| stash | stash list, refs/stash | none | yes | clear |
| logs | ls .git/logs | absent | yes | clear |
| size | du -sh .git | 17 MB | yes | clear |
| tree | status --porcelain | clean | yes | clear |
| whitelist | ls .git | **extra entry `gk/`** (GitKraken, 61-byte config holding a last-accessed timestamp, dated 2026-08-14, zipped in; seed has no such entry) | falls short of a strict read of Meets | NOT the NR trigger: no fix content, no dangling objects, no remotes/stash/reflog. Soft-signal class (:93), noted as a finding |
| loose ref | unzip -l, refs listing | **seed ships `.git/refs/heads/main` (41 bytes); the submission ships only the empty `refs/heads/` directory entry**; refs/remotes/origin/HEAD dropped (that half is an improvement) | the repo still resolves HEAD via packed-refs and fsck is silent | not a :95 trigger; it is the empty-git-refs fragility class (learning/empty-git-refs.md), and on cargo (no VCS stamping) the verifier does not depend on it |

## PR comparability, hunk level (R5)

Fetched https://api.github.com/repos/aws/aws-lambda-web-adapter/pulls/183/files paged: 35 files, one page (second page empty).

| File | PR | golden.patch | Reading |
|---|---|---|---|
| src/lib.rs | +66/-33 | every PR hunk present, PLUS the declared mutual-TLS extension (tls_client_cert_file/key fields, client_tls_config, identity_error fail-closed) and ONE semantic deviation: PR sets SSL_CERT_FILE whenever tls_cert_file is set, golden guards it behind enable_tls | extension declared in PR additions; the guard is more faithful to the instruction's "switch off and nothing moves" than the PR itself |
| Cargo.toml | +4/-1 | carries all four PR lines (hyper-rustls, lto, opt-level...) but as `hyper-rustls = "0.23"` (range, not the PR's "0.23.2"), plus rustls/rustls-native-certs/rustls-pemfile for the extension; does NOT remove hyper-tls dev-dep (PR does) because the graded test support module uses hyper_tls::native_tls; omits aws-sigv4 dev-dep (e2e-only) | clean |
| tests/integ_tests.rs vs tests/integ_tests/main.rs | renamed +42/-7 incl. from_env TLS assertions and three style fixes | golden keeps the file at its base path and adds the five-field literals; omits the rename, the from_env assertions, the style fixes | the graded suite replaced that coverage wholesale; omission is the normal accepted shape |
| tests/e2e* (12 files) | removed/restructured/added | omitted | CI/e2e harness, not graded; normal |
| .github/workflows/pipeline.yaml | +209/-179 | omitted | CI; normal (L59) |
| .gitallowed, examples app cert.pem/key.pem | added | omitted | a committed private key and its gitleaks allowlist entry; omitting is the right call |
| Cargo.lock | +299/-94 | **omitted**; the submitter's claim "ships the pinned Cargo.lock" does not hold as written; offline resolution is instead asserted by the Dockerfile resolve probe | writeup mismatch, small; mechanism measured in R6 |
| examples/fastapi-https remaining 8 files | added | all present, byte-matching the PR by hunk | clean |

Direction that matters is clean: no undeclared extra production material, so quality score 1 is off the table.

## R4 preflight (bin/preflight.sh work -v)

OK=3 FAIL=2 WARN=1 (the WARN is "ran against the working copy", expected for a review). Adjudication:

- `git.entries` FAIL: `.git/gk` — REAL, matches the gate above. Not a Major (no fix content; :95 triggers are leaking objects/remotes/worktrees/HEAD mismatch). Filed as a small note.
- `grader.fail-closed` FAIL: pattern check wanted `args.raw_exit_code == 0` in the success expression. The gate exists in a different shape: `nonzero_exit_forced_zero = args.raw_exit_code != 0` then `success = False; reward = 0.0` (test.sh:548-557). FALSE POSITIVE by reading; the previous reviewer's exact repro runs in R6 to settle it by measurement.
- `grader.runner-pipefail` FAIL: the runner is `bash /tmp/run_tests.sh` without `-o pipefail`, but `execution.commands[0]` IS `set -o pipefail`, which governs every later pipeline in the generated script (L67 mechanics), and PIPESTATUS is captured per cargo binary with an explicit exit 1 gate. FALSE POSITIVE by reading; R6 measures the NOP's raw exit.
- `grader.runner-errexit` FAIL: no `set -e` in the generated runner, by design: per-command PIPESTATUS capture plus an explicit `if either failed: exit 1` then `exit 0`. The runner's status is the graded one. FALSE POSITIVE by reading.
- `50-restore-shape`: PASS. 38 graded ids (17 f2p + 21 p2p), 97% resolved, "0 of 38 outside the patched files", tests.patch is 3 creates, verdict create-only sufficient. Cross-checked by hand: all 37 test functions live in the two created files; the 38th id is the sentinel emitted by config.json command 4. Consistent.
- Pillar 4 (no preflight coverage, read by hand): `[environment] network_mode = "public"`, `[agent] allowlist` = ["api.portkey.ai"], `[verifier] "no-network"`, all per docs/harbor-framework.md:59,66. TLS fixtures bind 127.0.0.1 only; `cargo test --offline`; CARGO_NET_OFFLINE=true in execution.env. Measured half comes from the R6 runs all being `--network none`.
- Secondary Requirement 2 (pinning): base image `rust:1.79` is a version tag, not a digest; apt line carries no `|| true`; no pip; no git+https; the menu prefetch uses minor-version ranges by design; the verifier replays offline against a lockfile-pinned base plus that cache. Compare accepted bundles for the image-tag practice before deciding whether this is even a note.
- Secondary Requirement 1 (timeout pair): verifier 1500 vs execution 1200. NOT inverted. The generator default (300 vs 1800) was corrected. Clear.
- Stock defect 7 (python3 behind || true): the apt line is non-optional and line 6 asserts `command -v python3` unguarded; structurally absent (L66 shape).
- Scripts 0755 in the zip (rwxrwxrwx): not 0644.

## Measurement battery

Constraint from the user partway through: no further docker builds/runs, oracle and NOP already passed (platform panels plus the two local runs below). Rows needing a fresh container after that point are marked NOT RUN with the reason, never silently dropped.

| # | Run | Command / probe | Result | Exit |
|---|---|---|---|---|
| 1 | NOP | `bash /tests/test.sh` on the untouched base tree, `--network none`, image review183:v1 | reward 0, raw_exit_code 1, `nonzero_exit_forced_zero: true`, 21 of 38 passed (exactly the 20 behavioural p2p + the sentinel), the 17 f2p all in missing_required, `infrastructure_error: None`. The suite compiles and runs at base and fails on behaviour, so the NOP is 0 for the right reason | 1 |
| 2 | Oracle, real protocol | `bash /solution/solve.sh` THEN `bash /tests/test.sh`, 3 cycles, ONE container, `--network none` | cycle 1: reward 1, 38/38, raw 0. cycle 2: reward 1, 38/38, raw 0. cycle 3: reward 1, 38/38, raw 0. 3 of 3. This also exercises test.sh's re-apply (CLEAN_PY deletes the created paths each run) | 0 each |
| 2b | Reported vs declared ids | oracle report.json against config.json | reported 38 passed of 38 required; 17 f2p + 21 p2p declared, all distinct, no duplicates. The pillar's own diff is clean | - |
| 3 | Hostile delete | NOT RUN (user instruction: no further container runs). Read-level: the fail-closed requirement is asserted directly by `an_identity_that_cannot_be_used_does_not_become_an_anonymous_one` and `half_an_identity_is_not_an_identity`; removing golden's identity_error gate makes both `call(...).is_err()` assertions fail, and either failing leaves the cargo binary nonzero, which the exit gate also catches | NOT RUN | - |
| 4 | Gaming probe | NOT RUN as a container probe. Structural read: the graded tests are integration tests compiled as their own crates, the assertion layer is std assert!, the support module arrives via tests.patch and is deleted and recreated by test.sh CLEAN_PY, so no agent-writable file feeds the grader. The residual fd-level forgery route (writing "test X ... ok" to real stdout from library code) cannot pay: the reward also requires raw_exit_code 0, and cargo exits nonzero whenever a real test fails. The settings-only stub is the NOP's own baseline, measured 0 of 17 f2p at base | NOT RUN, structural | - |
| 4b | Agent-collision at created paths | host-side replay of test.sh's CLEAN_PY + `git apply` on a scratch copy, with an agent file planted at tests/lwa_tls_contract.rs AND tests/lwa_support/mod.rs | both pre-existing files cleared, patch applies, real content restored. "APPLY OK after cleanup" | 0 |
| 5 | `sh /tests/test.sh` | NOT RUN in a container. Read: test.sh:9 is `set -uo pipefail`, before the trap at :25, so under dash the run dies before a reward file exists (the measured mithril/elfuse pattern). Mitigant present: both scripts ship 0755 with `#!/usr/bin/env bash`, so a shebang-exec harness gets bash. That is the accepted-bundle shape (kvdex 245) | NOT RUN, read | - |
| 6 | Forced test edit | NOT RUN in a container. Read: golden.patch touches tests/integ_tests.rs with additive five-field literals only (all false/None); tests/e2e/main.rs and tests/events.rs never name AdapterOptions (grep: zero hits), so the added fields cannot break their compile; no base assertion is removed | NOT RUN, read | - |
| 7 | Move the created file | N/A structurally: golden.patch creates only examples/fastapi-https/*, and no graded test references any path golden creates (the suite reaches the deliverable through the crate name and env vars). Nothing to move | N/A, reasoned | - |
| 8 | Determinism | NOT RUN as two fresh extracts (user instruction). Weakest measured substitute: the three in-container oracle cycles returned identical 38/38 pass sets. The TLS fixtures regenerate certificates per process (temp dir keyed on pid), so byte-level fixture drift is designed in and the pass set held across it | NOT RUN, partial | - |
| + | Previous finding 1 repro | host-side run of the extracted embedded grade.py against a fabricated all-ok log of all 38 ids | exit 0 -> reward 1; exit 1 -> reward 0; exit 124 -> reward 0. Plus: a log carrying both "ok" and FAILED for one id -> reward 0 with that id in missing_required; a log missing the suite_completed sentinel -> reward 0 | measured |
| + | Previous finding 2 repro | host-side replay of solve.sh's exact git commands, 3 runs, one scratch repo | run 1 applies exit 0, runs 2 and 3 no-op exit 0, solution still present (5 files differ from base) | measured |

## Requirement to test mapping

Read end to end: instruction.md (17 lines), problem_statement.md (byte-identical), task.toml, config.json, test.sh, tests.patch (1439 lines), golden.patch (931 lines).

| # | Requirement, quoted | instruction.md line | Graded by | Mark |
|---|---|---|---|---|
| 1 | "opt-in, off unless someone asks for it ... unset, empty, or anything that is not a valid bool leaves TLS off" | 3, 5 | requests_are_encrypted_when_tls_is_switched_on (f2p) + 4 p2p off-state guards incl. empty and non-bool values | covered |
| 2 | "the adapter has to reach the app over https: the proxied request, and the readiness probe ... not obliged to share a port" | 7 | requests_are_encrypted..., the_readiness_probe_is_encrypted..., the_readiness_probe_completes_against_a_tls_only_app, the_readiness_probe_and_the_request_can_use_different_tls_ports, a_request_is_proxied_to_a_tls_only_app (f2p) | covered |
| 3 | "a plaintext server on the other end stops being reachable" | 7 | a_plaintext_app_is_out_of_reach_once_tls_is_on (f2p, with endpoint.assert_hits(0)) | covered |
| 4 | "paths, query strings, base-path stripping, request methods, headers and gzip compression all behave exactly as they do today" | 7 | the_request_path_selects..., the_query_string_reaches... (method DELETE and header asserted on the wire), the_base_path_is_stripped..., a_response_from_a_tls_app_is_still_compressed_on_request (f2p) | covered |
| 5 | "the name ... travels in the handshake, and it is what the app's certificate gets checked against ... unset and the session is opened for localhost" | 9 | the_configured_name_travels_in_the_handshake (f2p, asserts SNI bytes carry the configured name, and localhost when unset) | covered |
| 6 | "Naming it has to be enough ... with it unset the same app is out of reach ... a certificate chaining to nothing trusted is refused, and so is one issued to a name other than the one configured" | 11 | verification_refuses_a_certificate_it_should_not_accept (f2p: positive control, then no-CA refusal, then wrong-name refusal) | covered |
| 7 | "Name both, with TLS on, and the door opens. It opens on the readiness port as well" | 13 | a_client_identity_gets_a_request_into_an_app_that_demands_one, the_readiness_probe_proves_who_it_is_as_well (f2p), plus the no-identity refusal | covered |
| 8 | "A certificate named without its key, a key named without its certificate, a file that holds nothing usable ... Those requests fail. An anonymous connection is the one outcome nobody configured" | 15 | half_an_identity_is_not_an_identity, an_identity_that_cannot_be_used_does_not_become_an_anonymous_one (f2p, each with a positive control first) | covered |
| 9 | "Leave the switch off and nothing moves. Same scheme, same readiness behaviour, same handling of headers, paths, query strings, request methods and gzip compression" | 17 | 12 regression_* p2p + the_readiness_probe_stays_cleartext_when_tls_is_off + the three identity-vars-inert p2p | covered |

No row uncovered; no row graded more strictly than stated (the SNI "localhost" default and the wrong-name refusal are both stated). Helper read (R7's standing rule): the WireTap/TlsApp/TlsRequestRecorder helpers were read as graded surface; their preconditions (a real handshake record, a real openssl s_server round trip) are the requirements themselves, not silent extra contracts. SSL_CERT_FILE is named only in a test-support comment, and tests.patch is verify-time only, so it never reaches the agent.

Instruction quality: measured 17 lines, longest prose paragraph 504 chars (calibration band is roughly 312 to 826 across accepted bundles). Persona reads as a real engineering memo; none of the four red flags at docs/guidelines.md:177 fires. Symbol grep over instruction.md: no internal names (no AdapterOptions, no field names, no crate names); only the five operator env vars, which are the public contract.

Difficulty read: panel says PASS HARD, codex-gpt-5-5 0.0% (0/4), status "Some tests not passed by any agent run (not blocking; require_solvable disabled)". Read, not re-measured (12.2: a local control measures my model, not theirs). Consistent with task.toml's pass_at_k_gpt_5_5 = "0/4".

## Stock defect sweep

| Defect | Present | Evidence or the structural reason |
|---|---|---|
| 1 fail-open grader | FIXED | measured: fabricated all-ok log at exit 1 and 124 both reward 0; the gate is test.sh:554-556 |
| 2 no regression guard | FIXED | p2p 21 entries, allow_extra_failures false; NOP measured the 20 behavioural guards passing at base |
| 3 stale build-time reports | ABSENT | the Dockerfile compiles tests but never runs them; the grader parses fresh stdout, not a report directory |
| 4 non-idempotent solve.sh | FIXED | measured: 3 runs, exit 0 each, tree intact; seed's reverse-apply fallback is gone |
| 5 predictably named graded files | PRESENT IN FORM, MITIGATED | the lwa_* names are task-flavoured but not Sentinel-prefixed; what carries the load is CLEAN_PY deleting created paths before apply, measured working with planted agent files at both colliding paths |
| 6 no test-tree restore | ABSENT BY DESIGN | tests.patch is 3 creates, 0 modifications; 0 of 38 graded ids live outside the patched files (hand-verified: all 37 test functions are in the two created files; the 38th id is the config-emitted sentinel); the delete-created-paths step covers the collision half, measured in 4b |
| 7 verifier dependency behind `\|\| true` | ABSENT | the apt line is non-optional and Dockerfile:6 asserts `command -v python3` (plus tmux, asciinema, patch) unguarded; structurally the cista shape (L66) |
| 8 report shares stdout with the code under test | ABSENT | grading.parser.framework is custom, so _find_json is never reached (L66); the residual fd-write variant is analysed under run 4 and cannot pay while the exit gate stands |

Two extra rows this bundle earns on its own:

| Check | Result |
|---|---|
| Pillar 2 distinct-id count | 38 declared, 38 reported at oracle, all distinct, 17 f2p inside the 10-20 range |
| Pillar 4 measured half | both container runs were `--network none`; the suite passed, including every TLS fixture, so no graded behaviour needs egress |

## Rubric tally

| # | Finding | Severity | Pillar or requirement | Provenance | Blocks alone? |
|---|---|---|---|---|---|
| 1 | Writeup does not match the diff: Files Changed says "difficulty and model_difficulty left as inherited (not hand-edited)" while the seed-to-submitted diff shows model_difficulty medium->hard and pass_at_k_gpt_5_5 0/3->0/4; Comments for Reviewer says the model_difficulty/difficulty mismatch "still" exists (it does not; the pair agrees at hard) and that pass_at_k was left alone; Files Changed says pass_to_pass 0->19 where config.json carries 21 entries (20 behavioural + the sentinel); Comments says "36/36" where the graded set is 37 tests + sentinel = 38 ids | Minor | Secondary Requirement 5 | read, diff seed vs original | no |
| 2 | .git/gk/config, a 61-byte GitKraken last-accessed stamp, zipped into the shipped repo's .git; absent from the seed, so it arrived via the submitter's tooling. No fix content | Observation | rubric :93 soft-signal class; not one of the eleven | read | no |
| 3 | The loose ref was lost: seed ships .git/refs/heads/main (41 bytes), the submission ships only the empty refs/heads/ directory entry, so the repo depends on empty-directory preservation. HEAD still resolves via packed-refs, fsck silent, and cargo does not stamp VCS, so nothing measured breaks | Observation | none of the eleven; Pillar 5 Meets holds | read | no |
| 4 | test.sh's CLEAN_PY uses os.remove on the paths tests.patch creates; a directory or symlink planted at such a path (rather than a file) raises inside the python and the trial would die as an infrastructure error. Nothing in the task invites an agent to create one, and the names are task-prefixed | Observation | none of the eleven | read | no |
| 5 | golden's Cargo.toml uses minor-version ranges (hyper-rustls "0.23", rustls "0.20") and ships no Cargo.lock hunk, so the added TLS stack resolves within its minor line at verify time against the image cache. Deterministic per built image; the Dockerfile's offline resolve probe asserts resolvability at build time; oracle measured 3/3 | Observation | not SR9 (no flake measured); a note on the floating-resolution shape | read + oracle measured | no |

Counts: 0 Major, 1 Minor, 5 Observations. Zero Majors clears path 1; one Minor clears path 2's five-Minor bar. The verdict arithmetic gives Accept with mandatory coaching comments; the score consistent with one Minor is 3.

Bucket: not needed beyond Fixable - everything found is correctable inside the bundle, and the one counted Minor is in the writeup, not the task content.

## Findings withdrawn

| Candidate | Why it was dropped | Which 12.7 check caught it |
|---|---|---|
| preflight's grader.fail-closed FAIL | the gate exists in a different shape (`nonzero_exit_forced_zero`, test.sh:548-557); measured working with the previous reviewer's exact repro | check 1, open the cited line; then measured |
| preflight's grader.runner-pipefail FAIL | `set -o pipefail` is execution.commands[0], the first line of the generated runner, which governs the later pipelines (L67 mechanics); PIPESTATUS is captured per binary with an explicit exit 1 gate; the NOP's raw exit measured 1 | check 2, read the mechanism rather than the invocation line |
| preflight's grader.runner-errexit FAIL | the config replaces set -e with explicit per-binary PIPESTATUS capture plus `if either failed: exit 1` then `exit 0`; the runner's status is the graded one, measured | check 2 |
| "the menu still names the rustls family, so finding 3 is only half fixed" | the previous round's ask was "not one specific crate/version", and the menu across both families answers it; more fundamentally the agent runs allowlist-only and cannot fetch crates at all, so a usable TLS stack MUST be visible in the cache or the task is unsolvable offline. A warm cache is necessary, and ambiguity between families is the achievable ceiling | check 5, the remedy (no cache) would break the bundle |
| "the Dockerfile comment block names crates" | environment/Dockerfile never reaches the agent; only repo/ is copied into /app. Measured by the COPY line, not assumed | check 1 |
| model_difficulty medium->hard as a defect | the change itself is fine: the screen measured PASS HARD independently, and hulak 118 is the precedent for aligning the pair. The finding is the writeup denying the edit, not the edit | check 5 |

## Open caveats

| Caveat | Stated in round | What would retire it | Retired? |
|---|---|---|---|
| the Accept branch shows five confirmation items in two truncated pastes where docs and the template carry six | workspace caveat, carried | an untruncated capture of the Accept branch | NO |
| the rebuttal panel contents, the two difficulty counter fields, and the maximum-revisions dialog state were asked for and not yet supplied | R1.5, 2026-08-18 | the user's answer | NO |
| the page's Metadata block matches the seed task.toml rather than the submission, so no cross-check of the submission against the platform block is possible beyond what the diff shows | R2, 2026-08-18 | a platform render of the current task.toml | NO |
| the oracle wall-clock vs the ~300s "in-app limit" the submitter mentions in Comments is unverified; config carries execution.timeout_sec 1200 and verifier 1500, so which "300s" they meant is unclear | R3, 2026-08-18 | the R6 oracle run's measured wall time | NO |

## Superseded answers

Round 1 of this review; nothing superseded yet.

## Audit pass

The five 12.10 checks over the finished review_answer.txt:

1. Baseline claims: one sentence in the paste was shaped "the shape accepted bundles ship". It was rewritten to name its provenance ("a shape I have seen pass review on earlier bundles in this programme"). No other cross-bundle sentence in the paste.
2. Remedies read against each other: the asks are (a) reword the writeup fields, (b) sweep .git/gk before zipping, (c) write the loose ref back after gc. No pair touches the same file; nothing contradicts.
3. Every number re-derived from the live bundle: 17 f2p / 21 p2p / 38 ids (python count over config.json), 37 test functions (12 + 25, enumerated from tests.patch), 20 behavioural p2p (21 minus the sentinel), oracle 3 of 3 at 38 of 38 (container run), NOP 21 of 38 with the 17 missing (container run), 41-byte loose ref and 61-byte gk config (unzip -l), model_difficulty medium to hard and pass_at_k_gpt_5_5 0/3 to 0/4 (diff seed vs original). All reproduce.
4. Mechanisms tested by removal: "a truncated run cannot pass" is measured (fake log without the sentinel, reward 0). "A FAILED marker is never overridden" is measured (mixed log, reward 0 with the id in missing_required). "The image build keeps empty directories" is indirectly measured: the oracle ran git apply successfully inside the image built from this tree. The Dockerfile no-fingerprint assertion's failing direction is read, not measured; the sentence in the answer claims only what the shell line does.
5. Run list walked: rows never tried are 3, 5, 6 and 8, all NOT RUN on the user's mid-review instruction that no more containers run because oracle and NOP already passed. No finding and no part of the verdict rests on them; the counted Minor is a read of the diff against the writeup. The verdict's measured spine (NOP, oracle protocol, grader repro, solve replay, collision sim) all ran before the instruction landed.

What the audit changed: the opener (too close to the retired ten-word boilerplate), the "five places" count (the paragraph listed six), the 8/15/2026 date shape (tripped the score-fraction grep), the one unattributed baseline sentence. No finding moved severity.

## Closing

- Verdict: Accept. Score 3 of 5. 0 Majors, 1 Minor (writeup does not match the diff, six instances), 4 observations, all on 2026-08-18.
- Rebuttal acknowledgement: "No rebuttal comments available" selected; the panel was asked for and not supplied. The Comments for Reviewer field WAS supplied and read in full.
- Review minutes: PENDING the user's number; the Q6 field carries a placeholder until then.
- Battery honesty: rows 3, 5, 6, 8 NOT RUN (user instruction mid-review); the harvest row below records the command or NOT RUN per row.
- Harvest: first Accept on this path, so learning/bundles-i-accepted-as-reviewer.md gets its first row; two learning notes get additions (verifier-fail-open.md, the host-side grader repro technique; reviewer-page-carries-the-whole-submission.md, the page Metadata block describing the seed rather than the submission).
- Archive: moved to `_archive/reviews/20260805_220102__aws_aws-lambda-web-adapter__183/` on 2026-08-18 under the user's close instruction, ahead of the platform submission. The two repo directories (`seed`, `original`, `work` copies of environment/repo) are staged as gitlinks, matching how the archived tasks store theirs. The `git mv` is staged, not committed; committing is the user's call. Pre-existing index drift noted in passing and left alone: a staged-but-on-disk-deleted redisshake 657 review archive, a staged openwhispr 1002 task archive, and the humanizer `.mdc`/SKILL.md twins diverging (doclint's one failure, 57 passed).
