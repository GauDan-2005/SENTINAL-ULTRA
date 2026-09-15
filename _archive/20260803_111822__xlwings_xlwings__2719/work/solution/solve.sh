#!/usr/bin/env bash
# Forward-only and idempotent: applying twice leaves the tree solved, and a
# patch that will not apply fails loudly instead of reverting anything.
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
set -euo pipefail
cd /app

# Idempotency probe: if the REVERSE of the patch fits, the patch is already in.
if git apply -p1 --reverse --check --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
  echo "golden.patch is already applied; nothing to do."
  exit 0
fi

if git apply -p1 --whitespace=nowarn /solution/golden.patch 2>/dev/null; then
  exit 0
fi

# --3way resolves context drift; it still applies FORWARD, so it cannot invert.
if git apply -p1 --3way --whitespace=nowarn /solution/golden.patch; then
  exit 0
fi

echo "ERROR: golden.patch did not apply cleanly." >&2
exit 1
