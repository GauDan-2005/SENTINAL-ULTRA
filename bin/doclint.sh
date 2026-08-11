#!/usr/bin/env bash
# doclint.sh — lint this workspace's own prose against itself.
#
# This repo's most common defect is internal contradiction: a number that is right
# in CLAUDE.md and wrong in five rule-file lines, a rule file that drifted from its
# skill twin, a path that no longer exists. Nothing else in the workspace checks the
# workspace against itself. This does.
#
# Four passes:
#   TWIN   every .cursor/rules/X.mdc equals .claude/skills/X/SKILL.md below the
#          frontmatter. CLAUDE.md mandates it and it drifts anyway.
#   PATH   every repo path named in the prose exists.
#   XREF   every "Section N" / "Step N.N" resolves to a heading in the file it
#          points at, every markdown link resolves, and every learning note is
#          indexed in learning/README.md.
#   FACT   every entry in facts.yml is stated consistently wherever it appears.
#
# It reads the tree and writes nothing. Task bundles are never touched: this is a
# prose linter, not a bundle checker. For a bundle use bin/preflight.sh.
#
# Usage:  bin/doclint.sh [--only <pass>] [--skip <pass>] [-v]
#           <pass> is one of twin path xref fact (case-insensitive, substring match)
# Exit:   0 clean, 1 a real defect was found, 2 the check could not run.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FACTS="$ROOT/facts.yml"

ONLY=""
SKIP=""
VERBOSE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --only) ONLY="${2:-}"; shift 2 ;;
    --skip) SKIP="${2:-}"; shift 2 ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help) sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "SKIP doclint unknown argument: $1" >&2; exit 2 ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "SKIP doclint python3 not found"; exit 2; }
[ -d "$ROOT" ] || { echo "SKIP doclint repo root not found"; exit 2; }

ONLY="$ONLY" SKIP="$SKIP" VERBOSE="$VERBOSE" ROOT="$ROOT" FACTS="$FACTS" \
python3 - <<'PYEOF'
import os, re, sys, difflib, glob

ROOT    = os.environ["ROOT"]
FACTS   = os.environ["FACTS"]
ONLY    = os.environ.get("ONLY", "").strip().lower()
SKIP    = os.environ.get("SKIP", "").strip().lower()
VERBOSE = os.environ.get("VERBOSE") == "1"

passed = failed = skipped = 0

def emit(status, ident, msg):
    global passed, failed, skipped
    if status == "PASS":
        passed += 1
        if not VERBOSE:
            return
    elif status == "FAIL":
        failed += 1
    elif status == "SKIP":
        skipped += 1
    print(f"{status} {ident} {msg}")

def detail(text):
    if not text:
        return
    for line in str(text).rstrip("\n").split("\n"):
        print("      " + line)

def wanted(name):
    if ONLY and ONLY not in name:
        return False
    if SKIP and SKIP in name:
        return False
    return True

def rel(p):
    return os.path.relpath(p, ROOT)

def read(p):
    with open(p, encoding="utf-8", errors="replace") as fh:
        return fh.read()

def strip_frontmatter(text):
    """Drop a leading --- ... --- block. Both twins carry one and they differ by design."""
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            nl = text.find("\n", end + 1)
            return text[nl + 1:] if nl != -1 else ""
    return text

def strip_mirror_note(text):
    """The SKILL.md copies carry a '> **Mirror.**' banner the .mdc does not."""
    out = []
    for ln in text.split("\n"):
        if ln.startswith("> **Mirror.**") or ln.startswith("> **Twin.**"):
            continue
        out.append(ln)
    return "\n".join(out)

def normalise(text):
    text = strip_mirror_note(strip_frontmatter(text))
    return [ln.rstrip() for ln in text.strip("\n").split("\n")]

def code_fence_mask(text):
    """Return a set of 0-based line indexes that sit inside a fenced code block."""
    inside = set()
    fence = None
    for i, ln in enumerate(text.split("\n")):
        m = re.match(r'^\s*(`{3,}|~{3,})', ln)
        if m:
            tok = m.group(1)[0]
            if fence is None:
                fence = tok
                inside.add(i)
                continue
            if tok == fence:
                fence = None
                inside.add(i)
                continue
        if fence is not None:
            inside.add(i)
    return inside

