---
id: graded-tests-that-import-the-deliverable
status: locally-verified
last_verified: 2026-08-11
verified_by:
  - 20260717_182400__felixguendling_cista__172
evidence: "A complete, correct solution placed at include/cista/static_type_hash.h instead of
  include/cista/type_hash/static_type_hash.h scored reward 0, 4 of 21. instruction.md contains no
  file path at all. Deleting the one #include line from the graded test file returns 21 of 21 for
  both placements"
applies_to:
  languages: [c, cpp, python, rust, go, java, any]
  runners: [any]
  phases: [analysis, verifier-design, peer-review]
blocks_submission: true
fails_gate: [peer-review]
supersedes: []
contradicts: []
---

# A graded test that imports the file the solution must create turns the path into a graded name

The arbitrary-naming rule is usually applied to symbols. `docs/guidelines.md:149-159` also lists a
**"new module/file name"**, and the place that requirement gets broken is not an assertion. It is an
`import` or `#include` at the top of the graded test file, where nobody reads it as a requirement.

## The measurement

cista 172 asks for a compile-time type hash whose public entry point is `static_type_hash<T>()`.
`instruction.md` names **no file path anywhere**; grep it for `.h`, `include/`, `src/`, `.cc` or
`test/` and it returns nothing. Its only placement sentence is "The feature remains header-only".

`tests/tests.patch:255` is the tenth line of the graded test file:

```
+#include "cista/type_hash/static_type_hash.h"
```

Measured in the task's own image, golden applied, then the header relocated to
`include/cista/static_type_hash.h` with `serialization.h` repointed at it. Every stated requirement
still satisfied, public API untouched:

| tree | reward | passed |
|---|---|---|
| golden as shipped | 1 | 21 of 21 |
| header at a different legal path | **0** | **4 of 21** |

The graded compile dies at `test/static_type_hash_test.cc:10` with `No such file or directory`, so
no binary is produced and all 17 ids in that translation unit report missing. The 4 survivors are in
the other binary, which reaches the feature through `cista/serialization.h`.

## The remedy is one deleted line plus its hunk header, and it costs nothing

`golden.patch` already makes `cista/serialization.h` include the new header, and the instruction
already requires the feature to be wired into the serialization layer. So the public umbrella header
reaches it. Delete the direct include and keep the `#include "cista/serialization.h"` line above it.

**Decrement the hunk header in the same edit.** `tests/tests.patch:245` reads `@@ -0,0 +1,195 @@` and
must become `@@ -0,0 +1,194 @@`. Hand-editing the body without the count corrupts the patch: `git
apply --check` returns `corrupt patch at line 440` and the `patch(1)` fallback returns `malformed
patch at line 439`, so **both** apply routes in `test.sh` fail and the round scores
`infrastructure_error: tests.patch did not apply`, which is a whole round of invalid trials. Re-run
`git apply --check` after any hand edit to a patch. Better still, regenerate the patch rather than
editing it.

| tree | reward | passed |
|---|---|---|
| include deleted, golden as shipped | 1 | 21 of 21 |
| include deleted, header relocated | **1** | **21 of 21** |

**Do not fix it the other way.** Writing the path into `instruction.md` satisfies derivability and
re-opens the prescriptiveness finding it currently has none of, which is the trade
`prescriptiveness-check.md` warns about from the other side.

## The probe, and when to run it

Two minutes, and it belongs in the pre-upload sweep and in the reviewer's mechanical sweep:

1. Apply `golden.patch`.
2. Move every file `golden.patch` **creates** to another location that is legal under the
   instruction, and repoint whatever the solution itself imports it from.
3. Run the verifier.

Reward must not move. If it does, the graded suite is pinning a path the instruction never states.

Generalise past `#include`, but check how each ecosystem actually resolves the reference, because
what gets pinned is not always a path:

| Ecosystem | The shape | What is pinned |
|---|---|---|
| pytest | `from mypkg.newmod import thing` | the module path, which is the file path under the source root |
| deno, vitest | `import { x } from "../src/ext/encoding/v8/mod.ts"` | the file path, relative to the test file |
| JUnit | `import com.example.NewClass` | the package, which maven and gradle bind to the directory |
| cargo | `use mycrate::new_module::Thing` | a **module** name, not a file path. Files under `tests/` compile as their own crate, so they reach the library by its crate name and never by `crate::`. `#[path = "..."]` can decouple module from file, so the Rust case is closer to the symbol-side rule |

Anywhere the graded test reaches the deliverable by its **location** rather than through a public
entry point the instruction names, the location has become a graded name.

**The bipartite instruction-to-tests mapping does not catch this**, because the mapping walks
assertions and this lives in the header block. The pre-upload item 10 grep ("instruction and tests
name the same things") does not catch it either, because it looks for *identifiers*, not paths.

## A path can be derivable without ever appearing as a literal

The counter-argument, and it is a fair one. kvdex 245, the accepted reference bundle, has six graded
imports of paths its `golden.patch` creates and none of the six is a literal string in its
instruction. It is **not** a defect, because `instruction.md:23` states the layout as a rule:

> Serialization moves into a new `src/ext/encoding` module tree. Each of the three encoders lives in
> its own directory with a `mod.ts` barrel, and a top-level `src/ext/encoding/mod.ts` re-exports all

That composes to `src/ext/encoding/v8/mod.ts` without naming it, which is `docs/guidelines.md:157`,
"follows a standard language/framework convention", plus a stated rule. So **a grep for the literal
path is a first pass that tells you which paths to go read the instruction for, never a verdict.**
The cista case is different in kind rather than in degree: its instruction states no layout at all,
only that the feature stays header-only, so there is nothing to compose from.

## Why the tell is easy to miss on the other side

The oracle can never reproduce it. `golden.patch` puts the file exactly where the test expects,
because both were written by the same person in the same sitting. The failure only exists for an
agent, so a green Oracle Check says nothing about it, and the difficulty run reports it as an
ordinary low pass rate rather than as a harness problem. On this bundle `task.toml` records
`pass_at_k` 0/3 for both graded models on arrival, and this is a plausible part of the reason.
**That last link is inference and not measurement** - no trial transcript was read for this bundle.
What would settle it: a difficulty artifact showing an agent that implemented the feature correctly
and lost the whole translation unit to the include.

See also [non-derivable-private-names.md](non-derivable-private-names.md) for the symbol-side version
and LEDGER **L24**, where the fix was to repoint the tests rather than to state the name.
