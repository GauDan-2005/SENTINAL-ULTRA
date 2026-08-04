---
id: unreachable-git-blobs
status: locally-verified
last_verified: 2026-08-02
verified_by:
  - 20260716_114438__ETLCPP_etl__1466 (peer review, second-hand)
  - 20260723_030109__cryspen_libcrux__1165 (reproduced here)
evidence: "chat_transcripts/cursor_etlcpp.md for the original bounce; git fsck --unreachable on this machine for the reproduction"
applies_to:
  languages: [any]
  runners: [git]
  phases: [packaging]
blocks_submission: false
fails_gate: [peer-review]
supersedes: []
contradicts: []
---

# Solution and test blobs surviving in `.git` after a clean-looking gc

Source: peer-review notes on task `20260716_114438__ETLCPP_etl__1466` (ETLCPP/etl PR 1466),
reviewed 2026-08-02. **Provenance:** originally a reviewer's finding on another EC's bundle,
read from their session transcript, which is kept in this workspace at
[`chat_transcripts/cursor_etlcpp.md`](../chat_transcripts/cursor_etlcpp.md). **Now
machine-verified here** — see "Confirmed on this machine" below.

## What happened

The bundle passed Static Checks, the Difficulty Check, the Oracle Check and the Quality
Check judge, then came back from the reviewing EC with this:

> The corrected repository still contains unreachable Git blobs that exactly match the
> golden patched `include/etl/algorithm.h`, the golden patched documentation, and the test
> patched `test/test_algorithm.cpp`. These objects expose both the solution and hidden tests
> through commands such as `git fsck --unreachable` and `git cat file`.

Every other git check on the bundle was clean. HEAD equalled the base commit, there were no
refs past HEAD, no remotes, no `filter.*`, a clean working tree, no `.git/logs`, and `.git`
was well under 100 MB. The nine-line pre-submission checklist in `docs/guidelines.md` passed
in full, and the solution was still sitting in the object store.

## Why it happens

Fixing a task writes objects into `.git` that never end up on a branch:

- Regenerating `tests.patch` per the documented procedure — apply the new tests by hand,
  `git add -A`, `git diff --cached > tests.patch`, `git checkout .` — stages the patched
  test file, which writes a blob for it. The `git checkout .` removes it from the tree, not
  from the object store.
- Running the oracle inside `environment/repo` instead of a disposable copy leaves blobs of
  every golden-patched file behind the same way.
- Any `git stash`, `git commit --amend` or aborted rebase during the fix round does the same.

`git gc --prune=now` prunes unreachable objects only when they are also older than the grace
period *and* not protected by something still pointing at them — the index, `ORIG_HEAD`, a
stash ref, or a reflog entry that the same command has not yet expired. Running
`gc --prune=now` without `reflog expire --expire=now --all` first is the usual way objects
survive. So is running it while the index still references the staged blob.

An unreachable blob is readable by anyone with the repo:

```bash
git fsck --unreachable --no-progress
# unreachable blob 4f2a…
git cat-file -p 4f2a…          # prints the golden file in full
```

`docs/` prescribes the remedy but never the verification: the git table in
`guidelines.md` gives `git reflog expire --expire=now --all && git gc --prune=now` as the fix
for a reflog, and the pre-submission checklist has no `fsck` line. `docs/tasking-guide.md`
step 5 does require that "no solution material … is readable from agent paths" — and `.git`
is an agent path, since the agent works in that checkout.

## The rule

Do the git cleanup last, immediately before zipping, then **verify instead of assuming**:

```bash
cd environment/repo
git reflog expire --expire=now --all
git gc --prune=now
rm -rf .git/logs .git/ORIG_HEAD .git/FETCH_HEAD
git fsck --unreachable --no-progress     # MUST print nothing
```

If it prints anything, read one or two of them before doing anything else — `git cat-file -p
<sha>` tells you immediately whether it is harmless or the golden file. Then repeat the
expire/gc pair. A stubborn object usually means something still references it: check
`git stash list`, `.git/ORIG_HEAD`, and whether the index is clean.

Belt and braces on a task where the golden change has a distinctive string, grep the whole
object store for it:

```bash
git rev-list --objects --all > /dev/null   # warm the pack
git cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' \
  | awk '$2=="blob"{print $1}' \
  | while read sha; do git cat-file -p "$sha" | grep -ql 'stable_partition' && echo "$sha"; done
```

Anything that comes back and is not a tracked file at HEAD is leakage.

Two habits that stop the blobs appearing in the first place, both already in `CLAUDE.md`:
regenerate `tests.patch` in the working copy but run `solve.sh` and `test.sh` only in
disposable scratchpad copies, and re-run the cleanup after the Step 5.5 checks rather than
before them.

## Confirmed on this machine

Source: `20260728_153118__jqno_equalsverifier__1166`, revision round, 2026-08-02.

Regenerating `tests.patch` by the documented procedure left, in `environment/repo/.git`:

```
error: refs/remotes/origin/HEAD: invalid sha1 pointer 0000000000000000000000000000000000000000
unreachable blob 97000ad09be6052fc74a81a76a00fbb9357fef4e
unreachable blob 42214044f008c7a4ac6f6a855c6958c6bafbc12d
... 10 blobs total
```

`git cat-file -p` on the first three printed
`package nl.jqno.equalsverifier.internal.instantiation;`, so they were the patched test
sources, exactly as the reviewer described. Also present were `.git/logs`, `ORIG_HEAD` and
`FETCH_HEAD`. The expire/gc/rm sequence cleared all of it in one pass and `fsck` went silent.

### `refs/remotes/origin/HEAD` is a second leak path the checklist misses

That first line is not a blob and it is worth its own mention. A dangling
`refs/remotes/origin/HEAD` containing `ref: refs/remotes/origin/main`, pointing at a branch
that does not exist, had survived every round and **shipped inside the uploaded zip**.

It passes everything that looks for it:

- `git remote` prints nothing, because no remote is configured in `.git/config`, so the
  platform's `no remote` static check is green
- `git for-each-ref` does not list it, because it is a broken symref
- the tree is clean, HEAD equals base, there is no reflog

The only thing that catches it is `git fsck`, which stops being silent. So the "fsck must
print nothing" rule earns its keep against more than dangling blobs. Add
`rm -rf .git/refs/remotes` to the cleanup, and check `.git` holds exactly
`config description HEAD hooks index info objects packed-refs refs` afterwards.
