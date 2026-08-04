# tests.patch fails to apply after an agent edits the tests

Source: difficulty check results for `20260719_045042__oliver-oloughlin_kvdex__245`,
2026-08-01. This one killed 13 of 16 agent trials and made the difficulty verdict
untrustworthy, so it is the most expensive failure mode seen so far.

## What it looks like

```
Difficulty run incomplete — infra or harness failures left the verdict untrustworthy:
  claude-opus-4-8: only 3/8 valid trials (5/8 invalid: 5x harness failure:
    tests.patch did not apply (error: patch failed: tests/collection/enqueue.test.ts:16;
    error: tests/collection/enqueue.test.ts: patch does not apply));
  codex-gpt-5-5: only 0/8 valid trials (8/8 invalid: same)
```

The oracle passes 3/3 and the NOP is 0/1, so every local check is green. The failure only
appears once a real agent has been in the repo.

## Why it happens

`tests.patch` is applied at verify time, on top of whatever the agent left behind. If a
hunk's context lines sit in a file the agent also edited, `git apply` fails, `test.sh`
reports an infrastructure error, and the trial is scored as invalid rather than on merit.

On an API migration this is close to guaranteed. The hunk that broke everything was:

```diff
--- a/tests/collection/enqueue.test.ts
+++ b/tests/collection/enqueue.test.ts
@@ -16,8 +16,9 @@
-      const db = kvdex(kv, {
-        numbers: collection(model<number>()),
+      const db = kvdex({
+        kv,
+        schema: { numbers: collection(model<number>()) },
```

The task asks the agent to change `kvdex(kv, schema)` into `kvdex({ kv, schema })`. After
that change the existing test suite no longer compiles, so **any competent agent edits
those same call sites**. It is not optional behaviour that a better instruction would
prevent.

`test.sh` already falls back to `git apply --3way` and then `patch -p1 --forward`. Neither
saves you: a semantic overlap produces a conflict, not a clean merge.

## Reproduce it locally in one run

Do not trust a clean oracle run. Simulate an agent that touched the tests:

```bash
docker run --rm --network none -v "$PWD/tests:/tests:ro" -v "$PWD/solution:/solution:ro" \
  <image> bash -c '
    cd /app
    bash /solution/solve.sh
    sed -i "s/const db = kvdex(kv, {/const db = kvdex({ kv, schema: {/" tests/collection/enqueue.test.ts
    bash /tests/test.sh'
```

This reproduced the platform error byte for byte, same file, same line number.

## The fix

> **Superseded — read "Restore from the base commit, not the index" below before copying this.**
> The shape here fixes the common case and fails against an agent that stages or commits.
> It shipped, and the platform failed the task a second time on the same error.

Restore the test tree before applying the patch, so the agent's copy of the tests can never
influence grading. In `tests/test.sh`, immediately before the `tests.patch` block:

```bash
if command -v git >/dev/null 2>&1 && [ -d .git ]; then
  git checkout -- tests/ >>"$STDERR_LOG" 2>&1 || true
  git clean -fdq tests/ >>"$STDERR_LOG" 2>&1 || true
fi
```

Verified across all three scenarios afterwards:

| Scenario | Before | After |
|---|---|---|
| NOP | reward 0 | reward 0, 0/132 |
| Oracle, clean tree | reward 1 | reward 1, 132/132 |
| Oracle + agent rewrote the tests | **infra error, reward 0** | **reward 1, 132/132** |

Two things this buys beyond fixing the bounce. It removes a test-gaming route, since an
agent editing the tests to make them pass no longer affects the outcome. And it makes the
instruction's "do not modify the tests" line unnecessary, which matters because that line is
exactly what the prescriptiveness checker flags as verifier mechanics. Fix the harness, not
the wording.

## Do this on every task, not just the ones that bounced

The platform's own advice is to "rework tests.patch so it does not depend on solution-code
context (add new test files, or touch only dedicated test files agents are told not to
change)". That is right in principle, but on a migration the pre-existing tests *are* the
acceptance criteria for the new API, so they have to change. Restoring them at verify time
achieves the same guarantee without gutting coverage.

