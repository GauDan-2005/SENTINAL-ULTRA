#!/usr/bin/env bash
# nop-audit.sh - a NOP reward of 0 is necessary and never sufficient.
#
# Three mechanisms produce a textbook-looking 0 while grading nothing: test results baked into
# the image at build time, a collection abort, and a module whose test sources do not compile
# at base so the runner never reaches the rest of the graded set. In all three every graded id
# lands in missing_required_tests, and set(required) - set(missing) reads as a clean all-clear.
#
# So this does not read the reward. It splits the graded ids by whether their own module runs
# at base, runs the ones that do, and reads PER-TEST outcomes. Anything that PASSES at base is
# not a fail-to-pass test and has to move to pass_to_pass.
#
# Usage:
#   bin/nop-audit.sh <task-dir>                 build or reuse the image and run the audit
#   bin/nop-audit.sh <task-dir> --image <tag>   reuse an image
#   bin/nop-audit.sh <task-dir> --static        symbol audit only, no container
#   bin/nop-audit.sh <task-dir> --report <dir>  analyse an existing /logs/verifier directory
#   bin/nop-audit.sh <task-dir> --keep          keep the scratch copy
#
# Exit: 0 the fail-to-pass set is genuine, 1 a defect (an f2p passes at base, an empty stdout
#       log, or the corrected count leaves the 10 to 20 range), 2 cannot run, 3 misuse.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sanitize_tag() {   # docker repo names are [a-z0-9]+([._-][a-z0-9]+)*
  printf '%s' "$1" | tr 'A-Z' 'a-z' | sed -e 's/[^a-z0-9]\+/-/g' -e 's/^-*//' -e 's/-*$//' | cut -c1-100
}

TASK_ARG=""; IMAGE=""; STATIC_ONLY=0; REPORT_DIR=""; KEEP=0
SCRATCH_ROOT="${SENTINEL_SCRATCH:-${TMPDIR:-/tmp}}/sentinel-nop-audit"
while [ $# -gt 0 ]; do
  case "$1" in
    --image)  IMAGE="${2:-}"; shift 2 ;;
    --static) STATIC_ONLY=1; shift ;;
    --report) REPORT_DIR="${2:-}"; shift 2 ;;
    --keep)   KEEP=1; shift ;;
    --scratch) SCRATCH_ROOT="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)       echo "SKIP unknown argument: $1" >&2; exit 3 ;;
    *)        TASK_ARG="$1"; shift ;;
  esac
done

[ -n "$TASK_ARG" ] || { echo "SKIP usage: bin/nop-audit.sh <task-dir>" >&2; exit 3; }
TASK_DIR="$(cd "$TASK_ARG" 2>/dev/null && pwd || true)"
[ -n "$TASK_DIR" ] || { echo "SKIP no such directory: $TASK_ARG" >&2; exit 3; }
TASK_NAME="$(basename "$TASK_DIR")"

# ---- resolve the bundle (zip first: that is what actually ships) ------------------------------
BUNDLE=""
shopt -s nullglob
ZIPS=("$TASK_DIR/upload/"*.zip)
shopt -u nullglob
SCRATCH="$SCRATCH_ROOT/$TASK_NAME-$(date +%Y%m%d-%H%M%S)"
case "$SCRATCH_ROOT" in "$ROOT"|"$ROOT"/*) echo "FAIL scratch must be outside the workspace"; exit 3 ;; esac

cleanup() { [ "$KEEP" = "1" ] || rm -rf "$SCRATCH"; }
trap cleanup EXIT

mkdir -p "$SCRATCH"
if [ ${#ZIPS[@]} -gt 0 ] && command -v unzip >/dev/null 2>&1; then
  BUNDLE="$SCRATCH/src"; mkdir -p "$BUNDLE"
  unzip -qq "${ZIPS[0]}" -d "$BUNDLE"
  SRC_KIND="zip (${ZIPS[0]##*/})"
