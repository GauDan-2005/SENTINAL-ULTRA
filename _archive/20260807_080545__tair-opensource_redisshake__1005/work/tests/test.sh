#!/usr/bin/env bash
# Compact verifier entrypoint — SELF-CONTAINED (generic; shipped per task).
#
# Resolves the workspace, applies the eval tests (tests/tests.patch) at verify
# time, runs the configured test command(s), then grades via an EMBEDDED copy of
# grade.py (inlined at materialize time at the grader marker below — no sibling
# grade.py ships). Reads tests/config.json = {execution, grading, artifacts}.
# A fallback trap guarantees reward.txt exists.
# The harness may hand this script to /bin/sh. Everything below needs bash,
# so re-exec under it rather than dying on the first array or [[ ]].
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

# ---------------------------------------------------------------------------
# Restore the test tree BEFORE applying the eval tests.
#
# The solving agent works in this same tree. It may add, edit or delete test
# files, including at the paths tests/tests.patch creates, and any of those
# makes the patch fail to apply and scores the trial invalid rather than wrong.
# The verify-time workspace is NOT a git repository, so nothing here leans on
# git: the base test files travel as a gzipped tar embedded in this script.
#
# Every *_test.go goes first. That clears whatever the agent wrote, which would
# otherwise collide with a created path, fail to compile and take its whole
# package down, or fail on its own and trip the exit-code gate below. The list
# of files to put back is the archive's own contents, so the two cannot drift.
# ---------------------------------------------------------------------------
SENTINEL_TESTS_B64="/tmp/sentinel_tests_base.tar.gz.b64"
SENTINEL_TESTS_TGZ="/tmp/sentinel_tests_base.tar.gz"

sentinel_restore_failed() {
  echo "ERROR: could not restore the base test tree" | tee -a "$STDERR_LOG"
  echo '{"success": false, "infrastructure_error": "base test tree restore failed", "reward": 0.0}' > "$REPORT"
  echo "0" > "$REWARD"
  exit 2
}

cat > "$SENTINEL_TESTS_B64" <<'SENTINEL_TESTS_B64_EOF'
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
AgoooIACCiiggAIKKKCAO8B/AZq/DEEAUAAA
SENTINEL_TESTS_B64_EOF

if ! ( base64 -d "$SENTINEL_TESTS_B64" > "$SENTINEL_TESTS_TGZ" 2>/dev/null \
       || base64 --decode "$SENTINEL_TESTS_B64" > "$SENTINEL_TESTS_TGZ" 2>/dev/null ); then
  sentinel_restore_failed
fi

# rm -rf rather than -delete, and no -type filter: a directory or a symlink left at a path
# tests.patch creates would survive a file-only wipe, fail the apply, and score the trial
# invalid instead of wrong.
find . -name '*_test.go' -not -path './.git/*' -exec rm -rf {} + 2>>"$STDERR_LOG" || true
tar -xzf "$SENTINEL_TESTS_TGZ" -C . 2>>"$STDERR_LOG" || sentinel_restore_failed

  [ -f "internal/commands/keys_test.go" ] || sentinel_restore_failed
  [ -f "internal/filter/function_test.go" ] || sentinel_restore_failed
  [ -f "internal/rdb/types/set_test.go" ] || sentinel_restore_failed
  [ -f "internal/reader/sync_standalone_reader_test.go" ] || sentinel_restore_failed
  [ -f "internal/utils/crc_test.go" ] || sentinel_restore_failed

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
# set -e so a failing command in a multi-command list propagates its status
# instead of the runner reporting the LAST command's.
print("set -e")
for cmd in commands:
    print(cmd.replace("${TEST_FILES}", files_arg))
PY
chmod +x /tmp/run_tests.sh

# Wrap with timeout(1) if available + configured.
TIMEOUT_SEC="$(python3 -c "import json;print((json.load(open('/tests/config.json')).get('execution') or {}).get('timeout_sec',''))" 2>/dev/null || true)"
# bash -o pipefail: the runner is a child shell and inherits no shell options
# from this script, so a piped test command would otherwise report the LAST
# stage's status and the exit-code gate below would never fire.
RUNNER=(bash -o pipefail /tmp/run_tests.sh)
if [ -n "${TIMEOUT_SEC:-}" ] && command -v timeout >/dev/null 2>&1; then
  RUNNER=(timeout "${TIMEOUT_SEC}" bash -o pipefail /tmp/run_tests.sh)
fi

set +e
# append, do not truncate: the restore and the patch apply above write their diagnostics
# to this same file, and those are the lines you need when a run fails only on the platform.
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

    # Fail closed. A run that exited nonzero did not succeed, whatever the log
    # happens to contain: a compile error, a panic, a timeout or a partly
    # executed suite can all leave the expected PASS lines behind. Gated inside
    # the success expression rather than as an early infrastructure_error exit,
    # so a failing agent stays an ordinary grading failure and not an invalid
    # trial.
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
