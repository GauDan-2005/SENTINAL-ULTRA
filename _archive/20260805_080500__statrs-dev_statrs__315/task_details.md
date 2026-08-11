# Platform task data - pasted verbatim (Step 1.5)

Received 2026-08-05. Source zip: `8b7cc519-d8a3-49f7-9d5f-0c51c048058a_submission.zip`,
sha256 `42d30f41b61bc20987e12221dd1d3abdcf65dc844fe8010ecd94001a9f2cc67f`, 3454577 bytes,
108 entries, 0 symlinks, no `runs/`, no `task/` wrapper.

---

Original Directory Name
20260805_080500__statrs-dev_statrs__315
Category
implementation
Difficulty
hard
Task Tags
statistics
hypothesis-testing
rust
numerical-computing
scipy-parity
Languages
Rust
YAML
Metadata
schema_version = "1.3"

[metadata]
pass_at_k_opus_4_8 = "0/3"
pass_at_k_gpt_5_5 = "1/3"
hardening_cycles = "1"
agent_hardened = "true"
author_name = "anonymous"
author_email = "anonymous@snorkel.ai"
# --- swe_ultra_requirements §4 field names ---
category = "implementation"
subcategory = "feature"
coding_language = "rust"
repo_name = "statrs"
repo_license = ""
source_pr_url = "https://github.com/statrs-dev/statrs/pull/315"
base_commit_sha = "a8fe65cdeb10548b01ad8897a17b0a9bfdfbf0af"
model_difficulty = "medium"
tags = ["statistics", "hypothesis-testing", "rust", "numerical-computing", "scipy-parity"]
# --- legacy aliases (kept for backward-compatible internal consumers) ---
difficulty = "hard"
task_type = "implementation"
task_subtype = "feature"
source = "https://github.com/statrs-dev/statrs/pull/315"
language = "rust"
expert_time_estimate_min = 180.0
junior_time_estimate_min = 600.0
pr_created_at = "2025-01-02T16:24:22Z"
pr_merged_at = "2025-01-19T15:51:33Z"

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
