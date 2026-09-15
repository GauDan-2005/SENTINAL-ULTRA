# Platform task data

Pasted verbatim from the platform, 2026-08-05. Do not edit. `task.toml` on disk is
cross-checked against this block in Step 2.

```
Original Directory Name
20260803_111822__xlwings_xlwings__2719
Category
implementation
Difficulty
hard
Task Tags
async
lazy-loading
excel
office-js
api-design
Languages
Python
Markdown
Metadata
schema_version = "1.3"

[metadata]
pass_at_k_opus_4_8 = "0/3"
pass_at_k_gpt_5_5 = "0/3"
hardening_cycles = "1"
agent_hardened = "true"
author_name = "anonymous"
author_email = "anonymous@snorkel.ai"
# --- swe_ultra_requirements §4 field names ---
category = "implementation"
subcategory = "feature"
coding_language = "python"
repo_name = "xlwings"
repo_license = "NOASSERTION"
source_pr_url = "https://github.com/xlwings/xlwings/pull/2719"
base_commit_sha = "91a3f9ab96c3da33a8122a2e522386b6fd8989e9"
model_difficulty = "medium"
tags = ["async", "lazy-loading", "excel", "office-js", "api-design"]
# --- legacy aliases (kept for backward-compatible internal consumers) ---
difficulty = "hard"
task_type = "implementation"
task_subtype = "feature"
source = "https://github.com/xlwings/xlwings/pull/2719"
language = "python"
expert_time_estimate_min = 90.0
junior_time_estimate_min = 300.0
pr_created_at = "2026-07-13T13:30:54Z"
pr_merged_at = "2026-07-13T14:32:30Z"

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

## Source zip

| Field | Value |
|---|---|
| File | `download/705a2188-c9cb-4b08-afec-0a2174c103d4_submission.zip` |
| sha256 | `2f0758909758aded1e02c47dd70b450cb16827a13f57301d4ed5f48812606d41` |
| Size | 69802177 bytes (66.6 MB) |
| Entries | 437 files |
| Symlinks | 0 |
| Wrapper | none. Unpacks flat to `instruction.md`, `task.toml`, `environment/`, `solution/`, `tests/` |
| `runs/` | **absent**. No agent trial logs ship with this bundle |
