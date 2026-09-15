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

**The last four rows are observed, not documented.** `docs/harbor-framework.md:74-78` lists only `category`, `difficulty_explanation` and `source` under `[metadata]`, yet all eleven arriving bundles on this machine carry `repo_name`, `repo_license`, `source_pr_url` and `base_commit_sha` as keys, alongside `author_name`, `author_email`, `subcategory` and `coding_language`. Re-measured 2026-08-16 across the same eleven `download/original/task.toml` as the baseline table below: the key being present is not the same as it being filled in, and `repo_license` arrives **blank** in **4 of the 11** (statrs 315, redisshake 1005, elfuse 162, hulak 118), `MIT` in four, `Apache-2.0` in two (libcrux 1165 and AltBeacon 1177), and **`NOASSERTION` on xlwings 2719, which is a fifth case the old wording had no room for: not blank, not missing, and not a real SPDX id either.** Check all four on every task, in the Step 2 cross-check:

- `repo_license` holds a real SPDX identifier and matches the licence file in `environment/repo`. A blank, missing or invented value is a Metadata Issues finding, and `NOASSERTION` is the invented case rather than the blank one. It arrives unusable in 5 of the 11, so word it as the arriving default the submitter did not fill in, the same discipline the baseline table uses
- `repo_name` matches the repo directory and the repo half of the source URL
- `base_commit_sha` equals `git rev-parse HEAD` in the working copy. On a mismatch HEAD wins and the field gets realigned
- `source_pr_url` and `source` resolve to the same PR

Network rules that changed recently and are easy to get wrong:

- `network_mode` is a **per-block** field. Do NOT strip it - older guidance said to remove `network_mode` / `allowed_hosts` and that guidance is dead
- Separately, remove `network_mode = "none"` from `docker_compose.yaml` if it is present
- The Dockerfile MAY use the network at build time. Only run time is restricted - the agent reaches the model gateway only, the verifier is airgapped. Never flag a build-time network install as an issue; flag non-reproducible builds and run-time fetches instead

**These three values are a Major pillar now, not metadata tidying.** `docs/reviewer-rubric.md:73-83` makes airgapped verifier and network integrity one of the five Major Pillars, flagged in 41% of reviewer comments, and one confirmed violation is Needs Revision whatever else the bundle gets right. The Needs Revision line reads "graded behavior requires internet the verifier won't have, or the shipped environment leaves network open where it should be restricted" (`:83`), which is `[verifier] network_mode` not reading `"no-network"`, `[agent] network_mode` not reading `"allowlist"`, and an `allowed_hosts` list widened past `["api.portkey.ai"]`. Read a widened allowlist as network left open rather than as a metadata nit: cista 172 widens it to six entries including `registry.npmjs.org` and `api.openai.com` on a C++ task.

**The declared value is only half of that pillar and the other half is measured.** `:79` puts "tests pass with networking disabled" in the Meets line, so a `task.toml` reading `"no-network"` proves nothing about whether the graded path reaches a host. Settle that half by running the Phase B verifier with networking off (`docker run --network none`). The measured case is `learning/cmake-reconfigure-needs-network.md`: applying `tests.patch` re-ran a CMake configure that tried to git-update a dependency pinned to a branch, and no graded test ran at all. The build-time bullet above survives the new rubric untouched, because `:81` puts a non-graded setup step reaching the network at Soft signal, so a build-time `apt-get` is still not a finding.

Do NOT hand-edit the difficulty or pass-rate metadata to make a check pass. If the measured difficulty and the declared metadata disagree and the linter then rejects the task as "easy", that conflict is a known tooling gap - escalate it on Slack with the UID rather than tuning the fields (see the troubleshooting list in Section 4).

### The pristine baseline - what a `task.toml` looks like BEFORE any submitter touches it

Re-measured 2026-08-16 across all eleven `download/original/task.toml`, the untouched extracts.
Use this before calling any `task.toml` value a defect, and **measure against `download/original/`,
never against `work/`** - `work/` is what those submitters changed, so comparing a new bundle to eight
`work/` copies measures other people's rewrites and reports the difference as this bundle's defect.

