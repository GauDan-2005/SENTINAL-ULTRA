FROM rust:1.89
RUN apt-get update && apt-get install -y --no-install-recommends git tmux asciinema && rm -rf /var/lib/apt/lists/*
RUN command -v tmux && command -v asciinema
WORKDIR /app
# Coverage tooling (installed at build time; no network at test time)
RUN rustup component add llvm-tools-preview
RUN cargo install cargo-llvm-cov --locked
COPY repo/ .
RUN cargo fetch
# Warm the dependency and crate build cache so no network is needed at test time.
# The pqcp feature and its test target only exist once the solution is applied,
# so build the existing test targets here to prime the shared dependency graph.
RUN cargo test -p libcrux-ml-kem --no-run || true
CMD ["sh", "-c", "cargo test"]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
