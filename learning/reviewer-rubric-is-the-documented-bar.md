---
id: reviewer-rubric-is-the-documented-bar
status: platform-confirmed
last_verified: 2026-08-14
verified_by:
  - 20260723_030152__mithriljs_mithril.js__2021
  - 20260720_144200__thomas4019_expressa__132
evidence: "docs/reviewer-rubric.md, a new Hub tab announced 2026-08-12 and dated 'Last updated: August 7, 2026', arrived in the 2026-08-13 re-export. It is the platform's own published policy rather than a local run, and it reverses LEDGER L58"
applies_to:
  languages: [any]
  runners: [any]
  phases: [peer-review, analysis, fixing]
blocks_submission: false
fails_gate: [none]
supersedes:
  - "LEDGER L58, whose measurement stands and whose conclusion does not. Superseded as L73"
contradicts:
  - ".claude/rules/13-reviewer-path.md Section 12.8 as it stood before 2026-08-14, whose four severity levels (blocking, major, minor, observation) were invented here and did not map onto the rubric's two. 12.8 now anchors severity on the rubric and retires blocking into Major, so this note records what was changed rather than a live disagreement"
---
> **Process scope, 2026-08-19.** This note preserves measurements from the legacy deep-battery reviewer workflow. New reviews use the timed platform-first static path in Section 13. Docker, Harbor, Oracle, NOP, container, mutation, and full-audit work are no longer routine review steps. Consult a measured legacy case only after a recorded timed-review trigger or in a separately requested diagnostic.


# The platform documented a verdict threshold, and it overturned one of our own conclusions

`docs/reviewer-rubric.md` is new in the 2026-08-13 export. It is 159 lines, it says
`Last updated: August 7, 2026`, and it is the first time the platform has written down **how many
findings of what kind make a verdict**. Everything this workspace had before it was invented here.

## The threshold, stated

`docs/reviewer-rubric.md:15` puts two independent paths to Needs Revision, and both must be clear to
accept:

- **One confirmed Major Pillar violation** is enough on its own (`:17`). Five Major Pillars exist and
  they are listed below
- **Five or more Minor violations**, across any combination of the eleven Secondary Requirements at
  `:101-111`, is Needs Revision on systemic low quality (`:19`)
- **One to four Minor violations is Accept**, with mandatory coaching comments (`:19`, repeated at
  `:158`)

Section 12.8 of `.claude/rules/13-reviewer-path.md` had four severity levels of its own, blocking,
major, minor and observation, and no rule at all for turning a count of them into a verdict. Those
four do not map cleanly onto the rubric's two. Our blocking and major both collapse into rubric
Major. Our minor and observation do not both become rubric Minor, because a rubric Minor is one of
**eleven named requirements** and it counts toward five, while an observation counts toward nothing.
Filing an observation as a Minor is now a real arithmetic error, not a style preference. Section 12.8
was rewritten on 2026-08-14 to say exactly that: severity is anchored on the rubric, blocking retires
into Major and survives only as an ordering rule, and observation is kept as this workspace's own
extra word with the explicit note that it counts toward nothing.

**The consequence for our own review shape is immediate.** The stock-defect sweep in Section 12.5
finds **five** of the eight scaffold defects on mithril.js 2021 and expressa 132, and **six** on
cista 172 (`learning/stock-bundle-defect-baseline.md`). If those are read as Minor, an arriving
bundle is at or past the five-Minor line before the reviewer has read a sentence of the instruction.
So the severity call on the stock five is now load-bearing, and most of them are not Minor: a grader
that never gates on `raw_exit_code`, and a `tests.patch` with no restore that scores the oracle
**1 of 3** (`learning/oracle-protocol-is-solve-then-verify.md`), sit under Pillar 2 and Pillar 1 and
are Major on their own.

`:21-31` also splits Invalid into **Unfixable-Structure** and **Unfixable-Difficulty** and requires
them tagged separately, because "lumping them as 'invalid' is what sends ECs into 3+ unpaid revision
loops on tasks that were never fixable" (`:31`).

## It is not only a reviewer document

