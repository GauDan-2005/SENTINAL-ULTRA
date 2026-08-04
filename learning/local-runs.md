# Running the local oracle and NOP checks on this machine

Source: session of 2026-07-31, task `20260719_045042__oliver-oloughlin_kvdex__245`.

## UPDATE 2026-08-04: the workspace has moved to ext4

**Everything below about ntfs3 is now history for this workspace.** The tree lives at
`/home/gaurav-s-ubuntu/Work/Work/AirDawg/SENTINAL-ULTRA` on `/dev/nvme0n1p5`, which is
**ext4** and mounted at `/`. Check before assuming either way:

```bash
df -Th /home/gaurav-s-ubuntu/Work/Work/AirDawg/SENTINAL-ULTRA | tail -1
```

What changes: `cp -a` and `rm -rf` of a full task copy are seconds rather than minutes,
`git gc` inside `environment/repo` finishes immediately, and the `D`-state wedge that ended
the libcrux round 1 cannot happen. The stuck `rm -rf .next` processes and the pending
`ntfsfix` from that round are gone with the move.

What does not change: **still put disposable run copies in the session scratchpad**, and still
copy only `tests/` and `solution/` rather than the whole task. That rule was never really about
NTFS. It keeps `solve.sh` and `test.sh` from mutating the working copy, which is a correctness
rule, and `/tmp` is faster than any project tree regardless of filesystem.

Keep the NTFS sections below. The mount still exists and a task could be opened from it again,
and the `git`-segfault and stale-`.lock` findings are worth having either way.

## The workspace lives on NTFS and that matters

```
/dev/nvme0n1p5 on /media/gaurav-s-ubuntu/COLLEGE MATERIAL type ntfs3 (rw,...)
```

`ntfs3` is fine for reading and writing a handful of files. It is very slow at bulk
operations over many small files, and a shipped `environment/repo` is a few thousand of
them. `cp -a` of a full task copy and `rm -rf` of one both take minutes and routinely blow
past a 10 minute tool timeout.

**Rule: put disposable run copies in the session scratchpad, never in a folder inside the
workspace.** An earlier version of `CLAUDE.md` named `local_runs/` at the workspace root
for this. That cost an afternoon (see the SIGKILL section below) and `CLAUDE.md` now points
at the scratchpad instead.

## Do not copy the whole task to run the checks

The image already contains the repo at `/app` because the Dockerfile does `COPY repo/ .`.
The verifier only ever reads `/tests`, and the oracle only reads `/solution`. So the
disposable copy only needs those two directories, which are about 250 KB together instead
of ~10 MB.

```bash
SP=<scratchpad>
mkdir -p "$SP/run/logs-nop" "$SP/run/logs-oracle"
cp -a <task>/tests "$SP/run/tests"
cp -a <task>/solution "$SP/run/solution"
chmod -R a+rwX "$SP/run"

docker build -t task:v1 <task>/environment/

# NOP, must give reward 0
docker run --rm --network none --cpus=4 --memory=8g \
  -v "$SP/run/tests:/tests:ro" -v "$SP/run/logs-nop:/logs/verifier" \
  task:v1 bash /tests/test.sh

# Oracle, must give reward 1
docker run --rm --network none --cpus=4 --memory=8g \
  -v "$SP/run/tests:/tests:ro" -v "$SP/run/solution:/solution:ro" \
  -v "$SP/run/logs-oracle:/logs/verifier" \
  task:v1 bash -c 'bash /solution/solve.sh && bash /tests/test.sh'
```

Mount `tests` and `solution` read-only. Then the scripts cannot mutate anything outside
the container and the "never run these in the working copy" rule is satisfied structurally
rather than by discipline.

Use `--network none` to reproduce the airgapped verifier, and `--cpus` / `--memory` to
match what `task.toml` declares. Without the limits the timing measurement is meaningless.

## Never SIGKILL an `rm -rf` on this mount

This is the expensive one. Three concurrent `rm -rf` runs on the same tree, each killed
mid-delete when a tool call timed out, left a process stuck in the kernel:

```
PID 1888842  STAT D  WCHAN vfs_unlink  ELAPSED 01:16:52
```

`D` is uninterruptible sleep. `kill -9` is queued and never delivered while the ntfs3
driver sits in `vfs_unlink`. That process pins the inodes, so every later `rm` on the
directory returns exit 124, and even `find -maxdepth 3` hangs. Only a reboot clears it.

**Rules:**
- One delete at a time on this mount. Never start a second while the first is running.
- Give bulk deletes a background task with `run_in_background`, not a foreground call that
  a timeout will kill.
- If a delete times out, check `ps -o pid,stat,wchan -p <pid>` before retrying. A `D` state
  means stop; retrying only adds more stuck processes.
- Recovery is `reboot`, then `sudo ntfsfix /dev/nvme0n1p5`, then delete.

## Timing is only meaningful on a quiet host

The same oracle run measured 173s, 250s and then over 600s across the session, purely from
other containers competing for CPU. Check `uptime` and `docker ps` before trusting a
number, and take the fastest clean run as the real figure. Do not size a verifier timeout
off a measurement taken on a loaded box.

## Tool timeout ceiling

`Bash` caps at 600000 ms. Asking for more is silently clamped, and the call dies at ten
minutes with exit 143. A full oracle run plus a build can exceed that, so run them with
`run_in_background: true` and poll, rather than passing a larger timeout that will not be
honoured.

## git can segfault on this mount, and the lock it leaves ships

Source: `20260723_030109__cryspen_libcrux__1165`, revision round, 2026-08-03.

Two new failure shapes on the same ntfs3 mount, both while regenerating `tests.patch`:

```
/bin/bash: line 29: 1299702 Segmentation fault      git reset -q
```

The `git diff --cached` before it had already written the patch correctly, and the reset had taken
effect, but it left `.git/HEAD.lock` **and** `.git/refs/heads/main.lock`. The first is obvious.
The second is not: it survived into the working copy, got baked into a test image by
`COPY repo/ .`, and then silently broke a simulated agent's commit:

```
fatal: cannot lock ref 'HEAD': Unable to create '/app/.git/refs/heads/main.lock': File exists.
```

That made an agent-collision probe look like it passed when the agent had never actually
committed. **Add `find .git -name '*.lock' -delete` to the pre-zip hygiene, and check for it
after any git command that dies abnormally.**

## When the mount wedges mid-round, rebuild the bundle on /tmp

Later in the same round, `git reflog expire --expire=now --all` went into `D` state and stayed
there:

```
1313686 D    lock_two_nondirectories      891  git reflog expire --expire=now --all
 627189 DN   vfs_unlink                 39179  rm -rf .next
 642659 DN   iterate_dir                38529  rm -rf .next
load average: 19.35
```

The two `rm -rf .next` had been stuck for about eleven hours and belonged to a different project
on the same mount, so the wedge was inherited rather than caused by this task. Diagnose with
`ps -eo pid,stat,wchan:24,etimes,cmd | awk '$2 ~ /D/'` before assuming your own command is at
fault, and do not retry, since `kill -9` is never delivered.

The round does not have to stop there. The deliverable can be rebuilt entirely on `/tmp`:

```bash
cp -a <task>/download/original/. "$SP/rebuild/"      # pristine, one bulk read
cp <edited files> "$SP/rebuild/"                     # the handful you changed
cd "$SP/rebuild/environment/repo"
git checkout -- .                                    # clean tree, symlinks and modes back
git reflog expire --expire=now --all && git gc --prune=now   # seconds here, not minutes
git fsck --unreachable --no-progress                 # must print nothing
cd "$SP/rebuild" && zip -rXy "$SP/task.zip" .
cp "$SP/task.zip" <task>/upload/                     # one large write back
md5sum "$SP/task.zip" <task>/upload/*.zip            # confirm the copy
```

The same hygiene that hung for over ten minutes on the mount finished in seconds on `/tmp`. Verify
the copy with `md5sum` afterwards, because a large write to a degraded mount returning instantly
is not by itself proof it landed.
