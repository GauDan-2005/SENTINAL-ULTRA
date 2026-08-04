---
id: ledger
status: locally-verified
last_verified: 2026-08-04
verified_by:
  - 20260719_045042__oliver-oloughlin_kvdex__245
  - 20260723_030109__cryspen_libcrux__1165
  - 20260727_135618__AltBeacon_android-beacon-library__1177
  - 20260728_153118__jqno_equalsverifier__1166
evidence: "Every retraction already recorded inside a note body or a task.md, collected in one place"
applies_to:
  languages: [any]
  runners: [any]
  phases: [all]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts: []
---

# Ledger of refuted and superseded claims

Things this workspace believed, acted on, and then disproved. Each row says what was believed,
why it was believable, what refuted it, what replaced it, and what it cost.

**Why this file exists.** All of these were already retracted somewhere, inside a note body or
a `task.md` revision section. That is not enough. A refutation buried on line 180 of a 594-line
note gets skimmed past, and the wrong idea comes back looking new. The single most expensive
failure this workspace has recorded is shipping a design that had already been refuted.

**The rule for adding a row.** When a note's `status` is flipped to `refuted` or `superseded`,
or a claim inside a note is retracted, the same edit adds the row here. A retraction in prose
with no ledger row is an incomplete edit.

Read the table. The detail under it is only for the rows you are about to re-derive.

| # | Date | The claim | Refuted by | Replaced with | Cost |
|---|---|---|---|---|---|
| L1 | 2026-08-02 | Restoring the test tree with `git checkout -- tests/` plus `git clean` makes `tests.patch` apply after an agent edits the tests | kvdex 245 round 4 difficulty check: **16 of 16** trials invalid, worse than the 13 of 16 with no restore at all | Nothing git-based. See L3 | 1 round |
| L2 | 2026-08-03 | `rm -rf tests` then `git checkout <base sha> -- tests` fixes what L1 could not, because it reads a commit rather than the index | kvdex 245 round 5: **15 of 16** invalid. Flat across two different correct fixes | Nothing git-based. See L3 | 1 round |
| L3 | 2026-08-02 | Deleting each module test dir and checking it out from the base commit SHA is the durable restore | equalsverifier 1166 round 2: harness failures continued. The verify-time workspace **is not a git repository**, so every git-based design is a no-op there | A gzipped tarball of the base test tree, base64-encoded inside `test.sh`. Accepted on kvdex round 6, first time | 1 round, plus the two above |
| L4 | 2026-08-02 | The restore archive can ship as `tests/files/base-test-tree.tar.gz` | equalsverifier 1166 round 2 upload rejected at the static phase. `tests/` accepts exactly `config.json`, `grade.py`, `test.sh`, `tests.patch` | Payload embedded in `test.sh` itself | Half a round, caught before the evals |
| L5 | 2026-08-03 | The non-idempotent `solve.sh` reverse-apply fallback was the **cause** of a platform `Oracle did not pass all runs: 0/3` | The 0/3 survived the fix on android-beacon 1177. The defect is real and reproduced; the causal claim was not | The defect stands on its own merits. The 0/3 needs its own diagnosis | 0 rounds, but it misdirected a search and put a false sentence in Comments |
| L6 | 2026-08-04 | equalsverifier 1166 has its graded ids concentrated in the patched test files, so a create-only `tests.patch` is enough | Measured on the shipped bundle: **1124 of 1223** graded ids live outside the patched files. Only `fail_to_pass` is concentrated, at 0 of 19 | Count `pass_to_pass` too. Over zero means the full-tree payload | 0 rounds. It would have shipped 1124 unguarded ids |
| L7 | 2026-08-04 | The which-restore-shape one-liner works on any task | It splits ids on `::`. JUnit ids are `ClassName#method` and cargo, Go and Jest ids carry no path, so it reports every graded id as outside the patched files | An id-shape-aware version handling `::` and `#`, plus resolving by hand when the id scheme and the patched paths share no namespace | 0 rounds, one wrong measurement |
| L8 | 2026-08-02 | Q9 navigation is cleared by stating placement relative to a class that already exists at the base commit | equalsverifier 1166 round 2 failed Q9 again and quoted the replacement wording | There is no safe phrasing for placement. Delete it and let the tests' imports rest on repo convention | 1 round |
| L9 | 2026-08-04 | A `tests.patch` that adds only brand-new files does not need a restore step, because a create has no context to conflict with | android-beacon 1177 finding 6: `error: ... SettingsTest.kt: already exists in working directory`. A create conflicts with a file the agent wrote itself | Restore the tree first on every task, whatever shape the patch is | 0 rounds here, caught locally. It is what L1 to L3 cost elsewhere |
| L10 | 2026-08-04 | libcrux 1165's NOP is 0 because the graded file compiles to zero tests at base | Re-verification: stdout is **zero bytes** and `raw_exit_code` 101. The build tool rejects the feature flag on the command line before compiling anything | A third NOP-looks-healthy mechanism, earlier than a collection abort. Read the log length, not just the reward | 0 rounds, one false sentence in an answer that was corrected |
| L11 | 2026-07-31 | `fail_to_pass` needs at least 10 tests, per `docs/guidelines.md` and the form's "more than 10" checkbox | kvdex 245 round 1 static check: `grading.fail_to_pass lists 22 test(s), outside the 10–20 range`, build failed | A hard 10 to 20 range. Target 11 to 20 and regroup rather than delete when a rewrite overshoots | 1 round |
| L12 | 2026-08-04 | `tests.patch` must only add new files and must never touch a pre-existing test file (retired `Sentinel_CLAUDE.md`) | kvdex 245 was **accepted** with `tests.patch` modifying 44 pre-existing test files | What must stay byte-identical is the pre-existing test files **in the shipped repo at the base commit**. The patch is how graded tests arrive, and it may edit them | 0 rounds. It would have blocked the design that got accepted |
| L13 | 2026-08-04 | Set `allow_extra_failures: false` on every task (retired `Sentinel_CLAUDE.md` pre-upload checklist item 6) | The field is undocumented in `docs/`, and `false` breaks a run whose executed set is not exactly the graded set, such as Deno `t.step` regrouping | Set it to `false` only when the shipped `config.json` already carries the field and the run executes exactly the graded set. Never add it to a config that lacks it | 0 rounds |
| L14 | 2026-08-04 | Align the `task.toml` difficulty fields to whatever the Difficulty Check returned (retired `Sentinel_CLAUDE.md`) | `docs/faq.md` and `CLAUDE.md` section 8 both forbid hand-editing difficulty or pass-rate metadata to satisfy a check. The linter and the measured value pull in opposite directions | Report the mismatch in Comments for Reviewer and escalate the linter conflict with the UID. Change it only if a reviewer asks directly, and say so | 0 rounds |
| L15 | 2026-08-04 | Delete the downloaded platform zip once the extract is confirmed (retired `Sentinel_CLAUDE.md`) | `CLAUDE.md` keeps it at `tasks/<name>/download/<submission_id>_submission.zip`, and it is what `download/original/` gets re-extracted from when a filesystem move damages the reference tree | Keep the platform zip for the life of the task | 0 rounds. It would have cost the libcrux symlink repair its reference |
| L16 | 2026-08-04 | `problem_statement.md` sits at the bundle root beside `instruction.md` (retired `Sentinel_CLAUDE.md`) | Current spec puts the copy at `task/environment/problem_statement.md`. Older bundles keep the root copy, and some ship both | Diff whichever one ships. If both exist, all three files must be byte-identical | 0 rounds |
| L17 | 2026-08-04 | This workspace lives on ntfs3, so bulk deletes are dangerous and one at a time | `df -Th` on 2026-08-04: the tree is on `/dev/nvme0n1p5`, **ext4** | The NTFS hazards in `local-runs.md` are history for this workspace. Check the mount before assuming either way | 0 rounds, but the earlier hazard cost a wedged round on libcrux |

