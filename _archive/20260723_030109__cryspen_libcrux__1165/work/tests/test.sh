#!/usr/bin/env bash
# Compact verifier entrypoint — SELF-CONTAINED (generic; shipped per task).
#
# Resolves the workspace, applies the eval tests (tests/tests.patch) at verify
# time, runs the configured test command(s), then grades via an EMBEDDED copy of
# grade.py (inlined at materialize time at the grader marker below — no sibling
# grade.py ships). Reads tests/config.json = {execution, grading, artifacts}.
# A fallback trap guarantees reward.txt exists.
set -uo pipefail

CONFIG="/tests/config.json"
LOG_DIR="/logs/verifier"
STDOUT_LOG="$LOG_DIR/test-stdout.txt"
STDERR_LOG="$LOG_DIR/test-stderr.txt"
REPORT="$LOG_DIR/report.json"
OUTPUT="$LOG_DIR/output.json"
REWARD="$LOG_DIR/reward.txt"

mkdir -p "$LOG_DIR"

# Safety net: if we crash before the grader writes the reward, write 0.
write_zero_reward_if_missing() {
  if [ ! -f "$REWARD" ]; then echo "0" > "$REWARD"; fi
}
trap write_zero_reward_if_missing EXIT

if [ ! -f "$CONFIG" ]; then
  echo "ERROR: missing $CONFIG" | tee "$STDERR_LOG"
  echo '{"success": false, "infrastructure_error": "missing config.json", "reward": 0.0}' > "$REPORT"
  echo "0" > "$REWARD"
  exit 2
fi

# Resolve the workspace from hardcoded fallbacks (config carries no workspace).
WORKSPACE=""
for p in /app /testbed /workspace; do
  if [ -d "$p" ]; then WORKSPACE="$p"; break; fi
done
if [ -z "$WORKSPACE" ]; then
  echo "ERROR: could not resolve workspace" | tee "$STDERR_LOG"
  echo '{"success": false, "infrastructure_error": "missing workspace", "reward": 0.0}' > "$REPORT"
  echo "0" > "$REWARD"
  exit 2
fi
cd "$WORKSPACE" || exit 2

# Export configured env vars (execution.env).
python3 - <<'PY' > /tmp/verifier_env.sh
import json, shlex
cfg = json.load(open("/tests/config.json"))
env = (cfg.get("execution") or {}).get("env", {})
if isinstance(env, dict):
    for k, v in env.items():
        if isinstance(k, str):
            print(f"export {k}={shlex.quote(str(v))}")
PY
# shellcheck disable=SC1091
source /tmp/verifier_env.sh

# Apply the eval tests at VERIFY time. They ship as tests/tests.patch (NOT in
# repo/), so the solving agent never saw them. git apply (plain, then 3-way for
# agent edits to neighbouring files) when git exists; otherwise fall back to
# patch(1), which patch_dockerfile injects into every task image — a slim/alpine
# base without git must not zero the reward. A hard failure means we cannot
# grade -> infra error, reward 0.
if [ -f /tests/tests.patch ]; then
  # Put the two test source files that carry every graded pass_to_pass id back to
  # their base-commit state, from a payload embedded in this script.
  #
  # Deliberately NOT git. The verify-time workspace is not a git repository, so a
  # git-based restore silently does nothing and the regression guards then run
  # against whatever the agent left behind. This script is read from /tests, so
  # its own contents are the most dependable restore source inside the verifier.
  # Only self.rs and ml-kem.rs are carried: they hold all 21 graded p2p ids, and
  # the rest of the tests/ directory is 19 MB of KAT vectors that cannot be
  # embedded at any sane size.
  TEST_DIR="libcrux-ml-kem/tests"
  TEST_BASE_B64="/tmp/tests_base.tar.gz.b64"
  TEST_BASE_TGZ="/tmp/tests_base.tar.gz"

  cat > "$TEST_BASE_B64" <<'TESTS_BASE_B64_EOF'
