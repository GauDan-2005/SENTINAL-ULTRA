_Owner of CLAUDE.md **Section 12**. Loaded every session. Rewritten 2026-08-19._

## 12. The reviewer path

Peer review is in scope. This file owns **what** a reviewer verifies, how a finding is graded, and how
the live form is written. `.claude/rules/14-reviewer-workflow.md` owns the timed sequence. The
standard review is platform-first and static. It is five active minutes with one recorded, static-only
five-minute extension. Routine local Docker, Harbor, Oracle, NOP, verifier, container, and mutation
runs are not reviewer work; the platform evaluation phase has already run before review, and
`docs/tasking-guide.md:347-349` calls local reruns optional.

The reviewer does not fix a bundle. `work/` supports static inspection only in the timed path. Both
pristine extracts stay untouched. A separately requested diagnostic may use the historical execution
tools, but it is outside the timed review and must never be described as a normal form requirement.

Two official documents govern this path:

- `docs/tasking-guide.md:345-459` defines the reviewer form, branches, categories, score, rebuttal,
  and duration field.
- `docs/reviewer-rubric.md` defines the defect bar, the five Major Pillars, eleven Secondary
  Requirements, the three task buckets, and reviewer integrity.

### 12.1 Folder discipline

Reviews live in `review_tasks/<Original Directory Name>/`.

```text
review_tasks/<Original Directory Name>/
  task.md                    concise timed evidence record
  task_details.md            received page evidence and submitter answers
  download/
    <original-id>_submission.zip original task archive, always supplied
    <submitted-id>_submission.zip optional submitter archive
    seed/                    original task only when a submitted archive is under review. Never edited.
    original/                pristine artifact under review: submitted when supplied, otherwise original task. Never edited.
  work/                      copy of the artifact under review for static inspection only
  answers/review_answer.txt  Path D, the paste-ready form answer
```

`bin/new-review.sh` makes this shape before the timer starts. The original task ZIP is always supplied.
For Fixable the submitted ZIP is also supplied and becomes the artifact under review. For Invalid/Not
Fixable it may or may not be supplied. For Valid-as-is, Invalid Difficulty, and every other branch it
is not supplied, so the original task ZIP is the artifact under review. Do not call an expected missing
submitted ZIP an identity conflict.

### 12.2 The live form and verdict

The live form has seven questions:

| # | Question | What matters |
| --- | --- | --- |
| 1 | Verdict: Accept / Needs Revision / Reject | Reject only under the maximum-revisions dialog. |
| 2a | If Accept: six confirmations | Tick only what the timed review actually verified. |
| 2b | If Needs Revision: error categories | Select the smallest set covering written notes. |
| 3 | Explain revisions or coaching | Specific, evidence-based prose. An Accept with 1 to 4 Minors still needs coaching. |
| 4 | Acknowledgement of Submitter Rebuttal | Read the rebuttal panel and select exactly one outcome. |
| 5 | Overall quality, 1 to 5 | Must agree with verdict. Use the live page for score 5 if the export is incomplete. |
| 6 | Review duration | Enter actual elapsed minutes. Never invent it. |

The conditional Accept and Needs Revision branches mean the page may render fewer questions at once.
The rebuttal acknowledgement and duration field are still real form fields. Comments for Reviewer and
the rebuttal panel are different surfaces; read both when available.

**Verdict arithmetic is not a timebox exception.** One confirmed Major produces Needs Revision. Five
distinct Minors produce Needs Revision. One to four Minors may be accepted with concrete coaching.
Observations do not count. A direct file, archive, page, or platform-artifact fact can establish a
Major when it meets the published pillar trigger. Do not demote directly confirmed leakage, a golden
mismatch, open networking, reward-hackability, or git exposure merely because the timed workflow did
not rerun it locally. Conversely, do not promote a suspicion whose static evidence is incomplete.

Use three buckets before writing:

- **Fixable** — the submitter can correct the issue inside permitted task scope.
- **Unfixable - Structure** — only a source-PR scope change or an environment change outside EC
  permissions can resolve it.
