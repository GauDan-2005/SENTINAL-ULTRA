_Owner of CLAUDE.md **Section 13**. Loaded every session. Rewritten 2026-08-19._

## 13. Timed reviewer workflow

This is the current reviewer sequence. It replaces the routine R1 to R11 battery for new reviews.
References to R1 to R11 in archived review records and learning notes describe the older deep-review
process and remain historical evidence, not current mandatory work.

**Standard path:** five minutes of active review after the submitted bundle, the current reviewer page,
and the review folder are ready. **Extension:** one extra five-minute allocation only after a named
trigger is recorded. The extension is targeted and static-only. It is not five minutes per finding and
it cannot be stacked. The timer ends when the answer is humanized and ready to paste. Archive and
calibration work comes later and never delays form-ready output.

The platform already evaluates the upload before a reviewer sees it. `docs/tasking-guide.md:347-349`
says a reviewer is not required to run Harbor, build Docker, or execute Oracle or NOP tests. Therefore
the standard path, and the extension, do **not** run Docker, Harbor, NOP, Oracle, a local verifier,
containers, hostile or gaming probes, mutation probes, determinism runs, or a stock battery. Those
remain tools for an explicitly requested diagnostic session outside this timed workflow.

This change does not weaken the official review. The reviewer still makes an independent assessment,
reads the rebuttal, applies the published Major/Minor arithmetic, chooses a score consistent with the
verdict, and records the actual elapsed minutes. `docs/reviewer-rubric.md:113-123` also still applies
to the reviewer's prose, so the final `humanizer` pass is mandatory.

### The timed spine

| Step | Active-time budget | What happens | Never |
| --- | --- | --- | --- |
| **F0** | before timer | Receive the original task zip, the branch-appropriate reviewed artifact, and current reviewer-page evidence. Bootstrap with `bin/new-review.sh`. | Start the clock while required inputs are absent. |
| **F1** | 0:00 to 1:00 | Start the timer. Turn every item in `Reviewer Feedback` on the page into a fixed / partial / still open / not assessed checklist before reviewing new work. | Treat a platform status such as Invalid Difficulty as the reviewer verdict. |
| **F2** | 1:00 to 2:00 | Run `bin/preflight.sh --review-fast <reviewed.zip>`. Read only its direct output. | Run a Docker or container check. |
| **F3** | 2:00 to 3:30 | Verify the previous-feedback checklist first, then independently scan the current task for new direct candidates. | Turn a generic concern into a finding. |
| **F4** | 3:30 to 4:00 | Count confirmed candidates and decide whether one recorded extension trigger exists. | Take an extension from curiosity, repository size, or a green panel. |
| **F5** | 4:00 to 5:00, or 8:30 to 10:00 after extension | Write the seven form answers, run `humanizer`, perform the short paste checks, record actual elapsed time, and hand over the answer. | Skip humanization or invent review minutes. |
| **F6** | after form-ready | Update durable records, harvest only genuine new evidence, and archive after the platform outcome. | Hold the form-ready answer for bookkeeping. |

**At minute five:** submit-ready if no extension trigger is recorded. **At minute ten:** submit-ready
regardless. Keep only confirmed findings. An unresolved concern is not a Minor, Major, observation, or
reason to exceed the cap.

### F0: Ready the inputs before the timer

The timer begins only after `bin/new-review.sh` has placed the artifact under review in
`review_tasks/<name>/download/original/` and made `work/`. It is the submitted ZIP when one belongs
to the branch, otherwise the original task ZIP. `download/seed/` exists only when a submitted ZIP is
under review and then holds the original task as a baseline.

Before starting, obtain the original task ZIP and the current reviewer page or its complete text. It
must identify the selected branch, the reviewed artifact when a submitted ZIP exists, the **review task
UUID** when the page provides one, submitter answers relevant to the branch, Comments for Reviewer,
rebuttal comments, prior reviewer feedback when shown, the evaluation panels, and whether the
maximum-revisions dialog is showing. The reviewer form itself requires the rebuttal acknowledgement;
read it rather than writing that it was unavailable.

