---
id: related-pr-carries-its-own-bug
status: platform-confirmed
last_verified: 2026-08-16
verified_by:
  - 20260805_220102__xaaha_hulak__118
  - 20260807_080545__tair-opensource_redisshake__1005
evidence: "Difficulty screen returned FAIL EASY at 8 of 8 agent solves. The related later PR adapted as the lever carried a bug of its own, and 4 of 5 plausible implementations of its one function fail the graded test built from real server output"
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty, oracle, verifier-design]
blocks_submission: true
fails_gate: [difficulty]
supersedes: []
contradicts: []
---

# The best difficulty lever in a related later PR is usually the bug in it

## The situation

`docs/faq.md:104-110` lets you adapt a change from a **related** later PR when a task comes back
easy. [difficulty-levers-must-discriminate.md](difficulty-levers-must-discriminate.md) says a
lever only counts if independent implementations disagree about it, and that the strongest
evidence is that the upstream author got it wrong. Put those together and the search has a
shape: **do not look for the biggest related PR, look for the one whose own code is subtly
wrong.**

## What it looked like

redisshake 1005 was blocked `FAIL EASY`, both models 4 of 4. PR 1005 leaves one line unfinished:

```go
// TODO: detect if server is Valkey and pass appropriate flag
// For now, assume Redis format (false)
o := types.ParseObject(anotherReader, typeByte, key, false)
```

PR 1038, `fix: add Valkey server type detection support`, exists to close exactly that TODO in
exactly that file. Three files, 160 lines. That made it the obvious lever on relatedness alone.
The reason it is a *good* lever is what its own function does:

```go
for _, line := range strings.Split(serverInfo, "\n") {
    if strings.HasPrefix(line, "valkey_version:") { return true, nil }
    if strings.HasPrefix(line, "redis_version:")  { return false, nil }   // returns first
}
```

Valkey publishes a Redis compatibility version **before** its own
(`valkey-io/valkey`, `src/server.c:6175-6178`):

```
"# Server"
"redis_version:%s\r\n",  REDIS_VERSION      <- first
"server_name:%s\r\n",    SERVER_NAME
"valkey_version:%s\r\n", VALKEY_VERSION     <- second
```

So against a real Valkey server the function answers **Redis**, which is the one thing it exists
to get right. Upstream's own `func_test.go` never catches it: all ten of its cases are
hand-written, and every Valkey case omits the `redis_version` line. The test suite was written
from imagined input.

## Why that is worth more than a bigger change

Measured, five ways an agent might write that function against the graded tests built from real
`INFO` output:

| Implementation | Result |
|---|---|
| upstream's own, first version line wins | **FAIL** |
| scan the whole reply, Valkey line wins | pass |
| `strings.Contains` over the whole reply | **FAIL**, takes `master_redis_version` for the server's own |
| go by `server_name:` | **FAIL**, a Redis reply has no such line |
| split on the colon, first match wins | **FAIL** |

Four of five fail. A larger but well-specified addition would have added *work* and no
*disagreement*, which is the dud [difficulty-levers-must-discriminate.md](difficulty-levers-must-discriminate.md)
already describes. This one is small and splits honest attempts.

## The three-step search

1. List later PRs that touch a file the source PR touched, or that close a TODO it left. The
   GitHub API, filtered on the source PR's own file list.
2. For each candidate, read its diff and ask **what does real-world input look like, and does
   this code handle it**. Fetch the definition from the upstream project that produces the input,
   not from the PR's own tests, which are exactly where the blind spot lives.
3. Before shipping, write the plausible implementations and run them. Keep the candidate only if
   they disagree.

## The correction is a case-1 oracle edit, same as any other PR bug

Adapting a buggy PR into the oracle unchanged would ship the bug. Fixing it in the oracle is
[oracle-bug-vs-pr-scope.md](oracle-bug-vs-pr-scope.md) again, under
`docs/guidelines.md` "Solution & oracle - editable in two cases", case 1. Check the default branch
first, disclose the divergence, and state the requirement in `instruction.md` in a form that does
not hand over the answer. Here the instruction says a Valkey server "answers with more than one
version line, so the reply has to be read as a whole rather than settled on the first version line
that turns up in it" - the constraint, not the algorithm.

**This is the second time on one task.** PR 1005 itself mis-decodes Valkey's `-1` no-expiry
marker. A task can carry two of these, and both are difficulty as well as correctness.

See also [[difficulty-levers-must-discriminate]], [[oracle-bug-vs-pr-scope]],
[[raising-difficulty-on-a-wrapper-task]], [[source-pr-cross-check]].

## Outcome, 2026-08-11: ACCEPTED, with three adaptations in one golden patch

The task closed accepted on round 4, carrying adaptations from **three** different later PRs at
once (1038 server type detection, 1048 the append-only length-prefixed read, and the writer half
of 1043). What survived review, and the bounds that kept it inside `docs/faq.md`:

- **Each one is related by the source PR's own output or its own TODO.** 1038 closes the TODO PR
  1005 left in the scan path. 1048 fixes the append-only path PR 1005 already changes. 1043's
  writer bug is reached by PR 1005's own decoder output, since a large Valkey hash field becomes
  exactly the oversized single command that trips it
- **Half a PR is a legitimate adaptation and a declared one.** PR 1043's `rdb.go` half was
  **rejected** because it sits on PR 1018's RESTORE machinery, and importing that would change
  what PR 1005 is about. The answers said so under PR additions rather than leaving the reviewer
  to notice the asymmetry
- **None was copied wholesale.** The graded tests are the submitter's; the upstream test files do
  not ship

**The caution this note opens with is now measured from the other side.** "The upstream author
got it wrong" is strong evidence a **trap** exists. It is not evidence that agents fall into it:
4 of 5 hand-written plausible versions of PR 1038's parser fail the graded test, and **all four
honest implementations passed**, because they wrote exact field matching where upstream wrote a
first-match scan. Use the author's mistake to find the trap, then measure whether anyone actually
walks into it, and remember the control is a ceiling (LEDGER L35).

## Second instance of the recipe, efficacy unmeasured (hulak 118, accepted 2026-08-16)

The three-step search worked exactly as written and found the candidate in one pass. PR 118 adds
`DetailForm.HandleMouse`; **PR 155 exists to patch that same method**, which is as close as a later
PR gets. The bug is `setArgEnabled(argName, v)` setting `enabled` on every item sharing an argument
name, so an input-object argument drawn as one row per field switches all its siblings at once. The
tell this note is about is textbook: the base keyboard path does exactly that, **eight lines above
the method the agent has to write**, so copying it is the natural move and it is the wrong one.

Two behaviours were adapted, neither wholesale, and PR 155's own 124 lines of tests were left out.
The task was accepted.

**And that is the whole of what is known.** The screen never re-ran after the round that added it,
so nothing measures whether the trap converts anybody, and the round-2 discriminate matrix behind it
is the weak shape this note's own caution describes: five implementations written on purpose to be
wrong rather than five honest builds ([[difficulty-levers-must-discriminate]]). Cite hulak as
evidence that **the three-step search finds real candidates**, never as evidence that this lever
class moves a screen.
