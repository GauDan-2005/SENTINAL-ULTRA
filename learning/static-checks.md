# Platform static checks on upload

Source: CodeBuild log from a real upload, 2026-07-31, task
`20260719_045042__oliver-oloughlin_kvdex__245`.

The platform runs `scripts.harbor.checks.cdg_sentinel_ultra.run_static_checks` against the
uploaded bundle. It reports **20 checks** and any single failure fails the build with
`exit status 1`, which blocks the submission.

## The one that bit us

```
❌ config: tests/config.json — grading.fail_to_pass lists 22 test(s), outside the 10–20 range

❌ 1 of 20 checks failed — see above.
```

**`grading.fail_to_pass` must contain between 10 and 20 entries. Twenty is a hard ceiling,
not a target.**

This is easy to get wrong because every other source reads as a floor:

| Source | Wording | Reads as |
|---|---|---|
| `docs/guidelines.md` | "at least 10 fail-to-pass tests ... ideally 10–20" | 21+ is fine, just not ideal |
| `docs/tasking-guide.md` | "every task needs at least 10 (ideally 10–20)" | same |
| Submitter form checkbox | "More than 10 fail-to-pass tests in the test suite" | more is better |
| `CLAUDE.md` | "the form checkboxes say 'more than 10', so treat 11+ as the safe bar" | more is better |

All four are floors. The checker enforces a **range**. Adding coverage past 20 fails the
build.

**Rule: keep `len(grading.fail_to_pass)` between 11 and 20.** Aim at 20 when coverage
warrants it, never above.

## Fixing an over-count without losing coverage

A fail-to-pass id maps to one **top-level test**, not one assertion. If you are over the
cap, regroup rather than delete. Nest the extra cases as sub-steps under a parent test and
the id count drops while every assertion survives.

In Deno that is a nested `t.step`:

```ts
// Two f2p ids
Deno.test("ext - jsonEncoder", async (t) => { /* 4 steps */ });
Deno.test("ext - v8Encoder",   async (t) => { /* 4 steps */ });

// One f2p id, same 8 assertions
Deno.test("ext - encoder factories", async (t) => {
  await t.step("json", async (t) => { /* 4 steps */ });
  await t.step("v8",   async (t) => { /* 4 steps */ });
});
```

pytest equivalent: fold sibling test functions into one test class or one parametrized
test. Jest equivalent: wrap sibling `test()` calls in a single `describe()` if the runner
reports at describe level.

Going 22 to 20 on this task took two merges (`jsonEncoder` + `v8Encoder`, and
`encoding barrels` + `encoding exports`) and cost nothing. Verify the count afterwards:

```bash
python3 -c "import json;print(len(json.load(open('tests/config.json'))['grading']['fail_to_pass']))"
```

Note that merging changes the suite's top-level test count too, so any figure you quoted
in `submission_answer` (total tests, required tests) moves with it. Re-run the oracle and
re-read the numbers off `report.json` rather than editing them by hand.

## The full check list

Worth reproducing locally before every upload, because all of it is cheap:

**Structure — directories**
- `environment/`
- `environment/repo/`
- `solution/`
- `tests/`

**Structure — files**
- `task.toml`
- `instruction.md`
- `environment/Dockerfile`
- `environment/problem_statement.md`
- `solution/solve.sh`
- `solution/golden.patch`
- `tests/test.sh`
- `tests/tests.patch`
- `tests/config.json`

**Content**
- `prompt`: `environment/problem_statement.md` matches `instruction.md`
- `config`: `grading.fail_to_pass` count is within 10–20
- `tests`: only allowed entries present — **exactly `config.json`, `grade.py`, `test.sh`, `tests.patch`**
- `agent-timeout`: `task.toml [agent] timeout_sec` within the 7200s limit

**Git**
- no remote configured
- no reflog
- `.git` within the 100 MB limit

Note what is **not** statically checked: `pass_to_pass` size, the verifier timeout, whether
`tests.patch` applies to the base commit, and whether the oracle passes. Those surface
later in the Difficulty, Oracle and Quality checks, so a green static check means very
little on its own.

## Regenerating `tests.patch` recreates the reflog

Caught this the hard way on the same task, one round after the first failure.

The shipped repo has `logallrefupdates = true` in `.git/config`. Regenerating `tests.patch`
means running `git apply`, `git add`, `git reset` and `git checkout` inside
`environment/repo`, and every one of those writes `.git/logs/HEAD`. So the reflog you
cleaned before the last zip is back, along with `ORIG_HEAD` and sometimes `FETCH_HEAD`.

The zip built straight after a patch regeneration therefore ships a reflog and fails
`git: no reflog`. Worse, the reflog carries your real git identity:

```
c9aba256... c9aba256... GauDan-2005 <gauravdan2005@gmail.com> 1785515631 +0530  reset: moving to HEAD
```

**Rule: git hygiene is the LAST step before zipping, not an early one.** Any time you touch
`environment/repo` with a git command after cleaning, clean again:

```bash
cd environment/repo
git reflog expire --expire=now --all && git gc --prune=now --quiet
rm -rf .git/logs .git/ORIG_HEAD .git/FETCH_HEAD
git apply --check ../../tests/tests.patch      # confirm gc did not break anything
git apply --check ../../solution/golden.patch
```

`.git` should end up containing exactly: `config description HEAD hooks index info objects
packed-refs refs`. Anything else is cruft.

Because `git gc` packs refs, `.git/refs/heads/` ends up empty, which is exactly the case
`zip -rD` and GUI compress tools break. Always `zip -rX` and confirm afterwards:

```bash
unzip -l <task>.zip | grep 'refs/'   # must list refs/ and refs/heads/
```

## The form asks more than the docs say

