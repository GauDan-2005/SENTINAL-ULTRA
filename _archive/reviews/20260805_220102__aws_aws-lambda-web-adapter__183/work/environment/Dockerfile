FROM rust:1.79
RUN apt-get update && apt-get install -y --no-install-recommends git tmux asciinema patch && rm -rf /var/lib/apt/lists/*
# Harbor drives the session through tmux and records it with asciinema; test.sh
# falls back to patch(1) when git apply cannot be used. A missing binary here
# fails the run long after the build, so verify loudly and unguarded.
RUN command -v tmux && command -v asciinema && command -v patch && command -v python3
# The integration tests mutate process-wide environment variables. The verifier
# runs each test binary with --test-threads=1; this default keeps a bare
# `cargo test` honest for anyone running the suite by hand.
ENV RUST_TEST_THREADS=1
WORKDIR /app
COPY repo/ .
RUN n=0; until cargo fetch; do n=$((n+1)); if [ $n -ge 3 ]; then exit 1; fi; echo "dependency fetch failed (attempt $n/3), retrying" >&2; sleep $((n*15)); done
# The verifier runs airgapped, so every crate the solved code can need must already
# sit in the cargo registry cache. A TLS-to-upstream solution can be built on more
# than one stack, so warm the cache with a MENU of TLS-capable client crates spanning
# both families — rustls (hyper-rustls / tokio-rustls) and native-tls — against a
# temporarily amended Cargo.toml, then restore the pristine manifests. No single
# crate or exact version is spotlighted: the cache is a menu, not an answer key (the
# k=8 solve runs confirmed the graded suite is mechanism-agnostic — agents solved with
# both native-tls and rustls). native-tls is already a transitive base dependency via
# hyper-tls, so its half of the menu is present regardless.
# Deliberately fetch-only: compiling against the amended manifest would leave
# fingerprints and .d files under target/ naming the crates, and target/ lives in the
# agent's own workspace. target/ is wiped and rebuilt from the PRISTINE manifest, so
# the warm cache covers the base dependency graph only. The final line is a hard,
# unguarded assertion that nothing under target/ names a solution TLS crate.
RUN cp Cargo.toml /tmp/Cargo.toml.orig && cp Cargo.lock /tmp/Cargo.lock.orig \
 && sed -i '/^hyper = { version = "0.14"/a hyper-rustls = "0.23"\ntokio-rustls = "0.23"\nnative-tls = "0.2"' Cargo.toml \
 && grep -q '^hyper-rustls' Cargo.toml && grep -q '^native-tls' Cargo.toml \
 && (n=0; until cargo fetch; do n=$((n+1)); if [ $n -ge 3 ]; then exit 1; fi; sleep $((n*15)); done) \
 && cp /tmp/Cargo.toml.orig Cargo.toml && cp /tmp/Cargo.lock.orig Cargo.lock \
 && rm -rf target \
 && cargo build --tests \
 && ! grep -rql 'hyper.rustls\|rustls.native.certs' target 2>/dev/null
# A warm cache is worth nothing unless a TLS-capable manifest can actually be
# RESOLVED from it with the network gone — which is the state the verifier runs in.
# The two are not the same check: the fetch above resolves against crates.io on
# build day, and a build day that lands after a new release of any transitive crate
# leaves the cache holding versions nobody asked for. So prove it, on a throwaway
# copy of the workspace outside /app (nothing here reaches the agent's workspace,
# and the copy is gone in this same layer).
# The copy carries Cargo.lock, and the probe is `fetch --offline` rather than
# `generate-lockfile`: that is exactly what a solved tree does at verify time —
# keep every pin the lock already has, resolve only what the new dependencies add,
# and require all of it to be on disk. Resolving from scratch instead would demand
# registry index entries for crates cargo never had to query, and would fail on a
# cache that serves the real build perfectly well.
# Unguarded on purpose: a failure here is a broken image, and it should read as one
# at build time rather than as an unexplained oracle failure two stages downstream.
RUN mkdir -p /tmp/resolve-probe/ \
 && cp /app/Cargo.toml /app/Cargo.lock /tmp/resolve-probe/ && cp -a /app/src /app/tests /tmp/resolve-probe/ \
 && cd /tmp/resolve-probe \
 && sed -i '/^hyper = { version = "0.14"/a hyper-rustls = "0.23"\ntokio-rustls = "0.23"\nnative-tls = "0.2"' Cargo.toml \
 && CARGO_NET_OFFLINE=true cargo fetch --offline \
 && cd / && rm -rf /tmp/resolve-probe
# Carried through from the authored image unchanged: neither is attributable to
# this task, and Harbor may rely on them.
RUN mkdir -p /installed-agent
CMD ["sh", "-c", "cargo test"]