| Submitter branch | Original task ZIP | Submitted ZIP | Artifact under review |
| --- | --- | --- | --- |
| Fixable | always required | always required | submitted ZIP |
| Invalid/Not Fixable | always required | optional | submitted ZIP when supplied, otherwise original ZIP |
| Valid as-is | always required | not supplied | original ZIP |
| Invalid Difficulty | always required | not supplied | original ZIP |
| Any other branch | always required | not supplied | original ZIP |

A missing submitted ZIP is therefore an identity conflict only for Fixable. Do not create a conflict
for a branch where the platform does not provide one.

If the page's branch matrix and artifact disagree, or the panel version does not match the artifact
under review, record **artifact or evaluation identity conflict** before the timer starts. That is an
extension trigger, not a licence to accuse the submitter without evidence.

### F1: Page-first read

Start `## Review timer` in `task.md` with the start time, the five-minute base deadline, and `Track:
timed-static-v1`. Then read only what affects this review:

- the submitter's verdict and the specific claims or Files Changed entries relevant to the branch;
- Comments for Reviewer, the rebuttal panel, and the complete `Reviewer Feedback` block if it is displayed;
- Static Checks, Prescriptiveness, Difficulty, Agentic Judge, Oracle, and Quality panels as page
evidence for the submitted version;
- the maximum-revisions state, which alone makes Reject available.

**Previous Reviewer Feedback is a required checklist, not background reading.** Before looking for
new defects, copy each earlier required item into `## Previous reviewer feedback` and mark it **fixed**,
**partial**, **still open**, or **not assessed**, with the current file, line, page panel, or direct
archive fact that settles it. A partial or still-open item becomes a current finding. A not-assessed
item automatically earns the single extension, because an Accept cannot be written until every earlier
required item has a status. Do not re-file a fixed item as new work.

Green panels are evidence for the checks and version they actually cover. They are not a warranty for
the whole bundle. Do not repeat a complete, current, internally consistent evaluation. Do extend for a
concrete contradiction in the visible bundle, detailed panel output, previous feedback, rebuttal, or
artifact identity.

**Invalid Difficulty** is a platform-set status at the difficulty-check cap. It still receives human
review. Do not demand a difficulty dossier, do not automatically Accept, and do not spend the timed
path reassessing difficulty. Apply the normal tally to the visible submission.

### F2: ZIP-only fast static gate

Run this exact command against the artifact under review, never a review `work/` tree:

```bash
bin/preflight.sh --review-fast "review_tasks/<name>/download/<reviewed>.zip"
```

The profile selects only `10-static.sh`, `20-git.sh`, `30-package.sh`, and `40-grader.sh`. It does not
run pristine verification, restore-shape, answer-file checks, build tools, Docker, or any verifier.
A skipped selected check is not a pass. Record concise PASS, FAIL, or SKIP names in `## Fast static
gate`; do not reproduce the full output in the reviewer paste.

A direct FAIL or SKIP that can affect the task is an extension trigger. It is not automatically a
verdict. Read the cited file or archive entry and decide whether the output describes this submission.

### F3: Focused static content read

Read the smallest material needed to assess the current submission. Do it in this order:

1. Resolve every previous-feedback checklist item against the current submission. Only then scan for
   additional new items that the earlier reviewer did not name.
2. `instruction.md` and `environment/problem_statement.md` for identity and stated success;
3. `task.toml` for source identity, base commit, network declaration, and directly relevant metadata;
4. `solution/solve.sh` and `solution/golden.patch` for a direct mismatch with the instruction or
   source scope;
5. `tests/config.json`, `tests/test.sh`, and the relevant hunk of `tests/tests.patch` for a direct
   requirement or verifier concern;
6. the changed file or claim named by the submitter. If a seed is already available, a quick diff is
   allowed, but a full claim table is extension work.

Read for the submission branch. Valid-as-is means coherence, metadata, and PR comparability. Fixable
means claimed rewrites and their alignment. Invalid/Not Fixable is prose-first, so confirm the stated
issue and its bucket rather than trying to run a missing zip.

A direct file or page fact may establish a Major when it meets `docs/reviewer-rubric.md:33-95`. Local
container execution is not a prerequisite for severity. Every note still needs a file/line, panel item,
or directly observable archive fact.

