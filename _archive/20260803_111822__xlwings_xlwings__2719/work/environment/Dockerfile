FROM python:3.12-slim

RUN command -v git >/dev/null 2>&1 || (apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*)

WORKDIR /app
COPY repo/ .

# .vscode/ is tracked upstream at the base commit, so it cannot be deleted from
# environment/repo without editing tracked source. Drop it from the image instead,
# so no editor cruft reaches the container the agent works in. A plain rm is used
# deliberately: an earlier version also ran "git update-index --skip-worktree" here
# to keep the agent's checkout reporting clean, and git exits 128 with "detected
# dubious ownership" whenever the build uid does not own /app, which fails the
# whole build. Nothing in the image may depend on the uid the builder happens to use.
RUN rm -rf /app/.vscode

# Test dependencies are baked into the image at build time (no network at test time)
# and pinned to the versions this bundle was verified against, so the difficulty run
# and the oracle run cannot get different toolchains. The reward parser depends on
# pytest's -v per-test line format and the graded async tests depend on the anyio
# pytest plugin, so both are version-sensitive.
# These pure-Python tests exercise the async/lazy book-load logic in the remote
# backend and don't require the compiled Rust extension (its import is guarded).
RUN pip install --no-cache-dir pytest==9.1.1 anyio==4.14.2

# xlwings PRO modules validate a license on import; "noncommercial" is the
# built-in bypass, so make it the default for the test environment.
ENV XLWINGS_LICENSE_KEY=noncommercial

RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
RUN (command -v tmux >/dev/null 2>&1 && command -v asciinema >/dev/null 2>&1) || ( (apt-get update && apt-get install -y --no-install-recommends tmux asciinema && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache tmux asciinema 2>/dev/null || dnf install -y tmux asciinema 2>/dev/null || yum install -y tmux asciinema 2>/dev/null || true )
