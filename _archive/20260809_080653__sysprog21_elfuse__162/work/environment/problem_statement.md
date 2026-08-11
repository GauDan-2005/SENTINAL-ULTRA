Guests running under elfuse cannot call `times(2)`. The syscall was never wired into the emulator, so every guest invocation falls through to the `-ENOSYS` path. Shell timing builtins and build tools that poll `times()` for elapsed and CPU tick accounting either error out or read garbage. We need a real `times(2)` so guests get correct CPU accounting and an elapsed tick count.

On aarch64-linux `times(2)` is syscall number 153. It takes one argument, a guest pointer to a `struct tms` buffer, and returns an elapsed tick count. Route the number to a handler and make sure the dispatcher is not asked to fetch the extended argument registers for it, since there is only the one argument.

What the call has to do.

1. The return value is an elapsed tick count. Linux hands back jiffies since boot. POSIX only asks for a fixed reference point that successive calls can subtract from each other, so a host clock that only ever moves forward is enough. It must not be a clock a user can set, because that would make two calls differ by the wrong amount.

2. Ticks run at the same rate the emulator already advertises to guests as the clock tick rate, which is 100 a second. Guest libc divides these raw counts by `sysconf(_SC_CLK_TCK)`, so a rate that disagrees with what the emulator advertises silently rescales every value a guest reads.

3. The buffer holds four 64-bit tick counts, in the order `tms_utime`, `tms_stime`, `tms_cutime`, `tms_cstime`. The first two are the CPU the emulator process itself has used, split into user and system time, taken from the host's own accounting for the running process.

4. The last two are the CPU of guest child processes that the guest created and has already waited for, split into user and system time the same way. A child that spends its time in system calls has to move the system half on its own. Take care here. The emulator forks its own helper subprocesses for translation and sysroot work, and the host's aggregate children accounting includes those. Helper CPU must never show up in a guest's child totals, so the aggregate the host offers is the wrong source. Only a child the guest itself owns and reaps may contribute.

5. Each child counts once. Credit its CPU when a wait reports that the child has finished for good, whether it exited or was killed by a signal. A report that a child has stopped or continued is a snapshot of a process that is still running and will be reported again, so it must leave the child totals alone. So must a wait that only looks at a child and deliberately leaves it collectable, since the wait that finally collects it would otherwise count the same time twice.

6. A null buffer pointer is valid, the same as on Linux. Return the tick count and write nothing.

7. If the buffer cannot be written to guest memory, return `-EFAULT` rather than leaving a half-written struct behind.

Do not modify the test files.
