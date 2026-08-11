# 20260807_080545__tair-opensource_redisshake__1005

Submission id: e115d5ec-345a-4234-bf45-ce9bbce9f0b1
Claimed: 2026-08-07
Verdict: Fixable
Status: checks-green

tair-opensource/redisshake PR 1005, Go, `go test`. Arrived flat at the zip root with no
`runs/`, so there is no trial evidence in the bundle.

## Arrival snapshot (2026-08-07, structural only)

Measured while arranging the folder. Nothing here is a verdict; Steps 2 to 4 have not run.

| Fact | Value |
|---|---|
| Zip | `e115d5ec-345a-4234-bf45-ce9bbce9f0b1_submission.zip`, 27152017 bytes, 597 entries, 0 symlinks |
| Zip shape | flat at the root: `instruction.md`, `task.toml`, `environment/`, `solution/`, `tests/`. No wrapper, no `runs/` |
| `download/original` | frozen read-only, 597 of 597 verified against the zip by `bin/pristine-freeze.sh` |
| `tests/` entries | `config.json`, `test.sh`, `tests.patch` - all three on the allowed list, no `files/` |
| `fail_to_pass` | **10** - inside the static check's 10 to 20 range and at the very bottom of it |
| `pass_to_pass` | **1** |
| `allow_extra_failures` | `true` |
| `instruction.md` vs `environment/problem_statement.md` | byte-identical |
| `tests/test.sh` mode | **0644** |
| `solution/solve.sh` mode | **0644** |
| `solve.sh` size | 278 bytes |
| `golden.patch` size | 67070 bytes |
| Arrival difficulty | `pass_at_k` 0/3 on both models, `agent_hardened = "true"`, `hardening_cycles = "2"` |
| `repo_license` | blank, against a `license.txt` in the repo |

Two of those are already worth flagging as Step 3 candidates rather than facts: `fail_to_pass`
at exactly 10 makes the submitter form's "**More than** 10 fail-to-pass tests" checkbox false
as shipped, and a `pass_to_pass` of 1 is the smallest regression guard any task in
`learning/calibration.tsv` has arrived with (the range there is 1 to 1204).

## Upload ledger

A row goes in after each zip is verified, before it is uploaded.

| # | Date | Zip sha256 | Size | Checks returned | Outcome |
|---|---|---|---|---|---|
| 1 | 2026-08-07 | 6cee6cd7f8799e00 | 25761566 (654 entries) | never uploaded | SUPERSEDED by the re-verification pass |
| 2 | 2026-08-07 | bf776cb1a414f277 | 25761685 (654 entries) | never uploaded | SUPERSEDED, intermediate |
| 3 | 2026-08-07 | a620487c0b7050b2 | 25761xxx (654 entries) | never uploaded | SUPERSEDED, intermediate |
| 4 | 2026-08-07 | 95067b10d9b1b62a | 25762919 (654 entries) | never uploaded | content-identical predecessor of row 5 |
| 5 | 2026-08-07 | ed1b399695f92a82 | 25762919 (654 entries) | not uploaded yet | built and verified, Send unchecked. the bundle uploaded for round 0. Blocked at the difficulty screen, FAIL EASY, 8 of 8 agent runs solved it. Rebuilt from row 4 with identical content after a post-zip `git apply --check` moved `.git`'s mtime and tripped Send gate 7 (the xlwings 2719 shape). `diff -rq` between the row-4 extract and `work/` was empty before the rebuild, and NOP, oracle, vA and vI were re-confirmed against this zip |

| 6 | 2026-08-07 | bf23e88236728608 | 25765527 (654 entries) | not uploaded yet | round 1. PR 1038 adapted as added scope. **THIS is the current bundle** |

| 7 | 2026-08-08 | 18df1e5c432d0cd3 | 25765xxx | never uploaded | superseded, intermediate |
| 8 | 2026-08-08 | 3c23ff5982db4e2c | 25765xxx | never uploaded | superseded, intermediate |
| 9 | 2026-08-08 | 4921a3087afcb531 | 25765xxx (654 entries) | not uploaded yet | round 2 final. Instruction rewrite, one unmoored graded id dropped, test comments aligned. **THIS is the current bundle** |

| 10 | 2026-08-08 | 74d6b0850f9383cb | 25767227 (654 entries) | not uploaded yet | round 3. PR 1048 adapted, padding merged, AOF stream graded. Submitter chose to upload after the control returned 4 of 4. **THIS is the bundle to upload** |

| 11 | 2026-08-08 | 45977e21f6bacfb9 | (654 entries) | not uploaded yet | round 3 final. Scan-path coverage gap closed. **THIS is the bundle to upload** |

| 12 | 2026-08-08 | 3a8da623b8966b4a | (654 entries) | never uploaded | content-identical predecessor of row 13 |
| 13 | 2026-08-09 | 64436d2f894104af | 25771128 (654 entries) | not uploaded yet | round 4 final. PR 1043's writer half adapted. Rebuilt after a post-zip `git apply --check` moved `.git`'s mtime. **THIS is the bundle to upload** |

## Handling-time ledger

The answers form's revision figure is copied from the last Cumulative cell, never remembered.
Round 0 is the first pass and is NOT revision time, so the cumulative stays 0 until a bounce.

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 0 (first pass) | 2026-08-07 | 0 | 0 |
| 1 | 2026-08-07 | 65 | 65 |
| 2 | 2026-08-08 | 65 | 130 |
| 3 | 2026-08-08 | 110 | 240 |
| 4 | 2026-08-08 | 75 | 315 |

Round 3 is larger than the 50 to 70 a round usually costs. It carried the difficulty artifact analysis, the PR 1048 adaptation with its own four-implementation measurement, the padding merge, and then the scan-path coverage close with a wire-speaking server written from scratch. Recorded at what it took rather than trimmed to the band.

## Strike counter

Two strikes on one signature forces the remove-the-dependency path. A third variation of the
same theory does not get shipped.

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|

## Learning notes carried in

Every note in `learning/` was read at session start on 2026-08-07. The ones below carry a
concrete prediction for this bundle. Each row names what it predicts here and the command that
confirms or refutes it, so none of them gets settled by memory.

| Note | What it predicts here | Command that settles it |
|---|---|---|
| stock-bundle-defect-baseline.md | all six stock defects present until a command says otherwise. Two are already confirmed by the arrival snapshot (`pass_to_pass` 1, `allow_extra_failures` true) | the six commands in the baseline table below |
| go-task-verifier-gotchas.md | `go test ./...` may exit nonzero on a correct tree, which decides whether the exit-code gate can be wired whole-repo or has to be scoped | on the oracle tree: `go test ./...; echo "bare exit=$?"` then the same for the scoped command |
| empty-git-refs.md + LEDGER L26 | this is a Go task, so a half-present `.git` fails `go build` outright with `error obtaining VCS status: exit status 128`. Loose ref after the gc **and** `-buildvcs=false` in the Dockerfile and `execution.env` | `find work/environment/repo/.git -type d -empty` prints nothing; four-state repo matrix in the image (intact, empty-dirs-deleted, refs removed, no `.git`) |
| verifier-fail-open.md | the stock grader writes reward 1.0 without reading `raw_exit_code`. `tests/test.sh` is 18902 bytes, which is the stock size range | `grep -n 'raw_exit_code' work/tests/test.sh` then read the success expression |
| tests-patch-vs-agent-edits.md | Go keeps tests beside the source, so whatever package the agent implements is a package `tests.patch` may also touch. No git-based restore, ever | `grep '^diff --git' work/tests/tests.patch \| sed 's\|diff --git a/\|\|;s\| b/.*\|\|'` then `grep -n 'git\|rm -rf\|base64' work/tests/test.sh` |
| non-derivable-private-names.md | `pass_at_k` 0/3 with `hardening_cycles = 2` is the exact arrival metadata hulak 118 had, where the cause was six private names, not difficulty. Go compiles per package, so one bad name takes every graded id in that package down | for each identifier the graded tests call: `git -C work/environment/repo grep -c -- '<name>' HEAD -- '*.go'` and `grep -c -- '<name>' work/instruction.md`. Both zero on the same name is the defect |
| static-checks.md | `fail_to_pass` is 10, in range but at the floor, so any regrouping has headroom and any deletion does not. `tests/` is clean at three allowed names | `python3 -c "import json;print(len(json.load(open('work/tests/config.json'))['grading']['fail_to_pass']))"` |
| solve-sh-idempotency.md | a 278-byte `solve.sh` is the stock shape, which reverse-applies as its `else` branch | `grep -n 'apply.* -R' work/solution/solve.sh`, then three consecutive applies in one container |
| solve-sh-under-sh.md + go-task §4 | both entrypoints ship 0644 and may carry bashisms the harness would hit under dash | `dash -n work/tests/test.sh` and one `sh /solution/solve.sh && sh /tests/test.sh` run |
| dockerignore-context-root.md | the build context is `environment/`, so any `.dockerignore` inside `environment/repo` is inert by construction. The repo ships a `.gitignore`; check for editor directories reaching `/app` | `ls work/environment/.dockerignore` and `docker run --rm <image> bash -c 'find /app -maxdepth 3 \( -name .vscode -o -name .idea \)'` |
| unreachable-git-blobs.md | golden and patched-test blobs dangling in `.git`, plus a broken `refs/remotes/origin/HEAD` that no other check catches | `git -C work/environment/repo fsck --unreachable --no-progress` |
| dirty-repo-and-symlinks.md | the shipped tree may already be dirty at base; the zip reports 0 symlinks so the `-y` assertion is free here | `git -C work/environment/repo status --porcelain` |
| git-autofetch-watcher.md | an editor autofetch rewrites `.git/FETCH_HEAD` in both trees on a three minute cycle, undoing any scrub done early | scrub last, immediately before zipping, and re-list `.git`'s entries at that point |
| stale-test-reports.md | applies only if the Dockerfile runs the suite at build time and the grader reads a report path | read `work/environment/Dockerfile` for a build-time test run, then confirm in the NOP |
| verify-in-the-image.md | a NOP reward of 0 proves nothing on its own. Go is the friendly case: packages that still compile at base execute, so split the graded ids rather than accepting the reward | run the NOP, then run the graded ids whose package compiles at base and read per-test outcomes |
| quality-check-criteria.md | Q9 navigation and Q10 leakage block on their own, whatever the test axes say | grep `instruction.md` for source paths and for any literal the graded tests assert |
| prescriptiveness-check.md | non-blocking, but grep the tests before deleting any name from the instruction, or a `test_faithfulness` failure replaces it | the symbol audit in that note, against `tests.patch` |
| source-pr-cross-check.md | before acting on any coverage finding, check whether it describes PR 1005 rather than the tests. Page the API, do not read page 1 | `curl "https://api.github.com/repos/tair-opensource/redisshake/pulls/1005/files?per_page=100&page=N"` until a page returns under 100 |
| oracle-bug-vs-pr-scope.md | if PR 1005 carries a real defect and the instruction promises a standard, `docs/guidelines.md:286` case 1 authorises fixing the oracle. Check the default branch first | fetch the same file from `master` and diff |
| local-runs.md | run everything in the session scratchpad, never in `work/`. Workspace is ext4 | `df -Th .` |
| diagnosing-platform-only-failures.md | two strikes. A locally verified fix that fails twice means remove the dependency, not a third theory | the strike table above |
| platform-announcements.md | a red difficulty screen saying trivially easy is a measurement, not noise. A harness failure is the case the rerun ladder covers | read the message, not the colour |
| accepted-bundle-reference.md + calibration.tsv | calibration only. `pass_to_pass` 1 and `fail_to_pass` 10 both sit at the bottom of every column | compare against `learning/calibration.tsv` |
| rust-cargo-verifier-gotchas.md | **not applicable.** This is a Go task with `go test`, not cargo | `grep -c '^go ' work/environment/repo/go.mod` |

