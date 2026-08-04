#!/usr/bin/env bash
#
# 10-static.sh — reproduce the platform's 20 upload static checks locally, plus
# the task.toml limits from CLAUDE.md Section 8 that the platform enforces later.
#
# Specification: learning/static-checks.md. That note is written from a real
# CodeBuild log, so the check ids below mirror the platform's own grouping:
#   4 required directories, 9 required files, prompt, config, tests, agent
#   timeout, no remote, no reflog, .git size = 20.
#
# It runs against the EXTRACTED ZIP by default. Both times a static check failed
# on a real upload, the working copy looked clean and the zip did not, so a pass
# read off work/ is worth very little. When no zip exists yet the check still
# runs against the working copy and says so with a WARN, because it is useful
# during the fix loop as well as before upload.
#
# usage: 10-static.sh [--work|--zip] <task-dir|bundle-dir|zip>
# exit:  0 clean, 1 a real defect, 2 could not run

# shellcheck source=_common.inc
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.inc"

if parse_mode "${1-}"; then shift; fi
ARG="${1-}"
[ -n "$ARG" ] || usage_die "static.args" "no task directory given"

need python3 || { skip "static.python3" "python3 is not available"; summary || true; exit 2; }

# Prefer the zip. resolve_input with --zip fails when there is no zip, so try
# that first and fall back to the working copy with a warning.
if [ "$PREFER" = "work" ]; then
  resolve_input work "$ARG" || usage_die "static.args" "cannot resolve a bundle from $ARG"
else
  if ! resolve_input zip "$ARG" 2>/dev/null; then
    BUNDLE_DIR=""; BUNDLE_SRC=""
    resolve_input work "$ARG" || usage_die "static.args" "cannot resolve a bundle from $ARG"
  fi
fi

B="$BUNDLE_DIR"
report_source
if [ "$BUNDLE_SRC" != "zip" ]; then
  warn "input.source" "no zip found, ran against the working copy. Re-run after zipping, because that is the artifact the platform checks"
fi

F2P_MIN="$(fact fail_to_pass_min 10)"
F2P_MAX="$(fact fail_to_pass_max 20)"
TESTS_ALLOWED="$(fact tests_allowed_files "config.json grade.py test.sh tests.patch")"
AGENT_MAX="$(fact agent_timeout_sec_max 7200)"
VERIFIER_MAX="$(fact verifier_timeout_sec_max 1800)"
BUILD_MAX="$(fact build_timeout_sec_max 1800)"
MEM_MIN="$(fact memory_mb_min 2048)"
MEM_MAX="$(fact memory_mb_max 16384)"
STO_MIN="$(fact storage_mb_min 5120)"
STO_MAX="$(fact storage_mb_max 10240)"
GIT_MAX_MB="$(fact git_max_mb 100)"

# ------------------------------------------------------- 1-4  directories --

for d in environment environment/repo solution tests; do
  if [ -d "$B/$d" ]; then
    pass "static.dir.$d" "present"
  else
    fail "static.dir.$d" "required directory missing"
  fi
done

# ------------------------------------------------------------ 5-13  files --

for f in task.toml instruction.md environment/Dockerfile environment/problem_statement.md \
         solution/solve.sh tests/test.sh tests/tests.patch tests/config.json; do
  if [ -f "$B/$f" ]; then
    pass "static.file.$f" "present"
  else
    fail "static.file.$f" "required file missing"
  fi
done

# solution/golden.patch is the name the checker lists. A reverse-diff task ships
# init_state.patch instead and solve.sh applies it with -R, which is a legitimate
# shape (CLAUDE.md Section 9) — that is a WARN, not a FAIL. A bundle still
# carrying the dead draft name solution.patch is a FAIL, it has to be renamed.
if [ -f "$B/solution/golden.patch" ]; then
  pass "static.file.solution/golden.patch" "present"
elif [ -f "$B/solution/init_state.patch" ]; then
  warn "static.file.solution/golden.patch" "absent, bundle ships init_state.patch (reverse-diff task)"
