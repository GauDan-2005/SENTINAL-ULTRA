#!/usr/bin/env bash
# learning-query.sh - return the learning/ notes that apply to a given task.
#
# CLAUDE.md Step 1 makes reading all of learning/ mandatory and then asks which notes apply
# to THIS task. That selection is done from memory today. This makes it reproducible.
#
# Usage:
#   bin/learning-query.sh --task tasks/<name>          # infer language and runner
#   bin/learning-query.sh --lang java --runner maven --phase difficulty
#   bin/learning-query.sh --candidate 'raw_exit_code'  # matching notes and LEDGER rows only
#   bin/learning-query.sh --stale                      # notes over 60 days old
#   bin/learning-query.sh --all                        # every note, ranked
#
# Reads the frontmatter schema written by learning-frontmatter:
#   status (platform-confirmed | locally-verified | reported | superseded | refuted)
#   last_verified, verified_by, evidence, applies_to {languages, runners, phases},
#   supersedes, contradicts, blocks_submission
# Notes with no frontmatter are still listed, in an UNCLASSIFIED group, so this never
# hides a note just because the metadata has not landed yet.
#
# Exit: 0 normally, 2 when a matched note has status refuted, 3 on misuse.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# SENTINEL_LEARNING_DIR exists so the query can be exercised against a scratch copy of the
# notes without writing to learning/ itself.
LEARNING="${SENTINEL_LEARNING_DIR:-$ROOT/learning}"

usage() { sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

LANG_ARG=""; RUNNER_ARG=""; PHASE_ARG=""; TASK_ARG=""; CANDIDATE=""; STALE=0; ALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --lang)    LANG_ARG="${2:-}"; shift 2 ;;
    --runner)  RUNNER_ARG="${2:-}"; shift 2 ;;
    --phase)   PHASE_ARG="${2:-}"; shift 2 ;;
    --task)    TASK_ARG="${2:-}"; shift 2 ;;
    --candidate)
      [ -n "${2:-}" ] || { echo "SKIP --candidate needs a search term" >&2; exit 3; }
      CANDIDATE="$2"; shift 2 ;;
    --stale)   STALE=1; shift ;;
    --all)     ALL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)         echo "SKIP unknown argument: $1" >&2; usage >&2; exit 3 ;;
  esac
done

if [ ! -d "$LEARNING" ]; then
  echo "SKIP learning/ not found at $LEARNING"
  exit 3
fi

# ---- infer language and runner from the task directory -----------------------------------
if [ -n "$TASK_ARG" ]; then
  BUNDLE=""
  for c in "$TASK_ARG/work" "$TASK_ARG" "$TASK_ARG/download/original" "$TASK_ARG/task"; do
    if [ -f "$c/task.toml" ]; then BUNDLE="$c"; break; fi
  done
  if [ -z "$BUNDLE" ]; then
    echo "SKIP no task.toml under $TASK_ARG (looked in work/, ./, download/original/, task/)"
    exit 3
  fi
  if [ -z "$LANG_ARG" ]; then
    LANG_ARG="$(sed -n 's/^[[:space:]]*\(coding_language\|language\)[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\2/p' \
                 "$BUNDLE/task.toml" | head -1 || true)"
  fi
  if [ -z "$RUNNER_ARG" ]; then
    REPO="$BUNDLE/environment/repo"
    if   [ -f "$REPO/pom.xml" ];           then RUNNER_ARG="maven"
    elif [ -f "$REPO/build.gradle" ] || [ -f "$REPO/build.gradle.kts" ] || [ -f "$REPO/settings.gradle" ]; then RUNNER_ARG="gradle"
    elif [ -f "$REPO/deno.json" ] || [ -f "$REPO/deno.jsonc" ]; then RUNNER_ARG="deno"
    elif [ -f "$REPO/Cargo.toml" ];        then RUNNER_ARG="cargo"
    elif [ -f "$REPO/go.mod" ];            then RUNNER_ARG="go"
    elif [ -f "$REPO/package.json" ];      then RUNNER_ARG="npm"
    elif [ -f "$REPO/pyproject.toml" ] || [ -f "$REPO/setup.py" ] || [ -f "$REPO/setup.cfg" ]; then RUNNER_ARG="pytest"
    elif [ -f "$REPO/CMakeLists.txt" ];    then RUNNER_ARG="cmake"
    fi
  fi
  echo "# task:    $TASK_ARG"
  echo "# bundle:  $BUNDLE"
fi