### F4: Extension gate and tally

Record a single extension only for one of these exact triggers:

1. **Artifact or evaluation identity conflict** — the re-upload may be missing, the page may be showing
a seed, or a panel/version citation does not match the artifact.
2. **Concrete contradiction** — a claimed change is absent, an unclaimed relevant change appears, prior
feedback is unresolved, rebuttal and bundle conflict, or detailed panel output contradicts a headline.
3. **Direct Major or scope signal** — a line-level leakage, unstated golden-only dependency, network or
git exposure, source/PR substitution, or an in-scope answer to a claimed Not Fixable reason that the
page does not settle.
4. **Specific coverage or faithfulness discrepancy** — one named instruction requirement and one named
test/assertion leave a concrete question.

Large repositories, a generic wish to be thorough, stock-bundle history, later rounds by themselves,
or platform-green status are not triggers. Record the trigger, file/line or page fact, and the exact
question before minute five. A previous-feedback item marked not assessed is a required trigger, not an
optional one. If it is still not assessed at minute ten, do not Accept: report that the prior required
fix was not demonstrated against the current submission. The extension may use a narrow diff, a targeted source-PR lookup,
`bin/learning-query.sh --candidate '<term>'`, a matching LEDGER row, or `bin/coverage-map.sh` for
trigger 4. It remains static-only.

Then assign severity and count:

- one confirmed Major or five distinct Minors means Needs Revision;
- one to four Minors may be Accept with concrete coaching;
- observations are true but not actionable and never count;
- Fixable, Unfixable-Structure, and Unfixable-Difficulty are separate buckets;
- Reject requires the maximum-revisions dialog and unresolved work;
- the score must agree with the verdict. Use the current live form for a score 5 if the exported guide
  is incomplete.

### F5: Write, humanize, and hand over

Build `answers/review_answer.txt` from Section 6 Path D. Complete the form in its live order:
verdict, the applicable confirmation or error-category branch, revision/coaching prose, rebuttal
acknowledgement, score, and actual review duration.

In Q3, begin with **Previous reviewer feedback follow-up** when that block was present. List every
earlier item with its feedback detail, direct current evidence, and one reviewer-facing status:
**Done** for fixed, **Partly done** for partial, **Not done** for still open, or **Not assessed** only
when the record explains why it could not be settled. Then write **New findings from this review** for
issues the previous reviewer did not name. A Done item is reported so the submitter knows it was checked;
a Partly done or Not done item is a current required change. Do not omit the previous-feedback results
just because the current review also found new items.

Run the `humanizer` skill over every reviewer-facing paragraph **after** the file is written. It may
copy-edit prose only. It must not create, remove, or change findings, evidence, citations, remedy,
severity, verdict, score, or numbers. Keep file paths, commands, checkboxes, and time values verbatim.

Run the short Section 5 paste checks after humanization: banned reviewer-facing vocabulary, no
word-wrap, and no scoring ladder in the paste. The former cross-review boilerplate search and
five-part audit are not timed gates. Write naturally from this bundle instead of using stock framing.

Record the final elapsed minutes from the timer. Five or ten is entered only when that is the actual
elapsed time. `## Form-ready` records the deadline used, whether an extension ran, the humanizer
completion, and the handoff timestamp.

### F6: Deferred maintenance

After the humanized submission document is created, do these three deferred actions in order. They are
outside review minutes and never delay form-ready handoff:

1. **Previous-feedback writing lesson.** If earlier reviewer feedback was present, read how it was
   written after the current document exists. Record one concrete writing practice to adopt or avoid in
   `## Deferred maintenance`. Learn from its evidence and clarity, not its boilerplate or verdict. Do
   not copy wording into future reviews.
2. **Accepted-task learning.** If this review's verdict is Accept, learn from the accepted task and
   add or update the relevant entry under `learning/`. Update
   `learning/bundles-i-accepted-as-reviewer.md` with the task, review UUID, platform evidence reviewed,
   useful technique or wording, and what the timed review did not inspect. Add a separate learning note
   only when it establishes a new measured platform or environment fact. Needs Revision reviews still
   add learning only for a genuinely new fact.
