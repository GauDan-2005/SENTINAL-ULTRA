# 20260801_211601__ggrossetie_asciidoctor-web-pdf__79

The platform data block and the submitter's own answers, pasted verbatim from the reviewer page
the user supplied on 2026-08-19. Note (`learning/reviewer-page-carries-the-whole-submission.md`):
the page Metadata block describes the SEED, not the submission, so any mismatch against the
submitted zip's task.toml is a stale page, not a defect.

## Platform block (verbatim from the page)

```
UID: dc190bc5-e210-4082-951f-1e9e6634deb9
Original Directory Name: 20260801_211601__ggrossetie_asciidoctor-web-pdf__79
Category: implementation
Difficulty: hard
Task Tags: pdf, pdf-lib, asciidoctor, outline, puppeteer, toc
Languages: CSS, JavaScript

Metadata:
schema_version = "1.3"
[metadata]
pass_at_k_opus_4_8 = "0/3"
pass_at_k_gpt_5_5 = "1/3"
author_name = "anonymous"
author_email = "anonymous@snorkel.ai"
category = "implementation"
subcategory = "feature"
coding_language = "javascript"
repo_name = "asciidoctor-web-pdf"
repo_license = ""
source_pr_url = "https://github.com/ggrossetie/asciidoctor-web-pdf/pull/79"
base_commit_sha = "fd41ce026f06d6013b4a1d69290ed73d29d5e575"
model_difficulty = "medium"
tags = ["pdf", "pdf-lib", "asciidoctor", "outline", "puppeteer", "toc"]
difficulty = "hard"
task_type = "implementation"
task_subtype = "feature"
source = "https://github.com/ggrossetie/asciidoctor-web-pdf/pull/79"
language = "javascript"
expert_time_estimate_min = 120.0
junior_time_estimate_min = 420.0
pr_created_at = "2019-10-25T07:20:13Z"
pr_merged_at = "2019-10-30T11:17:34Z"
[verifier]
timeout_sec = 300.0
network_mode = "no-network"
[agent]
timeout_sec = 1800.0
network_mode = "allowlist"
allowed_hosts = [ "api.portkey.ai", ]
[environment]
build_timeout_sec = 900.0
cpus = 4
memory_mb = 8192
storage_mb = 10240
gpus = 0
network_mode = "public"
```

