_Owner of CLAUDE.md **Section 1**, Steps 6 through 11. The filename still reads `6-to-10`; it owns Step 11 as well. Loaded every session. Steps 1 through 5.5 are in `.claude/rules/01-workflow-steps-1-to-5.5.md`._

### STEP 6: Draft the form answers

On the Fixable path, do NOT start this step until the whole Step 5.5 battery has passed against the built zip (oracle 3/3 at 1.0, NOP 0.0, hostile-delete 0.0 with its test id named, failures resolved) and that zip is still the newest thing in `tasks/<name>/upload/`. Use Section 2 of this file - it lists every question per path and the basis for answering it.

The Fixable form is answered in TWO phases, because the zip upload field sits BELOW the first set of questions:

- **Phase 1 - before the zip upload:** the analysis verdict (both occurrences + the [Internal] Validity field), "Select where the task had issues", "What issues did you find", and the numbered issue details. Draft these now - they must be entered in the platform BEFORE the fixed zip can be uploaded for Check feedback
- **Phase 2 - after Check feedback and the evals pass, in this order:** Files Changed → PR additions (or "NA") → the post-fix confirmation checklist (all 8) → the rewrite-only time → the difficulty question → the senior-engineer estimate → then the Final Comment and Handling Time section: Comments for Reviewer, review time, total submission time (Steps 7–9 cover when these happen)

**Delivery order when showing Phase 1 to the user (hard rule).** Output in the same order the platform asks: (1) the verdict, (2) the "Select where the task had issues" list rendered with `[x]` / `[ ]` for all four options, (3) the "What issues did you find" list rendered with `[x]` / `[ ]` for all seven options, (4) only then the numbered issue-details pastebox. That is the documented form order in `docs/tasking-guide.md`. Never jump straight to the pastebox - the user is filling checkboxes first and has to scroll back.

**Always draft, never wait to be asked.** Every task, both Valid as-is and Fixable, produce paste-ready text for the difficulty question, the senior-engineer estimate, and Comments for Reviewer alongside the rest of the answers. The only things to wait on are the handling-time numbers, which must come from the user (Step 8).

**Files Changed is a numbered list**, one entry per file with indented `Changed:` and `Why:` lines, matching the Section 6 Path B template. Not a markdown table - the platform field is plain text and a table pastes as pipes.

### STEP 7: Eval loop (Fixable only)

Before uploading the fixed zip for Check feedback, enter the Phase 1 answers in the platform - the verdict (both occurrences + [Internal] Validity), where-issues, what-issues, and the numbered issue details all sit ABOVE the upload field and must be answered first. Then write the upload-ledger row in `task.md` (Step 5 re-zip item 7) and upload the zip from `tasks/<name>/upload/` as `<all-task-content>`. After upload the platform runs Static Checks, Difficulty Check, Oracle Check, and the Quality Check judge. Iterate per Section 4 until the Send gate below is fully green. Expect that the Phase 2 answers are only completed AFTER the checks pass. Every revision round happens in the working copy under `tasks/<name>/work/` and produces a fresh zip into `tasks/<name>/upload/` via the Step 5 re-zip rule, overwriting the previous one - which is why each round needs its own ledger row. Once `submission_answer.txt` exists, every round through this loop also updates it - that is Step 10.

**The Send-to-reviewer gate.** Read this list before checking the box. Any single unmet condition means Send = No, and the reason gets recorded on the `Send to reviewer:` line of the answers file:

1. **Static Checks green.** The build stops at the first failing phase, so a green static check only means the next phase could run - it is a precondition, not a pass
2. **Difficulty Check green with ZERO invalid trials.** An `invalid trial` / `harness failure` count above zero voids the round: you learn nothing about difficulty, nothing about the quality panel's test axes and nothing about agent behaviour, so a "passing" difficulty summary alongside invalid trials is not a pass
3. **Oracle Check 3/3.** Anything below 3/3 blocks. On the Fixable path it is a task defect, not flake - see Section 4 for what 0/3 versus 1/3 tells you
4. **Quality Check pass.** Both test axes above 3.0 with no judge at ≤ 2, AND zero failing must-have criteria - a `criterion: Instructions` failure blocks on its own even with clean test axes
5. **Task Instruction Sufficiency is not FAIL.** See Section 4 troubleshooting for the 0%-agents / 100%-oracle signature
6. **The Step 5.5 battery passed against the CURRENT zip.** NOP 0.0, oracle 3/3 at 1.0, hostile-delete 0.0 naming its test id, all run on an extract of the zip now sitting in `tasks/<name>/upload/`
7. **The zip is newer than every file in `work/`.** `find tasks/<name>/work -newer tasks/<name>/upload/<name>.zip` prints nothing. If it prints anything, an edit landed after the battery and both the zip and the battery are void
8. **The upload ledger in `task.md` has a row for this zip**, with its sha256 and the checks it returned

Sending with a failing condition is allowed only deliberately, and then Comments for Reviewer must say which condition failed, why you sent anyway, and what you tried. Checking the box with unexplained failing checks always comes back as revision.

### STEP 8: Ask for the handling times

Ask the user for the real numbers - never generate them. The live form shows **five** time
lines: four independently asked fields, plus the total, which is computed from three of them
(verified on a real submission, 2026-08-01 - `docs/tasking-guide.md` documents fewer). The
Section 6 templates print all five for that reason:

| # | Field | Asked or computed | What it covers |
|---|---|---|---|
| 1 | Minutes to review the initial task and determine its validity | asked | Steps 2–4 - the analysis and the verdict, nothing else. All paths |
| 2 | Minutes to complete the initial task rewrite only | asked | The Step 5 edits made before the FIRST upload - instruction, tests, oracle, git, Dockerfile. Fixable path only. Not revision rounds |
| 3 | Minutes to complete the additional questions on the form | asked | Filling in the rest of the form - difficulty, senior estimate, checklists, Comments for Reviewer |
| 4 | Minutes to complete all revisions | asked | **Post-first-upload rounds only** - a failed check or a reviewer bounce, then edit, re-zip, re-upload. Update this number every revision round |
| 5 | Total submission time | computed | Fields 1 + 2 + 3. Not an independent number to invent |

**Total submission time is fields 1 + 2 + 3 only. Field 4 is tracked separately.**
**This is an INFERENCE, not verified platform behaviour, and `docs/` reads the other way.**
`docs/tasking-guide.md:229` - the source of truth per the top of this file - describes the
total as "How long did it take you to complete this entire submission? (in minutes - if the
task is sent back for revision, adjust this number to include the additional time)". That
wording says to fold revision time IN. The exclusion here is inferred from the existence of a
separate fourth field on the live form, which the docs export predates. It has not been
confirmed against the live helper text.

Resolve it rather than carrying it: ask the user to screenshot the live total field's helper
text, then record what it says with its observation date in a `learning/` note. If the live
text matches `docs/tasking-guide.md:229`, reverse this rule and re-total every answers file.
Until that is done, apply the exclusion and say in Comments for Reviewer if the number could
be read either way.

Sanity hints for splitting a stated total - **hints, not gates. A figure outside them is not
an error**:

- **Total submission time (1 + 2 + 3): 180 to 240 minutes** is the usual shape of a
  first pass. The one platform-ACCEPTED bundle shipped **260** minutes
  (`_archive/20260719_045042__oliver-oloughlin_kvdex__245/answers/submission_answer.txt:190`),
  so the band describes typical work rather than a permitted range.
- **All revisions (4)** starts at zero and grows **50 to 70 minutes per round** after the
  first. The accepted bundle shipped **195** minutes of revision time across its rounds
  (same file, line 193) and libcrux is at 240. Do not clamp a real cumulative figure into a
  60 to 120 window - read it off the task's handling-time ledger (Step 10) instead.

