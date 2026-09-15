# 20260719_045042__openwhispr_openwhispr__1002

Submission id: 451dd036-2828-4229-96a3-a1275d92ad43
Repo / PR: openwhispr/openwhispr 1002
Claimed: 2026-08-10
Verdict: **Fixable**
Status: accepted
Round: 2

Downloaded zip sha256 `4f41d578a9fd037a1f33ef3f181e4455bb50ce6f305f292eba364c9f3b542d3f`,
22138170 bytes, 697 entries, flat at the zip root, no `runs/`, no symlinks, **no directory
entries at all**. `bin/pristine-freeze.sh` verified all 697 entries against the zip's own
central directory before freezing `download/original` read-only, and `work/` was copied from
the frozen tree and diffed clean.

**No `runs/` in the download, so there is no trial evidence for this task.** Any statement about
agent behaviour has to come from the platform's own difficulty artifact, not from this bundle.

## Upload ledger

A row goes in after each zip is verified, before it is uploaded.

| # | Date | Zip sha256 | Size | Checks returned | Outcome |
|---|---|---|---|---|---|
| 1 | 2026-08-10 | `b9c072f301d075ab23aa7680d738c0b8f31acc1b8a12b19ab21c4acfebabc8e4` | 16331534 bytes, 700 entries | static, agentic judge | **Review gate blocked at the agentic judge. DISCUSS, coverage_gap.** Difficulty screen not run |
| 2 | 2026-08-10 | `f67c493a9ef30e6a7a551bba768d84b535757dfadf29a5ee7a884471fed227ae` | 16332574 bytes, 700 entries | static, agentic judge | **Blocked at the agentic judge again. DISCUSS, coverage_gap**, this time naming only the settings store |
| 3 | 2026-08-11 | `5a7862675ea1d448a3c5a4dadb07482a16e1d5c01a865cab8773d460d75138ae` | not supplied | **ACCEPTED.** The eval summary was not relayed, so which checks returned what is unknown. What is inferable: the review gate runs before a reviewer sees the task, so passing the judge AND the difficulty screen is a precondition of the acceptance |

Zip `a1dcddf87e6f078ef3a8e4459c84077bd9ec04f31129d859c658ea1292b43282` was built during round 2 and
discarded before upload. It was produced with a `bin/rezip.sh` that had been reverted to an older
commit by the incident below, so it lacked the loose-ref write-back and shipped `.git/refs/heads`
as an empty directory. Rebuilt with the restored script; the shipped zip has all three refs
entries. Only zip 3's numbers are quoted anywhere.

Zip `92c98ccc47c53740e49f83b8407bfff14b3ff9a9c794ffec7dc2e95d6ad99299` was built during round 1
and superseded before upload, when the local rehearsal found an assertion message in a new test
that also appeared verbatim in `instruction.md`. The message was reworded and the battery re-run
from scratch. Only zip 2's numbers are quoted anywhere.

An earlier zip `3339b924e5ab61ef28d8ae862a803c4c29ea7ca41b360685cc9da9dd750181fc` was built and its
battery passed, then a local Quality Check rehearsal flagged the word `alongside` in
`instruction.md` as a Q9 navigation candidate. The word was replaced, which voided that zip and
its battery, and the whole Phase B battery was re-run from fresh extracts of `b9c072f3`. Only the
second zip's numbers are quoted anywhere.

## learning/ notes applied

Every note in `learning/` was read at session start on 2026-08-10. The rows below name what
each applicable note predicts for **this** bundle and the command that settles it. A row marked
MEASURED was run during the arrival scan; a row marked TO RUN has not been.

