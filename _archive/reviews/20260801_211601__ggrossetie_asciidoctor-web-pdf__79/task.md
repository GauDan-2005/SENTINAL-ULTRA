# Peer review - 20260801_211601__ggrossetie_asciidoctor-web-pdf__79

Section 13, `.claude/rules/14-reviewer-workflow.md`. Started 2026-08-19.

- Seed zip: 71a6e258-171a-4862-a154-84115dec29a2_submission.zip, sha256 `279bd961a3ef999a2db761959509694058aafbe916b23210b94e19f54c80c3dc`, 115 entries, all stamped 2026-08-01 (generator build stamp matching the folder name)
- Submitted zip: 7c2fb5e2-f2ba-4d17-a581-9a7dfcf1e1cd_submission_2026-08-18T18_38_15.660Z.zip, sha256 `809c5a4dbd2c7ca2907ad5384c0e4c1b4af1a886df5c78654d1ac89592940ab6`, 116 entries, mtimes spread 2026-08-05 (104), 2026-08-16 (4), 2026-08-18 (6), 2026-08-06 (1) - a rewritten bundle, not the seed
- 0 symlinks in the submitted zip; `tests/test.sh`, `solution/solve.sh` and `bin/asciidoctor-pdf` all 755 in the zip
- Source PR: ggrossetie/asciidoctor-web-pdf#79, base commit fd41ce026f06d6013b4a1d69290ed73d29d5e575 (== HEAD of environment/repo), JavaScript, mocha + puppeteer
- Round: 2 of this task's review cycle (previous reviewer feedback dated 8/12/26, four items); round 1 of this review
- User instruction 2026-08-19: do not check or test any item `docs/` marks optional for a reviewer. `docs/tasking-guide.md:349` exempts the Harbor run, oracle, NOP and docker build, so the R6 battery is NOT RUN on instruction, recorded per row

## Submitter answers

Pasted verbatim in `task_details.md`. Verdict Fixable, so this is the full R2 to R11 shape.
Rebuttal panel: no comments (user, 2026-08-19). Maximum-revisions dialog: not showing (user,
2026-08-19), so Reject is not available.

## learning/ notes applied

| Note | What it predicts here | Command that settles it | Result |
|---|---|---|---|
| reviewer-page-carries-the-whole-submission (L101) | Both zips plus all answers are in hand, so R3's diff and claims table can run | `diff -rq download/seed download/original -x '.git'` | diff run, R3 table built |
| self-inflicted-defects-dominate-late-rounds | The upload is named "Sentinal 10.zip", a late round; the bundle's own diff is the highest-yield read and previous-round fixes are the suspect population | the same diff, read against their Files Changed list | done, R3 |
| reviewer-path 12.3 second-round rule | The 8/12 note's four items are this round's checklist; do not re-file what they answered | unzip -Z modes, read solve.sh, task.toml, instruction.md vs tests.patch | Previous round findings table |
| solve-sh-idempotency + L5 | Their claim "forward-only idempotent" is checkable on paper; no `-R`/`--3way` as the success path | read solution/solve.sh | HOLDS, R3 |
| L73 (docs/reviewer-rubric.md:101) | Their issue 5 claims verifier timeout raised to 1800; page metadata (seed block) still shows 300 | grep timeout_sec work/task.toml work/tests/config.json | measured, R4 |
| unreachable-git-blobs | A repo with clean porcelain can still hold dangling blobs of the golden | git fsck --unreachable, cat-file a sample | R4 |
| source-pr-cross-check | Page the GitHub API; PR 79 is from 2019, check both directions at hunk level | curl api.github.com .../pulls/79/files | R5 |
| oracle-protocol-is-solve-then-verify (L69) + L102 + L105 | The solve-then-verify cycle is the probe, but its result words as agent collision, never as "their Oracle Check failed" (their panel says 3/3); user exempted container runs | NOT RUN on user instruction | NOT RUN |
| stock-bundle-defect-baseline | Node scaffold: expect defects 1, 2, 4, 5, 6 historically; row 7 (python3 behind `\|\| true`) and row 8 (mocha parser brace-slice) decided structurally first | greps in 12.5 table | R8 sweep |
| verifier-fail-open (L70) | Read the parser for a stderr fallback before calling the grader gated | read tests/test.sh success expression | R8 |
| agent-writable-test-infrastructure | Can the agent fake a pass by editing what the graded tests call (pdf-lib is installed by test.sh itself) | NOT RUN (container), paper read done | R8 |
| L106 | Previous round asked to name First/Last/Count/Next/Prev in the instruction; check the named fields did not break derivability or alignment | diff instruction.md vs tests.patch key asserts | R7 |
| instruction-promises-the-suite-keeps-passing | Golden alone vs repo's own suite | NOT RUN (container) | NOT RUN |
| airgapped-means-no-egress-not-no-sockets | Puppeteer/Chromium is local; no graded egress expected; network_mode values read against docs/harbor-framework.md | grep network_mode task.toml | R4 |
| reviewer-findings-need-a-baseline (L61) | Baselines measured against download/original trees, never work/ | per finding at R8 | applied |

