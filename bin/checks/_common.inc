# shellcheck shell=bash
# Shared helpers for bin/checks/*.sh — sourced, never run.
#
# Deliberately named .inc so that `bin/preflight.sh` globbing bin/checks/*.sh
# does not pick it up as a check. If something runs it anyway, the guard below
# makes that a no-op rather than a crash.
#
# Contract every check follows:
#   argv[1] = a task dir (tasks/<name>), a bundle dir (the one holding task.toml)
#             or a zip. Optional leading --work / --zip selects the source.
#   stdout  = one line per check: "PASS|FAIL|WARN|SKIP <check-id> <message>"
#   exit    = 0 all good, 1 a real defect was found, 2 the check could not run
#
# Thresholds come from facts.yml at the workspace root when it exists. The
# defaults below are the same numbers and exist only so a check still runs on a
# workspace where facts.yml has not been created yet.

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  echo "SKIP _common not a check, this file is sourced by the others"
  exit 0
fi

set -euo pipefail

SENTINEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SENTINEL_ROOT

_N_PASS=0
_N_FAIL=0
_N_WARN=0
_N_SKIP=0
_TMPDIRS=()

# _VERDICTS holds "<verdict> <id>" for every emitted line so a check can tally a
# subset of its own ids afterwards (10-static needs "N of 20 platform checks").
_VERDICTS=()

pass() { printf 'PASS %s %s\n' "$1" "${2-}"; _N_PASS=$((_N_PASS + 1)); _VERDICTS+=("PASS $1"); }
fail() { printf 'FAIL %s %s\n' "$1" "${2-}"; _N_FAIL=$((_N_FAIL + 1)); _VERDICTS+=("FAIL $1"); }
warn() { printf 'WARN %s %s\n' "$1" "${2-}"; _N_WARN=$((_N_WARN + 1)); _VERDICTS+=("WARN $1"); }
skip() { printf 'SKIP %s %s\n' "$1" "${2-}"; _N_SKIP=$((_N_SKIP + 1)); _VERDICTS+=("SKIP $1"); }

# tally <id-prefix> — echoes "<not-failed> <total>" for ids under that prefix.
tally() {
  local prefix="$1" total=0 ok=0 v
  for v in ${_VERDICTS+"${_VERDICTS[@]}"}; do
    case "${v#* }" in
      "$prefix"*) total=$((total + 1)); case "$v" in FAIL*) ;; *) ok=$((ok + 1)) ;; esac ;;
    esac
  done
  printf '%d %d\n' "$ok" "$total"
}

# note() prints an unprefixed detail line. Used for evidence under a FAIL
# (the sha of a dangling blob, the offending source line) so the machine
# readable PASS/FAIL lines stay one per check.
note() { printf '     %s\n' "$*"; }

summary() {
  local extra=""
  [ "$_N_WARN" -gt 0 ] && extra=" ($_N_WARN warning$([ "$_N_WARN" -eq 1 ] || echo s))"
  printf '%d passed, %d failed, %d skipped%s\n' "$_N_PASS" "$_N_FAIL" "$_N_SKIP" "$extra"
  if [ "$_N_FAIL" -gt 0 ]; then return 1; fi
  if [ "$_N_PASS" -eq 0 ] && [ "$_N_SKIP" -gt 0 ]; then return 2; fi
  return 0
}

_cleanup_tmpdirs() {
  local d
  for d in ${_TMPDIRS+"${_TMPDIRS[@]}"}; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf -- "$d"
  done
}
trap _cleanup_tmpdirs EXIT

# One session directory, handed out as numbered subdirectories. mktempdir is
# usually called inside a command substitution, and an array appended to in a
# subshell does not survive, so registering the parent once is what makes the
# EXIT trap actually clean up.
_SESSION_TMP="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-check.XXXXXX")"
_TMPDIRS+=("$_SESSION_TMP")
echo 0 > "$_SESSION_TMP/.seq"
mktempdir() {
  local n
  n=$(( $(cat "$_SESSION_TMP/.seq" 2>/dev/null || echo 0) + 1 ))
  echo "$n" > "$_SESSION_TMP/.seq"
  mkdir -p "$_SESSION_TMP/d$n"
  printf '%s' "$_SESSION_TMP/d$n"
}