| Field | Arrives as, n=11 | Archived tasks' shipped value, n=8 | A difference is |
|---|---|---|---|
| `[environment] os` | **absent 11/11** | **added 8/8** | a real finding, and the strongest of the five |
| `[metadata] difficulty_explanation` | **absent 10/11**, mithril.js 2021 still the one that arrives with it | added 7/8 | a real finding, weaker |
| `[verifier] timeout_sec` vs `config.json` `execution.timeout_sec` | **inverted 10/11**, cista 172 still the one that arrives matched at 300 against 300 | **7 of 8 cleared it before shipping** - libcrux 900/840, statrs 300/240, xlwings 300/240, redisshake 1800/1500, elfuse 1200/900, AltBeacon 1800/1500, hulak 900/600. Only kvdex 245 shipped it inverted, 900 against 1800 | **a real finding, Minor.** `docs/reviewer-rubric.md:101` and `:142` name this exact pair as Secondary Requirement 1, flagged in 18% of reviewer comments. It supersedes LEDGER L58, whose measurement stands and whose conclusion does not |
| `difficulty` vs `model_difficulty` | **hard vs medium, 9/11**, libcrux 1165 and mithril.js 2021 the medium/medium pair | **6 of 7 shipped unchanged; hulak 118 changed it**, hard to medium, at a reviewer's direct request | **not a finding on its own** (LEDGER L62), and a reviewer may still ask for it, which is now measured rather than hypothetical |
| `[agent] timeout_sec` | **1800, 11/11** | 2/8 kept it | **not a finding** (LEDGER L63) |
| `[metadata] author_name` and `author_email` | **`anonymous` and `anonymous@snorkel.ai`, 11/11** | shipped unchanged 8/8 | **not a finding.** It is the generator's placeholder and no submitter has touched it. `docs/reviewer-rubric.md:105` scopes Metadata mismatch to files-changed counts and the writeup against the actual diff, which is a different thing. Same family as L61 to L63. Raised by an external reviewer prompt pack, measured here 2026-08-14 |
| `[environment] network_mode` | **`"public"` 10/11** | shipped `"public"` | **a real finding, and blocking.** Measured on cista 172, the one bundle carrying `"no-network"`: `docker build --network=none` on its own Dockerfile dies on the first `apt-get` layer with exit 100. `docs/harbor-framework.md:59` prescribes `"public"` directly, so this one does not rest on the baseline at all |
| `[agent] allowed_hosts` | **`["api.portkey.ai"]` 10/11** | unchanged | a real finding when it differs. cista 172 widens it to six entries including `registry.npmjs.org` and `api.openai.com` on a C++ task. `docs/harbor-framework.md:66` names the single host |

**Re-measured 2026-08-16. Every row in column two is n=11, and column three is n=8.** The arriving
population is the eight `_archive/*/download/original/` extracts plus the three
`review_tasks/*/download/original/` ones, which are arriving bundles as much as the archived ones.
Column three is a different population, the `_archive/*/work/` trees, so do not read eleven into it.

**Archived peer reviews are kept out of both globs by their path, and that is deliberate** (added
2026-08-18). A review's `work/` is a copy of **another EC's submitted bundle**, so it is not "what a
submitter here shipped" and must never join column three. Section 13 F6 therefore archives a review
to `_archive/reviews/<name>/`, one level deeper than a task, so `_archive/*/work/` and
`_archive/*/download/original` cannot match it. Column **two** is the opposite case and wants them:
a review's `download/original` is an arriving bundle like any other, which is why the loop below
already globs `review_tasks/*/download/original`, so the archived form is added there explicitly.
One caveat on column three: libcrux 1165 is a Path C submission that shipped **no bundle at all**, so
its `work/` numbers record what the submitter prepared rather than what a reviewer accepted. **Both
counts move every time a task is archived**, which is the whole reason they keep going stale - re-run
the loop below rather than trusting the numbers above. cista 172 is the outlier in three of the rows
and mithril.js 2021 in two more, and cista is the oldest of the eleven: its pristine `task.toml` is
stamped 2026-07-17 and the other ten are 2026-07-22 or later, the newest 2026-08-09. That closes off the "an
older generator produced it" reading, which is the first thing to check before calling an outlier a
defect.