elif [ -f "$B/solution/solution.patch" ]; then
  fail "static.file.solution/golden.patch" "bundle ships the dead draft name solution.patch — rename it"
else
  fail "static.file.solution/golden.patch" "no solution patch of any name found"
fi

# --------------------------------------------------------- 14  prompt copy --

if [ -f "$B/instruction.md" ] && [ -f "$B/environment/problem_statement.md" ]; then
  if cmp -s "$B/instruction.md" "$B/environment/problem_statement.md"; then
    pass "static.prompt" "problem_statement.md is byte-identical to instruction.md"
  else
    fail "static.prompt" "problem_statement.md differs from instruction.md"
    note "$(diff "$B/instruction.md" "$B/environment/problem_statement.md" 2>&1 | sed -n '1,5p' || true)"
  fi
  # older bundles keep a second copy at the task root; all three must match
  if [ -f "$B/problem_statement.md" ] && ! cmp -s "$B/instruction.md" "$B/problem_statement.md"; then
    fail "static.prompt.legacy" "the legacy root problem_statement.md differs from instruction.md"
  fi
else
  skip "static.prompt" "one of the two prompt files is missing"
fi

# ------------------------------------------------------------- 15  config --

if [ -f "$B/tests/config.json" ]; then
  N_F2P="$(python3 - "$B/tests/config.json" <<'PY' || echo ERR
import json, sys
try:
    g = json.load(open(sys.argv[1], encoding="utf-8"))["grading"]
    print(len(g["fail_to_pass"]))
except Exception:
    print("ERR")
PY
)"
  if [ "$N_F2P" = "ERR" ]; then
    fail "static.config" "tests/config.json is unreadable or has no grading.fail_to_pass"
  elif [ "$N_F2P" -lt "$F2P_MIN" ] || [ "$N_F2P" -gt "$F2P_MAX" ]; then
    fail "static.config" "grading.fail_to_pass lists $N_F2P test(s), outside the $F2P_MIN-$F2P_MAX range"
  elif [ "$N_F2P" -eq "$F2P_MIN" ] || [ "$N_F2P" -eq "$F2P_MAX" ]; then
    warn "static.config" "fail_to_pass = $N_F2P sits exactly on the range edge, one regroup either way rejects the build"
  else
    pass "static.config" "fail_to_pass = $N_F2P is inside $F2P_MIN-$F2P_MAX"
  fi
else
  skip "static.config" "tests/config.json missing"
fi

# -------------------------------------------------------------- 16  tests --

if [ -d "$B/tests" ]; then
  bad=""
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    if [ -d "$B/tests/$entry" ]; then bad="$bad $entry/"; continue; fi
    case " $TESTS_ALLOWED " in
      *" $entry "*) ;;
      *) bad="$bad $entry" ;;
    esac
  done < <(ls -A "$B/tests" 2>/dev/null)
  if [ -n "$bad" ]; then
    fail "static.tests" "unexpected entry in tests/:$bad (allowed: $TESTS_ALLOWED)"
  else
    pass "static.tests" "tests/ holds only the allowed filenames"
  fi
else
  skip "static.tests" "tests/ missing"
fi

# ------------------------------------------------------ 17  agent timeout --

toml_get() {
  python3 - "$B/task.toml" "$1" "$2" <<'PY' 2>/dev/null || true
import sys
path, block, key = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    import tomllib
    with open(path, "rb") as fh:
        data = tomllib.load(fh)
except Exception:
    import re
    text = open(path, encoding="utf-8", errors="replace").read()
    m = re.search(r"^\[" + re.escape(block) + r"\]([\s\S]*?)(?=^\[|\Z)", text, re.M)
    if not m:
        raise SystemExit(0)
    m2 = re.search(r"^\s*" + re.escape(key) + r"\s*=\s*(.+)$", m.group(1), re.M)
    if m2:
        print(m2.group(1).strip().strip('"').split("#")[0].strip())
    raise SystemExit(0)
v = (data.get(block) or {}).get(key)
if v is None:
    raise SystemExit(0)
if isinstance(v, list):
    print(" ".join(str(x) for x in v))
elif isinstance(v, float) and v.is_integer():
    print(int(v))
else:
    print(v)
PY
}

