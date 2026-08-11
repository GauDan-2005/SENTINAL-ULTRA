---
id: non-derivable-private-names
status: locally-verified
last_verified: 2026-08-06
verified_by:
  - 20260809_080653__sysprog21_elfuse__162
  - 20260805_220102__xaaha_hulak__118
evidence: "17 of 17 graded ids in a bundle depended on six private method names that existed nowhere except the reference solution; repointing the tests at the rendered view removed all six and every hostile probe still fired"
applies_to:
  languages: [go, any]
  runners: [go-test, any]
  phases: [analysis, verifier-design, fixing]
blocks_submission: true
fails_gate: [difficulty, quality-check, peer-review]
supersedes: []
contradicts:
  - "the common reading that a graded test needing a lookup key has to ask the implementation for one"
---

# When the graded tests need a name only the reference solution knows

## Second confirmation, in C, and this time it removed nine file paths (elfuse 162, 2026-08-11)

The fix this note records, point the tests at what the caller sees rather than at the
implementation's own vocabulary, reproduced on a completely different stack and had a larger
side effect than expected.

`20260809_080653__sysprog21_elfuse__162` graded a Linux syscall handler inside an emulator. The
shipped tests demanded, by name, `sys_times`, `sc_times`, `SC_FORWARD`, `proc_children_cpu_add`,
`proc_children_cpu_us`, `guest_write` and the parameter spelling `buf_gva`. Four of those seven
do not exist at the base commit (`sys_times`, `sc_times`, `proc_children_cpu_add`,
`proc_children_cpu_us`), so they had to be stated in `instruction.md`, and stating them is why
that instruction named nine internal file paths and read as a construction plan. The other three
do exist at base and are a different objection: `SC_FORWARD` is one of three wrapper macros the
file uses, `guest_write` is an internal helper, and `buf_gva` is a parameter spelling, so
demanding them grades internal vocabulary rather than a contract.

The replacement suite reaches the feature through the **syscall number**:

```c
syscall_table[153].handler(g, buf_gva, 0, 0, 0, 0, 0, false);
```

153 is the aarch64 ABI number for `times(2)`, a public fact about Linux rather than anything the
repository chose. Nothing else in the 24 graded tests names a symbol the solution introduces.

**The size of the knock-on is the finding.** Once no test demanded a name, the instruction had
nothing left to leak: it went from nine file paths, five internal symbols, two host API calls and
a literal guard expression to **zero of all four**, and the local Quality rehearsal returned 0
navigation hits and 0 of 174 test literals appearing in it. The causal direction is worth stating
plainly because it is the opposite of how the fix usually gets attempted:

**An instruction cannot be de-prescribed below the names its tests demand. That floor is a
property of the tests, not of the task.** Cutting names out of the instruction while the tests
still require them is what manufactures `Task Instruction Sufficiency: FAIL`
(`prescriptiveness-check.md`). Rewriting the tests to stop requiring them lowers the floor, and
the instruction edit then costs nothing and breaks nothing.

## What it looks like

hulak 118 shipped with 17 graded ids and six private Go method names holding them up:
`Model.operationZoneID`, `Model.endpointZoneID`, `Model.searchZoneID`, `Model.detailMousePrefix`,
`SelectorModel.itemZoneID`, `SelectorModel.searchZoneID`. None exists at the base commit. None is
stated in `instruction.md`. The tests call all six by exact spelling.

**Go makes the blast radius total.** A package compiles as a unit, so one wrong private name stops
the whole test binary building and every graded id in that package reports missing. Six unguessable
names took down all 17 ids, including the six pure unit tests that never touch them. The same shape
in pytest or JUnit costs you one test; in Go, cargo, or any per-package compiler it costs the package.

**It is indistinguishable from difficulty in the arrival metadata.** This task arrived
`pass_at_k_opus_4_8 = "0/3"`, `pass_at_k_gpt_5_5 = "0/3"`, `agent_hardened = "true"`,
`hardening_cycles = "2"`. Every one of those numbers is what you would expect from a genuinely hard
task and also what you get from a task nobody can pass. `prescriptiveness-check.md` already warns the
pattern "looks exactly like difficulty". **Run the identifier audit before reading a pass rate.**

The audit, one command per candidate, inside the working copy's repo:

```bash
# every identifier the graded tests call, checked against the base commit
git grep -c -- '<name>' HEAD -- '*.go'     # 0 means it does not exist at base
grep -c -- '<name>' ../../instruction.md   # 0 means the agent was never told
```

Both zero on the same name is the defect.

## The fix that was said not to exist

An adversarial verifier on this bundle concluded: *"The alternative, repointing the tests off these
helpers, is not available, because the tests need a zone id to look bounds up with."* That is wrong,
and the reason it is wrong generalises well beyond click zones.

**A test does not need the implementation's lookup key. It needs the thing the user sees.** These
tests were rewritten to render the real view, find the row they want by the text drawn on it, and
send the click at that cell:

```go
// the screen cell where want is drawn, failing when it is missing or ambiguous
func sentinelCellOf(t *testing.T, view, want string) (int, int)
```

That removed all six names from the tests and let all six come out of the instruction in the same
edit. It is also a **stronger** check: the old test asked the model for an id and trusted it, while
the new one only passes when the registered region actually lines up with the visible row. Every one
of 18 hostile probes still fired, each naming its test.

