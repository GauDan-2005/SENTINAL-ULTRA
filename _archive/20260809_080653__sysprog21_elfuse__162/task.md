# 20260809_080653__sysprog21_elfuse__162

| | |
|---|---|
| Submission id | `4ef5f832-93a7-4c02-b21d-276425e529c7` |
| Repo / PR | sysprog21/elfuse PR 162, "Implement times(2) syscall" |
| Base commit | `23ec9b0ac58719d92cda5a076877d2118d77b705` |
| Language / runner | C plus Shell, GNU Make with an `mk/` include tree, graded through **pytest**, `ubuntu:24.04` |
| Category | implementation / feature |
| Arrival difficulty | `difficulty = "hard"`, `model_difficulty = "medium"`, `pass_at_k` 0/3 on both models |
| Claimed | 2026-08-10 |
| Verdict | **Fixable** |
| Status | `accepted` |
| Round | 0 |

Downloaded zip `4ef5f832-93a7-4c02-b21d-276425e529c7_submission.zip`,
sha256 `4be890cb0fdd61724152054cfad5eb6753336a5c6f7be185a9c8effcf3d2f86c`, 14969066 bytes,
359 entries, 0 symlinks, already flat. `download/original/` frozen since 2026-08-10 11:18.

**No `runs/` shipped, so there is no agent trial evidence.** Every statement about agent
behaviour here comes from a local measurement and is labelled as one.

## The finding that shaped the whole round

The repository is a macOS / Apple Silicon program. `src/core/guest.h:22` and
`src/syscall/proc.h:18` include `<Hypervisor/Hypervisor.h>`, `src/syscall/proc.c` includes
`<libproc.h>` and `<sys/sysctl.h>`, and `README.md` lists Hypervisor.framework and an Apple
Silicon Mac as requirements. The verifier image is `ubuntu:24.04`. The shipped bundle
concluded from that it could not execute anything, said so in its own test docstring
(`tests/tests.patch:234`, "These tests inspect the source instead"), and graded all 15
fail-to-pass ids with regular expressions over C and header text.

`docs/guidelines.md:135` bans that by name, and `docs/tasking-guide.md:324` puts it on the
Quality Check judge's own Don't list. So the shipped suite was not merely weak, it was the
documented auto-fail shape.

**The premise turned out to be false, and measuring it is what made the round fixable.**
The handlers are ordinary C. Measured in a container, in this order:

| Step | Result |
|---|---|
| `src/syscall/time.c` compiled for x86_64 with a ~30 line stand-in for the framework header | 0 errors |
| `src/syscall/proc.c` same | 0 errors after adding stand-ins for `libproc.h` and `sys/sysctl.h` |
| `src/syscall/proc.c` assembled for x86_64 | **fails**, one unguarded `mrs %0, cntfrq_el0` at `src/syscall/proc.c:1970` |
| all three of `time.c`, `proc.c`, `syscall.c` cross-compiled for aarch64 and run under `qemu-user-static` | works |
| linking all 24 compilable translation units | fails on duplicate symbols, so the build stays a fixed short list |

So the verifier can run the real handlers. The round replaced every source-text assertion
with a behavioural one on that basis.

## Upload ledger

| # | Date | Zip sha256 | Size | Checks returned | Outcome |
|---|---|---|---|---|---|
| 1 | 2026-08-10 | `fc2ae9dcbc4966257f0ef23a0a329e418af70d2cd35825f88e2e23a605299e33` | 9533746 bytes | not uploaded yet | round 0 applied, local battery green |

Earlier builds this round, superseded and never uploaded: `77f7233d` (before the dash
re-exec guards), `e99b51aa` and `cd135656` (before the child user and system split was
stated in the instruction).

## Handling time ledger

| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 0 | 2026-08-10 | 0 | 0 |

The revision field in the answers file stays 0 until a round actually happens, and it is
copied from the Cumulative column rather than estimated.

## Failure signatures

| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| - | - | none yet | 0 |

## learning/ notes applied

Written before Step 3 per Step 1 item 6, and now carrying the result of each command.

