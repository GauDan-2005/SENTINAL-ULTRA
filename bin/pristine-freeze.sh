#!/usr/bin/env bash
# pristine-freeze.sh <task-dir> [--zip PATH] [--force] [--keep-backup] [--dry-run]
#
# Rebuild tasks/<name>/download/original from the shipped zip, prove the extract is
# byte-for-byte, mode-for-mode and symlink-for-symlink what the zip holds, then freeze it
# read-only so nothing can quietly edit the diff target again.
#
# What it does, in order:
#   1. locate the shipped zip under <task-dir>/download/
#   2. find the inner task tree inside it (flat, task/, or <id>/<name>_harborized/)
#   3. write download/original.manifest.tsv from the zip's own central directory
#   4. re-extract with unzip -X into a fresh download/original
#   5. repair any mode or symlink the filesystem dropped, from the manifest
#   6. verify with bin/pristine-verify.sh - a content mismatch is never repaired
#   7. chmod -R a-w download/original and write download/.frozen
#
# Step 5 is not cosmetic. On a filesystem that cannot hold a mode bit or a symlink the
# repair fails and step 6 catches it, which is the whole point of the check.
#
# After freezing, download/original is read-only, so a later `cp -a download/original/. work/`
# produces a read-only work/ too. Follow it with `chmod -R u+w work`. bin/new-task.sh does.
#
# Exit codes:
#   0  frozen and verified
#   1  a real mismatch - the extract does not match the zip, nothing was frozen
#   2  cannot run (bad arguments, no zip, missing tool, refusing to overwrite)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
usage: pristine-freeze.sh <task-dir> [options]
  --zip PATH      use this zip instead of auto-detecting download/*.zip
  --force         replace an existing download/original
  --keep-backup   with --force, move the old tree aside instead of deleting it
  --dry-run       print what would happen and change nothing
EOF
}

TASK_DIR=""
ZIP=""
FORCE=0
KEEP_BACKUP=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --zip) ZIP="${2:-}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --keep-backup) KEEP_BACKUP=1; shift ;;
    --dry-run|-n) DRY_RUN=1; shift ;;
    -*) echo "SKIP unknown option $1" >&2; usage; exit 2 ;;
    *)
      if [ -n "$TASK_DIR" ]; then echo "SKIP more than one task directory given" >&2; exit 2; fi
      TASK_DIR="$1"; shift ;;
  esac
done

[ -n "$TASK_DIR" ] || { usage; exit 2; }
[ -d "$TASK_DIR" ] || { echo "SKIP $TASK_DIR is not a directory"; exit 2; }
for tool in python3 unzip; do
  command -v "$tool" >/dev/null 2>&1 || { echo "SKIP $tool not found"; exit 2; }
done

TASK_DIR="$(cd "$TASK_DIR" && pwd)"
DL="$TASK_DIR/download"
ORIG="$DL/original"
MANIFEST="$DL/original.manifest.tsv"

[ -d "$DL" ] || { echo "SKIP $DL does not exist"; exit 2; }

# ---------------------------------------------------------------- locate the shipped zip
if [ -z "$ZIP" ]; then
  mapfile -t CANDIDATES < <(find "$DL" -maxdepth 1 -type f -name '*_submission.zip' | sort)
  if [ "${#CANDIDATES[@]}" -eq 0 ]; then
    mapfile -t CANDIDATES < <(find "$DL" -maxdepth 1 -type f -name '*.zip' | sort)
  fi
  if [ "${#CANDIDATES[@]}" -eq 0 ]; then
    echo "SKIP no zip found in $DL"; exit 2
  fi
  if [ "${#CANDIDATES[@]}" -gt 1 ]; then
    echo "SKIP more than one zip in $DL, pass --zip to choose:"
    printf '  %s\n' "${CANDIDATES[@]}"
    exit 2
  fi
  ZIP="${CANDIDATES[0]}"
fi
[ -f "$ZIP" ] || { echo "SKIP zip $ZIP not found"; exit 2; }

echo "PASS ZIP using $(basename "$ZIP")"

# ------------------------------------------------- read the zip and choose the inner root
ROOT_PREFIX="$(ZIP="$ZIP" python3 - <<'PY'
import os, sys, zipfile
z = zipfile.ZipFile(os.environ["ZIP"])
names = z.namelist()
cands = sorted((n for n in names if n.endswith("task.toml")), key=lambda n: (n.count("/"), len(n)))
for n in cands:
    prefix = n[: -len("task.toml")]
    if prefix + "instruction.md" in names:
        sys.stdout.write(prefix)
        sys.exit(0)
if cands:
    sys.stdout.write(cands[0][: -len("task.toml")])
    sys.exit(0)
sys.stderr.write("no task.toml inside the zip\n")
sys.exit(2)
PY
)" || { echo "FAIL ROOT could not find the task tree inside the zip"; exit 1; }

if [ -z "$ROOT_PREFIX" ]; then
  echo "PASS ROOT task tree sits at the zip root"
else
  echo "PASS ROOT task tree sits under $ROOT_PREFIX"
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "SKIP DRY-RUN would write $MANIFEST, re-extract $ORIG, then freeze it"
  echo "0 passed, 0 failed, 1 skipped"
  exit 0
fi

# ------------------------------------------------------- refuse to clobber without --force
if [ -e "$ORIG" ] && [ "$FORCE" -ne 1 ]; then
  echo "SKIP $ORIG already exists - pass --force to rebuild it"
  exit 2
fi

# --------------------------------------------------------------- manifest from the zip
TMP_MANIFEST="$(mktemp "${TMPDIR:-/tmp}/pristine-manifest.XXXXXX")"
trap 'rm -f "$TMP_MANIFEST"' EXIT

ZIP="$ZIP" ROOT_PREFIX="$ROOT_PREFIX" OUT="$TMP_MANIFEST" python3 - <<'PY'
import datetime, hashlib, os, stat, sys, zipfile

zip_path = os.environ["ZIP"]
prefix = os.environ["ROOT_PREFIX"]
out = os.environ["OUT"]

z = zipfile.ZipFile(zip_path)

h = hashlib.sha256()
with open(zip_path, "rb") as fh:
    for chunk in iter(lambda: fh.read(1024 * 1024), b""):
        h.update(chunk)
zip_digest = h.hexdigest()

rows = []
skipped = 0
for info in z.infolist():
    name = info.filename
    if prefix:
        if not name.startswith(prefix):
            skipped += 1
            continue
        rel = name[len(prefix):]
    else:
        rel = name
    if not rel or rel in (".", "./"):
        continue
    rel = rel.rstrip("/") if info.is_dir() else rel
    if "\t" in rel or "\n" in rel:
        sys.stderr.write("path with a tab or newline cannot be manifested: %r\n" % rel)
        sys.exit(2)

    attr = info.external_attr >> 16
    fmt = stat.S_IFMT(attr)
    perms = attr & 0o7777

    if info.is_dir():
        kind = "d"
        if not perms:
            perms = 0o755
    elif fmt == stat.S_IFLNK:
        kind = "l"
    else:
        kind = "f"
        if not perms:
            perms = 0o644

    link = "-"
    digest = "-"
    if kind == "l":
        link = z.read(info).decode("utf-8", "surrogateescape")
        perms = 0o777
    elif kind == "f":
        d = hashlib.sha256()
        with z.open(info) as fh:
            for chunk in iter(lambda: fh.read(1024 * 1024), b""):
                d.update(chunk)
        digest = d.hexdigest()

    rows.append((rel, kind, "%04o" % perms, link, digest))

rows.sort(key=lambda r: r[0])

with open(out, "w", encoding="utf-8") as fh:
    fh.write("# sentinel pristine manifest v1\n")
    fh.write("# zip\t%s\n" % os.path.basename(zip_path))
    fh.write("# zip_sha256\t%s\n" % zip_digest)
    fh.write("# root_prefix\t%s\n" % (prefix or "(zip root)"))
    fh.write("# built\t%s\n" % datetime.date.today().isoformat())
    fh.write("# columns\tpath\ttype\tmode\tsymlink-target\tsha256\n")
    for row in rows:
        fh.write("\t".join(row) + "\n")

counts = {}
for row in rows:
    counts[row[1]] = counts.get(row[1], 0) + 1
sys.stderr.write(
    "PASS MANIFEST %d entries (%d files, %d dirs, %d symlinks), %d zip entries outside the task tree\n"
    % (len(rows), counts.get("f", 0), counts.get("d", 0), counts.get("l", 0), skipped)
)
PY

# ------------------------------------------------------------------------ re-extract
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/pristine-extract.XXXXXX")"
trap 'rm -f "$TMP_MANIFEST"; chmod -R u+w "$STAGE" 2>/dev/null || true; rm -rf "$STAGE"' EXIT

# unzip -X keeps the recorded ownership and permission info. -qq keeps the log short.
if ! unzip -qq -X -d "$STAGE" "$ZIP" >/dev/null; then
  echo "FAIL EXTRACT unzip returned nonzero on $ZIP"
  echo "0 passed, 1 failed, 0 skipped"
  exit 1
fi

SRC="$STAGE"
if [ -n "$ROOT_PREFIX" ]; then
  SRC="$STAGE/${ROOT_PREFIX%/}"
fi
[ -d "$SRC" ] || { echo "FAIL EXTRACT $ROOT_PREFIX missing from the extraction"; exit 1; }

if [ -e "$ORIG" ]; then
  chmod -R u+w "$ORIG" 2>/dev/null || true
  if [ "$KEEP_BACKUP" -eq 1 ]; then
    BACKUP="$ORIG.bak.$(date +%Y%m%dT%H%M%S)"
    mv "$ORIG" "$BACKUP"
    echo "WARN BACKUP previous tree moved to $(basename "$BACKUP")"
  else
    rm -rf "$ORIG"
  fi
fi

mkdir -p "$(dirname "$ORIG")"
mv "$SRC" "$ORIG"
cp "$TMP_MANIFEST" "$MANIFEST"
chmod 0644 "$MANIFEST"

# ------------------------------------- repair anything the filesystem dropped on the way
REPAIRED="$(MANIFEST="$MANIFEST" ROOT="$ORIG" python3 - <<'PY'
import os, stat, sys

manifest = os.environ["MANIFEST"]
root = os.environ["ROOT"]
repaired = 0
unrepairable = []

rows = []
with open(manifest, encoding="utf-8") as fh:
    for line in fh:
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) == 5:
            rows.append(parts)

# Deepest first so a directory's mode is fixed after its children are written.
for path, kind, mode, link, digest in sorted(rows, key=lambda r: r[0].count("/"), reverse=True):
    full = os.path.join(root, path)
    try:
        st = os.lstat(full)
    except OSError:
        continue
    actual_kind = "l" if stat.S_ISLNK(st.st_mode) else ("d" if stat.S_ISDIR(st.st_mode) else "f")
    if kind == "l" and actual_kind == "f":
        # The filesystem or the extractor flattened a symlink into a regular file whose
        # contents are the target. Put the link back.
        try:
            with open(full, "r", encoding="utf-8", errors="surrogateescape") as fh:
                body = fh.read()
            if body == link:
                os.remove(full)
                os.symlink(link, full)
                repaired += 1
                continue
        except OSError as exc:
            unrepairable.append("%s (%s)" % (path, exc))
            continue
        unrepairable.append("%s (flattened symlink whose body is not the target)" % path)
        continue
    if actual_kind != kind:
        continue
    if kind == "l":
        continue
    want = int(mode, 8)
    if stat.S_IMODE(st.st_mode) != want:
        try:
            os.chmod(full, want)
            repaired += 1
        except OSError as exc:
            unrepairable.append("%s (%s)" % (path, exc))

for item in unrepairable:
    sys.stderr.write("WARN REPAIR could not repair %s\n" % item)
sys.stdout.write(str(repaired))
PY
)"

if [ "$REPAIRED" != "0" ]; then
  echo "WARN REPAIR restored $REPAIRED modes or symlinks the extraction did not preserve"
fi

# ------------------------------------------------------------------ verify before freezing
VERIFY="$ROOT_DIR/bin/pristine-verify.sh"
if [ ! -x "$VERIFY" ]; then
  echo "FAIL VERIFY bin/pristine-verify.sh is missing or not executable"
  echo "0 passed, 1 failed, 0 skipped"
  exit 1
fi

set +e
"$VERIFY" "$TASK_DIR"
VERIFY_RC=$?
set -e

if [ "$VERIFY_RC" -ne 0 ]; then
  echo "FAIL VERIFY the extract does not match the zip - not freezing"
  echo "if the mismatch is a mode or a symlink, the filesystem under $TASK_DIR cannot hold it"
  exit 1
fi

# ------------------------------------------------------------------------------- freeze
chmod -R a-w "$ORIG"

ZIP_SHA="$(awk -F'\t' '/^# zip_sha256/ {print $2}' "$MANIFEST")"
MANIFEST_SHA="$(python3 -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$MANIFEST")"
ENTRIES="$(grep -cv '^#' "$MANIFEST" || true)"

cat > "$DL/.frozen" <<EOF
frozen_on	$(date -u +%Y-%m-%d)
frozen_at	$(date -u +%Y-%m-%dT%H:%M:%SZ)
zip	$(basename "$ZIP")
zip_sha256	$ZIP_SHA
manifest_sha256	$MANIFEST_SHA
entries	$ENTRIES
tool	bin/pristine-freeze.sh v1
EOF
chmod 0444 "$DL/.frozen"

echo "PASS FROZEN $ENTRIES entries verified and download/original is now read-only"
echo "NOTE copy it with 'cp -a download/original/. work/' then 'chmod -R u+w work'"
echo "3 passed, 0 failed, 0 skipped"
