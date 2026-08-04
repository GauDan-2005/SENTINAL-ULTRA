#!/usr/bin/env bash
# work-vs-zip-drift.sh <task-dir> [--record] [--zip PATH] [--max-report N] [--quiet]
#
# Answer one question: is work/ still the tree the uploaded zip was built from?
#
# It is not, more often than anyone expects. An editor git watcher writes
# environment/repo/.git/FETCH_HEAD into the working copy with no session command involved,
# and the next round is then re-zipped from a tree that has changed since it was verified.
# Two of three active working copies in this workspace had drifted with nothing detecting it.
#
#   --record   after a zip is verified, write upload/<name>.manifest from the zip itself
#   default    compare work/ against that manifest, or straight against the zip when no
#              manifest exists yet
#
# Manifest columns match bin/pristine-freeze.sh:
#   path <TAB> type(f|d|l) <TAB> mode(4-digit octal) <TAB> symlink-target <TAB> sha256
#
# Exit codes:
#   0  work/ matches the zip
#   1  drift found
#   2  cannot run (bad arguments, no zip, missing tool)

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: work-vs-zip-drift.sh <task-dir> [options]
  --record         write upload/<name>.manifest from the zip and exit
  --zip PATH       use this zip instead of auto-detecting upload/*.zip
  --max-report N   cap the number of drift lines printed (default 40)
  --quiet          print nothing when clean
EOF
}

TASK_DIR=""
ZIP=""
RECORD=0
MAX_REPORT=40
QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --record) RECORD=1; shift ;;
    --zip) ZIP="${2:-}"; shift 2 ;;
    --max-report) MAX_REPORT="${2:-40}"; shift 2 ;;
    -q|--quiet) QUIET=1; shift ;;
    -*) echo "SKIP unknown option $1" >&2; usage; exit 2 ;;
    *)
      if [ -n "$TASK_DIR" ]; then echo "SKIP more than one task directory given" >&2; exit 2; fi
      TASK_DIR="$1"; shift ;;
  esac
done

[ -n "$TASK_DIR" ] || { usage; exit 2; }
[ -d "$TASK_DIR" ] || { echo "SKIP $TASK_DIR is not a directory"; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "SKIP python3 not found"; exit 2; }

TASK_DIR="$(cd "$TASK_DIR" && pwd)"
WORK="$TASK_DIR/work"
UPLOAD="$TASK_DIR/upload"
[ -d "$WORK" ] || { echo "SKIP $WORK does not exist"; exit 2; }

if [ -z "$ZIP" ]; then
  mapfile -t CANDIDATES < <(find "$UPLOAD" -maxdepth 1 -type f -name '*.zip' 2>/dev/null | sort)
  if [ "${#CANDIDATES[@]}" -eq 0 ]; then
    echo "SKIP no zip in $UPLOAD - build one with bin/rezip.sh first"
    exit 2
  fi
  if [ "${#CANDIDATES[@]}" -gt 1 ]; then
    echo "SKIP more than one zip in $UPLOAD, pass --zip to choose:"
    printf '  %s\n' "${CANDIDATES[@]}"
    exit 2
  fi
  ZIP="${CANDIDATES[0]}"
fi
[ -f "$ZIP" ] || { echo "SKIP zip $ZIP not found"; exit 2; }

MANIFEST="${ZIP%.zip}.manifest"

if [ "$RECORD" -eq 1 ]; then
  ZIP="$ZIP" OUT="$MANIFEST" python3 - <<'PY'
import datetime, hashlib, os, stat, sys, zipfile

zip_path = os.environ["ZIP"]
out = os.environ["OUT"]
z = zipfile.ZipFile(zip_path)

h = hashlib.sha256()
with open(zip_path, "rb") as fh:
    for chunk in iter(lambda: fh.read(1024 * 1024), b""):
        h.update(chunk)
zip_digest = h.hexdigest()

rows = []
for info in z.infolist():
    rel = info.filename
    if rel.startswith("./"):
        rel = rel[2:]
    rel = rel.rstrip("/") if info.is_dir() else rel
    if not rel or rel == ".":
        continue
    attr = info.external_attr >> 16
    perms = attr & 0o7777
    if info.is_dir():
        kind, digest, link = "d", "-", "-"
        perms = perms or 0o755
    elif stat.S_ISLNK(attr):
        kind = "l"
        link = z.read(info).decode("utf-8", "surrogateescape")
        digest = "-"
        perms = 0o777
    else:
        kind, link = "f", "-"
        perms = perms or 0o644
        d = hashlib.sha256()
        with z.open(info) as fh:
            for chunk in iter(lambda: fh.read(1024 * 1024), b""):
                d.update(chunk)
        digest = d.hexdigest()
    rows.append((rel, kind, "%04o" % perms, link, digest))

rows.sort(key=lambda r: r[0])
with open(out, "w", encoding="utf-8") as fh:
    fh.write("# sentinel upload manifest v1\n")
    fh.write("# zip\t%s\n" % os.path.basename(zip_path))
    fh.write("# zip_sha256\t%s\n" % zip_digest)
    fh.write("# built\t%s\n" % datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
    fh.write("# columns\tpath\ttype\tmode\tsymlink-target\tsha256\n")
    for row in rows:
        fh.write("\t".join(row) + "\n")
print("PASS RECORD %d entries fingerprinted into %s" % (len(rows), os.path.basename(out)))
print("PASS RECORD zip sha256 %s" % zip_digest)
print("2 passed, 0 failed, 0 skipped")
PY
  exit 0
fi

SOURCE="manifest"
if [ ! -f "$MANIFEST" ]; then
  SOURCE="zip"
  echo "WARN NO-MANIFEST $(basename "$MANIFEST") is missing, comparing straight against the zip"
fi

set +e
ZIP="$ZIP" MANIFEST="$MANIFEST" SOURCE="$SOURCE" WORK="$WORK" \
MAX_REPORT="$MAX_REPORT" QUIET="$QUIET" python3 - <<'PY'
import hashlib, os, stat, sys, zipfile

zip_path = os.environ["ZIP"]
manifest = os.environ["MANIFEST"]
source = os.environ["SOURCE"]
work = os.environ["WORK"]
max_report = int(os.environ["MAX_REPORT"])
quiet = os.environ["QUIET"] == "1"

# The zip is built with these exclusions, so work/ carrying them is not drift.
EXCLUDE_BASENAMES = {".DS_Store"}
EXCLUDE_PREFIXES = ("__MACOSX/",)


def excluded(rel):
    if rel.startswith(EXCLUDE_PREFIXES):
        return True
    return os.path.basename(rel) in EXCLUDE_BASENAMES


expected = {}
zip_note = ""

if source == "manifest":
    with open(manifest, encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                if line.startswith("# zip_sha256"):
                    zip_note = line.split("\t", 1)[1]
                continue
            parts = line.split("\t")
            if len(parts) == 5:
                expected[parts[0]] = tuple(parts[1:])
    h = hashlib.sha256()
    with open(zip_path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    actual_zip = h.hexdigest()
    if zip_note and actual_zip != zip_note:
        print("FAIL ZIP-CHANGED the zip has been rebuilt since the manifest was written")
        print("     manifest %s" % zip_note)
        print("     on disk  %s" % actual_zip)
        print("0 passed, 1 failed, 0 skipped")
        sys.exit(1)
else:
    z = zipfile.ZipFile(zip_path)
    for info in z.infolist():
        rel = info.filename
        if rel.startswith("./"):
            rel = rel[2:]
        rel = rel.rstrip("/") if info.is_dir() else rel
        if not rel or rel == ".":
            continue
        attr = info.external_attr >> 16
        perms = attr & 0o7777
        if info.is_dir():
            expected[rel] = ("d", "%04o" % (perms or 0o755), "-", "-")
        elif stat.S_ISLNK(attr):
            expected[rel] = ("l", "0777", z.read(info).decode("utf-8", "surrogateescape"), "-")
        else:
            d = hashlib.sha256()
            with z.open(info) as fh:
                for chunk in iter(lambda: fh.read(1024 * 1024), b""):
                    d.update(chunk)
            expected[rel] = ("f", "%04o" % (perms or 0o644), "-", d.hexdigest())

drift = []
soft = []
ok = 0

# Group and other write bits differ between the machine that built the zip and the machine
# reading it back - the workspace moved filesystems once and every directory changed from
# 0775 to 0755. That is noise. The read and execute bits are not, so those still fail.
SIGNIFICANT = 0o755


def mode_note(rel, want, got):
    if want & SIGNIFICANT != got & SIGNIFICANT:
        drift.append("FAIL MODE %s expected=0%04o actual=0%04o" % (rel, want, got))
        return False
    if want != got:
        soft.append(rel)
    return True


def sha256_of(p):
    h = hashlib.sha256()
    with open(p, "rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


seen = set()
for dirpath, dirnames, filenames in os.walk(work, followlinks=False):
    rel_dir = os.path.relpath(dirpath, work)
    rel_dir = "" if rel_dir == "." else rel_dir
    for name in list(dirnames):
        rel = name if not rel_dir else rel_dir + "/" + name
        full = os.path.join(dirpath, name)
        if os.path.islink(full):
            dirnames.remove(name)
            filenames.append(name)
            continue
        seen.add(rel)
    for name in filenames:
        rel = name if not rel_dir else rel_dir + "/" + name
        seen.add(rel)

for rel in sorted(seen):
    full = os.path.join(work, rel)
    if excluded(rel):
        continue
    st = os.lstat(full)
    kind = "l" if stat.S_ISLNK(st.st_mode) else ("d" if stat.S_ISDIR(st.st_mode) else "f")
    if rel not in expected:
        drift.append("FAIL ONLY-IN-WORK %s (%s) - added since the zip was built" % (rel, kind))
        continue
    want_kind, want_mode, want_link, want_sha = expected[rel]
    if kind != want_kind:
        drift.append("FAIL TYPE %s expected=%s actual=%s" % (rel, want_kind, kind))
        continue
    if kind == "l":
        target = os.readlink(full)
        if target != want_link:
            drift.append("FAIL SYMLINK %s expected=%s actual=%s" % (rel, want_link, target))
            continue
        ok += 1
        continue
    entry_ok = mode_note(rel, int(want_mode, 8), stat.S_IMODE(st.st_mode))
    if kind == "f":
        got = sha256_of(full)
        if got != want_sha:
            drift.append("FAIL CONTENT %s expected=%s actual=%s" % (rel, want_sha[:16] + "...", got[:16] + "..."))
            entry_ok = False
    if entry_ok:
        ok += 1

for rel in sorted(expected):
    if rel not in seen:
        drift.append("FAIL ONLY-IN-ZIP %s - removed from work/ since the zip was built" % rel)

if soft:
    print(
        "WARN MODE-NOISE %d entries differ only in the group or other write bit, first=%s"
        % (len(soft), ", ".join(soft[:3]))
    )

if drift:
    shown = drift[:max_report]
    for line in shown:
        print(line)
    if len(drift) > len(shown):
        print("FAIL TRUNCATED %d further differences not shown" % (len(drift) - len(shown)))
elif not quiet:
    print("PASS NO-DRIFT work/ matches %s across %d entries" % (os.path.basename(zip_path), ok))

print("%d passed, %d failed, %d skipped" % (ok, len(drift), 1 if soft else 0))
sys.exit(1 if drift else 0)
PY
RC=$?
set -e
exit "$RC"
