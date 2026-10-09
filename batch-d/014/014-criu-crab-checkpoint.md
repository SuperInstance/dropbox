# 014 — The CRIU experiment: checkpoint a live crab

**Date:** 2026-10-08 (AKDT) / 2026-10-09T04:43–04:50Z (experiment window, Oracle clock)
**Box:** Oracle Cloud `ubuntu@147.224.38.131` — aarch64, Ubuntu 26.04.1 LTS, kernel `7.0.0-1013-oracle`
**Thesis under test:** #10 clone-as-data-full-state (`ideas/clone-as-data-full-state.md` in SuperInstance/muse-workspace), which names CRIU explicitly as the mechanism for the "running processes" layer of full state.
**Rule observed:** nothing under `~/crabs/` or the live crontab was touched; all work on scratch copies and scratch processes. `~/scratch/` on Oracle was emptied afterwards.

## 1. CRIU verdict: AVAILABLE (installed for this experiment)

The task brief expected CRIU to be missing (`which criu` returns nothing). It was missing — but installable, so per the brief I installed it and ran the real experiment. Every probe, with exact outcome:

| Probe | Command | Outcome |
|---|---|---|
| Binary present? | `which criu` | Not found (rc=1); no `/usr/sbin/criu`, no `/usr/bin/criu` |
| Package installed? | `apt-cache policy criu` | Installed: (none). Candidate: `4.2-1ubuntu2` in `resolute/universe arm64` |
| Kernel support? | `grep -E 'CHECKPOINT_RESTORE\|FREEZER' /boot/config-7.0.0-1013-oracle` | `CONFIG_CHECKPOINT_RESTORE=y`, `CONFIG_FREEZER=y`, `CONFIG_CGROUP_FREEZER=y` — all built in |
| Non-interactive sudo? | `sudo -n whoami` | `root`, rc=0 — passwordless sudo works |
| Environment capable? | `sudo -n criu check` (after install) | `Looks good.` |
| Install | `sudo -n apt-get install -y criu` | Installed cleanly → `/usr/sbin/criu`, `Version: 4.2` |

Notes: a pre-existing broken line in `/etc/sudoers.d/oracle1-sudo` (a wildcard in a command argument) prints a warning on every sudo invocation but does not block; it predates this experiment and was left alone. CRIU remains installed on the box (reversible with `apt-get remove criu`); no configuration was changed.

**No substitution was needed.** The "nearest alternative" clause of the brief did not trigger. The file-snapshot and `/proc`-snapshot exercises below were run anyway, as the brief's step 2 asks for them as the contrast arm — and because for the real crab architecture they turn out to be the more honest checkpoint.

## 2. What was checkpointed

Two different "crabs", because the real crabs and a CRIU target are different kinds of thing:

**(a) `crab-sim.sh`** — a scratch long-running bash loop imitating a crab *as if* the loop lived in the process: cwd pinned to the workdir, `CRAB_ID`/`CRAB_ROLE` exported after exec, `umask 027`, fd 3 held open on `run.log` in append mode, fd 9 held open on `inbox.txt` with its offset moved 10 bytes in, an in-memory `TICK` counter, and a `sleep 5` timer driving the loop. Started detached (`setsid`), pid 1902312.

**(b) A scratch copy of the real crab** — `cp -r ~/crabs/heartbeat-01 ~/scratch/criu-crab-copy` (556K; contains `TASK.md`, `STATE.json` with `cursor`, `LEDGER/tokens.log`, `RESULTS.json`, `inbox.txt`, `routine.sh`, `feed-and-watch.sh`). The live original was never touched.

Key architectural fact established first (read-only): the real crabs are **cron-driven batches**, not long-running processes — `crontab -l` shows `*/10 * * * * /home/ubuntu/crabs/heartbeat-01/feed-and-watch.sh`. Each run of `routine.sh` is seconds long: it tallies `inbox.txt`, writes `RESULTS.json`, appends `LEDGER/tokens.log`, advances the `cursor` in `STATE.json` via python3, and exits. There is no mid-loop process to freeze; the "loop" lives in cron.

## 3. The CRIU experiment (process checkpoint)

