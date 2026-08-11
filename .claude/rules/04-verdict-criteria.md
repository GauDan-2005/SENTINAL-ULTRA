_Owner of CLAUDE.md **Section 3**. Loaded every session._

## 3. Verdict criteria (official)

**Valid as-is:** instruction, tests, and oracle all align with each other and with the source PR. No edits required. All 7 compliance items are genuinely true.

**Fixable** - any of:

1. Instructions overly prescriptive or exposing verifier internals
2. Instruction reads as templated/AI-generated
3. Tests miss requirements stated in the instruction
4. Tests grade undescribed behavior or rely on arbitrary (non-derivable) names
5. Fewer fail-to-pass tests than the bar → add tests to reach it (11–20; the static check rejects anything outside 10–20)
6. Solution leakage (PR URL in instruction, environment spoilers, test-gaming shortcuts)
7. Oracle does not implement the instruction
8. Task too easy → raise difficulty by expanding PR scope. Material for that expansion may be adapted from a later PR in the same repo when it is a RELATED one - `docs/faq.md`, "A task came back too easy - can I adapt a change from a related PR to add complexity?". Never pull from an unrelated PR, never lift a PR wholesale, and never change the scope or feature of the original PR. This sits inside the expansion-only rule and does not widen it
9. A specific, LISTED Dockerfile issue (allowed-fix table in sentinel-task-fixing)
10. A git-hygiene issue in the shipped repo (leaked history, remote, HEAD/base mismatch, reflog, oversized .git)
11. A `task.toml` problem measured against the Section 8 limits - a value out of range, `gpus` not 0, a missing or stripped `network_mode` block, an agent timeout too low for the runs, inaccurate `category` / `difficulty_explanation` / source URL
12. Packaging problems - `tests.patch` cut against the wrong base, a pre-existing test file left modified in the shipped tree (not one that `tests.patch` edits, which is allowed), stray dev artifacts, `solution.patch` instead of `golden.patch`, `problem_statement.md` out of sync with `instruction.md`

**Invalid/Not Fixable** - either of:

1. PR scope needs to be changed or reduced - the only path to validity is reducing or replacing the PR scope entirely
2. Environment issues ECs cannot fix: tangled image/dependency build failures, an oracle timeout that bumping cannot resolve, an agent that genuinely cannot finish within the 7200 s ceiling, heavy external-network dependency, genuinely unrecoverable git corruption

**NOT a Not Fixable condition - platform and infra failures.** A failed eval is only a verdict input when it is caused by the task. `DaytonaRateLimitError` / `ApiRateLimitError`, sandbox auth or connection errors, a one-off `NonZeroAgentExitCode`, and a run that returns blank feedback or "No evaluation information available" are all platform-side. **Infra and platform failures never make a task Unfixable.** The tell is inconsistency - the same task passes on one run and errors on another, or only 1 of N agent trials fails while the rest are clean. Retry rather than reworking; do not burn a revision slot resubmitting blindly; if it persists, tell the user to flag it on Slack with the task/submission UID, the exact error, and whether it is intermittent (that is what separates an outage from a real defect). Before concluding anything from a red eval, separate a platform failure from a task defect that merely looks like one - `tests.patch did not apply` after an agent edited the tests reproduces on every run and IS a task defect (see Section 4 and `learning/tests-patch-vs-agent-edits.md`).

**A review-gate block is the same kind of carve-out - it is not on the platform-side list.** `docs/faq.md`, "My eval says Review gate blocked at the agentic judge / difficulty screen - what does that mean?", says a block is in almost every case a real content-side result to act on. Blocked at the agentic judge means the judge returned a needs-work verdict, and the reasons are in the "Agentic Judge Quality Report" field on the submission, which is collapsed and marked optional, not in the one-line summary. Blocked at the difficulty screen means the screen found the task trivially easy, which is Fixable trigger 8 and not an outage. "Not run: difficulty screen" means the judge blocked first so the later stage never ran, which is expected rather than a second error. The one infra case is a message that explicitly says the difficulty screen failed with an infra error, and that one is retried like the errors above. None of these makes a task Not Fixable. If the same block repeats across different tasks, or several land in a short window with otherwise-clean checks, have the user flag it on Slack with the UIDs - a cluster is what points at a platform-side problem rather than at each task.

Rules: a single Not Fixable condition overrides everything. Fixable requires every issue actually fixed - a Fixable verdict with unfixed issues is never allowed. Full detail: sentinel-task-check and sentinel-task-fixing.