## Stock-defect baseline

Filled in Step 2, one verdict and one piece of evidence per row. `NA` needs the same evidence
as the other two answers.

| # | Defect | Verdict | Evidence |
|---|---|---|---|
| 1 | Fail-open grader, `raw_exit_code` recorded and never branched on | **Present** | `test.sh:507` success expression read neither. Proved live: same passing log at raw exit 1 scored **1.0 stock, 0.0 fixed** |
| 2 | No regression guard, `pass_to_pass` empty or near it with `allow_extra_failures` true | **Present** (arrival) | `pass_to_pass` 1, `allow_extra_failures` true, measured 2026-08-07 |
| 3 | Stale test results baked into the image at build time | **Absent** | Dockerfile runs `go build`/`go vet` only, no suite at build time, and the NOP executed 22 ids live (34880 bytes of stdout) |
| 4 | `solve.sh` not idempotent, reverse-apply fallback reporting success | **Present** | `solve.sh:8` `git apply -p1 -R` as the `else` branch. It never fired locally because `--3way` absorbs the second apply, but it fires the moment `.git` cannot serve a three-way |
| 5 | Graded test files named what an agent would name its own | **Present** | `internal/rdb/types/hash_valkey_test.go` beside a Valkey hash reader, and `internal/commands/hash_field_cmds_test.go`. Both are the obvious agent choice |
| 6 | No test-tree restore before `tests.patch`, or one built on git | **Present** | `test.sh` went straight to `git apply`. The graded test in `internal/commands` also depends on `testEq` from the pre-existing `keys_test.go:7`, so an agent editing that file alone breaks the graded set |

Two more arrival observations that are not on the six-row baseline but belong with it: both
entrypoints ship at mode **0644**, and `[metadata] repo_license` is **blank** against a
`license.txt` in the repo.

## Restore shape, hand resolved

`bin/preflight.sh` prints `UNRESOLVED` here and refuses a number, which is correct: the graded
ids are `RedisShake/<pkg>::<Test>`, a Go **import path** and not a file path, so the id-scheme
detector in Section 10.3 cannot map them (LEDGER L7, same class as the AltBeacon and libcrux
misreads). Resolved by hand, mapping each id to the file that defines it:

**7 of 22 graded ids live in files `tests.patch` does not touch** - `TestCalcKeys` and
`TestKeyHash` in `internal/commands/keys_test.go`, `TestSet`, `TestSetIntset` and
`TestSetListpack` in `internal/rdb/types/set_test.go`, `Test_syncStandaloneReader_Status` in
`internal/reader/sync_standalone_reader_test.go`, and `TestCrc16` in
`internal/utils/crc_test.go`. Above zero, so Section 10.3 requires the **full test-tree payload
embedded in `test.sh`**, not a create-only patch. That is what shipped.

## Check history

One block per round: what the platform returned, verbatim.

### Round 0 - 2026-08-07, first pass, not yet uploaded

No platform feedback yet. Everything below is local measurement.

## Findings

### 1. HEADLINE: 8 of the 10 graded ids were unreachable by any agent (non-derivable names)

`tests/tests.patch:148` and six sibling lines call `o.SetIsValkey(true)`, and `:319` calls
`ParseObject(buf, 22, "mykey", true)`. Measured against the base commit:

    SetIsValkey    base .go files = 0    instruction.md = 0
    ParseObject    base signature = (io.Reader, byte, string)   3 args, not 4

Both are real upstream PR code, not task-author inventions (confirmed against the PR diff), but
neither is named anywhere the agent can see. Go compiles a package as one unit, so the file does
not build and the whole package goes down together. Measured in the image at base:

    vet: internal/rdb/types/hash_valkey_test.go:74:4: o.SetIsValkey undefined
         (type *HashObject has no field or method SetIsValkey)
    internal/rdb/types/hash_valkey_test.go:245:37: too many arguments in call to ParseObject
         have (*bytes.Buffer, number, string, bool)
         want (io.Reader, byte, string)
    FAIL RedisShake/internal/rdb/types [build failed]

That is 8 of 10 `fail_to_pass` ids lost by construction, which is what the arrival
`pass_at_k` 0/3 on both models actually measures. Same shape as hulak 118
(`learning/non-derivable-private-names.md`), and the reason the identifier audit runs before a
pass rate is read as difficulty.

**Fix, per LEDGER L24: repoint the tests at what the user sees, do not name the private plumbing
in the instruction.** The graded tests now hand the loader a whole snapshot file and read back the
command stream. Every symbol they touch exists at the base commit. Whatever internal wiring an
agent picks, a Valkey file has to come out as the right commands.

### 2. Three stated requirements had no enforcing assertion

- the `REDIS` versus `VALKEY` header detection. Nothing constructed a header at all
- the append-only-file signature check, the second site the PR changes
- the Redis 8.0 side of type byte 22, so nothing failed when an implementation used the Valkey
  layout for both flavors

An implementation that adds the five command entries, ignores a fourth `ParseObject` argument,
gives `SetIsValkey` an empty body, hardcodes type 22 to the Valkey reader and never touches
either magic string scored **reward 1.0** on the shipped bundle. It cannot read a Valkey file at
all and it corrupts every Redis 8.0 type-22 hash that works at base. Both halves of that are now
caught, probes e1 and e5.

### 3. The instruction promised a path the oracle does not implement

`instruction.md:1` said support was added "across the sync, scan, RDB and AOF paths".
`golden.patch:657-659` leaves the scan path hardcoded to the Redis flavor behind a `TODO`,
exactly as the upstream PR does. Reducing PR scope is not available, so the fix is in the
instruction (`learning/source-pr-cross-check.md`). The promise now names only the snapshot and
append-only-file paths.

### 4. Padding in the graded set

7 of the 10 shipped ids were the same decode contract reminted across sizes
(`TestReadHashValkeyLargeTTL` is strictly dominated by `SingleField`, whose constant is larger;
`SingleFieldNoTTL` duplicates `ZeroTTL` at n=1; `SingleField` duplicates `AllExpiring` at n=1;
`ThreeFields` duplicates `TestReadHashValkey` at n=3). Replaced with 12 contracts that fail for
different reasons, each proved by its own probe.

### 5 to 14. Verifier, packaging and metadata

| # | Finding | Evidence |
|---|---|---|
| 5 | Fail-open grader | `test.sh:507`. Proved live: one passing log at raw exit 1 scores 1.0 stock, 0.0 fixed |
| 6 | No test-tree restore of any kind | `test.sh` went straight to `git apply`, with graded files named exactly what an agent would name its own |
| 7 | `solve.sh` reverse-applies as its `else` branch | `solve.sh:8` |
| 8 | Both entrypoints ship 0644 | verified in the zip, not only on disk |
| 9 | Shipped tree dirty at base | `build.sh` and `test.sh` had lost their 100755 mode bits |
| 10 | Regression guard of 1 id with `allow_extra_failures` true | 5 pre-existing test files, 9 tests, all ungraded |
| 11 | `fail_to_pass` exactly 10 | in the static range but makes the form's "more than 10" box false as shipped |
| 12 | `task.toml`: `repo_license` blank against an MIT `license.txt`, `[environment] os` missing, `difficulty_explanation` missing, `[verifier] timeout_sec` 300 inside `execution.timeout_sec` 1800 so the inner limit could never fire, `[agent] timeout_sec` 1800 of a 7200 ceiling on a 180-minute task | |
| 13 | Dockerfile masked its own compile with `\|\| true` | an image whose tree does not build came out green |
| 14 | No `-buildvcs=false` on a Go task | LEDGER L26. A half-present `.git` fails `go build` outright and cost firefly 1123 a platform Oracle 0/3 |

**Deliberately not changed, and why.** `model_difficulty = "medium"` against `difficulty = "hard"`
is reported rather than reconciled (LEDGER L14, `docs/faq.md`). `allow_extra_failures` stays
`true` because the run does not execute exactly the graded set (LEDGER L13); the exit-code gate
is the stronger guard and it is now wired. `golden.patch` still omits the 10 CI and documentation
files the PR also touches, because `docs/guidelines.md` asks the patch to carry only what
resolves the task and no repo test reads them.

## Step 5.5 battery, against zip 6cee6cd7f8799e00

Every run on a fresh extract of the built zip, in an image built from that same extract.

| Check | Result |
|---|---|
| NOP | reward **0**, raw exit **1**, `infrastructure_error: None`, **10 of 22** required passing, 34880 bytes of stdout |
| NOP genuineness | **executed, not audited.** All 10 regression guards ran and passed at base and all 12 f2p ran and failed. No compile abort and no collection abort, so the zero is read per test |
| Oracle, 3 fresh containers | **1.0, 1.0, 1.0**, 22 of 22 each |
| Oracle, 3 applies in one container | 1.0 at 22 of 22. Runs 2 and 3 print "golden.patch is already applied" |
| Hostile probes | **10 of 10 drop to 0.0**, each naming its catching test (list below) |
| Agent-hostile restore | **1.0 at 22 of 22** with agent tests written at two graded paths, one of them not valid Go, the pre-existing `keys_test.go` gutted, a graded file deleted, everything committed and `.git` removed |
| Repo-state matrix (LEDGER L26) | intact, empty-dirs-dropped, refs-removed, no-git all **1.0** |
| Dash | `/bin/sh` is dash in this image. `sh /solution/solve.sh` and `sh /tests/test.sh` both 1.0 at 22 of 22 |
| Fail-open | same passing log at raw exit 1: **stock grader 1.0, this grader 0.0** |

