#!/usr/bin/env bash
set -euo pipefail
cd /app

PATCH=/solution/golden.patch

# Already applied: reverse --check succeeds → no-op (do not mutate the tree).
if git apply --check --reverse --whitespace=nowarn "$PATCH" 2>/dev/null; then
  echo "Patch already applied: $PATCH"
  exit 0
fi

# Forward-only apply. No -R / --3way.
git apply --whitespace=nowarn "$PATCH"
echo "Applied patch: $PATCH"
exit 0
