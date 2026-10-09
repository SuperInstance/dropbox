# Done: 003 — The redshirt reaper (proper death)

## What was done
Both halves, committed to `SuperInstance/redshirt`:

**1. The scavenger (`reaper.sh`).** Claims are no longer empty `.claimed`
markers — claiming writes `inbox/<task>.md.claimed` with
`name=`/`claimed_at=`/`heartbeat=` (created atomically via `noclobber`, so
exactly one shirt wins a race). The owning shirt refreshes the heartbeat every
30s while the task runs, so a long task is never mistaken for a dead shirt.
`reaper.sh` runs at the top of every poll cycle — and standalone, by the zero
agent or any other shirt — and requeues any task whose claim heartbeat is
older than `REAP_AFTER` (default 300s, `--reap-after` at install): the claim
is deleted, the task becomes claimable again, and the event is appended to
`outbox/reaped.log`. Malformed claims are treated as ancient.

**2. Self-burial.** `redshirt.sh` installs an `EXIT` trap: on timebox expiry
*or any other exit*, `bury()` kills the shirt's children (wake daemon,
heartbeat pumpers) and `rm -rf`s `$HOME/.redshirt` — workdir, repo clone,
config, logs. Results were already pushed to git; the node leaves literally
nothing.

## Outcome
Committed and pushed to `SuperInstance/redshirt`:
- `af8fc3d` — 003: reaper.sh, `docs/reaper.md`, `tests/test-reaper.sh`
- `c3d4c2f` — 008 (integration commit): wires scavenger + burial into
  `redshirt.sh`/`install.sh`/README.

Verified:
- `tests/test-reaper.sh` 5/5 (stale claim requeued, fresh claim survives,
  malformed claim treated as stale, unclaimed task untouched, `reaped.log`
  records both requeues) on both machines.
- `tests/test-poller-e2e.sh` 7/7 (full loop against a local bare repo):
  tasks claimed/executed/pushed, and after timebox expiry `~/.redshirt`
  does not exist — burial confirmed, logged.
- `tests/demo-killswitch.sh` ends with the same burial check passing.

## Honest gaps
- The "kill a shirt mid-task, watch requeue within one poll cycle" drill was
  verified at the unit level (reaper logic) and in the e2e loop, not as a
  live two-node demonstration against the real repo. The mechanism is
  straightforward (`kill -9` the poller → next cycle's reaper pass requeues),
  but a live drill remains a good first-run exercise.
- Burial deletes the local log with everything else; the git repo (results,
  heartbeats, `reaped.log`) is the surviving record — by design.
