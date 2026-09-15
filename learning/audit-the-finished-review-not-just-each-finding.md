---
id: audit-the-finished-review-not-just-each-finding
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260723_030152__mithriljs_mithril.js__2021
evidence: "An adversarial pass over a finished 11-note review answer left 1 note CONFIRMED and 9 WEAKENED, found two new blocking findings nothing in the review had run, and found two remedies that would have sent the submitter backwards"
applies_to:
  languages: [any]
  runners: [any]
  phases: [peer-review]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts: []
---

# A review that passed every per-finding check still fails an audit of the finished answer

## What happened

The mithril.js 2021 peer review was built carefully. Every finding had a file and a line, five were
measured in a container, an 8-dimension fan-out produced 77 candidates and adversarial verification
refuted 40 of them before anything was written, and four more were filed and withdrawn with reasons.
That is the discipline `learning/reviewer-findings-need-a-baseline.md` asks for and it was applied.

An adversarial pass over the **finished document**, one skeptic per note plus five ground-up sweeps,
returned this:

| Outcome | Count |
|---|---|
| Note confirmed exactly as written | 1 of 10 |
| Note weakened, real defect but something in the wording wrong | 9 of 10 |
| Note refuted outright | 0 of 10 |
| New findings the review never ran a check for | 2, both blocking |
| Remedies that would have made the bundle worse | 2 |

Nothing was wrong about **whether** a defect existed. Everything that was wrong was in the second
sentence of each note. That is the argument for the audit being a separate pass rather than more care
during the first one, because per-finding rigour is exactly what was already being applied.

## The five error classes, in the order they cost the most

**1. A baseline measured against the wrong tree, twice, in a document that gets it right elsewhere.**
Note 10 said "the five bundles I compared against all carry `os = linux`" and note 7 said "five other
bundles ship both scripts at 0755". Both were measured against `_archive/*/work/`, which is five other
submitters' rewritten output. Against `_archive/*/download/original/` the counts are 0 of 5 and 0 of 7.
This is LEDGER **L61** verbatim, filed on expressa 132 on the same day, and the same document applies
the correct framing eleven lines later in its closing note. **So the technique was present and the
document still shipped two instances.** A rule you know is not a check you ran.

**2. A remedy that contradicts another note in the same answer.** Note 9 asked for the graded tests to
be moved into their own file. Note 11 said the opposite about the same tests, that hoisting them out
would deviate from source and to keep them. Measured cost of following note 9: 6 of the 15 graded ids
are two tests nested in a `components.forEach`, so relocation collapses them to 2, takes the graded
count to 11, rewrites every one of those id strings, and breaks the byte-for-byte PR match the answer's
own opening paragraph is built on. It also buys nothing, because the corrected restore closes the same
failures on its own.

**3. A remedy that is right but scoped short, described as complete.** Note 1's restore covered
`render/tests`, `ospec` and `test-utils` and claimed "that one change also fixes note 9". Measured
false. `tests.patch` creates `ospec-json-runner.js` at the **repo root**, outside every directory in
that list, so an agent file at that path still breaks all three apply routes. The delete list has to be
read out of the patch (`sed -n 's|^+++ b/||p'`), not written as a fixed directory list. A submitter
following the note would have declared note 9 closed and reopened it a round later.

**4. A number that appears only in the answer and nowhere in the evidence.** Note 5 said the
instruction "scores fourteen" on a leakage count where the accepted bundles score zero. The
instruction is 11 lines long, no unit is stated that produces 14, and the figure is in no measurement
anywhere. This is LEDGER **L53** on the reviewer side. The finding was strong and the invented
precision was the weakest thing in it.

**5. A mechanism explained by the wrong cause.** Note 9 said five agent edits survived "because /app
really is a git repository at verify time so the `git apply --3way` fallback absorbs them". Deleting
`/app/.git` outright and re-running still scored 15 of 15. The real reason is that none of those edits
touches a line `tests.patch` has context on, so the **plain** apply succeeds and the fallback is never
reached. The claim had been carried across from expressa 132, where it is true, and it does not
transfer.

## The two blocking findings nobody ran a check for

Both were cheap, both are standing rows somewhere in this workspace, and neither had been run.

- **`sh /tests/test.sh` writes no reward file at all.** Every run in the original pass and in all five
  verification sweeps used `bash`. `/bin/sh` is dash on `node:20-slim`, `test.sh:9` is
  `set -uo pipefail` which dash rejects, and that line sits **before** the `trap` on line 25 that
  exists to guarantee a reward file. Exit 2, `/logs/verifier` never created, nothing written. This is
  LEDGER **L56** and `learning/solve-sh-under-sh.md`, which carries `blocks_submission: true`. It
  compounds with the note about script modes, which the same review filed without connecting them: the
  scripts ship `0644`, so the harness cannot exec them by shebang and has to pick an interpreter.
- **The oracle protocol scores 1 of 3.** `solve.sh` then `test.sh`, three cycles, one container. The
  review had run `solve.sh` three times, which is a different and weaker check, and reported 3/3 in
  its paragraph of things that are **right**. Full write-up in
  `learning/oracle-protocol-is-solve-then-verify.md`.

Neither was unknown to this workspace. The dash hazard is LEDGER **L56** with its own note carrying
`blocks_submission: true`, and the oracle mechanism was written down the same day in
`learning/stock-bundle-defect-baseline.md` under cista 172's **defect 6**. Both were filed under a
heading a reviewer checking something else does not open. **A standing row you never execute is
indistinguishable from a rule you never had**, which is why check 5 below is about the run list.

## The rule

Run these over the **finished answer**, as a separate pass, after every finding has already passed its
own checks:

1. **Grep your own document for baseline claims.** Any sentence of the form "N other bundles do X".
   Confirm which tree each was measured against and say so in the sentence. `download/original/` or it
   does not go in.
2. **Read the remedies against each other.** Every `What to do.` line, in one pass, asking whether any
   two of them ask for opposite things about the same file. Two notes that are individually right can
   still be jointly impossible.
3. **Re-derive every number from the live bundle**, not from the evidence record and never from an
   earlier draft. A number you cannot reproduce on demand comes out, and the citations behind it carry
   the finding perfectly well without it.
4. **Check each stated mechanism by removing it.** Before writing "X survives because Y", delete Y and
   re-run. This is LEDGER L5 and L10 applied to a review instead of to a defect.
5. **Walk the run list rather than the finding list.** Ask which invocations were never tried, not
   which findings were never written. Two blocking defects here sat behind `sh` and behind a
   solve-then-verify cycle, and no amount of re-reading the notes would have surfaced either.

## What it does not mean

It does not mean fewer findings, and it does not mean hedging. Every one of the ten notes survived as a
real defect and the verdict and the score did not move. The corrected answer is longer, more specific
and more useful, and two of its strongest notes did not exist before the audit. The cost of the audit
is one pass; the cost of skipping it is a submitter who checks the first baseline sentence, finds they
never touched the field, and discounts the rest of the page.