H4sIAAAAAAAAA+0c71PbOLaf+StEbjfj3IYApqUdd2Gmy9K7Ttu7Ttu7D8dwHuMoxBvH9tpygevw
v9+TZFuyLP9IUijsWh8gkaX3nt5vPclJsD+bxMmTu2x70A6fPmX/oSn/nx4ePD98sv8Mhjwz90xz
H/qfm4d7T9DenVKVtTQhTozQfaB6iC1NMPK9CzdOr+2lby/w0rK+vvff4uWJF81xTPA1GSPW8SH2
vjgEv8U3ty+3tuSJydw5sCz4u8Dms8OX7FnsBFMAFQeXYwR/Esv6Z/KRfvkc38D/kzDGFIwbBglB
n/7+6uPpr/an05OPp5/tT2/+c2qhNPH+h9EROjBh2CxgAMOl7cSxc/Mzn/YuG3VsjNDOMTpLX7xE
787R1y0EzccELVNCkQMUhvxl6UGC8RSenO3RSfwRjJ2Q+Maeeb5vX9wQnBjDfOhokgZXsRMZIz6W
9m3dbm0tHTcO7Tj1cbKNvGXk25Q4LyE4cG8yWowfAmeJLW+KA+DmDwt8Y1/iwMLXUQxfYaATJfm3
KS6+jdDRcQaBtr+cubNL2yEkNkBnLzEBZrhzWMLgykmWB+ZgjOgH+8ILpgDeBvKJZVW6RucSRNoh
vgObGaXAT4E25xkXQICTBFDK0sg5Ig+mS4wcL4ah+XINAUAzYSXohispJ+hdjKd2gt0YkxFFyBlq
5DRMovTC91xQbgA2Ro1klIDZXBapD2pPVSWTjQSYm0QOeSjIUkA7SQL9Nv592yj1M0WSUY4bKBhX
pg78eWKpAOJKXwnKoAQF6Cx9391Fb2aIzLEsEFAhFIQE4SBML+doFsZ8BP4Nu8QLA5Q4oPceGBpo
faTC8wKqDTugATh22HCAjLiMKEnQA6umlnMDIEkaB+jKI/MwJSqkmeNRLJOi/5Z9Aj/SZod2GkSO
uwApag1yGU4jK3LI/OFYHPWhjC7QHRQpUmo1GJVzf+PMx6jgA4ik1mgFt45QZFn5N8vKZMgUno0s
23Qt1hhfgqTjRqQc14oYToMkjTHTRnIVUlgJcrIOUEpctW8ce44PMWNqC6+AjiqWVVp2wRftbGNY
4dsK1q91UhMnsRP4BmpRNXotEdIM1b5VFrCgiAtaS3xAv+KZk/qgxFP+QfW+Jb5oQNQ53WE91hoS
ayS1GoU1AtMTklGpnbOKP2+RT1WibTrQRaIyVhGVVuWXVtMFOBswVRdc1f/qEiucFUDHTcvrymgB
riOn5cjdwGrV4fxL8p9oFodL7moKSlAGWOvqKA8CfGUvorXlQlEWq6XSGNYwlXOcY1PX8Y3zLaBU
RHO8VtolIRBKpCQxhXNtc9cyMVXdnMgGX0vU2glbvQl0TdZyCJVErSt9gpeNtqBheeN4Tr+sCXG5
o55y1YpO5thdsCwPYsIOXcvywgfj4ep6j9rBEfYqURl2vyrRtvNqlqg0VmPvTduyCl7uzWSAd7jX
q9XllTd9EqRVd39rUf4AdqkrupDGfX29NnFofxxp/0H2+mxfbsywQ+juD7bjXgBrX8Jm3vEHsNtu
rgVIg79/OUBZiOP7oTvYqGBgWV+lFVrWX8coCmPigHkIPb/VeOCsTmevV1mgCTFzlOqIV3RJyIhA
/KBNSzTFEQ4op9l2faQlIysIMG7oigJVUhWzBLyfRFJOEWmz8SJasGIvqwbTInLR7ePAGJ2XQXeh
Jku/y+DVCrJE60m4jGKYx7xDC91loKDZ+VQg/y2++QCPBLhf6BjLYtsGWrHWc64qVIKixT4z3mhh
IhICVfAZ7HSi5SMMVlh4+FRhmwik+VheWy++yuypQWIqSGiPTkQSLrOMK/taG1DI3CHM4TWXkiSv
X9A/pkuREhCOqD5cFMTQiWbbRKrQQEXhkCWx55ZXh2gokVirPFQsRgO1Q4ncJiAmA6KS/hkoDoHs
GAiNyY0UEUCaoF1U2SaTqm7xcc0eSZ1juGR/jFxiaraqZZeZz6DYj9AHtgkAC9q3LHYIBDYj8Y7W
YYdn6YvzOjMu408IrG2MpjeBDSYmfJm08n0GfVxdpAbwFF+kEHqEPADJ5Ivjp3jCDGCMxHkd0M/6
VDlksuDo9nnuJDkbRrF2RUrthg0sbDCjnnVqjbEEpZSqSMhzaNWTwBposH4TZpXYWRlIm6T92ucV
7uuHqQUsLt+GoTUrrU4ZVXoaFEynAWPGDP65Rua5c8OIb3V5+QpciZQXTWqQbRsA2ZtS8UaLTGWF
NxhNvMQOF7XaBlbNwgjgDrilm1VEMI6GGS8B98BcGuSRYG7c7i4goaXJDaV+inNOOh6B7BJmxGlA
vGVVcSnMSspRRc11ydQaqGkwKdMtcIxnbNcnrbteSBpjNeuM1exirOYKxgq4FMMwS0XCzDEN5Vio
F3yZdOZSG7RMmsOdnrrPETRoMEpOO3OZpSFqupqFFC/wiOcQ0GNp15MUx0Fi05ZsnJXqNllCabQV
A0lt2Orgr9mWpnbCa2oqIhIF8gZHOaDKArhEzzo5aZXIBbCiPitIFro4rVvZAcCRVyKAsIUkC4WX
dUkczqAjDr0sfUlTdTSoaUNtSqQVzUazD6qzdVJJCc//nNhL6I5cXmrCvK2k+dx1kCIBe/XhTf2e
AtjfdNrbuu36FtXalkJ+qVirS530OuHy3YxrarcWwE3YoQN9Li0BfsHuNk9HagqizKwnumRHAnS2
N5koWdr5xA0jnllmRdVhMWJUD0iBMplo4ZhaON2qwtXVaY7wJJI0dao3AUsTZNXrWMQDjZTzkG9b
XmuglCtP2Xxq66PV8hO4frlys/QXePlsnxaB6gpTo/OtpmIUBFv9AxvAjivX9HKElK/1FD0/fHEX
FAHYGorgSTNF+3vm07sgicKtoYk+GvFrhMtw6s1ubKGl+V3C038UtwnFQwspdyF/hnHH7Lah7oF6
9dC5khAVexwYmd83LA2oGHX51IaZZW5EAgXbDKcHprgxGQeX4CToFjZgpn0Ae/IizLN+LyChUam3
KDBpGAegLwCiIdCgIdq7fv16RPNzWAyb6M3kOejoCO1JO2350U9HaJ/Pud2SnlG4x8dH6IVESRQm
HqsgH8mjflT5blmM81kWrWPrWQ7pHP33SKZGQiZL/CyXEcNcggQevRG9KNNKbBZ9Cr8l8WYjtdfY
mMZ61O0KVeqvlT7sa6UV0CU3UPFBRvcTys3upOpia4CVZLTpgEoTxL3HeYYkYkG2TECqiQVshhhh
oaFyGZ7ZP88yMniUNM/1iF0s2GaZmYUuwtAfb4nwoUDRhA+BuSZ8iAGV8CE9Eof4f8oAAvBbZCOh
MxTRlF082tHUKEfop9ISf9SN4VQj7Ce4ujg+ax3UuUprNKJL5JNVW418EqQ88tXRtlrkkzRTRD4w
SJdvbnVSKrmkzE5PhKGOUY3pNuVyJ8J0ZTboDVy8YqKpUSuWS0J77iQ0hkosXF22dKMHoGA7mker
DPAEqMfBtGOumL+YYwyz6W2JhuR0+kTjzhMNe+PkohQkKkGtNjWYOeCK1s03hgJBlySjwwa++R5M
V9dQzuEKGlsv9j7SLKbTdsEG1G2RrzfxB23iD3H/sIHrIXGlUNlMqb1M1nc+lR1O2dc0o/02Dg0A
9T5NQFrtdl9RWtXUBjMpyEVBWi3l6VhNxVRztNE2QTqKaBsqiX0LhKJfDS3LdlsNrbTWY4Snq62G
Tei2Gja002pYSbfbcliVth4nfbzagviMbiviY5UltZTztQXp/LBBs8DixTKYbOcXL9t0Jh/XgZ5S
5RyMbbpvvhiMN6IywGC4LRTSMetQB/uODalzvly32jMd00Id19F1CaGzu0iTa1hHcVZPQjaXJyO0
RaCcyA4S1RO4mUgZgS0y5QR2ECo73VqbFJjdRabMD3YUaeW4bXOJUipbBMoo7CBPLXWbiZNS1yJN
Rp0izKbortnBZBTo9jaPLdqvtrpHF/1XW97DywZWUE+RiasrFE8er3p2Wt3jVc9Oy3t46rme+2ws
ADWYZ9O0x6vZd8yXx2sTd8yYh2dN3/vX175/W/o7wJy7/QXA5t//2zt89tRUf//v2V7/+3/30nZ3
t9FnnJCE1QLfv9t5e/p+a2uX36+nL12wZ/Q9OPZjJ3NCosTa3b30yDy9mLjhcvfE/PRh9+Tk8793
wdfQ6/BXxhQ74BXCKQYPMwsYDNvjly6ps0n9NDEiCw0TEudVfPqCR0LoLwaKSn9iWa89X3rJxgvh
+S/p7CPAH6PsA45vx6UzcFbbdwj9ET9s07d4weuxz+zYIBq9rIyCARSRZYURDozSXPV+PDsHYFhh
UkEB3XxdFROzoZShvhfQtxSyKRP6NSmdXFB4bNAR+6e5jc9fUIPnc3zNHBjw1aBjdVf3cwmkQUrv
zH9xYo9uWhPpQKWAFy2kayECxNIh7hxFyulKY9ohDxzQPnoolL88tF0fwsV7ReIkpFIkHwKdmisn
5dq3cl25MRkoUUv72qllgfWeqc1DdIlc1tlOLw92d0awTSlIA1Bqd07Va1u+Ln6bX89hlXx+eNeo
PeAhFOdAU8vCSrTeg2nZ6GU7jkzmGhzwpAUHm9sBRy4pDRL6qAULn51fSZMcVe4gd465Z6TuyLI+
wF/wOxlI5QH3QwPmtAfS9ZvfQi8wBuCfNL0KQZUB9O0oBzRtwIPDztfbCbkmgzGKRiPOm3anP13c
ob8HZNMFc7zdeNadb/W80/BvutA+b2QfN5TaqFUs695iVn6BiQUqespdilt8zNWcomdn3J9CUFSg
EnjuBZejMWIdLsk76LE3i1XJhN4kpCe/8jc1EE7VMFeALla0QdBj0Kf6oMdfnFSwF+v4FtgZdJc8
nJArHchXg8JUGxR07wSR9oH3HJ0f2sK+ZSD/fmu7s5gPNl4b7iFubBDpAXJtkKeQN4jvALo+tFPY
Iqp/7x1e3/rWt771rW9961vf+ta3vvWtb33rW9/61re+9a1vffuztf8D6hH8sQB4AAA=
TESTS_BASE_B64_EOF

  if base64 -d "$TEST_BASE_B64" > "$TEST_BASE_TGZ" 2>/dev/null \
     || base64 --decode "$TEST_BASE_B64" > "$TEST_BASE_TGZ" 2>/dev/null; then
    mkdir -p "$TEST_DIR"
    rm -f "$TEST_DIR/self.rs" "$TEST_DIR/ml-kem.rs"
    if ! tar -xzf "$TEST_BASE_TGZ" -C "$TEST_DIR" >>"$STDERR_LOG" 2>&1; then
      echo "ERROR: could not unpack the base test sources" | tee -a "$STDERR_LOG"
      echo '{"success": false, "infrastructure_error": "test tree restore failed", "reward": 0.0}' > "$REPORT"
      echo "0" > "$REWARD"
      exit 2
    fi
  else
    echo "ERROR: could not decode the embedded base test sources" | tee -a "$STDERR_LOG"
    echo '{"success": false, "infrastructure_error": "test tree restore failed", "reward": 0.0}' > "$REPORT"
    echo "0" > "$REWARD"
    exit 2
  fi

  # Drop anything sitting where tests.patch creates a file, so the create-only
  # patch cannot collide with a file the agent happened to write itself.
  sed -n 's|^+++ b/||p' /tests/tests.patch | while IFS= read -r _created; do
    [ -n "$_created" ] && rm -f "$_created"
  done

  APPLIED=0
  if command -v git >/dev/null 2>&1; then
    if git apply /tests/tests.patch 2>>"$STDERR_LOG" \
       || git apply --3way /tests/tests.patch 2>>"$STDERR_LOG"; then
      APPLIED=1
    fi
  fi
  if [ "$APPLIED" != "1" ] && command -v patch >/dev/null 2>&1; then
    if patch -p1 --forward < /tests/tests.patch >>"$STDERR_LOG" 2>&1; then
      APPLIED=1
    fi
  fi
  if [ "$APPLIED" != "1" ]; then
    echo "ERROR: failed to apply tests/tests.patch" | tee -a "$STDERR_LOG"
    echo '{"success": false, "infrastructure_error": "tests.patch did not apply", "reward": 0.0}' > "$REPORT"
    echo "0" > "$REWARD"
    exit 2
  fi