Rule: **if `tests.patch` modifies any file the agent has a reason to touch, add the restore
step.** Check with:

```bash
grep '^diff --git' tests/tests.patch | sed 's|diff --git a/||;s| b/.*||'
```

If that list is anything other than brand-new files, you need it.

## Brand-new files are not safe either

Source: `20260727_135618__AltBeacon_android-beacon-library__1177`, 2026-08-01. Reproduced
locally in a control run, so this is measured rather than predicted.

The rule above says a patch of nothing but brand-new files does not need the restore step.
That is wrong, and it is wrong in the most common case there is: **a feature task where the
agent writes its own test for the API it was asked to build.**

That task's `tests.patch` adds two files and modifies nothing:

```
lib/src/test/java/org/altbeacon/beacon/SettingsTest.kt
lib/src/test/java/org/altbeacon/beacon/SettingsJavaTest.java
```

An agent told to build a `Settings` class in `org.altbeacon.beacon` will very plausibly write
`SettingsTest.kt` in that same package. It is the obvious name in the obvious place. When it
does, `git apply` does not merge, it refuses:

```
error: lib/src/test/java/org/altbeacon/beacon/SettingsTest.kt: already exists in working directory
Falling back to direct application...
Performing three-way merge...
error: lib/src/test/java/org/altbeacon/beacon/SettingsTest.kt: does not exist in index
error: cannot read the current contents of '...SettingsTest.kt'
ERROR: failed to apply tests/tests.patch
```

`infrastructure_error: tests.patch did not apply`, reward 0, trial scored invalid. Same
verdict-destroying failure as the kvdex case, from a patch that touches no existing file.

Two runs of the same simulated agent (writes its own `SettingsTest.kt`, and renames a method
in a pre-existing test), differing only in `test.sh`:

| `test.sh` | Result |
|---|---|
| as shipped | infra error, `tests.patch did not apply`, reward 0 |
| with the restore step | reward 1, 229/229 |

**Revised rule: add the restore step on every task.** It costs four lines and there is no
case where it hurts. Point it at whatever directory the repo keeps its tests in — `tests/`
on kvdex, `lib/src/test/` here — and derive that from the patch rather than assuming:

```bash
grep '^diff --git' tests/tests.patch | sed 's|diff --git a/||;s| b/.*||' | xargs -n1 dirname | sort -u
```

Worth simulating too, not just adding blind. The one-run local check is cheap: apply the
oracle, drop a file where the agent would plausibly drop one, then run the verifier.

## Do not build the restore on git at all

Source: `20260719_045042__oliver-oloughlin_kvdex__245`, round 5 result, 2026-08-03.
**This supersedes the two git-based fixes below.** Both of them are correct as far as they go,
both passed every local scenario I could construct, and neither measurably worked on the
platform.

Three rounds, three restore designs, same outcome:

| Round | `test.sh` restore | Invalid trials |
|---|---|---|
| 3 | none | 13 of 16 |
| 4 | `git checkout -- tests/` + `git clean -fdq tests/` | 16 of 16 |
| 5 | `rm -rf tests` + `git checkout <base sha> -- tests` | 15 of 16 |

Every round reported the identical error, `patch failed: tests/collection/enqueue.test.ts:16`.

### What the agent transcripts actually show

The difficulty results artifact ships the agents' own session logs under
`solve/<model>_<n>/agent/sessions/`. They are worth reading before theorising, and they
contradicted the theory I had just shipped:

- `.git` **is present** in the agent's `/app`. It shows up directly in agent `ls -la` output.
  So "the workspace has no git metadata" is not the story either.
- Across 12 transcripts the only git command any agent ran is a single `git ls-files`.
  **No agent staged or committed anything.** So the index-versus-commit distinction that the
  round 4 fix turned on could not have decided those trials, even though it is a genuine
  defect in that code.

Two plausible mechanisms, both eliminated by measurement. What remains is a restore that does
not take effect at verify time for a reason not observable from this side. The lesson is not
"find the third theory". It is that a step this important should not depend on state you
cannot inspect.

### The condition that does reproduce it

Removing `.git` before the verifier runs reproduces the platform error byte for byte:

