#!/usr/bin/env bash
# coverage-map.sh - the instruction-requirement to test-assertion matrix, both directions.
#
# CLAUDE.md's test-writing checklist says to build the bipartite mapping yourself first, and
# the two Quality Check axes that can flip the verdict are scored on exactly it:
#   coverage      every stated requirement has a real enforcing assertion. A gap is a FALSE
#                 POSITIVE: a stub solution passes.
#   faithfulness  every assertion maps to something stated or implied. A gap is a HIDDEN
#                 REQUIREMENT: a correct solution fails.
# Today it is done in the head, and it is the first thing a reviewer reconstructs.
#
# This is deliberately a text matcher, not a semantic one. It matches on the tokens a
# requirement and an assertion have to share to be about the same thing - backticked names,
# quoted strings, identifiers and numeric thresholds - and prints its working so a human can
# overrule it. Treat every row as a claim to check, not a verdict.
#
# Usage:
#   bin/coverage-map.sh <task-dir>                 print the map
#   bin/coverage-map.sh <task-dir> -o <file>       write it (e.g. answers/coverage-map.md)
#   bin/coverage-map.sh <task-dir> --all-tests     map every graded test, not just fail_to_pass
#
# Exit: 0 both gap lists empty, 1 either gap list non-empty, 2 cannot run, 3 misuse.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TASK_ARG=""; OUT=""; ALL_TESTS=0
while [ $# -gt 0 ]; do
  case "$1" in
    -o|--out)    OUT="${2:-}"; shift 2 ;;
    --all-tests) ALL_TESTS=1; shift ;;
    -h|--help)   sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)          echo "SKIP unknown argument: $1" >&2; exit 3 ;;
    *)           TASK_ARG="$1"; shift ;;
  esac
done
[ -n "$TASK_ARG" ] || { echo "SKIP usage: bin/coverage-map.sh <task-dir> [-o file]" >&2; exit 3; }

BUNDLE=""
for c in "$TASK_ARG/work" "$TASK_ARG" "$TASK_ARG/download/original" "$TASK_ARG/task"; do
  if [ -f "$c/instruction.md" ] && [ -d "$c/tests" ]; then BUNDLE="$c"; break; fi
done
[ -n "$BUNDLE" ] || { echo "SKIP no bundle with instruction.md and tests/ under $TASK_ARG"; exit 2; }

export CM_BUNDLE="$BUNDLE" CM_OUT="$OUT" CM_ALL="$ALL_TESTS"

python3 - <<'PY'
import json, os, re, sys, collections

b   = os.environ["CM_BUNDLE"]
out = os.environ.get("CM_OUT") or ""
allt= os.environ.get("CM_ALL") == "1"

instr = open(os.path.join(b, "instruction.md"), encoding="utf-8", errors="replace").read()
cfgp  = os.path.join(b, "tests", "config.json")
cfg   = json.load(open(cfgp, encoding="utf-8")) if os.path.isfile(cfgp) else {}
grading = cfg.get("grading") or {}
f2p = list(grading.get("fail_to_pass") or [])
p2p = list(grading.get("pass_to_pass") or [])
graded = f2p + p2p if allt else f2p

patchp = os.path.join(b, "tests", "tests.patch")
patch  = open(patchp, encoding="utf-8", errors="replace").read() if os.path.isfile(patchp) else ""

# ---------------------------------------------------------------- tokenising
STOP = set("""a an and are as at be been but by can cannot do does for from has have if in into is it
its may must new no not of on or should so than that the their them then there these this to under
use used uses using when where which while will with without you your each every all any both same
other more most such only own too very just also both each few own than very return returns returned
value values type types call calls called make makes made take takes taken give gives given case cases
test tests testing assert asserts asserted expect expects expected equal equals true false null none
public private static void class import package function const let var async await throw throws catch
try else elif def fun impl struct enum trait mod pub crate self this super new delete size len length
add adds added get gets got set sets setting run runs running work works working file files line lines
code codes name names named number numbers first second third last next previous same different""".split())

IDENT   = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
BACKTIK = re.compile(r"`([^`\n]{2,80})`")
QUOTED  = re.compile(r"[\"']([A-Za-z0-9_@/.:\- ]{3,60})[\"']")
NUMBER  = re.compile(r"(?<![\w.])(\d+(?:\.\d+)?)(?![\w.])")
CAMEL   = re.compile(r"\b(?:[a-z]+[A-Z][A-Za-z0-9]*|[A-Z][a-z]+[A-Z][A-Za-z0-9]*|[a-z_]+_[a-z0-9_]+)\b")

