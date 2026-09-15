---
id: patch-forward-skips-colliding-creates
status: locally-verified
last_verified: 2026-08-19
verified_by:
  - 20260801_211601__ggrossetie_asciidoctor-web-pdf__79 (peer review)
evidence: "With an agent-written file at a path tests.patch creates, patch -p1 --forward exits 0 while skipping that create, so test.sh counts the patch as applied and the graded suite never lands"
applies_to:
  languages: [any]
  runners: [any]
  phases: [peer-review, fixing]
blocks_submission: true
fails_gate: [peer-review]
supersedes: []
contradicts: []
---

# `patch -p1 --forward` turns a loud collision into a silent partial apply

The stock `test.sh` apply trio is `git apply`, then `git apply --3way`, then `patch -p1 --forward`,
and it treats success on any of the three as APPLIED. LEDGER **L71** (mithril.js 2021) recorded that
all three routes fail when the agent has created a file the patch also creates. The sharper half,
measured on the asciidoctor-web-pdf 79 peer review (2026-08-19), is what the third route does:

```
agent file at test/pdf_test.js (the path tests.patch creates):
  git apply          exit 1   "already exists in working directory"
  git apply --3way   exit 1
  patch -p1 --forward  exit 0  "The next patch would create the file test/pdf_test.js,
                               which already exists!  Skipping patch.  1 out of 1 hunk ignored"
```

`patch` applied the four fixture creates, skipped the graded file, and **exited 0**. So `test.sh`
sets APPLIED=1, runs the suite, and every graded id in the skipped file reports missing. The agent
scores 0 with the feature complete, and the report reads as a merit zero rather than as the
`infrastructure_error: tests.patch did not apply` that the two git routes would have produced.

Two consequences:

- **The collision probe is not finished when the git routes fail.** Run the `patch(1)` route too and
  read its exit code. A skip with exit 0 is the worse outcome, because the platform sees an invalid
  score on a valid solution with no infra marker to appeal to.
- **The remedy is unchanged and still mandatory**: restore the create list out of the patch itself
  (`sed -n 's|^+++ b/||p' /tests/tests.patch`) before applying, per
  `.claude/rules/11-verifier-hardening.md` Section 10.3, and prefer a task-prefixed name for any
  graded file whose path follows repo convention. The graded path here was the conventional name
  for tests of the feature and the exact path the upstream PR itself used, which is what makes the
  collision plausible rather than theoretical.

Related: LEDGER **L71** (the three-route failure on mithril.js 2021), LEDGER **L9** (a create
conflicts with a file the agent wrote itself), `learning/tests-patch-vs-agent-edits.md`.
