---
id: destructive-git-in-the-wrong-tree
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260719_045042__openwhispr_openwhispr__1002
evidence: "A chained `cd <scratch> && git reset --hard && git clean -fdx` ran with the cd failing. It reverted every uncommitted tracked change in the workspace, deleted .claude/rules/ and twelve untracked learning notes, and emptied the task's work/. 39 of 40 tracked files and all 47 deleted files were recovered from unreachable objects; the one untracked file git had never hashed was not"
applies_to:
  languages: [any]
  runners: [git]
  phases: [all]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts:
  - "the assumption that `set -e` stops a script when a `cd` fails"
---

# A failing `cd` does not stop the destructive command chained after it

## What happened

One line, written to reset a scratch clone before regenerating a patch:

```bash
cd "$SP/gold/repo" && git reset -q --hard HEAD && git clean -qfdx
```

The scratch directory had been removed earlier in the session. The `cd` failed. The script was
running under `set -euo pipefail` and continued anyway, and a later unguarded

```bash
git reset -q --hard HEAD && git clean -qfdx
```

ran against the workspace instead. Effects, all in one second:

- every uncommitted change to tracked files in the workspace reverted to the last commit, which
  on this repo was 40 files including `CLAUDE.md`, `INDEX.md`, all of `docs/`, all of `bin/` and
  a dozen `learning/` notes
- `.claude/rules/`, all twelve files, deleted
- twelve untracked `learning/` notes deleted
- the live task's `work/` emptied

## Why `set -e` did not save it

This is the part worth internalising, because the script looked defended. Bash does not exit on a
failing command that is **part of a `&&` or `||` list, except the final one**. In
`cd X && A && B`, a failing `cd` makes the list return nonzero, `A` and `B` are skipped, and
execution continues at the next line with the working directory unchanged. `set -e` never fires.

So the danger is not the line that failed. It is every later line that assumed the `cd` worked.

## The rule

**Never let a destructive git command inherit its target from the working directory.** Name the
repository explicitly, every time:

```bash
git -C "$REPO" reset --hard HEAD
git -C "$REPO" clean -fdx
```

`git -C` on a missing path is an error, not a silent redirection. If a `cd` is genuinely needed,
make it fatal on its own line: `cd "$X" || exit 1`.

Two supporting habits, both cheap:

- **`git clean -fdx` is not a scratch-directory command.** `-x` includes ignored files, which in
  this workspace means `tasks/` and every untracked note. There is no version of this command
  that is safe to run without knowing exactly where you are.
- **Prefer `rm -rf "$SCRATCH" && mkdir -p "$SCRATCH"` to resetting a clone.** A scratch tree that
  is recreated cannot be the wrong tree.

## Recovery, and what is genuinely unrecoverable

Most of it came back, because git had hashed the content at some earlier point and the blobs
survive as unreachable objects even though nothing references them.

```bash
git fsck --unreachable --no-progress | awk '$2=="blob"{print $3}'
```

Matching blobs to paths needs care, and the first attempt made things worse by matching on the
first line, which conflated every file starting with `---`. Two reliable discriminators:

- **Content similarity against the committed version.** Jaccard over line sets, taking a match
  only when it clears a floor and beats the runner-up by a margin. This resolved `bin/` and
  `docs/` cleanly, at 0.77 to 0.99.
- **Identity out of the document itself.** Frontmatter `id:` for a learning note, `name:` plus
  the presence of `alwaysApply`/`globs` to tell a Claude skill from its Cursor twin, and the
  `_Owner of CLAUDE.md **Section N**_` header for a rule file. This is what separated the five
  near-identical skill and `.mdc` pairs, which similarity alone scored 0.97 against 0.94.
- **Known sizes as ground truth.** A session that recorded `ls -la` early has the exact byte
  count of every file, which beats both heuristics. Where similarity picked one blob and the
  recorded size picked another, the size was right: `learning/LEDGER.md` scored 0.72 for the
  wrong version and 0.63 for the correct one.

Result: 39 of 40 reverted tracked files, all 12 rule files and all 35 `learning/` entries
restored and verified.

**What did not come back: an untracked file git had never hashed.** Nothing recovers that. The
loss is bounded by whether a file was ever staged, diffed or committed, which is invisible until
you need it.

## The second lesson, which cost a rebuilt artifact

After a recovery, **the tooling is part of what has to be verified**. `bin/rezip.sh` had been
reverted to an older commit that predates the loose-ref write-back. The next zip was built with
it, passed every check the older script knew about, and shipped `.git/refs/heads` as an empty
directory, which is precisely the hazard [empty-git-refs.md](empty-git-refs.md) exists for. It
was caught by comparing one line of output against the previous round:

```
round 1:  PASS REFS 3 refs/ entries present
round 2:  PASS REFS 2 refs/ entries present      <- the loose ref is gone
```

A check suite that has silently lost a check still reports PASS. Diff the count of passing checks
against the last round, not just their colour, and re-run the build once the tooling is restored.

See also [[empty-git-refs]], [[local-runs]], [[git-autofetch-watcher]].
