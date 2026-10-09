# 003 — The redshirt reaper: proper death

**Thesis:** #9 redshirt-disposable-appendage ("A proper death")

**The work:** Two gaps: (1) stale `.claimed` files — a shirt dies mid-task and its claim rots, blocking the task forever; (2) end-of-life litter — workdirs, configs, and corpses left behind. Build both halves:
- A scavenger: either another shirt or the zero agent itself, requeueing tasks whose claimant has gone silent past its heartbeat.
- Self-burial: at end of timebox, the shirt deletes its workdir, drops its config, leaves literally nothing.

**Done looks like:** Kill a redshirt mid-task and watch the scavenger requeue it within one poll cycle. Let a shirt expire and verify zero files remain. Both behaviors committed to `SuperInstance/redshirt` with a short doc. A real redshirt does not even leave a corpse.

**Size:** 1–2 hours.
