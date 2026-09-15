_Owner of CLAUDE.md **Section 7**. Loaded every session._

## 7. Task Directory Structure

```
SENTINAL-ULTRA/                      # Workspace root (WSL: Ubuntu-22.04, ext4)
  .cursor/
    rules/
      sentinel-difficulty-scope.mdc  # Companion rules - Cursor copy
      sentinel-task-check.mdc
      sentinel-task-fixing.mdc
      humanizer.mdc                  # Tool rules, same twinning discipline
      quality-rehearsal.mdc
  .claude/
    rules/                           # The twelve CLAUDE.md sections in thirteen files,
                                     # Section 1 split across the first two. Every .md here
                                     # is loaded into context at session start, at the same
                                     # priority as CLAUDE.md. No Cursor twin - Cursor reads
                                     # .cursor/rules/ and never reads this
      01-workflow-steps-1-to-5.5.md  # Section 1, Steps 1 to 5.5
      02-workflow-steps-6-to-10.md   # Section 1, Steps 6 to 10
      03-submitter-form.md           # Section 2
      04-verdict-criteria.md         # Section 3
      05-evals-and-quality-check.md  # Section 4
      06-writing-rules.md            # Section 5
      07-answer-templates.md         # Section 6
      08-workspace-layout.md         # Section 7 - this file
      09-task-toml-reference.md      # Section 8
      10-solution-patch.md           # Section 9
      11-verifier-hardening.md       # Section 10
      12-common-mistakes.md          # Section 11
      13-reviewer-path.md            # Section 12 - the peer-review path, added 2026-08-11
      14-reviewer-workflow.md        # Section 13 - timed five-minute reviewer workflow plus one static extension
    skills/                          # One SKILL.md per .mdc above - keep every pair in sync
      sentinel-difficulty-scope/SKILL.md   # Same rules - Claude Code copy, keep in sync
      sentinel-task-check/SKILL.md
      sentinel-task-fixing/SKILL.md
      humanizer/SKILL.md             # Mandated by Step 9 and Step 10
      quality-rehearsal/SKILL.md     # Local Quality Check rehearsal before zipping
  bin/                               # Workspace scripts and the pre-upload check suite
    new-review.sh                    # Section 13 F0 bootstrap. Wraps new-task.sh --dest review_tasks,
                                     # then extracts the mandatory original task ZIP by contents into download/seed only
                                     # when an optional submitted ZIP is under review, and scaffolds the compact timed review task.md.
                                     # pristine extracts and every other tool here assumes one
    rezip.sh                         # Step 5 re-zip rule, in order, refusing to build when a gate fails
    checks/60-answers.sh             # lints answers/submission_answer.txt. Two of its checks exist because
                                     # a careful re-read demonstrably does not catch this class:
                                     #   answers.count-*      any count stated in more than one place must agree
                                     #   answers.graded-total any total-sized "N of N" in the prose must match
                                     #                        tests/config.json. Reads the config rather than
                                     #                        guessing wording, because the spelled-out figures
                                     #                        ("forty one of forty one") are the ones that survive
  docs/                              # Local export of the Sentinel Ultra Hub - source of truth
    guidelines.md  tasking-guide.md  harbor-framework.md
    reviewer-rubric.md               # The accept bar for BOTH sides, added by the 2026-08-13 export
    faq.md  glossary.md  quick-links.md  whats-new.md  changelog.md
    ALL_DOCUMENTATION.md
  learning/                          # Verified findings from real runs - submitter Step 1 reads all; timed reviews query candidates
    README.md                        # Index and note format
    bundles-i-accepted-as-reviewer.md # Bundles a review here ACCEPTED. A separate population from
                                     # accepted-bundle-reference.md. Section 13 F6 deferred maintenance
    calibration.tsv                  # One row per submitted TASK, 39 bundle-shaped columns
    review-calibration.tsv           # One row per peer REVIEW, legacy fields plus timed-workflow trailing fields. Section 13 F6
    static-checks.md                 # The 20 upload checks; hard 10–20 fail_to_pass range
    prescriptiveness-check.md        # Instruction scoring phase; library and internal-path rules
    tests-patch-vs-agent-edits.md    # tests.patch vs agent edits; invalid difficulty trials
    stale-test-reports.md            # Build-time test results faking pass_to_pass
    local-runs.md                    # Local oracle/NOP on this machine; filesystem pitfalls
    verify-in-the-image.md           # Checking in the built image what the bundle only claims
    unreachable-git-blobs.md         # Solution/test blobs surviving a clean-looking gc
    verifier-fail-open.md            # Reward 1.0 with a nonzero test-command exit
    solve-sh-idempotency.md          # Reverse-apply fallback undoing the fix on the 2nd oracle run
    quality-check-criteria.md        # The 15 must-have criteria; instruction findings block
    source-pr-cross-check.md         # Coverage findings that describe the PR; API paging trap
    dirty-repo-and-symlinks.md       # Dirty shipped tree, lost mode bits, zip -y
    raising-difficulty-on-a-wrapper-task.md  # When the API names ARE the deliverable
    diagnosing-platform-only-failures.md     # Two-strikes rule; evidence hierarchy
    accepted-bundle-reference.md     # The bundle that cleared every gate, measured
    <and any note added since>       # learning/README.md is the authoritative index, not this tree
  chat_transcripts/                  # Raw session transcripts kept for evidence
    alt.txt  cryspen.txt  jqno.txt  oliver.txt  cursor_etlcpp.md  revision.md  README.md
  comparison-report/                 # The audit that produced the current rule set
  AGENTS.md                          # Entry point for non-Claude agents
  CLAUDE.md                          # This file
  README.md                          # Workspace orientation
  INDEX.md                           # Cross-task register - one row per task, read at session start
  facts.yml                          # The settled facts, machine-readable
  prompts.md                         # Reusable prompt templates for the submitter
  .gitignore
  _archive/                          # Finished tasks moved here whole by Step 11, same folder shape.
                                     # Tracked in git; tasks/ is NOT, so this move is what makes a task recoverable
    20260719_045042__oliver-oloughlin_kvdex__245/   # Eight archived tasks live here, all accepted.
                                     # kvdex 245 is the longest-standing reference. READ-ONLY,
                                     # and the population every measured n= in Section 8 counts
    superseded/                      # Retired root documents (Sentinel_CLAUDE.md, res.md). TODO.md was
                                     # rewritten as root prompts.md; revision.md moved to chat_transcripts/
  tasks/                             # ONE FOLDER PER TASK - everything for a task lives together
    <Original Directory Name>/
      task.md                        # Record. Carries, in this order: the upload ledger, the
                                     # learning/ notes applied, the failure-signature strike
                                     # table, the handling-time ledger, then one block per round
      task_details.md                # The platform data block, pasted verbatim (Step 1.5)
      download/
        <submission_id>_submission.zip   # Exactly what the platform gave you. Its internal shape
                                     # varies - the five task entries may sit at the zip root or
                                     # under a wrapper such as task/ or seed/, and runs/ may or may
                                     # not be included (docs/harbor-framework.md, components list)
        original/                    # Pristine extract, NEVER edited, the diff target. ALWAYS
                                     # normalised to the flat five-entry shape below, whatever
                                     # wrapper the downloaded zip used
          instruction.md             # Problem statement given to the agent
          task.toml                  # schema_version + [environment] [agent] [verifier] [metadata] - see Section 8
          environment/
            Dockerfile               # Container build (only LISTED fixes allowed)
            problem_statement.md     # MUST be a byte-identical copy of instruction.md
            repo/                    # Real git checkout - NEVER edit tracked source files
          solution/
            solve.sh                 # Oracle solution
            golden.patch / init_state.patch  # Fix patch (init_state.patch = reverse form). OPTIONAL
          tests/                     # ONLY these four names are legal inside tests/
            test.sh                  # Verifier: applies tests, runs suite, writes reward
            tests.patch              # Fail-to-pass test patch (must apply at the base commit)
            config.json              # Harness run + grading config (fail_to_pass / pass_to_pass)
            grade.py                 # Allowed but usually absent - most tasks grade inside test.sh
            files/                   # DOES NOT SHIP. The static check allows only the four names
                                     # above inside tests/, and a files/ directory is rejected
                                     # even though older layout docs list it - see
                                     # learning/static-checks.md
        runs/                        # Agent trial logs when the bundle ships them. NEVER re-zipped
          <agent_name>/<timestamp>/
            result.json
            harborized__<id>/verifier/
              reward.txt             # 0 or 1
              test-stdout.txt        # Full test output - KEY for failure analysis
      work/                          # THE WORKING COPY - all edits happen here, same shape as original/
      upload/
        <Original Directory Name>.zip    # The bundle you re-upload
      answers/
        submission_answer.txt        # Form answers (Step 9)
  review_tasks/                      # ONE FOLDER PER REVIEW - Section 12 for what a finding is,
                                     # Section 13 for the order it happens in. Gitignored the same
                                     # way tasks/ is. Added 2026-08-11, when review stopped being
                                     # out of scope. NOTHING here has ever been archived, so all
                                     # review records are preserved by deferred Section 13 F6 maintenance
    <Original Directory Name>/
      task.md                        # Compact timed evidence record: timer, page evidence, gate, extension, tally, form-ready, deferred maintenance
      task_details.md                # The platform block AND the submitter's own answers, verbatim
      download/
        <seed_id>_submission.zip     # The task as ISSUED to the submitter, from the page's first
                                     # zip field (sample_review_page.md:62)
        <submission_id>_submission.zip  # What the submitter built, from the re-upload field (:141)
        seed/                        # Pristine extract of the SEED. NEVER edited, no commands
        original/                    # Pristine extract of the SUBMITTED bundle. NEVER edited
      work/                          # Static timed-review inspection only. A reviewer does
                                     # NOT edit. A change here is a probe and is recorded as one
      answers/
        review_answer.txt            # The Section 6 Path D template, seven questions
                                     # There is no upload/ - a reviewer ships no bundle.
                                     # bin/new-task.sh --dest review_tasks creates an empty one;
                                     # leave it rather than deleting it
```