- **Unfixable - Difficulty** — the task cannot be recalibrated inside source scope.

The bucket is not a separate form control. Carry it in the first line of the written note and select
the corresponding error category when the form branch calls for one. A supported Invalid/Not Fixable
submission can be accepted. Do not convert task status into a mandatory Needs Revision or score 2.

**Invalid Difficulty** is a platform-set fourth validity status, not an argument from the submitter
and not an automatic Accept. It is reviewed under the same tally. Do not run a local difficulty
control or bounce leftover FAIL EASY evidence during a timed review.

### 12.3 Platform evidence and independent review

The original task ZIP is always present. The submitted ZIP follows the branch matrix in 12.1: required
for Fixable, optional for Invalid/Not Fixable, and absent otherwise. The reviewer page provides
submitter answers, all six evaluation panels, difficulty counters, previous reviewer feedback, and the
rebuttal panel. The standard path reads the current panels first:

- Static Checks and Prescriptiveness;
- Difficulty Check and Agentic Judge Quality Report;
- Oracle Check and Quality Check;
- difficulty counters and the version they describe.

A clean, current, internally consistent panel is evidence for its stated check and artifact version.
Do not repeat it locally as routine reviewer work. A detailed panel that contradicts its headline, a
version mismatch, a stale citation, a missing re-upload, or a concrete bundle contradiction is a
Section 13 extension trigger.

When `Reviewer Feedback` appears on the reviewer page, it is the first assessment step. Turn every
previous required fix into a current checklist row marked fixed, partial, still open, or not assessed,
with direct current evidence. Fixed items stay closed. Partial and still-open items are current findings.
A not-assessed item uses the Section 13 extension and blocks an Accept until it is resolved or described
as not demonstrated. Only after this reconciliation does the reviewer independently scan the task again
for new remaining issues.

The reviewer then checks the smallest material needed for the branch. For Valid-as-is, read coherence,
metadata, and apparent PR identity. For Fixable, read the claimed rewrites and their alignment. For
Invalid/Not Fixable, review the written explanation against the issue and bucket. The platform's green
headline never defeats a direct contradiction in those materials.

### 12.4 Standard static evidence

The standard timed command is:

```bash
bin/preflight.sh --review-fast "review_tasks/<name>/download/<reviewed>.zip"
```

`<reviewed>.zip` is the submitted ZIP when supplied, otherwise the original task ZIP.

It is ZIP-only and selects static, git, package, and grader checks. It does not build, run, mutate, or
restore anything. Read its direct FAIL or SKIP output against the artifact under review before filing a
finding.

The focused read covers `instruction.md`, its `environment/problem_statement.md` copy, `task.toml`,
`solution/solve.sh`, `solution/golden.patch`, `tests/config.json`, `tests/test.sh`, and only the
relevant hunk of `tests/tests.patch`. A seed diff is quick supporting evidence when both bundles are
already ready, but a full claim-by-claim table is extension work.

The following are **not** routine reviewer obligations:

- a full `learning/` or LEDGER read;
- source-PR API paging and whole-patch hunk comparison;
- broad arriving-bundle metadata baselines;
- requirement-to-test maps over the entire instruction;
- stock-defect sweeps, hostile probes, or audit mutations;
- Docker, Harbor, NOP, Oracle, local verifier, or any container run.

They become available only through a concrete Section 13 trigger. Historical learning notes showing
what such diagnostics found remain useful evidence, not standing instructions to repeat them.

### 12.5 Trigger-only diagnostics

A timed reviewer may use the single extension only after recording one of the four trigger classes in
Section 13. The allowed work is narrow and static:

| Trigger | Allowed extension work |
| --- | --- |
| Artifact or evaluation identity conflict | Compare page version, zip hash, archive entries, a ready seed, or a cited panel line. |
| Concrete claim or feedback contradiction | Diff the named file, compare the named claim, or read the exact rebuttal/previous note. |
| Direct Major or scope signal | Read the cited source hunk, source URL, archive fact, or targeted PR file. |
| Specific coverage or faithfulness discrepancy | Run `bin/coverage-map.sh` for the named requirement/test, then verify the reported candidate by eye. |

