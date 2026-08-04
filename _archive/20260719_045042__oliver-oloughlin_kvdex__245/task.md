# 20260719_045042__oliver-oloughlin_kvdex__245

| Field | Value |
|---|---|
| Submission id | 05589b6f-39f7-4db3-8916-dd9ccdd69963 |
| Repo / PR | oliver-oloughlin/kvdex PR 245 (Release/3.0.0) |
| Category | evolution_and_maintenance / migration |
| Difficulty | hard |
| Language | TypeScript (Deno) |
| Verdict | **Fixable** |
| Status | **ACCEPTED 2026-08-04** on round 6. See the closing section at the end of this file |
| Claimed | 2026-07-31 |
| Closed | 2026-08-04 |

Platform data block is in `task_details.md`. Form answers are in `answers/submission_answer.txt`.

## Local check results

Run against the exact bundle in `upload/`, airgapped, at the declared `cpus=4 / 8 GB`.

| Check | Reward | Required tests | Suite | Time |
|---|---|---|---|---|
| NOP | 0 | 0 of 132 | does not run, encoding module absent | 4 s |
| Oracle | 1 | 132 of 132 | 152 pass, 0 fail | 158 s of 900 s |

fail_to_pass 20, pass_to_pass 112.

## Platform check history

| Round | Phase | Result |
|---|---|---|
| 1 | Static checks | FAIL, `fail_to_pass` listed 22, outside the hard 10 to 20 range |
| 2 | Static checks | pass |
| 2 | Prescriptiveness | FAIL, score 0.25, 4 findings (2 high, 2 medium) |
| 3 | Static + prescriptiveness | pass |
| 3 | Difficulty | **INCOMPLETE** — 13 of 16 agent trials invalid, `tests.patch did not apply` |
| 3 | Oracle 3/3, NOP 0/1, Quality judge | pass, status OK |
| 4 | pending | rebuilt with the harness fix below |

## Revision 2, after the difficulty bounce

**The blocker.** 13 of 16 trials died with
`patch failed: tests/collection/enqueue.test.ts:16`. Every local check was green, because
the fault only appears once an agent has been in the repo. `tests.patch` rewrites
`kvdex(kv, {...})` into `kvdex({ kv, schema })` in 40 existing test files, and any agent
doing the migration edits those same call sites, since the visible suite stops compiling
otherwise. The patch then conflicts and the trial is scored invalid rather than on merit.

Reproduced locally byte for byte by applying `golden.patch`, `sed`-ing one line of
`tests/collection/enqueue.test.ts`, and running `test.sh`.

Fixed in `tests/test.sh` by restoring the test tree immediately before applying the patch:

```bash
git checkout -- tests/ && git clean -fdq tests/
```

The agent's copy of the tests can no longer influence grading, which also closes a
test-gaming route. Verified across three scenarios:

| Scenario | Before | After |
|---|---|---|
| NOP | 0 | 0, 0 of 132 |
| Oracle, clean tree | 1 | 1, 132 of 132 |
| Oracle + agent rewrote the tests | infra error, 0 | **1, 132 of 132** |

**Agent timeouts.** 3 of 8 opus trials hit `[agent] timeout_sec = 1800`. Not blocking, but a
timed-out trial gives no difficulty signal. Raised to the 7200 maximum per `docs/faq.md`.

**test_faithfulness, adjudicated 3.5.** GPT flagged that `tests/db/atomic.test.ts` adds
assertions about atomic overwrite and about throwing on indexable overwrite, which the
instruction never mentions. Confirmed: `golden.patch` really does add that logic, and
`tests/db/atomic.test.ts::db - atomic` sits in the graded set, so a perfect encoder
migration would still fail it. Removed the two unrelated steps from `tests.patch`. The file
keeps only its `kvdex({...})` migration change, which the instruction does describe.

**test_coverage, adjudicated 3.5.** GPT was right that the custom-compressor test proved
nothing: a byte-reversing compressor round-trips fine even if the collection ignores both
`compress` and `decompress`. The compressor now counts invocations and the test asserts both
were called. Also added the two unasserted requirements GPT named: `KvdexOptions` is now
used as a type, and a check that the serialization helpers are no longer exported from
`mod.ts`.