fi

# Build the test command(s) from config (expands ${TEST_FILES}; language default
# from grading.parser.framework when execution.commands is empty).
python3 - <<'PY' > /tmp/run_tests.sh
import ast, json, shlex
cfg = json.load(open("/tests/config.json"))
execution = cfg.get("execution", {}) or {}

def parse_list(value):
    if isinstance(value, list):
        return value
    if isinstance(value, str) and value.strip():
        for p in (json.loads, ast.literal_eval):
            try:
                v = p(value)
                if isinstance(v, list):
                    return v
            except Exception:
                pass
    return []

test_files = parse_list(execution.get("selected_test_files_to_run") or [])
commands = execution.get("commands", [])
if isinstance(commands, str):
    commands = [commands]
if not commands:
    fw = ((cfg.get("grading") or {}).get("parser") or {}).get("framework", "").lower()
    # Output MUST be parseable by grade.py: pytest -v (per-test lines),
    # jest/go JSON modes. `pytest -q` prints no per-test lines -> reward 0.
    if fw == "pytest":
        commands = ["python -m pytest -v ${TEST_FILES}"]
    elif fw == "jest":
        commands = ["npx jest --json ${TEST_FILES}"]
    elif fw == "go-test":
        commands = ["go test -json ./..."]
    else:
        raise SystemExit("No execution.commands configured and no framework default")

