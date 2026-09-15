_Owner of CLAUDE.md **Section 10**. Loaded every session._

## 10. Verifier hardening - what passes every eval and still comes back

Everything here comes from real submissions that cleared Static Checks, the Difficulty Check, the Oracle Check and the Quality Check judge, and were still sent back by the reviewing EC. The evals grade the task as declared; a reviewer reads what the verifier actually does. Work this list before the Step 5.5 runs, and again before you submit.

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
- **A pipe written into `execution.commands` itself needs BOTH fixes above, not either one.** The two bullets above are about the runner's invocation; this is about the config. `g++ ... 2>&1 | tail -n 80` hands the runner `tail`'s status, so `set -e` alone never sees the compile failure, and a trailing `for ... done` loop ending in `echo` makes the runner's last-command status 0, so `bash -o pipefail` alone is masked as well. **`pipefail` does reach a pipeline written inside the generated runner** - it is an option of the shell executing the script, so it governs every pipeline that shell runs. Measured on cista 172 in its own image, against a tree where nothing compiles: as shipped **exit 0**, `bash -o pipefail` alone **exit 0**, `set -e` alone **exit 127**, `set -e` prepended plus `bash -o pipefail` **exit 1**. So read `execution.commands` for pipes and trailing `echo` to learn that you need the pair rather than either half, and prefer fixing the config too, by capturing the status before the pipe or dropping the `tail`, which also stops `tail` keeping the wrong end of a C++ template error cascade
- **A parser with a fallback source makes this exploitable, so never report it as theoretical.** The stock `parse_jest` reads `_find_json(stdout) **or** _find_json(stderr)`, so the report the grader grades need not be the report the runner printed. Measured on mithril.js 2021 with the solution never applied and **two** lines added to product source, one logging an object so the stdout parse fails and one writing a forged all-pass report to stderr: `reward 1.0`, `success True`, 15 of 15, with `raw_exit_code 1` recorded in the same file. That review had written "the invariant is broken but no exploit is constructible here", reasoning from the runner's own `process.exit(failed === 0 ? 0 : 1)`, which is true about the runner and irrelevant. Read the parser for a second source before deciding the gate is hygiene, and note that on this shape the gate is the **only** standard fix that closes the route: a test-infrastructure restore cannot, because the injected lines are in product source, and moving the report off stdout cannot, because the forged report is what gets read either way (LEDGER L70)
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

**The restore step, written correctly. Do NOT use git.** Three git-based designs shipped on kvdex 245 across three rounds and none of them measurably worked, while every one passed every local scenario that could be constructed. A restore that touches git, in any form, is a wasted round.

**Do not give "the verify-time workspace is not a git repository" as the reason, because it is per-bundle and it is checkable.** That was true on kvdex 245 and equalsverifier 1166 and is measured **false** on firefly 1123, where the image carries `/usr/bin/git`, `/app` is inside a work tree at the declared base commit and the pack holds 53553 objects. A peer reviewer disproved the sentence in one command, and the rest of an answer inherits the doubt. The two reasons that hold either way: a directory-scoped `git checkout <base> -- <dir>` reverts the **product source** sharing those directories, measured at **reward 0.0, 0 of 59** with the oracle applied, and a `*_test.go`-scoped one fails **destructively** once `.git` is absent or partial, because the `find -delete` lands while the `git ls-tree` restore silently does not, leaving no test files at all. Full matrix in `learning/git-restore-fails-for-a-different-reason.md` (LEDGER L74). Full history in `learning/tests-patch-vs-agent-edits.md`, now platform-confirmed by kvdex 245's acceptance on 2026-08-04.

Pick the shape by measuring where the graded ids live:

```bash
python3 - <<'PY'
import json, os, re
patch = open('tests/tests.patch', encoding='utf-8', errors='replace').read()
touched = set(re.findall(r'^diff --git a/(\S+)', patch, re.M))
added = '\n'.join(l[1:] for l in patch.splitlines()
                  if l.startswith('+') and not l.startswith('+++'))

# Graded ids come in FIVE shapes and each maps back to a file differently:
#   tests/x.test.ts::name           path::name     (deno, pytest, vitest, jest)
#   pkg.ClassTest::method           fqcn::method   (gradle, kotlin)
#   pkg.ClassTest#method            fqcn#method    (junit, surefire)
#   example.com/m/pkg::TestFunc     IMPORT path    (go)  <- has / AND . and is NOT a file
#   module::test  /  bare_test      symbol only    (cargo, ctest)
# The first three name a file. The fourth names a PACKAGE and has to be mapped
# through go.mod. The fifth names neither and is resolved by where the symbol
# occurs. Never let a shape you cannot map fall through and count as outside.
stems = set()
for t in touched:
    stems.add(t)                                              # exact path
    stems.add(t.rsplit('/', 1)[-1].rsplit('.', 1)[0])         # simple class / file stem
    parts = t.split('/')
    for lang in ('java', 'kotlin'):                           # FQCN, maven / gradle layout
        if lang in parts:
            stems.add('.'.join(parts[parts.index(lang) + 1:]).rsplit('.', 1)[0])

# ---- Go support. Three things the naive version gets silently wrong: a test on a
# CONTEXT line of a modified file, a name defined in a DIFFERENT package, and a
# NESTED module whose path is not its directory. All three printed a number with
# zero UNRESOLVED, which is the worst way for this to fail.
modules = []                                                  # (module path, dir), longest first
for root, dirs, files in os.walk('environment/repo'):
    dirs[:] = [d for d in dirs if d != '.git']
    if 'go.mod' in files:
        m = re.search(r'^module\s+(\S+)', open(os.path.join(root, 'go.mod')).read(), re.M)
        if m:
            modules.append((m.group(1), os.path.relpath(root, 'environment/repo').strip('./')))
modules.sort(key=lambda t: -len(t[0]))

creates, cur = set(), None                                    # a create shows its WHOLE content
for line in patch.splitlines():
    m = re.match(r'^diff --git a/\S+ b/(\S+)', line)
    if m: cur = m.group(1); continue
    if line.startswith('new file mode') and cur: creates.add(cur)

defs_by_dir, complete, patched_dirs, cur = {}, {}, set(), None
for line in patch.splitlines():
    m = re.match(r'^\+\+\+ b/(\S+)', line)
    if m:
        cur = m.group(1); d = os.path.dirname(cur); patched_dirs.add(d)
        complete[d] = complete.get(d, True) and (cur in creates)
        continue
    if cur is None: continue
    m = re.match(r'^[ +]func\s+([A-Za-z_]\w*)\s*\(', line)     # added AND context lines
    if m: defs_by_dir.setdefault(os.path.dirname(cur), set()).add(m.group(1))

def go_classify(head, name):
    for mod, mdir in modules:
        if head == mod or head.startswith(mod + '/'):
            sub = head[len(mod):].lstrip('/')
            d = os.path.normpath(os.path.join(mdir, sub)) if mdir else sub
            d = '' if d == '.' else d
            if d not in patched_dirs: return 'outside'
            if re.split(r'[ (/]', name)[0] in defs_by_dir.get(d, set()): return 'inside'
            # not defined by the patch. Only safe to call outside when every patched
            # file in that directory is a create, so the patch shows all of them.
            return 'outside' if complete.get(d) else 'unresolved'
    return None

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
    if head and ('/' in head or '.' in head):                 # names a file, a class or a package
        if head in stems:
            inside.append(i); continue                        # a file the patch touches
        if os.path.exists(os.path.join('environment/repo', head)):
            outside.append(i); continue                       # a real file the patch does not touch
        go = go_classify(head, name)
        if go:
            {'inside': inside, 'outside': outside, 'unresolved': unresolved}[go].append(i); continue
        if '/' not in head:
            outside.append(i); continue                       # FQCN: the stems set is authoritative
        unresolved.append(i); continue                        # a slashed head that is neither
    sym = re.split(r'[ (]', name)[0]                          # symbol-only id: cargo, ctest
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

Re-measured 2026-08-16 against the seven archived bundles the snippet resolves, plus equalsverifier 1166, which is still in `tasks/`: `102 of 132` on kvdex 245, `1124 of 1223` on equalsverifier 1166, `210 of 230` on AltBeacon 1177, `21 of 38` on libcrux 1165, `19 of 43` on xlwings 2719, `0 of 24` on elfuse 162, and the two Go bundles the Go arm was added for, **`330 of 350` on hulak 118 and `7 of 33` on redisshake 1005**.

**The Go arm is not optional and its absence was silent, which is the worst way for this to fail.** Before it, a Go id's head (`github.com/xaaha/hulak/pkg/tui`) contained both `/` and `.`, so it took the file-path branch, could never match a repo-relative stem, and every graded id was counted **outside with zero UNRESOLVED lines**. hulak 118 printed `350 of 350` against a true 330, and redisshake 1005 printed `33 of 33` against a true 7 - both accepted bundles, so the defect has been live since 2026-08-05, when the id-shape-aware version was first written. The UNRESOLVED guard rail could not help, because nothing was unresolved; the snippet was confidently wrong rather than honestly stuck. LEDGER **L7** named this class in 2026-08-04 and prescribed exactly this snippet as the remedy, so L7 is reopened rather than closed. **Validated 2026-08-16 across eight bundles, seven archived plus equalsverifier 1166 from `tasks/`**: the four previously hand-checked figures reproduce unchanged, the two Go figures become correct, and nothing else moved. The eighth archived bundle, **statrs 315, is the one it does not resolve**: `3 of 127` with 106 UNRESOLVED cargo ids, so the cargo arm is unvalidated there and that count is not an answer yet.

**The first Go arm written for this was itself wrong in three silent ways**, each printing a number with zero UNRESOLVED, and all three are fixed above. A test function on a **context** line of a modified file was never found, because the search read only `+` lines. A name defined in a **different** package was matched, because the search read the whole added blob rather than the hunks under that package. And a **nested** `go.mod` whose module path is not its directory fell through to outside. The rule that replaced the guessing: a directory the patch does not touch is outside, a name the patch defines there is inside, and a name it does not define is outside **only when every patched file in that directory is a create**, so the patch shows all of them, and UNRESOLVED otherwise. On a synthetic fixture whose id matches neither a patched file nor any symbol it prints `UNRESOLVED` instead of a number. The earlier version of this snippet split every id on `::` and read the left half as a path, which made all 20 of AltBeacon's `pkg.ClassTest::method` ids and all 17 of libcrux's `module::test` ids look like files it had never patched. On libcrux it printed `35 of 35` against the 35-id config of the day, and hand resolution put the real figure at 21 outside. The config has since grown to 38 ids and the corrected snippet reads `21 of 38`, so the outside count is the number that matched. **An UNRESOLVED line means the count is not yet an answer.** Resolve those ids by hand and re-run before you pick a shape, because the whole point of the number is which of the two designs below you build.

**Re-run it on any open task whose number was recorded before 2026-08-16, because the correction moves some of them.** Measured on the five tasks still in `tasks/` that day: firefly 1123 goes from `59 of 59` to **`14 of 59`**, openwhispr 1002 to `144 of 229`, ziti-sdk-c 668 to `0 of 26`, deepfabric 297 to `0 of 16`, and equalsverifier 1166 is unchanged at `1124 of 1223`. A number that moves from all-outside to mostly-inside is the difference between needing the full payload and needing only a create-only patch, so a recorded figure from before that date is a design decision resting on a wrong measurement.

**Whichever shape you pick, derive the delete list from the patch and not from a directory list.** `tests.patch` can create a file **outside every directory the graded specs live in**, and an agent file at that path breaks all three apply routes even with those directories pristine. Measured on mithril.js 2021, where the patch creates `ospec-json-runner.js` at the repo root: with `render/tests`, `ospec` and `test-utils` all restored, `git apply` says `already exists in working directory`, `--3way` says `does not exist in index`, and `patch -p1 --forward` skips the hunk. **The third route is the dangerous one, measured on asciidoctor-web-pdf 79 (2026-08-19): `patch -p1 --forward` exits 0 while skipping the colliding create, so `test.sh` counts the patch as applied and the skipped graded file reports every id missing, a merit-looking zero with no infra marker.** Read the creates out of the patch itself, `sed -n 's|^+++ b/||p' /tests/tests.patch`, and delete every one before applying (LEDGER L71, `learning/patch-forward-skips-colliding-creates.md`). This is L9 in a new costume.

**A missing restore is also an Oracle Check defect, which is not where this section files it.** `test.sh` applies `tests.patch` on every invocation, so the second cycle lands on a tree that already carries it. Measured 1 of 3 on mithril.js 2021 and independently on cista 172. If you take nothing else from this section, take that a bundle with no restore fails the platform's 3/3 oracle bar on its own, whatever `solve.sh` does (`learning/oracle-protocol-is-solve-then-verify.md`).

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
- **Golden patch scoped to the PR, and this check runs ONE way only.** `docs/guidelines.md:289`: only what resolves the task, no drive-by edits. Diff the patch's file list against the PR's (Step 2 item 9) and file the extra files golden carries that the PR never touched. **The reverse direction is not a finding.** A docs or changelog file the PR touched and golden omits is the normal accepted shape: `docs/guidelines.md:289` requires no mirror, and **7 of 8** archived goldens ship no `.md` or docs file at all, accepted kvdex 245 included at 38 golden files against a 198-file PR, and the eighth is AltBeacon 1177 shipping its `CHANGELOG.md`. This bullet used to read "missing files count too", that note was filed on mithril.js 2021 and withdrawn, and the omitted changelog line there carried the PR URL and three issue numbers, so leaving it out was the safer reading (LEDGER L59). Outside reviewer prompt packs still state it both ways, which is where it keeps coming back from, so check L59 before filing it.
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

- **Distinct contracts, not padding.** The f2p count is a coverage floor, not a target to fill. The same assertion reminted across N sizes, or tautologies like asserting a constant against itself, add count and no coverage. cista 172 ships one of these by name: `static type hash - hash is stable across calls` compares a `constexpr` expression with itself and then calls the same function twice with the same template argument, so it cannot fail for any implementation that satisfies the other sixteen. When a count has to come **down** to reach the 10 to 20 range, a tautology is the id to retire first, and the coverage that replaces it goes in as sub-cases under existing top-level ids rather than as new ones.
- **Count how many graded ids share one translation unit or one process, because that is how many the suite can really distinguish.** On cista 172, 17 of the 21 ids compile into a single binary. Breaking one requirement took all 17 down together on a single compile error while the other 4 carried on, so the failure list reads as 17 problems and is one. This is not a defect on its own and it changes how every difficulty report on the task should be read, so say it in Comments for Reviewer. It also sets a floor on the hostile-delete gate: a break that stops the compile proves nothing about coverage, so aim probes at breaks that still build.
- **Test the wiring, not only the helper.** If the PR's point is that some path now uses a new helper, at least one f2p must go through that path. A perfect helper nobody calls can green the whole suite. This is the same failure the `No CLI/entry-point invocation` auto-REMOVE pattern describes.
- **No serialization accidents.** Do not pin object numbers, byte offsets, creation-order ids or other artifacts of how something happens to be written out. Assert the structure and the observable values.
- **"Any equivalent wording" is a contract.** If the instruction says a message may be phrased freely, the matcher has to accept the paraphrases - including every example the instruction itself gives. A regex demanding two literal tokens within 40 characters is not flexible wording.

### 10.9 A process-killing error path needs a child process, not a try/except (practice)

Added 2026-08-11 from redisshake 1005, accepted carrying this in five graded test files.

Some runners execute a whole package or module in **one process**: Go is the clearest case, and any suite sharing an interpreter has the same exposure. A library whose error path ends in `log.Panicf`, `log.Fatal`, `os.Exit` or `sys.exit` then does not fail one test - it takes the binary down and every other graded id in that unit is reported **missing**. On a task about feeding a parser malformed input, that is the main path rather than an edge case.

- **Find it before designing the tests:** `grep -rnE 'log\.(Panicf|Fatalf|Panic|Fatal)|os\.Exit|sys\.exit' environment/repo/<pkg>`
- **Do not wrap it.** Catching the exit is not available, and a broad `try/except` around a test body is banned by the Section 4 checklist anyway
- **Re-exec the test binary as a helper.** The graded test spawns its own binary filtered to a helper test, passes the input through the environment, and reads the result back out of the child's combined output. The helper skips when its flag is absent and appears in **neither** `fail_to_pass` nor `pass_to_pass`. Ignore the child's exit status deliberately, because a crash there is the measurement
- **Encode the result, do not scrape it.** Print a prefixed line with an argument count and quoted arguments; read it back with the language's own unquoting. Binary payloads and embedded newlines survive that and a whitespace split does not
- **Use a killable child with a deadline for a liveness assertion.** A loop that never terminates cannot be measured by a test that waits for it. Go's `exec.CommandContext` with a 10 s deadline separated a base tree that sat on the full deadline from a fixed one returning in 0.017 s
- **Disclose it in Comments for Reviewer**, because a reader opening the file will ask why two tests skip

The payoff shows up in the NOP as well as the oracle: the graded ids still execute and report individually at base, instead of the whole unit reading as a compile-shaped zero that `verify-in-the-image.md` warns proves nothing.

**Same one-process family, third mechanism: a graded test that mutates a process singleton leaks into the
rest of the suite.** Added 2026-08-14 from android-beacon 1177. The graded tests run in the same process
as the pre-existing suite, so a test that binds a consumer to a process-wide manager, installs a static
calculator, or builds and starts a service leaves that state behind for the next test class. The suite is
usually ordered such that the damage lands on `pass_to_pass`, which is the half you did not write and the
half a reviewer reads as a regression.

- The teardown has to be **class-level** (`@After`, `tearDown`, a fixture finaliser), not a line at the
  end of the test body, because an assertion that throws skips everything after it and the leak happens
  precisely on the runs that fail
- It has to be **idempotent**, since it runs after tests that never created the state
- Prove it rather than assume it. The check is the full graded set, not the one test: on that task the
  battery ran all 230 ids after adding a test that builds a `BeaconService`, and `pass_to_pass` stayed at
  210 including the pre-existing `BeaconServiceTest` that drives the same class

This is the mirror of the section above. There the risk is one test killing the process; here it is one
test surviving it and changing what the next one sees.

### 10.10 Grading a target the verifier cannot run (practice)

Added 2026-08-11 from elfuse 162, accepted carrying this design.

When the repository targets a platform the verifier is not - macOS, Windows, a specific arch, a device - the reflex is to grade the source text, and `docs/guidelines.md:135` bans exactly that. The product not running is not the same as its translation units not compiling, so measure before conceding. Full ladder and traps in `learning/platform-locked-repos-are-still-testable.md`; the shape that worked:

- **Stand-in headers carry types and constants, never function bodies.** Declare the unavailable platform's entry points and leave them undefined. A fake implementation is a shim that lies about behaviour
- **`#include` the `.c` file** when the thing you need is `static`. That is how a `static` dispatch table becomes reachable, and it is what turns "does the source contain the right words" into "call slot N and see what happens". Do not also link that unit
- **Reach the deliverable by a public number or a public path, never by a symbol the solution creates.** This is the same move as Section 10 on non-derivable names, and it has a second payoff: with no test naming a created symbol, the instruction stops needing to name one either
- **Interpose the host calls the contract is about.** Defining `getrusage` in the probe executable wins over libc for the linked units, records which argument the code asked for, and can forward to the real syscall so the numbers stay honest
- **Build the probe so it links at the base commit.** Then the NOP is an executed split rather than a compile-bound zero, with no audit to caveat
- **Two-pass link.** Parse `undefined reference to 'X'`: compile the `src/` file that defines `X` if there is one, otherwise emit `long X(); long X() { return 0; }` into a generated file, and `__thread long X;` when the linker reports a TLS mismatch. Compile that generated file **bare**, with no forced prelude and no `-I`, or it meets a real prototype and fails. `-Wl,--unresolved-symbols=ignore-all` is not a substitute: it resolves the symbol to address 0 and the call segfaults
- **The toolchain goes in the Dockerfile's verifier dependency layer**, grounded on `docs/tasking-guide.md:41` ("bake test dependencies into the image instead of fetching them when the tests run", because "the verifier runs fully airgapped"). Do **not** cite `docs/guidelines.md:332` as the authorization: it carries the useful "adding a missing dev package" phrase but it is a row of the **Not Fixable** table, not the allowed-fix one. The allowed-fix table does not list this case, so disclose it as an inference in Comments for Reviewer