**Packaging, adjudicated 3.0.** GPT scored 1 on `environment/repo/.vscode/settings.json`
shipping into the image. Left alone deliberately: `git ls-files` shows it tracked upstream at
the base commit, so removing it would mean editing tracked repo files and shipping a dirty
tree. Claude scored the same axis 5 for that reason. Documented rather than changed.

Both failures are written up in `learning/static-checks.md` and
`learning/prescriptiveness-check.md`.

## What changed from the downloaded bundle

1. `instruction.md` rewritten as a maintainer memo. Corrected a false claim about the base
   API, removed file location hints, the verifier note, the two node built-ins it named and
   the internal brotli filename.
2. `environment/problem_statement.md` re-copied to match, md5 `f41023e5e982`.
3. `tests/tests.patch` regenerated. Restored `tests/test.deps.ts`, reverted 150 files to
   their original imports, added 4 new top-level tests, repointed `brotliCompressor` to the
   public barrel. 158 files down to 45, modified pre-existing test files 157 down to 40.
4. `tests/config.json` fail_to_pass 16 to 20, pass_to_pass empty to 112.
5. `task.toml` verifier timeout 300 to 900, added `os` and `difficulty_explanation`.
6. `environment/repo/.git/` hygiene. No tracked source file touched.

Solution untouched, so the PR scope is unchanged.

## Open items

- Total submission time in the answers reads 10 minutes, which is below both the 30 minute
  review and the 150 minute rewrite. Needs a real number from the submitter.
- `model_difficulty = "medium"` contradicts `difficulty = "hard"` in `task.toml`. Left alone
  per the FAQ rule against hand editing difficulty metadata. Flagged to the reviewer.

---

# Revision 3 — 2026-08-02

Round 4 upload result. Source: platform automated feedback, pasted by the submitter.
Note: the submitter first filed this feedback against the equalsverifier folder. Every path
in it (`tests/collection/enqueue.test.ts`, `src/ext/encoding`, `brotliCompressor`,
`kvdex({kv, schema})`, `source_pr_url` = kvdex#245) belongs to this task, and the misfiling
was corrected before any edit was made.

## Feedback, verbatim

### Automated feedback

Agent Runner Summary: Evaluation FAILED. Rubric panel judge: DISCUSS (NEEDS_REVISION)

Agent Runner Summary: Evaluation FAILED. Difficulty check incomplete (not a difficulty verdict): claude-opus-4-8: only 0/8 valid trials (8/8 invalid: 8x harness failure: tests.patch did not apply (error: patch failed: tests/collection/enqueue.test.ts:16; error: tests/collection/enqueue.test.ts: patch does not apply)); codex-gpt-5-5: only 0/8 valid trials (8/8 invalid: 8x harness failure: tests.patch did not apply (error: patch failed: tests/collection/enqueue.test.ts:16; error: tests/collection/enqueue.test.ts: patch does not apply)). See the difficulty check summary for what the invalid trials mean and how to proceed.

### Difficulty Check

Difficulty run incomplete — infra or harness failures left the verdict untrustworthy: claude-opus-4-8: only 0/8 valid trials (8/8 invalid: 8x harness failure: tests.patch did not apply (error: patch failed: tests/collection/enqueue.test.ts:16; error: tests/collection/enqueue.test.ts: patch does not apply)); codex-gpt-5-5: only 0/8 valid trials (8/8 invalid: 8x harness failure: tests.patch did not apply (error: patch failed: tests/collection/enqueue.test.ts:16; error: tests/collection/enqueue.test.ts: patch does not apply))

What the invalid trials mean and how to proceed:

- Harness failure — the task's own test harness broke before any test ran (the reason above comes from your task's verifier, e.g. tests.patch did not apply). This is a problem in the task itself: the reference (oracle) runs all passed, so tests.patch applies cleanly over the reference solution — it failed only after an agent's own edits, which means its diff context very likely overlaps files agents may modify. Testing on a fresh checkout will not reproduce this. Rework tests.patch so it does not depend on solution-code context (add new test files, or touch only dedicated test files agents are told not to change), then resubmit.

Difficulty: PASS HARD

Status: Some tests not passed by any agent run (not blocking; require_solvable disabled)

Agent Performance:

- claude-opus-4-8: 0.0% (0/8 runs) [8 invalid: 8x harness failure: tests.patch did not apply (error: patch failed: tests/collection/enqueue.test.ts:16; error: tests/collection/enqueue.test.ts: patch does not apply)]
- codex-gpt-5-5: 0.0% (0/8 runs) [8 invalid: 8x harness failure: tests.patch did not apply (error: patch failed: tests/collection/enqueue.test.ts:16; error: tests/collection/enqueue.test.ts: patch does not apply)]

Reference Agents:

- nop: 0.0% (0/1 runs)
- oracle: 100.0% (3/3 runs)

Analysis on Agent Failures:

- Task Instruction Sufficiency: NOT_APPLICABLE, Harbor analyze did not include any results.

### Agentic Judge Quality Report

Status: DISCUSS. Reason: coverage_gap.

Per-axis (rating out of 5):

| Axis | Adjudicated | claude | gpt |
|---|---|---|---|
| clarity | 4.5 | 5 | 4 |
| oracle_no_gaming | 5.0 | 5 | 5 |
| oracle_robustness | 4.0 | 4 | 4 |
| oracle_spec_faithfulness | 3.5 | 5 | 3 |
| packaging | 3.0 | 5 | 1 |
| prescriptiveness | 4.5 | 3 | 5 |
| realism | 5.0 | 5 | 5 |
| self_containedness | 5.0 | 5 | 5 |
| **test_coverage** | **3.0** | 5 | 3 |
| test_faithfulness | 5.0 | 5 | 5 |

Driving judge rationale, verbatim:

> The suite is broad, with required tests for the new encoder factories/module surface and many serialized collection/indexable operations listed in [tests/config.json:166-187] and [tests/config.json:258-300]. However, an explicitly named indexable secondary-order update-many behavior from the prompt's "updating one, many or by id" plus "secondary index and secondary order variants" requirement [instruction.md:40-42] is left as `Deno.test.ignore` for `serialized_indexable_collection - updateManyBySecondaryOrder` [tests/tests.patch:3121-3124], and the value fixture deliberately removes `Float16Array` despite the prompt requiring JSON/V8 to cover "the other typed arrays" [instruction.md:25-27] [tests/tests.patch:3356-3388]. The suite also runs extra tests but allows extra failures [tests/config.json:302-309], so non-required failures do not close these gaps.

Other gpt justifications that name a defect:

- oracle_spec_faithfulness (3/5): "the JSON implementation serializes only `RegExp.source` and reconstructs without flags [solution/golden.patch:1605-1610] [solution/golden.patch:1784-1787], and it leaves Float16Array support as a TODO / removes it from the value schema [solution/golden.patch:1688-1695] [solution/golden.patch:2446-2452]"
- packaging (1/5): "`_DIRECTORY_LISTING.txt` includes an IDE artifact, `environment/repo/.vscode/settings.json` ... the Dockerfile copies the entire `repo/` directory into `/app`, so that `.vscode` file ships into the agent-readable runtime filesystem"
- oracle_robustness (4/5, both judges): "the final fallback reverse-applies the patch if normal application fails [solution/solve.sh:6-9], so rerunning in an already-patched checkout could undo the solution rather than no-op"
- prescriptiveness (claude 3/5): "[instruction.md:23] prescribes internal file layout (per-encoder mod.ts barrel directories), [instruction.md:29] fixes the brotli quality default to 1, and [instruction.md:19] specifies the exact rename and exported type name KvdexOptions"

Verdict logic: only the two test axes flip the verdict, and `test_coverage` adjudicated
3.0 hits the DISCUSS rule ("adjudicated score on either axis is ≤ 3.0"). Everything else
above is advisory.

## Findings and what was done

**1. The round-2 restore step was defeated by staged and committed agent work. The blocker.**
`git checkout -- tests/` restores the working tree from the INDEX, not from a commit. An
agent that ran `git add` before finishing has already put its own version there, so the
restore is a silent no-op. That is why round 3 was 13 of 16 invalid and round 4 got *worse*
at 16 of 16, with the same error to the character.

Reproduced in the task's own image, four runs, only the agent's git behaviour varying:

| agent behaviour | old restore | new restore |
|---|---|---|
| edits left unstaged | reward 1, 132/132 | reward 1, 132/132 |
| `git add -A` | **0, patch did not apply** | reward 1, 132/132 |
| `git commit` | **0, patch did not apply** | reward 1, 132/132 |
| committed + wrote its own `tests/ext/encoder.test.ts` | **0** | reward 1, 132/132 |

The last row is why checking the base commit out over the top is not enough on its own:
`git checkout <sha> -- tests/` only writes files present in that tree and leaves anything the
agent added. The directory has to go first. `tests/test.sh` now does `rm -rf tests` then
`git checkout <base sha> -- tests`, with the base commit pinned in the script (which lives in
`/tests`, mounted read-only, never visible to the agent), and raises a hard infra error if
the restore itself fails rather than grading on a tree it could not reset.

Written back to `learning/tests-patch-vs-agent-edits.md`, whose unstaged-only simulation is
exactly what made the round-2 fix look verified.

**2. The coverage gap is the instruction over-promising, not the oracle under-delivering.**
Pulled all 198 changed files of PR 245 through the GitHub API and checked each judge claim:

- **Float16Array.** The PR itself disables it, with the same `// TODO:` markers, across
  `src/ext/encoding/json/utils.ts`, `src/ext/zod/schemas.ts`, `src/types.ts`, `src/utils.ts`
  and `tests/values.ts`. The oracle mirrors it exactly. Re-adding it would be reducing and
  replacing PR behaviour.
- **`updateManyBySecondaryOrder`.** Already `Deno.test.ignore` at the base commit in both
  files, and the `// TODO: fix update document deleting indices ...` line is the PR's own.
  Our `tests.patch` adds nothing else there. Neither id is in `fail_to_pass` or
  `pass_to_pass`, and the runner reports them as `2 ignored`, so they emit neither PASS nor
  FAIL.
- **RegExp flags.** `[TypeKey.RegExp]: value.source` is pre-existing at `src/utils.ts:917`;
  the PR relocates it verbatim. The fixture is `new RegExp("[0-9]")`, no flags, so nothing is
  actually mis-asserted.

So the fix is in `instruction.md`. The JSON paragraph no longer claims "every value type Deno
KV supports ... and the other typed arrays" and now says existing gaps carry over; the
indexable sentence now asks for "the secondary index and secondary order operations the
library ships working today". Both requirements the judge scored against are gone as
*requirements*, with no change to PR scope and no graded assertion weakened, so
`test_faithfulness` stays at 5.0.

**3. `allow_extra_failures` was true.** The judge's third point. Now false. Verified safe:
the oracle run reports 152 pass, 0 fail with 0 unexpected failures, so the 20 ungraded
top-level tests all pass.

**4. The grader was fail-open, demonstrated on this bundle.** The NOP run reported
`raw_exit_code = 0` with zero tests run. The configured command is a pipeline and
`/tmp/run_tests.sh` executes in a child bash that does not inherit this script's `pipefail`,
so the captured status was the parser's. Reward was still 0, but only because the
required-test check caught it. Fixed by running the generated script with `bash -o pipefail`
and downgrading any reward of 1 that contradicts a nonzero test-command status. Measured
first: deno exits 0 on a green graded tree (`ok | 152 passed (500 steps) | 0 failed |
2 ignored`), so the gate cannot fire on a correct solution. Only ever downgrades.

**5. `solve.sh` reverse-apply fallback.** Both judges flagged it at `oracle_robustness` 4/5,
and `CLAUDE.md` 10.6 prescribes the fix. A second run on an already-patched tree used to
revert the solution. Now forward-only and idempotent: apply, no-op if already applied, fail
on anything else.

**6. Script modes.** `tests/test.sh` and `solution/solve.sh` shipped 644 in the uploaded zip.
Both sibling tasks were fixed rounds ago; this one was missed. Now 755.

## Local check results, revision 3

Against the edited bundle, airgapped, at the declared `cpus=4 / 8 GB`.

| Check | Reward | Required | Suite | Time |
|---|---|---|---|---|
| NOP | 0 | 0 of 132 | 0 reported, encoding module absent | 4 s |
| Oracle | 1 | 132 of 132 | 152 pass, 0 fail, 2 ignored | 138 s of 900 s |
| Hostile delete, brotli default 1 to 6 | **0** | 131 of 132 | `ext - brotliCompressor` fails | — |

