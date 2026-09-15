FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends build-essential cmake meson ninja-build pkg-config git ca-certificates curl wget autoconf automake libtool libboost-all-dev libssl-dev zlib1g-dev libcurl4-openssl-dev libgtest-dev libgmock-dev libcmocka-dev libfmt-dev nlohmann-json3-dev libspdlog-dev libprotobuf-dev protobuf-compiler libzstd-dev liblz4-dev libsnappy-dev libbz2-dev libreadline-dev libncurses-dev libicu-dev && rm -rf /var/lib/apt/lists/*
# The mem-alloc unit tests are written against cmocka 2.0 (namespaced cmocka::cmocka
# target, self-contained header). Build it here while the network is available so the
# airgapped verifier can link against it; fall back to the packaged libcmocka-dev if
# the source build is unavailable.
RUN set -eux; \
    ( curl -fsSL https://git.cryptomilk.org/projects/cmocka.git/snapshot/cmocka-2.0.1.tar.gz -o /tmp/cmocka.tar.gz \
      && tar -xzf /tmp/cmocka.tar.gz -C /tmp \
      && cmake -S /tmp/cmocka-2.0.1 -B /tmp/cmocka-2.0.1/build -DCMAKE_BUILD_TYPE=Release -DWITH_EXAMPLES=OFF -DUNIT_TESTING=OFF \
      && cmake --build /tmp/cmocka-2.0.1/build -j"$(nproc)" \
      && cmake --install /tmp/cmocka-2.0.1/build \
      && ldconfig ) \
    || echo "cmocka 2.0.1 source build unavailable; using system libcmocka-dev"; \
    rm -rf /tmp/cmocka*

WORKDIR /app
COPY repo/ .
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release 2>&1 | tee /tmp/cmake_configure.log
CMD ["sh", "-c", "cmake --build build && ctest --test-dir build --output-on-failure"]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
RUN (command -v tmux >/dev/null 2>&1 && command -v asciinema >/dev/null 2>&1) || ( (apt-get update && apt-get install -y --no-install-recommends tmux asciinema && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache tmux asciinema 2>/dev/null || dnf install -y tmux asciinema 2>/dev/null || yum install -y tmux asciinema 2>/dev/null || true )