elif [ -d "$TASK_DIR/work" ]; then
  BUNDLE="$SCRATCH/src"; mkdir -p "$BUNDLE"; cp -a "$TASK_DIR/work/." "$BUNDLE/"
  SRC_KIND="work/"
elif [ -f "$TASK_DIR/task.toml" ]; then
  BUNDLE="$SCRATCH/src"; mkdir -p "$BUNDLE"; cp -a "$TASK_DIR/." "$BUNDLE/"
  SRC_KIND="bundle"
else
  echo "SKIP no zip, no work/ and no task.toml under $TASK_DIR"; exit 2
fi
for f in tests/config.json tests/test.sh; do
  [ -e "$BUNDLE/$f" ] || { echo "FAIL the bundle has no $f"; exit 2; }
done

echo "# nop-audit  $TASK_NAME"
echo "  source: $SRC_KIND"

# ---- the static symbol audit, always run ------------------------------------------------------
export NA_BUNDLE="$BUNDLE"
python3 - <<'PY'
import json, os, re, sys, collections

b = os.environ["NA_BUNDLE"]
cfg = json.load(open(os.path.join(b, "tests", "config.json"), encoding="utf-8"))
grading = cfg.get("grading") or {}
f2p = list(grading.get("fail_to_pass") or [])
p2p = list(grading.get("pass_to_pass") or [])
status = {"range_fail": False, "no_static_evidence": []}
print(f"  graded: {len(f2p)} fail_to_pass, {len(p2p)} pass_to_pass, {len(f2p)+len(p2p)} total")
if not (10 <= len(f2p) <= 20):
    print(f"FAIL fail_to_pass is {len(f2p)}, outside the hard 10 to 20 static-check range")
    status["range_fail"] = True
    json.dump(status, open(os.path.join(b, ".nop-audit-status.json"), "w"))

json.dump(status, open(os.path.join(b, ".nop-audit-status.json"), "w"))
patch_path = os.path.join(b, "tests", "tests.patch")
if not os.path.isfile(patch_path):
    print("WARN no tests/tests.patch - the symbol audit cannot run")
    raise SystemExit(0)
patch = open(patch_path, encoding="utf-8", errors="replace").read()

# added lines per file
added = collections.defaultdict(list)
cur = None
for ln in patch.splitlines():
    m = re.match(r"^\+\+\+ b/(.+)$", ln)
    if m:
        cur = m.group(1).strip(); continue
    if cur and ln.startswith("+") and not ln.startswith("+++"):
        added[cur].append(ln[1:])

repo = os.path.join(b, "environment", "repo")
def owner(i):
    return i.split("::")[0] if "::" in i else i.rsplit("#", 1)[0]
def leaf(i):
    return i.split("::")[-1] if "::" in i else i.rsplit("#", 1)[-1]

# identifiers that appear in the added test text but nowhere in the base repo
ident = re.compile(r"[A-Za-z_][A-Za-z0-9_]{3,}")
base_text = []
skip_dirs = {".git", "node_modules", "target", "build", ".gradle", "dist", "vendor"}
for dirpath, dirnames, filenames in os.walk(repo):
    dirnames[:] = [d for d in dirnames if d not in skip_dirs]
    for fn in filenames:
        if os.path.splitext(fn)[1] in (".ts", ".js", ".java", ".kt", ".py", ".rs", ".go",
                                       ".c", ".h", ".cc", ".cpp", ".hpp", ".json", ".toml"):
            p = os.path.join(dirpath, fn)
            try:
                if os.path.getsize(p) < 2_000_000:
                    base_text.append(open(p, encoding="utf-8", errors="replace").read())
            except OSError:
                pass
base_blob = "\n".join(base_text)
base_idents = set(ident.findall(base_blob))

absent_by_file = {}
for f, ls in added.items():
    a = sorted({w for w in ident.findall("\n".join(ls)) if w not in base_idents})
    if a:
        absent_by_file[f] = a

