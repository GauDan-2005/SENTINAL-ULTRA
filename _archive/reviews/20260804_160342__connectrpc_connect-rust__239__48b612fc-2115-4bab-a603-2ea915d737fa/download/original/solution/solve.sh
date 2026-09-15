#!/usr/bin/env bash
# Oracle: apply solution/golden.patch forward. Never reverse it.
set -eu

WORKSPACE=""
for p in /app /testbed /workspace; do
  if [ -d "$p" ]; then WORKSPACE="$p"; break; fi
done
if [ -z "$WORKSPACE" ]; then
  echo "ERROR: could not resolve workspace" >&2
  exit 2
fi
cd "$WORKSPACE"

PATCH=""
for c in /solution/golden.patch "$(cd "$(dirname "$0")" && pwd)/golden.patch"; do
  if [ -f "$c" ]; then PATCH="$c"; break; fi
done
if [ -z "$PATCH" ]; then
  echo "ERROR: could not find golden.patch" >&2
  exit 2
fi

if git apply -p1 --whitespace=nowarn --check "$PATCH" 2>/dev/null; then
  git apply -p1 --whitespace=nowarn "$PATCH"
  echo "golden.patch applied"
  exit 0
fi

# Reverse --check only asks "is this already applied?"; it writes nothing.
if git apply -p1 --whitespace=nowarn --reverse --check "$PATCH" 2>/dev/null; then
  echo "golden.patch already applied; nothing to do"
  exit 0
fi

if git apply -p1 --3way --whitespace=nowarn "$PATCH"; then
  echo "golden.patch applied (3-way)"
  exit 0
fi

echo "ERROR: could not apply golden.patch forward" >&2
exit 1
