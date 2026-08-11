---
id: empty-git-refs
status: locally-verified
last_verified: 2026-08-07
verified_by:
  - 20260728_153118__jqno_equalsverifier__1166
  - 20260805_080500__hyperledger-firefly_firefly__1123
evidence: "`rm -rf .git/refs` in the built image reproduces `fatal: not a git repository` exactly, with HEAD, objects and packed-refs all intact. A peer reviewer counted agents hitting that string 134 times on this bundle"
applies_to:
  languages: [any]
  runners: [git, docker]
  phases: [packaging, difficulty]
blocks_submission: true
fails_gate: [difficulty, oracle]
supersedes: []
contradicts: []
---

# `git gc` leaves `.git/refs` empty, and an empty directory is not portable

## Writing the loose ref back: compute first, redirect second (elfuse 162, 2026-08-11)

The remedy in this note is one line and it has an ordering trap that destroys the ref it is
meant to restore:

```bash
git rev-parse HEAD > .git/refs/heads/main      # WRONG
```

The shell opens and truncates the redirect target **before** running the command. On a repo whose
only ref is the one you just emptied, `git rev-parse HEAD` then has nothing to resolve, prints
the literal string `HEAD`, and that is what lands in the file. `git fsck` afterwards:

```
error: refs/heads/main: invalid sha1 pointer 0000000000000000000000000000000000000000
error: invalid HEAD
notice: No default references
dangling commit 23ec9b0ac58719d92cda5a076877d2118d77b705
```

Two steps, always, and delete the corrupted ref first if you have already tripped it, because
`rev-parse` cannot resolve anything while it is there:

```bash
rm -f .git/refs/heads/main                       # only if already corrupted
SHA=$(git rev-parse HEAD) && printf '%s\n' "$SHA" > .git/refs/heads/main
```

`bin/rezip.sh` already does it correctly (`PASS GIT-LOOSE-REF`). This bites when the scrub is run
by hand, which is exactly when nobody is watching for it. Verify with `git fsck
--unreachable --no-progress` printing nothing **and** `git for-each-ref` listing the branch.

## What happens

The pre-zip scrub every bundle runs ends with `git gc --prune=now`. That packs every ref into
`.git/packed-refs` and **deletes the loose ref files**, so `.git/refs/heads` is left as an empty
directory. `.git/refs` itself then contains nothing but that empty directory.

Git treats a missing `.git/refs` as *no repository at all*, even when `HEAD`, `objects` and
`packed-refs` are all present and correct. Measured in the task's own image:

```
-- baseline --
e6be8176f00d18f485a865b53fc4cdb2b5be1681
-- after rm -rf .git/refs --
fatal: not a git repository (or any of the parent directories): .git
```

That is the same string a peer reviewer counted **134 times** across the agent trials on
jqno 1166, alongside one agent writing itself a build-workaround note before abandoning Maven.

## Why it is easy to miss

`zip -rXy` writes directory entries, and both `unzip` and Python's `zipfile.extractall`
recreate them, so the empty directories survive the packaging path this workspace tests. Both
were checked here and both pass:

```
environment/repo/.git/refs/          0 bytes
environment/repo/.git/refs/heads/    0 bytes
```

So the local check is green and the bundle is still fragile. Anything downstream that does not
preserve empty directories removes git from the agent's workspace: `git archive`, a naive
`tar` filter, a copy that skips empty dirs, an artifact store that flattens them. You cannot
inspect which of those the platform uses, which is exactly the situation
[diagnosing-platform-only-failures.md](diagnosing-platform-only-failures.md) says not to build
on.

`CLAUDE.md` already warns that `zip -rD` drops the empty `.git/refs/` and breaks the repo. This
is the same hazard arriving from the other direction, and the `-D` warning does not cover it,
because the defect is in the bundle rather than in the zip command.

## The fix

Write the loose ref back **after** the gc, so the directory is non-empty and no extractor can
drop it. `bin/rezip.sh` does this in the step 0 scrub, immediately after `fsck` goes silent:

```bash
HEAD_REF="$(sed -n 's|^ref: ||p' "$REPO/.git/HEAD")"          # refs/heads/main
if [ -n "$HEAD_REF" ] && [ ! -s "$REPO/.git/$HEAD_REF" ]; then
  HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"
  mkdir -p "$(dirname "$REPO/.git/$HEAD_REF")"
  printf '%s\n' "$HEAD_SHA" > "$REPO/.git/$HEAD_REF"
  rm -rf "$REPO/.git/logs"
fi
```

Three details that matter:

- **After the gc, not before.** `git gc` packs and deletes loose refs, so a ref written earlier
  in the scrub is gone by the time the zip is built.
- **`printf`, not `git update-ref`.** The repo ships `logallrefupdates = true`, so the git
  command would recreate `.git/logs` and fail the platform's `git: no reflog` static check. The
  `rm -rf .git/logs` above is belt and braces.
- **Nothing about the repo changes.** The sha matches the one already in `packed-refs`, a loose
  ref simply takes precedence over the packed copy, and `.git` gains no top-level entry, so the
  `config description HEAD hooks index info objects packed-refs refs` whitelist still holds.

Verified after the change, in the image built from the shipped zip:

