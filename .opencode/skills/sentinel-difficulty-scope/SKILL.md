---
name: sentinel-difficulty-scope
description: PR scope and difficulty rules for Sentinel Ultra tasks. Use when assessing task difficulty, planning difficulty-raising edits, or verifying that edits stay anchored to the source PR (expansion only, never reduction or replacement).
---

> **Mirror.** This skill and `.cursor/rules/sentinel-difficulty-scope.mdc` hold the same rules. Edit both together - Cursor loads the `.mdc`, Claude Code loads this file.


# Sentinel 2.0 — PR Scope & Difficulty Check

Use these rules whenever assessing task difficulty, planning difficulty-raising edits, or verifying that changes stay anchored to the source PR. Companion to sentinel-task-check (verdicts, four principles) and sentinel-task-fixing (how to execute edits).

**Source of truth:** `docs/` is the local export of the Sentinel Ultra Hub. When this file disagrees with `docs/guidelines.md#pr-scope-and-task-difficulty` or `docs/faq.md`, the docs win.

---

## 1. Difficulty baseline — what to assume on arrival

- Sentinel tasks train and evaluate frontier coding agents, so they must be **genuinely hard** — an easy task gives no useful signal
- The bar is a pass@k threshold: a frontier model solves a Medium task in at most 4 of 8 attempts, a Hard task in at most 2 of 8. Use the trial outcomes in `runs/` when a difficulty claim needs grounding
- Every task that reaches this workflow has **already passed the difficulty checks**. Do NOT re-judge difficulty from scratch, and do not flag "seems easy" as a finding on its own
- Difficulty evals do NOT re-run on tasks marked **Valid as-is** — which is exactly why the local oracle and NOP run is mandatory on that path
- BUT: clearing the difficulty bar does not mean the task is free of other issues — and **fixing those issues can pull difficulty back below the benchmark**. When that happens, the platform's evals send the task back to raise it again
- Practical consequence: after any edit that ADDS context to the instruction (a required name, an output format, clarified requirements), explicitly note that difficulty may have dropped and a bounce-back from the evals is possible

---

## 2. Troubleshooting difficulty (when a task is, or becomes, too easy)

**First read WHICH stage blocked, because only one of them measured difficulty.** The review gate that runs before a task reaches a reviewer has two stages - the agentic judge first, then a difficulty screen which is a cheap single-arm rollout - and the second only runs if the first passed (`docs/faq.md`, the review gate FAQ "My eval says Review gate blocked at the agentic judge / difficulty screen"). Neither stage is the task's final difficulty grade; the full difficulty rollout is a separate check that runs later, after a reviewer accepts.

- **Blocked at the difficulty screen** - the model solved every attempt, so the task is trivially easy and this section is the work to do

**Before choosing a lever, build implementations and measure.** This is the first move on a screen block, ahead of every lever class below, and it is cheap. Generate three or four implementations of the feature from `instruction.md` alone, each blind to `golden.patch`, `tests/` and the upstream commit, then run the graded suite against each. It answers three questions at once and the third is the one nobody expects:

- **does anything in the suite discriminate.** ziti-sdk-c 668 got four for four at 26 of 26, which together with the platform's seven agent runs is eleven implementations and not one failed requirement. That converts "this feels easy" into a measurement, and it is what two rounds of argument could not settle
- **is the suite overfitted to the oracle.** All four invented their own type for a map's values and all four still passed, which is the graded assertions reading behaviour rather than the oracle's internals
- **where the lever is.** Make each implementation end with an honest list of what it was unsure about or did not implement. Three of four independently named the same unasked-for gap, it had a matching fix in a related later PR, and grading it dropped all four to 25 of 26 while the oracle held at 26

A behaviour they merely **disagree** about is not a lever when the instruction is deliberately silent on it: grading it is overreach and stating it first hands over the answer. Full method, and the two ways a candidate dies under measurement, in `learning/implementation-control-is-the-lever-generator.md`.

**And read the unit table before reading the headline.** The `Unit Tests Results` block counts agent runs only, so the pass count subtracted from the run count separates real failures from runs that never reached a test at all. Then type the build command an **agent** would type, with the network off, because a default target that shells out to the network poisons a run every screen and looks exactly like difficulty (`learning/difficulty-screen-unit-table.md`).
- **Blocked at the agentic judge** - difficulty was never measured this round at all, because the screen never ran. `Not run: difficulty screen` in the summary is the expected consequence of that, not a second error. Fix what the judge flagged and resubmit; do not start raising difficulty on the strength of a judge block
- The one infra case is a message that explicitly says the difficulty screen failed with an infra error - no verdict was produced, so retry

Work through these in order:

**Step 0 - before any of the steps below, check whether the source PR's own author got anything subtly wrong.** This is the cheapest question in the section and it decides whether you are looking for a lever or at a ceiling. A place upstream got wrong is a trap, and a trap you have found is one a weaker model can walk into; a PR with no such place is where a difficulty ceiling is structural. redisshake 1005 had three, all still on the project's default branch, and was accepted on round 4 after four `FAIL EASY` screens. libcrux 1165 had none, because its PR wraps existing functions, and was accepted as Not Fixable. Same symptom, opposite verdicts, and this is what separates them (`learning/when-fail-easy-is-not-not-fixable.md`).


**Step 1 — Check for over-prescriptive instructions first.**
Often the instruction hands the agent context it should have discovered itself:

- the files to touch
- the root cause
- a step-by-step approach

Remove anything the agent could reasonably find by exploring the codebase, and remove any solution-revealing names or paths (those are also leakage). Describe the **behavior you expect**, not the how. (Full over-prescription sign list: sentinel-task-check §4. Rewrite patterns: sentinel-task-fixing §2.)

**Step 2 — Apply the balancing principle.**
This is the crux of the work: a task needs **enough context to be solvable, but not so much that it becomes instructional**. Every trim must be re-checked against solvability — never trim a genuine public contract or required output format.

**Step 0b - before designing anything, look for a stated clause nothing grades.** This outranks
adding a requirement and it is what actually cleared xlwings 2719. Split every sentence already in
`instruction.md` into clauses, and for each one make the smallest oracle edit that violates it and
run the graded suite. A clause where the suite stays green is free difficulty: the behaviour is
already stated so the task is fair, the agent is already told to build it, and closing it costs one
graded id and **no new instruction text**, so no new leak or over-prescription surface. That task
went 87.5% to 75% to **37.5% solves and passed the screen** on a round whose only change was an
assertion on the untested half of one sentence, and the platform artifact names that id in two of
the three failing trials (`learning/probe-the-instruction-you-already-wrote.md`).

**Two lever families, and only one of them has ever measured anything here.** Measured across three
rounds on xlwings 2719, both duds were **type-system puzzles** and both looked excellent on paper.
The second was built on `issubclass(dt.datetime, dt.date)` being `True`, adapted from a related later
PR, closing a TODO the source PR left. Eight independent agents implemented it from the requirement
text alone; the six that implemented it at all passed everything, and their own write-ups named the
trap unprompted while writing the code. **A trap a frontier model can recite is not a trap.** What
did move the number was **stateful interaction**: state that has to stay straight across a sequence
of operations, where the natural implementation loses track. Prefer that family, and measure either
way before the requirement is written (LEDGER L80).

**What to do when you have run out of levers.** Measured on redisshake 1005: four consecutive `FAIL EASY` screens, answered with four different lever classes, every one measured at 0 of 4 against a local control, plus six further related PRs surveyed and rejected. That was a complete Not Fixable dossier and the task was **accepted on round 4**. Three rules come out of it:

- **Your local control is a ceiling, never a forecast.** It runs on a model newer than the ones the screen grades, so an all-pass says the lever *might* be worth nothing and never that it is. Quote the number with the model attached, as "4 of 4 against Opus 5". The platform artifact for that task showed gpt-5.5 losing seven graded assertions to a trap the control had found 16 times out of 16
- **Ship the round anyway when it independently improves the bundle.** More coverage, a real defect fixed, a path graded that was not graded before - all of that is true whatever the screen says, and it is what got the task accepted. The screen answers difficulty; you answer whether this bundle is better than the last one
- **Try the classes in cost order, cheapest first.** Withholding a stated answer from the instruction costs no scope, no id budget and no reviewer risk, and it was the class that actually bit on the platform. Withhold a fact when its natural wrong reading is **silent** - it compiles, runs and looks plausible. State it when the wrong reading fails loudly on the first byte, because that is a debugging speed bump rather than difficulty

**A repeated `FAIL EASY` does terminate now, and the line that said otherwise held until 2026-08-14.** This paragraph read "not a strike count that terminates" until then and that reading is superseded: `docs/faq.md`, "Difficulty checks are now capped - what is Invalid Difficulty?", gives a task **four** difficulty checks, and once the fourth has run without passing the platform writes **Invalid Difficulty** into the validity answer itself and sends the task to review as it stands. What survives is the reasoning under the old line - two strikes tells you to stop refining one theory, and four screens answered with four genuinely different lever classes is four theories rather than four variations of one - so the argument is intact and what is gone is the unlimited attempts to work through it.

