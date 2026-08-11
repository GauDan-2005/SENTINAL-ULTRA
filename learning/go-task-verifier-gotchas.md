---
id: go-task-verifier-gotchas
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260805_080500__hyperledger-firefly_firefly__1123
evidence: "go test ./... exits 1 on a fully correct oracle tree for three pre-existing reasons; golden.patch omitting a generated doc file the PR carries turned a green repo test red; a Go signature migration makes the base test files stop compiling, so every agent edits exactly what tests.patch patches"
applies_to:
  languages: [go, any]
  runners: [go-test, docker]
  phases: [analysis, verifier-design, oracle, local-runs]
blocks_submission: true
fails_gate: [difficulty, oracle, peer-review]
supersedes: []
contradicts:
  - "verifier-fail-open.md - it offers two answers when the runner exits nonzero on a green tree, and there is a third"
---

# Go task gotchas, and the exit-code gate on a repo whose suite is not green

Three things measured on firefly 1123 that cost time and would cost it again.

## 1. `go test ./...` can exit nonzero on a fully correct tree, and the answer is to scope it

`verifier-fail-open.md` already says to measure the runner's bare exit on a green tree before
wiring the exit-code gate. It then offers two outcomes: the exit is 0 so the gate is safe, or the
exit is nonzero so leave the gate out and say why in Comments for Reviewer. **There is a third,
and on a large repo it is usually the right one.**

Measured on firefly at the oracle, everything the task asks for implemented correctly:

```
go test ./...   -> exit 1
```

Three packages fail and not one of them has anything to do with the task:

| Package | Why it fails on a correct tree |
|---|---|
| `internal/apiserver` | `TestDiffSwaggerYAML` compares generated swagger to a checked-in file that is **already 1190 lines out of date at the base commit** |
| `internal/reference` | the generated type reference, which the change legitimately alters |
| `test/e2e/runners` | end-to-end suites that need a live stack and fail at base too |

Leaving the gate out would have shipped the fail-open grader. Gating on that status would have
failed my own oracle. **Scope `execution.commands` to the packages the change touches, and the
gate becomes safe on a measurement:**

```json
"commands": [
  "/usr/local/go/bin/go build ./...",
  "/usr/local/go/bin/go test -json ./internal/assets/... ./internal/tokens/fftokens/... ./internal/events/... ./internal/database/sqlcommon/... ./internal/contracts/... ./internal/orchestrator/..."
]
```

Six packages, exit **0** on a green tree, 14 s warm. The `go build ./...` line keeps the
whole-repo compile requirement as a graded command, which is the pattern
`verifier-fail-open.md` already describes for a requirement no assertion can reach.

**The check to run before you choose.** On the oracle tree, run the whole-repo command and read
its exit, then run the scoped command and read its exit. If they differ, the difference is the
list of packages that are red for reasons you did not cause, and it is also your scope.

**One consequence worth stating.** Scoping bounds the surface the gate polices, which is what
makes it equivalent to a regression guard over those packages. Pair it with a populated
`pass_to_pass` from the same packages so the report still names what it protected, and keep
`allow_extra_failures` at `true` per LEDGER L13, because the run still does not execute exactly
the graded set.

## 2. A golden patch that omits a generated doc file turns a green repo test red

`CLAUDE.md` Step 2 item 9 already says files the PR changed and golden omits are a finding. This
is what that finding actually costs when the omitted file is **generated**.

firefly regenerates its API reference and swagger from `ffstruct` tags and a description
registry, and it has two pre-existing tests that compare the generated output to the checked-in
files. PR 1123 adds three fields to the token pool with descriptions, so both generated files
change, and the PR carries both. `golden.patch` shipped without either.

Measured, in the task's own image:

| | `internal/reference::TestCheckGeneratedMarkdownPages` |
|---|---|
| at base | **passes** |
| after the oracle, golden as shipped | **fails** |
| after the oracle, with the PR's 12-line doc hunk added to golden | passes |

`pass_to_pass` was empty and `allow_extra_failures` was true, so nothing caught it, and the
fail-open grader wrote reward 1.0 over the top of it.

**The check.** After the oracle, run the whole repo suite and diff the failing set against the
same run at base. Anything that is green at base and red after the oracle is caused by your
golden patch, whatever the reward says:

```bash
# in the image, on separate runs
go test -json ./... > /tmp/base.json          # no solve.sh
bash /solution/solve.sh && go test -json ./... > /tmp/oracle.json
# then compare the Action=="fail" sets
```

