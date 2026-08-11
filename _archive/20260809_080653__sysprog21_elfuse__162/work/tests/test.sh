#!/usr/bin/env bash
# Compact verifier entrypoint — SELF-CONTAINED (generic; shipped per task).
#
# Resolves the workspace, applies the eval tests (tests/tests.patch) at verify
# time, runs the configured test command(s), then grades via an EMBEDDED copy of
# grade.py (inlined at materialize time at the grader marker below — no sibling
# grade.py ships). Reads tests/config.json = {execution, grading, artifacts}.
# A fallback trap guarantees reward.txt exists.
# Started by a shell without arrays or pipefail (dash, ash) this script dies
# before it can write a reward, which reads as a missing verifier output rather
# than as a failure. Hand ourselves to bash instead.
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi

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

# Put the test tree back the way the base commit had it before applying the eval
# tests. The agent has had the repository to itself and may have edited a file
# these tests replace, or created one at a path they add; either way the apply
# would fail and the run would be scored as a harness fault rather than as a
# solution that did or did not work. The payload below is the base content of
# the files the eval tests overwrite, carried here because /tests is the one
# directory the verifier can always read. It is not a secret: it is the same
# content the agent already had checked out.
TEST_RESTORE_B64=/tmp/tests_base.b64
TEST_RESTORE_TGZ=/tmp/tests_base.tar.gz

cat > "$TEST_RESTORE_B64" <<'TESTS_BASE_B64_EOF'
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
2I/92I/92I/92I/92I/9+H85/gk6okORAFAAAA==
TESTS_BASE_B64_EOF

if base64 -d "$TEST_RESTORE_B64" > "$TEST_RESTORE_TGZ" 2>/dev/null \
   || base64 --decode "$TEST_RESTORE_B64" > "$TEST_RESTORE_TGZ" 2>/dev/null; then
  RESTORED="$(tar -tzf "$TEST_RESTORE_TGZ" 2>/dev/null | tr '\n' ' ')"
  if [ -z "$RESTORED" ]; then
    echo "ERROR: restore payload is unreadable" | tee -a "$STDERR_LOG"
    echo '{"success": false, "infrastructure_error": "restore payload unreadable", "reward": 0.0}' > "$REPORT"
    echo "0" > "$REWARD"
    exit 2
  fi
  # Clear every path the eval tests create, so a file the agent wrote at one of
  # them cannot block the apply.
  for path in $(sed -n 's|^+++ b/||p' /tests/tests.patch); do
    case " $RESTORED " in
      *" $path "*) ;;
      *) rm -rf "$path" ;;
    esac
  done
  tar -xzf "$TEST_RESTORE_TGZ" -C . 2>>"$STDERR_LOG" || {
    echo "ERROR: could not restore the base test tree" | tee -a "$STDERR_LOG"
    echo '{"success": false, "infrastructure_error": "test tree restore failed", "reward": 0.0}' > "$REPORT"
    echo "0" > "$REWARD"
    exit 2
  }
else
  echo "ERROR: could not decode the restore payload" | tee -a "$STDERR_LOG"
  echo '{"success": false, "infrastructure_error": "restore payload decode failed", "reward": 0.0}' > "$REPORT"
  echo "0" > "$REWARD"
  exit 2
fi

# Apply the eval tests at VERIFY time. They ship as tests/tests.patch (NOT in
# repo/), so the solving agent never saw them. git apply (plain, then 3-way for
# agent edits to neighbouring files) when git exists; otherwise fall back to
# patch(1), which patch_dockerfile injects into every task image — a slim/alpine
# base without git must not zero the reward. A hard failure means we cannot
# grade -> infra error, reward 0.
if [ -f /tests/tests.patch ]; then
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
print("set -e")
for cmd in commands:
    print(cmd.replace("${TEST_FILES}", files_arg))
PY
chmod +x /tmp/run_tests.sh

# Wrap with timeout(1) if available + configured.
TIMEOUT_SEC="$(python3 -c "import json;print((json.load(open('/tests/config.json')).get('execution') or {}).get('timeout_sec',''))" 2>/dev/null || true)"
RUNNER=(bash /tmp/run_tests.sh)
if [ -n "${TIMEOUT_SEC:-}" ] && command -v timeout >/dev/null 2>&1; then
  RUNNER=(timeout "${TIMEOUT_SEC}" bash /tmp/run_tests.sh)
fi

set +e
"${RUNNER[@]}" > "$STDOUT_LOG" 2>> "$STDERR_LOG"
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

    # A nonzero exit from the suite means the run did not complete cleanly, so
    # it cannot be a pass however the log parsed.
    success = (
        not missing_required and not unexpected and args.raw_exit_code == 0
    )
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
