---
id: reviewer-page-carries-the-whole-submission
status: locally-verified
last_verified: 2026-08-18
verified_by:
  - sample_review_page.md
evidence: "A markdown conversion of the whole live reviewer page for one submission (tair-opensource/redisshake 657, review UID 1f5ffbd1-489c-49c3-8c5b-695895bde5fc), captured 2026-08-18"
applies_to:
  languages: [any]
  runners: [any]
  phases: [peer-review]
blocks_submission: false
fails_gate: [none]
supersedes:
  - "reviewer-path.md, 'The live form has four questions, not seven'"
  - "reviewer-path.md, 'The submitter's Comments for Reviewer do not arrive with the zip'"
contradicts:
  - "LEDGER L65"
---

# The reviewer page carries the whole submission, and it always did

Three peer reviews were run here on 2026-08-11 on the belief that a reviewer gets a bare zip. All
three said so in their answer files, one of them in a sentence the submitter would read. The belief
came from what arrived in a chat message and was never checked against the page.

`sample_review_page.md` is a conversion of the whole reviewer page for one submission. It settles two
things this workspace had marked settled the other way, and it opens two capabilities no review here
has used.

## What is actually on the page

| Section | Lines | What it is |
|---|---|---|
| Automated feedback | `:11-13` | "All checks have passed", the platform's own headline |
| Reviewer Feedback | `:15` | the **previous** round's reviewer notes, dated, in full |
| Task metadata | `:19-48` | Original Directory Name, Category, Difficulty, Task Tags, Languages, the whole `task.toml` |
| Seed zip | `:62` | "Download Sentinel 2.0 task here", the task **as issued to the submitter** |
| Their verdict, the internal Validity radio, the duplicate question | `:64-95` | with **Invalid Difficulty** as a live fourth option on both |
| Both checkbox groups | `:99-119` | where the task had issues, and what issues they found |
| Their numbered issue details | `:121-139` | their analysis, in their own words |
| The submitted zip | `:141-147` | the re-upload, with its timestamp |
| Difficulty Checks | `:149-177` | checks run, checks remaining, **last counted submission version**, **last difficulty check result** |
| Submission Feedback | `:179-321` | Static Checks, Prescriptiveness, the difficulty results download, and the Difficulty Check, Agentic Judge Quality Report, Oracle Check and Quality Check panels **with their contents** |
| Files Changed, PR additions, the eight confirmations, the difficulty answer, the senior estimate | `:323-379` | |
| Comments for Reviewer | `:383-415` | the field `docs/tasking-guide.md` requires a reviewer to read |
| The reviewer's own form | `:417-467` | verdict, rebuttal acknowledgement, quality score, review duration |

The panels are not empty labels. This capture's Difficulty Check reads `Difficulty: PASS HARD` with
`codex-gpt-5-5: 25.0% (1/4 runs)`, the Agentic Judge reads `Status: OK`, the Oracle Check reads
`Oracle: PASS 3/3 runs passed` and `NOP: PASS 0/1 runs passed (expected 0)`, and the Quality Check
reads `15/15 criteria pass`.

## The four-question finding was a truncation artefact

`docs/tasking-guide.md:401-459` describes seven reviewer questions. Two captures on 2026-08-11 showed
four, and this workspace concluded the live form disagreed with `docs/` and retired the doubt, as
LEDGER **L65**. Both missing fields are on this page: the rebuttal acknowledgement at `:433-441` with
all three of its options, and the review duration at `:467`.

The mechanism is worth more than the correction. Both 2026-08-11 captures were **truncated
documents** - `reviewer-path.md` says so about them for a different reason, and one breaks mid-word at
"Oracle solution matches the inst". Truncation drops **trailing** fields, and those two sit at the
end. So two captures agreeing about an absence was one mechanism firing twice rather than two
independent witnesses, which is exactly the condition the retiring rule was written to require.