**What spends a check, and what resets it.** The counter moves only when a difficulty check runs AND returns a result, so a submission that comes back to you before the check runs costs nothing, and a technical issue that stops a result costs nothing. A reviewer sending the task back restarts the count at zero, which makes the budget four per review cycle rather than four per task lifetime. Two of the four new read-only fields, Difficulty checks run and Difficulty checks remaining, are where you read what is left.

**So the measurement moves in front of the upload, and that is the practical consequence of the cap.** Implementations built from `instruction.md` alone (`learning/implementation-control-is-the-lever-generator.md`), the discriminate matrix run across them (`learning/difficulty-levers-must-discriminate.md`), and the clause-by-clause probe of the instruction you already wrote (`learning/probe-the-instruction-you-already-wrote.md`) were advisable while rounds were free, and they are what the budget is now for: a check spent finding out whether a lever chosen by reasoning works is a quarter of it. That consequence follows from the cap by reasoning rather than from a run, because nobody here has hit the cap yet.

**Invalid Difficulty is the platform's verdict and not yours.** When the task comes back once with it already set, resubmit the bundle unchanged and leave the verdict where the platform put it - it is not a rejection and a human reviewer still reads it. Your own route to Unfixable - Difficulty is unchanged, Step 0 above and Section 6 below still decide that, and a local control is still a ceiling rather than a forecast. redisshake 1005 sits at or past this cap, four `FAIL EASY` screens with the record silent on how many checks ran in total, and it predates 2026-08-14 and the policy is not retroactive, so it was not affected. Its lesson is not withdrawn, it is now something you have four checks to demonstrate rather than unlimited ones.

**Step 3 — If trimming isn't enough, expand the PR scope** (Section 3 rules).

**Step 4 — Keep any added difficulty REAL.**

- ✅ Good difficulty comes from the problem itself: complex debugging, root-cause analysis, a substantial feature, hard domain/security work
- ❌ Difficulty must NOT come from vague or underspecified requirements, or from stapling unrelated changes together — those make a task **confusing, not difficult**, and a reviewer will flag them

---

## 3. PR scope rules (the anchor)

When fixing a task you can change the instruction, tests, and oracle — but you **cannot change what the task is about**. The source PR anchors what the task is.

### ✅ Allowed

**Add to the scope of the PR to make the task harder.**

- Example: original PR adds a `/health` endpoint → you extend it so the endpoint also handles auto-restart on failure
- Example: original PR fixes a single edge case in a date parser → you extend it to handle three additional edge cases

**Where the added material may come from.** When a task comes back too easy you may look at LATER PRs in the repo and adapt a change from a **related** one for inspiration (`docs/faq.md`, "A task came back too easy - can I adapt a change from a related PR to add complexity?"). Three bounds, all of them from that answer:

- Do not pull from **unrelated** PRs
- Do not copy a PR **wholesale** - adapt from it, do not lift it entirely
- Do not change the **scope or feature** of the original PR/task - you are adding to it, not replacing it

This is an extra source of material inside the expansion-only rule, not a relaxation of it. The anchor still has to hold: the task must map back to the ORIGINAL PR, with the adapted material building on that change rather than sitting beside it as a second PR. A later PR you took inspiration from is never a new anchor - `task.toml` still points at the original, and the scope-check procedure in Section 4 is still run against it.

### ❌ Forbidden

- **Reduce** the scope of the PR to make it more concise
- **Replace** the PR with a different feature or task type entirely
  - Example: original PR is a bug fix → it cannot be rewritten as a feature add
  - Example: original PR is a refactor of module X → it cannot become a refactor of module Y

### Worked example (from the FAQ)

Source PR adds **CSV export** to a reports page:

- ✅ **Adding complexity:** let the user pick which columns to export, or handle edge cases the PR missed (empty results, commas and quotes inside cell values, very large exports)
- ❌ **Changing the scope:** swap it for PDF export, replace it with something unrelated, or strip it down to exporting only the current page

Rule of thumb: if the task still clearly maps back to the original PR, just bigger or more thorough, that is adding complexity. If it no longer resembles the PR, or does *less* than the PR, the scope changed → Not Fixable.

### Hard rule

If the ONLY way to make a task solvable, difficult enough, or valid is to reduce or replace the PR scope, the task is **Not Fixable**. Say which kind, Structure or Difficulty, whenever you record that verdict (Section 6).

**Why this matters:** the task is anchored to a real PR via task.toml. If the task no longer resembles the PR, the link is misleading and the dataset loses its grounding in real-world engineering work.

---

## 4. Scope-check procedure

Run this whenever edits are planned or reviewed:

1. Fetch the source PR from task.toml (`[metadata] source`, or `source_pr_url` on older tasks). Summarize its intent in one line: type (bug fix / feature / refactor), module/area, and the behavior it changes
2. Summarize the task's current intent the same way, from instruction.md plus the oracle
3. Compare the two: same problem? same type? same module/area?
4. If the scope was expanded, verify the **anchor is preserved**: the original PR's change must be fully contained in the expanded oracle, with the additions building on it — not parallel unrelated changes bolted alongside
5. Classify the relationship as exactly one of:
   - **Identical** — task matches PR, no scope change
   - **Valid expansion** — original PR + additions, anchor intact
   - **Scope reduction** — forbidden
   - **Scope replacement** — forbidden (different type or different module/area)
6. If a valid expansion happened: confirm the instruction and tests were updated in lockstep, the instruction still reads as one realistic ask, and the difficulty eval is re-run

---

## 5. Red flags to raise

- Instruction hands over files to touch, the root cause, a stepwise plan, or solution-revealing names/paths → over-prescribed (fix by trimming, Step 1)
- A planned "difficulty increase" that is really added vagueness, underspecification, or an unrelated bolt-on → reject the plan, find real difficulty or expand scope properly
- An edit that adds names, formats, or clarifying context to the instruction → note possible difficulty drop and eval bounce-back
- Any fix plan whose feasibility depends on shrinking or swapping the PR's behavior → stop, escalate to **Not Fixable**
- An expanded task where the original PR's change is no longer recognizable inside the oracle → anchor broken, treat as scope replacement

---

## 6. Verdict interactions

- Task too easy, fixable by trimming prescription → **Fixable** (instruction rewrite)
- Task too easy, trimming insufficient → **Fixable** (scope expansion per Section 3, difficulty eval re-run)
- Only path to solvable / difficult / valid requires reducing or replacing the PR, so **Not Fixable**, and name which of the two kinds it is. `docs/reviewer-rubric.md:28` is **Unfixable - Structure**: the only fix is changing or reducing the source PR scope, or an environment issue ECs are not allowed to touch. `:29` is **Unfixable - Difficulty**: the task cannot be recalibrated without leaving the PR scope. `:31` says reviewers must tag the two separately, because lumping them together as "invalid" is what sends ECs into 3 or more unpaid revision loops. The form still offers one Invalid option, so the distinction has to be carried in the unfixable explanation instead
- Task under-difficult but genuinely raisable inside the PR scope is **Fixable**, and on the reviewer's side it scores as a Minor rather than a Major (`docs/reviewer-rubric.md:111`, Secondary Requirement 11, difficulty drift recoverable). It stays Minor only while it really is recoverable in scope. Once it is not, the row above applies and the kind is Difficulty
- Four difficulty checks have run and none of them passed, so the platform has already set the validity answer to **Invalid Difficulty** itself. That is its verdict rather than yours: the task comes back once, the bundle is resubmitted unchanged, and the verdict is left as the platform set it (`docs/faq.md`, "Difficulty checks are now capped"). It is not a rejection, a human reviewer still reads it, and it is not licence to record Unfixable - Difficulty in your own answers
- Task marked Valid as-is → no difficulty re-judgment needed; evals do not re-run

### Known conflict: the linter vs a difficulty downgrade

If a task's measured difficulty comes back different from its declared metadata and the linter then rejects the task as "easy", the two demands pull in opposite directions — matching the metadata to the measurement is exactly what trips the linter. This is a **known platform issue**, not a task defect.

- Do NOT hand-edit the pass-rate or difficulty fields in `task.toml` to satisfy a reviewer or the linter
- Do NOT tune the values back and forth trying to satisfy both
- Tell the user to flag it on the Slack channel with the task/submission UID and the two conflicting values (the linter's difficulty floor vs the measured/updated metadata)

Separately, `stb submissions list` from the CLI is the source of truth for a submission's state — the GUI lags and can make a task flicker in and out. If the CLI and GUI disagree, or a submission is stuck, flag it on Slack with the UID.

---

## 7. Quick checklist

- [ ] Did not re-judge arrival difficulty from scratch
- [ ] Instruction hands over nothing the agent could discover by exploring the codebase
- [ ] No files-to-touch lists, no root cause, no step-by-step approach in the instruction
- [ ] Context balance holds: solvable, not instructional
- [ ] Any added difficulty is real (debugging, root cause, substantial feature, domain/security) — not vagueness or unrelated bolt-ons
- [ ] Any expansion = original PR + additions, with the anchor fully preserved
- [ ] No scope reduction anywhere; no task-type or module replacement
- [ ] If scope expanded: instruction and tests updated in lockstep, difficulty eval re-run
- [ ] Difficulty checks remaining read before the round is planned, and the lever measured locally before a check is spent on it
- [ ] If shrinking/replacing the PR is the only viable path: task marked Not Fixable with reasons, and the kind named as Structure or Difficulty