Sanity-check before writing anything: the total has to equal fields 1 + 2 + 3 exactly, and it
must exceed the review and rewrite components on its own. If the user gives only an overall
number, propose a split across the three fields that matches what actually happened rather
than padding one to hit a round total, and say which field you put the slack in. Never invent
any of the four asked numbers.

### STEP 9: Create submission_answer.txt (end of the first pass, not the end of the task)

Only after EVERY previous step for the current task is complete - verdict locked, fixes applied in `tasks/<name>/work/`, the task zipped into `tasks/<name>/upload/` (Fixable path), the whole Step 5.5 battery passing against that zip, platform evals passing (Fixable path), and all handling times received from the user - create `tasks/<Original Directory Name>/answers/submission_answer.txt` using the matching Section 6 template. It stores the full answer set for the task Cursor is currently working on. If a submission_answer.txt from a previous task still exists, confirm with the user before overwriting it.

This closes the first submission, not the task. The task itself closes at Step 11. Most tasks come back at least once - see Step 10, which keeps this file in step with every revision.

**Humanize the file as the last action, after it is written.** Draft the answers, write the file, then run the `humanizer` skill over every free-text answer in it - the issue descriptions, the difficulty paragraph, the unfixable explanation, and Comments for Reviewer - and save the humanized text back. Do this even when the same paragraphs were already humanized in chat, because they get edited, merged and re-ordered on the way into the file, and the pass that matters is the one over the text the user actually pastes. The file is not finished until that pass has run.

What the pass must not change: file paths, function and test names, commands, diffs, code examples, the checkbox lines, and the handling-time numbers. Those stay verbatim. What it removes is the LLM tells listed in Section 5 - em dashes, colons and semicolons in prose, comma pile-ups, filler, and any phrasing that does not read like a person wrote it. Re-check the Section 5 rules after the pass, since humanizing can reintroduce a wrapped line or a dash.

**Write the file unwrapped, and keep it unwrapped after humanizing.** Every paragraph is one single line, however long it runs - no hard wrap at 80 columns or any other width, and no editor reflow. The file exists to be copied out of and pasted into platform text fields, and a newline inserted mid-sentence travels with the paste. Section 5 lists the only places a line break is allowed. Check the file after writing it: if any prose line ends without the sentence ending, it was wrapped and needs rejoining.

### STEP 10: Revision rounds (expect at least one - this is the normal path)

A task is rarely done in one pass. It comes back either from a failing platform check during the Step 7 eval loop, or from the reviewing EC with **Needs Revision** and a list of findings after Send to reviewer. Both are the same job: address the feedback, re-validate, re-zip, and bring the answers back in line with what the task now is.

Run this loop every time feedback arrives, however small it looks.

**0. Confirm WHICH task the feedback belongs to, from the feedback itself.** Do not trust the path or task name in the message that carries it. Feedback gets pasted with the previous task's path attached, and the `__` in a directory name renders as markdown bold, so `20260728_153118__jqno_equalsverifier__1166` arrives as `20260728_153118**jqno_equalsverifier**1166` and is easy to mistake for a different task. The report always identifies itself: judge justifications cite `task.toml` line numbers with the source PR, repo paths under `environment/repo/`, and file names from the bundle. Match those against the task folders before touching anything, and say plainly which task you concluded it is. Working the wrong folder costs a whole round.

**0b. Check the report is FRESH before acting on it.** Confirming the right task is not enough - two rounds have been spent on stale reports for the right task, including an entire "round 2 feedback" that turned out to be the round 0 report re-pasted (libcrux `task.md`, caught only by four independent tells). Check the report against the bundle currently in `work/` on four axes and record the result at the top of the round block in `task.md`:

| Axis | What to compare |
|---|---|
| Test ids | Every test id the report names exists in the current `tests/config.json` |
| Line numbers | Line numbers it cites fall inside the current `tests.patch` and `config.json` lengths |
| Commands | The command list it describes matches the current `execution.commands` |
| Instruction text | Any instruction phrase it quotes is still present in the current `instruction.md` |

