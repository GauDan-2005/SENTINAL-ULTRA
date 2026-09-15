_Owner of CLAUDE.md **Section 1**, Steps 6 through 11. The filename still reads `6-to-10`; it owns Step 11 as well. Loaded every session. Steps 1 through 5.5 are in `.claude/rules/01-workflow-steps-1-to-5.5.md`._

### STEP 6: Draft the form answers

On the Fixable path, do NOT start this step until all four runs of the Step 5.5 Phase B battery have passed against the built zip (oracle 3/3 at 1.0, NOP 0.0, hostile-delete 0.0 with its test id named, Run 4, the gaming probe, at 0.0 with the file it edited named, failures resolved) and that zip is still the newest thing in `tasks/<name>/upload/`. Use Section 2 of this file - it lists every question per path and the basis for answering it.

The Fixable form is answered in TWO phases, because the zip upload field sits BELOW the first set of questions:

- **Phase 1 - before the zip upload:** the analysis verdict (both occurrences + the [Internal] Validity field), "Select where the task had issues", "What issues did you find", and the numbered issue details. Draft these now - they must be entered in the platform BEFORE the fixed zip can be uploaded for Check feedback
- **Phase 2 - after Check feedback and the evals pass, in this order:** Files Changed → PR additions (or "NA") → the post-fix confirmation checklist (all 8) → the rewrite-only time → the difficulty question → the senior-engineer estimate → then the Final Comment and Handling Time section: Comments for Reviewer, review time, total submission time (Steps 7–9 cover when these happen)

**Delivery order when showing Phase 1 to the user (hard rule).** Output in the same order the platform asks: (1) the verdict, (2) the "Select where the task had issues" list rendered with `[x]` / `[ ]` for all four options, (3) the "What issues did you find" list rendered with `[x]` / `[ ]` for all seven options, (4) only then the numbered issue-details pastebox. That is the documented form order in `docs/tasking-guide.md`. Never jump straight to the pastebox - the user is filling checkboxes first and has to scroll back.

**Always draft, never wait to be asked.** Every task, both Valid as-is and Fixable, produce paste-ready text for the difficulty question, the senior-engineer estimate, and Comments for Reviewer alongside the rest of the answers. The only things to wait on are the handling-time numbers, which must come from the user (Step 8).

**Files Changed is a numbered list**, one entry per file with indented `Changed:` and `Why:` lines, matching the Section 6 Path B template. Not a markdown table - the platform field is plain text and a table pastes as pipes.

### STEP 7: Eval loop (Fixable only)

Before uploading the fixed zip for Check feedback, enter the Phase 1 answers in the platform - the verdict (both occurrences + [Internal] Validity), where-issues, what-issues, and the numbered issue details all sit ABOVE the upload field and must be answered first. Then write the upload-ledger row in `task.md` (Step 5 re-zip item 7) and upload the zip from `tasks/<name>/upload/` as `<all-task-content>`. After upload the platform runs Static Checks, Difficulty Check, Oracle Check, and the Quality Check judge. Iterate per Section 4 until the pre-submit gate below is fully green. Expect that the Phase 2 answers are only completed AFTER the checks pass. Every revision round happens in the working copy under `tasks/<name>/work/` and produces a fresh zip into `tasks/<name>/upload/` via the Step 5 re-zip rule, overwriting the previous one - which is why each round needs its own ledger row. Once `submission_answer.txt` exists, every round through this loop also updates it - that is Step 10.

**The pre-submit gate.** Read this list before you press Submit. There is no "Send to reviewer" checkbox any more (`docs/tasking-guide.md:251`) - submitting runs the post-submission evals on their own, a pass routes the task straight to the reviewer queue, and a fail returns it to you to fix and resubmit. So this is the list you clear first, and any single unmet condition means the gate is not clear, with the reason recorded on the `Pre-submit gate:` line of the answers file:

1. **Static Checks green.** The build stops at the first failing phase, so a green static check only means the next phase could run - it is a precondition, not a pass
2. **Difficulty Check green with ZERO invalid trials.** An `invalid trial` / `harness failure` count above zero voids the round: you learn nothing about difficulty, nothing about the quality panel's test axes and nothing about agent behaviour, so a "passing" difficulty summary alongside invalid trials is not a pass
3. **Oracle Check 3/3.** Anything below 3/3 blocks. On the Fixable path it is a task defect, not flake - see Section 4 for what 0/3 versus 1/3 tells you
4. **Quality Check pass.** Both test axes above 3.0 with no judge at ≤ 2, AND zero failing must-have criteria - a `criterion: Instructions` failure blocks on its own even with clean test axes
5. **Task Instruction Sufficiency is not FAIL.** See Section 4 troubleshooting for the 0%-agents / 100%-oracle signature
6. **The Step 5.5 Phase B battery passed against the CURRENT zip, all four runs.** NOP 0.0, oracle 3/3 at 1.0, hostile-delete 0.0 naming its test id, and Run 4, the gaming probe, leaving the reward at 0.0 with the file it edited named, each on its own fresh extract of the zip now sitting in `tasks/<name>/upload/`
7. **The zip is newer than every file in `work/`.** `find tasks/<name>/work -newer tasks/<name>/upload/<name>.zip` prints nothing. **When it prints something, find out WHAT before concluding the battery is void.** The overwhelmingly common cause is the `.git` **directory** mtime with no content change at all, because any git read inside `work/environment/repo` writes `.git/index` - `git status`, `git apply --check`, `git apply --numstat`. xlwings 2719 tripped this four times in two days, twice from a `git status` in a verification step and once from an audit agent checking tracked source. Settle it in one command: extract the zip and `diff -rq <extract> work`. **Identical content means the battery transfers** and the fix is a rebuild for gate hygiene, not a re-run. Different content means an edit really did land and the battery is void. **Never touch the mtime to silence the gate** - that is the self-confirming check Section 11 bans. The durable fix is ordering: do every git read BEFORE the zip is built (LEDGER L82)
8. **The upload ledger in `task.md` has a row for this zip**, with its sha256 and the checks it returned

There is no deliberate send any more, because the box that allowed one is gone and the `AlwaysNoPass` message with it (`docs/tasking-guide.md:251`). Conditions 1 to 5 are the ones the post-submission evals re-run for you, so submitting with any of them red spends a whole round and the task comes back to you without a person having read it. Conditions 6 to 8 are local and the platform never sees them, so a gap there ships silently and only the reviewer catches it. A red condition is fixed, never explained: record it on the `Pre-submit gate:` line as Not clear with the condition named, and do not submit until it is green. What does carry across a bounce is the written text, so when a returned submission has been fixed and is going back up, re-read Comments for Reviewer and the `Pre-submit gate:` line before pressing Submit again. Both have to be true of the round where the evals finally pass, not of the round that failed.

**The difficulty check is a budgeted resource now, and this gate is where it gets spent.** Until 2026-08-14 a task could cycle through the difficulty check with no limit. As of that date the budget is **four difficulty checks**: once four have run on a task without passing, the platform classifies it **Invalid Difficulty** on its own and sends it to review as it stands (`docs/faq.md`, "Difficulty checks are now capped"). The submission carries four new read-only fields and two of them belong to this gate, **Difficulty checks run** and **Difficulty checks remaining**. Read both before every upload, and write both into the round record in `task.md` (Step 10), because nothing else in this workspace records them and they cannot be reconstructed after the fact.

What spends the budget is a difficulty check that runs AND returns a result. A submission that comes back to you before the check runs costs nothing, and a technical issue that prevents a result costs nothing. A reviewer sending the task back restarts the count at zero, so the cap is **per review cycle and not per task lifetime** - do not write it as a lifetime limit. Reaching it is not a rejection, it is not retroactive to tasks that arrived before 2026-08-14, and a human reviewer still reads the task afterwards. Step 10 says what to do with the task when it comes back with that verdict already on it.