| Note | What it predicted here | How it settled |
|---|---|---|
| stock-bundle-defect-baseline.md | All six scaffold defects present until proven otherwise | Five of six present. The stale-report defect is genuinely NA, the Dockerfile runs no suite at build time |
| solve-sh-idempotency.md | `solve.sh` ends in `git apply -p1 -R`, so run two inverts the tree | **Confirmed.** Replaced with the sanctioned four step shape. Three solve and verify cycles in one container now report "already applied" twice and stay at 1.0 |
| verifier-fail-open.md | Stock grader writes 1.0 without reading `raw_exit_code` | **Confirmed** at the old `test.sh:507`. Gate added inside the success expression, never as an early infra exit. NOP now shows raw exit 1 with `infrastructure_error: None` |
| stale-test-reports.md | Likely NA | **NA confirmed.** No `RUN` in the Dockerfile executes a suite |
| tests-patch-vs-agent-edits.md | `tests.patch` touches `tests/manifest.txt`, which an agent has every reason to edit | **Confirmed and worse than predicted.** `instruction.md:19` ordered the agent to make that exact edit. Restore step added, git independent, plus the instruction line removed |
| static-checks.md | f2p 15, inside the hard range; `tests/` holds only legal names | Still true. f2p is now 16, p2p 8 |
| unreachable-git-blobs.md | `.git/refs/remotes/origin/HEAD` ships broken | **Confirmed**, `git fsck` errored on it as received. Removed. Regenerating `tests.patch` then left 12 dangling blobs of the graded files, caught by the same check and scrubbed |
| empty-git-refs.md | Becomes a defect the moment a pre-zip gc packs the loose ref | **Confirmed.** `.git/refs/heads` was empty after the gc; the loose ref is written back and `bin/rezip.sh` does this too |
| verify-in-the-image.md | A collection abort would mark all ids missing and read as a clean NOP | Handled by construction. The probe builds at the base commit, so the NOP is an executed split, 8 guards passing and 16 fail-to-pass failing |
| non-derivable-private-names.md | The graded names read as though they pin C symbols | **Confirmed.** The new suite reaches the handler through the dispatch table and names no symbol the solution has to create |
| no source-shape grading (Step 5 item 9) | A pytest suite over a C repo that greps `.c` and `.h` grades shape, not behaviour | **Confirmed on all 15 ids.** Replaced |
| cmake-reconfigure-needs-network.md | Probably NA, the repo uses GNU Make | NA confirmed |
| airgapped-means-no-egress-not-no-sockets.md | Any requirement left ungraded because it "needs a real process" is the reasoning the judge returns REMOVE on | Applied as the governing principle. A subprocess is available airgapped, and the new suite forks real children and reaps them |
| dockerignore-context-root.md | Build context is `environment/`, so a repo-level `.dockerignore` would be inert | Checked, none exists, nothing to fix |
| dirty-repo-and-symlinks.md | The tree can arrive dirty with lost mode bits | **Confirmed.** 28 files arrived at 644 that git tracks at 755. Restored |
| local-runs.md | ext4, disposable copies in the session scratchpad | Followed |
| solve-sh-under-sh.md | Bash shebang with bashisms is the normal accepted state, a guard is insurance | Measured instead of assumed. `sh /tests/test.sh` produced **no reward file at all**, so the guard was added to both entrypoints and the case now returns 1.0 |
| script modes (Step 5 item 7) | Both scripts are 644 | **Confirmed.** Both now 755 |
| accepted-bundle-reference.md | Longest paragraph 808 characters, marginal | Rewritten instruction has a longest paragraph of 474 characters |
| source-pr-cross-check.md | Diff golden's file list against PR 162, paged | **Confirmed a real defect.** golden carried PR 161 wholesale as well |
| oracle-bug-vs-pr-scope.md | If the instruction promises kernel conformance and the PR gets a field wrong, that is a case 1 oracle edit | Not needed. The merged PR implements the contract correctly |
| probe-the-instruction-you-already-wrote.md | Only relevant if the task comes back easy | Not reached |
| diagnosing-platform-only-failures.md | Two strikes governs any repeat failure | Counter at zero |
| LEDGER.md | L1 to L3 never build the restore on git, L4 payload cannot live in `tests/files/`, L9 a create-only patch still needs a restore, L13 leave `allow_extra_failures` alone unless it is already there | All four applied. The restore is a base64 payload inside `test.sh`, and `allow_extra_failures` was already present so it was flipped to false |