files_arg = " ".join(shlex.quote(str(x)) for x in test_files)
# `execution.commands` is a list and the script's exit status would otherwise be
# the LAST command's, so a failing suite followed by a healthy command reads as
# success. Fail on the first one that fails.
print("set -e")
for cmd in commands:
    print(cmd.replace("${TEST_FILES}", files_arg))
PY
chmod +x /tmp/run_tests.sh

# Wrap with timeout(1) if available + configured.
TIMEOUT_SEC="$(python3 -c "import json;print((json.load(open('/tests/config.json')).get('execution') or {}).get('timeout_sec',''))" 2>/dev/null || true)"
# `-o pipefail` is passed to the runner shell itself. Shell options do not carry
# into a child bash, so the `set -uo pipefail` at the top of this file does not
# reach the generated script.
RUNNER=(bash -o pipefail /tmp/run_tests.sh)
if [ -n "${TIMEOUT_SEC:-}" ] && command -v timeout >/dev/null 2>&1; then
  RUNNER=(timeout "${TIMEOUT_SEC}" bash -o pipefail /tmp/run_tests.sh)
fi

set +e
"${RUNNER[@]}" > "$STDOUT_LOG" 2> "$STDERR_LOG"
TEST_EXIT_CODE=$?
set -e

# Grade via the embedded grader (grade.py inlined at the marker below; written to
# /tmp at runtime and invoked with the same CLI it has always used).
cat > /tmp/grade.py <<'GRADE_PY_EOF'
#!/usr/bin/env python3
"""Compact SWE-bench/Harborized verifier — parser + evaluator (`grade.py`).

This is a **generic, task-agnostic** grader and the single source of grading
truth (see ``agents/difflection`` TEST_DESIGN.md). It is NOT shipped as its own
``tests/`` file: ``config_builder.assemble_test_sh`` embeds this file's source
into the self-contained ``test.sh`` at materialize time. It does NOT run the
tests — ``test.sh`` runs them + captures logs; this grader only parses those logs
against ``config.json``'s required-test lists and writes the reward.

Division of responsibility (compact = config.json + tests.patch + test.sh):
    config.json = declarative {execution, grading, artifacts} metadata (per-task)
    tests.patch = the eval tests, applied by test.sh at verify time (per-task)
    test.sh     = self-contained verifier (runs tests + this grader, embedded)

CLI (called by test.sh)::

    python3 /tests/grade.py \
      --config /tests/config.json \
      --stdout /logs/verifier/test-stdout.txt \
      --stderr /logs/verifier/test-stderr.txt \
      --raw-exit-code <int> \
      --output /logs/verifier/output.json \
      --report /logs/verifier/report.json \
      --reward /logs/verifier/reward.txt

Exit codes: 0 = success (reward 1), 1 = grading failure (reward 0),
2 = infrastructure/parser error (reward 0). reward.txt is ALWAYS written.
"""

