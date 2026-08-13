---
id: mock-standing-in-for-the-deliverable
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260805_080500__hyperledger-firefly_firefly__1123
evidence: "Agentic judge returned DISCUSS twice on the same task naming this shape; the second report described three implementations that all scored 1.0 against the shipped bundle"
applies_to:
  languages: [any]
  runners: [any]
  phases: [step-5, quality-check, fixing]
blocks_submission: true
fails_gate: [quality-check, review-gate-agentic-judge]
---

# A mock of the thing you are grading is not coverage of it

When the deliverable is a method on subsystem A, and every graded test reaches it through
subsystem B where A is mocked, **nothing grades A**. The mock returns whatever the test told it
to return, so the assertions downstream pass for any implementation of A, including one that
does nothing. The suite looks well covered because a real call chain runs and real assertions
fire. They are just all downstream of the substitute.

This is easy to ship because the mocking is correct engineering everywhere else. Testing B in
isolation *should* mock A. The defect is only that no test also drives A directly, and a
requirement-to-test mapping does not catch it, because the requirement genuinely is exercised
by name in a test file.

## What it cost

firefly 1123 shipped four rounds this way. `instruction.md` states two new contracts manager
methods as deliverables. Every graded assertion on them ran through `internal/assets`, whose
own test helper mocks the contracts manager out. The agentic judge blocked the task twice on
this shape, and the second report named three implementations to check:

| Implementation the judge described | Score before the fix |
|---|---|
| the method lookup ignores which interface it was handed | 1.0 |
| the method lookup returns nothing at all | 1.0 |
| resolution stops filling the id into the reference | 1.0 |

All three now score 0.0 and each names the new test.

## The check, and it is cheap

For every subsystem the instruction names as carrying behaviour, ask whether a graded test
constructs a **real** instance of it. Not whether the subsystem is mentioned, and not whether a
mock of it is configured.

```bash
# does any graded test build a real instance, or only a mock of the thing under test?
python3 - <<'PY'
import io,re
added='\n'.join(l[1:] for l in io.open('tests/tests.patch',encoding='utf-8',errors='replace')
                if l.startswith('+') and not l.startswith('+++'))
for name,(real,mock) in {
  'contracts manager': (r'newTestContractManager|contractManager\{', r'contractmocks'),
  # one row per subsystem the instruction names, using the repo's own constructor names
}.items():
    r=len(re.findall(real,added))
    print(f'{name:22} real instances {r} {"<-- GAP" if not r else ""}  mock refs {len(re.findall(mock,added))}')
PY
```

Pair it with the symbol sweep, which catches the same gap from the other side: list every
exported symbol `golden.patch` adds and check which the graded tests never name.

```bash
grep -oP '^\+func (?:\([^)]*\) )?\K[A-Z]\w+(?=\()' solution/golden.patch | sort -u
```

## A symbol the tests never name is not automatically a gap

Run the sweep, then read each hit against the instruction before writing a test for it. On
firefly 1123 the sweep returned one ungraded exported method, `GetFFIEvents`. The instruction
mentions it **zero** times, because the PR adds it as a refactor pulling an existing inline
store call out into a method. Grading it would have been the `Overreach` auto-REMOVE pattern
and a faithfulness finding, so the correct action was to leave it and say why. The behaviour it
rewires was already covered by four pre-existing tests that run inside the graded command, and
therefore under the exit-code gate, without being named in `pass_to_pass`.

So the sweep produces a list to **judge**, not a list to grade. Two outcomes are legitimate:
the instruction states it and nothing drives it, which is a real gap, or the instruction never
states it, which means it stays ungraded and the reasoning goes in Comments for Reviewer.

## Prove the fix by capturing, not by trusting

The natural way to assert "the lookup was scoped to the interface it was given" is to set an
expectation on the mocked store and let the mock framework verify the call happened. That
proves a call was made with *something*. Capture the argument and read it back instead:

```go
var scoped ffapi.Filter
mdb.On("GetFFIMethods", context.Background(), "ns1", mock.Anything).
    Run(func(args mock.Arguments) { scoped, _ = args[2].(ffapi.Filter) }).
    Return(expected, nil, nil)
// ... call under test ...
info, err := scoped.Finalize()
assert.NoError(t, err)
assert.Contains(t, info.String(), interfaceID.String())
assert.NotContains(t, info.String(), otherID.String())
```

The `NotContains` half is what makes it discriminate. Without it, a lookup that queries for
every interface in the namespace still passes.

## Related

- [[quality-check-criteria]] for the criteria that block on their own
- [[probe-the-instruction-you-already-wrote]] for the same failure found from the instruction side
- [[source-pr-cross-check]] for when a coverage finding describes the PR rather than your tests
