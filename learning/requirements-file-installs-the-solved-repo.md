---
id: requirements-file-installs-the-solved-repo
status: locally-verified
last_verified: 2026-08-17
verified_by:
  - 20260803_111822__nolabs-ai_deepfabric__297
evidence: "Built the arriving image and read the files. A 112 MB clone of the upstream repo at a commit ten and a half months after the source PR merged, sitting at /app/src/deepfabric, carrying every deliverable instruction.md names"
applies_to:
  languages: [python, javascript, any-with-a-lockfile]
  runners: [any]
  phases: [step-2, step-3, step-5, review]
blocks_submission: true
fails_gate: [quality-check, review-gate-agentic-judge]
---

# The dependency file can install the task's own repository, solved

Every leakage check in this workspace looks at `instruction.md`, at `environment/repo`, or at
`.git`. None of them looks at the **dependency list**, and on deepfabric 297 that is where the
answer was. `environment/frozen-requirements.txt` line 20 read

```
-e git+https://github.com/nolabs-ai/deepfabric.git@86591d8ae9217a906823d7e32f3e02fcbee3b7b0#egg=DeepFabric
```

which is the task's own repository, installed editable, at a commit that is **not the base
commit**. `git cat-file -t 86591d8` inside the shipped repo answers `Not a valid object name`,
because that revision is nowhere in the shipped history. The GitHub API dates it 2026-07-30,
about ten and a half months after PR 297 merged.

## Why the clone lands somewhere an agent reads

A `pip install -e git+URL` needs somewhere to put the checkout, and for a non-virtualenv install
pip's default is `<current directory>/src`. The Dockerfile sets `WORKDIR /app` at line 11 and
runs the requirements install at line 15, so the clone lands at **`/app/src/deepfabric`**, inside
the agent's own working directory. `environment/repo/.gitignore` has no `src/` entry either, so
it also turns up in `git status` inside `/app`.

Measured in the arriving image:

```
/app/src/deepfabric               112 MB, git HEAD 86591d8ae9217a906823d7e32f3e02fcbee3b7b0
  deepfabric/schemas.py           class ChatMessage:48  ChatTranscript:76
                                  GraphSubtopic:1016    GraphSubtopics:1026
  deepfabric/llm/client.py        class LLMClient:44    def generate:98    import outlines:12
  deepfabric/graph.py             from .llm import LLMClient:19   self.llm_client = LLMClient(:172
  deepfabric/config.py            provider / model_name split at :63, :587, :608-609
  grep -rn litellm deepfabric/    no hits
```

Those are the four files `golden.patch` creates plus the split it makes, so an agent reading one
directory across from its own checkout had the whole task written out.

## Why no existing check catches it

- The stray-artifact sweep walks `work/`, and the clone does not exist until the image is built
- The git-hygiene block reads `environment/repo/.git`, which is clean
- The Section 10.3 restore-shape count answers a different question entirely
- `docs/guidelines.md:108` describes environment spoilers as "commit messages, comments, or docs
  in the base repo/Docker setup that describe the exact change", which sets the reader looking for
  prose rather than for an install line
- Build-time network use is explicitly allowed, so a `git+https://` line reads as normal

The tell is not the URL scheme. It is **the repo name in the URL matching `[metadata] repo_name`**.

## The check

Two greps, on arrival, before anything else:

```bash
# any dependency file that names the task's own repository
REPO=$(sed -n 's/^ *repo_name *= *"\(.*\)"/\1/p' task.toml)
grep -rniE "git\+|github\.com|gitlab\.com" environment/*.txt environment/Dockerfile
grep -rni "$REPO" environment/*.txt environment/Dockerfile
```

Any hit naming the task's own repo is a finding whatever revision it pins, because even the base
commit leaves a second checkout of the product in an agent-readable path. Then confirm it in the
built image rather than reasoning about pip's src default:

```bash
docker run --rm --network none <image> sh -c 'find /app -name "*.py" -path "*src*" | head; du -sh /app/src 2>/dev/null'
```

## The fix

Delete the line. On this bundle it was redundant as well as harmful, because `Dockerfile:19`
already runs `pip install --no-cache-dir -e ".[dev]"` from `/app`, and every other requirement in
the file carries an exact version so removing one editable entry changed no resolution. Re-pinning
it to the base commit would close the leak and still leave a second copy of the product in an
agent path, so removal is the cleaner move.

Verified after the rebuild: `find /app -name schemas.py` returns nothing, no
`deepfabric/llm/client.py` exists anywhere on the filesystem, `import deepfabric` still resolves
to `/app/deepfabric/__init__.py`, and the image dropped from 1.2 GB to 1.07 GB.

## What it means for the arrival numbers

deepfabric 297 arrived at `pass_at_k_opus_4_8 = "2/3"` and `pass_at_k_gpt_5_5 = "3/3"`, and those
were measured against **this** image. LEDGER **L44** already says an arrival rate measures the
bundle rather than the problem; this is the strongest instance of it recorded here, because the
bundle was handing over the finished implementation. Say so in Comments for Reviewer, because a
reviewer reading a high arrival rate will otherwise read it as a difficulty signal.

## Related

- `learning/unreachable-git-blobs.md`, the same lesson one directory over. Solution material
  survives in places nobody thinks to read
- `learning/dockerignore-context-root.md`, for the other way content reaches `/app` unnoticed
- LEDGER **L44**, on reading an arrival `pass_at_k`
