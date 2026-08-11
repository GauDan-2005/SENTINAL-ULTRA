#!/usr/bin/env bash
# Apply the golden patch. Forward only, and a no-op when it is already applied,
# so repeated runs leave the tree in the same solved state.
# Started by a shell without arrays or pipefail (dash, ash) this script dies
# before it can write a reward, which reads as a missing verifier output rather
# than as a failure. Hand ourselves to bash instead.
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi

set -euo pipefail
cd /app

PATCH=/solution/golden.patch

# Already applied? The reverse of the patch fitting is the test for that.
if git apply -p1 --reverse --check --whitespace=nowarn "$PATCH" 2>/dev/null; then
  echo "golden.patch is already applied; nothing to do."
  exit 0
fi

if git apply -p1 --whitespace=nowarn "$PATCH" 2>/dev/null; then
  exit 0
fi

# Three-way resolves context drift that a plain apply will not. Still forward.
if git apply -p1 --3way --whitespace=nowarn "$PATCH"; then
  exit 0
fi

echo "ERROR: golden.patch did not apply cleanly." >&2
exit 1
