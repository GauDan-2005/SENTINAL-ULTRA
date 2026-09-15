---
id: bundler-resolved-modules-are-gradeable
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260719_045042__openwhispr_openwhispr__1002
evidence: "openwhispr 1002 round 1 left the settings store ungraded on the reasoning that it is renderer TypeScript the node test runner cannot load. The agentic judge returned DISCUSS coverage_gap naming exactly that. A resolve hook supplying the two things the app's bundler supplies loads the real module in about 150 ms with its own code unmodified, and the round that graded it was accepted"
applies_to:
  languages: [typescript, javascript, any]
  runners: [node-test, any]
  phases: [verifier-design, quality-check]
blocks_submission: true
fails_gate: [quality-check]
supersedes: []
contradicts:
  - "the reflex that a module the test runner cannot import is therefore out of grading reach"
---

# A module the test runner cannot import is not a module you cannot grade

## The third instance of one wrong premise

This workspace has now paid for the same mistake three times, on three unrelated tasks, in three
different languages:

| Note | The premise | What it actually was |
|---|---|---|
| [platform-locked-repos-are-still-testable.md](platform-locked-repos-are-still-testable.md) | the verifier cannot **build or run** this program | its translation units cross-compiled and ran under qemu on the same image |
| [airgapped-means-no-egress-not-no-sockets.md](airgapped-means-no-egress-not-no-sockets.md) | this needs a **live server** and the verifier has no network | a listener on `127.0.0.1` inside the test process graded it |
| this note | the test runner cannot **import** this module | the runner needed the two things the app's bundler already supplies |

The shape is identical every time. A layer is declared out of reach, the requirement is either
narrowed away or stated with a disclosure, and the agentic judge names that layer as a coverage
gap. **`Reason: coverage_gap` on a layer you decided not to grade is the single most repeated
finding in this workspace.**

LEDGER **L39** already says the rule for the live-server case. This note is the rule for the
import case, and the generalisation is in the last section.

## What happened

openwhispr 1002 unifies BYOK secret plumbing across four layers. Three of them are plain
CommonJS the runner loads without help. The fourth, `src/stores/settingsStore.ts`, is renderer
TypeScript. Round 1 concluded it could not be graded, narrowed the instruction, and shipped. The
judge came back:

> they never import or exercise `src/stores/settingsStore.ts`; they only assert the manifest's
> `storeKey` string. Thus a plausible implementation that leaves the settings store without an
> OpenRouter state key/setter or without persisting under `storeKey` would still pass.

That is true, and it was true because of a decision rather than a constraint.

## What actually blocked the import, measured one layer at a time

Node 24 is closer to being able to load this than it looks. Peel the failures in order and each
one is small:

```
node -e 'import("/app/src/stores/settingsStore.ts")'
  1. (nothing)  -> types are stripped natively, TypeScript is not the blocker
  2. Cannot find module '/app/src/config/constants'
                -> extensionless relative imports, which the bundler resolves and node does not
  3. Module ".../src/locales/de/prompts.json" needs an import attribute of "type: json"
                -> json imports, which the bundler handles and node requires to be declared
  4. TypeError: window.dispatchEvent is not a function
                -> browser globals the module touches while loading
```

None of those is "this cannot be graded". They are four lines of setup, and all four are things
the application's own build already does.

## The shape that works

`module.registerHooks` is synchronous and available in node 22.15 and above. The resolve hook
does exactly what the bundler does and nothing more, so the module under test runs unmodified:

```js
const { registerHooks } = require("node:module");
registerHooks({
  resolve(spec, ctx, next) {
    if ((spec.startsWith(".") || spec.startsWith("/")) && ctx.parentURL) {
      const base = path.resolve(path.dirname(new URL(ctx.parentURL).pathname), spec);
      for (const ext of ["", ".ts", ".tsx", ".js", ".json", "/index.ts", "/index.js"]) {
        const candidate = base + ext;
        try {
          if (fs.statSync(candidate).isFile()) {
            const resolved = next(new URL(`file://${candidate}`).href, ctx);
            return candidate.endsWith(".json")
              ? { ...resolved, importAttributes: { type: "json" } }
              : resolved;
          }
        } catch { /* try the next extension */ }
      }
    }
    const resolved = next(spec, ctx);
    return (resolved.url || "").endsWith(".json")
      ? { ...resolved, importAttributes: { type: "json" } }
      : resolved;
  },
});
globalThis.window = globalThis;
globalThis.localStorage = { getItem: () => null, setItem() {}, removeItem() {} };
globalThis.dispatchEvent = () => true;
globalThis.addEventListener = () => {};
```

Measured: the real store loads in about **150 ms**, exposes all eight provider keys and all eight
setters, and the whole 18-test file runs in 1.8 s.

**Stub the environment, never the module under test.** The hook supplies resolution. The globals
supply a browser. Neither replaces a line of the store, which is what keeps this coverage rather
than [mock-standing-in-for-the-deliverable.md](mock-standing-in-for-the-deliverable.md).

## Grade the behaviour the layer is actually for

Loading it is not the point. The point is that the layer can now be driven end to end. The store
persists under a key and routes through a saver map to the main process, so hand it a recording
`window.electronAPI` and drive the real setter:

```
for each manifest entry:
  call state's own setter for entry.storeKey, passing a secret
  -> state[entry.storeKey] === that secret           // it landed under the right key
  -> electronAPI[entry.save] was called              // it reached the right accessor
```

Measured on the accepted bundle: all eight providers route to exactly their own `save` accessor.
Three controls prove it discriminates, each dropping the reward to 0.0:

| Control | Caught by |
|---|---|
| the provider left out of the store entirely | both store tests |
| its setter pointed at another provider's save accessor | the routing test |
| its store key renamed | the key test |

The middle one is the one worth having. A store that saves under the right key but calls the
wrong accessor is exactly the drift the task is about, and no source-text check would see it.

## The rule

**Before writing "this layer cannot be graded" anywhere, spend twenty minutes failing to load
it.** Read the error, fix that one thing, read the next error. The question is not whether the
runner loads it today, it is how many of the bundler's jobs you have to do by hand, and the
answer has been four or fewer every time.

Three further points, each of which cost something here:

- **A disclosure does not close a coverage gap.** The panel does not read Comments for Reviewer
  (LEDGER L18), and the judge named this layer in the round that disclosed it.
- **Narrowing the instruction while still mentioning the layer is the worst of both.** Round 1
  narrowed the claim that all four layers come from one definition, correctly, because the source
  PR does not unify the store. It still described `storeKey` as the key the store persists under,
  so a stated requirement with no assertion survived, and that is what came back. Either grade
  the layer or stop referring to it.
- **Weigh the loader against what it depends on.** The rejection reflex here was
  [diagnosing-platform-only-failures.md](diagnosing-platform-only-failures.md), do not build on
  what you cannot observe. That rule is about the platform's environment, which you cannot
  inspect. A resolve hook runs inside your own image against files you ship, so it is fully
  observable, and the honest test is whether it is deterministic there. Five consecutive runs
  and the full battery said yes.

See also [[platform-locked-repos-are-still-testable]], [[airgapped-means-no-egress-not-no-sockets]],
[[grade-the-derivation-not-the-instances]], [[quality-check-criteria]].
