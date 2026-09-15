#!/usr/bin/env bash
# new-review.sh <original-zip> <original-dir-name> --branch <branch> [--submitted <zip>] [--go]
#
# Section 13 F0 bootstrap. The original task ZIP is always supplied. The artifact under review is
# the submitted ZIP when the reviewer page provides one, otherwise the original ZIP itself.
# `download/original/` is always that reviewed artifact and `work/` copies it for static inspection.
# `download/seed/` is created only when a submitted ZIP exists, and then contains the original task.
#
# Branch contract:
#   fixable              submitted ZIP is required
#   invalid              submitted ZIP is optional
#   valid-as-is          submitted ZIP must be absent
#   invalid-difficulty   submitted ZIP must be absent
#   other                submitted ZIP must be absent
#
# It is a dry run unless --go is passed. The compact task.md scaffold is the twin of the record in
# .claude/rules/14-reviewer-workflow.md. The timer starts only after bootstrap and page evidence are ready.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
usage: new-review.sh <original-zip> <original-dir-name> --branch <branch> [options]
  --branch <branch>  fixable | invalid | valid-as-is | invalid-difficulty | other
  --submitted <zip>  submitter's re-uploaded ZIP; required only for fixable
  --go               actually bootstrap instead of printing the plan
EOF
}

ORIGINAL=""; SUBMITTED=""; NAME=""; BRANCH=""; GO=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --branch) BRANCH="${2:-}"; shift 2 ;;
    --submitted) SUBMITTED="${2:-}"; shift 2 ;;
    --go) GO=1; shift ;;
    -*) echo "SKIP unknown argument: $1" >&2; exit 2 ;;
    *)
      if [ -z "$ORIGINAL" ]; then ORIGINAL="$1"
      elif [ -z "$NAME" ]; then NAME="$1"
      else echo "SKIP unexpected argument: $1" >&2; exit 2
      fi
      shift ;;
  esac
done

[ -n "$ORIGINAL" ] && [ -n "$NAME" ] && [ -n "$BRANCH" ] || { usage; exit 2; }
[ -f "$ORIGINAL" ] || { echo "SKIP no such original zip: $ORIGINAL" >&2; exit 2; }
[ -z "$SUBMITTED" ] || [ -f "$SUBMITTED" ] || { echo "SKIP no such submitted zip: $SUBMITTED" >&2; exit 2; }
command -v unzip >/dev/null || { echo "SKIP unzip not installed" >&2; exit 2; }

case "${BRANCH,,}" in
  fixable) BRANCH="fixable" ;;
  invalid|invalid-not-fixable|invalid/not-fixable) BRANCH="invalid" ;;
  valid-as-is|valid) BRANCH="valid-as-is" ;;
  invalid-difficulty) BRANCH="invalid-difficulty" ;;
  other) BRANCH="other" ;;
  *) echo "SKIP unknown review branch: $BRANCH" >&2; usage; exit 2 ;;
esac

case "$BRANCH" in
  fixable)
    [ -n "$SUBMITTED" ] || { echo "SKIP fixable review requires --submitted <zip>" >&2; exit 2; }
    ;;
  valid-as-is|invalid-difficulty|other)
    [ -z "$SUBMITTED" ] || { echo "SKIP $BRANCH review must not receive --submitted" >&2; exit 2; }
    ;;
  invalid) ;;
esac

REVIEW_ZIP="${SUBMITTED:-$ORIGINAL}"
REVIEW_KIND="original"
[ -n "$SUBMITTED" ] && REVIEW_KIND="submitted"
RD="$ROOT_DIR/review_tasks/$NAME"

root_source() {
  local source="$1"
  [ -n "$source" ] || { printf 'NONE'; return; }
  [ "$(cd "$(dirname "$source")" && pwd)" = "$ROOT_DIR" ] && printf '%s' "$source" || printf 'NONE'
}
ROOT_ORIGINAL="$(root_source "$ORIGINAL")"
ROOT_SUBMITTED="$(root_source "$SUBMITTED")"

echo "-- plan"
echo "   review folder   $RD"
echo "   branch          $BRANCH"
echo "   original zip    $ORIGINAL"
echo "   submitted zip   ${SUBMITTED:-<not supplied for this branch>}"
echo "   review artifact $REVIEW_ZIP ($REVIEW_KIND)"
echo
if [ "$GO" -eq 0 ]; then
  cat <<EOF