| Probe | Break | Caught by |
|---|---|---|
| e1 | drop the VALKEY header branch | `TestSentinelValkeyRDBHeaderIsRead` +8 |
| e2 | never emit the field expiry | `TestSentinelValkeyRDBEmitsExpireForEveryExpiringField` +5 |
| e3 | emit an expiry even for a zero TTL | `TestSentinelValkeyRDBOmitsExpireForFieldsWithoutTTL` +5 |
| e4 | read the TTL as 4 bytes not 8 | `TestSentinelValkeyRDBPreservesLargeTimestampsAndFieldAlignment` +1 |
| e5 | use the Valkey layout for BOTH flavors | `TestSentinelRedisRDBUsesTheRedisLayoutForTheSameTypeByte` |
| e6 | unregister HGETDEL | `TestSentinelHashFieldCommandsRouteWithKeyAtIndexOne` |
| e7 | unregister XACKDEL | `TestSentinelStreamCommandsRouteWithKeyAtIndexOne` |
| e8 | drop the VALKEY branch in the AOF check | `TestSentinelValkeyAOFBaseFileIsReadAsASnapshot` |
| e9 | unregister the legacy HPERSIST | `TestSentinelLegacyHashTTLCommandsStillRoute` |
| e10 | emit the expiry before its field | `TestSentinelValkeyRDBDecodesFieldsWithMillisecondTTL` +5 |

**Preflight override.** `bin/rezip.sh` ran with `--skip-preflight` for the final zip, after a full
preflight pass on the same tree. The one blocking line is a false positive:
`pkg.leak.repo environment/repo/scripts/commands/config.json`. That file is the upstream spec for
the Redis `CONFIG` command, 1 of 391 files in `scripts/commands/`, tracked at the base commit,
holding zero verifier keys. Deleting it would be editing tracked source. Every other Phase A gate
was run and passed.

## Files changed

Bundle paths only. Workspace bookkeeping is never in this list.

1. `instruction.md` and `environment/problem_statement.md` - rewritten so every graded
   deliverable is derivable and no ungraded path is promised
2. `tests/tests.patch` - regenerated create-only against the base commit; 3 new sentinel-prefixed
   files replace the 2 that needed private names
3. `tests/config.json` - 12 f2p and 10 p2p, whole-repo build plus test commands,
   `GOFLAGS=-buildvcs=false`, inner timeout moved under the verifier limit
4. `tests/test.sh` - dash re-exec guard, git-independent test-tree restore, `bash -o pipefail`
   runner, `set -e` in the generated runner, exit-code gate in the success expression, mode 0755
5. `solution/solve.sh` - sanctioned four-step forward-only shape, mode 0755
6. `environment/Dockerfile` - `GOFLAGS=-buildvcs=false`, compile fails closed, vet stays advisory
7. `task.toml` - licence, `os`, `difficulty_explanation`, verifier and agent timeouts
8. `environment/repo/build.sh` and `environment/repo/test.sh` - 100755 mode bits restored
9. `environment/repo/.git` - scrubbed, loose ref written back after the gc


---

# Re-verification pass, 2026-08-07

Triggered by the submitter asking for the whole rule set to be re-read and the bundle
re-checked. `bin/docs-freshness.sh` returned `PASS no Hub entries newer than the export`, and
nothing in `docs/`, `.claude/` or `CLAUDE.md` had moved. What the pass actually exposed is that
**the first pass had not read all of `learning/` in full**, only the condensed prediction table
above. Reading the remaining 6111 lines and re-auditing the bundle against them found four real
defects, one of them worse than anything found on the first pass.

## R1. HEADLINE: the source PR mis-decodes Valkey's no-expiry marker, and every graded test agreed with it

`learning/oracle-bug-vs-pr-scope.md` names the exact trap: **a graded test written from the
oracle's observed behaviour cannot detect a bug in the oracle.** Both the shipped tests and my
own round-1 replacements took the oracle's zero-TTL semantics as ground truth. They are wrong.

Verified against Valkey upstream, not reasoned:

| Fact | Source |
|---|---|
| `#define EXPIRY_NONE -1` | `valkey-io/valkey` unstable, `src/expire.h:12` |
| `entryGetExpiry` returns `EXPIRY_NONE` when a field has no expiry | `src/entry.c:211-214` |
| The `RDB_TYPE_HASH_2` save path writes that value for every entry | `src/rdb.c`, `add_expiry = (rdbtype == RDB_TYPE_HASH_2)` |
| The load path tests `itemexpiry != EXPIRY_NONE` | `src/rdb.c:2245, 2272` |
| `RDB_TYPE_HASH_2 = 22, /* Hash with field-level expiration, RDB 80 (9.0) */` | `src/rdb.h:130` |

So a real Valkey 9.0 hash stores **-1** for a field that never expires, and **0 is an ordinary
timestamp that has already passed.** `golden.patch` gated on `expireAt != 0`, so it emitted
`hpexpireat <key> -1 fields 1 <field>` for every non-expiring field. `HPEXPIREAT` with a past
timestamp deletes the field, so replicating any real Valkey TTL-bearing hash silently dropped
the common case.

**Upstream has not fixed it.** `curl` of `tair-opensource/redisshake` master
`internal/rdb/types/hash.go` is byte-identical to our post-golden file, so the "genuinely
unavailable" clause of `docs/guidelines.md` is earned and the divergence is documented rather
than assumed. Fixed under `docs/guidelines.md` case 1, "to correct an oracle that does not
implement the instruction", with the instruction and tests moved in lockstep as that section
requires. The file list is unchanged, so this is a correctness fix and not a scope change.

Proved by probe e12: reverting the oracle to the source PR's own `!= 0` gate drops the reward to
**0.0**, caught by **8** tests including the new `TestSentinelValkeyRDBTreatsZeroAsAnOrdinaryTimestamp`.

## R2. The task is measurably easy, and that is now stated honestly rather than dressed up

`learning/difficulty-levers-must-discriminate.md` demands a control the first pass never ran:
independent implementations, not deletions from the oracle. The 10 hostile probes were the
coverage control and were being read as a difficulty claim, which that note calls out by name.

Run properly, the answer is uncomfortable. An honest implementation written from `instruction.md`
alone, with plumbing deliberately unlike golden's, passes the whole suite first try. That is the
xlwings 2719 shape. The arrival `pass_at_k` 0/3 measured a build failure, so difficulty was never
measured on this task at all, and `hardening_cycles = 2` did not measure it either.

The difficulty answer and the `difficulty_explanation` this workspace wrote have both been
rewritten to say only what a measurement supports. **PR 1038, "fix: add Valkey server type
detection support", touches `internal/reader/scan_standalone_reader.go`, the exact file where
`golden.patch` leaves its TODO.** It is the sanctioned related-later-PR lever
(`docs/faq.md`, LEDGER L21) and it is recorded as identified and NOT yet measured, because
shipping an unmeasured lever is what that note forbids.

## R3. The test-tree wipe was not total

`find . -name '*_test.go' -type f -delete` skips a directory or a symlink sitting at a path
`tests.patch` creates. Measured: planting a directory at
`internal/rdb/sentinel_valkey_rdb_test.go` made all three apply paths fail and produced
`infrastructure_error: tests.patch did not apply`, which scores the trial **invalid** rather than
wrong. That is the kvdex 245 failure in a narrower form. Now `-exec rm -rf {} +` with no type
filter, and the same planted directory scores **1.0 at 25 of 25**.

## R4. The stderr artifact truncated its own restore diagnostics

The runner redirected with `2>` after the restore and the patch apply had already appended to
that file, so a rescued or failed apply left no trace in the artifact the platform hands back.
Now `2>>`. Proved both ways: with git removed from the image so the `patch(1)` fallback runs, the
artifact carries **179 bytes** naming the three patched files; with the old truncating redirect it
is **0 bytes**.

## Also in this pass

- A missing regression guard on the Redis append-only path. Implementation vE, which requires all
  six signature bytes and matches only `VALKEY`, passed 22 of 22 before it was added
- Graded fixtures could never encode an RDB length above 6 bits, so an implementation that never
  calls the repo's RDB primitives passed. Fixtures now write real multi-byte lengths and one
  graded case uses 100 fields with 200-byte values
- The fixture header was `VALKEY011`, a version Valkey rejects for its own magic. Now `VALKEY080`,
  which is what `RDB_VERSION 80` and `snprintf("%s%03d")` actually produce
- One sentence that pre-answered the mechanism was cut from the instruction

## Implementation matrix, final zip 95067b10

The control `learning/difficulty-levers-must-discriminate.md` asks for. Each row is a whole
implementation, not a deletion from the oracle.

| Impl | What it does | Result |
|---|---|---|
| vA | honest, independent plumbing (`UseValkeyLayout`, `ParseObjectFlavored`, 3-arg `ParseObject` kept) | **1.0, 25 of 25** |
| vB | never reads the header, treats type 22 as always Valkey | 0.0, 24 of 25 |
| vC | snapshot path done, append-only path forgotten | 0.0, 24 of 25 |
| vD | copies the Redis header arithmetic, version from byte 5 | 0.0, 14 of 25 |
| vE | append-only check accepts only `VALKEY`, drops `REDIS` | 0.0, 24 of 25 |
| vF | restores every expiry, marker included | 0.0, 17 of 25 |
| vG | reads the expiry as 32 bits | 0.0, 17 of 25 |
| vH | reads counts and lengths as raw bytes, never calls the RDB primitives | 0.0, 24 of 25 |
| vI | **the gate the source PR itself ships** | 0.0, 17 of 25 |

vA passing is the overfit control: the graded set measures behaviour, not golden's internals.

## Battery, final zip ed1b399695f92a82 (measured on its content-identical predecessor 95067b10, re-confirmed here)

