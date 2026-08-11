_Owner of CLAUDE.md **Section 5**. Loaded every session._

## 5. Writing Rules for Free-Text Answers

Applies to issue descriptions, the unfixable explanation, "What makes this task difficult", and Comments for Reviewer:

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