**The consequence is the one worth changing a habit over: the measurement work moves BEFORE the upload.** Spending a check to find out whether a lever you picked by reasoning does anything is a quarter of the budget, and nothing local costs you a check. This workspace already knows which measurements find a lever. Build three or four implementations of the feature from `instruction.md` alone, blind to the oracle, the tests and the upstream commit, and read what each one reports it was unsure about (`learning/implementation-control-is-the-lever-generator.md`). Run every candidate lever as a throwaway probe against every implementation you have and discard each row where they all agree, which killed 13 of 15 candidates on xlwings 2719 (`learning/difficulty-levers-must-discriminate.md`). Split the sentences you already wrote into clauses and check a test fails when each one is violated, which moved xlwings from 87.5% to 37.5% solves on a round that added no requirement at all (`learning/probe-the-instruction-you-already-wrote.md`). All three were advisable while the rounds were free. They are what the budget is for now. The person standing at this gate is the person deciding whether the round is worth a quarter of it, so decide it here rather than after the screen has answered.

**One consequence that is a reading of the FAQ rather than something measured here.** `learning/platform-announcements.md` carries a difficulty rerun ladder - rerun a failed Difficulty Check once, then a second time, before diagnosing. Read the FAQ sentence directly and every rerun that returns a result spends budget, so a ladder that used to cost only wall-clock time can now cost half the cap. Nobody in this workspace has hit the cap yet, so treat that as a reading to check against the **Difficulty checks remaining** field on the form before you rerun anything, not as a measured rule.

### STEP 8: Ask for the handling times

Ask the user for the real numbers - never generate them. The live form shows **five** time
lines: four independently asked fields, plus the total, which is computed from three of them
(verified on a real submission, 2026-08-01 - `docs/tasking-guide.md` documents fewer). The
Section 6 templates print all five for that reason.

**Weakened 2026-08-18, and not refuted.** A capture of the whole submission page renders exactly
**four** submitter time labels (`sample_review_page.md:401`, `:403`, `:405`, `:407`) and a grep for
"total" and "entire submission" across all 473 of its lines returns nothing. That is not enough to
drop the fifth line, for one specific reason: a **computed display** is not an input, and the same
conversion renders all four of those inputs label-only with no values, so it demonstrably drops what
it cannot represent. `docs/tasking-guide.md:229` also still describes a whole-submission total. So
the fifth line is now an open caveat rather than a measurement, the 1 + 2 + 3 inference below is
unchanged and still an inference, and what would settle both is one screenshot of that block with
values in it. The same capture also puts the **rewrite-only time inside the handling block**
(`:403`), after the difficulty question (`:359`) and the senior estimate (`:365`), where Step 6's
Phase 2 ordering puts it before both. Everything up to the confirmation checklist matches.

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
  (same file, line 193) and libcrux is at **370**, re-measured 2026-08-16 from its own answers file. Across all eight accepted submissions the totals run 195 to 260 and the revision figures 0 to 370, so seven of the eight totals sit inside the 180-240 band and kvdex is the one above it. Do not clamp a real cumulative figure into a
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

A task is rarely done in one pass. It comes back one of three ways: from a failing platform check during the Step 7 eval loop, from the post-submission evals returning it to you automatically after you submit (`docs/tasking-guide.md:251`), or from the reviewing EC with **Needs Revision** and a list of findings once those evals passed and the task reached the queue. All three are the same job: address the feedback, re-validate, re-zip, and bring the answers back in line with what the task now is.

Run this loop every time feedback arrives, however small it looks.