## Submitter claims, verified

`diff -rq download/seed download/original -x '.git'`: 9 files differ (Dockerfile,
problem_statement.md, instruction.md, golden.patch, solve.sh, task.toml, config.json, test.sh,
tests.patch) plus one added file, tests/grade.py, which no numbered issue and no Files Changed
entry names.

| # | Their claim | Where it should land | Measured | Verdict |
|---|---|---|---|---|
| 1 | 14 f2p + 13 p2p from templates_test.js, allow_extra_failures=false | tests/config.json | 14 f2p, 13 p2p, flag false, execution timeout 1800 | HOLDS |
| 2 | tests walk Catalog -> /Outlines with pdf-lib, First/Last/Next/Prev resolve; empty docs accept missing or empty /Outlines | tests/tests.patch | pdf_test.js collectOutlineItems walks the dict tree; hasNoOutlineEntries accepts both empty shapes | HOLDS |
| 3 | test.sh installs pdf-lib with --no-save --no-package-lock | tests/test.sh | line 142, exact flags, behind `\|\| true` | HOLDS |
| 4 | instruction rewritten as a normal ticket; problem_statement.md in sync | instruction.md, environment/problem_statement.md | byte-identical per diff | HOLDS |
| 5 | raw stdout write | solution/golden.patch | converter.js: `process.stdout.write(Buffer.from(pdf))` | HOLDS |
| 6 | forward-only idempotent solve.sh | solution/solve.sh | reverse --check no-op exit 0, then plain forward git apply, no -R/--3way | HOLDS (paper; container replay NOT RUN) |
| 7 | golden ships package.json + package-lock.json; npm ci after apply works | solution/golden.patch | both files in the patch; npm ci itself not exercised | HOLDS for the files; npm ci NOT CHECKABLE HERE |
| 8 | fail-closed p2p, timeout 1800 | config.json, task.toml | 13 p2p + flag false; verifier 1800 == execution 1800 | HOLDS |
| 9 | Dockerfile restores package.json/package-lock.json after npm install | environment/Dockerfile | `RUN git checkout -- package-lock.json package.json` | HOLDS |
| 10 | bin/asciidoctor-pdf fixed | zip modes | 755 in the submitted zip; the seed zip shipped it 644 | HOLDS |
| 11 | Files Changed lists every changed file | the diff | tests/grade.py is in the diff and in no entry; "bin/asciidoctor-pdf" entry carries no what/why; golden's two outline.js deltas from the PR are undeclared | DOES NOT HOLD in part |
| 12 | Local oracle 1.0 (27/27), NOP 0.0 | container | user exempted container runs; their platform panel reads Oracle PASS 3/3, NOP PASS 0/1 on this zip | NOT CHECKABLE HERE |

## Previous round findings

The 8/12/26 note's four items, against this zip:

| # | Their finding | Status |
|---|---|---|
| 1 | solve.sh must be forward-only idempotent, no -R/--3way success path | fixed. solve.sh is a reverse-CHECK no-op plus a plain forward apply |
| 2 | solve.sh and test.sh must be 755 in the zip | fixed. Both 755 per `unzip -Z`; bin/asciidoctor-pdf is 755 too |
| 3 | restore network_mode in all three blocks plus allowed_hosts | STILL OPEN. task.toml carries zero network_mode lines and no allowed_hosts; Files Changed declares "drop network fields", so this is deliberate, and it is the second consecutive round the fields are missing |
| 4 | name First/Last/Count/Next/Prev in instruction.md and problem_statement.md | fixed. instruction.md line 9 names all five; problem_statement.md is byte-identical |

## mtime forensics

Not needed: both zips in hand. Recorded anyway: seed 115 entries all stamped 2026-08-01 (generator
build stamp, matches the folder name); submitted 116 entries spread 2026-08-05 (104), 2026-08-06
(1), 2026-08-16 (4), 2026-08-18 (6), so this is a rewritten bundle and the late edits are exactly
test.sh (8/18) and solve.sh (8/16).

## Git hygiene

| Check | Command | Output | Meets (:91) | NR trigger (:95) |
|---|---|---|---|---|
| fsck | git fsck --unreachable --no-progress | silent | yes | no |
| HEAD vs base | git rev-parse HEAD | fd41ce026f06d6013b4a1d69290ed73d29d5e575 == base_commit_sha | yes | no |
| remotes | git remote -v | none | yes | no |
| worktrees | git worktree list | only itself | yes | no |
| stash | stash list / refs/stash | none | yes | no |
| reflog | ls .git/logs | absent | yes | no |
| size | du -sh .git | 9.3 MB | yes | no |
| status | git status --porcelain | clean | yes | no |

Pillar 5 fully clean. First review here with nothing to read out of fsck.

## PR comparability, hunk level

PR #79 paged through the API: 9 files, one page, complete. Compared against golden.patch plus
tests.patch in both directions, changed-line sets.

| File | only in PR | only in bundle | Note |
|---|---|---|---|
| .gitignore | 0 | 0 | identical |
| lib/converter.js | 0 | +1/-1 | the declared stdout Buffer write extra |
| lib/document/templates.js | 0 | 0 | identical (incl. two whitespace-only deltas the PR itself carries) |
| lib/outline.js | 2 | 2 | undeclared: `dests ? ... : []` null guard, `save({ useObjectStreams: false })` vs PR's `save()` |
| package.json | 3 | 2 | same pdf-lib ^1.2.1 addition; the PR's hunk also reorders two neighbour lines |
| package-lock.json | 25 | ~1162 | full regen under node 20, declared in issue 4 |
| test/pdf_test.js | 12 | 164 | the declared coverage expansion, 67 to 298 lines |
| fixtures sections/.gitkeep | 0 | 0 | identical to the PR |
| empty-doc.adoc, umlaut-section.adoc | - | new | declared test expansion, not in the PR |

No golden file or hunk the PR never touched, apart from the declared extras. Score 1 off the table.

## Measurement battery

User instruction 2026-08-19: skip every item docs/ marks optional for a reviewer
(docs/tasking-guide.md:349 exempts Harbor, oracle, NOP, docker build). Two host-level probes ran
because they need no container and are not on that exempt list.

