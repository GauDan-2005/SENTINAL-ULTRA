---
id: self-inflicted-defects-dominate-late-rounds
status: platform-confirmed
last_verified: 2026-08-16
verified_by:
  - 20260727_135618__AltBeacon_android-beacon-library__1177
  - 20260805_220102__xaaha_hulak__118
evidence: "All five findings of the accepted round were authored by earlier rounds of the same task, not by the seed or the PR. hulak 118 is the second instance and adds the regression direction: two defects an earlier round had closed were re-authored by a later round's fix, in two different files, inside one four-upload arc."
applies_to:
  languages: [any]
  runners: [any]
  phases: [revision, verification]
blocks_submission: false
fails_gate: [quality-check, difficulty-check, peer-review]
supersedes: []
contradicts: []
---

# The bundle's own diff becomes the higher-yield review target, and sooner than you think

*Measured at round 4 of 8 on one task and round 2 of 4 on another. The round number is not the rule;
see the second section for what is and what is still UNSETTLED.*

Source: `20260727_135618__AltBeacon_android-beacon-library__1177`, accepted 2026-08-14 on round 8
after 12 uploads. The full record is in `_archive/20260727_135618__AltBeacon_android-beacon-library__1177/task.md`.

The revision loop reviews the **seed**. Step 2 reads the delivered bundle, Step 3 runs the four core
principles over it, and every later round works whatever the newest report quotes. Nothing in the loop
reviews **the material the rounds themselves added**, and on a long arc that is where the defects are.

## The measurement

Round 8 was the last round and the one it was accepted on. It carried five findings. **Every one of
them was created by an earlier round of the same task.** None came from the seed and none came from
PR 1177.

| Finding | Authored in |
|---|---|
| the graded file only compiles against a non-optional snapshot type | round 0's test rewrite |
| the below-Android-8 default stated but never exercised | round 7's field-table edit |
| `jobPersistenceEnabled` applied false and asserted false at both sites | round 2's assertions |
| the loose git ref missing, so the tree depends on empty directory entries | the mandated pre-zip `git gc` |
| a `.gradle` cache inside `environment/repo` | local runs between rounds |

The first one is the expensive one. It had been present since the **first** rewrite, survived seven
rounds and every automated check, and was found by a human reviewer only because it killed 7 of 8
difficulty trials at `compileDebugUnitTestKotlin`. No panel could see it, because the oracle defines
the type and therefore compiles.

## Why the loop cannot see it

Each check looks at the bundle as a finished object, and each one is satisfied by the oracle:

- the **Oracle Check** applies `golden.patch`, which defines whatever the tests need, so it compiles
- the **NOP** already fails, so a compile error and a missing feature look identical
- the **hostile-delete gate** runs on top of golden, so it compiles too
- the **agentic judge** reads the files rather than building a counterfactual implementation

None of them asks the one question that matters here: would a *different but compliant*
implementation still work.

## What to add to the loop

**1. Read your own diff as an unreviewed submission, every round from about round 4.**

```bash
# what this task has become, against what was delivered
diff -rq download/original work -x '.git'
# what this round changed, against the last thing that was measured
git diff --stat            # if you keep the bundle under git, otherwise diff against the previous extract
```

Then read the **new** material with the Step 3 principles rather than the old: every sentence added to
`instruction.md`, every symbol added to `golden.patch`, every assertion added to `tests.patch`. The
question is not "is the bundle sound" but "is the material I added sound", and those have different
answers by round 4.

**2. Put a provenance column on the numbered feedback list.** Step 10 item 2 already turns feedback
into numbered items. Add one column: **seed / source PR / created in round N**. It is cheap and it
decides where the fix goes. On this task the same question was answered by a running tally instead,
and that is the next section.

