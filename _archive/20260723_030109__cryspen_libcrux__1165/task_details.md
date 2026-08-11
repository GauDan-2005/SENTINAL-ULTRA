# Platform task data — pasted verbatim (Step 1.5)

Original Directory Name
20260723_030109__cryspen_libcrux__1165
Category
implementation
Difficulty
medium
Task Tags
ml-kem
pqcp
cryptography
public-api
feature-flag
rust
Languages
C
Rust
Metadata
schema_version = "1.3"

[metadata]
pass_at_k_opus_4_8 = "2/3"
pass_at_k_gpt_5_5 = "2/3"
hardening_cycles = "1"
agent_hardened = "true"
author_name = "anonymous"
author_email = "anonymous@snorkel.ai"
# --- swe_ultra_requirements §4 field names ---
category = "implementation"
subcategory = "feature"
coding_language = "rust"
repo_name = "libcrux"
repo_license = "Apache-2.0"
source_pr_url = "https://github.com/cryspen/libcrux/pull/1165"
base_commit_sha = "6146075b6ea0b52da9304eea1086505c3eb5270b"
model_difficulty = "medium"
tags = ["ml-kem", "pqcp", "cryptography", "public-api", "feature-flag", "rust"]
# --- legacy aliases (kept for backward-compatible internal consumers) ---
difficulty = "medium"
task_type = "implementation"
task_subtype = "feature"
source = "https://github.com/cryspen/libcrux/pull/1165"
language = "rust"
expert_time_estimate_min = 180.0
junior_time_estimate_min = 600.0
pr_created_at = "2025-09-22T11:33:46Z"
pr_merged_at = "2025-09-24T06:49:27Z"

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
