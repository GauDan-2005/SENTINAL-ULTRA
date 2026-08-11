---
id: raising-difficulty-on-a-wrapper-task
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260723_030109__cryspen_libcrux__1165
evidence: "Three difficulty screens returned easy (8/8, then 4/4, then 4/4, both models at 100%). Ten expansions tried or prototyped, all measured at zero effect. Submitted Invalid / Not Fixable on the PR-scope trigger. Caveat added 2026-08-06: all ten levers added to PR 1165's own surface, and none adapted a related later PR, which docs/faq.md sanctioned on 2026-08-05 - see the last section. Accepted by the reviewer 2026-08-11 on that verdict, with no bundle reviewed and no difficulty re-run"
applies_to:
  languages: [rust, any]
  runners: [cargo]
  phases: [difficulty, fixing]
blocks_submission: true
fails_gate: [difficulty]
supersedes: []
contradicts: []
---

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

## The measurement that predicts difficulty better than anything else here

Added 2026-08-05, after libcrux 1165 failed the difficulty screen a third time.

Body length tells you the oracle is delegation. It does not tell you why the *other* tasks in
this workspace are hard. This does, and it is one command over `solution/golden.patch`:

```bash
python3 - solution/golden.patch <<'PY'
import sys,re
p=open(sys.argv[1],encoding='utf-8',errors='replace').read()
add=len([l for l in p.split('\n') if l.startswith('+') and not l.startswith('+++')])
rem=len([l for l in p.split('\n') if l.startswith('-') and not l.startswith('---')])
print(f"+{add} -{rem}  removed/added={rem/max(add,1):.2f}")
PY
```

Measured across every bundle here:

| Task | Platform difficulty | removed/added |
|---|---|---|
| kvdex 245 | hard (accepted) | **0.79** |
| equalsverifier 1166 | hard | **0.60** |
| xlwings 2719 | — | 0.27 |
| AltBeacon 1177 | hard | 0.12 |
| **libcrux 1165** | **measured easy, three times** | **0.01** |

libcrux removes 4 lines while adding 450. Every other task replaces real amounts of existing
behaviour, and the two rated hard replace the most.

**The mechanism.** A change that rewrites existing code has to keep an existing suite green while
doing it, and that is where agents fail: they break a regression guard, or miss a call site, or
change a contract something else depended on. libcrux's PR is a new module behind an off-by-default
feature. Nothing existing can break, so the whole class of failure that makes the other tasks hard
is structurally absent. Its `pass_to_pass` is 21 against 112, 210 and 1204 for the others, which is
the same fact from the other side.

**What this means for a difficulty round.** Requirements you bolt onto an additive feature are all
graded by tests that only run in the new configuration. They can catch a wrong implementation, and
on libcrux three separate ones demonstrably do, but none of them creates the pressure that comes
from having to not break what is already there. If a task measures easy and its
`removed/added` is near zero, expect added requirements to move the number very little, and say so
before spending the round rather than after.

**Do not respond by making the patch invasive.** Rewriting existing code so the task gets harder is
changing what the PR does, which is the reduce-or-replace prohibition. This measurement is a
diagnosis to report, not a target to hit.

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

## The end of the line, reached and documented (2026-08-05)

libcrux 1165 failed the difficulty screen three times (8/8, then 4/4, then 4/4, both models at
100% throughout) and was submitted as **Invalid / Not Fixable, PR scope**. What that call rested
on, so the next task does not have to re-derive it:

**The decisive guideline is `docs/guidelines.md:217`**, and it names difficulty explicitly:

> If the only way to make a task solvable, **difficult enough**, or valid is to reduce or replace
> the PR scope, the task is Not Fixable.

The Fixable row at `:65` is conditional in the matching way, "too easy **but you can raise
difficulty by adding to the PR scope**". So the verdict turns on one empirical question, *can
difficulty be raised by adding*, and that question is answerable with measurements rather than
argument.

**What a complete answer looks like.** Eight levers were explored in the task image and each
viable one adversarially refuted, on top of two killed in earlier rounds:

| Lever | Result |
|---|---|
| instruction underspecification | large effect, but banned by `guidelines.md:197` and overshoots: one argument-order difference took the suite 17 passed to 0, because it is one compilation unit |
| eurydice C-extraction gate | 0. Agent self-verifies in 7 s; repo shows the idiom 10/10 with no counter-example |
| wycheproof KAT conformance | 0. Six independent keygen routes measured byte-identical, so any delegating impl is conformant by construction |
| cross-variant length dispatch | 0. Base already returns the length errors; prototype 38 lines, first try |
| trait genericity | 0. Three incompatible designs each passed first attempt |
| incremental API wrapper | 0. Full layer compiled and passed first try, bodies 1 to 6 lines |
| zeroization on drop | 0. Correct answer measured at three lines |
| no-std / alloc-free | 0. Already enforced; zero `Vec`/`vec!` in the whole crate |
| C ABI layer (earlier round) | killed by `#![deny(unsafe_code)]` |
| backend-aware alias (earlier round) | killed by workspace-wide `simd256` under resolver v1 |

