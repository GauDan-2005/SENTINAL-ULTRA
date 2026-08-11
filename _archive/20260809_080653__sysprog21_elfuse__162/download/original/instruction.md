Guests running under elfuse can't call `times(2)`. The syscall was never wired into the emulator, so every guest invocation falls through to the `-ENOSYS` path. That breaks shell timing builtins and any build tool that polls `times()` for elapsed/CPU tick accounting — they either error out or get garbage back. We need a real `times(2)` implementation so guests get correct CPU accounting plus an elapsed tick count.

`times(2)` is aarch64 syscall number 153. Right now `src/syscall/abi.h` has no `SYS_times` define and `src/syscall/dispatch.tbl` has no entry, so the dispatcher never routes it. Wire it up end to end: add `SYS_times` = 153 to `src/syscall/abi.h`, add the `SYS_times sc_times 0` row to `src/syscall/dispatch.tbl` (E=0, only x0 is consumed — the single `struct tms *` buffer pointer), and add the `sc_times` dispatch wrapper in `src/syscall/syscall.c` that forwards to `sys_times(g, x0)`. The dispatch header is generated from those files by `scripts/gen-syscall-dispatch.py`, and it only succeeds when `abi.h`, `dispatch.tbl`, and `syscall.c` all agree — so a solved build produces a live `_(SYS_times, sc_times, 0)` entry. Declare `sys_times` in `src/syscall/time.h` and implement it in `src/syscall/time.c`.

What `sys_times` has to do:

1. Return value is an elapsed tick count. Linux hands back jiffies-since-boot; POSIX only requires an arbitrary-but-fixed reference point that successive calls can difference. Use the host `CLOCK_MONOTONIC` converted to ticks. The tick rate is USER_HZ = 100, i.e. `_SC_CLK_TCK` must read as 100 for guests — this has to match the `AT_CLKTCK` auxv value that `core/stack.c` already advertises, because libc divides these raw tick counts by `sysconf(_SC_CLK_TCK)`; any mismatch silently rescales every value.

2. Fill the four `struct tms` fields (each a 64-bit clock_t tick count in this order: `tms_utime`, `tms_stime`, `tms_cutime`, `tms_cstime`). Self time — `tms_utime` and `tms_stime` — comes from `getrusage(RUSAGE_SELF)` (`ru_utime` / `ru_stime`), converted to 100 Hz ticks.

3. Child time — `tms_cutime` / `tms_cstime` — must come from a proc-layer accumulator of reaped guest children's CPU, NOT from `getrusage(RUSAGE_CHILDREN)`. The emulator also forks helper subprocesses (rosettad translate, sysroot tooling) whose CPU shows up in the host's `RUSAGE_CHILDREN` aggregate; counting those would masquerade as guest child time. So maintain your own counters that are fed only at reaps of proc-table children. Add `proc_children_cpu_add(const struct rusage *ru)` and `proc_children_cpu_us(uint64_t *utime_us, uint64_t *stime_us)` in `src/syscall/proc.c` (declared in `src/syscall/proc.h`), and have `sys_times` read the accumulated microseconds via `proc_children_cpu_us` and convert to ticks.

4. Feed that accumulator at every host reap site for a guest child — the `sys_wait4` path and the proc-table reaper (`proc_reap_finished`). Those reaps need to grab rusage, so switch the reaping calls from `waitpid(...)` to `wait4(..., &ru)` and call `proc_children_cpu_add(&ru)` on success. Crucially, credit CPU only once, on a terminal report: guard the `sys_wait4` crediting on `WIFEXITED(status) || WIFSIGNALED(status)`. `mac_options` may carry `WUNTRACED`/`WCONTINUED`, and a stop/continue report — or a `waitid(WNOWAIT)` peek — is a snapshot of a still-running child; crediting there would double- or triple-count the same child across its stop, continue, and final-exit reports. A `WNOWAIT` peek in particular must not move `tms_cutime` at all.

5. A NULL buffer is valid, same as on Linux — accept `buf_gva == 0` and return only the tick count, skipping the struct write. Guard the write on a non-NULL `buf_gva`.

6. A bad user pointer must yield `-EFAULT` (Linux errno 14) rather than a partial write — if the guest buffer write fails, return `-EFAULT`.

Register the guest test `test-times` in `tests/manifest.txt` (it sits between `test-sysinfo` and `test-io-opt`).

Concretely, once done: `sysconf(_SC_CLK_TCK)` reads 100; `times(&buf)` succeeds; `times(NULL)` returns a non-negative tick count; the return value strictly advances across a 60ms sleep; `tms_utime + tms_stime` grows after ~100ms of CPU burn; a waited-for child that burns ~100ms of CPU grows `tms_cutime + tms_cstime`; a child doing real syscalls grows `tms_cstime` on its own (not just `tms_cutime`); a `waitid(WNOWAIT)` peek leaves `tms_cutime` unchanged; and `times(bad_ptr)` returns `-EFAULT`.

Do not modify the test files.
