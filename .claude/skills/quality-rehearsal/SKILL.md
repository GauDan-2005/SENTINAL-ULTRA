---
name: quality-rehearsal
description: Rehearse the platform Quality Check against a bundle before uploading it. Use when a fixed task is about to be zipped or sent to reviewer, to score the ten rubric axes and the must-have instruction criteria locally, with quoted evidence, so a failing axis costs an edit instead of an upload round.
---

> **Mirror.** This skill and `.cursor/rules/quality-rehearsal.mdc` hold the same rules. Edit both together — Cursor loads the `.mdc`, Claude Code loads this file.


# Sentinel 2.0 — Quality Check Rehearsal

Run this on a bundle **before** the zip, after the Step 5 pre-upload checklist and before or alongside the Step 5.5 oracle and NOP runs. It is the local dry run of the platform's rubric panel. Every finding cites a file path, a line number, and the exact text the platform judge would quote.

**Input:** a task directory — the working copy `tasks/<name>/work/`, or any unpacked bundle root that holds `instruction.md`, `task.toml`, `environment/`, `solution/`, `tests/`.

**Output:** a per-axis score from 1 to 5 with cited evidence, the must-have instruction criteria as pass or fail, a simulated `Status:` and `Reason:`, and a fix list. Nothing is mutated. This skill never edits the bundle it reads.

**Source of truth:** `docs/tasking-guide.md` for the rubric, `learning/quality-check-criteria.md` for what the check actually returns, `learning/source-pr-cross-check.md` for the gate every coverage finding has to pass before it is reported.

---

## 1. What you are rehearsing

The platform returns **two shapes**, and both have blocked a real submission in this workspace.

| | Rubric panel | Must-have criteria list |
|---|---|---|
| Looks like | `Status: ❌ REMOVE` / `Reason: oracle_spec_gap`, plus 10 axes scored 1–5 | `❌ 2 must-have quality criteria failed (13/15 criteria pass)` with `[Q9]`, `[Q10]` |
| Who scores | Claude Opus and GPT-5.5 independently, blinded adjudicator on a 2-point disagreement | numbered criteria, each tagged with a `criterion:` group and a `judge:` justification |
| Blocks on | see the verdict logic below | any must-have criterion, on its own |

The ten axes: instruction quality (realism, clarity, self-containedness, prescriptiveness), test quality (`test_coverage`, `test_faithfulness`), oracle quality (spec faithfulness, no gaming, robustness/reproducibility), packaging.

Documented verdict logic:

- **REMOVE** — adjudicated score on either test axis ≤ 2.0, OR either judge scored an axis ≤ 2 with the failure matching one of the six auto-REMOVE patterns
- **DISCUSS** — any single judge scored either test axis ≤ 2, OR the adjudicated score on either axis is ≤ 3.0
- **OK** — both test axes above 3.0 with no judge at ≤ 2

**Three things the documented logic does not tell you, all measured here:**

1. **`criterion: Instructions` items block on their own.** `20260728_153118__jqno_equalsverifier__1166` failed on Q9 and Q10 with healthy test axes. Do not carry over the "prescriptiveness is advisory" reasoning — that belongs to a different, non-blocking check (section 8 below).
2. **An oracle axis can REMOVE a task with both test axes clear.** `20260727_135618__AltBeacon_android-beacon-library__1177` round 2: `test_coverage` 3.5, `test_faithfulness` 3.5, `oracle_spec_faithfulness` 2.0, verdict REMOVE, `Reason: oracle_spec_gap`. **Read `Reason:` first and treat the axis it names as blocking**, whatever the verdict rules say about test axes.
3. **A 3 does not pass.** The verdict bullets above stop at DISCUSS; `docs/tasking-guide.md`, the Quality Check practical bar, states the consequence - a final above 3 on both test axes passes, a final of 3 or below on either axis sends the task to needs-revision, a single judge at 2 or below on either axis trips the same thing, and a final of 2 or below is a hard fail. Score honestly and fix the 3. Arguing a 3 up to a 4 in Comments for Reviewer has never worked and costs the round anyway.

So the bar to clear is: `test_coverage` and `test_faithfulness` both finishing comfortably above 3, no must-have instruction criterion failing, and no oracle axis you would score below 3. **This skill still rehearses to 4 or better on both test axes, as this workspace's own margin and not the documented bar** - a local score is one reader's estimate of what two judges will adjudicate, so leave it a point of slack.

