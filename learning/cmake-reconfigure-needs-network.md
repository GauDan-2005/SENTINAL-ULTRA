---
id: cmake-reconfigure-needs-network
status: locally-verified
last_verified: 2026-08-09
verified_by:
  - 20260808_213817__openziti_ziti-sdk-c__668
evidence: "Adding one source file to tests/integ/CMakeLists.txt made ninja re-run the CMake configure inside the airgapped verifier, and FetchContent tried to git-update a dependency pinned to a branch. Build died with `ninja: error: rebuilding 'build.ninja': subcommand failed`"
applies_to:
  languages: [c, cpp]
  runners: [cmake, ninja, make]
  phases: [packaging, difficulty, oracle]
blocks_submission: true
fails_gate: [oracle, difficulty]
supersedes: []
contradicts: []
---

# On a CMake bundle, editing any CMakeLists at verify time can pull the build back onto the network

## What happened

ziti-sdk-c 668 is a CMake plus Ninja plus vcpkg bundle. The image runs the configure at build time,
when the network is available, and the verifier only runs `cmake --build build --target <t>`, which
is offline. That works right up to the moment something touches a `CMakeLists.txt`.

Section 10.3 says to give the graded tests their own file with a verifier-only prefix. Doing that on
a CMake project means adding the file to a target, which means editing `tests/integ/CMakeLists.txt`,
which `tests.patch` applies at verify time. Ninja tracks every `CMakeLists.txt` as an input to
`build.ninja`, so the next build re-runs the configure. The configure re-enters
`deps/CMakeLists.txt`, which carries

```cmake
FetchContent_Declare(subcommand
        GIT_REPOSITORY https://github.com/openziti/subcommands.c.git
        GIT_TAG main
        )
```

and `FetchContent` runs a `git update` step on an already-populated dependency whose tag is a moving
branch. With no network the step fails and the whole build stops:

```
CMake Error at .../subcommand-populate-gitupdate.cmake:8 (execute_process):
CMake Error at /usr/share/cmake-3.28/Modules/FetchContent.cmake:1679 (message):
ninja: error: rebuilding 'build.ninja': subcommand failed
```

No graded test ran, and the failure looks nothing like a missing dependency. It looks like the
verifier is broken.

## The check, before you design the tests

Two lines, run in the built image, and they cost nothing:

```bash
# does anything reach the network during configure?
grep -rnE 'FetchContent_Declare|ExternalProject_Add|GIT_REPOSITORY|GIT_TAG' \
     $(git -C environment/repo ls-files '*CMakeLists.txt' 'cmake/*')
# does a CMakeLists touch actually re-run the configure?
docker run --rm --network=none <image> bash -lc \
  'cd /app && touch tests/CMakeLists.txt && cmake --build build --target <graded target>'
```

If the second command fails, `tests.patch` must not touch any `CMakeLists.txt`, and neither may the
restore step.

## What to do about it

**Put the graded cases in a source file the target already compiles.** On this task they went at the
end of `tests/integ/legacy-auth.cpp`, which `tests.patch` already edits for the source PR's own call
site updates. Section 10.3's separate-file practice is a practice and this is when it loses. The
collision surface it exists to remove is closed the other two ways instead:

- give every graded case a `sentinel_` name prefix, so an agent writing its own test with the
  obvious name cannot collide
- restore the whole test tree before applying `tests.patch`, which is required here anyway

**Do not fix it in the Dockerfile.** A second configure pass with `-DFETCHCONTENT_FULLY_DISCONNECTED=ON`
would work, and it is not on the allowed-fix table in `docs/guidelines.md`. The moving `GIT_TAG main`
is tracked source and cannot be edited either. Report both in Comments for Reviewer with the measured
error text.

## The wider rule

A build system that is only offline-safe *by accident of what you did not touch* is a trap with your
name on it, and the tell is generic. Ask what re-runs the expensive, network-facing phase of the
build, then check whether anything the verifier does can trigger it. On CMake that is any
`CMakeLists.txt` or toolchain-file change. On Gradle it is a `build.gradle` change against a
non-offline dependency cache. On Cargo it is a `Cargo.toml` change without a vendored registry.

The same bundle carries a second instance worth naming. `tests/integ/CMakeLists.txt` declares

```cmake
add_custom_target(ziti-cli ALL
        COMMAND ... ${GOLANG_EXE} install github.com/openziti/ziti/ziti@${ZITI_CLI_VER})
```

`ALL` puts it in the default target, and a CMake custom target is always out of date, so a plain
`cmake --build build` tries to `go install` over the network every time. The verifier never sees it
because it names its targets, but the **agent** does, and the agent's allowlist is the model gateway
only. An agent that runs the obvious build command meets a network failure that has nothing to do
with the task. That is difficulty coming from confusion, which `sentinel-difficulty-scope` calls out
as the wrong kind of hard, and on a task arriving at `pass_at_k` 0/3 it is worth naming to the
reviewer.

See also [[tests-patch-vs-agent-edits]], [[verify-in-the-image]], [[empty-git-refs]].