Re-upload zip unpacks directly to `instruction.md`, `task.toml`, `environment/`, `solution/`, `tests/` - no `runs/`, no `task/` wrapper.

**Local oracle and NOP runs are submitter work or separately requested diagnostics, never timed-review work.** They use the session scratchpad rather than the workspace because `solve.sh` and `test.sh` mutate the measured tree. The workspace is on **ext4** as of 2026-08-04. See `learning/local-runs.md` when a diagnostic is explicitly requested.

**Starting a new review:** obtain the original task zip and current reviewer page, then run `bin/new-review.sh <original-zip> "<name>" --branch <branch> [--submitted <submitted-zip>] --go`. The original ZIP is always supplied. Fixable requires the submitted ZIP, Invalid/Not Fixable may carry one, and every other branch reviews the original ZIP directly. The bootstrap extracts the original into `download/seed/` only when a submitted ZIP is under review. Paste page evidence into `task_details.md`, add the Reviews row, and start the five-minute timer only when bootstrap and evidence are ready. Run `bin/preflight.sh --review-fast review_tasks/<name>/download/<reviewed>.zip`. Use `coverage-map.sh` only for a recorded coverage or faithfulness trigger. `local-run.sh`, Docker, Oracle, and NOP are not timed-review tools.

**Starting a new task:** create `tasks/<Original Directory Name>/{download,work,upload,answers}`, drop the downloaded zip in `download/`, extract the directory that holds `instruction.md`, `task.toml`, `environment/`, `solution/` and `tests/` to `download/original/`, paste the platform data block into `task_details.md`, then add a row to `INDEX.md`. That directory may be the zip root or a wrapper such as `task/` or `seed/` - packaging varies per `docs/harbor-framework.md` (the components list) and `docs/tasking-guide.md` quick start step 2 - so locate the five entries wherever they land and normalise `download/original/` to the flat shape above. Step 2 item 0 copies `download/original/` to `work/` before any command runs, and `download/original/` is frozen from that point on.
