# 20260805_220102__aws_aws-lambda-web-adapter__183

The platform data block, pasted verbatim from the reviewer page (user paste, 2026-08-18). Do not fill any of this in from the files - it comes from the platform and Step 2 cross-checks the files against it.

```
Original Directory Name: 20260805_220102__aws_aws-lambda-web-adapter__183
Category: implementation
Difficulty: hard
Task Tags: https, tls, rust, hyper-rustls, reverse-proxy, aws-lambda
Languages: Markdown, YAML
Metadata:
schema_version = "1.3" [metadata] pass_at_k_opus_4_8 = "0/3" pass_at_k_gpt_5_5 = "0/3" hardening_cycles = "2" agent_hardened = "true" author_name = "anonymous" author_email = "anonymous@snorkel.ai"
category = "implementation" subcategory = "feature" coding_language = "rust" repo_name = "aws-lambda-web-adapter" repo_license = "" source_pr_url = "https://github.com/aws/aws-lambda-web-adapter/pull/183" base_commit_sha = "acf214e56091b3a421d38dd6994625a4070f464b" model_difficulty = "medium"
legacy aliases: difficulty = "hard" task_type = "implementation" task_subtype = "feature" source = "https://github.com/aws/aws-lambda-web-adapter/pull/183" language = "rust" expert_time_estimate_min = 60.0 junior_time_estimate_min = 210.0 pr_created_at = "2023-02-26T09:46:44Z" pr_merged_at = "2023-03-10T09:46:39Z"
[verifier] timeout_sec = 300.0 network_mode = "no-network"
[agent] timeout_sec = 1800.0 network_mode = "allowlist" allowed_hosts = ["api.portkey.ai"]
[environment] build_timeout_sec = 900.0 cpus = 4 memory_mb = 8192 storage_mb = 10240 gpus = 0 network_mode = "public"
```

NOTE (recorded at intake): the page's Metadata block matches the SEED task.toml (verifier 300, agent 1800, model_difficulty medium, repo_license blank, pass_at_k 0/3 + 0/3), not the submitted one (verifier 1500, agent 7200, model_difficulty hard, license Apache-2.0, pass_at_k_gpt_5_5 0/4). The platform block appears to describe the task as issued, so the Step-2 cross-check runs against the SEED file, not the submission.

Source PR: https://github.com/aws/aws-lambda-web-adapter/pull/183
Base commit: acf214e56091b3a421d38dd6994625a4070f464b

## Reviewer page particulars (from the user paste)

- Reviewer Feedback, 8/14/26 5:33 PM (the previous round's findings, verbatim):

  "I checked the latest ZIP and it needs revision. A lot of the earlier problems look fixed. The instruction is cleaner the TLS tests are much stronger and the repo at the base commit looks clean. Three things still need fixing. 1. The grader can still give reward 1 when the test process fails. It records raw_exit_code but it does not require that exit code to be 0. I tried a fake log where every required test shows ok, including lwa_meta::suite_completed, with exit code 1, and it still returned reward 1. Same result with exit 124. Please make any nonzero test process exit force reward 0. 2. solve.sh also is not idempotent. The first run applies the patch and exits 0. The second run leaves the solution in place but exits 1. On a rerun it should exit 0 and change nothing. 3. Last, the Dockerfile still prefetches hyper-rustls = "0.23.2" into the offline cargo cache. That points agents at the intended TLS stack. Please cache in a way that does not advertise one specific crate/version."

- Submitter verdict: Fixable (analysis question) / [internal] Validity: Fixable.
- Issue-location checkboxes: not individually legible in the paste; the numbered issue details cover all four (Instructions, Tests, Oracle Solution, Environment/Dockerfile).
- Submitted zip as listed on the page: 2c330de7-4b1b-4c5c-a5f4-25516ab8e732_v8.zip, 8/15/2026, 4:42:09 PM. The file handed over locally is 68455bcb-e7b8-4b4a-b38b-f4273a2a4ac5_submission_2026-08-15T11_11_28.084Z.zip.
- Difficulty Checks block: checks run (blank in the paste), checks remaining (blank in the paste), last counted submission version 5babf619-66b0-4896-a30c-15115c678416, last result "hard".
- Eval panels (verbatim from the paste):
  - Static Checks: "Check feedback" (no detail rendered in the paste); Automated feedback banner reads "All checks have passed".
  - Prescriptiveness: "Check prescriptiveness" (no detail rendered in the paste).
  - Difficulty Check: "Difficulty: PASS HARD. Status: Some tests not passed by any agent run (not blocking; require_solvable disabled). Agent Performance: codex-gpt-5-5: 0.0% (0/4 runs)".
  - Agentic Judge Quality Report: "Status: OK. Reason: n/a".
  - Oracle Check: "Oracle: PASS 3/3 runs passed. NOP: PASS 0/1 runs passed (expected 0)".
  - Quality Check: "datapoint meets quality bar (15/15 criteria pass)".
- Rebuttal comments (left-hand panel): asked for; not supplied. See task.md Open caveats.
- "Maximum revision reached" dialog: asked about; no answer. The verdict radio on the paste shows Accept / Needs Revision / Reject all present, which argues the dialog is NOT showing, but this is inferred, not stated.
- Review duration: to be asked at R10/R11. Not invented.

## Submitter's own answers (verbatim from the paste)

What issues did you find (numbered details):

1) Instructions - overly prescriptive, and a leak in themselves.