**The five real-finding rows split into three kinds and they are worded differently.** `os` and
`difficulty_explanation` are **not** "the submitter broke this". `os` arrives absent in all eleven and
`difficulty_explanation` in ten of the eleven, so the true sentence names the arrival rather than the
submitter: "this arrives absent in nearly every bundle, the submitters who cleared review added it, and
this one did not". Word them that way,
or a submitter checks their own diff, finds they never touched the field, and stops trusting the page.
`network_mode` and `allowed_hosts` are different in kind: `docs/harbor-framework.md` prescribes both
values by name, so they stand on the documented rule and the baseline is only corroboration. The
timeout pair is both at once, which is why it left the not-a-finding group on 2026-08-14.
`docs/reviewer-rubric.md:101` makes it a documented Minor violation, so it stands on the rule like the
last two, and it still arrives mismatched in 10 of the 11, so it gets the arriving-default wording like
the first two. The rubric calls the finding mechanical and asks for both numbers, so name them: "the
bundle ships `[verifier] timeout_sec = 300` against `execution.timeout_sec = 1800`, the value it
arrives with, and it was not corrected."

**On the submitter path this is a fix now, not a line in Comments for Reviewer.** `docs/reviewer-rubric.md:101`
says a verifier timeout shorter than the task's own configured timeout can kill valid solutions early.
Decide from the measured oracle wall time in the Step 5.5 battery, then either raise `[verifier] timeout_sec`
to cover the execution budget, up to the documented 1800 ceiling, or bring `execution.timeout_sec` under it.
Both routes have been accepted: elfuse 162 shipped 1200 against 900, and statrs 315 left `[verifier]` at 300
and dropped `execution` from 1800 to 240.

```bash
for d in _archive/*/download/original _archive/reviews/*/download/original review_tasks/*/download/original; do
  [ -f "$d/task.toml" ] || continue
  echo "== $d"
  grep -nE '^\s*os\s*=|^\s*difficulty\s*=|difficulty_explanation|timeout_sec|model_difficulty|network_mode|allowed_hosts' "$d/task.toml"
  python3 -c "import json;print('  execution.timeout_sec',json.load(open('$d/tests/config.json'))['execution']['timeout_sec'])" 2>/dev/null
done
```

**Legacy `model_difficulty` vs `difficulty` - report it, do not quietly reconcile it.** On the
**submitter** path this stays a metadata accuracy note worth a line in Comments for Reviewer. On the
**reviewer** path it is not a finding at all, on the baseline above: it arrives that way in 9 of the 11
arriving bundles, and six of the seven accepted bundles carrying the mismatch shipped it unchanged. **The seventh is the measured exception and it settles the escape hatch two sentences below.** hulak 118's round-1 peer reviewer named the stale pair as a Metadata Issue and asked directly for both fields to read medium; the submitter complied, said so in Files Changed, and the task was accepted. So a reviewer asking is a real event with a known outcome, not a hypothetical. Neither field is in the current schema; both only survive on older tasks. When they contradict each other (`model_difficulty = "medium"` against `difficulty = "hard"`), that is a metadata accuracy finding worth naming in Comments for Reviewer, and a reviewer may well ask for them to agree. It is still not licence to edit a difficulty field to satisfy a check or a linter - `docs/faq.md` is explicit that the fix for that conflict is escalation, not tuning. If a reviewer asks directly for the fields to be aligned, do it, and say in Comments for Reviewer that the change came from their note.

`[environment] os` is a documented field (`docs/harbor-framework.md`) and appears in the reference `task.toml`. A bundle missing it is a metadata finding.
