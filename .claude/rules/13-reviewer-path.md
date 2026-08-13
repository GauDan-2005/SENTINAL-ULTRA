_Owner of CLAUDE.md **Section 12**. Loaded every session._

## 12. The Reviewer Path

Peer review is **in scope**. It was not until 2026-08-11, and `CLAUDE.md` still said so while two
reviews were being run; that line is now corrected. Everything here was established on mithril.js
2021 and expressa 132. Evidence and open caveats in `learning/reviewer-path.md`.

The reviewer is a second Expert Contributor who repeats the submitter's document and logic review,
reaches an **independent** verdict, and returns Accept / Needs Revision / Reject plus a 1-5
Submission Quality Score. The official description is `docs/tasking-guide.md:345-459` and it is the
source of truth for the form.

### 12.1 Folder discipline

Reviews live in `review_tasks/<Original Directory Name>/`, a sibling of `tasks/`. `CLAUDE.md` used
to propose `reviews/`; the name in use is `review_tasks/` and it is gitignored the same way `tasks/`
is. The shape is the submitter shape minus `upload/`:

```
review_tasks/<Original Directory Name>/
  task.md                    # the evidence record behind the answer
  download/
    <submission_id>_submission.zip
    original/                # pristine extract, NEVER edited, no commands run in it
  work/                      # copy of original/, every command runs here
  answers/
    review_answer.txt        # the Path D template, Section 6
```

Every hard boundary from the submitter path still applies to `download/original/`. A reviewer does
not fix the bundle, so `work/` exists to run git and patch commands in, not to edit.

### 12.2 The live form is four questions, and `docs/` describes seven

Answer what the platform actually shows. Measured 2026-08-11:

| # | Question | Notes |
|---|---|---|
| 1 | Verdict: Accept / Needs Revision / Reject | **Reject only** when the "maximum revision reached" dialog is showing AND it still needs work |
| 2a | If Accept: confirm the six requirements | all six must be genuinely true |
| 2b | If Needs Revision: Error Categories | the 19 labels at `docs/tasking-guide.md:418-436`, internal tracking only |
| 3 | Explain in more detail what revisions are needed | the written answer, and the whole substance of the review |
| 4 | Overall quality of the submission, x/5 | 1-2 send back, 3-5 accept |

`docs/tasking-guide.md:401-459` additionally lists **Acknowledgement of Submitter Rebuttal** and
**How long did it take you to complete this review**. **Neither is on the live form.** Two independent
captures on 2026-08-11, mithril/expressa and then cista 172, agree on all four questions and on the
absence of those two, which is the condition `learning/reviewer-path.md` set for retiring the doubt.
**Stop carrying them as `PENDING` form fields.** When the submitter's answers were unavailable, say so
in a record block under the answer instead, because that is a real limit on the review.

Two things the cista capture added. The Q2 list is exactly the 19 labels at
`docs/tasking-guide.md:418-436`, in that order, and the platform calls them "for internal tracking
only", which is worth knowing before agonising over a borderline tick. And its Accept branch showed
**five** confirmation items rather than six, missing *Tests every requirement in the instructions* -
but that paste is visibly truncated elsewhere, so keep all six in the template until an untruncated
Accept-branch capture says otherwise.

### 12.3 Ask for the submitter's answers with the zip

The zip arrives alone. The reviewer's job is defined as verifying the submitter's findings, and
question 5 exists to force reading their Comments for Reviewer, so **ask for the submitter's form
answers in the same message that receives the zip**. If they never arrive, say in the answer which
field is unanswered. Never fill it in unread.

### 12.4 What to run, and in what order

`docs/tasking-guide.md:349` says a reviewer need not run Harbor, the oracle, the NOP or a build.
Run them anyway. On mithril three of eleven notes were measurements no reading would have produced,
and two were the lead findings.

