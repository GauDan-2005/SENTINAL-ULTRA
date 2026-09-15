FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# ---- Harbor/Terminus runtime tools (installed early so they are cached) ----
RUN apt-get update && apt-get install -y --no-install-recommends \
        tmux asciinema \
    && rm -rf /var/lib/apt/lists/* \
    && command -v tmux && command -v asciinema

# ---- Build toolchain & system libs ----
# libssl-dev and libsodium-dev provide openssl and libsodium directly (vcpkg
# skips both via the overlay stubs below). The rest is what vcpkg needs to
# bootstrap and build its ports (compiler, cmake, ninja, python3, autotools, and
# zip/unzip/tar/curl for downloads & the binary cache).
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        git \
        ca-certificates \
        curl \
        zip \
        unzip \
        tar \
        autoconf \
        autoconf-archive \
        automake \
        libtool \
        python3 \
        libssl-dev \
        libsodium-dev \
        zlib1g-dev \
        expect \
        golang-go \
        gcovr \
    && rm -rf /var/lib/apt/lists/*

# ---- vcpkg (pinned to the builtin-baseline referenced by vcpkg.json) ----
ENV VCPKG_ROOT=/opt/vcpkg
ENV VCPKG_FORCE_SYSTEM_BINARIES=1
RUN git clone https://github.com/microsoft/vcpkg.git ${VCPKG_ROOT} \
    && git -C ${VCPKG_ROOT} checkout cd61e1e26a038e82d6550a3ebbe0fbbfe7da78e3 \
    && ${VCPKG_ROOT}/bootstrap-vcpkg.sh -disableMetrics
ENV PATH="${VCPKG_ROOT}:${PATH}"

WORKDIR /app
COPY repo/ .

# ---- The upstream repo tracks .idea/ at the base commit, so it cannot be deleted
#      from the shipped tree. environment/.dockerignore keeps it out of the build
#      context; this removal is the belt to that braces, and it also covers the
#      other editor directories should the repo ever grow one. Side effect: the
#      paths stay listed in the shipped .git, so `git status` inside the container
#      reports them deleted. ----
RUN rm -rf .idea .vscode .DS_Store

# ---- vcpkg overlay ports: at this base commit the pinned baseline still ships
#      libsodium 1.0.18, whose GitHub source archive hash has since changed, so
#      vcpkg's download fails. Stub out libsodium and openssl with empty ports so
#      vcpkg skips building them; the SDK picks them up from the system libraries
#      (libsodium-dev via pkg-config, libssl-dev via find_package(OpenSSL)), which
#      are installed above. This mirrors the openssl overlay upstream ships. ----
RUN for pkg in libsodium openssl; do \
        mkdir -p /opt/vcpkg-overlays/linux/$pkg; \
        printf 'set(VCPKG_POLICY_EMPTY_PACKAGE enabled)\n' > /opt/vcpkg-overlays/linux/$pkg/portfile.cmake; \
        printf '{ "name": "%s", "version": "0" }\n' "$pkg" > /opt/vcpkg-overlays/linux/$pkg/vcpkg.json; \
    done

# ---- Configure with a single-config Ninja generator + developer mode so the
#      tests are built, and let vcpkg install every dependency (including the
#      test dep catch2 via the "test" manifest feature, matching CMakePresets).
#      Single-config keeps `ctest --test-dir build` working without -C.
#      `expect` and `golang-go` are installed above so the tests/integ subdir is
#      *configured* (it early-returns when expect is missing and REQUIREs go),
#      making the `integ-tests` target available to build later at test time.
#      `--coverage` is baked into the compile/link flags so the oracle coverage
#      report (gcovr -> Cobertura XML) can be produced offline.
#      Doing all of this at build time means the test container runs fully offline. ----
RUN cmake -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Debug \
        -Dziti_DEVELOPER_MODE=ON \
        -DVCPKG_MANIFEST_FEATURES="test;samples" \
        -DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake \
        -DVCPKG_OVERLAY_PORTS=/opt/vcpkg-overlays/linux \
        -DCMAKE_C_FLAGS="--coverage -O0 -g" \
        -DCMAKE_CXX_FLAGS="--coverage -O0 -g" \
        -DCMAKE_EXE_LINKER_FLAGS="--coverage" \
        -DCMAKE_SHARED_LINKER_FLAGS="--coverage" \
        > /tmp/cmake_configure.log 2>&1 \
    || (tail -n 120 /tmp/cmake_configure.log; false)

# ---- Build the library and the unit-test executables at image build time so
#      vcpkg has fetched/compiled every dependency while the network is still
#      available. We deliberately do NOT build the `integ-tests` target here:
#      the eval tests arrive at verify time in tests/tests.patch and only compile
#      against the solved controller API, so building that target now would bake a
#      binary the verifier has to replace anyway. We also skip the `ziti-cli`
#      custom target, which would `go install` over the network. Those are built
#      offline at test time from tests/config.json. ----
RUN cmake --build build --target ziti all_tests zitilib-tests > /tmp/cmake_build.log 2>&1 \
    || (tail -n 120 /tmp/cmake_build.log; false)

# ---- Vendor the ziti CLI that tests/integ/CMakeLists.txt declares. That target is
#      `add_custom_target(ziti-cli ALL ...)`, and a CMake custom target is always out
#      of date, so a plain `cmake --build build` shells out to `go install` on every
#      invocation. The verifier escapes it by naming its targets; an agent typing the
#      obvious build command does not, and the agent reaches only the model gateway,
#      so it meets a DNS failure that has nothing to do with the task. Warm the module
#      cache here, where the network is available, then resolve from that cache at run
#      time. `go install pkg@version` consults the proxy for the version before it
#      looks in the cache, so GOPROXY=off is what makes the cached copy reachable. ----
RUN go install github.com/openziti/ziti/ziti@v1.1.3
ENV GOPROXY=off

CMD ["sh", "-c", "cmake --build build && ctest --test-dir build --output-on-failure"]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