NOP checked for the right reason, not just the number: no fail-to-pass test passes at base,
and the run did not abort collection.

## Not changed, and why

- `environment/repo/.vscode/settings.json`, the gpt packaging 1/5. `git ls-files` shows it
  tracked upstream at the base commit, so removing it means editing tracked repo files and
  shipping a dirty tree. Claude scored the same axis 5 for that reason.
- `model_difficulty = "medium"` against `difficulty = "hard"`. FAQ rule against hand-editing
  difficulty metadata.
- The three residual `prescriptiveness` findings, all pinned by graded tests: `KvdexOptions`
  is imported as a type and used, the brotli `quality` default of 1 is asserted by byte
  comparison against an explicit `{quality: 1}`, and the per-encoder barrels are imported as
  `jsonBarrel` / `v8Barrel` / `brotliBarrel`. Cutting them trades a 4.5 advisory axis for a
  blocking `test_faithfulness` one.
- The 40 modified pre-existing test files. Unavoidable on a breaking API migration, and the
  hardened restore now removes the risk they carried.

## Files changed this round

| File | Change |
|---|---|
| `tests/test.sh` | restore hardened to `rm -rf tests` + checkout from the pinned base commit, with a hard infra error if it fails; runner under `bash -o pipefail`; reward 1 downgraded when the test command exited nonzero; mode 644 to 755 |
| `instruction.md` | JSON value-type claim and the indexable secondary-order sentence narrowed to what PR 245 ships |
| `environment/problem_statement.md` | re-copied, md5 `831ced9511d5` |
| `tests/config.json` | `allow_extra_failures` true to false |
| `solution/solve.sh` | forward-only and idempotent, reverse-apply fallback removed; mode 644 to 755 |

`solution/golden.patch` and `environment/Dockerfile` untouched. No tracked source file inside
`environment/repo` touched. PR scope unchanged. `diff -rq download/original work -x .git`
lists exactly seven files, all intended.

## Packaging, revision 3

Git hygiene run last, immediately before zipping. `.git` contains exactly `config description
HEAD hooks index info objects packed-refs refs`, `git fsck --unreachable` prints nothing,
both patches still apply at base, HEAD equals the base commit, no remotes, no refs past HEAD,
clean tree, 1.6 MB.

Zip rebuilt with `zip -rX` into `upload/`. 309 entries, 1.7 MB, unpacks to `environment/`,
`instruction.md`, `solution/`, `task.toml`, `tests/` with no `runs/` and no `task/` wrapper.
`.git/refs/` and `.git/refs/heads/` both present, no `.git/logs`, `FETCH_HEAD` or `ORIG_HEAD`,
both scripts 755.

All 20 static checks simulated against the **extracted zip**, not the working copy: pass.

## Open

- Handling times: 90 review, 150 rewrite, 20 form, total 260, revisions 195 as of revision 4.
  The total is **above** the 180 to 240 band, by the submitter's decision, and the reason is
  stated in Comments for Reviewer. The revision figure is also above the 60 to 120 band this
  workspace targets, chosen by the submitter after three rounds. Worth a sentence to the
  reviewer if either is ever queried.

---

# Revision 4 — 2026-08-03

Round 5 upload result, on the bundle built 2026-08-02 15:44 with the hardened git restore.
Submitter confirmed that is the zip that ran.

## Feedback, verbatim

Agent Runner Summary: Evaluation FAILED. Difficulty check incomplete (not a difficulty verdict): claude-opus-4-8: only 1/8 valid trials (7/8 invalid: 7x harness failure: tests.patch did not apply (error: patch failed: tests/collection/enqueue.test.ts:16; error: tests/collection/enqueue.test.ts: patch does not apply)); codex-gpt-5-5: only 0/8 valid trials (8/8 invalid: 8x harness failure: tests.patch did not apply (error: patch failed: tests/collection/enqueue.test.ts:16; error: tests/collection/enqueue.test.ts: patch does not apply)). See the difficulty check summary for what the invalid trials mean and how to proceed.

