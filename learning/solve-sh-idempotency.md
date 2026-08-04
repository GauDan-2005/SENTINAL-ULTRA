# A non-idempotent solve.sh silently undoes the solution on the second run

Source: `20260727_135618__AltBeacon_android-beacon-library__1177`, platform eval 2026-08-02,
found and fixed the same day. **Machine-verified on this workspace**, unlike the
`solve.sh` bullet in `CLAUDE.md` 10.6, which came from a peer reviewer's notes.

> **Correction, 2026-08-03.** The first version of this note was titled "…grades the oracle at
> 0/3" and presented the reverse-apply fallback as the *cause* of a platform
> `Oracle did not pass all runs: 0/3`. **That causal claim was wrong** and is retracted below.
> The defect described here is real, reproduced, and worth fixing on its own merits. It was not
> what the platform was failing on.

## What it looks like

The defect is invisible until you invoke the script twice. The bundle it was found on was also
showing this, which is what sent the search here in the first place:

```
Agent Runner Summary: Evaluation FAILED. Validation failed: Oracle did not pass all runs: 0/3.
Task may be flaky or has infra issues.
```

The Difficulty Check prints the same line and nothing else. No agent stats, because the oracle
gate fails before the agent trials run.

Every local check is green. Oracle reward 1, 229 of 229, NOP reward 0. Three fresh runs on an
image cold-built from the uploaded zip: reward 1 every time.

## Why it happens

The shipped `solve.sh` on that task, and the same shape ships on others:

```bash
set -e
cd /app
if   git apply -p1 --whitespace=nowarn /solution/golden.patch 2>/dev/null; then :
elif git apply -p1 --3way --whitespace=nowarn /solution/golden.patch 2>/dev/null; then :
else git apply -p1 -R --whitespace=nowarn /solution/golden.patch
fi
```

The `else` branch reverse-applies. Once the tree is already patched, both forward attempts
fail, so the fallback fires and **removes the solution**, then exits 0. Proven in one container:

```
first apply OK
1                                     <- adjustSettings present in BeaconManager
second apply exit 0                   <- solve.sh reported success
adjustSettings occurrences after 2nd run: 0
Settings.kt GONE — solution was reversed
```

Any path that invokes `solve.sh` more than once, or starts from a tree that is already
patched, hands the verifier an unsolved repo.

## Why this was NOT the 0/3, and how that was settled

The fix shipped, the same bundle was re-uploaded, and the platform returned
`Oracle did not pass all runs: 0/3` again — with the judge scoring `oracle_no_gaming` 5/5 and
quoting the *new* script by line number, so the corrected bundle is definitely what ran. Two
independent disproofs, either of which was available before any of the measuring started:

- **A sibling bundle ships the unsafe script and passes.**
  `20260728_153118__jqno_equalsverifier__1166` has the identical reverse-apply fallback and its
  oracle passed 3/3 on the platform. The script was never the discriminator between the two.
- **The arithmetic does not work.** The reverse-apply only fires from the *second* invocation
  onward, so the first oracle run passes. This defect can produce 1/3. It cannot produce 0/3.
  A reported 0/3 says run one already failed, which rules out every state-accumulation theory
  in one step.

**Read the number before theorising.** `0/3` and `1/3` and `2/3` are different failures.
Anything that needs prior state to go wrong cannot explain a `0/N`.

## The trap this note fell into

The reasoning that produced the wrong answer was: the platform says "flaky or infra issues";
`CLAUDE.md` 3 says genuine infra failures are *inconsistent*; this one is consistent; therefore
it is a task defect. All true. Then: a real, reproducible, consistent-looking defect turned up
in the oracle path — therefore that is the one. That last step is where it went wrong.

A found defect matching the *shape* of the symptom is not the cause until something ties it to
the symptom. The tie was available and cheap: count the failed runs, and check whether a sibling
task with the same defect fails the same way. Neither was done.

**Rule: before writing a root cause into this log, state what observation would be different if
the diagnosis were wrong, and go check it.** Fix the defect either way. Do not close the
investigation, and do not tell the reviewer you found the cause, until that check passes.

## The fix

Forward-only, no-op when already applied, loud when nothing applies:

```bash
set -euo pipefail
cd /app

if git apply -p1 --reverse --check --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
  echo "golden.patch is already applied; nothing to do."
  exit 0
fi
if git apply -p1 --whitespace=nowarn /solution/golden.patch 2>/dev/null; then exit 0; fi
if git apply -p1 --3way --whitespace=nowarn /solution/golden.patch; then exit 0; fi

echo "ERROR: golden.patch did not apply cleanly." >&2
exit 1
```

`--reverse --check` is the idempotency probe: if the reverse of the patch fits the tree, the
patch is already in. Verified after the change with three consecutive applies in one
container. Solution intact, verifier reward 1, 230 of 230.

## The check to run on every task

One container, one minute, and it is the only thing that catches this:

```bash
docker run --rm --network none -v "$PWD/solution:/solution:ro" <image> bash -c '
  bash /solution/solve.sh
  bash /solution/solve.sh
  ls /app/<a file the patch creates> || echo "REVERSED — solve.sh is not idempotent"'
```

### That check reports a false green when the reverse only partially applies

Source: `20260728_153118__jqno_equalsverifier__1166`, measured 2026-08-04. The check above was
run on this task and said nothing was wrong. The script was still broken.

When `golden.patch` **deletes** a file as well as creating some, the reverse pass can get part
way and then abort. Measured over three invocations:

| Run | exit | file the patch creates | file the patch deletes | changed files |
|---|---|---|---|---|
| 1 | 0 | present | absent (correct) | 11 |
| 2 | **1** | present | **restored** | 10 |
| 3 | **1** | present | **restored** | 10 |

The created file survives, so `ls <a file the patch creates>` prints it and the check passes.
Meanwhile `SealedTypesFinder.java`, which the refactor deletes, is back, and the tree is neither
base nor solved. It fails loudly rather than silently, which is why this task's oracle stayed at
3/3 on the platform, but a reviewer running the script twice sees exit 1 and a corrupted tree.

**Revised check. Assert on the exit status and on a file the patch DELETES, not only on one it
creates:**

```bash
docker run --rm --network none -v "$PWD/solution:/solution:ro" <image> bash -c '
  cd /app
  for i in 1 2 3; do bash /solution/solve.sh; echo "run $i exit=$?"; done
  ls <a file the patch creates> >/dev/null || echo "REVERSED"
  ! ls <a file the patch deletes> >/dev/null 2>&1 || echo "DELETE UNDONE"
  echo "changed files: $(git status --porcelain | wc -l)"'
```

Every run must exit 0 and the changed-file count must not move. Find the deleted files with
`grep -B3 "^deleted file mode" solution/golden.patch | grep "^diff --git"`. The forward-only fix
above handles this case unchanged: three runs, all exit 0, count stable at 11.

Grep for the tell before you even build: `grep -n 'apply.* -R' solution/solve.sh`. A `-R` on
the *only* path is correct on reverse-diff tasks that ship `init_state.patch`
(`CLAUDE.md` 9). A `-R` as a *fallback* after a failed forward apply is always the bug.

## What this cost, and what not to do

Two rounds. Recording every eliminated hypothesis so nobody repeats the sweep — the first four
came from round 1, the rest from round 2 after the retraction above:

| Hypothesis | Measurement | Verdict |
|---|---|---|
| `build_timeout_sec = 900` too low for a double Gradle warm | cold `docker build --no-cache` from the zip: exit 0 in **316s**; `gradlew test` alone is **52s** at the declared 4 cpus, so the 316s is download-bound not compute-bound | weak, not dead |
| Offline Gradle cache missing the deps `golden.patch` bumps | image holds core-ktx 1.12.0 and robolectric 4.11.1 | dead |
| Verifier timeout on a slow runner | oracle run is **30s** against `execution.timeout_sec` 1500 | dead |
| A flaky graded test | 3 fresh runs on the cold image, identical pass sets | dead |
| Non-idempotent `solve.sh` | sibling bundle ships it and passes 3/3; 0/3 needs run one to fail | **dead — this note's original claim** |
| Ungraded test flake against `allow_extra_failures = false` | suite reports exactly the graded ids, no ungraded surface | dead |
| Locale or timezone | oracle under `TZ=UTC LANG=C LC_ALL=C`: reward 1, full pass set | dead |
| Non-root execution | `--user 1000:1000` makes git refuse the repo outright, but that breaks all four bundles and three pass | dead |
| Container `CMD` exiting early | all four Dockerfiles have the same run-then-exit shape and Harbor overrides it | dead |

**Rule: when the platform reports an oracle failure that does not reproduce, test the oracle
*script* before you test the environment.** A single clean run proves the patch applies. It
proves nothing about what happens on the second invocation, and the platform runs it three
times. That rule still holds — it is cheap and it found a real defect. What does not follow is
that the defect it finds is the failure you were sent to explain.

**Second rule, learned the expensive way: an oracle failure that survives a full local
elimination sweep is a `docs/faq.md` escalation, not a rework loop.** The one surface a
submitter cannot test is the platform building the image. On a bundle whose Dockerfile pulls an
Android SDK plus ~2 GB of Gradle and Robolectric cache and whose verifier then runs `--offline`,
a partial cache on their builder fails silently with no test XML and grades 0 every run,
invisibly. Ship the free mitigations (raise `build_timeout_sec` to the 1800 ceiling, keep the
image lean), then escalate on Slack with the submission UID rather than spending another round
guessing.

Related: [verifier-fail-open.md](verifier-fail-open.md) is the same class of defect one level
over, a verifier that reports success it did not earn. This one is a solver that reports
success while undoing its own work.
