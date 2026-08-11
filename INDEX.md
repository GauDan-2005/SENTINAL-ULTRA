# Sentinel Ultra submissions

One row per task. Full detail lives in each task's own `task.md`.

## Row format

Three separate cells carry what used to be one sentence, so the register can be read by eye
and counted by a script.

**Status** holds one token and nothing else. No parentheses, no dates, no bold. The vocabulary
is fixed:

| Status | Means |
|---|---|
| `claimed` | The zip is downloaded and the folder exists. Nothing read yet |
| `analysing` | Steps 2 to 4 are running. No verdict yet |
| `fixing` | Verdict is Fixable and edits are in progress in `work/` |
| `checks-green` | Local oracle and NOP both pass and the zip is built. Not uploaded yet |
| `uploaded` | The zip is on the platform and the checks are running |
| `pending-revision` | A check or a reviewer sent it back. Counts against the throughput rule |
| `sent-to-reviewer` | Send to reviewer is checked and the task is with the peer EC |
| `accepted` | The reviewer accepted it. Task is closed |
| `rejected` | The reviewer rejected it. Task is closed |

**Round** is the revision-round number as an integer. `0` means the task has not been sent
back yet. It matches the `Revision round N` headings in the task's own `task.md`.

**Note** is free text and carries everything else. It never carries the status or the round.

Throughput rule: at most **two** tasks sitting in `pending-revision` at once, or the
platform blocks a new claim. Count it with

```
grep -c '^| \[.*| pending-revision |' INDEX.md
```

which only works because the Status cell holds nothing but the token. The leading `^| \[`
anchors on a real row, so this line of documentation does not count itself.

## Active

**pending-revision: 7 of 2, 2026-08-11.** statrs 315 closed as **accepted** today and the count did **not** move either, for the same reason libcrux did not: it was sitting at `checks-green`, not `pending-revision`, so it was never counting against the cap. That is now twice, so it is a pattern rather than a coincidence: **the tasks that reach a verdict tend to be the ones that already left `pending-revision`, so closing them frees nothing.** The count is only moved by a task going from `pending-revision` straight to a close, or by the register being reconciled against `stb submissions list`, which has still never been run and remains the blocking action.

Superseded count line, kept for the audit trail: **pending-revision: 7 of 2, 2026-08-11.** libcrux 1165 closed as accepted today and the count did **not** move, because it had already left `pending-revision` for `sent-to-reviewer` on 2026-08-05. Closing a task only frees a slot when it was counting against the cap, which is worth knowing before anyone closes a task expecting the number to drop. `stb submissions list` has still never been run and remains the blocking action.

**pending-revision: 6 of 2, 2026-08-10. NINTH instance, same day as the eighth, and the count has
still not moved.** elfuse 162 was claimed and its zip handed over while this line already read
`6 of 2`, and `stb submissions list` has still never been run. Same reading as the eight instances
below: the claim was made before the session began, so the folder was arranged and the drift is
reported rather than silently fixed. The new row goes in as `claimed`, which does not count against
the cap. **Two claims in one day against a register that is six over its cap is the point at which
the cap stops being informative at all.** The six are unchanged: ziti-sdk-c 668 (round 4),
redisshake 1005 (round 3), hulak 118 (round 3), xlwings 2719 (round 1), jqno 1166 (round 5) and
AltBeacon 1177 (round 7). Three of those six carry an applied, rebuilt, **not yet uploaded** zip,
and openwhispr 1002 now carries a fourth, so uploading them is the action that would move the
number. `stb submissions list` remains the blocking action, and it is now cheaper to run it than to
write the next one of these paragraphs.

**pending-revision: 6 of 2, 2026-08-10. Eighth instance, and the count has not moved since
2026-08-09.** openwhispr 1002 was claimed and its zip handed over while this line already read
`6 of 2`, and `stb submissions list` has still never been run. Same reading as the seven instances
below: the claim was made before the session began, so the folder was arranged and the drift is
reported rather than silently fixed. The new row goes in as `claimed`, which does not count against
the cap. **Eight consecutive instances is not a lagging register, it is an unreconciled one**, and
the single command that would settle whether the real figure is 6 or 2 has now been deferred eight
times. `stb submissions list` is the blocking action before any further claim, and it should be run
before openwhispr 1002 is worked rather than after. The six are ziti-sdk-c 668 (round 4),
redisshake 1005 (round 3), hulak 118 (round 3), xlwings 2719 (round 1), jqno 1166 (round 5) and
AltBeacon 1177 (round 7). Three of those six carry an applied, rebuilt, **not yet uploaded** zip,
so uploading them is what would actually move the number.

**pending-revision: 6 of 2, 2026-08-09. Seventh instance.** ziti-sdk-c 668 was uploaded, the review
gate blocked it at the agentic judge, and it re-entered on its own. **Not a claiming violation**, same
reading as every instance below: the cap blocks starting a NEW claim, and a task the platform sends
back re-enters whatever the count says. Round 1 is applied and the zip is rebuilt, so it is ready to
go straight back up. No new task may be claimed until four of the six clear, and `stb submissions list`
has still never been run, which is now the seventh time that has been recorded rather than done.