3. **Review tally.** Append the exact review task UUID to the root `review_tally.md`, one UUID per line,
   only when it is not already present:

   ```bash
   grep -qxF "$REVIEW_UUID" review_tally.md || printf '%s\n' "$REVIEW_UUID" >> review_tally.md
   ```

   Do not replace the UUID with a submission-id prefix or task-folder name. If the platform did not
   supply a review UUID, record that fact in `## Deferred maintenance` and ask for it rather than
   inventing one.

4. **Root ZIP cleanup.** Once `answers/review_answer.txt` is form-ready and the retained copies under
   `review_tasks/<name>/download/` have matching sha256 values, delete the mandatory original task
   source ZIP and the optional submitted task source ZIP only when each was supplied directly at the
   workspace root.
   Record their names and sha256 values before removal. Never delete the retained `download/` copies,
   any archive copy, `logs_artifact.zip`, or a ZIP in another directory. A safe shape is:

   ```bash
   for ROOT_ZIP in "$ROOT_ORIGINAL_ZIP" "$ROOT_SUBMITTED_ZIP"; do
     [ -n "$ROOT_ZIP" ] || continue
     RETAINED="review_tasks/<name>/download/$(basename "$ROOT_ZIP")"
     [ -s answers/review_answer.txt ] && cmp -s "$ROOT_ZIP" "$RETAINED" || {
       printf 'KEEP %s: form-ready document or matching retained copy is absent\n' "$ROOT_ZIP" >&2
       continue
     }
     rm -- "$ROOT_ZIP"
   done
   ```

   `ROOT_ORIGINAL_ZIP` and `ROOT_SUBMITTED_ZIP` mean only paths whose parent is the workspace root.
   If a source ZIP arrived elsewhere, or its retained copy differs, keep it and record why. This cleanup
   is after form-ready document creation and does not touch the review evidence.

Then update `INDEX.md`, `learning/review-calibration.tsv`, and the review record. Archive only after
the platform outcome is known. Keep the whole review under `_archive/reviews/` with `git mv`; never
delete its retained `download/` ZIPs or extracts. Historical deep-battery reviews retain their own
records and are never rewritten as timed-static reviews.

### Compact review record

`bin/new-review.sh` and this rule are twins. New `task.md` files carry exactly these sections:

```text
# Peer review - <Original Directory Name>

## Review timer
## Evidence reviewed
## Previous reviewer feedback
## Fast static gate
## In-depth extension
## Rubric tally
## Form-ready
## Deferred maintenance
```

The record holds the review UUID when supplied, the source of each confirmed finding, the tally behind
the verdict, actual elapsed time, the single trigger if used, the previous-feedback writing lesson,
accepted-task learning when applicable, review-tally status, root ZIP cleanup status, and what remains
deferred. It does not require a measurement battery, full corpus read, cross-bundle baseline, or audit
table.

### Tools in the timed path

| Tool | Timed use |
| --- | --- |
| `bin/new-review.sh` | bootstrap before the timer |
| `bin/preflight.sh --review-fast <submitted.zip>` | standard F2 static gate |
| `bin/learning-query.sh --candidate '<term>'` | extension only |
| `bin/coverage-map.sh <review>` | extension only for trigger 4; output is a candidate, not a verdict |
| `bin/local-run.sh`, `bin/hostile-probe.sh`, `bin/nop-audit.sh` | not part of F0-F6; separate requested diagnostics only |

### Hard boundaries

- Never edit `download/original/` or `download/seed/`, and never run commands inside either.
- Never fix the submitted bundle. `work/` supports static inspection only during the timed path.
- Never run Docker, Harbor, Oracle, NOP, a verifier, a container, or a mutation probe as routine
  reviewer work or as the five-minute extension.
- Never exceed ten active minutes, stack extensions, or promote a suspicion left unresolved at the
  deadline.
- Never skip `humanizer`, the rebuttal acknowledgement, actual elapsed time, or the documented tally.
- Never let deferred archive or calibration work delay the form-ready answer.
