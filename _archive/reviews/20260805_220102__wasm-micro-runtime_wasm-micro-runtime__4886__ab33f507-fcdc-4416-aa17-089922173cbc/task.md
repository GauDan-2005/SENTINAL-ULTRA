# Peer review - 20260805_220102__wasm-micro-runtime_wasm-micro-runtime__4886

## Review timer
Track: timed-static-v1
Review UUID: ab33f507-fcdc-4416-aa17-089922173cbc
Started: 2026-08-19T12:23:37Z
Base deadline: 2026-08-19T12:28:37Z
Extension used: direct Major signal at 2026-08-19T12:25:01Z. The static gate found a dirty checkout and missing Git archive directory entry. The extension confirmed the specific archive and file facts without running a container or verifier.
Form-ready: 2026-08-19T12:30:14Z
Actual elapsed: 6 minutes 37 seconds

## Evidence reviewed
Submitted zip: 4e2fdfd9-59a3-4e50-b513-c2300b5e2399_submission_2026-08-16T19_00_50.678Z.zip, sha256 675d1c046b772c1c
Seed zip: 35924bc2-ee3a-4522-89e4-f24219e6aec0_submission.zip, sha256 75b1e1eb98221962
Reviewer page: complete current paste received. Read the Fixable answer, Files Changed, PR additions, Comments for Reviewer, previous reviewer feedback, difficulty counters, all evaluation panels, and maximum-revisions state. The page contained no separate rebuttal comments panel and no maximum-revisions dialog.
Panels: Static Checks passed. Difficulty PASS MEDIUM with 2 of 4 codex-gpt-5-5 runs. Agentic Judge OK. Oracle PASS 3 of 3. NOP PASS 0 of 1. Quality Check 15 of 15.

## Fast static gate
FAIL 10-static: task.toml has no environment os value and repo_license is empty.
FAIL 20-git: repository has one tracked deletion at product-mini/platforms/linux-sgx/enclave-sample/Enclave/Enclave_private.pem.
FAIL 30-package: the archive lacks the environment/repo/.git/refs directory entry and includes three VSCode extension .vscode files.
Observation: 40-grader reported a pipefail issue. config.json starts its only command with set -uo pipefail and the command contains no pipeline, so this was not counted.

## In-depth extension
Trigger: direct Major or scope signal from the dirty repository and missing Git archive directory entry.
Question: confirm the archive and repository facts, their narrow remedy, and whether the grader warning is real.
Static results: instruction.md line 3 and line 5 no longer give header paths or declared-next-to advice. environment/problem_statement.md matches it. tests/tests.patch creates only three files. GitHub PR 4886 lists every non-test path in golden.patch, including .gitignore. task.toml line 11 has repo_license = "" and its environment block omits os. test.sh lines 151 to 153 invoke bash without pipefail, but config.json line 5 sets pipefail before the command and the command has no pipeline.
Result: prior instruction feedback is resolved. The dirty checkout, incomplete metadata, and missing archive directory entry remain actionable. The grader warning is only an observation.

## Rubric tally
1. Confirmed Major. Pillar 5. Fixable. The submitted repository is dirty because a tracked file is deleted from the declared base checkout.
2. Confirmed Minor. Metadata completeness. Fixable. task.toml omits environment os and has an empty repo_license despite the Apache license file.
3. Confirmed Minor. Package construction. Fixable. The archive was built with -D and lacks the Git refs directory entry.
Observation only. The VSCode extension .vscode paths may be tracked project material, so they were not treated as a defect.
Observation only. The preflight pipefail warning does not match the actual command shape.
Verdict: Needs Revision from one confirmed Major. Score: 2.

## Form-ready
review_answer.txt written and humanized. Reviewer-facing paste checks passed for prohibited vocabulary, scoring language, en and em dashes, and wrapped prose.

## Deferred maintenance
Previous-feedback writing lesson: the earlier reviewer quoted the exact instruction sentences and named the smallest safe correction. That made it possible to verify the fix quickly without reopening the resolved issue.
Review UUID ab33f507-fcdc-4416-aa17-089922173cbc appended once to review_tally.md.
Added a timed-static row to learning/review-calibration.tsv and a review-submitted row to INDEX.md.
The platform submission was reported by the user on 2026-08-19. Archive remains deferred until the platform records the outcome.
