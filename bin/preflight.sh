#!/usr/bin/env bash
# preflight.sh — run every staged check in bin/checks/ against one task bundle.
#
# CLAUDE.md's pre-upload checklist is carried in prose, so every item is skippable
# and the skipped ones are the ones that cost a round. This runs them all, in a
# fixed order, with one verdict at the end. It orchestrates only: the checks live
# in bin/checks/NN-<name>.sh and are run in numeric order, whatever is installed.
#
# Usage:
#   bin/preflight.sh [options] <target>
#
#   <target> is any of
#     a bundle directory        (has task.toml, environment/, solution/, tests/)
#     a task folder             (has work/ and download/) - work/ is checked
#     a wrapper directory       (holds the bundle under task/, seed/ or *_harborized/task/)
#     a .zip                    (extracted to a temp dir, checked, cleaned up)
#
# Options:
#   --work            force the task folder's work/ tree
#   --zip             force the built zip in the task folder's upload/
#   --only <pat>      run only checks whose filename contains <pat>
#   --skip <pat>      skip checks whose filename contains <pat>
#   --review-fast     run the ZIP-only reviewer static profile: 10, 20, 30 and 40
#   --list            print the checks that would run, then stop
#   -v, --verbose     stream every line each check prints
#   -h, --help        this text
#
# What each check receives:
#   $1                    the resolved bundle directory (or the zip, for --zip)
#   $PREFLIGHT_BUNDLE_DIR the extracted or on-disk bundle root
#   $PREFLIGHT_ZIP        the zip, when the target was or produced one
#   $PREFLIGHT_TASK_DIR   the task folder, when the target was one
#   $FACTS_FILE           facts.yml. Thresholds come from there, never from a
#                         number typed into a check.
#
# Exit codes (the house contract - never conflate 1 and 2):
#   0  every check passed
#   1  at least one check found a real defect. Do not zip, do not upload
#   2  a check could not run (missing tool, missing input, no checks installed),
#      and nothing failed outright
#
# A stage that could not run is never reported as a pass. An empty bin/checks/
# exits 2, not 0: silence is not evidence.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_DIR="$ROOT/bin/checks"
FACTS_FILE="${FACTS_FILE:-$ROOT/facts.yml}"

ONLY=""; SKIP_PAT=""; REVIEW_FAST=0; VERBOSE=0; LIST=0; MODE="auto"; TARGET=""
TMPDIR_EXTRACT=""

die() { echo "SKIP preflight $*" >&2; exit 2; }

cleanup() {
  if [ -n "$TMPDIR_EXTRACT" ] && [ -d "$TMPDIR_EXTRACT" ]; then
    rm -rf "$TMPDIR_EXTRACT"
  fi
}
trap cleanup EXIT

while [ $# -gt 0 ]; do
  case "$1" in
    --work) MODE="work"; shift ;;
    --zip)  MODE="zip";  shift ;;
    --only) ONLY="${2:-}"; shift 2 ;;
    --skip) SKIP_PAT="${2:-}"; shift 2 ;;
    --review-fast) REVIEW_FAST=1; shift ;;
    --list) LIST=1; shift ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help) sed -n '2,46p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$TARGET" ] || die "more than one target given"; TARGET="$1"; shift ;;
  esac
done

[ -n "$TARGET" ] || die "no target given. Usage: bin/preflight.sh [options] <task-dir|bundle-dir|zip>"
[ -e "$TARGET" ] || die "target does not exist: $TARGET"
if [ "$REVIEW_FAST" = "1" ]; then
  [ -z "$ONLY" ] && [ -z "$SKIP_PAT" ] || die "--review-fast cannot be combined with --only or --skip"
  case "$TARGET" in *.zip) ;; *) die "--review-fast requires the submitted .zip, not a work tree" ;; esac
fi

# ── resolve the target ───────────────────────────────────────────────────────
is_bundle() { [ -f "$1/task.toml" ] && [ -d "$1/tests" ]; }

BUNDLE_DIR=""; ZIP=""; TASK_DIR=""

