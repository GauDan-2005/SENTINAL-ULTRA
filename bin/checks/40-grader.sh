#!/usr/bin/env bash
#
# 40-grader.sh — statically prove that tests/test.sh fails closed.
#
# The flagship defect. The STOCK harness computes
#
#     success = not missing_required and not unexpected
#
# and never reads the `raw_exit_code` it recorded three lines earlier, so an
# untouched bundle is already fail-open: a compile failure, a timeout, a crash or
# a partially executed suite can leave every expected test name in the log and
# still be awarded 1.0. `docs/guidelines.md` states the invariant the other way
# round — the exit code should match the reward it writes — and a reviewer will
# reproduce the mismatch.
#
# Four things have to hold together, and each one alone is insufficient:
#   1. the success expression reads the raw exit status
#   2. `execution.commands` is a list, so the runner's status is the LAST
#      command's unless the generated runner opens with `set -e`
#   3. `bash /tmp/run_tests.sh` is a child shell and inherits no shell options,
#      so a piped command needs `bash -o pipefail` at the invocation
#   4. the gate lives INSIDE the success expression, never as an early
#      infrastructure_error exit — that reclassifies every non-compiling agent as
#      an invalid trial and poisons the difficulty run
#
# What this check deliberately does NOT do: require allow_extra_failures to be
# false, and require the executed test count to equal len(fail_to_pass). Both
# are refuted by the accepted bundle. See bin/selftest.sh.
#
# usage: 40-grader.sh [--work|--zip] <task-dir|bundle-dir|zip>
# exit:  0 clean, 1 a real defect, 2 could not run

# shellcheck source=_common.inc
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.inc"

if parse_mode "${1-}"; then shift; fi
ARG="${1-}"
[ -n "$ARG" ] || usage_die "grader.args" "no task directory given"

need python3 || { skip "grader.python3" "python3 is not available"; summary || true; exit 2; }
resolve_input "$PREFER" "$ARG" || usage_die "grader.args" "cannot resolve a bundle from $ARG"
B="$BUNDLE_DIR"
report_source

TS="$B/tests/test.sh"
CFG="$B/tests/config.json"
if [ ! -f "$TS" ]; then
  fail "grader.present" "tests/test.sh is missing"
  summary || true
  exit 1
fi

REPORT="$(mktempdir)/report"
python3 - "$TS" "$CFG" > "$REPORT" <<'PY' || true
import json, re, sys

ts_path, cfg_path = sys.argv[1], sys.argv[2]
src = open(ts_path, encoding="utf-8", errors="replace").read()
lines = src.splitlines()

try:
    cfg = json.load(open(cfg_path, encoding="utf-8"))
except Exception:
    cfg = {}
execution = cfg.get("execution") or {}
grading = cfg.get("grading") or {}
commands = execution.get("commands") or []
if isinstance(commands, str):
    commands = [commands]

out = []
def emit(verdict, cid, msg, *details):
    out.append((verdict, cid, msg, details))

# ------------------------------------------------ 1. head shell options ------
head = "\n".join(lines[:15])
m = re.search(r"^\s*set\s+-([A-Za-z]+)(?:\s+-o\s+(\w+))?", head, re.M)
opts = ""
pipefail_head = bool(re.search(r"set\s+-[A-Za-z]*o?\s*pipefail|set\s+-o\s+pipefail", head))
if m:
    opts = m.group(1)
if not m:
    emit("FAIL", "grader.set-options",
         "tests/test.sh opens with no `set -` line at all, so an unset variable or a failing "
         "command passes silently")
else:
    missing = []
    if "u" not in opts:
        missing.append("-u")
    if not pipefail_head:
        missing.append("pipefail")
    if missing:
        emit("FAIL", "grader.set-options",
             "tests/test.sh head is missing %s (found `set -%s`)" % (" and ".join(missing), opts))
    elif "e" not in opts:
        # The stock harness ships `set -uo pipefail` and toggles errexit by hand
        # around the runner so a failing suite is graded rather than aborted.
        # That is the accepted bundle's shape, so it is a WARN, not a FAIL.
        has_toggle = bool(re.search(r"^\s*set \+e\s*$", src, re.M)) and \
                     bool(re.search(r"^\s*set -e\s*$", src, re.M))
        if has_toggle:
            emit("PASS", "grader.set-options",
                 "`set -%s` at the head with an explicit set +e / set -e around the runner" % opts)
        else:
            emit("WARN", "grader.set-options",
                 "`set -%s` at the head: errexit is off and no set +e / set -e toggle was found" % opts)
    else:
        emit("PASS", "grader.set-options", "`set -%s` at the head" % opts)

