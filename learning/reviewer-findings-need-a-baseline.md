---
id: reviewer-findings-need-a-baseline
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260720_144200__thomas4019_expressa__132
  - 20260723_030152__mithriljs_mithril.js__2021
evidence: "Four metadata findings filed on expressa 132; three withdrawn after measuring _archive/*/download/original/, and one of the three was already LEDGER L58"
applies_to:
  languages: [any]
  runners: [any]
  phases: [peer-review, analysis]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts: []
---

# A reviewer finding is a claim about the submitter, so it needs a baseline

A submitter finding says "this bundle is wrong". A **reviewer** finding says something stronger and
more personal: "the person who submitted this either did it or failed to catch it". That second
claim needs two things the first does not. A baseline for what the bundle looked like before anybody
touched it, and a check that the change you are asking for does not break something else.

expressa 132 was reviewed without either. Four metadata findings went into a draft that was handed
over. **Three of the four were the generator's default**, present identically in every bundle this
workspace has ever seen, and one of those three had already been filed, withdrawn and written into
`LEDGER.md` as **L58** eleven hours earlier by the other review on the same day.

Two of those three are still withdrawn and they are the worked example this note runs on:
`difficulty` against `model_difficulty`, and `[agent] timeout_sec`. The third, the verifier timeout,
came back as a real finding on 2026-08-14, when `docs/reviewer-rubric.md:101` made it a documented
Minor violation (LEDGER **L73**). That does not weaken the rule. A baseline tells you **how to word**
a finding, and only sometimes tells you whether to file it at all.

## The failure that matters most: the LEDGER was not read

`CLAUDE.md` Step 1 says to read every file in `learning/` first, and `learning/README.md` names
`LEDGER.md` as the first file to take, because it is "the list of claims this workspace has
**disproved**, so a wrong idea does not come back looking new". The session read `README.md` and
went straight to the task. `LEDGER.md` itself was never opened.

The cost was exact and predictable. L58 reads:

> `[verifier] timeout_sec` in `task.toml` and `execution.timeout_sec` in `tests/config.json`
> disagreeing is a metadata accuracy finding. mithril.js 2021, filed and withdrawn. Measured across
> `_archive/*/download/original/`: all five bundles ship 300 against 1800.

That is the finding, the measurement, and the exact command, written down before the session started.
It was re-derived from scratch, re-filed, shipped to the user in a deliverable, and withdrawn.

**L58's conclusion was superseded on 2026-08-14 and this section is unaffected.**
`docs/reviewer-rubric.md:101` makes the pair a documented Minor violation, so the finding is real
again (LEDGER **L73**). What went wrong here was never the verdict. It was that a session spent its
budget re-deriving a measurement the workspace had already written down along with the command that
produced it.

**Rule. `LEDGER.md` is read before the first finding is written, not as part of a general sweep of
`learning/`.** It is the only file in the workspace whose entire purpose is to stop you writing
something. Read it late and it cannot do its job. `bin/learning-query.sh` exists for exactly this
lookup.

## It recurred, twice, in one finished document (mithril.js 2021, 2026-08-11)

Knowing this rule is not the same as running it. The mithril review shipped **two** `_archive/*/work/`
baselines, "the five bundles I compared against all carry `os = linux`" and "five other bundles ship
both scripts at 0755", in a document whose own closing note gets the framing right eleven lines later
for the verifier timeout. Measured against `download/original/` on 2026-08-14, `os` is **present in
0 of 8** arriving bundles, and neither script arrives at `0755` in any of the 8, seven of them at
`0644` and redisshake 1005 at `0444`. Both findings survive in the weakened form this note
prescribes; both sentences were false about what any submitter received.

The fix is not more care per finding, because per-finding care was already being applied. It is a
grep over the **finished answer** for every sentence shaped "N other bundles do X", asking which tree
each was measured against. That is check 1 of Section 12.10 and LEDGER **L72**.


## The pristine baseline, measured once so nobody measures it again

Every value below was read from `_archive/*/download/original/task.toml`, the untouched extract,
across all five archived bundles, plus the three `review_tasks/` extracts where a row says so.
**`work/` is the wrong place to measure a baseline**, because
`work/` is what the submitter changed, so comparing a bundle under review against five `work/`
copies measures the other submitters' rewrites and calls the difference a defect.

