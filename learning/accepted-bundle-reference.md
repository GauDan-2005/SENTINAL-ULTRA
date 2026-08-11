---
id: accepted-bundle-reference
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260809_080653__sysprog21_elfuse__162
  - 20260719_045042__oliver-oloughlin_kvdex__245
  - 20260805_080500__statrs-dev_statrs__315
evidence: "The bundle as accepted on round 6, measured out of _archive/"
applies_to:
  languages: [typescript, any]
  runners: [deno]
  phases: [all]
blocks_submission: false
fails_gate: [none]
supersedes: []
contradicts: []
---

# What an accepted bundle actually looked like

Source: `20260719_045042__oliver-oloughlin_kvdex__245`, accepted 2026-08-04 after six rounds.

**There are now four accepted bundles**, plus one accepted Path C submission with no bundle at
all (libcrux 1165, written up in `not-fixable-is-a-written-argument.md`).
`20260809_080653__sysprog21_elfuse__162` was accepted 2026-08-11, C, graded through pytest,
`implementation / feature`, difficulty hard. **Read its row in `calibration.tsv` with the caveat
attached**: the submitter reported only the word accepted, so its round count and every check
panel result are unknown and its numbers are all local measurements. It is the reference for one
thing none of the others show, a graded suite that **cross-compiles part of a macOS-only program
for aarch64 and runs it under qemu-user on the Linux verifier**, in place of the source-text
assertions the bundle arrived with (`platform-locked-repos-are-still-testable.md`). It is also
the only one here whose instruction names **zero** internal paths, internal symbols and host API
calls, which was a consequence of the tests dropping those names rather than of editing the
instruction harder.
`20260807_080545__tair-opensource_redisshake__1005` was accepted 2026-08-11 on round 4, Go with
`go test`, `implementation / feature`, difficulty hard, 5 uploads, 225 minutes plus 315 of
revisions. It is the reference for three things the other two do not show: an oracle carrying
**three** case-1 corrections adapted from three different later PRs, a graded suite that stands a
**fake server on a loopback socket inside the verifier**, and a bundle accepted after the
difficulty screen had blocked it **four consecutive times** (see
`when-fail-easy-is-not-not-fixable.md`). `20260805_080500__statrs-dev_statrs__315` was accepted
2026-08-11 after five uploads across rounds 0 to 4. Its measurements are in
[calibration.tsv](calibration.tsv) and its full record in
`_archive/20260805_080500__statrs-dev_statrs__315/task.md`. Where the two agree, the number is
worth something; where they differ, there is no normal. All four agree on: an instruction whose
longest prose paragraph sits under 800 characters (kvdex 717, statrs 769, redisshake 680, elfuse 379), a
populated `pass_to_pass` guard, script modes at 0755, a silent `git fsck`, a git-independent
test-tree restore, an exit-code gate in the grader, and an oracle whose runtime has large headroom
against the verifier timeout. All four also ship an instruction that names **no internal file
path and no library to use**, and elfuse is the extreme case of it. Where all four agree the number is worth more than where two do. They differ on nearly everything else, including the
`tests.patch` shape, the graded totals and the number of rounds. statrs is also the first accepted
bundle here whose `golden.patch` was **edited** rather than shipped as received, under
`docs/guidelines.md:286` case 1 and then again to expand scope, so it is the reference for what an
accepted oracle edit looks like. redisshake 1005 is the second and the wider one, at three
corrections in one patch, all three still unfixed upstream, each declared in its own issue block.
**Two of the four accepted bundles carry an edited oracle**, so a case-1 correction is now the
normal shape here rather than the exception, and `oracle-bug-vs-pr-scope.md` carries what makes
one survivable.
Deno/TypeScript, `evolution_and_maintenance / migration`, difficulty hard, verdict Fixable
throughout, PR scope never touched.

The first task in this workspace to clear every gate. `CLAUDE.md` says what the rules are;
this note is the one worked example of a bundle that satisfied all of them at once, with the
measured numbers, so the next task has something to calibrate against instead of a checklist.

**Read the last section first if you are short on time.** The point of this note is the
distinction between the hardening that acceptance actually validated and the hardening that
merely did not get caught.

