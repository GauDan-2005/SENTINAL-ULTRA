---
id: preflight-false-positives
status: locally-verified
last_verified: 2026-08-07
verified_by:
  - 20260807_080545__tair-opensource_redisshake__1005
evidence: "bin/preflight.sh blocked a clean bundle on an upstream scripts/commands/config.json, and bin/checks/50-restore-shape printed UNRESOLVED on all 22 graded ids because Go ids are import paths"
applies_to:
  languages: [go, any]
  runners: [go-test, any]
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