**3. Sweep the class, never the instance.** When a report names one instance of a defect class, the
same round sweeps the class across the whole bundle and records the sweep command in `task.md`. The
snapshot-shape class fired three times here and was fixed pointwise three times: a `copy()` method the
instruction never asked for (round 2), two accessors graded but never declared (round 5, self-caught),
and finally the type of every field the graded tests read (round 8, found by a human). A fix scoped to
the sentence the report quoted guarantees the class comes back.

## A per-task tally is not a routing rule

This task's `learning/ notes applied` table recorded, as a property of the task, "confirmed six times.
**Every** oracle finding on this task has been PR-inherited". The same file records one that was not,
in the round 4 block: `applySettingsChange` pushing every managed field, marked **"true, and
self-inflicted"**.

The rule in `source-pr-cross-check.md` is *check each finding against the PR before touching
`golden.patch`*. It is a per-finding check. Once a tally of how often it came back inherited hardens
into a default, a defect the bundle itself created gets answered by narrowing the instruction, which is
both the wrong instrument and another sentence that then needs an assertion.

**Keep the count if it is useful, but never let it answer the next finding.**

## A refusal that names a mechanism is a measurement

Round 1 refused a reported item and wrote down why: `ForegroundServiceScanStrategy.equals` ignoring the
notification was reported as a defect, and the refusal said that comparing it "would make two
identically configured strategies unequal and break the instruction's contract in the other direction."

That is a mechanism, and it was correct. What reversed it was not a refutation but a change of
instruction, recorded as "the submitter's call changed from hold the oracle gap to fix all the items in
this revision". Five rounds later the contract was rewritten to say the notification counts by
identity, which is what the refusal had been describing all along.

**A refusal with a stated mechanism can only be reversed by refuting the mechanism.** Keep refusals in
a table beside the strike table, with the predicted failure mode, and re-read it before any round that
reverses course.

## The battery has to grow with the bundle

Every hostile probe on this task was retrospective. Probe counts by round were 1, 1, then 2, then 5,
then 7, and each new probe answered a finding an earlier round had already been given. The Step 5.5
battery is invariant while the bundle changes every round, so left alone it re-proves what earlier
rounds established and says nothing about the edit in front of it.

**Each revision round adds at least one probe aimed at what that round changed, and the round's record
names it.** A battery that has not grown since the last round is evidence the round was not verified,
not evidence that it was.

## A verification pass that runs after you act cannot see what it is checking

Recorded 2026-08-14 from the close of this same task, because it is the same failure one level up.

The close ran an analysis fan-out and then an adversarial pass over its findings. The analysis was
sound. The adversarial pass returned **refuted on all four**, and almost every refutation was the
same sentence: *this is already written*. It was, because the findings had been written into
`learning/` in the interval between the two phases. The verifiers were reading a workspace that
already contained the edits they were sent to question, and they could not tell a note written two
minutes earlier from one written two weeks earlier.

Nothing they said was false. The pass was simply spent re-discovering the writes rather than
attacking them, which is the one thing it existed not to do.

**Rule: when a review runs against a target you are also editing, either run the review before you
edit, or freeze what it reads.** In practice:

- do the analysis, then the adversarial pass, **then** write. Writing between them destroys the pass
- if the write cannot wait, tell the verifier what changed and when, so "already present" is a
  question it asks rather than an answer it accepts
- treat "this is already written" from a verifier as a claim with a timestamp attached. Check the
  file's mtime against the start of the round before believing it

Two of the four refutations survived this correction and were real: a mechanism restated in a caveat
that `rust-cargo-verifier-gotchas.md` section 4 already tabulates, and a column whose two readings
had never diverged before this task. Both were taken. That is the yield of a verification pass that
was mostly wasted, and it is the argument for ordering it properly rather than for skipping it.

## "About round 4" is wrong, and the reason is UNSETTLED (hulak 118, accepted 2026-08-16)

Second confirmation, and it moves the number. `20260805_220102__xaaha_hulak__118` was accepted after
**four** rounds, not eight, and the crossover happened at **round 2**:

| Round | What blocked it | Who authored the cause |
|---|---|---|
| 0 | arrival: 13 findings, six unguessable private names taking all 17 graded ids down | the seed |
| 1 | human reviewer: 4 untested requirements, stale metadata, a dirty shipped tree | the seed |
| 2 | difficulty screen `FAIL EASY` at 75% / 75% | **unmasked by round 0's solvability fix**, see below |
| 3 | agentic judge `DISCUSS` / `overreach` on one unexported helper call | **round 2's own test edit** |
| 4 | nothing, accepted | |

**The round-2 row is the weaker claim and it is worth stating weakly.** A solvability fix does not
author a difficulty defect, it stops masking one. Everything both judges later quoted as
over-specification is in the **seed** instruction: the exported signatures, the `Dropdown` semantics,
and the module pin the judge cited "at :5" is the seed's own line 5. Round 0 could not have cut any
of it, because every symbol was called by a graded test (LEDGER L37). What round 0 removed was the
compile failure holding the arrival rating at 0 of 3, which let the seed's own over-specification
become the binding constraint. It is still self-inflicted in the sense that matters - the round that
fixes solvability is the round that owes a difficulty lever ([[clarity-fixes-spend-difficulty]]) -
and it is not the same as that round having created the defect.

**Do NOT read the crossover off the size of the first rewrite.** That was the obvious explanation
here and it does not survive the second data point. hulak's round 0 replaced 8 of the bundle's 9
editable files, a near-total rewrite, and its crossover was round 2 of a 4-upload arc. AltBeacon's
round 0 was **also** a test rewrite, and it is where that task's most expensive defect was authored,
and its crossover was still round 4 of a 12-upload arc. Arc length is uncontrolled between the two,
so rewrite size is not isolated. **UNSETTLED.** What would settle it is one task with a small round 0
and a long arc, scored the same way.

**The reading that costs nothing while it stays unsettled:** start reading your own diff as an
unreviewed submission on the first round after a rewrite that replaced most of the editable surface,
rather than waiting for a round number to arrive.

## The regression direction: a fix for finding A reinstates defect B

This is not the same as sweeping the class, and the existing sections do not cover it. Sweeping the
class asks whether a **reported** defect has siblings you have not found. This asks whether a defect
you already **removed** has come back in through work you did afterwards.

hulak carries **two** independent instances inside one four-upload arc, in two different files:

| Round that removed it | Round that put it back | Round it was reported again |
|---|---|---|
| 0 removed six non-derivable private names from the graded tests | 2 called `itemZoneID` while adding a parity check | 3, agentic judge `overreach` |
| 1 set `pass_at_k_*` to the full-run 4/4 and 2/4 at a reviewer's direct request | 2 overwrote both with the cheap-screen 3/4 figures | 3, the report called them invalid evidence |

Neither is an identifier problem, and only one is even about tests. The common shape is that **the
fix for finding A walked over the fix for finding B**, and nothing in the loop reads the earlier fix.
On the first row the helper was simply the obvious way to locate a row while adding a parity check.

**Nothing in the loop was looking.** The technique was right, documented and applied. What was
missing was anything that re-ran round 0's own check after round 2 edited the same file.

**So every audit a round invents becomes a standing audit.** When a round removes a defect class,
the command that proves it gone gets written into `task.md` and re-run in every later round, over
the whole surface rather than over the instance a report named:

```bash
# hulak's, run over BOTH graded files and every selector, every round
git -C environment/repo grep -c -- "<name>" HEAD -- '*.go'   # empty means the symbol is new
grep -c -- "<name>" instruction.md                            # 0 means it is unstated
#   absent at base AND unstated  ->  overreach, and it is yours
```

It takes seconds. It is the only thing standing between a green local battery and a judge block, and
on this task it was written in the round that got blocked rather than in the round that could have
prevented it. **Keep the standing audits as a list in `task.md` beside the strike table, each with
the command it runs, and run the whole list before every zip.** The list only ever grows, the same
way the probe battery does, and for the same reason.

