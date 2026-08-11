---
id: related-pr-carries-its-own-bug
status: platform-confirmed
last_verified: 2026-08-07
verified_by:
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
