# 006 — Sentinel swap-back: recovery without debugging — DONE

**Thesis:** #14 clones-as-checkpoints ("Swap-back as the petri-dish recovery primitive")

## What was built (on Oracle, `/home/ubuntu/crabs/.parked/`)

- **`swap-back.sh <crab-dir>`** — the recovery primitive. Every crab's
  `feed-and-watch.sh` calls it first thing (host-side, before the
  sandboxed routine runs), guarded by `|| true` so it can never be a
  second failure. Breakage signals: `tripwire.txt` present,
  `RESULTS.json` not `ok:true`, `routine.sh` failing `bash -n`, or the
  crab dir missing. On breakage it moves the broken clone to
  `.parked/postmortem/<crab>-<timestamp>/` (kept inspectable, never
  deleted), `cp -a`'s the parked clone into place, and appends a
  `SWAPBACK` token to the new live ledger. No pointer, no swap — it
  leaves the crab alone rather than guessing.
- **`park-good.sh <crab-dir>`** — snapshots a healthy crab to
  `.parked/<crab>/<timestamp>/`, refuses to park a broken one, keeps the
  newest 3 snapshots, and writes the pointer.
- **`README.md`** — documents the pointer format and post-mortem
  retrieval (kept on Oracle at `.parked/README.md`).

## Pointer format

`.parked/<crab>/LAST-GOOD`, a key=value file:

```
clone=/home/ubuntu/crabs/.parked/health-01/20261009T044716Z
parked_at=20261009T044716Z
results_ok=true
```

Only the `clone=` line is read. Post-mortem retrieval: the broken clone
sits untouched at `.parked/postmortem/<crab>-<ts>/` with its broken
`routine.sh`, `RESULTS.json`, and ledger — diff it against the live crab.

## The drill (deliberate break, watched swap)

1. Created test crab `swaptest-01` (standard layout, feeder wired).
2. Ran it healthy, parked it (`LAST-GOOD` written).
3. Broke `routine.sh` with a real syntax error (`bash -n` exit 2).
4. Ran the feeder: `SWAPBACK swaptest-01: broke (routine.sh fails
   bash -n); parked clone live; broken kept at
   .parked/postmortem/swaptest-01-20261009T044634Z`. The ledger shows the
   `SWAPBACK` token, then a fresh `TICK ok=true` from the restored clone.
5. Ran the feeder again: no second swap, fresh tick — steady state.
6. Confirmed the broken clone in postmortem still contains the sabotaged
   `routine.sh`, fully inspectable.

## Production wiring

All five feeders (commitments-01, health-01, heartbeat-01, sentinel-01,
swaptest-01) call swap-back first. Parked the three healthy production
crabs. sentinel-01's next scan picked up swaptest-01 honestly in its
snapshot.

## Honest gaps and incidents

- **I briefly broke the production feeders.** The first wiring inserted
  the swap-back line *before* the `CRAB=` assignment; under `set -u`
  that is a fatal unbound-variable error. Fixed within minutes by making
  the line derive the crab dir from its own path (no variable ordering
  dependency), re-verified all five feeders with `bash -n` and ran
  health-01's and sentinel-01's feeders end-to-end. No ledger damage —
  the broken line exited before any feeder work ran.
- **health-01 has an active tripwire** (`tripwire.txt` created today
  04:44:47 UTC, not by me — likely someone else's fire drill). Its
  routine is correctly reporting `ok:false` "tripwire pulled — drill"
  and the watcher escalated it (unacked token in sentinel's report).
  I did **not** remove the tripwire or ack the escalation — not mine to
  stand down. Consequence: `park-good` correctly refused to park
  health-01 (you don't park a tripped crab), so health-01 currently has
  no `LAST-GOOD` pointer; if it breaks for another reason, swap-back
  will log "no parked clone — leaving as-is". Re-park it once the drill
  is stood down.
- The drill used a syntax-error breakage; the tripwire and `ok:false`
  paths were exercised by health-01's live drill (swap-back correctly
  stood aside there). A missing-crab-dir break was not drill-tested.
- `swaptest-01` remains on Oracle as a standing drill crab, run manually
  (not on cron). It appears in sentinel-01's snapshot like any crab.