Difficulty: PASS HARD. Status: Some tests not passed by any agent run (not blocking; require_solvable disabled).

Agent Performance:
  - claude-opus-4-8: 100.0% (1/8 runs) [7 invalid: harness failure, tests.patch did not apply]
  - codex-gpt-5-5: 0.0% (0/8 runs) [8 invalid: same]

Reference Agents: nop 0.0% (0/1), oracle 100.0% (3/3).

Analysis on Agent Failures: Task Instruction Sufficiency: NOT_APPLICABLE, Harbor analyze did
not include any results.

## Round history, so the trend is visible

| Round | `test.sh` restore | Invalid trials |
|---|---|---|
| 3 | none | 13 of 16 |
| 4 | `git checkout -- tests/` + `git clean` | 16 of 16 |
| 5 | `rm -rf tests` + `git checkout <base> -- tests` | 15 of 16 |

Three rounds, three results in the same band. **A git-based restore has never measurably
worked on this platform**, while every one of them passed every local scenario I could build.

## Correcting revision 3's diagnosis

Revision 3 concluded the mechanism was agents staging or committing, because
`git checkout -- <path>` reads the index. That defect is real and the measurements were
sound, but it is **not** what the platform was hitting.

Evidence, from the agent session transcripts in `logs_artifact.zip` (12 transcripts, round 3):

- `.git` **is present** in the agent's `/app`. Agent `ls -la` output shows it directly, so a
  missing git store is not the story either.
- Across all 12 transcripts the only git command any agent ran is a single `git ls-files`.
  **No agent staged or committed anything.** So the index-versus-commit distinction that
  revision 3 turned on could not have been the deciding factor for those trials.

That leaves a restore step that does not take effect at verify time for a reason not
observable from here. Rather than build a fourth git-based theory, the restore now does not
use git at all.

## What was measured this round

| Scenario | Result |
|---|---|
| agent edits tests, `.git` removed before verify | **reproduces the platform error exactly**: `patch failed: tests/collection/enqueue.test.ts:16`, `patch does not apply`, infra error, reward 0 |
| agent commits on an orphan branch then `gc --prune=now` | restore still works, reward 1, 132 of 132. The base object survives, so a pruned object store is not the mechanism |

The first row is a sufficient explanation for the observed failure and it is the only
condition I could construct that reproduces it byte for byte. It is not proof that the
platform's workspace lacks git, and the fix does not depend on that being true.

## The fix: stop depending on git

`tests/test.sh` now deletes `tests/` and restores it from an archive of the tests exactly as
they exist at the base commit.

Why this is reliable where git was not: **`test.sh` is itself read from `/tests`**, so `/tests`
is guaranteed mounted or nothing runs at all. A restore sourced from there is exactly as
reliable as the verifier entrypoint. It cannot be defeated by staging, by commits, by a
missing or pruned `.git`, or by an agent creating a file where `tests.patch` adds one, because
the directory is deleted first.

### Where the archive lives, after the static check rejected the first answer

The first attempt shipped it as `tests/files/tests_base.tar.gz`. **The static check rejected
the upload:**

```
❌ tests: unexpected entry in tests/: files (allowed: config.json, grade.py, test.sh, tests.patch)
```

`tests/` accepts exactly four filenames and no subdirectories. `CLAUDE.md` Section 7 and the
Harbor layout both listed `tests/files/` as valid, so this is documented-structure drift and
is now written up in `learning/static-checks.md`, with Section 7 corrected.

The payload therefore lives **inside `test.sh`**, base64'd into a quoted heredoc and decoded
to `/tmp` at run time. `test.sh` is an allowed entry, has no size limit, and keeps the whole
reliability argument intact. 158 files and 904 KB of tests compress to a 52 KB archive, 70 KB
of base64, and a 93 KB `test.sh`. Verified to round-trip out of the built zip: 158 files,
byte-identical to `environment/repo/tests`. It leaks nothing, because that is the tree the
agent already has in its checkout.

### Why the whole tree, and not the cheaper create-only patch

`learning/static-checks.md` documents a lighter fix that needs no payload: regenerate
`tests.patch` so every graded file is a create rather than a diff, then delete those paths
first. A create has no context lines, so nothing can conflict. It is verified on
equalsverifier and it is the better answer there.