# ------------------------------------------ 2. the success expression --------
records_exit = "raw_exit_code" in src or "TEST_EXIT_CODE" in src

succ = [(i, l) for i, l in enumerate(lines) if re.search(r"^\s*success\s*=", l)]
if not succ:
    emit("WARN", "grader.fail-closed",
         "no `success =` expression found in tests/test.sh, the grader shape could not be read "
         "statically — confirm by hand that a nonzero test exit cannot be awarded reward 1.0")
else:
    # take the last one; the embedded grader is appended after the shell body
    idx, line = succ[-1]
    expr = line
    j = idx
    while expr.rstrip().endswith(("\\", "(", "and", "or", "+")) and j + 1 < len(lines):
        j += 1
        expr += " " + lines[j].strip()
    gated = "raw_exit_code" in expr
    trace = ""
    if not gated:
        # one hop: success may name a variable that is itself derived from the
        # exit status (libcrux: `exit_ok = args.raw_exit_code == 0`).
        rhs = expr.split("=", 1)[1]
        for name in set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", rhs)):
            if name in ("not", "and", "or", "True", "False", "args"):
                continue
            for dl in lines:
                if re.search(r"^\s*%s\s*=" % re.escape(name), dl) and "raw_exit_code" in dl:
                    gated = True
                    trace = "%s -> %s" % (name, dl.strip())
                    break
            if gated:
                break
    if gated:
        emit("PASS", "grader.fail-closed",
             "the success expression gates on the raw test exit status",
             "test.sh:%d %s" % (idx + 1, expr.strip()),
             *( [trace] if trace else [] ))
    elif records_exit:
        emit("FAIL", "grader.fail-closed",
             "tests/test.sh records a raw exit status and the success expression never reads it — "
             "this is the stock fail-open grader, add `and args.raw_exit_code == 0`",
             "test.sh:%d %s" % (idx + 1, expr.strip()))
    else:
        emit("FAIL", "grader.fail-closed",
             "the success expression ignores the test command's exit status and no exit status is "
             "captured anywhere",
             "test.sh:%d %s" % (idx + 1, expr.strip()))

# ---------------------------------- 3. the gate must not be an early exit -----
# An early `infrastructure_error` on a nonzero TEST exit reclassifies the trial
# as invalid. infrastructure_error for a missing config, a missing workspace, a
# failed restore or a patch that did not apply is correct and is not flagged.
bad_infra = []
for i, l in enumerate(lines):
    if not re.search(r"(TEST_EXIT_CODE|RAW_EXIT|raw_exit_code)\b", l):
        continue
    if not re.search(r"(-ne\s+0|!=\s*0|-gt\s+0|>\s*0)", l):
        continue
    window = "\n".join(lines[i:i + 8])
    if "infrastructure_error" in window and not re.search(
            r'infrastructure_error"?\s*[:=]\s*(None|null)', window):
        bad_infra.append("test.sh:%d %s" % (i + 1, l.strip()))
if bad_infra:
    emit("FAIL", "grader.gate-placement",
         "a nonzero TEST exit writes infrastructure_error — the difficulty harness reads that as "
         "an invalid trial, not an agent failure. Gate inside the success expression instead",
         *bad_infra[:4])
else:
    emit("PASS", "grader.gate-placement",
         "no nonzero-test-exit path writes infrastructure_error")

# ------------------------------------------- 4. the runner invocation --------
runner_lines = [(i, l) for i, l in enumerate(lines)
                if "run_tests.sh" in l and re.search(r"\b(bash|sh)\b", l)]
invocations = [(i, l) for i, l in runner_lines if re.search(r"RUNNER=\(|^\s*(timeout\s+)?(bash|sh)\b", l.strip())]
if not invocations:
    invocations = runner_lines

has_pipeline = any("|" in c for c in commands)
if not invocations:
    emit("WARN", "grader.runner-pipefail",
         "could not find the generated-runner invocation, cannot check for `bash -o pipefail`")
else:
    missing_pf = [ "test.sh:%d %s" % (i + 1, l.strip())
                   for i, l in invocations if "-o pipefail" not in l ]
    if has_pipeline and missing_pf:
        emit("FAIL", "grader.runner-pipefail",
             "execution.commands contains a pipeline and the runner is invoked without "
             "`bash -o pipefail` — the status captured is the last stage's, essentially always 0",
             *missing_pf[:4])
    elif has_pipeline:
        emit("PASS", "grader.runner-pipefail",
             "piped command and the runner is invoked with `bash -o pipefail`")
    elif missing_pf:
        emit("PASS", "grader.runner-pipefail",
             "no command is a pipeline, `-o pipefail` on the runner is not required")
    else:
        emit("PASS", "grader.runner-pipefail",
             "runner invoked with `bash -o pipefail`")