Source PR: https://github.com/ggrossetie/asciidoctor-web-pdf/pull/79
Base commit: fd41ce026f06d6013b4a1d69290ed73d29d5e575 (matches `git rev-parse HEAD` in the
submitted bundle's environment/repo, checked 2026-08-19)

## Previous round reviewer feedback (verbatim, dated 8/12/26, 9:54 PM)

```
Please fix these four items in the re-upload. The instruction rewrite, 14 mocha f2p cases, golden
stdout Buffer write, clean repo porcelain, and asciidoctor-pdf 755 are fine and should stay.
1. solution/solve.sh still treats blind --3way as success and falls through to `git apply -R`.
That reverse path is not allowed. Use a forward-only apply that is idempotent: first run applies
cleanly, second run exits 0 and leaves the solved tree unchanged. Guidelines: oracle / solve.sh
idempotency (no reverse as the success path).
2. In the zip, solution/solve.sh and tests/test.sh are mode 644. Both need to be 755.
3. task.toml dropped network_mode / allowed_hosts entirely. That is not the FAQ shape. Put them
back:
- [verifier] network_mode = "no-network"
- [agent] network_mode = "allowlist" and allowed_hosts = ["api.portkey.ai"]
- [environment] network_mode = "public"
Guidelines: task.toml network_mode requirements.
4. Faithfulness: tests/tests.patch checks outline dict keys First, Last, Count, Next, and Prev
(nesting + sibling cases), but instruction.md only says nested parents / well-formed tree. Either
name those standard PDF outline linkage fields in instruction.md and the identical
problem_statement.md, or drop the key-presence asserts and keep the behavioral checks (entry
counts, titles, dests, depth, missing-dest warning, file path, stdout).
```

## Submitter answers (verbatim from the page)

Verdict radio: **Fixable**. [internal] Validity: Fixable.

Issue categories ticked: Instructions, Tests, Oracle Solution, Environment/Dockerfile (all four;
the "Select where the task had issues" group also lists: Every requirement in the instructions is
not properly tested / All test requirements are not properly specified in the instructions / The
instructions appear LLM generated / The instructions are overly-prescriptive / The task leaks
solution information / The oracle does not implement the solution following the instructions /
Less than 10 fail-to-pass tests in test suite).

Numbered issue details:

```
1. Less than 10 fail-to-pass tests
Intake only had four mocha cases.
Fixable? Yes — 14 f2p plus 13 p2p from templates_test.js, allow_extra_failures=false.

2. Every requirement not properly tested
Titles, nesting, siblings, empty docs, warnings, and stdout were missing. Later checks grepped raw
PDF bytes (easy to fake) and crashed if the agent never installed pdf-lib.
Fixable? Yes — same 14 titles, but they walk Catalog -> /Outlines with pdf-lib and check that
First/Last/Next/Prev actually resolve. test.sh installs pdf-lib with --no-save --no-package-lock
so the agent's package.json is left alone. Empty docs accept missing or empty /Outlines.

3. Instructions appear LLM generated / overly-prescriptive / leak solution info
Read like a generated checklist.
Fixable? Yes — rewrote as a normal ticket; linkage fields described as observable PDF behavior;
problem_statement.md in sync.

4. Oracle / solve path
Stdout corrupted PDF bytes; solve.sh used -R/--3way; package.json gained pdf-lib without a
lockfile, so npm ci was not deterministic.
Fixable? Yes — raw stdout write, forward-only idempotent solve.sh, golden now includes
package.json and package-lock.json. npm ci after apply works.

5. Environment / packaging
Lost +x on bin/asciidoctor-pdf, empty p2p failed static, verifier timeout was 300s (too tight for
14 Puppeteer PDFs), Node 20 rewrote the vintage lockfile so golden would not apply.
Fixable? Yes — hygiene, fail-closed p2p, timeout 1800s, Dockerfile restores
package.json/package-lock.json after npm install.
```

Files Changed (verbatim):

```
instruction.md + problem_statement.md   Human ticket; linkage fields explicit
tests/tests.patch + config.json         14 f2p via pdf-lib tree walk; 13 p2p; fail-closed
tests/test.sh                           Install pdf-lib without touching agent lockfile
solution/golden.patch                   Outline feature + pdf-lib + lockfile + stdout fix
solution/solve.sh                       Forward-only idempotent apply
environment/Dockerfile                  bash/tmux/asciinema; offline pdf-lib; restore lockfile at HEAD
task.toml                               hard/hard; timeout 1800; drop network fields
bin/asciidoctor-pdf
```

PR additions (verbatim): "Same PR #79 outline feature. Safe extras: stdout binary write, declare
pdf-lib with a real lockfile, and the verifier walks the outline tree instead of grepping PDF
bytes."

Difficulty answer (verbatim): "Chromium still will not emit PDF bookmarks on print, so you have to
rebuild an outline after the fact, keep Dest targets alive even with no visible TOC, honor
toclevels, wire a real First/Last/Count/Next/Prev tree, warn on bad anchors instead of dying, and
ship that post-processed PDF on both file and stdout."

Senior estimate: the page paste lists the four options without showing the selection.

Comments for Reviewer (verbatim): "Marked Fixable. Instruction is a normal ticket; suite is 14 f2p
+ 13 p2p with allow_extra_failures off. Verifier loads PDFs with pdf-lib and walks Catalog ->
/Outlines (not raw-byte greps); test.sh installs pdf-lib with --no-save --no-package-lock so
agents who used another library still get graded. Golden now ships package.json +
package-lock.json for pdf-lib; npm ci after apply works. solve.sh is forward-only idempotent.
Verifier timeout is 1800s. Local oracle 1.0 (27/27), NOP 0.0. Please re-run judge + difficulty on
Sentinal 10.zip."

## Eval panels (verbatim from the page)

- Automated feedback: "All checks have passed"
- Static Checks: pass (page shows only the header)
- Prescriptiveness: page shows only the header, no failure rendered
- Difficulty Check: "Difficulty: PASS HARD. Status: Some tests not passed by any agent run (not
  blocking; require_solvable disabled). Agent Performance: codex-gpt-5-5: 0.0% (0/4 runs)"
- Agentic Judge Quality Report: "Status: OK. Reason: n/a"
- Oracle Check: "Oracle: PASS 3/3 runs passed. NOP: PASS 0/1 runs passed (expected 0)"
- Quality Check: "datapoint meets quality bar (15/15 criteria pass)"

## Difficulty Checks block

- checks run: (rendered blank in the paste)
- checks remaining: (rendered blank in the paste)
- Last counted submission version: 96fbd5a0-e4be-4891-9a6c-4e95a6b70a86
- Last difficulty check result: hard

## Rebuttal panel / max-revisions dialog

- Rebuttal comments in the left-hand panel: none (user confirmed 2026-08-19)
- "Maximum revision reached" dialog: not showing (user confirmed 2026-08-19), so Reject is not
  available on this review
