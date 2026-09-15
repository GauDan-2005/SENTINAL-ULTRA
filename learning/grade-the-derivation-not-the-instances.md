---
id: grade-the-derivation-not-the-instances
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260719_045042__openwhispr_openwhispr__1002
evidence: "An implementation that declared the required manifest and then hand-wrote the eight accessors and eight channel registrations beside it scored 13 of 13 against a suite that graded every stated behaviour. Adding a ninth entry to the manifest at run time and reloading the consumers fails that implementation on exactly two ids and nothing else"
applies_to:
  languages: [any]
  runners: [any]
  phases: [verifier-design, quality-check, difficulty]
blocks_submission: true
fails_gate: [quality-check]
supersedes: []
contradicts:
  - "the assumption that a suite covering every stated behaviour therefore covers the architecture the task is about"
---

# When the task is "define it once", grading every instance proves nothing

## The gap

A refactor task's whole point is often structural: one shared definition, and every consumer
derives from it. openwhispr 1002 states it plainly, that adding a provider becomes a one entry
change.

A suite can grade every stated behaviour of that feature and still be blind to it. Round 1 of
that task graded the manifest shape, the generated accessors, the round trip, the clearing
semantics, the persistence, the IPC channels, the preload bridge and the lockstep between them.
Sixteen ids, each with a hostile probe that fired. The agentic judge still said:

> a solution that adds the manifest but keeps separate hand-coded accessors/channels can pass

**Measured rather than argued.** An implementation was written that declares the manifest exactly
as required and then hand-writes the eight accessor pairs and the eight channel registrations
next to it:

```
hand-coded implementation, manifest present but nothing derives from it
  vs the 13-test round 0 suite:   13 pass, 0 fail
```

Every instance behaved correctly, because the instances *were* correct. Nothing asked whether
they came from the manifest.

## The technique

Grade the derivation by changing the shared input and watching the consumers follow. Add an entry
that exists nowhere else, reload the consumers against it, and require them to have picked it up
with no other edit:

```js
const ADDED = { base: "sentinelprobe", env: "SENTINELPROBE_API_KEY",
                get: "getSentinelprobeKey", save: "saveSentinelprobeKey",
                storeKey: "sentinelprobeApiKey" };

function withProviderAddedToManifest(body) {
  const previous = Module._load;
  const drop = () => { for (const p of [MANIFEST, MANAGER, IPC]) delete require.cache[p]; };
  drop();
  Module._load = function (request, parent, isMain) {
    // match on the RESOLVED path, not the request string: consumers spell it differently
    try {
      if (Module._resolveFilename(request, parent) === MANIFEST) {
        return { BYOK_API_KEYS: [...REAL, ADDED] };
      }
    } catch { /* not resolvable from here */ }
    return realLoad.call(this, request, parent, isMain);
  };
  try { return body({ Manager: require(MANAGER), Handlers: require(IPC) }); }
  finally { Module._load = previous; drop(); delete process.env[ADDED.env]; }
}
```

Then assert the new provider works end to end, and separately that it is gone again once the real
manifest is back, so the test cannot leave state behind for the next one.

Measured against the same hand-coded implementation:

```
  vs the 18-test suite:   16 pass, 2 fail
    not ok - a provider added to the manifest gets working accessors with no other edit
    not ok - a provider added to the manifest gets main process channels with no other edit
```

Two ids, precisely the two that grade the property, and no collateral. That is what a
discriminating test looks like.

## Four mechanics that decide whether it works

- **Match the shared input by resolved path.** Consumers reference it differently
  (`../config/secretKeys`, `./secretKeys`), so comparing request strings misses one.
  `Module._resolveFilename(request, parent)` normalises them.
- **Drop the consumers from the module cache, not just the input.** They captured the old value
  at load time; re-requiring the input alone changes nothing.
- **Restore, and assert the restoration.** The suite asserts the extra provider is absent from a
  fresh manager afterwards. Without that, a leak turns into a mystery failure three tests later.
- **Only some consumers can follow.** The sandboxed preload inlines its copy by design, so it
  cannot react to a runtime manifest change and is deliberately not part of this test. Say which
  consumers the property covers, or the test is asserting something the task never asked for.

## Where this generalises

Any requirement of the form *X is defined in one place and Y derives from it* is gradeable this
way, and the instance tests never reach it:

| Requirement | The mutation |
|---|---|
| routes come from one table | add a route to the table, assert the router serves it |
| the schema drives validation | add a field, assert validation covers it |
| the registry drives the plugin loader | add an entry, assert the loader finds it |
| one config drives N consumers | change a value, assert every consumer changed |

The tell that you need it: the instruction contains "exactly once", "single source of truth",
"adding one should be enough", or "without touching anything else". Those are testable
statements, not aspirations, and a judge reads them as requirements.

## Two side effects worth knowing

**It is a difficulty lever, measured.** A competent implementer who declares the manifest and then
writes the accessors out by hand is producing a plausible implementation that the suite now
rejects, which is exactly the discriminator
[difficulty-levers-must-discriminate.md](difficulty-levers-must-discriminate.md) asks for.

**It costs no instruction surface.** The requirement was already stated. What changed is that a
sentence describing the mechanism ("the manager derives its accessors from the manifest") became
a sentence describing the outcome ("a ninth entry should work end to end on its own"), which
reads as a requirement rather than a strategy and answers the over-specification axis at the same
time.

See also [[bundler-resolved-modules-are-gradeable]], [[difficulty-levers-must-discriminate]],
[[probe-the-instruction-you-already-wrote]], [[quality-check-criteria]].