```
error: patch failed: tests/collection/enqueue.test.ts:16
error: tests/collection/enqueue.test.ts: patch does not apply
infrastructure_error: tests.patch did not apply, reward 0
```

Worth knowing that an orphan branch plus `gc --prune=now` does **not** reproduce it: the base
commit's objects survive and the checkout still works, reward 1, 132 of 132. A pruned object
store is not the mechanism.

### Corroborated: the platform's verify-time workspace is not a git repository

Added 2026-08-04. kvdex shipped the git-independent restore on a reproduction it could not
confirm, and the confirmation turned out to be in a **sibling task's** report. kvdex's own
difficulty result returned `Task Instruction Sufficiency: NOT_APPLICABLE`, so it never got the
per-trial analysis. `20260728_153118__jqno_equalsverifier__1166` did, and four independent
codex trial analyses in it name the mechanism in plain words:

> "an infrastructure incompatibility: **the workspace is not a git repository**, so the
> verifier's test-restoration step was unable to reset test files to their base state before
> applying tests.patch." (`codex-gpt-5-5_3`)
>
> "the verifier environment **lacked a git repository**, so the test.sh could not restore test
> source directories to their base-commit state" (`codex-gpt-5-5_4`)
>
> "the verifier was designed to restore them via git, but **the environment lacked git**"
> (`codex-gpt-5-5_5`)
>
> "The verifier's git-based test-file restoration mechanism also **silently failed because
> there was no git repository**" (`codex-gpt-5-5_7`)

Java, Maven, multi-module, against kvdex's Deno single-module. Same platform, same harness,
same `tests.patch did not apply` error class. Together with the local reproduction above, that
is two independent lines of evidence for the same condition.

Caveat worth keeping: these are LLM judges reasoning over trial logs, not platform source, and
only the codex judges say it. Strong corroboration of an already-reproduced hypothesis, not a
platform guarantee. It does not need to be one, because the fix does not depend on it.

**Which shipped bundles still carry a git-based restore.** Checked 2026-08-04.
`20260727_135618__AltBeacon_android-beacon-library__1177` still does, guarded by
`command -v git && [ -d .git ]`, so on the platform the guard fails and the restore is silently
skipped. It also uses a bare `git checkout -- <dir>`, which reads the index and so is defeated
by an agent that merely stages. It passes every local scenario, which is why it survived two
rounds there. Its rewrite is queued behind a separate blocker; the point for anyone reading this
note is that a bundle can look fixed for this defect and not be.

Note the cheap half of the fix does **not** transfer to that task. Its `tests.patch` already
creates both graded files, but 210 of its 230 graded ids live in files the patch never touches,
so a create-only patch plus `rm -f` would leave those 210 running the agent's own copies. Run the
"graded ids outside the patched files" check in [static-checks.md](static-checks.md) before
assuming create-only is enough.

**Two practical rules out of this.** First, when a difficulty report returns
`NOT_APPLICABLE` for instruction sufficiency, read the *other* tasks' reports before
concluding you have no evidence. The harness is shared, so a sibling task's per-trial
analysis is evidence about your task's environment. Second, the fact that a git-based
restore has never worked on this platform is now explained rather than merely observed,
so treat "restore without git" as the default on every task rather than as kvdex's
peculiarity.

### The fix: restore the whole tree from a payload embedded in `test.sh`

The first attempt put the archive at `tests/files/tests_base.tar.gz`. **The static checker
rejected it** on upload: `tests/` accepts only `config.json`, `grade.py`, `test.sh` and
`tests.patch`. See `learning/static-checks.md`. The payload has to live inside one of those
four files.

`test.sh` is the right host. It is read from `/tests`, so it is present whenever the verifier
runs at all, which makes it the most dependable restore source available inside the verifier.
Embed the tree as a gzipped tarball, base64'd into a **quoted** heredoc so nothing expands:

```bash
TEST_TREE="tests"
TEST_TREE_B64="/tmp/tests_base.tar.gz.b64"
TEST_TREE_TGZ="/tmp/tests_base.tar.gz"

cat > "$TEST_TREE_B64" <<'TESTS_BASE_B64_EOF'
<base64 of the gzipped tarball, wrapped at 76 columns>
TESTS_BASE_B64_EOF

if base64 -d "$TEST_TREE_B64" > "$TEST_TREE_TGZ" 2>/dev/null \
   || base64 --decode "$TEST_TREE_B64" > "$TEST_TREE_TGZ" 2>/dev/null; then
  rm -rf "$TEST_TREE"
  tar -xzf "$TEST_TREE_TGZ" -C . || <infra error, reward 0, exit 2>
else
  <infra error, reward 0, exit 2>
fi
```

A failed restore genuinely is a harness failure, so `infrastructure_error` is correct on those
two paths. That is different from using it to fail closed on a nonzero test exit, which
`verifier-fail-open.md` warns against.

Build the payload from the pristine base tree, from the repo root so it carries `tests/` at
top level, with deterministic flags so the bundle stays reproducible:

```bash
tar --sort=name --mtime='<base commit date>' --owner=0 --group=0 --numeric-owner \
    -czf /tmp/tests_base.tar.gz -C environment/repo tests
base64 -w76 /tmp/tests_base.tar.gz
```

Cost on kvdex: 158 files and 904 KB of tests became a 52 KB archive, 70 KB of base64 and a
93 KB `test.sh`. No leakage, because it is the tree the agent already has in its checkout.

Verify the payload round-trips before spending container time on it. Pull the block back out
from between the heredoc markers, decode, untar and `diff -rq` against
`environment/repo/tests`. Match the opening marker on the line ending `<<'TESTS_BASE_B64_EOF'`
and the closing one on a line that is exactly `TESTS_BASE_B64_EOF`, or a naive toggle grabs
the wrong half of the file.

### Whole tree, or only the patched files?

There is a cheaper variant that needs no payload: regenerate `tests.patch` so every graded
file is a create rather than a diff, then delete those paths in `test.sh` first. A create has
no context lines, so nothing can conflict. That is the better answer **when the graded ids
live inside the patched files**.

It does not transfer automatically. Measure first:

```
graded ids whose file is not touched by tests.patch
```

**Correction, 2026-08-04: equalsverifier 1166 is not the "concentrated" example this section
used to name.** Measured on the shipped bundle, it is **1124 of 1223** outside the patched
files. Its `fail_to_pass` really is concentrated, 0 of 19 outside across 10 protected classes,
and that is the number the earlier claim was describing. Its `pass_to_pass` is 1204 guards
spread over 129 test classes and none of them are protected by a create-only patch. Count
f2p **and** p2p, which is what the snippet in `CLAUDE.md` 10.3 does.

Watch the id shape when you run it. The original one-liner split on `::`, which is the Deno
and pytest form. JUnit ids are `fully.qualified.ClassName#method` with no `::` at all, so on a
Java task it reports *every* id as outside and sends you to the payload for the wrong reason.
The corrected snippet in `CLAUDE.md` 10.3 handles both and reproduces `102 of 132` on kvdex.

On kvdex that is **102 of 132**, because `pass_to_pass` is 112 regression guards spread across
a suite where only 45 files are patched. A create-only patch would leave those 102 running the
agent's own copies, which is a test-gaming route that a Quality Check round had already told
me to close. Zero means use the create-only patch. Anything else means restore the whole tree.

Measured after the change, with the row that previously failed now green:

| Scenario | Result |
|---|---|
| NOP | reward 0, `raw_exit_code 1`, `infrastructure_error: None`, 0 of 132 |
| Oracle, clean tree | reward 1, 132 of 132 |
| **agent edited tests, `.git` removed** | **reward 1, 132 of 132** |
| agent committed, wrote its own `tests/ext/encoder.test.ts`, `.git` removed | reward 1, 132 of 132 |
| hostile delete of a stated requirement | reward 0, 131 of 132 |

**Rule: the restore must not depend on anything in the agent's workspace, including `.git`,
and it must not depend on a file `tests/` is not allowed to contain.** Choose between the
create-only patch and a full-tree payload by measuring where the graded ids actually live.

### The which-shape one-liner misreads any runner whose ids are not `path::test`

