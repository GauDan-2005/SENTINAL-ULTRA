# 20260808_213817__openziti_ziti-sdk-c__668

| | |
|---|---|
| Submission id | `6a0fee66-e7f8-49fc-b39a-6dba8ae38798` |
| Repo / PR | openziti/ziti-sdk-c PR 668, "HA: ziti controller failover handling" |
| Base commit | `daf515a28cb3b730b2be22a8be617bef4c7038df` |
| Language / runner | C library with C++ Catch2 tests, CMake + Ninja + vcpkg, Ubuntu 24.04 |
| Category | implementation / feature |
| Arrival difficulty | `difficulty = "hard"`, `model_difficulty = "medium"`, `pass_at_k` 0/3 on both models |
| Claimed | 2026-08-09 |
| Verdict | **Fixable** (Step 4, 2026-08-09) |
| Status | `checks-green` |
| Round | 5 |

Downloaded zip `6a0fee66-e7f8-49fc-b39a-6dba8ae38798_submission.zip`,
sha256 `7ee5acab43cb7875a3db7d327a7797f975f6de764c772e5c6ea3f55170241091`, 3190544 bytes,
197 entries, 0 symlinks. The zip is already flat and `download/original/` is a straight extract,
frozen since 2026-08-09 04:12.

**No `runs/` shipped, so there is no agent trial evidence.** Every statement about agent behaviour
in this file comes from a local measurement, and it is labelled as one.

## Upload ledger

| # | Date | Zip sha256 | Size | Checks returned | Outcome |
|---|---|---|---|---|---|
| 1 | 2026-08-09 | `04a0ea1cba35134b1d13f121ce8a6e97febbeda4f4243bf32707a700f0a91e5f` | 2284059 B (2.2 MB) | static, difficulty, oracle, quality | **review gate blocked at the agentic judge**, `Reason: coverage_gap`, Status REMOVE |
| 2 | 2026-08-09 | `da92faf20b2769da961383b2e1a115415a05273cad0dfd25b57b1fbc2da98717` | 2288101 B (2.2 MB) | static, difficulty, oracle, quality | **review gate blocked at the agentic judge**, `Reason: coverage_gap`, Status DISCUSS |
| 3 | 2026-08-09 | `9c01d38552dd8c5934db0f5d2d487d2b9add54893dfcd1173e5a47579c456801` | 2288358 B (2.2 MB) | built, then superseded | replaced before upload by the Q10 fix below |
| 4 | 2026-08-09 | `c173f29fe0ebd90a423358f3f4a3c3076fa8cdb04bf7e2d87a8b271c40cb6b38` | 2288340 B (2.2 MB) | static, difficulty, oracle, quality | **review gate blocked at the agentic judge**, `Reason: oracle_spec_gap`, Status DISCUSS |
| 5 | 2026-08-09 | `734de403bebaddaf1a2eb6c512fbf073323ef18cc2e3647d06bf9a557bc6c450` | 2.2 MB | **agentic judge PASSED**, difficulty screen | `FAIL EASY`, opus 4/4 and codex 3/4, oracle 3/3, nop 0/1 |
| 6 | 2026-08-09 | `a58468498fe81f765519853fb78f0a1568495e118810af9e7734320a6bd59e9c` | 2.2 MB | judge passed, difficulty screen | `FAIL EASY`, **opus 3/4 (was 4/4)**, codex 3/4, so **6 of 8** |
| 7 | 2026-08-09 | `1c2a3fb70ef798886eb55e77f37dcc326e445d86af625dba04028c355f1af09e` | 2.2 MB | judge passed, difficulty screen | `FAIL EASY`, opus 3/4 and codex **4/4**, so **7 of 8**. Unit table 7 runs, all 26 passing |
| 8 | 2026-08-11 | `29f00bd9d90f069224ba683d597bb1dd1a8acb711287d455dd9780eab0d50994` | 2291111 B (2.2 MB) | not uploaded yet | Phase A and Phase B both green locally |

An earlier zip, `6173b7c0fd4e595a05f7179f0e6426bb52f06f114c0ddd4924c9fc26a7ef6ea5`, was built and then
superseded by one instruction wording change. It was never uploaded and its battery run is void.

## Handling time ledger

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 0 | 2026-08-09 | 0 | 0 |
| 1 | 2026-08-09 | 70 | 70 |
| 2 | 2026-08-09 | 70 | 140 |
| 3 | 2026-08-09 | 65 | 205 |
| 4 | 2026-08-09 | 70 | 275 |
| 5 | 2026-08-09 | 75 | 350 |
| 6 | 2026-08-11 | 80 | 430 |

First-pass fields 1, 2 and 3 are in the answers file. The revision field stays 0 until a round
actually happens, and it is copied from the Cumulative column above, never estimated.

## Failure signatures

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Review gate blocked at the agentic judge, `Reason: coverage_gap` | 1, 2 | r1 graded the peer refresh and the online state preference with an in-process controller, plus 3 oracle corrections. r2 graded the in-flight condition with two concurrent requests, plus a 4th oracle correction | 2 |
| Packaging capped at 1 on the PEM key in `environment/repo/tests/test_ziti_model.cpp:805` | 1, 2 | r1 moved the two regression guards off that file. **The score did not move** | 2 |
| Quality Check must-have Q10, instruction quotes a test-asserted error string | 2 | removed the literal, kept the requirement, relied on the literal being in the base repo | 1 |
| Review gate blocked at the agentic judge, `Reason: oracle_spec_gap` | 3 | deleted the unbounded quantifier in the instruction and updated the stale dead-source call site | 1 |
| Difficulty screen `FAIL EASY` | 4, 5 | r4 graded two stated-and-unenforced clauses, **and the number moved 7/8 to 6/8**. r5 adapted openziti 678 and 794 | 2 |

**Strike 2, but the trend says the class is right.** Section 4 says a number that does not move across
two fixes means neither touched the cause. This one moved, and one opus run flipped, so the answer is
a bigger lever of the same class rather than removing the dependency.

**The coverage signature is closed, not at strike 3.** `Reason: coverage_gap` scored rounds 1 and 2;
round 3 moved to `oracle_spec_gap` and the coverage number went 2.5 to 3.0 to 4.5. A reason that
moves is a different failure, not another strike on the same one.

`Not run: difficulty screen` is not a signature and gets no row. The judge blocked first, so the
second stage never started, which is expected rather than a second error.

## Graded id to file map (resolves the preflight UNRESOLVED)

`bin/checks/50-restore-shape` prints `UNRESOLVED` on this bundle, exactly as
`learning/preflight-false-positives.md` predicts: all 25 graded ids are bare Catch2 test-case names
with no path and no separator, so the resolver cannot attribute them. Resolved by hand, after round 1:

| Graded id | Defined in | Touched by tests.patch |
|---|---|---|
| `invalid_controller` and the 18 `sentinel_*` ids | `tests/integ/legacy-auth.cpp` | yes |
| `version` | `tests/integ/main.cpp` | no |
| `parse_model_list`, `lists_model`, `model_map_test` | `tests/model_tests.cpp` | no |
| `parse_enum_array`, `parse_enum_list` | `tests/enum_tests.cpp` | no |

**6 of 25 graded ids live in files `tests.patch` does not touch**, so the create-only patch shape is
not available and the restore has to be the full test-tree payload. That is what shipped.

Round 1 moved two guards off `tests/test_ziti_model.cpp`. That file holds the repository's only PEM
private key, at line 805, and the judge capped packaging on it.

## learning/ notes applied

