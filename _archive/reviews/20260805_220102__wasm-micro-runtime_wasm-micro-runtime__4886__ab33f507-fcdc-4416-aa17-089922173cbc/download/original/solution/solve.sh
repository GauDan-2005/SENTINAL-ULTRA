#!/usr/bin/env bash
# Apply the reference solution. Idempotent: re-running in a workspace that
# already carries the patch is a no-op, never a reverse-apply.
set -e
cd /app

# Already applied? Nothing to do.
if git apply -p1 -R --check --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
  echo "golden.patch already applied; nothing to do"
  exit 0
fi

if git apply -p1 --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
  exit 0
fi

# Agent edits to neighbouring context can defeat a strict apply; retry 3-way.
git apply -p1 --3way --whitespace=nowarn /solution/golden.patch
