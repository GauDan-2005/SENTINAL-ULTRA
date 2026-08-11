---
id: source-pr-cross-check
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260719_045042__oliver-oloughlin_kvdex__245
  - 20260809_080653__sysprog21_elfuse__162
evidence: "Three Quality Check coverage findings traced back to the upstream PR and to the base commit; and a golden.patch found to be the source PR with a second PR welded into it, caught only by hunk-level comparison"
applies_to:
  languages: [any]
  runners: [any]
  phases: [quality-check, analysis]
blocks_submission: false
fails_gate: [quality-check]
supersedes: []
contradicts: []
---

# Cross-checking a judge finding against the source PR

Source: `20260719_045042__oliver-oloughlin_kvdex__245`, revision 3, 2026-08-02. The Quality
Check came back DISCUSS on `test_coverage` with three named defects. All three turned out to
describe the upstream PR rather than anything the submitter did, and acting on any of them
directly would have meant reducing PR scope.

## The rule

**Before changing a line in response to a coverage or faithfulness finding, check whether the
thing being complained about comes from the source PR.** If it does, the oracle is faithful
and the fix belongs in `instruction.md`, which is promising something the PR does not deliver.
Changing the oracle to satisfy the judge would be reducing or replacing PR behaviour, which is
an Invalid condition, not a fix.

What the kvdex report said, and what was actually true:

| Judge finding | Reality |
|---|---|
| "the value fixture deliberately removes `Float16Array` despite the prompt requiring the other typed arrays" | PR 245 disables Float16Array itself, with `// TODO:` markers, in `src/ext/encoding/json/utils.ts`, `src/ext/zod/schemas.ts`, `src/types.ts`, `src/utils.ts` and `tests/values.ts` |
| "`updateManyBySecondaryOrder` is left as `Deno.test.ignore`" | already `Deno.test.ignore` at the base commit. The only thing `tests.patch` adds there is the PR's own `// TODO: fix update document deleting indices ...` comment |
| "the JSON implementation serializes only `RegExp.source` and reconstructs without flags" | pre-existing at `src/utils.ts:917` at base. The PR relocates it verbatim into the new module |

So the defect was `instruction.md` claiming the helpers cover "every value type Deno KV
supports ... and the other typed arrays" and asking indexable collections for "the secondary
index and secondary order variants". Narrowing both sentences removed the requirements the
judge scored against, changed no graded assertion, and left PR scope untouched.

The general shape: a judge reads the instruction as the spec and the bundle as the
implementation. When the bundle faithfully reproduces a PR that does less than the instruction
promises, the judge reports it as a test gap. It is a spec gap.

## Fetching the PR: use the API, and page it

The obvious routes both fail or mislead.

`https://github.com/<owner>/<repo>/pull/<n>.diff` 302s to
`patch-diff.githubusercontent.com`, which timed out on this network. The web
`/files` view is JavaScript and converts to markdown badly.

What works:

```bash
curl -sS "https://api.github.com/repos/<owner>/<repo>/pulls/<n>/files?per_page=100" -o p1.json
```

**It paginates at 100 and this cost a wrong conclusion mid-session.** Page 1 of kvdex 245 held
100 files and contained no `updateManyBySecondaryOrder` entry, from which I concluded the PR
did not touch those tests and that our `tests.patch` had added the TODO comment on its own.
The PR has **198** files. Page 2 has both test files and shows the comment is the PR's. Always
fetch until a page returns fewer than `per_page` rows:

```bash
for p in 1 2 3; do
  curl -sS "https://api.github.com/repos/<owner>/<repo>/pulls/<n>/files?per_page=100&page=$p" \
    -o "pr_p$p.json"
  [ "$(python3 -c "import json;print(len(json.load(open('pr_p$p.json'))))")" -lt 100 ] && break
done
```

Then search every page at once rather than per file:

```python
import json, glob
files = [f for p in sorted(glob.glob('pr_p*.json')) for f in json.load(open(p))]
print(len(files), "files in PR")
for f in files:
    if 'Float16Array' in (f.get('patch') or ''):
        print(f['filename'])
```