**Since 2026-08-14 there is a fourth way it comes back, and it is the one round that changes nothing.** When four difficulty checks have run on a task without passing, the platform writes **Invalid Difficulty** onto the validity question itself and returns the task to you once with that verdict already set (`docs/faq.md`, "Difficulty checks are now capped"). The right action is to submit it again without changing anything and to leave the verdict where the platform put it. Do not rewrite the bundle, do not restore your own verdict, and do not work it as a bounce to fix. It is not a rejection and a human reviewer still reads it. This is the only situation in this workspace where resubmitting an unchanged bundle is correct, so items 3 through 6 below do not fire - there is nothing to edit, nothing to re-zip, no battery to re-run and nothing in the answers file that the round made false. The answers file is not rewritten either: a verdict the platform set is not a verdict change of yours, so the Section 6 template does not move and the archive-then-rewrite rule in item 5 stays shut. Record the platform's verdict and its date in `task.md` under item 7, as a round that deliberately changed nothing, or it reads later as a skipped step. That last part follows from the FAQ's instruction to submit again without changing anything rather than from anything measured here. Reaching the cap is the platform's verdict and never yours, so it is not licence to write Unfixable - Difficulty into an answer, and every condition Section 3 puts in front of that verdict still stands.

**Establish WHICH of the three it is before you plan the round, because the third one behaves differently in two ways that change what you do.** Measured on android-beacon 1177, whose round 8 was the first human-reviewer round in this workspace and the round it was accepted on.

- **A human reviewer reads Comments for Reviewer. The automated panel does not.** LEDGER **L18** says the judge does not read it, and that is true and scoped to the panel, which scores the instruction, the tests, the oracle and the task directory and nothing else. `docs/tasking-guide.md` defines the reviewing EC's job as repeating the document and logic review **and reading Comments for Reviewer**. So on a judge round an explanation buys nothing and the fix has to be in the artefact; on a reviewer round the explanation is a real channel. Answer their findings there **point by point, including the ones you decline and the ones you cannot reproduce** (LEDGER L77)
- **A human reviewer finds defect classes no automated check can reach.** All four of AltBeacon's round-8 findings had survived every eval. The blocking one was that the graded file only compiled against a type the instruction never specified, so seven of eight difficulty trials died at compile with all 230 graded ids recorded missing. No panel sees that, because the oracle defines the type and therefore compiles, and the NOP fails either way. **Do not treat "every check passed" as evidence the bundle is sound**, and do not argue a reviewer finding down on the strength of a green pipeline

**Say so plainly when a reviewer finding does not reproduce, and fix the cause anyway if they identified it.** AltBeacon's fourth finding was that the shipped repo had no usable `refs` directory. It did not reproduce: the zip carries the entries and an extract gives a working repository. The reviewer was still right about the cause, which was that the pre-zip `git gc` packs the loose ref away and leaves an empty directory the bundle then depends on surviving. Reporting "did not reproduce, here is the cause you found, here is the fix" is a better answer than either agreeing silently or disagreeing.

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

**The round counter and the platform's difficulty-check counter are two different counters, and conflating them will cost somebody a task.** The round counter above counts feedback received, whatever the feedback was about. The platform's counter, shown as **Difficulty checks run** with **Difficulty checks remaining** beside it, only moves when a difficulty check runs and returns a result (`docs/faq.md`, "Difficulty checks are now capped"). So a round that came back on a static check, an oracle failure or a quality finding leaves that counter exactly where it was, and so does a round the difficulty check never finished because of a technical problem. They reset differently too: a reviewer sending the task back restarts the platform's counter at zero while the round number keeps climbing, so a task at round 7 can legitimately be sitting at zero checks run with four remaining. Never derive either number from the other and never estimate one of them. Read both off the form and write both into the round record.

**2. Turn the feedback into a numbered item list, then work it.** One line per finding, each with the file it touches, **its provenance**, and the fix. Findings arrive in prose and bundle several asks into one paragraph - split them, or you will address four of six and think you are done. Reply to every item, including the ones you decide not to act on, with the reason.