The intake instruction handed the agent the implementation shape: it named the
AdapterOptions struct, the exact new fields (enable_tls, tls_server_name,
tls_cert_file), their Rust types (Option<String>), that they were public struct
fields, that from_env populates them, and the Protocol/Default compatibility
note. That is a recipe, not a requirement.

Fixable: yes. The instruction now states only the observable contract - the
operator-facing environment variables and the behaviour (https on both the
request and the readiness path, real certificate verification, fail-closed on a
broken client identity, no regression when the switch is off). None of the
internal symbols remain (a symbol grep over v7's instruction is empty).

2) Tests - requirements were not actually tested, and the grader could be gamed.

The intake shipped 13 fail-to-pass tests, zero pass-to-pass, allow_extra_failures
= true, and a single unguarded test command. Nothing exercised the TLS scheme,
the client, the server name, or the cert bundle - a stub that just exposed three
settings and read their env vars scored reward 1.0 at 13/13. The test patch also
deleted one existing test file and renamed ten others, so several of those 13
"failures" were rename/compile artifacts, not real behaviour.

Fixable: yes. The suite now drives the adapter only through the documented env
vars and observes real TLS handshakes and round trips against a real openssl
server: encrypted request and readiness traffic, private-CA trust with wrong-CA
and wrong-name refusals, separate readiness ports, and full path/query/method/
header/base-path/gzip preservation, plus the mutual-TLS half (client identity
accepted, and half or unusable identities failing closed). The patch adds new
files only (0 deletions, 0 renames). Lists are 17 fail-to-pass and 19
pass-to-pass, derived by running base and oracle; allow_extra_failures is false;
the same settings-only stub now passes 0/17. The grader was also hardened so it
fails closed: any non-zero test-process exit forces reward 0, a FAILED marker is
never overridden by a stray ok, and a suite-completed sentinel covers both test
binaries so a truncated run cannot score.

3) Oracle Solution - a self-destructing solve script and an incomplete patch.

The intake solve.sh chained plain apply -> --3way -> reverse-apply (-R), so a
second run deleted the solution and still exited 0. The golden patch also
shipped without Cargo.lock, so the airgapped verifier re-resolved the TLS stack
every run.

Fixable: yes. solve.sh is now one strict forward apply and is idempotent - it
reverse-checks first and no-ops (exit 0) if already applied, and never
reverse-applies, so the solution is never undone. The golden patch ships the
pinned Cargo.lock and the previously-omitted PR files.

4) Environment/Dockerfile - the build leaked the solution.

The intake Dockerfile prefetched hyper-rustls = "0.23.2" and aws-sigv4 by name
and then actually compiled the solution crates (cargo build --lib --bins plus
cargo llvm-cov), leaving fingerprints under target/ that named hyper-rustls right
in the agent's own workspace.