| Note | What it predicts here | Command that settles it | State |
|---|---|---|---|
| LEDGER.md | 41 refuted claims. L7 bites directly: the f2p ids here are prose sentences (`manifest entries are unique and complete`), so the which-restore-shape one-liner cannot map any of them to a file. L9 bites too: a create-only patch still needs a restore | read it before designing any restore | MEASURED, ids are prose |
| stock-bundle-defect-baseline.md | all six scaffold defects present until proven otherwise | the baseline table below | 4 of 6 MEASURED |
| verifier-fail-open.md | `test.sh` records `raw_exit_code` at lines 446 and 470 and the success expression never reads it. The single graded command is not a pipeline, so `-o pipefail` may not be needed, but `set -e` in the generated runner still is | `grep -n 'success *=' tests/test.sh` | TO RUN |
| tests-patch-vs-agent-edits.md | `tests.patch` creates one file and edits one pre-existing test file, and `test.sh` has **no restore step of any kind** - no `rm -rf`, no base64, only `git apply` then `--3way` then `patch --forward`. An agent that writes its own `secretKeys.test.js` kills the trial | `grep -n 'rm -rf\|base64' tests/test.sh` returns nothing today | MEASURED, absent |
| solve-sh-idempotency.md | `solve.sh` ends in `git apply -p1 -R`, the reverse-apply-as-success shape. Predicts oracle 1/3 or 2/3, never 0/3 | run `solve.sh` three times in one container and assert on exit status plus a file the patch deletes | MEASURED in the file, TO RUN in a container |
| unreachable-git-blobs.md | `git fsck` is not silent: 69 unreachable objects, 37 of them blobs, plus the broken `refs/remotes/origin/HEAD` symref that no other check catches | `git fsck --unreachable --no-progress` | MEASURED, not silent |
| empty-git-refs.md | the platform's own zip carries **zero directory entries**, so an empty `.git/refs/heads` would not survive a round trip through it. A loose `refs/heads/main` is present today and the pre-zip `git gc` will delete it. Node does not stamp VCS metadata the way Go does, so the oracle-fatal half is unlikely, and it has to be measured rather than assumed | write the loose ref back after the gc, then run the four-state repo matrix | TO RUN |
| dirty-repo-and-symlinks.md | the shipped tree arrives dirty: 4 tracked files at `0 0` numstat, all `100755` to `100644`. Zero symlinks, so `zip -y` is free rather than load-bearing here | `git status --porcelain`, `git diff --numstat` | MEASURED, 4 mode-only |
| static-checks.md | `f2p` is 12, inside the hard 10 to 20 range, so the count passes as shipped. `tests/` holds exactly `config.json`, `test.sh`, `tests.patch`. **`.git/logs/HEAD` exists, so `git: no reflog` fails today** | `ls tests/`, `ls .git/logs` | MEASURED |
| dockerignore-context-root.md | any `.dockerignore` inside `environment/repo` is inert, because the build context is `environment/`. `COPY repo/ .` is at Dockerfile line 17 | `ls environment/.dockerignore`, then `find /app -name .vscode` in the built image | TO RUN |
| stale-test-reports.md | probably NA: the Dockerfile runs `npm ci`, `npm rebuild` and `npm install -g c8` but never runs the suite, so there is no build-time report for the grader to read. NA is a real answer and needs the same evidence | `grep -n 'npm test\|node --test' environment/Dockerfile` on the build steps | MEASURED, no suite run at build time |
| verify-in-the-image.md | the NOP reward has to be read for the right reason. `node --test` takes a file list, so the two graded files can be run individually at base, which is the friendly case - no collection abort to hide behind | run both graded files at base and read per-test outcomes, not the reward | TO RUN |
| non-derivable-private-names.md | audit every identifier the graded tests call against the base commit and against `instruction.md`. Both zero on the same name is the defect. JS is not a per-package compiler, so one bad name costs one test rather than the suite | `git grep -c '<name>' HEAD` and `grep -c '<name>' instruction.md` | TO RUN |
| quality-check-criteria.md | Q9 and Q10 block on their own. `instruction.md` is 3601 bytes and `problem_statement.md` is byte-identical to it. Any literal the graded tests assert must not appear in the instruction | grep each asserted fragment in `instruction.md` | TO RUN |
| prescriptiveness-check.md | a BYOK secret-manifest feature is public-surface work, which scores far better than a refactor. Expect findings on internal file paths rather than on the API names | read the instruction against the six questions in that note | TO RUN |
| source-pr-cross-check.md | `golden.patch` touches 40 files. The PR file list must be fetched through the API and **paged**, or a coverage finding gets answered against half the evidence | `curl .../pulls/1002/files?per_page=100&page=N` until a page returns under 100 | TO RUN |
| accepted-bundle-reference.md, calibration.tsv | `f2p` 12 against a measured band of 17 to 20 on five prior bundles, and `p2p` **0** against 21 to 1204. Both are unusual, which is a reason to look again rather than a target | already measured | MEASURED |
| local-runs.md | workspace is ext4 (`/dev/nvme0n1p5`), so bulk copies are cheap and the NTFS wedge cannot happen. Disposable runs still go in the session scratchpad | `df -Th .` | MEASURED, ext4 |
| git-autofetch-watcher.md | `FETCH_HEAD` can reappear in both `work/` and `download/original` on a three minute cycle, undoing a manual scrub. `download/original` is frozen read-only here, which blocks the write | `find tasks -name FETCH_HEAD` before zipping | TO RUN |
| diagnosing-platform-only-failures.md, platform-announcements.md | process rules for a red check: rerun ladder before any fix, two strikes after one has shipped, and a review-gate block is content-side | n/a until a check comes back | n/a |
| difficulty-levers-must-discriminate.md, probe-the-instruction-you-already-wrote.md, related-pr-carries-its-own-bug.md, raising-difficulty-on-a-wrapper-task.md | only if the difficulty screen blocks. Note the arrival metadata is `pass_at_k` 0/3 on both models with `agent_hardened = "true"` and one hardening cycle, which reads as hard **and** is exactly what an unsolvable task looks like. `non-derivable-private-names.md` says run the identifier audit before reading a pass rate | the identifier audit, then the discriminate matrix | TO RUN |
| oracle-bug-vs-pr-scope.md | if a graded assertion was written from the oracle's behaviour it cannot detect a bug in the oracle. Build any reference independently | n/a until the tests are read | TO RUN |
| airgapped-means-no-egress-not-no-sockets.md | `no-network` blocks egress, not sockets. If a requirement here needs an HTTP endpoint (OpenRouter is in the tags), a loopback server inside the test process grades it | bind `127.0.0.1:0` inside the test | TO RUN if needed |
| go-task-verifier-gotchas.md, rust-cargo-verifier-gotchas.md, cmake-reconfigure-needs-network.md, preflight-false-positives.md | NA, wrong toolchain. This is Node with `node --test` | n/a | NA |
| solve-sh-under-sh.md | `solve.sh` shebang is `#!/usr/bin/env bash` and the script contains no bashisms, so the accepted-bundle state applies. `test.sh` needs its own grep | `grep -nE '\[\[\|BASH_SOURCE\|pipefail' solution/solve.sh tests/test.sh` | TO RUN for `test.sh` |
| peer-review-bounces.md | name every public symbol the graded tests import, do not name source paths, and make any "equivalent wording" promise survive its own matcher | read the instruction against the tests | TO RUN |

## Stock-defect baseline

`stock-bundle-defect-baseline.md` says to treat all six as present until a command says
otherwise. Filled from the arrival scan on 2026-08-10.

| # | Defect | Verdict | Evidence |
|---|---|---|---|
| 1 | Fail-open grader, `raw_exit_code` recorded and never branched on | **Likely present, unconfirmed** | `tests/test.sh:446` and `:470` record it. The success expression has not been read yet |
| 2 | No regression guard, `pass_to_pass` empty and `allow_extra_failures` true | **Present** | `pass_to_pass` is `[]`, `allow_extra_failures` is `true`, and the repo ships a real `test/` tree that nothing guards |
| 3 | Stale build-time test reports read by the grader | **Probably NA** | `environment/Dockerfile` runs `npm ci`, `npm rebuild better-sqlite3` and `npm install -g c8`, and never runs the suite. Confirm in the NOP run rather than on paper |
| 4 | `solve.sh` not idempotent, reverse-apply fallback reports success | **Present** | `solution/solve.sh` ends `else git apply -p1 -R --whitespace=nowarn /solution/golden.patch`, the exact shape in `solve-sh-idempotency.md` |
| 5 | Graded test files carry the name an agent would choose | **Present** | `tests.patch` targets `test/helpers/secretKeys.test.js` and `test/helpers/snippetsDatabase.test.js`. Both are the obvious names in the obvious directory, and `snippetsDatabase.test.js` already exists at base |
| 6 | No test-tree restore, or one built on git | **Present, and it is the worse half** | `tests/test.sh` has no restore at all. It goes straight to `git apply`, then `git apply --3way`, then `patch -p1 --forward`. `grep -n 'rm -rf\|base64' tests/test.sh` returns nothing |