**Provenance is a column, not a memory.** Mark every item **seed / source PR / created in round N**, because that is what decides where the fix goes. A PR-inherited finding is answered in `instruction.md` and never in `golden.patch`; a finding the bundle itself created is answered wherever the bundle created it. **Decide it per finding.** android-beacon 1177 kept a running tally instead, recorded in its own notes table as "confirmed six times, every oracle finding on this task has been PR-inherited", while the same file records one marked "true, and self-inflicted" - and a tally that hardens into a default routes a self-inflicted defect to an instruction-side fix (LEDGER **L79**).

**From about round 4, add the bundle's own diff to what you review.** By then most findings are yours rather than the seed's. On the task above, **all five findings of the round it was accepted on had been authored by earlier rounds**, and the most expensive had survived since the first rewrite. `diff -rq download/original work -x '.git'` and read the new material as an unreviewed submission (`learning/self-inflicted-defects-dominate-late-rounds.md`).

**Sweep the class, not the instance the report quoted.** When a report names one instance of a defect class, the same round sweeps the class across the whole bundle and records the sweep command in `task.md`. On that task the snapshot-shape class fired three times and was fixed pointwise three times, and the surviving instance is what a human reviewer found after every automated check had passed.

**Read the Guidelines section a finding cites before working it.** Reviewers are asked to cite the relevant section of the Guidelines in their notes for specific or easily-missed rules (`docs/tasking-guide.md`, reviewer form question 4), so a Needs Revision item may name the exact rule behind it. Open that section first - it settles what the finding is actually asking for faster than re-deriving the ask from the prose.

**Count the strikes before choosing a fix.** Every `task.md` carries a strike table, updated here, before any fix is chosen:

```
## Failure signatures
| Failure signature | Rounds seen | Fixes shipped against it | Strike count |
|---|---|---|---|
| Oracle Check 0/3 | 2, 3, 4 | solve.sh idempotency; -3way apply; mode fix | 3 |
```

**Keep a refusals table beside it, and re-read it before any round that reverses course.** A refusal that names a *mechanism* is a measurement, and it can only be reversed by refuting the mechanism, never by a change of instruction such as "take every item this time".

```
## Refusals
| Round | Item refused | Mechanism that makes the fix wrong | Predicted failure if reversed | Still holds? |
|---|---|---|---|---|
| 1 | compare the notification in strategy equality | Android `Notification` has no value equality | two identically configured strategies compare unequal | yes, and the contract was rewritten to match in round 6 |
```

On android-beacon 1177 that exact refusal was correct, was reversed on a change of instruction rather than a refutation, and five rounds later the contract was rewritten to say what the refusal had been describing.

A strike count of **2 forces the remove-the-dependency path**. It is not a nudge: a fix you verified locally that comes back failing a second time means your model of the environment is wrong, so shipping a third variation of the same theory is forbidden. Remove whatever the failure depends on instead (Section 4, two strikes). AltBeacon ran oracle 0/3 across three consecutive rounds and only invoked the rule afterwards, because nothing was counting.

**A stage that never ran is not a failure signature.** `Not run: difficulty screen` in a review-gate summary means the agentic judge blocked first, so the second stage never started. It is expected, not a second error to diagnose, and it does not get a row in the strike table (`docs/faq.md`, the "Review gate blocked at the agentic judge / difficulty screen" FAQ). The judge block is the one signature that round scored.

**Change only what the finding requires.** A revision round is not a tidy-up. Every file you touch that no numbered finding named has to be justified in Comments for Reviewer. Workspace bookkeeping - `task.md`, `INDEX.md`, `learning/` write-backs, rule files - is never part of the bundle diff and never appears in Files Changed.

