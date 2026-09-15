---
id: child-process-negative-tests-need-a-reason
status: locally-verified
last_verified: 2026-08-18
verified_by:
  - 20260806_080603__tair-opensource_redisshake__657
evidence: "A graded test naming four corrupt-stream contracts was measured to enforce only two. Removing the opcode guard from both readers it names still scored 14 of 14 at reward 1, because the test asserts only that the child process exited non-zero and both fixtures are truncated, so an unguarded reader dies on the short read anyway"
applies_to:
  languages: [go, python, any]
  runners: [go-test, pytest, any]
  phases: [verifier-design, peer-review, fixing]
blocks_submission: true
fails_gate: [quality-check, peer-review]
supersedes: []
contradicts:
  - "the reading that a re-exec-the-test-binary negative test is covered once it exists, because the hard part was the plumbing"
---

# A child-process negative test proves the child died, not why

Section 10.9 of `.claude/rules/11-verifier-hardening.md` says how to grade an error path that ends in
`os.Exit` or `log.Panicf`: re-exec the test binary as a helper process, gate the helper on an
environment variable, and read the result out of the child. That is correct and it is the hard part
to get working, which is exactly why it is where the attention stops. The assertion at the end of it
is one line and nobody reads it twice.

**The one line is usually `the child exited non-zero`, and that is a much weaker claim than the test's
own name.**

## Measured on redisshake 657, 2026-08-18

`internal/rdb/types/tair_negative_verifier_gen_test.go` is a single graded id,
`RedisShake/internal/rdb/types::TestNegativeCases`, and its own table names four contracts:

```go
for _, tc := range []struct{ name, env string }{
    {"opcode mismatch on unsigned field", "SENTINEL_CORRUPT_OPCODE"},
    {"opcode mismatch on string field",   "SENTINEL_CORRUPT_STRING"},
    {"non-zero end-of-value terminator",  "SENTINEL_CORRUPT_EOF"},
    {"unsupported module name",           "SENTINEL_MODULE_DISPATCH_CRASH"},
} {
    sub := exec.Command(os.Args[0], "-test.run=^TestNegativeCases$")
    sub.Env = append(os.Environ(), tc.env+"=1")
    err := sub.Run()
    if ee, ok := err.(*exec.ExitError); !ok || ee.Success() {
        t.Fatalf("%s should abort the load with a non-zero exit, got err=%v", tc.name, err)
    }
}
```

Two of the four cannot fail. Measured inside the task image, network off, golden applied, with only
the two guards the test names neutralised and the signed, double and end-of-value guards left alone:

```bash
sed -i 's/if opcode != rdbModuleOpcodeUINT {/if opcode == 0xFF {/;
        s/if opcode != rdbModuleOpcodeSTRING {/if opcode == 0xFF {/' \
    internal/rdb/structure/module2_struct.go
go build ./...            # clean
bash /tests/test.sh        # reward 1, 14 of 14
```

An implementation with no opcode validation on the two most-used readers scores full marks.

## The mechanism, and it is the fixture rather than the assertion

Both corrupt fixtures are **deliberately truncated**. `SENTINEL_CORRUPT_OPCODE` writes one bogus
opcode byte and one length byte and stops. `SENTINEL_CORRUPT_STRING` writes a valid version and
flags, then a bogus opcode, a length and three bytes, and stops. A reader that honours the guard
aborts at the guard. A reader that skips the guard reads the field it was never meant to read,
carries on to the next field, finds an empty buffer and dies on the short read.

**Both paths exit non-zero, so the assertion is satisfied either way.**

The end-of-value case in the same test is the control that proves the diagnosis rather than the
theory. There the buffer is complete, so a missing guard lets the load return normally, the child
exits 0, and the test catches it. Same plumbing, same assertion, and it discriminates, because the
fixture leaves the unguarded implementation somewhere to land.

## The rule

When a negative test asserts an abort, ask what a **non-aborting** implementation does with that
exact fixture. If the answer is "dies a moment later for a different reason", the test is measuring
the fixture and not the requirement. Two ways to fix it, in order:

1. **Give the fixture enough trailing bytes that a non-validating implementation finishes cleanly.**
   Then only the guard can produce the non-zero exit. This costs nothing and pins no wording.
2. Assert on the child's stderr for the specific message. Reach for this second, because it pins
   wording the instruction does not state, which is overreach under `docs/guidelines.md`.

## Two things this generalises to

- **Any "must reject / must abort / must raise" test built on truncated or malformed input.** The
  same shape appears with `pytest.raises(Exception)` over a truncated payload, where the parser
  raises the wrong exception type and the test still passes. Narrow the exception type, or complete
  the fixture.
- **Bundling several contracts into one graded id costs diagnosability on top of this.** Here four
  contracts share `TestNegativeCases`, so a failing report cannot say which one broke. That is not a
  defect on its own and it is worth a line in a review, because it is what stops the two inert rows
  from being visible in any platform report.

## Where the existing checks miss it

The hostile-delete gate does not reach it. Stubbing the end-of-value consumption on this bundle took
the reward to 0 at 12 of 14, correctly, so the gate looked healthy while two rows of the same test
were inert. **The gate proves a requirement is enforced somewhere; it never proves that the test
which claims to enforce it is the one doing the work.** Pick the probe from the test's own case
table, one break per named case, rather than from the requirement list.
