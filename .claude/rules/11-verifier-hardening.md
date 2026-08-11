_Owner of CLAUDE.md **Section 10**. Loaded every session._

## 10. Verifier hardening - what passes every eval and still comes back

Everything here comes from real submissions that cleared Static Checks, the Difficulty Check, the Oracle Check and the Quality Check judge, and were still sent back by the reviewing EC. The evals grade the task as declared; a reviewer reads what the verifier actually does. Work this list before the Step 5.5 runs, and again before Send to reviewer.

Each item says how far the docs back it. **Docs rule** = stated in `docs/`. **Docs criterion** = the docs state the property and this is the way to verify it. **Practice** = not in `docs/`; a defect-avoidance technique, applied with judgment and disclosed in Comments for Reviewer.

### 10.1 The grader must fail closed (docs rule)

`docs/guidelines.md` states the invariant: *the exit code should match the reward it writes.* A grader that scans stdout for the expected test names and writes `1.0` when it finds them breaks it - a compile failure, a timeout, a crash or a partially executed suite can all leave those lines in the log. Reward `1.0` alongside a nonzero exit is reproducible and a reviewer will reproduce it.

- Any nonzero exit from the test command means reward `0.0` and a nonzero exit from `test.sh`.
- If the script records the raw status (`raw_exit_code` or similar), it must also gate on it. Recording without gating is the defect.
- `set -euo pipefail`, and no `|| true` on the line that runs the suite.
- The NOP run is the check: it must show a nonzero raw exit as well as reward `0.0`. See `learning/verifier-fail-open.md`.

**The stock harness ships this defect.** The generic `test.sh` computes `success = not missing_required and not unexpected` and never reads the `raw_exit_code` it recorded three lines earlier. If you have not edited `test.sh`, your task is fail-open - this is not a hypothetical about someone else's bundle. Two things follow:

- **`execution.commands` is a list, so the runner's exit status is the LAST command's.** On a task that runs the suite and then a parser, a failing suite followed by a healthy parser gives status 0 and any gate you add never fires. Emit `set -e` at the top of the generated runner so the first failure propagates.
- **`set -e` does not cover a command that is itself a pipeline, and `test.sh`'s own `pipefail` does not reach the runner.** `bash /tmp/run_tests.sh` is a separate shell and does not inherit shell options, so a single command like `deno test … | python3 -c '<parser>'` runs with defaults and reports the parser's status however carefully `test.sh` was written. Measured on kvdex: `raw_exit_code 0` on a NOP where **zero tests ran**. Fix at the invocation, `RUNNER=(bash -o pipefail /tmp/run_tests.sh)`, and keep the `set -e` above as well - a multi-command task needs one, a piped task needs the other, and many need both.
- **Measure the runner's bare exit on a green tree before wiring the gate.** Some runners exit nonzero on a fully passing suite (leak or sanitizer complaints, skipped-test codes). Gating without checking fails your own oracle. kvdex answered `bare exit=0` with `ok | 152 passed | 0 failed | 2 ignored`, so the gate was safe. If yours answers nonzero on green, leave the gate out and say why in Comments for Reviewer. Tests the runner reports as *ignored* emit neither PASS nor FAIL, so an upstream skip is not a hazard when flipping `allow_extra_failures` to `false`.
- **Gate inside the grader, never with an early `infrastructure_error` exit.** The difficulty harness reads `infrastructure_error` as *invalid trial*, not *agent failed*. Bailing out on a nonzero exit would reclassify every non-compiling agent as an invalid trial and poison the difficulty verdict the same way a broken `tests.patch` does. Add the condition to the success expression instead (`and args.raw_exit_code == 0`) so the per-test report survives and the run still counts as an ordinary grading failure. Confirm on the NOP: reward `0`, raw exit nonzero, `infrastructure_error: None`.

### 10.2 `pass_to_pass` and unexpected failures (mixed)