1. Extract to `download/original/`, `cp -a` to `work/`, freeze the extract
2. **mtime forensics, before anything else.** A reviewer gets a zip and no diff, and the archive
   contains one anyway: the generator stamps every file at build time, so only what the submitter
   rewrote carries a later mtime. `unzip -l <zip>` and read the dates. On expressa 132 all 188
   entries read `2026-07-20 14:42` except `task.toml` at `2026-07-22 02:20`, which answered "what did
   this submitter actually do" in one command and framed the whole review. Two caveats to state
   whenever it is used: a tool that preserves mtimes leaves no trace, and an unchanged mtime supports
   "they did not rewrite this" but never "the content is wrong"
3. Mechanical sweep on `work/`: git hygiene and `fsck`, both patches apply at base, `unzip -Z` for
   script modes and the symlink count, stray artifacts, `instruction.md` vs `problem_statement.md`
4. **PR comparability at hunk level, never file list.** Page the GitHub API for the PR's per-file
   patches and compare changed-line sets **in both directions**. On mithril this returned 304
   changed lines each way with zero unique to either side, which removes quality score 1 in one step
5. Build the image; run NOP, oracle 3x, hostile delete. Use `bin/hostile-probe.sh`, never a
   hand-rolled `sed` (12.6)
6. **The forced-test-edit run.** Apply `golden.patch` alone, without `tests.patch`, and run the
   repo's own full test command. Compare against the same command at base. Any test green at base and
   red after golden is an edit the instruction may be forcing the agent to make, and every file
   holding one is a collision surface. expressa went 117 passing / 0 failing to 113 / **4**, and the
   compliant edit that follows was measured as an invalid trial
   (`learning/instruction-promises-the-suite-keeps-passing.md`)
7. **The move-the-created-file probe.** Apply `golden.patch`, move every file it **creates** to another
   location the instruction also permits, repoint whatever the solution itself imports it from, and re-run
   the verifier. The reward must not move. On cista 172 it went from 21 of 21 to **4 of 21**, because the
   graded test file opens with `#include "cista/type_hash/static_type_hash.h"` and `instruction.md` names no
   path anywhere. The bipartite mapping and pre-upload item 10 both miss this, since they walk identifiers
   rather than paths, and the oracle can never reproduce it
   (`learning/graded-tests-that-import-the-deliverable.md`)
8. **The two invocations, which are runs rather than findings and so get missed by re-reading notes.**
   Both are one command and both have produced a blocking defect on the one bundle where they were
   finally tried (`learning/audit-the-finished-review-not-just-each-finding.md`):
   - **`sh /tests/test.sh`**, never only `bash`. On mithril.js 2021 dash rejected `set -uo pipefail`
     at line 9, which sits **before** the `trap` that guarantees a reward file, so the run wrote
     **no `reward.txt` at all** rather than reward 0. Read it together with the script modes: a
     bundle shipping `0644` cannot be exec'd by shebang, so the harness must pick an interpreter and
     `sh` is a candidate. Those two are one finding, not two (`learning/solve-sh-under-sh.md`)
   - **The real oracle protocol, `solve.sh` then `test.sh`, three cycles in one container.** Not
     `solve.sh` three times, which is a weaker check about the oracle *script*. mithril.js 2021
     replays `solve.sh` 3 of 3 and scores **1 of 3** on the protocol, because `test.sh` applies
     `tests.patch` every run and restores nothing. A missing restore is an Oracle Check defect and
     not only an agent-collision defect (`learning/oracle-protocol-is-solve-then-verify.md`)
9. The stock-defect sweep (12.5)
10. Only then read for instruction quality, coverage and faithfulness

### 12.5 The stock-defect sweep is most of a review

Two independent reviews of two unrelated bundles found the **same five defects**, and a third found
six of eight. Check these first rather than discovering them, using the eight-row table in
`learning/stock-bundle-defect-baseline.md`:

| Defect | Check |
|---|---|
| Grader never gates on `raw_exit_code` | `grep -n raw_exit_code tests/test.sh`, then read the success expression |
| `python3` behind an `\|\| true` | `docker run --rm <base-image> sh -c 'which python3'`, then rebuild without the swallowed install |
| A correct solution that logs an object scores zero | oracle run with a `console.log({...})` added to the code under test |
| Scripts ship `0644` | `unzip -Z <zip> 'tests/test.sh' 'solution/solve.sh'` |
| No restore before `tests.patch` | `grep -n 'rm -rf\|base64\|tar -xz\|checkout' tests/test.sh` |

