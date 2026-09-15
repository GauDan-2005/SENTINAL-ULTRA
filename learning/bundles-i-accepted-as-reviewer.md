---
id: bundles-i-accepted-as-reviewer
status: locally-verified
last_verified: 2026-08-20
verified_by: []
evidence: "Accepted reviewer tasks are learned from after the form document is created. Section 13 F6 records the review UUID in review_tally.md and updates this file with platform evidence plus any triggered static check."
applies_to:
  languages: [any]
  runners: [any]
  phases: [peer-review]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts: []
---
> **Process scope, 2026-08-19.** This note contains legacy deep-battery Accepts and future timed-static Accepts. A legacy row may name local battery results. A timed-static row instead names the review UUID, platform panels read, any recorded static extension, what the task teaches, and the parts not inspected. Docker, Harbor, Oracle, NOP, container, mutation, and full-audit work are not routine timed-review steps.


# Bundles I accepted as a reviewer

A separate population from `accepted-bundle-reference.md`, and the two are never merged.

## Why it is a separate file

`accepted-bundle-reference.md` holds the bundles **this workspace submitted** and a peer accepted.
This file holds bundles **someone else submitted** and a review here accepted. They answer different
questions and no sentence should cite one while meaning the other:

- `accepted-bundle-reference.md` answers **what got us accepted**
- this file answers **what the bar lets through when I am the one applying it**

**The first draft of this section gave a false reason for the split, and the real one is worth more.**
It claimed that dropping a foreign bundle into the other note would change `n=` in
`.claude/rules/09-task-toml-reference.md` column three. It would not: no `n=` anywhere is derived
from a markdown note. Column three counts **`_archive/*/work/` trees** and column two globs
`_archive/*/download/original` plus `review_tasks/*/download/original`, and that file says so at the
paragraph following its baseline table. So the contamination risk is not what you write, it is
**where the folder lands**: a review's `work/` is a copy of another EC's submitted bundle, and
archiving a review flat would put it straight into the population that answers "what a submitter here
shipped". Section 13 F6 archives to `_archive/reviews/<name>/` for exactly that reason, one
level deeper so `*` cannot reach it, and the column-two loop globs the archived reviews back in on
purpose because an arriving bundle is an arriving bundle whoever was sent it.

That is the same family as LEDGER **L61** and **L72**, which cost this workspace two withdrawn
findings when a `task.toml` baseline was read off `_archive/*/work/` and reported five other
submitters' rewrites as one bundle's defects. The lesson holds and the mechanism is a path, not a
paragraph.