# ── which files are ours to lint ─────────────────────────────────────────────
def rule_files():
    """The numbered CLAUDE.md sections, one file each, in .claude/rules/.

    These are loaded into every session at the same priority as CLAUDE.md, so a
    'Section 8' or 'Step 5.5' written anywhere in the workspace resolves against
    them exactly as it used to resolve against CLAUDE.md."""
    return sorted(glob.glob(os.path.join(ROOT, ".claude", "rules", "*.md")))


def prose_files():
    out = []
    for name in ("CLAUDE.md", "AGENTS.md", "README.md", "INDEX.md", "prompts.md"):
        p = os.path.join(ROOT, name)
        if os.path.isfile(p):
            out.append(p)
    out += rule_files()
    out += sorted(glob.glob(os.path.join(ROOT, "learning", "*.md")))
    out += sorted(glob.glob(os.path.join(ROOT, ".cursor", "rules", "*.mdc")))
    out += sorted(glob.glob(os.path.join(ROOT, ".claude", "skills", "*", "SKILL.md")))
    for rel in (("docs", "README.md"), ("chat_transcripts", "README.md")):
        p = os.path.join(ROOT, *rel)
        if os.path.isfile(p):
            out.append(p)
    return out

# Top-level entries that make a mentioned path OURS rather than a task bundle's.
REPO_ROOTS = {
    "bin", "docs", "learning", "tasks", "_archive", ".cursor", ".claude",
    "comparison-report", "chat_transcripts",
}
REPO_FILES = {
    "CLAUDE.md", "INDEX.md", "AGENTS.md", "README.md", "prompts.md", "facts.yml",
    ".gitignore",
}
# Retired 2026-08-04. Kept OUT of the sets above on purpose: these names must now
# resolve as dead references so the lint fires if a document still points at them.
#   local_runs/  Sentinel_CLAUDE.md  TODO.md  revision.md

# ── PASS 1: twin sync ────────────────────────────────────────────────────────
def pass_twin():
    mdcs = sorted(glob.glob(os.path.join(ROOT, ".cursor", "rules", "*.mdc")))
    if not mdcs:
        emit("SKIP", "twin", "no .cursor/rules/*.mdc found")
        return
    for mdc in mdcs:
        name = os.path.basename(mdc)[:-4]
        skill = os.path.join(ROOT, ".claude", "skills", name, "SKILL.md")
        ident = f"twin:{name}"
        if not os.path.isfile(skill):
            emit("FAIL", ident, f"{rel(mdc)} has no twin at .claude/skills/{name}/SKILL.md")
            continue
        a, b = normalise(read(mdc)), normalise(read(skill))
        if a == b:
            emit("PASS", ident, "rule and skill are identical below the frontmatter")
            continue
        diff = list(difflib.unified_diff(a, b, fromfile=rel(mdc), tofile=rel(skill), lineterm="", n=1))
        emit("FAIL", ident, f"{len(diff) - 2} diff lines between the twins")
        detail("\n".join(diff[:60]))
        if len(diff) > 60:
            detail(f"... {len(diff) - 60} more diff lines")
    # a skill with no rule counterpart is drift in the other direction
    for skill in sorted(glob.glob(os.path.join(ROOT, ".claude", "skills", "*", "SKILL.md"))):
        name = os.path.basename(os.path.dirname(skill))
        if not os.path.isfile(os.path.join(ROOT, ".cursor", "rules", name + ".mdc")):
            emit("FAIL", f"twin:{name}", f"{rel(skill)} has no twin at .cursor/rules/{name}.mdc")

# ── PASS 2: dead paths ───────────────────────────────────────────────────────
PATH_TOKEN = re.compile(r'`([^`\n]+)`')

def looks_like_path(tok):
    if not tok or len(tok) > 200:
        return False
    if any(c in tok for c in "<>*$|\"'{}()[]!?"):
        return False
    if " " in tok or "\t" in tok:
        return False
    if tok.startswith(("http://", "https://", "-", "--")):
        return False
    if "::" in tok or "=" in tok or "#" in tok:
        return False
    if "/" not in tok and "." not in tok:
        return False
    return True

