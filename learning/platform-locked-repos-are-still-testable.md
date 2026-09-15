---
id: platform-locked-repos-are-still-testable
status: platform-confirmed
last_verified: 2026-08-11
verified_by:
  - 20260809_080653__sysprog21_elfuse__162
evidence: "A bundle graded a macOS Hypervisor.framework program with 15 source-text tests, justified by 'it cannot be built or exercised on the Linux verifier'. Its time.c, proc.c and syscall.c cross-compiled for aarch64 and ran under qemu-user-static on that same ubuntu:24.04 verifier. Rebuilt behavioural, accepted. The defect was caught in analysis so it never reached a platform gate"
applies_to:
  languages: [c, cpp, objc, swift, rust, any]
  runners: [any]
  phases: [analysis, verdict, tests, packaging]
blocks_submission: true
fails_gate: [none]
supersedes: []
contradicts: []
---

# "The verifier cannot run this code" is a claim to measure, not a premise to build on

Source: `20260809_080653__sysprog21_elfuse__162`, sysprog21/elfuse PR 162, accepted 2026-08-11.

## What happened

elfuse runs Linux ELF binaries on macOS inside a Hypervisor.framework VM. `README.md` lists
"macOS on Apple Silicon" and the hypervisor entitlement as requirements,
`environment/repo/src/core/guest.h:22` and `src/syscall/proc.h:18` include
`<Hypervisor/Hypervisor.h>`, and `src/syscall/proc.c` includes `<libproc.h>` and
`<sys/sysctl.h>`. The verifier image is `ubuntu:24.04`.

The bundle drew the obvious conclusion and wrote it into the graded test file's own docstring:

> elfuse is an aarch64-linux executor built on macOS Hypervisor.framework, so it can't be built
> or exercised on the Linux verifier host. These tests inspect the source instead.

All 15 `fail_to_pass` ids then graded source text rather than behaviour: 13 by regex over `.c`
and `.h`, one over `src/syscall/dispatch.tbl`, and one (`test_generated_dispatch_header_wires_times`)
by running the dispatch generator and regexing its output, which is the only id in the suite that
executes anything at all. Two of the 13 use plain substring membership rather than `re.search`.
Grading source text is banned by name in two places: `docs/guidelines.md:135` forbids grading "by patch structure, diff format,
line numbers, file names, or source-code keyword matching" and requires tests to "verify
observable behavior by running code and checking results", and `docs/tasking-guide.md:324` puts
"Don't assert on source code text" on the Quality Check judge's own Don't list.

**How weak it was, measured rather than asserted.** A 37-line no-op whose handler body is
`if (0) { ... } return 0;` passes all 15. Appending `this is not valid C at all ;;; ###` to
`src/syscall/time.c` and `@@@ broken @@@` to `src/syscall/proc.c` also passes all 15, so the
suite did not require the submission to compile.

**The premise was true and the conclusion was false.** The *program* cannot run on Linux. The
*translation units* compile and run fine. Nobody had checked.

## The measurement ladder

Five commands, in this order, roughly twenty minutes. Each one narrows what is actually
impossible. **Run them in the task's own image, not on the host.** Steps 1 to 3 below were run on
the host first and then re-run inside a container built from `environment/Dockerfile`; the
compiler that decides the answer is the one the image pins, and `verify-in-the-image.md` owns the
rule.

| Step | Command shape | elfuse result |
|---|---|---|
| 1 | `gcc -fsyntax-only -I <shim> -I src <the one file you care about>` | 0 errors after a 30-line throwaway stand-in for `Hypervisor/Hypervisor.h`. The shipped one grew to 89 lines once every unit had to compile |
| 2 | Same for every unit the feature touches | `proc.c` needed stand-ins for `libproc.h` and `sys/sysctl.h`, then 0 errors |
| 3 | `gcc -c` on the host arch, **not** `-fsyntax-only` | `proc.c` **failed**: `Error: no such instruction: 'mrs %rax,cntfrq_el0'`, from the unguarded `__asm__` at `src/syscall/proc.c:1970` |
| 4 | Cross-compile for the repo's real arch and run a trivial binary under qemu-user | `aarch64-linux-gnu-gcc -static` plus `qemu-aarch64-static`, works |
| 5 | Cross-compile every unit, then link | all three units built; linking **all 24** compilable units failed on duplicate symbols |

**Step 3 is the one people skip and it is the one that bites.** `-fsyntax-only` never reaches
the assembler, so a translation unit carrying one unguarded target instruction looks perfectly
portable right up to the point you ask for an object file. `src/syscall/proc.c:1970` in the
shipped tree is a single `__asm__ volatile("mrs %0, cntfrq_el0")`, and `grep -c __aarch64__
src/syscall/proc.c` returns **0**, so nothing guards it. That one line decided the whole design:
host-native was out, cross plus qemu was in.