**Where the real report lands, for the comparison.** When the platform blocks a task at the review gate, the one-line eval summary names only the stage that stopped it. The per-axis reasons sit in the **"Agentic Judge Quality Report"** field on the submission, collapsed and marked optional, lower down the form. Expand it - it carries the DISCUSS or REMOVE status and cites the specific axes and files, and it is the report to read this rehearsal against. See `docs/faq.md`, "My eval says 'Review gate blocked at the agentic judge / difficulty screen' - what does that mean?".

---

## 2. Read the bundle, and get the complete PR file list first

Before scoring anything:

1. `instruction.md` and `environment/problem_statement.md` — `diff` them, they must be byte-identical
2. `tests/tests.patch`, `tests/config.json` (`grading.fail_to_pass`, `grading.pass_to_pass`), `tests/test.sh`
3. `solution/solve.sh` and `solution/golden.patch` (or `init_state.patch`)
4. `environment/Dockerfile`, `task.toml` (`[metadata] source`)
5. The source PR file list, **paged**, per `learning/source-pr-cross-check.md`:

```bash
for p in 1 2 3 4; do
  curl -sS "https://api.github.com/repos/<owner>/<repo>/pulls/<n>/files?per_page=100&page=$p" -o "pr_p$p.json"
  [ "$(python3 -c "import json;print(len(json.load(open('pr_p$p.json'))))")" -lt 100 ] && break
done
```

The PR list is not optional decoration. Section 4 will not let you report a coverage finding without it, and page 1 alone produced a confidently wrong conclusion on a 198-file PR.

---

## 3. The six auto-REMOVE test patterns — check these first

Any one of these matching is a REMOVE on its own and outranks every score you were about to write. Read `tests/tests.patch` and `tests/test.sh` for each.

| Pattern | What it looks like | Fix |
|---|---|---|
| Silent skip | `@pytest.mark.skip`, `skipif`, `Deno.test.ignore`, `@Disabled`, catching `ImportError` and nulling the module — anything that lets a substantive test not run | A missing dependency must FAIL, not skip |
| No CLI/entry-point invocation | The instruction asks for a CLI, service or script and `test.sh` only drives library internals | Invoke the thing that was asked for |
| Pre-created artifact passes | `path.exists()` / `is_file()` with no content assertion, so `touch` passes | Pair every existence check with a content or behaviour assertion |
| Agent controls coverage | Tests iterate the agent's own output, so the agent can shrink the test surface | Enumerate expected items from the instruction or the environment |
| Fail-open | `if not output.exists(): return`, `try/except: pass`, assertions behind a precondition, `\|\| true` on the suite line | A missing or malformed artifact fails the suite |
| Overreach | Enforcing names, formats, thresholds, paths or conventions the instruction never states | Either state it in the instruction or drop the assertion |

Grep starters, run from the bundle root:

```bash
grep -nE '@pytest\.mark\.(skip|skipif)|Deno\.test\.ignore|@Disabled|@Ignore' tests/tests.patch
grep -nE 'except[^:]*:\s*pass|except\s*:|catch\s*\(\s*\w*\s*\)\s*\{\s*\}' tests/tests.patch
grep -nE '\|\| *true|; *exit 0|set \+e' tests/test.sh
grep -nE 'exists\(\)|is_file\(\)|isFile\(\)|assertTrue\(.*exists' tests/tests.patch
```

A hit is a candidate, not a verdict. `Deno.test.ignore` that was already ignored at the base commit is not your silent skip — check whether the patch added it or inherited it before reporting.

**The grader is part of this axis.** `tests/test.sh` must write reward `1.0` only when the test command also exited zero. The stock harness computes `success = not missing_required and not unexpected` and never reads the `raw_exit_code` it recorded, so an untouched `test.sh` is already fail-open. Confirm the gate is in the success expression and not an early `infrastructure_error` exit, which would reclassify non-compiling agents as invalid trials.

---

## 4. `test_coverage` — every stated requirement has a real enforcing assertion

The axis question: *would a broken or stub solution fail at least one test?* Gaps are false positives.

