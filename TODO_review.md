I am working as a reviewer.

Use `.claude/rules/13-reviewer-path.md` for the form, evidence, and tally. Use
`.claude/rules/14-reviewer-workflow.md` for the timed path. The form-ready timer is five minutes,
with one recorded five-minute static extension at most. Keep the `humanizer` skill.

Reviews go in `review_tasks/<Original Directory Name>/`. Submitter tasks stay in `tasks/`.

## What to ask me for before the timer

1. The original task zip, which is always supplied.
2. The selected submission branch and current reviewer page or a complete paste of it: submitter answer,
   Comments for Reviewer, rebuttal, prior reviewer feedback when shown, all evaluation panels, counters,
   and the maximum-revisions state.
3. The submitted zip only when the branch supplies one: required for Fixable, optional for Invalid/Not Fixable, and absent for Valid-as-is, Invalid Difficulty, and every other branch.

Do not say something is unavailable without saying what was requested or checked.

## Timed review

```bash
bin/new-review.sh <original-zip> "<name>" --branch <branch> [--submitted <submitted-zip>] --go
bin/preflight.sh --review-fast review_tasks/<name>/download/<reviewed>.zip
```

- Start the timer after bootstrap and page evidence are ready.
- Before new review work, turn every `Reviewer Feedback` item from the page into a current checklist
  marked fixed, partial, still open, or not assessed. Resolve it against current evidence first.
- Then read only the directly relevant instruction, problem-statement copy, task metadata, solution,
  tests, submitter claim, and panel evidence for newly remaining issues.
- Do not routinely run Docker, Harbor, Oracle, NOP, a local verifier, containers, mutation probes, or a
  stock battery. Platform evaluation already ran before reviewer assignment.
- Take one extra five minutes only after recording an artifact/panel identity conflict, a concrete
  claim or feedback contradiction, a direct Major or PR-scope signal, or a named coverage/faithfulness
  discrepancy. The extension is static-only.
- At five minutes without a trigger, or ten minutes after one extension, keep confirmed findings only.
- Apply the published tally. Invalid Difficulty is not an automatic Accept.

Answer the applicable live form branch, read and acknowledge rebuttal, record actual elapsed minutes,
then run `humanizer` over the completed reviewer-facing prose. The answer is form-ready after that.

## After form-ready

After the document exists, first study prior reviewer-feedback writing if it was present and record one
evidence or clarity lesson without copying boilerplate. Second, when this verdict is Accept, update
`learning/` from the task through `learning/bundles-i-accepted-as-reviewer.md` and any genuinely new
learning note. Third, append the exact platform review UUID once to root `review_tally.md`. Fourth,
after matching sha256 confirms the retained `review_tasks/<name>/download/` copies, delete only the
the original ZIP copy and any supplied submitted ZIP copy sitting directly in the workspace root. Keep retained downloads,
archives, and `logs_artifact.zip`. Then update the concise record, INDEX row, calibration data, and
archive status. Do not delay the answer for these steps.

## Task details

ORIGINAL TASK ZIP:

SUBMITTED TASK ZIP, IF SUPPLIED:

REVIEWER PAGE:
