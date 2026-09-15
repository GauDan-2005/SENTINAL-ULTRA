---
id: frozen-requirements-that-does-not-freeze
status: locally-verified
last_verified: 2026-08-18
verified_by:
  - 20260803_111822__nolabs-ai_deepfabric__297
evidence: "Platform returned SandboxBuildFailedError on a build that succeeds locally in 113 s. Measured: the project install re-resolved 21 unpinned packages and downgraded 12 the frozen file had just pinned, so the file was authoritative for 95 of its 107 pins"
applies_to:
  languages: [python, any-with-a-lockfile]
  runners: [any]
  phases: [step-2, step-5, step-5.5, eval-loop]
blocks_submission: true
fails_gate: [oracle-check, review-gate-difficulty-screen]
---

# A `frozen-requirements.txt` that the next layer un-freezes

`SandboxBuildFailedError` on the platform, a build that takes 113 seconds locally and has never
failed. The message that comes with it is worth quoting because it names the answer:

> Environment image failed to build - the sandbox could not build the image your task declares, so
> no trial ever started. This is a problem in the task itself: build environment/Dockerfile locally
> on a fresh checkout, fix whatever breaks (missing base image, unpinned package that disappeared, a
> build step that needs network), and resubmit.

## First, it is a task defect and not the infra carve-out

The carve-out at `docs/faq.md` is a **literal string test**: the one infra case is a message that
explicitly says the difficulty screen failed with an infra error. `SandboxBuildFailedError` and the
words "infra exception" classify the **trial**, not the cause. The documented infra tell is
inconsistency, and this was 1 of 1 with a named exception and specific remedial guidance.

## The shape, which is easy to ship and invisible locally

The stock Dockerfile does this:

```dockerfile
RUN pip install --no-cache-dir -r /tmp/frozen-requirements.txt   # ~110 exact pins
RUN pip install --no-cache-dir -e ".[dev]"                       # <- resolves against the live index
```

The second line is the defect. It resolves the project's own `pyproject.toml`, and whatever that
leaves unbounded is decided by whatever PyPI is serving that day. Measured on deepfabric 297 by
diffing `pip freeze` in the built image against the frozen file:

| | |
|---|---|
| packages in the image pinned **nowhere** | **21** (litellm, ipython, tiktoken, fastuuid, python-dotenv, psutil, importlib-metadata, zipp and the ipython stack) |
| packages the frozen file pins that the second layer **downgrades** | **12** (requests 2.34.2 to 2.32.3, huggingface-hub 1.26.0 to 0.34.4, datasets 5.0.1 to 4.0.0, fsspec, certifi, idna, urllib3, tqdm, dill, multiprocess, charset-normalizer, mermaid-py) |
| pins the file is actually authoritative for | 95 of 107 |

So the file named `frozen-requirements.txt` does not describe the image. On this bundle it turned out
to be a `pip freeze` of the project at a **much later commit than the one under test**, which is why
the second layer had so much to undo.

## Three sharper things hiding inside that

- **A live backtracking search on every build.** `pyproject.toml` declared `mermaid-py>=0.8.0` and
  hard-pinned `requests==2.32.3`. Every mermaid-py at or above the floor: 0.8.4 and 0.8.3 require
  `requests>=2.32.5` and are rejected, 0.8.2 does not exist. The satisfiable set is exactly
  {0.8.0, 0.8.1}, which is **two yanks from `ResolutionImpossible`**, and pip fetches and rejects the
  newer metadata on every single build.
- **Unpinned native extensions against an image with no compiler.** litellm pulls `fastuuid>=0.12.0`
  and `tiktoken>=0.7.0`, both Rust. The image has no gcc, cc, make, cargo or rustc. One release
  without a wheel for the sandbox's platform tag is a hard build failure with nothing in the bundle
  changed.
- **The build backend resolved live.** `requires = ["hatchling"]` with no bound, and PEP 517 build
  isolation fetches it fresh into a throwaway env on every build. The tell that isolation really ran:
  `editables` is required for a hatchling editable install, is absent from the manifest and absent
  from the image, and the install succeeded anyway.

## The fix, and why `--no-deps` is required rather than convenient

```dockerfile
FROM python:3.11-slim@sha256:<manifest-list digest>          # pin the moving tag
COPY frozen-requirements.txt /tmp/frozen-requirements.txt
RUN pip install --no-cache-dir --no-deps -r /tmp/frozen-requirements.txt
RUN pip install --no-cache-dir --no-build-isolation \
      -c /tmp/frozen-requirements.txt -e ".[dev]"
```

Regenerate the manifest from `pip freeze` of a **built and verified** image, so it records the
versions the build actually ends on rather than the ones a fresh resolve would pick.

**`--no-deps` is not a shortcut.** The manifest of a working image is frequently **not resolvable in
one pass**: here the project pins `requests==2.32.3` while two of its own dependencies want newer, so
`pip install -r manifest` returns `ResolutionImpossible`, measured. The old two-layer shape was
reaching that combination only by installing a different set and letting the next layer downgrade it.
`--no-deps` says out loud that the manifest is a closure and there is nothing to solve.

Pin the base image by **manifest-list digest**, not by a per-architecture image digest, or the pin
breaks on any arch but yours. `docs/guidelines.md` lists an unpinned base image as a fixable
environment issue.

## Proving the fix when the symptom does not reproduce

This is the hard part and it deserves stating. The build already succeeded locally, so after any fix
it still succeeds, which is the same observation as before. `learning/diagnosing-platform-only-failures.md`
covers the reverse case, a local reproduction; this is a local **non**-reproduction, which is worse,
because nothing is falsifiable. The ranking criterion is therefore dependency-removal rather than
theory-fit, and the evidence to gather is about determinism rather than about success:

```
the project layer installs        deepfabric only, 0 Collecting and 0 Downloading lines
the test-tools layer              every line "Requirement already satisfied"
two independent cold builds       identical N-package freeze
package set vs the verified image identical
```

Say plainly in the answers that the culprit package is unknown and that the fix removes the class
rather than naming it, and ask for the results artifact, which would carry the build log.

## Related

- [[requirements-file-installs-the-solved-repo]] - the other defect in the same file on the same task
- [[diagnosing-platform-only-failures]] - the two-strikes rule and the evidence hierarchy
- [[dockerignore-context-root]] - the other way the image ends up carrying what nobody intended
