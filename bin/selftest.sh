#!/usr/bin/env bash
#
# selftest.sh — the meta-check. Every check under bin/checks/ must pass the one
# platform-ACCEPTED bundle. A check that fails an accepted bundle is a broken
# check, and this is what stops one being added.
#
# The accepted bundle is
#   _archive/20260719_045042__oliver-oloughlin_kvdex__245
# It cleared Static Checks, the Difficulty Check, a 3 of 3 Oracle Check, the
# Quality Check panel and the reviewing EC. It is READ-ONLY. Nothing here writes
# to it, to tasks/, or to any bundle.
#
# Run this before adding or changing any check.
#
# ---------------------------------------------------------------------------
# DO NOT ADD THESE FIVE CHECKS. Each one is refuted by the accepted bundle or by
# a documented platform fact. A sibling Sentinel workspace ships all five, and
# its equivalent scripts fail this bundle on five separate checks as a result.
#
#  1. `allow_extra_failures == false` as a hard failure.
#     Refutation: the field is not documented anywhere in docs/. Setting it to
#     false is correct only when the run executes exactly the graded set, and it
#     must never be ADDED to a config.json that lacks it. equalsverifier 1166
#     ships it true and was not rejected for it. WARN at most.
#
#  2. executed-test-count == len(fail_to_pass).
#     Refutation: a fail_to_pass id maps to one TOP-LEVEL test, not one
#     assertion. Deno `t.step` regrouping, pytest parametrization and JUnit
#     nesting all break the equality by design — regrouping is the prescribed
#     remedy for an over-count, so a check enforcing this would reject the fix
#     for the only static failure this workspace has ever hit.
#
#  3. Banning `git apply --3way` in solve.sh.
#     Refutation: --3way is the PRESCRIBED fix for a patch that will not apply
#     cleanly. It is not a defect. (What IS a defect is a reverse-apply FALLBACK
#     that counts as success, which is a different construct entirely.)
#
#  4. Failing a bundle because tests.patch edits pre-existing test files.
#     Refutation: what must stay byte-identical is the pre-existing test files
#     in the SHIPPED REPO at the base commit. tests.patch is how new graded tests
#     arrive, and the accepted bundle's patch edits 44 pre-existing test files.
#
#  5. Treating a `git+https://` requirement, or any build-time network use, as a
#     failure.
#     Refutation: the Dockerfile MAY use the network at build time. Only run time
#     is restricted — the agent reaches the model gateway only and the verifier
#     is airgapped. Flag non-reproducible builds and run-time fetches instead.
# ---------------------------------------------------------------------------
#
# KNOWN, ACCEPTED EXCEPTIONS
#
#  A. `_archive/.../work/environment/repo/.git/FETCH_HEAD` exists as a 0-byte
#     file, so `20-git.sh --work` on the archived working copy reports it. The
#     accepted ARTIFACT is the zip, and the zip contains no FETCH_HEAD: a git
#     command touched work/ after the zip was built, which is exactly the
#     "scrub immediately before zipping" hazard the note describes. The checks
#     default to the zip whenever one exists, so the default run is clean. This
#     is a real finding about the archived directory, not a bug in the check.
#
# usage: bin/selftest.sh [--verbose]
# exit:  0 every check passes the accepted bundle
#        1 a check failed the accepted bundle, or a forbidden check was found
#        2 the accepted bundle or a required tool is missing

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKS_DIR="$ROOT/bin/checks"
ACCEPTED="$ROOT/_archive/20260719_045042__oliver-oloughlin_kvdex__245"

VERBOSE=0
[ "${1-}" = "--verbose" ] && VERBOSE=1

n_pass=0
n_fail=0
n_skip=0

hr() { printf '%s\n' "----------------------------------------------------------------------"; }

if [ ! -d "$CHECKS_DIR" ]; then
  echo "SKIP selftest.checks $CHECKS_DIR does not exist"
  echo "0 passed, 0 failed, 1 skipped"
  exit 2