# ------------------------------------------- 5. set -e in the runner ---------
emits_set_e = bool(re.search(r'print\(\s*["\']set -e', src)) or \
              bool(re.search(r'^\s*echo\s+["\']?set -e', src, re.M)) or \
              bool(re.search(r'^set -e$', src, re.M) and "run_tests.sh" in src and False)
n_cmds = len(commands)
if n_cmds > 1 and not emits_set_e:
    emit("FAIL", "grader.runner-errexit",
         "execution.commands has %d entries and the generated runner does not open with `set -e`, "
         "so the status is the LAST command's and a failing suite followed by a healthy step "
         "reports 0" % n_cmds)
elif n_cmds > 1:
    emit("PASS", "grader.runner-errexit",
         "%d commands and the generated runner opens with `set -e`" % n_cmds)
else:
    emit("PASS", "grader.runner-errexit",
         "%d command configured, `set -e` in the runner is not required" % n_cmds)

# --------------------------------------------------- 6. `|| true` on the suite --
sloppy = [ "test.sh:%d %s" % (i + 1, l.strip())
           for i, l in enumerate(lines)
           if ("run_tests.sh" in l or 'RUNNER[@]' in l) and re.search(r"\|\|\s*true", l) ]
if sloppy:
    emit("FAIL", "grader.no-swallow",
         "the line that runs the suite ends in `|| true`, which throws the status away",
         *sloppy[:4])
else:
    emit("PASS", "grader.no-swallow", "no `|| true` on the line that runs the suite")

# -------------------------------------- 7. reward file consistency ------------
if re.search(r'echo\s+"?1(\.0)?"?\s*>\s*"?\$?\{?REWARD', src) and "raw_exit_code" not in src:
    emit("WARN", "grader.reward-write",
         "reward 1 is written by the shell without any reference to the test exit status")
else:
    emit("PASS", "grader.reward-write", "reward is written by the grader, not by an unguarded shell echo")

# ---------------------------------- 8. advisory: config grading shape ---------
aef = grading.get("allow_extra_failures", "ABSENT")
if aef == "ABSENT":
    emit("PASS", "grader.allow-extra-failures",
         "the field is absent — leave it absent, never add it to a config that lacks it")
elif aef is True:
    emit("WARN", "grader.allow-extra-failures",
         "allow_extra_failures is true, so an unexpected failure outside the graded set is "
         "ignored. Set it to false only if the run executes exactly the graded set")
else:
    emit("PASS", "grader.allow-extra-failures", "allow_extra_failures is false")

p2p = grading.get("pass_to_pass") or []
if not p2p:
    emit("WARN", "grader.pass-to-pass",
         "pass_to_pass is empty, so the bundle ships no regression guard. Not a documented "
         "violation, but reviewers read it as a weak verifier")
else:
    emit("PASS", "grader.pass-to-pass", "%d regression guards in pass_to_pass" % len(p2p))

for verdict, cid, msg, details in out:
    print("%s\t%s\t%s" % (verdict, cid, msg))
    for d in details:
        print("\t\t%s" % d)
PY

if [ ! -s "$REPORT" ]; then
  skip "grader.analysis" "the static analysis of tests/test.sh produced no result"
  summary || true
  exit 2
fi

while IFS= read -r line; do
  case "$line" in
    $'\t\t'*) note "${line#$'\t\t'}" ;;
    *)
      v="${line%%$'\t'*}"; rest="${line#*$'\t'}"
      cid="${rest%%$'\t'*}"; msg="${rest#*$'\t'}"
      case "$v" in
        PASS) pass "$cid" "$msg" ;;
        FAIL) fail "$cid" "$msg" ;;
        WARN) warn "$cid" "$msg" ;;
        *)    skip "$cid" "$msg" ;;
      esac
      ;;
  esac
done < "$REPORT"

# ------------------------------------------------------------ script modes ----
# 30-package checks the modes inside the zip. This one checks the source tree,
# because a 0644 entrypoint fails at run time and nothing local catches it.
for s in tests/test.sh solution/solve.sh; do
  [ -f "$B/$s" ] || continue
  m="$(stat -c '%a' "$B/$s" 2>/dev/null || stat -f '%Lp' "$B/$s" 2>/dev/null || echo "")"
  if [ "$m" = "755" ]; then
    pass "grader.mode.$s" "0755"
  elif [ -x "$B/$s" ]; then
    warn "grader.mode.$s" "0$m, executable but not exactly 0755"
  else
    fail "grader.mode.$s" "0$m — not executable. chmod 0755"
  fi
done

summary
