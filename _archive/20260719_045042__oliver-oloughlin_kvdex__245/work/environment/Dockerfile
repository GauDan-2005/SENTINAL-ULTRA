# Deno project (kvdex). Use the official Debian-based Deno image so the sandbox
# has full GNU coreutils, tar and gzip available (required by Daytona to archive
# the verifier directory). The Alpine/busybox base was the cause of the
# "sandbox images must provide tar and gzip" Daytona build failure.
FROM denoland/deno:debian-2.4.0

# Harbor/Terminus runtime tools + GNU tar/gzip. Installed early so the layer is
# cached across rebuilds. Verify both harness tools are on PATH.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        tmux \
        asciinema \
        tar \
        gzip \
        git \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && command -v tmux && command -v asciinema && command -v tar && command -v gzip

WORKDIR /app

# Cache Deno dependencies at build time so tests run fully offline.
ENV DENO_DIR=/deno-dir

# Copy manifest/lock first for better layer caching of the dependency download.
COPY repo/deno.json repo/deno.lock ./

# Bring in the full source so cache resolution sees every module/import.
COPY repo/ .

# Warm the module cache for the app entrypoint, all test modules and benchmarks.
# This downloads every jsr:/npm:/https: dependency during `docker build` so the
# offline test run needs no network.
RUN deno cache mod.ts \
    && find tests benchmarks src -name '*.ts' -print0 | xargs -0 deno cache

# The task solution migrates serialization into src/ext/encoding and bumps a
# handful of dependencies in deno.json/deno.lock (newer @std/* releases,
# @deno/kv 0.8.4). Those versions aren't referenced by the base repo, so warm
# them into the module cache now while the build still has network — otherwise
# the airgapped verifier can't resolve them and no tests run. Cache from /tmp
# with --no-lock so /app/deno.lock stays untouched and the solution patch still
# applies cleanly at verify time.
RUN cd /tmp && deno cache --no-lock \
        jsr:@std/assert@1.0.7 \
        jsr:@std/bytes@1.0.4 \
        jsr:@std/cli@1.0.6 \
        jsr:@std/collections@1.0.9 \
        jsr:@std/internal@1.0.5 \
        jsr:@std/ulid@1.0.0 \
        npm:@deno/kv@0.8.4 \
        npm:zod@3.23.8 \
        npm:@types/node@18.16.19

# Default: run the test suite exactly as `deno task test` does.
CMD ["deno", "test", "--allow-write", "--allow-read", "--allow-ffi", "--allow-sys", "--unstable-kv", "--trace-leaks"]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