`docs/guidelines.md` calls `pass_to_pass` "the regression guard" and ships it populated in the reference `config.json`, but only `fail_to_pass` is described as required - an empty `pass_to_pass` is not a documented violation. It is still a weak verifier, and reviewers treat it as one.

- Populate `pass_to_pass` with existing tests that cover the area the patch touches. Name real test ids and confirm they pass in the oracle run.
- `allow_extra_failures` **does not appear anywhere in `docs/`**. If the shipped `config.json` already carries the field and the run executes exactly the graded set, set it to `false`. Do not add the field to a config that lacks it - same rule as the legacy `task.toml` fields.
- Cross-check against `learning/stale-test-reports.md`: a `pass_to_pass` list that a build-time test report satisfies is not a guard at all.

### 10.3 Where the evaluator's tests live (practice)

`tests.patch` may edit a pre-existing public test file and the accepted kvdex bundle edits 44 of them (Step 2 item 6), so injecting graded tests into an existing suite is permitted. It is also how trials die. This section is a **practice**, not a rule: give the graded tests a file of their own and a distinctive prefix on the suite and test identifiers.

- An agent writing its own test named `partition_move` in the same public suite produces a redefinition error, the build fails, and the trial is scored as a failure for a correct implementation.
- A separate verifier-only source file with prefixed identifiers removes the collision surface and keeps the graded names out of the agent's view.
- This complements, not replaces, the restore step in `learning/tests-patch-vs-agent-edits.md`. Do both: separate file plus restoring the test tree before applying the patch. Measured: each half independently rescued a committing-agent run that the other half alone did not, so the redundancy is real rather than theoretical.
- **Name the new files something no agent would choose.** `SubtypeManagerTest.java` for a class called `SubtypeManager` is the obvious name in the obvious package, and an agent writes it as a matter of course. A `Sentinel`-prefixed verifier-only file cannot collide. Renaming changes the ids in `grading.fail_to_pass` and `execution.selected_test_files_to_run`, so update both, and keep the file matching whatever pattern the runner collects (surefire needs `*Test.java`).
- **The prefix has to be a legal module identifier in the target language, or the file is never collected.** A name the runner cannot import is not a graded test, it is a missing one, and every trial reports the ids missing while the file sits right there in the tree. Work with the language's own rules: `test_foo_sentinel.py` for pytest (a leading digit or a hyphen makes it unimportable), `foo.sentinel.test.ts` for deno and vitest, `SentinelFooTest.java` for surefire, `sentinel_foo.rs` for a cargo integration test. The shipped bundles use `SentinelSubtypeManagerTest.java`, `SettingsJavaTest.java` and `sentinel_pqcp_verifier.rs`. Confirm collection by running the suite once and seeing the new ids reported, not by reading the filename.

**The restore step, written correctly. Do NOT use git.** Three git-based designs shipped on kvdex 245 across three rounds and none of them measurably worked, while every one passed every local scenario that could be constructed. The verify-time workspace is not a git repository: reproduced locally, and named outright by four codex trial analyses in a sibling task's report. A restore that touches git, in any form, is a wasted round. Full history in `learning/tests-patch-vs-agent-edits.md`, now platform-confirmed by kvdex 245's acceptance on 2026-08-04.

Pick the shape by measuring where the graded ids live:

```bash
python3 - <<'PY'
import json, os, re
patch = open('tests/tests.patch', encoding='utf-8', errors='replace').read()
touched = set(re.findall(r'^diff --git a/(\S+)', patch, re.M))
added = '\n'.join(l[1:] for l in patch.splitlines()
                  if l.startswith('+') and not l.startswith('+++'))

# Graded ids come in four shapes and each maps back to a file differently:
#   tests/x.test.ts::name       path::name    (deno, pytest, vitest, jest)
#   pkg.ClassTest::method       fqcn::method  (gradle, kotlin)
#   pkg.ClassTest#method        fqcn#method   (junit, surefire)
#   module::test  /  bare_test  symbol only   (cargo, ctest, go)
# The first three name a file. The fourth does not, so it is resolved by where the
# symbol occurs: only in tests.patch means inside, in an unpatched test file means
# outside, nowhere means UNRESOLVED. Never let a shape you cannot map fall through
# and count as outside - that is the reading that picks the wrong restore design.
stems = set()
for t in touched:
    stems.add(t)                                              # exact path
    stems.add(t.rsplit('/', 1)[-1].rsplit('.', 1)[0])         # simple class / file stem
    parts = t.split('/')
    for lang in ('java', 'kotlin'):                           # FQCN, maven / gradle layout
        if lang in parts:
            stems.add('.'.join(parts[parts.index(lang) + 1:]).rsplit('.', 1)[0])

tokens = set()                                                # every word in the UNPATCHED tests
for root, dirs, files in os.walk('environment/repo'):
    dirs[:] = [d for d in dirs if d not in ('.git', 'node_modules', 'target', 'build')]
    if 'test' not in root.lower():
        continue
    for f in files:
        p = os.path.join(root, f)
        if not os.path.isfile(p) or os.path.relpath(p, 'environment/repo') in touched:
            continue                                          # skips broken symlinks too
        tokens |= set(re.findall(r'[A-Za-z_]\w+',
                                 open(p, encoding='utf-8', errors='replace').read()))

g = json.load(open('tests/config.json'))['grading']
inside, outside, unresolved = [], [], []
for i in g['fail_to_pass'] + g.get('pass_to_pass', []):
    head, name = i.rsplit('#', 1) if '#' in i else (
                 i.rsplit('::', 1) if '::' in i else ('', i))
    if head and ('/' in head or '.' in head):                 # the id names its file or class
        (inside if head in stems else outside).append(i)
        continue
    sym = re.split(r'[ (]', name)[0]                          # symbol-only id: cargo, ctest, go
    if head and re.search(r'\b%s\b' % re.escape(head), added):
        inside.append(i)
    elif re.search(r'\b%s\b' % re.escape(sym), added):
        inside.append(i)
    elif sym in tokens or head in tokens:
        outside.append(i)
    else:
        unresolved.append(i)

print(len(outside), 'of', len(inside) + len(outside) + len(unresolved),
      'graded ids live in files tests.patch does not touch')
if unresolved:
    print('UNRESOLVED:', len(unresolved), 'ids map to no patched file and no known symbol.',
          'Resolve these by hand before choosing a shape:', unresolved[:5])
PY
```

Re-measured 2026-08-04 against every bundle on this machine: `102 of 132` on kvdex 245, `1124 of 1223` on equalsverifier 1166, `210 of 230` on AltBeacon 1177 and `21 of 38` on libcrux 1165. On a synthetic fixture whose id matches neither a patched file nor any symbol it prints `UNRESOLVED` instead of a number. The earlier version of this snippet split every id on `::` and read the left half as a path, which made all 20 of AltBeacon's `pkg.ClassTest::method` ids and all 17 of libcrux's `module::test` ids look like files it had never patched. On libcrux it printed `35 of 35` against the 35-id config of the day, and hand resolution put the real figure at 21 outside. The config has since grown to 38 ids and the corrected snippet reads `21 of 38`, so the outside count is the number that matched. **An UNRESOLVED line means the count is not yet an answer.** Resolve those ids by hand and re-run before you pick a shape, because the whole point of the number is which of the two designs below you build.

**Zero → create-only patch.** Regenerate `tests.patch` so every graded file is a create (`new file mode`, `--- /dev/null`) rather than a diff. A create has no context lines, so nothing can conflict. Delete those paths in `test.sh` first, reading the list out of the patch itself with `sed -n 's|^+++ b/||p' /tests/tests.patch`. No payload needed.

**This is NOT the equalsverifier shape, despite what earlier revisions of this file and of `learning/` said.** equalsverifier 1166 measures **1124 of 1223** outside the patched files: its `fail_to_pass` is fully covered (0 of 19 outside, 10 graded classes protected) but its `pass_to_pass` is 1204 regression guards spread over 129 test classes. Only its f2p set is concentrated, which is what the earlier claim was really describing. A create-only patch there fixes the harness failure and still leaves 1124 guards running the agent's own copies.