newest_zip() {
  # newest *.zip under $1, without relying on ls parsing
  find "$1" -maxdepth 1 -name '*.zip' -type f -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -n1 | cut -d' ' -f2-
}

extract_zip() {
  command -v unzip >/dev/null 2>&1 || die "unzip not found, cannot check a zip"
  TMPDIR_EXTRACT="$(mktemp -d "${TMPDIR:-/tmp}/preflight-XXXXXX")"
  unzip -q "$1" -d "$TMPDIR_EXTRACT" || die "could not extract $1"
  # the zip should unpack flat; tolerate a single wrapper directory
  if ! is_bundle "$TMPDIR_EXTRACT"; then
    local inner
    inner="$(find "$TMPDIR_EXTRACT" -mindepth 1 -maxdepth 1 -type d | head -n1)"
    if [ -n "$inner" ] && is_bundle "$inner"; then
      TMPDIR_EXTRACT_INNER="$inner"
    fi
  fi
  echo "${TMPDIR_EXTRACT_INNER:-$TMPDIR_EXTRACT}"
}

case "$TARGET" in
  *.zip)
    if [ "$MODE" = "work" ]; then die "--work given but the target is a zip"; fi
    ZIP="$(cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")"
    BUNDLE_DIR="$(extract_zip "$ZIP")"
    ;;
  *)
    TARGET="$(cd "$TARGET" && pwd)"
    if [ "$MODE" = "zip" ]; then
      cand=""
      if [ -d "$TARGET/upload" ]; then cand="$(newest_zip "$TARGET/upload")"; fi
      [ -n "$cand" ] || cand="$(newest_zip "$TARGET")"
      [ -n "$cand" ] || die "--zip given but no .zip found under $TARGET"
      ZIP="$cand"; TASK_DIR="$TARGET"
      BUNDLE_DIR="$(extract_zip "$ZIP")"
    elif is_bundle "$TARGET"; then
      BUNDLE_DIR="$TARGET"
      case "$(basename "$TARGET")" in
        work|task|seed) TASK_DIR="$(dirname "$TARGET")" ;;
      esac
    elif is_bundle "$TARGET/work"; then
      BUNDLE_DIR="$TARGET/work"; TASK_DIR="$TARGET"
    elif is_bundle "$TARGET/task"; then
      BUNDLE_DIR="$TARGET/task"; TASK_DIR="$TARGET"
    elif is_bundle "$TARGET/seed"; then
      # docs/harbor-framework.md: a download may wrap the task files in task/ OR seed/
      BUNDLE_DIR="$TARGET/seed"; TASK_DIR="$TARGET"
    else
      die "no bundle found at $TARGET (looked for task.toml + tests/ here, in work/, task/ and seed/)"
    fi
    ;;
esac

[ -n "$BUNDLE_DIR" ] || die "could not resolve a bundle directory from $TARGET"

