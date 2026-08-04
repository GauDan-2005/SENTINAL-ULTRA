#!/usr/bin/env bash
# local-run.sh - the disposable NOP and oracle battery, run as a matrix.
#
# Step 5.5 is prose today and gets re-improvised every task, so the agent-hostile rows are the
# ones that get dropped under time pressure. That is exactly how the tests.patch failure
# survived three rounds on kvdex 245. learning/accepted-bundle-reference.md records the matrix
# that actually preceded acceptance: five runs, and the agent-hostile rows OUTNUMBER the clean
# ones.
#
# Rows:
#   nop         test.sh on the untouched base tree. MUST fail: reward 0, NONZERO raw exit.
#   oracle      solve.sh then test.sh. MUST pass: reward 1, inside the verifier timeout.
#   agent-edit  an agent edited a file tests.patch touches and .git is gone, then oracle.
#   collision   as agent-edit, plus the agent committed and wrote its own copy of a test file
#               tests.patch creates. The trial-killing case a clean oracle run never catches.
#   thrice      solve.sh three times in one container, then test.sh. The platform runs the
#               oracle 3 times and needs 3 of 3; a reverse-apply fallback passes once and
#               inverts the tree on the second run.
#
# Usage:
#   bin/local-run.sh <task-dir>                   dry run: print the plan and exit
#   bin/local-run.sh <task-dir> --run             execute
#   bin/local-run.sh <task-dir> --run --rows nop,oracle
#   bin/local-run.sh <task-dir> --run --from zip  copy from the built zip (what Step 5.5 wants)
#   bin/local-run.sh <task-dir> --run --image <tag>   reuse an image instead of building
#   bin/local-run.sh <task-dir> --run --keep      keep the scratch copies for inspection
#
# It never runs anything inside the task folder: every row gets its own copy under a scratch
# root outside the repo, and solve.sh and test.sh only ever touch that copy.
#
# Exit: 0 the matrix is green (nop 0 with a nonzero raw exit, every other row reward 1),
#       1 a row came out wrong, 2 cannot run (no docker, no bundle), 3 misuse.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sanitize_tag() {   # docker repo names are [a-z0-9]+([._-][a-z0-9]+)*
  printf '%s' "$1" | tr 'A-Z' 'a-z' | sed -e 's/[^a-z0-9]\+/-/g' -e 's/^-*//' -e 's/-*$//' | cut -c1-100
}

TASK_ARG=""; DO_RUN=0; ROWS="nop,oracle,agent-edit,collision,thrice"; IMAGE=""
KEEP=0; FROM="auto"; SCRATCH_ROOT="${SENTINEL_SCRATCH:-${TMPDIR:-/tmp}}/sentinel-local-run"
while [ $# -gt 0 ]; do
  case "$1" in
    --run)     DO_RUN=1; shift ;;
    --rows)    ROWS="${2:-}"; shift 2 ;;
    --image)   IMAGE="${2:-}"; shift 2 ;;
    --from)    FROM="${2:-}"; shift 2 ;;
    --keep)    KEEP=1; shift ;;
    --scratch) SCRATCH_ROOT="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,32p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        echo "SKIP unknown argument: $1" >&2; exit 3 ;;
    *)         TASK_ARG="$1"; shift ;;
  esac
done

[ -n "$TASK_ARG" ] || { echo "SKIP usage: bin/local-run.sh <task-dir> [--run]" >&2; exit 3; }
TASK_DIR="$(cd "$TASK_ARG" 2>/dev/null && pwd || true)"
[ -n "$TASK_DIR" ] || { echo "SKIP no such directory: $TASK_ARG" >&2; exit 3; }