| Note | What it predicted here | What settled it | Result |
|---|---|---|---|
| static-checks.md | `fail_to_pass` held 6 ids, outside the hard 10 to 20 range | `len(config.json fail_to_pass)` | confirmed, 14 after round 0 and 19 after round 1 |
| static-checks.md | `problem_statement.md` differed from `instruction.md` | `diff` | confirmed, one clause; now byte-identical |
| static-checks.md | `tests/` may hold only config.json, grade.py, test.sh, tests.patch | `ls tests/` | holds three of the four, no `files/` |
| stock-bundle-defect-baseline.md | all six scaffold defects present until disproved | one command per row | 5 present, 1 not applicable |
| verifier-fail-open.md | `success = not missing_required and not unexpected`, `raw_exit_code` never read | grep | confirmed, gate added |
| verifier-fail-open.md | the runner reports only the last command's status | read `execution.commands` | confirmed, `set -e` emitted into the generated runner |
| verifier-fail-open.md | measure the runner's bare exit on a green tree before wiring the gate | oracle run | bare exit 0 on green, gate is safe |
| verifier-fail-open.md, L23 | gate inside the grader, never an early `infrastructure_error` exit | NOP report | reward 0, raw_exit 1, `infrastructure_error: None` |
| solve-sh-idempotency.md | `solve.sh` reverse-applies as its success fallback | `grep -n 'apply.* -R' solution/solve.sh` | confirmed at line 9, replaced with the sanctioned four-step shape, measured 3 applies in one container |
| solve-sh-under-sh.md | shebang is bash and the script uses no unguarded bashisms | grep | clean |
| tests-patch-vs-agent-edits.md | API migration means the agent must edit the two patched test files, so `tests.patch` will conflict | agent-edit simulation with a real commit | confirmed as a risk, and the embedded payload restore clears it: reward 1.0 with the agent's edits committed |
| tests-patch-vs-agent-edits.md, L3 | no git-based restore | design | payload is a base64 tarball inside `test.sh`, no git anywhere in the restore |
| tests-patch-vs-agent-edits.md, L4 | the payload may not ship as `tests/files/<archive>` | design | embedded in `test.sh` |
| tests-patch-vs-agent-edits.md, L9 | restore on every task whatever the patch shape | design | restore ships |
| L6, L7 | count `pass_to_pass` too, and resolve bare ids by hand | the map above | 6 of 25 outside, so full-tree payload |
| LEDGER L18 | a refutation in Comments for Reviewer never reaches the judge | round 0 disclosed both coverage gaps there and the judge blocked on them anyway | confirmed the hard way, cost one round |
| LEDGER L37 | answer an over-specification score with added behaviour, not deletion | the names gpt objects to are all asserted by graded tests | applied, names kept, five requirements added |
| probe-the-instruction-you-already-wrote.md | clauses nothing grades are free difficulty, and every probe must assert its own break landed | the 12-probe sweep | the log probe was green until the assertion was tightened, which is the note's own failure mode |
| oracle-bug-vs-pr-scope.md | a defect the instruction promises against is a case 1 oracle edit, and the canonical fix is upstream's | fetched `library/ziti_ctrl.c` from openziti main | all three of gpt's claims already fixed upstream, minimal form adopted |
| verify-in-the-image.md | one broken translation unit kills the whole binary, so a NOP reward of 0 proves nothing on its own | see the NOP section below | confirmed, and the split was done both ways |
| unreachable-git-blobs.md | a broken `refs/remotes/origin/HEAD` that no other check catches | `git fsck --unreachable` | confirmed `invalid sha1 pointer 000...`, removed, fsck now silent |
| empty-git-refs.md, L26 | `git gc` empties `.git/refs/heads` and a half-present `.git` can break a build that reads VCS state | `cmake/version.cmake` calls `git describe --always`; checked in the built image | loose ref written back by `bin/rezip.sh`, `git rev-parse HEAD` works in the image, `refs/heads` contains `main` |
| dirty-repo-and-symlinks.md | the shipped tree is dirty, three tracked scripts lost their executable bit | `git diff --summary` | confirmed, restored to 100755, tree now clean |
| dirty-repo-and-symlinks.md | 0 symlinks, so the `zip -y` assertion is free | `find -type l` | 0 == 0 |
| dockerignore-context-root.md, L25 | tracked `.idea` reaches `/app` and there is no context-root `.dockerignore` | `git ls-files .idea`, then `find /app` in the image | confirmed, fixed both ways, `find /app -name .idea` is now silent |
| stale-test-reports.md | the image builds test binaries at build time | the parser reads stdout only, no report file is globbed | not applicable |
| quality-check-criteria.md | Q9 near certain, Q10 risk from the quoted error codes | the two detectors in `quality-rehearsal` | Q9 was 4 nav hits before the rewrite and is 0 after; Q10 is 1 hit, the error code, which is the API contract |
| prescriptiveness-check.md | Rule 2 findings on six named source files, plus verifier mechanics in the instruction | read the instruction | all six paths removed, the "do not modify the test files" sentence removed |
| prescriptiveness-check.md | grep the tests before deleting a name | the name-parity gate below | every identifier the instruction names appears in both patches |
| source-pr-cross-check.md | diff `golden.patch` against the PR's real file list, paged | GitHub API, one page of 8 rows | golden is byte-identical to the PR's six non-test files |
| oracle-bug-vs-pr-scope.md | an oracle quirk may be the PR's own | compared golden to the PR diff line by line | two upstream quirks found, both left alone, both disclosed |
| non-derivable-private-names.md | `pass_at_k` 0/3 can mean unsolvable as easily as hard | symbol audit plus the base-behaviour probe | the task is solvable, the oracle passes 3/3, and every graded id fails at base for a measured reason |
| preflight-false-positives.md | `50-restore-shape` prints UNRESOLVED on ids with no path | `bin/preflight.sh` | confirmed, resolved by hand in the table above |
| local-runs.md | ext4, and the vcpkg image is slow to build cold | `df -Th`, timed build | ext4; the cold image build is about 4 minutes on 16 cores |
| accepted-bundle-reference.md | instruction paragraphs should sit well under 800 characters | measured | longest block is now 527, was 1788 |
| difficulty-levers-must-discriminate.md, L35 | only relevant if a difficulty screen comes back easy | not needed yet | no lever designed, nothing measured |
| go-task-verifier-gotchas.md, rust-cargo-verifier-gotchas.md | not applicable, this is C with CMake and Catch2 | - | not applicable |
| calibration.tsv | no C or CMake row exists yet | - | gap noted, a row is worth adding once the platform returns numbers |

## Stock-bundle defect baseline

| # | Defect | Verdict | Evidence | Fixed by |
|---|---|---|---|---|
| 1 | Fail-open grader | Present | `tests/test.sh` computed `success` without reading `raw_exit_code` | exit-code gate in the success expression, `set -e` in the generated runner, `bash -o pipefail` |
| 2 | No regression guard | Present | `pass_to_pass` was `[]`, `allow_extra_failures` was `true` | 6 regression guards, `allow_extra_failures` now `false` |
| 3 | Stale build-time test results | Not applicable | the parser reads stdout only and globs no report path | - |
| 4 | `solve.sh` not idempotent | Present | reverse apply as the success fallback | sanctioned four-step shape, measured over three applies |
| 5 | Graded tests carry names an agent would choose | Present | five new cases with plain names such as `ctrl_init_multi_endpoint` | every new case now carries a `sentinel_` prefix |
| 6 | No test-tree restore before `tests.patch` | Present | no base64, no wipe, no restore anywhere in `test.sh` | embedded tarball payload, wipe list derived from the archive |

## Findings and fixes (Step 3 and Step 5)

| # | Finding | Evidence | Maps to | Fix |
|---|---|---|---|---|
| 1 | 6 fail-to-pass ids against a hard floor of 10 | `tests/config.json` | Fixable 5 | 14 graded cases, 8 of them new |
| 2 | `problem_statement.md` not byte-identical to `instruction.md` | 4245 B against 4235 B | Fixable 12 | re-copied, and re-copied again after the wording change |
| 3 | Instruction names six internal source files and both headers | old `instruction.md` paragraph 2 | Fixable 1, Q9, prescriptiveness Rule 2 | rewritten with no paths |
| 4 | Instruction carries "do not modify the test files under `tests/`" | old paragraph 3 | Q9, verifier mechanics in the instruction | removed; the guarantee now lives in `test.sh` as the restore |
| 5 | Instruction promises three things `golden.patch` does not do | see the spec-gap table below | oracle spec faithfulness | instruction narrowed, oracle untouched |
| 6 | Grader awards 1.0 without reading the exit status | `tests/test.sh` | Section 10.1 | gate added, proved with a build-break probe |
| 7 | `pass_to_pass` empty | `tests/config.json` | Section 10.2 | 6 guards over config parsing, version parsing and the collection types the patch leans on |
| 8 | `tests.patch` conflicts once an agent fixes the test call sites | measured with a committing agent | Section 10.3 | full test-tree payload restore |
| 9 | `solve.sh` reverse-applies on failure | `solution/solve.sh:9` | Section 10.6 | replaced |
| 10 | `tests/test.sh` and `solution/solve.sh` at mode 0644 | `stat` | allowed-fix row | both 0755, asserted in the built zip |
| 11 | Shipped tree dirty, three tracked scripts at 100644 | `git diff --summary` | pre-upload gate 2 | restored to 100755 |
| 12 | Broken `refs/remotes/origin/HEAD` | `git fsck` | pre-upload gate 4 | `.git/refs/remotes` removed, fsck silent |
| 13 | `repo_license` empty while the repo ships Apache 2.0 | `task.toml:13` | Section 8 | `Apache-2.0` |
| 14 | `[environment] os` missing | `task.toml` | Section 8 | `os = "linux"` |
| 15 | `[metadata] difficulty_explanation` missing | `task.toml` | Section 8 | added |
| 16 | `build_timeout_sec` 900 for a cold vcpkg build | `task.toml` | Section 8 | 1800 |
| 17 | `[agent] timeout_sec` 1800 against a 7200 ceiling | `task.toml` | Fixable 11 | 7200 |
| 18 | Tracked `.idea` reaches `/app`, no context-root `.dockerignore` | `git ls-files .idea` | packaging hard cap | `environment/.dockerignore` plus `rm -rf` after the COPY |
| 19 | Dockerfile comment claims the baked test sources use the post-change API | old `environment/Dockerfile:88` | accuracy | corrected; measured false, the base tree compiles at base |
| 20 | `model_difficulty` medium against `difficulty` hard | `task.toml:16` and `:19` | report only, LEDGER L14 | not reconciled, named in Comments for Reviewer |

