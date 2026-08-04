#!/usr/bin/env bash
# docs-freshness.sh - has the Sentinel Ultra Hub moved since docs/ was exported?
#
# docs/ is a dated verbatim export declared the source of truth. Nothing detects when the
# live Hub changes, and a Hub correction is exactly the kind of change that silently
# invalidates a rule (the Jul 27 entry reversed the earlier "strip network_mode" advice).
#
# The Hub is a single-page app: its content is compiled into one JS bundle, so this fetches
# the bundle and reads the dated changelog and what's-new entries straight out of it, then
# compares that set of dates against the entries present in the local export. A Hub date the
# local files do not carry is drift, whether it is newer than the export or a backdated edit.
#
# Usage: bin/docs-freshness.sh [--json] [--bundle <file>]
#   --bundle <file>  read a already-downloaded JS bundle instead of fetching (offline test)
#
# Exit: 0 no drift, 2 the Hub carries entries the export does not, 3 no network / cannot run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="${SENTINEL_DOCS_DIR:-$ROOT/docs}"
HUB="https://snorkel-ai.github.io/Sentinel_Ultra_Hub/"

JSON=0; LOCAL_BUNDLE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --json)   JSON=1; shift ;;
    --bundle) LOCAL_BUNDLE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "SKIP unknown argument: $1" >&2; exit 3 ;;
  esac
done

if [ ! -d "$DOCS" ]; then
  echo "SKIP docs/ not found at $DOCS"
  exit 3
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BUNDLE="$TMP/hub.js"
ASSET="(local file)"
if [ -n "$LOCAL_BUNDLE" ]; then
  if [ ! -f "$LOCAL_BUNDLE" ]; then echo "SKIP no such bundle: $LOCAL_BUNDLE"; exit 3; fi
  cp "$LOCAL_BUNDLE" "$BUNDLE"