## The measured shape

| Dimension | Value |
|---|---|
| `fail_to_pass` | 20 (the hard ceiling; 22 was rejected at the static phase in round 1) |
| `pass_to_pass` | 112 |
| graded ids total | 132 |
| suite at oracle | 152 pass, 0 fail, 2 ignored |
| `allow_extra_failures` | `false` |
| files in `tests.patch` | 45 |
| pre-existing test files modified | 44 (42 `*.test.ts` plus `tests/utils.ts` and `tests/values.ts`) |
| graded ids outside the patched files | 102 of 132 (this is what forced the full-tree restore) |
| files changed vs the pristine extract | 7 |
| zip | 309 entries, 1.8 MB, `zip -rX` (that repo has no symlinks, so `-y` was moot; the canonical command is now `zip -rXy`) |
| `.git` | 1.6 MB, exactly `config description HEAD hooks index info objects packed-refs refs` |
| `test.sh` | 93 KB, mode 755, carries a 70 KB base64 payload |
| `solve.sh` | mode 755, forward-only and idempotent |

`task.toml` at close: `[verifier] timeout_sec = 900` (raised from 300, oracle uses 138),
`[agent] timeout_sec = 7200` (raised from 1800 after 3 of 8 trials timed out),
`[environment] os = "linux"`, `cpus = 4`, `memory_mb = 8192`, `storage_mb = 10240`,
`gpus = 0`, `network_mode` present in all three blocks, `difficulty_explanation` added.

## The verification matrix that preceded acceptance

Five runs, airgapped, in the task's own image at the declared `cpus=4 / 8 GB`.

| Scenario | Reward | Required | Notes |
|---|---|---|---|
| NOP | 0 | 0 of 132 | `raw_exit_code 1`, `infrastructure_error: None`, 0 unexpected |
| Oracle, clean tree | 1 | 132 of 132 | 152 pass, 0 fail, 2 ignored, 138 s of 900 s |
| Agent edited tests, `.git` removed | 1 | 132 of 132 | the case that reproduced the platform failure |
| Agent committed + wrote its own `tests/ext/encoder.test.ts`, `.git` removed | 1 | 132 of 132 | collision case |
| Hostile delete, brotli default 1 → 6 | **0** | 131 of 132 | `ext - brotliCompressor` fails |

Two properties of this matrix are worth copying rather than the numbers themselves. The
agent-hostile rows **outnumber** the clean rows, and the NOP row is checked for the right
reason rather than for a reward of 0 (no f2p passing at base, no collection abort, and a
nonzero `raw_exit_code`).

## The answer set that went with it

10 numbered issue blocks, 8 Files Changed entries, both Phase 1 checkbox lists rendered with
`[x]`/`[ ]` (4 options and 7 options), 8 of 8 post-fix confirmations, all free text humanized
and unwrapped. Handling times 90 review / 150 rewrite / 20 form, total 260, revisions 195.

Both time figures sit **above** this workspace's target bands (180–240 and 60–120). That was
the submitter's call, the reason is stated in Comments for Reviewer, and it did not cost the
acceptance. Worth knowing the bands are guidance rather than a gate.

## What acceptance actually validated

Only these. Everything here was exercised by a gate that had previously failed, so acceptance
is real evidence:

- **The git-independent test-tree restore.** Three git-based designs failed the difficulty
  check across three rounds; this one passed first time. See
  `tests-patch-vs-agent-edits.md`.
- **The payload living inside `test.sh`.** The static checker rejected `tests/files/` on the
  previous upload and passed this.
- **`fail_to_pass` at exactly 20.** Rejected at 22 in round 1, passed at 20.
- **Narrowing the instruction rather than touching the oracle** to clear a `test_coverage` 3.0
  DISCUSS. The judge's three complaints all traced to PR 245 itself, so the spec was
  over-promising. `test_faithfulness` stayed at 5.0 and PR scope was untouched. See
  `source-pr-cross-check.md`.
- **`allow_extra_failures: false`** with 20 ungraded top-level tests in the suite, measured
  safe first.
- **`[agent] timeout_sec = 7200`**, after 3 of 8 opus trials hit the old 1800 ceiling.