fi
if [ ! -d "$ACCEPTED" ]; then
  echo "SKIP selftest.accepted the accepted bundle is not at $ACCEPTED"
  echo "0 passed, 0 failed, 1 skipped"
  exit 2
fi

CHECKS=()
for c in "$CHECKS_DIR"/*.sh; do
  [ -f "$c" ] || continue
  CHECKS+=("$c")
done
if [ "${#CHECKS[@]}" -eq 0 ]; then
  echo "SKIP selftest.checks no checks found in $CHECKS_DIR"
  echo "0 passed, 0 failed, 1 skipped"
  exit 2
fi

echo "accepted bundle: $ACCEPTED"
echo "checks:          ${#CHECKS[@]} in $CHECKS_DIR"
hr

# ------------------------------------------- 1. every check on the accepted --

for c in "${CHECKS[@]}"; do
  name="$(basename "$c")"
  out="$("$c" "$ACCEPTED" 2>&1)"
  rc=$?
  fails="$(printf '%s\n' "$out" | grep -c '^FAIL ' || true)"
  warns="$(printf '%s\n' "$out" | grep -c '^WARN ' || true)"
  tail_line="$(printf '%s\n' "$out" | tail -1)"

  if [ "$rc" -eq 0 ] && [ "$fails" -eq 0 ]; then
    printf 'PASS selftest.%-22s %s\n' "${name%.sh}" "$tail_line"
    n_pass=$((n_pass + 1))
    [ "$VERBOSE" -eq 1 ] && printf '%s\n' "$out" | sed 's/^/     /'
  elif [ "$rc" -eq 2 ] && [ "$fails" -eq 0 ]; then
    printf 'SKIP selftest.%-22s could not run: %s\n' "${name%.sh}" "$tail_line"
    n_skip=$((n_skip + 1))
    printf '%s\n' "$out" | grep '^SKIP ' | sed 's/^/     /'
  else
    printf 'FAIL selftest.%-22s %d FAIL line(s) on the ACCEPTED bundle — the check is wrong, not the bundle\n' \
           "${name%.sh}" "$fails"
    printf '%s\n' "$out" | grep '^FAIL ' | sed 's/^/     /'
    n_fail=$((n_fail + 1))
  fi
  [ "$warns" -gt 0 ] && [ "$VERBOSE" -eq 0 ] && \
    printf '     (%d warning(s) on the accepted bundle, which is allowed)\n' "$warns"
done

hr

# ------------------------------------------------ 2. the forbidden checks -----
# Mechanical enforcement of the five refutations in the header. Each pattern
# looks for the banned concept appearing on a line that emits a hard failure.

FORBIDDEN_HITS="$(python3 - "$CHECKS_DIR" <<'PY' 2>/dev/null || true
import glob, os, re, sys
d = sys.argv[1]
rules = [
    ("allow_extra_failures as a hard fail",
     re.compile(r'fail\s+"[^"]*"[^\n]*allow_extra_failures|allow_extra_failures[^\n]*\bfail\s+"')),
    ("executed-count == len(fail_to_pass)",
     re.compile(r'fail\s+"[^"]*"[^\n]*(executed|test count)[^\n]*fail_to_pass')),
    ("a --3way ban in solve.sh",
     re.compile(r'fail\s+"[^"]*"[^\n]*3way|3way[^\n]*\bfail\s+"')),
    ("tests.patch may not edit pre-existing tests",
     re.compile(r'fail\s+"[^"]*"[^\n]*pre-existing[^\n]*test')),
    ("git+https or build-time network as a failure",
     re.compile(r'fail\s+"[^"]*"[^\n]*(git\+https|build-time network)')),
]
for path in sorted(glob.glob(os.path.join(d, "*.sh"))):
    for i, line in enumerate(open(path, encoding="utf-8", errors="replace"), 1):
        if line.lstrip().startswith("#"):
            continue
        for label, rx in rules:
            if rx.search(line):
                print("%s:%d\t%s\t%s" % (os.path.basename(path), i, label, line.strip()[:100]))
PY
)"

if [ -n "$FORBIDDEN_HITS" ]; then
  echo "FAIL selftest.forbidden a check implements one of the five refuted rules as a hard failure"
  printf '%s\n' "$FORBIDDEN_HITS" | sed 's/^/     /'
  echo "     read the DO NOT ADD block at the top of $0 before changing anything"
  n_fail=$((n_fail + 1))
else
  echo "PASS selftest.forbidden none of the five refuted rules is implemented as a hard failure"
  n_pass=$((n_pass + 1))
fi

# --------------------------------------------------- 3. the orchestrator ------

PREFLIGHT="$ROOT/bin/preflight.sh"
if [ -x "$PREFLIGHT" ]; then
  out="$("$PREFLIGHT" "$ACCEPTED" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ] || [ "$rc" -eq 2 ]; then
    echo "PASS selftest.preflight bin/preflight.sh exits $rc on the accepted bundle (0 clean, 2 warnings only)"
    n_pass=$((n_pass + 1))
  else
    echo "FAIL selftest.preflight bin/preflight.sh exits $rc on the accepted bundle"
    printf '%s\n' "$out" | grep '^FAIL ' | sed 's/^/     /'
    n_fail=$((n_fail + 1))
  fi
else
  echo "SKIP selftest.preflight bin/preflight.sh is not present or not executable"
  n_skip=$((n_skip + 1))
fi

# ---------------------------------- 3b. timed reviewer fast profile ----------

FAST_ZIP=""
for z in "$ACCEPTED"/upload/*.zip; do
  [ -f "$z" ] || continue
  FAST_ZIP="$z"
  break
done
if [ -n "$FAST_ZIP" ] && [ -x "$PREFLIGHT" ]; then
  out="$("$PREFLIGHT" --review-fast --list "$FAST_ZIP" 2>&1)"; rc=$?
  selected="$(printf '%s\n' "$out" | sed -n 's/^  -- //p')"
  expected="$(printf '%s\n' 10-static.sh 20-git.sh 30-package.sh 40-grader.sh)"
  if [ "$rc" -eq 0 ] && [ "$selected" = "$expected" ]; then
    echo "PASS selftest.preflight-review-fast selects only the four ZIP-only static reviewer checks"
    n_pass=$((n_pass + 1))
  else
    echo "FAIL selftest.preflight-review-fast selected an unexpected reviewer profile"
    printf '%s\n' "$out" | sed 's/^/     /'
    n_fail=$((n_fail + 1))
  fi
else
  echo "SKIP selftest.preflight-review-fast accepted upload zip or preflight script is unavailable"
  n_skip=$((n_skip + 1))
fi

hr

# ------------------------------------- 4. the live bundles, informational -----
# Never blocking. A FAIL here is a finding about that task, not about the check.

if [ -d "$ROOT/tasks" ]; then
  echo "live bundles (informational, a FAIL here is a finding about the task):"
  for t in "$ROOT"/tasks/*/; do
    [ -d "$t/work" ] || continue
    tn="$(basename "${t%/}")"
    for c in "${CHECKS[@]}"; do
      out="$("$c" "${t%/}" 2>&1)"; rc=$?
      fails="$(printf '%s\n' "$out" | grep -c '^FAIL ' || true)"
      if [ "$fails" -gt 0 ]; then
        printf '  %-46s %-20s %d FAIL\n' "$tn" "$(basename "$c")" "$fails"
        printf '%s\n' "$out" | grep '^FAIL ' | sed 's/^/       /'
      fi
    done
  done
fi

hr
printf '%d passed, %d failed, %d skipped\n' "$n_pass" "$n_fail" "$n_skip"
[ "$n_fail" -gt 0 ] && exit 1
exit 0