num_le() { python3 -c "import sys;a,b=sys.argv[1:3];sys.exit(0 if float(a)<=float(b) else 1)" "$1" "$2"; }
num_in() { python3 -c "import sys;v,a,b=sys.argv[1:4];sys.exit(0 if float(a)<=float(v)<=float(b) else 1)" "$1" "$2" "$3"; }

if [ -f "$B/task.toml" ]; then
  AGENT_T="$(toml_get agent timeout_sec)"
  if [ -z "$AGENT_T" ]; then
    fail "static.agent-timeout" "[agent] timeout_sec is missing"
  elif num_le "$AGENT_T" "$AGENT_MAX"; then
    pass "static.agent-timeout" "[agent] timeout_sec = $AGENT_T (max $AGENT_MAX)"
  else
    fail "static.agent-timeout" "[agent] timeout_sec = $AGENT_T exceeds $AGENT_MAX"
  fi
else
  skip "static.agent-timeout" "task.toml missing"
fi

# ------------------------------------------------------------- 18-20  git --

REPO="$B/environment/repo"
if [ -d "$REPO/.git" ]; then
  if need git; then
    if [ -n "$(git -C "$REPO" remote 2>/dev/null)" ]; then
      fail "static.git.remote" "a remote is configured: $(git -C "$REPO" remote | tr '\n' ' ')"
    else
      pass "static.git.remote" "no remote configured"
    fi
  else
    skip "static.git.remote" "git is not available"
  fi
  if [ -d "$REPO/.git/logs" ]; then
    fail "static.git.reflog" ".git/logs exists — the reflog carries your git identity"
  else
    pass "static.git.reflog" "no reflog"
  fi
  SZ_KB="$(du -sk "$REPO/.git" 2>/dev/null | cut -f1)"
  SZ_MB=$(( ${SZ_KB:-0} / 1024 ))
  if [ "$SZ_MB" -gt "$GIT_MAX_MB" ]; then
    fail "static.git.size" ".git is ${SZ_MB} MB, over the ${GIT_MAX_MB} MB limit"
  else
    pass "static.git.size" ".git is ${SZ_MB} MB (limit ${GIT_MAX_MB} MB)"
  fi
else
  fail "static.git.remote" "environment/repo/.git is missing — the zip dropped it or the repo is not a checkout"
  skip "static.git.reflog" "no .git"
  skip "static.git.size" "no .git"
fi

read -r _PLAT_OK _PLAT_N < <(tally "static.")
note "platform static checks: $_PLAT_OK of $_PLAT_N OK"

# ------------------------------------ beyond the 20: task.toml limits (S8) --
# Not part of the upload static phase, but every one of these is a documented
# hard limit and each is a Fixable finding when it is out of range.