def tokens(text, keep_numbers=True):
    """Identifier-shaped names, quoted paths and numeric thresholds. Free prose is deliberately
    not tokenised: it produces matches that mean nothing."""
    t = set()
    for m in BACKTIK.finditer(text):
        inner = m.group(1).strip()
        for w in IDENT.findall(inner):
            if len(w) > 3 and w.lower() not in STOP:
                t.add(w)
        if "/" in inner or "." in inner:
            t.add(inner)
    for m in QUOTED.finditer(text):
        s = m.group(1).strip()
        if (" " not in s) and len(s) > 3 and s.lower() not in STOP:
            t.add(s)
    for w in CAMEL.findall(text):
        if w.lower() not in STOP and len(w) > 3:
            t.add(w)
    for w in IDENT.findall(text):
        if len(w) > 3 and w.lower() not in STOP and (w[0].isupper() or "_" in w):
            t.add(w)
    if keep_numbers:
        for n in NUMBER.findall(text):
            if n not in ("0", "1", "2"):        # too common to discriminate
                t.add(n)
    return {x for x in t if x}

def norm(t):
    return t.strip().strip("`\"'.,;:()[]{}").lower()

# ---------------------------------------------------------------- requirements out of the instruction
MODAL = re.compile(r"\b(must|should|has to|have to|needs? to|is required|are required|shall|"
                   r"add|create|introduce|expose|accept|return|throw|raise|support|provide|"
                   r"implement|replace|rename|move|keep|preserve|default[s]? to|fail|reject|"
                   r"validate|handle|emit|write|read|log|expect)\b", re.I)

lines = instr.splitlines()
reqs = []
in_fence = False
for i, raw in enumerate(lines, 1):
    s = raw.strip()
    if s.startswith("```"):
        in_fence = not in_fence
        continue
    if in_fence or not s or s.startswith("#"):
        continue
    units = []
    if re.match(r"^[-*+]\s+|^\d+[.)]\s+", s):
        units = [re.sub(r"^[-*+]\s+|^\d+[.)]\s+", "", s)]
    else:
        units = [x.strip() for x in re.split(r"(?<=[.!?])\s+(?=[A-Z`])", s) if x.strip()]
    for u in units:
        if len(u) < 15:
            continue
        if not MODAL.search(u) and not BACKTIK.search(u):
            continue
        tk = tokens(u)
        # a bare number with no name attached cannot be matched on: "a 3.0 release" is not a
        # requirement token, it is prose with a version in it
        if not {x for x in tk if not re.fullmatch(r"\d+(?:\.\d+)?", x)}:
            tk = set()
        reqs.append({"line": i, "text": u, "tokens": tk})

# ---------------------------------------------------------------- assertions out of tests.patch
TESTDECL = [
    re.compile(r"""Deno\.test\(\s*[\{"']?\s*(?:name:\s*)?["']([^"']+)["']"""),
    re.compile(r"""\bt\.step\(\s*["']([^"']+)["']"""),
    re.compile(r"""\b(?:it|describe|test)\(\s*["']([^"']+)["']"""),
    re.compile(r"""^\s*(?:public|private)?\s*void\s+(\w+)\s*\("""),
    re.compile(r"""^\s*def\s+(test\w+)\s*\("""),
    re.compile(r"""^\s*fn\s+(\w+)\s*\("""),
    re.compile(r"""^\s*TEST(?:_F)?\(\s*(\w+)\s*,\s*(\w+)\s*\)"""),
]
ASSERT = re.compile(r"\b(assert\w*|expect\w*|should\w*|verify\w*|check\w*|EXPECT_\w+|ASSERT_\w+)\b")

added = collections.defaultdict(list)
cur = None
for ln in patch.splitlines():
    m = re.match(r"^\+\+\+ b/(.+)$", ln)
    if m:
        cur = m.group(1).strip(); continue
    if cur and ln.startswith("+") and not ln.startswith("+++"):
        added[cur].append(ln[1:])

def owner(i):
    return i.split("::")[0] if "::" in i else i.rsplit("#", 1)[0]
def leaf(i):
    return i.split("::")[-1] if "::" in i else i.rsplit("#", 1)[-1]