### 10.11 Restore the test INFRASTRUCTURE, not just the graded specs (practice)

Added 2026-08-11 from the mithril.js 2021 peer review.

`tests.patch` protects the graded test bodies. Nothing protects the **assertion library those bodies
call**, and on most repositories it sits in the agent's own writable checkout. Measured, with the
solution never applied:

```
render/render.js at the BASE commit, untouched.
One clause added to ospec/ospec.js record():   message = null;
  -> reward 1.0, 15 of 15, exit 0
```

**The Section 10.3 measurement does not answer this.** That snippet counts graded ids living outside
the files `tests.patch` touches, and on mithril it returned `0 of 15`, whose documented reading is
"create-only patch would suffice". That is correct for **collisions** and blind to this, because the
gaming route runs through `ospec/` and `test-utils/`, which `tests.patch` never touches at all. Two
questions, one snippet:

| Question | Answered by | Fix |
|---|---|---|
| Can an agent's edit break the patch apply? | the 10.3 count | create-only patch, or a payload |
| Can an agent's edit **fake a pass**? | the probe below | restore the infrastructure |

So when 10.3 returns zero, do not stop. Enumerate every path the graded specs import that
`tests.patch` does not create, and put those in the restore payload alongside the spec directory.

**On a compiled language the "leave the solution unapplied" form is not available**, because the graded
translation units name symbols the base commit does not have, so the compile fails before any assertion
runs and the probe measures a build error. Apply golden first, break **one** stated requirement in a way
that still compiles, then neuter the library, and read that against the same break without the neuter.
Measured on cista 172, where `tools/doctest/doctest.h` is a tracked file the graded compile line pulls in
directly: stamp value off by one gives reward 0 at 20 of 21, and the same break plus `CHECK` and
`REQUIRE` redefined to `((void)0)` gives **reward 1 at 21 of 21**.

