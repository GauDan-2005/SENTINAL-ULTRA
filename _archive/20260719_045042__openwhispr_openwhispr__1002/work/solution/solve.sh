#!/usr/bin/env bash
# Oracle entrypoint. Forward-only and idempotent: applying it twice leaves the
# tree solved rather than reverting it. The platform runs the oracle three
# times, so a reverse-apply fallback here would undo the solution on run two.
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
set -euo pipefail

cd /app

PATCH=/solution/golden.patch

# 1. Idempotency probe. If the reverse of the patch fits the tree, the patch is
#    already applied and there is nothing to do.
if git apply -p1 --reverse --check --whitespace=nowarn "$PATCH" 2>/dev/null; then
  echo "golden.patch is already applied; nothing to do."
  exit 0
fi

# 2. Plain forward apply.
if git apply -p1 --whitespace=nowarn "$PATCH" 2>/dev/null; then
  exit 0
fi

# 3. Forward apply with three-way merge, for context drift a plain apply refuses.
if git apply -p1 --3way --whitespace=nowarn "$PATCH"; then
  exit 0
fi

# 4. Loud failure. Never reverse-apply as a fallback.
echo "ERROR: golden.patch did not apply cleanly." >&2
exit 1
