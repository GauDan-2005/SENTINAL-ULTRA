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

### The pristine baseline - what a `task.toml` looks like BEFORE any submitter touches it

Measured 2026-08-11 across all five `_archive/*/download/original/task.toml`, the untouched extracts.
Use this before calling any `task.toml` value a defect, and **measure against `download/original/`,
never against `work/`** - `work/` is what those submitters changed, so comparing a new bundle to five
`work/` copies measures other people's rewrites and reports the difference as this bundle's defect.

| Field | Arrives as, n=5 | Accepted bundles' shipped value | A difference is |
|---|---|---|---|
| `[environment] os` | **absent 5/5** | **added 5/5** | a real finding, and the strongest of the five |
| `[metadata] difficulty_explanation` | **absent 5/5** | added 4/5 | a real finding, weaker |
| `[verifier] timeout_sec` vs `config.json` `execution.timeout_sec` | **300 vs 1800, 5/5** | statrs 315 **accepted** keeping 300 | **not a finding** (LEDGER L58) |
| `difficulty` vs `model_difficulty` | **hard vs medium, 4/5** | shipped unchanged 4/4 | **not a finding** (LEDGER L62) |
| `[agent] timeout_sec` | **1800, 5/5** | 2/5 kept it | **not a finding** (LEDGER L63) |
| `[environment] network_mode` | **`"public"` 7/7** | shipped `"public"` | **a real finding, and blocking.** Measured on cista 172, the one bundle carrying `"no-network"`: `docker build --network=none` on its own Dockerfile dies on the first `apt-get` layer with exit 100. `docs/harbor-framework.md:59` prescribes `"public"` directly, so this one does not rest on the baseline at all |
| `[agent] allowed_hosts` | **`["api.portkey.ai"]` 7/7** | unchanged | a real finding when it differs. cista 172 widens it to six entries including `registry.npmjs.org` and `api.openai.com` on a C++ task. `docs/harbor-framework.md:66` names the single host |

The last two rows are `n=7` rather than `n=5`, because the two `review_tasks/*/download/original/` extracts
count as arriving bundles too and one of them was generated three days **after** cista 172. That closes off
the "an older generator produced it" reading, which is the first thing to check before calling an outlier a
defect.

**The four real-finding rows split into two kinds and they are worded differently.** The first two,
`os` and `difficulty_explanation`, are **not** "the submitter broke this". They arrive absent
everywhere, so the true sentence is "this arrives absent in every bundle, every submitter who cleared
review added it, and this one did not". Word them that way, or a submitter checks their own diff,
finds they never touched the field, and stops trusting the page. The last two, `network_mode` and
`allowed_hosts`, are different in kind: `docs/harbor-framework.md` prescribes both values by name, so
they stand on the documented rule and the baseline is only corroboration.

```bash
for d in _archive/*/download/original review_tasks/*/download/original; do
  [ -f "$d/task.toml" ] || continue
  echo "== $d"
  grep -nE '^\s*os\s*=|difficulty_explanation|timeout_sec|model_difficulty|network_mode|allowed_hosts' "$d/task.toml"
done
```

**Legacy `model_difficulty` vs `difficulty` - report it, do not quietly reconcile it.** On the
**submitter** path this stays a metadata accuracy note worth a line in Comments for Reviewer. On the
**reviewer** path it is not a finding at all, on the baseline above: it arrives that way in 4 of 5
bundles and all four shipped it unchanged and were accepted. Neither field is in the current schema; both only survive on older tasks. When they contradict each other (`model_difficulty = "medium"` against `difficulty = "hard"`), that is a metadata accuracy finding worth naming in Comments for Reviewer, and a reviewer may well ask for them to agree. It is still not licence to edit a difficulty field to satisfy a check or a linter - `docs/faq.md` is explicit that the fix for that conflict is escalation, not tuning. If a reviewer asks directly for the fields to be aligned, do it, and say in Comments for Reviewer that the change came from their note.

`[environment] os` is a documented field (`docs/harbor-framework.md`) and appears in the reference `task.toml`. A bundle missing it is a metadata finding.