def ours(tok):
    head = tok.split("/", 1)[0]
    if head in REPO_ROOTS:
        return True
    if "/" not in tok and tok in REPO_FILES:
        return True
    return False

# A path named inside a sentence about the past is a history note, not a live
# reference. learning/LEDGER.md is nothing but such sentences. Narrow on purpose:
# these phrases, nothing looser.
HISTORICAL = re.compile(
    r'(?i)earlier version|used to|no longer|formerly|was removed|retired|'
    r'predecessor|superseded|now lives|moved to|renamed')
CITE_SUFFIX = re.compile(r':\d+(?:[-,]\d+)*$')

def pass_path():
    files = prose_files()
    if not files:
        emit("SKIP", "path", "no prose files found")
        return
    dead = []
    checked = 0
    for f in files:
        text = read(f)
        masked = code_fence_mask(text)
        for i, ln in enumerate(text.split("\n")):
            if i in masked:
                continue
            if HISTORICAL.search(ln):
                continue
            for tok in PATH_TOKEN.findall(ln):
                tok = tok.strip().rstrip(".,;:")
                if not looks_like_path(tok):
                    continue
                # `docs/tasking-guide.md:229` and `:345-459` are citations, not paths
                cand = CITE_SUFFIX.sub("", tok)
                cand = cand.rstrip("/")
                # a bare note name inside learning/ resolves next to the file
                local = os.path.join(os.path.dirname(f), cand)
                root_rel = os.path.join(ROOT, cand)
                if os.path.exists(root_rel) or os.path.exists(local):
                    checked += 1
                    continue
                if not ours(cand):
                    continue  # bundle-relative or illustrative, not ours to resolve
                checked += 1
                dead.append((rel(f), i + 1, tok))
    if dead:
        emit("FAIL", "path", f"{len(dead)} dead path reference(s) of {checked} repo paths checked")
        detail("\n".join(f"{f}:{n}  {t}" for f, n, t in dead))
    else:
        emit("PASS", "path", f"all {checked} repo path references resolve")

# ── PASS 3: cross references ─────────────────────────────────────────────────
XREF = re.compile(r'\b(Section|Step)\s+(\d+(?:\.\d+)?|\d+[a-z])\b')
MDLINK = re.compile(r'\[[^\]\n]*\]\(([^)\s]+)\)')

def anchors_of(path):
    """Numbers a 'Section N' / 'Step N' reference may legally point at, per file."""
    text = read(path)
    masked = code_fence_mask(text)
    sections, steps = set(), set()
    for i, ln in enumerate(text.split("\n")):
        if i in masked:
            continue
        m = re.match(r'^#{1,6}\s+(?:Section\s+)?(\d+(?:\.\d+)?|\d+[a-z])[.\s·]', ln)
        if m:
            sections.add(m.group(1))
        m = re.match(r'^#{1,6}\s+STEP\s+(\d+(?:\.\d+)?)', ln, re.I)
        if m:
            steps.add(m.group(1))
        # bold pseudo-headings: **Step 3 — ...** / **Section 4a ...**
        m = re.match(r'^\s*\**\s*\*\*(Section|Step)\s+(\d+(?:\.\d+)?|\d+[a-z])\b', ln)
        if m:
            (sections if m.group(1) == "Section" else steps).add(m.group(2))
        # numbered list item used as a step anchor: "1. **Git hygiene first**"
        m = re.match(r'^\s{0,3}(\d+)\.\s', ln)
        if m:
            steps.add(m.group(1))
            sections.add(m.group(1))
    return sections, steps