**Build the map by hand, requirement side first.** Walk `instruction.md` clause by clause, not sentence by sentence. One sentence often carries four requirements — the equalsverifier line 9 message requirement carried four clauses and the tests asserted two, which came back as `Reason: coverage_gap` two rounds after the leak fix that shrank them.

```
requirement (instruction.md:<line>, clause)  ->  assertion (tests.patch:<line>, test id)
```

Every requirement with an empty right-hand side is a coverage finding. For each one, before you report it:

### The PR cross-check gate — mandatory

**A coverage finding that describes the source PR is a spec gap, not a test gap.** A judge reads the instruction as the spec and the bundle as the implementation, so when the bundle faithfully reproduces a PR that does less than the instruction promises, it reports a missing test. Check the complete PR file list from section 2 before reporting:

- If the behaviour is **absent from the PR**, or the PR disabled or ignored it, mark the finding **`SPEC GAP — fix instruction, do not touch oracle`** and put the fix in `instruction.md` by narrowing the promise.
- If the behaviour is **in the PR and the oracle implements it**, it is a real test gap. Add the assertion.
- Changing the oracle to satisfy a coverage finding is reducing or replacing PR behaviour, which is an Invalid condition, not a fix. Expansion only.

On kvdex 245 all three coverage complaints came from the PR or from base. Narrowing two instruction sentences cleared the finding and changed no graded assertion.

### Fixtures that cannot violate the constraint

A test that names a constraint but uses a fixture incapable of breaking it fails this axis while looking like coverage. The shipped case: bidirectional-iterator tests built on `std::array`, whose iterators are random access, so an implementation illegally depending on random access passed all of them. Same shape as "handles empty input" with a one-element fixture, or "rejects oversized payloads" with a payload under the limit. For every assertion, name the implementation defect it would catch. If the answer is none, the fixture is the finding.

### The hostile delete decides the score

Do not score this axis from reading alone. In a throwaway copy, stub or delete the one requirement you are least sure is tested, re-run the verifier, and confirm the reward drops to `0.0`. A reward that stays `1.0` is an unenforced requirement and a coverage score of 2, whatever the map looked like. Discard the throwaway copy afterwards; it never touches `work/`.

### Suite shape

- **Distinct contracts, not padding.** The 10–20 `fail_to_pass` range is a floor with a hard ceiling, not a target to fill. The same assertion reminted across N sizes, or a tautology asserting a constant against itself, adds count and no coverage.
- **Test the wiring, not only the helper.** If the PR's point is that some path now uses a new helper, at least one `fail_to_pass` must go through that path. A perfect helper nobody calls greens the whole suite.
- **`pass_to_pass` is the regression guard.** Empty, where existing tests cover the patched area, is a weak verifier and reviewers treat it as one.

---

## 5. `test_faithfulness` — every assertion maps to something stated or implied

The mirror axis. Hidden requirements are false negatives: the agent cannot pass a test for a thing nobody told it.

Walk the assertion side of the map. For each assertion in `tests/tests.patch`, name the instruction clause it rests on. Anything with no clause is one of:

- **A hidden requirement** — move it into `instruction.md`, or relax the assertion.
- **A non-derivable name** — a symbol, path, message or constant the agent has no way to guess. Either the instruction states it or the test must not demand it.
- **A serialization accident** — object numbers, byte offsets, creation-order ids, JSON key ordering, whitespace, exact tolerances. Assert structure and observable values instead.
- **A wording contract broken** — if the instruction says a message may be phrased freely, a regex demanding two literal tokens within 40 characters is not free phrasing. The matcher must accept every paraphrase the instruction itself offers.

Do not confuse this with section 6. Section 6 asks whether a literal in the instruction leaked *from* the tests. This section asks whether an assertion in the tests has no home in the instruction. The same line can fail both, and the fix differs, so decide which direction the defect runs before writing it up.

---

## 6. The instruction criteria — these block on their own

Two must-have criteria have failed a real bundle in this workspace, both `criterion: Instructions`. Rehearse them explicitly and treat a hit as blocking.

### Q9 — navigation hand-holding

> *The instruction gives explicit navigation hand-holding, e.g. 'Where to look: <files>' or 'start by modifying <method>'.*

Candidate finder:

```bash
python3 - <<'PY'
import re
inst = open('instruction.md', encoding='utf-8').read()
NAV = (r"(?i)\b(where to look|start by|begin by|open the file|you (?:will|'ll) find|"
       r"lives? in|belongs? (?:in|with)|resides? (?:in|under)|located in|is defined in|"
       r"sits? (?:alongside|next to|with)|alongside|same (?:package|directory|folder|module) as|"
       r"under the (?:package|directory|folder))\b")
for i, l in enumerate(inst.split('\n'), 1):
    for m in re.finditer(NAV, l):
        print(f"Q9? instruction.md:{i}  [{m.group(0)}]  {l[max(0,m.start()-70):m.start()+90]}")
PY
```

Add a second sweep for bare paths and package roots: `grep -nE '\b[a-z0-9_]+(/[a-z0-9_.-]+){1,}\b|\b([a-z][a-z0-9]*\.){3,}[A-Za-z]' instruction.md`.

**Triage — this is where the finder stops and judgment starts.**

| Text | Verdict | Why |
|---|---|---|
| Where code **already** lives at the base commit | **Q9 FAIL** | Pure navigation. The agent is being told where to look |
| Where a **new** artifact should be placed | **Q9 FAIL** | Placement is rejected in every phrasing, including relative to a class that exists at base |
| The module tree, export map or public surface the agent must **create** | pass | That is the deliverable, not a hint |

Rule 3 in `learning/quality-check-criteria.md` was written after round 1 and corrected after round 2: **there is no safe phrasing for placement.** Replacing `In nl.jqno.equalsverifier.internal.instantiation: AbstractValueProvider...` with `It belongs with the other ValueProvider implementations, alongside ObjectValueProvider` failed Q9 again on the replacement. Delete placement and let the tests' imports rest on repo convention — after measuring how strong that convention is, because the cost lands on a correct agent that picks a different package and fails to compile. Where the convention is weak, say so in Comments for Reviewer.

### Q10 — leaking the exact strings the tests assert

> *The instruction leaks hidden test information, e.g. specific status codes, assertions, or internal test logic.*

Mechanical, and the strongest detector in this skill — it compares the two files directly instead of guessing:

```bash
python3 - <<'PY'
import re
inst  = open('instruction.md', encoding='utf-8').read()
patch = open('tests/tests.patch', encoding='utf-8', errors='replace').read()
added = [l[1:] for l in patch.split('\n') if l.startswith('+') and not l.startswith('+++')]
lits = set()
for l in added:
    lits |= set(re.findall(r'"((?:[^"\\]|\\.){12,})"', l))
    lits |= set(re.findall(r"'((?:[^'\\]|\\.){12,})'", l))
hits = sorted(s.replace('\\"', '"') for s in lits if s.replace('\\"', '"') in inst)
print(len(lits), 'long literals added by tests.patch;', len(hits), 'appear verbatim in instruction.md')
for h in hits:
    print('  Q10?', h[:160])
PY
```

**Triage, calibrated against the one accepted bundle.**

| Leaked literal | Verdict | Why |
|---|---|---|
| A quoted **message sentence** presented as the text to emit | **Q10 FAIL** | This is what Q10 actually objected to |
| A magic constant, status code or threshold that exists only to satisfy an assertion | **Q10 FAIL** | Verifier internals |
| A **required public name** the agent has to produce — export path, symbol, type name | pass | It is the deliverable. kvdex 245 was accepted with 7 such overlaps |
| A **content word** inside a stated prose requirement (`sealed`, `subclass`) | pass | The requirement is stated in prose, and prose requirements are not quoted message strings |

**The Q10 fix has two halves and skipping the second one costs a later round.** Rule 2 says drop the literal and relax the assertion. Relax **to** the requirement, not below it. After removing a literal, re-read the instruction sentence it came from, list every clause, and confirm each clause still has an assertion. On equalsverifier, line 9 carried four clauses, the relaxed pair covered two, and round 3 came back `Reason: coverage_gap` on the same sentence that had never changed. What to relax to: a content word the instruction states in prose, or a literal the repo contains and the instruction does not, which the agent derives from the code it already has.

### The rest of the instruction axes

Advisory in the documented logic, read by reviewers, and cheap to fix here:

- **Realism** — reads like a real ticket, not a template. No numbered how-to, no "Your task is to implement the following requirements:" scaffolding
- **Clarity and self-containedness** — success is fully specified, and every artifact it references exists in the repo
- **Prescriptiveness** — states requirements, not procedure. Naming the library or built-in the agent should have chosen is the classic hit
- **Leakage beyond Q10** — a PR URL, an issue number, a commit hash, a changelog line, or an environment spoiler

---

## 7. The oracle axes and packaging

### Oracle spec faithfulness

The axis that took a task to REMOVE with both test axes clear. The shape of an `oracle_spec_gap`: **the instruction promises behaviour the golden patch does not implement.** Walk the instruction's requirement list against `solution/golden.patch` and name the requirement for each hunk, and the hunk for each requirement.

There are exactly two honest fixes, and `learning/source-pr-cross-check.md` decides which:

- The gap is **inherited from the upstream PR** → the instruction is over-promising. Narrow it.
- The PR left it on a **TODO the instruction then promised** → completing the TODO is an allowed additive oracle edit.

**Narrowing usually needs a second attempt.** Take the new sentence and the list of unimplemented items and check each item against it by hand. On the AltBeacon task the narrowed sentence still promised exactly what the oracle skipped, and the axis fell instead of rising.

Also check the oracle against whatever standard the instruction names. If the instruction says an API behaves like a known library function, read the oracle against that function's real contract — the shipped defect was a `stable_partition` analogue returning `first` instead of `last` at n == 1, correct-looking and wrong.

### No gaming

No hardcoded answers, no fabricated tool output, no reading test-side ground truth, no fixture-specific shortcuts such as treating `df['Date'].max()` as "today". Litmus: **if the inputs were reshuffled within the spec, would this oracle still produce the right answer?**

### Robustness and reproducibility

Seeded randomness, no live network at run time, timeouts on subprocesses. `solve.sh` forward-only and idempotent — a reverse-apply fallback that counts as success inverts a correct tree on the second run and hides a bad patch, and the platform runs the oracle three times and needs 3/3. `git apply --3way` is the prescribed remedy for a patch that will not apply cleanly, not a defect. Both `solve.sh` and `tests/test.sh` at mode `0755`.

Golden patch scope: diff its file list against the complete PR file list. A patch spanning more files than the PR is a polluted oracle; files the PR changed and golden omits, including docs and changelogs, are the same finding in the other direction.

### Packaging

One stray dev artifact shipping into the container hard-caps this axis at 1, as does any solution material readable from an agent path.

```bash
find . -name '__pycache__' -o -name '*.pyc' -o -name '.DS_Store' -o -name '.venv' \
  -o -name '.pytest_cache' -o -name '.mypy_cache' -o -name '.ruff_cache' \
  -o -name '.idea' -o -name '.vscode' -o -name '*.orig' -o -name '*.bak' -o -name 'node_modules'
ls tests/          # only config.json, grade.py, test.sh, tests.patch may be here
git -C environment/repo fsck --unreachable --no-progress   # must print nothing
```

---

## 8. Do not confuse this with the prescriptiveness check

Two different checkers that read the same file and object to the same kinds of text.

| | Prescriptiveness check | Quality Check |
|---|---|---|
| Runs at | CodeBuild BUILD phase, on upload | after the bundle runs |
| Output | `score=0.42, 6 finding(s)` with `P1`..`Pn` | `13/15 criteria pass` with `Q1`..`Q15`, or the 10-axis panel |
| Blocks | **No.** It says so in its own message | **Yes**, on must-have criteria and on the axis named in `Reason:` |

They pull in opposite directions and chasing both to zero is a trap. Fix for the blocking one. **When a prescriptiveness finding quotes a requirement that a graded test asserts, the finding is asking you to break `test_faithfulness`. Refuse it and say so in Comments for Reviewer.**

Equally, a judge's mechanical claim can simply be wrong. Split the rationale into individual claims and reproduce each one in the task image before touching anything — a claim about resolution, visibility, linkage or types is a two-minute check. Fix the ones that reproduce, refute the others in Comments for Reviewer with the measurement. On libcrux 1165 one paragraph held one true claim and one false one, and they needed opposite responses.

---

## 9. Scoring and the report