**A compile-time assertion layer raises the bar and does not grant immunity.** On cista 15 of the 21 ids
carry a `static_assert` mirroring their `CHECK` and 6 are runtime-only. Neither neuter alone is enough
and both together are, measured with the array `Size` dropped from the hash:

| edit | reward | passed |
|---|---|---|
| `CHECK` and `REQUIRE` neutered in `tools/doctest/doctest.h` | 0 | 4 of 21 |
| `#undef static_assert` plus `#define static_assert(...)` appended to the header golden creates | 0 | 20 of 21 |
| both | **1** | **21 of 21** |

The second edit lands in a file the **solution** creates, so the agent owns it outright and no restore
can protect it without deleting the agent's own work. So the honest reading is that mirroring a `CHECK`
with a `static_assert` costs an attacker a second edit and nothing more. Do not write "immune" into an
answer, and note that Rust's `static_assert!` is an ordinary macro with even less standing.

**Enumerate by running, not by reading the import lines.** The mithril review named three files and had measured one. Run each. All three reach reward 1.0 at 15 of 15 with the target file at base: `ospec/ospec.js` with `record()` forced to pass, `test-utils/domMock.js` and `test-utils/components.js` with a wrapper rebinding the assertion prototype. A probe that fails is not evidence a route is closed either, and the tell is instructive: patching domMock at **module load** throws `Assertions should not occur outside test definitions` and scores 0 of 15, while the same patch inside `o.beforeEach` scores 15 of 15.

