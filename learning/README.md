# Learning log

Hard-won facts from real Sentinel submissions. Read every file here at the start of a
session, before touching a task.

Everything in this folder is **evidence from an actual platform run**, not a restatement
of `docs/`. When a note here contradicts `docs/` or `CLAUDE.md`, the note wins on matters
of fact about what the platform *does*, because it was verified against a real build log
or a real container run. Follow `docs/` for policy and judgment.

## Index

| File | What it saves you from |
|---|---|
| [static-checks.md](static-checks.md) | The 20 checks the platform runs on upload, the `fail_to_pass` range that is a hard cap rather than a preference, the four filenames `tests/` will accept (a `tests/files/` directory is rejected despite being in the layout docs), and the reflog that comes back every time you regenerate `tests.patch` |
| [prescriptiveness-check.md](prescriptiveness-check.md) | The second CodeBuild phase that scores `instruction.md`. How to actually make it pass, which took three uploads on one task, plus what it catches beyond the two documented rules, the symbol audit, and the floor below which cutting starts breaking the blocking checks |
| [tests-patch-vs-agent-edits.md](tests-patch-vs-agent-edits.md) | `tests.patch` failing to apply once an agent has edited the tests, which made the difficulty verdict untrustworthy three rounds running. **Three git-based restores shipped and none worked on the platform**, because the verify-time workspace is not a git repository. Reproduced locally on kvdex, named outright by four codex trial analyses on equalsverifier. The restore that works is an archive of the base test tree embedded in `test.sh` itself (**not** `tests/files/`, which the static checker rejects), and it is **platform-confirmed** as of 2026-08-04. A clean oracle run does not catch any of it |
| [stale-test-reports.md](stale-test-reports.md) | Verifiers that read test results baked into the image at build time, which makes `pass_to_pass` an illusion and only shows up in the NOP run |
| [local-runs.md](local-runs.md) | Wedging the workspace filesystem while running local oracle and NOP checks. **The workspace moved to ext4 on 2026-08-04**, so read the update at the top before assuming NTFS |
| [verify-in-the-image.md](verify-in-the-image.md) | Static conclusions that were wrong: the host interpreter rejecting syntax the task's own Python accepts, a textbook-looking NOP whose collection aborted before grading anything, a NOP whose build tool refused the feature flag before compiling anything, and two hostile probes that "passed" because the break never landed |
| [unreachable-git-blobs.md](unreachable-git-blobs.md) | Dangling blobs of the golden file and the patched test file surviving in `.git` after every documented git check passes. `gc --prune=now` alone does not clear them and nothing in `docs/` tells you to look |
| [verifier-fail-open.md](verifier-fail-open.md) | A grader that scans stdout for the graded test names and writes reward 1.0 even though the test command exited nonzero. Compile failures, timeouts and crashes all grade as success. **The stock harness ships this defect**, so it is your task's defect unless you edited `test.sh` |
| [solve-sh-idempotency.md](solve-sh-idempotency.md) | A `solve.sh` whose reverse-apply fallback undoes the solution on a second invocation, which the platform reports as "Oracle did not pass all runs: 0/3. Task may be flaky" and which reproduces on exactly zero local runs |
| [quality-check-criteria.md](quality-check-criteria.md) | The Quality Check returns 15 must-have criteria rather than the 10 axes `docs/` describes, and **instruction leakage and navigation can block submission on their own**. The "it is advisory, keep the residual findings" reasoning belongs to the prescriptiveness check and does not transfer |
| [raising-difficulty-on-a-wrapper-task.md](raising-difficulty-on-a-wrapper-task.md) | A task the platform measures as easy where the instruction cannot be trimmed, because the API names are the deliverable. What earns agent failures, and two expansions killed by `deny(unsafe_code)` and by workspace-wide feature unification |
| [dirty-repo-and-symlinks.md](dirty-repo-and-symlinks.md) | A shipped `environment/repo` whose working tree is already dirty, 28 lost mode bits and 7 symlinks flattened into regular files, the `zip -y` flag that stops your fix being undone at packaging time, and the same damage reappearing when the workspace is moved between filesystems |
| [source-pr-cross-check.md](source-pr-cross-check.md) | A coverage finding that describes the upstream PR rather than your tests, where the fix belongs in the instruction and touching the oracle would be reducing PR scope. Plus the GitHub API paging trap that produced a confidently wrong answer off page 1 of 2 |
| [diagnosing-platform-only-failures.md](diagnosing-platform-only-failures.md) | **Three rounds spent fixing real defects that were not the defect.** How to work a failure that reproduces on the platform and nowhere else: the two-strikes rule, why a local reproduction proves sufficiency and never necessity, the round-over-round trend nobody read, and the evidence hierarchy that ends with a sibling task's report |
| [accepted-bundle-reference.md](accepted-bundle-reference.md) | The one bundle in this workspace that cleared every gate, with its measured numbers as a calibration target. Critically, it separates the hardening that acceptance **validated** from the hardening that merely was not caught, so advisory choices do not get quoted as proven practice |

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
- Split the graded ids by whether their module compiles at base. Actually run the ones that do.
  That is where a test that already passes hides, and the NOP cannot show it.
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

## How to add to this log

Add a note when something cost real time and would cost it again. Each note should say:

1. **What happened** with the exact error text or command output.
2. **Why** it happened.
3. **The rule** to apply next time, stated so it can be followed without re-deriving it.
4. **Date and task** it came from, so a stale note can be spotted later.

Do not log things already covered by `docs/` or `CLAUDE.md`. Log the gap between what
those say and what actually happens.