from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from typing import Any

# Normalized statuses; only exact PASSED counts as passed for grading.
PASSED, FAILED, ERROR, SKIPPED, UNKNOWN = (
    "PASSED",
    "FAILED",
    "ERROR",
    "SKIPPED",
    "UNKNOWN",
)


# ---------------------------------------------------------------------------
# Robust helpers
# ---------------------------------------------------------------------------
def parse_list(value: Any) -> list[str]:
    """Coerce a JSON array OR a string-encoded list into ``list[str]``.

    SWE-bench-style datasets often store list fields as strings, e.g.
    ``'["a", "b"]'`` or ``"['a', 'b']"``. All forms normalize to the same list.
    """
    if isinstance(value, list):
        return [str(x) for x in value]
    if isinstance(value, str):
        value = value.strip()
        if not value:
            return []
        for parser in (json.loads, ast.literal_eval):
            try:
                parsed = parser(value)
                if isinstance(parsed, list):
                    return [str(x) for x in parsed]
            except Exception:
                pass
    return []


def normalize_name(name: str) -> str:
    """Backslash→slash, collapse duplicate slashes, strip leading ./ and space."""
    n = name.strip().replace("\\", "/")
    n = re.sub(r"/+", "/", n)
    if n.startswith("./"):
        n = n[2:]
    return n