Two more the baseline does not cover, both measured:

- **Script modes.** `tests/test.sh` and `solution/solve.sh` are both **0644**. The allowed-fix
  table calls a non-executable verifier entrypoint a run-time failure that nothing local catches.
- **Git hygiene, five separate items.** `.git/logs/HEAD` (a reflog, which fails the platform's
  own static check), `.git/ORIG_HEAD`, `.git/AUTO_MERGE`, a broken `refs/remotes/origin/HEAD`
  pointing at `refs/remotes/origin/main` which does not exist, and 69 unreachable objects of
  which 37 are blobs. `.git` is 14 MB, inside the 100 MB limit. `git remote -v` is empty and
  `git rev-list --all --not HEAD` is 0, so the two checks that usually catch this are both green.

On the unreachable blobs, one sampled blob is a `node:test` file, and it contains **none** of
the 12 graded f2p ids, so it is the base version of the repo's own
`snippetsDatabase.test.js` rather than a leaked graded test. Whether any unreachable blob
carries `golden.patch` material has **not** been checked yet and is a Step 2 job.

## Arrival measurements

| Dimension | Value |
|---|---|
| language / runner | JavaScript and TypeScript, Electron app, `node --test` with the TAP reporter |
| graded command | one, `node --test --test-reporter=tap ... test/helpers/secretKeys.test.js test/helpers/snippetsDatabase.test.js` |
| `fail_to_pass` | **12** (inside the hard 10 to 20 range) |
| `pass_to_pass` | **0** |
| `allow_extra_failures` | `true` |
| f2p id shape | prose sentences, e.g. `manifest entries are unique and complete` |
| `tests.patch` | 2 files, 1 of them a create, so 1 pre-existing test file edited by the patch |
| `golden.patch` | 40 files, 115750 bytes |
| `instruction.md` | 3601 bytes, byte-identical to `environment/problem_statement.md` |
| base image | `node:24-slim`, pinned tag |
| `.git` | 14 MB, dirty tree at 4 mode-only files, reflog present |
| `[verifier] timeout_sec` | 300, against `execution.timeout_sec` 1800. The inner limit is the smaller one, which is the right way round |
| arrival difficulty metadata | `pass_at_k_opus_4_8` 0/3, `pass_at_k_gpt_5_5` 0/3, `agent_hardened` true, `hardening_cycles` 1, `difficulty` hard against `model_difficulty` medium |

## Failure signatures

Two strikes on one signature forces the remove-the-dependency path. A third variation of the
same theory does not get shipped.

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Review gate blocked at the agentic judge, `coverage_gap` | 1, 2 | r1: two derivation tests plus a store-key convention test, and the instruction narrowed off the settings store. r2: the settings store is graded rather than narrowed away | **2** |

Two strikes, and the rule was applied rather than noted. `diagnosing-platform-only-failures.md`
says a second failure on a signature means the model of the problem is wrong and the dependency
has to go rather than the theory be refined a third time. Here the dependency was *a stated
requirement the graded suite could not reach*, and round 1 removed it the weak way, by narrowing
the instruction while still mentioning the store. LEDGER **L39** names that exact move as refuted:
stand the dependency up inside the test process, or stop stating the requirement, but not the
middle path. Round 2 stands it up.

**The delta was read before the class was changed, per LEDGER L42.** Round 1 scored 3.5 on the
coverage axis with two named holes; round 2 scored 4.0 with one, and the derivation hole did not
come back. A number that moves means the class of fix was right and under-powered, not that it
missed. So round 2 finished the same class of work rather than switching to a different one.

`Not run: difficulty screen` is not a signature and gets no row, because the judge gates the
screen and blocking there means the screen never started.

## Handling-time ledger

The answers form's revision figure is copied from the last Cumulative cell, never remembered.

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 0 | 2026-08-10 | 0 | 0 |
| 1 | 2026-08-10 | 60 | 60 |
| 2 | 2026-08-11 | 60 | **120** |

Round 0 is the first pass and its time sits in fields 1, 2 and 3 of the form, not in the revision
field. The answers file's revision figure is copied from the last Cumulative cell above and is
never recalled or re-estimated.

## Check history

Round 0 was uploaded as zip `b9c072f3`. Static checks passed and the **review gate blocked at the
agentic judge**, so the difficulty screen never ran. Round 1 is applied and zipped as
`f67c493a`, not yet uploaded.

## Revision round 1, 2026-08-10

### The feedback, verbatim in the parts that decide anything

```
Status:    DISCUSS
Reason:    coverage_gap

  clarity                   5.0/5
  oracle_no_gaming          5.0/5
  oracle_reproducibility    5.0/5
  oracle_spec_faithfulness  3.0/5   (claude 5, gpt 3)
  packaging                 3.0/5   (both)
  prescriptiveness          2.0/5   (both)
  realism                   4.5/5
  self_containedness        5.0/5
  test_coverage             3.5/5   (claude 5, gpt 3)
  test_faithfulness         5.0/5

Rationale (from driving judge):
... a central architectural requirement that each provider's plumbing be defined exactly once
and that the environment/IPC layers derive from the manifest [instruction.md:3-5]
[instruction.md:9-13] is not enforced: the tests only check methods/channels exist and work with
the manifest's current values [tests/tests.patch:194-205] [tests/tests.patch:312-357], so a
solution that adds the manifest but keeps separate hand-coded accessors/channels can pass. The
settings-store part is also under-tested: `storeKey` is only checked for nonempty uniqueness
[tests/tests.patch:170-182], while the test imports only the manifest, environment manager, and
IPC handlers - not `settingsStore` [tests/tests.patch:75-77] - so a solution that never wires
OpenRouter into settings storage can pass.

Agent Runner Summary: Evaluation FAILED. Review gate blocked at the agentic judge
```