Two mechanics that made it work and are worth copying:

- **Own the fixtures so the target string is unique.** Do not reuse the repo's sample data. Build
  operations named `opalpha`, `opbeta`, `opgamma` so a text search has exactly one answer, and assert
  the count is one rather than taking the first hit.
- **Anchor when the same text is drawn twice.** The explorer repeats endpoint names in a badge bar
  above the search box, so a bare search matched two cells. `sentinelCellBelow(view, "Search:", want)`
  takes the occurrence under a unique anchor and fails when there is not exactly one.
- **Column precision does not have to be exact.** The target text sits several cells inside the
  region, so a one-cell disagreement between two width implementations cannot move the click out of
  bounds. Row precision is exact, because newlines are unambiguous.

## bubblezone registers zones on a worker, and every scan wipes the last one

Measured in `bubblezone@v1.0.0` (`manager.go`), because the shipped tests polled a 250 ms deadline
and nothing said why:

- `Manager.Scan(v)` stamps an iteration number, sends every marked region to a buffered channel, then
  sends a bare marker. A single `zoneWorker` goroutine consumes in order.
- On the bare marker the worker **deletes every zone whose iteration differs**. So each scan clears
  the previous scan's zones, and a probe scanned before a render does not survive it.
- `Get(id)` reads stored state, so a read straight after `Scan` can miss. The library's own tests
  `time.Sleep(15 * time.Millisecond)`.

That kills the obvious barrier (scan a probe after the view and wait for the probe), because the
probe's own scan would wipe the view's zones. **Invert it:**

```go
// arm a probe, render, then wait for the probe to disappear. The render's scan
// clears other iterations as its last act, so probe-gone means every region from
// that render is stored.
settled := sentinelArmZones(t)
view := model.View()
settled()
```

Two things fall out for free. The wait is a real happens-before signal rather than a sleep guess, and
when the implementation never calls the scan function the probe never clears, so the barrier fails
with `the rendered view never passed through ScanMouseZones`. That is an instruction requirement no
other assertion reached.

## Two smaller measurements from the same task

**`go test ./...` exited 0 on this repo, at base and at the oracle.**
`go-task-verifier-gotchas.md` documents the opposite on firefly 1123 and prescribes scoping the
command. Here scoping was unnecessary and the whole-repo command kept the exit-code gate safe while
still policing every package. The note's own instruction is the right one: **measure the bare exit on
a green tree, do not assume either answer.** Small repo, no e2e suite, no generated-file comparison.

**A full test-tree restore makes an agent-written failing test invisible, which changes how you prove
the exit-code gate.** The first attempt at demonstrating the fail-open grader wrote a failing test in
an ungraded package. The restore deleted it before the run, so the reward stayed 1.0 and proved
nothing. Use a **non-test** compile break instead: a bad `.go` file in a package with no tests leaves
all graded ids passing and still exits nonzero. That produced the clean pair, stock grader 1.0 with
`raw_exit 1`, gated grader 0.0.

**Assert that a hostile probe's own edit landed.** One probe in the first sweep used `sed` with a `|`
delimiter against a line containing `||`. `sed` errored, the tree was untouched, the reward read 1.0,
and it looked like a coverage hole. Every probe now does its edit in Python with
`assert old in s, 'SABOTAGE DID NOT LAND'`. `verify-in-the-image.md` names this failure mode and it
still happened.

## It comes back, and it comes back in a helper (hulak 118 round 3, 2026-08-09)

Round 0 of that task removed six private names from the graded surface and wrote the technique up
above. **Round 2 put one back.** Adding a list-row check, the obvious way to find the row was
`byMouse.itemZoneID(listPrefix, 0)`, and the agentic judge blocked the round with
`Status: DISCUSS, Reason: overreach` naming that one line. Two strikes on one signature, both
self-inflicted, three rounds apart.

**The fix is not a better technique, it is a per-round audit.** The technique was already right and
already documented. What was missing was anything that re-checked it after a later edit:

```bash
# every identifier the graded tests touch, in one pass, every round
#   absent at the base commit AND missing from instruction.md  ->  overreach
git -C environment/repo grep -c -- "<name>" HEAD -- '*.go'   # empty means new
grep -c -- "<name>" instruction.md                            # 0 means unstated
```

Run it over **both** graded files and over every selector, not the one a report happens to name. On
this bundle it prints 8 new identifiers, all 8 stated, none unnamed. That takes seconds and it is
the only thing standing between a green local battery and this finding.

### The second one was in a test helper, not an assertion

Auditing after the fix turned up a case no report had named. The barrier the graded tests use to
wait for regions to be recorded works by watching an earlier region **disappear**, so it silently
required that a fresh scan replaces what the previous scan recorded. Nothing in the instruction said
so. Measured in the image:

```
first region recorded=true, still recorded after a later scan=false
=> the barrier used by the graded tests depends on this being false: true
```

An implementation that kept every region would have satisfied every written word and failed most of
the suite.

**Generalisation worth carrying: a helper is graded surface.** The bipartite mapping in the rules
walks assertions against requirements, and a `waitFor`, a barrier, a fixture builder or a coordinate
finder can carry a contract that no assertion mentions. Read the helpers as if each precondition
they rely on were an assertion, because for a failing implementation that is exactly what they are.
The remedy is the same either way: state the rule, or stop depending on it.