**3. Make the edits in `tasks/<name>/work/`, under the same rules as the first pass.** Every hard boundary from Step 5 still applies - no tracked source edits, no pre-existing test file left modified in the shipped tree, no PR reduction, only the listed Dockerfile fixes. Feedback from a reviewer does not widen what you are allowed to edit. If a requested change would cross one of those lines, say so plainly in Comments for Reviewer and explain what you did instead.

**4. Re-run everything, and add one probe aimed at what this round changed.** The Step 5.5 battery is invariant while the bundle changes every round, so on its own it re-proves what earlier rounds established and is silent on the edit in front of it. Every round adds at least one hostile probe targeting its own change, and the round record names it and the test it kills. Measured on android-beacon 1177, where probe counts by round ran 1, 1, 2, 5, 7 and every probe answered a finding an earlier round had already been given. **A battery that has not grown since the last round is evidence the round was not verified, not evidence that it was.**

**Name all four Phase B runs in the round record, with a result or the words NOT RUN beside each.** A battery table with three green rows looks exactly like a table with four minus one, and nothing in the loop reads a table for **missing** rows. hulak 118 ran five batteries across four rounds with **Run 4, the gaming probe, absent from every one of them** under any name, and four rounds of platform checks, two agentic-judge passes and a human reviewer all went by without noticing (LEDGER L85).

**Re-run every standing audit, not only this round's probe.** When an earlier round removes a defect class, the command that proved it gone goes into a list in `task.md` beside the strike table, and runs before every zip from then on. The list only grows, the same way the probe battery does, and for the same reason: on hulak 118 round 0 removed six graded calls to unexported names, **round 2 put one back** while fixing something else, and round 3 was blocked on it by the agentic judge (LEDGER L83). Two supporting changes to the strike table, both cheap: give a round 0 finding a row at **strike 0**, so a signature is in the table before the round that recreates it, and add an **authored-in** column, because `Rounds seen` records detections and not authorship.

**4b. Re-run everything, not just the part you touched.** The full Step 5 Phase A pre-upload checklist including `git fsck --unreachable`, then the Step 5 re-zip rule into `tasks/<name>/upload/` overwriting the previous zip, then the WHOLE Step 5.5 Phase B battery - NOP, oracle 3/3, hostile delete, and Run 4, the gaming probe - from four fresh extracts of that new zip. Git hygiene comes immediately before zipping, every round, because the revision work recreates `.git/logs`, a stash and dangling objects exactly the way the first pass did. Write the new upload-ledger row after the zip verifies.

**5. Update `submission_answer.txt` - this is the step that gets skipped.** The file has to describe the bundle you are actually uploading now, not the one you uploaded last week. Do not regenerate it from scratch and do not leave it alone: edit the answers your changes affected and add the ones the changes created, and leave everything else as it stands.

**Re-derive every count in Files Changed from the live bundle, never from last round's prose.** This is the one place the answers audit was not looking, and the drift shipped inside an **accepted** submission: redisshake 1005's Files Changed entry 5 read `fail_to_pass 10 to 14 and pass_to_pass 1 to 11` against a live config of **20 and 13**, entry 4 named three graded files against **seven**, and the post-fix checkbox one line below read `counted: 20`, so the file contradicted itself on the same page. Nothing caught it, including the reviewer. A per-file "changed X to Y" sentence gets written in round 0 and then never re-read, because the round that changes X to Z edits the config and the issue block and considers itself done.

```bash
# measure first, then read every count in the answers against these
python3 -c "import json;g=json.load(open('tasks/<name>/work/tests/config.json'))['grading'];print('f2p',len(g['fail_to_pass']),'p2p',len(g['pass_to_pass']))"
grep -c '^new file mode' tasks/<name>/work/tests/tests.patch      # graded files created
grep -c '^diff --git'   tasks/<name>/work/solution/golden.patch   # golden file count
grep -nE '[0-9]+ to [0-9]+|\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty)\b' tasks/<name>/answers/submission_answer.txt
```