export LQ_LANG="$LANG_ARG" LQ_RUNNER="$RUNNER_ARG" LQ_PHASE="$PHASE_ARG"
export LQ_CANDIDATE="$CANDIDATE" LQ_STALE="$STALE" LQ_ALL="$ALL" LQ_DIR="$LEARNING" LQ_ROOT="$ROOT"

python3 - <<'PY'
import os, re, sys, datetime, glob

D      = os.environ["LQ_DIR"]
ROOT   = os.environ["LQ_ROOT"]
lang   = (os.environ.get("LQ_LANG")   or "").strip().lower()
runner = (os.environ.get("LQ_RUNNER") or "").strip().lower()
phase  = (os.environ.get("LQ_PHASE")  or "").strip().lower()
stale  = os.environ.get("LQ_STALE") == "1"
showall= os.environ.get("LQ_ALL")   == "1"
candidate = (os.environ.get("LQ_CANDIDATE") or "").strip().lower()

try:
    import yaml
    def parse_yaml(text):
        return yaml.safe_load(text) or {}
except Exception:                                    # degrade: tiny frontmatter parser
    def parse_yaml(text):
        out, stack = {}, [(0, None)]
        cur_key = None
        for raw in text.splitlines():
            if not raw.strip() or raw.lstrip().startswith("#"):
                continue
            indent = len(raw) - len(raw.lstrip())
            line = raw.strip()
            if line.startswith("- ") and cur_key:
                out.setdefault(cur_key, [])
                if isinstance(out[cur_key], list):
                    out[cur_key].append(line[2:].strip().strip('"\''))
                continue
            if ":" in line:
                k, _, v = line.partition(":")
                k, v = k.strip(), v.strip()
                if indent and cur_key and isinstance(out.get(cur_key), dict):
                    out[cur_key][k] = _scalar(v)
                elif v == "":
                    out[k] = {} if indent == 0 else out.get(k, {})
                    cur_key = k
                else:
                    out[k] = _scalar(v); cur_key = k
        return out
    def _scalar(v):
        v = v.strip()
        if v.startswith("[") and v.endswith("]"):
            return [x.strip().strip('"\'') for x in v[1:-1].split(",") if x.strip()]
        return v.strip('"\'')

