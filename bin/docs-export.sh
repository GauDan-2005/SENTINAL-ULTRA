#!/usr/bin/env bash
# docs-export.sh - re-export the Sentinel Ultra Hub into docs/, and say what moved.
#
# docs/README.md used to end with "No exporter script is checked into this workspace, so this is
# a manual step". That gap is what let the 2026-08-14 difficulty-check cap sit on the Hub
# unnoticed: bin/docs-freshness.sh could see that SOMETHING had changed, and nothing could turn
# that into an updated file without a person rebuilding the pipeline from scratch.
#
# Two halves, and each is useful alone:
#   bin/docs-render.mjs    renders every tab in headless Chrome and dumps the .content DOM
#   bin/docs-html2md.py    converts one tab's HTML into the docs/ Markdown convention
#
# This script runs both, then DIFFS rather than overwrites. It never touches docs/ - it writes a
# candidate export to a scratch directory and prints, per tab, whether the live site still matches
# what is on disk. That is deliberate. docs/guidelines.md carries a local repair of a defect in the
# Hub's own page bundle, and every wholesale regeneration to date has silently reimported the
# broken commands. Diffing first means you copy across only the tabs that actually moved, which is
# how the 2026-08-18 export avoided re-applying the repair at all.
#
# Usage:
#   SENTINEL_HUB_EMAIL=you@example.com bin/docs-export.sh [out-dir]
#
# The Hub is behind a client-side email allowlist, so an approved contributor address is required.
# It is not a credential and is deliberately not stored in this repo.
#
# Exit: 0 every tab matches docs/ (the export is current), 2 at least one tab differs,
#       3 could not run (no chrome, no node, no email, network down).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="${SENTINEL_DOCS_DIR:-$ROOT/docs}"
OUT="${1:-$(mktemp -d)}"
RAW="$OUT/raw"
CAND="$OUT/candidate"

command -v google-chrome >/dev/null 2>&1 || { echo "SKIP google-chrome not installed"; exit 3; }
command -v node          >/dev/null 2>&1 || { echo "SKIP node not installed"; exit 3; }
command -v python3       >/dev/null 2>&1 || { echo "SKIP python3 not installed"; exit 3; }
[ -d "$DOCS" ] || { echo "SKIP docs/ not found at $DOCS"; exit 3; }
[ -n "${SENTINEL_HUB_EMAIL:-}" ] || {
  echo "SKIP SENTINEL_HUB_EMAIL is unset. The Hub renders nothing without an approved address."
  exit 3
}

mkdir -p "$RAW" "$CAND"

echo "# rendering the Hub"
node "$ROOT/bin/docs-render.mjs" "$RAW" || { echo "SKIP render failed"; exit 3; }

# html slug | tab label | docs/ file name
TABS=(
  "what-s-new|What's New|whats-new.md"
  "guidelines|Guidelines|guidelines.md"
  "tasking-guide|Tasking Guide|tasking-guide.md"
  "reviewer-rubric|Reviewer Rubric|reviewer-rubric.md"
  "the-harbor-framework|The Harbor Framework|harbor-framework.md"
  "glossary|Glossary|glossary.md"
  "faq|FAQ|faq.md"
  "quick-links|Quick Links|quick-links.md"
  "changelog|Changelog|changelog.md"
)

echo
echo "# converting and diffing against $DOCS"
printf '%-24s %-10s %s\n' "FILE" "STATUS" "DETAIL"
printf '%-24s %-10s %s\n' "------------------------" "----------" "------"

moved=0
for row in "${TABS[@]}"; do
  IFS='|' read -r slug label md <<<"$row"
  if [ ! -f "$RAW/$slug.html" ]; then
    printf '%-24s %-10s %s\n' "$md" "SKIP" "tab did not render"
    moved=1
    continue
  fi
  python3 "$ROOT/bin/docs-html2md.py" "$RAW/$slug.html" "$label" > "$CAND/$md" || {
    printf '%-24s %-10s %s\n' "$md" "SKIP" "conversion failed"
    moved=1
    continue
  }
  if [ ! -f "$DOCS/$md" ]; then
    printf '%-24s %-10s %s\n' "$md" "NEW" "the Hub has a tab docs/ does not carry"
    moved=1
  elif diff -q "$CAND/$md" "$DOCS/$md" >/dev/null 2>&1; then
    printf '%-24s %-10s %s\n' "$md" "same" "matches docs/ byte for byte"
  elif [ "$md" = "guidelines.md" ]; then
    # guidelines.md ALWAYS differs, and that is correct rather than stale: docs/ carries a
    # deliberate repair of shell commands the Hub itself ships broken. So a diff here is not the
    # signal - the signal is whether the diff is STILL only the repair. Check that with the repo's
    # own two commands from docs/README.md rather than by counting lines: no damaged table row may
    # survive in docs/, and the three repaired forms must be present. Anything else and the
    # Guidelines tab moved upstream, which is the one case where the repair has to be re-applied.
    n=$(diff "$CAND/$md" "$DOCS/$md" | wc -l)
    dmg=$(awk '/^\|/ && (/apk add -no-cache/||/install y /||/chmod x/||/memorymb/)' "$DOCS/$md" | wc -l)
    fix=$(grep -c 'apk add --no-cache bash\|apt-get install -y tmux\|chmod +x' "$DOCS/$md")
    if [ "$dmg" -eq 0 ] && [ "$fix" -eq 3 ]; then
      printf '%-24s %-10s %s\n' "$md" "repair" "$n diff lines, all the documented local repair"
    else
      printf '%-24s %-10s %s\n' "$md" "MOVED" "$n diff lines, and the repair no longer verifies (damaged rows=$dmg, repaired forms=$fix of 3)"
      moved=1
    fi
  else
    n=$(diff "$CAND/$md" "$DOCS/$md" | wc -l)
    printf '%-24s %-10s %s\n' "$md" "MOVED" "$n diff lines"
    moved=1
  fi
done

echo
echo "candidate export: $CAND"
echo "rendered DOM:     $RAW"

if [ "$moved" -eq 0 ]; then
  echo
  echo "PASS every tab matches docs/. The export is current and there is nothing to copy."
  exit 0
fi

cat <<'NOTE'

At least one tab differs. Before copying anything across, read these, in order:

  1. guidelines.md is EXPECTED to differ. It carries a deliberate local repair of shell commands
     that are broken in the Hub itself, plus a top-of-file comment and an inline note recording
     that. A candidate guidelines.md will always show that diff and must NOT be copied over the
     repaired one unless the Guidelines tab genuinely changed upstream - and then the repair has
     to be re-applied by hand. docs/README.md "Reapply after any re-export" has the table.

  2. Copy across only the tabs that MOVED. Regenerating the ones that did not is what reimported
     the Hub's broken commands into ALL_DOCUMENTATION.md on 2026-08-06 and again on 2026-08-13.

  3. ALL_DOCUMENTATION.md is a concatenation, not a tab. Prefer replacing the moved tab's section
     in place over rebuilding the file, for the same reason.

  4. Then update docs/manifest.json (export_date, manifest_generated, hub_bundle, and the per-file
     exported/bytes/line_count/character_count/sha256 for whatever you copied) and the narrative
     in docs/README.md. Run the hash loop in docs/README.md afterwards; it must print ok.

  5. Mirror whatever you changed into the second copy of these docs if this workspace still keeps
     one, and write a dated sync report beside it.

NOTE
exit 2