**The spelled-out half of that grep is the half that matters** - three of redisshake's four stale numbers were words, not digits, so a numeric grep could never have found them. And re-decide the `Pre-submit gate:` line every round: that accepted file still carried the old `Send to reviewer: No ... the checks have not run against it` while the task sat in front of a reviewer.

**A careful re-read of the answers file is not a check, and three measurements say so.** xlwings 2719
audited the file against measured ground truth three times, each audit run after a hand pass judged
clean, and they returned **9, then 11, then 6** confirmed defects the hand pass had missed every time.
The reason is structural: the recurring defect is not a wrong number but **a sentence that was true
when it was written and a later round made false**, and that does not read as wrong when you scan
past it. So the round's answers check is not "are the numbers right", it is **"what did this round
make false"**, run against the bundle rather than against the previous draft. Two mechanical checks in
`bin/checks/60-answers.sh` now cover the part that can be automated - `answers.count-*` reconciles any
count stated in more than one place, and `answers.graded-total` reads `tests/config.json` and fails on
any total-sized `N of N` in the prose that disagrees with it. Run `bash bin/checks/60-answers.sh
tasks/<name>` every round.

**Verify each finding yourself before you act on it, because a hurried fix is where the next false
statement comes from.** On that task two new false statements were created *while fixing old ones*:
one asserted a base-image pin had caused a build failure that a `git update-index` call actually
caused, and one added a correct round-count sentence without deleting the contradicting sentence it
was meant to replace, which is this section's own supersede rule broken inside the pass enforcing it.
And **annotating a superseded figure is not removing it** - relabelling an old total "numbers from
that round" still leaves a reviewer reading a stale figure in a reviewer-facing field. Superseded
numbers go to `task.md` (LEDGER L81).


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
| Pre-submit gate | Re-decide it against the Step 7 pre-submit gate every round. It is a template line, so it always carries either Clear or Not clear with a reason |

**6. Re-humanize the file after editing it.** Run the `humanizer` skill over the answers you touched, and re-check the whole file against Section 5 afterwards - the same no-wrap and no-LLM-tells rules, on the edited text and on the joins where new text meets old. New text pasted next to already-humanized text is where the tells reappear. Same exempt list: paths, test names, commands, code, checkbox lines, and the numbers.

**7. Record the round in `task.md` and update `submission_answer.txt` in the SAME action.** These were two separate steps and they drifted apart every time - AltBeacon's answers file carried a revision figure its own `task.md` still flagged as needing a fresh number after five rounds, and libcrux recorded outright that "the round-2 increment had been lost somewhere". Treat them as one write, never one after the other with thinking in between.

Into `task.md`: what the feedback said, the freshness-check result, what you changed, the new NOP / oracle 3/3 / hostile-delete / gaming-probe results, the check outcomes, the **Difficulty checks run** and **Difficulty checks remaining** values as the form read them this round, the updated strike table, and the new upload-ledger row. Plus the handling-time ledger, which is the only place the revision number is derived from:

```
## Handling time ledger
| Round | Date | Minutes added | Cumulative |
|---|---|---|---|
| 1 | 2026-07-30 | 65 | 65 |
| 2 | 2026-08-02 | 60 | 125 |
```

The answers file's "all revisions" figure is **copied from the last Cumulative cell**, not recalled and not re-estimated. Then update the status and the round number in `INDEX.md`. The record is what makes the next round cheap; without it you re-derive the history every time.

**The two difficulty-check numbers get a ledger of their own, for the reason this step already gives about the difficulty artifact and Step 11 gives about the closing numbers: nothing else holds them.** They are read-only fields on the submission, they are gone as soon as the page moves on, and a reviewer bounce silently resets them, so a run of rounds with no record leaves you unable to say how much of the current review cycle's budget has actually been spent. One row per round:

```
## Difficulty check budget
| Round | Date | Checks run | Checks remaining | Reset since last round? |
|---|---|---|---|---|
| 3 | 2026-08-15 | 2 | 2 | no |
| 4 | 2026-08-17 | 0 | 4 | yes, reviewer sent it back |
```

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

