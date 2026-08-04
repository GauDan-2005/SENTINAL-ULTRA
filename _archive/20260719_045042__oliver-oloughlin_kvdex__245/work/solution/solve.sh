#!/usr/bin/env bash
# Apply the reference solution. Forward-only and idempotent: apply if the tree still needs
# it, no-op if it is already patched, fail loudly on anything else. The previous version
# fell back to `git apply -R` when the forward apply failed, which turned a second run on an
# already-patched tree into a silent revert of the solution.
set -e
cd /app

if git apply -p1 --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
  exit 0
fi

if git apply -p1 --3way --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
  exit 0
fi

# A tree that is already fully patched is the one legitimate reason the forward apply fails.
if git apply -p1 -R --check --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
  echo "golden.patch is already applied, nothing to do"
  exit 0
fi

echo "ERROR: golden.patch did not apply and the tree is not already patched" >&2
exit 1