if [ -f "$B/task.toml" ]; then
  OS="$(toml_get environment os)"
  [ -n "$OS" ] && pass "toml.environment.os" "os = $OS" \
                || fail "toml.environment.os" "[environment] os is missing (required field)"

  CPUS="$(toml_get environment cpus)"
  case "$CPUS" in
    2|4) pass "toml.environment.cpus" "cpus = $CPUS" ;;
    "")  fail "toml.environment.cpus" "[environment] cpus is missing" ;;
    *)   fail "toml.environment.cpus" "cpus = $CPUS, must be 2 or 4" ;;
  esac

  MEM="$(toml_get environment memory_mb)"
  if [ -z "$MEM" ]; then fail "toml.environment.memory_mb" "missing"
  elif num_in "$MEM" "$MEM_MIN" "$MEM_MAX"; then pass "toml.environment.memory_mb" "memory_mb = $MEM"
  else fail "toml.environment.memory_mb" "memory_mb = $MEM, outside $MEM_MIN-$MEM_MAX"; fi

  STO="$(toml_get environment storage_mb)"
  if [ -z "$STO" ]; then fail "toml.environment.storage_mb" "missing"
  elif num_in "$STO" "$STO_MIN" "$STO_MAX"; then pass "toml.environment.storage_mb" "storage_mb = $STO"
  else fail "toml.environment.storage_mb" "storage_mb = $STO, outside $STO_MIN-$STO_MAX"; fi

  GPUS="$(toml_get environment gpus)"
  if [ "$GPUS" = "0" ]; then pass "toml.environment.gpus" "gpus = 0"
  else fail "toml.environment.gpus" "gpus = ${GPUS:-<missing>}, must be 0"; fi

  BUILD_T="$(toml_get environment build_timeout_sec)"
  if [ -z "$BUILD_T" ]; then fail "toml.environment.build_timeout_sec" "missing"
  elif num_le "$BUILD_T" "$BUILD_MAX"; then pass "toml.environment.build_timeout_sec" "build_timeout_sec = $BUILD_T"
  else fail "toml.environment.build_timeout_sec" "build_timeout_sec = $BUILD_T exceeds $BUILD_MAX"; fi

  VER_T="$(toml_get verifier timeout_sec)"
  if [ -z "$VER_T" ]; then fail "toml.verifier.timeout_sec" "missing"
  elif num_le "$VER_T" "$VERIFIER_MAX"; then pass "toml.verifier.timeout_sec" "verifier timeout_sec = $VER_T"
  else fail "toml.verifier.timeout_sec" "verifier timeout_sec = $VER_T exceeds $VERIFIER_MAX"; fi

  # network_mode is a per-block field. Stripping it is the finding, not keeping it.
  ENV_NM="$(toml_get environment network_mode)"
  AG_NM="$(toml_get agent network_mode)"
  VER_NM="$(toml_get verifier network_mode)"
  [ "$ENV_NM" = "public" ]     && pass "toml.network.environment" 'network_mode = "public"' \
                               || fail "toml.network.environment" "[environment] network_mode = ${ENV_NM:-<missing>}, expected public"
  [ "$AG_NM" = "allowlist" ]   && pass "toml.network.agent" 'network_mode = "allowlist"' \
                               || fail "toml.network.agent" "[agent] network_mode = ${AG_NM:-<missing>}, expected allowlist"
  [ "$VER_NM" = "no-network" ] && pass "toml.network.verifier" 'network_mode = "no-network"' \
                               || fail "toml.network.verifier" "[verifier] network_mode = ${VER_NM:-<missing>}, expected no-network"

  HOSTS="$(toml_get agent allowed_hosts)"
  EXPECT_HOSTS="$(fact allowed_hosts "api.portkey.ai")"
  if [ "$HOSTS" = "$EXPECT_HOSTS" ]; then pass "toml.agent.allowed_hosts" "allowed_hosts = [$HOSTS]"
  elif [ -z "$HOSTS" ]; then fail "toml.agent.allowed_hosts" "[agent] allowed_hosts is missing, expected [$EXPECT_HOSTS]"
  else warn "toml.agent.allowed_hosts" "allowed_hosts = [$HOSTS], expected [$EXPECT_HOSTS]"; fi

  for k in category source repo_license difficulty_explanation; do
    V="$(toml_get metadata "$k")"
    if [ -n "$V" ]; then
      pass "toml.metadata.$k" "present"
    else
      fail "toml.metadata.$k" "[metadata] $k is missing"
    fi
  done

  # docker_compose.yaml must not pin network_mode = "none"
  for dc in "$B/environment/docker_compose.yaml" "$B/environment/docker-compose.yaml" \
            "$B/docker_compose.yaml" "$B/docker-compose.yaml"; do
    if [ -f "$dc" ] && grep -q 'network_mode *: *"\?none' "$dc"; then
      fail "toml.compose.network" "$(basename "$dc") still pins network_mode = none"
    fi
  done
fi

summary