**The restore narrows this class and cannot close it, so do not answer the residue with a longer list.** The graded specs load six agent-writable files into one process and three are product source the solution is allowed to touch, which no verifier may restore. Measured on mithril: 13 lines added to `render/render.js` **alone**, rebinding the ospec assertion methods to self-comparisons at the first `render()` call, gives reward 1.0 at 15 of 15 with `ospec/` and `test-utils/` byte identical to base. The blunt version that no-ops every assertion method scores 0 of 15, because it also kills the runner's own marker assertions, which is why the naive attack fails and the surgical one does not. What covers that residue is the 10.1 exit-code gate, not more restoring.

**The probe, two minutes, run it on every task.** Leave the solution unapplied so any reward above
zero is unearned, and **assert the mutation landed** or the result is not evidence
(`bin/hostile-probe.sh` exits 3 for exactly this). It discriminates rather than always firing:
mithril returned reward 1.0, expressa 132 reached 15 of 21 at reward 0 and earned a sentence saying
so. Full detail in `learning/agent-writable-test-infrastructure.md`.

### 10.12 The report must not share stdout with the code under test (practice)

Added 2026-08-11 from two peer reviews.

The stock grader locates its JSON by slicing stdout from the first `{` to the last `}`. When the
runner prints its report to the same stdout the agent's code writes to, any object the agent logs
lands before the report and the slice stops parsing. Measured with the **correct** solution applied:

| leftover debug line | reward | passed |
|---|---|---|
| none | 1 | 15/15 |
| `console.log("hi")` | 1 | 15/15 |
| `console.log({a:1})` | **0** | **0/15** |

A plain string survives; an object does not, and logging the structure under repair is how anybody
debugs one. This is a **false negative against correct work**, the opposite direction from the
fail-open grader in 10.1, so it needs its own check and its own fix: write the report to a file the
grader reads, to fd 3, or between unique markers the parser anchors on.

**A second instance of the same class, with a different signature.** An ospec `o.only` left behind in a graded spec file gives reward 0 at 0 of 15 with `raw_exit_code` **0**: the runner reports one test, the other 104 never run, every graded id lands in `missing_required`, and the runner saw no failures so the exit code is clean. The 10.1 gate does not cover this direction. Adding `"type": "module"` to `/app/package.json` is a third, at reward 0 and 0 of 15, and nothing in the module graph requires that file. Two things that look dangerous and are not, worth recording so they are not re-derived: deleting `/app/node_modules` and deleting `/app/.git` both leave reward 1.0 at 15 of 15.

**Do not fix this by switching `grading.parser.framework` to `custom`.** It is a one-field change that removes the brace slice and looks like the cheap answer. `parse_custom` is a line-anchored regex over the same shared stdout, so an agent can satisfy it by printing a matching line, which trades a false negative against correct work for a false positive that hands the 10.11 gaming class a second entrance. Keep to the report file, fd 3, or unique markers.

