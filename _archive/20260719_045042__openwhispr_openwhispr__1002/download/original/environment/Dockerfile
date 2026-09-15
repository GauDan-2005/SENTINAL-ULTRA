FROM node:24-slim

# Runtime tools required by the Harbor/Terminus harness for session recording,
# plus build tooling needed to compile native npm modules (better-sqlite3, etc.).
RUN apt-get update && apt-get install -y --no-install-recommends \
      tmux \
      asciinema \
      git \
      python3 \
      make \
      g++ \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && command -v tmux && command -v asciinema

WORKDIR /app

# Avoid downloading the large Electron binary and skip electron-builder's
# app-deps rebuild during install; the test suite only needs better-sqlite3
# and ws, which npm ci compiles/installs from the lockfile.
ENV ELECTRON_SKIP_BINARY_DOWNLOAD=1 \
    npm_config_electron_skip_binary_download=1 \
    ELECTRON_OVERRIDE_DIST_PATH=/app/node_modules/electron/dist

COPY repo/ .

# Install all dependencies at build time so tests can run fully offline.
# Ignore lifecycle scripts (postinstall runs electron-builder which is not
# needed for the test suite and would require Electron/network).
RUN npm ci --ignore-scripts

# Native modules that npm ci skipped rebuilding due to --ignore-scripts:
# rebuild only the one the tests need so it works offline at test time.
RUN npm rebuild better-sqlite3

# Coverage tooling for the offline test runner (emits Cobertura XML). Installed
# at build time so no network is required when tests execute.
RUN npm install -g c8@10.1.3

CMD ["sh", "-c", "npm test"]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