Plus the one that discriminates rather than always firing, and is worth a sentence either way:
**can an agent fake a pass by editing the assertion library it is graded by**
(`learning/agent-writable-test-infrastructure.md`). mithril: reward 1.0 with the solution unapplied.
expressa: 15 of 21, reward 0, and the review said so in its opening. cista: reward 1.0 with a broken
stamp, but only the 4 runtime-checked ids were defeated because the other 17 are `static_assert`s.
On a compiled language run the probe **on top of golden plus one break that still compiles**, since
leaving the solution unapplied only measures a build error there.

**Two rows are decided structurally, in a minute, before any container run** (LEDGER L66). Row 8
cannot fire when `grading.parser.framework` is `custom`, because the brace-slicing in `_find_json` is
only reached for `jest` and `mocha`. Row 7 does not apply when the verifier's `python3` is a hard
dependency of a **non-optional** install line rather than a passenger on an `|| true` chain. Report
those as absent with the reason. **An "absent" that you can justify is worth writing down**, because it
tells the submitter which of the usual suspects they do not have to go and look at.

### 12.6 Never hand-roll a mutation probe

Both wrong conclusions in the mithril review came from a `sed` that silently matched nothing, one of
them drafted as a **blocking** finding. `bin/hostile-probe.sh` already exits **3** with
`THE BREAK DID NOT LAND`, and `learning/verify-in-the-image.md:328,366` already records two earlier
instances. The knowledge was never missing; the reviewer path just had no hookup to the tooling. Use
the script, or copy its guard:

```python
assert needle in s, "NEEDLE NOT FOUND: " + needle[:70]
```

A probe that cannot prove it changed the tree measured nothing, and its result is not evidence.

### 12.7 Check a finding before filing it

An 8-dimension fan-out over mithril produced 77 candidates and adversarial verification refuted
**40**, four of them already written into the answer file. Every one failed the same four checks.

**Step 0, before the first finding is written: read `learning/LEDGER.md` itself.** Not
`learning/README.md`, which only describes it. The LEDGER is the list of claims this workspace has
already disproved and it is the one file whose entire purpose is to stop you writing something, so
reading it late means it cannot work. Measured: expressa 132 re-derived, re-filed and shipped the
`[verifier] 300` against `execution 1800` finding to the user, eleven hours after the mithril review
had filed it, disproved it and written it down as **L58** with the exact command. `bin/learning-query.sh`
is the fast lookup.

Then, per finding:

1. **Open the cited file at the cited line.** A wrong quote or line is grounds to drop it
2. **Read the cited rule's actual sentence.** Watch for a rule paraphrased stronger than it reads,
   and for a **practice** read as a rule. `.claude/rules/11-verifier-hardening.md:7` defines practice
   as "not in `docs/` ... applied with judgment", and Section 10.6 is headed `(mixed)`
3. **Check scope.** The em-dash ban is scoped by `.claude/rules/06-writing-rules.md:5` to form
   answers, not to `instruction.md`. Applying it to an instruction is L57
4. **Check the archive.** Identical in all five `_archive/*/download/original/` means it is the
   generator's default and not a submitter act (L58, L61 to L63). Present in five accepted
   `_archive/*/work/` bundles means it is the accepted shape (L59). Measure the baseline against
   `download/original/`, never against `work/`, or you are comparing this bundle to five other
   people's rewrites and calling the difference a defect. Section 8 now carries the measured
   `task.toml` baseline so it does not need re-measuring
5. **Check the remedy.** A `What to do.` line is an instruction someone will follow, so it can be
   wrong in a way an observation cannot. Before telling a submitter to delete a name or a literal
   from `instruction.md`, grep the graded tests for it and split the list. On expressa, thirteen file
   paths had zero graded references and were safe to cut, while six literals had a graded assertion
   behind them, so the draft advice to "delete the error strings" would have traded a non-blocking
   instruction finding for a blocking alignment one. `docs/guidelines.md:99` exempts strings that are
   a genuine public or API contract and `:101` requires stating a required response shape. Hand the
   submitter both halves

