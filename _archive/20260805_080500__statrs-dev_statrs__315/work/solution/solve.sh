#!/usr/bin/env bash
# Re-exec under bash if something handed this file to a POSIX shell. The shebang is only
# consulted when the file is executed directly, and this script uses bash arrays below.
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
set -euo pipefail
cd /app

PATCH=/solution/golden.patch

# 1. Idempotency probe. If the REVERSE of the patch fits, the patch is already applied,
#    so there is nothing to do. This is a --check probe and never writes to the tree.
if git apply -p1 --reverse --check --whitespace=nowarn "$PATCH" 2>/dev/null; then
  echo "golden.patch is already applied; nothing to do."
  exit 0
fi

# 2. Plain forward apply.
if git apply -p1 --whitespace=nowarn "$PATCH" 2>/dev/null; then
  echo "golden.patch applied."
  exit 0
fi

# 3. Forward apply with three-way merge, which resolves context drift the plain apply will not.
if git apply -p1 --3way --whitespace=nowarn "$PATCH"; then
  echo "golden.patch applied with --3way."
  exit 0
fi

# 4. Loud failure. Never reverse-apply as a fallback: that would undo a correct tree and
#    report success, which is what the previous version of this script did.
echo "ERROR: golden.patch did not apply cleanly." >&2
exit 1