It does not fit this task. Measured on the current bundle:

```
102 of 132 graded ids live in files tests.patch does not touch
```

`pass_to_pass` is 112 regression guards spread across the suite while only 45 files are
patched. A create-only patch would leave those 102 running the agent's own copies, which is
the test-gaming route the revision 2 Quality Check round specifically asked me to close. So
the whole tree gets restored. The measurement is in `learning/tests-patch-vs-agent-edits.md`
so the choice is made by counting rather than by assuming one task's answer transfers.

## Also fixed this round

The revision 3 fail-closed gate wrote an `infrastructure_error`, which `CLAUDE.md` 10.1 and
`learning/verifier-fail-open.md` both say not to do, because the difficulty harness reads that
as *invalid trial* rather than *agent failed*. My version only fired when the grader had
already written reward 1, so it could not have poisoned ordinary failing trials, but it was
still the wrong classification. Replaced with the documented shape, a single term in the
grader's success expression:

```python
success = not missing_required and not unexpected and args.raw_exit_code == 0
```

The post-hoc downgrade block in `test.sh` is gone. `infrastructure_error` is now written only
on genuine harness failures: missing config, unresolvable workspace, failed restore, failed
patch.

## Local check results, revision 4

Against the edited bundle, airgapped, at the declared `cpus=4 / 8 GB`.

| Check | Reward | Required | Notes |
|---|---|---|---|
| NOP | 0 | 0 of 132 | `raw_exit_code 1`, `infrastructure_error: None`, 0 unexpected |
| Oracle, clean tree | 1 | 132 of 132 | 152 pass, 0 fail, 2 ignored, 0 unexpected |
| **Agent edited tests, `.git` removed** | **1** | **132 of 132** | the case that reproduces the platform failure |
| Agent committed + own `tests/ext/encoder.test.ts`, `.git` removed | 1 | 132 of 132 | |
| Hostile delete, brotli default 1 to 6 | **0** | 131 of 132 | `ext - brotliCompressor` fails |

## Files changed this round

| File | Change |
|---|---|
| `tests/test.sh` | restore rewritten: deletes `tests/` and unpacks a base64 payload of the base test tree embedded in the script itself, no git; grader gates on `raw_exit_code` inside the success expression; post-hoc downgrade block removed. 22 KB to 93 KB |

`instruction.md`, `task.toml`, `tests/config.json`, `tests/tests.patch`, `solution/solve.sh`
and `environment/problem_statement.md` carry revision 3's changes unchanged.
`solution/golden.patch` and `environment/Dockerfile` still untouched across every round. No
tracked source file inside `environment/repo` touched. PR scope unchanged.

`diff -rq download/original work -x .git` lists exactly the seven changed files, no additions.
`tests/` holds only `config.json`, `test.sh` and `tests.patch`.

## Packaging, revision 4

Git hygiene run last, immediately before zipping. `.git` contains exactly `config description
HEAD hooks index info objects packed-refs refs`, `git fsck --unreachable` prints nothing, both
patches apply at base, HEAD equals the base commit, no remotes, no refs past HEAD, clean tree,
1.6 MB.

Zip rebuilt with `zip -rX`. 309 entries, 1.8 MB, unpacks to the five top-level entries with no
`runs/` and no `task/` wrapper, `.git/refs/` and `.git/refs/heads/` present, no `.git` cruft,
both scripts 755.

All 20 static checks simulated against the **extracted zip**, now including the `tests/`
allowed-entry rule that bounced the previous upload: pass. The embedded payload was decoded
back out of the built zip and is still 158 files byte-identical to `environment/repo/tests`.

`answers/submission_answer.md`, the stale Aug 1 duplicate, was deleted. `answers/` holds only
`submission_answer.txt`.

## CLOSED — passed and accepted, 2026-08-04

**Round 6, on the revision 4 bundle with the embedded base64 test-tree payload, passed. The
task was accepted.** Reported by the submitter. Six rounds, verdict Fixable throughout, no PR
scope change at any point.

The zip that did it is `upload/20260719_045042__oliver-oloughlin_kvdex__245.zip`, built
2026-08-03 09:57, 309 entries, 1.8 MB.

