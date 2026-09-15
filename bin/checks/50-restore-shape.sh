#!/usr/bin/env bash
#
# 50-restore-shape.sh — measure how many graded ids live OUTSIDE the files
# tests.patch touches, and say which test-tree restore that implies.
#
# The measurement picks the verifier design, so getting it wrong costs a round:
#
#   0 outside  -> a create-only tests.patch is sufficient. Every graded file is
#                 re-created from /dev/null, so there is no context an agent's
#                 edits can conflict with, and nothing else needs restoring.
#   >0 outside -> the whole test tree has to be restored from a base64 payload
#                 embedded in test.sh. A create-only patch would leave those ids
#                 running the agent's own copies, which is a test-gaming route.
#
# The snippet the rule files used to carry split every id on `::` and therefore
# reported a JUnit task as 100% outside and a cargo task as 100% inside. This one
# detects the id scheme per id and refuses to answer when it cannot attribute
# enough of them.
#
# Restores built on git are always wrong, whatever the count says: the
# verify-time workspace is not a git repository. Three git-based designs shipped
# on kvdex 245 across three rounds and none of them worked.
#
# usage: 50-restore-shape.sh [--work|--zip] <task-dir|bundle-dir|zip>
# exit:  0 the shape matches, 1 it does not, 2 too few ids resolved to answer

# shellcheck source=_common.inc
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.inc"

if parse_mode "${1-}"; then shift; fi
ARG="${1-}"
[ -n "$ARG" ] || usage_die "restore.args" "no task directory given"

need python3 || { skip "restore.python3" "python3 is not available"; summary || true; exit 2; }
resolve_input "$PREFER" "$ARG" || usage_die "restore.args" "cannot resolve a bundle from $ARG"
B="$BUNDLE_DIR"
report_source

for f in tests/tests.patch tests/config.json tests/test.sh; do
  if [ ! -f "$B/$f" ]; then
    skip "restore.inputs" "$f is missing, cannot measure"
    summary || true
    exit 2
  fi
done

OUT="$(mktempdir)/out"
python3 - "$B" > "$OUT" <<'PY' || true
import json, os, re, sys

bundle = sys.argv[1]
patch_path = os.path.join(bundle, "tests/tests.patch")
cfg_path = os.path.join(bundle, "tests/config.json")
ts_path = os.path.join(bundle, "tests/test.sh")
repo = os.path.join(bundle, "environment/repo")

patch = open(patch_path, encoding="utf-8", errors="replace").read()
touched = set(re.findall(r"^diff --git a/(\S+)", patch, re.M))
if not touched:
    touched = set(re.findall(r"^\+\+\+ b/(\S+)", patch, re.M))
creates = set(re.findall(r"^\+\+\+ b/(\S+)", patch, re.M)) & \
          set(re.findall(r"^--- /dev/null\n\+\+\+ b/(\S+)", patch, re.M))
n_create_hunks = len(re.findall(r"^new file mode ", patch, re.M))
added = "\n".join(l[1:] for l in patch.splitlines()
                  if l.startswith("+") and not l.startswith("+++"))

cfg = json.load(open(cfg_path, encoding="utf-8"))
grading = cfg.get("grading") or {}
f2p = list(grading.get("fail_to_pass") or [])
p2p = list(grading.get("pass_to_pass") or [])
ids = f2p + p2p

SRC_EXT = (".ts", ".tsx", ".js", ".jsx", ".mjs", ".py", ".rs", ".go", ".java",
           ".kt", ".kts", ".scala", ".rb", ".cs", ".cpp", ".cc", ".c", ".swift")

index = []
if os.path.isdir(repo):
    for root, dirs, files in os.walk(repo):
        dirs[:] = [d for d in dirs if d != ".git"]
        for fn in files:
            if fn.endswith(SRC_EXT):
                index.append(os.path.relpath(os.path.join(root, fn), repo))

stem_index = {}
for p in index:
    stem_index.setdefault(os.path.basename(p).rsplit(".", 1)[0], []).append(p)
touched_stems = {os.path.basename(p).rsplit(".", 1)[0] for p in touched}
index_set = set(index)

# tier-2 name lookup only scans plausible test sources, so a large repo stays cheap
test_files = [p for p in index
              if "test" in p.lower() or "spec" in p.lower()]