Any mismatch means the report predates your last upload. Ask for the current one before touching a file. A stale report sends you to fix something you already fixed, and the round returns unchanged.

**1. Capture the feedback before touching anything.**

**First action on any failed check: ask the submitter for the downloadable results artifact**, in the same message that captures the feedback. The difficulty-check download carries the platform-side verifier stdout, which sits above local reproduction in the evidence hierarchy (`learning/diagnosing-platform-only-failures.md`) - a local reproduction only ever proves a condition is sufficient, while the artifact says what actually happened. AltBeacon spent three rounds and roughly 35 local oracle runs before concluding that asking for the artifact was the next step. Record in `task.md` whether it was supplied, so the next round knows whether that avenue is open or already closed.

**On a review-gate block, ask for the "Agentic Judge Quality Report" field by name**, alongside the difficulty artifact. **A difficulty-screen block produces a real downloadable artifact and it is the single most useful thing you can get** - statrs 315's was 199 files with all 8 trial transcripts and per-trial verifier reports. It answered two questions nothing local could: it proved a report fresh when two screens returned byte-identical headline numbers, and it named the difficulty lever by showing that the one failing agent had written the mathematically *correct* implementation and been caught by a place the library deliberately diverges. Do not read `Task Instruction Sufficiency: NOT_APPLICABLE, debug output not available` as proof there is nothing to ask for; that string is a line inside the artifact. The review gate is a two-stage check that runs before the task reaches a reviewer - the agentic judge first, then a cheap single-arm difficulty screen - and the one-line eval summary only names the stage that stopped it. On a judge block the reasons are not in that line: they sit in the **"Agentic Judge Quality Report"** field on the submission, which is collapsed, marked optional and lower down the form, so it gets missed. It carries the DISCUSS / REMOVE status and cites the specific axes and files, which is the only thing there is to act on. A block at the difficulty screen instead means the screen found the task trivially easy, and the answer is added difficulty per the PR scope and difficulty rules, not diagnosis. The one infra case is a message that explicitly says the difficulty screen failed with an infra error - that is a platform crash with no verdict, so retry. See `docs/faq.md`, the "Review gate blocked at the agentic judge / difficulty screen" FAQ.

Paste the feedback verbatim into the task's `task.md` under a dated revision heading, alongside which round it is and where it came from (which check, or the reviewer). Verbatim matters - reviewer notes are the defect list you will be graded against, and paraphrasing loses the specific ask. Set the task's status to `pending-revision` in `INDEX.md`, update the `pending-revision: N of 2` count, and stop if that count would exceed two.

**Elided reports are not evidence.** When a pasted report contains an elision marker (`… 172 lines omitted …`, a truncation notice) or shows an axis with no quoted justification, mark those axes **UNVERIFIED** in `task.md` and ask the submitter for the untruncated report. Do not ship a change whose only justification is an unverified axis. A score you remember from reading a previous session's report counts as unverified too - memory of a number is not a re-readable citation, and the blocking axes are exactly the ones worth being wrong about.

**One round counter per task, shared by all three files.** The counter increments **once per platform feedback received** - not per fix, not per re-upload, not per part of a bundled report. No part-numbered sub-headings (`round 2-part-3`); if new feedback arrives, that is the next round, and if it does not, it is the same round. The highest round heading in `task.md`, the round number in the answers `Comments for Reviewer` opener, and the number in the `INDEX.md` status cell must all read the same.

**2. Turn the feedback into a numbered item list, then work it.** One line per finding, each with the file it touches and the fix. Findings arrive in prose and bundle several asks into one paragraph - split them, or you will address four of six and think you are done. Reply to every item, including the ones you decide not to act on, with the reason.

**Read the Guidelines section a finding cites before working it.** Reviewers are asked to cite the relevant section of the Guidelines in their notes for specific or easily-missed rules (`docs/tasking-guide.md`, reviewer form question 4), so a Needs Revision item may name the exact rule behind it. Open that section first - it settles what the finding is actually asking for faster than re-deriving the ask from the prose.

