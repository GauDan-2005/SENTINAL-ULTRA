#!/usr/bin/env bash
# Re-exec under bash when the harness hands this script to a POSIX shell.
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
set -euo pipefail

cd /app

PATCH="/solution/golden.patch"

# Already applied? The reverse of the patch fitting is the probe for that, and it
# is only ever a --check. The oracle is run more than once against the same tree,
# so a second run has to be a no-op rather than an undo.
if git apply -p1 --reverse --check --whitespace=nowarn "$PATCH" 2>/dev/null; then
  echo "golden.patch is already applied; nothing to do."
  exit 0
fi

if git apply -p1 --whitespace=nowarn "$PATCH" 2>/dev/null; then
  exit 0
fi

# Forward apply again with three-way merging, which resolves context drift the
# plain apply refuses.
if git apply -p1 --3way --whitespace=nowarn "$PATCH"; then
  exit 0
fi

echo "ERROR: golden.patch did not apply cleanly." >&2
exit 1