## What acceptance did NOT validate

This is the honest half, and the more useful one. These shipped, they are defensible, and
**nothing in the result confirms any of them was necessary or sufficient.** Do not cite this
task as proof of them:

- **The fail-closed grader** (`success = ... and args.raw_exit_code == 0`, runner under
  `bash -o pipefail`). It was never the reason a round bounced. It is right on the documented
  invariant in `docs/guidelines.md`, and a reviewer would have found the fail-open version,
  but acceptance is not evidence it mattered here.
- **The idempotent `solve.sh`.** Flagged advisory at `oracle_robustness` 4/5 by both judges,
  never blocking.
- **Script modes 755.** Fixed late; the bundle had passed oracle runs at 644 in earlier rounds,
  so the practical impact on this task is unclear.
- **The 102-of-132 measurement.** It correctly ruled out the create-only patch *for this task*.
  It has not been tested the other way round, i.e. nobody has shipped a create-only patch on a
  task measuring zero and had it accepted.
- **Leaving `.vscode/settings.json` in place.** One judge scored packaging 1/5 for it and the
  other scored 5/5. Adjudicated 3.0, advisory, so the disagreement was never resolved. The
  reasoning for leaving it (tracked upstream at base, removing it means editing tracked repo
  files) still stands, but it is unadjudicated.

  > **Settled against, 2026-08-06 (LEDGER L25).** firefly 1123 round 0 put the same question to
  > two judges and **both** scored packaging **1.0**, citing `.vscode` reaching `/app`. The kvdex
  > split was one sampling, not a standing ambiguity. The reasoning about tracked files still
  > holds and the conclusion drawn from it does not: exclude the directory from the image rather
  > than leaving it, which needs no tracked-source edit. See `dockerignore-context-root.md`.
- **`model_difficulty = "medium"` against `difficulty = "hard"`.** Left alone per the FAQ rule,
  declared to the reviewer, and never queried.

**Rule: an acceptance validates the things that had previously failed and were then changed.
Everything else in the bundle merely was not caught. Keep the two lists separate when citing
this task, or advisory choices start getting quoted as proven practice.**

## The one thing that would have saved three rounds

Not a hardening measure. Reading the round-over-round trend. 13 of 16 invalid, then 16 of 16,
then 15 of 16 is a flat line across two different locally-verified fixes, and a flat line
means the fixes are not landing on the cause. That signal was free and available from round 4.
See `diagnosing-platform-only-failures.md`.


## Instruction shape, measured (added 2026-08-05, from AltBeacon 1177 round 5)

A judge scored AltBeacon's `instruction.md` down on clarity twice. The first fix added section
headings and the score did not move, which is the tell that the headings were never the problem.
Measuring the four bundles here answered it in one command:

| Bundle | Lines | Longest prose paragraph |
|---|---|---|
| kvdex 245 (**accepted**) | 47 | **717** chars |
| libcrux 1165 | 45 | 791 |
| equalsverifier 1166 | 36 | 447 |
| xlwings 2719 | 35 | 312 |
| firefly 1123 | 55 | 663 |
| hulak 118 | 49 | 603 |
| statrs 315 | 59 | 769 |
| openwhispr 1002 | 21 | 602 |
| redisshake 1005 | 15 | 680 |
| ziti-sdk-c 668 | 46 | 777 |
| elfuse 162 (**accepted**) | 21 | **379** chars |
| AltBeacon 1177, as bounced | 13 | **2724** (second longest 2466) |
| AltBeacon 1177, after the round 5 rewrite | 67 | 826 |

So the bundles that are not being bounced on clarity all sit at or under about 830 characters in
their longest paragraph, and the one being bounced was more than three times that. The rewrite that
moved it was a 14-row field table plus two bullet lists, not more headings.

`instr_lines` and `instr_max_para_chars` are now columns in `calibration.tsv`. Measure with

