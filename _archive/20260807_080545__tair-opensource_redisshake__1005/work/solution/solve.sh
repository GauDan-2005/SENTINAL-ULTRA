#!/usr/bin/env bash
# Oracle: apply golden.patch, forward only and idempotent.
# A second invocation is a no-op rather than an inversion, because the platform
# runs this three times.
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
set -euo pipefail

cd /app

PATCH=/solution/golden.patch

# 1. Idempotency probe: if the reverse of the patch fits, the patch is already in.
if git apply -p1 --reverse --check --whitespace=nowarn "$PATCH" 2>/dev/null; then
  echo "golden.patch is already applied; nothing to do."
  exit 0
fi

# 2. Plain forward apply.
if git apply -p1 --whitespace=nowarn "$PATCH" 2>/dev/null; then
  exit 0
fi

# 3. Forward apply with three-way merge, which resolves context drift the plain
#    apply will not. This still applies forward and cannot invert the tree.
if git apply -p1 --3way --whitespace=nowarn "$PATCH"; then
  exit 0
fi

# 4. Loud failure. Never a reverse apply, which would undo a correct tree and
#    report success while doing it.
echo "ERROR: golden.patch did not apply cleanly." >&2
exit 1
