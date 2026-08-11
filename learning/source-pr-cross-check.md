---
id: source-pr-cross-check
status: locally-verified
last_verified: 2026-08-02
verified_by:
  - 20260719_045042__oliver-oloughlin_kvdex__245
evidence: "Three Quality Check coverage findings traced back to the upstream PR and to the base commit"
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

## Related

- `CLAUDE.md` Step 2 item 9 already requires diffing the golden patch's file list against the
  PR's. This note is the same discipline applied to *judge findings* rather than to the patch,
  and it needs the same complete file list to be trustworthy.
- `sentinel-difficulty-scope` for why the oracle cannot be shrunk to satisfy a report:
  expansion only, never reduction or replacement.