### Freshness check, all four axes green

The report describes the bundle I actually shipped, so it was acted on rather than queried.

| Axis | Result |
|---|---|
| Line numbers | every citation lands inside the current file. `task.toml:4-5` are the two `pass_at_k` lines, `:18` and `:22` the difficulty clash, `config.json:271` is `allow_extra_failures`, `golden.patch:2489` is the `settingsStore.ts` hunk |
| Content at those lines | each one says what the report claims it says |
| Commands | `config.json:4-6` is the single `node --test` command the bundle ships |
| Instruction text | every phrase quoted is present, including `derives its per-provider accessors from the manifest` and `carries its own inline copy` |
| Test imports | `tests.patch:75-77` really is exactly the manifest, the manager and the IPC handlers, with no `settingsStore` |

### Finding 1, the blocking one, and it was mine

The judge said a solution that declares the manifest and hand codes the accessors and channels
alongside it would pass. **Measured rather than argued.** I wrote that implementation, replacing
the two derivation loops in `environment.js` and `ipcHandlers.js` with eight hand written entries
each, leaving the manifest declared and untouched:

```
hand-coded implementation vs the round 0 suite:   13 tests, 13 pass, 0 fail
```

So the hole was exactly as described. Two new graded tests close it by making the manifest the
only input: a ninth provider is added to the array at run time, the manager and the IPC layer are
reloaded against it with `Module._resolveFilename` matching on the manifest's own path, and that
provider then has to have working accessors and both channels with no other edit anywhere. The
tree is restored afterwards and the suite asserts the extra provider is gone again.

```
hand-coded implementation vs the round 1 suite:   16 tests, 14 pass, 2 fail
  not ok - sentinel a provider added to the manifest gets working accessors with no other edit
  not ok - sentinel a provider added to the manifest gets main process channels with no other edit
```

### Finding 2, the settings store, is a spec gap rather than a test gap

`source-pr-cross-check.md` says to check a coverage finding against the source PR before acting
on it. PR 1002's `settingsStore.ts` change **never mentions the shared module**: measured through
the API, the hunk contains no `secretKeys` and no `BYOK_API_KEYS`, hand writes 14 `openrouter`
strings, and keeps one setter per provider routed through a local `createSecretSetter` helper.
`golden.patch` reproduces that faithfully. So the instruction was over promising when it said all
four layers come from one definition, and the honest fix is in `instruction.md`, not the oracle.
Making the store derive from the manifest would be adding behaviour the PR does not have.

The narrowing then had to not create coverage debt, per `quality-check-criteria.md`. `storeKey`
was previously only checked for uniqueness and non emptiness. It now has to follow the same
`<base>ApiKey` naming the seven existing providers use, which is readable at the base commit in
4 to 9 files each while `openrouterApiKey` appears in none.

**Grading the store itself was attempted and rejected on measurement, not on preference.**
`settingsStore.ts` is TypeScript renderer code. Node 24 strips the types and parses it, and it
then fails on extensionless imports; behind a `registerHooks` resolver it gets through the whole
TS graph and fails on Vite style JSON imports needing an import attribute. A bespoke loader chain
for the renderer bundle inside the verifier is exactly the unobservable dependency
`diagnosing-platform-only-failures.md` says not to build on, so it was not shipped and the
instruction no longer promises what cannot be checked.

### Finding 3, over specification, answered with behaviour rather than deletion

Both readers scored it 2.0 and quoted the module path, the exported array, the five field names,
the provider order, and the two sentences describing how the manager and the preload are built.
Every symbol in that list is called by name in a graded test, so cutting them trades an advisory
score for tests no agent can satisfy, which is LEDGER L37. What moved instead is the framing: the
sentence that described the mechanism now states the outcome, and the outcome is the thing the two
new tests enforce.

| Before | After |
|---|---|
| the manager derives its per-provider accessors from the manifest | adding a provider has to become a one entry change, and a ninth entry should work end to end on its own |
| the preload carries its own inline copy of the tuples | the preload cannot import a local module at all, so it has to keep working without importing the shared definition |

### Finding 4, packaging, deliberately not acted on. SETTLED 2026-08-10

Both readers capped packaging at 3.0 for the `model_difficulty = "medium"` against
`difficulty = "hard"` clash and for `pass_at_k` recorded as `0/3` rather than a full attempt
count. Section 8 and LEDGER L14 both forbid hand editing difficulty or pass rate metadata to make
a check pass, and these are the platform's own arrival values. They are also stale by LEDGER L27:
the `0/3` was measured on a bundle where two graded tests demanded an accessor name the
instruction never gave and a third matched renderer source with a formatting sensitive regex, so
no agent could have passed it. **Raised with the submitter as a decision, and the decision came back: keep whatever the zip
says.** So the arrival values ship unchanged and this is closed rather than open. Verified against
the shipped zip rather than assumed: `diff download/original/task.toml` against the copy inside
`f67c493a` returns exactly four changes, and not one of them is a difficulty or pass rate field.

| Field | Pristine | In the shipped zip |
|---|---|---|
| `pass_at_k_opus_4_8`, `pass_at_k_gpt_5_5` | `"0/3"` | `"0/3"` |
| `model_difficulty`, `difficulty` | `"medium"`, `"hard"` | `"medium"`, `"hard"` |
| `hardening_cycles`, `agent_hardened` | `"1"`, `"true"` | `"1"`, `"true"` |