**pending-revision: 5 of 2, 2026-08-09. Sixth instance, and the count did not move.** ziti-sdk-c 668
was claimed and its zip downloaded while this line already read `5 of 2`, and `stb submissions list`
has still never been run. Same reading as the five instances below: the claim was made before the
session began, so the folder was arranged and the drift is reported rather than silently fixed. The
new row goes in as `claimed`, which does not count against the cap. **The register is not lagging
occasionally at this point, it is not being reconciled at all**, and the one command that would settle
it has now been deferred six times. `stb submissions list` is the blocking action before any further
claim, and it should be run before ziti-sdk-c 668 is worked rather than after.

**pending-revision: 5 of 2, 2026-08-08.** Counted with the documented command. hulak 118 re-entered
on its own when the peer reviewer sent it back, joining redisshake 1005, xlwings 2719, jqno 1166 and
AltBeacon 1177. Not a claiming violation, same reading as every instance below: the cap blocks
starting a NEW claim, and a task a reviewer sends back re-enters regardless. No new task may be
claimed until three of the five clear, and `stb submissions list` has still never been run.

**pending-revision: 4 of 2, 2026-08-07 19:30.** Counted with the documented command, not by eye.
redisshake 1005 re-entered on its own when the platform blocked it at the difficulty screen, and
xlwings 2719 moved to pending-revision as well. **Neither is a claiming violation**: the cap blocks
starting a NEW claim, and a task the platform sends back re-enters whatever the count says. It does
mean no new task may be claimed until two of the four clear. The four are redisshake 1005 (round 1),
xlwings 2719 (round 1), jqno 1166 (round 5) and AltBeacon 1177 (round 7). `stb submissions list` has
still never been run, and two of those four have been unconfirmed for a week, so the real number may
be lower. **Run it before claiming anything.**

pending-revision: 3 of 2 - OVER THE CAP as of 2026-08-07, when xlwings 2719 was submitted and bounced. Needs resolving with the submitter before any new claim
landed and it moved back to `checks-green`. It briefly read 3 of 2 while the round was being
worked, which was correct bookkeeping and not a claiming violation: the cap blocks starting a
NEW claim, and a task the platform sends back re-enters `pending-revision` on its own. The two
are jqno 1166 and AltBeacon 1177, both still unconfirmed against `stb submissions list`, so one
of them may already have moved the way libcrux had. Run it before assuming the number.

**Fifth instance, 2026-08-07.** redisshake 1005 was claimed and its zip downloaded while this
line still read `2 of 2`, and `stb submissions list` has still not been run. Fifth time in a
row, and the reading has not changed: the claim was already made before the session began, so
the folder was arranged and the drift is reported rather than silently fixed. The new row goes
in as `claimed`, which does not move the pending-revision count. At five consecutive instances
the register is not lagging occasionally, it is simply not being reconciled, and the one command
that would settle it has been deferred every time. **Run `stb submissions list` before claiming
anything after redisshake 1005**, and correct the count line here in the same action.

**Fourth instance, 2026-08-06.** hulak 118 was claimed and its zip downloaded while this line
still read `2 of 2`, and `stb submissions list` had still not been run, which is the exact thing
the third-instance note below said to do first. Same shape, same reading: the claim was already
made before the session began, so the folder was arranged and the drift is reported rather than
silently fixed. The new row goes in as `claimed`, which does not move the pending-revision count.
**Run `stb submissions list` before claiming anything after hulak 118**, and if it shows jqno 1166
or AltBeacon 1177 has moved, correct the count line here in the same action.

**Third instance of the register lagging the platform, 2026-08-06.** firefly 1123 was claimed
and its zip downloaded while this line read `2 of 2`, which under CLAUDE.md Step 1 item 5 is a
blocked claim. The platform did not block it. That is the same shape as the two instances
recorded below, and the reading stays the same: the cap is real and this file is the stale
side. The claim was already made before the session began, so the folder was arranged rather
than refused, and the drift is reported here instead of being silently fixed.
`stb submissions list` has still not been run and remains the only thing that would confirm
whether jqno 1166 and AltBeacon 1177 are genuinely still in `pending-revision`. **Run it before
claiming anything after firefly 1123.**

Previous count line, kept for the audit trail: pending-revision 2 of 2, counted 2026-08-05 with
`grep -c '^| \[.*| pending-revision |' INDEX.md`. libcrux 1165 went to sent-to-reviewer as
Invalid / Not Fixable on 2026-08-05, which cleared the third slot. A new claim is still blocked
until one of the remaining two clears. Update this line in the same action that changes any
row's Status.

**Contradiction resolved, 2026-08-05.** It read as unresolved twice: xlwings 2719 was claimed
while the count said 3 of 2, and then statrs 315 was claimed under the same count, so on both
occasions the platform did not block a claim the register said was blocked. The register was
the stale side, not the cap. libcrux 1165 had already stopped being `pending-revision`, and
recording that moved it to `sent-to-reviewer` and brought the count back to 2. **The reading to
carry forward is that the cap is real and this file lagged it**, which is the opposite of the
conclusion the second instance was drifting towards. `stb submissions list` still has not been
run, so the two remaining `pending-revision` rows are unconfirmed and could lag the same way.