Source: `20260723_030109__cryspen_libcrux__1165`, 2026-08-04.

The selector script (`i.split('::')[0] not in touched`) assumes pytest-style ids, where the part
before `::` is a file path. Run against a cargo task it returned **35 of 35 outside**, which would
have argued for a full-tree payload on a bundle where every graded f2p already lives inside a
patched file.

Cargo ids are `module::test` (`mlkem512::packed_roundtrip`) or bare (`consistency_512`). JUnit,
Go and Jest have the same property. The path is nowhere in the id, so nothing can ever match and
every id reads as outside.

**Rule: check that the script's `touched` set and the id scheme share a namespace before trusting
the number. If they do not, resolve it by hand** — for each graded id, find the file that defines
it and ask whether `tests.patch` touches that file. On libcrux the honest answer was 21 of 35
(the f2p all live in the created file, the p2p all live in two files the patch does not touch),
which still means payload, but for a reason the script did not actually establish.

### When the test tree is too big to embed, carry only the files that hold graded ids

Same task. `libcrux-ml-kem/tests` is **20 MB**, 19 MB of it KAT vector files, which is 9.0 MB of
base64 and unshippable inside a shell script. kvdex's 904 KB tree was the easy case.

The payload does not have to be the whole tree. It has to be **every file that defines a graded
id**, because those are the only ones whose contents can change a reward. On libcrux that is
`self.rs` and `ml-kem.rs`, holding all 21 `pass_to_pass` ids between them: **4.9 KB of base64**,
a factor of 1900 smaller than the tree.

```bash
tar --sort=name --mtime="$(git log -1 --format=%cI "$BASE")" --owner=0 --group=0 --numeric-owner \
    -czf /tmp/tests_base.tar.gz -C environment/repo/<test dir> self.rs ml-kem.rs
base64 -w76 /tmp/tests_base.tar.gz
```

Verify two things before shipping it, both cheap and both worth doing:

```bash
# 1. it round-trips OUT of test.sh, not just out of the tarball you built
awk "/<<'TESTS_BASE_B64_EOF'/{f=1;next} /^TESTS_BASE_B64_EOF$/{f=0} f" tests/test.sh \
  | base64 -d | tar -xzf - -C /tmp/rt && diff -q /tmp/rt/self.rs environment/repo/<dir>/self.rs

# 2. the payload really contains every graded id you think it does
python3 -c "
import json; p2p=json.load(open('tests/config.json'))['grading']['pass_to_pass']
src=open('/tmp/rt/self.rs').read()+open('/tmp/rt/ml-kem.rs').read()
print([i for i in p2p if i not in src] or 'all present')"
```

What the scoped payload does **not** cover is fixture data the graded tests read at runtime. The
KAT files stay in the agent's workspace, so an agent could trim them and quietly shrink a test
that iterates over them. Close that in the test rather than the payload, by asserting the count
you expect (`assert_eq!(vectors.len(), 775)`) instead of only that the list is non-empty.
Measured: trimming all three vector files to one line each takes the reward from 1 to 0.

### Pair the payload with a create-only sweep and git disappears entirely

The payload restores files the patch does **not** create. The other half is files it does: if the
agent wrote its own copy at a path `tests.patch` creates, `git apply` refuses with `already
exists`. Read the list out of the patch and delete it, which needs no git either:

```bash
sed -n 's|^+++ b/||p' /tests/tests.patch | while IFS= read -r _created; do
  [ -n "$_created" ] && rm -f "$_created"
done
```

With both halves in place the verifier has no git dependency at all. Measured on libcrux across
three agent shapes, all reward 1 with 35 of 35: a committing agent, the same agent with `.git`
deleted (which scored **0 with 14 of 35** under the git restore), and an agent that writes its own
file at the exact graded path with no `.git`.

### Confirmed on the platform, 2026-08-04

**This is the payoff line for the whole note.** kvdex 245 passed and was accepted on the round
that shipped the embedded payload. Four restore designs went through the platform's difficulty
check on the same task, same repo, same error:

| Round | `test.sh` restore | Invalid trials |
|---|---|---|
| 3 | none | 13 of 16 |
| 4 | `git checkout -- tests/` + `git clean -fdq tests/` | 16 of 16 |
| 5 | `rm -rf tests` + `git checkout <base sha> -- tests` | 15 of 16 |
| 6 | **base64 payload of the base test tree, embedded in `test.sh`, no git** | **passed, accepted** |

Every git-based design passed every local scenario and none of them moved the platform result.
The one that does not touch git worked first time. Treat the three git rows as a closed
question rather than something to re-derive: **do not write a git-based test-tree restore.**

The full sequence that got there, worth keeping because each step cost a round:

1. Restore the test tree at verify time, or an agent's edits make `tests.patch` conflict.
2. Do not restore it with git. The verify-time workspace is not a git repository.
3. Do not ship the archive in `tests/files/`. The static checker allows only `config.json`,
   `grade.py`, `test.sh` and `tests.patch`.
4. Embed it in `test.sh`, which is read from `/tests` and is therefore present whenever the
   verifier runs at all.
5. Choose full-tree over create-only by counting graded ids that live outside the patched
   files. Zero means create-only is enough. kvdex was 102 of 132.

## `git checkout -- <path>` reads the INDEX, so staging defeats the restore

Source: `20260719_045042__oliver-oloughlin_kvdex__245`, 2026-08-02. Measured in the task's own
image across four controlled runs. **This is a correction to the fix given above, which is
incomplete as written.**

The restore step went into round 3 and the difficulty check came back *worse*: 16 of 16
trials invalid against 13 of 16 before, with the same error to the character.

```
error: patch failed: tests/collection/enqueue.test.ts:16
error: tests/collection/enqueue.test.ts: patch does not apply
```

`git checkout -- tests/` restores the working tree **from the index**, not from a commit. An
agent that ran `git add` before finishing has already put its own version in the index, so
the restore is a silent no-op and the patch still lands on the agent's context. `git clean`
does not help either: once the agent commits, its new files are tracked, so nothing removes
them.

The local simulation that "verified" the original fix used an unstaged `sed -i`, which is the
one case the old restore handles. That is why it looked green.

Measured, same image, same patch, only the agent's git behaviour varying:

| what the agent did | old restore | `rm -rf` + checkout from base |
|---|---|---|
| edited tests, left unstaged | reward 1, 132/132 | reward 1, 132/132 |
| edited tests, `git add -A` | **reward 0, patch did not apply** | reward 1, 132/132 |
| edited tests, `git commit` | **reward 0, patch did not apply** | reward 1, 132/132 |
| committed + wrote its own copy of a file the patch adds | **reward 0** | reward 1, 132/132 |

Note the last row. Checking out the base commit over the top is not enough on its own,
because `git checkout <sha> -- tests/` only writes files that exist in that tree and leaves
anything the agent added sitting there. The directory has to go first.

**The restore that actually works**, with the base commit pinned in `test.sh` (which lives in
`/tests`, mounted read-only, and is never visible to the agent):

```bash
TEST_TREE="tests"
BASE_COMMIT="<base commit sha from task.toml>"
if command -v git >/dev/null 2>&1 && [ -d .git ] \
   && git cat-file -e "${BASE_COMMIT}^{tree}" 2>/dev/null; then
  rm -rf "$TEST_TREE"
  if ! git checkout "$BASE_COMMIT" -- "$TEST_TREE" >>"$STDERR_LOG" 2>&1; then
    # restore failed -> infra error, reward 0. Never grade on a tree you could not reset.
    exit 2
  fi
fi
```

Do not use `git rev-parse HEAD` for the base: if the agent committed, HEAD is the agent's
commit. Do not use the root commit either, since a real checkout has full history (kvdex has
607 commits). Pin the literal sha.

**Rule: whenever you add or review a restore step, test it with the agent's work STAGED and
COMMITTED, not just dirty.** An unstaged-only simulation proves nothing. Agents stage and
commit as a matter of course, and on this task all 16 trials did.

### Confirmed on a second task, and one gap in the snippet above