else
  if ! command -v curl >/dev/null 2>&1; then
    echo "SKIP curl not installed, cannot reach the Hub"
    exit 3
  fi
  if ! curl -fsS --max-time 30 "$HUB" -o "$TMP/index.html" 2>"$TMP/curl.err"; then
    echo "SKIP could not fetch $HUB ($(tr -d '\n' < "$TMP/curl.err" | cut -c1-120))"
    echo "SKIP no network - docs freshness is UNKNOWN, do not read this as up to date"
    exit 3
  fi
  ASSET="$(grep -o 'src="[^"]*\.js"' "$TMP/index.html" | head -1 | sed 's/src="//;s/"$//')"
  if [ -z "$ASSET" ]; then
    echo "SKIP no JS bundle referenced from the Hub index - the site layout changed"
    exit 3
  fi
  case "$ASSET" in
    http*) URL="$ASSET" ;;
    /*)    URL="https://snorkel-ai.github.io${ASSET}" ;;
    *)     URL="${HUB}${ASSET}" ;;
  esac
  if ! curl -fsS --max-time 60 "$URL" -o "$BUNDLE"; then
    echo "SKIP could not fetch the Hub bundle at $URL"
    exit 3
  fi
fi

export DF_DOCS="$DOCS" DF_BUNDLE="$BUNDLE" DF_ASSET="$ASSET" DF_JSON="$JSON"

python3 - <<'PY'
import json, os, re, sys, datetime

docs   = os.environ["DF_DOCS"]
bundle = os.environ["DF_BUNDLE"]
asset  = os.environ["DF_ASSET"]
as_json= os.environ["DF_JSON"] == "1"

DATE_RE = re.compile(r"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2}),\s+(20\d\d)\b")
MONTHS  = {m: i for i, m in enumerate(
    ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"], 1)}

def norm(m):
    return datetime.date(int(m.group(3)), MONTHS[m.group(1)], int(m.group(2)))

def read(path):
    try:
        return open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return ""

# --- the export date -----------------------------------------------------------------------
export_date, export_src = None, "unknown"
man = os.path.join(docs, "manifest.json")
if os.path.isfile(man):
    try:
        data = json.load(open(man, encoding="utf-8"))
        if isinstance(data, dict):
            for k in ("exported", "exported_at", "export_date", "generated_at"):
                if data.get(k):
                    export_date, export_src = str(data[k])[:10], "docs/manifest.json"
                    break
    except Exception:
        pass
if export_date is None:
    m = re.search(r"Exported:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})", read(os.path.join(docs, "README.md")))
    if m:
        export_date, export_src = m.group(1), "docs/README.md"

# --- dates the Hub carries ------------------------------------------------------------------
btext = read(bundle)
hub = {}
for m in DATE_RE.finditer(btext):
    d = norm(m)
    ctx = btext[m.end(): m.end() + 400]
    ctx = ctx.replace("\\n", " ").replace('\\"', '"')
    ctx = re.sub(r"[^\x20-\x7e]", " ", ctx)
    ctx = re.sub(r"\s+", " ", ctx).strip()
    hub.setdefault(d, ctx[:220])

# --- dates the local export carries ---------------------------------------------------------
local = {}
for name in ("changelog.md", "whats-new.md", "ALL_DOCUMENTATION.md"):
    for m in DATE_RE.finditer(read(os.path.join(docs, name))):
        local.setdefault(norm(m), set()).add(name)

TAB_HINTS = [
    ("task.toml",       "docs/harbor-framework.md"),
    ("harbor",          "docs/harbor-framework.md"),
    ("network_mode",    "docs/harbor-framework.md"),
    ("faq",             "docs/faq.md"),
    ("quality check",   "docs/tasking-guide.md"),
    ("tasking guide",   "docs/tasking-guide.md"),
    ("submitter form",  "docs/tasking-guide.md"),
    ("fail_to_pass",    "docs/tasking-guide.md"),
    ("guidelines",      "docs/guidelines.md"),
    ("git",             "docs/guidelines.md"),
    ("verdict",         "docs/guidelines.md"),
    ("glossary",        "docs/glossary.md"),
]
def likely(text):
    t = text.lower()
    hits = [f for k, f in TAB_HINTS if k in t]
    seen, out = set(), []
    for h in hits:
        if h not in seen:
            seen.add(h); out.append(h)
    return out[:3] or ["docs/changelog.md", "docs/whats-new.md"]

drift = sorted(d for d in hub if d not in local)
newer = [d for d in drift if export_date and d.isoformat() > export_date]

if as_json:
    print(json.dumps({
        "asset": asset, "export_date": export_date, "export_source": export_src,
        "hub_dates": [d.isoformat() for d in sorted(hub)],
        "local_dates": [d.isoformat() for d in sorted(local)],
        "drift": [{"date": d.isoformat(), "text": hub[d], "likely_files": likely(hub[d])}
                  for d in drift],
    }, indent=2))
else:
    print(f"# docs freshness")
    print(f"  Hub bundle:   {asset}")
    print(f"  export date:  {export_date or 'UNKNOWN'} (from {export_src})")
    print(f"  Hub entries:  {len(hub)}   local entries: {len(local)}")
    if not hub:
        print("WARN the Hub bundle carried no dated entries - the site format may have changed")
    if not drift:
        print("PASS no Hub entries newer than the export")
    else:
        for d in drift:
            flag = "NEWER" if export_date and d.isoformat() > export_date else "MISSING"
            print(f"FAIL {d.isoformat()} [{flag}] not in the local export")
            print(f"     {hub[d]}")
            print(f"     likely affected: {', '.join(likely(hub[d]))}")
        print(f"\n{len(drift)} Hub entries the export does not carry ({len(newer)} dated after it)")
        print("Re-export docs/ and re-run bin/doclint.sh before trusting any policy statement.")

sys.exit(2 if drift else 0)
PY