| # | Run | Command | Result | Exit |
|---|---|---|---|---|
| 1 | NOP | NOT RUN (user instruction). Platform panel on this zip: NOP PASS 0/1 | - | - |
| 2 | Oracle protocol, solve then verify x3 | NOT RUN (user instruction). Platform panel: Oracle PASS 3/3. L105: the one-container shape measures agent collision, and the missing restore is filed as finding 2 | - | - |
| 3 | Hostile delete | NOT RUN (user instruction) | - | - |
| 4 | Gaming probe | PARTIAL, host: extracted the embedded grade.py, poisoned stdout with a brace-bearing debug line ahead of a failing mocha JSON, forged an all-pass report on stderr naming the 27 required ids | reward 1.0, success True, 27 of 27, raw_exit_code 1 | grade exit 0 |
| 5 | sh /tests/test.sh | NOT RUN in an image. Paper: test.sh:9 `set -uo pipefail` precedes the trap at :25, so dash aborts before any reward file exists; modes are 755 so shebang exec works | - | - |
| 6 | Forced test edit, golden alone vs repo suite | NOT RUN (user instruction) | - | - |
| 7 | Move the created file | NOT RUN. Paper: graded tests require ../lib/converter.js and ../lib/document/templates.js, both pre-existing paths, and never import lib/outline.js directly; the cista shape does not apply structurally | - | - |
| 8 | Determinism, two fresh extracts | NOT RUN (user instruction). Paper: graded asserts are structural, no wall clock or random source | - | - |

Second host probe (agent collision, finding 2): copied the repo, wrote a one-line
`test/pdf_test.js` as an agent plausibly would, ran the exact apply trio from test.sh.
`git apply` exit 1 ("already exists in working directory"), `git apply --3way` exit 1,
`patch -p1 --forward` exit 0 with "Skipping patch" on the graded file, so test.sh reports APPLIED
and the graded file never lands. All 14 f2p then report missing.

## Requirement to test mapping

| # | Requirement, quoted | instruction.md line | Graded by | Mark |
|---|---|---|---|---|
| 1 | outline "whether or not a visible table of contents was requested... toc unset, disabled, or macro" | 5 | f2p 1, 2, 10 | covered |
| 2 | "Depth should follow the document's toclevels attribute (default 2)" with the 9/4/11 counts | 7 | f2p 3, 4, plus the count asserts in 1, 2, 10 | covered |
| 3 | "section's id as its destination and the section's title as its label" | 9 | f2p 5, 8, 11 | covered |
| 4 | "nested under their parents so the bookmark tree is well-formed... First, Last, Count... Next and Prev" | 9 | f2p 6, 7 plus the collectOutlineItems helper asserts on every walk | covered |
| 5 | "destination cannot be resolved... emit a warning and keep going" | 9 | f2p 12 | covered |
| 6 | "Documents with no sections in range can be left without an outline" | 9 | f2p 9 | covered |
| 7 | "written to a file or sent to stdout... must be the post-processed document" | 11 | f2p 13, 14 | covered |
| 8 | "the HTML the converter feeds to Chromium needs those links available even when a visible TOC is not" | 11 | indirect: f2p 1, 2 require the outline to exist without a TOC, which requires the Dests | weakly covered |

Every helper assert (Parent resolves, /Title present, root /Count) sits inside the PDF spec's
outline dictionary definition, which "well-formed tree" plus the five named fields states. No
overreach row.

## Stock defect sweep

| Defect | Present | Evidence or the structural reason |
|---|---|---|
| 1 fail-open grader | Present | test.sh:514 `success = not missing_required and not unexpected` never reads raw_exit_code; preflight 40-grader FAILs the same line; forged-stderr probe returned reward 1.0 |
| 2 no regression guard | Absent | 13 p2p and allow_extra_failures false |
| 3 stale build-time reports | Absent | Dockerfile never runs the suite at build; the grader parses fresh stdout, not a report directory |
| 4 non-idempotent solve.sh | Absent | rewritten forward-only with a reverse-check no-op; previous round's item 1 |
| 5 predictably named graded files | Present | tests.patch creates test/pdf_test.js, the conventional path for this feature and the PR's own path; collision probe measured |
| 6 no test-tree restore | Present | test.sh:66-85 applies tests.patch with no restore of anything first |
| 7 verifier dependency behind `\|\| true` | Absent | python3 arrives via asciinema on the non-optional apt line; node:20-bookworm also ships it. Not measured in-image per instruction |
| 8 report shares stdout, brace-sliced | Present | parser framework is mocha so _find_json is reached; the same probe shape with no forged stderr scores 0 of 27 for a correct solution that logs an object |