### Spec gaps closed in the instruction, not in the oracle

| The old instruction promised | What `golden.patch` does | How the instruction now reads |
|---|---|---|
| the client is initialized against the endpoint that was picked | the client is initialized against the last URL in the list, and the picked endpoint is chosen separately | "pick one of those endpoints as the one in use" and "bring up the underlying HTTP client", with no claim that the two are the same |
| the endpoint map is rebuilt "preserving online/offline state" | the old map is dropped and the new one carries whatever the controller reported | "carrying the online state the controller reports for it" |
| controller listing "should only be issued when" HA was advertised | the login path is gated, the current-edge-routers path is not | "Ask for peers after login only when the controller advertised the ... capability" |
| a negative response code triggers the switch | a cancellation is a negative code and is deliberately excluded | "a negative response code other than a cancellation" |

`golden.patch` is byte-identical to the source PR's six non-test files, checked hunk by hunk, so
every one of these is the PR's own behaviour. None of them was fixed in the oracle.

## Step 5.5 Phase B, against zip `04a0ea1c`

Every run is a fresh `unzip` of that exact zip into the session scratchpad, with the image built
from the extracted `environment/Dockerfile`. Nothing ran inside `work/`.

**Run 1, NOP.** `reward 0.0`, `test.sh` exit 1, `raw_exit_code 1`, `infrastructure_error: None`,
0 of 20 required ids passed, 29237 bytes of stdout. The restore line
`restored base test tree: tests` is in the log, so the payload fired.

**Why that zero is genuine, both ways.** The graded translation unit does not compile at base, so
the reward alone proves nothing (`learning/verify-in-the-image.md`). Two separate measurements:

- **Symbol audit** for the ten controller cases. At the base commit `inc_internal/ziti_ctrl.h`
  declares `int ziti_ctrl_init(uv_loop_t *loop, ziti_controller *ctrl, const char *url, tls_context *tls)`,
  and `git grep` for `endpoints`, `active_reqs` and `is_ha` in that header returns nothing. The
  cases read `ctrl.endpoints` and `ctrl.active_reqs` and call the list form of `ziti_ctrl_init`,
  none of which exists at base.
- **Executed base-behaviour probe** for the four config and context cases, which touch only
  symbols that do exist at base. The four contracts were appended to `tests/util_tests.cpp` in a
  disposable container at base, built into `all_tests` and run. All four fail at base with real
  assertion output: legacy migration leaves `controllers` at 0, a controllers-only config is
  rejected with -13, a config with no controller is accepted with 0, and `ziti_context_init`
  rejects a controllers-only config with -13. So none of the 14 is a test that already passes.

**Run 2, oracle, three cycles in one container.** `solve.sh` then `test.sh`, three times:

| Cycle | solve.sh | test.sh | reward | passed | raw_exit | infra |
|---|---|---|---|---|---|---|
| 1 | 0, "golden.patch applied." | 0 | 1.0 | 20 / 20 | 0 | None |
| 2 | 0, "already applied; nothing to do." | 0 | 1.0 | 20 / 20 | 0 | None |
| 3 | 0, "already applied; nothing to do." | 0 | 1.0 | 20 / 20 | 0 | None |

3/3. Verifier wall clock 1.7 to 2.0 seconds per cycle against a 1800 second budget.

**Run 3, hostile delete.** Four probes on a disposable copy, each reverted before the next:

| Probe | Reward | Test that caught it |
|---|---|---|
| baseline, nothing stubbed | 1.0 | - |
| endpoint switch removed from the response callback | 0.0 | `sentinel_ctrl_failover_switches_endpoint` |
| `ziti_ctrl_close` no longer frees the endpoint map | 0.0 | `sentinel_ctrl_close_frees_endpoints` |
| empty-endpoint-list rejection removed | 0.0 | `sentinel_ctrl_init_rejects_empty_endpoints` |
| build break in a library file no graded id names | 0.0 | none, and that is the point: `raw_exit_code 1` fired the exit-code gate |

**Run 4, agent-edit simulation.** An agent applies the solution, rewrites the two test call sites
the way the API change forces, writes its own `tests/integ/ha-controller-tests.cpp`, and commits
all of it. `reward 1.0`, 20 of 20, `infrastructure_error: None`. Without the restore this is the
`tests.patch did not apply` harness failure.

## Local Quality Check rehearsal

| Axis | Score | Evidence |
|---|---|---|
| realism | 4 | reads as a ticket, no numbered how-to, no template scaffolding |
| clarity | 4 | every requirement is stated as an outcome; longest block 527 characters |
| self_containedness | 4 | every symbol named either exists at base or is the deliverable |
| prescriptiveness | 4 | no file paths, no library choices, no procedure |
| test_coverage | 4 | 14 cases mapped clause by clause; three hostile probes each named a different test |
| test_faithfulness | 4 | every assertion rests on a stated clause |
| oracle_spec_faithfulness | 4 | four over-promises narrowed, oracle untouched |
| oracle_no_gaming | 5 | no hardcoded answers, no test-side ground truth |
| oracle_robustness | 4 | forward-only idempotent oracle, 3/3 measured; the upstream unpinned FetchContent branch is tracked source and out of bounds |
| packaging | 5 | `.idea` excluded both ways and absent from `/app`, fsck silent, `tests/` holds only legal names |

Must-have criteria: Q9 has 0 navigation hits after the rewrite, against 4 before. Q10 has one hit,
`CONTROLLER_UNAVAILABLE`, which is the API error contract two graded cases assert and the
instruction has to state or the task stops being solvable. Simulated status: OK.

## Not fixed, on purpose

| Thing | Why it was left | Where it is disclosed |
|---|---|---|
| `model_difficulty` medium against `difficulty` hard | LEDGER L14 and `docs/faq.md` forbid hand-editing difficulty metadata to satisfy a check | Comments for Reviewer |
| `|| true` on the `patch` install at the end of the Dockerfile | platform-injected line, and nothing downstream breaks because git is present; Section 10.7 says report rather than strip | Comments for Reviewer |
| Two upstream quirks in `golden.patch`: the client initialized against the last list entry, and `ctrl_default_cb` freeing a URL the endpoint map owns | both are the source PR's own code, and changing them is replacing PR behaviour | Comments for Reviewer |
| `deps/CMakeLists.txt` fetches `subcommand` from a moving branch, so any CMakeLists change at verify time triggers a re-configure that needs the network | tracked source, cannot be edited; measured `ninja: error: rebuilding 'build.ninja': subcommand failed` when a source file was added to `tests/integ/CMakeLists.txt`. It is why the graded cases live in an already-patched file | Comments for Reviewer |
| `ziti-cli` is an `ALL` custom target that would `go install` over the network | tracked source; the verifier only builds named targets so it is never reached, but a plain `cmake --build build` by the agent would hit it | Comments for Reviewer |
| Peer refresh and the online/offline preference have no graded assertion | they need a live HA controller and the verifier is airgapped | Comments for Reviewer |

## Round 0

Analysis, verdict Fixable, all fixes applied in `work/`, Phase A green, zip built and verified,
Phase B green against that zip. Answers written and uploaded as zip `04a0ea1c`.

## Round 1, 2026-08-09

### Freshness check on the incoming report

| Axis | Result |
|---|---|
| Test ids | every id the report names is in the round-0 `config.json`, 14 f2p including `invalid_controller` and 13 `sentinel_*` |
| Line numbers | `instruction.md:11,19-26,28,32,34-42` against a 42-line file, `tests/config.json:6-25` and `:31-53` against 71 lines, `tests/test.sh:558-560` lands exactly on the restore loop and `:570-589` on the patch apply, `solution/solve.sh:36-68` against 68 lines |
| Commands | the report describes the `if ./build/tests/integ/integ-tests "NAME"` shape, which is what round 0 shipped |
| Instruction text | "other parameters keep their current meaning and order" is quoted verbatim and was in round 0's `instruction.md:19` |

Fresh, and it is for zip `04a0ea1c`. **No axis was elided**: the paste carries a quoted
justification from both judges for all ten, so nothing is marked UNVERIFIED.

### The report

`Status: REMOVE`, `Reason: coverage_gap`. Adjudicated: test_coverage 2.5 (claude 4, gpt 2),
oracle spec faithfulness 2.5 (claude 4, gpt 2), packaging 1.0 (claude 3, gpt 1), instruction
over-specification 2.5 (claude 4, gpt 2). Everything else 4.0 or better, and the two
faithfulness and self-containedness scores were 5.0.

### What the round changed

**1. The blocking gap, closed by grading it rather than by explaining it.** Round 0 disclosed the
peer-learning and online-state gaps in Comments for Reviewer. LEDGER L18 says the judge does not
read that field, and it did not. The conclusion underneath was also wrong: airgapped means no
egress, not no sockets (`redisshake 1005`, round 3). Five new cases stand a throwaway HTTP
controller on `127.0.0.1` inside the test process, on the same loop, serving `/version`,
`/authenticate`, `/controllers` and `/current-identity/edge-routers` from canned payloads, and
refusing to list peers to a caller with no `zt-session` header. The listening handle is
`uv_unref`ed so `uv_run` still returns.

