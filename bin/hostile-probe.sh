#!/usr/bin/env bash
# hostile-probe.sh - the coverage gate, with the break proven to have landed.
#
# The Quality Check's coverage axis is scored on one property: a broken or stub solution must
# fail at least one test. The probe that checks it has two assertions, not one:
#   (a) the break actually landed in the tree that ran, and
#   (b) the reward actually dropped.
# Without (a) a no-op edit reads as a passing gate. learning/verify-in-the-image.md records two
# probes that "passed" because the sed matched nothing.
#
# Usage:
#   bin/hostile-probe.sh <task-dir> --file src/ext/brotli.ts \
#       --break 's/quality: 1/quality: 6/' --expect-fail 'tests/ext/encoder.test.ts::ext - brotliCompressor' \
#       [--pattern 'quality: 1'] [--requirement "brotli defaults to quality 1"] [--record]
#
#   bin/hostile-probe.sh <task-dir> --delete src/ext/encoding/mod.ts --expect-fail '<test id>'
#
# The run order is the real one: solve.sh first, then the break, then the verifier. A probe on
# an unsolved tree measures nothing.
#
# Aim it at the requirement you are LEAST sure is tested, not the easiest one.
#
# Exit: 0 the break landed and the reward dropped to 0 with the named test failing,
#       1 the reward stayed 1.0 (that requirement is unenforced) or a different test failed,
#       2 cannot run, 3 THE BREAK DID NOT LAND (the probe measured nothing).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sanitize_tag() {
  printf '%s' "$1" | tr 'A-Z' 'a-z' | sed -e 's/[^a-z0-9]\+/-/g' -e 's/^-*//' -e 's/-*$//' | cut -c1-100
}

TASK_ARG=""; FILE=""; BREAK=""; DELETE=""; EXPECT=""; PATTERN=""; REQUIREMENT=""
IMAGE=""; RECORD=0; KEEP=0
SCRATCH_ROOT="${SENTINEL_SCRATCH:-${TMPDIR:-/tmp}}/sentinel-hostile-probe"
while [ $# -gt 0 ]; do
  case "$1" in
    --file)        FILE="${2:-}"; shift 2 ;;
    --break)       BREAK="${2:-}"; shift 2 ;;
    --delete)      DELETE="${2:-}"; shift 2 ;;
    --expect-fail) EXPECT="${2:-}"; shift 2 ;;
    --pattern)     PATTERN="${2:-}"; shift 2 ;;
    --requirement) REQUIREMENT="${2:-}"; shift 2 ;;
    --image)       IMAGE="${2:-}"; shift 2 ;;
    --record)      RECORD=1; shift ;;
    --keep)        KEEP=1; shift ;;
    --scratch)     SCRATCH_ROOT="${2:-}"; shift 2 ;;
    -h|--help)     sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)            echo "SKIP unknown argument: $1" >&2; exit 3 ;;
    *)             TASK_ARG="$1"; shift ;;
  esac
done

[ -n "$TASK_ARG" ] || { echo "SKIP usage: bin/hostile-probe.sh <task-dir> --file <path> --break <sed> --expect-fail <id>" >&2; exit 3; }
if [ -z "$DELETE" ] && { [ -z "$FILE" ] || [ -z "$BREAK" ]; }; then
  echo "SKIP give either --file with --break, or --delete" >&2; exit 3
fi
[ -n "$EXPECT" ] || { echo "SKIP --expect-fail <test id> is required: a probe that names no test proves nothing" >&2; exit 3; }

TASK_DIR="$(cd "$TASK_ARG" 2>/dev/null && pwd || true)"
[ -n "$TASK_DIR" ] || { echo "SKIP no such directory: $TASK_ARG" >&2; exit 3; }
case "$TASK_DIR" in
  */work|*/download/original|*/download/original/*)
    echo "FAIL point me at the task folder, not the working copy - the probe mutates its copy"
    exit 3 ;;
esac
TASK_NAME="$(basename "$TASK_DIR")"
case "$SCRATCH_ROOT" in "$ROOT"|"$ROOT"/*) echo "FAIL scratch must live outside the workspace"; exit 3 ;; esac

command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 || {
  echo "SKIP docker is unavailable - the hostile gate has to run in the task image"; exit 2; }

SCRATCH="$SCRATCH_ROOT/$TASK_NAME-$(date +%Y%m%d-%H%M%S)"
cleanup() { [ "$KEEP" = "1" ] || rm -rf "$SCRATCH"; }
trap cleanup EXIT
mkdir -p "$SCRATCH"

# ---- source: the zip if there is one, else work/ ------------------------------------------------
BASE="$SCRATCH/src"; mkdir -p "$BASE"
shopt -s nullglob; ZIPS=("$TASK_DIR/upload/"*.zip); shopt -u nullglob
if [ ${#ZIPS[@]} -gt 0 ] && command -v unzip >/dev/null 2>&1; then
  unzip -qq "${ZIPS[0]}" -d "$BASE"; SRC_KIND="zip (${ZIPS[0]##*/})"
