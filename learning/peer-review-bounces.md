---
id: peer-review-bounces
status: reported
last_verified: 2026-08-01
verified_by:
  - "teslamotors/fixed-containers#67 (another EC's task)"
  - "foliojs/pdfkit#1002 (another EC's task)"
  - "d4vinci/scrapling#14 (another EC's task)"
  - "datarecce/recce#1399 (another EC's task)"
evidence: "Peer revision notes on four EC submissions that cleared every platform eval and were still sent back. Mined out of the retired Sentinel_CLAUDE.md section 9 on 2026-08-04"
applies_to:
  languages: [cpp, javascript, python, typescript, any]
  runners: [any]
  phases: [peer-review, fixing]
blocks_submission: false
fails_gate: [peer-review]
supersedes: []
contradicts: []
---

# What peer reviewers bounced on four submissions that passed every eval

**Provenance.** These come from another EC's revision notes on four tasks that are not in this
workspace: `teslamotors/fixed-containers#67`, `foliojs/pdfkit#1002`, `d4vinci/scrapling#14` and
`datarecce/recce#1399`. Every one of them cleared Static Checks, the Difficulty Check, the
Oracle Check and the Quality Check judge, sat in `REVIEW_PENDING`, and came back anyway.
Nothing here was reproduced on this machine.

They were carried in `Sentinel_CLAUDE.md` section 9, a predecessor manual that is now retired to
`_archive/superseded/`. That file mixed these with four rules this workspace has since disproved,
which is why the whole thing was pulled apart rather than kept. The disproved ones are recorded
in [LEDGER.md](LEDGER.md). What survived the check is below.

The general lesson is the one that repeats across every task here as well. **The evals grade
the task as declared. A reviewer reads what the verifier actually does.** A green board is not
evidence of a coverage floor, an honest matcher, or a clean repo.

## Instructions: name the graded API, not the recipe

**Name every public symbol the tests import.** If `tests.patch` imports
`ResponseEncoding.get_value`, calls `form.text(...)`, or references a TypeScript `RunType` by
name, the instruction has to state that contract. Scrapling's instruction described "a
standalone utility in the toolbelt" and an agent that picked a correct alternate name scored
zero on every fail-to-pass test. It matched `pass_at_k_* = 0/3`, which reads as a hard task and
was actually an unsolvable one.

**Do not name source paths or private helpers.** `include/fixed_containers/reflection.hpp`,
`for_each_field_entry` and "the mixin wiring under `lib/mixins/...`" are all navigation. The
behavioural ask plus the public API is enough. This is the same tension the two instruction
checkers create here, and the resolution is the same: cut until only the symbols the suite
calls by name are left, then stop.

**Say where a diagnostic surfaces.** If a test regexes an abort message, the instruction has to
say the wording lands in the assertion or process abort output rather than in a nearby comment.
The difficulty judges split on this for fixed-containers, which is a sign the instruction was
ambiguous rather than that the judges were.

**"Any equivalent wording" is a contract you have to honour.** fixed-containers said clear
equivalents were fine. An agent wrote "field count grows large enough", faithful to the
instruction, and `OverLimitDeathMentionsFieldLimit` still demanded the literal pair `field` and
`limit` within 40 characters. Either the matcher accepts the paraphrases or the instruction
stops promising flexibility. Make every example the instruction itself gives pass its own
matcher, or delete the example and re-sync `problem_statement.md`.

## Tests: distinct contracts, real coverage, no accidents

**Distinct behaviours, not padding.** Do not fill the fail-to-pass count with `EXPECT_LT(193, 194)`
tautologies or the same death regex reminted across many struct sizes. fixed-containers wanted
independent contracts: the ceiling constant, a live recursive count at the ceiling, a hostile
`operator&` on both count and field info, and the over-limit diagnostic. Four contracts, not one
contract four times.

**The hostile-delete gate, with the example that shows why a loose assertion is not coverage.**
pdfkit's form-level font registry fell from three fonts to one and all 16 tests still passed,
because the suite only grepped for `/DR` and `/DA` appearing somewhere in the PDF and field
dictionaries already carry both. Assert the **form-level** resource map after `doc.end`, not a
whole-document scrape. This is the same defect shape as a fixture that cannot violate the
constraint it names.

**Test the wiring, not only the helper.** If the PR's point is that engines stop crashing or
that `Response` now uses the resolver, at least one graded test has to build a `Response` or go
through the engine path. Scrapling had a perfect helper nobody called and a green suite.

**No serialization accidents.** Do not pin PDF object numbers (`10 0 obj`), absolute byte
offsets or creation-order ids. Assert dictionaries, parent and `Kids` links, action bodies,
resource membership, and observable values.

**Diagnostic matchers: prefer themes over literal pairs.** Compiler version, unit-test context,
field-count failure. A literal token pair inside a character window is how the fixed-containers
bounce happened.

## Oracle, git, Dockerfile and task.toml

**`solve.sh` forward-only and idempotent, mode 0755.** Never let `git apply -R` be a success
path. It inverts a correctly applied tree on rerun. Independently reproduced in this workspace,
so this one is no longer second-hand: [solve-sh-idempotency.md](solve-sh-idempotency.md).

**No working-tree "environment workaround" edits in the shipped repo.** recce deleted
`pytest-flake8` from `pyproject.toml` in the checkout to make the suite run. It looks like a
tracked source edit to a reviewer, because it is one. Environment pins belong in the Dockerfile
under the allowed-fix table.

**Bump timeouts when the real suite plus the image install cannot finish inside them**, and
record the change in Files Changed. recce needed it for DuckDB. The ceilings are in `CLAUDE.md`
section 8.

## Difficulty and scope

**Naming the API can flip a task to FAIL EASY.** Solvability fixes make the task easier by
construction. Re-check difficulty after them. If agents then one-shot it, expand PR-adjacent
scope, meaning the same PR intent plus additions: an extra engine handoff, re-exports, a Stage B
frontend contract, stricter outcomes. Scrapling grew a `StaticEngine` and re-exports; recce grew
Stage B TypeScript and a harder top-K. Never shrink or replace the PR.

**Good difficulty comes from multi-mechanism features, easy-to-miss wiring and hostile edge
cases.** Not from vague instructions and not from brittle object ids.

## Platform noise, and the bounce that follows a green board

**Infra exceptions are not task defects.** `ApiRateLimitError`, or a difficulty run coming back
7 of 8 valid, means re-run Check feedback. Scrapling was nearly rewritten for a rate limit.

**An early oracle 0/3 is usually packaging or a reverse-apply `solve.sh`, not a bad golden
patch.** Fix hygiene first, then re-run the oracle three times on fresh containers. See also
[solve-sh-under-sh.md](solve-sh-under-sh.md) for a third cause with the same signature, and
[platform-announcements.md](platform-announcements.md) for the rerun ladder.

**Read revision notes literally and do not re-open settled work.** pdfkit and fixed-containers
both came back with packaging and oracle already correct and one coverage hole left. When the
note says the packaging is fine, changing it costs a round and buys nothing.