**2. Three oracle corrections, under `docs/guidelines.md:284-291` case 1.** Each of gpt's three
claims was reproduced against `golden.patch` before anything was edited, and each held. Upstream
`openziti/ziti-sdk-c` main already carries the canonical fix for all three, so that is what was
taken, in its minimal in-shape form rather than importing the later `cstr` and `capabilities`
refactor:

| gpt's claim | Reproduced | Canonical fix taken |
|---|---|---|
| the client is initialised with the loop variable `ep`, not the selected `ctrl->url` | yes | `tlsuv_http_init(loop, ctrl->client, ctrl->url)`, upstream `ziti_ctrl.c:635` |
| configured endpoints are stored with `NULL` values, so the failed one cannot be marked offline | yes | a `ziti_controller_detail` per configured endpoint, upstream `ziti_ctrl.c:626-628`. Divergence: `is_online` is set true at init, because upstream's zero-allocated version depends on a later selection rewrite with an `offline_time` recheck that is out of scope here |
| the post-login peer refresh is issued when the login request starts, not once a session exists | yes | moved into the success branch of the login callback, matching upstream issuing it from the token-setting path |

Two more went with them because the same sentence in `instruction.md` covers them: the
edge-router piggyback now answers to the same capability gate upstream applies to it, and a
refresh that drops the endpoint in use now selects a new one instead of leaving `ctrl->url`
pointing into the map it just freed. **The file list is unchanged**, still exactly the source
PR's six non-test files.

**3. Instruction updated in lockstep**, as case 1 requires. It now states that the HTTP client
talks to the endpoint reported as `url`, that the peer request waits for a session, and that the
capability gate covers both refresh paths. Detectors after the edit: 0 navigation hits, 0 file
paths, 1 literal shared with the tests (`CONTROLLER_UNAVAILABLE`, the error contract), longest
block 602 characters.

**4. The over-specification score was answered with behaviour, not deletion (LEDGER L37).** gpt
scored it 2 for naming the `model_list` parameter change, the `endpoints` map, `active_reqs` and
the close behaviour. Every one of those names is asserted by a graded test and the same report
scored the tests' faithfulness 5.0 because they are named, so cutting them trades a passing check
for a failing one. The names stayed, the wording moved from "add this field" to what a caller and
a reader observe, and the answer to the score is five more graded requirements.

**5. Packaging.** `environment/repo/tests/test_ziti_model.cpp:805` holds a PEM private key in an
upstream config fixture. It is the only one in the repository, confirmed with
`git grep -- '-----BEGIN .*PRIVATE KEY-----'` at the base commit. It is tracked source and cannot
be deleted. What was in reach: two regression guards used to run cases from that same file
(`load cfg`, `parse-ctrl-version`) and now run equivalent cases from files that carry no key
(`parse enum array`, `parse enum list`, which guard the capability array `is_ha` is read from), so
nothing in the graded set points at it. Escalated to the reviewer with the path and line.
The `model_difficulty` against `difficulty` clash claude also cited is **not** reconciled, per
LEDGER L14.

### Probe sweep, 12 of 12 caught, run against an extract of zip `da92faf2`

Every probe asserts its own anchor matched exactly once before it edits, so a probe that has
rotted refuses to run instead of reporting a false all-clear
(`learning/probe-the-instruction-you-already-wrote.md`).

| Probe, one stated requirement broken | Reward | Caught by |
|---|---|---|
| baseline, nothing broken | 1.0 | 25 of 25 pass |
| endpoints stored with no state | 0.0 | `sentinel_ctrl_failover_visits_distinct_endpoints` |
| client pointed at a different endpoint than `url` | 0.0 | `sentinel_ctrl_failover_visits_distinct_endpoints` |
| peers asked for before the session exists | 0.0 | `sentinel_ctrl_learns_peers_from_controller`, `sentinel_ctrl_prefers_peer_reported_online` |
| capability gate removed from the edge-router path | 0.0 | `sentinel_ctrl_skips_peer_refresh_without_ha` |
| endpoint map never rebuilt from the peer list | 0.0 | `sentinel_ctrl_learns_peers_from_controller`, `sentinel_ctrl_prefers_peer_reported_online` |
| selection ignores the reported online state | 0.0 | `sentinel_ctrl_failover_visits_distinct_endpoints` |
| port dropped from the controller log line | 0.0 | `sentinel_ctrl_log_names_host_and_port` |
| endpoint switch removed from the response callback | 0.0 | 3 tests |
| close no longer frees the endpoint map | 0.0 | `sentinel_ctrl_close_frees_endpoints` |
| empty endpoint list accepted | 0.0 | `sentinel_ctrl_init_rejects_empty_endpoints` |
| in-flight counter never decremented | 0.0 | 4 tests |
| build break in `library/channel.c`, which no graded id names | 0.0 | nothing, and that is the point: `raw_exit_code 1` fired the exit-code gate |

**The log probe caught a real hole in my own first draft.** The assertion looked for the host and
the port anywhere in a captured line, and the `using %s` line quotes the whole URL, so the port was
present either way and the probe came back green. Tightened to skip lines containing a URL, and it
then discriminated. That is the `assert the sabotage landed` mechanic doing its job on the test
rather than on the oracle.

### Phase B against zip `da92faf2`

| Run | Result |
|---|---|
| NOP | reward 0.0, `test.sh` exit 1, `raw_exit_code 1`, `infrastructure_error: None`, 0 of 25, 41916 bytes of stdout, restore line present |
| Oracle, 3 cycles in one container | 1.0, 1.0, 1.0, 25 of 25 each, 2.0 to 2.4 s against an 1800 s budget |
| Oracle stability, 6 further back-to-back runs | 1.0 every time. Run because the new cases open sockets |
| Hostile probes | 12 of 12, table above |
| Agent-edit simulation | 1.0, 25 of 25, with the agent's test-file edits committed |

Graded set is now 19 fail-to-pass and 6 pass-to-pass, 25 ids. The f2p count sits under the hard
ceiling of 20 with one to spare, which is why the edge-router refresh was folded into
`sentinel_ctrl_learns_peers_from_controller` rather than given an id of its own.

### Files this round touched

`instruction.md`, `environment/problem_statement.md`, `solution/golden.patch`, `tests/tests.patch`,
`tests/config.json`. Nothing else in the bundle moved. `task.md`, `INDEX.md` and `learning/` are
workspace bookkeeping and are not in Files Changed.


## Round 2, 2026-08-09

### Freshness check on the incoming report

| Axis | Result |
|---|---|
| Test ids | 19 f2p and 6 p2p, exactly what the report counts |
| Line numbers | `tests.patch:760-773` lands on the log case the judges quote, `test.sh:1016` on the exit-code gate, `config.json:4-30` on the commands and `:35-64` on grading, `instruction.md:9-42` against a 42-line file |
| Commands | the `if ./build/tests/integ/integ-tests "NAME"` shape the report describes |
| Instruction text | "identify the port as well as the host" quoted from `instruction.md:28`, and the `active_reqs` sentence from `:32` |

Fresh, and it is for zip `da92faf2`. No axis elided, both judges quoted on all ten.

### The report, against round 1

`Status: DISCUSS` (was REMOVE), `Reason: coverage_gap` (unchanged).

| Axis | Round 1 | Round 2 | Movement |
|---|---|---|---|
| test_coverage | 2.5 | **3.0** | up, and still the blocker. The bar is *above* 3 |
| oracle spec faithfulness | 2.5 | 3.5 | up |
| over-specification | 2.5 | **4.0** | fixed, and fixed by adding behaviour rather than cutting names (LEDGER L37 held) |
| test faithfulness | 5.0 | **4.0** | **regressed, and I caused it** with the round-1 log assertion |
| packaging | 1.0 | 1.0 | unmoved. Same PEM key both rounds |
| clarity | 4.0 | 4.0 | flat, one new ambiguity named |

### What the round changed

**1. The blocking gap: the in-flight condition was stated and never exercised.** The judge's words:
*"a solution that leaves `active_reqs` always 0 and switches endpoints even while another request is
outstanding would pass"*. Correct. Every case issued one request at a time.
`sentinel_ctrl_no_switch_while_a_request_is_in_flight` starts two logins before the loop runs, checks
the counter reads 2, and has each callback record the counter and the url it saw when it fired.
Exactly one comes back with the other still outstanding, and that one must see the url unchanged.
Deterministic, and it reads only `active_reqs` and `url`, both already named in the instruction.