Not a check, but the same class of drift and it costs a round trip if you prepare the wrong
answers. `docs/tasking-guide.md` lists three handling-time questions. The live form asks
**four** (verified 2026-08-01):

1. review the initial task and determine its validity
2. complete the initial task rewrite only
3. **complete the additional questions on the form**
4. **complete all revisions** — updated every revision round

Question 3 is undocumented, and question 4 is tracked separately rather than folded into the
total. The first three sum to the total submission time; revisions sit outside it. Collect
all four from the submitter before writing `submission_answer.txt`.

## Reproducing the checker locally

There is no local copy of the checker, but every one of its assertions is a one-liner:

```bash
cd <task dir>
for f in task.toml instruction.md environment/Dockerfile environment/problem_statement.md \
         solution/solve.sh solution/golden.patch tests/test.sh tests/tests.patch tests/config.json; do
  [ -f "$f" ] && echo "ok   $f" || echo "MISS $f"
done
diff -q instruction.md environment/problem_statement.md && echo "ok   prompt matches"
python3 -c "
import json;n=len(json.load(open('tests/config.json'))['grading']['fail_to_pass'])
print(('ok   ' if 10<=n<=20 else 'FAIL '),'fail_to_pass =',n,'(range 10-20)')"
python3 -c "
import re;t=open('task.toml').read()
m=re.search(r'\[agent\][\s\S]*?timeout_sec\s*=\s*([\d.]+)',t);v=float(m.group(1))
print(('ok   ' if v<=7200 else 'FAIL '),'agent timeout_sec =',v)"
git -C environment/repo remote | grep . && echo "FAIL remote" || echo "ok   no remote"
[ -d environment/repo/.git/logs ] && echo "FAIL reflog" || echo "ok   no reflog"
du -sh environment/repo/.git
```

Run this before zipping and the static phase stops being a round trip.


## `tests/` accepts four filenames and nothing else

Source: rejected upload of `20260728_153118__jqno_equalsverifier__1166`, 2026-08-02.

```
❌ tests: unexpected entry in tests/: files (allowed: config.json, grade.py, test.sh, tests.patch)

❌ 1 of 20 checks failed — see above.
```

The bundle shipped `tests/files/base-test-tree.tar.gz`, a snapshot the verifier restored the
test tree from. It worked in every local run and never got past the static phase.

**`tests/` may contain only `config.json`, `grade.py`, `test.sh` and `tests.patch`.** No
subdirectories, no fixtures, no data files.

This contradicts the documented task structure. `CLAUDE.md` section 7 listed
`tests/files/` as "Optional test files copied into repo", and the Harbor layout in `docs/`
is where that came from. Both have been corrected. If a task needs data at verify time it has
to arrive inside one of those four files, or through `tests.patch`, or be baked into the image.

### What to do instead when the verifier needs pristine test content

The problem that snapshot was solving was `tests.patch` failing to apply after an agent edits
the test files. The answer that needs no extra file at all:

1. Regenerate `tests.patch` so every graded test file is a **create** (`new file mode`,
   `--- /dev/null`) rather than a diff against base. A create-only patch has no context lines,
   so there is nothing an agent's edits can conflict with.
2. In `test.sh`, delete those paths first, reading the list out of the patch itself:
   `sed -n 's|^+++ b/||p' /tests/tests.patch`, plus any file the change deletes outright.

Verified on that task across four cases (oracle, NOP, agent that commits, agent that deletes
`.git`): reward 1, 1223 of 1223 in all three non-NOP cases. See
`learning/tests-patch-vs-agent-edits.md` for why the git-based alternatives failed first.

### It only works when the graded set lives inside the patched files

The create-only trick restores exactly the files `tests.patch` touches and nothing else.
Everything else under the test root keeps whatever the agent left there. That is fine when
the graded ids are concentrated in the patched files.

**Correction, 2026-08-04.** This section used to call equalsverifier 1166 that shape. It is
not: measured on the shipped bundle it is **1124 of 1223** outside the patched files. Only its
`fail_to_pass` is concentrated (0 of 19). Count `pass_to_pass` too, and use the id-shape-aware
snippet in `CLAUDE.md` 10.3 — the one below splits on `::` and silently reports every id as
outside on a JUnit task, whose ids are `ClassName#method`.

Check before assuming it transfers:

```bash
python3 - <<'PY'
import json, re
patch = open('tests/tests.patch', encoding='utf-8', errors='replace').read()
touched = set(re.findall(r'^diff --git a/(\S+)', patch, re.M))
g = json.load(open('tests/config.json'))['grading']
ids = g['fail_to_pass'] + g['pass_to_pass']
outside = [i for i in ids if i.split('::')[0] not in touched]
print(len(outside), 'of', len(ids), 'graded ids live in files tests.patch does not touch')
PY
```

On kvdex 245 that prints **102 of 132**. Its `pass_to_pass` is 112 regression guards spread
across the whole suite, and only 45 files are patched, so a create-only patch would leave
102 graded tests running the agent's own copies. That is a test-gaming route, and closing it
is what a Quality Check round had already asked for. Anything over zero here means the
create-only patch is not sufficient on its own.

When it is not sufficient, the whole test tree has to be restored, and the payload has to go
somewhere `tests/` permits. Embedding a gzipped tarball as base64 inside a quoted heredoc in
`test.sh` works: on kvdex a 52 KB archive of 158 files became 70 KB of base64 and a 93 KB
`test.sh`. `test.sh` is read from `/tests`, so it is present whenever the verifier runs at
all, which makes it the most dependable restore source available. Do not ship a payload named
`grade.py` just because the name is on the allowed list; the stock `test.sh` embeds its own
grader and says explicitly that no sibling `grade.py` ships.