**Count the strikes before choosing a fix.** Every `task.md` carries a strike table, updated here, before any fix is chosen:

```
## Failure signatures
| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Oracle Check 0/3 | 2, 3, 4 | solve.sh idempotency; -3way apply; mode fix | 3 |
```

A strike count of **2 forces the remove-the-dependency path**. It is not a nudge: a fix you verified locally that comes back failing a second time means your model of the environment is wrong, so shipping a third variation of the same theory is forbidden. Remove whatever the failure depends on instead (Section 4, two strikes). AltBeacon ran oracle 0/3 across three consecutive rounds and only invoked the rule afterwards, because nothing was counting.

**A stage that never ran is not a failure signature.** `Not run: difficulty screen` in a review-gate summary means the agentic judge blocked first, so the second stage never started. It is expected, not a second error to diagnose, and it does not get a row in the strike table (`docs/faq.md`, the "Review gate blocked at the agentic judge / difficulty screen" FAQ). The judge block is the one signature that round scored.

**Change only what the finding requires.** A revision round is not a tidy-up. Every file you touch that no numbered finding named has to be justified in Comments for Reviewer. Workspace bookkeeping - `task.md`, `INDEX.md`, `learning/` write-backs, rule files - is never part of the bundle diff and never appears in Files Changed.

**3. Make the edits in `tasks/<name>/work/`, under the same rules as the first pass.** Every hard boundary from Step 5 still applies - no tracked source edits, no pre-existing test file left modified in the shipped tree, no PR reduction, only the listed Dockerfile fixes. Feedback from a reviewer does not widen what you are allowed to edit. If a requested change would cross one of those lines, say so plainly in Comments for Reviewer and explain what you did instead.

**4. Re-run everything, not just the part you touched.** The full Step 5 Phase A pre-upload checklist including `git fsck --unreachable`, then the Step 5 re-zip rule into `tasks/<name>/upload/` overwriting the previous zip, then the WHOLE Step 5.5 Phase B battery - NOP, oracle 3/3, hostile delete - from fresh extracts of that new zip. Git hygiene comes immediately before zipping, every round, because the revision work recreates `.git/logs`, a stash and dangling objects exactly the way the first pass did. Write the new upload-ledger row after the zip verifies.

**5. Update `submission_answer.txt` - this is the step that gets skipped.** The file has to describe the bundle you are actually uploading now, not the one you uploaded last week. Do not regenerate it from scratch and do not leave it alone: edit the answers your changes affected and add the ones the changes created, and leave everything else as it stands.

**Re-derive every count in Files Changed from the live bundle, never from last round's prose.** This is the one place the answers audit was not looking, and the drift shipped inside an **accepted** submission: redisshake 1005's Files Changed entry 5 read `fail_to_pass 10 to 14 and pass_to_pass 1 to 11` against a live config of **20 and 13**, entry 4 named three graded files against **seven**, and the post-fix checkbox one line below read `counted: 20`, so the file contradicted itself on the same page. Nothing caught it, including the reviewer. A per-file "changed X to Y" sentence gets written in round 0 and then never re-read, because the round that changes X to Z edits the config and the issue block and considers itself done.

```bash
# measure first, then read every count in the answers against these
python3 -c "import json;g=json.load(open('tasks/<name>/work/tests/config.json'))['grading'];print('f2p',len(g['fail_to_pass']),'p2p',len(g['pass_to_pass']))"
grep -c '^new file mode' tasks/<name>/work/tests/tests.patch      # graded files created
grep -c '^diff --git'   tasks/<name>/work/solution/golden.patch   # golden file count
grep -nE '[0-9]+ to [0-9]+|\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty)\b' tasks/<name>/answers/submission_answer.txt
```

**The spelled-out half of that grep is the half that matters** - three of redisshake's four stale numbers were words, not digits, so a numeric grep could never have found them. And re-decide the `Send to reviewer:` line every round: that accepted file still read `Send to reviewer: No ... the checks have not run against it` while the task sat in front of a reviewer.

