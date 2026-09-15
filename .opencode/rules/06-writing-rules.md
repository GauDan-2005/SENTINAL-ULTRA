_Owner of CLAUDE.md **Section 5**. Loaded every session._

## 5. Writing Rules for Free-Text Answers

Applies to issue descriptions, the unfixable explanation, "What makes this task difficult", and Comments for Reviewer, and to every free-text answer in `review_answer.txt` on the reviewer path, which Section 12.8 already says follows these rules in full. The scope is form answers and it stops there. `instruction.md` is not a form answer, and LEDGER L57 is the finding that was lost to reading it as one:

- **Simple 8th-grade English** - basic plain easy to read
- **100% humanized** writing
- **NO LLM artifacts**: no em dashes (the long dash, U+2014), no en dashes (U+2013), no arrows (U+2192, U+2190, U+2194), no markdown symbols in the answer body (`**`, `##`, backticks around prose), minimize commas, no colons, no semicolons (code examples are exempt from these style rules)
- **NO internal check vocabulary.** The reviewer sees your answer with none of the context this workspace has. Never write a criterion label (`Q9`, `Q10`, `Q13`, `Q15`), a judge axis name (`test_coverage`, `oracle_spec_faithfulness`, `test_faithfulness`), a reason string (`coverage_gap`, `oracle_spec_gap`), or a fraction score (`13/15`, `2 of 15`) in an answer. Say what the defect was in plain words instead - "the instruction quoted the exact error text the tests check for", not "Q10 leakage". Real answers files have shipped both. The mechanical check is a bare grep over the whole file, with no exclusions, and any hit outside a code example is a defect. **The grep has to cover the whole ban and not just the punctuation half of it** - the version of this line that only listed `Q9`, `Q1[0-5]`, `→`, `–` and `/15` let judge axis names, reason strings, verdict words and bare axis scores ship in reviewer-facing prose across five rounds of AltBeacon 1177, because nothing in the check looked for them:

```bash
grep -nE 'Q(9|1[0-5])\b|/15|→|←|↔|–|—|\*\*|oracle_spec_faithfulness|oracle_spec_gap|test_coverage|test_faithfulness|coverage_gap|weak_check|self_contained|prescriptiveness|\brealism\b|\brubric\b|\baxis\b|\baxes\b|adjudicat|\b(DISCUSS|REMOVE)\b' answers/submission_answer.txt
```

Words that are also ordinary English need judgment, not a blanket delete. `prescriptiveness` attached to a score is an axis name and goes; the platform's own checkbox says "overly-prescriptive" and that phrasing is fine. Say the defect in plain words instead of naming the axis - "the quality report marked the oracle down against the instruction", not "oracle_spec_faithfulness 2.5"
- The one exception is a **verbatim quoted report line** inside a code block, where the labels are part of the quote. Quote it as a block, do not paraphrase its vocabulary into your own prose
- Reference specific things verified from the task files (file names, function names, test names, line numbers, patch details)
- Issue descriptions follow the numbered form format exactly and may include code examples
- Difficulty and Comments are one short paragraph each (Comments may be a few short lines when listing several points)
- Never pad with generic filler like "this task tests real-world skills"
- **NO word wrap in `submission_answer.txt`** - every paragraph is ONE long line, however long it runs. Never hard-wrap at 80 columns or any other width, and never let an editor reflow the file. Break lines only where the form itself breaks: between list items, between checkbox lines, between the `- Is this issue fixable` sub-answers, between the separate short lines of Comments for Reviewer, and inside code examples. Everywhere else a newline is a defect, because pasting into a platform text field carries it across and the reviewer reads prose chopped mid-sentence. Verify after writing the file: any prose line that ends without the sentence ending was wrapped, and the lines have to be rejoined
- Declare what you deliberately did NOT fix. If the prescriptiveness check still has residual findings, say in Comments for Reviewer which names stayed and that the graded tests call them by name, so nobody reads it as the report being ignored (`learning/prescriptiveness-check.md`)
- **Run the `humanizer` skill over every paragraph the user will paste into the platform** - the issue descriptions, the difficulty answer, the unfixable explanation, and Comments for Reviewer - at both points it matters: when the text is first drafted in a chat message, and again over the finished `submission_answer.txt` as the closing action of Step 9. The second pass is not redundant, because answers get edited, merged and re-ordered on the way into the file. Code, file paths, test names, commands, diffs, checkbox lines, and the handling-time numbers are exempt and stay verbatim

### 5.1 Reviewer-facing prose, and the six soft signals

`docs/reviewer-rubric.md:113-123` scores the reviewer's own writing as a **Major** defect when it reads as LLM output. It names six soft signals and says any **four in one review is Major on its own**: uniform em-dash usage, exhaustive parallel bullet lists, mirrored instruction language, academic filler, zero natural typos, rubric-aware framing. The `Meets` line at `:119` pulls the other way and is the half that gets dropped - comments have to be specific and idiosyncratic, citing exact files, tests, config keys or eval results from this task. So the evidence is never what gets cut. The framing is.

Measured 2026-08-14 across the three finished reviews in `review_tasks/`, which are three unrelated bundles:

| Signal | Where this workspace stands | What retires it |
|---|---|---|
| uniform em-dash usage | **Retired.** Zero em dashes and zero en dashes in all three answer files, because the rules above ban them outright | already done, keep the bare grep |
| exhaustive parallel bullet lists | **Exposed, in prose clothing.** There is no prose bullet list anywhere, since every dash-prefixed line in the three files is a form checkbox. What is exposed is the same shape as prose: of the 39 notes, 33 carry a labelled `What to do.` line and 20 carry a labelled `Guidelines reference.` line, in the same order every time | vary the note by what the finding needs, below |
| mirrored instruction language | **Exposed, and the worst of the six here.** All three files open Q3 with the same ten words, "Start with what is right, because none of it should", parting company only at word eleven. All three then carry "I built the image and ran the bundle, which a reviewer is not required to do" verbatim. The closing notes are near-identical across bundles that share no code and no language | write the framing sentences from this bundle, below |
| academic filler | **Not exposed.** A scan of all three files for the usual filler openers returns nothing. The filler bullet above and the `humanizer` pass are what keep it that way | keep running both |
| zero natural typos | **Exposed, structurally, and it stays that way.** `aspell` over all three returns identifiers and technical terms only, with no natural misspelling in any of them. Do NOT introduce typos or broken grammar to defeat this signal, and never read this row as licence to. It is retired by real variation in how sentences are built and by writing each one out of a measurement you actually took, which is the thing a template cannot fake | vary construction, write from what you measured |
| rubric-aware framing | **Not exposed in the measured set, and newly available.** All three reviews were written 2026-08-11 and the rubric tab was announced 2026-08-12, so there was nothing for them to mirror, and the four scoring words appear three times between them, every one as ordinary English. The tab now supplies the vocabulary. Citing the Guidelines section behind a finding is asked for by the form itself (`docs/tasking-guide.md:437`), so a `docs/guidelines.md` citation is never the signal. The signal is narrating your own answer in the scoring ladder, or walking the error-category list box by box | cite the rule, never the scoring ladder |

**Three of six, measured, which is one short of Major.** Do not read one short as comfort. The typo row can never be retired, so a review starts every time with one of its four already spent, and the sixth signal became available on 2026-08-12, which means a review written today in the old template shape is one scoring sentence from Major. Two of the three that are exposed came out of the template rather than out of the reviewer, so retiring the parallel note shape and the shared framing sentences is what buys the margin back, and both are done below. `learning/reviewer-rubric-is-the-documented-bar.md` carries the same three with the same evidence.

**Vary the note, keep every citation.** Every finding still carries its file, its line and its measured number. Dropping a citation to sound more human fails the bar it was meant to pass. What changes is the packaging around the evidence:

- Number the findings so the submitter can answer them one by one, and stop there. Beyond the number a note owes nobody a fixed set of labelled lines
- Cite a `docs/` section when one genuinely backs the finding, and leave the line out when none does. Twenty of thirty nine notes had one, which is the right ratio and not a slot to fill
- Say the remedy where it fits. A one-line change belongs in the sentence that names the defect, and a remedy with a sequence, a payload or a measurement behind it earns its own paragraph. Both are still remedies and the Section 12.10 audit still reads them against each other
- Let the length follow the finding. A measured blocking defect runs long, a lost mode bit runs to two sentences

**Write the framing sentences for this bundle.** The opener, the closer, and the sentence saying what you ran are the three places boilerplate collects, because nothing about the bundle forces the words there. The content of each stays: what the bundle gets right with the numbers, what you are not asking to change, and which findings you measured against which you read. The wording comes out of this bundle's own measurements. Check it before shipping:

```bash
for s in "<your opening sentence>" "<your measured versus read sentence>" "<your closing note's first sentence>"; do
  grep -rnF "$s" review_tasks/*/answers/review_answer.txt
done
```

A hit in a review of a different bundle means the sentence is boilerplate and gets rewritten.

**Two items at `docs/reviewer-rubric.md:123` are about honesty rather than style, and each is one clause of work.** Never write that something was unavailable without saying what you did to get it, because "claiming logs are inaccessible when they are visibly present" is a flaggable item and "the submitter's answers did not arrive with the zip" is the sentence this workspace writes that sits closest to it. And when a finding rests on a baseline from other bundles, name it as your own reference set in the same sentence, so a cross-bundle measurement is never read as a reference to content that is not in this task.

**The mechanical check runs over the paste and not over the whole file, and that is the one scoping this rule set allows.** `review_answer.txt` is two documents in one file. Everything above the `--- Not part of the paste. Record only. ---` marker is what the submitter reads, and everything below it is the tally the verdict is arithmetic on, which Section 12.2 and the Path D template both require to be written in the rubric's own terms and never pasted. So the check is the grep above with the scoring ladder added, run against the paste alone:

```bash
sed '/Not part of the paste/,$d' answers/review_answer.txt |
  grep -nE 'Major Pillar|Secondary Requirement|Pillar [0-9]|soft signal|Minor violation|reviewer.?flag|\brubric\b'
```

This is not the self-confirming check the common-mistakes list warns about, where an exclusion is written around the thing the check exists to catch. The cut is at a marker that already exists for a different reason, the text below it never reaches the submitter, and the ban itself does not move: **no scoring vocabulary in the paste, none at all.** A finding that needs a Secondary Requirement named is named in plain words to the submitter and by its number in the tally. Write "the verifier timeout is 300 seconds against a configured 1800" in the paste, and "Minor, Secondary Requirement 1" in the record block, and both readers get what they came for.

The same judgment as with the axis names applies to what is left. Calling a defect major or minor in plain English is ordinary writing and stays. The compound labels are the ladder and come out.