`docs/reviewer-rubric.md:9` says the tab "defines the technical bar every Sentinel Ultra task must
clear to be accepted, and the bar a reviewer's assessment of that task must itself meet". So the five
Major Pillars and the eleven Secondary Requirements are a **submitter pre-submit checklist**, and the
things on it are the things a reviewer will actually be counting. Read it on the submitter path too.

## The reversal, and the general lesson under it

`docs/reviewer-rubric.md:101`, Secondary Requirement 1, at an 18% reviewer-flag rate:

> Verifier timeout set shorter than the task's own configured timeout (e.g. 1800s config, 300s
> verifier), which can kill valid solutions early. Mechanical; name the two numbers.

`LEDGER.md` L58 recorded that exact finding as **disproved**, and
`.claude/rules/09-task-toml-reference.md` carried a baseline row reading `not a finding (LEDGER L58)`.
It is now L73, superseded.

**The measurement behind L58 was never wrong.** Re-measured 2026-08-14 at n=8 arriving bundles,
7 of 8 carry `[verifier] 300.0` against `execution 1800`, cista 172 being the one that arrives
matched. It is the generator's default and not something a submitter did.

What was wrong was the step after the measurement: inferring from "it is the generator's default"
that "it is therefore not a finding". Those are two different questions and the baseline only answers
the first.

**Rule. A measured baseline tells you where a value came from. It never tells you whether the value
is acceptable. Provenance is not permission.** The baseline still decides how you word the finding,
which is the L61 discipline: say it is the arriving default the submitter did not correct, never that
they broke it. It does not decide whether you file it. `docs/` decides that, and `docs/` wins.

This is the first time documented policy has reversed one of this workspace's own measured
conclusions, and it will not be the last. When it happens again, keep the measurement, move it to
whichever question it actually answers, and change only the conclusion.

## The flag frequencies say where reviewers spend findings, and it is not where we have

Each Major Pillar carries the share of reviewer comments that flag it (`:39, :51, :63, :75, :87`).
Set against the 48 notes in `learning/`, measured 2026-08-14 as every `.md` there except `README.md`
and `LEDGER.md`, this note included:

| Pillar | Flagged in | Notes here | Reading |
|---|---|---|---|
| 1. Oracle / golden correctness | 51% | 5 | proportionate |
| 2. `fail_to_pass` / `pass_to_pass` integrity | 45% | 10 | our strongest area, correctly |
| 4. Airgapped verifier and network integrity | 41% | **2** | **under-invested** |
| 5. Git state and repo cleanliness | 31% | 4 | proportionate, and it is an early gate (`:95`) |
| 3. No leakage / not reward-hackable | 21% | 2 | proportionate |

The two network notes are `airgapped-means-no-egress-not-no-sockets.md` and
`cmake-reconfigure-needs-network.md`. Both were written after being bitten, one of them by an
agentic-judge **REMOVE** on ziti-sdk-c 668. Against 41% of reviewer comments, two notes is thin, and
the pillar covers two separate things we treat casually: graded behaviour that needs a host the
verifier will not have, and a shipped `network_mode` set wrong.

cista 172 arriving with `[environment] network_mode = "no-network"`, where `docker build
--network=none` dies on the first `apt-get` layer with exit 100, is the second of those, and it is
worth being precise about which line of the pillar it fails. It fails the `Meets` line at `:79`,
"`network_mode` / allowed-hosts set correctly". It is **not** the Needs Revision trigger at `:83`,
which reads "graded behavior requires internet the verifier won't have, or the shipped environment
leaves network open where it should be restricted" - both of those are the other direction, network
wanted and absent or left open and unrestricted, where cista is closed and needed open at build time.
So do not file it as a Pillar 4 Major. It sends the task back on its own separate ground, which is
that the image does not build and therefore nothing about the task can be verified at all, and the
rule it breaks is `docs/harbor-framework.md:59` prescribing `"public"` directly. That is how
`.claude/rules/09-task-toml-reference.md` already words it, and it was found by reading that table
rather than by any note here.

