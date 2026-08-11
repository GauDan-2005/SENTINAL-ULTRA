---
id: airgapped-means-no-egress-not-no-sockets
status: platform-confirmed
last_verified: 2026-08-09
verified_by:
  - 20260808_213817__openziti_ziti-sdk-c__668
  - 20260807_080545__tair-opensource_redisshake__1005
evidence: "ziti-sdk-c 668 round 0 shipped with peer learning and the online-state rule stated and ungraded, on the reasoning that observing them needed a live controller. The agentic judge returned Status REMOVE, Reason coverage_gap, and both judges named those two requirements. A loopback HTTP server inside the test process graded both, and 12 of 12 hostile probes then landed"
applies_to:
  languages: [any]
  runners: [any]
  phases: [verifier-design, quality-check]
blocks_submission: true
fails_gate: [quality-check]
supersedes: []
contradicts: []
---

# "It needs a live server, and the verifier has no network" is almost never true

## What happened

ziti-sdk-c 668 is an HA controller failover feature. Two of its requirements only show up once a
controller answers: the SDK refreshes its endpoint set from the controller's own peer list, and it
prefers the peers that controller reports as online. Round 0 left both stated in `instruction.md`
with no assertion, wrote the gap into Comments for Reviewer, and shipped.

The review gate returned `Status: REMOVE`, `Reason: coverage_gap`, and the driving judge said it in
one sentence:

> no selected test performs a successful login or edge-router fetch/list-controller refresh, so the
> explicit peer-learning requirement and the online-state preference/carrying behavior are
> essentially unverified; a partial implementation that only fails over among statically configured
> controllers and never learns peers would still pass.

Two separate mistakes, and the second is the one worth a note.

**First**, disclosing a coverage gap does not close it. That is [[LEDGER]] L18 again: the panel
scores the instruction, the tests, the oracle and the task directory, and Comments for Reviewer is
not among them. A gap you can describe is a gap you can grade or a gap you should stop promising.

**Second, and the real error: `network_mode = "no-network"` restricts egress, not sockets.** A test
can bind a listener on `127.0.0.1`, drive the real client code against it and shut it down again,
entirely inside the verifier container. redisshake 1005 had already used this to close its own
coverage finding; the reasoning simply was not carried across to a different language.

## The shape that works

Bind on port 0, read the assigned port back, and hand the code under test the resulting URL, so
nothing is hardcoded and two cases can never collide:

```cpp
uv_tcp_init(loop, &srv.server);
struct sockaddr_in addr{}; uv_ip4_addr("127.0.0.1", 0, &addr);
uv_tcp_bind(&srv.server, (const struct sockaddr *) &addr, 0);
uv_listen((uv_stream_t *) &srv.server, 16, on_connection);
struct sockaddr_in bound{}; int len = sizeof(bound);
uv_tcp_getsockname(&srv.server, (struct sockaddr *) &bound, &len);
srv.url = "http://127.0.0.1:" + std::to_string(ntohs(bound.sin_port));
uv_unref((uv_handle_t *) &srv.server);   // or uv_run never returns
```

Four mechanics decide whether it works:

- **`uv_unref` the listener**, or the event loop stays alive forever and the case hangs until the
  verifier timeout. Same for any timer the fixture owns.
- **Run the server on the same loop as the code under test.** No second thread, no synchronisation,
  and the whole exchange is deterministic.
- **Close each accepted connection after its response** and answer with `Connection: close` and a
  real `Content-Length`, so the client sees a clean end of body.
- **Wait for the whole request before replying** when the client sends a body. Parse
  `Content-Length` out of the headers and hold off until that many bytes have arrived.

## Make the fixture refuse, not just answer

The strongest thing the fake server buys you is the ability to be *unhelpful* in exactly the way the
real thing is. This bundle's controller returns 401 to `/controllers` when the caller presents no
session header. That one behaviour turned an untestable ordering requirement into a graded one: the
oracle used to ask for peers at the moment the login request went out, and against a server that
checks the header, the peer list simply never loads.

A fixture that answers everything grades that the code can parse. A fixture that answers the way the
real service answers grades that the code is correct.

## Cost, measured

Under 300 lines of C++ in the same test file, no new source file, no build-system change (which
mattered here, see [[cmake-reconfigure-needs-network]]). It bought five graded cases covering four
requirements that had no assertion at all, and the graded suite then caught 12 of 12 hostile
removals. Nine consecutive verifier runs came back 1.0, so the sockets did not make it flaky.

## The rule

Before writing "this cannot be graded without a live X" into an answer, ask whether an X can be
stood up **inside the test process**. HTTP, TCP, a Unix socket, a subprocess and a temp directory
are all available in an airgapped container. What is not available is reaching something outside it.

And when the honest answer really is that a requirement cannot be graded, the choice is to stop
stating it, not to state it and note the gap. A stated requirement with no enforcing assertion is
exactly what the coverage axis is looking for.

See also [[quality-check-criteria]], [[probe-the-instruction-you-already-wrote]],
[[cmake-reconfigure-needs-network]], [[oracle-bug-vs-pr-scope]].
