FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Harbor/Terminus runtime tools required to record terminal sessions.
# Installed early so the layer is cached across rebuilds.
RUN apt-get update && apt-get install -y --no-install-recommends \
    tmux asciinema \
    && rm -rf /var/lib/apt/lists/* \
    && command -v tmux && command -v asciinema

RUN apt-get update && apt-get install -y --no-install-recommends build-essential cmake meson ninja-build pkg-config git ca-certificates curl wget autoconf automake libtool libboost-all-dev libssl-dev zlib1g-dev libcurl4-openssl-dev libgtest-dev libgmock-dev libfmt-dev nlohmann-json3-dev libspdlog-dev libprotobuf-dev protobuf-compiler libzstd-dev liblz4-dev libsnappy-dev libbz2-dev libreadline-dev libncurses-dev libicu-dev python3 && rm -rf /var/lib/apt/lists/*

# Verifier dependencies: the times(2) contract is checked with a pytest suite
# that also emits a Cobertura coverage report. Installed at build time so the
# test container needs no network (allow_internet=false).
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pytest python3-pytest-cov python3-coverage \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -c "import pytest, pytest_cov, coverage"
WORKDIR /app
COPY repo/ .
CMD ["sh", "-c", "make test"]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