| Check | Result |
|---|---|
| NOP | reward **0**, raw exit **1**, infra None, **11 of 25**, 38207 bytes of stdout. Executed per test, not a compile abort |
| Oracle, 3 fresh containers | **1.0, 1.0, 1.0** at 25 of 25 |
| Oracle, 3 applies in one container | 1.0 at 25 of 25, runs 2 and 3 report already applied |
| Hostile probes | **12 of 12** drop to 0.0, each naming its catching test |
| Implementation matrix | 9 rows above |
| Agent-hostile restore | **1.0 at 25 of 25** |
| Directory planted at a graded path | **1.0 at 25 of 25** (was an invalid trial) |
| Repo-state matrix | intact / empty-dirs-dropped / refs-removed / no-git all **1.0** |
| Dash | `sh` on both entrypoints, 1.0 at 25 of 25 |
| No git in the image at all | 1.0 at 25 of 25 via the `patch(1)` fallback |
| Fail-open | one passing log at raw exit 1: stock 1.0, this grader 0.0 |

f2p 12 to **14**, p2p 11. Total graded ids 25.


---

# Revision round 1, 2026-08-07

## 0. Which task, and is the report fresh

**The report does not identify itself.** It names no test id, no file path, no line number and no
instruction text, so three of the four Step 10 freshness axes cannot be checked against it at all.
What ties it to this bundle is the reference-agent line, `nop: 0.0% (0/1)` and
`oracle: 100.0% (3/3)`, which matches the verifier shipped in zip `ed1b3996`, and the fact that no
other task in this workspace is at a difficulty screen. Recorded as **probably fresh, not
provable**, and nothing was changed on the strength of a number the report alone supplies.

## 1. The feedback, verbatim

```
## Difficulty Check
Blocked at the difficulty screen (cheap single-arm rollout).

This eval runs two checks in order - the agentic judge, then the difficulty screen - and the
screen runs only if the judge passed. The full difficulty rollout is a separate check that runs
after a reviewer accepts the task.

Difficulty: FAIL EASY - Requires at least MEDIUM

Status: Some tests not passed by any agent run (not blocking; require_solvable disabled)

Agent Performance:
  - claude-opus-4-8: 100.0% (4/4 runs)
  - codex-gpt-5-5: 100.0% (4/4 runs)

Reference Agents:
  - nop: 0.0% (0/1 runs)
  - oracle: 100.0% (3/3 runs)

Analysis on Agent Failures:
  - Task Instruction Sufficiency: NOT_APPLICABLE, debug output not available

## Automated feedback
Agent Runner Summary: Evaluation FAILED. Review gate blocked at the difficulty screen (cheap
single-arm rollout)
```

**Two things this result establishes that are worth stating plainly.**

The **agentic judge passed**. The screen only runs when it does, so every quality axis and every
must-have criterion cleared on this bundle. Nothing on the quality side is being asked for, and
nothing on the quality side should be disturbed to fix this.

The **verifier is healthy**: nop 0 of 1, oracle 3 of 3. So the eight agent successes are real
successes and not a grader that cannot fail. This is a content result about difficulty and
nothing else.

**It also confirms, from the platform rather than from my own measurement, the thing the
re-verification pass disclosed before upload.** That pass ran the discriminate control from
`difficulty-levers-must-discriminate.md`, found an implementation written from `instruction.md`
alone passed first try, wrote "difficulty is measured easy" into Comments for Reviewer, and named
PR 1038 as the identified but unmeasured lever. 8 of 8 agent runs is the same finding with a
bigger sample. The disclosure was right and the lever is now the work.

`Task Instruction Sufficiency: NOT_APPLICABLE` is not a result (Section 4), and
`Some tests not passed by any agent run` is marked not blocking with `require_solvable` disabled,
which sits oddly beside 100 percent agent success and is not something to reason from.

## 2. The finding list

One finding. **F1: the task is too easy and must reach at least MEDIUM.** That is Fixable
trigger 8, and `docs/faq.md` says the answer is to expand PR scope, not to diagnose. The bar to
clear is a frontier model solving a Medium task in at most 4 of 8 attempts, against 8 of 8 today.

## 3. Strike table

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Difficulty screen FAIL EASY | 1, 2 | r1 PR 1038 adapted as added scope (moved 8/8 to 7/8); r2 the instruction stopped pre-answering its own traps (**measured at zero before upload**) | 2 |

One strike. The two-strikes rule is not yet in play, but the thing that would trip it is shipping
a lever whose only evidence is that it sounds hard, so every candidate below is measured against
independent implementations before it ships.


## 4. What round 1 shipped

**The lever, and why this one rather than a guess.** `docs/faq.md:104-110` allows adapting a
change from a **related** later PR. PR 1038, "fix: add Valkey server type detection support",
merged 2026-03-30, touches `internal/client/func.go`, `internal/client/func_test.go` and
`internal/reader/scan_standalone_reader.go`. That last file is the exact place PR 1005 leaves
`// TODO: detect if server is Valkey and pass appropriate flag`, so this is not a bolt-on: it
finishes the thing the source PR started and is the reason the instruction had to stop promising
the scan path at all. Adapted, not lifted: the graded tests are mine, upstream's
`func_test.go` does not ship, and the function body is corrected (below).

**Why it is a real lever and not a story.** Valkey's `INFO server` publishes a Redis
compatibility version **before** its own, verified in `valkey-io/valkey` `src/server.c:6175-6178`:

```
"# Server"
"redis_version:%s\r\n",  REDIS_VERSION      <- first
"server_name:%s\r\n",    SERVER_NAME
"valkey_version:%s\r\n", VALKEY_VERSION     <- second
```

Upstream PR 1038's `ParseServerVersion` walks the reply and **returns on the first version line it
meets**, so against a real Valkey server it answers Redis. Every Valkey fixture in upstream's own
`func_test.go` omits the `redis_version` line, which is why their suite never caught it. That is
the second time in this task that the natural implementation is the wrong one and the upstream
author wrote it, which
`learning/difficulty-levers-must-discriminate.md` calls the strongest evidence a lever is real.
The oracle ships the corrected form under the same `docs/guidelines.md` case-1 reasoning as the
`-1` marker, and the divergence is disclosed.

**Measured before shipping, five ways of writing the same function:**

| `ParseServerVersion` written as | Result |
|---|---|
| upstream PR 1038's own, first version line wins | **FAIL**, a Valkey server reads as Redis |
| scan the whole reply, the Valkey line wins | pass |
| `strings.Contains` over the whole reply | **FAIL**, takes `master_redis_version` for the server's own |
| go by `server_name:` | **FAIL**, a Redis reply has no such line |
| split each line on the colon, first match wins | **FAIL**, same as upstream |

**Four of five plausible implementations fail.** That is the step-4 keep condition, not a discard.

**Also trimmed, because a checklist is not difficulty.** The instruction spelled out
`hpexpireat <key> <ms> fields 1 <field>`. The repository's own `readHashTtl` and
`readHashListpackTtl` already emit exactly that, so the form is derivable from the code the agent
is editing and the literal was one less thing to work out. It now points at that convention. No
graded assertion changed, and the same trade was already made for `del` and `hset`.

## 5. Implementation matrix, zip bf23e88236728608

Whole implementations, not deletions from the oracle.

| Impl | What it does | Result |
|---|---|---|
| vA | honest and complete, plumbing unlike golden throughout | **1.0, 30 of 30** |
| vB | never reads the snapshot header | 0.0, 29 of 30 |
| vC | append-only path forgotten | 0.0, 29 of 30 |
| vD | Valkey version taken from byte 5 | 0.0, 19 of 30 |
| vE | append-only check accepts only `VALKEY` | 0.0, 29 of 30 |
| vF | restores every expiry, marker included | 0.0, 22 of 30 |
| vG | expiry read as 32 bits | 0.0, 22 of 30 |
| vH | counts and lengths read as raw bytes | 0.0, 29 of 30 |
| vI | **the expiry gate PR 1005 itself ships** | 0.0, 22 of 30 |
| vJ | **the version parse PR 1038 itself ships** | 0.0, 29 of 30 |
| vK | version parse by substring search | 0.0, 29 of 30 |

Ten of eleven fail, and the two that matter most are the two upstream authors' own code. vA
passing is the overfit control.

## 6. Battery, zip bf23e88236728608

| Check | Result |
|---|---|
| NOP | reward **0**, raw exit **1**, infra None, **11 of 30**, 39528 bytes of stdout, executed per test |
| Oracle, 3 fresh containers | **1.0, 1.0, 1.0** at 30 of 30 |
| Oracle, 3 applies in one container | 1.0 at 30 of 30 |
| Hostile probes | **14 of 14** to 0.0, each naming its catching test |
| Implementation matrix | 11 rows above |
| Agent-hostile restore | 1.0 at 30 of 30 |
| Directory at a graded path | 1.0 at 30 of 30 |
| Repo-state matrix | all four states 1.0 |
| Dash | 1.0 at 30 of 30 |

f2p 14 to **19** (one slot under the ceiling), p2p 11, 30 graded ids. `golden.patch` 21 files to
**22**.

**Known gap, disclosed rather than papered over.** The instruction asks the scan reader to ask
once and decode with the answer. `ParseServerVersion` is graded five ways, but the wiring itself
is exercised only by the oracle, because that path needs a live server and the verifier is
airgapped. Probe e13 catches the detection, not the wiring.


---

# Revision round 2, 2026-08-08

## 1. The feedback, verbatim

```
## Difficulty Check
Blocked at the difficulty screen (cheap single-arm rollout).

Difficulty: FAIL EASY - Requires at least MEDIUM

Status: Some tests not passed by any agent run (not blocking; require_solvable disabled)

Agent Performance:
  - claude-opus-4-8: 100.0% (4/4 runs)
  - codex-gpt-5-5: 75.0% (3/4 runs)

Reference Agents:
  - nop: 0.0% (0/1 runs)
  - oracle: 100.0% (3/3 runs)

Analysis on Agent Failures:
  - Task Instruction Sufficiency: NOT_APPLICABLE, debug output not available
```

**Round 1 moved the number, which is the first evidence either round has produced about what
this task responds to.** codex went 4 of 4 to 3 of 4. opus did not move. Same verifier, nop 0 of
1 and oracle 3 of 3, so both rounds are measuring the same thing and the comparison is real.
7 of 8 against 8 of 8. The bar is 4 of 8.

**Strike 2 on this signature.** `learning/diagnosing-platform-only-failures.md` says two failures
on the same signature means the model of the cause is wrong and the next variation of the same
theory will not help either. Round 1's theory was *add scope*. It bought one run out of eight.
Shipping more scope is the third variation and the rule says do not.

**So this round changes the dependency instead.** The thing every round has held constant is that
`instruction.md` states the answer to its own hard parts. Both traps this task has are written
down in it:

| Trap | What the instruction said |
|---|---|
| Valkey's no-expiry marker | "A field that never expires is written as **-1** rather than as 0, and 0 is an ordinary timestamp that happens to be in the past" |
| Valkey's INFO reply | "A Valkey server answers with **more than one version line**, so the reply has to be read as a whole rather than settled on the first version line that turns up in it" |

Each of those is the whole difficulty of its half of the task, handed over. Round 1 measured that
4 of 5 plausible implementations of the version parse are wrong **when the answer is not given**.
It is given. That is why opus is at 4 of 4.

This is also what the submitter asked for this round, and it is the one lever the workspace's own
notes point at that has not been pulled: `raising-difficulty-on-a-wrapper-task.md` calls trimming
unavailable when every stated fact is a graded contract, and that is true of the *format facts*
here but not of the *pre-solved mechanisms*, which are a different category.

## 2. The finding list

**F1 (carried, strike 2): FAIL EASY.** Fix by removing the pre-solving from `instruction.md`
while keeping every contract a graded assertion rests on. Requirements stay, mechanisms go.


## 3. What round 2 shipped

**Only `instruction.md` and its copy changed.** The oracle, `tests.patch`, `config.json`,
`test.sh`, `solve.sh`, the Dockerfile and `task.toml` are byte-identical to round 1. That is
deliberate: the agentic judge passed on both rounds and the verifier is measurably healthy, so
neither is the thing to touch.

**Four things stopped being handed over.**

| Was | Now | Why it was a handout |
|---|---|---|
| "written as **-1** rather than as 0" | "the format says so with a **reserved value** rather than with zero, because zero is an ordinary timestamp that has already gone by" | The value was the whole of that trap. The contract still says a reserved value exists and that zero is not it, so the -1 fixtures stay moored |
| "answers with **more than one version line**, so the reply has to be read as a whole rather than settled on the first" | "It has to answer correctly for the reply a real server of each kind sends, not just for a reply trimmed down to the line that settles it" | Round 1 measured 4 of 5 plausible implementations wrong **when the answer is not given**. It was given |
| "a **four-digit** version ... a **three-digit** version" | "the version digits that follow the name fill out the rest of those nine bytes" | Nine bytes minus a five or six letter name is arithmetic the agent can do, and the base code already reads nine |
| "the key is cleared first"; "ask once, when it opens the connection it dumps over" | dropped | `Rewrite()` emits the del for every hash type, so it is readable off the code being edited. The wiring hint buys nothing because the wiring is not graded |

**What deliberately did NOT change, and why.** The Valkey body layout stays spelled out, because
it is not derivable from the repository and cutting it would be withholding rather than
difficulty. The command names, groups and key index stay, because they are the deliverable. The
error case and the replica case in the scan paragraph stay, because two graded assertions rest on
them.

**The line this round walked.** `docs/guidelines.md` is explicit that difficulty must come from
the problem and never from vagueness. The first draft of the scan paragraph read "the two are
less easily separated than they look", which is a riddle rather than a requirement, and it was
replaced before the zip with an acceptance condition that names what the function has to work
against. Every remaining sentence states a contract.

## 4. Battery, zip 18df1e5c432d0cd3

Re-run in full because the zip changed, even though only prose did.

| Check | Result |
|---|---|
| NOP | reward **0**, raw exit **1**, infra None, **11 of 30**, 39529 bytes of stdout |
| Oracle, 3 fresh containers | **1.0** at 30 of 30 each |
| Hostile probes (representative 5 of 14) | all **0.0**, each naming its test |
| Agent-hostile restore | 1.0 at 30 of 30 |
| Directory at a graded path | 1.0 at 30 of 30 |
| Repo-state matrix | all four states 1.0 |
| Dash | 1.0 at 30 of 30 |

f2p 19, p2p 11, unchanged. `golden.patch` 22 files, unchanged.

## 5. Honest read on whether this is enough

It moved once already, so the dial is not stuck: round 1 took codex from 4 of 4 to 3 of 4 and
left opus at 4 of 4. This round attacks the reason opus never has to think, which is that the
instruction contained both answers. **I cannot measure agent behaviour locally, so this is a
prediction and not a measurement, and it is recorded as one.** What is measured is that with the
answers withheld, 4 of 5 plausible ways of writing the version parse are wrong, and that the two
upstream authors both got their half wrong in real merged code.

If it comes back easy again that is strike 3 on this signature, and the next move is not a third
variation of either theory. It would be to take the remaining format spelling out of the
instruction and let the graded tests define the contract, which trades directly against
Instruction Sufficiency and should be a decision made with the submitter rather than by me.


## 6. What the round-2 audit changed after the first draft

Four independent read-only audits of the rewritten instruction. Three findings were acted on and
one is the reason this round is not finished until a control has run.

**Acted on.**

1. **`TestSentinelServerTypeIgnoresVersionLineOrder` was left unmoored.** Round 2 removed the
   sentence about version-line order, and that test asserts order independence, so nothing in the
   instruction backed it any more. Checked what it was worth first: in the round-1 measurement
   none of the four wrong implementations failed it, so it discriminated nothing. **Dropped**
   rather than re-adding the hint to justify it. f2p 19 to 18.
2. **The version-hint sentence was deleted outright** rather than softened. The replacement
   wording still told the agent a trap existed, which points at the same answer. Nothing graded
   rested on it.
3. **"handing that field an expiry already in the past deletes it" contradicted the graded zero
   case** sitting next to it, which asserts that a recorded expiry of zero IS replicated. Reworded
   so the two say the same thing.

**Not acted on, and why.** The audit wanted the test-file comments reworded so they stop
documenting format facts the instruction withholds. The judge has passed twice with those
comments, the agent never sees them, and a comment that explains why a fixture is realistic helps
the coverage read rather than hurting it. Recorded as a disclosure instead of a change.

**Still open, and it is the important one.** The audit's blocking finding is that the control
which would actually answer this round has not been run: independent implementations generated
from the **round-2** instruction alone. Round 1's matrix was written by someone who knew the
answers. That control is running now against four sandboxes holding nothing but `instruction.md`
and the base repo, with no tests, no oracle and no git history.

**Structural figure worth recording, as a diagnosis and not a target.**
`removed/added` on `golden.patch` is 0.09 whole-patch and 0.51 over the Go files alone, and most
of those removals are the nine legacy command entries being relocated inside one map literal
rather than behaviour being replaced. `raising-difficulty-on-a-wrapper-task.md` puts kvdex at
0.79 and libcrux at 0.01, with AltBeacon hard at 0.12, so this ratio does not settle anything on
its own. It is here because if a third screen comes back easy it is part of the evidence for
escalating rather than for a fourth variation.


## 7. The faithfulness mapping, and the last edit it produced

The audit's faithfulness slice mapped all 30 graded ids against the rewritten instruction one at
a time. Result: **21 STATED, 6 REASONABLY IMPLIED, 0 wholly unmoored at the assertion level**, and
explicitly **no Instruction Sufficiency FAIL signature**, because no graded test references a
symbol the instruction fails to declare. That is the check that decides whether this round is
allowed to stand, and it stands.

Two exposures it named, both at the level of a fixture constant rather than an assertion:

- the `-1` marker, which 8 of the 19 fail-to-pass ids use in a fixture. The behaviour each of
  those asserts is stated; the value is withheld on purpose. Kept, and disclosed in Comments for
  Reviewer as the one place solvability was traded for difficulty
- the Valkey INFO fixture shape. One id rested on it and that id was the one already dropped for
  being worth nothing, so the exposure went with it

**One finding I had declined and then reversed on the evidence.** The audit said the graded test
files documented the two withheld facts more precisely than the instruction did, and that a judge
reads both side by side, so the tests were advertising a hidden requirement at **zero difficulty
cost**, since the agent never sees them. I had recorded that as a disclosure rather than a change
on the grounds that the judge had passed twice with those comments. The zero-cost half is the part
that matters and I was wrong to weigh it as speculative. Three comments now use the instruction's
own vocabulary, a reserved marker rather than a spelled-out value, and every fixture value and
assertion is byte-identical.

**Still pending: the discriminate control.** Four agents are implementing from the round-2
`instruction.md` and the base repo alone, no tests, no oracle, no git. They spent roughly fifteen
minutes reading before writing a line, which is suggestive and is not a measurement. The
measurement is whether their implementations pass the 18 fail-to-pass ids, and this round is not
finished until that number exists.


## 8. The control ran, and it says round 2 is spent

Four agents implemented from the round-2 `instruction.md` and the base repo alone. No tests, no
oracle, no git history, no internet. Scored against the shipped verifier:

| Sandbox | Result |
|---|---|
| s1 | **reward 1.0, 29 of 29** |
| s2 | **reward 1.0, 29 of 29** |
| s3 | **reward 1.0, 29 of 29** |
| s4 | **reward 1.0, 29 of 29** |

**4 of 4. The documentation lever is worth nothing and must not be shipped as a difficulty fix.**
`difficulty-levers-must-discriminate.md` is unambiguous here: if you cannot make anything fail it,
it is not a lever.

**Why, in the implementers' own words, which is the useful part.**

*The withheld marker changed nothing.* All four independently chose the all-ones 8-byte value.
s1 wrote `const valkeyHashFieldNoExpire = uint64(math.MaxUint64)` and said outright "it is also -1
when read signed". s2 wrote the same constant. That is the **same bit pattern** the oracle
compares against:

```
uint64 MaxUint64 -> ffffffffffffffff
int64  -1        -> ffffffffffffffff
identical: True
```

So "a reserved value, not zero, in an 8-byte field" has exactly one answer and everyone finds it.
The round-1 audit predicted this in as many words and it was right.

*The version trap did not catch them either, and this is the more important finding.* All four
wrote an order-independent parser without being told to. They split each line at the first colon
and compared the **whole field name**, so `master_redis_version` never matches and the order of
the two version lines is irrelevant by construction. None of them had to know that Valkey reports
`redis_version` first. They wrote a careful parser and carefulness dissolved the trap.

**The rule this refines.** `difficulty-levers-must-discriminate.md` says the strongest evidence a
lever is real is that the upstream author got it wrong. That has a boundary condition this task
just found: **the upstream author was patching an existing file under time pressure, and a model
writing the function fresh with the contract in front of it is not doing the same task.** A trap
that only punishes carelessness does not survive contact with an implementer who is not careless.
The lever separated the deliberate mistakes I hand-wrote in round 1 and separated none of the four
honest attempts, and only the second measurement was ever evidence about agents.