**Anything above zero → restore the whole test tree from a payload embedded in `test.sh`.** kvdex was 102 of 132, because `pass_to_pass` was 112 regression guards spread across a suite where only 45 files are patched; a create-only patch would have left 102 graded tests running the agent's own copies, which is a test-gaming route a Quality Check round had already asked to close.

```bash
# build the payload from the pristine base tree, deterministically
tar --sort=name --mtime='<base commit date>' --owner=0 --group=0 --numeric-owner \
    -czf /tmp/tests_base.tar.gz -C environment/repo tests
base64 -w76 /tmp/tests_base.tar.gz     # paste between the heredoc markers below
```

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

The payload goes **inside `test.sh`**, not in `tests/files/` - `tests/` accepts only `config.json`, `grade.py`, `test.sh` and `tests.patch`, and a `tests/files/` archive is rejected by the static checker. `test.sh` is read from `/tests`, so it is present whenever the verifier runs at all, which makes it the most dependable restore source available inside the verifier. Deleting the tree first is what removes a file the agent created where `tests.patch` adds one. A failed restore genuinely is a harness failure, so `infrastructure_error` is correct on those two paths only. Cost on kvdex: 158 files and 904 KB of tests became a 52 KB archive, 70 KB of base64 and a 93 KB `test.sh`. It leaks nothing, because it is the tree the agent already has in its checkout. Verify it round-trips **out of the built zip** before spending container time on it.

### 10.4 A test must exercise the constraint it claims (docs criterion)

The coverage axis asks whether a broken or stub solution fails at least one test. A test that names a constraint but uses a fixture that cannot violate it fails that bar while looking like coverage.

- The shipped case: tests labelled bidirectional-iterator coverage built on `std::array`, whose iterators are random access. An implementation illegally depending on random access passed every one of them.
- Same shape elsewhere: "handles empty input" with a one-element fixture, "works without network" with a mock already installed, "rejects oversized payloads" with a payload under the limit.
- For every assertion, ask what implementation defect it would actually catch. If the answer is none, the fixture is wrong.

### 10.5 Hostile-delete before the zip (docs criterion)

Stub out one requirement the instruction states, in a throwaway copy, and re-run the verifier. Reward must drop to `0.0`. If it stays at `1.0`, that requirement has no enforcing assertion and the coverage axis is scoring a false positive. Run it against the requirement you are least sure is tested, not the easiest one.

### 10.6 Oracle shape (mixed)

- **`solve.sh` forward-only and idempotent.** Apply if needed, no-op if already applied, fail loudly when nothing applies. The sanctioned shape is four steps, in this order, and it is the one verified in a container with three consecutive applies (the "The fix" section in `learning/solve-sh-idempotency.md`):

  ```bash
  # 1. idempotency probe: if the REVERSE of the patch fits, the patch is already in
  if git apply -p1 --reverse --check --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
    echo "golden.patch is already applied; nothing to do."; exit 0
  fi
  # 2. plain forward apply
  if git apply -p1 --whitespace=nowarn /solution/golden.patch 2>/dev/null; then exit 0; fi
  # 3. --3way retry, which resolves context drift the plain apply will not
  if git apply -p1 --3way --whitespace=nowarn /solution/golden.patch; then exit 0; fi
  # 4. loud failure
  echo "ERROR: golden.patch did not apply cleanly." >&2; exit 1
  ```

  **`git apply --3way` is the prescribed retry, not a defect.** The banned thing is a reverse apply that counts as SUCCESS after the forward apply failed, because that inverts a correct tree on the second run and hides a patch that never applied. Step 3 above is a forward apply with better merge logic and cannot invert anything. Grep for the tell before you build: `grep -n 'apply.* -R' solution/solve.sh`. A `-R` inside a `--check` probe is the idempotency test and is correct. A `-R` that actually applies, as a fallback, is always the bug.