The only `task.toml` edits in the bundle are the two documented fields that were missing,
`[environment] os` and `[metadata] difficulty_explanation`, plus `[verifier] timeout_sec` 300 to
900 and `[agent] timeout_sec` 1800 to 7200 so the 600 second execution limit sits underneath the
verifier limit rather than above it.

**Do not reopen this in a later round without a fresh instruction.** If the reviewer asks directly
for the two difficulty fields to be aligned, that is the one case Section 8 allows, and the change
then gets made and attributed to their note. A judge marking packaging down is not that case.

### Supersede greps run over the answers file

`learning` says a round that replaces a mechanism must edit every block that still describes the
old one, not just append. Greps run and resolved: `13 tests`, `counted: 13`, `224 of 224`,
`Six hostile`, `Eight agent`, `nine short paragraphs`, `b9c072f3`, `3339b924`. All updated or
confirmed as correct history. The only surviving mentions of 12 and 13 describe the bundle as it
arrived and the round 0 suite, which is what they are meant to describe.

### Battery, round 1, against zip `f67c493a`

| Run | Result |
|---|---|
| NOP | reward **0**, raw exit **1**, `infrastructure_error: None`, 46200 bytes of stdout |
| NOP split | **0 of 16** graded ids pass at base, **211 of 211** guards execute and pass at base |
| Oracle, three applies in one container | **3/3** at 1.0, **227 of 227**, 0 unexpected, idempotent, 41 changed files stable |
| Oracle runtime | 1.24 s against a 900 s verifier timeout |
| Hostile deletes | **13 of 13** drop the reward to 0.0, each naming its test |
| Agent and environment cases | **9 of 9** hold at 1.0 and 227 of 227 |
| Phase A against the extracted zip | 6 passed, 0 failed, 0 warnings |
| Drift | none across all 700 entries |

The headline hostile probe is the hand coded implementation above. The rest cover an off
convention store key, an off convention env name, the manifest env vars removed from the secret
set, a channel bypassing the manager, a preload importing the manifest, a preload pointing at the
wrong channel, clearing leaving the env var, openrouter dropped, the main process skipping
registration, a duplicate store key, a renamed legacy accessor, and the generation loop removed.

## Round 0 verification, 2026-08-10, zip `b9c072f3`

Every number below was measured against a fresh extract of the zip in `upload/`, in an image
built from that extract, not from `work/`.

### Phase A