def _read(path: str | None) -> str:
    if not path:
        return ""
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except OSError:
        return ""


# ---------------------------------------------------------------------------
# Framework parsers — text/JSON logs → [{name, status, raw_name, source}]
# ---------------------------------------------------------------------------
_PYTEST_RE = re.compile(
    r"^(?P<name>[\w./\-\[\]]+::[^\s]+)\s+(?P<status>PASSED|FAILED|ERROR|SKIPPED)",
    re.MULTILINE,
)
# unittest verbose: "test_name (module.TestClass) ... ok|FAIL|ERROR|skipped"
_UNITTEST_RE = re.compile(
    r"^(?P<test>\w+)\s+\((?P<cls>[\w.]+)\)\s+\.\.\.\s+"
    r"(?P<status>ok|FAIL|ERROR|skipped)",
    re.MULTILINE,
)
_STATUS_MAP = {
    "passed": PASSED,
    "pass": PASSED,
    "ok": PASSED,
    "failed": FAILED,
    "fail": FAILED,
    "error": ERROR,
    "skipped": SKIPPED,
    "skip": SKIPPED,
}


def _entry(name: str, status: str, source: str) -> dict[str, str]:
    return {
        "name": normalize_name(name),
        "status": status,
        "raw_name": name,
        "source": source,
    }


def parse_pytest(stdout: str, stderr: str) -> list[dict[str, str]]:
    out: list[dict[str, str]] = []
    for m in _PYTEST_RE.finditer(stdout + "\n" + stderr):
        out.append(_entry(m.group("name"), m.group("status").upper(), "pytest"))
    return out


def parse_unittest(stdout: str, stderr: str) -> list[dict[str, str]]:
    # unittest writes verbose results to stderr by default.
    out: list[dict[str, str]] = []
    for m in _UNITTEST_RE.finditer(stdout + "\n" + stderr):
        status = _STATUS_MAP.get(m.group("status").lower(), UNKNOWN)
        out.append(_entry(f"{m.group('cls')}.{m.group('test')}", status, "unittest"))
    return out


