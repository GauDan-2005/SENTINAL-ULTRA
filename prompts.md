# Prompt templates

Reusable prompts the submitter pastes into a session. This file is a scratchpad for the
human, not a rule document. Nothing here overrides `CLAUDE.md`, `docs/` or `learning/` —
when a prompt below and a rule file disagree, the rule file wins.

Paths are written with real directory names in backticks. A bare `__` renders as bold in
markdown, so a name pasted without backticks arrives mangled and gets mistaken for a
different task. See the "Confirm WHICH task" rule in Step 10, in
`.claude/rules/02-workflow-steps-6-to-10.md`.

---

## New task

```
This is the task details:

<paste the platform data block>

This is the task zip:

<path to the downloaded zip>

Arrange this new task according to the task structure, then analyse the repo completely.
Use docs/, learning/ and CLAUDE.md as the source of truth for every check and validation.
Complete Steps 1 to 8.
```

Handling times come from me, not from you. Ask for all four numbers and do not invent any of
them. The bands and the arithmetic are in Step 8, in
`.claude/rules/02-workflow-steps-6-to-10.md` — the total is fields 1 + 2 + 3
and never includes the revision figure.

The four questions the form asks:

- How long (in minutes) did it take you to review the initial task and determine its validity?
- How long (in minutes) did it take you to complete the initial task rewrite only?
- How long (in minutes) did it take you to complete the additional questions on the form?
- How long (in minutes) did it take you to complete all revisions? Update this every round.

---

## New review

```
This is a review task.

Submission zip: <path to the zip>
Submitter's form answers: <paste them, or say "not supplied">

Set it up under review_tasks/ and run Section 12. Read docs/reviewer-rubric.md before the
first finding is written and score against it: the five Major Pillars first, then the
Secondary Requirements, then the verdict.
```

The zip usually arrives on its own. Ask for the submitter's answers anyway, and if they never
come, say in the review which field went unanswered rather than filling it in unread. The
rubric is the bar for the task and also for the write-up, so a review that reads as generated
is a Major finding against the reviewer.

---

## Resume from a transcript

```
I was previously working on this task:
/home/gaurav-s-ubuntu/Work/Work/AirDawg/SENTINAL-ULTRA/tasks/`20260728_153118__jqno_equalsverifier__1166`

I have a transcript of the entire work and I want to continue the revision from that point.

Transcript: /home/gaurav-s-ubuntu/Work/Work/AirDawg/SENTINAL-ULTRA/chat_transcripts/jqno.txt

Analyse the task and the transcript completely.
```

The transcripts live in `chat_transcripts/` and are indexed in `chat_transcripts/README.md`.

---

## Revision round

```
I got another feedback.

<paste the platform report verbatim>

Read CLAUDE.md and the whole learning/ folder again before you start, since both may have
changed since the last round. Then run Step 10.
```

For a difficulty bounce specifically:

```
This time it says the task is not difficult enough. It is easy for the system.
Use the documentation and raise the difficulty while keeping everything the previous rounds
fixed.
```

---

## Explain, do not fix

```
I got this in the Prescriptiveness (optional) check.

<paste the build log>

Do not fix this yet. Explain what the errors are.
```

---

## After an acceptance

```
This task has been accepted. Work out and write down:

- which criteria it satisfied
- how the task was worked
- what the key factors were
- what the thinking process was

Then put the findings into learning/, and into CLAUDE.md or the matching `.claude/rules/` file.
```

---

## Platform CLI

```
stb submissions list --project-id 1230ae8f-afc6-4705-abc7-fbe1c94250ff --show-folder-names
```

`stb submissions list` is the source of truth for submission state. The web UI lags.
