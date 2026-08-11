---
id: git-autofetch-watcher
status: locally-verified
last_verified: 2026-08-08
verified_by:
  - workspace-wide (measured on this machine, all three live tasks plus _archive)
evidence: "Two mtime snapshots three minutes apart, taken while only root-level files were being edited. Six FETCH_HEAD files rewritten in a single 0.09-second burst at 22:05:13 and again at 22:08:13"
applies_to:
  languages: [any]
  runners: [any]
  phases: [arrival, fixing, pre-upload, packaging]
blocks_submission: false
fails_gate: [static-checks]
---

# A background git watcher keeps rewriting `.git` inside every task tree

## What happens

Something outside this workspace runs `git fetch` against every checkout under `tasks/` and
`_archive/` on a roughly three minute cycle. It writes a zero byte `.git/FETCH_HEAD` into
each one. It does this to **both** `work/environment/repo` and
`download/original/environment/repo`, which is the tree that is supposed to be the untouched
reference.

## How it was measured

Snapshot the mtimes, do something that touches nothing under `tasks/`, snapshot again.

```
find tasks _archive -name FETCH_HEAD -printf '%TH:%TM:%TS %p\n' | sort > /tmp/fh_before.txt
# ... edit only root-level files for a few minutes ...
find tasks _archive -name FETCH_HEAD -printf '%TH:%TM:%TS %p\n' | sort > /tmp/fh_after.txt
diff /tmp/fh_before.txt /tmp/fh_after.txt
```

Measured 2026-08-04: every one of the six files moved from `22:05:13` to `22:08:13`, and all
six timestamps inside each burst sit within 0.09 seconds of each other. A burst that tight
across six unrelated repositories is one process walking a list, not six separate actions. A
three minute gap is a poll interval. Nothing under `tasks/` was modified in the window either
side of it.

The likely source is an editor with git integration open on this folder. Cursor and VS Code
both ship a periodic autofetch, and it recurses into nested repositories.

## Why it matters

1. **It dirties `.git` past the whitelist.** The static check and `bin/checks/20-git.sh` both
   require `.git` to contain exactly `config description HEAD hooks index info objects
   packed-refs refs`. `FETCH_HEAD` is an eighth entry. Every scrub is undone within three
   minutes.
2. **It writes into `download/original/`.** That tree is the diff target for
   `diff -rq download/original work`, and the whole point of it is that nothing writes there.
   This is one confirmed mechanism by which the pristine copies drift, alongside Step 2's git
   inspection rewriting `.git/index`.
3. **It is silent.** `FETCH_HEAD` is zero bytes, `git status` stays clean, and `tasks/` is
   gitignored at the workspace root, so no workspace-level git command will ever show it.

## The rule

- **Never conclude from a clean `git status` that nothing wrote under `tasks/`.** The
  workspace `.gitignore` lists `tasks/`, so `git status --porcelain` cannot report a path
  there whether or not it changed. Verify with mtimes instead:
  `find tasks -newermt '<session start>' -printf '%TY-%Tm-%Td %TH:%TM  %p\n'`
- **Scrub `FETCH_HEAD` as the last action before zipping, not earlier.** `bin/rezip.sh`
  already removes it inside the pre-zip scrub, so the scripted path is safe. The exposure is
  a hand-rolled `zip` run more than three minutes after a manual scrub.
- **Re-run `git fsck --unreachable` and the `.git` entry listing immediately before the zip**,
  never from an earlier round's result.
- If the bundle can be closed out in one sitting, turn the editor's autofetch off first. In
  VS Code and Cursor that is `git.autofetch: false`.

## It is not only `FETCH_HEAD`: a build-tool cache appeared the same way

Added 2026-08-08, firefly 1123 round 3. `bin/rezip.sh` **refused to build a zip** and named
`work/environment/repo/smart_contracts/corda/cordapp_kat/.gradle`, five files of Gradle daemon state
with lock files and `last-build.bin`.

Nothing in the session ran Gradle. Checked before touching it, and every answer mattered:

- **untracked** (`git ls-files` returns nothing), so deleting it is not a tracked-source edit
- **absent from `download/original/`**, so it did not arrive in the bundle
- **absent from the uploaded zip the reviewer had reviewed**, so it never reached the platform
- mtime **more than a day after** the previous zip was built, so it appeared *between sessions*

Same class as the `FETCH_HEAD` writer above, most likely the same editor indexing a Gradle project
it found in the tree. The consequence is worse: a stray dev artifact in the shipped repo **hard-caps
the packaging axis at 1**, which is a real scored penalty rather than a failed whitelist.

**Two rules out of it.** A tree you verified in a previous session is not still verified, so re-run
the stray sweep at the start of every round, not only on arrival. And build the zip through
`bin/rezip.sh` rather than a hand-rolled `zip`: the scripted path caught this in one second, and it
is the same path that carries the loose-ref step in [[empty-git-refs]] that a hand-rolled zip had
already gone around once.

## What this does not explain

The libcrux pristine tree has 28 lost `100755` mode bits, 4 flattened symlinks and 3
deletions. A fetch does not do that. Those came from the extraction path, most likely the
NTFS to ext4 move. This note covers `FETCH_HEAD` only, and the two causes are independent.

See also [[unreachable-git-blobs]], [[dirty-repo-and-symlinks]], [[local-runs]].