Then ask whether the remedy would make the bundle worse. L60 is a finding whose fix would have
weakened the verifier.

A finding that survives all six is worth filing even when it is uncomfortable. The same review filed
eleven notes that all survived adversarial verification, five of them measured in a container. The
discipline is not fewer findings, it is a baseline per finding. See
`learning/reviewer-findings-need-a-baseline.md`.

### 12.8 Writing the answer

`review_answer.txt` follows the **Section 5 writing rules in full**, the same as
`submission_answer.txt`: plain English, no em or en dashes, no internal check vocabulary, no
markdown symbols in prose, one unwrapped line per paragraph. Run `humanizer` over it as the closing
action, then re-run the Section 5 greps.

Shape both reviews converged on, and it works:

- **Open with what is right**, with the measurements, before any note. It stops a revision round
  undoing what already works, and it is the evidence for not scoring 1
- One numbered note per finding, each carrying the evidence, a `Guidelines reference.` line where a
  section supports it, and a `What to do.` line. Reviewers are asked to cite Guidelines sections for
  specific or easily-missed rules (`docs/tasking-guide.md`, reviewer form question 4)
- A closing note listing what you looked at and are **not** asking to change, so an unticked box is
  not read as an oversight. Include findings you filed and withdrew, with why
- Say which findings are measured and which are read. One line, "I built the image and ran the
  bundle, which a reviewer is not required to do", earns the measured ones their weight
- Severity discipline: **blocking** would fail a platform check or a must-have criterion on its own;
  **major** means a reviewer sends it back; **minor** is worth a note; **observation** is true but
  not actionable

### 12.9 Scoring

`docs/tasking-guide.md` defines the five points. The two that get confused:

- **1** is reserved for deviation from the source content (wrong PR, substituted repo code) or a
  low-effort submission. A bundle whose golden and tests reproduce the PR exactly cannot be a 1,
  however many verifier defects it carries. Establish this early with the hunk-level comparison
- **2** is source intact, execution has real gaps needing meaningful revision
- **3** is correct and complete with only minor residue, and it accepts

Both 2026-08-11 reviews landed on 2, in both cases with perfect PR fidelity and real verifier-side
defects.

### 12.10 Audit the finished answer, as a separate pass

12.7 checks each finding as it is formed. That is necessary and it is measurably not sufficient. An
adversarial pass over a finished, careful 11-note review of mithril.js 2021 left **1 note confirmed
and 9 weakened**, none refuted, and added two blocking findings the review had never run a check for.
Nothing was wrong about whether a defect existed. Everything wrong was in the second sentence of a
note, which is exactly what per-finding rigour does not look at
(`learning/audit-the-finished-review-not-just-each-finding.md`).

Run all five over the whole document, after the findings are written:

1. **Grep your own answer for baseline claims.** Any sentence shaped "N other bundles do X". Name the
   tree each was measured against, in the sentence. That review shipped **two** `work/` baselines
   while using the correct framing eleven lines later in its own closing note, so knowing L61 is not
   the same as running it (LEDGER **L72**)
2. **Read every `What to do.` line against every other one.** Two notes that are individually right
   can be jointly impossible. There, note 9 asked for the graded tests to be relocated and note 11
   said keep them where the PR author put them, about the same six ids
3. **Re-derive every number from the live bundle.** Not from `task.md`, never from an earlier draft.
   A figure you cannot reproduce on demand comes out, and the file-and-line citations carry the
   finding without it (LEDGER L53 applied to the reviewer side)
4. **Test each stated mechanism by removing the thing it names.** "These survive because `/app` is a
   git repository" died when `/app/.git` was deleted and the case still scored 15 of 15. LEDGER L5
   and L10, pointed at a review instead of at a defect
5. **Walk the run list, not the finding list.** Ask which invocations were never tried. Both new
   blocking defects sat behind 12.4 item 8, and no amount of re-reading the notes would have found
   either

A remedy scoped short and described as complete is its own class and belongs in check 2. "That one
change also fixes note 9" was measured false, because the restore covered three directories and
`tests.patch` creates a file at the repo root (LEDGER **L71**).