def base_body(path):
    p = os.path.join(repo, path)
    if os.path.isfile(p):
        return open(p, encoding="utf-8", errors="replace").read()
    return ""

per_test, via = {}, {}
for i in f2p:
    o = owner(i)
    direct = absent_by_file.get(o)
    if not direct:
        # a JUnit-style id is pkg.Class#method, so map the class name onto a patched file.
        # Match on the file name, never on a substring: a loose match hands one file's absent
        # symbols to an unrelated test and manufactures evidence that does not exist.
        stem = o.split("/")[-1].split(".")[0] if "/" in o else o.split(".")[-1]
        for k, a in absent_by_file.items():
            kbase = os.path.basename(k)
            if kbase == o.split("/")[-1] or os.path.splitext(kbase)[0] == stem:
                direct = a; break
    if direct:
        per_test[i] = direct
        via[i] = o
        continue
    # indirect: the test file itself is untouched, but a helper it imports IS patched with
    # symbols that do not exist at base. That is how a pre-existing test becomes fail-to-pass
    # without the patch touching it, and it is easy to read as "no evidence".
    src = base_body(o)
    best, bestfile = None, None
    for helper, a in absent_by_file.items():
        stem = os.path.splitext(os.path.basename(helper))[0]
        if helper == o or not src:
            continue
        if (os.path.basename(helper) in src) or (f"/{stem}" in src) or (f'"{stem}' in src):
            if best is None or len(a) > len(best):
                best, bestfile = a, helper
    if best:
        per_test[i] = best
        via[i] = bestfile
    else:
        per_test[i] = []
        via[i] = None

print("\n## Symbol audit - identifiers the graded tests use that do not exist at base")
noevidence = []
for i in f2p:
    absent = per_test[i]
    if absent:
        src = via[i]
        how = "" if src == owner(i) else f"  via the patched {src} it imports"
        print(f"  PASS-CANNOT-HOLD  {i}{how}")
        print(f"      absent at base: {', '.join(absent[:8])}"
              + (f" (+{len(absent)-8} more)" if len(absent) > 8 else ""))
    else:
        noevidence.append(i)
if noevidence:
    print(f"  NO STATIC EVIDENCE ({len(noevidence)}): these f2p ids use only symbols that already")
    print("      exist at base, so nothing here proves they fail at base. They are exactly the")
    print("      ids the run below has to settle.")
    for i in noevidence:
        print(f"        {i}")
json.dump({"f2p": f2p, "p2p": p2p, "no_static_evidence": noevidence},
          open(os.path.join(b, ".nop-audit-static.json"), "w"))
status["no_static_evidence"] = noevidence
json.dump(status, open(os.path.join(b, ".nop-audit-status.json"), "w"))
print(f"  {len(f2p) - len(noevidence)} of {len(f2p)} fail_to_pass ids cannot pass at base on the "
      f"symbols alone, {len(noevidence)} rest on the run")
PY

if [ "$STATIC_ONLY" = "1" ]; then
  echo
  echo "WARN --static: genuineness rests on the symbol audit above, not on a run. Say so in"
  echo "WARN task.md and in Comments for Reviewer."
  RANGE="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['range_fail'])" \
           "$BUNDLE/.nop-audit-status.json" 2>/dev/null || echo False)"
  [ "$RANGE" = "True" ] && exit 1
  exit 2
fi

# ---- the run --------------------------------------------------------------------------------
LOGS=""
if [ -n "$REPORT_DIR" ]; then
  [ -d "$REPORT_DIR" ] || { echo "SKIP no such report dir: $REPORT_DIR"; exit 2; }
  LOGS="$REPORT_DIR"