`bin/learning-query.sh --candidate '<term>'` may be used after a candidate exists. It returns matching
notes and LEDGER rows rather than making the reviewer read a corpus. `coverage-map` is a heuristic;
its output is a candidate, never a verdict by itself.

The historical local-run, mutation, stock-defect, and full-audit material is reserved for a separately
requested diagnostic session. If a diagnostic runs, use its safety instructions: mutation must prove
its edit landed, a result must name the actual command, and a diagnostic is never retroactively claimed
as part of the timed review.

### 12.6 Filing a finding

Before a note enters the tally:

1. Open the exact file, archive entry, panel, or submitter statement it cites.
2. Check the cited rule’s actual scope. A workspace practice is not a platform requirement.
3. State what the visible evidence proves and no more. If an extension expired before the mechanism was
   settled, drop the candidate.
4. Check the remedy against the evidence. Do not prescribe a change that worsens alignment or reduces
   permitted source scope.
5. Word a note against the bundle unless the submitter’s own statement is in front of you and directly
   contradicted.

Use an arriving-bundle baseline only when the finding truly depends on whether a value is a generator
default. A baseline decides wording, not the published rule. It is never a routine five-minute task.

### 12.7 Writing the answer

`review_answer.txt` follows Section 5 in full: plain, specific language; no em or en dashes; no
scoring ladder in the paste; one unwrapped paragraph per line; and no internal checker vocabulary.
Every concrete note retains its file, line, panel item, or archive evidence. The human-readable note
must explain the correction or coaching in terms the submitter can act on. When earlier `Reviewer
Feedback` exists, Q3 first reports every item as Done, Partly done, Not done, or Not assessed with its
current evidence. It then reports new findings from this review separately. That makes the return
checklist visible to the submitter instead of leaving it only in `task.md`.

Run the **humanizer skill as the last drafting action** over every reviewer-facing paragraph. It
copy-edits prose only. It must not alter evidence, remedies, citations, verdict, score, severity, or
numbers. Then run the short mechanical checks over the paste: banned internal vocabulary, no scoring
ladder, and no wrapped prose. Do not run a cross-review boilerplate search or a five-part audit as a
form-ready gate. Write opening and closing sentences from this bundle’s own evidence instead.

The record-only block below the marker holds the track, timer, optional trigger, platform evidence
reviewed, and tally. Scoring words, pillar labels, requirement numbers, and counts stay there rather
than in the paste.

### 12.8 Scoring

Scores 1 and 2 pair with Needs Revision. Scores 3 through 5 pair with Accept. Score 1 is reserved for
deviation from source content or a low-effort submission. Score 2 is meaningful revision with source
content intact. Score 3 is an Accept carrying minor residue. Scores 4 and 5 are clean Accepts. A
timed review with no confirmed Minor does not manufacture one to make the coaching field look busy.

### 12.9 Form-ready and deferred maintenance

The timed review is complete at form-ready handoff. Then, outside the timer, preserve the concise
record, update the review status and calibration row, and archive after outcome is known. Do not delete
the zip or extracts. Do not claim a timed-static Accept has the same evidentiary scope as a historical
deep-battery Accept.


### 12.10 Historical deep-review audit

Historical notes citing Section 12.10 describe the former five-part audit: baseline wording, remedy
compatibility, number re-derivation, mechanism testing, and the run-list walk. It is not a timed
form-ready gate. Use it only after handoff in a separately requested diagnostic or maintenance pass.
The timed workflow instead ends at F5 with confirmed evidence and records deferred work at F6.

### 12.11 Historical diagnostic coverage

Historical notes citing Section 12.11 describe how the legacy container battery covered the Major
Pillars and Secondary Requirements. That mapping remains useful when a diagnostic is explicitly
requested. Standard timed review uses platform panels, the ZIP-only fast gate, direct static evidence,
and one trigger-gated extension. It never implies that an unrun legacy battery row was clean.
