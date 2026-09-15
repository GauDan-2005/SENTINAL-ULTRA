FROM rust:1.88
# Harbor/Terminus runtime tools for terminal session recording, plus git for any git-based deps.
RUN apt-get update && apt-get install -y --no-install-recommends tmux asciinema git unzip curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && command -v tmux && command -v asciinema

# The proto files use `edition = "2023"`, which requires protoc >= 27.
# Debian's packaged protobuf-compiler (3.21.x) is too old, so install a modern
# release from the official GitHub releases (linux/amd64) at build time.
ARG PROTOC_VERSION=29.3
RUN curl -fsSL -o /tmp/protoc.zip \
      "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip" \
    && unzip -q /tmp/protoc.zip -d /usr/local \
    && rm /tmp/protoc.zip \
    && chmod +x /usr/local/bin/protoc \
    && command -v protoc && protoc --version
# Coverage tooling for the oracle-coverage report (Cobertura XML). Installed at
# build time so no network is needed at test time. Best-effort: test.sh falls
# back to plain `cargo test` if this is unavailable.
RUN rustup component add llvm-tools-preview \
    && cargo install cargo-llvm-cov --locked || true

WORKDIR /app
COPY repo/ .
RUN n=0; until cargo fetch; do n=$((n+1)); if [ $n -ge 3 ]; then exit 1; fi; echo "dependency install failed (attempt $n/3), retrying…" >&2; sleep $((n*15)); done
CMD ["sh", "-c", "cargo test"]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