else
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo
    echo "SKIP docker is unavailable, so the per-module split cannot run."
    echo "SKIP Fall back to the symbol audit above and record that in task.md."
    exit 2
  fi
  if [ -z "$IMAGE" ]; then
    IMAGE="sentinel-na-$(sanitize_tag "$TASK_NAME")"
    echo
    echo "== building $IMAGE"
    if ! docker build -t "$IMAGE" "$BUNDLE/environment" > "$SCRATCH/build.log" 2>&1; then
      echo "FAIL docker build failed - tail of $SCRATCH/build.log:"; tail -20 "$SCRATCH/build.log"; exit 2
    fi
  fi

  mkdir -p "$SCRATCH/logs/verifier" "$SCRATCH/logs/audit"
  chmod +x "$BUNDLE/tests/test.sh" 2>/dev/null || true

  # The audit script: the full NOP first, then one subset run per file owning graded ids. The
  # subset runs are what separate "failed at base" from "never ran at base".
  python3 - "$BUNDLE" > "$SCRATCH/audit.sh" <<'PY'
import json, os, shlex, sys
b = sys.argv[1]
cfg = json.load(open(os.path.join(b, "tests", "config.json"), encoding="utf-8"))
ex  = cfg.get("execution") or {}
cmds = ex.get("commands") or []
if isinstance(cmds, str): cmds = [cmds]
grading = cfg.get("grading") or {}
ids = list(grading.get("fail_to_pass") or []) + list(grading.get("pass_to_pass") or [])
def owner(i):
    return i.split("::")[0] if "::" in i else i.rsplit("#", 1)[0]
files = []
for i in ids:
    o = owner(i)
    if o not in files:
        files.append(o)
print("#!/usr/bin/env bash")
print("set -u")
print('WS=""; for p in /app /testbed /workspace; do [ -d "$p" ] && WS="$p" && break; done')
print('cd "$WS" || exit 2')
print('echo "== full NOP"')
print('bash /tests/test.sh > /logs/audit/nop-console.log 2>&1; echo "NOP_TEST_SH_EXIT=$?" >> /logs/audit/nop-console.log')
RUNNERS = ("pytest", "deno", "go test", "npx jest", "jest", "cargo test", "ctest", "vitest")

def with_file(cmd, path):
    """Restrict a configured command to one test file. When the config carries the
    ${TEST_FILES} placeholder that is exact. Otherwise insert the path before the first pipe,
    which is where a runner's own arguments end and the result parser begins - appending after
    the pipe hands the file to the parser instead."""
    q = shlex.quote(path)
    if "${TEST_FILES}" in cmd:
        return cmd.replace("${TEST_FILES}", q)
    head, sep, tail = cmd.partition("|")
    if any(r in head for r in RUNNERS):
        return f"{head.rstrip()} {q} {sep}{tail}"
    return None

subset_cmds = []
for f in files:
    built = [with_file(c, f) for c in cmds]
    if any(x is None for x in built):
        subset_cmds = []
        break
    subset_cmds.append((f, built))

if not subset_cmds:
    print('echo "SUBSET_UNSUPPORTED=1" > /logs/audit/subset.txt')
else:
    print('echo "SUBSET_SUPPORTED=1" > /logs/audit/subset.txt')
    for n, (f, built) in enumerate(subset_cmds):
        for line in built:
            print(f'echo "--- subset {n}: {f}"')
            print(f'( {line} ) > /logs/audit/subset-{n}.log 2>&1; echo "EXIT=$? FILE={f}" >> /logs/audit/subset-{n}.log')
print("exit 0")
PY
  chmod +x "$SCRATCH/audit.sh"

  read -r CPUS MEM <<<"$(python3 - "$BUNDLE/task.toml" <<'PY'
import re, sys
txt = open(sys.argv[1], encoding="utf-8", errors="replace").read()
def g(block, key, d):
    m = re.search(rf"\[{block}\](.*?)(?=\n\[|\Z)", txt, re.S)
    if m:
        m2 = re.search(rf"^\s*{key}\s*=\s*([0-9.]+)", m.group(1), re.M)
        if m2: return int(float(m2.group(1)))
    return d
