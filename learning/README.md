# Learning log

Hard-won facts from real Sentinel submissions. Read every file here at the start of a
session, before touching a task.

Everything in this folder is **evidence from an actual platform run**, not a restatement
of `docs/`. When a note here contradicts `docs/` or `CLAUDE.md`, the note wins on matters
of fact about what the platform *does*, because it was verified against a real build log
or a real container run. Follow `docs/` for policy and judgment.

Two files are not notes and are read differently. [LEDGER.md](LEDGER.md) is the list of claims
this workspace has **disproved**, so a wrong idea does not come back looking new.
[calibration.tsv](calibration.tsv) is one row of measured numbers per task, for telling an
ordinary figure from an unusual one.

## Frontmatter

Every note carries YAML frontmatter, so the mandatory session-start read can be sequenced and
filtered instead of taken in file order.

```yaml
---
id: static-checks                       # slug, matches the filename
status: platform-confirmed              # see the vocabulary below
last_verified: 2026-08-04               # the date this note's evidence was gathered
verified_by:                            # the task or tasks it came from
  - 20260719_045042__oliver-oloughlin_kvdex__245
evidence: "what was actually observed, one line"
applies_to:
  languages: [any]                      # or [java, kotlin], [rust], ...
  runners: [any]                        # maven, gradle, cargo, deno, docker, git, zip, ...
  phases: [packaging, static-checks]    # where in the workflow it bites
blocks_submission: true                 # can this stop a submission by itself
fails_gate: [static-checks]             # which gate has actually failed because of it
supersedes: []                          # earlier positions this note retracts
contradicts: []                         # what it disagrees with, in docs/ or in itself
---
```

`status` vocabulary, strongest first:

| Value | Means |
|---|---|
| `platform-confirmed` | The platform itself returned this. A build log, a check result, an acceptance |
| `locally-verified` | Reproduced on this machine, usually in the task's own image |
| `reported` | Second-hand: another EC, a sibling workspace, Slack. **Not reproduced here.** Earlier drafts called this `provisional` |
| `superseded` | A later note replaced it. The row in `LEDGER.md` says what by |
| `refuted` | Disproved. Kept so nobody re-derives it. Must have a `LEDGER.md` row |

`blocks_submission: true` means an unfixed instance can stop a submission on its own, through a
static check, a difficulty verdict or a must-have Quality criterion. `false` does not mean
harmless: several `false` notes are things a peer reviewer bounced a green bundle for, and
`fails_gate` names which gate that was.

## Index