Fixable: yes. The prefetch is now a menu of TLS crates across both families
(hyper-rustls, tokio-rustls, native-tls) using version ranges, it is fetch-only,
target/ is wiped and rebuilt from the pristine manifest, and a hard assertion
fails the build if anything under target/ names a solution TLS crate.

Files Changed (verbatim):

instruction.md - rewritten from a field/type recipe to a behavioural contract; no internal symbol names remain. Why: remove over-prescription and the leak. environment/problem_statement.md - re-copied byte-for-byte from instruction.md. tests/tests.patch - replaced the delete/rename suite with new-files-only TLS tests driving the documented env vars and a real TLS server; added the mutual-TLS cases. Why: close the coverage gap that let a stub pass. tests/config.json - fail_to_pass 13->17, pass_to_pass 0->19 (derived by running), allow_extra_failures true->false, and the run now propagates each cargo binary's exit code. Why: real behaviour is graded and the grader fails closed. tests/test.sh - the embedded grader forces reward 0 on any non-zero exit code, treats a FAILED marker as a hard non-pass, and uses a suite-completed sentinel. Why: a failed/truncated/aborted run can never score. solution/solve.sh - idempotent single forward apply; reverse-check no-op; no reverse-apply. Why: reruns must not undo the solution. solution/golden.patch - complete PR subset plus a pinned Cargo.lock and the tests/integ_tests.rs fields needed so a bare cargo test compiles. Why: offline, reproducible oracle. environment/Dockerfile - fetch-only menu prefetch, target/ wiped, no solution compile, hard no-leak assertion. Why: stop advertising the TLS stack. task.toml - filled repo_license and os, added difficulty_explanation, nested the timeouts (verifier 1500 > agent step budget), labelled the stale pass_at_k. difficulty and model_difficulty left as inherited (not hand-edited).

PR additions (verbatim):

The production scope is unchanged - it is still the opt-in TLS-to-upstream
feature from PR #183. Earlier repair restored source-PR files the intake omitted
and ported the repo's own exhaustive AdapterOptions test literals so the
upstream-shaped solution compiles. One logically-connected extension was added on
top: mutual TLS (the adapter presenting its own client identity), which reuses
the same connector and the same request and readiness paths. Nothing was removed
or reduced.

Comments for Reviewer (verbatim):

This upload answers your three revision notes; everything else is unchanged from
the version you reviewed.

1) Exit-code gate. The grader now gates the reward on the process exit code.
config.json captures each cargo binary's exit code and the run exits non-zero if
either failed, so the suite-completed echo no longer masks it; grade.py then
forces reward 0 whenever the exit code is non-zero. Your exact repro behaves now -
the fake all-ok log gives reward 1 at exit 0, reward 0 at exit 1, and reward 0 at
exit 124. Oracle still scores 36/36 at exit 0; NOP still 0 with the 17
fail-to-pass missing.

2) solve.sh idempotency. It reverse-checks first and no-ops if already applied,
exiting 0 without touching the tree, and never reverse-applies. First run
applies; second and third runs exit 0 and leave the TLS changes in place.

3) Dockerfile prefetch. The single hyper-rustls = "0.23.2" line is replaced by a
menu of TLS crates across both families using version ranges. native-tls is
already vendored via hyper-tls, so both stacks are cached and no one crate or
version is spotlighted. The offline oracle build still resolves and passes 36/36.
The earlier k=8 runs confirmed the suite is stack-agnostic, so a visible menu is
not a hint.

Two things I left alone and want to flag rather than quietly change. The oracle
suite runs around 233s against the ~300s in-app limit - it is compile-bound
because the rustls stack builds at verify time and cannot be pre-baked without
leaking the crate under target/, and it came in with the mutual-TLS expansion,
not these edits. And the difficulty metadata still has the old
model_difficulty/difficulty mismatch and a stale pass_at_k; I left those per the
no-hand-edit rule, and the difficulty screen now measures HARD on its own, which
is the real evidence. Happy to change either if you would prefer.

Senior estimate: (rendered as the radio group; the paste does not show which of <10 / 10-20 / 20-40 / 40+ was selected)