## Rubric tally

| # | Finding | Severity | Pillar or requirement | Provenance | Blocks alone? |
|---|---|---|---|---|---|
| 1 | Fail-open grader with a stderr fallback: a forged all-pass report on stderr plus one brace-bearing stdout line scores reward 1.0 at raw_exit_code 1; the same parse hole scores 0 for a correct solution that logs an object | Major | Pillar 3, reward-hackable | measured, host probe on the bundle's own grader and config | yes |
| 2 | No test-tree restore and the graded file lands at the conventional path: an agent that writes test/pdf_test.js gets every apply route skipping it and scores 0 with the feature complete | Major | Pillar 1/2 territory, agent collision per L105; Test Build Issues | measured, host run of the exact apply trio | yes |
| 3 | task.toml strips all three network_mode values and allowed_hosts, one round after the reviewer asked for them restored; docs/harbor-framework.md says "don't strip these fields" | Minor | Environment; Pillar 4 soft signal at most, no open-network harm measurable, platform panels passed | read; the other 15 arriving bundles all carry 3 lines, this one carries 0 | no |
| 4 | Writeup does not match the diff: tests/grade.py added and named nowhere, the two outline.js deltas from the PR undeclared, a bare bin/asciidoctor-pdf entry | Minor | Secondary 5, metadata mismatch | read, R3 table | no |
| 5 | sh /tests/test.sh aborts at line 9 before the trap, so a dash invocation writes no reward file at all; 755 modes make shebang exec viable, which is why this is not graded higher | Minor | Test Build Issues | read, test.sh:9 vs :25 | no |
| 6 | pdf-lib is resolved live at build time and again at verify time with --no-package-lock, beside a golden lockfile that pins it; base image is an unpinned tag | Minor | Secondary 2, pinning; the unpinned tag is the arriving default (16 of 16) | read, Dockerfile and test.sh:142 | no |

Verdict: two confirmed Majors, Needs Revision. Bucket: Fixable, every fix is mechanical and in
scope. Score 2: PR fidelity is clean at hunk level both directions, so 1 is off the table.

## Findings withdrawn

| Finding | Why it was dropped | Which 12.7 check caught it |
|---|---|---|
| verifier timeout vs execution timeout mismatch | 1800 == 1800 in this bundle; the submitter's issue 5 fix landed | check 1, the numbers |
| model_difficulty edited medium to hard | both declared tiers now agree and the platform's last difficulty result is hard; hulak 118 precedent | check 4, baseline and panel |
| over-prescription on instruction line 7 spelling out the 9/4/11 counts | the counts are the behavioural contract docs/guidelines.md:101 asks stated; the five PDF fields are the public outline spec, exempted by :99 | check 5, remedy would break alignment (L106 shape) |
| `npm install --no-save pdf-lib \|\| true` at verify time as a blocking item | it is a deliberate faithfulness feature for agents who solved with another PDF library, and the image pre-installs pdf-lib; only the pinning half survives, as finding 6 | check 5, remedy would make the bundle worse |

## Open caveats

| Caveat | Stated in round | What would retire it | Retired? |
|---|---|---|---|
| Their "local oracle 1.0 (27/27), NOP 0.0" and "npm ci after apply works" are unverified here because container runs were exempted by the user; the platform Oracle 3/3 and NOP PASS panels on this zip are consistent with both | 1 | a container battery on a later review, or trusting the panels | no |
| The golden touches lib/document/templates.js, which the 13 p2p templates tests exercise; whether golden keeps the whole repo suite green was not run (battery row 6) | 1 | row 6 on a later review | no |
| python3's presence in the image is argued from the apt line and the base image, not measured in-image | 1 | `docker run <image> which python3` | no |

## Superseded answers

TODO

## Audit pass