**Take the hunk from the PR, do not regenerate it.** Regenerating on the solved tree also folds
in whatever drift the repo already had, which on firefly was 1190 added and 84 removed lines of
swagger with no connection to the task. That is a drive-by edit inside the oracle. Fetch the two
blob versions at the PR's base and head shas and diff those:

```bash
gh api "repos/<owner>/<repo>/contents/<path>?ref=$BASE" --jq .download_url | xargs curl -sSL -o base.f
gh api "repos/<owner>/<repo>/contents/<path>?ref=$HEAD" --jq .download_url | xargs curl -sSL -o head.f
```

The base blob should be byte-identical to the shipped file. If it is not, the bundle's repo is not
at the base commit and that is a different finding.

**Note the repo may be red at base for its own reasons.** firefly's swagger check fails at the
base commit, so that one is not yours and fixing it means shipping unrelated churn. Report it,
scope it out of the graded command, and leave it.

## 3. A Go signature migration is the guaranteed `tests.patch` conflict

`tests-patch-vs-agent-edits.md` covers this class. Go adds two specifics.

**It is guaranteed rather than likely, and the reason is the compiler.** The task adds a
parameter to an exported constructor and a fifth argument to four interface methods. The base
test files call the old signatures, so `go test ./...` will not build the package until the agent
edits them. There is no version of a correct implementation that leaves those files alone, and
they are exactly the files `tests.patch` patches. Both models arrived at `pass_at_k` 0/3.

**Go is the friendly case for reading a NOP**, because it compiles per package. The packages
holding the new symbols cannot build, but every other package still runs, so a `pass_to_pass` id
in a package that does compile **executes and passes in the NOP** and proves the run reached the
test phase rather than aborting. Six did here. That is the split
`verify-in-the-image.md` asks for, available without any special handling.

For the `fail_to_pass` half, whose packages cannot build, the symbol audit is the fallback and it
has to be reported as an audit:

```bash
# every new symbol the graded tests touch, against the base tree
for s in CheckInterface ResolvePoolMethods ResolveFFIReference TokenInterfaceFormat InterfaceFormat; do
  printf "%-24s %s\n" "$s" "$(grep -rn --include='*.go' -- "$s" . | grep -v '^./vendor' | wc -l)"
done   # all zero = no f2p test could pass at base
```

**Restore scope on Go.** Tests live beside the source, so `go test` also runs whatever the agent
wrote. Restore every `*_test.go` under each graded package directory, deleting before extracting,
and the agent's own failing test disappears along with its collisions. On firefly that was 71
files, a 91 KB tarball and 124 KB of base64 inside a 145 KB `test.sh`. Proven with an agent that
writes its own file at the exact graded path, adds a failing test of its own and deletes `.git`:
reward 1.0, 55 of 55.

**A graded id names an import path, not a file.** `github.com/hyperledger/firefly/internal/assets::TestX`
carries the module prefix, so the which-restore-shape one-liner in `CLAUDE.md` 10.3 can never
match a `touched` entry like `internal/assets/token_pool_test.go`. This is LEDGER L7 again on a
fourth id scheme. Resolve by hand: for each id, find the `_test.go` file defining that
`func Test...` and ask whether the patch touches it.

## 3b. Go fails the build on an unreadable `.git`, so pin `-buildvcs=false`

Measured on firefly 1123 after a platform `Oracle 0/3` that reproduced nowhere locally. Go
stamps VCS metadata into binaries, and a `.git` that is present but unreadable does not make it
skip the stamp, it makes the build fail:

```
error obtaining VCS status: exit status 128
	Use -buildvcs=false to disable VCS stamping.
```

The state arises on its own: `git gc` deletes the loose ref files, `.git/refs` and
`.git/refs/heads` are left as empty directories, `zip`/`unzip` preserve them so every local check
is green, and any extractor that does not leaves `.git` half-present. **A missing `.git` is
harmless; a half-present one is fatal.**

Put the flag in both places, because they fail independently:

```dockerfile
ENV GOFLAGS="-vet=off -buildvcs=false"
```
```json
"env": { "GOFLAGS": "-vet=off -buildvcs=false" }
```

Then fix the cause too, per [empty-git-refs.md](empty-git-refs.md): write the loose ref back
after the gc. `bin/rezip.sh` does it; a hand-rolled `zip` goes around it. Verify with
`find environment/repo/.git -type d -empty`, which has to print nothing, and re-run the oracle
with `find .git -type d -empty -delete` applied first.

**The generalisation.** `go build ./...` as a graded command is a good whole-repo compile guard
(section 1) and it puts the toolchain's own environment assumptions on the critical path. Any
command you add to `execution.commands` inherits every dependency that command has, including
ones that have nothing to do with the task.

## 4. `test.sh` does not parse under dash, and the guard costs one line