| Task | Submission id | Repo / PR | Verdict | Status | Round | Claimed | Note |
|---|---|---|---|---|---|---|---|
| [20260809_080653__sysprog21_elfuse__162](tasks/20260809_080653__sysprog21_elfuse__162/task.md) | 4ef5f832 | sysprog21/elfuse 162 | Fixable | checks-green | 0 | 2026-08-10 | Round 0 APPLIED 2026-08-10, zip `fc2ae9dc`, **not uploaded**. 13 findings, 9 bundle files changed. **The headline defect is that all 15 fail-to-pass ids were regular expressions over C and header source text**, which `docs/guidelines.md:135` bans by name and `docs/tasking-guide.md:324` puts on the judge's own Don't list. Measured: a 37 line no-op passes all 15, and so does a tree with `this is not valid C at all ;;; ###` appended, so the suite never required the submission to compile. The bundle's own docstring justified it, and the justification is false. elfuse is a macOS Hypervisor.framework program, but the handlers are ordinary C: `time.c` and `proc.c` compile on Linux behind a 30 line stand-in for the framework header, `proc.c` will not assemble for x86_64 because of one unguarded `mrs x0, cntfrq_el0` at `proc.c:2031`, and all three of `time.c`, `proc.c` and `syscall.c` cross-compile for aarch64 and run under `qemu-user-static`. So the graded suite was rebuilt to compile the real dispatch, time and process units, reach the handler **through the static dispatch table** rather than by name, and drive it with real forked children. **Second guaranteed killer**: `instruction.md:19` ordered the agent to make the exact `tests/manifest.txt` edit `tests.patch` makes, reproduced unstaged, staged and committed, and all three apply routes failed into `infrastructure_error`, so a compliant agent was guaranteed an invalid trial; the line is gone and a git-independent base64 restore is in `test.sh`. **Third**: `golden.patch` was PR 162 plus the whole of PR 161 welded together, 11 hunks and 4 extra files of exit_group teardown work that the instruction never states and no test touches, now cut back to PR 162's 8 non-test files exactly. Also fixed: the stock fail-open grader, `pass_to_pass` empty with `allow_extra_failures` true, a reverse-applying `solve.sh`, both scripts at 0644, a dirty shipped tree with 28 lost exec bits, a broken `refs/remotes/origin/HEAD` that `git fsck` errored on, and a `task.toml` missing `os`, `repo_license` and `difficulty_explanation` with a verifier timeout under its own inner execution timeout. f2p 15 to **16**, p2p 0 to **8**, `allow_extra_failures` true to **false**, 24 graded. Battery on `fc2ae9dc`: NOP 0.0 raw exit 1 with **8 of 24 passing at base** (an executed split, not a symbol audit), oracle **3/3** at 1.0 24/24 across three applies in one container, **3 of 3 in-verifier hostile probes plus 12 of 12 suite-level probes** each naming its test, and 6 of 6 agent cases at 1.0 including a committing agent, `.git` deleted entirely and both entrypoints under `sh`. Deliberately left and disclosed: the `model_difficulty` clash, the Dockerfile `|| true` patch install, and `tests/test-times.c` shipping as PR content the verifier cannot build. Original arrangement note follows. Arranged 2026-08-10, nothing analysed. Zip `4be890cb`, 14969066 bytes, 359 entries, 0 symlinks, and **already flat**, so `download/original/` is a straight extract with no wrapper to unwind. C plus Shell, GNU Make with an `mk/` include tree, graded through **pytest** on `ubuntu:24.04`. HEAD equals the `base_commit_sha` in `task.toml`, no remote, no reflog, `.git` is 5.0 MB holding exactly the whitelist entries. f2p **15**, inside the hard 10 to 20 range, and `tests/` holds only legal filenames. **Four signals from the arrangement pass, recorded as signals rather than findings because Step 3 has not run**: `solve.sh` ends in `git apply -p1 -R` as its fallback, the exact reverse-apply shape from `solve-sh-idempotency.md`; both `tests/test.sh` and `solution/solve.sh` are mode **644**; `pass_to_pass` is empty with `allow_extra_failures` true against a repo that ships a whole `tests/` tree of C programs and shell drivers; and the graded ids are pytest tests named `test_sys_times_declared_in_time_header` and `test_syscall_c_forwards_sc_times_to_sys_times`, which is what source-text assertions get called, so the no-source-shape-grading gate is the first thing Step 3 checks. Also visible: `.git/refs/remotes/origin/HEAD` ships in the zip, `repo_license` is blank, and `model_difficulty = "medium"` clashes with `difficulty = "hard"`. The `learning/` notes table is written into `task.md` |
| [20260719_045042__openwhispr_openwhispr__1002](tasks/20260719_045042__openwhispr_openwhispr__1002/task.md) | 451dd036 | openwhispr/openwhispr 1002 | Fixable | pending-revision | 2 | 2026-08-10 | Round 2 APPLIED 2026-08-11, zip `5a786267`, **not uploaded**. Blocked at the agentic judge twice, both `DISCUSS coverage_gap`. **Strike 2, and the rule was applied rather than noted.** Round 1's fix for the settings-store finding was to narrow the instruction while still mentioning the store; LEDGER **L39** names exactly that middle path as refuted, so round 2 stands the dependency up instead. The store is renderer TypeScript and node needs two things the bundler supplies, the extension it will not guess and the json import attribute; a `registerHooks` resolver giving both loads the real module in ~150 ms unmodified. Two new tests then grade it end to end, and **every provider's store setter is measured routing to that provider's `save` accessor** through the store's own savers map. Three controls confirm the judge's scenario is caught: OpenRouter omitted from the store, its setter pointed elsewhere, its store key renamed, all reward 0. **Delta read before changing class, per L42**: coverage 3.5 to 4.0 with the round-1 derivation complaint gone, so the class was right and under-powered rather than missing. Also dropped the arbitrary provider **ordering** requirement, the one over-specification item no test needed. Other axes moved well: oracle spec faithfulness 3.0 to **5.0**, no-gaming and reproducibility 5.0. f2p 16 to **18**, graded **229**. Battery on `5a786267`: NOP 0.0 raw exit 1 with 0 of 18 f2p and **211 of 211** guards executing at base, oracle **3/3** at 1.0 229/229 with 0 unexpected, **17 of 17** hostile probes each naming its test, **9 of 9** agent and environment cases at 1.0, 2.58 s against a 900 s timeout, zero drift across 700 entries. Difficulty metadata left as it arrived at the submitter's instruction. **Incident:** an unguarded `cd` before `git reset --hard`/`clean -fdx` reverted the workspace and emptied `work/`; recovered in full from the zip and from unreachable git objects except the untracked root `revision.md`, and the first round-2 zip was discarded because the reverted `bin/rezip.sh` omitted the loose-ref write-back |
| [20260808_213817__openziti_ziti-sdk-c__668](tasks/20260808_213817__openziti_ziti-sdk-c__668/task.md) | 6a0fee66 | openziti/ziti-sdk-c 668 | Fixable | pending-revision | 6 | 2026-08-11 | **Round 6 APPLIED 2026-08-11, zip `29f00bd9`, not uploaded.** Screen returned `FAIL EASY` a third time at 7/8. **The r5 reading was wrong**: three screens read 7, 6, 7, so the 6 was noise at n=4 (LEDGER L43). **The decisive number is the unit table**: 7 runs, all 26 passing, so every agent that BUILT it scored 26/26 and the 8th run never reached a test. Reproduced that 8th run: `add_custom_target(ziti-cli ALL)` makes plain `cmake --build build` hit `go install` on a blocked network. **Fixed** by vendoring the CLI at image build + `ENV GOPROXY=off`, measured exit 0 offline; this makes the headline WORSE and is still right. **Ran the control r4/r5 skipped**: 4 independent implementations from instruction.md alone, all **26/26**, four different designs, divergence only where the instruction is silent. **First measured lever**: version must follow the endpoint in use, adapted from openziti `36fa75fb9` (3 of 4 impls volunteered the gap unprompted). Lazy clear at all 3 move sites, not upstream's eager re-request, which risks the PR-711 hang. Oracle 26/26, **all four impls drop to 25/26** on that id alone. Two false leads killed by measurement: the `26096590a` reorder clears the version before the response stores it, and the close-in-callback abort is **my own** `assert(active_reqs > 0)`. f2p stays 20 by folding `failover_stays_in_endpoint_set` into `failover_switches_endpoint`. Battery on `29f00bd9`: NOP 0.0 raw exit 1, oracle **3/3** at 1.0 across three applies in one container, hostile delete 0.0 caught by `sentinel_ctrl_version_follows_the_endpoint_in_use`. Answers updated and re-humanized, revisions 430. Rounds 0 to 5 in `task.md` |
<!-- r5 -->| Fixable | superseded | 5 | 2026-08-09 | Round 5, zip `1c2a3fb7`, uploaded, screen 7/8. **The screen MOVED**: r3 7/8, r4 **6/8** with opus dropping 4/4 to 3/4. MEDIUM needs at most 4/8. Section 4 says a number that does not move means the fix missed the cause; this one moved, so the answer is a bigger lever of the same class, not a different class. Strike 2 on `FAIL EASY`. **Shipped openziti 678 + 794**, the lever the round-4 survey identified and recommended. 678 is a **case 1 correction**: golden pointed `ctrl->url` at a key the endpoint map owns and the pre-existing `ziti_ctrl.c:219` frees it, verified against `model_collections.c:122-128`. **A double free the bundle has carried since round 1**, unreachable from the graded tests. The controller now owns its url at all four sites that move it and releases it on close. 794 is the **expansion**: a redirect moves the endpoint inside the set instead of repointing url, so the set keeps its size and url stays a member. Declared under PR additions, file list unchanged. **Why it should discriminate where clause grading only nudged**: two probes take the WHOLE binary down rather than failing one id, `url_borrows_the_map_key` at 15 tests and `keeps_dropped_endpoint_after_refresh` at **26**, the entire graded set, because the process aborts. No partial credit, and four existing ids already REQUIRE the address stays valid after every failed request. **20 of 20 probes**, two new, three anchors refreshed where the rework moved the code. **One probe was wrong rather than coverage being thin**: after the rework the client is initialised FROM `ctrl->url`, so pointing url elsewhere no longer breaks the invariant. Retargeted at the `tlsuv_http_init` argument and re-verified 5 of 5. `sentinel_ctrl_init_single_endpoint` folded into the populate case to stay at the 20 ceiling, no assertion lost, `sentinel_ctrl_redirect_rekeys_endpoint_set` took the slot. Battery on `1c2a3fb7`: NOP 0.0 raw exit 1, oracle 3/3 at 26/26 plus 6 back-to-back 1.0, agent-collision 1.0. **Artifact still not supplied** for the second round running; the unit table shows 7 runs against 8 agent runs, so one failure never reached the tests and L36 says the headline cannot tell those apart. **No agent control run**, so MEDIUM is still unmeasured. Packaging 1.0 on the tracked PEM key, escalated since round 2. Rounds 0 to 4 in `task.md` |
| [20260807_080545__tair-opensource_redisshake__1005](tasks/20260807_080545__tair-opensource_redisshake__1005/task.md) | e115d5ec | tair-opensource/redisshake 1005 | Fixable | pending-revision | 3 | 2026-08-07 | Round 3 APPLIED 2026-08-08, zip `45977e21`, **to be uploaded**. Blocked at the difficulty screen three times; the agentic judge has passed every round (`verdict: ok`, test_faithfulness 5.0, oracle axes 5.0, packaging 5.0, **test_coverage 3.5** which is the only real margin). **The difficulty artifact arrived this round and corrected round 1 from 7/8 to 8/8**: the one gpt-5.5 'failure' scored 0 of 30, missing even pre-existing guards, on `internal/rdb/rdb.go:55:13: undefined: bytes`. The agent broke the build and the round-0 exit-code gate caught it. So it was never a difficulty signal. `Some tests not passed by any agent run` came from an empty `tests_results: {}` and meant nothing. **Three levers, three measured zeroes, none shipped on a guess**: r1 added scope (PR 1038) = 0 on merit; r2 withheld the two pre-solved answers = 0 of 4 (all four found the all-ones marker and wrote order-independent parsers unaided); r3 adapted PR 1048, a real upstream defect where the AOF reader truncates length-prefixed binary arguments with a line-based read = 0 of 4 (all four read by declared length and consumed the terminator). PR 1043 was **rejected on evidence** (its hunk sits on PR 1018's RESTORE machinery, importing that would change the PR's feature). LEDGER L29 to L32. Structural finding: every requirement this task can carry has, once stated, exactly one implementation a competent engineer writes, and the instruction must state them. Not Fixable is NOT being claimed - LEDGER L19 refuted 'third easy screen = Not Fixable', and the control runs on a newer model than the screen so 4 of 4 is a ceiling not a forecast. Round 3 is worth shipping regardless: the append-only command stream is now graded where it was not (the axis the judge scored lowest), two padding ids were merged into siblings with every assertion surviving, and `golden.patch` carries a second documented upstream defect fix. **The scan-path coverage gap is also closed**, which was the judge's only mark-down (`test_coverage` 3.5, *"a solution that adds the parser but never wires the scan path could pass"*). It was gradeable after all: airgapped means no egress, not no sockets, so the test stands a fake server on 127.0.0.1 inside the test process and hands the reader a Valkey-layout DUMP. Wiring `restore()` to a fixed `false` now fails on one named test (probe e17), and the Redis-server case passes at base so it guards the reverse mistake. f2p 19, p2p 13, 32 graded ids, golden 23 files. Battery on the uploaded zip: NOP 0.0 raw exit 1 at 13 of 32 with 43487 bytes executed, oracle 3/3 at 1.0 32/32 fresh and stable across three applies, **12 of 12 hostile probes** each naming its test, agent-hostile 1.0, directory-at-graded-path 1.0, dash 1.0. Earlier rounds in `task.md`: the non-derivable `SetIsValkey`/4-arg `ParseObject` that made 8 of 10 ids unreachable, Valkey's `-1` marker mis-decoded by the source PR, the fail-open grader, the git-independent restore |
| [20260805_220102__xaaha_hulak__118](tasks/20260805_220102__xaaha_hulak__118/task.md) | 24d6d443 | xaaha/hulak 118 | Fixable | pending-revision | 3 | 2026-08-06 | Round 3 APPLIED 2026-08-09, zip `675f27cd`, not uploaded. Agentic judge **DISCUSS, overreach**; the difficulty screen did not run because the judge gates it. **The blocking item was mine and it was a repeat**: a graded test called `itemZoneID`, an unexported helper the instruction never names, which is the round 0 defect returning after round 2 reintroduced it while adding a list-row check. Fixed by locating the row by its drawn text like every other test. **The audit now runs over every identifier in both graded files**, not just the one a report names: 8 absent at base, all 8 named in the instruction, none unnamed. **Two strikes on this signature.** **A second case found by auditing rather than reported**: the barrier waits for an earlier region to disappear, which silently required that a fresh scan replaces the last one's regions, a rule the instruction never stated, so a spec-correct implementation keeping regions would have failed most of the suite. Measured, then stated and asserted. **The module pin is gone**, closing two report items at once, since both readers named it first for over-specification and nothing in the suite enforced it. Marker encoding is now the implementer's choice; the oracle still uses the warmed module, which the instruction neither requires nor forbids. A clause sweep per the new `probe-the-instruction-you-already-wrote.md` found one ungraded rule, the picker marking **every** visible row, closed inside an existing test so f2p stays 19. Pass rates restored to the last full run (4/4, 2/4) after the report called the cheap-screen figures invalid evidence. Battery green: NOP 0.0 raw exit 1, oracle 3/3 at 1.0 350/350 and stable across three applies, 10 hostile probes each naming its test, exit gate separating, agent-hostile 1.0, `.git` four-state matrix all 1.0, round trip clean under both extractors. Rounds 0 to 2 in task.md |
| [20260805_080500__hyperledger-firefly_firefly__1123](tasks/20260805_080500__hyperledger-firefly_firefly__1123/task.md) | 446c3ef2 | hyperledger-firefly/firefly 1123 | Fixable | checks-green | 3 | 2026-08-06 | Round 3 APPLIED 2026-08-08, zip `19abaf28`, not uploaded. **All evaluation checks PASSED on the round-2 zip**, then peer review returned Needs Revision with 2 findings, both correct. **(1) A stated clause nothing graded** - the field table says the format and methods are never accepted as caller input, golden does it with `ffexcludeinput`, nothing asserted it, and an implementation exposing both as writable input scored 1.0. Exactly the shape `probe-the-instruction-you-already-wrote.md` predicts. Of the reviewer's three options, two are wrong here and the reasoning is recorded: asserting the fields arrive unset **would fail the oracle** (the tag is read only by `SwaggerGen`, nothing strips at runtime - measured), and adding `internal/reference` is **non-derivable** (byte-exact generated markdown carrying patch-authored descriptions). Took the third path: a test that drives the real schema generator over the real pool-create routes and asserts interface IS accepted, format and methods are NOT, and all three still come back. Routes found by input type; every name it touches exists at base; golden touches `internal/apiserver` 0 times; `ffexcludeinput` appears 0 times in instruction and tests, so it grades the effect not the tag. Verified f2p by RUNNING at base. **(2) An assertion nothing stated** - the migration down-path loop was overreach; took the reviewer's first option and stated reversibility, since the PR ships down migrations for both databases and the repo pairs 99. **bin/rezip.sh refused to build** and caught a stray `.gradle` cache that appeared under the checkout between sessions - untracked, not in the pristine extract, and **never in any uploaded zip** (verified against the one reviewed). Removed. This is the round the hand-rolled zip cost something. f2p 18 to 19, p2p 39, `internal/apiserver` graded via a third command selecting only the sentinel test (a pre-existing test there is red at base). Restore widened to 7 packages / 187 files. Battery green: NOP 0.0, oracle 3/3 at 1.0 58/58, sh run, git-damage matrix all 1.0 (no round-2 regression), REV1 and REV2 probes each 0.0 naming their test, AC1/AC2/AC5/AC6 all 1.0. Send: Yes once the panels come back green on this zip. Earlier rounds in `task.md` |
| [20260805_080500__statrs-dev_statrs__315](_archive/20260805_080500__statrs-dev_statrs__315/task.md) | 8b7cc519 | statrs-dev/statrs 315 | Fixable | accepted | 4 | 2026-08-05 | ACCEPTED 2026-08-11 on round 4, zip `fe241712`. The second bundle this workspace has had accepted. Five uploads, 195 minutes total plus 255 of revisions. Arc: round 0 four stock defects, round 1 agentic judge DISCUSS on coverage, round 2 a peer reviewer who found a genuinely inverted Mann-Whitney tail in the oracle that is still on statrs master today, rounds 3 and 4 the difficulty screen twice. **No round-4 screen result was ever seen, so it is NOT established that the round-4 levers cleared it.** What is measured: the round-3 scope expansion converted zero of eight agents, and the only assertion that ever failed one was the zero-skew case. Difficulty screen returned FAIL EASY a SECOND time, 7/8, so this is strike 2 on that signature. Verified the report was fresh from the results artifact rather than assuming, since the numbers were byte-identical: the artifact lists both new anderson_darling ids among 127 required, so round 3 converted ZERO agents. Read the one failing trajectory: codex wrote the textbook D'Agostino transform with no zero-skew guard and failed on `assertion failed: z_sym != 0.0`, i.e. it wrote the CORRECT version and failed on the oracle quirk. Theory replaced rather than repeated: difficulty here scales with how many documented behaviours contradict the natural implementation, not with how much there is to implement. Swept the oracle for such divergences and graded three (one constant group poisons f_oneway even when others vary; a size-1 group is fine beside a bigger one; Exact carries no size limit). Each measured by writing the natural implementation and watching it fail. f2p still 18, assertions 111 to 132. Found and deliberately did NOT fix a zero-variance panic in ttest_onesample. PR 329 (KS test, 1095 lines) is the next untried lever, NOT a Not Fixable verdict. Round 3 detail follows. Round 3 came from the DIFFICULTY SCREEN: judge passed, screen returned FAIL EASY (opus 4/4, codex 3/4). Diagnosed with a measured before and after: zip 2 passed the screen, zip 4 fails it, and the delta is the round-2 Mann-Whitney correction. Round 1 had been asserting thresholds tuned to the buggy oracle, so a correct implementation failed and that was doing the discriminating; fixing it was right and removed it. Contributing cause: three rounds of clarity findings turned the instruction into a near-complete spec. Fixed by expanding PR scope with an Anderson-Darling test adapted (not lifted) from statrs PR 346, same module and family, joined to PR 315 conventions with a NaNPolicy and a two-variant error enum. Lever MEASURED first against four wrong implementations (11.86 / 22.76 / 2.12 / 0.17 against a correct 0.16); PR 336 rejected on evidence as a pure perf refactor with zero observable change. f2p 19 to 18 by merging three padded pairs. Self-caught that the new module was missing from the command skip list. Battery green: NOP 0, oracle 3/3 at 1.0 127/127, nine hostile probes each naming its test. task.toml difficulty fields untouched. Round 2 detail follows. Round 2 came from a PEER REVIEWER with all evaluation checks PASSING. Confirmed and widened their claim: the exact Mann-Whitney one-sided p-values were inverted whenever n1 <= n2, including equal sizes, because `calc_mwu_exact_pvalue` ends with an `if k == n1` complement that is never correct. My own round-1 swapped-sample block had asserted the inverted values as correct. Fixed the oracle under `docs/guidelines.md:286` case 1 (upstream unavailable, statrs master still carries the branch), moved the PR helper test 0.6 to 0.4 in lockstep, pinned independently computed reference values for both sample orders across all three alternatives, added Automatic-with-pooled-ties and six pinned asymptotic values. f2p still 19, assertions 90 to 111. Applied the new `learning/empty-git-refs.md` remedy, and added a dash re-exec guard to both entrypoints after measuring that `sh /tests/test.sh` exited 2 with reward 0 without it. Checked the LEDGER L26 Go VCS hazard for cargo and measured it absent in a four-state matrix, so no `-buildvcs` analogue was invented. Ran the golden-omits-a-PR-file check both ways and it is clean. Battery green, six hostile probes, and the reviewer bug now fails 2 of 19 when reinstated. Round 1 detail follows. Review gate had blocked at the AGENTIC JUDGE, DISCUSS, reason `coverage_gap`, `test_coverage` 3.0 (claude 5, gpt 3). Difficulty screen never ran, which is expected on a judge block and is not a second failure. Report freshness-checked green on all four axes against zip `ebcad9ef`. All four named coverage gaps closed IN PLACE so f2p stayed 19, assertions 26 as shipped to 90: the one-sided test was swap-invariant and is now `one_sided_alternatives_pick_the_requested_tail` pinning which tail is small, Mann-Whitney gained one-sided coverage, chi-square gained four multi-violation precedence inputs, and the Emit cases now separate an emptied group from a constant one. Self-caught my own round-0 error: the `Automatic` dispatch sentence was backwards for mixed sizes, measured 9-vs-5 returning the Exact p-value. Two deliberate scipy departures (zero-skew z, whole-number f_exp totals) now stated and graded. Three scipy-constant assertions moved off 1e-12 to match the stated 1e-9 contract. Battery green: NOP 0 raw exit 101, oracle 3/3 at 1.0 128/128, seven hostile probes each naming its test. Local rehearsal: Q9 0 hits, Q10 0 hits, 35/35 requirements asserted. Round 0 detail follows. Zip `ebcad9ef`, 2652838 bytes, 126 entries. Four headline defects, all measured: `solve.sh` reverse-applied its own patch as the success path (replay gave SOLVED, BASE, SOLVED, so a predicted Oracle 2/3); the stock fail-open grader at `test.sh:507`, proven by running the extracted grader twice over one passing log; no regression guard at all, `pass_to_pass` empty with 628 existing tests ungraded; and the instruction published all seven full-precision constants that `tests.patch` asserts, making 5 of 11 graded tests passable by lookup. f2p 11 to 19, p2p 0 to 109, `allow_extra_failures` false, tolerances 1e-1 to 1e-9/1e-12. Instruction longest paragraph 2312 to 709 chars, plain ASCII, zero constants leaked. Battery green against a fresh extract: NOP 0 with raw exit 101 and `infrastructure_error: None`, oracle 3/3 at 1.0 with 128/128, five hostile probes each naming its test. NOP zero is compile-bound so it was split: 109 of 109 guards executed and pass at base, and the 19 f2p rest on a symbol audit that is reported as an audit. Dockerfile, `Cargo.lock` and the `model_difficulty` clash deliberately left alone and disclosed |
| [20260803_111822__xlwings_xlwings__2719](tasks/20260803_111822__xlwings_xlwings__2719/task.md) | 705a2188 | xlwings/xlwings 2719 | Fixable | pending-revision | 1 | 2026-08-07 | **SUBMITTED and bounced once.** Round 1 feedback carried two independent results. The difficulty screen returned `FAIL EASY` again (opus 3/4, codex 4/4), and the Quality Check failed 2 must-have criteria, both pointing at one test that demanded the exact method name `get_value` while the instruction only promised the error would say what to await. Difficulty answered by expanding the PR's own `values` argument to take a **list of sheet names**, chosen because the report showed the single failing agent run failed four tests that all sit in the values-and-no-clobber cluster, so the fix adds more of what already bites. Three plausible implementations of it are each wrong in a different visible way and each fails the graded suite (treating a truthy list as True fails 3 tests; letting the short reply update the book drops every unnamed sheet; marking all sheets makes unnamed ones read empty). The quality failure was fixed by relaxing the assertion to what the instruction states rather than adding the name to the instruction, verified three ways (both routes pass, load-only route now passes where it failed, no-route still fails 3). A local rehearsal before zipping caught the same class of defect in the new text and it was closed before upload. Zip `3360fead`, f2p 19 of 20, graded 41, battery green: NOP 0.0 with nonzero raw exit and 19 f2p executed as failing at base, oracle 3/3 at 1.0 with 41 of 41, 4 hostile probes each naming its test, 4 agent-collision cases at 1.0. Send gate 7 clean
| [20260728_153118__jqno_equalsverifier__1166](tasks/20260728_153118__jqno_equalsverifier__1166/task.md) | 7f75eb9d | jqno/equalsverifier 1166 | Fixable | pending-revision | 6 | 2026-08-01 | Round 6 2026-08-10: evals all passed, reviewer sent four findings. Difficulty fields aligned to hard (actioned). Three refused with measurements: network_mode removal contradicts docs/harbor-framework.md:61 and the Jul 27 changelog reversal; CMD is off-table and inert; the JaCoCo block is not unused, it is what keeps the offline run alive with MAVEN_ARGS unset |
| [20260727_135618__AltBeacon_android-beacon-library__1177](tasks/20260727_135618__AltBeacon_android-beacon-library__1177/task.md) | a1bcc8a9 | AltBeacon/android-beacon-library 1177 | Fixable | pending-revision | 7 | 2026-08-01 | Round 7 applied 2026-08-06. Panel DISCUSS `coverage_gap`. Both named requirements now graded inside existing tests (f2p stays 20), each proved by a hostile probe; the long-scan one needed reflection because no public reader exists, plus a negative control that closes the switch-it-on-always cheat. **Round 6's own rewrite was the defect this round fixed** - it replaced a false backward-compatibility claim with a stronger one, so round 7 removed the unbounded universals instead of narrowing a seventh time. Battery green, 5 probes. Oracle 0/3 re-read as the infra signature (no per-test output, platform text says flaky/infra) and unmeasured for 3 rounds |