**What is kept anyway.** The round-2 edits stay in the bundle, because they are improvements on
their own terms: less hand-holding, one graded id that was worth nothing removed, a contradiction
fixed, test comments no longer advertising a hidden requirement. They are simply not a difficulty
fix and are no longer described as one anywhere.

## 9. Where that leaves the task

Two measurements now exist rather than one:

| Round | Lever | Measured effect |
|---|---|---|
| 1 | added scope, PR 1038 adapted | 8 of 8 to **7 of 8** |
| 2 | withheld the pre-solved answers | **0 of 4 in the control** |

Adding scope is the only thing that has ever moved this number. It was under-dosed rather than
wrong. **The Not Fixable path is not available and should not be reached for**: LEDGER L21 says
that verdict needs an exhausted option space including related later PRs looked at and rejected on
evidence, and exactly one related PR has been used out of at least four merged candidates in the
same area (1028 command specs, 1042 rdb preamble in the aof loader, 1043 writer deadlock on
oversized RDB values, 1048 AOF reader truncating RESP bulk strings on embedded CRLF).

The strike rule says do not ship a third variation of a spent theory, and it also says to remove
what the failure depends on. What this failure depends on is that the task is **format plumbing**:
once the formats are stated, every remaining step is mechanical, which is why four independent
attempts landed on the same answers. Removing that dependency means adding behaviour that is not
plumbing. Of the candidates, **PR 1043 is the one that is not** - a writer deadlock on oversized
values is concurrency, where honest implementations genuinely disagree and where being careful is
not sufficient. PR 1048's embedded-CRLF parsing bug is second on the same reasoning.

That is a materially larger change to what this task is, and the previous instruction was to make
it harder through documentation, which has now been measured as ineffective. Recorded here as a
recommendation and taken to the submitter rather than spent unilaterally.


---

# The difficulty artifact, read 2026-08-08

Supplied by the submitter after two rounds of asking. It is the round-1 run. It settles three
things that guesswork had left open, and one of them reverses a conclusion.

## A. The 7 of 8 was never 7 of 8 on merit

Per-trial rewards from `difficulty_screen/logs/solve/*/verifier/`:

| Trial | reward | passed |
|---|---|---|
| claude-opus-4-8 1 to 4 | 1, 1, 1, 1 | 30 of 30 each |
| codex-gpt-5-5 1, 3, 4 | 1, 1, 1 | 30 of 30 each |
| codex-gpt-5-5 2 | **0** | **0 of 30** |

The failing trial missed **everything**, including the pre-existing guards `TestCalcKeys`,
`TestCrc16`, `TestSet` and `Test_syncStandaloneReader_Status`, which have nothing to do with this
change. Its `test-stdout.txt` is **0 bytes** and its `test-stderr.txt` is one line:

```
# RedisShake/internal/rdb
internal/rdb/rdb.go:55:13: undefined: bytes
```

The agent dropped an import and left the package not compiling. `execution.commands` runs
`go build ./...` first under `set -e`, so the suite never ran. **That is the exit-code gate this
workspace added in round 0 working exactly as designed**, and it is not a difficulty signal.

**So the real score is 8 of 8 solved on merit, with one run self-destructing.** Round 1's
PR 1038 expansion, which looked like it bought one run out of eight, bought **nothing**. Both
levers tried so far measure zero. The strike table is corrected accordingly.

## B. The agentic judge passed, and its one complaint is actionable

`judge/rubric_panel_judge.json`, verdict **`ok`**, adjudicated:

| Axis | Score |
|---|---|
| realism | 5.0 |
| oracle_spec_faithfulness | 5.0 |
| oracle_no_gaming | 5.0 |
| oracle_robustness | 5.0 |
| packaging | 5.0 |
| test_faithfulness | **5.0** |
| self_containedness | 4.5 |
| clarity | 4.0 |
| prescriptiveness | 4.0 |
| test_coverage | **3.5** (claude 4, gpt 3) |

`test_coverage` is one of the two axes that flip the verdict and the bar is above 3.0, so **3.5 is
the closest thing in this bundle to a real margin**. gpt-5.5's justification names the reason, and
it is the gap this workspace already knew about and disclosed: *"the instruction explicitly says
the scan reader should ask once and use the answer when it decodes"*, and nothing grades that
wiring.

**That constrains round 3.** Any difficulty work must not push `test_coverage` down, and the one
cheap way to push it **up** is to close the scan-wiring gap. The judge has told us where its own
doubt is.

## C. What "Some tests not passed by any agent run" meant

Nothing. `difficulty_screen/summary.json` carries `"tests_results": {}`, empty, which is also why
`Task Instruction Sufficiency` reads `NOT_APPLICABLE, debug output not available`. The
`"solvable": false` field is computed from that empty map, not from the trials, every one of which
either passed all 30 or compiled not at all. It was right to refuse to reason from that line.

## D. Corrected strike table

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Difficulty screen FAIL EASY | 1, 2, 3, 4 | r1 added scope, PR 1038 (**0 on merit**); r2 withheld the pre-solved answers (**0 of 4**); r3 a defect-class PR, 1048 (**0 of 4**); r4 a liveness bug, PR 1043's writer half (**0 of 4**) | 4 |

Two levers, two zeroes, and both were measured rather than assumed. What has never been tried is
a lever that is not more surface area to specify.


---

# Revision round 3, 2026-08-08

Driven by the artifact rather than by theory, which is the first time that has been true here.

## What the artifact changed about the plan

Reading it corrected the round-1 result from "moved one run" to "moved nothing" (section A
above), so both levers tried so far measure zero. It also handed over the judge report, which
passes at `ok` but puts **`test_coverage` at 3.5** against a bar of above 3.0, with gpt-5.5's
justification naming the exact reason: *"a solution that adds the parser but never wires the scan
path could pass"*. That is the closest thing this bundle has to a real margin, and it means round
3 had two jobs rather than one: add difficulty, and do not push that axis down.

## The lever, and why not the one I recommended

I had recommended PR 1043, the writer deadlock on oversized RDB values, because it is concurrency
rather than plumbing. **Reading it against our base commit killed it.** Its `rdb.go` hunk sits on
top of PR 1018's RESTORE machinery, which our base does not have, and its own diff shows
`types.ParseObject(teeReader, typeByte, key, ld.isValkey)` so it was written on top of PR 1005 as
well. Adapting it would have meant importing PR 1018 first, which is a different feature, and
`docs/faq.md` forbids changing the scope or feature of the original PR. Recorded as a rejected
lever with the evidence, which is what `raising-difficulty-on-a-wrapper-task.md` asks for.

**PR 1048 was the one that applies.** `fix: AOF reader truncates RESP bulk strings on embedded
CRLF`, merged 2026-05-12, and the buggy code is verbatim at our base commit
(`internal/aof/aof.go:141-151`). It is related on the axis this task already owns, since PR 1005
changes the append-only path and the instruction already promises it.

**Why it is a different class from the first two levers.** It is not a format to look up. A RESP
bulk string is length prefixed precisely because its payload may contain the bytes that end a
line, and a `RESTORE` in an append-only file carries a raw snapshot value that routinely does.
The shipped code reads the payload with a line-based read and then slices it to the declared
length, which either panics or silently leaves the stream offset wrong for everything after. You
do not get this right by being careful about the requirement. You get it right by noticing that a
line-based read cannot be used on a length-prefixed binary payload.

**Measured before shipping**, four implementations of that one read:

| Implementation | Result |
|---|---|
| the fix as shipped | passes |
| line-based read then slice (**what upstream shipped and what is at our base**) | **FAIL**, 2 tests |
| read the declared length but not the terminator after it | **FAIL**, 3 tests |
| read the declared length and the terminator, but keep the terminator in the argument | **FAIL**, 3 tests |

Three distinct wrong versions caught, and the terminator ones are a genuine second trap on top of
the first.

## Budget

`fail_to_pass` was at 18 against a cap of 20, so two ids were freed by merging padding this
workspace had already identified rather than by deleting coverage:
`TreatsOneMillisecondAsAnExpiry` folded into `EmitsExpireForEveryExpiringField` as a third field,
and `KeepsKeyLevelExpiry` folded into `DecodesSeveralKeysInOneFile` by giving the second key an
expiry of its own. Every assertion survives. f2p stays **18**, p2p **12**, 30 graded ids.

## Battery, zip 74d6b0850f9383cb

| Check | Result |
|---|---|
| NOP | reward 0, raw exit 1, **12 of 30**, executed per test |
| Oracle | 1.0 at 30 of 30 |
| Agent-hostile restore | 1.0 at 30 of 30 |
| Directory at a graded path | 1.0 at 30 of 30 |
| Dash | 1.0 at 30 of 30 |

`golden.patch` 22 files to **23**, gaining `internal/aof/aof.go`.

## Pending

The round-3 discriminate control is running: four agents implementing from the round-3
instruction and the base repo alone. Round 2's identical control returned 4 of 4 and that is why
round 2 was not claimed as a difficulty fix. This round is not finished until that number exists.


## Round 3 control: 4 of 4, and the pattern is now the finding

| Sandbox | t1 | t2 | t3 | t4 |
|---|---|---|---|---|
| Result | 1.0, 30 of 30 | 1.0, 30 of 30 | 1.0, 30 of 30 | 1.0, 30 of 30 |

Unanimous on every point that was supposed to separate them. All four read the argument by its
declared length, all four consumed and checked the terminator after it, and all four picked the
all-ones marker. t1's own note is the clearest statement of what happened: it flagged the marker
as "the one genuinely uncertain point", picked `UINT64_MAX` as "the canonical reserved value for
a raw 8 byte little-endian unsigned field", and was right.

**Three levers, three measured zeroes, none of them shipped on a guess.**

| Round | Lever | Class | Measured |
|---|---|---|---|
| 1 | PR 1038 adapted as added scope | more surface to specify | 0 on merit |
| 2 | withhold the two pre-solved answers | less handed over | 0 of 4 |
| 3 | PR 1048 adapted, a real upstream defect | a defect rather than a format | 0 of 4 |

**The structural reason, which is now well evidenced rather than suspected.** Every requirement
this task can carry has, once stated, exactly one implementation a competent engineer writes. The
instruction must state them, because withholding them either breaks Instruction Sufficiency or,
as round 2 measured, withholds nothing at all. The oracle bodies are a handful of lines each and
delegate to base-commit exports. That is the same shape `raising-difficulty-on-a-wrapper-task.md`
describes, and it is not a shape that reaches MEDIUM by addition.

