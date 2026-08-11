_Owner of CLAUDE.md **Section 8**. Loaded every session._

## 8. task.toml reference (check on EVERY task)

`schema_version` is the Harbor format version, not the task version. Four blocks, with hard limits:

| Block           | Field                      | Required value / limit                               |
| --------------- | -------------------------- | ---------------------------------------------------- |
| `[environment]` | `os`                       | container OS, e.g. `linux`                           |
|                 | `cpus`                     | `2` or `4`                                           |
|                 | `memory_mb`                | min `2048`, max `16384`                              |
|                 | `storage_mb`               | min `5120`, max `10240`                              |
|                 | `gpus`                     | always `0`                                           |
|                 | `build_timeout_sec`        | max `1800`                                           |
|                 | `network_mode`             | `"public"`                                           |
| `[agent]`       | `network_mode`             | `"allowlist"`                                        |
|                 | `allowed_hosts`            | `["api.portkey.ai"]`                                 |
|                 | `timeout_sec`              | max `7200` - raise it when runs/ show agent timeouts |
| `[verifier]`    | `network_mode`             | `"no-network"`                                       |
|                 | `timeout_sec`              | max `1800`                                           |
| `[metadata]`    | `category` (+ subcategory) | primary classification - editable                    |
|                 | `difficulty_explanation`   | why the task warrants its tier - editable            |
|                 | `source`                   | URL of the source PR / commit / issue                |
|                 | `repo_name`                | short repo name, e.g. `kvdex`                        |
|                 | `repo_license`             | a real SPDX id, never blank                          |
|                 | `base_commit_sha`          | must equal `git rev-parse HEAD` in the shipped repo  |
|                 | `source_pr_url`            | same URL as `source` on every bundle measured        |

**The last four rows are observed, not documented.** `docs/harbor-framework.md:74-78` lists only `category`, `difficulty_explanation` and `source` under `[metadata]`, yet all four bundles on this machine ship `repo_name`, `repo_license`, `source_pr_url` and `base_commit_sha` populated, alongside `author_name`, `author_email`, `subcategory` and `coding_language`. Measured 2026-08-04: `repo_license` is `MIT` on kvdex 245 (`_archive/20260719_045042__oliver-oloughlin_kvdex__245/work/task.toml:13`) and `Apache-2.0` on libcrux 1165, AltBeacon 1177 and equalsverifier 1166. Check all four on every task, in the Step 2 cross-check:

- `repo_license` holds a real SPDX identifier and matches the licence file in `environment/repo`. A blank, missing or invented value is a Metadata Issues finding
- `repo_name` matches the repo directory and the repo half of the source URL
- `base_commit_sha` equals `git rev-parse HEAD` in the working copy. On a mismatch HEAD wins and the field gets realigned
- `source_pr_url` and `source` resolve to the same PR

Network rules that changed recently and are easy to get wrong:

- `network_mode` is a **per-block** field. Do NOT strip it - older guidance said to remove `network_mode` / `allowed_hosts` and that guidance is dead
- Separately, remove `network_mode = "none"` from `docker_compose.yaml` if it is present
- The Dockerfile MAY use the network at build time. Only run time is restricted - the agent reaches the model gateway only, the verifier is airgapped. Never flag a build-time network install as an issue; flag non-reproducible builds and run-time fetches instead

Do NOT hand-edit the difficulty or pass-rate metadata to make a check pass. If the measured difficulty and the declared metadata disagree and the linter then rejects the task as "easy", that conflict is a known tooling gap - escalate it on Slack with the UID rather than tuning the fields (see the troubleshooting list in Section 4).

**Legacy `model_difficulty` vs `difficulty` - report it, do not quietly reconcile it.** Neither field is in the current schema; both only survive on older tasks. When they contradict each other (`model_difficulty = "medium"` against `difficulty = "hard"`), that is a metadata accuracy finding worth naming in Comments for Reviewer, and a reviewer may well ask for them to agree. It is still not licence to edit a difficulty field to satisfy a check or a linter - `docs/faq.md` is explicit that the fix for that conflict is escalation, not tuning. If a reviewer asks directly for the fields to be aligned, do it, and say in Comments for Reviewer that the change came from their note.

`[environment] os` is a documented field (`docs/harbor-framework.md`) and appears in the reference `task.toml`. A bundle missing it is a metadata finding.
