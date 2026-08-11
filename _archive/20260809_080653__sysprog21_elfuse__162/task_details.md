# Platform task data (pasted verbatim, Step 1.5)

Received from the user 2026-08-10. Not generated, not inferred.

```
Original Directory Name
20260809_080653__sysprog21_elfuse__162
Category
implementation
Difficulty
hard
Task Tags
syscall
times
cpu-accounting
aarch64
emulator
getrusage
Languages
C
Shell
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
repo_name = "elfuse"
repo_license = ""
source_pr_url = "https://github.com/sysprog21/elfuse/pull/162"
base_commit_sha = "23ec9b0ac58719d92cda5a076877d2118d77b705"
model_difficulty = "medium"
tags = ["syscall", "times", "cpu-accounting", "aarch64", "emulator", "getrusage"]
# --- legacy aliases (kept for backward-compatible internal consumers) ---
difficulty = "hard"
task_type = "implementation"
task_subtype = "feature"
source = "https://github.com/sysprog21/elfuse/pull/162"
language = "c"
expert_time_estimate_min = 90.0
junior_time_estimate_min = 300.0
pr_created_at = "2026-07-07T09:05:34Z"
pr_merged_at = "2026-07-09T07:28:20Z"

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

## Cross-check status

Not yet run. Step 2 cross-checks this block against the extracted `task.toml`, the repo and the
source PR. Two things are already visible from the arrangement pass and are recorded here so the
cross-check has somewhere to land, not as findings:

- `repo_license = ""` is blank. Section 8 requires a real SPDX id, and `environment/repo/LICENSE`
  ships in the bundle, so there is something to check it against.
- `model_difficulty = "medium"` against `difficulty = "hard"` is the legacy clash Section 8 says to
  report rather than quietly reconcile.