Handling times as submitted and final: 90 review, 150 rewrite, 20 form, total 260, revisions
195. Both the total and the revision figure sit above this workspace's target bands, by the
submitter's decision, and both are explained in Comments for Reviewer.

### What actually got it through

Four restore designs went through the platform's difficulty check on this task. The three that
used git all passed every local scenario I could construct and none of them moved the result.
The one that does not touch git worked first time.

| Round | `test.sh` restore | Invalid trials |
|---|---|---|
| 3 | none | 13 of 16 |
| 4 | `git checkout -- tests/` + `git clean` | 16 of 16 |
| 5 | `rm -rf tests` + `git checkout <base sha> -- tests` | 15 of 16 |
| 6 | **base64 payload of the base test tree embedded in `test.sh`, no git** | **passed, accepted** |

Written up in `learning/tests-patch-vs-agent-edits.md`, which now carries the platform
confirmation rather than only the local verification matrix.

### Bundle state at close

Re-verified against the zip on disk on 2026-08-04, with no container time needed because
nothing had changed since 2026-08-03 09:57:

| Check | Result |
|---|---|
| `diff -rq download/original work -x .git` | exactly the 7 intended files |
| zip vs `work/` for all 9 non-repo files | byte-identical |
| zip shape | 309 entries, 5 top-level entries, no `runs/`, no `task/` wrapper |
| `.git` in the zip | `refs/` and `refs/heads/` present, no `logs`, `FETCH_HEAD` or `ORIG_HEAD` |
| script modes in the zip | `tests/test.sh` and `solution/solve.sh` both 755 |
| `tests/` entries | `config.json`, `test.sh`, `tests.patch` only |
| `instruction.md` vs `problem_statement.md` | byte-identical, md5 `831ced9511d5` |
| git hygiene in `work/` | HEAD == base, no remotes, no refs past HEAD, clean tree, `fsck --unreachable` silent, 1.6 MB |
| both patches at base | apply |
| grading | `fail_to_pass` 20, `pass_to_pass` 112, `allow_extra_failures` false |
| `task.toml` | every Section 8 limit holds |
| embedded payload, decoded **out of the built zip** | 928 base64 lines, 52874 bytes, 158 files, byte-identical to `environment/repo/tests` |

One thing to redo before any future re-zip: `.git/FETCH_HEAD` is back in the working copy. It
is not in the current zip, and the git hygiene pass removes it, but it recreates itself every
time git runs in there.

## The git-absence diagnosis is now corroborated from a sibling task

Revision 4 shipped the git-independent restore on a hypothesis it could not prove. Its own
words: "It is not proof that the platform's workspace lacks git, and the fix does not depend
on that being true." The proof was sitting in the workspace the whole time, in another task's
report.

`revision.md` holds the equalsverifier 1166 round 1 difficulty results, and that report
included the per-trial **Task Instruction Sufficiency** analysis that kvdex's own report
returned as `NOT_APPLICABLE`. Four independent codex trial analyses name the mechanism
directly:

> `codex-gpt-5-5_3`: "an infrastructure incompatibility: **the workspace is not a git
> repository**, so the verifier's test-restoration step was unable to reset test files to
> their base state before applying tests.patch."
>
> `codex-gpt-5-5_4`: "the verifier environment **lacked a git repository**, so the test.sh
> could not restore test source directories to their base-commit state"
>
> `codex-gpt-5-5_5`: "the verifier was designed to restore them via git, but **the environment
> lacked git**"
>
> `codex-gpt-5-5_7`: "The verifier's git-based test-file restoration mechanism also **silently
> failed because there was no git repository**"

Different repo, different language, different build system, same platform, same harness, same
`tests.patch did not apply` error class. That is the condition this task reproduced byte for
byte on 2026-08-03 and could not confirm from its own report.

Nothing in the bundle changes. The fix already assumes the worst case. What changes is that
the Comments for Reviewer no longer has to present it as an unproven guess, and
`learning/tests-patch-vs-agent-edits.md` no longer has to hedge.

Note the qualifier that survives: these are LLM judge analyses of trial logs, not platform
source. Four of eight codex trials say it and none of the claude trials do. Treat it as strong
corroboration of a hypothesis that was already reproduced locally, not as a platform
guarantee.