print(g("environment", "cpus", 2), g("environment", "memory_mb", 4096))
PY
)"
  echo "== running the audit (airgapped, cpus=$CPUS memory=${MEM}m)"
  set +e
  docker run --rm --network none --cpus "$CPUS" --memory "${MEM}m" \
    -v "$BUNDLE/tests:/tests:ro" -v "$BUNDLE/solution:/solution:ro" \
    -v "$SCRATCH/logs:/logs" -v "$SCRATCH/audit.sh:/audit.sh:ro" \
    --entrypoint /bin/sh "$IMAGE" -c 'bash /audit.sh' > "$SCRATCH/logs/audit/driver.log" 2>&1
  set -e
  LOGS="$SCRATCH/logs/verifier"
fi

# ---- read the outcomes -------------------------------------------------------------------------
export NA_LOGS="$LOGS" NA_AUDIT="$SCRATCH/logs/audit" NA_BUNDLE="$BUNDLE"
python3 - <<'PY'
import json, os, re, sys, glob

logs   = os.environ["NA_LOGS"]
audit  = os.environ["NA_AUDIT"]
bundle = os.environ["NA_BUNDLE"]
cfg    = json.load(open(os.path.join(bundle, "tests", "config.json"), encoding="utf-8"))
grading= cfg.get("grading") or {}
parser = grading.get("parser") or {}
f2p    = list(grading.get("fail_to_pass") or [])
p2p    = list(grading.get("pass_to_pass") or [])
fail   = 0
try:
    if json.load(open(os.path.join(bundle, ".nop-audit-status.json")))["range_fail"]:
        fail = 1            # the count is already outside the hard range, reported above
except Exception:
    pass

stdout_log = os.path.join(logs, "test-stdout.txt")
report_p   = os.path.join(logs, "report.json")
reward_p   = os.path.join(logs, "reward.txt")

print("\n## The NOP run")
if os.path.isfile(reward_p):
    print(f"  reward: {open(reward_p).read().strip()}")
if os.path.isfile(stdout_log):
    size = os.path.getsize(stdout_log)
    print(f"  test-stdout.txt: {size} bytes")
    if size == 0:
        # An empty stdout means the run graded nothing. That is a defect UNLESS the symbol audit
        # already shows every f2p id cannot pass at base, which is the documented fallback when
        # the toolchain cannot run a subset. Then it is a declaration, not a blocker.
        static = {}
        sp = os.path.join(bundle, ".nop-audit-static.json")
        if os.path.isfile(sp):
            try: static = json.load(open(sp))
            except Exception: static = {}
        gaps = static.get("no_static_evidence")
        if gaps:
            print(f"FAIL test-stdout.txt is empty - nothing ran, and {len(gaps)} f2p id(s) have "
                  f"no symbol evidence either, so their genuineness rests on nothing")
            fail = 1
        else:
            print("WARN test-stdout.txt is empty - nothing ran at base, so the reward of 0 grades")
            print("WARN nothing. Every f2p id is covered by the symbol audit above, so this is the")
            print("WARN documented fallback: say in task.md and Comments for Reviewer that")
            print("WARN genuineness rests on the audit rather than on the run.")
else:
    print("WARN no test-stdout.txt in the log directory")

report = {}
if os.path.isfile(report_p):
    try: report = json.load(open(report_p))
    except Exception: pass
if report:
    print(f"  raw_exit_code: {report.get('raw_exit_code')}   "
          f"infrastructure_error: {report.get('infrastructure_error')}")
    print(f"  required passed: {report.get('passed_tests_count')} of {report.get('required_tests_count')}")
    if report.get("raw_exit_code") == 0:
        print("FAIL raw_exit_code is 0 on a NOP run - the grader cannot be failing closed")
        fail = 1

