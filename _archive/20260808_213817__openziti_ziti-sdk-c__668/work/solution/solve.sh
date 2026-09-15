#!/usr/bin/env bash
# Oracle: apply golden.patch to the workspace, forward only.
#
# Running this twice in a row must leave the tree in the solved state, so the
# first step is an idempotency probe: if the reverse of the patch still fits,
# the patch is already in and there is nothing to do. There is deliberately no
# reverse apply anywhere else, because a reverse apply that counted as success
# would undo the solution on a second run and hide a patch that never applied.
#
# git is used when the workspace is a usable checkout and patch(1) when it is
# not, so a damaged .git cannot take the oracle down with it.
set -euo pipefail

PATCH="/solution/golden.patch"

WORKSPACE=""
for p in /app /testbed /workspace; do
  if [ -d "$p" ]; then WORKSPACE="$p"; break; fi
done
if [ -z "$WORKSPACE" ]; then
  echo "ERROR: could not resolve workspace" >&2
  exit 1
fi
cd "$WORKSPACE"

if [ ! -f "$PATCH" ]; then
  echo "ERROR: $PATCH is missing." >&2
  exit 1
fi

USE_GIT=0
if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
  USE_GIT=1
fi

if [ "$USE_GIT" = "1" ]; then
  # 1. already applied?
  if git apply -p1 --reverse --check --whitespace=nowarn "$PATCH" 2>/dev/null; then
    echo "golden.patch is already applied; nothing to do."
    exit 0
  fi
  # 2. plain forward apply
  if git apply -p1 --whitespace=nowarn "$PATCH" 2>/dev/null; then
    echo "golden.patch applied."
    exit 0
  fi
  # 3. forward apply with a three-way merge, for context drift
  if git apply -p1 --3way --whitespace=nowarn "$PATCH"; then
    echo "golden.patch applied with a three-way merge."
    exit 0
  fi
else
  echo "no usable git checkout here, falling back to patch(1)" >&2
  # 1. already applied?
  if patch -p1 -R --dry-run --force --silent < "$PATCH" >/dev/null 2>&1; then
    echo "golden.patch is already applied; nothing to do."
    exit 0
  fi
  # 2. forward apply
  if patch -p1 --forward < "$PATCH"; then
    echo "golden.patch applied."
    exit 0
  fi
fi

# 4. loud failure
echo "ERROR: golden.patch did not apply cleanly." >&2
exit 1