need() {
  # need <tool> ; returns 1 when the tool is absent so the caller can SKIP
  command -v "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------- facts.yml --

# fact <key> <default> — reads facts.yml at the workspace root. Tolerant of both
# shapes the file might take: a flat "key: value" mapping, or a list of entries
# each carrying id/value. Lists come back space separated.
fact() {
  local key="$1" default="${2-}"
  local f="$SENTINEL_ROOT/facts.yml"
  if [ ! -f "$f" ] || ! need python3; then
    printf '%s' "$default"
    return 0
  fi
  python3 - "$f" "$key" "$default" <<'PY' 2>/dev/null || printf '%s' "$default"
import sys
path, key, default = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    import yaml
    data = yaml.safe_load(open(path, encoding="utf-8")) or {}
except Exception:
    print(default, end="")
    raise SystemExit(0)

def render(v):
    if isinstance(v, (list, tuple)):
        return " ".join(str(x) for x in v)
    if isinstance(v, bool):
        return "true" if v else "false"
    return str(v)

def walk(node):
    # flat mapping: key -> value, or key -> {value: ...}
    if isinstance(node, dict):
        if key in node:
            v = node[key]
            if isinstance(v, dict) and "value" in v:
                return v["value"]
            return v
        if node.get("id") == key and "value" in node:
            return node["value"]
        for v in node.values():
            r = walk(v)
            if r is not None:
                return r
    elif isinstance(node, list):
        for v in node:
            r = walk(v)
            if r is not None:
                return r
    return None

got = walk(data)
print(default if got is None else render(got), end="")
PY
}

# ------------------------------------------------------------ bundle lookup --

# BUNDLE_DIR  the directory holding task.toml (a work/ copy or a zip extraction)
# BUNDLE_SRC  "work" or "zip"
# TASK_DIR    the tasks/<name> directory when one could be identified, else ""
# ZIP_PATH    the zip when one was found, else ""

BUNDLE_DIR=""
BUNDLE_SRC=""
TASK_DIR=""
ZIP_PATH=""

_find_zip() {
  local taskdir="$1" newest=""
  local f
  for f in "$taskdir"/upload/*.zip; do
    [ -f "$f" ] || continue
    if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f"; fi
  done
  printf '%s' "$newest"
}

# resolve_input <prefer: zip|work|auto> <arg>
resolve_input() {
  local prefer="$1" arg="$2"
  [ -n "$arg" ] || return 2

  if [ -f "$arg" ] && case "$arg" in *.zip) true ;; *) false ;; esac; then
    ZIP_PATH="$arg"
    TASK_DIR="$(cd "$(dirname "$arg")/.." 2>/dev/null && pwd || true)"
  elif [ -d "$arg" ]; then
    if [ -f "$arg/task.toml" ]; then
      BUNDLE_DIR="$(cd "$arg" && pwd)"
      BUNDLE_SRC="work"
      TASK_DIR="$(cd "$arg/.." 2>/dev/null && pwd || true)"
      ZIP_PATH="$(_find_zip "$TASK_DIR")"
    elif [ -f "$arg/work/task.toml" ]; then
      TASK_DIR="$(cd "$arg" && pwd)"
      BUNDLE_DIR="$TASK_DIR/work"
      BUNDLE_SRC="work"
      ZIP_PATH="$(_find_zip "$TASK_DIR")"
    elif [ -f "$arg/download/original/task.toml" ]; then
      TASK_DIR="$(cd "$arg" && pwd)"
      BUNDLE_DIR="$TASK_DIR/download/original"
      BUNDLE_SRC="work"
      ZIP_PATH="$(_find_zip "$TASK_DIR")"
    else
      return 2
    fi
  else
    return 2
  fi

  # auto prefers the zip whenever one exists. Both times a static check failed on
  # a real upload the working copy looked clean and the zip did not, so the zip is
  # the artifact worth checking. Pass --work explicitly during the fix loop.
  if [ "$prefer" = "zip" ] || { [ "$prefer" = "auto" ] && [ -n "$ZIP_PATH" ]; }; then
    [ -n "$ZIP_PATH" ] || return 3
    need unzip || return 4
    local d
    d="$(mktempdir)"
    unzip -qq -o "$ZIP_PATH" -d "$d" || return 5
    if [ -f "$d/task.toml" ]; then
      BUNDLE_DIR="$d"
    elif [ -f "$d/task/task.toml" ]; then
      BUNDLE_DIR="$d/task"     # a wrappered zip; 30-package reports that separately
    else
      BUNDLE_DIR="$d"
    fi
    BUNDLE_SRC="zip"
  fi
  [ -n "$BUNDLE_DIR" ] || return 2
  return 0
}

# strip a leading --work / --zip / --auto off "$@" into PREFER
PREFER="auto"
parse_mode() {
  case "${1-}" in
    --zip)  PREFER="zip";  return 0 ;;
    --work) PREFER="work"; return 0 ;;
    --auto) PREFER="auto"; return 0 ;;
    *) return 1 ;;
  esac
}

# report_source — say which artifact the check actually read, and warn when the
# zip is older than the working copy it was supposed to be built from.
report_source() {
  if [ "$BUNDLE_SRC" = "zip" ]; then
    note "source: $ZIP_PATH (extracted)"
    if [ -n "$TASK_DIR" ] && [ -d "$TASK_DIR/work" ] && [ -f "$ZIP_PATH" ]; then
      local newer
      newer="$(find "$TASK_DIR/work" -type f -newer "$ZIP_PATH" -not -path '*/.git/*' -print -quit 2>/dev/null || true)"
      if [ -n "$newer" ]; then
        warn "input.stale-zip" "work/ has changed since the zip was built (${newer#"$TASK_DIR/"}), re-zip before trusting this run"
      fi
    fi
  else
    note "source: $BUNDLE_DIR (working copy, not the zip)"
  fi
}

usage_die() {
  # the SKIP line goes to stdout so an orchestrator capturing stdout still sees
  # one line for this check; the usage hint goes to stderr
  echo "SKIP ${1} ${2}"
  echo "0 passed, 0 failed, 1 skipped"
  echo "usage: $(basename "$0") [--work|--zip] <task-dir|bundle-dir|zip>" >&2
  exit 2
}