- **`solve.sh` applies `golden.patch` and does nothing else.** Every delete, rename and content edit of a tracked path lives inside the patch, never as an `rm`, `mv`, `sed` or `cp` line in the script. A script that mutates tracked files outside the patch passes the Oracle Check, because the check only asks whether the verifier goes green, and then the reviewer reads a golden patch that does not describe the solved state. The diff of the patch has to be the whole solution. Setup lines that touch nothing tracked (`cd /app`, `set -euo pipefail`, an echo) are fine.
- **Golden patch scoped to the PR.** `docs/guidelines.md`: only what resolves the task, no drive-by edits. Diff the patch's file list against the PR's (Step 2 item 9). Missing files count too - docs and changelogs the PR touched belong in golden.
- **Test files stay out of golden.** Golden carries non-test changes; graded test changes travel in `tests/tests.patch` (Step 2 item 9). Measured 2026-08-04: not one of the four bundles here has a test file in `solution/golden.patch`, including the accepted kvdex 245.

  **Open question, tested and not confirmed: does a PR-aligned expectation update to a pre-existing test belong in golden?** The claim was that it must, because the Quality Check applies golden alone. Checked against `docs/` and against the four bundles and it does not hold up as stated. `docs/tasking-guide.md:266` says the Quality Check judges READ the instruction, tests, oracle solution and task directory - they score files, they do not apply a patch. The check that does apply golden is the Oracle Check (`docs/tasking-guide.md:244`), and it runs `solve.sh` and then `test.sh`, so `tests.patch` lands there too and an expectation update inside `tests.patch` is present during the oracle run. So there is no measured mechanism that needs the update to travel with golden. Until a real report says otherwise, keep expectation updates in `tests.patch` and let the affected id move from `pass_to_pass` into `fail_to_pass`, since that is what it has become. What would settle it: a downloaded Quality or Oracle report that fails on a pre-existing test whose expectation `tests.patch` updates. Paste that report into `learning/` if it ever arrives.
- **Check the oracle against whatever standard the instruction names.** If the instruction says an API should behave like a known library function, read the oracle against that function's actual contract. The shipped case was a `stable_partition` analogue returning `first` instead of `last` for a single matching element - correct-looking code, wrong at n == 1, and no test caught it.
- Script mode `0755` on both `solve.sh` and `test.sh`.

### 10.7 Fail-open Dockerfiles (limited)

`; exit 0` after a configure step, or an install chain ending in `|| true`, lets the image build green without the tools the agent and verifier need. It is a real defect, but "make the build fail closed" is **not** on the allowed-fix table in `docs/guidelines.md`, and that table is exhaustive.

- Fix it where it causes a listed issue: a swallowed install that leaves tmux, asciinema, bash or a required toolchain missing is the listed row, and installing the tool properly is the allowed fix. `command -v` gates for tools the verifier depends on fall under the same reasoning.
- Do not strip `; exit 0` purely as hygiene when nothing downstream breaks. Record it as a finding and say so in Comments for Reviewer.
- `docs/tasking-guide.md` still requires the build to be reproducible with test dependencies baked into the image; a build that hides its own failures is not.

### 10.8 Test-suite shape (docs criterion)

- **Distinct contracts, not padding.** The f2p count is a coverage floor, not a target to fill. The same assertion reminted across N sizes, or tautologies like asserting a constant against itself, add count and no coverage.
- **Test the wiring, not only the helper.** If the PR's point is that some path now uses a new helper, at least one f2p must go through that path. A perfect helper nobody calls can green the whole suite. This is the same failure the `No CLI/entry-point invocation` auto-REMOVE pattern describes.
- **No serialization accidents.** Do not pin object numbers, byte offsets, creation-order ids or other artifacts of how something happens to be written out. Assert the structure and the observable values.
- **"Any equivalent wording" is a contract.** If the instruction says a message may be phrased freely, the matcher has to accept the paraphrases - including every example the instruction itself gives. A regex demanding two literal tokens within 40 characters is not flexible wording.