**Cite the source line you grepped, not the one the error prints.** The failure arrives from the
assembler stage, and its line number does not have to agree with the source: the same
instruction reported as `proc.c:2031` on a golden-applied copy sits at `proc.c:2021` in that copy
and at `proc.c:1970` in the shipped tree. Locate it with `grep -n` and quote that.

**Step 5 decides the shape.** Linking everything that compiles is the tempting move and it does
not work, because the units you did not need redefine things your stub file provides. Keep the
list to the units the feature lives in and resolve the rest at link time.

## The build that resulted

Committed as `tests/sentinel-hostcheck/` in
`_archive/20260809_080653__sysprog21_elfuse__162/work/tests/tests.patch`.

```
tests/sentinel-hostcheck/
  hvshim/Hypervisor/Hypervisor.h   89 lines, types and enum constants only, no function bodies
  hvshim/libproc.h                 Darwin headers the units include
  hvshim/sys/sysctl.h
  hvshim/prelude.h                 forced first include, see the glibc note below
  hostcheck.h                      report_i(key, value), SCENARIO(name)
  hostcheck-stubs.h                what the probe may observe
  stubs.c                          guest memory, the getrusage interposer, a CPU burner
  probe_core.c                     the thing that actually drives the code
  hostbuild.py                     compile, link, run
tests/test_sentinel_times_host.py  the pytest driver holding all 24 graded ids
```

`tests/manifest.txt` is the one pre-existing file the patch edits; everything else it creates.

Six things in there are the reusable part.

**1. The stand-in header carries types and constants, never function bodies.** Every `hv_*`
entry point is declared and left undefined; the link resolves them to a placeholder and no probe
calls one. Writing fake implementations is how a shim starts lying about behaviour.

**2. `#include` the `.c` file when the thing you need to reach is `static`.** elfuse's dispatch
table is `static const syscall_entry_t syscall_table[SC_TABLE_SIZE]` inside
`src/syscall/syscall.c`. `probe_core.c` does `#include "syscall/syscall.c"` and then indexes it
directly. That single line is what turned "does the source contain the right words" into "call
whatever is in slot 153 and see what it does". Do not link that unit separately as well.

**3. Reach the deliverable by its public number, not by its symbol.** The probe calls
`syscall_table[153].handler(g, buf_gva, ...)`. It never names `sys_times`, `sc_times`,
`proc_children_cpu_add` or anything else the solution creates. That is what let the rewritten
instruction name **zero** internal files, functions and host APIs and still be gradeable, and it
is the same move `non-derivable-private-names.md` records in Go. That note owns the rule and the
reasoning; the one-line version is that the instruction's prescriptiveness floor is set by the
names its tests demand, so moving the floor is a test edit rather than an instruction edit.

**4. Interpose the host calls you want to reason about.** `stubs.c` defines `getrusage` in the
executable, which wins over libc for calls from the linked units, records which `who` argument
the code asked for, and forwards to the kernel with `syscall(SYS_getrusage, who, usage)` so the
numbers stay real. That converts "must not read the host's aggregate children accounting" from a
source grep into an observation. The same trick covers `clock_gettime`, `open`, `stat` and
anything else the contract is really about.

**5. The strongest test is usually a negative one built from the mistake the obvious
implementation makes.** PR 162's own description says "RUSAGE_CHILDREN supplies
tms_cutime/tms_cstime" while the merged code reads a private proc-layer accumulator instead, so
the description records the natural approach and the merged code records the correction. Whether
that change came from review is an inference and the review thread was never fetched; what is
measured is the divergence between the PR body and its own merged diff.
The graded test built from that is `test_helper_subprocess_cpu_stays_out_of_the_child_totals`:
fork a child, burn CPU, reap it with plain `waitpid` outside the process table, assert the child
totals did **not** move. Two of the 24 ids caught the RUSAGE_CHILDREN hostile probe, that one and
`test_a_peek_does_not_credit_child_cpu`, and the other 22 passed it. Neither of the two is a test
anybody writes from the requirement alone; both come from asking what the obvious implementation
would get wrong.

**6. Make the probe build at the base commit, on purpose.** `probe_core.c` names no symbol the
solution introduces, so it compiles and links against the unsolved tree. The consequence is the
whole point:

```
NOP: reward 0, raw_exit 1, infrastructure_error None, 8 of 24 passing, 16 f2p missing
```

Those 8 are regression guards that genuinely executed at base. `verify-in-the-image.md` tells
you to split the graded ids and run the ones that compile, and CLAUDE.md Step 5.5 offers a
symbol audit when you cannot. **This is a third and better option: design the harness so the
split is automatic and every f2p failure is behavioural rather than compile-bound.** It costs
nothing at design time and it removes the whole class of "the zero proves nothing" doubt.

## `hostbuild.py`, and why it is not a fixed command list

