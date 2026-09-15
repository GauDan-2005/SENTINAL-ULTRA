#!/usr/bin/env bash
# Apply the reference solution.
#
# Forward-only, idempotent, and carrying no dependency on /app being a git
# repository that git is willing to operate on.
#
# Two properties this has to hold, both learned the expensive way:
#
#   * It must never reverse-apply as a fallback. Doing so turns a solved tree
#     back into an unsolved one on a second invocation, and reports success.
#   * It must not need `git apply --3way`, which is the one git path that
#     requires a recognised repository. It fails with "'--3way' outside a
#     repository" whenever git declines the workspace, and git declines it both
#     when .git is absent and when the ownership is distrusted. patch(1) has no
#     notion of a repository at all, so it is the fallback.
#
# Plain `git apply` is tried first because it is atomic: all hunks or none.
# patch(1) is not atomic, so it only runs if git could not do the job.
set -uo pipefail
cd /app

PATCH_FILE=/solution/golden.patch

if [ ! -f "$PATCH_FILE" ]; then
  echo "ERROR: $PATCH_FILE not found." >&2
  exit 1
fi

# --- already applied? then the reverse of the patch is what fits the tree ---
if git apply -p1 --reverse --check --whitespace=nowarn "$PATCH_FILE" >/dev/null 2>&1; then
  echo "golden.patch is already applied; nothing to do."
  exit 0
fi
if command -v patch >/dev/null 2>&1 \
   && patch -p1 -R --dry-run --batch --force <"$PATCH_FILE" >/dev/null 2>&1; then
  echo "golden.patch is already applied; nothing to do."
  exit 0
fi

# --- forward apply ---
if git apply -p1 --whitespace=nowarn "$PATCH_FILE" 2>/dev/null; then
  echo "golden.patch applied with git apply."
  exit 0
fi
if command -v patch >/dev/null 2>&1 \
   && patch -p1 --forward --batch <"$PATCH_FILE"; then
  echo "golden.patch applied with patch."
  exit 0
fi

echo "ERROR: golden.patch did not apply cleanly." >&2
exit 1
