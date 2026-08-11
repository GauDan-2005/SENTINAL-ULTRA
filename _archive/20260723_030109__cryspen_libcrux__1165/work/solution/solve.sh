#!/usr/bin/env bash
# Apply the reference solution.
#
# Forward-only and idempotent: running this twice leaves the solved tree in
# place instead of reverse-applying the patch and silently undoing the fix.
set -euo pipefail
cd /app

# Already applied? Then the reverse of the patch fits the tree and there is
# nothing to do. This is the idempotency probe.
if git apply -p1 --reverse --check --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
  echo "golden.patch is already applied; nothing to do."
  exit 0
fi

if git apply -p1 --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
  exit 0
fi

if git apply -p1 --3way --whitespace=nowarn /solution/golden.patch; then
  exit 0
fi

echo "ERROR: golden.patch did not apply cleanly." >&2
exit 1