## Done

| Task | Submission id | Repo / PR | Verdict | Status | Round | Closed | Note |
|---|---|---|---|---|---|---|---|
| [20260719_045042__oliver-oloughlin_kvdex__245](_archive/20260719_045042__oliver-oloughlin_kvdex__245/task.md) | 05589b6f | oliver-oloughlin/kvdex 245 | Fixable | accepted | 6 | 2026-08-04 | Accepted on round 6. The one bundle that cleared every gate, written up in `learning/accepted-bundle-reference.md` |
| [20260723_030109__cryspen_libcrux__1165](_archive/20260723_030109__cryspen_libcrux__1165/task.md) | 51077619 | cryspen/libcrux 1165 | Invalid / Not Fixable | accepted | 5 | 2026-08-11 | Accepted 2026-08-11 as **Invalid / Not Fixable**, trigger "PR scope needs to be changed or reduced", Environment Issues left blank on purpose. The workspace's first accepted Not Fixable and the first acceptance of a submission with **no bundle attached**, since Path C has no zip field. 17 defects were found and fixed across rounds 1 to 4 and none of that was ever reviewed. The verdict rests on `docs/guidelines.md:217`, which names "difficult enough" as a PR-scope trigger, plus a measured cause (18 oracle bodies of 1 to 7 lines, removed/added 0.01) and ten expansions tried or prototyped at zero effect. Write-up in `learning/not-fixable-is-a-written-argument.md`; evidence in `learning/raising-difficulty-on-a-wrapper-task.md` |

