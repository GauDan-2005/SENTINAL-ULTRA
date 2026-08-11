---
id: dockerignore-context-root
status: platform-confirmed
last_verified: 2026-08-06
verified_by:
  - 20260805_080500__hyperledger-firefly_firefly__1123
evidence: "Both agentic judges scored packaging 1.0 and cited environment/repo/.vscode reaching /app, because the repo's own .dockerignore listing **/.vscode sits below the build-context root and Docker never reads it"
applies_to:
  languages: [any]
  runners: [docker]
  phases: [analysis, packaging, quality-check]
blocks_submission: true
fails_gate: [quality-check]
supersedes: []
contradicts: []
---

# A repo's own `.dockerignore` is inert when the build context is its parent

## What happened

firefly 1123 round 0 came back blocked at the agentic judge. The blocking reason was
`coverage_gap`, but the worst number on the report was **packaging 1.0 from both judges**, and
they agreed on the mechanism:

> The Dockerfile at `environment/Dockerfile:13-14` sets the build context to `environment/` and
> runs `COPY repo/ .`, so the `**/.vscode` rule in `environment/repo/.dockerignore` is not at the
> build-context root and does not apply. As a result the upstream repo's `.vscode/launch.json`
> and `.vscode/settings.json` ship verbatim into `/app/.vscode/` inside the running container.

Both judges cited `_DIRECTORY_LISTING.txt`, a listing of the bundle the platform hands them. So
this is visible to a judge from the file list alone, without building anything.

## Why the stray-artifact sweep misses it

The Step 2 sweep looks for artifacts and this repo genuinely has one, so the sweep is not what
failed. What failed is the reasoning after it: **the repo carries a `.dockerignore` that lists
`**/.vscode`, and it reads as though the problem is already handled.** It is not, for a reason
that has nothing to do with the rule and everything to do with where the file sits.

Docker reads exactly one `.dockerignore`, at the root of the **build context**. Harbor bundles
put the context at `environment/` and the repo at `environment/repo/`, so a repo that ignores its
own editor directories at its own root is one level too deep and the file is never opened.

**Every Harbor bundle has this shape.** The context is always `environment/`, the repo is always
`environment/repo/`, so any `.dockerignore` a repo ships is inert by construction.

## The check

Two lines, in the Step 2 sweep, and it costs nothing:

```bash
# does the repo think it is ignoring something?
ls environment/repo/.dockerignore && cat environment/repo/.dockerignore
# is there one where Docker actually looks?
ls environment/.dockerignore || echo "NO context-root .dockerignore - the repo's is inert"
```

Then confirm from the built image rather than from the file list, because that is what the judge's
claim is really about:

```bash
docker run --rm <image> bash -c \
  'find /app -maxdepth 3 \( -name .vscode -o -name .idea -o -name .DS_Store \) | head'
```

Silence is the pass. Anything printed is a hard cap on packaging.

## The fix, when the artifact is tracked upstream

`accepted-bundle-reference.md` records kvdex 245 leaving `.vscode/settings.json` in place, with
one judge at 1/5 and one at 5/5, adjudicated 3.0 and never resolved. **Here both judges said 1.0,
so the unadjudicated reading did not survive contact with a second task.** Treat a tracked
`.vscode` as something to exclude, not something to argue about.

Tracked at the base commit means it cannot be deleted from the shipped tree, because that is a
tracked-source edit. `CLAUDE.md` Step 2 item 7 names the two allowed routes and this task used
both, deliberately:

```dockerfile
WORKDIR /app
COPY repo/ .

# The upstream repo tracks .vscode/ at the base commit, so it cannot be deleted
# from the shipped tree. The repo's own .dockerignore does list **/.vscode, but it
# sits at repo/ rather than at this build context's root, so Docker never reads it.
RUN rm -rf .vscode .idea .DS_Store
```

plus `environment/.dockerignore` at the context root carrying `repo/.vscode` and `repo/.idea`.
The ignore file stops the artifacts entering the context at all; the `rm -rf` is the form the
workspace's own check greps for (`grep -n 'rm -rf' environment/Dockerfile` has to show a removal
after the `COPY`), and it sits on the exact line the judges cited, which is worth something when
the next report is written by a reader rather than a build.

**Disclose the side effect.** With the files gone from `/app` but still listed in the shipped
`.git`, `git status` inside the container reports them as deleted, and the oracle's changed-file
count goes up by that many. On firefly it went from 23 to 25 and every patch still applied.
Say so in Comments for Reviewer rather than letting a reviewer find it.

## The wider rule

**A hard-cap axis is worth over-defending.** Coverage findings are argued on judgment; a stray
developer artifact is a rule with a number attached, and both judges applied it identically. When
a fix has two sanctioned forms and neither costs anything, ship both.