# per-test outcomes the full NOP produced
outcomes = {}
for t in (report.get("_tests") or []):
    outcomes[str(t.get("name"))] = str(t.get("status"))

# subset runs
pass_re = re.compile(parser.get("pass_regex", r"(?P<name>\S+) PASS$"), re.M)
fail_re = re.compile(parser.get("fail_regex", r"(?P<name>\S+) FAIL$"), re.M)
subset_supported = os.path.isfile(os.path.join(audit, "subset.txt")) and \
    "SUBSET_SUPPORTED" in open(os.path.join(audit, "subset.txt")).read()
sub_pass, sub_fail, sub_ran_files, sub_dead_files = set(), set(), set(), set()
for p in sorted(glob.glob(os.path.join(audit, "subset-*.log"))):
    text = open(p, encoding="utf-8", errors="replace").read()
    m = re.search(r"EXIT=(\d+) FILE=(\S+)", text)
    fname = m.group(2) if m else os.path.basename(p)
    got = False
    for mm in pass_re.finditer(text):
        sub_pass.add(mm.group("name")); got = True
    for mm in fail_re.finditer(text):
        sub_fail.add(mm.group("name")); got = True
    (sub_ran_files if got else sub_dead_files).add(fname)

def norm(i):
    return i
def owner(i):
    return i.split("::")[0] if "::" in i else i.rsplit("#", 1)[0]

PASSING, FAILING, UNKNOWN = [], [], []
for i in f2p:
    st = outcomes.get(i, "")
    if i in sub_pass or st.upper().startswith("PASS"):
        PASSING.append(i)
    elif i in sub_fail or st.upper() in ("FAILED", "ERROR", "FAIL"):
        FAILING.append(i)
    else:
        UNKNOWN.append(i)

print("\n## fail_to_pass at base, split by what actually ran")
print(f"  FAILING at base (genuine f2p):        {len(FAILING)}")
for i in FAILING: print(f"      {i}")
print(f"  PASSING at base (NOT a f2p):          {len(PASSING)}")
for i in PASSING: print(f"      {i}")
print(f"  UNKNOWN - module never ran at base:   {len(UNKNOWN)}")
for i in UNKNOWN: print(f"      {i}   [{owner(i)}]")

if not subset_supported:
    print("\nWARN execution.commands carries no ${TEST_FILES} placeholder, so a per-file subset")
    print("WARN could not be run. The UNKNOWN bucket rests on the symbol audit above.")
elif sub_dead_files:
    print(f"\n  files whose subset run produced no per-test lines at base ({len(sub_dead_files)}):")
    for f in sorted(sub_dead_files): print(f"      {f}")
    print("      these are the modules that do not compile or collect at base. Every graded id")
    print("      in them lands in missing_required_tests whether it would pass or not.")

if PASSING:
    print(f"\nFAIL {len(PASSING)} fail_to_pass id(s) PASS at base. Move them to pass_to_pass.")
    fail = 1
    corrected_f2p = [i for i in f2p if i not in PASSING]
    corrected_p2p = p2p + PASSING
    print(f"     corrected split: fail_to_pass {len(corrected_f2p)}, pass_to_pass {len(corrected_p2p)}")
    if not (10 <= len(corrected_f2p) <= 20):
        print(f"     corrected fail_to_pass {len(corrected_f2p)} leaves the hard 10 to 20 range - "
              f"add distinct contracts rather than putting these back")
    print("     as JSON:")
    print("     " + json.dumps({"fail_to_pass": corrected_f2p, "pass_to_pass": corrected_p2p})[:400] + " ...")
else:
    print("\nPASS no fail_to_pass id passes at base")

if UNKNOWN and not PASSING:
    print("WARN the UNKNOWN ids were never executed at base. A reward of 0 says nothing about")
    print("WARN them - cite the symbol audit, or make their module compile at base and re-run.")

sys.exit(1 if fail else 0)
PY
