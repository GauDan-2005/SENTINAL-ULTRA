---
id: git-restore-fails-for-a-different-reason
status: locally-verified
last_verified: 2026-08-16
verified_by:
  - 20260805_080500__hyperledger-firefly_firefly__1123
evidence: "Inside the built verifier image: /usr/bin/git present, /app inside a work tree, HEAD f1b10e9c, 53553 in-pack objects, `git checkout f1b10e9c -- internal/assets` exit 0. Then a five-state matrix over three restore designs."
applies_to:
  languages: [any]
  runners: [any]
  phases: [step-5, verifier-hardening, reviewer-response]
blocks_submission: false
contradicts:
  - ".claude/rules/11-verifier-hardening.md Section 10.3 - 'The verify-time workspace is not a git repository'. Measured FALSE on firefly 1123. The conclusion (do not build the restore on git) survives; the stated reason does not."
---

# The verify-time workspace can be a git repository, and the restore still must not use git

Section 10.3 tells you not to build the test-tree restore on git, and gives the reason that the
verify-time workspace is not a git repository. On firefly 1123 that reason is **false**, measured
inside the image built from the shipped zip:

```
git binary          : /usr/bin/git
/app inside worktree: true
HEAD                : f1b10e9c5cab7abe59a7e5db13e7344e650707f9   (the declared base commit)
in-pack objects     : 53553
git checkout f1b10e9c -- internal/assets   ->  exit 0
```

A peer reviewer found this and was right to. `.claude/rules/12-common-mistakes.md` already records
that git availability **varies by bundle** (kvdex broke staged and passed dirty, expressa 132
measures the exact reverse "because `/app` is a git repository there"), so the flat claim in 10.3 is
a generalisation from the two bundles it was written on.

**The conclusion survives anyway, for two reasons that hold whether or not git is present.** Do not
reach for git here, and do not repeat the availability argument, because it is checkable and wrong.

## Reason 1: the restore directories hold product source, so a checkout reverts the fix

A restore is scoped to directories, and on any real task those directories hold the implementation
as well as the tests. On firefly, eight of `golden.patch`'s 23 files sit inside the eight restore
directories, `internal/assets/manager.go` and `internal/contracts/manager.go` among them.

```bash
# does a dir-scoped checkout revert the solution? list the overlap first
python3 - <<'PY'
import re,io
g=io.open('solution/golden.patch',encoding='utf-8',errors='replace').read()
files=re.findall(r'^diff --git a/(\S+)',g,re.M)
dirs=open('/dev/stdin').read().split()   # your restore dirs
print([f for f in files if any(f.startswith(d+'/') for d in dirs)])
PY
```

Measured: `git checkout <base> -- <dir>` for the eight directories scores **reward 0.0 at 0 of 59**
with the oracle applied. It reverts the solution along with the tests, so it does not fail the agent,
it fails the **Oracle Check**.

## Reason 2: the failure mode is destructive, because delete and restore fail separately

Restricting the checkout to `*_test.go` paths fixes reason 1 and passes on an intact repository. It
then fails in a worse way than no restore at all, because the two halves have different dependencies:

```bash
find "$d" -name '*_test.go' -delete          # needs only a filesystem. ALWAYS lands
git ls-tree -r --name-only <sha> -- "$d" |   # needs .git. silently produces nothing
  while read f; do git checkout <sha> -- "$f"; done
```

With `.git` absent or partial the delete lands, the restore does not, and the tree ends up with **no
test files at all**. `tests.patch` then cannot apply because the files it modifies are gone.

| repo state | `checkout -- <dir>` | `checkout -- *_test.go` | base64 payload |
|---|---|---|---|
| intact | **0.0, 0/59** | 1.0, 59/59 | 1.0, 59/59 |
| empty `.git` dirs dropped | - | 1.0, 59/59 | 1.0, 59/59 |
| `.git/refs` removed | - | **0.0** `tests.patch did not apply` | 1.0 |
| no `.git` at all | - | **0.0** same | 1.0, 59/59 |
| agent edits tests and commits | - | 1.0 | 1.0 |

The third and fourth rows are not hypothetical on this task. LEDGER **L26** is firefly 1123 losing a
round to a platform **Oracle 0/3** caused by a `.git` damaged in the delivery path, which is the exact
state a git-based restore cannot survive.

## What to say when a reviewer proposes the git version

Do not cite the availability rule at them, because they can disprove it in one command and the rest of
your answer inherits the doubt. Cite the overlap and the matrix. Both are cheap to reproduce and
neither depends on what the workspace believes.

Also concede the part they have right. The comment in `test.sh` justifying the payload said the
verify-time workspace has no git, and that sentence was false on this bundle for five rounds without
anyone checking it. **A justification comment is a claim like any other and it decays the same way**,
so it belongs in the round-over-round audit alongside the numbers.

## Size is a fair complaint and usually cannot be answered

The payload is large because it carries every test file of every package holding a graded regression
id. On firefly that is 187 files and 145 KB of base64 in a 2457-line `test.sh` against a canonical
542. Measured attempts to shrink it:

- Dropping the one package with no `pass_to_pass` ids saves **23 KB of 145**, because the bulk is the
  six packages that do carry them
- `xz` would save another **36 KB** and **is not in the image**. Only `gzip`, `base64` and `tar` are,
  so buying the reduction costs a Dockerfile dependency for a cosmetic gain

Offer that trade to the reviewer rather than taking it unilaterally, and say which you measured.

## Related

- [[tests-patch-vs-agent-edits]] for why the restore exists
- [[empty-git-refs]] and LEDGER L26 for the damaged `.git` this task actually met
- [[go-task-verifier-gotchas]] for the `-buildvcs=false` half of that same round