Two things about the `patch` field. It is absent for very large or binary files, so a symbol
missing from it is not proof the PR leaves that file alone: check `filename` membership
separately. And grepping only lines containing your search term hides the surrounding context,
which matters when the PR comments code out with a `/* */` block whose opening line does not
mention the symbol. Print a few lines either side before concluding anything about intent.

`gh auth status` was already logged in on this machine, so `gh api` is available as an
alternative and handles paging with `--paginate`.

## When it is the fifth round, audit every claim at once

Added 2026-08-05 from `20260727_135618__AltBeacon_android-beacon-library__1177`, rounds 2 to 6.

The rule above tells you where a single finding belongs. It does not tell you what to do when the
same *shape* of finding keeps coming back on different sentences. This task was sent back five
consecutive rounds because `instruction.md` promised something PR 1177 does not deliver, and each
round narrowed the one sentence that had been reported:

| Round | The promise the PR did not keep |
|---|---|
| 2 | fields the instruction said were applied that the oracle never applied |
| 4 | the transaction guarantee, against an async rebind |
| 5 | a closed strategy set, Java-readable defaults, the foreground notification, `Identifier.parse` |
| 6 | backward compatibility, and the `rssiFilterImplClass` type |

Four correct fixes, four more rounds. **The two-strikes rule applies to the pattern, not to the
sentence.** Fixing what was reported and re-uploading is itself the fix that has failed, so the
move is to stop waiting for the judge to enumerate them.

What that looks like in practice: take every absolute claim in `instruction.md` (`every`, `all`,
`must`, `unchanged`, `never`, `always`, an exact type, an exact default) and check each one against
`golden.patch` by hand, in one pass. On round 6 that took under an hour and found a gap no judge had
reported, `ForegroundServiceScanStrategy` equality being identity-sensitive on the `Notification`
because `android.app.Notification` does not override `equals`.

**The audit also finds your own mistakes.** That same gap had been visible a round earlier as a
graded assertion that disagreed with the instruction, and round 5 resolved the disagreement by
deleting the assertion. See `LEDGER.md` L20. A test that contradicts the instruction is evidence
about the instruction at least as often as the reverse, and the tiebreaker is always which of the
two matches the patch.

## The other direction: golden.patch carrying a SECOND PR (elfuse 162, 2026-08-11)

Everything above is about a finding that describes the PR when it looks like it describes your
tests. This is the mirror case, and it is the oracle rather than the tests.

`20260809_080653__sysprog21_elfuse__162` shipped a `solution/golden.patch` of 27 hunks over 12
files. Sixteen of those hunks are PR 162's own eight non-test files. The remaining **eleven are
PR 161**, "Wake internal condvar parks on exit_group teardown", a concurrency and teardown fix
with nothing to do with the feature. It brought in four files PR 162 never touched
(`src/core/guest.c`, `src/main.c`, `src/runtime/thread.c`, `src/runtime/thread.h`), a new public
function `thread_wake_exit_waiters`, and four wait loops taught to re-check an exit-group flag.
The instruction never mentioned any of it and no graded test referenced a single one of its
symbols, so it was undescribed and unverifiable behaviour sitting in the oracle.

**A file-list diff alone understates this and would have missed a third of it.** Three of the
polluted hunks land inside files PR 162 *does* legitimately touch:
`src/runtime/forkipc.c`, `src/syscall/syscall.c` and `src/syscall/proc.c`. Comparing file lists
reports "4 extra files". Comparing hunks reports the truth, 11 extra hunks across 7 files.

**The comparison that works.** The API gives you a real unified diff per file in the `patch`
field, so compare changed-line bodies rather than filenames. This is the script that found it:

```bash
# page it, because this note's own headline lesson is that page 1 is not the PR
p=1; : > pr_pages.json
while curl -s "https://api.github.com/repos/<owner>/<repo>/pulls/<n>/files?per_page=100&page=$p" -o "pr_p$p.json"; do
  n=$(python3 -c "import json,sys;print(len(json.load(open(sys.argv[1]))))" "pr_p$p.json")
  [ "$n" -lt 100 ] && break
  p=$((p+1))
done
python3 -c "import json,glob;json.dump([x for f in sorted(glob.glob('pr_p*.json')) for x in json.load(open(f))], open('pr.json','w'))"
python3 - <<'PY'
import json, re
pr = {f["filename"]: f.get("patch") or "" for f in json.load(open("pr.json"))}
golden = open("solution/golden.patch", encoding="utf-8", errors="replace").read()

# golden -> {path: [changed lines]}
blocks = re.split(r'^diff --git a/(\S+) b/\S+\n', golden, flags=re.M)[1:]
mine = dict(zip(blocks[0::2], blocks[1::2]))

def changed(text):
    return [l for l in text.split("\n")
            if (l.startswith("+") or l.startswith("-"))
            and not l.startswith(("+++", "---"))]

for path, body in mine.items():
    if path not in pr:
        print(f"NOT IN PR AT ALL   {path}")
        continue
    theirs = set(changed(pr[path]))
    extra = [l for l in changed(body) if l not in theirs]
    if extra:
        print(f"{len(extra):4d} extra changed lines   {path}")
        for l in extra[:3]:
            print(f"       {l[:100]}")
PY
```

On elfuse it printed four `NOT IN PR AT ALL` files and extra changed lines in three more. Then
search the repo's other pull requests for a distinctive new symbol from the extra lines
(`thread_wake_exit_waiters` here) to find which PR it came from, and read that PR's dates before
reaching for the FAQ's related-PR allowance.

**It is Fixable and the correction is subtractive.** `docs/guidelines.md` requires the patch to
carry "only what's needed to resolve the task" with no drive-by edits, and CLAUDE.md Step 2
item 9 calls a golden patch spanning more files than the PR a polluted oracle and a Fixable
finding. Removing another PR's material is **not** reducing the source PR's scope, so the
expansion-only boundary is not in play. The clean rebuild is to reconstruct `golden.patch` from
the API's own per-file `patch` fields:

```python
import json

out, skipped = [], []
for f in json.load(open("pr.json")):
    name = f["filename"]
    if name.startswith("tests/"):            # test changes belong in tests.patch
        continue
    patch = f.get("patch")                   # absent for binaries and very large diffs
    if not patch:
        skipped.append(name)
        continue
    if not patch.endswith("\n"):
        patch += "\n"
    status = f.get("status")
    if status == "added":
        head = f"new file mode 100644\n--- /dev/null\n+++ b/{name}\n"
    elif status == "removed":
        head = f"deleted file mode 100644\n--- a/{name}\n+++ /dev/null\n"
    else:                                    # modified
        head = f"--- a/{name}\n+++ b/{name}\n"
    out.append(f"diff --git a/{name} b/{name}\n{head}{patch}")

open("solution/golden.patch", "w").write("".join(out))
if skipped:
    print("HAND-BUILD THESE, the API returned no patch:", skipped)
```

Renames are not covered: the API reports them with `status == "renamed"` and a
`previous_filename`, and they need `rename from` / `rename to` headers. **Always finish with
`git apply --check` against the base commit** rather than trusting the reconstruction.

That produced a patch of exactly the PR's 8 non-test files which applied cleanly at the base
commit and passed the oracle 3/3. **Check the polarity of the FAQ allowance before reaching for
it as a defence**: adapting a *later related* PR for difficulty is sanctioned, and PR 161 was
created a day earlier, merged 18 seconds earlier, and was copied wholesale rather than adapted,
so none of the three bounds applied.

## Related

- `CLAUDE.md` Step 2 item 9 already requires diffing the golden patch's file list against the
  PR's. This note is the same discipline applied to *judge findings* rather than to the patch,
  and it needs the same complete file list to be trustworthy.
- `sentinel-difficulty-scope` for why the oracle cannot be shrunk to satisfy a report:
  expansion only, never reduction or replacement.