**The rule that replaces it: an absence is retired by a capture that could have shown the thing.** A
second document of the same kind is not a second witness. The sibling caveat is still open on the same
logic: Q2a, Q2b and Q3 are conditional on the verdict radio, and no capture here has had one selected,
so nobody has ever seen the Accept branch and the five-versus-six confirmation count stays unsettled.

## The two capabilities nobody has used

**The seed zip beside the submitted one.** The submitter's entire change is one command away:

```bash
diff -rq review_tasks/<name>/download/seed review_tasks/<name>/download/original -x '.git'
```

`self-inflicted-defects-dominate-late-rounds.md` measured that on one task **all five findings of the
round it was finally accepted on had been authored by earlier rounds of that same task**, and the most
expensive had survived every automated check since the first rewrite. The submitter path only reaches
that diff from about round 4. A reviewer has it on round 1 and had it all along.

**Their claims as a verification table.** `docs/tasking-guide.md` defines the reviewer's job as
independently verifying the submitter's findings. That is per-claim work and it needs their numbered
issue list, which is on the page. A claim that does not hold is its own finding, and it is Secondary
Requirement 5, metadata mismatch, where `docs/reviewer-rubric.md:105` puts a writeup that does not
match the actual diff. It is separate from whatever defect sits under it.

## What this changes about wording

`docs/reviewer-rubric.md:123` makes "claiming logs are inaccessible when they are visibly present" a
flaggable integrity item, listed beside pasted LLM output under a **Major** heading. "The submitter's
answers did not arrive with the zip" is the sentence this workspace writes that sits closest to it,
and on a page that renders them it would now be that item. The three reviews that wrote it were not
wrong about what they had; they were wrong about what was available, and the difference stopped being
invisible on 2026-08-18.

So ask for all of it in the message that receives the assignment (Section 13, R1.5), and when
something genuinely is missing, say what you did to get it in the same sentence.

## Two smaller things the same capture settles

**The page's Metadata block describes the seed, not the submission** (measured once, aws-lambda-web-adapter
183, 2026-08-18). On that review the page's block read `verifier timeout_sec = 300.0`,
`model_difficulty = "medium"`, `repo_license = ""`, `pass_at_k 0/3 and 0/3` while the submitted bundle
carried 1500, `hard`, `Apache-2.0` and `0/4` respectively, and the seed matched the page on all five.
So the task-metadata section of the reviewer page is generated from the task as issued and never
re-derived from a re-upload. Two consequences: the Step-2-style cross-check of the platform block
against the extracted `task.toml` has to run against the SEED's file, and a "the page says X but the
zip says Y" disagreement there is not a defect in the submission, it is the page being stale by design.

**`Invalid Difficulty` is a live option**, at `:69`, `:79` and `:93`, worded "Difficulty runs have
been exhausted and task is auto marked as invalid". `.claude/rules/03-submitter-form.md` recorded it
as documented in `docs/faq.md`, absent from `docs/tasking-guide.md:124-126`, and never seen on the
live form, with an instruction not to invent a fourth option. It is now seen. It appears on the
analysis question, on its duplicate, and in the internal Validity radio.

**All four difficulty-check fields are named.** `docs/faq.md` names two and says nothing about the
others. The page carries **Difficulty checks run** ("How many times the difficulty check has run on
this task **since the last review**"), **Difficulty checks remaining**, **Last counted submission
version** ("the submission version id the last increment was charged to, which is what makes a
platform retry of the evaluation cost no run") and **Last difficulty check result** ("Persisted so the
unfixable verdict can be re-applied if it is changed by the EC in the radio button"), at `:149-177`.

Two workspace readings become measured by those helper texts. The per-review-cycle reset was inferred
from one FAQ sentence and "since the last review" is the platform saying it. And "a technical issue
that prevents a result costs nothing" was flagged as a reading rather than a measurement; the
last-counted-version field is the mechanism that makes it true, because an increment charged to a
submission version cannot be charged to it twice.