def _find_json(text: str) -> Any:
    """Best-effort: parse the largest JSON object/array embedded in *text*."""
    text = text.strip()
    try:
        return json.loads(text)
    except Exception:
        pass
    start = text.find("{")
    end = text.rfind("}")
    if start != -1 and end > start:
        try:
            return json.loads(text[start : end + 1])
        except Exception:
            return None
    return None


def parse_jest(stdout: str, stderr: str) -> list[dict[str, str]]:
    data = _find_json(stdout) or _find_json(stderr)
    out: list[dict[str, str]] = []
    if not isinstance(data, dict):
        return out
    for suite in data.get("testResults", []):
        for a in suite.get("assertionResults", []):
            status = _STATUS_MAP.get(str(a.get("status", "")).lower(), UNKNOWN)
            title = a.get("fullName") or a.get("title") or ""
            out.append(_entry(title, status, "jest"))
    return out


def parse_mocha(stdout: str, stderr: str) -> list[dict[str, str]]:
    data = _find_json(stdout) or _find_json(stderr)
    out: list[dict[str, str]] = []
    if not isinstance(data, dict):
        return out
    for key, status in (("passes", PASSED), ("failures", FAILED), ("pending", SKIPPED)):
        for t in data.get(key, []):
            title = t.get("fullTitle") or t.get("title") or ""
            out.append(_entry(title, status, "mocha"))
    return out


def parse_go_test(stdout: str, stderr: str) -> list[dict[str, str]]:
    # `go test -json` emits one JSON object per line with Action/Test/Package.
    out: list[dict[str, str]] = []
    for line in (stdout + "\n" + stderr).splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            ev = json.loads(line)
        except Exception:
            continue
        test = ev.get("Test")
        action = ev.get("Action")
        if not test or action not in ("pass", "fail", "skip"):
            continue
        status = {"pass": PASSED, "fail": FAILED, "skip": SKIPPED}[action]
        out.append(_entry(f"{ev.get('Package', '')}::{test}", status, "go-test"))
    return out


def parse_custom(stdout: str, stderr: str, parser_cfg: dict) -> list[dict[str, str]]:
    out: list[dict[str, str]] = []
    text = stdout + "\n" + stderr
    pass_re = parser_cfg.get("pass_regex")
    fail_re = parser_cfg.get("fail_regex")
    for rx, status in ((pass_re, PASSED), (fail_re, FAILED)):
        if not rx:
            continue
        for m in re.finditer(rx, text, re.MULTILINE):
            name = m.groupdict().get("name") or (m.group(1) if m.groups() else "")
            if name:
                out.append(_entry(name, status, "custom"))
    return out


_PARSERS = {
    "pytest": parse_pytest,
    "unittest": parse_unittest,
    "jest": parse_jest,
    "mocha": parse_mocha,
    "go-test": parse_go_test,
}


def parse_results(
    framework: str, stdout: str, stderr: str, parser_cfg: dict
) -> list[dict[str, str]]:
    if framework == "custom":
        return parse_custom(stdout, stderr, parser_cfg)
    fn = _PARSERS.get(framework)
    return fn(stdout, stderr) if fn else []