**Supersede, do not only append.** A round that replaces a mechanism makes every earlier block describing that mechanism false, and appending a new block does not repair them - the file then describes two mutually exclusive verifiers, which is what a reviewer reads. Before adding anything, grep the answers file for the mechanism you replaced and edit **every** block that still describes it, noting the superseded design in a single clause rather than deleting the history. libcrux shipped a round where issue 2 and Files Changed entry 2 still described a git-based test-tree restore that a later entry in the same file explained had been removed. List the greps you ran in `task.md`, so the next round can see what was checked.

**A verdict change rewrites the whole file, so archive the old one first.** Moving between paths changes the template, so "edit it, do not regenerate it" cannot be followed literally, because the new file asks different questions. Copy the current file to `answers/superseded/submission_answer.<old-verdict>.txt` before writing the new one, and make sure every numbered issue block also exists in `task.md`. `tasks/` is gitignored, so the overwrite is the only copy there was. libcrux 1165 moved from Fixable to Invalid in round 5 and 17 issue blocks stopped existing; the substance survived only because `task.md` carried it in prose. Every number in the answers file has to be re-derivable from `task.md` for the same reason: libcrux's revision figure silently reverted twice, and the arithmetic checks pass on a reverted value.

What typically moves after a revision round:

| Answer | When it changes |
|---|---|
| "Select where the task had issues" | A round that touched a new component - a Dockerfile or task.toml fix means the Environment box now applies |
| "What issues did you find" | A newly found defect maps to a category not yet checked |
| Numbered issue details | A new numbered block per newly addressed finding, and edits to existing blocks whose fix changed |
| Files Changed | Every **bundle** file the round touched - new entries, and edits where the "what changed" is now different. Workspace bookkeeping never appears here |
| PR additions | Only if the round expanded scope. Otherwise it stays "NA" |
| Post-fix confirmation (all 8) | Re-verify each box against the current files. A box checked two rounds ago is not evidence about the bundle you are shipping now |
| What makes this task difficult | If the fixes changed what the task actually demands |
| Comments for Reviewer | Every round. Say which revision this is, what you changed, what you deliberately did not change and why, and the fresh oracle/NOP numbers |
| Handling times | The revision field only, **copied from the last Cumulative cell of the task.md ledger**, never remembered. The other three are first-pass numbers and do not move |
| Send to reviewer | Re-decide it against the Step 7 gate every round. It is a template line, so it always carries either Yes or No with a reason |

**6. Re-humanize the file after editing it.** Run the `humanizer` skill over the answers you touched, and re-check the whole file against Section 5 afterwards - the same no-wrap and no-LLM-tells rules, on the edited text and on the joins where new text meets old. New text pasted next to already-humanized text is where the tells reappear. Same exempt list: paths, test names, commands, code, checkbox lines, and the numbers.

**7. Record the round in `task.md` and update `submission_answer.txt` in the SAME action.** These were two separate steps and they drifted apart every time - AltBeacon's answers file carried a revision figure its own `task.md` still flagged as needing a fresh number after five rounds, and libcrux recorded outright that "the round-2 increment had been lost somewhere". Treat them as one write, never one after the other with thinking in between.

Into `task.md`: what the feedback said, the freshness-check result, what you changed, the new NOP / oracle 3/3 / hostile-delete results, the check outcomes, the updated strike table, and the new upload-ledger row. Plus the handling-time ledger, which is the only place the revision number is derived from:

```
## Handling time ledger
| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 1 | 2026-07-30 | 65 | 65 |
| 2 | 2026-08-02 | 60 | 125 |
```

The answers file's "all revisions" figure is **copied from the last Cumulative cell**, not recalled and not re-estimated. Then update the status and the round number in `INDEX.md`. The record is what makes the next round cheap; without it you re-derive the history every time.