**Dump:** `sudo -n criu dump --tree 1902312 --images-dir ~/scratch/criu-images --leave-stopped` → rc 0. The tree (bash + its `sleep` child) froze to `Ts`. Image set: 3.6 MB — `core-*.img`, `mm-*.img`, `pagemap-*.img`, `pages-*.img` (the RAM), `fdinfo-*.img`, `files.img`, `fs-*.img`, `ids-*.img`, `pstree.img`, `inventory.img`.

**Restore elsewhere:** the images dir was moved to `~/scratch/criu-images-moved` (proving the checkpoint is portable data, not tied to its directory), the stopped original was killed, and `sudo -n criu restore --images-dir ~/scratch/criu-images-moved -d` → rc 0, from the moved location.

**Verified after restore** (every claim probed, none assumed):

- Same PID 1902312 came back (PPID is now 1 — the original `setsid` parent was outside the dumped tree; cause below).
- In-memory `TICK` continued 5 → 6 → 7 → 8 → 9 with no reset — RAM survived.
- fd 9 offset still `pos: 10` (`/proc/1902312/fdinfo/9`) — open-file offsets survived.
- fd 3 still → `run.log`, appending continued — open fds survived.
- `Umask: 0027` in `/proc/1902312/status` — umask survived.
- cwd identical — fs state survived.
- Exported env survived: `/proc/1902312/environ` never showed `CRAB_ID` (post-exec exports are invisible to `/proc` readers — a real limitation of the `/proc`-snapshot method), but the re-forked `sleep` child's environ contained `CRAB_ID=heartbeat-sim-01` and `CRAB_ROLE=heartbeat`, and the log lines kept printing `crab=heartbeat-sim-01`. CRIU sees what `/proc` cannot.
- Timer: the in-flight `sleep 5` resumed with remaining-time semantics — the next tick fired ~1s after restore, matching roughly the ~1s left when frozen. No burst of "catch-up" ticks; the ~10s of wall-clock that elapsed during the freeze is simply lost to the process.
- Clock: log timestamps jump from `04:45:01Z` (tick 5) to `04:45:13Z` (tick 6) across the freeze — the process did not experience the intervening time.

## 4. Sockets: the sharp edge, tested three ways

A second sim held a connected TCP socket (bash fd 4 → `127.0.0.1:18923`, python listener on loopback).

1. **Dump without `--tcp-established` → REFUSED.** Exact errors from the dump log: `Error (criu/sk-inet.c:200): inet: Connected TCP socket, consider using --tcp-established option.` / `Dumping FAILED.` The process was left stopped and had to be `SIGCONT`'d by hand. Cause: kernel connection state is not in the default image; CRIU refuses rather than silently dropping it.
2. **Restore without `--tcp-established` (after a flagged dump) → REFUSED.** `Error (criu/sk-inet.c:912): inet: Connected TCP socket in image` / `Unable to open fd=4` / `Restoring FAILED.` The flag is required on **both** sides — a matched pair.
3. **Flag on both sides → full survival.** Restore clean, same PID, same endpoints `ESTABLISHED`, and a message the peer sent *while the process was frozen* was delivered to the restored process intact — all 20 bytes of `HELLO-AFTER-RESTORE`, logged one second after restore.

Two honest footnotes. First, **PID restoration is strict**: one restore attempt failed with `Error (criu/cr-restore.c:1230): Can't fork for 1904315: File exists` because I had killed only the bash and its orphaned `sleep` child was still alive holding the old PID — the original tree must be *fully* dead before restore, or the PID replay collides. Second, **a failed half-repair costs bytes**: in the run where the flag-less restore was attempted first, the eventually delivered message arrived missing its first byte (`ELLO-AFTER-RESTORE`); the clean re-run delivered all 20 bytes. Cause: the failed repair attempt consumed the byte from the queue — the checkpoint didn't lose it, my fumbling did.

## 5. The file-clone experiment (the architecture the crabs actually use)

Mid-"loop" (between cron ticks; the live crab last ran `20261009T044001Z`): tarred the scratch copy, extracted to `~/scratch/criu-restore-20261009T044946Z/`, ran `routine.sh` there → rc 0.

Continuation verified, field by field:

- `STATE.json`: `cursor` 747 → 748, `last_run` advanced to `20261009T044946Z`.
- `RESULTS.json`: rewritten with the fresh per-run token `tok-20261009T044946Z-1910250`.
- `LEDGER/tokens.log`: appended `tok-20261009T044946Z-1910250 TALLY lines=747`.
- Live original untouched: its cursor still 747. The clone has now diverged — from this point the ledger would show two signers, exactly the twin problem thesis #10 names.

## 6. The `/proc`-snapshot contrast (SIGSTOP vs kill+restart)

On the still-running sim: `SIGSTOP` → captured `cmdline`, `environ`, fd symlinks (0→/dev/null, 1,2→nohup.out, 3→run.log, 9→inbox.txt, 255→script), fdinfo offsets (fd3 pos 4089, fd9 pos 10), `Umask: 0027`, `PPid: 1`, cwd → `SIGCONT`. Ticks continued 63 → 64: a stopped process keeps its RAM, so this "snapshot" preserves everything trivially — because nothing was ever copied.

Then `kill -9` + fresh start (what "restart from STATE.json" means for a file-state design): new pid 1910544, log shows `start pid=1910544 tick=0` — the in-memory counter reset to zero (66 ticks of RAM history gone), while the file history (all 66 log lines) persisted and the script re-established fd offsets, env, umask, and cwd by itself.

## 7. The breakage inventory (the deliverable)

Two checkpoint mechanisms, twelve elements. One-line cause each. "Survived" means verified by probing the restored system, not inferred.

| # | Element | CRIU dump → restore | File snapshot (tar/cp) → rerun |
|---|---|---|---|
| 1 | Sockets (connected TCP) | **Survived** — with `--tcp-established` on *both* dump and restore: same endpoints, ESTABLISHED, in-flight bytes delivered. *Cause of the failure mode: connection state lives in the kernel's socket table and is excluded from the default image, so CRIU refuses without the flag rather than silently dropping it.* | **Broke** — the clone has no fd 4. *Cause: tar copies bytes on disk; the connection lived in the kernel and died with the original process.* |
| 2 | Timers (`sleep` cadence) | **Survived with remaining-time semantics** — next tick fired ~1s after restore, matching ~1s left at freeze; no catch-up burst. *Cause: CRIU checkpoints the remaining sleep; wall-clock elapsed during the freeze is simply lost to the process.* | **Not carried** — a fresh run restarts the cadence from zero; the real crab's 10-minute rhythm was never in the process anyway. *Cause: the rhythm lives in crontab, outside any snapshot.* |
| 3 | File offsets | **Survived** — fd 9 `pos: 10` before and after. *Cause: offsets belong to the open-file description, which CRIU serialises into the image.* | **Re-established, not preserved** — fresh opens start at 0 unless the script seeks. *Cause: offsets live in the kernel's open-file table, not on disk. (Moot for the real crab: `routine.sh` re-opens `inbox.txt` every run.)* |
| 4 | In-memory cursor / variables (`TICK`) | **Survived** — counter continued 5→6→7… and 63→64, no reset. *Cause: RAM pages are the bulk of the 3.6 MB image; that is what a process checkpoint is for.* | **Lost** — fresh process started at `tick=0`. *Cause: bash variables live in RAM; the snapshot was of files only. (The real crab's cursor lives in `STATE.json`, so it loses nothing that matters.)* |
| 5 | PID | **Preserved** — 1902312, 1908561, 1909834 all restored identically. *Cause: CRIU replays PIDs via `ns_last_pid` — which is also why restore fails with `Can't fork for <pid>: File exists` unless the original tree is fully dead first.* | **Meaningless** — every run gets a fresh PID by design. *Cause: the crab is a short-lived batch; its identity is the directory, not the PID.* |
| 6 | cwd | **Survived** — identical path. *Cause: fs state is in the image; the path must still exist at restore time.* | **Survived** — the script `cd`s to its own directory. *Cause: `routine.sh` is location-independent (`cd "$(dirname "$0")"`).* |
| 7 | Env vars | **Survived** — `CRAB_ID`/`CRAB_ROLE` present in the re-forked child's environ after restore. *Cause: the environment is process memory, captured in the pages image — CRIU sees post-exec exports that `/proc/PID/environ` never shows.* | **Re-set, not preserved** — the fresh shell re-exports from the script; anything not re-exported is gone. *Cause: environment is per-process; files carry no env.* |
| 8 | umask | **Survived** — `0027` before and after. *Cause: umask is in the fs image.* | **Lost** — the fresh process inherits its spawner's umask (cron's `022`). *Cause: umask is a process attribute, not a file attribute.* |
| 9 | Open file descriptors | **Survived** — fds 3→`run.log`, 9→`inbox.txt` intact and appending. *Cause: the fd table is in the image.* | **Lost** — the clone opens its own fds. *Cause: the fd table is kernel state. (Moot for the real crab: it opens and closes everything inside one run.)* |
| 10 | Cron schedule (external) | **Not captured** — the 10-minute cadence is not in the tree. *Cause: CRIU snapshots the tree, not the scheduler that launches it.* | **Not captured** — same. *Cause: the schedule lives in `crontab -l`, not in the directory; a clone on a new machine sits idle until the crontab entry is recreated.* |
| 11 | Tokens (per-run) | N/A for the sim; for the real crab: never checkpointable by design. *Cause: a token (`tok-<stamp>-2`) names one execution — checkpointing it would forge a run that already happened.* | **Regenerated** — the restored run minted `tok-20261009T044946Z-1910250`. *Cause: generation happens at runtime from the clock.* |
| 12 | Clock | **Jumped, not frozen** — ~10s of wall-clock elapsed during the freeze; timestamps show the gap; no catch-up. *Cause: time is not in the box — CRIU freezes the process, not the clock.* This is the thesis's own "wall-clock time" breakage, confirmed empirically. | **Fresh** — the new run stamps the new time and never pretends otherwise. *Cause: the clone reads the clock at start.* |