The same review found `python3` reaching the image only as a transitive dependency of `asciinema`,
behind an `|| true`. Rebuilt without that line, the image is green, `test.sh` dies at line 48 with
exit 127 and no `report.json`. Section 10.7 says not to strip `; exit 0` as pure hygiene; this is the
case where the swallowed install is load-bearing and the fix is the listed row. Both are now defects
7 and 8 in `learning/stock-bundle-defect-baseline.md`.


**The noisy writer is not always the agent's code. It is often a dependency of yours.** Added
2026-08-11 from openwhispr 1002. A graded test called a manager method that persists secrets, which
internally calls `dotenv.config()`. dotenv 17 prints a rotating promotional tip to stdout on every
call, one of which lands mid-stream in the runner's own TAP output and derails node's TAP parser:
the file is reported as a single `not ok` with a parse error, the remaining tests never run, and
the count silently drops from 13 to 6. It is intermittent, because the tip rotates and only some
of them break the parse.

The tell is a run that reports **fewer tests than the file defines** while every individual test
that did report passed. Count the ids, not the failures.

The fix is to silence the writer, not to work around the parser. dotenv reads
`process.env.DOTENV_CONFIG_QUIET` at call time, so one line at the top of the graded file, before
anything can load it, is enough. Any library that logs on import or on first use has the same
shape: a JSON-mode runner is just as easy to derail as a TAP one. When a graded test drives real
application code, ask what that code prints.

### 10.13 A graded test must not reach the deliverable by its file path (docs criterion)

Added 2026-08-11 from the cista 172 peer review.

`docs/guidelines.md:149-159`, the arbitrary naming problem, lists a **"new module/file name"** among
the names a test may only require when they are already in the base codebase, follow a standard
convention, or are stated in the instruction. The place that rule gets broken is not an assertion, so
neither the bipartite instruction-to-tests mapping nor pre-upload item 10 can see it. It is the
`#include`, `import` or `use` at the top of the graded test file, naming a path `golden.patch`
**creates**.

