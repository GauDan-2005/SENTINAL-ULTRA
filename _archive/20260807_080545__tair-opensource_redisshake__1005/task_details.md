# 20260807_080545__tair-opensource_redisshake__1005

The platform data block, pasted verbatim. Do not fill any of this in from the files - it
comes from the platform and Step 2 cross-checks the files against it.

```
Original Directory Name: 20260807_080545__tair-opensource_redisshake__1005
Category: implementation
Difficulty: hard
Task Tags: redis, valkey, rdb, replication, golang
Languages: JSON, Go
Metadata:
schema_version = "1.3"

[metadata]
pass_at_k_opus_4_8 = "0/3"
pass_at_k_gpt_5_5 = "0/3"
hardening_cycles = "2"
agent_hardened = "true"
author_name = "anonymous"
author_email = "anonymous@snorkel.ai"
# --- swe_ultra_requirements §4 field names ---
category = "implementation"
subcategory = "feature"
coding_language = "go"
repo_name = "redisshake"
repo_license = ""
source_pr_url = "https://github.com/tair-opensource/redisshake/pull/1005"
base_commit_sha = "1dc99dcbe02fafb4490459ecd45b02332476a967"
model_difficulty = "medium"
tags = ["redis", "valkey", "rdb", "replication", "golang"]
# --- legacy aliases (kept for backward-compatible internal consumers) ---
difficulty = "hard"
task_type = "implementation"
task_subtype = "feature"
source = "https://github.com/tair-opensource/redisshake/pull/1005"
language = "go"
expert_time_estimate_min = 180.0
junior_time_estimate_min = 360.0
pr_created_at = "2025-12-30T05:58:33Z"
pr_merged_at = "2025-12-31T06:56:47Z"

[verifier]
timeout_sec = 300.0
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

Source PR: https://github.com/tair-opensource/redisshake/pull/1005
Base commit: 1dc99dcbe02fafb4490459ecd45b02332476a967

## Cross-check against the extract (arrival, 2026-08-07)

Only the mechanical comparisons that the arrangement itself settles. The full Step 2 list is
still to run.

| Platform field | File | Agrees? |
|---|---|---|
| Original Directory Name | the extracted directory name | yes |
| Metadata block | `work/task.toml` | yes, the pasted block is the file verbatim |
| Category / Difficulty / Tags / Languages | `task.toml` `category`, `difficulty`, `tags`, `coding_language` | yes |
| Source PR | `[metadata] source` and `source_pr_url` | yes, both the same URL |

Not yet checked: `base_commit_sha` against `git rev-parse HEAD` in the working copy, the
licence file behind the blank `repo_license`, and the source PR's own file list.