Two-pass link. Compile the fixed unit list, try to link, parse the failures, react, retry.

- `undefined reference to 'X'` where some other `src/**/*.c` defines `X` at line start:
  **compile that file too**. This is what makes the harness survive a correct solution that put
  the handler in a new file, which in turn is what let the instruction stop naming placements
- `undefined reference to 'X'` where nothing defines it: emit `long X(); long X() { return 0; }`
  into a generated `inert.c`
- `X: TLS reference in ... mismatches non-TLS definition`: emit `__thread long X;` instead

Three traps that cost real time here:

- **Compile the generated placeholder file bare.** With the normal flags it meets the real
  prototype from a header and fails with `conflicting types for 'pthread_set_qos_class_self_np'`.
  Build it with `-O1 -g0 -std=gnu11` and no `-include`, no `-I`
- **`-Wl,--unresolved-symbols=ignore-all` is not a substitute for stubs.** It resolves the
  missing symbol to address 0, so the link is green and the call segfaults. Three scenarios
  looked like probe bugs before that was understood. Let the link fail and generate placeholders
  from what it names
- **glibc defines `si_code`, `si_status` and friends as macros.** Sources written against the
  macOS SDK use those spellings as ordinary identifiers and stop parsing. A forced-first
  `prelude.h` that `#undef`s them, plus a couple of Darwin-only constants, fixed every remaining
  error in a 3000-line file

## What it costs

`gcc-aarch64-linux-gnu`, `libc6-dev-arm64-cross` and `qemu-user-static` added to the verifier
dependency layer of `environment/Dockerfile`. **Be careful how this is justified, because the
obvious citation is backwards.** The allowed-fix table at `docs/guidelines.md:316-326` does not
list "add a toolchain the tests need", and `guidelines.md:332`, which carries the useful phrase
"Adding a missing dev package or flag is under worth fixing", is a row of the **Not Fixable**
table rather than the fixable one, so quoting it as authorization cites the wrong table. What
actually grounds it is `docs/tasking-guide.md:41`, which requires you to "bake test dependencies
into the image instead of fetching them when the tests run" precisely because "the verifier runs
fully airgapped". The toolchain is a test dependency. Treat the rest as an inference and say so
in Comments for Reviewer, which is what was done here. Build timeout went 900 to 1500 to
pay for the install. Verifier runtime for the whole graded suite, build included, was about
**15 seconds** against a 1200 second timeout.

## The rule

When a bundle grades source text, or leaves a stated requirement ungraded, and the reason given
is that the verifier cannot build or run the thing: **treat that as an untested claim and spend
twenty minutes on the ladder above before you accept it.** It is the same failure
`airgapped-means-no-egress-not-no-sockets.md` records from the other direction, where "this
needs a live controller" turned out to mean "this needs a socket on 127.0.0.1". That note already
carries the standing ordinal for the disclosure-instead-of-grading result, whose ledger row is
**L39** (ziti-sdk-c 668, the judge returning REMOVE on two requirements that had been described
rather than graded); this is a further instance of the same thing and does not renumber it.
**Do not cite `L18` for that result** - `LEDGER.md` carries two rows numbered L18 and the one
usually meant records something else, that refuting a false judge claim does not clear it.

Second half of the rule, for the verdict. **Not Fixable is a closed list of two**
(`docs/guidelines.md:66`), PR scope needing reduction and the environment issues at
`guidelines.md:330-334`. "The verifier host cannot execute the software under test" is on
neither list, and `docs/` is silent on cross-platform, macOS-only and hardware-dependent repos. Measured across
the eight policy tabs: `Darwin`, `Apple`, `aarch64`, `hypervisor` and `cross-platform` do not
appear at all, and `macOS` appears six times, every one of them zip-command boilerplate about
`__MACOSX/` and `.DS_Store` (`docs/guidelines.md:381`, `docs/tasking-guide.md:83`, `:93`, `:99`,
`:102`, `:104`). Re-measured 2026-08-14 against the 2026-08-13 export, which added the Reviewer
Rubric tab: all six citations still resolve to the same lines, the counts are unchanged, and the
new tab carries none of the five terms. So reaching Not Fixable that way is an **inference**, and
on this task the inference was also false.

## What acceptance validated, and what it did not

Validated, because it shipped and a reviewer signed it off: the whole approach of grading a
platform-locked target through a cross-built probe, the Dockerfile addition, an instruction
naming zero internal paths, and f2p 16 / p2p 8 with `allow_extra_failures` false.

Not validated, because nobody had to open the bundle to check: the two-pass link and the
generated placeholders, the `sh` re-exec guards, the restore payload, and the exit-code gate.
All four were measured locally and no platform result speaks to any of them. The submitter
supplied only the word accepted, so there is no panel output, no round count and no artifact
behind this note beyond the local runs and the outcome.