## Round 0, 2026-08-10

### Verdict

**Fixable.** Not Fixable was considered seriously and rejected on evidence.
`docs/guidelines.md:66` makes Not Fixable exactly two categories, PR scope needing reduction
and environment issues ECs may not fix. PR 162's scope is untouched and the image builds
clean, so neither applies. `docs/` is silent on repositories that target a platform the
verifier is not, so calling that Not Fixable would have been an inference rather than a
rule, and the compile measurements above showed it was not even true.

### The 13 findings

1. All 15 fail-to-pass ids are regular expressions over C and header source text. Measured:
   a 37 line no-op that writes the right words passes all 15, and so does a tree with
   `this is not valid C at all ;;; ###` appended, so the suite never required the submission
   to compile.
2. `instruction.md:19` ordered the agent to add `test-times` to `tests/manifest.txt`, which
   is the exact edit `tests.patch` makes. Reproduced on disposable copies with the edit
   unstaged, staged and committed. All three apply routes in `test.sh` failed and the
   verifier wrote `infrastructure_error`, so a compliant agent was guaranteed an invalid
   trial. `instruction.md:23` also said not to modify the test files, contradicting line 19.
3. The grader was the stock fail-open one. `raw_exit_code` was recorded and never read.
4. `pass_to_pass` was empty with `allow_extra_failures` true, so nothing outside the 15
   regex tests could affect the reward.
5. `solve.sh` reverse-applied its own patch as the last branch, the exact shape that inverts
   the tree on the second oracle run.
6. `tests/test.sh` and `solution/solve.sh` both shipped at mode 644.
7. The shipped tree was dirty. 28 files that git tracks at 755 arrived at 644, 24 of them
   under `tests/` and 4 under `.ci/`.
8. `.git/refs/remotes/origin/HEAD` was a broken ref and `git fsck` errored on the bundle as
   received.
9. `solution/golden.patch` was PR 162 plus the whole of PR 161 welded together. 16 hunks are
   PR 162, 11 hunks and 4 extra files are PR 161, "Wake internal condvar parks on exit_group
   teardown". None of it is described by the instruction or touched by any test.
10. The instruction was a construction plan rather than a ticket. It named nine internal
    file paths, the generator script, the exact function signatures and the boolean guard
    expression, and 16 of its phrases were reproduced near verbatim inside the graded
    assertions.
11. `tests/test-times.c`, the one behavioural test in the bundle, is shipped into the repo
    and never compiled or run by the verifier.
12. `task.toml` had `repo_license = ""`, no `[environment] os`, no `difficulty_explanation`,
    and a verifier timeout of 300 seconds sitting under an inner execution timeout of 1800.
13. Two graded tests could not fail for their stated reason. `test_null_buffer_accepted`
    passed for a solution that rejects a null buffer, and the second half of
    `test_tick_rate_is_100hz` asserted a property that is already true at the base commit.

### What was built

The graded suite is now behavioural. `tests/sentinel-hostcheck/` carries a stand-in for the
framework header plus two Darwin headers, a link stub file, and one probe that includes the
dispatcher source so the static dispatch table is reachable. `hostbuild.py` cross-compiles
the time, process and dispatch translation units for aarch64-linux, links them, and runs the
probe under `qemu-user-static`. Any symbol left undefined is looked up across `src/` and its
file pulled into the build, so a handler placed in a new file still links; whatever is left
gets an inert placeholder. Nothing in the assertions reads source text.

f2p 15 to **16**, p2p 0 to **8**, `allow_extra_failures` true to **false**, 24 graded ids.
The 8 guards are pre-existing behaviour that passes at the base commit, which is what makes
the NOP an executed split rather than a compile-bound zero.

### Battery, against a fresh extract of `fc2ae9dc`

