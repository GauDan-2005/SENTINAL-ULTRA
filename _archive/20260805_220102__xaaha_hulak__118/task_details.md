# 20260805_220102__xaaha_hulak__118

The platform data block, pasted verbatim. Do not fill any of this in from the files - it
comes from the platform and Step 2 cross-checks the files against it.

```
Original Directory Name: 20260805_220102__xaaha_hulak__118
Category: implementation
Difficulty: hard
Task Tags: tui, mouse-support, bubbletea, bubblezone, graphql-explorer, go
Languages: Go, YAML
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
repo_name = "hulak"
repo_license = ""
source_pr_url = "https://github.com/xaaha/hulak/pull/118"
base_commit_sha = "e1cd5e43d6c0c0a81bf90e9f29aa582e014b2927"
model_difficulty = "medium"
tags = ["tui", "mouse-support", "bubbletea", "bubblezone", "graphql-explorer", "go"]
# --- legacy aliases (kept for backward-compatible internal consumers) ---
difficulty = "hard"
task_type = "implementation"
task_subtype = "feature"
source = "https://github.com/xaaha/hulak/pull/118"
language = "go"
expert_time_estimate_min = 150.0
junior_time_estimate_min = 480.0
pr_created_at = "2026-03-10T17:02:42Z"
pr_merged_at = "2026-03-10T17:30:52Z"

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

Source PR: https://github.com/xaaha/hulak/pull/118
Base commit: e1cd5e43d6c0c0a81bf90e9f29aa582e014b2927

## Platform block vs the files, first pass

Checked against `work/task.toml` on arrival, 2026-08-06. The pasted Metadata block is
byte-identical to the `task.toml` on disk, so "same as file" holds. The remaining Step 2
cross-check rows:

| Field | Platform | Files | Match |
|---|---|---|---|
| Original Directory Name | 20260805_220102__xaaha_hulak__118 | extract is flat at the zip root | yes |
| Category | implementation | `category = "implementation"`, `subcategory = "feature"` | yes |
| Difficulty | hard | `difficulty = "hard"`, `model_difficulty = "medium"` | clash, see below |
| Task Tags | 6 tags | `tags` holds the same 6 | yes |
| Languages | Go, YAML | `coding_language = "go"`; repo is Go with YAML fixtures under `e2etests/` | yes |
| base commit | e1cd5e43 | `git rev-parse HEAD` in the shipped repo is e1cd5e43d6c0c0a81bf90e9f29aa582e014b2927 | yes |
| repo_license | `""` | `environment/repo/LICENSE` is MIT | BLANK, a finding |

`model_difficulty = "medium"` against `difficulty = "hard"` is the legacy clash CLAUDE.md
Section 8 covers. Report it, never quietly reconcile it (LEDGER L14).
