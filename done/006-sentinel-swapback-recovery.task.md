# 006 — Sentinel swap-back: recovery without debugging

**Thesis:** #14 clones-as-checkpoints ("Swap-back as the petri-dish recovery primitive")

**The work:** When a crab breaks, the sentinel should not debug it — it should swap to the last parked clone. Debugging becomes optional archaeology, not emergency surgery. Implement the primitive: sentinel-01 (or whichever watcher owns the crabs) keeps a pointer to the last known-good parked clone per crab; on tripwire, it swaps the pointer instead of attempting repair. The broken clone stays parked for post-mortem.

**Done looks like:** A working swap-back path on Oracle for at least one crab: break it deliberately, watch the sentinel swap rather than debug, confirm the replacement is live. Document the pointer format (where the "last good" reference lives) and the post-mortem retrieval procedure. The broken clone must remain inspectable.

**Size:** 2 hours.
