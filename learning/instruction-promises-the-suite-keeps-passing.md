---
id: instruction-promises-the-suite-keeps-passing
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260720_144200__thomas4019_expressa__132
evidence: "Base repo suite 117 passing / 0 failing; after golden.patch and before tests.patch, 113 passing / 4 failing, all in the file instruction.md tells the agent must keep passing"
applies_to:
  languages: [any]
  runners: [mocha, pytest, gradle, cargo, any]
  phases: [analysis, peer-review, verification]
blocks_submission: true
fails_gate: [difficulty]
supersedes: []
contradicts: []
---

# The instruction does not have to order a test edit to force one

`CLAUDE.md` pre-upload item 14 catches an instruction that **tells** the agent to edit a path
`tests.patch` also writes to. elfuse 162 is that case, and the check is a grep. expressa 132 is the
same disaster reached by an inference chain the grep cannot see, and it is the more common shape
because nobody writes it on purpose.

## The chain

`instruction.md:9` ended with:

> the existing `test/0-install.js` and `test/users.js` suites must keep passing

Nothing there orders an edit. It promises a property. The problem is that the property is **false**,
and the instruction's own requirements are what make it false:

| Tree state | Repo's own suite |
|---|---|
| base commit | **117 passing, 0 failing** |
| after `golden.patch`, before `tests.patch` | **113 passing, 4 failing** |

All four failures are inside `test/users.js`. Two because the instruction requires the login error
strings to change while the shipped test still asserts the old ones. Two because `golden.patch` adds
a field to a helper the users schema rejects under `additionalProperties: false`. Only
`tests/tests.patch`, which the agent never sees, repairs them.

So a compliant agent implements the change, watches four pre-existing tests go red, reads a sentence
telling it those tests must be green, and does the only thing available. It edits `test/users.js`.
Which is a file `tests.patch` also writes to.

**The general form. Any sentence promising that a named pre-existing test file keeps passing is a
forced edit whenever the required change breaks that file.** The instruction never has to say
"edit". It only has to make the edit the sole way to satisfy what it said.

## The check, which is a run and not a grep

Item 14's grep finds the elfuse shape. This one needs the measurement, and it is two commands:

```bash
# in a disposable container, on the extracted zip
bash /solution/solve.sh                       # golden only, do NOT apply tests.patch
<the repo's own full test command>            # e.g. npx mocha --exit, pytest, ./gradlew test
```

Compare against the same command at the base commit. **Any test that is green at base and red after
golden-without-tests.patch is a forced edit**, and every file holding one is a collision surface.
The count is the finding: 0 is clean, 4 is expressa.

This belongs beside the NOP and oracle runs in the Step 5.5 battery, because it costs one extra
invocation of a command already being run and it catches something no static check can.

## What it costs, measured

Correct solution applied in every row, base reset between rows, `--network none`:

| Agent behaviour | reward | outcome |
|---|---|---|
| touched no test file (control) | 1.0 | 21/21 pass |
| **fixed the stale expectation, left unstaged** | 0.0 | **INVALID TRIAL**, `tests.patch did not apply` |
| fixed it, staged | 1.0 | 21/21 pass |
| fixed it, staged and committed | 1.0 | 21/21 pass |
| **fixed both stale expectations, unstaged** | 0.0 | **INVALID TRIAL** |
| appended its own test to `test/users.js` | 1.0 | 21/21 pass |
| added a test to `test/0-install.js` | 1.0 | 21/21 pass |
| **created its own `test/login-collections.js`** | 0.0 | **INVALID TRIAL** |
| formatter stripped trailing whitespace in `test/` | 1.0 | 21/21 pass |
| **deleted the two stale assertions** | 0.0 | **INVALID TRIAL** |

`task.toml` records `pass_at_k_opus_4_8 = "0/3"` and `pass_at_k_gpt_5_5 = "0/3"`. A defect that
converts the single most likely compliant behaviour into a harness failure is a plausible part of
that, and it means the recorded difficulty is not measuring difficulty.

## The asymmetry is the opposite of the one already recorded, so test all three states

`tests-patch-vs-agent-edits.md:594` says to test a restore step **"with the agent's work STAGED and
COMMITTED, not just dirty"**, because on kvdex 245 an unstaged-only simulation proved nothing and
the staged case was where it broke.

expressa runs the other way. **Unstaged fails and staged passes.** `/app` is a real git repository at
verify time (`COPY repo/ .` with no `.dockerignore`), so `git apply --3way` has an index to merge
against. With the edit staged, the index carries the agent's content and the three-way merge
resolves. With it unstaged, the index still holds the base blob while the worktree has moved, and
both the plain apply and the `--3way` fail.

Neither direction is the rule. The rule is that **an agent edit has three states and any one of them
can be the failing one**, so a simulation that tests fewer than three is not evidence. Unstaged is
also the state to weight most heavily, because kvdex's own difficulty artifact showed **no agent
staging or committing anything** (`tests-patch-vs-agent-edits.md:269`).

## The fixes, in the order they close the most

1. **Delete the sentence.** Say instead that behaviour outside the described change must not regress.
   It costs nothing and it removes the forcing function.
2. **Restore the test tree in `tests/test.sh` before applying `tests.patch`**, from a base64 payload
   embedded in `test.sh` and never from git. This is the only fix that survives an agent doing
   something you did not predict.
3. **Give the graded tests their own file with a prefix no agent would choose.** expressa's new graded
   file is `test/login-collections.js` on a task whose instruction says "login collections"
   throughout, and an agent creating that exact filename was measured as an invalid trial.

## For a reviewer

This is worth leading with when it is present, because it is measured, it is cheap to reproduce, and
it explains a bad pass rate without any appeal to difficulty. Report the base-versus-golden test
counts, the agent matrix, and the three fixes together. Do not report the pass rate as evidence of
anything until the forced edit is gone.