**Ask for the closing numbers in the same message that receives the acceptance.** An acceptance usually arrives as one line, and the three things the calibration row and the next task want are gone the moment the conversation moves on: the **final difficulty screen result**, the reviewer's **Submission Quality Score**, and any **reviewer notes**. None of them can be reconstructed later. ziti-sdk-c 668 closed without all three, so its row records an accepted bundle whose final measured difficulty nobody here knows. Ask once, immediately, and record `not supplied` if they do not come.

**2. Write the closing block into `task.md`.** The reviewer's verdict verbatim under a dated heading, the Submission Quality Score if one was given, the final round number, and the last row of the handling-time ledger. This is the last write to that file.

**3. Update `INDEX.md` in the same action.** Status becomes `accepted` or `rejected`, the two closing tokens the register defines. Round keeps the final round number. Then update the `pending-revision: N of 2` line under `## Active`, because closing a task is the thing that frees a slot and that count is what blocks the next claim (Step 1 item 5).

**4. Harvest before the folder moves.** Answer two questions in writing. What did this task prove that no note yet says, and what did it disprove that a note still says. A new fact gets a `learning/` note with frontmatter plus a row in `learning/README.md`. A disproved claim gets a `LEDGER.md` row. The Step 1 write-back rule says how to write one. **This step is when it fires.**

**On a Fixable task the reviewer ACCEPTED, the harvest has a named target and this step never said so.** `learning/accepted-bundle-reference.md` holds one row per `accepted` row in `INDEX.md` and its rows were all written by hand, because nothing in this list pointed at it. Re-derive the count with `grep -c '^| \[.*| accepted |' INDEX.md` rather than quoting the figure in that file, which measured stale by two on 2026-08-18. Add the row here: the measured shape (f2p, p2p, graded total, the battery results, the restore shape), **what acceptance validated**, and separately **what merely was not caught**, which is the distinction that file exists to keep. Write the second column honestly, because it is the one that decays: an acceptance validates what previously failed and was then changed, and anything a reviewer would have had to open the bundle to check is unproven rather than endorsed. If the reviewer supplied only the word accepted, say so in the row, since four of the ten already close with numbers unsupplied and their check panels are simply unknown. The reviewer-path counterpart, a bundle **you** accepted while reviewing, is a different population and goes in `learning/bundles-i-accepted-as-reviewer.md` under Section 13 F6 deferred maintenance, never in this one.

**5. Fill in the task's `learning/calibration.tsv` row.** Set `verdict` to the path submitted, set `outcome` to what the reviewer returned, and refresh every number the rounds moved: revision minutes, upload rounds, and any measured column that changed. A row left at its mid-flight values is worse than a missing one, because the next task reads it as measured.

**6. Move the whole folder to `_archive/<Original Directory Name>/`.** Whole and unstripped, the shape Section 7 describes. `download/`, `work/`, `upload/`, `answers/`, `task.md` and `task_details.md` all travel, and rule files cite paths inside archived bundles. Move it with `git mv` and confirm with `git ls-files _archive/<name> | wc -l`. **`tasks/` is gitignored and `_archive/` is not**, so this move is the moment the record becomes recoverable. Everything before it lives on one disk with no history.

**7. Repoint anything that cited the old path.** Moving the folder breaks every inbound `tasks/<name>/...` reference in `learning/`, the rule files and the README, and those are exactly the citations that made the note credible. `grep -rl 'tasks/<name>' --include='*.md' .` finds them; rewrite each to `_archive/<name>/...` and re-run `bin/doclint.sh`, which is what catches the ones you miss. On libcrux 1165 the move broke one reference in `learning/stock-bundle-defect-baseline.md` and doclint found it immediately.

Then say in chat that the task is closed, which notes were added, and what the `pending-revision` count now reads.
