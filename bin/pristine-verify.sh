#!/usr/bin/env bash
# pristine-verify.sh <task-dir> [--quiet] [--max-report N]
#
# Re-check tasks/<name>/download/original against download/original.manifest.tsv.
# READ-ONLY. Never touches the tree it checks.
#
# The pristine copy is the diff target for every pre-zip change gate, so it has to be
# provably the same bytes, the same mode bits and the same symlinks the platform shipped.
# Three of four reference copies in this workspace went bad without anything noticing.
#
# Manifest columns, tab separated, one line per entry, sorted by path:
#   path <TAB> type(f|d|l) <TAB> mode(4-digit octal) <TAB> symlink-target <TAB> sha256
# Lines starting with # are metadata and are skipped.
#
# When download/.frozen exists the tree is expected to be read-only, so every mode is
# compared with the write bits stripped. Without .frozen the manifest mode is compared
# as recorded.
#
# Exit codes:
#   0  clean
#   1  drift found
#   2  cannot run (bad arguments, missing directory, missing tool)
#   3  no manifest (run bin/pristine-freeze.sh first)

set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <task-dir> [--quiet] [--max-report N]" >&2
}

TASK_DIR=""
QUIET=0
MAX_REPORT=50

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -q|--quiet) QUIET=1; shift ;;
    --max-report) MAX_REPORT="${2:-50}"; shift 2 ;;
    -*) echo "SKIP unknown option $1" >&2; usage; exit 2 ;;
    *)
      if [ -n "$TASK_DIR" ]; then echo "SKIP more than one task directory given" >&2; exit 2; fi
      TASK_DIR="$1"; shift ;;
  esac
done

if [ -z "$TASK_DIR" ]; then usage; exit 2; fi
if [ ! -d "$TASK_DIR" ]; then echo "SKIP $TASK_DIR is not a directory"; exit 2; fi
command -v python3 >/dev/null 2>&1 || { echo "SKIP python3 not found"; exit 2; }

MANIFEST="$TASK_DIR/download/original.manifest.tsv"
ROOT="$TASK_DIR/download/original"

if [ ! -f "$MANIFEST" ]; then
  echo "SKIP no manifest at $MANIFEST - run bin/pristine-freeze.sh"
  # 2, not 3: the workspace contract reserves 2 for "could not run", and both
  # bin/preflight.sh and bin/pre-send.sh read 2 that way. A bare 3 reads as an
  # unknown failure to every caller.
  exit 2
fi
if [ ! -d "$ROOT" ]; then
  echo "FAIL MISSING download/original does not exist but a manifest does"
  echo "0 passed, 1 failed, 0 skipped"
  exit 1
fi

MANIFEST="$MANIFEST" ROOT="$ROOT" FROZEN="$TASK_DIR/download/.frozen" \
QUIET="$QUIET" MAX_REPORT="$MAX_REPORT" python3 - <<'PY'
import hashlib, os, stat, sys

manifest = os.environ["MANIFEST"]
root = os.environ["ROOT"]
frozen_marker = os.environ["FROZEN"]
quiet = os.environ["QUIET"] == "1"
try:
    max_report = int(os.environ["MAX_REPORT"])
except ValueError:
    max_report = 50

frozen = os.path.exists(frozen_marker)

entries = {}
bad_lines = 0
with open(manifest, "r", encoding="utf-8") as fh:
    for line in fh:
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) != 5:
            bad_lines += 1
            continue
        path, kind, mode, link, digest = parts
        entries[path] = (kind, mode, link, digest)

failures = []
ok = 0


def report(tag, path, expected, actual):
    failures.append("FAIL %s %s expected=%s actual=%s" % (tag, path, expected, actual))


def sha256_of(p):
    h = hashlib.sha256()
    with open(p, "rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def expected_mode(mode_str):
    mode = int(mode_str, 8)
    if frozen:
        mode &= ~0o222
    return mode


for path in sorted(entries):
    kind, mode, link, digest = entries[path]
    full = os.path.join(root, path)
    try:
        st = os.lstat(full)
    except OSError:
        report("MISSING", path, kind, "absent")
        continue

    actual_kind = "l" if stat.S_ISLNK(st.st_mode) else ("d" if stat.S_ISDIR(st.st_mode) else "f")
    if actual_kind != kind:
        report("TYPE", path, kind, actual_kind)
        continue

    if kind == "l":
        target = os.readlink(full)
        if target != link:
            report("SYMLINK", path, link, target)
            continue
        ok += 1
        continue

    want = expected_mode(mode)
    got = stat.S_IMODE(st.st_mode)
    entry_ok = True
    if want != got:
        report("MODE", path, "0%o" % want, "0%o" % got)
        entry_ok = False

    if kind == "f":
        try:
            actual_digest = sha256_of(full)
        except OSError as exc:
            report("HASH", path, digest, "unreadable: %s" % exc)
            continue
        if actual_digest != digest:
            report("HASH", path, digest[:16] + "...", actual_digest[:16] + "...")
            entry_ok = False

    if entry_ok:
        ok += 1

# Extras. Directories that only exist because the manifest has files inside them are not
# extras - the platform zips carry no directory entries at all.
implied_dirs = set()
for path in entries:
    parts = path.split("/")
    for i in range(1, len(parts)):
        implied_dirs.add("/".join(parts[:i]))

writable = []
for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
    rel_dir = os.path.relpath(dirpath, root)
    rel_dir = "" if rel_dir == "." else rel_dir
    # os.walk puts symlinked directories in dirnames; treat them as entries, not dirs.
    real_dirs = []
    for name in list(dirnames):
        rel = name if not rel_dir else rel_dir + "/" + name
        full = os.path.join(dirpath, name)
        if os.path.islink(full):
            if rel not in entries:
                failures.append("FAIL EXTRA %s expected=absent actual=symlink" % rel)
        else:
            real_dirs.append(name)
            if rel not in entries and rel not in implied_dirs:
                failures.append("FAIL EXTRA %s expected=absent actual=directory" % rel)
    dirnames[:] = real_dirs
    for name in filenames:
        rel = name if not rel_dir else rel_dir + "/" + name
        full = os.path.join(dirpath, name)
        if rel not in entries:
            kind = "symlink" if os.path.islink(full) else "file"
            failures.append("FAIL EXTRA %s expected=absent actual=%s" % (rel, kind))
        if frozen and not os.path.islink(full) and os.access(full, os.W_OK):
            writable.append(rel)
    if frozen and os.access(dirpath, os.W_OK):
        writable.append(rel_dir or ".")

warns = 0
lines = []
if bad_lines:
    warns += 1
    lines.append("WARN MANIFEST %d unparseable lines skipped" % bad_lines)
if not frozen:
    warns += 1
    lines.append("WARN NOT-FROZEN download/.frozen is absent, modes compared as recorded")
if frozen and writable:
    failures.append(
        "FAIL FROZEN-WRITABLE %d paths under download/original are writable, first=%s"
        % (len(writable), ", ".join(sorted(writable)[:3]))
    )

if failures:
    shown = failures[:max_report]
    lines.extend(shown)
    if len(failures) > len(shown):
        lines.append("FAIL TRUNCATED %d further mismatches not shown" % (len(failures) - len(shown)))
else:
    lines.append("PASS PRISTINE %d entries match the manifest%s" % (ok, " (frozen)" if frozen else ""))

if not quiet or failures:
    for line in lines:
        print(line)

print("%d passed, %d failed, %d skipped" % (ok, len(failures), warns))
sys.exit(1 if failures else 0)
PY