elif [ -d "$TASK_DIR/work" ]; then
  cp -a "$TASK_DIR/work/." "$BASE/"; SRC_KIND="work/"
else
  echo "SKIP no zip and no work/ under $TASK_DIR"; exit 2
fi
for f in tests/test.sh tests/config.json solution/solve.sh environment/Dockerfile; do
  [ -e "$BASE/$f" ] || { echo "FAIL the bundle has no $f"; exit 2; }
done
chmod +x "$BASE/tests/test.sh" "$BASE/solution/solve.sh" 2>/dev/null || true

echo "# hostile-probe  $TASK_NAME"
echo "  source:       $SRC_KIND"
echo "  requirement:  ${REQUIREMENT:-<not named - say which stated requirement this probes>}"
if [ -n "$DELETE" ]; then
  echo "  break:        delete $DELETE"
else
  echo "  break:        sed '$BREAK' on $FILE"
fi
echo "  expect fail:  $EXPECT"

read -r CPUS MEM VTIMEOUT <<<"$(python3 - "$BASE/task.toml" <<'PY'
import re, sys
txt = open(sys.argv[1], encoding="utf-8", errors="replace").read()
def g(b, k, d):
    m = re.search(rf"\[{b}\](.*?)(?=\n\[|\Z)", txt, re.S)
    if m:
        m2 = re.search(rf"^\s*{k}\s*=\s*([0-9.]+)", m.group(1), re.M)
        if m2: return int(float(m2.group(1)))
    return d
print(g("environment", "cpus", 2), g("environment", "memory_mb", 4096), g("verifier", "timeout_sec", 1800))
PY
)"

if [ -z "$IMAGE" ]; then
  IMAGE="sentinel-hp-$(sanitize_tag "$TASK_NAME")"
  echo "== building $IMAGE"
  if ! docker build -t "$IMAGE" "$BASE/environment" > "$SCRATCH/build.log" 2>&1; then
    echo "FAIL docker build failed - tail of $SCRATCH/build.log:"; tail -20 "$SCRATCH/build.log"; exit 2
  fi
else
  echo "== reusing image $IMAGE"
fi

# ---- the probe script, run inside the container ---------------------------------------------------
{
  echo '#!/usr/bin/env bash'
  echo 'set -u'
  echo 'WS=""; for p in /app /testbed /workspace; do [ -d "$p" ] && WS="$p" && break; done'
  echo '[ -n "$WS" ] || { echo "PROBE_STATUS=no-workspace"; exit 2; }'
  echo 'cd "$WS" || exit 2'
  echo 'echo "== applying the oracle first: a probe on an unsolved tree measures nothing"'
  echo 'bash /solution/solve.sh || { echo "PROBE_STATUS=solve-failed"; exit 2; }'
  if [ -n "$DELETE" ]; then
    echo "TARGET=$(printf '%q' "$DELETE")"
    cat <<'PD'
if [ ! -e "$TARGET" ]; then echo "PROBE_STATUS=target-missing"; exit 3; fi
BEFORE_HASH="$( (sha256sum "$TARGET" 2>/dev/null || md5sum "$TARGET") | cut -d' ' -f1 )"
rm -rf "$TARGET"
if [ -e "$TARGET" ]; then echo "PROBE_STATUS=break-did-not-land"; exit 3; fi
echo "PROBE_BEFORE=$BEFORE_HASH"
echo "PROBE_AFTER=deleted"
echo "PROBE_STATUS=landed"
PD
  else
    echo "TARGET=$(printf '%q' "$FILE")"
    echo "SEDEXPR=$(printf '%q' "$BREAK")"
    echo "PATTERN=$(printf '%q' "${PATTERN:-}")"
    cat <<'PB'
if [ ! -f "$TARGET" ]; then echo "PROBE_STATUS=target-missing"; exit 3; fi
BEFORE_HASH="$( (sha256sum "$TARGET" 2>/dev/null || md5sum "$TARGET") | cut -d' ' -f1 )"
if [ -n "$PATTERN" ]; then
  BEFORE_COUNT="$(grep -c -- "$PATTERN" "$TARGET" || true)"
  echo "PROBE_BEFORE_COUNT=$BEFORE_COUNT"
fi
sed -i -e "$SEDEXPR" "$TARGET" || { echo "PROBE_STATUS=sed-failed"; exit 3; }
AFTER_HASH="$( (sha256sum "$TARGET" 2>/dev/null || md5sum "$TARGET") | cut -d' ' -f1 )"
if [ -n "$PATTERN" ]; then
  AFTER_COUNT="$(grep -c -- "$PATTERN" "$TARGET" || true)"
  echo "PROBE_AFTER_COUNT=$AFTER_COUNT"
fi
echo "PROBE_BEFORE=$BEFORE_HASH"
echo "PROBE_AFTER=$AFTER_HASH"
if [ "$BEFORE_HASH" = "$AFTER_HASH" ]; then echo "PROBE_STATUS=break-did-not-land"; exit 3; fi
if [ -n "$PATTERN" ] && [ "$BEFORE_COUNT" = "$AFTER_COUNT" ]; then
  echo "PROBE_STATUS=break-did-not-land"; exit 3
fi
echo "PROBE_STATUS=landed"
PB
  fi
  echo 'echo "== the break landed, running the verifier"'
  echo 'bash /tests/test.sh; echo "PROBE_TEST_SH_EXIT=$?"'
  echo 'exit 0'
} > "$SCRATCH/probe.sh"
chmod +x "$SCRATCH/probe.sh"