The other side of the ledger. Difficulty is **Secondary Requirement 11**, Minor, and only Minor when
it is "actually recoverable in-scope" (`:111`). Seven of the 48 notes are about difficulty
(`difficulty-is-divergence-not-volume`, `difficulty-levers-must-discriminate`,
`difficulty-screen-unit-table`, `raising-difficulty-on-a-wrapper-task`,
`when-fail-easy-is-not-not-fixable`, `probe-the-instruction-you-already-wrote`,
`related-pr-carries-its-own-bug`), and two more exist only because of a difficulty argument
(`stated-caveats-decay`, `not-fixable-is-a-written-argument`). Nine notes on one Minor requirement.

That is not pure waste, because the difficulty screen really did block real rounds here. It does say
that as a **reviewer** our attention is calibrated to what blocked our own submissions rather than to
what reviewers flag, and the fix is cheap: run the network checks before the difficulty read.

## Reviewer Integrity, where our default output scores three of six

`docs/reviewer-rubric.md:113-123` makes an LLM-generated review a **Major** defect, against the
reviewer rather than the task. `:121` lists six soft signals and says **any four in one review is
Major**. Measured 2026-08-14 across the three finished reviews in `review_tasks/`, which are three
unrelated bundles, and so scored against what Section 12.8 and the Path D template produced **before
2026-08-14**, which is what the fixes below changed:

| Soft signal | Exposed? | What retires it |
|---|---|---|
| uniform em-dash usage | **no** | already retired for free. `.claude/rules/06-writing-rules.md` bans em and en dashes outright and enforces it with a bare count that must return 0. Measured zero em dashes and zero en dashes in all three files |
| exhaustive parallel bullet lists | **yes, until 2026-08-14** | of the 39 notes across the three reviews, 33 carried a labelled `What to do.` line and 20 a labelled `Guidelines reference.` line, in the same order every time, which is parallel structure by construction. The template mandated that block and no longer does. Vary the shape: a finding with no supporting section gets no empty label, and a one-line finding stays one line |
| mirrored instruction language | **yes** | all three open Q3 with the same ten words, "Start with what is right, because none of it should", and all three carry "I built the image and ran the bundle, which a reviewer is not required to do" verbatim. Write the defect in the bundle's own vocabulary, its file names, test ids and config keys, not in the rubric's. Section 5 already bans internal check vocabulary, which covers the judge-axis half and not this |
| academic filler | no | a scan of the three files for the usual filler openers returns nothing. Section 5 bans padding and the `humanizer` pass is mandatory |
| zero natural typos | **yes, permanently** | `aspell` over all three returns identifiers and technical terms only. It cannot be retired and it must not be gamed. Treat it as one of the four that is always counted, which is exactly why the others have to be absent |
| rubric-aware framing | **not yet, and newly available since 2026-08-12** | all three reviews were written 2026-08-11 and the tab was announced 2026-08-12, so there was nothing for them to mirror, and the four scoring words appear three times between them, every one as ordinary English. The 2026-08-12 tab is what supplies that vocabulary. Name the defect and its consequence, never its rubric row. Write "the grader writes reward 1.0 while the test command exited 1", not "this is a Pillar 2 violation" |

**Three of six as measured, which is one short of Major, and the count is the same one
`.claude/rules/06-writing-rules.md` carries.** Read the margin rather than the number. The typo row
can never be retired, so every review starts with one of its four already spent. The sixth signal was
unavailable to the measured set and has been available since 2026-08-12. And two of the three exposed came
straight out of our own template, which means the workspace was generating them rather than the
reviewer choosing them. **Retiring the parallel block shape takes it to two**, and it is the cheapest
of the three because nothing in the evidence discipline depends on it, which is why it is the one the
2026-08-14 template change removed.

The trap in the other direction is real and `:119` names it. The `Meets` line rewards comments that
are "specific and idiosyncratic" and "cite exact files, tests, config keys, or eval results from this
task". A review that drops its citations to sound more human fails `Meets` while it is busy dodging
the soft signals. Every finding keeps its file, its line and its measurement. Only the uniform
packaging goes.