def _extract(src, name):
    """The block from this test's declaration to the next declaration at the same or shallower
    indent. Nesting matters: a Deno.test body is full of t.step declarations, and cutting at the
    first of them leaves an empty body that reads as zero assertions."""
    starts = []
    for idx, ln in enumerate(src):
        indent = len(ln) - len(ln.lstrip())
        for rx in TESTDECL:
            m = rx.search(ln)
            if m and any(g for g in m.groups()):
                starts.append((idx, [g for g in m.groups() if g], indent))
                break
    hit = None
    for pos, names, indent in starts:
        if any(norm(n) == norm(name) or norm(name) in norm(n) or norm(n) in norm(name)
               for n in names):
            hit = (pos, indent); break
    if hit is None:
        return None
    pos, indent = hit
    nxt = next((p for p, _, ind in starts if p > pos and ind <= indent), len(src))
    return src[pos:nxt]

def body_for(test_id):
    """The graded test's body: out of tests.patch when the patch adds it, otherwise out of the
    shipped repo, which is where a pre-existing pass_to_pass test actually lives."""
    o, name = owner(test_id), leaf(test_id)
    src = added.get(o)
    if src is None:
        stem = o.split("/")[-1].split(".")[0] if "/" in o else o.split(".")[-1]
        for k, v in added.items():
            kbase = os.path.basename(k)
            if kbase == o.split("/")[-1] or os.path.splitext(kbase)[0] == stem:
                src = v; break
    if src:
        block = _extract(src, name)
        if block:
            return block, True
        if len(src) > 5:
            return src, True
    # fall back to the repo copy
    cand = os.path.join(b, "environment", "repo", o)
    if not os.path.isfile(cand):
        simple = o.replace(".", "/").split("/")[-1]
        for dirpath, dirnames, filenames in os.walk(os.path.join(b, "environment", "repo")):
            dirnames[:] = [d for d in dirnames if d not in (".git", "node_modules", "target", "build")]
            for fn in filenames:
                if os.path.splitext(fn)[0] == simple or fn == o.split("/")[-1]:
                    cand = os.path.join(dirpath, fn); break
            if os.path.isfile(cand):
                break
    if os.path.isfile(cand):
        lines_ = open(cand, encoding="utf-8", errors="replace").read().splitlines()
        block = _extract(lines_, name)
        if block:
            return block, False
        return lines_, False
    return [], False

def liberal_tokens(text):
    """Every identifier a test body mentions. Used only for the coverage direction, where a
    lowercase option name like `quality` has to match the requirement that names it."""
    t = {w for w in IDENT.findall(text) if len(w) > 3 and w.lower() not in STOP}
    t |= {n for n in NUMBER.findall(text) if n not in ("0", "1", "2")}
    return t

tests = []
for tid in graded:
    body, from_patch = body_for(tid)
    text = "\n".join(body)
    asserts = [l.strip() for l in body if ASSERT.search(l)]
    tests.append({
        "id": tid,
        "from_patch": from_patch,
        "body_lines": len(body),
        "asserts": asserts,
        "text": text,
        # liberal: what this test could possibly be enforcing
        "tokens": liberal_tokens(text) | tokens(leaf(tid)),
        # strict: what this test actually CLAIMS, taken from its assertion lines only
        "claims": tokens("\n".join(asserts)),
    })

instr_tokens_norm = {norm(t) for t in tokens(instr)}
instr_lower = instr.lower()

# ---------------------------------------------------------------- match both ways
for r in reqs:
    r["covered_by"] = []
    rn = {norm(t) for t in r["tokens"]} - {""}
    paths = {t for t in rn if "/" in t or (t.count(".") and not t.replace(".", "").isdigit())}
    for t in tests:
        tn = {norm(x) for x in t["tokens"]}
        shared = rn & tn
        low = t["text"].lower()
        for pth in paths:                       # a path token matches as a substring
            if pth in low:
                shared.add(pth)
        if shared:
            r["covered_by"].append((t["id"], sorted(shared)[:4]))

for t in tests:
    stated, unstated = [], []
    for tok in sorted({norm(x) for x in t["claims"]}):
        if len(tok) < 4 or tok in STOP:
            continue
        (stated if tok in instr_tokens_norm or tok in instr_lower else unstated).append(tok)
    t["stated_tokens"] = stated
    t["unstated_tokens"] = unstated

UNCOVERED = [r for r in reqs if not r["covered_by"] and r["tokens"]]
UNTOKENISED = [r for r in reqs if not r["tokens"]]
UNSTATED = [t for t in tests
            if t["from_patch"] and t["asserts"] and t["unstated_tokens"] and not t["stated_tokens"]]
GUARDS   = [t for t in tests if not t["from_patch"]]
NOBODY   = [t for t in tests if t["body_lines"] == 0]

