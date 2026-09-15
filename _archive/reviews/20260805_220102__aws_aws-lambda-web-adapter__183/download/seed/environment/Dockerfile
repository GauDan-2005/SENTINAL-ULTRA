FROM rust:1.79
RUN apt-get update && apt-get install -y --no-install-recommends git tmux asciinema && rm -rf /var/lib/apt/lists/*
RUN command -v tmux && command -v asciinema
# Tests mutate process-wide env vars and rely on per-test process isolation
# (upstream CI uses cargo-nextest). Under plain `cargo test` they share one
# process, so force single-threaded execution to keep them isolated.
ENV RUST_TEST_THREADS=1
WORKDIR /app
COPY repo/ .
RUN n=0; until cargo fetch; do n=$((n+1)); if [ $n -ge 3 ]; then exit 1; fi; echo "dependency install failed (attempt $n/3), retrying…" >&2; sleep $((n*15)); done
# The HTTPS solution pulls in hyper-rustls (lib) and aws-sigv4 (dev/e2e). These
# are NOT in the init-state Cargo.toml/Cargo.lock, so pre-fetch them (and their
# transitive crates) into the cargo cache now — the eval container has no network,
# so the solved code and all its test targets must build fully offline. Restore
# the pristine manifests afterward so the agent still sees the unsolved init state.
# Coverage tooling for the oracle coverage report (Cobertura XML). Installed at
# build time only; never invoked with network access at eval time.
RUN rustup component add llvm-tools-preview \
 && cargo install cargo-llvm-cov --version 0.5.31 --locked
RUN cp Cargo.toml /tmp/Cargo.toml.orig && cp Cargo.lock /tmp/Cargo.lock.orig \
 && sed -i '/^hyper = { version = "0.14"/a hyper-rustls = "0.23.2"' Cargo.toml \
 && sed -i '/^\[dev-dependencies\]/a aws-sigv4 = "0.54"' Cargo.toml \
 && (n=0; until cargo fetch; do n=$((n+1)); if [ $n -ge 3 ]; then exit 1; fi; sleep $((n*15)); done) \
 && cargo build --lib --bins \
 && cargo llvm-cov --no-report --lib \
 && cp /tmp/Cargo.toml.orig Cargo.toml && cp /tmp/Cargo.lock.orig Cargo.lock
CMD ["sh", "-c", "cargo test"]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
