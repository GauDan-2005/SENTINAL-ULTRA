# 20260805_220102__xaaha_hulak__118

Submission id: 24d6d443
Claimed: 2026-08-06
Repo / PR: xaaha/hulak 118 (https://github.com/xaaha/hulak/pull/118)
Base commit: e1cd5e43d6c0c0a81bf90e9f29aa582e014b2927
Verdict: **Fixable**
Status: **accepted 2026-08-16** (round 3, 4 uploads, zip `675f27cd`)
Round: 3

> **Reading this file.** It was written forward, one block per round, so an earlier block
> describes the bundle as it was then and not as it shipped. Every "not uploaded yet / pending"
> row below was true when written and is superseded by the final upload ledger in the closing
> block at the end, which is the only one describing what the platform actually graded.

Go / `go test` / `golang:1.25`. Adds mouse support to the bubbletea TUI through
`github.com/lrstanley/bubblezone`, across `pkg/tui` and `pkg/tui/gqlexplorer`.

## Arrival record

| Item | Value |
|---|---|
| Platform zip | `download/24d6d443-f797-45d8-87f2-3e3798524e78_submission.zip` |
| Zip sha256 | `d2bc930042a919282cb464234d9107b3cf95c213bfd19a46693ad94001ebbe21` |
| Zip size | 3879894 bytes, 190 entries |
| Packaging | **flat at the zip root** - no `task/` wrapper, no `seed/`, no `*_harborized/`, no `runs/` |
| Symlinks in zip | 0 |
| Pristine extract | `download/original/`, frozen read-only by `bin/pristine-freeze.sh`, 190 of 190 entries verified against the zip |
| Manifest | `download/original.manifest.tsv`, sha256 `7e94e925ea8e5048f5ac5d44c68116946585347ef481cdfb884cd0771537d6a1` |
| Working copy | `work/`, made with `cp -a download/original/. work/` then `chmod -R u+w`, diff-clean against the frozen tree outside `.git` |

**No `runs/` in this download**, so there is no trial evidence to read. Any statement about
agent behaviour on this task has to come from the platform's own difficulty artifact, not from
this bundle (CLAUDE.md Step 2 item 2).

**Arrived measured hard.** `pass_at_k_opus_4_8 = "0/3"`, `pass_at_k_gpt_5_5 = "0/3"`,
`agent_hardened = "true"`, `hardening_cycles = "2"`. Read that against finding 1 below: six
identifiers the graded tests called by name did not exist at the base commit and were never
stated anywhere the agent could see, so a spec-complete implementation scored 0 of 17 by
construction. `learning/prescriptiveness-check.md` warns that this pattern "looks exactly like
difficulty", and the arrival numbers cannot separate the two.

## Upload ledger

| # | Date | Zip sha256 | Size | Checks returned | Outcome |
|---|---|---|---|---|---|
| 1 | 2026-08-06 | `72857eaacf37a2b3c514aab1d20e9b4f36c462d7e59077f2eb9fa609b7953e11` | 3244921 bytes, 225 entries | none yet - not uploaded | pending |

## Handling-time ledger

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 0 | 2026-08-06 | 0 (first pass, not a revision) | 0 |

First-pass fields: review 55, rewrite 145, form 15, total 215. Revisions 70 after round 1.

## Strike counter

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| - | - | - | 0 |

## learning/ notes applied

| Note | What it predicted here | Command that settled it | Verdict |
|---|---|---|---|
| go-task-verifier-gotchas #1 | `go test ./...` can exit nonzero on a correct tree, so the exit-code gate may need the command scoped | ran the command in the image at base and at the oracle | **REFUTED HERE.** Bare exit is **0** both at base and after the oracle, so the whole-repo command keeps the gate safe and no scoping was needed |
| go-task-verifier-gotchas #2 | `golden.patch` may omit a PR file and turn a green test red | paged the PR API, diffed the file lists | **CLEAN.** PR 118 is 13 files; golden touches exactly the 8 non-test ones and `tests.patch` exactly the 5 test ones |
| go-task-verifier-gotchas #3 | Go keeps tests beside the code, so an agent building this feature writes files `tests.patch` needs | `tests.patch` created `pkg/tui/mouse_test.go` next to the new `pkg/tui/mouse.go` | **CONFIRMED**, fixed with the embedded restore |
| go-task-verifier-gotchas #4 | `test.sh` uses `RUNNER=(...)` and dies under dash | `dash -n tests/test.sh` | **CONFIRMED**, fixed with the one-line re-exec guard; `sh /tests/test.sh` now scores 1.0 |
| tests-patch-vs-agent-edits.md + LEDGER L1-L3, L9 | Nothing git-based can restore the tree, and a create-only patch still collides with a file the agent wrote | agent simulation with `.git` deleted | **CONFIRMED**, base64 payload embedded in `test.sh`, proven on two agent-hostile runs |
| verifier-fail-open.md | The stock grader writes reward 1.0 without reading `raw_exit_code` | ran the same break through the gated and the ungated grader | **CONFIRMED AND MEASURED**: stock 1.0 with `raw_exit 1`, this bundle 0.0 |
| solve-sh-idempotency.md | `solve.sh` reverse-applies as its `else` branch | three applies in one container | **CONFIRMED** statically, now forward-only and stable across three applies |
| unreachable-git-blobs.md | Broken `refs/remotes/origin/HEAD` only `fsck` sees | `git fsck --unreachable --no-progress` | **CONFIRMED**, removed; `fsck` silent, and the two graded-test blobs left by regenerating `tests.patch` were pruned |
| dirty-repo-and-symlinks.md | Shipped tree dirty at base | `git status --porcelain` | **CONFIRMED**: `scripts/install-hooks.sh` had lost its exec bit; restored |
| static-checks.md + LEDGER L11 | `fail_to_pass` must sit in 10 to 20 | counted | 17 on arrival, 18 now |
| LEDGER L13 | `allow_extra_failures` stays `true` unless the run executes exactly the graded set | the run is whole-repo | **left `true`**; the exit-code gate polices the rest |
| LEDGER L7 | The 10.3 which-shape one-liner cannot read `pkg/tui::TestX` | resolved by hand | **CONFIRMED trap.** Ids rewritten to the full import path so the grader matches exactly rather than by suffix |
| quality-check-criteria.md | Q9 and Q10 block on their own | ran both detectors after the rewrite | Q9 **0 hits**, Q10 **1 overlap** and it is the required public import path |
| verify-in-the-image.md | A hostile probe can pass because the break never landed | probe 1 in the first sweep | **HAPPENED.** A `sed` delimiter clash left the tree untouched and the probe read 1.0; every probe now asserts its own edit landed |
| stale-test-reports.md | Build-time results faking a pass | parser reads `stdout_stderr` | **NA, evidenced** |
| source-pr-cross-check.md | Page the PR API | two pages fetched | applied |
| local-runs.md | ext4, scratchpad only | `df -Th` | applied |
| raising-difficulty-on-a-wrapper-task.md | Not applicable | arrived at 0/3 | NA |

## Findings

Every one carries a file and a line in the bundle as received.

1. **`tests/tests.patch` graded six identifiers that were absent at base and named nowhere the
   agent could see.** `tests.patch:247` `model.operationZoneID(1)`, `:283` `model.endpointZoneID(1)`,
   `:318` `model.detailForm.itemZoneID(model.detailMousePrefix(), 0)`, `:353` `model.searchZoneID()`,
   `:515` `m.itemZoneID(1)`, `:541` `m.searchZoneID()`. `git grep` at HEAD returns nothing for any
   of them and `instruction.md` never states them. Go compiles per package, so one wrong private
   name fails the whole test binary: the blast radius is 17 of 17 graded ids for an implementation
   that meets the written spec in full.
2. **`tests/config.json:37` ships `"pass_to_pass": []`** with `allow_extra_failures` true, against
   330 existing tests in the two packages the patch edits, while `instruction.md:54` requires that
   every existing behaviour keep working.
3. **`tests/test.sh:507` is the stock fail-open grader**: `success = not missing_required and not unexpected`,
   with `raw_exit_code` recorded at `:446` and `:470` and never read.
4. **`tests/test.sh:69-70` applies `tests.patch` with no restore of any kind**, and the patch
   creates `pkg/tui/mouse_test.go`, the file an agent writes for its own `pkg/tui/mouse.go`.
5. **`solution/solve.sh:9` reverse-applies `golden.patch` as its `else` branch**, so a second
   oracle run undoes the solution. The platform runs the oracle three times.
6. **`instruction.md` named five internal source files and one method to modify** (`pkg/tui/mouse.go`,
   `pkg/tui/dropdown.go`, `pkg/tui/selector.go`, `pkg/tui/gqlexplorer/model.go`,
   `pkg/tui/gqlexplorer/formitem.go`, and "Within `Update`, a `tea.MouseMsg` is handled ahead of key
   handling"), which is Q9 navigation.
7. **`instruction.md` restated the graded expectations** as worked examples, including the cursor
   index, the selected string, the zone end coordinate, and the item count after a click.
8. **`instruction.md:52` carried "Do not modify any test files"**, an environment spoiler that names
   the graded artifact and does not stop an honest agent writing its own test.
9. **Three stated requirements had no assertion**: dropdown index clamping and the empty-options
   behaviour (`instruction.md:19`), and non-click mouse events still reaching the input and the
   viewport (`instruction.md:25`).
10. **Git metadata.** `git fsck` reported `refs/remotes/origin/HEAD: invalid sha1 pointer 0000...`,
    which `git remote` and `for-each-ref` both miss; `git status --porcelain` reported
    `scripts/install-hooks.sh` modified, a lost executable bit.
11. **Both `tests/test.sh` and `solution/solve.sh` shipped at mode 0644**, and `test.sh` does not
    parse under dash because of its `RUNNER=(...)` array.
12. **`task.toml`**: `repo_license = ""` against an MIT LICENSE, `[environment] os` absent,
    `difficulty_explanation` absent, `[verifier] timeout_sec = 300` smaller than the
    `execution.timeout_sec = 1800` it contains, and `[agent] timeout_sec = 1800` against a
    documented 7200 ceiling and an `expert_time_estimate_min` of 150.
13. **`environment/Dockerfile:34` ran `go get golang.org/x/tools@latest`**, an unpinned fetch.

Reported and deliberately not changed: `model_difficulty = "medium"` against `difficulty = "hard"`
(LEDGER L14 - report, never quietly reconcile).

## Files changed

Paths as they appear in the upload zip.

1. `instruction.md` - rewritten. Removed every source-file path and the method-level step,
   removed the worked examples that restated the graded expectations, removed the test-file
   constraint, dropped the `tea.WithMouseCellMotion` requirement that nothing in-process can
   assert, and stated the required public surface instead. 10588 bytes to 6477, longest
   paragraph 705 characters.
2. `environment/problem_statement.md` - re-copied byte for byte.
3. `tests/tests.patch` - regenerated as a create-only patch of two verifier-only files,
   `pkg/tui/sentinel_mouse_test.go` and `pkg/tui/gqlexplorer/sentinel_mouse_test.go`, replacing
   a patch that modified four pre-existing `_test.go` files and created a fifth. The graded
   tests now find their click target by looking for the row in the rendered view instead of
   asking the implementation for a private zone id.
4. `tests/config.json` - `fail_to_pass` 17 to 18 and rewritten to the full import path form so
   the grader matches exactly rather than by suffix; `pass_to_pass` 0 to 331; `-count=1` added
   to the test command; `execution.timeout_sec` 1800 to 600; `selected_test_files_to_run`
   repointed at the two new files.
5. `tests/test.sh` - dash re-exec guard; a base64 archive of the base test tree and the golden
   fixtures embedded in the script, deleted and unpacked before the patch is applied; `set -e`
   emitted into the generated runner; `bash -o pipefail` on the runner; and the exit-code gate
   added inside the grader's success expression.
6. `solution/solve.sh` - replaced with the forward-only four-step shape, plus the dash guard.
7. `task.toml` - `repo_license = "MIT"`, `[environment] os = "linux"`, a
   `difficulty_explanation`, `[verifier] timeout_sec` 300 to 900, `[agent] timeout_sec` 1800 to 7200.
8. `environment/Dockerfile` - `go get golang.org/x/tools@latest` pinned to `@v0.38.0`.
9. `environment/repo/scripts/install-hooks.sh` - executable bit restored to its base-commit
   state. Content untouched.
10. `environment/repo/.git` - metadata only. Removed the broken `refs/remotes/origin/HEAD`,
    expired the reflog, pruned the unreachable graded-test blobs.

## Verification battery

Run against fresh extracts of zip `72857eaa`, in the image built from that extract.

| Run | Result |
|---|---|
| NOP | reward **0.0**, `raw_exit_code` 1, `infrastructure_error` None, 0 of 349 required passed |
| NOP split | the two graded packages compile at base without `tests.patch` and **130 + 200 = 330 top-level tests pass**, so the zero is compile-bound on the graded file and not an aborted run |
| Symbol audit | all 18 `fail_to_pass` bodies touch symbols absent at HEAD (`NewMouseZone`, `ScanMouseZones`, `IsLeftClick`, `Hit`, `ZoneBounds`, `ZonePos`, `MouseZone`, `ViewMarked`, `HandleMouse`, `Dropdown.Expand`, `Dropdown.Select`), each `git grep` at HEAD empty |
| Oracle, three fresh containers | **3/3** at reward 1.0, 349 of 349, `raw_exit_code` 0, 3 s each |
| Oracle, three applies in one container | reward 1 each time, tracked changes stable at 8, runs two and three print "already applied" |
| Oracle under `sh` | `sh /solution/solve.sh && sh /tests/test.sh` gives reward 1.0 |
| Hostile delete | **18 probes, every one drops the reward to 0.0 and names the test that caught it** (list below) |
| Exit-code gate | same break, this bundle **0.0** with `raw_exit 1`, stock grader **1.0** with `raw_exit 1` |
| Agent-hostile restore | agent writes its own `mouse_test.go`, edits `dropdown_test.go`, deletes `model_test.go`, commits, removes `.git` -> **1.0 at 349/349**; agent occupies both graded paths and deletes `testdata` -> **1.0 at 349/349** |
| Runtime | verifier 1 to 3 s against a 900 s budget; cold image build 40 to 85 s against 900 |

Hostile probes and the test each one tripped:

| Break | Caught by |
|---|---|
| `IsLeftClick` also accepts a press | `TestIsLeftClickOnlyAcceptsALeftRelease` |
| `ZoneBounds` reports the cell past the end | `TestScanMouseZonesKeepsTextAndRecordsBounds` |
| `ZonePos` returns 0,0 outside the region | `TestZoneBoundsAndZonePosOutsideARegion` |
| `MouseZone.ID` stops joining with a colon | `TestMouseZoneIDJoinsPartsWithColons` |
| every zone shares one prefix | `TestMouseZoneIDsDoNotCollideAcrossZones` |
| `Dropdown.Select` stops clamping | `TestDropdownSelectChoosesClampsAndCollapses` |
| `Dropdown.Expand` opens with no options | `TestDropdownExpandAndSelectWithoutOptions` plus base `TestDropdownExpandNoopWithEmptyOptions` |
| the picker view stops scanning zones | `TestSelectorClickOnARowSelectsAndConfirmsIt` plus three golden tests |
| clicking a picker row no longer confirms | `TestSelectorClickOnARowSelectsAndConfirmsIt` |
| the picker ignores a search click | `TestSelectorClickOnTheSearchAreaFocusesTheInput` |
| the explorer ignores a search-box click | `TestExplorerClickOnTheSearchBoxFocusesTheListAndTyping` |
| an operation click stops moving the cursor | `TestExplorerClickOnAnOperationRowMovesTheCursorAndFocusesTheList` |
| an endpoint click never toggles | `TestExplorerClickOnAnEndpointRowTogglesItBothWays` |
| a detail click never focuses the panel | `TestExplorerClickOnADetailRowFocusesTheDetailPanel` |
| `HandleMouse` claims every click | `TestDetailFormMarkedViewMatchesThePlainViewAndClickFocusesTheInput` |
| marking changes what the form draws | `TestDetailFormMarkedViewMatchesThePlainViewAndClickFocusesTheInput` |
| an expandable field never inserts children | `TestDetailFormClickOnAnExpandableFieldAddsItsChildRows` |
| an open dropdown ignores which row was clicked | `TestDetailFormClickExpandsADropdownThenPicksTheClickedOption` |

## Local Quality Check rehearsal

| Axis | Score | Evidence |
|---|---|---|
| realism | 4 | reads as a ticket, no numbered how-to |
| clarity | 4 | longest paragraph 705 characters |
| self_containedness | 4 | every named symbol is a deliverable or exists at base |
| prescriptiveness | 4 | one residual, the library name, kept deliberately |
| test_coverage | 5 | 18 hostile probes, each naming its test |
| test_faithfulness | 5 | every assertion maps to a stated clause; no non-derivable name left |
| oracle_spec_faithfulness | 5 | golden matches the PR at 8 of 8 non-test files |
| oracle_no_gaming | 5 | patch application only, nothing outside `golden.patch` |
| oracle_robustness | 5 | forward-only, idempotent across three applies |
| packaging | 5 | no stray artifacts, `fsck` silent, `tests/` legal |

Q9 detector: **0 hits**. Q10 detector: 97 long literals added by `tests.patch`, **1** appears in
`instruction.md` and it is `github.com/xaaha/hulak/pkg/tui`, the import path the agent has to
create the API under. That is the "required public name" row of the triage table, the same shape
as the seven overlaps the accepted kvdex bundle shipped.

## Check history

Nothing yet. The bundle has not been uploaded.

---

# Revision round 1 - 2026-08-08

Source: peer reviewer, after every platform eval passed. Result Fixable, Acceptable as-is No.

## Freshness check (Step 10 item 0b)

| Axis | Result |
|---|---|
| Test ids | `TestSelectorScrollStillReachesTheViewport` is in the current `pass_to_pass`. The counts it quotes, 18 fail-to-pass and 331 regression tests, match `tests/config.json` exactly |
| Line numbers | `instruction.md` lines 30, 39, 42 and 47 each carry the requirement the note attributes to them, read line by line |
| Commands | It describes the raw Go command having to exit successfully, which is the exit-code gate added in round 0 |
| Instruction text | Every requirement it quotes is present in the current `instruction.md` |

Fresh on all four axes. It describes the round 0 bundle, zip `72857eaa`.

## Feedback, verbatim

```
Submitter assessment: Correct - the task is Fixable.
Result: Fixable
Acceptable as-is: No
Summary: The repair removes the undocumented private helper requirements, uses additive behavioral
tests, restores broad regression coverage, and passes Oracle 3/3, NOP 0/1, quality 15/15, and the
Medium difficulty gate. Several explicit mouse-behavior requirements remain untested, and the final
repository and metadata are not cleanly aligned.
Verification of submitter description:
Confirmed that the six undocumented private zone-ID helpers are no longer used.
Confirmed that tests.patch adds only two verifier-owned files.
Confirmed 18 fail-to-pass tests and 331 listed regression tests.
Confirmed that test.sh restores the base test tree before injecting verifier tests and requires the
raw Go command to exit successfully.
Confirmed that the oracle is forward-only and idempotent.
Confirmed Oracle 3/3, NOP 0/1, quality 15/15, and Medium difficulty with Opus 4/4 and Codex 2/4.
The claims of complete behavioral coverage and clean repository packaging are not confirmed.
Required fixes:
Test Coverage Issues - High
Several explicit requirements in instruction.md have no corresponding behavioral assertion:
instruction.md:39 requires ViewMarked with an empty prefix to behave like the ordinary unmarked
View. The existing marked-view test uses a non-empty prefix only.
instruction.md:30 requires clicks to resolve against the left panel before the detail form. The
tests exercise each region separately but never create or simulate a competing hit that verifies
this priority.
instruction.md:42 requires a non-expandable toggle row to behave like the space key. The suite
checks an expandable toggle and dropdown/text rows, but not a plain toggle.
instruction.md:47 requires both scroll and drag events to continue reaching the filter input and
list. TestSelectorScrollStillReachesTheViewport covers wheel scrolling only; no drag behavior is
tested.
Add focused tests for these four behaviors or remove any requirement that is not intended to be
graded. Keep the fail-to-pass total within the supported 10-20 range by consolidating redundant
cases if necessary.
Metadata Issues - Medium
task.toml remains inconsistent and stale:
model_difficulty = "medium"
difficulty = "hard"
recorded Opus rate 0/3
recorded Codex rate 0/3
The current valid evaluation reports Medium with Opus 4/4 and Codex 2/4. Set both difficulty fields
to Medium and update the pass-rate fields to the current results.
Environment - Medium
The final shipped repository is dirty because scripts/install-hooks.sh changed from mode 100755 to
100644. This contradicts the submitter's claim that executable modes were restored.
Restore that executable mode and repeat git status, git fsck, and both patch-application checks
after a ZIP round trip.
```

Difficulty artifact and Agentic Judge Quality Report: not requested, because no check failed. Every
eval passed and the feedback is a human reviewer's.

## Round 1 item list

| # | Finding | Verdict | Action |
|---|---|---|---|
| 1 | `instruction.md:39`, empty-prefix `ViewMarked` untested | correct | fold into the existing marked-view test |
| 2 | `instruction.md:30`, left panel before detail form untested | correct that nothing asserts it, and the ordering is **unobservable** | reword the requirement and strengthen the search-box test with the negative half |
| 3 | `instruction.md:42`, plain toggle row untested | correct | one focused new test |
| 4 | `instruction.md:47`, drag untested | correct | extend the scroll test to cover drag |
| 5 | task.toml difficulty and pass rates stale | correct | set both fields to medium, record Opus 4/4 and Codex 2/4, reviewer asked directly |
| 6 | `scripts/install-hooks.sh` mode | not reproducible from the zip, but the symptom is real for any extractor that drops permission bits | normalise the mode and make the tree read clean whatever unpacked it |
| 7 | not from the reviewer, from `learning/empty-git-refs.md` L26 | `.git/refs/heads` ships EMPTY, and on a Go task that is oracle-fatal | write the loose ref back after the gc and set `-buildvcs=false` |

## Round 1, what changed

| File | Change |
|---|---|
| `tests/tests.patch` | one new graded test for the plain toggle row, `TestSelectorScrollStillReachesTheViewport` renamed and widened to `TestSelectorScrollAndDragStillReachTheListWithoutSelecting`, and seven assertions added to tests that already existed. f2p 18 to 19, no case merged |
| `instruction.md` + `problem_statement.md` | the click-priority sentence rewritten twice. First to "acts on the one region it lands on and leaves every other region alone", which is an unbounded universal and exactly LEDGER L21, then to the bounded claim the tests make, "A click the left panel handles must not also reach the detail form" |
| `tests/config.json` | f2p 19, the renamed regression id, `execution.env` set to `GOFLAGS=-buildvcs=false` |
| `tests/test.sh` | the pre-restore wipe now removes a directory or symlink at a test path as well as a regular file, and the runner appends to the error log instead of truncating it |
| `task.toml` | `difficulty` and `model_difficulty` both `medium`, `pass_at_k_opus_4_8` `4/4`, `pass_at_k_gpt_5_5` `2/4`. Reviewer asked directly, LEDGER L14 carve-out |
| `environment/Dockerfile` | `ENV GOFLAGS="-buildvcs=false"` |
| `environment/repo/scripts/install-hooks.sh` | mode normalised to 0755 |
| `environment/repo/.git` | `refs/heads/main` written back as a real file after the gc, `core.fileMode = false` |

## Round 1, the two findings that were mine, not the reviewer's

1. **My own round-1 reword was the L21 mistake.** Replacing an untestable ordering claim with
   "leaves every other region alone" swapped a false specific for an unbounded universal, which is
   the AltBeacon round 6 pattern verbatim. Caught by the re-analysis before the zip. The shipped
   wording is bounded and is what the assertions check.
2. **`.git/refs/heads` shipped empty** (`learning/empty-git-refs.md`, LEDGER L26). Fixed twice, the
   loose ref and `-buildvcs=false`.

## Round 1, the click-priority measurement

The reviewer asked for a competing hit. There is not one. On a live model at 160 by 40 with both
regions registered:

```
  search       x   2..45   y  2..4
  operation0   x   2..47   y  8..9
  operation1   x   2..11   y 10..10
  detailitem0  x  53..74   y  4..7
  cells inside BOTH a left-panel zone and the detail-form zone: 0 of 6400
```

The panels never share a cell, so the ordering is unobservable. What IS observable is that a click
the left panel handles must not also move the detail form, and reversing the two handlers while
making the form claim every click now fails `TestExplorerClickOnTheSearchBoxFocusesTheListAndTyping`.

## Round 1, the mode finding reproduced and fixed

| Extraction of the shipped zip | mode | `git status --porcelain` |
|---|---|---|
| `unzip` | 755 | empty |
| Python `zipfile.extractall` | 664 | empty |
| Python `zipfile.extractall`, `core.fileMode` forced back to `true` | 664 | ` M scripts/install-hooks.sh`, `old mode 100755 / new mode 100644` |

The third row is the reviewer's line verbatim. The zip always carried the bit; the extractor dropped
it. `core.fileMode = false` makes the tree read clean either way.

## Round 1 battery, against zip `04a22a2d`

| Run | Result |
|---|---|
| NOP | reward **0.0**, raw exit 1, infra None, 0 of 350 |
| NOP split | both graded packages compile at base without `tests.patch`, 130 + 200 = 330 pass |
| Oracle, three fresh containers | **3/3** at 1.0, 350 of 350, 3 s each |
| Oracle, three applies in one | reward 1 each, runs two and three print "already applied" |
| Oracle under `sh` | 1.0 |
| Hostile delete | **15 probes**, every one drops to 0.0 naming its test |
| Exit-code gate | this bundle 0.0, stock grader 1.0, same break |
| Agent-hostile | committing agent with deleted base tests and a symlink at a test path 1.0 at 350/350; agent on both graded paths with fixtures deleted 1.0 at 350/350 |
| `.git` four-state matrix | intact, empty-dirs-deleted, refs-removed, git-removed all **1.0** |
| Zip round trip | `unzip` and Python `zipfile` both give an empty `git status`, a silent `fsck`, and both patches applying |

Blast radius correction worth keeping: the verifier survived all four `.git` states **even before**
the fix, because the graded command is `go test` and not `go build`. The oracle was never at risk on
this bundle. `go build ./...` on a half-present `.git` does fail with
`error obtaining VCS status: exit status 128`, so the cost was the agent's, not the oracle's.

## Handling-time ledger

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 0 | 2026-08-06 | 0 (first pass, not a revision) | 0 |
| 1 | 2026-08-08 | 70 | **70** |

## Upload ledger

| # | Date | Zip sha256 | Size | Checks returned | Outcome |
|---|---|---|---|---|---|
| 1 | 2026-08-06 | `72857eaa…` | 3244921 bytes | static, difficulty, oracle, quality all green | reviewer Needs Revision, 3 items |
| 2 | 2026-08-08 | `04a22a2d0d6d904e1216679d01dd539cd6f14e8f3c7324b0ea63f2734a9183c8` | see manifest | **superseded row.** It was uploaded and the screen returned **FAIL EASY** 75/75 | see the closing block |

## Strike counter

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Test Coverage Issues, requirements with no assertion | 1 | six behaviours graded, one requirement reworded to what is observable | 1 |
| Metadata Issues, stale difficulty and pass rates | 1 | both fields set to medium, rates set to the measured ones | 1 |
| Environment, shipped repo reads dirty | 1 | mode normalised and `core.fileMode = false` | 1 |

---

# Revision round 2 - 2026-08-09

Source: the platform eval. Not a reviewer this time.

## Feedback, verbatim

```
## Difficulty Check
Blocked at the difficulty screen (cheap single-arm rollout).
Difficulty: FAIL EASY - Requires at least MEDIUM
Status: Some tests not passed by any agent run (not blocking; require_solvable disabled)
Agent Performance:
  - claude-opus-4-8: 75.0% (3/4 runs)
  - codex-gpt-5-5: 75.0% (3/4 runs)
Reference Agents:
  - nop: 0.0% (0/1 runs)
  - oracle: 100.0% (3/3 runs)
Analysis on Agent Failures:
  - Task Instruction Sufficiency: NOT_APPLICABLE, debug output not available

## Agentic Judge Quality Report
Status:    OK
Reason:    n/a
prescriptiveness  -  2.0/5
  claude (2/5): "transcribing eight exported method signatures plus their edge-case return
    values leaves the agent little latitude beyond typing the bodies" (instruction.md:7-21,
    :25-26, :39-40, module pinned at :5)
  gpt (2/5): "names the exact new public methods and signatures for MouseZone, Dropdown and
    DetailForm, and directs that SelectorModel and Model each get mouse zones and that views
    pass through ScanMouseZones"
```

The judge passed, so the difficulty screen is the only blocking result. Freshness is not in
question, the report is this bundle's own eval.

## The reading

**The two reports are one finding.** Both judges say the instruction hands over the whole API
surface. That is also why agents pass 3 of 4: the hard part was already done in the prompt.

**Deleting names was considered and rejected.** Every symbol the judges name is called by a
graded test, so cutting it trades an advisory axis, which the report marks OK, for a blocking
one. `learning/quality-check-criteria.md` is explicit that a finding quoting a requirement a
graded test asserts is asking you to break the blocking axis. Added behaviour needs no new
names and is the thing the judges said was missing.

## The lever, and the measurement that justified it

Adapted from **xaaha/hulak PR 155, "Bug Fix: GQL UI Issues"**, a later PR in the same repo. It
is about as related as a later change gets, because it patches `DetailForm.HandleMouse`, the
method PR 118 introduces, and it exists because the PR 118 author got it wrong.

`setArgEnabled(argName, v)` sets `enabled` on every item sharing that argument name. An argument
whose type is an input object is drawn as one row per field, all sharing the name, so switching
one switches the lot. The base keyboard path does exactly that, eight lines above the method the
agent has to write, so copying it is the natural move.

Two behaviours were added, both from that PR, neither copied wholesale. **PR 155 changes exactly two
files**, `pkg/tui/gqlexplorer/formitem.go` at +20/-3 and its own test file at +124/-0, re-fetched from
the API 2026-08-16. All three source hunks were adapted because they are one behaviour between them,
and its 124 lines of tests were not taken. An earlier wording here said "its third change and all of
its tests", which invented a third file and double-counted the second:

1. A switch reaches only its own row, unless the row stands for a whole argument or belongs to a
   list argument, in which case the group still follows. Keyboard and mouse share one helper.
2. An optional argument starts every row it expands into switched off, including a field that is
   required in its own right, which still reports itself as required.

**Measured before shipping, per `difficulty-levers-must-discriminate.md`:**

| Plausible implementation | Result |
|---|---|
| copies the base keyboard path (the upstream author's own bug) | **fails** `TestDetailFormToggleReachesOnlyTheRowItBelongsTo` |
| fixes the mouse path, leaves the keyboard path alone | **fails** the same test |
| always switches only the single row | **fails** the base `TestListArgSpaceTogglesAllRows` |
| keeps each field's own required flag | **fails** the same new test |
| clears `required` along with `enabled` | **fails** the new test and base `TestBuildDetailFormExpandsInputObject` |
| the shipped oracle | passes |

One graded id carries all five. The two zone-bounds cases were merged into one to pay for it, so
`fail_to_pass` is still **19** with one slot spare.

## A probe that lied, and the fix

The first run of the optional-argument probe reported **PASSES ALL**, which would have killed the
behaviour as a non-lever. The sabotage had left an unused variable, so the package did not compile,
and a run with no tests looks identical to a run with no failures. Every probe now runs
`go build ./...` first and reports a build failure as an invalid probe. The corrected run fails the
named test. This is `verify-in-the-image.md` again, in a new disguise, and it nearly cost a real
lever.

## Deliberately not done

| Considered | Why not |
|---|---|
| Revert `[agent] timeout_sec` 7200 to 1800 | Starving agents of time makes the task look hard without making the problem hard. `sentinel-difficulty-scope` names that as the wrong kind of hard |
| Undo the round 1 coverage tests | Each grades a requirement the instruction states. Dropping one to shed pass rate trades a real gap for a fake one |
| Cut the API names the judges flagged | Every one is called by a graded test |
| Raise the `difficulty` tier | Editing difficulty metadata to satisfy a check is forbidden. The tier is untouched |

`pass_at_k_*` now carries the freshest platform measurement, 3/4 on both models, and that figure
describes the bundle **before** this round.

## Round 2 battery, against zip `3ca617f9`

| Run | Result |
|---|---|
| NOP | **0.0**, raw exit 1, infra None, 0 of 350 |
| NOP split | both graded packages compile at base, 130 + 200 = 330 pass |
| Oracle, three fresh containers | **3/3** at 1.0, 350 of 350, 3 s each |
| Oracle, three applies in one | reward 1 each, stable |
| Hostile delete | **11 probes**, each drops to 0.0 naming its test, five aimed at the new behaviour |
| Exit-code gate | this bundle 0.0, stock grader 1.0, same break |
| Agent-hostile | committing agent with deleted base tests and a symlink at a test path, 1.0 at 350/350 |
| `.git` four-state matrix | all four **1.0** |

## Handling-time ledger

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 0 | 2026-08-06 | 0 (first pass) | 0 |
| 1 | 2026-08-08 | 70 | 70 |
| 2 | 2026-08-09 | 70 | **140** |

## Upload ledger

| # | Date | Zip sha256 | Checks returned | Outcome |
|---|---|---|---|---|
| 1 | 2026-08-06 | `72857eaa…` | all green | reviewer Needs Revision, 3 items |
| 2 | 2026-08-08 | `04a22a2d…` | judge OK, difficulty screen | **FAIL EASY** at 75% both models |
| 3 | 2026-08-09 | `3ca617f9c01adecba56cb02ea704df138e7b0b9d43313dfb43a7729c7c24790c` | **superseded row.** Intermediate zip, never uploaded | replaced inside the round by `6e930349` |

## Strike counter

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Difficulty screen FAIL EASY | 2 | added scope adapted from related PR 155, two behaviours, five wrong implementations measured failing | 1 |
| Test Coverage Issues | 1 | six behaviours graded, one requirement reworded | 1 |
| Metadata Issues | 1 | tier aligned, pass rates refreshed | 1 |
| Environment, repo reads dirty | 1 | mode normalised, `core.fileMode = false` | 1 |

## Round 2, the second pass after the parallel re-audit

Four audit lenses ran against the round-2 bundle while it was being built. Six findings survived
adversarial verification, and four of them were already applied by the time they landed. The two
that were not, plus three the lenses found in my own round-2 text:

| # | Finding | Action |
|---|---|---|
| 1 | `instruction.md` claimed the keyboard and the mouse reach equally far, and the oracle's mouse text and dropdown branches did not, so a list argument moved as a group under the keyboard and one row at a time under a click | Routed all three mouse branches through the shared helper. Parity measured directly: keyboard `[true true]`, mouse `[true true]` |
| 2 | **My own round-2 constraint line forbade the keyboard change this round makes.** "Everything the keyboard already does has to keep working unchanged" against a round that deliberately changes what the space key does | Bounded the line and named the one behaviour that moves. LEDGER L21 for the third time on this task |
| 3 | The endpoint sentence was a universal the oracle does not honour under a negated search | Narrowed to "switches endpoints the way pressing enter on that row already does" |
| 4 | `instruction.md:30` described the internal control flow of `View()` rather than behaviour | Rewritten as "every view it draws records its regions, including the single stacked panel" |
| 5 | The Send line carried the round-1 sentence appended after the round-2 one and contradicted itself | Rewritten as one line naming the red gate condition |
| 6 | Two banned vocabulary hits in Comments, missed because **my own later grep used a truncated pattern** | Reworded. The full pattern from the rules now returns 0 |

**The parity fix was unasserted until a probe said so.** After routing the mouse branches through
the shared helper, a probe that reverted the text branch still scored **1.0**, which meant the
instruction was promising something no test checked. The graded test now clicks a list row and
compares it against the space key row for row. Reverting the click path fails it with a named
message. That is the second time this round a probe result changed a decision.

## Round 2 final battery, against zip `6e930349`

| Run | Result |
|---|---|
| NOP | **0.0**, raw exit 1, infra None, 0 of 350 |
| Oracle, three fresh containers | **3/3** at 1.0, 350 of 350 |
| Oracle, three applies in one | reward 1 each |
| Hostile delete | **9 probes**, each 0.0 naming its test, five aimed at the round-2 behaviour |
| Exit-code gate | this bundle 0.0, stock grader 1.0, same break |
| Agent-hostile | committing agent, deleted base test, symlink at a test path, **1.0** at 350/350 |
| `.git` four-state matrix | all four **1.0** |
| Zip round trip | `unzip` and Python `zipfile` both clean on all four checks |

## Upload ledger, corrected

| # | Date | Zip sha256 | Checks returned | Outcome |
|---|---|---|---|---|
| 1 | 2026-08-06 | `72857eaa…` | all green | reviewer Needs Revision, 3 items |
| 2 | 2026-08-08 | `04a22a2d…` | judge OK, difficulty screen | **FAIL EASY**, 75% both models |
| 3 | 2026-08-09 | `6e930349728be677923eacd808ece1c5d512d11d98be4d7bdf37e33c916d7de6` | **superseded row.** It was uploaded; judge **DISCUSS**, screen not run | see the closing block |

Intermediate zips `3ca617f9`, `51eaa665` and `d5cd5e77` were built and superseded within this round
and were never uploaded.

---

# Revision round 3 - 2026-08-09

Source: the platform eval. Agentic judge **DISCUSS, Reason overreach**. The difficulty screen did
not run, because the judge gates it.

## The blocking item was mine, and it was a repeat

> one graded test calls an unexported helper `byMouse.itemZoneID(listPrefix, 0)` that is not named
> in the instruction ... A fully correct implementation that marks rows using any other internal
> helper or inline ID construction would fail to compile against this hidden test despite
> satisfying the stated contract.

`tests.patch:376`. **This is the round 0 defect returning**, reintroduced by me in round 2 when I
added the list-row parity check and reached for the helper instead of the screen. Round 0 removed
six of these; round 2 put one back.

Fixed by locating the row the way every other test does, by the text drawn on it. The row renders
`[ ] idsarg [ID]`, so `idsarg` is a unique target.

**The audit that should have caught it, now run over every identifier in both graded files:**

```
identifiers absent at the base commit: 8
   HandleMouse, Hit, IsLeftClick, NewMouseZone, ScanMouseZones, ViewMarked, ZoneBounds, ZonePos
   all named in instruction.md
ABSENT AT BASE AND UNNAMED: none
```

**Run this every round, not only the round you fix it in.**

## A second case of the same shape, found by auditing rather than reported

The barrier my tests use waits for an earlier region to **disappear**, which silently required that
a fresh scan replaces what the previous one recorded. The instruction never said so. Measured:

```
first region recorded=true, still recorded after a later scan=false
=> the barrier used by the graded tests depends on this being false: true
```

So an implementation that kept every region would have failed most of the suite while matching the
written contract. That is overreach of exactly the class the judge blocked on, sitting in a helper
rather than an assertion. **Audit what the helpers require, not only what the assertions say.**
The rule is now stated in the instruction and asserted in the test that already scans.

## The module pin, removed, closing two report items at once

Both readers named `instruction.md:5` first for over-specification, and the same report noted the
constraint was unasserted, so a correct implementation with its own marker encoding would pass while
breaking a stated rule. The instruction now says only that the verifier runs offline and leaves the
marker encoding to the implementer. The oracle still uses the warmed module, which the instruction
neither requires nor forbids.

## Clause sweep, per learning/probe-the-instruction-you-already-wrote.md

Six clauses I was least sure of were broken one at a time in a throwaway copy:

| Clause | Result |
|---|---|
| HandleMouse focuses the row it moved the cursor to | graded |
| the picker marks its search area | graded |
| explorer detail click focuses the detail panel | graded |
| an open dropdown click closes the list | graded |
| Mark leaves the visible text alone | graded |
| **the picker marks every visible row** | **UNGRADED** |

Leaving the first row unmarked passed the whole suite, because no test ever clicked it. Closed
inside the test that was already there, so `fail_to_pass` stays **19**. The lookup needed anchoring
below the search box, because the picker echoes its first item as the placeholder.

## Metadata

The report called the round-2 pass rates invalid evidence, because they came from the cheap single
arm screen. Restored to the last **full** evaluation, Opus 4/4 and Codex 2/4, which is also what the
round-1 reviewer asked for. The pass rates describe round 0's output, three rounds ago. The explanation describes the round-2 lever, which ships. The tier is untouched.

## Round 3 battery, against zip `675f27cd`

| Run | Result |
|---|---|
| NOP | **0.0**, raw exit 1, infra None, 0 of 350 |
| NOP split | both graded packages compile at base, 130 + 200 = 330 pass |
| Oracle, three fresh containers | **3/3** at 1.0, 350 of 350 |
| Oracle, three applies in one | reward 1 each |
| Hostile delete | **10 probes**, each 0.0 naming its test |
| Exit-code gate | this bundle 0.0, stock grader 1.0 |
| Agent-hostile | committing agent, deleted base test, symlink at a test path, **1.0** |
| `.git` four-state matrix | all four **1.0** |
| Zip round trip | `unzip` and Python `zipfile` both clean on all four checks |

## Handling-time ledger

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 0 | 2026-08-06 | 0 (first pass) | 0 |
| 1 | 2026-08-08 | 70 | 70 |
| 2 | 2026-08-09 | 70 | 140 |
| 3 | 2026-08-09 | 70 | **210** |

## Upload ledger

| # | Date | Zip sha256 | Checks returned | Outcome |
|---|---|---|---|---|
| 1 | 2026-08-06 | `72857eaa…` | all green | reviewer Needs Revision, 3 items |
| 2 | 2026-08-08 | `04a22a2d…` | judge OK, screen ran | **FAIL EASY**, 75% both models |
| 3 | 2026-08-09 | `6e930349…` | judge DISCUSS, screen not run | **overreach** on `itemZoneID` |
| 4 | 2026-08-09 | `675f27cda0d8a61f1d304584d0fcea742171d1ee7e9952a8426419871cd08c46` | **superseded row.** It was uploaded, cleared the review gate and reached a reviewer | **ACCEPTED 2026-08-16** |

## Strike counter

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Graded test depends on a name the instruction never states | 0, 3 | round 0 removed six by repointing the tests at the screen; round 3 removed the one round 2 reintroduced, plus an unstated scan semantic a helper depended on | **2** |
| Difficulty screen FAIL EASY | 2 | added scope from related PR 155, five wrong implementations measured failing | 1 |
| Test Coverage Issues | 1 | six behaviours graded | 1 |
| Metadata Issues | 1, 3 | tier aligned; pass rates restored to the full-run figures | 2 |
| Environment, repo reads dirty | 1 | mode normalised, `core.fileMode = false` | 1 |

**Two strikes on the name-dependency signature.** The remove-the-dependency answer is already in
place: graded tests locate targets by rendered text, never by asking the implementation for an id.
Round 3 added the audit that proves it, over every identifier rather than the one a report names.
A third instance means the audit is not being run, not that a new fix is needed.

## Round 3, the answers-file audit

Three independent readers were run over `answers/submission_answer.txt` against the bundle, because
the two previous times this file was declared finished it still carried stale numbers. Thirteen
defects survived adversarial verification. Nine my own mechanical pass had already caught; four it
had not:

| Defect | Why my pass missed it |
|---|---|
| "The tier itself has not been edited in any round" | **I wrote it in this session.** Round 1 moved `difficulty` from hard to medium at the reviewer's request, so the sentence denies the fix the reviewer asked for. My checks compared claims against the current bundle and never against the pristine one |
| "331 of the 350 graded ids live outside the patched files" | Off by one. One `pass_to_pass` entry is created **by** the patch, so it is 330. My count checked the p2p total, not the outside-the-patch total |
| "all 331 measured passing at the base commit" | One of them did not exist at base. Same root cause |
| PR 155 "its own tests and its second file are left out" | PR 155 has exactly two files and the second one **is** its tests, so the sentence invents a third and double counts. Verified against the API |
| "re-exec under bash on the first line", twice | The shebang is first, the guard is line 3 |
| Findings 6 to 13 folded the fixable answer into prose | Section 2 requires the same numbered shape inside the trailing group, with both sub-answer lines |
| "Step 7 conditions", "the pre-upload script" | Workspace-internal vocabulary a reviewer cannot look up |
| "Proved twice ... both 350 of 350" | Described rounds 1 and 2, not the run against this zip |
| One prose colon, and a difficulty answer naming no symbol | Section 5 and Section 2 |

**The lesson worth keeping: a self-audit checks the claims it thought to make.** Every number I
verified was one I had chosen to verify. The four it missed were a sentence I had just written, two
counts I had not thought to derive separately, and a fact about an upstream PR I had summarised from
memory rather than re-fetched. The independent read is what closed them.

---

# Closed - ACCEPTED, 2026-08-16

## The verdict as received

```
This task has been accepted.
```

That is the whole of it. **No Submission Quality Score, no reviewer notes, no eval panel and no
error categories were supplied**, so nothing beyond the word accepted is recorded here and nothing
below infers one. Two consequences worth stating rather than leaving implicit:

- `docs/reviewer-rubric.md:19` makes coaching comments **mandatory** on an Accept carrying one to
  four Minor violations. None arrived. That is compatible with a clean Accept and equally
  compatible with coaching that was written and not relayed, and there is no way to tell from here.
- The final round's difficulty and quality numbers are unknown. What IS known is structural and is
  in the next section.

Final round: **3**. Uploads: **4**. Handling-time ledger last cumulative: **210** minutes of
revisions against a 215 minute first pass.

## What acceptance proves, and what it does not

`docs/faq.md:70` puts the review gate - agentic judge, then the difficulty screen - **before** the
task reaches a reviewer, and `docs/tasking-guide.md:251` says a submission whose evals pass routes
to the reviewer queue on its own while one that fails comes straight back. A human reviewer accepted
zip `675f27cd`. So both review-gate stages passed on that bundle.

**Word it as "the bundle carrying the lever was accepted", never as "the lever cleared the screen"**
(`learning/when-fail-easy-is-not-not-fixable.md:112-116`). The number the screen returned on round 4
was never read by anyone here.

**And the attribution is not split two ways, it is confounded five ways.** The `FAIL EASY` was
measured on zip `04a22a2d`, the round-1 output. The accepted bundle is `675f27cd`, the round-3
output. Its screen result was never read here, and the screen on the round-2 output never ran at all
because the judge blocked first. So there is no A/B anywhere in
which the round-2 lever is the only thing that moved, and round 3 alone carried four
difficulty-relevant changes pulling in both directions:

| Round | Change | Direction |
|---|---|---|
| 2 | the `setArgEnabled` reach trap, adapted from related PR 155, pre-measured against 5 wrong implementations | raises |
| 3 | the module pin removed from `instruction.md`, so the marker encoding is the implementer's choice | raises, the "less handed over" class |
| 3 | an assertion on the picker marking **every** visible row, an already-shipped clause nothing graded | raises, the ungraded-clause class |
| 3 | the fresh-scan rule written into the instruction | **lowers** |
| 3 | the `itemZoneID` overreach removed | **lowers** |

Round 3 was a quality round answering a judge block. Three of its four difficulty-relevant changes
were side effects of that, and nothing planned any of them. **No lever on this task has a platform
number attached to it, and the round-2 pre-measurement is the weak matrix shape besides** - five
implementations written on purpose to be wrong, which is the statrs shape that
`difficulty-levers-must-discriminate.md:117-127` says tells you nothing about what a competent agent
writes, not the xlwings shape of five honest builds. No model was recorded against it either.

## Open caveats

Required by CLAUDE.md and LEDGER L35 and missing from this record until close. All three are open.

| Caveat | Stated in round | What would retire it | Retired? |
|---|---|---|---|
| the round-2 discriminate matrix is five deliberately-wrong implementations, not five honest builds, and carries no model name, so it is a ceiling and not a forecast | 2, retro-added at close | the same matrix re-run against independent honest implementations, with the model named | **NO** |
| the shipped `pass_at_k_*` describe round 0's output, three rounds before the accepted one, and the `difficulty_explanation` is silent on everything round 3 changed | 3 | a full difficulty rollout on `675f27cd` | **NO**, and nobody flagged it |
| `difficulty = "medium"` ships beside `pass_at_k_opus_4_8 = "4/4"`, which is 100% against a documented Medium bar of at most 4 of 8 | 1, unstated until close | a fresh rollout, or the reviewer's own reading | **NO**. The tier was set at a reviewer's direct request and the rates restored separately, so the pair was never read together |

## What acceptance did NOT validate

Following the discipline in `learning/accepted-bundle-reference.md`: acceptance validates what
previously failed and was then changed. Everything else merely was not caught.

| Item | Status |
|---|---|
| The non-derivable-name fix, the exit-code gate, the base64 test-tree restore, the forward-only oracle, `pass_to_pass` at 331, the git metadata work | **validated at least once each** - a reviewer and two judge rounds looked at this bundle and stopped naming them |
| **Step 5.5 Run 4, the gaming probe** | **never run on this task, under that name or any other, in any of five batteries.** What ran instead was the agent-hostile restore and the exit-code gate separation. On a Go repo the assertion layer is the stdlib `testing` package, not an agent-writable file, and `test.sh` restores all 46 base test files, so the mithril route has no analogue here. But the Section 10.11 residue is at its purest on this bundle: `tests.patch` declares `package tui` and `package gqlexplorer`, so both graded files are internal-package tests and **every `.go` file the agent writes in those two directories compiles into the same test binary**, and `go.mod` and `go.sum` are not restored either. That residue is closed only by the exit-code gate, and on a `-json` runner that is an argument rather than a measurement. **Four rounds of platform checks and a human reviewer all passed with this run simply absent**, because nothing in the loop reads the battery table for missing rows |
| The `pass_at_k_*` fields | `4/4` and `2/4` were measured on upload 1, round 0's output, so **three** rounds before the accepted bundle. Nobody flagged it. That is not the same as it being right |
| The final `difficulty_explanation` | describes the round-2 lever, which does ship, so it is current in substance and merely silent on everything round 3 changed |
| `[agent] timeout_sec = 7200` | never exercised. Agents finished on every round, so the ceiling was not hit. **How close they came is unknown** - no difficulty artifact was ever requested on any round |
| The instruction's authenticity | no round ever returned an Instruction Styling finding, so the persona work was never tested against a reader who disliked it |

## The provenance of every blocking result

The single most useful thing this task record holds.

| Round | What blocked it | Who authored the cause |
|---|---|---|
| 0 | arrival: 13 findings, six unguessable private names taking all 17 graded ids down | **the seed** |
| 1 | human reviewer: 4 untested requirements, stale metadata, a dirty shipped tree | the seed, plus 2 findings I caught myself before the zip |
| 2 | difficulty screen, `FAIL EASY` at 75% / 75% | **my own round 0 solvability fix.** Arrival was 0/3 because nothing compiled, so the arrival rating measured a build failure and the fix spent difficulty that was never there |
| 3 | agentic judge, `DISCUSS` / `overreach` on one unexported helper call | **my own round 2 test edit**, which reintroduced the exact defect round 0 existed to remove |
| 4 | nothing. Accepted | |

**From round 2 onward, every block was caused by the previous round's fix.**
`learning/self-inflicted-defects-dominate-late-rounds.md` puts that crossover at about round 4. It
happened at round 2 here, and the reason is that round 0 was a near-total rewrite: 13 findings, a
regenerated `tests.patch`, a rebuilt `test.sh` and a rewritten instruction. The bundle stopped being
the seed's after one round, so the bundle's own diff became the higher-yield review target after one
round too. **Start reading your own diff on the first round after a rewrite that replaced most of the editable surface, rather than waiting for a round number.** Whether the crossover actually tracks rewrite size is **UNSETTLED** - AltBeacon's round 0 was also a rewrite and its crossover was still round 4 (`learning/self-inflicted-defects-dominate-late-rounds.md`).

## Handling-time ledger, final

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 0 | 2026-08-06 | 0 (first pass, not a revision) | 0 |
| 1 | 2026-08-08 | 70 | 70 |
| 2 | 2026-08-09 | 70 | 140 |
| 3 | 2026-08-09 | 70 | **210** |

First-pass fields as submitted: review 55, rewrite 145, form 15, **total 215**. Revisions **210**.

## Upload ledger, final

| # | Date | Zip sha256 | Checks returned | Outcome |
|---|---|---|---|---|
| 1 | 2026-08-06 | `72857eaa…` | static, difficulty, oracle, quality all green | reviewer **Needs Revision**, 3 items |
| 2 | 2026-08-08 | `04a22a2d…` | judge OK, screen ran | **FAIL EASY**, 75% both models |
| 3 | 2026-08-09 | `6e930349…` | judge **DISCUSS**, screen not run | **overreach** on `itemZoneID` |
| 4 | 2026-08-09 | `675f27cda0d8a61f1d304584d0fcea742171d1ee7e9952a8426419871cd08c46` | review gate passed, reached a reviewer | **ACCEPTED** |

## Harvest (Step 11 item 4)

One wrong figure, recorded so the next reader does not re-derive it. The "longest paragraph 705
characters" stated twice above and in the answers file came from an **unfiltered** blank-line
paragraph split and matches neither documented method: the pre-L45 script returns **420** on this
file and the corrected one returns **603** (`learning/LEDGER.md` L45,
`learning/accepted-bundle-reference.md`), which is also what that note already carries beside 49
lines. A wrong number, not a stale method.

What this task proved that no note said, and what it disproved. Written up in `learning/` on
2026-08-16; the rows below are the index of that work.

| Finding | Where it landed |
|---|---|
| A solvability fix is a difficulty reset, so the round that fixes one budgets a lever into the same round. It does not author the difficulty defect, it stops masking one | `learning/clarity-fixes-spend-difficulty.md`, second mechanism |
| A defect an earlier round removed comes back through a LATER round's fix, so every audit a round invents becomes a standing audit | `learning/self-inflicted-defects-dominate-late-rounds.md`, LEDGER L83 |
| Four classes of answers-file defect a self-audit structurally cannot reach, and the pre-submit gate line is the field that goes stale most often | `learning/answers-file-drift.md`, LEDGER L84 |
| Closing an ungraded clause need not cost a graded id, which is the whole decision at 19 of a hard 20 | `learning/probe-the-instruction-you-already-wrote.md` |
| Go's Run 4 has no assertion-library route and a different residue, and it was never run here | `learning/agent-writable-test-infrastructure.md`, LEDGER L85 |
| The Section 10.3 which-shape snippet reports every Go id as outside, silently, with no UNRESOLVED line | `.claude/rules/11-verifier-hardening.md`, LEDGER L7 reopened |
| Seventh accepted bundle, first Go bundle graded whole-repo with the exit gate measured safe | `learning/accepted-bundle-reference.md`, `learning/calibration.tsv` |

**Not harvested, because it did not survive checking.** "Added scope from a related PR CAN clear the
screen" was drafted as a finding and withdrawn. It contradicts the wording rule three sections above
in this same file, and the confounding table shows why it cannot be supported: five changes across
two rounds, no screen number on the accepted bundle, and a matrix of the weaker shape behind it.