## 8. What this proves about thesis #10 — for THIS architecture

Three findings, stated plainly:

1. **For the actual crabs, clone-as-data-full-state is true at the file layer and the process layer is irrelevant.** Every piece of continuity-relevant state — `cursor`, ledger, results, inbox — lives in files. The "running loop" is cron, external to any snapshot. A tarball plus the crontab entry *is* the full state; kill+restart loses nothing the crab needs, as the restored copy's 747→748 cursor advance proves.

2. **CRIU proves the stronger claim is mechanically real.** A running loop *can* be frozen with RAM, fds, offsets, timers, env, umask, cwd, PID, and even live TCP connections intact — 3.6 MB for a bash loop, restore in seconds. If a future crab ever becomes a long-running daemon (watcher mid-poll, build half-done — the thesis's own examples), the mechanism exists on this box now (`/usr/sbin/criu`, 4.2).

3. **The boundary is where the thesis says it is.** What neither mechanism carries: the scheduler (cron), the wall clock, and anything past the machine boundary. Full state is full state *of the machine* — the experiment confirms the thesis's three breakage directions (outside world, wall-clock time, and by extension secrets/standing agreements) rather than refuting them. The thesis steelmans itself correctly.

The one-line version: **the clone lives in the files; CRIU is the answer to a question this architecture doesn't ask — and the proof that the thesis's mechanism claim holds for architectures that do.**

## 9. Honest gaps (not tested)

- Cross-host restore: "elsewhere" was a different images dir on the same machine (process) and a different path (files). True migration to a second host was not attempted.
- Socket variety: only connected TCP on loopback. Listening sockets, unix-domain sockets, TLS, and external-network connections were not tested.
- A real crab was never frozen mid-cron-run: runs last seconds, and live crabs were off-limits; the sim is the honest substitute, not the thing itself.
- Restore with a missing cwd, and CRIU under user namespaces/containers, were not exercised.
- The orphaned-`sleep` PID-collision failure and the half-repair byte loss were discovered by fumbling, not by design — but they are real behaviours, recorded above with their causes.

## 10. Cleanup

All scratch processes killed; `~/scratch/` on Oracle emptied (experiment dirs, image dirs, tarball, the temporary muse-workspace clone used to read the thesis docs). Live `~/crabs/` dirs and the crontab unmodified — verified after cleanup (`crontab -l | grep -c crab` → 4, all five crab dirs present, live heartbeat cursor still 747). CRIU 4.2 remains installed (the one durable change, authorised by the brief).
