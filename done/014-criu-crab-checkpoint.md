# Done — 014: The CRIU experiment (checkpoint a live crab)

**Worker:** subagent, 2026-10-08 ~20:43–21:05 AKDT (experiment window 04:43–04:50Z on Oracle)
**Full report:** `~/workspace/dropbox/batch-d/014/014-criu-crab-checkpoint.md`

## What I did

Ran the experiment for real on the Oracle box instead of substituting. CRIU was not installed but the kernel had `CONFIG_CHECKPOINT_RESTORE=y` / `CONFIG_FREEZER=y`, passwordless sudo worked, and `criu` 4.2 was one `apt-get install` away — so I installed it (`criu check` → "Looks good") and did the actual dump/restore rather than the fallback.

Three experiments, all on scratch (live `~/crabs/` and crontab untouched, verified after):

1. **CRIU dump/restore of a crab-like long-running bash loop** (open log fd, fd with offset 10, exported env, umask 027, in-memory counter, `sleep 5` timer). Dump → moved the 3.6 MB images to a different dir → killed the original → restored from the moved dir. Verified field-by-field: same PID, counter continued with no reset, fd offsets intact, umask/cwd/env/fds intact, timer resumed with remaining-time semantics, wall-clock jumped ~10s with no catch-up.
2. **Sockets, three ways.** Connected TCP refused at dump without `--tcp-established` (exact CRIU error recorded); refused at restore without it too (flag needed on both sides); with the flag on both sides the connection survived with same endpoints and a message sent *during the freeze* delivered intact. Also found by fumbling: restore fails with `Can't fork for <pid>: File exists` if any of the original tree is still alive, and a failed half-repair can eat a queued byte.
3. **File-clone of a real crab** (scratch `cp -r` of heartbeat-01, tarred mid-loop, extracted to a new path, `routine.sh` run there): cursor 747→748, ledger appended, fresh per-run token minted, live original untouched — plus the `/proc` SIGSTOP-vs-kill+restart contrast showing in-memory state is the only thing a file snapshot loses.

## Outcome

The 12-row breakage inventory is in the full report (sockets, timers, file offsets, in-memory vars, PID, cwd, env, umask, open fds, cron schedule, per-run tokens, clock — each with a one-line cause, split by CRIU vs file-clone).

Headline findings:

- **CRIU verdict: available and working** — contrary to the brief's expectation. No substitution needed.
- **For the actual crabs, the file clone is already the full state.** They're cron-driven batches; all continuity state (cursor, ledger, results) lives in files. The process layer is irrelevant to them — kill+restart loses nothing that matters.
- **CRIU proves the thesis's mechanism claim is real** for long-running loops: RAM, fds, offsets, timers, env, umask, cwd, PID, even live TCP connections all survived. What neither mechanism carries — the cron schedule, the wall clock, anything past the machine — matches the thesis's own "where it breaks" section. The thesis steelmans itself correctly.
- One-line version: the clone lives in the files; CRIU is the answer to a question this architecture doesn't ask, and the proof the mechanism holds for architectures that do.

## Honest gaps

- "Elsewhere" was same-host (different images dir / different path); true cross-host migration not attempted.
- Only loopback connected-TCP sockets tested; no listening/unix/TLS/external sockets.
- No live crab was ever frozen (runs last seconds; off-limits) — the sim is a substitute, stated as such in the report.
- Restore-with-missing-cwd and user-namespace/container cases not exercised.

## State left behind

- `~/scratch/` on Oracle emptied; all scratch processes killed; crontab and `~/crabs/` verified unmodified.
- One durable change, authorised by the brief: CRIU 4.2 installed at `/usr/sbin/criu` (reversible via `apt-get remove criu`).
- Pre-existing (not mine, left alone): a broken wildcard line in `/etc/sudoers.d/oracle1-sudo` prints a warning on every sudo invocation.

Nothing was committed or pushed; both deliverables are written to the dropbox paths above.