def pass_xref():
    files = prose_files()
    if not files:
        emit("SKIP", "xref", "no prose files found")
        return
    cache = {}
    bad, checked = [], 0
    for f in files:
        text = read(f)
        masked = code_fence_mask(text)
        for i, ln in enumerate(text.split("\n")):
            if i in masked:
                continue
            for m in XREF.finditer(ln):
                kind, num = m.group(1), m.group(2)
                # "CLAUDE.md Step 5.5" / "in `CLAUDE.md` Section 8" -> resolve there
                target = f
                before = ln[:m.start()]
                fm = re.findall(r'([A-Za-z0-9_.\-]+\.(?:md|mdc))', before)
                if fm:
                    cand = os.path.join(ROOT, fm[-1])
                    if os.path.isfile(cand):
                        target = cand
                    else:
                        found = [p for p in files if os.path.basename(p) == fm[-1]]
                        if found:
                            target = found[0]
                # Resolution order: the file named on the line, then this file,
                # then CLAUDE.md, then the .claude/rules/ files that hold the
                # numbered sections. An unqualified "Step 5.5" in a learning note
                # means the workspace's Step 5.5, and that is the house
                # convention. The rules pool is what makes it keep resolving now
                # that the sections live one per file instead of inline.
                claude = os.path.join(ROOT, "CLAUDE.md")
                pools = [target, f]
                if os.path.isfile(claude):
                    pools.append(claude)
                pools += rule_files()
                checked += 1
                hit = False
                for p in pools:
                    if p not in cache:
                        cache[p] = anchors_of(p)
                    sections, steps = cache[p]
                    # a Step reference may point at a Section heading of the same
                    # number and vice versa, so accept either pool
                    if num in (sections | steps):
                        hit = True
                        break
                if not hit:
                    bad.append((rel(f), i + 1, f"{kind} {num}", rel(target)))
        for m in MDLINK.finditer(text):
            href = m.group(1)
            if href.startswith(("http://", "https://", "#", "mailto:")):
                continue
            href = href.split("#", 1)[0]
            if not href:
                continue
            checked += 1
            if not os.path.exists(os.path.join(os.path.dirname(f), href)):
                bad.append((rel(f), text[:m.start()].count("\n") + 1, f"link {href}", "-"))
    if bad:
        emit("FAIL", "xref", f"{len(bad)} unresolved reference(s) of {checked} checked")
        detail("\n".join(f"{f}:{n}  {what} -> not found in {tgt}" for f, n, what, tgt in bad))
    else:
        emit("PASS", "xref", f"all {checked} section, step and link references resolve")

    # every learning note is indexed in learning/README.md
    idx = os.path.join(ROOT, "learning", "README.md")
    if not os.path.isfile(idx):
        emit("SKIP", "xref:index", "learning/README.md not found")
        return
    body = read(idx)
    missing = []
    for note in sorted(glob.glob(os.path.join(ROOT, "learning", "*.md"))):
        base = os.path.basename(note)
        if base == "README.md":
            continue
        if base not in body:
            missing.append(base)
    if missing:
        emit("FAIL", "xref:index", f"{len(missing)} learning note(s) missing from learning/README.md")
        detail("\n".join(missing))
    else:
        emit("PASS", "xref:index", "every learning note is indexed in learning/README.md")

# ── PASS 4: fact drift ───────────────────────────────────────────────────────
def load_facts():
    try:
        import yaml  # type: ignore
    except Exception:
        return None, "PyYAML not installed"
    if not os.path.isfile(FACTS):
        return None, f"{rel(FACTS)} not found"
    try:
        data = yaml.safe_load(read(FACTS))
    except Exception as exc:
        return None, f"{rel(FACTS)} does not parse: {exc}"
    if not isinstance(data, dict) or "facts" not in data:
        return None, f"{rel(FACTS)} has no top-level 'facts:' key"
    return data["facts"], None

REQUIRED_KEYS = ("id", "value", "statement", "source", "appears_in", "pattern")