Two cheap changes to the strike table make a regression visible instead of leaving it to memory:

- **A round 0 finding gets a strike row at strike 0.** hulak's round 0 counter read `| - | - | - | 0 |`,
  so the name-dependency signature had no row at the moment round 2 recreated it, and the row was
  retro-added in round 3. A signature that only enters the table when it recurs cannot warn the round
  that recreates it
- **Add an authored-in column.** Step 10 already requires provenance on the numbered item list; the
  strike table has `Rounds seen` and no equivalent, so it records detections only. hulak's row reads
  "Rounds seen 0, 3" for a defect authored in round **2**, and the round that authored it is the one
  a reader needs

## The close is a submission, and it needs the same audit (hulak 118, 2026-08-16)

The section above says a verification pass run *after* you edit cannot see what it is checking. This
is the other half, measured on the close of the same task: the harvest itself is unreviewed material,
and it is written fast, at the end of a long session, by someone who has stopped expecting to be
wrong.

That close wrote about thirty files in an hour: a task record, twelve `learning/` notes, four LEDGER
rows, seven rule files, three twinned pairs, `INDEX.md` and `calibration.tsv`. A four-lens adversarial
pass over the result confirmed **26 defects**, nearly all authored by the close. Three were blocking.
The rest were counts that disagreed with each other, a heading asserting what its own body refuted,
and an upstream-PR fact re-worded rather than re-fetched.

**Three findings generalise well past this task.**

**1. Validating a fix against the corpus you have is not validating the fix.** The close corrected the
Section 10.3 which-shape snippet for Go, ran it against all eight archived bundles, reproduced every
known figure, and installed it. It was still wrong three ways, each silent, each printing a number
with zero UNRESOLVED: a test function on a **context** line of a modified file was never found, a name
defined in a **different** package matched anyway, and a **nested** `go.mod` fell through. None could
appear in the corpus, because every Go bundle on the machine is create-only and single-module. A
three-file fixture found all three in two minutes.

**Build the fixture for the case your corpus cannot contain.** The corpus tells you a change did not
break what you already measured. It cannot tell you the change is right, and the gap between those two
is exactly where a silent defect lives.

**2. Twinning discipline covers code blocks, not only prose.** The close edited both halves of three
`.mdc` / `SKILL.md` pairs for a one-line count and left a **third copy of the defective snippet** sitting
in `sentinel-task-fixing`, which is the file a Cursor session actually reads. Grep for the artefact you
changed, not for the file you changed:

```bash
# after editing any snippet, table or command that appears in more than one place
grep -rln 'a distinctive line from the block you just edited' CLAUDE.md .claude/ .cursor/ learning/
```

**3. "Validated across all N" is a claim about the N.** The close wrote "validated across all eight
archived bundles" when the set was seven archived plus one still in `tasks/`, and the eighth archived
bundle was precisely the one the tool does not resolve. Enumerate the population in the sentence, or
the reader inherits a completeness you never had.

**So run the close through the same door as a round.** The cheapest version is one adversarial pass
over the finished edits, before you report them, asking the four questions that catch this class: what
was true when written and is now false, what count disagrees with the same count elsewhere, what
external fact was recalled rather than re-fetched, and what claim is about something that did **not**
change. All four have now produced real defects here, twice.

## Related

- `quality-check-criteria.md` - the compile-compatibility sweep, and the coverage debt a narrowing creates
- `source-pr-cross-check.md` - the per-finding PR check this section warns against averaging
- `LEDGER.md` L21 - auditing every absolute claim is necessary and not sufficient
- `accepted-bundle-reference.md` - both bundles' measured shapes, as the fifth and sixth accepted ones
- [[non-derivable-private-names]] - the defect class that came back, and the audit that catches it
- [[clarity-fixes-spend-difficulty]] - why hulak's round 2 was blocked by its own round 0