The five 12.10 checks over the finished answer, after humanizer and the Section 5 greps (both
clean, plus the scoring-ladder grep on the paste and the three-sentence boilerplate grep against
every other review's answer file, all clean):

1. Baseline claims: three in the paste. Two were WRONG and fixed: "16 of 16 carry all three
   network lines" became "the other fifteen arriving bundles all carry the three lines" (this
   bundle is itself the 16th and carries 0), and "the generator leaves them out of every bundle"
   gained the real counts (os absent 16 of 16, difficulty_explanation 15 of 16, mithril's
   original carries one). The unpinned-tag sentence was already correct at 16 of 16.
2. Remedies read against each other: the grader remedy (report to a file or markers, drop the
   stderr fallback, gate the raw exit), the restore remedy (embedded archive payload, prefixed
   file name), the re-exec guard and the pinning fix are pairwise compatible. No contradiction.
3. Every number re-derived from the live bundle: 14/13/27 from config.json, reward 1.0 and raw
   exit 1 from the probe's report.json, test.sh line numbers 9/25/66-85/142/514 re-read, the
   67-to-298 pdf_test.js growth from wc, the panel figures from the page paste.
4. Mechanism removal: finding 1's mechanism is the probe itself (poison stdout, forge stderr,
   reward 1.0); finding 2's is the measured apply trio. Nothing asserted on reasoning alone.
5. Run-list walk: the untried invocations are the whole container battery, skipped on the user's
   instruction and disclosed in the closing note, plus the sh invocation which is argued on
   paper from test.sh:9 sitting before the trap at :25 and disclosed as such.

## Closing

2026-08-19. Verdict **Needs Revision**, score **2**, bucket **Fixable**. Two Majors, both measured
on the host with the bundle's own files: the fail-open grader (reward 1.0 at raw_exit 1 via a
forged stderr report) and the missing test-tree restore landing the graded file at the
conventional path (patch(1) skips it with exit 0, compliant agent scores 0). Four Minors: the
stripped network_mode/allowed_hosts (second consecutive round, declared in Files Changed), the
writeup/diff mismatches, the dash hazard, the pdf-lib pinning. Q4 answered "No rebuttal comments
available" (user confirmed the panel is empty). Q6 left blank on the user's instruction; no review
minutes recorded, and the calibration row says so rather than guessing.

Closed under Section 13 R11 on 2026-08-19, ahead of the platform submission per the user's
instruction to run the remaining steps (the aws-lambda-web-adapter 183 precedent). Outcome is
`not supplied` in the calibration row until the user confirms the submission landed.

Harvest (R11 items 3 and 4):

- **What this review proved that no note yet said.** Two things, both written into `learning/`.
  (1) `patch -p1 --forward` exits 0 while skipping a colliding create, so the third apply route
  converts a loud collision into a silent partial apply and a merit-looking zero; new note
  `learning/patch-forward-skips-colliding-creates.md`, a row in `learning/README.md`, and one
  sentence at `.claude/rules/11-verifier-hardening.md` Section 10.3. (2) `allow_extra_failures:
  false` does not close the forged-stderr route (the forge contains no failures, so `unexpected`
  is empty by construction), measured on a mocha parser at reward 1.0 with the flag false;
  appended to `learning/verifier-fail-open.md` beside L108's file-level route.
- **What it disproved that a note still says.** Nothing. Every learning applied held, and the two
  structural-absence predictions (rows 3 and 7 of the stock sweep) held on this bundle.
- **No accepted-bundle harvest.** The verdict is Needs Revision, so
  `learning/bundles-i-accepted-as-reviewer.md` gets no row (its own guard: harvest is worth more
  than a received acceptance only while the battery table is filled in, and here the battery was
  exempted by the user besides).
- Calibration row written to `learning/review-calibration.tsv` (25 fields, `?`/not supplied where
  nothing was recorded).
- Archived to `_archive/reviews/20260801_211601__ggrossetie_asciidoctor-web-pdf__79/` with
  `git mv`. Both zips are under the 100 MB limit (17 MB submitted, 19 MB seed) and stay tracked.

## Superseded answers

None. Round 1 of this review, one answer file, never rewritten.