`bin/preflight.sh` against the extracted zip: **6 passed, 0 failed, 0 warnings**. Both scripts
`0755`, `tests/` holds only `config.json`, `test.sh`, `tests.patch`, `git fsck --unreachable`
silent, `.git` exactly the whitelist, loose `refs/heads/main` written back after the gc so no
extractor can drop an empty `refs/` (the platform's own download carries zero directory entries).
`bin/work-vs-zip-drift.sh`: **no drift across all 700 entries**.

### Phase B

| Run | Result |
|---|---|
| NOP | reward **0**, `test.sh` exit 1, `raw_exit_code` **1**, `infrastructure_error: None`, 46199 bytes of stdout |
| NOP split | **0 of 13** fail-to-pass ids pass at base, **211 of 211** pass-to-pass ids execute and pass at base |
| Oracle, three `solve.sh` invocations in one container | **3/3** at reward 1.0, 224 of 224 required, 0 unexpected, runs 2 and 3 report `already applied; nothing to do`, changed-file count stable at 41 |
| Oracle runtime | 1.22 s against a 900 s verifier timeout |

The NOP is an executed measurement rather than a symbol audit. The graded file cannot load at
base (`Cannot find module '../../src/config/secretKeys'`), and the 211 regression guards in the
same run executed and passed, which proves the run reached the test phase instead of aborting.

### Hostile delete, 6 of 6, each naming its test

| Stub | Reward | Caught by |
|---|---|---|
| manifest env vars not spread into the manager's secret set | 0.0 | `sentinel manifest environment variables are persisted with the manager's other secrets` |
| save channel writes to a private store instead of the manager | 0.0 | `sentinel a save channel round-trips through the environment manager` |
| preload requires the manifest instead of inlining it | 0.0 | `sentinel the sandboxed preload exposes a bridge for every manifest entry` |
| clearing a key leaves the environment variable set | 0.0 | `sentinel clearing a key empties the accessor and removes the environment variable` |
| openrouter dropped from the manifest | 0.0 | `sentinel manifest lists exactly eight providers in the documented order` |
| main process skips registering the openrouter channels | 0.0 | `sentinel the main process answers a get and a save channel for every manifest entry` |

Every probe asserts its own edit landed before the reward is read. A further six probes were run
against `work/` during design (duplicate store key, off-convention env name, renamed legacy
accessor, no generated accessors, wrong preload channel, preload drops one bridge) and all six
were caught by a named test, so 12 of 12 in total.

### Agent-collision and environment matrix, 8 of 8 at reward 1.0

| Case | Reward |
|---|---|
| agent wrote its own file at the graded path, committed, then deleted `.git` | 1.0, 224/224 |
| agent broke a pre-existing test and committed | 1.0, 224/224 |
| a directory planted at the graded path | 1.0, 224/224 |
| no `.git` at all | 1.0, 224/224 |
| `.git` empty directories deleted (the extractor signature) | 1.0, 224/224 |
| agent deleted the whole `test/` directory | 1.0, 224/224 |
| both entrypoints run under `sh` (dash) | 1.0, 224/224 |
| `TZ=Pacific/Kiritimati LANG=C LC_ALL=C` | 1.0, 224/224 |

### The exit-code gate, proven directly

The embedded grader was extracted from the shipped `test.sh` and from the pristine one, and both
were run over the same fully passing oracle log:

| Grader | raw exit 0 | raw exit 1 |
|---|---|---|
| as it arrived | reward 1 | **reward 1** |
| as shipped | reward 1 | **reward 0** |

### Local Quality Check rehearsal

Q9 navigation finder: **0 hits**. Q10 literal detector: **59 long literals added by
`tests.patch`, 0 appear in `instruction.md`**. No auto-REMOVE pattern present. Packaging sweep
clean, `tests/` holds three allowed entries, `git fsck` silent, nothing matching the manifest
symbols readable anywhere in the shipped repo. Instruction longest paragraph 606 characters,
against the under-800 band the bundles not bounced on clarity sit in.

## Findings

Numbered, each with a file and a line, from Step 3.

1. **Solution leakage from an agent path.** `environment/repo/.git` held 69 unreachable objects
   including two `git stash` commits of the **solved** tree. `git cat-file -p` on blob
   `09ea89d7` printed the finished `preload.js` with the complete `BYOK_KEY_BRIDGES` array,
   including `{ base: "openrouter", get: "getOpenrouterKey", save: "saveOpenrouterKey" }` which
   is the exact tuple the shipped graded regex asserted. Blobs `e4a23f9a` and `cd688b4f` printed
   the finished `src/helpers/environment.js` and `src/helpers/ipcHandlers.js`. The stash tree
   also carried the patched `test/helpers/snippetsDatabase.test.js`. Every other git check was
   green: no remote, no refs past HEAD, `git rev-list --all --not HEAD` empty. Only
   `git fsck --unreachable` caught it. Fixable trigger 6 and 10.
2. **Git hygiene, five further items.** `.git/logs/HEAD` present, which fails the platform's own
   `git: no reflog` static check; `.git/ORIG_HEAD`; `.git/AUTO_MERGE`; a broken
   `refs/remotes/origin/HEAD` with an invalid sha1 pointer that no check but `fsck` reports; and
   a dirty working tree, 4 tracked files at `0 0` numstat, all `100755` to `100644`. Trigger 10.
3. **Fail-open grader.** `tests/test.sh` records `raw_exit_code` and its success expression never
   reads it. Proven by running the extracted grader over one passing log twice. Trigger 13.
4. **No test-tree restore of any kind.** `tests/test.sh` went straight to `git apply`, then
   `--3way`, then `patch --forward`. `tests.patch` created `test/helpers/secretKeys.test.js`,
   which is the obvious name in the obvious directory for a task whose deliverable is
   `src/config/secretKeys.js`, and also edited the pre-existing
   `test/helpers/snippetsDatabase.test.js`. Either collision gives
   `infrastructure_error: tests.patch did not apply`, which the difficulty harness scores as an
   invalid trial rather than a wrong answer. Trigger 13.
5. **A graded test read source text.** `tests/tests.patch:75-85` read `preload.js` with
   `fs.readFileSync` and matched a regex requiring double-quoted values, the property order
   `base, get, save`, and no trailing comma. A correct preload written with single quotes, a
   different property order, or a programmatically built array failed it. It also forced the
   instruction to publish the literal declaration form `BYOK_KEY_BRIDGES = [ ... ];`. Trigger 4.
6. **Non-derivable names grading 2 of 12 ids.** `getOpenrouterKey`, `saveOpenrouterKey` and
   `OPENROUTER_API_KEY` are absent at the base commit (`git grep` over HEAD returns nothing) and
   absent from `instruction.md`, yet `tests/tests.patch:69,153,155,157` asserted them by exact
   spelling. `getOpenRouterKey` is at least as plausible a spelling given base carries
   `getOpenAIKey`. Trigger 4.
7. **Three stated requirements had no enforcing assertion.** The instruction stated the IPC
   channel pair and named the IPC layer as one of the four places, and nothing in the graded
   suite touched `src/helpers/ipcHandlers.js`; an implementation that built the manifest, the
   accessors and the preload but never wired the main process scored 12 of 12. The instruction
   stated that the sandboxed preload cannot require a local module, and nothing enforced it. The
   instruction stated that the manifest's env vars feed the manager's known secret keys, and the
   test named after that requirement only repeated the round-trip assertion from another test.
   Trigger 3.
8. **Padding rather than distinct contracts.** PR 1002 ships 4 tests; the bundle reached 12 by
   restating them. Test 12 duplicated test 1's presence check, test 9 overlapped test 1's
   uniqueness check, test 7 duplicated test 2, and test 8 asserted `{success: true}` which the
   base `_saveKey` returns unconditionally. Test 12's title claimed the entries carry no fields
   beyond the five and its body never checked that.
9. **`pass_to_pass` empty with `allow_extra_failures` true**, against a repo shipping 213
   top-level tests in 28 files. Nothing outside the new feature could fail the reward. Trigger 13.
10. **A silent skip widened by `tests.patch`.** The patch broadened the `t.skip` guard in
    `test/helpers/snippetsDatabase.test.js` from `NODE_MODULE_VERSION` to also cover
    `Could not locate the bindings file`. That file was in the graded command and owned no graded
    id, so a silent skip of the whole suite was invisible. Auto-REMOVE `Silent skip`.
11. **`solve.sh` reverse-applied as its success path.** `solution/solve.sh:9` ended
    `else git apply -p1 -R`, so a second invocation removed the solution and exited 0. The
    platform runs the oracle three times. Trigger 13.
12. **Both scripts shipped at `0644`.** Trigger 12, the allowed-fix table's non-executable row.
13. **`golden.patch` disagreed with PR 1002 in both directions.** It carried
    `src/components/notes/PersonalNotesView.tsx` and `src/stores/actionProcessingStore.ts`, which
    implement note-title generation gating and are in no way part of the secret manifest, and
    neither file is in PR 1002. It omitted `.github/workflows/tests.yml` and
    `docs/network-allowlist.md`, both of which the PR carries and the second of which is part of
    onboarding OpenRouter. Trigger 12.
14. **Instruction navigation and verifier mechanics.** The instruction named
    `src/helpers/environment.js`, `src/helpers/ipcHandlers.js` and `preload.js` and described
    where each piece of code lives today, and closed with `The test files remain unchanged.`
    Longest paragraph 1112 characters. Trigger 1.
15. **task.toml.** `[environment] os` missing; `[metadata] difficulty_explanation` missing;
    `execution.timeout_sec` 1800 against `[verifier] timeout_sec` 300, so the inner limit could
    never fire; `[agent] timeout_sec` 1800 against a 7200 ceiling. Trigger 11.

Reported and deliberately not changed: `model_difficulty = "medium"` against `difficulty = "hard"`;
`[agent] allowed_hosts` and `[environment] network_mode` disagreeing with the pasted platform
block; and the Dockerfile's `CMD ["sh", "-c", "npm test"]`, which has no `test` script at the base
commit. Harbor overrides the CMD and the PR's own `package.json` hunk adds the script, so nothing
downstream breaks and the line is not on the allowed-fix table.

## Files changed

1. `instruction.md`
   Changed: rewritten. Removed the two internal source paths and the where-the-code-lives-today
   narrative, removed the `The test files remain unchanged.` line, removed the literal
   `BYOK_KEY_BRIDGES = [ ... ];` declaration form, stated the main-process channel registration
   and the preserved-names requirement, and split one 1112-character paragraph into nine
   paragraphs whose longest is 606 characters.
   Why: findings 5, 7, 14.
2. `environment/problem_statement.md`
   Changed: re-copied from `instruction.md`, byte-identical.
   Why: the copy rule.
3. `solution/golden.patch`
   Changed: regenerated. Dropped `src/components/notes/PersonalNotesView.tsx` and
   `src/stores/actionProcessingStore.ts`, added `.github/workflows/tests.yml` and
   `docs/network-allowlist.md` from the PR. Now 40 of 40 non-test PR files, nothing extra.
   Why: finding 13.
4. `solution/solve.sh`
   Changed: rewritten forward-only with a reverse-apply probe, a plain apply, a `--3way` retry
   and a loud failure, plus a dash re-exec guard. Mode `0755`.
   Why: findings 11, 12.
5. `tests/tests.patch`
   Changed: regenerated as a create-only patch adding one verifier-only file,
   `test/helpers/sentinelByokManifest.test.js`, with 13 graded tests. The old
   `test/helpers/secretKeys.test.js` and the `snippetsDatabase.test.js` skip-widening hunk are
   both gone.
   Why: findings 4, 5, 6, 7, 8, 10.
6. `tests/config.json`
   Changed: `fail_to_pass` 12 to 13 new ids, `pass_to_pass` 0 to 211,
   `allow_extra_failures` true to false, `execution.timeout_sec` 1800 to 600, and the graded
   command now runs the new file plus all 28 pre-existing test files.
   Why: findings 9, 15.
7. `tests/test.sh`
   Changed: a base64 payload of the base `test/` tree embedded in the file and restored before
   `tests.patch` is applied, with a create-only sweep of the paths the patch adds; the reward
   gated on `raw_exit_code == 0` inside the grader's success expression; `2>` changed to `2>>`
   on the runner so the restore and apply diagnostics survive; `set -e` emitted into the
   generated runner; a dash re-exec guard. Mode `0755`. 18902 to 50200 bytes.
   Why: findings 3, 4, 12.
8. `task.toml`
   Changed: added `[environment] os = "linux"` and `[metadata] difficulty_explanation`, raised
   `[agent] timeout_sec` to 7200 and `[verifier] timeout_sec` to 900 so the inner
   `execution.timeout_sec` of 600 can actually fire.
   Why: finding 15.

Plus git metadata inside `environment/repo`, which is not a file change: stash cleared, reflog
expired, `gc --prune=now`, `logs`, `ORIG_HEAD`, `AUTO_MERGE` and `refs/remotes` removed, the 4
mode-only files restored, and the loose `refs/heads/main` written back after the gc.

## Tooling overrides recorded

`bin/checks/60-answers.sh` returns one FAIL and one WARN on the answers file. Both were read
before being dismissed, per `learning/preflight-false-positives.md`.

- **`answers.graded-total` FAIL is a false positive.** The check flags any `N of N` above 30 that
  is not the graded total of 224. It matched `211 of 211 regression guards execute and pass` and
  `40 of 40 non-test files the PR touches`. Both are correctly labelled counts of something other
  than the graded set, and the real total does appear as `224 of 224 required tests`. The check's
  own comment says it exists to catch a stale total left over after a round changed the counts,
  which is not the case here. Nothing was changed to satisfy it.
- **`answers.issue-headings` WARN is expected.** Blocks 5 to 12 sit under the
  `Additional findings outside the listed categories` heading, which is the shape Section 2
  prescribes for defects that map to none of the seven platform categories. The checker cannot
  tell that group apart from an invented heading.

`bin/preflight.sh` against the extracted zip returns 6 passed, 0 failed, 0 warnings, so there is
no packaging override to declare.

## Open question for the submitter

The pasted platform block and `work/task.toml` disagree on two network fields and the disagreement
has not been resolved.

| Field | Platform block | `task.toml` as shipped and as sent |
|---|---|---|
| `[agent] allowed_hosts` | six hosts including `registry.npmjs.org` and the Anthropic and OpenAI endpoints | `["api.portkey.ai"]` |
| `[environment] network_mode` | `"no-network"` | `"public"` |

The file's values are kept, because Section 8 requires exactly `["api.portkey.ai"]` and a `public`
build network, and `no-network` at build time would stop `npm ci` and break the image. Ask which
rendering the platform actually holds before either value is treated as authoritative.


## Revision round 2, 2026-08-11

### The feedback

`Status: DISCUSS`, `Reason: coverage_gap`, blocked at the agentic judge again so the difficulty
screen still has not run. Axis movement round 1 to round 2: coverage 3.5 to **4.0**,
oracle spec faithfulness 3.0 to **5.0**, packaging 3.0 to 3.5, clarity 5.0 to 4.5, over
specification flat at 2.0. The round 1 derivation complaint did not return. The driving judge:

```
they never import or exercise `src/stores/settingsStore.ts`; they only assert the manifest's
`storeKey` string [tests/tests.patch:408-415]. Thus a plausible implementation that leaves the
settings store without an OpenRouter state key/setter or without persisting under `storeKey`
would still pass, despite the instruction explicitly requiring the settings-store persistence
key and setter [instruction.md:1-7].
```

Freshness checked green on all four axes before anything was touched: every cited line lands
where the report says, `tests.patch:408-416` is the store-key test, `:418` the ninth-provider
test, `config.json:42` the fail_to_pass list, and `tests.patch:75-77` really is exactly three
requires with no `settingsStore`.

### What changed, and why it is not a third narrowing

The store **can** be graded. It is renderer TypeScript, and node needs two things the app's
bundler does for it: the file extension it will not guess, and the json import attribute it
requires. A `registerHooks` resolver supplying both loads the real module in about 150 ms with
its own code unmodified. Measured end to end: every provider's store setter routes to exactly
that provider's `save` accessor, through the store's own `SECRET_IPC_SAVERS` lookup.

Two graded tests were added on that. Three controls prove they catch the judge's scenario:

| Control | Reward | Caught by |
|---|---|---|
| OpenRouter left out of the store entirely | 0.0 | both new tests |
| its setter points at another provider's save accessor | 0.0 | the routing test |
| its store key renamed | 0.0 | the key test |

One subtraction as well, aimed at the over-specification score: the required **ordering** of the
eight providers was arbitrary and no test needed it, so the instruction now says the order is up
to the implementer and the test grades the set. Everything else both readers quoted is called by
name in a graded test, so cutting it would trade an advisory score for tests no agent can pass.

f2p 16 to **18**, graded total 227 to **229**.

### Battery, round 2, against zip `5a786267`

| Run | Result |
|---|---|
| NOP | reward **0**, raw exit **1**, `infrastructure_error: None`, 46197 bytes of stdout |
| NOP split | **0 of 18** graded ids pass at base, **211 of 211** guards execute and pass |
| Oracle, three applies in one container | **3/3** at 1.0, **229 of 229**, 0 unexpected, idempotent, 41 changed files |
| Oracle runtime | 2.58 s against a 900 s verifier timeout |
| Hostile deletes | **17 of 17** drop the reward to 0.0, each naming its test |
| Agent and environment cases | **9 of 9** hold at 1.0 and 229 of 229 |
| Phase A against the extracted zip | 6 passed, 0 failed, 0 warnings |
| Drift | none across all 700 entries |

## Incident, 2026-08-11: an accidental workspace reset during round 2

Recorded because it explains the discarded zip and because the lesson is cheap.

A command chained `cd <scratch dir> && git reset --hard HEAD && git clean -fdx`. The scratch
directory had already been cleaned up, the `cd` failed, and under `set -e` a failing `cd` inside
a `&&` list does not stop the script, so the git commands ran against the wrong tree. Effects:
every uncommitted change to tracked files in the workspace was reverted to the last commit,
`.claude/rules/` and twelve untracked `learning/` notes were deleted, and this task's `work/`
was emptied.

Recovery was complete except for one file. `work/` was restored byte for byte from the round 1
zip, which the drift check confirmed at 700 of 700 entries. The workspace files were recovered
from unreachable git objects, matched by content similarity and by frontmatter identity rather
than by guesswork, and verified against the sizes recorded earlier in the session: 39 of 40
tracked files, all 12 rule files, all 35 `learning/` entries. `revision.md` at the workspace root
was untracked and never hashed, so git could not return it.

**The rule that would have prevented it: never chain a destructive git command after an
unguarded `cd`.** Use `git -C <path>` so the target is explicit and a missing directory is an
error rather than a silent inheritance of the current one. Every git call in the round 2 rebuild
uses `-C`.

The second lesson is that the reverted `bin/rezip.sh` silently cost a correct zip. The first
round 2 zip was built with the older committed script, which lacks the loose-ref write-back, and
shipped `.git/refs/heads` as an empty directory. The tooling has to be verified after any
recovery, not assumed.


## Closed, 2026-08-17: ACCEPTED

The reviewer accepted the task. Round 2, zip
`5a7862675ea1d448a3c5a4dadb07482a16e1d5c01a865cab8773d460d75138ae`, is the accepted bundle.

**Three closing numbers were not supplied and cannot be reconstructed later.** Recorded as
`not supplied` in `learning/calibration.tsv` rather than guessed:

| | |
|---|---|
| Reviewer verdict | Accept. No written notes were relayed |
| Submission Quality Score | not supplied |
| Final difficulty screen result | not supplied, and it is the number most worth having had. Rounds 0 and 1 blocked at the judge and both reports said the screen was not run, so **this task has no observed difficulty measurement at all**. Round 2 is different and an earlier draft of this block got it wrong: the gate runs before a reviewer sees the task, so the screen must have run on round 2 and must have passed, and only its value is missing rather than its existence |

Ask for all three in the same message that receives an acceptance. This is the second task to
close without them.

Final handling times: 85 review, 120 rewrite, 15 form, **220 total**, **120 revisions** across two
rounds. Three uploads.

### What the acceptance validates, and what it does not

Acceptance validates what previously failed and was then changed. On this task that is a short
and specific list:

- **grading the settings store rather than narrowing it away.** Round 1 narrowed and was blocked
  naming that layer; round 2 graded it and passed
- **grading the derivation rather than the instances.** Round 0's suite passed an implementation
  that hand-wrote every consumer; round 1 added the mutation tests and that complaint never
  returned
- **dropping the arbitrary provider ordering**, which was the one over-specification item no test
  needed

Everything else in the bundle was never the reason a round bounced and is therefore defensible
but unvalidated: the git-independent restore payload, the exit-code gate, the 211-id regression
guard, `allow_extra_failures: false`, the sandbox-simulating preload test, and the stashed-solution
scrub. A reviewer would have found the fail-open grader; nothing in this result proves it mattered
here.

**Two things were accepted while still marked down.** Both judges capped packaging on the
difficulty metadata in both reported rounds, and both scored over-specification 2.0 in both
rounds. Neither blocked. The metadata was left exactly as it arrived at the submitter's explicit
instruction, and the over-specification residue is every symbol a graded test calls by name, which
is the floor `learning/prescriptiveness-check.md` describes.