```
refs/heads contents: main
git rev-parse HEAD:  e6be8176f00d18f485a865b53fc4cdb2b5be1681
git status clean:    0
-- after find .git -type d -empty -delete --
git rev-parse HEAD:  e6be8176f00d18f485a865b53fc4cdb2b5be1681
```

## Correction, 2026-08-07: a broken repo CAN fail the oracle, on any Go task (LEDGER L26)

**The section below says the cost lands only on the agent. That is wrong, and firefly 1123 paid
a full round for it.** The verifier not calling git is not the same as the verifier surviving a
broken repo, because the *toolchain* calls git.

Go stamps VCS metadata into the binaries it builds. When it finds a `.git` it cannot read it does
not skip the stamp, it **fails the build**:

```
error obtaining VCS status: exit status 128
	Use -buildvcs=false to disable VCS stamping.
```

On firefly 1123 that landed on `go build ./...`, the first entry in `execution.commands`, so
`set -e` stopped the runner there, `test-stdout.txt` was **zero bytes**, all 57 graded ids came
back missing and the reward was 0. Three times. The platform reported
`Oracle did not pass all runs: 0/3. Task may be flaky or has infra issues.` and it was neither.

The measured matrix is the part worth keeping, because it is counter-intuitive:

| Repository state in `/app` | Reward |
|---|---|
| intact | 1.0, 57 of 57 |
| `find .git -type d -empty -delete` | **0.0, 0 of 57** |
| `rm -rf .git/refs` | **0.0, 0 of 57** |
| `rm -rf .git` entirely | **1.0**, 57 of 57 |

**A missing `.git` is harmless. A half-present one is fatal.** That asymmetry is the fingerprint
of an extractor that skips empty directories, and it is why the fix in this note matters far
more than "the agent has a nicer time".

### Measured refinement, 2026-08-08: on Go it is `go build` that dies, not `go test`

Source: `20260805_220102__xaaha_hulak__118`, a Go task whose `execution.commands` is a single
`go test -count=1 -json ./...` with no `go build` line. The same four-state matrix, run against the
shipped zip:

| Repository state in `/app` | Reward, GOFLAGS cleared |
|---|---|
| intact | 1.0, 350 of 350 |
| `find .git -type d -empty -delete` | **1.0**, 350 of 350 |
| `rm -rf .git/refs` | **1.0**, 350 of 350 |
| `rm -rf .git` entirely | 1.0, 350 of 350 |

`go build ./...` on that same half-present repository does fail, with the note's exact string:

```
error obtaining VCS status: exit status 128
	Use -buildvcs=false to disable VCS stamping.
```

So the oracle-fatal half is real but **conditional on `go build` being one of the graded commands**,
which it was on firefly 1123 and is not everywhere. `go test` on a package did not trip it. Read the
note as: the toolchain reads VCS state during a *build*, and whether that reaches your reward depends
on your command list. Ship both fixes regardless, the loose ref and `-buildvcs=false`, because the
agent still cannot use git and still runs `go build` by hand, and because a future round that adds a
build command would silently inherit the hazard.

### Measured negative: Maven does not read VCS state, so a JVM task is not exposed

Source: `20260728_153118__jqno_equalsverifier__1166`, 2026-08-07. The same four-state matrix,
run against a Maven/Java bundle whose poms configure no `git-commit-id`, `buildnumber-maven` or
`maven-scm` plugin (the `<scm>` blocks present are release metadata, not a build-time read):

| Repository state in `/app` | Reward |
|---|---|
| intact | 1.0, 1223 of 1223 |
| `find .git -type d -empty -delete` | 1.0, 1223 of 1223 |
| `rm -rf .git/refs` | 1.0, 1223 of 1223 |
| `rm -rf .git` entirely | 1.0, 1223 of 1223 |

`test-stdout.txt` is byte-identical at 199972 bytes across all four, so nothing in the build
even branched on git. **The oracle-fatal half of this note is specific to toolchains that stamp
VCS metadata, and plain Maven is not one of them.** The loose-ref fix is still worth shipping
there, but for the agent-experience reason in the last section rather than to protect the
oracle. Check the poms before assuming either way: a JVM task that *does* configure
`git-commit-id-plugin` would be exposed exactly like Go.

**So fix it twice.** Write the loose ref back (below), *and* remove the dependency so no git
state can reach the build at all:

```dockerfile
ENV GOFLAGS="-vet=off -buildvcs=false"
```

and the same string in `tests/config.json` `execution.env`, so it survives an image whose
environment is overridden. After both, all five repository states score 1.0, including a
committing agent whose `.git` is then damaged the same way. Any toolchain that reads VCS state
during a build deserves the same treatment; Go is simply the one measured here.

## Why it is worth fixing even though the verifier does not call git itself

The verifier stopped depending on git three rounds ago
([tests-patch-vs-agent-edits.md](tests-patch-vs-agent-edits.md)). That removes git from the
verifier's own logic and, per the correction above, **does not** make the bundle safe. Beyond the
oracle, the cost lands on the **agent**: it cannot diff its own work, cannot see what it
changed, and burns budget rediscovering the tree by hand. That depresses the solve rate for a
reason that has nothing to do with the problem, which is difficulty coming from confusion
rather than from the task, and `sentinel-difficulty-scope` section 2 step 4 calls that out
explicitly as the wrong kind of hard.

See also [[unreachable-git-blobs]], [[static-checks]], [[git-autofetch-watcher]].
