# 20260719_045042__openwhispr_openwhispr__1002

The platform data block, pasted verbatim. Nothing here is derived from the files - it comes
from the platform, and Step 2 cross-checks the files against it.

```
Original Directory Name
20260719_045042__openwhispr_openwhispr__1002
Category
implementation
Difficulty
hard
Task Tags
byok
secret-management
manifest
electron-ipc
openrouter
preload
Languages
TypeScript
JavaScript
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
coding_language = "javascript"
repo_name = "openwhispr"
repo_license = "MIT"
source_pr_url = "https://github.com/openwhispr/openwhispr/pull/1002"
base_commit_sha = "593eb3cd7bf43e11d971478149a9c6c7ce4699a2"
model_difficulty = "medium"
tags = ["byok", "secret-management", "manifest", "electron-ipc", "openrouter", "preload"]
# --- legacy aliases (kept for backward-compatible internal consumers) ---
difficulty = "hard"
task_type = "implementation"
task_subtype = "feature"
source = "https://github.com/openwhispr/openwhispr/pull/1002"
language = "javascript"
expert_time_estimate_min = 60.0
junior_time_estimate_min = 180.0
pr_created_at = "2026-06-25T03:27:27Z"
pr_merged_at = "2026-07-10T19:53:37Z"

[verifier]
timeout_sec = 300.0
network_mode = "no-network"

[agent]
timeout_sec = 1800.0
network_mode = "allowlist"
allowed_hosts = [
    "registry.npmjs.org",
    "api.anthropic.com",
    "*.anthropic.com",
    "api.openai.com",
    "*.openai.com",
    "api.portkey.ai",
]

[environment]
build_timeout_sec = 900.0
cpus = 4
memory_mb = 8192
storage_mb = 10240
gpus = 0
network_mode = "no-network"
```

Source PR: https://github.com/openwhispr/openwhispr/pull/1002
Base commit: 593eb3cd7bf43e11d971478149a9c6c7ce4699a2

## Cross-check of the pasted block against `work/task.toml` (Step 2)

Run 2026-08-10 on the working copy. Most fields agree. **Two do not**, and both are in the
network configuration, so neither is cosmetic.

| Field | Platform block | `work/task.toml` | Reading |
|---|---|---|---|
| `[agent] allowed_hosts` | six hosts, including `registry.npmjs.org` and the Anthropic and OpenAI endpoints | `["api.portkey.ai"]` only | mismatch, unresolved |
| `[environment] network_mode` | `"no-network"` | `"public"` | mismatch, unresolved. The file's value is the one Section 8 requires |
| `[environment] os` | absent | absent | missing from both. `docs/harbor-framework.md` documents it, so this is a metadata finding either way |

Everything else matches line for line: `schema_version`, every `[metadata]` field, both
timeouts, `cpus`, `memory_mb`, `storage_mb`, `gpus`, `[verifier] network_mode` and
`[agent] network_mode`.

`base_commit_sha` agrees with `git rev-parse HEAD` in the shipped repo
(`593eb3cd7bf43e11d971478149a9c6c7ce4699a2`), and `repo_license = "MIT"` matches the repo's
`LICENSE`. Category, difficulty, tags and language all agree with the file.

**Ask the submitter which rendering of those two fields the platform actually holds** before
either value is treated as authoritative. `[environment] network_mode` matters most: the file
says `public`, which is what Section 8 requires and what lets the Dockerfile run `npm ci`, and
the block says `no-network`, which would break the image build.
