---
id: oracle-bug-vs-pr-scope
status: locally-verified
last_verified: 2026-08-07
verified_by:
  - 20260805_080500__statrs-dev_statrs__315
  - 20260807_080545__tair-opensource_redisshake__1005
evidence: "statrs PR 315's exact Mann-Whitney helper returns the complement of its own answer
  whenever n1 <= n2, so Less came back 0.9 where scipy gives 0.1. The bug is on statrs master
  today. Every PR-authored test uses n1 > n2, so nothing upstream or in two review rounds
  caught it, and a graded test written from the oracle's observed behaviour asserted it as
  correct"
applies_to:
  languages: [any]
  runners: [any]
  phases: [analysis, verifier-design, oracle, peer-review]
blocks_submission: true
fails_gate: [peer-review]
supersedes: []
contradicts: []
---

# A bug in the source PR is an ORACLE defect once the instruction promises a standard

**Second confirmation, 2026-08-07, redisshake 1005.** Different language, different domain, same
shape and the same trap. Valkey marks a hash field that never expires with `EXPIRY_NONE`, which is
`-1` (`valkey-io/valkey`, `src/expire.h:12`); the `RDB_TYPE_HASH_2` save path writes it for every
entry and the load path compares against it rather than against zero. PR 1005's decoder gates on
`expireAt != 0`, so every non-expiring field of a real Valkey hash came out as
`hpexpireat <key> -1`, a pre-1970 timestamp that DELETES the field. Upstream master was
byte-identical, so the "genuinely unavailable" clause was earned and the one-condition divergence
was documented. **All ten shipped graded tests agreed with the bug, and so did the replacements
written for them in the same session, because both sets took the oracle's behaviour as the
definition.** The bug only surfaced when the on-disk format was read from the source that defines
it. The lesson generalises past statistics: when the instruction states a wire or file format as
fact, go and read that format's own definition, not the code that claims to implement it.

## Correcting the bug can cost the task its only difficulty discriminator

Recorded 2026-08-11, after statrs 315 was accepted, because this is the bill that comes with a
case-1 fix and nothing else here names it.

Before the correction, the graded suite asserted Mann-Whitney thresholds that had been read off
the **buggy** oracle, so an agent implementing the test correctly **failed**. That was doing the
work of separating good answers from bad, illegitimately, by requiring agents to reproduce the
author's mistake. Correcting it, which the reviewer was right to demand, let correct
implementations pass and the discriminator vanished.

The before and after is measured. The pre-fix bundle cleared every evaluation check including the
review gate's difficulty screen and reached a human reviewer. The next bundle, differing by the
correction and its pinned reference values, returned `Difficulty: FAIL EASY`. Two more rounds went
into rebuilding difficulty honestly.

**So budget a difficulty lever into the same round as a case-1 fix.** The fix is still correct and
still mandatory. Just do not be surprised when the screen turns red immediately afterwards, and do
not read that as a new defect: it is the old, illegitimate discriminator being removed. Say so in
Comments for Reviewer, because a reviewer reading a red screen right after a fix they asked for
deserves the causal chain rather than a coincidence.

## The situation

The instruction said each function must agree with `scipy.stats` to an absolute 1e-9. The
oracle is a faithful port of the merged PR. The PR has a real algorithmic bug. So the oracle
does not meet the instruction, through no fault of the port.

The reflex from [source-pr-cross-check.md](source-pr-cross-check.md) is **narrow the
instruction, never touch the oracle**, and that reflex is right for a *missing feature*: the PR
does less than the instruction promised, so the promise was too broad. **It is wrong for a
defect.** There is no coherent sentence that describes "the exact one-sided p-value is reported
on the wrong tail whenever the first sample is not the larger one". Writing it down as spec
documents a bug as intended behaviour, and the same data with the two samples labelled the other
way then contradicts itself.

## What `docs/` actually permits

`docs/guidelines.md:284-291`, "Solution & oracle — editable in two cases":

> You may edit solve.sh / golden.patch in two cases: **(1) to correct an oracle that does not
> implement the instruction**, or (2) to expand PR scope to increase difficulty. When you do:
> - **Match the canonical fix.** ... **Only diverge if the upstream fix is genuinely unavailable
>   or unsuitable, and document why.**
> - **No unnecessary changes.**
> - never reduce or replace its intent.
> - **Update the instruction and tests in lockstep.**

Case 1 is the whole authorisation. A bug fix is not a scope reduction: no feature is added or
removed and the file list does not change. The expansion-only rule is about *scope*, not about
*correctness*.

**Before using case 1, check whether upstream already fixed it.** Fetch the file from the
project's default branch:

```bash
curl -sS "https://raw.githubusercontent.com/<owner>/<repo>/master/<path>" -o upstream.rs
grep -n -A6 '<the suspect construct>' upstream.rs
```

If upstream fixed it, adopt their fix, that is the canonical one. If upstream still carries it,
you have earned the "genuinely unavailable" clause and you say so in Comments for Reviewer.
Here master still carried the identical branch, so the divergence was documented rather than
assumed.

## The trap that produced it

**A graded test written from the oracle's observed behaviour cannot detect a bug in the
oracle.** Round 1 added a swapped-sample block with the comment "Exchanging the two samples has
to move the small tail to the other side" and then asserted the tail stayed where it was. The
comment was the intent, the assertion was the observation, and the oracle's bug made the
assertion pass. A peer reviewer caught the contradiction between the two.

**The remedy is an independent reference.** Do not assert oracle output against oracle output,
and do not read the expected value off a run. Implement the contract separately, from its
definition, in a language that is not the task's:

```python
# exact Mann-Whitney null distribution, written from the definition
from itertools import combinations
def tail_ge(u, n1, n2):
    n, k = n1 + n2, min(n1, n2)
    hits = tot = 0
    for c in combinations(range(1, n + 1), k):
        if u <= sum(c) - k * (k + 1) // 2:
            hits += 1
        tot += 1
    return hits / tot
```

That produced the numbers the graded tests now pin, and it disagreed with the oracle on 3 of 5
shapes. Where the oracle and the reference agree, pinning is safe; where they disagree, one of
them is wrong and you have to find out which before writing a test either way.

The same applies to the normal approximation. Writing `mu`, the tie-corrected `sigma` and the
continuity term out in Python and comparing agreed with the oracle to about 1e-12, which both
validated the oracle's asymptotic branch and produced assertable constants. A reviewer had
already called the previous version of those checks "compare the code with itself".

## The shape that hides this class of bug

The defect fired only when `n1 <= n2`. **Every test the PR shipped used `n1 > n2`.** When a
function takes two collections whose roles are asymmetric, the argument order is a dimension the
upstream tests may never vary. Same family: first vs second argument, empty vs non-empty,
equal-length vs unequal, smaller-first vs larger-first. Vary it deliberately and include the
equal case, which is the one both "smaller" and "larger" framings forget.

## Checklist

- Is a failing behaviour a *missing feature* (narrow the instruction) or a *defect* (case 1
  oracle edit)? Ask whether a coherent spec sentence could describe the current behaviour. If
  writing it down would embarrass you, it is a defect.
- Did you check the project's default branch for an existing fix, and record the result?
- Is the edit minimal, and does the file list still match the PR's?
- Did any PR-authored test encode the bug? It has to move in lockstep, and that is expected
  rather than a boundary violation.
- Does the full library suite still pass on the fixed tree?
- Do the graded tests now FAIL when the bug is reinstated? That is the only proof the coverage
  is real. Here 2 of 19 fail on reinstatement, where the previous suite passed the same tree.