## The rows worth reading twice

### L1 to L3: the git restore, three designs, three rounds

Four restore designs went through the platform's difficulty check on kvdex 245, same repo, same
error text every time:

| Round | `test.sh` restore | Invalid trials |
|---|---|---|
| 3 | none | 13 of 16 |
| 4 | `git checkout -- tests/` + `git clean -fdq tests/` | 16 of 16 |
| 5 | `rm -rf tests` + `git checkout <base sha> -- tests` | 15 of 16 |
| 6 | base64 payload of the base test tree, embedded in `test.sh`, no git | **passed, accepted** |

Every git-based design passed every local scenario that could be constructed, and none of them
moved the platform number. The flat line across rounds 4 and 5 was the signal, and it was
available for free at the end of round 4.

Read the trend before designing the next fix. Two locally-verified fixes that do not move the
number mean neither touched the cause, and the third variation of the same idea is the same trap.
Full account in [tests-patch-vs-agent-edits.md](tests-patch-vs-agent-edits.md) and
[diagnosing-platform-only-failures.md](diagnosing-platform-only-failures.md).

### L12 to L16: the retired manual

`Sentinel_CLAUDE.md` was the predecessor to `CLAUDE.md` and it sat at the workspace root until
2026-08-04, when it was moved to `_archive/superseded/`. It carried real lessons, which are now
in [peer-review-bounces.md](peer-review-bounces.md), and it carried these five claims, which
`docs/` or a measured result contradicts. It also cited two rule files that do not exist in this
workspace (`humanizer-output.mdc`, `sentinel-form-answers.mdc`) and a directory layout from a
different machine.

The general shape is worth noticing. None of the five is absurd. Each was a reasonable rule that
either predates a spec change or was over-generalised from one task. That is what makes a
retired manual dangerous rather than merely stale: it reads as authoritative and it is
specifically wrong on the points where the workspace has since learned something.

### L5 and L10: the two false causes

Both are the same error at different scales. A real defect was found, it was near the symptom,
and it was written up as the cause without a measurement that separated the two. L5 put the
blame for an `Oracle 0/3` on a reverse-apply fallback that was genuinely broken and genuinely
not responsible. L10 explained a NOP reward of 0 with a compile story, when the log was zero
bytes and nothing had run at all.

The check that catches both takes one command. Before writing "X caused Y", remove X and see
whether Y persists.