**What this does NOT establish.** LEDGER L19 refuted the idea that a third easy screen is by
itself the Not Fixable answer, and that refutation still stands. A Not Fixable verdict needs the
`docs/guidelines.md:217` PR-scope trigger, a measured task-side cause, and an exhausted option
space. The second is now firmly in hand. The third is close but not complete: 1038 was adapted,
1043 was rejected on evidence because it sits on PR 1018's machinery, 1048 was adapted, 1028 is
mechanical command-spec regeneration with no plausible trap, and 1042 is unmerged. The first is a
judgment that belongs to the submitter.

**One honest argument for uploading round 3 anyway, which is why this is not being called.** The
control runs on this session's model, which is newer and stronger than either model the platform
uses. **4 of 4 here is an upper bound on difficulty, not a prediction for opus-4.8 and gpt-5.5.**
Round 3 adds a real trap that a weaker model may well miss, the graded surface is larger and the
bundle is strictly better than round 2 on coverage. The screen is the ground truth and one more
reading either clears the task or completes the dossier.

**What round 3 is worth regardless of difficulty.** The append-only command stream is now graded
where it was not, which is real coverage on a path the instruction has always promised; the
padding merge removed two ids that separated nothing; and `golden.patch` now carries a second
genuine upstream defect fix, documented as a divergence.


## Round 3 closed out, 2026-08-08

Submitter's call after seeing the control: upload, on the reasoning that the control runs on a
newer model than the screen uses, so 4 of 4 is a ceiling rather than a forecast.

Every figure in `answers/submission_answer.txt` re-measured against the uploaded zip
`74d6b0850f9383cb` rather than carried forward:

| Check | Result |
|---|---|
| NOP | reward 0, raw exit 1, infra None, **12 of 30**, 40557 bytes of stdout |
| Oracle, 3 fresh containers | 1.0 at 30 of 30 each |
| Oracle, 3 applies in one container | 1.0 at 30 of 30 |
| Hostile probes | **11 of 11** to 0.0, each naming its catching test |
| Agent-hostile restore | 1.0 at 30 of 30 |
| Directory at a graded path | 1.0 at 30 of 30 |
| Dash | 1.0 at 30 of 30 |

Answers corrected where the round-3 text had been written before the control returned: the AOF
lever is no longer described as a difficulty win, the stale counts (19 graded tests, 11 guards,
39528 bytes, fourteen probes) are now 18, 12, 40557 and 11, and the difficulty answer says plainly
that eight honest implementations across two rounds have all passed.


## The scan-path coverage gap, closed 2026-08-08

The only thing the agentic judge marked down. `test_coverage` 3.5 against a bar of above 3.0,
with gpt-5.5's justification naming it exactly: *"a solution that adds the parser but never wires
the scan path could pass"*. That was true and this workspace had disclosed it twice as
ungradeable, on the grounds that the path needs a live server and the verifier is airgapped.

**It was gradeable.** Airgapped means no egress, not no sockets. The test stands a server in
front of the reader on `127.0.0.1:0` inside the test process, speaking just enough of the wire
protocol to answer what the reader actually sends: `ping`, `scan`, `info server`, `dump`, `pttl`
and `select`. It answers the way a Valkey server answers and hands back a `DUMP` whose type-22
body is in the Valkey layout, with `TargetRedisProtoMaxBulkLen` set to 1 so the reader takes the
branch that decodes the value rather than forwarding it whole.

| Case | Result |
|---|---|
| oracle | passes, five consecutive runs, no flakiness |
| **the judge's case: parser present, `restore()` passes a fixed `false`** | **FAILS**, caught by `TestSentinelScanReaderUsesTheServerAnswer` alone |
| at the base commit | Valkey case fails, Redis case passes |

So the Valkey test is `fail_to_pass` and the Redis one is a genuine `pass_to_pass` guard against
the reverse mistake, decoding a Redis server's hash with the Valkey layout. Probe e17 is the
same break run through the full verifier: reward 0.0, one named test.

Subprocess-isolated like the rest, because the reader calls `log.Panicf` which ends the process,
and `internal/reader` holds a pre-existing guard that would go down with it.

**f2p 18 to 19, p2p 12 to 13, 32 graded ids.** Battery on `45977e21f6bacfb9`: NOP reward 0 raw
exit 1 at **13 of 32** with 43487 bytes executed, oracle 3/3 at 1.0 32 of 32 fresh and stable
across three applies, **12 of 12 hostile probes** each naming its test, agent-hostile 1.0,
directory-at-a-graded-path 1.0, all four repo states 1.0, dash 1.0.

This does not change the difficulty picture and is not claimed to. It closes the one axis the
judge scored below 4 and removes a way of passing the task without doing part of it.


---

# Revision round 4, 2026-08-08

Fourth screen, same numbers as the previous two reports (opus 4/4, gpt-5.5 3/4). **Freshness could
not be checked**: the report names no test id, no line number, no command and no instruction text,
so three of the four Step 10 axes have nothing to compare. The numbers being byte-identical across
three materially different bundles is worth noting rather than trusting, and the artifact for THIS
run has been asked for.

## The lever, and why it is a different class again

The previous three levers were all "state a requirement, the agent implements it correctly".
This one is a **liveness** bug, which is the one class where being careful does not save you,
because the defect is a loop condition that can never become false.

**PR 1043's writer half applies verbatim at our base**, unlike its `rdb.go` half which was
rejected in round 3 for sitting on PR 1018's machinery. At `internal/writer/redis_standalone_writer.go`:

```go
for e.SerializedSize+atomic.LoadInt64(&w.stat.UnansweredBytes) > config.Opt.Advanced.TargetRedisClientMaxQuerybufLen {
    time.Sleep(1 * time.Nanosecond)
}
```

If a **single** entry is larger than the allowance, the condition is true with
`UnansweredBytes == 0` and stays true forever, because the reply that would free space is for a
command that was never sent. The copy stops there permanently and never reports an error.

**Related to PR 1005 by its own output.** The Valkey hash decoder this task adds emits
`hset key field value` per field. A field value larger than the target's query buffer produces
exactly such an entry, which is why PR 1043 exists and is titled for oversized RDB values.

**Measured, and this is a real measurement rather than a hand-written probe:**

| Tree | Result |
|---|---|
| base, the bug present | **FAIL**, the entry never left the writer, the test sat on its full 10 second deadline |
| PR 1043's writer fix applied | **ok in 0.017s** |

**The instruction points at the symptom, not the file or the fix**: "A single field can hold a
value larger than the target will accept in one message, and a copy that meets one has to keep
going rather than stopping there for good. That is worth checking rather than assuming, because a
run that stalls this way never reports an error." No file is named. Finding the throttle is the
work.

f2p 19 to **20**, which is exactly the static ceiling, p2p 13, 33 graded ids. `golden.patch` 23
files to **24**.

## Battery, zip 3a8da623b8966b4a

| Check | Result |
|---|---|
| NOP | reward 0, raw exit 1, **13 of 33**, 45630 bytes of stdout |
| Oracle, 3 fresh containers | 1.0 at 33 of 33 each |
| Oracle, 3 applies in one container | 1.0 at 33 of 33 |
| Agent-hostile restore | 1.0 at 33 of 33 |
| Dash | 1.0 at 33 of 33 |
| Repo-state matrix | 1.0 |

## The exhaustive lever survey

Run in parallel with the build, because a Not Fixable verdict needs the option space closed with
evidence rather than asserted (LEDGER L21). Every merged PR after 1005 that touches PR 1005's
subsystems was evaluated on four gates: applies at base, related, **is the natural implementation
wrong**, gradeable airgapped.

| PR | Verdict |
|---|---|
| 1038 Valkey server type detection | adapted in round 1, measured **0** |
| 1048 AOF reader truncates RESP bulk strings | adapted in round 3, measured **0** |
| 1043 writer deadlock on oversized values | `rdb.go` half rejected (needs PR 1018); **writer half adapted this round** |
| 1047 FUNCTION LOAD REPLACE | **not a lever**, the Go change is +1/-1 |
| 1029 remove the 128 argument limit | **not a lever** |
| 1031 AOF size via incrAOFList | **not a lever**, one line |
| 1026 discard RDB when sync_rdb=false | **not a lever**, a different feature |
| 1027 CalcKeys keyword panic | GEORADIUS, a different command family, unrelated to this PR |
| 1028 command spec regeneration | mechanical, no trap |
| 1042 rdb preamble in the aof loader | not merged |

Every one rejected for the same reason in the surveyors' own words, that it "clears every gate
except the one that matters": stating the requirement makes the correct implementation obvious.


## The survey completed: six candidates, six rejections, several of them measured

All six returned **not-a-lever**, and the surveyors did not merely reason. On PR 1027 three
independently shaped honest implementations "returned identical results on all thirteen realistic
probe cases". On PR 1032 four independent implementations "produced identical observable output".
Every rejection lands on the same sentence in different words: **it clears every gate except
discrimination, because stating the requirement is writing the implementation.**

Two findings worth keeping even though neither is a lever:

- **The shipped bundle crashes on any `GEORADIUS`.** Base `CalcKeys` panics when an optional
  keyword is absent, and `log.Panicf` ends the process. Real, and out of PR 1005's scope, so it
  belongs in Comments for Reviewer rather than in the bundle
- **The append-only loader refuses any command with more than 128 arguments** and panics rather
  than degrading. Redis's own AOF rewrite emits 130-argument `HMSET` and `ZADD`, so this is
  reachable in ordinary operation. User-reported upstream as issue 1024. A cheap and honest
  **coverage** addition if one is wanted, never a difficulty claim

One candidate produced a genuine non-zero measurement and was still rejected, which is worth
recording because it is the closest thing to a lever the survey found. Requiring the scan reader
to stop promptly on cancellation splits 3 of 4 plausible implementations, including the trap of
copying the file's own `select`/`default` idiom onto the wrong operation. It was rejected on three
grounds and the reasoning is sound: **PR 1032 causes that hang rather than fixing it and no
upstream PR fixes it**, so requiring it would be inventing a feature rather than adapting a
related later PR, which reads as PR Relevancy to a reviewer; the test would be a timeout assertion
that hangs rather than fails, which is the Time-Based Tests revision tag; and the discrimination
disappears the moment the requirement is stated fairly, because saying "must stop even while
waiting to hand an entry downstream" hands over the `select`, while omitting it grades a
distinction the instruction never drew, which is the hidden-requirement finding that would cost
the agentic judge pass this task earns every round.