mkdir -p "$SCRATCH/logs/verifier"
START="$(date +%s)"
set +e
docker run --rm --network none --cpus "$CPUS" --memory "${MEM}m" \
  -v "$BASE/tests:/tests:ro" -v "$BASE/solution:/solution:ro" \
  -v "$SCRATCH/logs:/logs" -v "$SCRATCH/probe.sh:/probe.sh:ro" \
  --entrypoint /bin/sh "$IMAGE" -c 'bash /probe.sh' > "$SCRATCH/console.log" 2>&1
DRC=$?
set -e
SECS=$(( $(date +%s) - START ))

STATUS="$(sed -n 's/^PROBE_STATUS=//p' "$SCRATCH/console.log" | tail -1)"
echo
sed -n 's/^PROBE_/  PROBE_/p' "$SCRATCH/console.log"

if [ "$STATUS" != "landed" ]; then
  echo
  echo "FAIL BREAK DID NOT LAND (${STATUS:-unknown}). The probe measured nothing, and a probe"
  echo "     that never landed is not coverage evidence. Check the path and the pattern against"
  echo "     the SOLVED tree - solve.sh runs before the break, so the file you are editing is"
  echo "     the post-oracle one."
  [ "$KEEP" = "1" ] && echo "     console: $SCRATCH/console.log"
  exit 3
fi

export HP_LOGS="$SCRATCH/logs/verifier" HP_EXPECT="$EXPECT" HP_SECS="$SECS" \
       HP_TASK="$TASK_NAME" HP_REQ="$REQUIREMENT" HP_FILE="${DELETE:-$FILE}" \
       HP_BREAK="${DELETE:+delete}${BREAK}" HP_RECORD="$RECORD" HP_TASKDIR="$TASK_DIR"

python3 - <<'PY'
import json, os, sys, datetime

logs   = os.environ["HP_LOGS"]
expect = os.environ["HP_EXPECT"]
reward = "?"
rp = os.path.join(logs, "reward.txt")
if os.path.isfile(rp):
    reward = open(rp).read().strip()
report = {}
jp = os.path.join(logs, "report.json")
if os.path.isfile(jp):
    try: report = json.load(open(jp))
    except Exception: pass

missing = [str(x) for x in (report.get("missing_required_tests") or [])]
unexpected = [str(x) for x in (report.get("unexpected_failures") or [])]
failed = missing + unexpected

print()
print(f"  reward:            {reward}")
print(f"  raw_exit_code:     {report.get('raw_exit_code')}")
print(f"  required passed:   {report.get('passed_tests_count')} of {report.get('required_tests_count')}")
print(f"  failing/missing:   {len(failed)}")
for f in failed[:10]:
    print(f"      {f}")

def norm(s):
    return s.replace("::", " ").replace("#", " ").strip().lower()
hit = any(norm(expect) == norm(f) or norm(expect) in norm(f) or norm(f) in norm(expect)
          for f in failed)

record = {
    "kind": "hostile-probe",
    "date": datetime.date.today().isoformat(),
    "task": os.environ["HP_TASK"],
    "requirement": os.environ.get("HP_REQ") or None,
    "file": os.environ["HP_FILE"],
    "break": os.environ["HP_BREAK"],
    "expect_fail": expect,
    "landed": True,
    "reward": reward,
    "expected_test_failed": bool(hit),
    "seconds": int(os.environ["HP_SECS"]),
}

rc = 0
print()
if reward == "0" or reward == "0.0":
    if hit:
        print(f"PASS the break landed and the reward dropped to 0, with {expect} failing")
    else:
        print(f"FAIL the reward dropped to 0 but {expect} is NOT in the failure list.")
        print("     Something else broke. Either the id is wrong or the break is too wide, and")
        print("     either way this run says nothing about that requirement.")
        rc = 1
else:
    print(f"FAIL the reward stayed {reward} with the requirement broken.")
    print("     That requirement has no enforcing assertion, so the coverage axis is scoring a")
    print("     false positive on it. Add or strengthen an assertion before shipping.")
    rc = 1
record["verdict"] = "pass" if rc == 0 else "fail"

line = json.dumps(record, separators=(",", ":"))
if os.environ.get("HP_RECORD") == "1":
    path = os.path.join(os.environ["HP_TASKDIR"], "probes.jsonl")
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(line + "\n")
    print(f"     recorded in {path}")
else:
    print()
    print("  round record line (append with --record, or paste into rounds.jsonl local_matrix):")
    print(f"    {line}")
sys.exit(rc)
PY