| Run | Result |
|---|---|
| NOP | reward 0, raw exit 1, `infrastructure_error: None`, **8 of 24 passing**, all 16 fail-to-pass missing |
| Oracle | **3/3** at 1.0, 24/24, 0 unexpected, raw exit 0, three solve and verify cycles in one container |
| Hostile delete, in the verifier | 3 of 3 drop to 0.0, each naming its test |
| Hostile delete, against the suite | 12 of 12 caught, each naming its test |
| Agent cases | 6 of 6 at 1.0: manifest edited, graded file created, `test-times.c` created, edits committed, `.git` deleted entirely, both entrypoints under `sh` |

Verifier runtime about 15 seconds against a 1200 second timeout.

The twelve suite-level probes and the test that caught each: routing removed and extra-regs
flag flipped (the two routing tests), tick rate changed to 1000 (rate and self accounting),
monotonic swapped for realtime (reference point), child time taken from the host children
aggregate (helper subprocess and peek), null guard removed (null buffer), EFAULT replaced by
0 (unwritable buffer), terminal-report gate removed (stop report), peek guard removed
(peek), crediting removed entirely (three child tests), ticks reported as microseconds (self
accounting), and child fields filled from self time (five child tests).

### Deliberately not changed, and why

- `model_difficulty = "medium"` against `difficulty = "hard"`. Section 8 says report the
  clash rather than quietly reconcile it, and hand-editing difficulty metadata is
  specifically warned against.
- The `|| true` on the Dockerfile's `patch` install at line 24. It is fail-open, but nothing
  downstream depends on it and hygiene alone is not on the allowed-fix table.
- `tests/test-times.c` and the `tests/manifest.txt` line stay in `tests.patch`. They are PR
  162 content and belong there, even though the verifier cannot build a guest binary.
- The `pass_at_k` fields, left as the platform supplied them.

### Next

Enter the Phase 1 answers, upload `fc2ae9dc`, then work the eval loop.

## Closed 2026-08-11, ACCEPTED

The submitter reported the outcome as **accepted**. Round 0 as built here was the submission.

**What was supplied and what was not.** The word accepted is the whole of it. No Submission
Quality Score, no reviewer note, no per-check results and no upload-round count were given, so
three things stay unknown and are recorded as unknown rather than filled in: how many upload
rounds the zip actually took, what the Static, Difficulty, Oracle and Quality panels returned,
and whether the review gate blocked at any point. The `upload_rounds` and `t_revisions` columns
in `calibration.tsv` carry that gap explicitly. **Do not read this row's numbers as a measured
round history.** Everything else in that row was measured here, off the bundle itself.

**What the acceptance validates, and what it does not.** Following
`accepted-bundle-reference.md`, the two lists are kept apart.

Validated, because it was the shipped state and a reviewer signed it off:

- A graded suite that compiles part of a macOS-only program for aarch64 and runs it under
  qemu-user on the Linux verifier, in place of source-text assertions
- Adding a cross toolchain and a user-mode emulator to the verifier dependency layer of the
  Dockerfile, on the "adding a missing dev package" reading of `docs/guidelines.md:332`
- An instruction naming zero internal paths, zero internal functions and zero host API calls,
  which was only possible because the tests stopped requiring any of them
- Cutting `golden.patch` back to the source PR's own eight non-test files after finding a
  second PR welded into it
- f2p 16, p2p 8, `allow_extra_failures` false, 24 graded ids

NOT validated, because nobody had to open the bundle to check it:

- The two-pass link with auto-generated inert placeholders. It worked on every local run and no
  platform result speaks to it
- The `sh` re-exec guards, the restore payload and the exit-code gate. All three were measured
  here and none of them was exercised by anything the reviewer reported
- The handling-time split, which was proposed inside the band the submitter gave rather than
  measured

## Open caveats

| Caveat | Retire when |
|---|---|
| The whole round rests on the claim that the graded probe builds at the base commit and therefore that the NOP zero is behavioural. Measured here as 8 of 24 passing at base, never on the platform | A platform NOP or difficulty artifact shows the same 8 of 24 split |
| `upload_rounds` is unknown, so this task contributes nothing to the round-count calibration | The submitter supplies the round history |
| The probe's build driver reads `src/*.c` to locate a symbol's defining file. Disclosed in Comments for Reviewer, never challenged, which is not the same as approved | A judge or reviewer comments on it either way |