**The related-later-PR option space is now closed with evidence rather than asserted.** That is
the leg LEDGER L21 says a Not Fixable verdict needs and that libcrux 1165 was criticised for
lacking.


## Round 4 control: 4 of 4. The fourth measured zero, and the reason is now unarguable

| Sandbox | u1 | u2 | u3 | u4 |
|---|---|---|---|---|
| Result | 1.0, 33 of 33 | 1.0, 33 of 33 | 1.0, 33 of 33 | 1.0, 33 of 33 |

u1's own account is the clearest statement of why a liveness bug did not work either. Given only
"a copy that meets one has to keep going rather than stopping there for good", with no file named,
it traced the symptom to the right loop, understood the mechanism unprompted, and wrote the
correct guard:

> "When one entry's own serialized size exceeds TargetRedisClientMaxQuerybufLen, draining the
> in-flight bytes never satisfies that condition, so the loop spins forever, logs nothing and
> returns no error."

It then added a `Flush()` inside the wait that the upstream fix does not have, reasoning that a
parked `processWrite` cannot run its own ticker, so the replies it waits on would never arrive.
**It improved on the upstream patch.** That is not an implementer a trap catches.

## The four rounds, in one table

| Round | Lever | Class | Measured |
|---|---|---|---|
| 1 | PR 1038 adapted, added scope | more surface to specify | **0 on merit** |
| 2 | withheld the two pre-solved answers | less handed over | **0 of 4** |
| 3 | PR 1048 adapted, a real upstream defect | a defect, not a format | **0 of 4** |
| 4 | PR 1043's writer half, a liveness bug | a hang, not a wrong value | **0 of 4** |

Four classes, four zeroes, **16 independent implementations across four rounds, every one
passing.** Plus six further candidate PRs surveyed and rejected, several with measurements of
their own. Nothing here was shipped on a guess and nothing was claimed that a measurement did not
support.

**Two independent measurement systems now agree.** The platform screen has said easy four times
on four materially different bundles, and this workspace's own control has said easy four times.
The earlier hedge that the control runs on a newer model than the screen, so 4 of 4 is a ceiling
rather than a forecast, no longer buys anything: the screen itself is the ground truth and it
agrees.

## The verdict question, with the dossier complete

`docs/guidelines.md` Invalid / Not Fixable, first condition: *PR scope needs to be changed or
reduced, the only path to validity is reducing or replacing the PR scope entirely.*

The three things LEDGER L19 says that verdict needs, and where each now stands:

| Requirement | Status |
|---|---|
| A measured task-side cause | **Held.** Every requirement this task can carry has, once stated, exactly one implementation a competent engineer writes, and the instruction must state it for solvability. Four levers and sixteen implementations |
| An exhausted option space including related later PRs rejected on evidence | **Held.** Every merged PR after 1005 touching this surface evaluated; two adapted and measured at zero, one split with half adapted and half disqualified, six rejected with reasons |
| The PR-scope trigger | **A judgment for the submitter.** PR 1005 is command-table entries plus a format branch. Making that reach MEDIUM means replacing what the PR does, which is the trigger |

**This is not being decided here.** It is a verdict change and it belongs to the submitter. Round 4
is built, verified and uploadable, and is a better bundle than round 3 on coverage and
authenticity whatever the difficulty answer turns out to be.


---

# The second artifact, 2026-08-09. A correction I have to make plainly

A genuinely new file, 4168923 bytes against the first one's 3647530, internal timestamps
2026-08-08 against 2026-08-07. **It tests the round-3 bundle** (32 required ids, carrying the AOF
and scan tests, not the round-4 writer one). So the freshness worry was unfounded and the
identical headline numbers across runs are real.

## The failing trial is a REAL failure this time, and it is the marker

| | first artifact (round 1 bundle) | this one (round 3 bundle) |
|---|---|---|
| failing trial | codex 2 | codex 3 |
| score | **0 of 30** | **25 of 32** |
| stdout | **0 bytes** | **96782 bytes** |
| stderr | `rdb.go:55:13: undefined: bytes` | **empty** |
| cause | the agent broke the build | **seven graded assertions genuinely failed** |

All seven failures are one cause. It read the eight byte expiry as an **unsigned** value and gated
on `!= 0`, so a field the format marks as never expiring came out carrying a real timestamp:

```
got:  hpexpireat h 18446744073709551615 fields 1 b
want: (no expire command at all)
```

Everything else it got right: the nine byte header, the Redis layout behind the same type byte,
the command table, the append-only bulk strings, the scan wiring and the server type check. Only
the marker.

## What I got wrong, and it was not a small thing

I described the round-2 marker withholding as **"removing hand-holding rather than adding
difficulty"** and wrote into Comments for Reviewer that "once zero is ruled out there is really
only one sensible value for a reserved marker in a signed millisecond field, and I am not going
to claim otherwise."

**That was wrong, and the platform has now shown it.** It is a real trap and it caught a frontier
model on a real run. `18446744073709551615` is the all-ones pattern read as unsigned, which is
exactly the mistake the withheld sentence used to prevent.

The reason I got it wrong is also clear and it is the more useful lesson. **My control runs on a
newer model than the screen does.** I noted that caveat early, then let it decay into a footnote
and finally started arguing the two measurement systems agreed. They do not. Opus 5 found the
marker in 16 of 16 implementations across four rounds; gpt-5.5 did not. **Every "measured zero" in
this task is a zero against a stronger model than the one being graded, which makes each of them a
ceiling and never a forecast.** I had written exactly that sentence in round 2 and then stopped
believing my own caveat.

## What this changes

**Not Fixable is off the table and should not have been my recommendation.** The task is moving on
merit. 7 of 8 with a genuine seven-assertion failure is a different object from 8 of 8 with a
build break, and the round-4 writer lever has never been screened at all.

The marker trap fires hard when it lands, taking a trial from 32 to 25, but it landed on 1 of 8
runs. Adding more tests of the same trap would not raise that rate, only its blast radius, so the
right move is a lever aimed at a different blind spot. Round 4 already carries one.

**Recommendation: upload round 4.** It has a proven-biting trap plus an untested liveness lever,
and the evidence says my local ceilings understate what the graded models will hit.

---

# CLOSED: ACCEPTED, 2026-08-11 (Step 11)

Reviewer outcome as given by the submitter: **accepted**. No Submission Quality Score, no
reviewer note and no round-4 check panel text was supplied, so the closing record says what is
known and marks the rest unknown rather than filling it in.

| Field | Value |
|---|---|
| Outcome | **accepted** |
| Final round | 4 |
| Bundle accepted | zip `64436d2f894104af`, upload-ledger row 13, 25771128 bytes, 654 entries |
| Path | Fixable |
| Uploads | 5 (rounds 0 to 4) |
| Handling time | 225 total (75 + 135 + 15), 315 revisions |
| Submission Quality Score | **not supplied** |
| Round-4 screen result | **not supplied** |

## The one inference in this block, marked as an inference

`docs/faq.md` puts the review gate - agentic judge, then the difficulty screen - **before** the
task reaches a reviewer. A reviewer accepted this task, so on that documented ordering the
round-4 bundle cleared the difficulty screen that had blocked rounds 0 to 3. **That is an
inference from the documented ordering and not a number anyone read.** What would settle it is
the round-4 eval panel or the results artifact for that run. Until one of those is seen, do not
cite "the writer lever cleared the screen" as measured; cite "the bundle carrying it was
accepted".

## What acceptance validated, and what it merely did not catch

Kept apart deliberately, per `accepted-bundle-reference.md`.

**Validated** - these had failed, were changed, and the changed version was accepted:

- The **oracle correction under `docs/guidelines.md` case 1**. Three upstream defects fixed
  inside `golden.patch` (the `-1` never-expires marker, the append-only length-prefixed read,
  the writer's wait loop), all three still on the project's default branch, all three disclosed
  in the issue blocks and in Comments for Reviewer. A reviewer read that and accepted it
- The **git-independent test-tree restore** in Go, base64 full-tree payload inside `test.sh`
- The **fake RESP server on `127.0.0.1` inside the test process** closing the scan-path coverage
  gap the agentic judge had named. Second platform confirmation that airgapped restricts egress
  and not sockets, this time in Go
- **Three adaptations from three different related later PRs in one `golden.patch`**, declared
  under PR additions with the half of PR 1043 that was deliberately left out and why
- The instruction shape: 8 paragraphs, longest 680 characters, no file path and no library named

**Not validated, merely not caught:**

- Four stale numbers in `submission_answer.txt`. Files Changed entry 5 says `fail_to_pass 10 to
  14 and pass_to_pass 1 to 11` against a live config of **20 and 13**; entry 4 says three new
  graded files against **seven**; issue 13 says 19 tests against **20**; issue 3 says twelve
  hostile breaks where Comments says thirteen. The checkbox one line below entry 5 reads
  `counted: 20`, so the file contradicts itself on the same page. **Acceptance is not evidence
  that this is fine.** Written up in `learning/answers-file-drift.md`
- `Send to reviewer: No` was still in the file when the task went to a reviewer
- `model_difficulty = "medium"` against `difficulty = "hard"`, reported and left
- `allow_extra_failures` left `true`, per LEDGER L13
- The ten CI and documentation files PR 1005 touches that `golden.patch` omits, disclosed with
  an offer to add them

## The correction this task ends on

At round 4 this record carried a completed Not Fixable dossier: four lever classes, sixteen
independent implementations all passing, six further related PRs surveyed and rejected. The
recommendation was withheld from the answers and left to the submitter, which was right, but the
reasoning had already drifted to "two independent measurement systems now agree".

**They did not agree and the task was Fixable.** The local control ran on a newer model than the
screen grades, a caveat this record stated plainly in round 2 and then argued away by round 4.
The second artifact refuted it (gpt-5.5 lost seven graded assertions to the never-expires
marker, the lever this record had dismissed as "removing hand-holding rather than adding
difficulty"), and the acceptance settles it. See LEDGER L51, L52 and L53 and
`learning/when-fail-easy-is-not-not-fixable.md`.

## Final upload ledger row

| # | Date | Zip sha256 | Size | Checks returned | Outcome |
|---|---|---|---|---|---|
| 13 | 2026-08-09 | 64436d2f894104af | 25771128 (654 entries) | uploaded round 4 | **ACCEPTED 2026-08-11** |