def pass_fact():
    facts, err = load_facts()
    if facts is None:
        emit("SKIP", "fact", err)
        return
    # schema first: a malformed entry silently disables its own check
    broken = []
    seen = set()
    for i, f in enumerate(facts):
        if not isinstance(f, dict):
            broken.append(f"entry {i} is not a mapping")
            continue
        fid = f.get("id", f"<entry {i}>")
        for k in REQUIRED_KEYS:
            if k not in f:
                broken.append(f"{fid}: missing required key '{k}'")
        if fid in seen:
            broken.append(f"{fid}: duplicate id")
        seen.add(fid)
    if broken:
        emit("FAIL", "fact:schema", f"{len(broken)} facts.yml schema problem(s)")
        detail("\n".join(broken))
    else:
        emit("PASS", "fact:schema", f"{len(facts)} facts, all with the required keys")

    for f in facts:
        if not isinstance(f, dict) or "id" not in f:
            continue
        fid = f["id"]
        ident = f"fact:{fid}"
        targets = f.get("appears_in") or []
        pattern = f.get("pattern")
        hits_total = 0
        problems = []
        stale = []
        # An appears_in entry ending in "/" is a directory group: it expands to
        # every .md inside and counts as ONE logical target. `.claude/rules/` is
        # the case this exists for - the numbered sections used to be one file,
        # so the union of the rules files is what a single `CLAUDE.md` entry used
        # to cover. Grouping keeps the stale warning honest: a fact stated in one
        # rule file must not warn about the eleven that do not state it.
        groups = []
        for t in targets:
            if t.endswith("/"):
                members = sorted(glob.glob(os.path.join(ROOT, t, "*.md")))
                if not members:
                    problems.append(f"{t}: appears_in names a directory with no .md files")
                    continue
                groups.append((t, members))
            else:
                p = os.path.join(ROOT, t)
                if not os.path.isfile(p):
                    problems.append(f"{t}: appears_in names a file that does not exist")
                    continue
                groups.append((t, [p]))

        for t, members in groups:
            group_hits = 0
            for p in members:
                rows = read(p).split("\n")
                # A grouped target reports the real file, so a drift problem
                # names the rule file to open, not the directory.
                label = t if len(members) == 1 else rel(p)
                if pattern:
                    try:
                        group_hits += sum(1 for ln in rows if re.search(pattern, ln))
                    except re.error as exc:
                        problems.append(f"{t}: bad 'pattern' regex: {exc}")
                for c in f.get("contradicts") or []:
                    rx, why = c.get("regex"), c.get("why", "")
                    if not rx:
                        continue
                    try:
                        crx = re.compile(rx)
                        # `unless` exempts a line that quotes the wrong value in
                        # order to refute it. Without it every warning about a
                        # mistake reads as the mistake.
                        urx = re.compile(c["unless"]) if c.get("unless") else None
                    except re.error as exc:
                        problems.append(f"{label}: bad 'contradicts' regex {rx!r}: {exc}")
                        continue
                    for n, ln in enumerate(rows, 1):
                        if crx.search(ln) and not (urx and urx.search(ln)):
                            problems.append(f"{label}:{n}: {why}\n        {ln.strip()[:160]}")
                nc = f.get("numeric_claim")
                if nc and nc.get("locate"):
                    try:
                        lrx = re.compile(nc["locate"])
                    except re.error as exc:
                        problems.append(f"{label}: bad 'numeric_claim.locate' regex: {exc}")
                        lrx = None
                    if lrx is not None:
                        want = str(nc.get("equals"))
                        for n, ln in enumerate(rows, 1):
                            m = lrx.search(ln)
                            if m and m.group(1) != want:
                                problems.append(
                                    f"{label}:{n}: states {m.group(1)} where facts.yml says {want}\n        {ln.strip()[:160]}")
            hits_total += group_hits
            if pattern and group_hits == 0:
                stale.append(t)
        if problems:
            emit("FAIL", ident, f"{len(problems)} drift problem(s)")
            detail("\n".join(problems))
        else:
            emit("PASS", ident, f"consistent across {len(targets)} file(s), {hits_total} mention(s)")
        if stale and not problems:
            # not a defect on its own, but appears_in is decaying
            print(f"WARN {ident} appears_in lists {len(stale)} file(s) with no mention: {', '.join(stale)}")

# ── run ──────────────────────────────────────────────────────────────────────
for name, fn in (("twin", pass_twin), ("path", pass_path), ("xref", pass_xref), ("fact", pass_fact)):
    if wanted(name):
        fn()

print(f"{passed} passed, {failed} failed, {skipped} skipped")
sys.exit(1 if failed else (2 if skipped and passed == 0 else 0))
PYEOF