```bash
python3 - instruction.md <<'EOF'
import io, re, sys
t = io.open(sys.argv[1], encoding='utf-8').read()
t = re.sub('(?ms)^' + chr(96)*3 + '.*?^' + chr(96)*3 + r'[ \t]*$', '', t)   # drop fenced code
struct = re.compile(r'^(\||#|>|[-*+][ \t]|\d+[.)][ \t])')                   # table, heading, quote, bullet, NUMBERED item
runs, cur = [], []
for ln in t.split(chr(10)):
    if not ln.strip() or struct.match(ln.lstrip()):
        if cur: runs.append(chr(10).join(cur)); cur = []
    else:
        cur.append(ln)
if cur: runs.append(chr(10).join(cur))
print(t.count(chr(10)), 'lines, longest prose paragraph', max(map(len, runs)))
EOF
```

**Corrected 2026-08-11 (LEDGER L45).** The script above replaces one that dropped only lines
starting with `|`, `-`, `#` or `*`. It had two defects pulling opposite ways. It never excluded
ordered list items, so a numbered list with no blank lines between the items counted as a single
paragraph: libcrux 1165 was recorded in `calibration.tsv` at **2698** when its longest prose
paragraph is **791**, xlwings at 622 when it is 312, and elfuse at 564 when it is 379. It also read
a `**bold lead-in**` paragraph as a `*` bullet and dropped it, which hides real prose the other
way: hulak 118 measures 420 under the old script and **603** under this one. The values in the
table above are all re-measured with the corrected script. **The band survives this and gets
stronger, because its only apparent counterexample was the bug.** Nothing measured here now sits
between 830 and the 2724 that was bounced. What the sample still cannot tell you is where in that
gap the line falls, since it holds one bounced instruction rather than a distribution. Treat the
range as calibration and never as a threshold. The AltBeacon figures are unaffected either way:
that instruction has never used a numbered list or a bold lead-in, so neither defect could reach
it, and its as-received file measures 1919 identically under both scripts.

libcrux's 791 is evidence rather than a footnote, despite the task closing as Not Fixable with no
bundle for a reviewer to read. Its round 4 agentic judge scored every instruction axis 4.5 to 5.0
against the same `instruction.md` the task closed with, since round 5 changed no bundle file. The
judge read it even though no reviewer did.


**Structure is not the risk it is sometimes taken for.** The accepted bundle uses headings, bullet
lists and a table, and still scores full marks on reading like a real ticket. What costs is a
single paragraph carrying fourteen field names, their types, their defaults and three method
contracts at once, because a judge reading for coverage cannot tell which of those is a
requirement. As always this is calibration, not a target: 717 is a fact about one accepted
bundle, not a threshold anyone published.

## One example is not a distribution: see `calibration.tsv`

This note is a single worked bundle, and a single bundle cannot tell you which of its numbers
are properties of an accepted task and which are properties of a Deno migration with 132 graded
ids. [calibration.tsv](calibration.tsv) carries the same measurements for every task this
workspace has handled, one row each, so the comparison is mechanical.

What the four rows already show that this note on its own cannot:

- `pass_to_pass` ranges from 21 to 1204 and the graded total from 38 to 1223. There is no normal
  size. What is constant is that the guard is populated at all.
- `graded ids outside the patched files` **was** above zero on all four, from 102 of 132 to 1124
  of 1223, and this note used to say the create-only `tests.patch` had never been the right shape
  here. **statrs 315 closes that open question**: it measured **0 of 127** outside the patched
  file, shipped the create-only shape with a git-independent pre-delete in `test.sh`, and was
  accepted. So the shape is now validated by an outcome rather than only reasoned about, and the
  rule in [[tests-patch-vs-agent-edits]] stands as written: measure where the graded ids live,
  and let the number pick the shape. Read libcrux's row with its caveat: cargo ids carry no path,
  so the counting script cannot resolve them and its 38 of 38 is the tool's answer rather than
  the truth.
- Oracle runtime is 19 to 138 seconds against verifier timeouts of 900 or 1800. The headroom is
  never close.
- `fail_to_pass` sits at 17, 19, 20, 20 against a hard ceiling of 20. Three of the four are at
  or one below the cap.

**A column in that file is calibration and never a target.** It tells you whether a number you
measured is ordinary or unusual, which is a reason to look again, not a number to move toward.
Nothing is improved by pushing `fail_to_pass` to 20 because kvdex was 20.
