# When a task is measured easy and the instruction cannot be trimmed

Source: `20260723_030109__cryspen_libcrux__1165`, difficulty check 2026-08-03. Both frontier
models scored **8/8**, against a Medium bar of at most 4 of 8.

## Why trimming was not the lever

`sentinel-difficulty-scope` says to look at over-prescription first. Here that was a dead end and
it is worth knowing the shape, because it recurs on any port of a public API:

- The task is "provide the PQCP `crypto_kem_*` API for ML-KEM". The function names, argument
  order and signatures **are** the deliverable, not hints about how to build it.
- The graded tests call every one of them by name, so cutting them from the instruction makes
  them underivable and trades a difficulty finding for a blocking `test_faithfulness` one.
- Both rubric judges had already scored prescriptiveness 5/5 and clarity 4.5/5 with the full
  signatures in place, which is the checker agreeing that a public API contract belongs there.

The task also arrived `agent_hardened = "true"` with `pass_at_k_opus_4_8 = "2/3"`. Two of three
is already above the Medium bar, so it was measured easy before this workspace touched it and one
platform hardening cycle had not moved it.

## Why a wrapper task resists difficulty

Every function in this PR delegates to something the crate already exports. An agent that can
read a signature can write the body. Adding **more** delegation adds surface, not difficulty, so
"expand the PR" only helps if the additions are things a competent-but-quick implementation gets
*wrong*, not things it has to type.

What actually earns failures:

- requirements that only break in a build configuration the agent is not running
- an ordering or atomicity constraint where the natural implementation is the wrong one
- a property that compiles fine and fails a test, rather than one the compiler teaches them

What was added here on that basis: the error type has to be usable from outside the crate (not the
same as `pub`), a rejected parse has to leave its destination untouched (deserialize-then-validate
fails it), and the feature composition has to hold with `rand` off and with no default features.

## Two candidate expansions, both killed by evidence

Both looked strong on paper. Measure before you build.

| Candidate | Killed by |
|---|---|
| A C ABI layer with `#[export_name]` + `extern "C"`, which fits a PR whose whole framing is "the reference C interface from mlkem-native" | `lib.rs` sets `#![deny(unsafe_code)]`. Raw pointers mean the task would force an agent to weaken a crate-wide lint in a cryptography library. A prototype produced 15 errors against that lint |
| Making the `unpacked` alias follow the best compiled backend (simd256 > simd128 > portable) | The workspace is a virtual manifest without `resolver = "2"`, so resolver v1 unifies features across members and another member turns `simd256` on. The alias would point the graded struct tests at AVX2 code and tie the reward to the grading host's CPU |

Check both of these on any Rust task before designing an expansion:

```bash
grep -n 'deny(unsafe_code)\|forbid(unsafe_code)\|no_std' <crate>/src/lib.rs
grep -n 'resolver' Cargo.toml            # absent in a virtual manifest means v1, features unify workspace-wide
cargo test -p <crate> --no-default-features --features <minimal> --test <t> -- --list | grep -c avx2
```

## Round 2 of the same problem: the expansion did not move the number

Added 2026-08-04, same task. The expansion described above shipped and the difficulty screen came
back **easy again**, 4/4 for both models against the previous 8/8, both still at 100 percent. The
screen had by then moved to a cheap single-arm rollout, so the run count changed and the verdict
did not.

Per [diagnosing-platform-only-failures.md](diagnosing-platform-only-failures.md) that is two
strikes, so the next move is not a third expansion. Measure the shape of the task instead. The
measurement that settled it, and it takes one command:

```bash
# every oracle entry point, and how many lines of body it actually has
python3 - <<'PY'
import re
src='\n'.join(l[1:] for l in open('solution/golden.patch') if l.startswith('+'))
for m in re.finditer(r'pub fn (\w+)\([^)]*\)[^{]*\{', src):
    i=m.end(); d=1
    while i<len(src) and d:
        d += (src[i]=='{') - (src[i]=='}'); i+=1
    n=len([l for l in src[m.end():i-1].strip().split('\n') if l.strip() and not l.strip().startswith('//')])
    print(f"{m.group(1):40s} {n:2d} lines")
PY
```

libcrux answered: **18 functions, every body between 1 and 7 lines, every one delegating to
something the crate already exported at the base commit.** That is the whole diagnosis. A PR that
is a naming layer over a complete implementation has a difficulty ceiling set by the PR, and no
amount of added API surface raises it, because each addition is another signature to transcribe.

**Rule: before designing a second difficulty expansion, measure the oracle's body lengths. If the
median is a handful of lines of delegation, stop expanding the API and either change the kind of
requirement (below) or escalate.**

## What to add when more API will not help

The requirements that survived on libcrux came from the **standard the task implements**, not from
the crate, and each has a natural implementation that is wrong:

| Requirement | The wrong answer that looks right |
|---|---|
| Decapsulation never reports failure (FIPS 203 implicit rejection), and the secret for a foreign ciphertext is stable, wrong, and bound to the key's own rejection secret | treating a bad ciphertext as an error, or deriving the answer from the ciphertext alone |
| A private key is well formed only while the encapsulation key it carries matches the digest it carries, with the rejection secret outside that binding | validating the encapsulation key inside the private key and stopping there |

The second is the better one, and the reason is worth copying. **It is a reasonable thing to
write, it rejects every obviously broken input, and it passed the previous round's suite.**
Measured: that implementation scored 1.0 before and 0.0 after. A requirement only raises
difficulty if you can name a plausible implementation it newly fails, so write that implementation
and run it before believing the requirement is worth anything.

Both were probed in the task image before any design work, which also confirmed the crate already
satisfies them, so the oracle needed no change at all and the judge's oracle axes were untouched.
Instruction plus tests is a much cheaper and safer round than an oracle expansion.

## The honest end of the line

If the only remaining way to reach Medium is a different, harder PR, that is the documented Not
Fixable condition (`docs/guidelines.md`, PR scope), not something to keep patching. Say so in
Comments for Reviewer with the evidence rather than bolting on more surface. Expansion first,
once, properly measured, then escalate.