**2. I removed the log requirement instead of defending it.** Both judges scored test faithfulness
down for the round-1 assertion, which skipped lines containing `://` so that a line quoting a whole
URL could not satisfy it. They are right that this rejects an implementation logging
`https://host:port`. There is no faithful *and* discriminating assertion available here, because the
URL always contains the port, so per `non-derivable-private-names.md` ("state the rule, or stop
depending on it") the sentence and its case are both gone. The trailing "log the move" clause went
with it, for the same reason: a stated requirement nothing grades is what the coverage axis looks for.

**3. A fourth oracle correction, and this one I had missed.** gpt found
`ziti_ctrl_set_token` asking the controller for its peers with no capability check at all
(`library/ziti_ctrl.c:477` at base, untouched by round 1's golden patch). That contradicts the
instruction. Reproduced, then fixed with the gate openziti main carries. The no-capability case now
drives that path too and fails without it.

**4. The other gpt oracle claim was answered on the instruction side.** It says `active_reqs` is
released in the header callback rather than when the body has finished. True, and **upstream main
does the same**, so there is no canonical fix to adopt and it is not a defect. A coherent sentence
describes it, so the sentence moved: the counter is what the controller is *waiting on*, raised when
a request starts and lowered when the response comes back.

**5. Clarity and over-specification, cheap and taken.** The compatibility line was ambiguous about
whether the old `const char *url` form had to survive; it now says the old form goes away and the
in-tree callers move. The "no longer owns a heap copy of one URL string" note is gone, since it
described the inside of the change.

### Probe sweep, 14 of 14 caught, against an extract of zip `9c01d385`

| Probe | Reward | Caught by |
|---|---|---|
| baseline | 1.0 | 25 of 25 pass |
| **switch fires while a request is in flight** | 0.0 | `sentinel_ctrl_no_switch_while_a_request_is_in_flight` |
| **counter pinned at zero** (the judge's own hypothetical) | 0.0 | 14 tests |
| **token path peer request ungated** | 0.0 | `sentinel_ctrl_skips_peer_refresh_without_ha` |
| counter never decremented | 0.0 | 5 tests |
| endpoints stored with no state | 0.0 | 2 tests |
| client pointed elsewhere than `url` | 0.0 | `sentinel_ctrl_failover_visits_distinct_endpoints` |
| peers asked for before the session | 0.0 | 2 tests |
| capability gate off the edge-router path | 0.0 | `sentinel_ctrl_skips_peer_refresh_without_ha` |
| endpoint map never rebuilt | 0.0 | 2 tests |
| selection ignores reported online state | 0.0 | 3 tests |
| endpoint switch removed | 0.0 | 4 tests |
| close no longer frees the map | 0.0 | `sentinel_ctrl_close_frees_endpoints` |
| empty endpoint list accepted | 0.0 | `sentinel_ctrl_init_rejects_empty_endpoints` |
| build break in `library/channel.c` | 0.0 | exit-code gate, `raw_exit_code 1` |

### Phase B against zip `9c01d385`

| Run | Result |
|---|---|
| NOP | reward 0.0, `raw_exit_code 1`, `infrastructure_error: None`, 0 of 25, restore line present |
| Oracle, 3 cycles in one container | 1.0, 1.0, 1.0, 25 of 25 each, 2.1 to 2.3 s against an 1800 s budget |
| Oracle stability, 6 further runs | 1.0 every time |
| Hostile probes | 14 of 14, table above |
| Agent-edit simulation | 1.0, 25 of 25, agent's test edits committed |

Graded set unchanged in size at 19 f2p and 6 p2p, because the log case was swapped for the in-flight
case rather than added to.

### Packaging is at two strikes and I cannot clear it

Same finding both rounds: `environment/repo/tests/test_ziti_model.cpp:805` carries the repository's
only PEM private key, in an upstream config fixture, tracked at the base commit. Round 1's mitigation
(moving the two regression guards that ran cases from that file onto key-free files) **did not move
the score**, which says the judge reads the file whatever the graded set points at. The remove-the-
dependency path is deleting the key, and that is a tracked-source edit inside `environment/repo`,
which is a hard boundary. **This is escalated to the submitter rather than worked a third time.**
Note that packaging has never been the `Reason:` on either report; both said `coverage_gap`.

### The separate Quality Check, same zip

`1 must-have quality criteria failed (14/15 criteria pass)`, `[Q10]`, `criterion: Instructions`. The
judge quoted the instruction's `CONTROLLER_UNAVAILABLE` sentence against
`sentinel_ctrl_single_endpoint_stays_selected`'s `Equals("CONTROLLER_UNAVAILABLE")`.

**This is the trade round 0 took deliberately, and it came due.** Round 0 reasoned that the tests
assert the string so the instruction has to state it or Instruction Sufficiency fails. That skipped a
step, and `quality-check-criteria.md` names it: the Q10 fix is to relax to *a literal the repo already
contains and the instruction does not*. Measured before editing anything:

```
daf515a2:library/ziti_ctrl.c:165:  const char *code = "CONTROLLER_UNAVAILABLE";
daf515a2:tests/integ/legacy-auth.cpp:117:  REQUIRE_THAT(version.error.code, Equals("CONTROLLER_UNAVAILABLE"));
golden.patch:278  appears only as a context line, so the path is unchanged by the solution
```

The agent can read it off the code it starts from, a test that ships with the repo already asserts
it, and the requirement is to *preserve* base behaviour rather than invent it. The literal came out
and the sentence now asks for the error the SDK already gives. The Q10 detector reports **0 of 53**
test literals in the instruction, against 1 before.

**`ZITI_INVALID_CONFIG` deliberately stays named.** The distinction the judge drew is the one that
matters: `CONTROLLER_UNAVAILABLE` is a string literal compared with `Equals(...)`, which reads as an
assertion string, while `ZITI_INVALID_CONFIG` is a public enum the agent has to *start returning* in
situations that do not exist at base. It cannot be read off current behaviour, so naming it is
contract rather than leakage.

Phase B was re-run in full against the final zip `c173f29f` after this edit, because any edit voids
the previous battery.

### Files this round touched

`instruction.md`, `environment/problem_statement.md`, `solution/golden.patch`, `tests/tests.patch`,
`tests/config.json`. Nothing else in the bundle moved.


## Round 3, 2026-08-09

### Freshness

Fresh on all four axes against zip `c173f29f`. `instruction.md:19,30,40` and
`tests/tests.patch:94-794` and `tests/config.json:4-30` all land where the report says, and it quotes
the round-2 wording verbatim. No axis elided.

### The report, against round 2

`Status: DISCUSS`, and **`Reason` moved from `coverage_gap` to `oracle_spec_gap`**.

| Axis | r1 | r2 | r3 | Note |
|---|---|---|---|---|
| test_coverage | 2.5 | 3.0 | **4.5** | the two rounds of coverage work landed. No longer the reason |
| test faithfulness | 5.0 | 4.0 | **5.0** | recovered by deleting the log assertion |
| oracle spec faithfulness | 2.5 | 3.5 | **3.0** | now the reason. claude 5, gpt 3 |
| over-specification | 2.5 | 4.0 | **3.0** | **regressed, and round 2 caused it** |
| packaging | 1.0 | 1.0 | 1.0 | claude moved 3 to 4, gpt still 1 on the PEM key |

### The blocking finding, measured before acting

> the base integration test still calls `ziti_ctrl_init` with a bare URL
> [environment/repo/tests/integ/ctrl_tests.cpp:21-22] after the patch changes the signature ... and
> the solution patch does not update that file.

Three measurements:

| Question | Answer |
|---|---|
| Is the stale call real? | yes, `ctrl_tests.cpp:22` calls the single-URL form |
| Does it break the build? | **no.** `grep -rn ctrl_tests tests/ --include=CMakeLists.txt` returns nothing. The file is in no target and never compiles |
| Does the source PR touch it? | no, 0 hits in the PR diff |
| Has upstream since fixed it? | **yes**, main now has `ziti_ctrl_init(loop(), &ctrl, &cfg->controllers, tls)` |

So the judge's conclusion is right and its mechanism is wrong. The finding attaches to
`instruction.md:40`, which was mine and read *"Every caller in the tree ... is updated"*. **That is
LEDGER L21 exactly: the dependency is the unbounded quantifier, so delete it rather than re-scope
it.** The sentence now says callers build the one-element list instead, and that the library and the
tests it builds today still build afterwards.

The call site was updated to the canonical upstream shape as well, so the misreading cannot recur
(LEDGER L18: change the artefact, do not argue in Comments). It travels in `tests.patch`, which is
where test-file changes belong (Section 10.6) and leaks nothing, because no graded id lives in that
file and the compiler never sees it.

### The over-specification regression was self-inflicted

Round 2 added *"The old form goes away rather than staying on beside it"* to answer a round-2 clarity
ambiguity. Both judges then quoted that exact clause and dropped the score a notch. No test asks for
it. Removed, and the ambiguity is covered by saying the other parameters are unchanged. **Fixing a
4.0 nit cost a full point on another axis, which is the thing to remember.**

### Three cheap coverage clauses closed, no new ids

gpt's 4/5 named them, and all three went into existing cases so `fail_to_pass` stays at 19:

- a peer publishing only an older edge API must be ignored (a fourth peer in the fixture)
- a cancelled request must not move the endpoint, the one negative code that is not a failure
- `ziti_context_init` rejecting a config naming no controller, and accepting a legacy-only one

### Probe sweep, 16 of 16, against an extract of zip `734de403`

Three new ones this round, each catching what it was written for: `accepts_peer_with_old_api`
(2 tests), `switches_on_a_cancelled_request` (4 tests), `ztx_init_accepts_no_controller`
(`sentinel_ztx_init_accepts_controllers_only`). The other thirteen all still fire, and the build
break still trips the exit-code gate at `raw_exit_code 1`.

### Phase B against zip `734de403`

NOP 0.0 with `raw_exit_code 1` and `infrastructure_error: None`. Oracle 3/3 at 25 of 25, plus six
back-to-back runs all 1.0. Agent-edit simulation 1.0. Graded set unchanged at 19 f2p and 6 p2p.

### Files this round touched

`instruction.md`, `environment/problem_statement.md`, `tests/tests.patch`. `golden.patch` was **not**
touched this round, which is worth saying plainly given the reason was the oracle: the fix was the
instruction's promise and a dead test file, not the solution.


## Round 4, 2026-08-09

### The judge passed, so the screen ran for the first time

`Difficulty: FAIL EASY - Requires at least MEDIUM`. claude-opus-4-8 **4/4**, codex-gpt-5-5 **3/4**,
so **7 of 8**. oracle 3/3, nop 0/1, `Status: PASS Solvable`. The one failing trial failed exactly
two ids, `sentinel_ctrl_learns_peers_from_controller` and `sentinel_ctrl_prefers_peer_reported_online`,
so peer discovery is already the hardest thing in the bundle.

**The results artifact was not supplied** (`Task Instruction Sufficiency: NOT_APPLICABLE, debug output
not available`), so the failing trial's stdout has not been read. Per LEDGER L36 the headline number
cannot separate a broken build from a real failure. **Ask for it before the next round.**

### The structural cause, stated plainly

Three rounds of judge feedback pushed the instruction toward a complete specification, and a complete
specification is easy for a frontier model. That is the same arc statrs 315 recorded at round 3. The
two goals genuinely pull against each other and this round is the first attempt to pull the other way.

### What this round shipped

Per `probe-the-instruction-you-already-wrote.md`, which is platform-confirmed to have taken a task
from 87.5% to 37.5% by grading one already-stated clause, the first move is to grade what is stated
and unenforced rather than to add requirements. Two clauses were found and graded:

| Clause | Status before | Now graded by |
|---|---|---|
| when none are believed online, any known endpoint will do | stated, unenforced with more than one endpoint | `sentinel_ctrl_failover_visits_distinct_endpoints`, extended |
| a refreshed peer set can leave out the endpoint in use | **neither stated nor graded**, though golden handles it | `sentinel_ctrl_refresh_replaces_dropped_endpoint`, new |

f2p 19 to **20**, which is the hard ceiling, so no slot remains without merging.

**Two probes exposed weak assertions before the platform could.** The first version of the fallback
check asserted the endpoint stayed inside the known set, which a give-up implementation also
satisfies because the url simply never moves; it now requires selection to keep moving across twelve
failures. The client-follows-url invariant was only in one case and detects the broken form about two
thirds of the time, so it is now asserted in a second case as well.

### Levers investigated and rejected, with the measurement

**The auth-method lifecycle inside PR 668 itself.** `version_pre_auth_cb` and `ziti_stop_internal`
carry real stateful behaviour the instruction never describes: the method is chosen from the
capability, reused when the kind matches, force-refreshed when unauthenticated, and stopped on
context stop. Grading it needs a running `ziti_context`, and `init_tls_from_config`
(`library/ziti.c:148-163`) requires a loadable key **and** `set_own_cert` with a certificate.
Measured in the image: `generate_key` and `to_pem` exist, so a key can be made at runtime, but
`ziti_context_run` still returns `ZITI_CONFIG_NOT_FOUND` because there is no certificate, and the
bundle cannot carry one when packaging is already capped at 1 for exactly that reason.
**Rejected on evidence, not on preference.**

**PR 711 with 707, the offline cooldown and version refresh on switch.** Rejected. The naive
composition is an infinite loop that upstream itself shipped for two days, and in this bundle the
failure mode would be a hang against `uv_run(UV_RUN_DEFAULT)` rather than a red test, taking the NOP
and every oracle run with it. The one-minute window is also a non-derivable constant needing a real
wall clock.

### The strong lever for next round, and a defect it also closes

**PR 794 with 678, the `ziti-ctrl-address` redirect path and `ctrl->url` ownership.** This is the
recommended next lever and it is better than anything this round shipped.

**It also names a real defect in the bundle as it stands, which I verified rather than took on
trust:**

| Fact | Evidence |
|---|---|
| `model_map` owns its keys | `library/model_collections.c:122-128`, a key longer than `sizeof(el->key)` gets its own `calloc` |
| golden points `ctrl->url` at a map key | `ctrl->url = ctrl_next_ep(...)`, which returns `model_map_it_key` |
| the redirect path frees it | `library/ziti_ctrl.c:219`, `FREE(ctrl->url)`, pre-existing and untouched by golden |

So a controller answering with a `ziti-ctrl-address` header frees a live map key, and
`ziti_ctrl_close` then frees it again. **I have been disclosing this in Comments for Reviewer since
round 1 as a harmless upstream quirk. It is a latent double free and the disclosure understated it.**
No graded test reaches it, which is why every battery has been green.

Upstream closes it in two parts: 678 makes `ctrl->url` an owned copy, strdup'd at init, at the
failover switch and at the redirect and freed in `ziti_ctrl_close`; 794 then re-keys the endpoint map
when a redirect supersedes an address, so the stated invariant that `url` is always a member of
`endpoints` survives the one path that moves it. Expansion of 668, nothing of 668 replaced, and the
wrong answer aborts the test binary rather than returning a wrong value, so partial credit is
unlikely. Testable airgapped, because the fake controller can simply send the header.

### Phase B against zip `a5846849`

NOP 0.0 with `raw_exit_code 1` and `infrastructure_error: None`. Oracle 3/3 at 26 of 26, plus six
back-to-back runs all 1.0. Agent-edit simulation 1.0. **20 of 20 hostile probes** each naming its
test. Graded set 20 f2p and 6 p2p.

### Honest read on whether this round is enough

Two graded clauses is the documented first move and it is cheap, but it is a small change against a
7-of-8 pass rate, and **no agent control was run**, so the difficulty gain is unmeasured. Per LEDGER
L35 a local control would run on a newer model than the screen grades and would only ever be a
ceiling. If the screen returns EASY again, the next round should be PR 794 with 678 rather than more
clause grading, and the results artifact should be in hand first.


## Round 5, 2026-08-09

### The screen moved

| Round | zip | opus | codex | combined |
|---|---|---|---|---|
| 3 | `734de403` | 4/4 | 3/4 | 7/8 |
| 4 | `a5846849` | **3/4** | 3/4 | **6/8** |

MEDIUM needs at most 4 of 8. So round 4's two graded clauses were worth one opus run, which is real
and is the reason this round used a bigger lever of the same class rather than a different one.

**The unit-test table lists 7 runs against 8 agent runs**, so one run produced no test output at all.
Of the two failures, one is a genuine peer-discovery failure and one never reached the tests. That is
exactly the distinction LEDGER L36 says the headline cannot make, and **the artifact was again not
supplied**. Ask for it.

### What this round shipped: openziti 678 and 794

Identified in the round 4 survey and recommended then. Two halves:

**678, a correction under `docs/guidelines.md:284-291` case 1.** golden pointed `ctrl->url` at a key
the endpoint map owns, and the pre-existing redirect path frees it. Verified before touching
anything: `model_collections.c:122-128` shows a key longer than a pointer gets its own allocation,
and `ziti_ctrl.c:219` does `FREE(ctrl->url)`. **That is a double free the bundle has been carrying
since round 1**, unreachable from the graded tests. The controller now owns its url at all four sites
that touch it (init, the failover switch, the reselect after a refresh, the redirect) and releases it
on close.

**794, an expansion for difficulty.** A redirect now moves the endpoint inside the set rather than
just repointing `url`: the superseded address leaves, the new one takes its place, the set keeps its
size, and `url` is still a member.

Declared under PR additions. The file list is unchanged, still the source PR's six non-test files.

### Why this is a stronger lever, measured

Two probes take the **whole test binary** down rather than failing one id:

| Probe | Effect |
|---|---|
| `url_borrows_the_map_key` (the pre-678 ownership) | **15 tests** fail |
| `keeps_dropped_endpoint_after_refresh` | **26 tests**, the entire graded set, because the process aborts |

That is the property the survey predicted and the reason this lever should discriminate where clause
grading only nudged: the wrong answer crashes rather than returning a wrong value, so there is no
partial credit. Four existing ids already `REQUIRE(ctrl.url != nullptr)` after every failed request,
so a half-correct ownership answer fails tests it was previously passing.

### Probe sweep, 20 of 20, against an extract of zip `1c2a3fb7`

Two new probes this round (`redirect_only_moves_url`, `url_borrows_the_map_key`), and the anchors of
three existing ones were refreshed because the ownership rework moved the code they patch. **One
probe was wrong rather than the coverage being thin**: after the rework the client is initialised
*from* `ctrl->url`, so pointing `url` elsewhere no longer breaks the invariant. Retargeted at the
`tlsuv_http_init` argument, where the divergence is still expressible, and re-verified 5 attempts out
of 5. That is `probe-the-instruction-you-already-wrote`'s assert-the-sabotage-landed mechanic
catching a rotted probe.

### Graded set

`sentinel_ctrl_init_single_endpoint` was folded into `sentinel_ctrl_init_populates_endpoint_map` to
free a slot at the hard ceiling of 20, losing no assertion, and
`sentinel_ctrl_redirect_rekeys_endpoint_set` took it. Still 20 f2p and 6 p2p.

### Phase B against zip `1c2a3fb7`

NOP 0.0 with `raw_exit_code 1` and `infrastructure_error: None`. Oracle 3/3 at 26 of 26, plus six
back-to-back runs all 1.0. Agent-edit simulation 1.0. Build break still trips the exit-code gate.

### Honest read

The lever is much stronger than round 4's and it closes a real defect either way, so it is worth
shipping on its own merits. Whether it reaches MEDIUM is still unmeasured against agents: no
implementation control was run, and per LEDGER L35 a local control would run on a newer model than
the screen grades and could only ever be a ceiling. If the screen returns EASY a third time, that is
strike 3 on a lever class that has now moved the number twice, and the next conversation is about
scope rather than about another lever.


## Round 6, 2026-08-11

### Feedback, verbatim

```
## Difficulty Check
Blocked at the difficulty screen (cheap single-arm rollout).

Difficulty: FAIL EASY - Requires at least MEDIUM
Status: PASS Solvable (all tests passed by at least one agent run)

Agent Performance:
  - claude-opus-4-8: 75.0% (3/4 runs)
  - codex-gpt-5-5: 100.0% (4/4 runs)

Reference Agents:
  - nop: 0.0% (0/1 runs)
  - oracle: 100.0% (3/3 runs)

Unit Tests Results:
  - every one of the 26 graded ids: 7 passed / 7 runs

Analysis on Agent Failures:
  - Task Instruction Sufficiency: NOT_APPLICABLE, debug output not available

## Automated feedback
Agent Runner Summary: Evaluation FAILED. Review gate blocked at the difficulty screen
(cheap single-arm rollout)
```

### Freshness check on the report, four axes

| Axis | Result |
|---|---|
| Test ids | all 26 named ids exist in the current `tests/config.json`, including `sentinel_ctrl_redirect_rekeys_endpoint_set` which only round 5 added |
| Line numbers | none cited |
| Commands | 26 ids match the 26 `execution.commands` entries one for one |
| Instruction text | none quoted |

Fresh, and it is the round-5 bundle `1c2a3fb7`. The presence of the redirect id settles it.

### The round-5 reading was wrong, and this is the correction

| Round | zip | opus | codex | combined |
|---|---|---|---|---|
| 3 | `734de403` | 4/4 | 3/4 | 7/8 |
| 4 | `a5846849` | 3/4 | 3/4 | **6/8** |
| 5 | `1c2a3fb7` | 3/4 | 4/4 | **7/8** |

Round 5 read the 7 to 6 step as the lever class working and scaled it up. The number came straight
back to 7, so **the step was noise at n=4 per model, not signal.** LEDGER L42 was written off that
one step and its own next data point refutes it. Row added to the ledger.

### The decisive number, which is not the headline

The unit table counts **agent runs only**. Proof: `pass_to_pass` ids show the same run count as
`fail_to_pass`, and NOP passes p2p while failing f2p, so if NOP were counted the two would differ.
Oracle is excluded on the same arithmetic.

| zip | ok/8 | runs producing test output | REAL failures | runs with no output at all |
|---|---|---|---|---|
| `734de403` | 7/8 | 8 | 1 | 0 |
| `a5846849` | 6/8 | 7 | 1 | 1 |
| `1c2a3fb7` | 7/8 | **7** | **0** | 1 |

**Every agent that got the project to build scored 26 of 26.** Not one partial result anywhere in
the table. Real, test-reaching failures across the three screens went 1, 1, **0**.

So round 5's lever did not merely measure zero. It shipped alongside the disappearance of the last
genuine failure the bundle had, which was peer discovery on the round-3 screen.

### The run that never reaches the tests, reproduced

Present in rounds 4, 5 and 6. Reproduced locally this round, in the built image with the network off:

```
[1/4] cd /app/build/tests/integ && cmake -E env GOBIN=... go install github.com/openziti/ziti/ziti@v1.1.3
FAILED: tests/integ/CMakeFiles/ziti-cli ...
go: ... dial tcp: lookup proxy.golang.org ...: network is unreachable
ninja: build stopped: subcommand failed.
```

`add_custom_target(ziti-cli ALL ...)` is in the default target and a custom target is always out of
date, so the obvious command `cmake --build build` fetches over the network every time. The verifier
escapes it by naming its targets; the **agent** does not. This is the hazard
`cmake-reconfigure-needs-network.md` recorded at round 0 as unfixable in the Dockerfile, and that
disposition is being re-tested this round, because Phase A checklist item 3 requires test
dependencies to be baked into the image rather than fetched at test time.

Consequence for every difficulty reading so far: the screen has been scoring 8 runs of which one is
poisoned by an environment trap. The honest denominator is 7.

### Related PR survey, completed against the real commit history

Round 4's survey was done from PR numbers. Redone this round from
`repos/openziti/ziti-sdk-c/commits?path=library/ziti_ctrl.c` over the 12 months after 668 merged
(2024-06-07), which is the complete list of changes to the failover file.

| Commit | Subject | Disposition |
|---|---|---|
| `9435f7777` | make sure ctrl.url is valid | **shipped** round 5 (678) |
| `2e5f4bd4d` | update ctrl list with new advertised address | **shipped** round 5 (794) |
| `36fa75fb9` | refresh ctrl.version when switching | rejected round 4, non-derivable constant |
| `0af597041` | avoid churn when controller(s) are down | rejected round 4, naive form hangs `uv_run` and takes NOP and oracle with it |
| `620d2612d` | make sure ctrl.endpoints map is not empty | **new candidate**, probed this round |
| `26096590a` | handle redirect before invoking response callback | **new candidate**, probed this round |
| `eb31e413a` | set internal OIDC endpoint to active controller | rejected, needs a live authenticated context, same certificate blocker as the auth lifecycle |
| others | enrollment, MFA, parsing, error mapping, ext-jwt | not the failover surface, out of PR 668's scope |

`26096590a` is live in this bundle as shipped. `ctrl_default_cb` invokes `resp->resp_cb` first and
touches `resp->ctrl` afterwards, which is upstream's pre-fix ordering, and upstream's message names
the reason: *controller may be disposed in callback*. **Round 5's re-keying enlarged it**, because
the block after the callback now also does `model_map_remove` and `FREE(ctrl->url)`.

### The implementation control, run at last

Round 4 recorded that no agent control had been run and that the difficulty gain was therefore
unmeasured. Run this round, by the method in `difficulty-levers-must-discriminate.md`.

Setup: four independent implementations, each in its own copy of the repo at the base commit,
each given `instruction.md` and nothing else. No `golden.patch`, no `tests.patch`, no
`config.json`, and each was told not to consult upstream. Confirmed absent from every working
copy before the agents started. Each was then evaluated by applying its library-only patch,
applying the shipped `tests.patch` on top, and running all 26 graded ids in the built image.

| Implementation | Graded result | Internal design |
|---|---|---|
| oracle (`golden.patch`) | 26 of 26 | `ziti_controller_detail` values, owned `url` |
| impl 1 | **26 of 26** | own `{char *url; bool online;}` value, two-pass scan, first-list-entry start |
| impl 2 | **26 of 26** | own endpoint struct, `ctrl_use_endpoint` helper, marks online on success |
| impl 3 | **26 of 26** | own `ctrl_endpoint_t`, `select_endpoint`, drops unparseable URLs |
| impl 4 | **26 of 26** | own `ctrl_endpoint`, index sweep from current, closes client before freeing url |

Four for four, every one with a different internal design, none of them golden's. Added to the
platform's seven agent runs at 26 of 26, that is **eleven independent implementations and not one
failed requirement.**

Two secondary results worth keeping:

- **The suite is not overfitted.** All four invented their own map value type, and all four
  passed, because the graded assertions read keys, size, membership and observable behaviour
  rather than golden's internals. Three of the four flagged the value type as a guess they
  expected to be caught on. It was not, and that is the suite working correctly.
- **The divergences are real but all sit in unspecified territory.** Where the four differ, they
  differ on things the instruction deliberately leaves open: which endpoint is picked first
  (first list entry versus map iteration order), whether a mid-response body-read failure also
  triggers failover (impl 1 and impl 3 yes, impl 2 and impl 4 no), whether an endpoint is marked
  online again when it answers, and whether an empty peer refresh keeps the old set. **Every
  behaviour the instruction states is implemented identically by all four.**

That is the L34 tell stated exactly, and it closes the lever question rather than opening it.
Grading a divergence would be `overreach`, because the instruction does not state it. Stating it
first would put the answer in the prompt, which is the trap L29 to L33 measured four times on
redisshake 1005. There is no third door.

### `pass_at_k` 0/3 on arrival does not mean this task was ever hard

The original `instruction.md` is one 5-paragraph block that names `library/ziti_ctrl.c`,
`inc_internal/ziti_ctrl.h`, the exact new signature, every struct field (`endpoints`, `url`,
`active_reqs`, `is_ha`), `library/ziti_enroll.c`, `library/ziti.c`, `library/config.c`,
`ztx_get_controller`, `ztx->controllers`, `tlsuv_http_set_url`, `ZITI_INVALID_CONFIG`,
`CONTROLLER_UNAVAILABLE` and `HA_CONTROLLER`. It hands over the entire implementation and it
scored **0/3 on both models**.

The current instruction names none of those paths and scores 7/8. **Information was never the
variable.** Whatever produced the arrival 0/3, it was not the task being intellectually hard, and
the `difficulty = "hard"` metadata rests on it. The `ziti-cli` build trap reproduced above is the
most plausible candidate, since an agent that cannot build cannot iterate, but the bundle shipped
no `runs/` so this stays a hypothesis with a reproduction behind it rather than a finding.

### Strike table update

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Difficulty screen `FAIL EASY` | 4, 5, 6 | r4 graded two stated-and-unenforced clauses; r5 adapted openziti 678 and 794 | **3** |

Two levers of two different classes, both measured at zero once the noise is removed. Section 4's
two-strikes rule and LEDGER L32 both say the same thing at this point: stop adding, diagnose the
shape. The shape is diagnosed above and it is not fixable by a third lever.

### Round 6, what shipped and the measurement behind it

Two changes, one of them the first difficulty lever on this task measured before upload.

**1. The `ziti-cli` build trap, fixed.** `environment/Dockerfile` now runs
`go install github.com/openziti/ziti/ziti@v1.1.3` at image build time, where the network is
allowed, then sets `ENV GOPROXY=off` so the cached copy is reachable at run time. Measured in the
shipped image with the network off: `cmake --build build` went from `dial tcp: lookup
proxy.golang.org ... network is unreachable` to **exit 0**. The cache alone is not enough, because
`go install pkg@version` resolves the version through the proxy before consulting the cache. Cost
360 MB. Allowed under `docs/guidelines.md`, *External-network dependency at build/solve time*, and
required by Phase A checklist item 3.

**This makes the headline difficulty number worse and is still right.** It converts a run that
never reached the tests into one that does, so the screen should now read 8 usable runs. Difficulty
that comes from an agent meeting a network wall on the obvious build command is what
`sentinel-difficulty-scope` calls the wrong kind of hard.

**2. The version follows the endpoint in use.** Adapted from openziti `36fa75fb9`, *refresh
`ctrl.version` when switching*, a related later PR in the same failover surface. Three of the four
independent implementations volunteered this gap unprompted before it was ever written down.

Adapted, not copied. Upstream re-requests the version eagerly at the switch site; on this bundle
that risks an endless switch, request, fail chain against `uv_run`, which is exactly why PR 711 was
rejected in the round 4 survey. Golden instead clears the cached version at all three
endpoint-change sites and lets the next caller re-learn it lazily. Same contract, no traffic, no
hang.

| Tree | before this round | after |
|---|---|---|
| oracle | 26 of 26 | **26 of 26** |
| impl 1 | 26 of 26 | **25 of 26** |
| impl 2 | 26 of 26 | **25 of 26** |
| impl 3 | 26 of 26 | **25 of 26** |
| impl 4 | 26 of 26 | **25 of 26** |

All four fail on the new id and on nothing else. That is 4 of 4 discrimination against
implementations that had a clean sheet an hour earlier, and it is the control
`difficulty-levers-must-discriminate.md` prescribes and that rounds 4 and 5 both skipped.

**The honest limit on that number.** Those four were written *before* the instruction stated the
requirement. 4 of 4 says this is a genuine blind spot, not that the screen will drop. Per LEDGER
L35 a local control on a newer model than the screen grades is a ceiling, never a forecast.

**Two false leads, killed with measurements rather than reasoning.** `26096590a`, the
redirect-before-callback reorder, was implemented and reverted: it clears the version *before*
`internal_version_cb` stores it, so it defeats the requirement it was supposed to help. And the
close-from-inside-the-callback crash that all five trees showed is **my own
`assert(ctrl->active_reqs > 0)`**, added by `golden.patch`; base has no `active_reqs` at all. It is
not an upstream defect and grading it would have invented scope.

**Id budget.** `fail_to_pass` was at the hard ceiling of 20. `sentinel_ctrl_failover_stays_in_endpoint_set`
was folded into `sentinel_ctrl_failover_switches_endpoint`, every assertion preserved, since both
express one contract. That freed the slot the new case took. Still 20 f2p and 6 p2p.

### Phase A against `work/`

Shipped tree clean, HEAD equals `base_commit_sha`, no remotes, no refs past HEAD, no reflog,
`.git` 2.1 MB, `git fsck --unreachable` silent, both patches apply, `problem_statement.md`
byte-identical, scripts 0755, grader gates on `raw_exit_code`, no source-shape grading, all 12
backticked instruction identifiers present in both patches, no `apt-get upgrade`, no unpinned pip,
no bare-branch `git+https`. The one stray-sweep hit is `environment/repo/.idea`, tracked at the
base commit and therefore not deletable, excluded from the image by `.dockerignore` and by the
`rm -rf` after the `COPY`, exactly as in earlier rounds.

### Phase B against the extracted zip `29f00bd9`

Three fresh extracts of the built zip, run through the shipped `test.sh` and `solve.sh` in the
rebuilt image with `--network=none`.

| Run | Result |
|---|---|
| NOP | reward **0**, `raw_exit_code 1`, `infrastructure_error: None`, 26 required ids missing |
| Oracle | **3 of 3** at reward **1.0**, every solve and test exit 0, three consecutive applies in one container |
| Hostile delete | stubbed the new requirement by removing its 3 call sites, reward dropped to **0.0**, caught by `sentinel_ctrl_version_follows_the_endpoint_in_use` |

The NOP zero is the compile-abort kind again, as in every prior round on this bundle: the graded
module does not build at the base commit because `endpoints`, `active_reqs` and the list-taking
`ziti_ctrl_init` do not exist there. Genuineness of the new id rests on the same symbol audit, not
on an executed subset, and the symbols it touches (`ctrl.url`, `ctrl.endpoints`) are absent at base.

`find work -newer upload/<zip>` prints nothing, so the battery ran against the artifact that ships.


## CLOSED, accepted, 2026-08-11

**Outcome: ACCEPTED.** Reported by the submitter on 2026-08-11 against zip `29f00bd9`, the round 6
bundle. Final round number 6, seven uploads across the arc.

**What was NOT captured, and it should have been.** The submitter's message said the task was
accepted and nothing else, so this file has no final screen result, no reviewer Submission Quality
Score and no reviewer notes. Those are exactly the three things the calibration row and the next
task want, and they are cheap to ask for at the moment acceptance arrives and impossible to
reconstruct afterwards. **Ask for them in the same message that receives an acceptance.**

**What acceptance validates, and what it merely did not catch** (`accepted-bundle-reference.md`).
It validates the things that had previously failed and were then changed, because those were
measured again by the platform: the two coverage blocks from rounds 1 and 2, the oracle spec gap
from round 3, the Q10 instruction leak, and the difficulty screen that blocked rounds 4, 5 and 6.
Everything else in the bundle was merely not caught. In particular the packaging axis sat at 1.0
from round 1 onward on the tracked PEM key in `environment/repo/tests/test_ziti_model.cpp:805`, was
escalated and never resolved, and the task was accepted carrying it. **That is a measurement about
the axis, not a permission**: a capped packaging axis did not block acceptance here, on one task,
with everything else clean.

**Final shape.** Fixable. 20 fail-to-pass and 6 pass-to-pass. `golden.patch` 6 files, exactly the
source PR's non-test file list. `tests.patch` 3 files, all pre-existing test files edited in place,
0 created. Full-tree base64 restore in `test.sh`. Instruction 46 lines, longest paragraph 777
characters, no file paths, no leaked literals. `[verifier] timeout_sec` 1800 against
`execution.timeout_sec` 1800, so the Secondary Requirement 1 default it arrived with was cleared.

**The arc, in one line per round.** 0 rewrite of a 6-id bundle with a fail-open verifier. 1 and 2
coverage, closed with an in-process loopback controller. 3 oracle spec gap, closed by deleting an
unbounded quantifier. 4 and 5 difficulty, two unmeasured levers, both worth zero. 6 difficulty,
measured first, and the round that shipped the build-trap fix.