# ---------------------------------------------------------------- render
L = []
def w(s=""): L.append(s)

w(f"# Coverage map - {os.path.basename(os.path.dirname(b) if os.path.basename(b) == 'work' else b)}")
w()
w(f"Generated by `bin/coverage-map.sh`. {len(reqs)} candidate requirements out of "
  f"`instruction.md`, {len(tests)} graded tests out of `tests/tests.patch` "
  f"({'fail_to_pass + pass_to_pass' if allt else 'fail_to_pass'}).")
w()
w("Every row is a claim to verify, not a verdict. The matcher links a requirement to a test "
  "when they share a name, a quoted string or a threshold.")
w()
w("## Requirement to test")
w()
w("| # | instruction.md | Requirement | Enforcing tests | Shared tokens |")
w("|---|---|---|---|---|")
for n, r in enumerate(reqs, 1):
    ids = ", ".join(f"`{leaf(i)}`" for i, _ in r["covered_by"][:3]) or "**none**"
    if len(r["covered_by"]) > 3:
        ids += f" (+{len(r['covered_by'])-3})"
    shared = ", ".join(sorted({s for _, ss in r["covered_by"] for s in ss})[:5]) or "-"
    text = r["text"].replace("|", "\\|")
    text = (text[:110] + "...") if len(text) > 113 else text
    w(f"| {n} | :{r['line']} | {text} | {ids} | {shared} |")
w()
w("## Test to requirement")
w()
w("| Graded test | Assertions | Tokens the instruction states | Tokens it does not |")
w("|---|---|---|---|")
for t in tests:
    w(f"| `{t['id']}`{'' if t['from_patch'] else ' (pre-existing)'} | {len(t['asserts'])} | {', '.join(t['stated_tokens'][:5]) or '-'} | "
      f"{', '.join(t['unstated_tokens'][:5]) or '-'} |")
w()
w("## UNCOVERED requirements - the coverage axis")
w()
if UNCOVERED:
    w("A stub of any of these passes the suite. Each one is a hostile-probe candidate: break it "
      "and confirm the reward drops.")
    w()
    for r in UNCOVERED:
        w(f"- `instruction.md:{r['line']}` {r['text'][:160]}")
        w(f"  - probe: `bin/hostile-probe.sh <task-dir> --file <impl> --break '<sed>' "
          f"--expect-fail '<test id>' --requirement \"{r['text'][:60]}\"`")
else:
    w("None. Every tokenised requirement has at least one graded test sharing its names.")
if UNTOKENISED:
    w()
    w(f"{len(UNTOKENISED)} requirement line(s) carry no name, string or threshold, so nothing "
      f"could be matched on. Read these by eye:")
    for r in UNTOKENISED[:10]:
        w(f"- `instruction.md:{r['line']}` {r['text'][:140]}")
w()
w("## UNSTATED assertions - the faithfulness axis")
w()
if UNSTATED:
    w("These graded tests assert on names the instruction never uses, which is a hidden "
      "requirement: a correct solution fails. Either state it in the instruction or relax the "
      "assertion.")
    w()
    for t in UNSTATED:
        w(f"- `{t['id']}` - unstated tokens: {', '.join(t['unstated_tokens'][:8])}")
        for a in t["asserts"][:2]:
            w(f"  - `{a[:120]}`")
else:
    w("None. Every graded test this bundle adds shares at least one name with the instruction.")
if GUARDS:
    w()
    w(f"{len(GUARDS)} graded id(s) are pre-existing tests rather than tests this bundle adds. "
      f"They are regression guards, so the faithfulness axis does not apply to them, but they "
      f"do have to be genuinely passing at base - that is `bin/nop-audit.sh`.")
if NOBODY:
    w()
    w(f"{len(NOBODY)} graded id(s) have no body in `tests.patch`. They are pre-existing tests, "
      f"which is normal for `pass_to_pass`, and a defect for `fail_to_pass`:")
    for t in NOBODY[:15]:
        w(f"- `{t['id']}`")

text = "\n".join(L) + "\n"
if out:
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    open(out, "w", encoding="utf-8").write(text)
    print(f"wrote {out}")
else:
    sys.stdout.write(text)

print(f"\n{len(UNCOVERED)} uncovered requirement(s), {len(UNSTATED)} unstated assertion set(s), "
      f"{len(UNTOKENISED)} unmatchable requirement line(s)", file=sys.stderr)
sys.exit(1 if (UNCOVERED or UNSTATED) else 0)
PY