DRY RUN. Nothing was written. It would:
  bin/new-task.sh "$REVIEW_ZIP" "$NAME" --dest review_tasks --go
      -> download/original (the $REVIEW_KIND artifact, frozen), work/
  ${SUBMITTED:+copy "$ORIGINAL" to $RD/download/ and extract it by contents to download/seed/}
  ${SUBMITTED:+chmod -R a-w $RD/download/seed}
  scaffold $RD/task.md with the compact Section 13 timed-review record
  print the INDEX.md Reviews row

Re-run with --go to do it.
EOF
  exit 0
fi

# ---- 1. the artifact actually under review ----------------------------------
"$ROOT_DIR/bin/new-task.sh" "$REVIEW_ZIP" "$NAME" --dest review_tasks --go || exit 1

# ---- 2. the original baseline, only when a submitted artifact exists --------
if [ -n "$SUBMITTED" ]; then
  [ -e "$RD/download/$(basename "$ORIGINAL")" ] || cp "$ORIGINAL" "$RD/download/"
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  unzip -qX "$ORIGINAL" -d "$TMP"
  TREE="$(cd "$TMP" && find . -name task.toml -not -path '*/node_modules/*' \
            -exec sh -c '[ -f "$(dirname "$1")/instruction.md" ] && dirname "$1"' _ {} \; \
          | head -1)"
  if [ -z "$TREE" ]; then
    echo "FAIL the original zip holds no directory with task.toml beside instruction.md" >&2
    exit 1
  fi
  rm -rf "$RD/download/seed"
  mkdir -p "$RD/download/seed"
  cp -a "$TMP/$TREE/." "$RD/download/seed/"
  chmod -R a-w "$RD/download/seed"
  echo "PASS original extracted from '$TREE' and frozen at $RD/download/seed"
else
  echo "PASS original zip is the reviewed artifact; no submitted ZIP or seed baseline is required"
fi

# ---- 3. task.md scaffold ----------------------------------------------------
if [ ! -s "$RD/task.md" ] || ! grep -q 'Review timer' "$RD/task.md" 2>/dev/null; then
  {
    echo "# Peer review - $NAME"
    echo
    echo "Section 13, \`.claude/rules/14-reviewer-workflow.md\`. Bootstrapped $(date +%Y-%m-%d). The review timer starts only after page evidence is ready."
    echo
    echo "- Branch: $BRANCH"
    echo "- Original task zip: $(basename "$ORIGINAL")"
    if [ -n "$SUBMITTED" ]; then
      echo "- Submitted task zip: $(basename "$SUBMITTED")"
    else
      echo "- Submitted task zip: NOT SUPPLIED"
    fi
    echo "- Reviewed artifact: $(basename "$REVIEW_ZIP") ($REVIEW_KIND)"
    echo "- Root original zip: $ROOT_ORIGINAL"
    echo "- Root submitted zip: $ROOT_SUBMITTED"
    echo "- sha256: \`$(sha256sum "$REVIEW_ZIP" | cut -c1-16)\` reviewed${SUBMITTED:+, \`$(sha256sum "$ORIGINAL" | cut -c1-16)\` original}"
    echo "- Track: timed-static-v1"
    echo "- Review UUID: NOT SUPPLIED. Copy the exact UUID from the reviewer page before deferred maintenance."
    echo "- Round: 1"
    echo "- Timer: NOT STARTED. Start only after the current reviewer page, rebuttal, and reviewed artifact are ready."
    echo
    # TWIN of the compact record in .claude/rules/14-reviewer-workflow.md. Edit both together.
    for h in "Review timer" "Evidence reviewed" "Previous reviewer feedback" \
             "Fast static gate" "In-depth extension" "Rubric tally" "Form-ready" \
             "Deferred maintenance"; do
      echo "## $h"; echo; echo "TODO"; echo
    done
  } > "$RD/task.md"
  echo "PASS scaffolded $RD/task.md"
fi

echo
echo "-- INDEX.md row to paste under ## Reviews"
echo "| [$NAME](review_tasks/$NAME/task.md) | $(basename "$REVIEW_ZIP" | cut -c1-8) | TODO repo/PR | - | - | \`review-claimed\` | 1 | - | $BRANCH, reviewed $REVIEW_KIND artifact |"
