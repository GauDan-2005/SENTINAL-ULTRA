---
id: reviewer-can-be-handed-the-seed
status: locally-verified
last_verified: 2026-08-18
verified_by:
  - 20260724_132921__gnmyt_MySpeed__1536
evidence: "One zip on the reviewer page, four independent tells that it is the pristine seed, and the submitter confirming there is no re-uploaded zip"
applies_to:
  languages: [any]
  runners: [any]
  phases: [review]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts: []
---

# The bundle on the reviewer page is not always a submission

`.claude/rules/14-reviewer-workflow.md` R1.5 asks for two zips and treats the second one, from the
re-upload field, as the thing under review. LEDGER **L101** established that the page renders both.
Neither says what to do when only one arrives, and the answer is not "the page is broken".

**The re-upload field is conditional.** `sample_review_page.md:136-141` shows it under the heading
"If Fixable is selected, please re-upload the entire task as a zip file". A submitter who has not
selected a verdict has not made that field render, so the page shows one zip and it is the SEED, in
the required "Download Sentinel 2.0 task here" field at `:62`.

## What that looks like, measured on gnmyt/MySpeed 1536, 2026-08-18

Everything else on the page argued that a corrected bundle existed. Automated feedback read "All
checks have passed". There was reviewer feedback dated 8/15/26 describing a zip with real fixes in
it, referring back to an 8/11 round. The difficulty block carried a last-counted submission version
id and a last result of `easy`. The difficulty answer was filled in.

What was actually there was the task as issued. The rest of the submitter form was blank, including
both verdict radios, the internal Validity field, the senior estimate, Comments for Reviewer and all
four handling-time fields.

## Establish which bundle you hold before writing a word

The cheapest test is the **previous round's reviewer feedback on the same page**, because it
describes the bundle it reviewed. Turn each of its statements into a check:

| The 8/15 note said of the bundle it reviewed | The zip on the page |
|---|---|
| `solve.sh` no longer has `git apply -R` | it has it, at line 9 |
| `tests.patch` creates `preference_format_sentinel_f2p.test.mjs` | it creates `FormatUtil.test.mjs` |
| the `800 to 100` and `95 to 11.88` numbers are gone from the instruction | both present at `instruction.md:7` |
| HEAD is `ee2f027`, parent `bd75c310` | HEAD is `bd75c310` itself |

Four for four. Add the archive's own stamp as a fifth: **all 558 entries carried the single mtime
`2026-07-24 13:30`**, which is the build time in the directory name `20260724_132921`. A submitter
rewrite leaves later mtimes on the files it touched, which is the whole basis of the 12.4 item 3
forensics, so a uniform stamp equal to the folder name is the generator's own archive.

When there is no previous round to check against, the mtime stamp and the R4 sweep still separate
them. A seed carries the generator's defects untouched, and this one carried eight of them.

## Ask, and then do not stall

The ask is one message and it belongs in R1.5 beside the rest. What it must NOT do is stop the
review, for a reason that is specific to this shape: **the seed is the R3 baseline either way.** If a
submitted zip arrives, everything measured on the seed becomes the diff target, which is the
highest-yield read a reviewer has. If it does not, the seed IS the submission and every measurement
is already a finding. Nothing measured before the answer arrives is wasted, so measure first and ask
in parallel.

What DOES depend on the answer is the wording, and only the wording. Until it is settled, no note may
say a submitter did or failed to do anything, because on the seed reading they did nothing at all.

## The thing to be careful about in the written answer

`docs/reviewer-rubric.md:123` makes claiming something is inaccessible when it is visibly present a
flaggable integrity item, so the honest sentence names the field rather than the artifact. Write that
the re-upload field did not render and that the submitter form is blank apart from one answer. Do not
write that their answers did not arrive, which is a claim about the platform, and do not write that
they submitted nothing, which is a claim about them.

## What it costs if you get it wrong

Every finding lands against the wrong artifact. On this task that would have been five Majors and six
Minors filed against a submitter who, on the record available, never uploaded the bundle they were
being judged for. LEDGER **L105** is the same failure at smaller scale, a review about to tell a
submitter their Oracle Check was 1 of 3 when their own page said 3 of 3.