| File | Status | Verified | What it saves you from |
|---|---|---|---|
| [LEDGER.md](LEDGER.md) | locally-verified | 2026-08-04 | **Read this before designing a fix that resembles one already tried.** Every claim this workspace believed, shipped and then disproved, with what refuted it and what it cost. Twenty-two rows, six of them a full round or more each |
| [stock-bundle-defect-baseline.md](stock-bundle-defect-baseline.md) | locally-verified | 2026-08-11 | Eight defects the stock Harbor scaffold ships, six found independently on the first four bundles and two added by peer review. A Step 2 table with a verdict and evidence per row, so they stop being rediscovered one task at a time. **Amended 2026-08-11 (LEDGER L66)**: the count is six or seven of eight, not eight of eight, and two rows are ruled out **structurally** in a minute. Defect 8 cannot fire when `grading.parser.framework` is `custom`, and defect 7 does not apply when the verifier's `python3` rides in on the non-optional apt line. Defect 1 gained a third mechanism, a pipe written into `execution.commands` itself, which needs **both** halves of the Section 10.1 fix rather than either one |
| [static-checks.md](static-checks.md) | platform-confirmed | 2026-08-04 | The 20 checks the platform runs on upload, the `fail_to_pass` range that is a hard cap rather than a preference, the four filenames `tests/` will accept (a `tests/files/` directory is rejected despite being in the layout docs), and the reflog that comes back every time you regenerate `tests.patch` |
| [prescriptiveness-check.md](prescriptiveness-check.md) | platform-confirmed | 2026-08-02 | The second CodeBuild phase that scores `instruction.md`. How to actually make it pass, which took three uploads on one task, plus what it catches beyond the two documented rules, the symbol audit, and the floor below which cutting starts breaking the blocking checks. Also the mirror-image trap: **extending the oracle invents public symbols, and grading them without naming them in the instruction manufactures a Sufficiency FAIL by hand** |
| [tests-patch-vs-agent-edits.md](tests-patch-vs-agent-edits.md) | platform-confirmed | 2026-08-11 | `tests.patch` failing to apply once an agent has edited the tests, which made the difficulty verdict untrustworthy three rounds running. **Three git-based restores shipped and none worked on the platform**, because the verify-time workspace is not a git repository. The restore that works is an archive of the base test tree embedded in `test.sh` itself (**not** `tests/files/`, which the static checker rejects), and it is **platform-confirmed** as of 2026-08-04. A clean oracle run does not catch any of it |
| [stale-test-reports.md](stale-test-reports.md) | locally-verified | 2026-08-01 | Verifiers that read test results baked into the image at build time, which makes `pass_to_pass` an illusion and only shows up in the NOP run |
| [local-runs.md](local-runs.md) | locally-verified | 2026-08-04 | Wedging the workspace filesystem while running local oracle and NOP checks. **The workspace moved to ext4 on 2026-08-04**, so read the update at the top before assuming NTFS |
| [verify-in-the-image.md](verify-in-the-image.md) | locally-verified | 2026-08-11 | Static conclusions that were wrong: the host interpreter rejecting syntax the task's own Python accepts, a textbook-looking NOP whose collection aborted before grading anything, a NOP whose build tool refused the feature flag before compiling anything, and two hostile probes that "passed" because the break never landed |
| [empty-git-refs.md](empty-git-refs.md) | platform-confirmed | 2026-08-07 | `git gc` before zipping packs every ref and leaves `.git/refs/heads` empty. Git calls a repo with no `.git/refs` "not a git repository" even with HEAD, objects and packed-refs intact, so any extractor that drops empty directories removes git from the agent's workspace. Measured against a reviewer's count of 134 agent hits on that exact string **Correction 2026-08-07 (LEDGER L26): this can fail the ORACLE, not just inconvenience the agent.** The verifier not calling git is not the same as surviving a broken repo, because the toolchain calls it: Go fails `go build` outright with `error obtaining VCS status: exit status 128` on a half-present `.git`, which cost firefly 1123 a platform `Oracle 0/3`. A **missing** `.git` is harmless and a **half-present** one is fatal. Fix the cause and set `-buildvcs=false` |
| [git-autofetch-watcher.md](git-autofetch-watcher.md) | locally-verified | 2026-08-04 | An editor's periodic `git fetch` rewrites `.git/FETCH_HEAD` in every task checkout on a three minute cycle, including inside `download/original/`. It undoes the pre-zip git scrub silently, and `tasks/` being gitignored means `git status` can never reveal it |
| [unreachable-git-blobs.md](unreachable-git-blobs.md) | locally-verified | 2026-08-02 | Dangling blobs of the golden file and the patched test file surviving in `.git` after every documented git check passes. `gc --prune=now` alone does not clear them and nothing in `docs/` tells you to look |
| [verifier-fail-open.md](verifier-fail-open.md) | locally-verified | 2026-08-02 | A grader that scans stdout for the graded test names and writes reward 1.0 even though the test command exited nonzero. Compile failures, timeouts and crashes all grade as success. **The stock harness ships this defect**, so it is your task's defect unless you edited `test.sh` |
| [solve-sh-idempotency.md](solve-sh-idempotency.md) | locally-verified | 2026-08-04 | A `solve.sh` whose reverse-apply fallback undoes the solution on a second invocation, which reproduces on exactly zero local runs. Read the correction too: it was once blamed for an `Oracle 0/3` it did not cause |
| [solve-sh-under-sh.md](solve-sh-under-sh.md) | locally-verified | 2026-08-11 | Bashisms in a script the harness hands to `sh`. **Two halves with different provenance.** The `solve.sh` half is still imported from a sibling workspace and not reproduced here. The **`test.sh` half is measured here**, and it fails harder: `sh /tests/test.sh` writes **no reward file at all**, because dash dies on the stock `RUNNER=(...)` array before reaching the trap that guarantees one, so the platform sees a missing verifier output rather than a failure. One line to fix, and invisible to any battery that only invokes `bash <path>` |
| [mock-standing-in-for-the-deliverable.md](mock-standing-in-for-the-deliverable.md) | platform-confirmed | 2026-08-11 | **A mock of the thing you are grading is not coverage of it.** A subsystem the instruction names as a deliverable, reached by every graded test only through a caller that mocks it out, so every assertion sits downstream of the substitute and any implementation passes. Blocked firefly 1123 at the agentic judge **twice**, and the second report named three implementations that all scored 1.0. Carries the two-sided sweep (real instance per subsystem, plus every exported symbol golden adds), the rule that an ungraded symbol is a list to **judge** rather than a list to grade, and why the fix has to capture the argument instead of trusting the call happened |
| [quality-check-criteria.md](quality-check-criteria.md) | platform-confirmed | 2026-08-04 | The Quality Check returns 15 must-have criteria rather than the 10 axes `docs/` describes, and **instruction leakage and navigation can block submission on their own**. The "it is advisory, keep the residual findings" reasoning belongs to the prescriptiveness check and does not transfer. Also **why fixing an `oracle_spec_gap` breeds the next `coverage_gap`** (a narrowing that states a behaviour is a new requirement), and the four conditions under which a reflective assertion is the right way to grade a requirement with no public observable |
| [raising-difficulty-on-a-wrapper-task.md](raising-difficulty-on-a-wrapper-task.md) | platform-confirmed | 2026-08-06 | A task the platform measures as easy where the instruction cannot be trimmed, because the API names are the deliverable. What earns agent failures, and two expansions killed by `deny(unsafe_code)` and by workspace-wide feature unification. **Read the last section before quoting its Not Fixable answer**: all ten levers added to the original PR's own surface and none adapted a related later PR, which `docs/faq.md` sanctioned the day after, so the exhausted-option-space leg is unproven |
| [difficulty-is-divergence-not-volume.md](difficulty-is-divergence-not-volume.md) | platform-confirmed | 2026-08-11 | **`FAIL EASY` is not a size complaint.** A whole extra statistical test, adapted from a related later PR by the sanctioned route and pre-measured against four wrong implementations, converted **zero of eight** agents. The only assertion that ever failed one punished a *correct* implementation, on a place where the library deliberately contradicts the textbook. The lever class that works is oracle-versus-natural divergence, and answering judge clarity findings quietly spends difficulty that nothing measures until the screen runs |
| [answers-file-drift.md](answers-file-drift.md) | locally-verified | 2026-08-11 | What five rounds of editing does to `submission_answer.txt`. A five-lens adversarial audit returned 34 findings, about nine real, including a merged-away test id still named as current, a count two rounds stale, and an adapted PR whose number was never given so the reviewer could not check the one thing the scope expansion's legality rests on. Carries the per-round grep checklist and the one-write-per-edit rule that two silently-dropped edit batches earned . **Extended 2026-08-11** with a sixth lens (Attribution, a round credited with work it did not do) and with the measured fact that **the author's own six-lens pass is not an independent read**: five defects found by the author, seven more by an independent adversarial pass over the same finished file, the strongest signalled by all six lenses converging on one sentence. Plus the rule that a test id goes into an answer only after being grepped, since the fix round is where an invented one gets written|
| [when-fail-easy-is-not-not-fixable.md](when-fail-easy-is-not-not-fixable.md) | platform-confirmed | 2026-08-11 | **The companion to the Not Fixable note, and read them together.** redisshake 1005 was blocked at the difficulty screen FOUR times, answered with four different lever classes each measured at 0 of 4, closed the related-PR option space on evidence, assembled a complete Not Fixable dossier - and was **accepted on round 4**. Carries the discriminator that separates it from libcrux 1165 (the substance of the source PR, not the screen count, and above all whether the PR's own author got something subtly wrong), and the rule it produces: ship the round that improves coverage, correctness or authenticity even when its lever is unmeasured, because the difficulty verdict is not yours to compute |
| [stated-caveats-decay.md](stated-caveats-decay.md) | platform-confirmed | 2026-08-11 | Not a platform fact, a reasoning failure, and it nearly produced a wrong verdict. A caveat stated plainly in round 2 ("the control runs on a newer model than the screen, so 4 of 4 is a ceiling not a forecast") became a closing hedge in round 3 and its own opposite in round 4 ("two independent measurement systems now agree"), with nothing measured in between. Carries the three mechanics that make a caveat survive a revision round: an `## Open caveats` table with a retire-condition, the qualifier travelling as part of the value ("4 of 4 against Opus 5"), and the grep for the phrases that mark a caveat argued away rather than measured away |
| [difficulty-levers-must-discriminate.md](difficulty-levers-must-discriminate.md) | locally-verified | 2026-08-07 | How to answer `FAIL EASY` without burning a round on a dud. A candidate requirement is only a difficulty lever if **independent implementations of the feature disagree about it**, so run the candidates as throwaway probes against every implementation you have and discard every row where they all agree. 13 of 15 died that way on xlwings 2719. Separates a row that splits honest implementations (difficulty) from one that splits off a partial implementation (a coverage gap, worth closing for a different reason). **The strongest evidence a lever is real is that the upstream PR author got it wrong.** Also: audit the existing f2p list for padding before concluding the 20-id cap leaves you no budget |
| [probe-the-instruction-you-already-wrote.md](probe-the-instruction-you-already-wrote.md) | platform-confirmed | 2026-08-09 | **The difficulty you need is usually an ungraded clause in the instruction you already shipped.** Before adding a requirement to answer `FAIL EASY`, split every sentence you wrote into clauses and check a test fails when each is violated. xlwings 2719 went 87.5% to 75% to **37.5% solves and passed the screen** on a round that added no requirement at all, only an assertion on the untested half of one sentence, and the platform artifact names that id in two of three failing trials. Fair by construction, costs no instruction surface, and a guard for base-passing behaviour goes in `pass_to_pass` so it misses the 20-id cap entirely. Carries the two mechanics that make the probe trustworthy |
| [dirty-repo-and-symlinks.md](dirty-repo-and-symlinks.md) | locally-verified | 2026-08-04 | A shipped `environment/repo` whose working tree is already dirty, 28 lost mode bits and 7 symlinks flattened into regular files, the `zip -y` flag that stops your fix being undone at packaging time, and the same damage reappearing when the workspace is moved between filesystems |
| [oracle-bug-vs-pr-scope.md](oracle-bug-vs-pr-scope.md) | locally-verified | 2026-08-07 | When the source PR carries a real algorithmic bug and the instruction promises a standard, the narrow-the-instruction reflex is wrong and `docs/guidelines.md:286` case 1 authorises fixing the oracle. Check the project's default branch first, because an existing upstream fix is the canonical one. Also the trap that caused it: a graded test written from the oracle's observed behaviour cannot detect a bug in the oracle, so build an independent reference from the definition |
| [source-pr-cross-check.md](source-pr-cross-check.md) | locally-verified | 2026-08-11 | A coverage finding that describes the upstream PR rather than your tests, where the fix belongs in the instruction and touching the oracle would be reducing PR scope. Plus the GitHub API paging trap that produced a confidently wrong answer off page 1 of 2 |
| [diagnosing-platform-only-failures.md](diagnosing-platform-only-failures.md) | platform-confirmed | 2026-08-04 | **Three rounds spent fixing real defects that were not the defect.** How to work a failure that reproduces on the platform and nowhere else: the two-strikes rule, why a local reproduction proves sufficiency and never necessity, the round-over-round trend nobody read, and the evidence hierarchy that ends with a sibling task's report |
| [peer-review-bounces.md](peer-review-bounces.md) | reported | 2026-08-01 | What peer reviewers sent back on four submissions that had cleared every eval: an unnameable API, a font registry that fell from three to one with all 16 tests green, a matcher demanding literal tokens the instruction said were optional. **Another EC's tasks, not reproduced here** |
| [platform-announcements.md](platform-announcements.md) | reported | 2026-08-06 | Operating rules that reach ECs through Slack and never appear in `docs/`. The difficulty rerun ladder, and the fact that a failed Difficulty Check is never automatically a Not Fixable verdict. Now carries the boundary the ladder was missing: a review-gate screen reporting the task trivially easy is a measurement, not noise, so rerunning it wastes a round. **Subordinate to `docs/` on policy and to the run-backed notes on behaviour** |
| [accepted-bundle-reference.md](accepted-bundle-reference.md) | platform-confirmed | 2026-08-11 | The four bundles in this workspace that cleared every gate, with its measured numbers as a calibration target. Critically, it separates the hardening that acceptance **validated** from the hardening that merely was not caught, so advisory choices do not get quoted as proven practice. Carries the measured instruction-shape calibration: the bundles not bounced on clarity keep their longest paragraph under 800 characters |
| [not-fixable-is-a-written-argument.md](not-fixable-is-a-written-argument.md) | platform-confirmed | 2026-08-11 | **The first accepted Not Fixable, and the first acceptance of a submission with no bundle attached.** On Path C the form has no zip upload field, so the reviewer saw four things and nothing else: the verdict, two checkbox groups, a 4929-character seven-block unfixable explanation and 2172 characters of Comments for Reviewer. Carries the block structure that was accepted, one claim plus one measurement per block and no opinions, and the checkbox left blank on purpose with a stated reason. **Read the validated/not-validated section before quoting it**: the acceptance validates that the argument was sufficient for a reviewer, not that the option space was exhausted, because nobody re-ran the screen and no bundle was graded |
| [rust-cargo-verifier-gotchas.md](rust-cargo-verifier-gotchas.md) | locally-verified | 2026-08-05 | Three cargo-specific traps. `#[should_panic]` tests match neither stock parser pattern, so 49 of statrs's 629 tests are invisible in both directions and only the exit-code gate catches one failing. `cargo fetch` writes a `Cargo.lock` into the image that the repo does not carry, so bind-mounting `/app` breaks offline resolution and fails for a reason the platform never hits. And how to switch on a regression guard without grading the agent's own inline unit tests |
| [go-task-verifier-gotchas.md](go-task-verifier-gotchas.md) | locally-verified | 2026-08-06 | Four Go-specific traps. `go test ./...` exits nonzero on a **fully correct** tree for three pre-existing reasons, and the answer is to scope the command rather than drop the exit-code gate, which is a third option `verifier-fail-open.md` does not offer. A golden patch that omits a **generated** doc file the PR carries turns a green repo test red, and the fix is the PR's own hunk rather than a regeneration that folds in unrelated drift. Why a signature migration makes the `tests.patch` conflict guaranteed rather than likely, and why Go is the friendly case for reading a NOP. Plus the one-line re-exec guard that makes `test.sh` survive being handed to dash |
| [non-derivable-private-names.md](non-derivable-private-names.md) | locally-verified | 2026-08-06 | Graded tests that call a private name only the reference solution knows. On a per-package compiler one wrong name takes the whole package down, so six of them cost all 17 graded ids, and the arrival pass rates read exactly like difficulty. **The fix said not to exist**: point the tests at what the user sees rather than at the implementation's lookup key, which removes the names from the instruction too and grades more, not less. Plus how bubblezone's scan-wipes-the-last-scan worker turns into a deterministic barrier, and why a full test-tree restore makes an agent-written failing test the wrong way to prove an exit-code gate |
| [dockerignore-context-root.md](dockerignore-context-root.md) | platform-confirmed | 2026-08-06 | Why a repo that ships its own `.dockerignore` is still leaking editor artifacts into the image. Docker reads only the one at the **build-context root**, which on every Harbor bundle is `environment/`, so a rule at `environment/repo/.dockerignore` is inert by construction. Both agentic judges scored packaging **1.0** on it, which also settles the unadjudicated `.vscode` split recorded in `accepted-bundle-reference.md`. Carries the two-line check, the fix for an artifact tracked upstream, and the `git status` side effect to disclose |
| [cmake-reconfigure-needs-network.md](cmake-reconfigure-needs-network.md) | locally-verified | 2026-08-09 | On a CMake bundle, ninja treats every `CMakeLists.txt` as an input to `build.ninja`, so a `tests.patch` that adds a source file to a target re-runs the whole CMake configure inside the airgapped verifier. On ziti-sdk-c 668 that configure re-entered a `FetchContent_Declare` pinned to `GIT_TAG main` and the build died with `ninja: error: rebuilding 'build.ninja': subcommand failed`, before a single graded test ran. **This is when Section 10.3's separate-verifier-file practice loses**, and the collision surface has to be closed with a name prefix plus the test-tree restore instead. Carries the two-line check, why the Dockerfile fix is out of bounds, and the sibling trap of an `add_custom_target(... ALL)` that shells out to the network on a plain `cmake --build` |
| [difficulty-screen-unit-table.md](difficulty-screen-unit-table.md) | locally-verified | 2026-08-11 | **CORRECTED: the screen DOES produce a downloadable artifact.** The note originally said it does not, on the evidence of `debug output not available` three rounds running; statrs 315's screen block shipped 199 files with every trial's transcript and verifier report, and that exact string turns out to be a line **inside** it describing the sufficiency analysis. Ask for it by name on every screen block. What still stands: the `Unit Tests Results` block carries a denominator worth reading, and it does not always enumerate every graded id, so do not subtract from the agent-run count unless it is listing the whole set |
| [platform-locked-repos-are-still-testable.md](platform-locked-repos-are-still-testable.md) | platform-confirmed | 2026-08-11 | **"The verifier cannot build or run this" is a claim to measure, not a premise to build on.** elfuse 162 arrived grading a macOS Hypervisor.framework program with 15 regex-over-source ids, justified in the graded file's own docstring and banned by name at `docs/guidelines.md:135`. The premise was about the *program*; its *translation units* cross-compile for aarch64 and run under `qemu-user-static` on the same `ubuntu:24.04` verifier. Carries the five-step measurement ladder (step 3 is `gcc -c`, not `-fsyntax-only`, because one unguarded target instruction passes the second and fails the first), the shim and probe layout, `#include`ing a `.c` file to reach a `static` table, reaching the deliverable **by public number so no test names a symbol the solution creates**, host-call interposition, the two-pass link with generated placeholders, and why Not Fixable on this ground is an inference rather than a rule |
| [airgapped-means-no-egress-not-no-sockets.md](airgapped-means-no-egress-not-no-sockets.md) | platform-confirmed | 2026-08-09 | ziti-sdk-c 668 shipped two stated requirements ungraded because observing them 'needs a live controller and the verifier has no network', disclosed the gap in Comments for Reviewer, and the agentic judge returned **REMOVE, `Reason: coverage_gap`** naming exactly those two. `no-network` restricts **egress, not sockets**: a listener on `127.0.0.1` inside the test process grades the whole client path. Carries the libuv shape (bind port 0, read the port back, **`uv_unref` the listener or `uv_run` never returns**, same loop, close per response), and the point that a fixture which **refuses** the way the real service refuses is what turns an untestable ordering requirement into a graded one. Second confirmation of LEDGER L18: describing a gap is not closing it |
| [oracle-bug-vs-pr-scope.md](oracle-bug-vs-pr-scope.md) also now carries a **second confirmation** from redisshake 1005: Valkey's no-expiry marker is -1, the source PR read it as a timestamp, and every graded test agreed with the bug because all of them were written from the oracle's behaviour |  |  |
| [related-pr-carries-its-own-bug.md](related-pr-carries-its-own-bug.md) | platform-confirmed | 2026-08-07 | Answering a `FAIL EASY` with a related later PR. **Pick the candidate whose own code is subtly wrong, not the biggest one.** redisshake 1005's lever was PR 1038, which closes the TODO the source PR left, and whose `ParseServerVersion` returns on the first version line it meets. Valkey publishes a Redis compatibility version BEFORE its own, so upstream's function answers Redis for a Valkey server, and its own tests miss it because every fixture was hand-written without the Redis line. 4 of 5 plausible implementations fail the graded test built from real output. Carries the three-step search and the case-1 correction |
| [preflight-false-positives.md](preflight-false-positives.md) | locally-verified | 2026-08-07 | Two `bin/` checks that block a clean bundle and are not task defects. `pkg.leak.repo` flags any tracked `config.json` inside `environment/repo`, which on a Redis repo is the upstream spec for the CONFIG command, 1 of 391 command files. Deleting it would be editing tracked source. And `50-restore-shape` prints `UNRESOLVED` on Go ids because the left half is a module import path rather than a file path, which is LEDGER L7 working as intended. Carries the by-hand Go mapping, and the measurement it produced (7 of 22 outside the patched files, so the full payload rather than a create-only patch) . **Third entry added 2026-08-11**: Send gate 7 (`find work -newer <zip>`) goes red after any git command in `work/`, because `git status` writes `.git/index`. Disambiguate with `diff -rq` against an extract, never on mtime|
| [agent-writable-test-infrastructure.md](agent-writable-test-infrastructure.md) | locally-verified | 2026-08-11 | **`tests.patch` protects the graded test bodies and nothing protects the assertion library they call.** On mithril.js 2021 an agent that left `render/render.js` at base and added one clause to `ospec/ospec.js` scored **reward 1.0, 15 of 15**. The Section 10.3 snippet cannot see it, because the route runs through paths `tests.patch` never touches. Carries the two-minute probe, which discriminated rather than always firing |
| [reviewer-path.md](reviewer-path.md) | locally-verified | 2026-08-11 | **Peer review is in scope now and `CLAUDE.md` said it was not.** The live reviewer form has four questions where `docs/tasking-guide.md:401-459` lists seven, **settled by two independent captures**, so the rebuttal-acknowledgement and review-duration fields are not template fields and no `PENDING` line is carried for them (LEDGER L65). The submitter's answers do not arrive with the zip on any of the three reviews run here, which is why every finding must be worded against the bundle rather than against the submitter. Also why 40 of 77 first-pass findings were refuted, and the four checks that would have caught them |
| [reviewer-findings-need-a-baseline.md](reviewer-findings-need-a-baseline.md) | locally-verified | 2026-08-11 | **A reviewer finding claims the submitter did something, so it needs a baseline before it needs a paragraph.** Four metadata findings on expressa 132, **three withdrawn** after measuring `_archive/*/download/original/` rather than `work/`, and one of the three was already **LEDGER L58**, filed and disproved eleven hours earlier by the other review that day. Carries the measured pristine `task.toml` baseline (`os` and `difficulty_explanation` absent 5 of 5, `verifier 300` vs `execution 1800` in 5 of 5), the rule that `LEDGER.md` is read first and in full rather than via `README.md`, the mtime-forensics read that tells you what the submitter actually changed from the zip alone, and the mirror check: before advising deletion of a leaked literal, grep the graded tests, because `docs/guidelines.md:99` exempts genuine API contracts and the draft advice would have broken two assertions |
| [graded-tests-that-import-the-deliverable.md](graded-tests-that-import-the-deliverable.md) | locally-verified | 2026-08-11 | **The arbitrary-naming rule gets broken in the import block, where nobody reads it as a requirement.** `docs/guidelines.md:149-159` lists a "new module/file name" among the names that must be derivable. cista 172's graded test file opens with `#include "cista/type_hash/static_type_hash.h"` and `instruction.md` contains **no file path at all**. Measured: a complete correct solution placed at another legal path scores **reward 0, 4 of 21**, because the compile dies and all 17 ids in that translation unit report missing. Deleting that one line returns **21 of 21 for both placements**, since golden already makes `serialization.h` include it. Neither the bipartite mapping nor pre-upload item 10 can see it, both walk identifiers rather than paths, and the oracle can never reproduce it. Carries the move-the-created-file probe and the equivalents in pytest, cargo, deno and JUnit |
| [instruction-promises-the-suite-keeps-passing.md](instruction-promises-the-suite-keeps-passing.md) | locally-verified | 2026-08-11 | **An instruction does not have to order a test edit to force one.** `CLAUDE.md` pre-upload item 14 greps for an instruction that names a path `tests.patch` writes to; expressa 132 reached the same disaster by inference. A closing sentence promised the pre-existing suites keep passing, which the required change makes false: base 117 passing / 0 failing, after `golden.patch` alone **113 / 4**, all four in the named file. The only edit that satisfies the sentence lands where `tests.patch` writes, and it was measured as an **invalid trial**. Carries the golden-without-tests.patch run that detects it, the 10-row agent matrix, and the finding that the staged/unstaged asymmetry is the **reverse** of kvdex's |
| [oracle-protocol-is-solve-then-verify.md](oracle-protocol-is-solve-then-verify.md) | locally-verified | 2026-08-11 | **Running `solve.sh` three times is not the Oracle Check.** Step 5.5 and `solve-sh-idempotency.md` are both about the oracle **script**; the platform runs the golden solution **and the verifier** three times. mithril.js 2021 has a correct reverse-check `solve.sh` that replays 3 of 3, and the real protocol returns **1 of 3**, because `test.sh` applies `tests.patch` every run and restores nothing, so cycles 2 and 3 give `infrastructure_error: tests.patch did not apply`. Both halves sat in one `task.md` thirty lines apart and were never joined, with the optimistic one in the paragraph of things that are right. A missing restore is an Oracle Check defect, not only an agent-collision defect, and the same three cycles return 1, 1, 1 once the restore includes the create list |
| [audit-the-finished-review-not-just-each-finding.md](audit-the-finished-review-not-just-each-finding.md) | locally-verified | 2026-08-11 | **Per-finding rigour does not survive contact with the finished document.** An adversarial pass over a careful 11-note review left **1 note confirmed and 9 weakened**, none refuted, plus two blocking findings nothing had run a check for. Five error classes, all in the second sentence of a note rather than in whether the defect was real: a baseline measured against `work/` **twice** in a document that gets it right eleven lines later (L61 again), two remedies that contradict each other about the same file, a restore scoped short and described as complete, a number that exists only in the answer, and a mechanism disproved by deleting the thing it named. Carries the five-check audit pass, and the rule that you walk the **run list** rather than the finding list, since both new blocking defects sat behind an invocation nobody had tried |
| [calibration.tsv](calibration.tsv) | locally-verified | 2026-08-06 | Judging bundle shape off one example. 36 measured columns for every task handled here, caveats included, so "is 1204 pass-to-pass ids a lot" has an answer |

**Sequencing the mandatory read.** Take `LEDGER.md` and
`stock-bundle-defect-baseline.md` first, then everything with
`blocks_submission: true`, then the rest. Filter the rest by `applies_to.runners` against the
task in front of you, and read the `reported` notes knowing they are second-hand.

## Evidence sources

Raw material the notes were written from lives in `chat_transcripts/` at the workspace root.
It is not indexed here note by note because it is transcript, not conclusion, but it is where a
claim gets checked when a note's summary is not enough:

| File | What it is |
|---|---|
| `chat_transcripts/cursor_etlcpp.md` | Another EC's session on `20260716_114438__ETLCPP_etl__1466`, including the peer reviewer's findings. **Primary evidence** for `unreachable-git-blobs.md`, `verifier-fail-open.md`, the graded-test-naming half of `tests-patch-vs-agent-edits.md`, and `CLAUDE.md` section 10 |
| `chat_transcripts/oliver.txt` | The kvdex 245 sessions, six rounds to acceptance |
| `chat_transcripts/cryspen.txt` | The libcrux 1165 sessions |
| `chat_transcripts/alt.txt` | The android-beacon 1177 sessions |
| `chat_transcripts/jqno.txt` | The equalsverifier 1166 sessions |

Do not delete anything in there as an unexplained loose file. Three notes and a `CLAUDE.md`
section rest on the first row alone.

`unreachable-git-blobs.md` and `verifier-fail-open.md` started as a peer reviewer's notes on
another EC's bundle rather than a run on this machine. Both have since been reproduced here,
and the provenance is stated at the top of each. Both survived every platform eval, which is
the point: the evals grade the task as declared and a reviewer reads what the verifier
actually does.

Two checkers read `instruction.md` and they are easy to confuse. The **prescriptiveness** check
(`P1..Pn`, a 0 to 1 score, CodeBuild BUILD phase) does not block and says so. The **Quality
Check** (`Q1..Q15`, must-have criteria) does. They flag overlapping text and disagree about how
far to cut, in both directions: the Quality Check has failed a task for not testing a
requirement the instruction states, and prescriptiveness then flagged the instruction for
stating it. Fix for the blocking one. A prescriptiveness finding that quotes a requirement a
graded test asserts is asking you to break `test_faithfulness`.

Prescriptiveness passing once does not settle it. Any later edit to `instruction.md` re-runs the
check, and it has come back red on text that was unchanged since the round that passed. The
threshold is above 0.50.

The upload pipeline runs its phases in order and stops at the first failure, so expect to
find problems one at a time rather than all at once. On both tasks so far the static checks
failed first and the prescriptiveness check only surfaced once they passed. Budget for
several upload rounds rather than assuming one clean pass.

Habits that come out of these notes and are worth doing on every task:

- Run the static-check simulation in `static-checks.md` **against the built zip**, not the
  working copy. Both times a check failed on this task, the working copy looked fine and
  the zip did not.
- Do git hygiene last, immediately before zipping.
- Before removing any path or name from `instruction.md`, grep the tests for it. Instruction
  and tests move together or you trade one violation for a worse one. On a refactor task,
  cut until only the symbols the suite calls by name are left, then stop and document the
  residual findings.
- A NOP reward of 0 is necessary but not sufficient. Check *which* tests passed, not just
  the reward, or a verifier reading stale results will look healthy. Check the pytest
  summary line too — a collection abort marks every f2p as failed and hides the ones that
  already pass at base.
- Never report a fact about the repo from a check run on the host. Read the runtime the
  image actually pins, then re-run the check inside the container. A repo pinned ahead of
  the host toolchain looks broken and is not.
- A green oracle run proves almost nothing about how the task behaves under a real agent.
  Before shipping, run the oracle once more with a simulated agent edit to any file
  `tests.patch` touches — and make that simulated agent **commit** its work, not just leave
  the tree dirty. Unstaged-only simulations are why a broken restore step shipped twice.
- Restore the test tree from an archive **embedded in `test.sh`**, not with git and not from
  `tests/files/` (the static checker rejects that directory). Three git-based restores passed
  every local scenario and none of them worked on the platform, because the verify-time
  workspace is not a git repository. `test.sh` is read from `/tests`, so a restore sourced from
  there is as reliable as the verifier itself. **Confirmed 2026-08-04**: this is the design that
  finally got kvdex 245 through its difficulty check and accepted.
- Read the agent session transcripts in the difficulty artifact before theorising about agent
  behaviour. They showed `.git` present and not one agent staging or committing, which killed
  two plausible theories in a single grep.
- **Two strikes.** When a fix you verified locally fails on the platform a second time, stop
  refining the theory and remove the dependency instead. The third mechanism is the same trap:
  locally reproducible, a genuine defect, and another wasted round. A local reproduction proves
  a condition is *sufficient* to cause the symptom, never that it is the one in play.
- A probe has two assertions and the first is that the break landed. `$HOME`, Java's `user.home`
  and a tool's own `*_USER_HOME` are three different things, so `-e HOME=...` proves nothing about
  a Gradle or Maven cache. Print what the tool resolved in the same command as the result.
- If the verifier runs offline, pin every cache it reads to an absolute path with `ENV` and warm it
  there. A cache under `~` moves with the uid the container runs as, which you cannot observe.
- Read the round-over-round trend before designing the next fix. 13 of 16 invalid, then 16 of
  16, then 15 of 16 is a flat line across two different fixes, and a flat line means neither
  fix touched the cause. That signal is free and it was ignored for two rounds.
- Anchor a verifier to the thing whose presence is implied by your code running at all.
  `test.sh` is read from `/tests`, so `/tests` is guaranteed mounted. Anything in the agent's
  workspace is not.
- An acceptance validates the things that previously failed and were then changed. Everything
  else in that bundle merely was not caught. Keep the two lists apart, or advisory choices get
  cited as proven practice.
- When your own difficulty report returns `Task Instruction Sufficiency: NOT_APPLICABLE`, read
  the **other** tasks' reports before concluding you have no evidence. The harness is shared,
  so a sibling task's per-trial analysis is evidence about your task's environment. kvdex spent
  three rounds guessing at a mechanism that equalsverifier's report stated outright.
- A local control that returns all-pass is a **ceiling, never a forecast**, whenever it runs on a
  model newer than the ones the difficulty screen grades. Write the model into the number every
  time it is quoted, and never let a local zero override a platform result. redisshake 1005 got
  four measured zeroes that way and was accepted on the fourth.
- Ship the round that makes the bundle more correct, better covered or more authentic, even when
  you cannot prove its difficulty lever works. The screen answers its own question and you do not.
- Before adding a requirement to answer `FAIL EASY`, ask whether the source PR's own author got
  anything subtly wrong. A place they got wrong is a trap; a PR with no such place is where a
  difficulty ceiling is structural rather than a lever you have not found yet.
- Split the graded ids by whether their module compiles at base. Actually run the ones that do.
  That is where a test that already passes hides, and the NOP cannot show it. Better still, when a
  public handle already reaches the feature, write the harness so it names no symbol the solution
  creates: it then compiles against the unsolved tree and the split comes for free.
- Verify git cleanup, do not assume it. `git fsck --unreachable --no-progress` must print
  nothing after the final gc, or the golden file is still readable out of `.git`.
- Run `git status --porcelain` in `environment/repo` before touching anything. The tree can be
  dirty in the bundle as received, and if symlinks are involved the zip needs `-y` or your
  cleanup is undone at packaging time.
- A requirement no assertion can reach can still be graded. Put it in `execution.commands` as a
  command and let the exit-code gate carry it.
- Read the grader before trusting any reward. If `test.sh` parses stdout for the graded test
  names, confirm it also gates on the test command's exit status. `set -e` in the generated
  runner does not cover a command that is itself a pipeline, and the `pipefail` at the top of
  `test.sh` does not reach the child shell that runs it. Check the NOP's `raw_exit_code`, and
  measure the runner's bare exit on a green tree before wiring any gate.
- Check a judge's coverage finding against the source PR before acting on it. If the thing it
  complains about comes from the PR, the oracle is faithful and the instruction is what is
  over-promising. Fetch the PR file list through the API and **page it** — a 100-file page 1
  of a 198-file PR gave a confidently wrong answer.
- Before zipping, stub one requirement the instruction states and re-run the verifier. If the
  reward stays 1.0, that requirement has no assertion behind it.
- Run `solve.sh` twice in one container before shipping. A single clean run says nothing about
  the second, and the platform runs the oracle three times.
- If the NOP's `test-stdout.txt` is **empty**, nothing ran and the reward is meaningless. On a
  feature-flag task the build tool rejects the command line itself (`does not contain this
  feature`) before compiling anything, which is earlier than a collection abort and looks just
  as healthy. Never write "the tests could not pass" into Comments when the log is zero bytes.
- A hostile probe has two assertions. Prove the break actually landed, with a `grep -c` before
  and after inside the same container run, then read the reward. A `sed` or `perl` that matched
  nothing is silent, so "reward 1, all tests pass" is far more often a broken probe than a
  broken guard.
- Re-run the whole battery against the **extracted zip** whenever the bundle was assembled
  somewhere other than where it was measured. Round-1 numbers taken from a `work/`-built image
  are not what "against the exact zip in upload" claims in Comments for Reviewer.
- The difficulty screen has a cheap single-arm mode (4 runs) that gates the review, and it only
  runs if the agentic judge passed. A difficulty-only failure therefore means the judge is settled.
  Observed here first, documented by the Hub on 2026-08-05 as the **review gate** (`docs/faq.md`),
  so it is now a rule in `.claude/rules/05-evals-and-quality-check.md` rather than local lore.
- On a review-gate block the one-line eval summary names only the stage that stopped it. The reasons
  are in the **"Agentic Judge Quality Report"** field on the submission, which is collapsed and
  marked optional lower down the form, so ask for it by name. `Not run: difficulty screen` beside a
  judge block is the expected consequence, not a second failure to diagnose.
- Before designing a SECOND difficulty expansion, measure the oracle's function body lengths. If
  they are all short delegations to things the crate already exports, the ceiling is the PR and
  more API surface cannot raise it. Change the kind of requirement or escalate.
- A new requirement is only worth adding if you can name a plausible implementation it newly
  fails. Write that implementation, run it, and check it scored 1.0 on the previous bundle.
- Before acting on a "feedback" paste, check its citations against the bundle you actually hold.
  Test names, line numbers and file sizes date a report precisely. A round-0 report re-pasted as
  round 2 costs a whole round of rework on findings already fixed.
- The which-restore-shape one-liner assumes pytest-style `path::test` ids. On cargo, JUnit, Go or
  Jest the path is not in the id, so it reports every graded id as outside the patched files.
  Resolve it by hand when the id scheme and the `touched` paths share no namespace.
- A restore payload only needs the files that DEFINE graded ids, not the whole test tree. 20 MB of
  tests became 4.9 KB of base64 that way. Fixture data the tests read at runtime is not covered by
  it, so assert the expected count in the test instead of only that the fixture is non-empty.
- A filesystem move re-flattens the repo's symlinks and re-dirties the tree, exactly like
  zipping without `-y`. Re-run the git sweep in `work/` after any move, sync or archive
  round-trip, and check the shipped zip separately rather than inferring one from the other.

- Assume all six stock-scaffold defects are present on an arriving bundle and fill the
  baseline table with a verdict and a command per row. Four tasks, four languages, and the same
  six findings every time.
- On a failed Difficulty Check with an unchanged bundle and green local checks, rerun once, then
  a second time, and only then diagnose or escalate. Reruns come before any fix has shipped;
  two strikes applies after one has.
- Run **both** entrypoints under `sh` at least once, not only under `bash`. A shebang is ignored
  when the file is passed to an interpreter, so `bash /solution/solve.sh` hides every bashism in
  it. `test.sh` is the worse half: dash dies on the stock `RUNNER=(...)` array before the
  `trap ... EXIT`, so there is no reward file at all rather than a reward of 0.
- Preserve symlinks at packaging time and prove it: `unzip -Z <zip> | grep -c '^l'` has to equal
  `find work -type l | wc -l`. Both sides print 0 on a repo with no symlinks and the check costs
  nothing.

- When a bundle grades source text, or leaves a stated requirement ungraded, and the stated reason
  is that the verifier cannot build or run the thing: **that is an untested claim.** Spend twenty
  minutes on the ladder in `platform-locked-repos-are-still-testable.md` before accepting it. The
  program not running is not the same as its translation units not compiling.
- Compile with `-c`, not `-fsyntax-only`, when you are deciding whether a unit is usable. One
  unguarded target instruction (`__asm__ volatile("mrs %0, cntfrq_el0")` with no arch guard) passes
  a syntax check and fails at the assembler, which is what decides host-native versus cross plus
  qemu.
- An instruction cannot be de-prescribed below the names its tests demand, and that floor is a
  property of the tests. Move the floor first: rewrite the tests to reach the deliverable through
  something public, and the paths and symbols fall out of the instruction on their own.
- Grep `instruction.md` for every path `tests.patch` touches before shipping. An instruction that
  tells the agent to edit one of them guarantees an invalid trial on every compliant run, and the
  oracle never reproduces it.
- Compare `golden.patch` to the source PR by **hunk body**, not by file list. Three of elfuse's
  eleven polluted hunks sat inside files the PR does legitimately touch, so the file-list diff
  reported four extra files where the truth was eleven extra hunks across seven.
- Put the loose ref back in two steps. `git rev-parse HEAD > .git/refs/heads/main` truncates the
  file before the command runs and writes the literal string `HEAD`.
- On Path C there is no zip field, so the explanation is the entire submission. Give each leg its own numbered block, put a number or a file:line in every one, and say why you left a checkbox blank. A seven-block explanation built that way was accepted on the first submission.
- A task that closes, whether accepted, rejected or abandoned, triggers a note or an update here and a `calibration.tsv` row in the same action, because that is the only moment the whole task is still in view. This is Step 11.

## How to add to this log

Add a note when something cost real time and would cost it again. Each note should say:

1. **What happened** with the exact error text or command output.
2. **Why** it happened.
3. **The rule** to apply next time, stated so it can be followed without re-deriving it.
4. **Date and task** it came from, so a stale note can be spotted later.

Plus the frontmatter block described at the top of this file, and a row in the index table with
its `status` and `last_verified`. A note with no frontmatter cannot be sequenced or filtered,
which is the whole reason the mandatory read is expensive.

**When you retract something, `LEDGER.md` gets a row in the same edit.** That covers flipping a
note's `status` to `refuted` or `superseded`, and it also covers retracting a single claim
inside a note that otherwise stands. A retraction that lives only in prose gets skimmed past,
and the wrong idea comes back looking new. Fill in every column: what was believed, why it was
believable, what refuted it with the evidence, what replaced it, and what it cost in rounds.

Do not log things already covered by `docs/` or `CLAUDE.md`. Log the gap between what
those say and what actually happens.
