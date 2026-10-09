# 012 — The gate dashboard ("are your assumptions holding?")

## What I did
Built a probe script for the Oracle crabs at `/home/ubuntu/crabs/` that
decomposes the big vague assumption **"the watchers are watching"** into
three gates, each rendered green/yellow/red. The board shows gate status
only — no raw numbers anywhere; words only (fresh / aging / silent, clear /
stale scan / unacked escalations, intact / degraded / pulled).

Ran it against the live system (all green, independently verified — see
below), deliberately tripped one gate with the designed fire-drill mechanism,
watched it go red, then stood the drill down and confirmed green again.
Committed to SuperInstance/muse-workspace under `gates/`.

## Gate definitions

1. **heartbeat alive** — freshness of heartbeat-01's tick. Green "fresh"
   (tick ≤ 20 min), yellow "aging" (20–40 min), red "silent" (> 40 min) or
   "halted" if the routine reports ok:false.
2. **sentinel clear** — sentinel-01's escalation ledger. Green "clear"
   (scan ok, zero unacked), red "unacked escalations" or "scanner down",
   yellow "stale scan" (report older than 20 min — a "zero" we can't trust).
3. **health & tripwire** — health-01's vitals + fire drill. Green "intact",
   yellow "degraded" (notes present or scheduler flag off), red "pulled —
   drill" (tripwire.txt present) or "critical reading" (ok:false).

## Gate pedigree (full detail in `gates/PEDIGREE.md`)
- Gate 1 boundaries: **manual.** The 20-minute rule is borrowed from
  health-01's own TASK.md ("if no crab has written to its ledger in 20
  minutes, the scheduler may be down") — the fleet's own definition, not an
  invented one. 40 min = two missed 10-min ticks plus slack, reasoned by hand.
- Gate 2 boundaries: **manual.** Zero tolerance for unacked escalations comes
  from sentinel-01's TASK.md design ("report honestly even when the news is
  bad — especially then"). 20-min staleness matches Gate 1's green for
  consistency.
- Gate 3 boundaries: **manual**, inherited from health-01's TASK.md
  fire-drill design (touch `tripwire.txt` to test the chain; remove to stand
  down — predates this dashboard). Yellow "degraded" is a **guess**: notes
  non-empty with ok:true has not been observed in the wild yet.
- **Recalibration procedure** (per gate, in PEDIGREE.md): two false
  yellow/reds in a week (verified against `tokens.log`, never against the
  gate itself) move the timing boundary to the 99th percentile of observed
  healthy values plus slack, logged with date and reason in PEDIGREE.md. The
  red "unacked" boundary is never recalibrated — red by design. The drill is
  fired monthly; if a drill ever fails to turn the gate red within two tick
  intervals, fix the probe, not the boundary.

## Live run (04:44 UTC, 2026-10-09)
Board: all three green — heartbeat fresh, sentinel clear, tripwire intact.
**Independent verification** (read the underlying state myself, did not trust
the script): heartbeat token ~4.7 min old with ok:true; sentinel ok:true,
`unacked_total` zero, scan fresh; health ok:true, scheduler yes, notes empty,
no `tripwire.txt`. All three verdicts confirmed true.

## Deliberate trip (04:44–05:01 UTC)
- 04:44:47 — pulled the drill: `touch
  /home/ubuntu/crabs/health-01/tripwire.txt`.
- 04:47 — the watchstander's 10-min health cycle wrote ok:false
  ("tripwire pulled — drill"); health-01's watcher raised
  `WATCHER ESCALATE` → human (`wtok-20261009T044749Z`).
- 04:50 — sentinel-01's scan picked it up as unacked.
- 04:57 — board showed **both** Gate 3 red ("pulled — drill") **and** Gate 2
  red ("unacked escalations"). Saved as `gates/sample-board-tripped.md`.
  The cascade is the point: the drill exercised the whole chain end to end.
- Stand-down: removed `tripwire.txt`, recorded an ack with
  `watcher.py --ack wtok-20261009T044749Z --by gate-dashboard-drill-012`
  (honest attribution — did not impersonate the human recipient).
- 05:00 — routine reported ok:true; watcher stood the escalation down
  (`pending_escalation` is None in STATE.json).
- 05:01 — board back to all green. No residual state: tripwire gone, no
  pending escalation, sentinel unacked count zero.

## Gaps and honest notes
- Gate 3's yellow "degraded" branch has never fired; its boundary is a guess
  and needs its first real sighting before I trust it (PEDIGREE.md records
  this and the narrowing procedure).
- The drill escalation was addressed to "human" per health-01's
  `escalate_to` chain. Nothing pages Casey — the proposed bridge cron that
  would surface escalations in main chat is still awaiting his approval — but
  I stood it down within the ack window regardless.
- Commitments-01 (6h cadence) was deliberately left out of the board; it is a
  ledger of promises, not a liveness assumption, and deserves its own
  decomposition (a future task, not this one).

## Artefacts (SuperInstance/muse-workspace, commit
`efbf7eec23e297d61a43b63c8bb986621f07464d`)
- `gates/gate-dashboard.sh` — probe + evaluate + render, single file.
- `gates/PEDIGREE.md` — boundary pedigree and recalibration procedures.
- `gates/sample-board-healthy.md` — the all-green live board.
- `gates/sample-board-tripped.md` — the board mid-drill (two gates red).