Source: `20260728_153118__jqno_equalsverifier__1166`, 2026-08-02. Java, Maven, multi-module,
against kvdex's Deno single-module. Same mechanism, same outcome, so this is not ecosystem
specific. The platform report named both shapes, `AbstractValueProviderTest.java: already
exists in working directory` for a file the agent wrote and `patch failed:
InstanceCreatorTest.java:1` for one it edited. A local simulation that writes its own copies of
both files the patch adds, edits the import block of two existing test files, and commits
everything reproduces the platform stderr line for line against the shipped bundle, and gives
reward 1 with 1223/1223 against the rebuilt one.

**The gap: `TEST_TREE` is not one directory on a multi-module repo.** equalsverifier keeps tests
under nine separate `<module>/src/test` roots. Hardcoding one path misses most of them, and
globbing `*/src/test` in the *current* tree misses any directory the agent deleted outright.
Enumerate from the base commit instead:

```bash
git ls-tree -d -r --name-only "$BASE_COMMIT" | grep -E '^[^/]+/src/test$' \
  | while IFS= read -r _testdir; do
      rm -rf "$_testdir"
      git checkout "$BASE_COMMIT" -- "$_testdir" >>"$STDERR_LOG" 2>&1 || true
    done
```

Derive the pattern from the patch rather than assuming, with
`grep '^diff --git' tests/tests.patch | sed 's|diff --git a/||;s| b/.*||' | xargs -n1 dirname | sort -u`.

**Incidental measurement worth keeping.** Running the *old* index-based restore against the
*new* patch, after the graded files had been renamed to names no agent would choose, gave
reward 1 under the same committing agent. So the rename in the section below independently
neutralises the "already exists" half, and the base-commit restore independently neutralises
the "patch does not apply" half. They overlap, which is the point. Ship both.

## The second half of the fix: give the graded tests their own file and prefix

Source: peer-review notes on `20260716_114438__ETLCPP_etl__1466`, read from another EC's
transcript 2026-08-02. Not reproduced here, but it is the same failure this note is about,
caught from the other side.

That task's `tests.patch` injected the graded tests into the repo's existing public
`test/test_algorithm.cpp` under ordinary names — `partition_move` among them. The reviewer's
finding:

> Reasonable agent authored tests using the same names produce UnitTest++ redefinition errors
> which is reflected in the supplied runs and is independently reproducible. Place evaluator
> tests in a separate verifier only source file and use uniquely prefixed suite and test
> identifiers so adding ordinary development tests cannot invalidate an otherwise correct
> implementation.

The restore step in this note fixes the *file*-level collision: the agent edited a file the
patch touches, so put the file back first. It does nothing about a *symbol*-level collision.
Restoring `test/test_algorithm.cpp` and applying the patch is exactly the right move, and the
build still fails, because the agent's own `TEST(partition_move)` lives in a different file
in the same binary and the linker or the framework's registration macro sees two of them.
Frameworks that register tests by name — UnitTest++, Catch2, GoogleTest with duplicate
`TEST(Suite, Name)` — all behave this way.

So do both:

1. Restore the test tree in `test.sh` before applying the patch (the rest of this note).
2. Put the graded tests in a file of their own that no agent would plausibly create, and
   prefix the suite and test identifiers distinctively — `test/test_sentinel_<topic>_verifier.cpp`
   with suite `sentinel_<topic>_f2p`, or the same idea in whatever the repo's framework uses.

`docs/tasking-guide.md` permits either shape — added tests arrive as "new functions **or**
new files" — so this is a choice, not a rule. Take the separate file every time. It removes
the collision surface, and it keeps the graded names out of the agent's view, which is worth
something on its own. Register the file in `config.json` `execution.commands` and the new ids
in `fail_to_pass`, and remember the new file still has to be added by `tests.patch`, not
shipped inside `environment/repo`.

## Related: agent timeouts on the same run

The same report showed `3/8 trials hit the agent timeout` at `[agent] timeout_sec = 1800`.
The gate passed (under 5 is not blocking) but accuracy from a timed-out trial is not a
difficulty signal. `docs/faq.md` says to raise it, and the ceiling is 7200. Raised to 7200.

Agents burning the budget rewriting a large test suite is itself a cause here, which the
restore step above does not prevent. It is another reason not to leave the timeout at the
authored default on a migration task.
