#!/usr/bin/env bash
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
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
# ---------------------------------------------------------------------------
# Restore the test tree to its base-commit state before applying tests.patch.
# The agent works in this checkout, so anything it wrote under test/ would
# otherwise decide the reward or make the patch refuse to apply. The payload is
# a gzipped tarball of the base tree, base64'd into this file: /tests is the one
# path guaranteed mounted whenever the verifier runs at all, and the verify-time
# workspace is not a git repository, so git cannot be used for this.
# ---------------------------------------------------------------------------
TEST_TREE="test"
TEST_TREE_B64="/tmp/tests_base.tar.gz.b64"
TEST_TREE_TGZ="/tmp/tests_base.tar.gz"

cat > "$TEST_TREE_B64" <<'TESTS_BASE_B64_EOF'
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
TESTS_BASE_B64_EOF

restore_failed() {
  echo "ERROR: could not restore the base test tree" | tee -a "$STDERR_LOG"
  echo '{"success": false, "infrastructure_error": "test tree restore failed", "reward": 0.0}' > "$REPORT"
  echo "0" > "$REWARD"
  exit 2
}

if base64 -d "$TEST_TREE_B64" > "$TEST_TREE_TGZ" 2>/dev/null \
   || base64 --decode "$TEST_TREE_B64" > "$TEST_TREE_TGZ" 2>/dev/null; then
  rm -rf "$TEST_TREE"
  tar -xzf "$TEST_TREE_TGZ" -C . 2>>"$STDERR_LOG" || restore_failed
else
  restore_failed
fi

# Anything tests.patch creates is deleted first, so a file the agent wrote at a
# graded path cannot make the apply refuse with "already exists". A directory or
# a symlink at that path is removed too, which -type f would miss.
if [ -f /tests/tests.patch ]; then
  sed -n 's|^+++ b/||p' /tests/tests.patch | while IFS= read -r _created; do
    [ -n "$_created" ] && [ "$_created" != "/dev/null" ] && rm -rf "$_created"
  done
fi

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

    # Fail closed. A compile failure, a crash, a timeout or a partial run can
    # leave every expected line in the log, so the reward also needs the test
    # command's own exit status. Gated here rather than with an early
    # infrastructure_error, which the difficulty harness reads as an invalid
    # trial instead of a failed one.
    success = not missing_required and not unexpected and args.raw_exit_code == 0
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
