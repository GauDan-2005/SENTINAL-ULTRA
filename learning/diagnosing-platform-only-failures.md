---
id: diagnosing-platform-only-failures
status: platform-confirmed
last_verified: 2026-08-04
verified_by:
  - 20260719_045042__oliver-oloughlin_kvdex__245
evidence: "Rounds 3 to 6 of kvdex 245: three locally-verified fixes to three real defects, none of which was the defect"
applies_to:
  languages: [any]
  runners: [any]
  phases: [difficulty, oracle, process]
blocks_submission: false
fails_gate: [difficulty]
supersedes: []
contradicts: []
---

# Diagnosing a failure you can only see on the platform

Source: `20260719_045042__oliver-oloughlin_kvdex__245`, rounds 3 to 6, 2026-08-01 to 08-04.
Accepted on round 6. Three of the six rounds were spent on one defect, and all three were
spent the same wrong way, so this is the most expensive process lesson in the log.

This note is not about `tests.patch`. That mechanism lives in
`tests-patch-vs-agent-edits.md`. This is about **how to work a failure that reproduces on the
platform and nowhere else**, which is a class, not a one-off.

## What happened

The platform kept returning the same line, to the character, for three consecutive rounds:

```
error: patch failed: tests/collection/enqueue.test.ts:16
error: tests/collection/enqueue.test.ts: patch does not apply
```

Each round followed the same loop, and each loop looked rigorous from the inside:

| Round | Hypothesis | Local verification | Platform result |
|---|---|---|---|
| 3 | agent edits the tests, so restore them | oracle + NOP + a simulated `sed -i` all green | 13 of 16 invalid |
| 4 | `git checkout -- ` reads the index, so restore from the base commit | 4 controlled runs varying the agent's git behaviour, all green | 16 of 16 invalid, **worse** |
| 5 | the directory must be deleted first | same 4 runs plus a collision case, all green | 15 of 16 invalid |
| 6 | **do not depend on git at all** | same runs plus a no-git case | **passed, accepted** |

Every hypothesis in rounds 3 to 5 was a **real defect**, correctly identified and correctly
fixed. The measurements were sound. None of them was what the platform was hitting. Three
rounds went to fixing real bugs that were not the bug.

## Why the loop kept closing on itself

The local reproduction was doing two jobs and only one of them was valid. It proved *"this
condition causes that error"*. It was read as *"that error is caused by this condition"*. A
condition sufficient to produce the symptom is not evidence that it is the condition in play.

The tell was available from round 4 and was not read as one: **the result did not improve**.
13 of 16, then 16 of 16, then 15 of 16 is one number with noise on it. A fix that addresses
the actual cause moves the number. A flat line across two fixes means the fixes are landing
somewhere other than the cause.

## The rule

**Two strikes. When a fix you verified locally fails on the platform a second time, stop
refining the theory and remove the dependency instead.**

Not "find the third mechanism". The third mechanism is the same trap: it will be locally
reproducible, it will be a real defect, and it will cost another round. The question changes
from *"what is breaking my restore?"* to *"how do I write a restore that cannot be broken by
anything I am unable to observe?"*

That reframing is what ended it. The winning design does not know or care whether git exists,
whether the agent staged, whether the object store was pruned, or whether `.git` shipped at
all. It reads a payload out of `/tests`, which is guaranteed mounted because `test.sh` is
itself read from there. **The strongest guarantee available inside the verifier is the
verifier's own entrypoint.** Anchor to that and the failure class disappears rather than being
patched.

Generalised: when you cannot inspect the environment, do not build on anything in it. Prefer
the thing whose presence is implied by your code running at all.

## The evidence hierarchy, cheapest first

Ranked by what it actually settled on this task, not by how it felt at the time.

1. **Your own local reproduction.** Cheapest, and the weakest. Proves sufficiency, never
   necessity. Round 3, 4 and 5 all had one and all three were wrong.
2. **The round-over-round trend.** Free. Nobody read it for two rounds. A flat number across
   two different fixes is a stronger signal than any single green local run.
3. **The agent session transcripts** in the difficulty artifact, under
   `solve/<model>_<n>/agent/sessions/`. One grep killed two live theories at once: `.git` was
   present in `/app`, and across 12 transcripts not one agent ran `git add` or `git commit`.
   Read these *before* theorising, not after shipping.
4. **A sibling task's per-trial analysis.** The strongest, and the one nobody thinks to look
   at. kvdex's own report returned `Task Instruction Sufficiency: NOT_APPLICABLE`, so it
   looked like there was no evidence to be had. equalsverifier 1166's report on the same
   harness contained the answer in plain words, from four independent codex trials:

   > "the workspace is not a git repository, so the verifier's test-restoration step was
   > unable to reset test files to their base state before applying tests.patch"

   Different repo, different language, different build system, same platform, same harness,
   same error class. **The harness is shared, so a sibling task's report is evidence about
   your task's environment.**

**Rule: when your own report returns `NOT_APPLICABLE` for instruction sufficiency, that means
this run produced no analysis, not that no analysis exists. Read the other tasks' reports
before concluding you are working blind.**

## Cost, and why this failure class deserves more up-front investment than any other

A harness failure is not one failure among several. It **voids the entire round**. When trials
are scored invalid you learn nothing about difficulty, nothing about the quality panel's test
axes, nothing about the agent's actual behaviour. Every other check that ran becomes
uninformative. Contrast a coverage finding, which is one axis on a report where everything
else still told you something.

So the arithmetic is not "spend an hour on diagnosis or ship in ten minutes". It is "spend an
hour on diagnosis, or spend a whole round and learn nothing". Rounds cost days of wall clock
on this platform.

**Rule: on any `invalid trial` or `harness failure` result, do the full evidence pass before
writing a line of fix. Cheapest to most expensive, in the order above, and stop at the first
one that actually discriminates between your hypotheses.**

## What a local check can and cannot buy

Worth keeping the distinction sharp, because the local runs on this task were genuinely good
and still misled:

- **Can** prove a fix does not regress the oracle, the NOP or the hostile-delete gate. All
  three are necessary, and rounds 3 to 5 were right to run them.
- **Can** prove a specific hostile condition is survivable.
- **Cannot** tell you which hostile condition the platform is actually applying.
- **Cannot** be made complete, because you are simulating an environment you have never seen.

That last point is the whole argument for the design rule above. A verifier that survives
every condition you can imagine is still betting on your imagination. A verifier with no
dependency to break is not.

## A probe that cannot fail is worse than no probe

Source: `20260727_135618__AltBeacon_android-beacon-library__1177`, 2026-08-04.

Chasing an oracle `0/3` that would not reproduce, the theory was that the platform ran the
container with a different `HOME`, so the offline Gradle cache would not be found. The probe:

```bash
docker run -e HOME=/tmp/otherhome <image> bash -c 'bash /solution/solve.sh && bash /tests/test.sh'
```

Reward 1.0. Hypothesis recorded as dead. **It was a false negative.** Java resolves `user.home`
from the passwd entry, not from `$HOME`:

```
shell HOME     = /tmp/otherhome
java user.home = /root          <- the probe changed nothing Gradle looks at
```

Re-run against the thing Gradle actually reads, and it dies immediately:

```
$ GRADLE_USER_HOME=/tmp/nowhere ./gradlew --no-daemon --offline -q help
Exception in thread "main" java.net.UnknownHostException: services.gradle.org
exit=1
```

The wrapper looks for the Gradle distribution under its own home. Move that home and it tries to
download Gradle itself, which an airgapped verifier cannot do. Every run, identically.

**Rule: a probe has two assertions, and the first one is that the break landed.** This is already
in the log for hostile-delete probes (`verify-in-the-image.md`). It applies just as hard to
environment probes, where it is easier to get wrong because the variable you set and the variable
the tool reads often have the same name. Print what the tool resolved, not what you exported, and
put that line in the same command as the result.

The generalisation for tool caches: **`$HOME`, `user.home`, and the tool's own `*_USER_HOME` are
three different things.** Java and Gradle read the second and third. Setting the first proves
nothing about either.

## Pin every cache the airgapped verifier reads to an absolute path

Same task. The fix that came out of the above, and a differential worth copying.

Of four bundles from this workspace, three pass their oracle check and one does not. The accepted
one, kvdex 245, pins its cache with `ENV DENO_DIR=/deno-dir`. AltBeacon pinned the Android SDK to
`/opt/android-sdk` but left the Gradle cache and the Robolectric jars under whatever `user.home`
resolved to at build time.

**Rule: if the verifier runs offline, every cache it reads belongs at an absolute path set by
`ENV`, warmed at that path during the build.** `ENV GRADLE_USER_HOME=/opt/gradle-home`,
`ENV DENO_DIR=/deno-dir`, `-Dmaven.repo.local`, `ENV CARGO_HOME`. A cache under `~` is a cache
whose location depends on the uid the container happens to run as, which is not something a
submitter can observe or control.

Two cautions from doing it:

- **Do the `chmod` in the layer that creates the files, never in a layer of its own.** A trailing
  `RUN chmod -R a+rwX /opt/gradle-home` rewrote 1.5 GB of metadata into a fresh layer and took the
  image from 2.98 GB to 4.92 GB. Folded into the warm step it costs nothing.
- **Ship only what the measurement supports.** The `chmod` was meant to make the bundle survive a
  non-root uid. It half worked: `solve.sh` started passing, the tests still failed because
  Robolectric's jars follow `user.home` too. Since a non-root verifier would break all four
  bundles and three pass, the scenario was not in play, and a 1.4 GB image increase for a partial
  fix to an unproven problem is not worth shipping. Dropped it and kept the pin.

**Pinning the path is half of it. The warm list has to cover every runtime level the graded tests
actually use.** Added 2026-08-14, android-beacon 1177.

That image warms Robolectric's platform jars through a throwaway test annotated
`@Config(sdk = {28, 34})`, which are the levels the graded classes pinned. Round 8 added a graded test at
`@Config(sdk = 24)`, because the behaviour under test only exists below API 26. The jar for 24 was not in
the cache, and the verifier runs with no network, so the test could not have run on the platform at all.
It passes locally the moment you build with network available, which is exactly the shape of failure this
note exists for.

**Rule: adding a graded test at a runtime level the image never warmed is a new offline dependency, and
nothing in the bundle declares it.** Extend the warm list in the same edit that adds the test. A new SDK
level, a platform jar, a cross-compilation target and an interpreter version are all the same case.

The cheap proof is already available if the Dockerfile is written for it. That one runs its warm-up
twice, once with network and then again with `--offline`, so a missing jar fails the **build** rather
than the verifier. If the image you inherit only warms once, adding the second run is worth it: it turns
a silent verify-time failure into a loud build-time one. Confirm afterwards that the jar is really there
rather than trusting the build, `docker run --rm <image> sh -c 'find / -name "android-all*.jar"'`.