The stock `test.sh` uses `RUNNER=(...)` and `"${RUNNER[@]}"`, so `dash -n /tests/test.sh` fails at
the array with `Syntax error: "(" unexpected`. `solve-sh-under-sh.md` is about `solve.sh` and
concludes a bash shebang is the normal accepted state, which is right. The cheap addition, when
you are already editing the file:

```bash
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
```

With it on both scripts, `sh /solution/solve.sh && sh /tests/test.sh` returns reward 1.0 instead
of exiting 2 with no reward file written.

## Timing, for calibration

`golang:1.22`, 4 cpus, `--network none`, firefly at 288 test files:

| Step | Wall |
|---|---|
| `docker build` from the extracted bundle | 58 to 82 s |
| `go build ./...` cold | 52 s |
| scoped 6-package `go test` warm | 14 s |
| NOP (whole verifier) | 56 s |
| oracle (solve plus whole verifier) | 66 to 67 s |

A 300 s `[verifier] timeout_sec` would have held, and it was raised to 900 anyway for headroom on
a slower builder. The bundle shipped with `[verifier] timeout_sec` 300 against an
`execution.timeout_sec` of 1800, so the inner limit could never fire. Check that pair on every
task: the inner one has to be the smaller of the two.

## 5. A logger that ends in `os.Exit` takes the whole package down, so isolate the call in a child test binary

Added 2026-08-11 from redisshake 1005, which was **accepted** carrying this shape in five graded
test files.

Go runs every test in a package inside **one process**. A library whose error path ends in
`log.Panicf`, `log.Fatalf` or a bare `os.Exit` therefore does not fail one test, it kills the
binary, and every other graded id in that package is reported missing. On a task where the whole
point is feeding the parser a malformed or unexpected input, that is not an edge case, it is the
main path. The tell is one line:

```bash
grep -rnE 'log\.(Panicf|Fatalf|Panic|Fatal)|os\.Exit' environment/repo/internal/<pkg> | head
```

RedisShake's own logger ends `Panicf` with `os.Exit(1)`, so a single unreadable snapshot loaded
in-process would have destroyed every result in `internal/rdb`.

**The fix is a helper process, which is a Go standard-library idiom and needs no dependency.** The
test re-execs its own binary with a `-test.run` filter that matches only the helper, hands the
work in through the environment, and reads the result back out of the child's combined output:

```go
// the helper: skipped in an ordinary run, and NOT in fail_to_pass
func TestSentinelAOFBulkHelper(t *testing.T) {
    if os.Getenv(sentinelAOFBulkChildFlag) != "1" {
        t.Skip("helper process for sentinelLoadAOF")
    }
    ld := NewLoader(os.Getenv(sentinelAOFBulkChildPath), ch)
    // ... print each result on a prefixed line
}

// the graded test drives it
cmd := exec.Command(os.Args[0], "-test.run=^TestSentinelAOFBulkHelper$")
cmd.Env = append(os.Environ(), sentinelAOFBulkChildFlag+"=1", sentinelAOFBulkChildPath+"="+path)
raw, _ := cmd.CombinedOutput()   // a crash here is data, not a lost package
```

Five things that make it hold up, all of them learned the expensive way:

- **`raw, _ := cmd.CombinedOutput()` deliberately ignores the error.** A child that panics exits
  nonzero, and that is the case being measured. Assert on the parsed output, not on the exit
- **The helper must skip when the flag is absent**, or it runs on every ordinary invocation
- **The helper is not graded.** It appears in neither `fail_to_pass` nor `pass_to_pass`. Say so in
  Comments for Reviewer, because a reader who opens the file will wonder
- **Encode the result, do not scrape it.** These tests print a prefixed line carrying an argument
  count and then `strconv.Quote`-ed arguments, and the parent reads them back with
  `strconv.QuotedPrefix` plus `Unquote`. Binary payloads and embedded newlines survive that;
  a `strings.Split` on whitespace does not
- **Use `exec.CommandContext` with a deadline for a liveness test.** The redisshake writer test
  measures a loop that never terminates, so the child has to be killable. Base sits on the full
  10 second deadline; the fixed tree returns in 0.017s

Cost: it is the difference between one failing id and a package-wide zero. It also makes the NOP
readable, since the graded ids still execute and report individually at base.

**This is one of the two Go facts that shaped the whole redisshake verifier.** The other is at
section 3 above: Go compiles a package as a unit, so one non-derivable name in a graded test file
takes down every id in that package. Both are the same property seen from different ends, and
between them they explain an arrival `pass_at_k` of 0/3 that was a build failure rather than
difficulty (LEDGER L27).
