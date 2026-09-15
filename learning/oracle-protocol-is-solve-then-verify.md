---
id: oracle-protocol-is-solve-then-verify
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260723_030152__mithriljs_mithril.js__2021
  - 20260717_182400__felixguendling_cista__172 (same mechanism, recorded under defect 6)
evidence: "solve.sh three times in one container returned 3/3. The real protocol, solve.sh THEN test.sh three times in the same container, returned 1 of 3, because test.sh applies tests.patch every run and restores nothing. Independently measured on cista 172 and recorded there under a different defect heading"
applies_to:
  languages: [any]
  runners: [any]
  phases: [oracle, local-runs, peer-review]
blocks_submission: true
fails_gate: [oracle]
supersedes: []
contradicts: []
---

# Running `solve.sh` three times is not the Oracle Check

## The gap

`.claude/rules/01-workflow-steps-1-to-5.5.md` Step 5.5 says to **"Run `solve.sh` three times in one
container, because the platform does"**, and `learning/solve-sh-idempotency.md` is written entirely
about a non-idempotent `solve.sh`. Both are correct and both are about the oracle **script**. The
Oracle Check is not about the script. `.claude/rules/05-evals-and-quality-check.md` says the platform
"runs the golden solution **three times**", and running the golden solution means `solve.sh` and then
the verifier, because a run with no verifier produces no reward to be 3/3 of.

So a bundle can have a perfectly idempotent `solve.sh`, pass the three-apply replay, and still score
below 3/3, because the thing that is not idempotent is **`test.sh`**.

## Measured, mithril.js 2021, 2026-08-11

`solution/solve.sh` on this bundle is the correct shape. It probes with `git apply -R --check`, never
reverse-applies, and reports `golden.patch already applied; no-op`. Three consecutive `solve.sh` runs
in one container are clean. The peer review recorded that as "Oracle x3 in one container, 3/3 at
reward 1.0" and put it in the paragraph of things that are **right** about the bundle.

The real protocol, in one container:

```
cycle 1  solve_exit=0  test_exit=0  reward=1  infrastructure_error None
cycle 2  solve_exit=0  test_exit=2  reward=0  infrastructure_error tests.patch did not apply
cycle 3  solve_exit=0  test_exit=2  reward=0  infrastructure_error tests.patch did not apply
```

**1 of 3.** `test.sh` applies `tests/tests.patch` on every invocation and restores nothing first, so
the second apply lands on a tree that already carries the patch. `solve.sh` is blameless. The oracle
script and the oracle **result** have different owners, and only one of them was being measured.

## The workspace already knew, one file over

This is not a new mechanism. It was written down the same day, in
`learning/stock-bundle-defect-baseline.md`, in the cista 172 column: **defect 6, no test-tree restore,
"And it is what makes run 2 of the oracle report `tests.patch did not apply`"**. The mithril review
marked that same defect 6 **Present** on its own bundle and did not draw the consequence, because on
mithril defect 4 was **Absent** and a clean `solve.sh` reads as a clean oracle.

That is the more useful version of this note. The failure was not missing knowledge, it was a
mechanism filed under the heading of a *different* defect. Defect 6 lives under agent collisions in
Section 10.3, so a reviewer checking the oracle never looks there.

## Why nobody caught it

The two halves were both in the evidence record and were never joined. `task.md:56` said 3/3. Eighty
lines later `task.md:89-93` recorded `test.sh` run three times in one container giving `1, 0, 0` with
`infrastructure_error`, and the review's own note 9 mentioned it in a closing sentence and hedged it
away with "whether that last one matters depends on whether the three oracle runs share a container,
which I could not establish". Two true measurements, one obvious conclusion, and a favourable headline
sitting on top of it.

The hedge is the tell. **Uncertainty about whether the platform reuses a container is not a reason to
report the optimistic half.** Report the protocol you actually ran, and if you did not run the
combined one, say that rather than quoting an oracle number.

## The rule

- **The oracle battery cycle is `solve.sh` then `test.sh`, three times, in one container.** Record all
  three rewards from the combined cycle. A three-apply replay of `solve.sh` alone is a separate and
  weaker check, and it must not be reported as an oracle result.
- **A missing restore in `test.sh` is an Oracle Check defect, not only an agent-collision defect.**
  `learning/tests-patch-vs-agent-edits.md` frames the restore as protection against agent edits. It is
  also what makes the verifier re-runnable. On a bundle with no restore, run the cycle twice before
  believing any 3/3.
- **On the reviewer path this belongs in the run list**, because it is cheap and it decides a
  pre-submit gate condition the submitter cannot see from a green single run.
- Confirming the fix is the same command. With a base64 payload restore plus a delete list read from
  the patch itself (`sed -n 's|^+++ b/||p'`), the same three cycles returned reward 1 on all three.

## What this does not say

It does not say `solve.sh` idempotency stops mattering. A reverse-applying `solve.sh` inverts a correct
tree on run two and is still the classic `1/3` and `2/3` signature (`learning/solve-sh-idempotency.md`).
This note adds a second, independent mechanism with the same signature, sitting one file over, and the
`0/3` versus `1/3` arithmetic in `.claude/rules/05-evals-and-quality-check.md` does not distinguish
them. When a platform Oracle Check comes back below 3/3, check both.

## The workspace's own tool implements the refuted shape (added 2026-08-18, LEDGER L102)

`bin/local-run.sh` is the disposable NOP and oracle battery, and its five rows are `nop`, `oracle`,
`agent-edit`, `collision` and `thrice`. Read `thrice` before trusting it:

```
bin/local-run.sh:268-272   thrice)  for i in 1 2 3; do bash /solution/solve.sh ... done
bin/local-run.sh:341                bash /tests/test.sh; echo "LOCALRUN_TEST_SH_EXIT=$?"
```

That is `solve.sh` three times and then `test.sh` **once**, which is exactly the weaker check this
note exists to separate from the real protocol. **No row in the tool runs `solve.sh` then `test.sh`
three times**, so a fully green matrix has measured no oracle protocol at all. The row's own header
comment makes it worse rather than better, because it says "the platform runs the oracle 3 times and
needs 3 of 3" right beside it, which is the sentence that makes a reader take the row for the
covering check.

Run the protocol by hand until the tool is fixed: three cycles of `solve.sh` **then** `test.sh` in
one container, reading the reward after each cycle.

**Why it survived.** The tool is dated 2026-08-04 and this note was written 2026-08-11, so the rule
landed a week after its tooling and nobody went back through `bin/` to see what still implemented the
old shape. That is LEDGER **L93** in a different costume: there, a reverted `bin/rezip.sh` shipped a
broken zip while reporting PASS, because the check it had lost went with it. The habit both point at
is the same one. **When a rule changes, grep `bin/` for the refuted version before the next round
relies on a green tool.**