kvdex took six rounds, five of them spent on one defect: `tests.patch` not applying after an
agent had edited the tests. Three git-based restores passed every local scenario and none of
them worked on the platform, because the verify-time workspace is not a git repository. The
design that worked embeds a base64 archive of the base test tree inside `test.sh`. Full write-up
in `learning/tests-patch-vs-agent-edits.md`, which is now platform-confirmed rather than only
locally verified. **Read that note before writing a restore step on any new task.**

## Layout

Everything for one task sits in one folder, so nothing has to be hunted across the
workspace:

```
tasks/<Original Directory Name>/
  task.md              record: ids, verdict, status, check history, what changed
  task_details.md      the platform data block, pasted verbatim
  download/
    <submission_id>_submission.zip    exactly what the platform gave you
    original/                          pristine extract, never edited, diff target
  work/                                the working copy, ALL edits happen here
  upload/
    <Original Directory Name>.zip      the bundle you re-upload
  answers/
    submission_answer.txt              the form answers
```

Shared across every task:

```
README.md          orientation, the folder map and the bin/ command table
AGENTS.md          the short contract every agent reads before touching anything
CLAUDE.md          the workflow spine, the hard boundaries and the rule routing table
.claude/rules/     the eleven numbered sections in full, one file each, loaded every session
docs/              local export of the Hub, source of truth for policy
learning/          verified findings from real runs, read all of it at session start
bin/               the check and build scripts
chat_transcripts/  session transcripts kept as evidence, indexed in its own README
INDEX.md           this file
```

Local oracle and NOP runs use disposable copies in the **session scratchpad**, never a
folder inside the workspace. The workspace moved to ext4 on 2026-08-04, so the old NTFS
bulk-delete hazard no longer applies here. See `learning/local-runs.md`.

## Starting a new task

1. Make `tasks/<Original Directory Name>/` with the five subfolders above.
2. Drop the downloaded zip in `download/`, then extract to `download/original/` whichever directory inside it holds `instruction.md`, `task.toml`, `environment/`, `solution/` and `tests/` together. Packaging varies - that may be the zip root, `task/`, or `seed/` - so go by contents, not by name (`docs/harbor-framework.md`).
3. Paste the platform data block into `task_details.md`.
4. Copy `download/original/` to `work/` with `cp -a` so `.git` and dotfiles survive.
5. Add a row to the Active table here.