**Do not quote either file's `n=` as current.** Measured 2026-08-18: `grep -c '^| \[.*| accepted |'
INDEX.md` returns **10** and `ls -d _archive/*/ | grep -v superseded | wc -l` returns **10**, against
"seven accepted bundles ... eight accepted submissions" in `accepted-bundle-reference.md` and `n=8`
in `09-task-toml-reference.md`. Both are stale by two. `09-task-toml-reference.md` does warn that
"both counts move every time a task is archived" and says to re-run its loop; `accepted-bundle-reference.md`
carries no such warning against its own figure, so do not credit it with one. Either way this file
cites the **derivation** rather than the number, because a number in prose goes stale and a `grep -c`
does not.

## Why an Accept you reviewed is stronger evidence than an Accept you received

This is the point of the whole exercise, and it inverts the central caveat of the other file.

`accepted-bundle-reference.md` warns, correctly, that an acceptance validates what previously failed
and was then changed, and that **anything a reviewer would have had to open the bundle to check
merely was not caught**. It says so because nobody here knows what those reviewers opened. hulak 118
closed on the single sentence "This task has been accepted." and elfuse 162 on the word accepted, so
both rows carry an explicit unknown where the evidence should be.

When **you** are the reviewer that unknown is **bounded**, which is weaker than gone and is the
honest word. By R9 you have run eight battery rows, the stock-defect sweep, the PR comparison at hunk
level and the requirement mapping, and you know which of them you ran. So the split between what
acceptance validated and what merely was not caught is drawn **at the time** from your own run list
rather than reconstructed afterwards from a one-line message. That is the whole of the improvement
and it is real.

**It is not "gone", and this workspace has measured why.** A row recorded as run and clean can have
measured the wrong thing. `audit-the-finished-review-not-just-each-finding.md` records a careful
review that ran `solve.sh` three times, reported **3 of 3** in its paragraph of things that are
right, and was wrong: the real protocol is `solve.sh` then `test.sh` three cycles and it scored **1
of 3**. That trap is still live in the tooling, because `bin/local-run.sh`'s `thrice` row is exactly
that weaker shape and reads like the covering check (LEDGER **L102**). And beyond a mis-run row there
is the run you never thought to make, which is why the same note's fifth audit check is "walk the run
list, not the finding list".

**Two guards, and the second one is new because the first is not enough.**

- An Accept reached by **reading** harvests nothing. If R6 rows came back `NOT RUN`, the harvest
  inherits that and says so per row. Provenance is already the R9 rule for a finding and it is the
  same rule here
- The row records the **command** used per battery row, not a tick. A row satisfied by the wrong
  invocation cannot then read as clean, and run 2 is the one the shipped tool will silently mis-fill

**And a forced Accept harvests nothing at all.** When the maximum-revisions dialog has fired and
Reject is unavailable for the workflow, `docs/tasking-guide.md:366` tells you to select Accept and
document the outstanding issues so the adjudicator can see them. That verdict means the bundle does
**not** meet standards, so putting it in a file about what the bar lets through would invert the
file's whole meaning. Tag it forced in `task.md` and in `review-calibration.tsv`, and write no row
here.

## Fixable is the case worth harvesting, and here is why

A **Fixable** submission that you accept is a bundle whose author found defects, changed things, and
cleared your bar. You hold both zips, so `diff -rq download/seed download/original -x '.git'` is the
full list of changes, and R3 has already scored each of their **claims** HOLDS or DOES NOT HOLD
against it.

**What that licenses, exactly.** Acceptance is one bit over the whole conjunction, so it says the
diff as a set did not stop the bundle clearing the bar. It does **not** say each change was
necessary, that any of them caused the acceptance, or that nothing survived unfound. LEDGER **L53**
retired that reading in its general form: acceptance validates what previously failed and was then
changed, and everything else merely was not caught. The per-change evidence you actually have is your
own R3 table, which is why the harvest is worth taking from a review and not from a bare outcome. Nothing else in this workspace produces that: our own accepted bundles show
fixes that worked, but only ours, written to these rules, by this author.

The other two shapes teach less and are not nothing:

- **Valid as-is, accepted.** The seed cleared the bar untouched. That is a statement about **arriving
  bundles** rather than about rewriting, and it belongs in the arriving-bundle baseline in
  `.claude/rules/09-task-toml-reference.md`, not here. Record it as one line and move on
- **Invalid / Not Fixable, accepted.** There is no bundle at all, so what you learned is about the
  written argument. `not-fixable-is-a-written-argument.md` is the file for it

## What to harvest, four headings

Four headings, not "buckets": `.claude/rules/13-reviewer-path.md` already uses **three buckets**
for the rubric's Fixable / Unfixable-Structure / Unfixable-Difficulty split, and reusing the word for
a different taxonomy inside the same domain is how a citation goes to the wrong place. These four
exist because they have different half-lives and different owners.

**1. Technique to adopt.** Something the bundle does that this workspace does not. This is the
highest-value bucket and the one a reviewer is uniquely placed to find, because a peer's bundle is
the only independent sample of how the job can be done. If it is genuinely new it gets its own
`learning/` note with frontmatter and a row in `learning/README.md`, and this file just points at it.

**2. What the bar let through.** The Minors you accepted are the boundary of the standard as actually
applied, measured, with your name on the verdict, and they are the honest answer to a submitter
asking how strict this is. List them by Secondary Requirement number here and in plain words in the
review itself, which is what the mandatory coaching comments already are.

**One to four is the case that owes coaching, and zero is also an Accept.** `docs/reviewer-rubric.md:19`
reads "Tasks with 1-4 minor violations **may** be accepted with mandatory coaching comments", which
sets what a small pile of Minors costs and does not make Minors a precondition. A bundle with no
Major and no Minor is the score 4 or 5 case at `docs/tasking-guide.md:458-459`, "no significant
issues" and "reference-quality". So an empty column four is a real result rather than an unfinished
row, and it is the **more** interesting of the two, because a bundle that survived eight battery rows
and a stock sweep with nothing to coach is the closest thing to a worked example this workspace can
obtain from outside itself.

**3. What your probes could not reach.** Two things, not one, and the second is the one that gets
dropped. The `NOT RUN` rows are the obvious half and are worth more than a green tick, because they
are what the next reviewer should try first. The other half is **what each row that DID run did not
try**: a probe bounds its own path and not its class. `.claude/rules/11-verifier-hardening.md` records
the case directly, where a review named three agent-writable routes, measured one, and all three
reached reward 1.0 when finally run. So one clause per green row naming the single path it neutered,
rather than a tick that reads as the whole class closed.

**4. How they wrote the answers, which is not in the bundle at all.** The reviewer page renders their
Files Changed, PR additions, numbered issue details, the eight confirmations and Comments for
Reviewer (`sample_review_page.md:323-415`), so an accepted Fixable submission hands over a worked
example of **form answers that cleared a reviewer**. This workspace has one per `accepted` row in
`INDEX.md`, ten as of 2026-08-18, and zero from anyone else, and it has spent more rounds on answer quality than on almost anything else. Worth
recording: how they worded a de-prescription without breaking test alignment, what they declared
under PR additions, whether their issue blocks used the seven verbatim category strings, and how long
their Comments for Reviewer ran.

**The guard on this bucket is sharper than on the other three, and it is measured.** An accepted
answers file is a sample of what **passes**, never a sample of what is **correct**.
`answers-file-drift.md` records four stale counts shipping inside an accepted submission, one of them
contradicting a checkbox on the same page, with the reviewer not catching any of them. So harvest
their **wording and structure**, and re-derive any **number** you intend to reuse from the bundle
itself. You are uniquely placed to check that here, because R3 already scored their claims against
the seed-versus-submitted diff: a Files Changed entry marked `DOES NOT HOLD` in your own table is a
worked example of the same defect class, caught rather than shipped.

## The row

One row per accepted review, written after the form document is created under Section 13 F6. Append the exact review UUID to root `review_tally.md` at the same time, then archive later when the platform outcome allows it.

**The numbers are not repeated here.** `learning/review-calibration.tsv` already carries `review`,
`their_verdict`, `my_verdict`, `score_given`, `minors`, `workflow_standard`, and timed form-ready fields, keyed on the same
`review` value, and a figure living in two files is a figure that will disagree with itself. This
table holds only what a tsv cell cannot: prose. The Minor **detail** belongs here because the tsv
column is a count; the Minor count does not.

| Review | Minors accepted, by requirement | Technique adopted | Answer-writing worth copying | What I could not reach, incl. what each green row did not try |
|---|---|---|---|---|
| 20260805_220102__aws_aws-lambda-web-adapter__183 (round 2 of the task, first Accept here) | One: the writeup does not match the diff (Secondary Requirement 5). Six instances: "difficulty fields left untouched" while model_difficulty went medium to hard and pass_at_k_gpt_5_5 went 0/3 to 0/4; Comments claiming the difficulty mismatch "still" exists when the pair agrees; pass_to_pass written as 19 against 21 in config.json; "golden ships a pinned Cargo.lock" with no such hunk; an oracle score of 36/36 against a graded set of 37 tests plus the sentinel. The bundle itself needed nothing | Three worth taking. (1) The graded suite drives a real TLS stack two ways at once: a raw loopback socket that reads the first bytes off the wire (stack-agnostic: 0x16 0x03 is a handshake in every TLS library) for the "is it encrypted" questions, and a real `openssl s_server` plus a native-tls acceptor for the round-trip questions, so a fake-handshake implementation cannot pass. (2) A suite-completed sentinel id emitted by `execution.commands` only when both test binaries' logs carry a real summary line, listed in pass_to_pass, so a truncated or crashed run scores 0 without any parser cleverness. (3) The exit-code discipline lives in `execution.commands` itself: `set -o pipefail` as the first command, per-binary `PIPESTATUS` capture, then an explicit `exit 1` gate, so the runner's own status is the graded one. Also: the mutual-TLS extension is the first accepted-in-review expansion of a source PR I have measured, and it stayed inside the same connector and request paths | Their Files Changed is one line per file with a Why, which is the shape to copy; the content is the cautionary half, since five of its claims fail against the zip and my own R3 table caught them only because both zips were in hand. The lesson is the file's own guard: every count in a Files Changed entry gets re-read out of the live config, never out of the previous round's text | Battery rows 3 (hostile delete), 5 (sh invocation), 6 (forced test edit) and 8 (two-extract determinism) were NOT RUN, on the user's mid-review instruction that no further containers run. Row 1 (NOP) and row 2 (the real solve-then-verify protocol, 3 of 3 at 38 of 38) ran in the image with the network off; neither tried an agent that stages or commits work before the verifier runs, though the create-only patch plus the delete-created-paths step was simmed host-side with planted files. Row 4 was answered structurally (integration tests compiled as their own crates, std assertions, support files arrive at verify time only) plus the NOP as the no-solution baseline, and never tried a forged-marker write to the real stdout fd from library code, which the exit-code gate makes worthless only while cargo's exit stays honest |
| 20260729_094233__layui_layui__1569, review UUID 817d6834-c6e3-4fc5-923e-ae3a6563b555 | Three. The verifier's 300 second outer limit is below the 1800 second configured test limit. The page says 13 graded behavior cases although config declares 20. task.toml also omits os and difficulty_explanation and leaves repo_license blank. | No new technique adopted. The bundle does correctly delete the verifier-only test destination before applying a create-only patch, and the raw exit code gates the reward. Both are established practice rather than new evidence. | Do not copy the count wording. The Files Changed entry and the difficulty answer both retain 13 after the final config has 20. This is another reason to derive every form count from the uploaded artifact. | Timed-static review only. No Docker, Harbor, Oracle, NOP, container, mutation, broad requirement map, or full PR comparison ran. The current platform panels and ZIP fast gate were read. The fast gate's raw-exit warning was refuted by tests/test.sh lines 513 through 517. |
| 20260804_160342__connectrpc_connect-rust__239, review UUID d1ced1cb-e60f-4c7f-88cf-492d63463f9a | One. The Files Changed field omits `solution/solve.sh`, `tests/test.sh`, and `tests/config.json` even though all three differ from the seed. This is Secondary Requirement 5, metadata mismatch. | No new technique adopted. The verifier retains an earlier correct fail-closed fix: `tests/test.sh` accumulates failures from all configured commands and requires `raw_exit_code == 0` before it awards success. | Do not trim a cumulative Files Changed account to the files edited in the newest round. The prior review record had the complete list. The revised page dropped the older verifier, configuration, and oracle entries even though the current bundle still contains them. | Timed-static review only. The current panels and ZIP fast gate were read. One static-only extension compared the gate warnings with `tests/test.sh`; its raw-exit and runner-status claims were refuted by lines 125 through 128 and 522 through 526. No Docker, Harbor, Oracle, NOP, container, mutation, broad requirement map, or full PR comparison ran. |

| 20260722_140543__openwhispr_openwhispr__656, review UUID 11c70bc8-fedc-4e48-9c1b-0a28e0fc69ab | Two. `task.toml` omits `[environment] os`. The current issue-details text also says the instruction specifies `0.70` and lists 15 fail-to-pass plus 5 pass-to-pass tests, while the submitted instruction has no `0.70` and `config.json` declares 20 and 10. Both are Secondary Requirement 5 metadata mismatches. | No new technique adopted. The revised verifier has a clear exit-status gate in `tests/test.sh` lines 509 through 516, while retaining parsed test output. This is established practice, not a new learning. | The correction text needs the same revision discipline as the ZIP. The page still says network settings were removed even though the current `task.toml` restores them, and it retains the earlier 15/5 count. Derive all reviewer-facing claims from the current archive after every rewrite. | Timed-static review only. The current page, previous feedback, submitted ZIP fast gate, task metadata, instruction, problem-statement copy, oracle script, configuration, grader, and test-patch headers were read. A direct missing-`os` signal was resolved within the base period. No Docker, Harbor, Oracle, NOP, container, mutation, broad requirement map, or full source-PR comparison ran. |

**No row was the honest state until 2026-08-18.** The three oldest finished reviews returned Needs Revision at a
score of 2. This file was created before the first Accept rather than after it, because the harvest is
a close-out step and a close-out step that does not exist yet is the one nobody performs. The three
older reviews are also the evidence for the guard above: none of them recorded which battery rows
it ran in a table, so none could fill in column five today without re-running the bundle. The first
row is now in the table: the aws-lambda-web-adapter 183 review, accepted with one Minor, with its
NOT RUN rows recorded rather than smoothed over.

## When an Accept is later overturned

`docs/glossary.md` defines an adjudicator as the final reviewer who resolves disagreements between
submitter and reviewer, so a verdict here is not always the last word. The accepted-task learning is
recorded after the form document, while archive and later outcome maintenance remain deferred.

If an adjudicator or a later round overturns an Accept harvested here: mark the row **overturned**
with the date and what the overturn said, set `outcome` in `learning/review-calibration.tsv`, and if
a technique from bucket 1 was promoted into its own `learning/` note, that note gets a `LEDGER.md`
row rather than a quiet edit. The reasoning is the one Section 13 F6 gives about calibration:
a row left at its mid-flight value is worse than a missing one, because the next review reads it as
measured. An overturned Accept left reading as accepted is that failure with a longer fuse.

**No row has ever carried an outcome.** All three `outcome` cells in `review-calibration.tsv` read
`not supplied`, and nothing in this workspace gives a reviewer an inbound signal about their own
verdict, which is one of the open questions Section 13 records rather than answers.

## What this file must never become

A place where an Accept is read as validating the whole bundle. It validates what you measured and
nothing else, and the standing proof of that is the **battery and NOT RUN columns**, which every row
carries including a clean one. It is deliberately not the Minors column: a zero-Minor Accept is real,
and a guard that vanishes on the row the file calls the more interesting one is not a guard. `accepted-bundle-reference.md` learned that the hard way with a row shipping
`difficulty = "medium"` beside `pass_at_k_opus_4_8 = "4/4"`, which is 100% against a documented bar
of at most 4 of 8, and nobody flagged it. **Not being caught is not the same as being right**, and
that sentence applies to a bundle you accepted exactly as much as to one you submitted.
