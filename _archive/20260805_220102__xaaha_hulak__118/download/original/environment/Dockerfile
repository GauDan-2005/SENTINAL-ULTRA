FROM golang:1.25

# Ensure Go's bin directory is on PATH explicitly, so that any shell environment
# (including minimal envs used by the verifier) can find the go binary.
ENV PATH="/usr/local/go/bin:${PATH}"

# Harbor/Terminus runtime tools for terminal recording, plus git for module fetches.
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        tmux \
        asciinema \
    && rm -rf /var/lib/apt/lists/* \
    && command -v tmux && command -v asciinema

WORKDIR /app
COPY repo/ .

# Warm the module cache at build time so `go test` runs offline.
RUN n=0; until go mod download; do n=$((n+1)); if [ $n -ge 3 ]; then exit 1; fi; echo "dependency install failed (attempt $n/3), retrying…" >&2; sleep $((n*15)); done

# The reference solution introduces github.com/lrstanley/bubblezone, which pulls
# github.com/charmbracelet/x/cellbuf up to the v0.0.13 release (the base repo pins a
# v0.0.13 prerelease). Warm both into the module cache so the offline test run can
# compile against the reference solution's module graph.
RUN n=0; until go mod download github.com/lrstanley/bubblezone@v1.0.0 github.com/charmbracelet/x/cellbuf@v0.0.13; do n=$((n+1)); if [ $n -ge 3 ]; then exit 1; fi; echo "module warm-up failed (attempt $n/3), retrying…" >&2; sleep $((n*15)); done

# Install a Cobertura converter so the offline test run can emit coverage.xml.
# gocover-cobertura v1.3.0 pins golang.org/x/tools v0.8.0, whose internal/tokeninternal
# no longer compiles under Go 1.25, so build the tool against a current x/tools.
# This step is best-effort: if the network is unavailable the build continues.
RUN ( git clone --depth 1 --branch v1.3.0 https://github.com/boumenot/gocover-cobertura /tmp/gocover-cobertura \
    && cd /tmp/gocover-cobertura \
    && rm -rf vendor \
    && go get golang.org/x/tools@latest \
    && go build -o /usr/local/bin/gocover-cobertura . \
    && cd /app \
    && rm -rf /tmp/gocover-cobertura ) || true

# Pre-build test binaries to fully warm the build cache for offline test runs.
RUN go test -count=1 -run '^$' ./... >/dev/null 2>&1 || true

CMD ["sh", "-c", "go test ./..."]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