_text = {}
def text(p):
    if p not in _text:
        try:
            _text[p] = open(os.path.join(repo, p), encoding="utf-8", errors="replace").read()
        except Exception:
            _text[p] = ""
    return _text[p]

def split_id(i):
    if "#" in i:
        o, n = i.split("#", 1)
        return o, n
    if "::" in i:
        head = i.split("::", 1)[0]
        # A path-shaped FIRST segment means the id is <file>::[Class::]name, which is
        # pytest's class form and deno's step form. There the file is the first segment
        # and everything after it is class plus test name, so rsplit hands back
        # "<file>::Class" as the path and nothing ever matches it. Measured on
        # deepfabric 297, where all five tests/test_topic_graph.py::TestGraph::* ids came
        # back UNRESOLVED. Same class of defect as the Go arm in LEDGER L7.
        if "/" in head or head.endswith(SRC_EXT):
            return head, i.rsplit("::", 1)[1]
        o, n = i.rsplit("::", 1)
        return o, n
    return None, i

def id_scheme(o):
    """path::name (deno, pytest, jest) | Class#method or FQCN::method (junit)
       | crate::module::test (cargo) | a bare test name."""
    if o is None:
        return "BARE"
    if "/" in o or o.endswith(SRC_EXT):
        return "PATH"
    last = o.split(".")[-1]
    if last[:1].isupper():
        return "CLASS"
    return "MODULE"

def decl_re(n):
    return re.compile(
        r"(?:\bfn\s+|\bdef\s+|\bfunc\s+|\bvoid\s+|\bpublic\s+void\s+|\bit\s*\(\s*[\"']|"
        r"\btest\s*\(\s*[\"'])" + re.escape(n) + r"\b")

def word_re(n):
    return re.compile(r"(?<![A-Za-z0-9_])" + re.escape(n) + r"(?![A-Za-z0-9_])")

inside = []
outside = []
unresolved = []
schemes = {}

for i in ids:
    o, n = split_id(i)
    s = id_scheme(o)
    schemes[s] = schemes.get(s, 0) + 1

    if s == "PATH":
        if o in touched:
            inside.append(i); continue
        cands = [p for p in index if p == o or p.endswith("/" + o)]
        if any(c in touched for c in cands):
            inside.append(i)
        elif cands or o in index_set:
            outside.append(i)
        else:
            unresolved.append(i)

    elif s == "CLASS":
        simple = o.split(".")[-1]
        if simple in touched_stems:
            inside.append(i)
        elif simple in stem_index:
            outside.append(i)
        else:
            unresolved.append(i)

    else:  # MODULE (cargo) or BARE
        rx = decl_re(n)
        if rx.search(added):
            inside.append(i); continue
        hits = [p for p in test_files if rx.search(text(p))]
        if not hits:
            # rust macro-generated names and table-driven suites never declare the
            # id with a `fn` of that name, so fall back to a word match inside a
            # test source before giving up
            wx = word_re(n)
            hits = [p for p in test_files if wx.search(text(p))]
        if hits:
            if any(p in touched for p in hits):
                inside.append(i)
            else:
                outside.append(i)
        else:
            unresolved.append(i)

total = len(ids)
resolved = total - len(unresolved)
rate = (resolved / total) if total else 0.0

ts = open(ts_path, encoding="utf-8", errors="replace").read()
has_payload = bool(re.search(r"base64\s+(-d|--decode)", ts)) and \
              bool(re.search(r"tar\s+-?xz?f|tar\s+-xzf", ts))
deletes_patched = bool(re.search(r"sed -n .s\|\^\+\+\+ b/\|p", ts)) or \
                  bool(re.search(r'rm\s+-f\b.*\+\+\+ b/', ts)) or \
                  bool(re.search(r"\+\+\+ b/", ts))
git_restore = re.findall(r"^(?!\s*#)([^\n]*\bgit\s+(?:checkout|stash|clean|reset|restore)\b[^\n]*)$",
                         ts, re.M)
all_creates = bool(touched) and len(creates) == len(touched)

print("SCHEMES\t" + ", ".join("%s=%d" % kv for kv in sorted(schemes.items())))
print("COUNTS\t%d\t%d\t%d\t%d\t%d\t%d" % (len(outside), total, len(inside),
                                          len(unresolved), len(f2p), len(p2p)))