| Field | Arrives as, n=5 pristine | Accepted bundles' shipped value | So a difference is |
|---|---|---|---|
| `[environment] os` | **absent, 5 of 5** | **added, 5 of 5** | a real finding, weakly |
| `[metadata] difficulty_explanation` | **absent, 5 of 5** | added, 4 of 5 | a real finding, weakly |
| `[verifier] timeout_sec` vs `execution.timeout_sec` | **300 vs 1800, 5 of 5** (7 of 8 with the three review extracts, cista 172 arriving matched at 300 against 300) | 4 of 5 cleared it; only kvdex 245 shipped it inverted, 900 against 1800 | **a real finding, Minor**, since 2026-08-14 |
| `difficulty` vs `model_difficulty` | **hard vs medium, 4 of 5** | shipped unchanged, 4 of 4 | not a finding |
| `[agent] timeout_sec` | **1800, 5 of 5** | 2 of 5 kept it | not a finding |

Note the shape of the rows that survive. They are not "the submitter broke this". They are "this
arrives that way everywhere, and the submitters who got through review corrected it, and this one
did not". That is a fair thing to ask for and it has to be **worded** that way, or the submitter
reads an accusation and checks their own diff, finds they never touched the field, and stops
trusting the rest of the page.

The timeout row joined those two on 2026-08-14, when `docs/reviewer-rubric.md:101` made a verifier
timeout shorter than the task's own configured timeout Secondary Requirement 1, a Minor violation
flagged in 18% of reviewer comments. `docs/` outranks a note on policy, so that row's measurement
stands and only its verdict flips (LEDGER **L73**). It gets the same wording as the other two, and
it gets both numbers named, which is what the rubric asks for. The evidence behind the old verdict
did not survive re-measurement either: 4 of 5 accepted bundles ship the verifier budget at or above
the execution budget, and statrs 315 did not keep the mismatch, it dropped `execution.timeout_sec`
from 1800 to 240.

The command:

```bash
for d in _archive/*/download/original review_tasks/*/download/original; do
  [ -f "$d/task.toml" ] || continue
  echo "== $d"; grep -nE '^\s*os\s*=|difficulty_explanation|timeout_sec|model_difficulty' "$d/task.toml"
  grep -o '"timeout_sec"[^,}]*' "$d/tests/config.json"
done
```

## The mirror check: does the fix you are asking for break something else

A reviewer writes `What to do.` lines. Those are instructions someone will follow, and they can be
wrong in a way a pure observation cannot.

On expressa the draft said to delete the leaked error strings from `instruction.md`. The observation
was right, since ten of eleven probed literals were restated there. The instruction was wrong.
`docs/guidelines.md:99` exempts "exact assertion strings, state paths, or fixture values from tests
**unless they're a genuine public/API contract**", and `:101` requires stating a required response
shape because "leaving it to guesswork is what breaks solvability". Those error strings are HTTP
response bodies, and two graded tests assert them. Following that advice would have traded a
non-blocking instruction finding for a blocking test-alignment one, which is the same trap
`learning/prescriptiveness-check.md` describes from the submitter's side.

**Before telling a submitter to remove a name or a literal from the instruction, grep the graded
tests for it and split the list.** On expressa the split was clean and belongs in the answer itself:

```bash
for s in "<each literal the instruction restates>"; do
  printf "%-52s tests.patch=%s\n" "$s" "$(grep -Fc "$s" tests/tests.patch)"
done
```

Thirteen file paths, zero graded references, all safe to cut. Six literals with a graded assertion
behind them, all of which have to stay stated somewhere. Handing over both halves is what makes the
finding actionable instead of dangerous.

## mtime forensics, the cheapest read in a review

A reviewer gets a zip and no diff. `unzip -l` gives one anyway, because the generator stamps every
file at build time and only what the submitter rewrote carries a later mtime.

```bash
unzip -l <submission>.zip | awk '{print $2, $3, $4}' | sort | uniq -c | sort -rn | head
```

On expressa 132 every one of the 188 entries carried `2026-07-20 14:42` except `task.toml` at
`2026-07-22 02:20`. That is a one-command answer to "what did this submitter actually do", it framed
the whole review, and it is defensible in the quality score because it is an observation about the
archive rather than an accusation.

Two caveats to state whenever it is used. A submitter who edits with a tool that preserves mtimes,
or who rebuilds from a fresh extract, leaves no trace. And an unchanged mtime proves the file was
not written, not that its content is correct, so it supports "they did not do the rewrite" and never
"the content is wrong".

## What this note is not

None of the above says be timid. The same review filed eleven notes that all survived adversarial
verification, five of them measured in a container, including an oracle that scores 2/3 and a
compliant agent edit that becomes an invalid trial. The discipline is not fewer findings. It is that
each one gets a baseline before it gets a paragraph.