# ---------------------------------------------------------------------------
# Matching: required name → parsed result (controlled, no broad fuzzy match)
# ---------------------------------------------------------------------------
def matched_passed(required: str, results: list[dict[str, str]]) -> bool:
    """True iff *required* maps to a parsed test whose status is exactly PASSED."""
    req = normalize_name(required)
    by_name: dict[str, str] = {}
    for r in results:
        # Last status wins; an exact PASSED is what we ultimately check.
        by_name[r["name"]] = r["status"]
    # 1) exact / whitespace / path-normalized (all folded into normalize_name).
    if req in by_name:
        return by_name[req] == PASSED
    # 2) unambiguous suffix match only.
    suffix_hits = [
        name
        for name in by_name
        if name.endswith("/" + req) or name.endswith("::" + req.split("::")[-1])
    ]
    if len(set(suffix_hits)) == 1:
        return by_name[suffix_hits[0]] == PASSED
    return False


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def _write(path: str, content: str) -> None:
    try:
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(content)
    except OSError as exc:  # pragma: no cover - disk failure
        sys.stderr.write(f"grade.py: could not write {path}: {exc}\n")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Compact verifier grader")
    ap.add_argument("--config", required=True)
    ap.add_argument("--stdout", default="")
    ap.add_argument("--stderr", default="")
    ap.add_argument("--raw-exit-code", type=int, default=0)
    ap.add_argument("--output", required=True)
    ap.add_argument("--report", required=True)
    ap.add_argument("--reward", required=True)
    args = ap.parse_args(argv)

    def finish(reward: float, report: dict, exit_code: int) -> int:
        report.setdefault("reward", reward)
        _write(args.output, json.dumps({"tests": report.pop("_tests", [])}, indent=2))
        _write(args.report, json.dumps(report, indent=2))
        _write(args.reward, f"{1 if reward >= 1.0 else 0}\n")
        return exit_code

    # --- load config (infra error if unreadable) ---
    try:
        with open(args.config, encoding="utf-8") as fh:
            cfg = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        return finish(
            0.0,
            {
                "success": False,
                "infrastructure_error": f"could not read config.json: {exc}",
                "raw_exit_code": args.raw_exit_code,
            },
            2,
        )

    instance_id = (cfg.get("instance") or {}).get("instance_id", "")
    grading = cfg.get("grading") or {}
    parser_cfg = grading.get("parser") or {}
    framework = (parser_cfg.get("framework") or "").lower()

    # --- required tests: required_pass, else fail_to_pass ∪ pass_to_pass ---
    f2p = parse_list(grading.get("fail_to_pass"))
    p2p = parse_list(grading.get("pass_to_pass"))
    required_explicit = parse_list(grading.get("required_pass"))
    required = required_explicit if required_explicit else [*f2p, *p2p]
    # De-dup, preserve order.
    seen: set[str] = set()
    required = [r for r in required if not (r in seen or seen.add(r))]

    stdout, stderr = _read(args.stdout), _read(args.stderr)
    results = parse_results(framework, stdout, stderr, parser_cfg)

    base_report: dict[str, Any] = {
        "instance_id": instance_id,
        "raw_exit_code": args.raw_exit_code,
        "parser_framework": framework or "unknown",
        "infrastructure_error": None,
        "_tests": results,
    }

    # Fail closed when no required tests are configured.
    if not required:
        return finish(
            0.0,
            {
                **base_report,
                "success": False,
                "infrastructure_error": "no required tests configured",
                "required_tests_count": 0,
                "passed_tests_count": 0,
                "required_tests": [],
                "passed_required_tests": [],
                "missing_required_tests": [],
                "unexpected_failures": [],
            },
            2,
        )

    passed_required = [r for r in required if matched_passed(r, results)]
    missing_required = [r for r in required if r not in passed_required]

    allow_extra = bool(grading.get("allow_extra_failures", True))
    unexpected: list[str] = []
    if not allow_extra:
        req_norm = {normalize_name(r) for r in required}
        unexpected = [
            r["name"]
            for r in results
            if r["status"] in (FAILED, ERROR) and r["name"] not in req_norm
        ]

    # Fail closed on the test command's own exit status. Without this a build
    # error, a timeout or a crash that still printed the graded lines earns a
    # reward of 1. The status is folded into the success expression rather than
    # raised as an infrastructure error, so a trial that simply does not compile
    # is still graded as a failure instead of being thrown out as invalid.
    exit_ok = args.raw_exit_code == 0
    success = not missing_required and not unexpected and exit_ok
    reward = 1.0 if success else 0.0
    return finish(
        reward,
        {
            **base_report,
            "success": success,
            "required_tests_count": len(required),
            "passed_tests_count": len(passed_required),
            "required_tests": required,
            "passed_required_tests": passed_required,
            "missing_required_tests": missing_required,
            "unexpected_failures": unexpected,
        },
        0 if success else 1,
    )


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())

GRADE_PY_EOF

python3 /tmp/grade.py \
  --config "$CONFIG" \
  --stdout "$STDOUT_LOG" \
  --stderr "$STDERR_LOG" \
  --raw-exit-code "$TEST_EXIT_CODE" \
  --output "$OUTPUT" \
  --report "$REPORT" \
  --reward "$REWARD"
GRADE_EXIT_CODE=$?

write_zero_reward_if_missing
exit "$GRADE_EXIT_CODE"