Measured: a complete, correct cista solution whose new header sat at `include/cista/static_type_hash.h`
instead of `include/cista/type_hash/static_type_hash.h` scored **reward 0, 4 of 21**, because the
compile died and every id in that translation unit reported missing. Deleting the one direct include
returned **21 of 21 for both placements**, since the public umbrella header the instruction already
requires the agent to wire up pulls the new header in anyway.

- **Reach the deliverable through a public entry point the instruction names**, never through its
  location. Same move as the non-derivable-symbol rule, one level up
- **The probe is three steps.** Apply `golden.patch`, move every file it creates somewhere else the
  instruction also permits and repoint whatever the solution itself imports it from, re-run. The
  reward must not move
- **The oracle can never reproduce it**, because golden puts the file exactly where the test expects.
  A green Oracle Check says nothing here, and the difficulty run reports it as a low pass rate rather
  than as a harness problem
- **Do not fix it by writing the path into `instruction.md`.** That satisfies derivability and buys a
  prescriptiveness finding, which is the trade `learning/prescriptiveness-check.md` warns about from
  the other side. Note that `docs/guidelines.md:159` gives the **opposite** remedy for the symbol
  case, "The instruction never specified that name -> add it in your rewrite". Repointing the test
  instead is this workspace's position, established on LEDGER **L24**, and it is why this section is
  a criterion rather than a rule: `docs/` states the property, the probe and this remedy are ours
- **A path can be derivable without being a literal.** kvdex 245 has six graded imports of paths its
  golden creates and states none of them by name, but `instruction.md:23` gives the layout as a rule
  ("each of the three encoders lives in its own directory with a `mod.ts` barrel"), which composes to
  the path under `docs/guidelines.md:157`. So a literal grep is a first pass, and the move-the-file
  probe is the verdict

**Deleting an `#include` from `tests.patch` by hand means decrementing its hunk header in the same
edit.** On cista, `@@ -0,0 +1,195 @@` becomes `@@ -0,0 +1,194 @@`. Skip it and `git apply` returns
`corrupt patch`, `patch(1)` returns `malformed patch`, and both apply routes in `test.sh` fail into
`infrastructure_error: tests.patch did not apply`, which costs a whole round of invalid trials.
Re-run `git apply --check` after any hand edit, or regenerate the patch instead.

Full write-up and the pytest, cargo, deno and JUnit equivalents in
`learning/graded-tests-that-import-the-deliverable.md`.

### 10.14 Grade the derivation, not only the instances (practice)

Added 2026-08-11 from openwhispr 1002, which was blocked at the agentic judge twice on this.

When the task's point is structural, that one definition exists and everything derives from it,
a suite can grade every stated behaviour and still be blind to the requirement. Measured: an
implementation that declared the required manifest and then hand-wrote the eight accessors and
the eight channel registrations beside it scored **13 of 13** against a suite whose every id had
a firing hostile probe. Each instance was correct. Nothing asked where the instances came from.

Grade it by changing the shared input and watching the consumers follow:

1. Add an entry that exists nowhere else in the repository.
2. Drop the consumers from the module cache, not just the input, since they captured the old
   value at load time.
3. Reload and require them to have picked the new entry up with no other edit.
4. Restore, and assert the entry is gone again, so nothing leaks into the next test.

Match the shared input by **resolved path** (`Module._resolveFilename(request, parent)`), because
consumers spell the same import differently. Say which consumers the property covers: a sandboxed
copy that inlines its data by design cannot follow a runtime change and must be excluded, or the
test asserts something the task never asked for.

The same hand-coded implementation then fails exactly the two derivation ids and nothing else,
which is what a discriminating test looks like. It is also a measured difficulty lever, since
hand-writing the instances is a plausible thing for a competent implementer to do, and it costs
no instruction surface: the requirement was already stated, and restating it as an outcome
("a ninth entry should work end to end on its own") rather than a mechanism ("the manager derives
its accessors from the manifest") answers the over-specification axis at the same time.

The trigger phrases in an instruction are "exactly once", "single source of truth", "adding one
should be enough" and "without touching anything else". A judge reads those as requirements.
Full detail in `learning/grade-the-derivation-not-the-instances.md`.
