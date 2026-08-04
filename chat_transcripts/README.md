# chat_transcripts

Raw session records kept as evidence. Nothing here is a rule and nothing here is current.
When a file below and `CLAUDE.md`, `docs/` or `learning/` disagree, the rule file wins — a
transcript records what was believed and done at the time, including the parts that turned
out to be wrong.

These files exist for two jobs:

1. **Resuming a task.** A transcript carries the reasoning behind decisions that the task's
   own `task.md` only summarises.
2. **Backing a learning note.** Several notes in `learning/` cite a session that happened
   here rather than a rule in `docs/`. Without the transcript those notes are unsourced
   claims.

They are large. Grep them, do not read them end to end.

## Index

| File | Task | What it is | What it is evidence for |
|---|---|---|---|
| `cursor_etlcpp.md` | `20260716_114438__ETLCPP_etl__1466` | Cursor export, 2026-08-01, from **another EC's machine and workspace** (`/home/adity/TERMINUS/...`). Peer-review notes on an ETLCPP/etl PR 1466 submission. The task was never worked in this workspace and has no row in `INDEX.md` | The only source behind three notes that name this task in their Source line — `learning/unreachable-git-blobs.md`, `learning/verifier-fail-open.md`, `learning/tests-patch-vs-agent-edits.md` — and behind three of CLAUDE.md Section 10's worked examples. See the section below |
| `jqno.txt` | `20260728_153118__jqno_equalsverifier__1166` | Claude Code session log, 2026-07-31 to 2026-08-02. Analysis through revision round 2 | The session behind that task's `task.md`. The Quality Check run that produced the `[Q9]` and `[Q10]` must-have instruction failures written up in `learning/quality-check-criteria.md` |
| `alt.txt` | `20260727_135618__AltBeacon_android-beacon-library__1177` | Claude Code session log, 2026-07-31 to 2026-08-02 | The prescriptiveness scoreboard 0.38, 0.45, pass, 0.50 that `learning/prescriptiveness-check.md` reports, including a pass that did not stick |
| `cryspen.txt` | `20260723_030109__cryspen_libcrux__1165` | Claude Code session log, 2026-07-31 to 2026-08-01. Ends at the revision round 1 rebuild, so the round 3 difficulty expansion is **not** in here — that is in the task's `task.md` | The NTFS wedge and the stuck `rm -rf` that `learning/local-runs.md` records, and the git-hygiene sequence that had to be re-run after a reboot |
| `oliver.txt` | `20260719_045042__oliver-oloughlin_kvdex__245` | Claude Code session log, 2026-07-31 to 2026-08-02 | The six-round `tests.patch` restore saga on the one accepted bundle. Backs `learning/tests-patch-vs-agent-edits.md`, `learning/diagnosing-platform-only-failures.md` and `learning/accepted-bundle-reference.md` |
| `revision.md` | all four | Platform feedback pasted verbatim: automated feedback, difficulty check, agentic judge quality report and oracle check. jqno at line 3, oliver at 267, alt at 305, cryspen at 569 | The raw platform text every round's diagnosis was made from. Cited by `_archive/20260719_045042__oliver-oloughlin_kvdex__245/task.md` for the equalsverifier round 1 difficulty results |

## cursor_etlcpp.md is second-hand

It is the single most cited file here and the only one that did not come from this
workspace. Everything it supports is another EC's peer-review finding, read from their
session, not reproduced locally. Three findings in CLAUDE.md Section 10 come straight out
of it:

- the `stable_partition` analogue returning `first` instead of `last` for a single matching
  element, at `cursor_etlcpp.md:140` — Section 10.6
- the bidirectional-iterator tests built on `std::array`, whose iterators are random access,
  at `cursor_etlcpp.md:262` — Section 10.4
- the verifier that ignored the raw process exit while `pass_to_pass` was empty and
  `allow_extra_failures` was true, at `cursor_etlcpp.md:320` — Section 10.1

Treat all three as reported rather than platform-confirmed, and say so if one of them drives
a decision a reviewer might question.

## revision.md moved here on 2026-08-04

It used to sit at the workspace root. It is evidence, not a record, so it belongs with the
transcripts rather than beside `INDEX.md`. Two things to know before quoting it:

- **Every path in its headers is dead.** They all point at
  `/media/gaurav-s-ubuntu/COLLEGE MATERIAL/Work/AirDawg/SENTINAL-ULTRA/...`, which was the
  workspace before it moved to `/home/gaurav-s-ubuntu/Work/Work/AirDawg/SENTINAL-ULTRA` on
  ext4. The directory names in those headers also lost their `__` to markdown bold.
- **A round's feedback belongs in that task's `task.md`.** CLAUDE.md Step 10 item 1 requires
  the verbatim paste to land under a dated revision heading in the task record. This file is
  where several rounds were pasted before that rule existed, so treat it as the archive of
  record for those rounds and put anything new in `task.md`.

## Adding a transcript

Name it after the task, not after the session. Add a row above saying which task it belongs
to, what it covers and which notes cite it. If a `learning/` note is going to cite it, cite
the path `chat_transcripts/<file>` in full so `bin/doclint.sh` can resolve it.
