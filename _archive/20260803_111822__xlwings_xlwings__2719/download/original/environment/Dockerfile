FROM python:3.12-slim

RUN command -v git >/dev/null 2>&1 || (apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*)

WORKDIR /app
COPY repo/ .

# Test dependencies are baked into the image at build time (no network at test time).
# These pure-Python tests exercise the async/lazy book-load logic in the remote
# backend and don't require the compiled Rust extension (its import is guarded).
RUN pip install --no-cache-dir pytest anyio pytest-cov

# xlwings PRO modules validate a license on import; "noncommercial" is the
# built-in bypass, so make it the default for the test environment.
ENV XLWINGS_LICENSE_KEY=noncommercial

RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
RUN (command -v tmux >/dev/null 2>&1 && command -v asciinema >/dev/null 2>&1) || ( (apt-get update && apt-get install -y --no-install-recommends tmux asciinema && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache tmux asciinema 2>/dev/null || dnf install -y tmux asciinema 2>/dev/null || yum install -y tmux asciinema 2>/dev/null || true )
