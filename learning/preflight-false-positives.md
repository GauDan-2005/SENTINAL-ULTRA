---
id: preflight-false-positives
status: locally-verified
last_verified: 2026-08-16
verified_by:
  - 20260807_080545__tair-opensource_redisshake__1005
  - 20260803_111822__nolabs-ai_deepfabric__297
evidence: "bin/preflight.sh blocked a clean bundle on an upstream scripts/commands/config.json; bin/checks/50-restore-shape printed UNRESOLVED on all 22 graded ids because Go ids are import paths; and on deepfabric 297 the same snippet printed a plausible but wrong 5 of 16 because pytest CLASS-scoped ids put the file in the first :: segment rather than the last but one"
applies_to:
  languages: [go, python, any]
  runners: [go-test, pytest, any]
  phases: [packaging, pre-upload]
blocks_submission: false
fails_gate: []
supersedes: []
contradicts: []
---

# Two `bin/` checks that block a clean bundle, and how to clear them honestly

Both fired on redisshake 1005. Neither is a task defect. Both will fire again on the next repo
of the same shape, and the wrong reaction to either one is to change the bundle.

## 1. `pkg.leak.repo` flags any tracked `config.json` inside `environment/repo`

    FAIL pkg.leak.repo solution or verifier material sits inside the agent's checkout:
         environment/repo/scripts/commands/config.json

The check looks for verifier filenames anywhere under the agent's checkout and treats a hit as
leakage. RedisShake ships `scripts/commands/*.json`, one JSON file per Redis command, and Redis
has a command called `CONFIG`. So `scripts/commands/config.json` is the upstream spec for that
command, 1 of **391** files in the folder, tracked at the base commit, holding zero verifier
keys.

**Deleting it would be editing tracked source, which is a hard boundary.** The three commands
that settle it, in this order, before you touch anything:

```bash
git -C "$R" ls-files --error-unmatch <path>          # tracked at base?
grep -c 'fail_to_pass\|pass_to_pass\|grading\|execution' <path>   # 0 = not the verifier's
head -12 <path>                                       # read it
```

Tracked, zero verifier keys, and the content is obviously something else means false positive.
Run `bin/rezip.sh --skip-preflight` **after** a full preflight pass on the same tree, and say in
Comments for Reviewer which line you overrode and why. Do not reach for `--skip-preflight`
before you have read the hit.

The same shape will fire on any repo that tracks a `config.json`, a `test.sh` or a `grade.py`
of its own. RedisShake tracks a root `test.sh` too, and that one did not trip the check, so the
rule is not uniform across the filenames it knows about.

## 2. `50-restore-shape` cannot map a Go graded id, and says so

    FAIL restore.resolution UNRESOLVED - only 0% of the 22 graded ids could be attributed to a
         file (22 unresolved). Refusing to print a number that would pick the verifier design

This is the checker behaving **correctly**, and it is the fix LEDGER L7 asked for. A Go graded
id is `RedisShake/internal/rdb::TestSentinelValkeyRDBHeaderIsRead`. The left half is the
**module import path**, not a file path, and the package directory holds many files, so nothing
in the id names the file that defines the test. `id schemes: PATH=22` is the detector guessing
wrong, because the id does contain slashes.

`UNRESOLVED` is not a number and is not an answer. Resolve it by hand, then record the result in
`task.md` so the next round does not redo it. The mapping that works for Go is
package-directory plus a grep for the test's own `func`:

```python
pkg, test = graded_id.split("::")
d = pkg.replace(module_name + "/", "", 1)          # import path -> directory
# the file is whichever *_test.go in that directory defines `func <test>(`
# ...and if none does, it is one tests.patch creates
```

On redisshake that gave **7 of 22 outside the patched files** (the five pre-existing `_test.go`
files hold seven graded ids), so Section 10.3 required the full test-tree payload rather than a
create-only patch. Reading `UNRESOLVED` as zero would have picked the create-only design and
shipped seven guards running the agent's own copies.

**Go keeps tests beside the source, so the restore payload is not one directory.** There is no
`src/test` root to derive from. Build the payload from `git ls-files | grep '_test\.go$'` and
derive the wipe list from the archive itself, per LEDGER L18.

## 2b. It also mis-resolves a pytest CLASS-scoped id, and this one prints a number rather than UNRESOLVED

Added 2026-08-16 from deepfabric 297, the first pytest task in this workspace.

Section 2 is about an id the checker cannot map at all, which it says so about. **This is the worse
case: the id maps to something, the something is wrong, and a plausible number comes out.** There is
no `UNRESOLVED` line to warn you.

The Section 10.3 snippet does `i.rsplit('::', 1)` and treats the head as a path. On pytest that is
right for a **function** id and wrong for a **class** id:

| id shape | `rsplit('::', 1)` head | matches a stem? |
|---|---|---|
| `tests/test_config.py::test_get_engine_args` | `tests/test_config.py` | yes, correct |
| `tests/test_topic_graph.py::TestGraph::test_build` | `tests/test_topic_graph.py::TestGraph` | **no, and it is counted outside** |

**On pytest the file is the FIRST `::` segment, never the last but one.** Measured on deepfabric 297,
whose `tests.patch` edits all four graded files so the true answer is zero:

```
snippet as written : 5 of 16 'outside'   (every one of them class-scoped)
corrected          : 0 of 16 outside
```

All five misreported ids are the `TestGraph` and `TestIntegration` ones. A session reading `5 of 16`
would conclude a create-only patch is insufficient **for the wrong reason** and reach for a full-tree
payload, when the bundle needs a targeted payload of four files.

The one-line correction, which is right for both pytest shapes and leaves the other schemes alone:

```python
head = i.split('::', 1)[0] if ('::' in i and '/' in i.split('::', 1)[0]) else head
```

This is LEDGER **L7** on a fifth id scheme, after pytest-function, JUnit `#`, cargo `module::test`
and Go import paths. The generalisation L7 already states holds and is worth restating in its
strongest form: **check that the id scheme and the `touched` paths share a namespace, and check it
per shape rather than per language.** One language can carry two id shapes and only one of them can
be broken.

## 3. Pre-submit gate 7 goes red after any git command in `work/`, and the content is fine

Added 2026-08-11 from firefly 1123, round 4.

Step 7 condition 7 is written as a mechanical test: `find tasks/<name>/work -newer
tasks/<name>/upload/<name>.zip` must print nothing, and anything it prints means an edit landed
after the battery, voiding both the zip and the battery. That reading is right for an edit and
wrong for the most common way the check fires.

`git status --porcelain`, `git fsck` and `git diff` all **write** `.git/index` even when they
change nothing, so running any of them inside `work/environment/repo` as a verification step
moves the mtime of `.git` and turns gate 7 red immediately. The gate then reports a voided
battery caused by the act of checking the battery.

Measured on the round-4 bundle. Gate 7 was green, one `git -C work/environment/repo status
--porcelain` was run to confirm the shipped tree was clean, and gate 7 went red with exactly one
path listed:

```
$ find work -newer upload/<name>.zip
environment/repo/.git
```

**Disambiguate on content, never on mtime.** The gate exists to guarantee that the artifact
which ships is the artifact that was measured, and that is a statement about bytes:

```bash
unzip -q "upload/<name>.zip" -d "$SCRATCH/gate7"
diff -rq "$SCRATCH/gate7" work        # empty means the gate is satisfied in substance
```

Empty output means re-zipping and re-running the battery would produce the same bundle, so the
red is an artifact of the check. Any file listed other than `.git`, or any `diff` output at all,
is the real thing the gate is for and the battery is genuinely void.

Cheapest habit: run the git-based Phase A checks **before** building the zip, which is the order
Step 5 already prescribes, and confirm the tree afterwards with the `diff -rq` above rather than
with another git command.