# ---- refuse to be pointed at the working copy or the pristine extract -----------------------
case "$TASK_DIR" in
  */work|*/work/|*/download/original|*/download/original/*)
    echo "FAIL $TASK_DIR is a bundle, not a task folder."
    echo "     solve.sh and test.sh mutate the tree, and download/original/ is the diff target."
    echo "     Hand me the task folder instead: bin/local-run.sh $(dirname "${TASK_DIR%/}")"
    exit 3 ;;
esac
if [ -f "$TASK_DIR/task.toml" ] && [ ! -d "$TASK_DIR/work" ] && [ ! -d "$TASK_DIR/download" ]; then
  case "$TASK_DIR" in
    "$ROOT"/*)
      echo "FAIL $TASK_DIR looks like a bundle inside the workspace."
      echo "     Point me at its task folder so the runs happen on scratch copies."
      exit 3 ;;
  esac
fi

TASK_NAME="$(basename "$TASK_DIR")"

# ---- resolve the source bundle ---------------------------------------------------------------
ZIP=""; SRC=""; SRC_KIND=""
shopt -s nullglob
ZIPS=("$TASK_DIR/upload/"*.zip)
shopt -u nullglob
[ ${#ZIPS[@]} -gt 0 ] && ZIP="${ZIPS[0]}"

case "$FROM" in
  zip)
    [ -n "$ZIP" ] || { echo "SKIP no zip under $TASK_DIR/upload/"; exit 2; }
    SRC="$ZIP"; SRC_KIND="zip" ;;
  work)
    [ -d "$TASK_DIR/work" ] || { echo "SKIP no work/ under $TASK_DIR"; exit 2; }
    SRC="$TASK_DIR/work"; SRC_KIND="work" ;;
  auto)
    if [ -n "$ZIP" ]; then SRC="$ZIP"; SRC_KIND="zip"
    elif [ -d "$TASK_DIR/work" ]; then SRC="$TASK_DIR/work"; SRC_KIND="work"
    elif [ -f "$TASK_DIR/task.toml" ]; then SRC="$TASK_DIR"; SRC_KIND="bundle"
    else echo "SKIP found no zip, no work/ and no task.toml under $TASK_DIR"; exit 2; fi ;;
  *)
    if [ -f "$FROM" ]; then SRC="$FROM"; SRC_KIND="zip"
    elif [ -d "$FROM" ]; then SRC="$FROM"; SRC_KIND="work"
    else echo "SKIP --from must be zip, work, or a path"; exit 3; fi ;;
esac

# ---- scratch root must live outside the repo -------------------------------------------------
case "$SCRATCH_ROOT" in
  "$ROOT"|"$ROOT"/*)
    echo "FAIL the scratch root must sit outside the workspace (got $SCRATCH_ROOT)"
    exit 3 ;;
esac
RUN_ID="$(date +%Y%m%d-%H%M%S)"
SCRATCH="$SCRATCH_ROOT/$TASK_NAME-$RUN_ID"

# ---- read the declared limits -----------------------------------------------------------------
TOML_SRC=""
if [ -d "$SRC" ] && [ -f "$SRC/task.toml" ]; then TOML_SRC="$SRC/task.toml"; fi
read_toml() {   # read_toml <file> -> "cpus memory_mb verifier_timeout agent_timeout"
  python3 - "$1" <<'PY'
import re, sys
try:
    import tomllib
    data = tomllib.load(open(sys.argv[1], "rb"))
except Exception:
    data = None
def g(block, key, default):
    if data:
        v = (data.get(block) or {}).get(key)
        if v is not None:
            return v
    txt = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    m = re.search(rf"\[{block}\](.*?)(?=\n\[|\Z)", txt, re.S)
    if m:
        m2 = re.search(rf"^\s*{key}\s*=\s*([0-9.]+)", m.group(1), re.M)
        if m2:
            return float(m2.group(1))
    return default
print(int(float(g("environment", "cpus", 2))),
      int(float(g("environment", "memory_mb", 4096))),
      int(float(g("verifier", "timeout_sec", 1800))),
      int(float(g("agent", "timeout_sec", 7200))))
PY
}

echo "# local-run  $TASK_NAME"
echo "  task dir:     $TASK_DIR"
echo "  source:       $SRC   [$SRC_KIND]"
echo "  scratch:      $SCRATCH"
echo "  rows:         $ROWS"

if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP docker is not installed. Harbor or a replicated host toolchain are the fallbacks,"
  echo "SKIP and both have to be driven by hand - see CLAUDE.md Step 5.5."
  exit 2
fi
if ! docker info >/dev/null 2>&1; then
  echo "SKIP docker is installed but the daemon is not reachable"
  exit 2
fi

# ---- materialise the source once --------------------------------------------------------------
mkdir -p "$SCRATCH"
BASE="$SCRATCH/src"
mkdir -p "$BASE"
if [ "$SRC_KIND" = "zip" ]; then
  command -v unzip >/dev/null 2>&1 || { echo "SKIP unzip not installed"; exit 2; }
  unzip -qq "$SRC" -d "$BASE"
  # tolerate a task/ wrapper, though a correct zip has none
  if [ ! -f "$BASE/task.toml" ] && [ -f "$BASE/task/task.toml" ]; then
    echo "WARN the zip carries a task/ wrapper - the platform expects a flat layout"
    mv "$BASE/task"/* "$BASE"/ 2>/dev/null || true
  fi
else
  cp -a "$SRC/." "$BASE/"
fi

for f in task.toml tests/test.sh tests/config.json environment/Dockerfile; do
  [ -e "$BASE/$f" ] || { echo "FAIL the source bundle has no $f"; exit 2; }
done
[ -e "$BASE/solution/solve.sh" ] || echo "WARN no solution/solve.sh - the oracle rows cannot run"

read -r CPUS MEM VTIMEOUT ATIMEOUT <<<"$(read_toml "$BASE/task.toml")"
echo "  limits:       cpus=$CPUS memory=${MEM}m verifier_timeout=${VTIMEOUT}s agent_timeout=${ATIMEOUT}s"

# ---- pick the agent-hostile targets out of tests.patch ------------------------------------------
AGENT_FILE=""; AGENT_LINE=""; CREATED_FILE=""
if [ -f "$BASE/tests/tests.patch" ]; then
  eval "$(python3 - "$BASE/tests/tests.patch" <<'PY'
import re, shlex, sys
patch = open(sys.argv[1], encoding="utf-8", errors="replace").read()
# files the patch MODIFIES (has context lines) and files it CREATES
modified, created, ctx_for = [], [], {}
cur = None
lines = patch.splitlines()
for i, ln in enumerate(lines):
    m = re.match(r"^\+\+\+ b/(.+)$", ln)
    if m:
        cur = m.group(1).strip()
        prev = lines[i-1] if i else ""
        if prev.startswith("--- /dev/null"):
            created.append(cur)
        else:
            modified.append(cur)
        continue
    if cur and cur in modified and cur not in ctx_for and ln.startswith(" "):
        body = ln[1:].strip()
        if len(body) > 12 and not body.startswith(("*", "//", "#")):
            ctx_for[cur] = body
target = next((f for f in modified if f in ctx_for), "")
print(f"AGENT_FILE={shlex.quote(target)}")
print(f"AGENT_LINE={shlex.quote(ctx_for.get(target, ''))}")
print(f"CREATED_FILE={shlex.quote(created[0] if created else (modified[0] if modified else ''))}")
PY
)"
fi
echo "  agent edit:   ${AGENT_FILE:-<none found>}"
echo "  agent's own:  ${CREATED_FILE:-<none found>}"

if [ "$DO_RUN" != "1" ]; then
  cat <<PLAN

DRY RUN. Nothing was executed and nothing was built. To run it:

  bin/local-run.sh $TASK_ARG --run

Plan:
  1. docker build -t sentinel-lr-$TASK_NAME $BASE/environment
  2. for each row, a fresh copy of $BASE and a fresh container:
       docker run --rm --network none --cpus $CPUS --memory ${MEM}m \\
         -v <row>/tests:/tests:ro -v <row>/solution:/solution:ro -v <row>/logs:/logs <image>
  3. read /logs/verifier/reward.txt and report.json, and time each run against ${VTIMEOUT}s
  4. print the matrix as a markdown table for task.md

Rows: $ROWS
PLAN
  rm -rf "$SCRATCH"
  exit 0
fi

# ---- build the image ---------------------------------------------------------------------------
if [ -z "$IMAGE" ]; then
  IMAGE="sentinel-lr-$(sanitize_tag "$TASK_NAME")"
  echo
  echo "== building $IMAGE from $BASE/environment"
  if ! docker build -t "$IMAGE" "$BASE/environment" > "$SCRATCH/build.log" 2>&1; then
    echo "FAIL docker build failed - tail of $SCRATCH/build.log:"
    tail -25 "$SCRATCH/build.log"
    exit 1
  fi
  echo "   built, log at $SCRATCH/build.log"
else
  echo "== reusing image $IMAGE (not rebuilt)"
fi

# ---- the per-row prep, generated on the host ------------------------------------------------------
write_prep() {   # write_prep <row> <file>
  local row="$1" out="$2"
  {
    echo '#!/usr/bin/env bash'
    echo 'set -u'
    echo 'WS=""'
    echo 'for p in /app /testbed /workspace; do [ -d "$p" ] && WS="$p" && break; done'
    echo '[ -n "$WS" ] || { echo "PREP: no workspace"; exit 2; }'
    echo 'cd "$WS"'
    case "$row" in
      nop) ;;
      oracle)
        echo 'bash /solution/solve.sh || { echo "PREP: solve.sh exited $?"; exit 3; }' ;;
      thrice)
        echo 'for i in 1 2 3; do'
        echo '  echo "PREP: solve.sh run $i"'
        echo '  bash /solution/solve.sh || { echo "PREP: solve.sh run $i exited $?"; exit 3; }'
        echo 'done' ;;
      agent-edit|collision)
        if [ -n "$AGENT_FILE" ] && [ -n "$AGENT_LINE" ]; then
          echo "AGENT_FILE=$(printf '%q' "$AGENT_FILE")"
          echo "AGENT_LINE=$(printf '%q' "$AGENT_LINE")"
          cat <<'PREPPY'
python3 - "$AGENT_FILE" "$AGENT_LINE" <<'EOF'
import sys, os
path, needle = sys.argv[1], sys.argv[2]
if not os.path.isfile(path):
    print(f"PREP: {path} not in the image, skipping the agent edit"); raise SystemExit(0)
ext = os.path.splitext(path)[1]
tok = {".py": "#", ".rb": "#", ".sh": "#", ".yml": "#", ".yaml": "#"}.get(ext, "//")
src = open(path, encoding="utf-8", errors="replace").read()
if needle not in src:
    print(f"PREP: context line not found in {path}"); raise SystemExit(0)
open(path, "w", encoding="utf-8").write(
    src.replace(needle, needle + f"  {tok} agent edit", 1))
print(f"PREP: edited {path}")
EOF
PREPPY
        else
          echo 'echo "PREP: no modified file found in tests.patch, agent edit skipped"'
        fi
        if [ "$row" = "collision" ] && [ -n "$CREATED_FILE" ]; then
          echo "CREATED_FILE=$(printf '%q' "$CREATED_FILE")"
          cat <<'PREPC'
mkdir -p "$(dirname "$CREATED_FILE")"
case "$CREATED_FILE" in
  *.ts|*.js) printf '// the agent wrote its own test here\nDeno.test("agent placeholder", () => {});\n' > "$CREATED_FILE" ;;
  *.java)    printf '// the agent wrote its own test here\n' > "$CREATED_FILE" ;;
  *.py)      printf '# the agent wrote its own test here\ndef test_agent_placeholder():\n    assert True\n' > "$CREATED_FILE" ;;
  *)         printf '// the agent wrote its own test here\n' > "$CREATED_FILE" ;;
esac
echo "PREP: wrote the agent's own $CREATED_FILE"
if [ -d "$WS/.git" ] && command -v git >/dev/null 2>&1; then
  git -C "$WS" -c user.email=a@b -c user.name=agent add -A >/dev/null 2>&1
  git -C "$WS" -c user.email=a@b -c user.name=agent commit -qm "agent work" >/dev/null 2>&1 \
    && echo "PREP: committed as the agent would"
fi
PREPC
        fi
        echo 'rm -rf "$WS/.git"; echo "PREP: removed .git"'
        echo 'bash /solution/solve.sh || { echo "PREP: solve.sh exited $?"; exit 3; }' ;;
    esac
    echo 'exit 0'
  } > "$out"
}

run_row() {   # run_row <row>  -> prints "reward|raw_exit|req_pass|req_total|infra|secs|missing"
  local row="$1"
  local dir="$SCRATCH/row-$row"
  rm -rf "$dir"; mkdir -p "$dir"
  cp -a "$BASE/." "$dir/"
  mkdir -p "$dir/logs/verifier"
  write_prep "$row" "$dir/prep.sh"
  chmod +x "$dir/prep.sh" "$dir/tests/test.sh" 2>/dev/null || true
  [ -f "$dir/solution/solve.sh" ] && chmod +x "$dir/solution/solve.sh" 2>/dev/null || true

  local start end
  start="$(date +%s)"
  set +e
  docker run --rm --network none --cpus "$CPUS" --memory "${MEM}m" \
    -v "$dir/tests:/tests:ro" \
    -v "$dir/solution:/solution:ro" \
    -v "$dir/logs:/logs" \
    -v "$dir/prep.sh:/prep.sh:ro" \
    --entrypoint /bin/sh "$IMAGE" -c \
    'bash /prep.sh; PREP=$?; if [ $PREP -ne 0 ]; then echo "LOCALRUN_PREP_EXIT=$PREP"; fi;
     bash /tests/test.sh; echo "LOCALRUN_TEST_SH_EXIT=$?"' \
    > "$dir/console.log" 2>&1
  local drc=$?
  set -e
  end="$(date +%s)"

  python3 - "$dir" "$((end - start))" "$drc" <<'PY'
import json, os, sys
d, secs, drc = sys.argv[1], sys.argv[2], sys.argv[3]
reward = "?"
rp = os.path.join(d, "logs", "verifier", "reward.txt")
if os.path.isfile(rp):
    reward = open(rp).read().strip() or "?"
rep = {}
jp = os.path.join(d, "logs", "verifier", "report.json")
if os.path.isfile(jp):
    try:
        rep = json.load(open(jp))
    except Exception:
        rep = {}
console = ""
cp = os.path.join(d, "console.log")
if os.path.isfile(cp):
    console = open(cp, encoding="utf-8", errors="replace").read()
tsx = ""
for line in console.splitlines():
    if line.startswith("LOCALRUN_TEST_SH_EXIT="):
        tsx = line.split("=", 1)[1]
missing = rep.get("missing_required_tests") or []
print("|".join([
    str(reward),
    str(rep.get("raw_exit_code", "?")),
    str(rep.get("passed_tests_count", "?")),
    str(rep.get("required_tests_count", "?")),
    str(rep.get("infrastructure_error")),
    str(secs),
    str(tsx or drc),
    ";".join(map(str, missing[:6])),
    str(len(missing)),
]))
PY
}

declare -a TABLE=()
FAILED=0
IFS=',' read -ra ROWLIST <<<"$ROWS"
for row in "${ROWLIST[@]}"; do
  row="$(echo "$row" | tr -d ' ')"
  [ -n "$row" ] || continue
  case "$row" in
    nop|oracle|agent-edit|collision|thrice) ;;
    *) echo "SKIP unknown row: $row"; continue ;;
  esac
  if [ "$row" != "nop" ] && [ ! -f "$BASE/solution/solve.sh" ]; then
    echo "SKIP row $row needs solution/solve.sh"; continue
  fi
  echo
  echo "== row: $row"
  out="$(run_row "$row")"
  IFS='|' read -r reward rawexit reqpass reqtotal infra secs tsx missing nmissing <<<"$out"
  verdict="?"
  if [ "$row" = "nop" ]; then
    if [ "$reward" = "0" ] && [ "$rawexit" != "0" ] && [ "$infra" = "None" ]; then
      verdict="OK"
    else
      verdict="WRONG"; FAILED=1
    fi
  else
    if [ "$reward" = "1" ]; then verdict="OK"; else verdict="WRONG"; FAILED=1; fi
  fi
  overtime=""
  if [ "$secs" -gt "$VTIMEOUT" ] 2>/dev/null; then overtime=" OVER TIMEOUT"; FAILED=1; fi
  echo "   reward=$reward raw_exit=$rawexit required=$reqpass/$reqtotal infra=$infra ${secs}s of ${VTIMEOUT}s -> $verdict$overtime"
  [ -n "$missing" ] && echo "   missing (first few of $nmissing): $missing"
  TABLE+=("| $row | $reward | $reqpass of $reqtotal | $rawexit | $infra | ${secs}s of ${VTIMEOUT}s | $verdict |")
done

echo
echo "## Local check matrix - paste into task.md"
echo
echo "| Row | Reward | Required | raw_exit_code | infrastructure_error | Time | Verdict |"
echo "|---|---|---|---|---|---|---|"
for line in "${TABLE[@]}"; do echo "$line"; done
echo
echo "Image $IMAGE, airgapped (--network none), cpus=$CPUS memory=${MEM}m, source $SRC_KIND."

if [ "$KEEP" = "1" ]; then
  echo "scratch kept at $SCRATCH"
else
  rm -rf "$SCRATCH"
fi

if [ "$FAILED" = "1" ]; then
  echo
  echo "FAIL the matrix is not green. Fix in work/, rebuild the zip, and re-run the whole battery."
  exit 1
fi
echo
echo "PASS every row came out as required"
exit 0