**And the open-caveat table, which is the one that stops a limit quietly turning into its opposite.** A caveat has no owner: a finding gets a file:line and a probe, a caveat gets a clause at the end of a paragraph that each round writes a little shorter because it was in the last one too. redisshake 1005 stated "the control runs on a newer model than the screen, so 4 of 4 is a ceiling not a forecast" in round 2, demoted it in round 3, and in round 4 wrote "two independent measurement systems now agree" with nothing measured in between. The platform then refuted it.

```
## Open caveats
| Caveat | Stated in round | What would retire it | Retired? |
|---|---|---|---|
| control model is newer than the graded models, so n of n is a ceiling | 2 | a control on the graded models, or an artifact showing a graded model failing | NO, open at round 4 |
```

Two habits go with the table. **Make the qualifier part of the value** - write "4 of 4 against Opus 5", never "4 of 4", so the number cannot be quoted bare three rounds later. And before shipping, grep the round for a caveat argued away rather than measured away: `grep -niE 'no longer buys|now agree|is settled|conclusively|the earlier hedge' tasks/<name>/task.md tasks/<name>/answers/submission_answer.txt`. Every hit needs a measurement on the same line or the sentence comes out. See `learning/stated-caveats-decay.md`.

Then hand the user the changed answers, in the platform's order, saying which ones moved since the last round so they only have to re-paste those.


### STEP 11: Close the task (the reviewer accepted or rejected it)

A task ends when the reviewer returns Accept or Reject, and the ending has work of its own. Steps 1 to 10 do not cover it, so until now a closed task simply stopped being touched and three records drifted every time: the register, the learning index, and the calibration row.

**1. Confirm the outcome and which task it belongs to.** Same discipline as Step 10 item 0. Identify the task from what the message itself cites, never from the path pasted alongside it.

**2. Write the closing block into `task.md`.** The reviewer's verdict verbatim under a dated heading, the Submission Quality Score if one was given, the final round number, and the last row of the handling-time ledger. This is the last write to that file.

**3. Update `INDEX.md` in the same action.** Status becomes `accepted` or `rejected`, the two closing tokens the register defines. Round keeps the final round number. Then update the `pending-revision: N of 2` line under `## Active`, because closing a task is the thing that frees a slot and that count is what blocks the next claim (Step 1 item 5).

**4. Harvest before the folder moves.** Answer two questions in writing. What did this task prove that no note yet says, and what did it disprove that a note still says. A new fact gets a `learning/` note with frontmatter plus a row in `learning/README.md`. A disproved claim gets a `LEDGER.md` row. The Step 1 write-back rule says how to write one. **This step is when it fires.**

**5. Fill in the task's `learning/calibration.tsv` row.** Set `verdict` to the path submitted, set `outcome` to what the reviewer returned, and refresh every number the rounds moved: revision minutes, upload rounds, and any measured column that changed. A row left at its mid-flight values is worse than a missing one, because the next task reads it as measured.

**6. Move the whole folder to `_archive/<Original Directory Name>/`.** Whole and unstripped, the shape Section 7 describes. `download/`, `work/`, `upload/`, `answers/`, `task.md` and `task_details.md` all travel, and rule files cite paths inside archived bundles. Move it with `git mv` and confirm with `git ls-files _archive/<name> | wc -l`. **`tasks/` is gitignored and `_archive/` is not**, so this move is the moment the record becomes recoverable. Everything before it lives on one disk with no history.

**7. Repoint anything that cited the old path.** Moving the folder breaks every inbound `tasks/<name>/...` reference in `learning/`, the rule files and the README, and those are exactly the citations that made the note credible. `grep -rl 'tasks/<name>' --include='*.md' .` finds them; rewrite each to `_archive/<name>/...` and re-run `bin/doclint.sh`, which is what catches the ones you miss. On libcrux 1165 the move broke one reference in `learning/stock-bundle-defect-baseline.md` and doclint found it immediately.

Then say in chat that the task is closed, which notes were added, and what the `pending-revision` count now reads.
