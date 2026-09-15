# Platform task data (pasted verbatim, Step 1.5)

Received from the user 2026-08-09. Not generated, not inferred.

```
Original Directory Name
20260808_213817__openziti_ziti-sdk-c__668
Category
implementation
Difficulty
hard
Task Tags
high-availability
failover
controller
c-sdk
networking
error-handling
Languages
C
C++
Metadata
schema_version = "1.3"

[metadata]
pass_at_k_opus_4_8 = "0/3"
pass_at_k_gpt_5_5 = "0/3"
author_name = "anonymous"
author_email = "anonymous@snorkel.ai"
# --- swe_ultra_requirements §4 field names ---
category = "implementation"
subcategory = "feature"
coding_language = "c"
repo_name = "ziti-sdk-c"
repo_license = ""
source_pr_url = "https://github.com/openziti/ziti-sdk-c/pull/668"
base_commit_sha = "daf515a28cb3b730b2be22a8be617bef4c7038df"
model_difficulty = "medium"
tags = ["high-availability", "failover", "controller", "c-sdk", "networking", "error-handling"]
# --- legacy aliases (kept for backward-compatible internal consumers) ---
difficulty = "hard"
task_type = "implementation"
task_subtype = "feature"
source = "https://github.com/openziti/ziti-sdk-c/pull/668"
language = "c"
expert_time_estimate_min = 180.0
junior_time_estimate_min = 600.0
pr_created_at = "2024-06-07T12:50:49Z"
pr_merged_at = "2024-06-07T18:26:14Z"

[verifier]
timeout_sec = 1800.0
network_mode = "no-network"

[agent]
timeout_sec = 1800.0
network_mode = "allowlist"
allowed_hosts = [
    "api.portkey.ai",
]

[environment]
build_timeout_sec = 900.0
cpus = 4
memory_mb = 8192
storage_mb = 10240
gpus = 0
network_mode = "public"
```

## Cross-check against the extracted bundle (Step 2, first pass)

Run against `work/`, never against `download/original/`.

| Field | Platform block | Bundle on disk | Agrees |
|---|---|---|---|
| Original Directory Name | `20260808_213817__openziti_ziti-sdk-c__668` | folder name matches | yes |
| Category | implementation | `task.toml` `category = "implementation"` | yes |
| Difficulty | hard | `task.toml` `difficulty = "hard"` | yes |
| Task Tags | 6 tags | `task.toml` `tags` same 6 | yes |
| Languages | C, C++ | `coding_language = "c"`; repo is C with C++ Catch2 tests | yes, C++ is the test language only |
| Metadata block | as above | byte-identical to `work/task.toml` | yes |
| base_commit_sha | `daf515a2` | `git rev-parse HEAD` = `daf515a28cb3b730b2be22a8be617bef4c7038df` | yes |
| repo_name | ziti-sdk-c | repo directory and source URL agree | yes |
| repo_license | **empty string** | repo ships Apache License 2.0 at `environment/repo/LICENSE` | **NO - metadata finding** |
| model_difficulty vs difficulty | medium vs hard | same clash in the file | **report, do not reconcile (LEDGER L14)** |

The Metadata block the platform shows is the same file that is on disk, so "same as file" holds.
Two mismatches are recorded above and both are findings rather than transcription errors.