**Two rules worth carrying.**

First, **a lever is only real if you can name a plausible implementation it newly fails, write
that implementation, and watch it fail.** Three of the eight above compiled and passed on the
first attempt, which is the tell that they add typing rather than difficulty.

Second, **check what the task measured before you touched it.** libcrux arrived with
`pass_at_k_opus_4_8 = "2/3"` and `agent_hardened = "true"`, `hardening_cycles = "1"`. It was
already above the Medium bar and one platform hardening cycle had already failed to move it. That
single line in `download/original/task.toml` reframes the whole round: you are not repairing
difficulty you removed, you are being asked to add difficulty the task never had.

**What this is not.** It is not "a red difficulty screen means Not Fixable".
[platform-announcements.md](platform-announcements.md) is explicit that a difficulty result is
never automatically the verdict, and that note is right. The verdict here rests on the PR-scope
trigger plus a measured task-side cause plus an exhausted option space. Two earlier drafts of this
workspace's own records made the weaker claim and had to be superseded, which is recorded in
`LEDGER.md` L19.

## The lever this note did not have (2026-08-06)

**The option space above was not exhaustive by the standard the Hub documented the next day, and
the gap is worth stating plainly rather than leaving for someone to rediscover.**

On 2026-08-05 the Hub added `docs/faq.md`, "A task came back too easy - can I adapt a change from a
related PR to add complexity?", and the answer is yes:

> You can look at later PRs in the repo and take inspiration from a related one to add complexity.

with three bounds: not from unrelated PRs, not a wholesale copy, and never a change to the scope or
feature of the original PR/task. libcrux 1165 was submitted Invalid / Not Fixable the same day, and
that FAQ had not been read when the ten levers were designed. **Every one of the ten was an addition
to the surface of PR 1165 itself.** Not one of them went looking at what the repo did next.

Why that is the exact gap this task had, and not a generic caveat. The measurement above says
libcrux's problem is `removed/added = 0.01`: the patch adds 450 lines and removes 4, so it replaces
no existing behaviour, and every lever tried added more surface without removing any. A later,
related PR is the one source of material that can carry a genuine *replacement* into the task while
still building on the same feature, which is what would move that ratio. So the untried lever is not
a tenth of the same kind, it is the only one of a different kind.

**What this does and does not change.**

- It does **not** retract the verdict. The verdict shipped, and none of the measurements above is
  wrong: the ten levers really did measure at zero, the removed/added figure really is 0.01, and
  `docs/guidelines.md:217` really does name difficulty. Nothing here says the answer was wrong, only
  that the search was narrower than it should have been.
- It does mean **the option space was not proven exhausted**, and "an exhausted option space" is one
  of the three things this note says a complete Not Fixable answer rests on. Treat that leg as
  unproven for libcrux 1165 until a related later PR has actually been looked at.
- If 1165 comes back from the reviewer, **this is the first thing to try**, before re-arguing the
  verdict: list the repo's PRs after the base commit, keep the ones touching the same feature, and
  measure a candidate the same way as the ten - name a plausible implementation it newly fails,
  write that implementation, and watch it fail.

**The rule for the next task.** Before writing "the option space is exhausted" into any answer, the
lever list has to include at least one related later PR that was looked at and rejected on evidence.
A list of ten additions to the original PR's own surface is a list of one kind of lever, however
long it is.

## The verdict was accepted (2026-08-11)

The reviewer accepted it. Submitted **Invalid / Not Fixable** with the trigger box "PR scope needs
to be changed or reduced" ticked and every Environment Issues sub-box deliberately left blank,
because the environment was healthy and the submission said so.

Two things that acceptance does **not** settle, and both matter more than the outcome:

- **No bundle was reviewed.** Path C has no zip upload field, so the four rounds of verifier
  hardening were never looked at. The acceptance validates the argument, not the work behind it.
- **It does not say five rounds were needed.** The structural measurement that carried the verdict
  was available at the first difficulty failure. Whether the same case would have been accepted at
  round 3 is untested.

How the argument was written, and the full validated / not-validated split, is in
[not-fixable-is-a-written-argument.md](not-fixable-is-a-written-argument.md). This note keeps the
evidence; that one keeps the write-up.