Score each axis 1 to 5, and write the evidence next to the number. An axis with no cited file and line is not a score, it is a guess.

| Score | Meaning |
|---|---|
| 5 | No finding. The map is complete and the hostile delete failed the suite |
| 4 | One cosmetic finding with no effect on what passes or fails |
| 3 | A real gap you can name. **This bounces the task** |
| 2 | A gap that lets a stub or broken solution pass, or an assertion with no home in the instruction |
| 1 | An auto-REMOVE pattern, or an axis that cannot be assessed because the bundle does not run |

**A 3 is a fix, not an argument.** A final of 3 or below on either test axis sends the task to needs-revision (`docs/tasking-guide.md`, the Quality Check practical bar), so a 3 is a bounce and not a near miss. The panel has never been talked up from a 3, and a round spent explaining one is a round.

Report in the platform's own shape so the local run and the real report can be read side by side:

```
Status: ⚠️ DISCUSS
Reason: coverage_gap

Axes
  realism                    4
  clarity                    4
  self_containedness         4
  prescriptiveness           3   instruction.md:3 names the package roots
  test_coverage              3   instruction.md:9 clause 3 has no assertion
  test_faithfulness          4
  oracle_spec_faithfulness   4
  oracle_no_gaming           5
  oracle_robustness          4
  packaging                  5

Must-have criteria
  ❌ [Q9]  criterion: Instructions
       judge: the instruction states where code already lives - "<quoted sentence>"
              instruction.md:3
  ✅ [Q10] no test-asserted literal appears in instruction.md

Fix list
  1. instruction.md:3   delete the package-root sentence            (Q9, blocking)
  2. tests.patch:118    assert clause 3 of instruction.md:9         (test_coverage)
  3. instruction.md:22  SPEC GAP - narrow, PR 245 does not ship it  (do not touch oracle)
```

Rules for the report:

- Quote the offending sentence verbatim in the `judge:` line. The quote is what makes the fix targetable.
- Mark every PR-inherited finding **`SPEC GAP — fix instruction, do not touch oracle`**.
- Rank the fix list by what blocks: must-have criteria and the axis you would put in `Reason:` first, then test axes, then the advisory ones.
- Say what you rehearsed and could not measure. An axis you scored without running the hostile delete is a reading, and label it as one.

---

## 10. Measured behaviour of the two detectors

Both were run against real bundles on 2026-08-04. Use these numbers to calibrate what a hit means.

**`20260728_153118__jqno_equalsverifier__1166`, pre-fix round 0 — the bundle the real Quality Check failed on Q9 and Q10.**

The Q9 finder returns 4 hits, including the two sentences the real `judge:` text quoted:

```
Q9? instruction.md:7   [belongs in]  A new `ValueProvider`, `AbstractValueProvider`, belongs in `nl.jqno.equalsverifier.internal.instantiation`.
Q9? instruction.md:11  [lives in]    `SubtypeManager` lives in `nl.jqno.equalsverifier.internal.reflection` as a final, non-instantiable class
Q9? instruction.md:3   [resides under]  The relevant code resides under `equalsverifier-core`, in the package roots ...
Q9? instruction.md:1   [lives in]    sealed handling lives in a separate `SealedTypesFinder`
```

The Q10 detector returns `8 long literals added by tests.patch; 3 appear verbatim in instruction.md`:

```
Q10? Cannot instantiate abstract class
Q10? Please add prefab values for this type
Q10? it is sealed and no non-recursive subclass could be found
```

All three are quoted message sentences, which is the Q10 FAIL row of the triage table.

**`20260719_045042__oliver-oloughlin_kvdex__245` — the one platform-accepted bundle.**

Both detectors fire here too, and every hit is a true negative under triage:

- Q9: 1 hit, `instruction.md:23` "each of the three encoders lives in its own directory with a `mod.ts` barrel" — the module tree the agent must **create**, not where existing code sits.
- Q10: `41 long literals added by tests.patch; 7 appear verbatim in instruction.md` — `./encoding/json`, `jsonSerialize`, `brotliCompressor` and four more. All are required public names, which are the deliverable.

**So a hit is a candidate, never a verdict.** A rehearsal that reports the accepted bundle as failing is a bug in the rehearsal. Run the triage table on every hit and report only what survives it.