# ── collect the checks ───────────────────────────────────────────────────────
FAST_CHECKS="10-static.sh 20-git.sh 30-package.sh 40-grader.sh"
CHECKS=()
if [ -d "$CHECK_DIR" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base="$(basename "$f")"
    if [ "$REVIEW_FAST" = "1" ] && [[ " $FAST_CHECKS " != *" $base "* ]]; then continue; fi
    if [ -n "$ONLY" ] && [[ "$base" != *"$ONLY"* ]]; then continue; fi
    if [ -n "$SKIP_PAT" ] && [[ "$base" == *"$SKIP_PAT"* ]]; then continue; fi
    CHECKS+=("$f")
  done < <(find "$CHECK_DIR" -maxdepth 1 -name '*.sh' -type f | LC_ALL=C sort)
fi

# stage 0: the pristine baseline, when the tooling and the manifest are both there
PRISTINE="$ROOT/bin/pristine-verify.sh"
RUN_PRISTINE=0
if [ "$REVIEW_FAST" != "1" ] && [ -x "$PRISTINE" ] && [ -n "$TASK_DIR" ] && [ -f "$TASK_DIR/download/original.manifest.tsv" ]; then
  if [ -z "$ONLY" ] || [[ "pristine-verify.sh" == *"$ONLY"* ]]; then
    if [ -z "$SKIP_PAT" ] || [[ "pristine-verify.sh" != *"$SKIP_PAT"* ]]; then
      RUN_PRISTINE=1
    fi
  fi
fi

if [ "$LIST" = "1" ]; then
  echo "bundle: $BUNDLE_DIR"
  if [ -n "$ZIP" ]; then echo "zip:    $ZIP"; fi
  if [ "$RUN_PRISTINE" = "1" ]; then echo "  00 pristine-verify.sh"; fi
  for c in "${CHECKS[@]:-}"; do
    if [ -n "$c" ]; then echo "  -- $(basename "$c")"; fi
  done
  if [ "${#CHECKS[@]}" -eq 0 ]; then echo "  (no checks installed in bin/checks/)"; fi
  exit 0
fi

if [ "${#CHECKS[@]}" -eq 0 ] && [ "$RUN_PRISTINE" = "0" ]; then
  if [ -n "$ONLY" ] || [ -n "$SKIP_PAT" ]; then
    echo "SKIP preflight no check matched the --only/--skip filter - nothing was verified"
  else
    echo "SKIP preflight no checks installed in bin/checks/ - nothing was verified"
  fi
  echo "0 passed, 0 failed, 1 skipped"
  exit 2
fi

# ── run them ─────────────────────────────────────────────────────────────────
export FACTS_FILE
export PREFLIGHT_BUNDLE_DIR="$BUNDLE_DIR"
export PREFLIGHT_ZIP="$ZIP"
export PREFLIGHT_TASK_DIR="$TASK_DIR"
export PREFLIGHT_REVIEW_FAST="$REVIEW_FAST"

passed=0; failed=0; skipped=0; warns=0
failed_names=()

echo "preflight: $BUNDLE_DIR"
if [ -n "$ZIP" ]; then echo "preflight: zip $ZIP"; fi

run_one() {
  local script="$1" arg="$2"
  local name; name="$(basename "$script")"; name="${name%.sh}"
  local out rc=0
  set +e
  out="$(bash "$script" "$arg" 2>&1)"
  rc=$?
  set -e
  local w; w="$(printf '%s\n' "$out" | grep -c '^WARN ' || true)"
  warns=$((warns + w))
  local wtxt=""
  if [ "$w" -gt 0 ]; then wtxt=" ($w warning(s))"; fi
  if { [ "$VERBOSE" = "1" ] || [ "$rc" != "0" ]; } && [ -n "$out" ]; then
    printf '%s\n' "$out" | sed 's/^/      /'
  fi
  case "$rc" in
    0) passed=$((passed + 1)); echo "PASS $name ok$wtxt" ;;
    1) failed=$((failed + 1)); failed_names+=("$name"); echo "FAIL $name found a defect - see the lines above" ;;
    2) skipped=$((skipped + 1)); echo "SKIP $name could not run - see the lines above" ;;
    *) failed=$((failed + 1)); failed_names+=("$name"); echo "FAIL $name exited $rc, which is outside the 0/1/2 contract" ;;
  esac
}

if [ "$RUN_PRISTINE" = "1" ]; then
  run_one "$PRISTINE" "$TASK_DIR"
fi

for c in "${CHECKS[@]:-}"; do
  [ -n "$c" ] || continue
  if [ -n "$ZIP" ] && [[ "$(basename "$c")" == *package* ]]; then
    run_one "$c" "$ZIP"          # the packaging check wants the archive itself
  else
    run_one "$c" "$BUNDLE_DIR"
  fi
done

echo "OK=$passed FAIL=$failed WARN=$warns"
if [ "$failed" -gt 0 ]; then
  echo "blocking: ${failed_names[*]}"
fi
echo "$passed passed, $failed failed, $skipped skipped"

if [ "$failed" -gt 0 ]; then exit 1; fi
if [ "$skipped" -gt 0 ]; then exit 2; fi
exit 0