def frontmatter(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    if not text.startswith("---"):
        return None, text
    end = text.find("\n---", 3)
    if end == -1:
        return None, text
    try:
        fm = parse_yaml(text[3:end])
    except Exception:
        return None, text
    return (fm if isinstance(fm, dict) else None), text[end+4:]

# one-line lesson from the README index table: | [file.md](file.md) | lesson |
lessons = {}
readme = os.path.join(D, "README.md")
if os.path.isfile(readme):
    for line in open(readme, encoding="utf-8", errors="replace"):
        m = re.match(r"\|\s*\[([^\]]+)\]\([^)]+\)\s*\|\s*(.+?)\s*\|\s*$", line)
        if m:
            lessons[m.group(1)] = re.sub(r"\*\*|`", "", m.group(2))

def aslist(v):
    if v is None: return []
    if isinstance(v, str): return [v]
    return [str(x) for x in v]

def matches(field_values, wanted):
    """[] or [any] means the note is general. Empty wanted means we cannot discriminate."""
    vals = [v.strip().lower() for v in field_values]
    if not vals or {"any", "all", "*"} & set(vals):
        return "any"
    if not wanted:
        return "unknown"
    return "yes" if wanted in vals else "no"

today = datetime.date.today()
def age_days(s):
    try:
        return (today - datetime.date.fromisoformat(str(s)[:10])).days
    except Exception:
        return None

archived = {os.path.basename(p) for p in glob.glob(os.path.join(ROOT, "_archive", "*"))}

blocking, advisory, general, unclassified, excluded = [], [], [], [], []
refuted_hit = False

for path in sorted(glob.glob(os.path.join(D, "*.md"))):
    name = os.path.basename(path)
    if name == "README.md" or name == "LEDGER.md":
        continue
    fm, _body = frontmatter(path)
    lesson = lessons.get(name, "")
    if fm is None:
        unclassified.append((name, "", "", lesson, None, ""))
        continue
    applies = fm.get("applies_to") or {}
    if not isinstance(applies, dict):
        applies = {}
    ml = matches(aslist(applies.get("languages")), lang)
    mr = matches(aslist(applies.get("runners")),   runner)
    mp = matches(aslist(applies.get("phases")),    phase)
    status = str(fm.get("status", "") or "")
    lv     = str(fm.get("last_verified", "") or "")
    blocks = str(fm.get("blocks_submission", "")).strip().lower() in ("true", "yes", "1")
    verified_by = ", ".join(aslist(fm.get("verified_by", fm.get("source_task", ""))))
    age = age_days(lv)

    if not showall and "no" in (ml, mr, mp):
        excluded.append((name, status, lv, lesson, age, verified_by))
        continue
    if status == "refuted":
        refuted_hit = True
    specific = "yes" in (ml, mr, mp)
    row = (name, status, lv, lesson, age, verified_by)
    if blocks and (specific or showall or "any" in (ml, mr)):
        blocking.append(row)
    elif specific:
        advisory.append(row)
    else:
        general.append(row)

order = {"platform-confirmed": 0, "locally-verified": 1, "reported": 2,
         "superseded": 3, "refuted": 4, "": 5}
key = lambda r: (order.get(r[1], 5), r[0])

def show(title, rows):
    if not rows:
        return
    print(f"\n== {title} ({len(rows)}) ==")
    for name, status, lv, lesson, age, vb in sorted(rows, key=key):
        agestr = f"{age}d" if age is not None else "?"
        tag = f"[{status or 'no-frontmatter'}, verified {lv or '?'} ({agestr})]"
        print(f"  {name}  {tag}")
        if vb:
            print(f"      from: {vb}")
        if lesson:
            print(f"      {lesson[:200]}")

ctx = f"lang={lang or '?'} runner={runner or '?'} phase={phase or '?'}"
print(f"# learning-query  {ctx}")

if candidate:
    print(f"# candidate: {candidate}")
    note_hits = {}
    for path in sorted(glob.glob(os.path.join(D, "*.md"))):
        name = os.path.basename(path)
        if name == "README.md":
            continue
        hits = []
        for number, raw in enumerate(open(path, encoding="utf-8", errors="replace"), 1):
            if candidate in raw.lower():
                hits.append((number, raw.strip()))
        if hits:
            note_hits[name] = hits
    if note_hits:
        print(f"\n== candidate files ({len(note_hits)}) ==")
        shown = 0
        for name in sorted(note_hits):
            hits = note_hits[name]
            if name == "LEDGER.md":
                for number, line in hits[:10]:
                    print(f"  {name}:{number}: {line[:240]}")
                    shown += 1
                if len(hits) > 10:
                    print(f"  {name}: {len(hits) - 10} more matching rows; use a narrower term")
            else:
                number, line = hits[0]
                suffix = f" ({len(hits)} matching lines)" if len(hits) > 1 else ""
                print(f"  {name}:{number}:{suffix} {line[:240]}")
                shown += 1
            if shown >= 20:
                print("  result cap reached; use a narrower term")
                break
    else:
        print("\nno candidate matches")
    sys.exit(0)

if stale:
    rows = []
    for path in sorted(glob.glob(os.path.join(D, "*.md"))):
        name = os.path.basename(path)
        if name in ("README.md", "LEDGER.md"):
            continue
        fm, _ = frontmatter(path)
        fm = fm or {}
        lv = str(fm.get("last_verified", "") or "")
        age = age_days(lv)
        vb = ", ".join(aslist(fm.get("verified_by", fm.get("source_task", ""))))
        arch = any(vb and a.startswith(vb.split("/")[-1][:20]) for a in archived) or \
               any(vb and vb in a for a in archived)
        if age is None or age > 60 or arch:
            why = []
            if age is None: why.append("no last_verified")
            elif age > 60:  why.append(f"{age} days old")
            if arch:        why.append("verified by an archived task")
            rows.append((name, str(fm.get("status", "")), lv, "; ".join(why), age, vb))
    show("STALE - re-verify before citing", rows)
    if not rows:
        print("\nno stale notes")
    sys.exit(0)

show("BLOCKING and applicable - read first", blocking)
show("APPLICABLE advisory", advisory)
show("GENERAL [any] - always in force", general)
show("UNCLASSIFIED - no frontmatter yet, treat as applicable", unclassified)
if excluded:
    print(f"\n== not applicable to this shape ({len(excluded)}) ==")
    print("  " + ", ".join(sorted(n for n, *_ in excluded)))

total = len(blocking) + len(advisory) + len(general) + len(unclassified)
print(f"\n{total} notes apply, {len(excluded)} excluded")
if refuted_hit:
    print("WARN a matched note has status refuted - do not act on it")
    sys.exit(2)
PY
