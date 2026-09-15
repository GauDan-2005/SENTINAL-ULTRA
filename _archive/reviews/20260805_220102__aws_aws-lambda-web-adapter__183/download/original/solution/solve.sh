#!/usr/bin/env bash
# Oracle: restore the solved state. One strict forward apply — no --3way, no
# reverse-apply fallback. IDEMPOTENT: if the patch is already applied a reverse
# --check succeeds, so a rerun does nothing and exits 0. It only ever *checks*
# for the reverse; it never reverse-applies, so the solution is never undone.
set -e
cd /app
if git apply --reverse --check /solution/golden.patch >/dev/null 2>&1; then
  echo "solution already applied; nothing to do"
  exit 0
fi
git apply --whitespace=nowarn /solution/golden.patch
