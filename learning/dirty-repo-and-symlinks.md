---
id: dirty-repo-and-symlinks
status: locally-verified
last_verified: 2026-08-04
verified_by:
  - 20260809_080653__sysprog21_elfuse__162
  - 20260723_030109__cryspen_libcrux__1165
evidence: "git status --porcelain on the bundle as received: 35 modified tracked files, 28 mode-only and 7 flattened symlinks"
applies_to:
  languages: [any]
  runners: [git, zip]
  phases: [analysis, packaging]
blocks_submission: false
fails_gate: [peer-review]
supersedes: []
contradicts: []
---

# The shipped repo can arrive dirty, and `zip -rX` re-dirties it

Source: `20260723_030109__cryspen_libcrux__1165`, 2026-08-02. Found in the Step 2 git sweep,
reproduced on a native ext4 extract of the platform's own zip, so it is not an NTFS artifact.

## Second sighting, and it is not a libcrux quirk (elfuse 162, 2026-08-11)

`20260809_080653__sysprog21_elfuse__162` arrived with `git status --porcelain` printing **28**
lines in `environment/repo`, every one of them `mode change 100755 => 100644`, 24 under `tests/`
and 4 under `.ci/`. Zero symlinks in that repo, so the `-y` half of this note did not apply and
the mode-bit half did, on its own, on a different repository and a different language.

Two things worth carrying:

- **The zip the platform handed us already had them at 644.** `unzip -Z` on the downloaded
  submission shows `?rw-r--r--` for `tests/driver.sh`, so the bit was lost upstream of this
  workspace rather than by anything done here. The cleanest proof is the pristine extract, which
  no command is ever allowed to run in: `git -C download/original/environment/repo status
  --porcelain` still prints the same 28 lines today, out of the archive. It is a defect in the
  bundle as received and it reports as a Fixable packaging finding
- **Restoring it is git-metadata cleanup, not a source edit.** The hard boundary forbids editing
  tracked source inside `environment/repo`; putting a file's mode back to what the base commit
  records is restoring the tree *to* base, which is the opposite. One line, and it is safe
  because it is driven by the index rather than by a guess:

```bash
# the path is everything after the tab, so do not read it as a whitespace field
git ls-files -s | sed -n 's/^100755 [^\t]*\t//p' | while IFS= read -r f; do chmod 755 "$f"; done
git status --porcelain     # must print nothing
```

## What happened

`git status --porcelain` inside `environment/repo` listed **35 modified tracked files** in the
bundle as received. Nothing had been edited. The breakdown:

```
mode-only: 28   content-changed: 7
```

- 28 files lost their executable bit (`old mode 100755` / `new mode 100644`): `extract-c.sh`,
  `hax-driver.py`, every `*.sh` helper in the tree.
- 7 files are **symlinks in git** (`git ls-files -s` shows mode `120000`) that arrived as
  ordinary files holding the target's contents. `libcrux-ml-kem/extracts/c_header_only/c.sh`
  is a symlink to `../common/c.sh` upstream and shipped as a 166-line regular file.

`docs/guidelines.md` puts a clean working tree on the pre-submission git checklist, so this is
a finding on arrival. It is also easy to miss, because every *other* git check passes: HEAD
equals the base commit, no remotes, no reflog, no refs past HEAD, `.git` well under the limit.

## Why it matters beyond tidiness

Regenerating `tests.patch` the documented way is `git add -A` then
`git diff --cached -- <paths>`. On a dirty tree that stages all 35 unrelated files too. The
generated patch is still correct if you scope the `git diff` to your own path, but `git add -A`
on a tree you have not inspected is how unrelated churn ends up in a patch.

## The fix, and the part that is not in `CLAUDE.md`

Restoring is one command, and it brings back both the mode bits and the symlinks:

```bash
cd environment/repo
git checkout -- .
git status --porcelain      # must be empty
```

**Then the zip has to preserve symlinks or the fix is undone at packaging time.** Plain `zip`
follows symlinks and stores the file content, which is almost certainly how the bundle got this
way. `CLAUDE.md` used to prescribe `zip -rX`, which warns against `-rD` and says nothing about
symlinks. The canonical command became `zip -rXy` on 2026-08-04, on the strength of this note:

```bash
cd work && zip -rXy "../upload/<name>.zip" . -x '*.DS_Store' '__MACOSX/*'
```

`-y` stores symlinks as symlinks. Verify it landed, and verify the tree is clean **after
extracting the finished zip**, not in the working copy:

```bash
unzip -Z <name>.zip | grep -c '^l'          # symlink count, 7 on this task
cd <extracted>/environment/repo && git status --porcelain | wc -l   # must be 0
```

## Rule

Run `git status --porcelain` in `environment/repo` during the Step 2 sweep, before touching
anything, and read what the changes actually are with `git diff --numstat` (a `0 0` row is a
mode change). If the tree is dirty as shipped, `git checkout -- .` is the fix, it is git
metadata rather than a tracked-source edit, and the zip has to be built with `zip -rXy`
afterwards or the symlinks flatten again.

## Moving the workspace flattens them all over again

Source: same task, 2026-08-04. The workspace was relocated from the ntfs3 mount to
`/home/.../SENTINAL-ULTRA` on ext4 between sessions.

`work/environment/repo` arrived at the new path with **the exact damage this note is about**,
undone by the copy rather than by the platform:

```
symlinks: 0        (was 7)
porcelain: 7        T x4  (symlink -> regular file)   D x3  (symlinked dirs dropped)
```

Plus a stale `.git/HEAD.lock` and `.git/logs/HEAD.lock` left from the round-1 git segfault,
which had travelled along with everything else.

Two things follow.

**A filesystem move is a packaging event.** Whatever copied the tree behaved like plain `zip`
without `-y`: it followed the symlinks and wrote their contents. Anything that re-materialises
the repo, a copy between mounts, a sync tool, an archive round-trip, can silently re-dirty a
tree you already cleaned. Re-run the Step 2 git sweep after any of them, not just on the bundle
as received.

**Check the shipped zip separately, and do not infer one from the other.** The zip in `upload/`
came through the same move perfectly intact, md5 unchanged, 7 symlinks, clean tree, `fsck`
silent. A zip is one file, so nothing can flatten anything inside it. The damage is confined to
the unpacked working copy. So a dirty `work/` after a move does not mean the deliverable is
compromised, and a clean deliverable does not mean `work/` is fit to re-zip from.

**`download/original` is damaged too, which silently breaks the pre-zip diff.** It is an unpacked
tree like `work/`, so it lost the same symlinks: `find download/original/environment/repo -type l`
returned **0** against 7 in the repaired `work/`. `diff -rq download/original work -x '.git'` then
reports directories as `Only in work/...` when they are symlinks correctly restored in `work/` and
missing from the reference. Three of them on this task, under
`libcrux-ml-kem/extracts/c_header_only/generated/`.

That matters because `CLAUDE.md` Step 5 treats that diff as the check that every changed file was
changed on purpose. Reading it after a move gives phantom entries, and the temptation is to
"fix" `work/` to match the reference, which would re-break the symlinks. Check the direction
before acting:

```bash
find download/original/environment/repo -type l | wc -l   # 0 means the REFERENCE is damaged
find work/environment/repo -type l | wc -l                # this is the one that must be right
```

Re-extract `download/original/` from `download/*_submission.zip` before trusting the diff again.

The repair is the one already in this note plus the lock sweep from
[local-runs.md](local-runs.md):

```bash
cd work/environment/repo
find .git -name '*.lock' -delete
git checkout -- .
rm -rf .git/logs .git/ORIG_HEAD .git/FETCH_HEAD .git/refs/remotes
git reflog expire --expire=now --all && git gc --prune=now --quiet
git fsck --unreachable --no-progress          # must print nothing
git apply --check ../../tests/tests.patch
git apply --check ../../solution/golden.patch
```

Related: [unreachable-git-blobs.md](unreachable-git-blobs.md) for the rest of the git sweep. On
this task `git fsck` also reported the broken `refs/remotes/origin/HEAD` that note describes,
in the bundle as received.