print("RATE\t%.3f" % rate)
print("PATCH\t%d\t%d\t%d" % (len(touched), len(creates), n_create_hunks))
print("IMPL\t%d\t%d\t%d" % (int(has_payload), int(all_creates), int(deletes_patched)))
for g in git_restore[:4]:
    print("GITRESTORE\t%s" % g.strip()[:120])
for u in unresolved[:5]:
    print("UNRES\t%s" % u)
PY

if [ ! -s "$OUT" ]; then
  skip "restore.measure" "the measurement produced no output"
  summary || true
  exit 2
fi

get() { awk -F'\t' -v k="$1" -v f="$2" '$1==k {print $f; exit}' "$OUT"; }

SCHEMES="$(get SCHEMES 2)"
N_OUT="$(get COUNTS 2)"
N_TOT="$(get COUNTS 3)"
N_IN="$(get COUNTS 4)"
N_UNRES="$(get COUNTS 5)"
N_F2P="$(get COUNTS 6)"
N_P2P="$(get COUNTS 7)"
RATE="$(get RATE 2)"
P_TOUCHED="$(get PATCH 2)"
P_CREATES="$(get PATCH 3)"
HAS_PAYLOAD="$(get IMPL 2)"
ALL_CREATES="$(get IMPL 3)"

note "id schemes: $SCHEMES"
note "tests.patch touches $P_TOUCHED file(s), $P_CREATES of them created from /dev/null"
note "graded ids: $N_F2P fail_to_pass + $N_P2P pass_to_pass"

# ------------------------------------------------------------ resolution -----

if awk -v r="$RATE" 'BEGIN{exit !(r < 0.90)}'; then
  fail "restore.resolution" "UNRESOLVED — only $(awk -v r="$RATE" 'BEGIN{printf "%.0f", r*100}')% of the $N_TOT graded ids could be attributed to a file ($N_UNRES unresolved). Refusing to print a number that would pick the verifier design"
  awk -F'\t' '$1=="UNRES" {print "     unresolved id: " $2}' "$OUT"
  note "resolve these by hand, or extend the id-scheme detection, before choosing a restore shape"
  summary || true
  exit 2
fi
pass "restore.resolution" "$(awk -v r="$RATE" 'BEGIN{printf "%.0f", r*100}')% of the $N_TOT graded ids resolved to a file"

# ----------------------------------------------------------- the number ------

note "$N_OUT of $N_TOT graded ids live outside the patched files ($N_IN inside)"
if [ "$N_OUT" -eq 0 ]; then
  VERDICT="create-only"
  note "verdict: a create-only tests.patch is sufficient"
else
  VERDICT="payload"
  note "verdict: the full-tree base64 payload embedded in test.sh is required"
fi

# ------------------------------------------------- what test.sh implements ----

if [ "$VERDICT" = "payload" ]; then
  if [ "$HAS_PAYLOAD" = "1" ]; then
    pass "restore.shape" "$N_OUT ids outside the patched files and test.sh restores the whole test tree from an embedded payload"
  elif [ "$ALL_CREATES" = "1" ]; then
    fail "restore.shape" "$N_OUT of $N_TOT graded ids live outside the patched files, so the create-only patch leaves them running the agent's own copies. Embed the full-tree base64 payload in test.sh"
  else
    fail "restore.shape" "$N_OUT of $N_TOT graded ids live outside the patched files and test.sh restores nothing before applying the patch"
  fi
else
  if [ "$HAS_PAYLOAD" = "1" ]; then
    pass "restore.shape" "no graded id lives outside the patched files, and the embedded payload restores the tree anyway"
  elif [ "$ALL_CREATES" = "1" ]; then
    pass "restore.shape" "every graded id lives inside the patched files and every patched file is a create, so there is nothing for an agent edit to conflict with"
  else
    warn "restore.shape" "no graded id lives outside the patched files, but tests.patch is not create-only ($P_CREATES of $P_TOUCHED files are creates) and test.sh embeds no payload — an agent editing a patched test file still breaks the apply"
  fi
fi

# ----------------------------------------------------- git-based restore -----

if grep -q '^GITRESTORE' "$OUT"; then
  fail "restore.not-git" "the restore is built on git — the verify-time workspace is not a git repository, so this cannot work and has already cost three rounds"
  awk -F'\t' '$1=="GITRESTORE" {print "     " $2}' "$OUT"
else
  pass "restore.not-git" "no git checkout, stash, clean, reset or restore in test.sh"
fi

summary
