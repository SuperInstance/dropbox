# 010 — The sync watermark protocol

**Thesis:** #13 pull-to-sync-not-push ("The sync protocol proper")

**The work:** Design the watermark record: "applied through entry N, at timestamp T, signed by whom." Then answer the hard parts: how does the cloud compact old entries without invalidating a slow edge's resume point? And the subtle one — should the edge's watermark itself become a ledger entry, so the cloud can see who is stale? That gives the cloud visibility without giving it command, but the line between visibility and control needs a careful write-up.

**Done looks like:** A `SYNC-PROTOCOL.md` in `SuperInstance/muse-workspace` specifying: the watermark format (exact fields), the compaction rule (what the cloud may delete and when), the resume guarantee for slow edges, and the visibility-vs-control boundary with at least one worked example of each side. This is a design doc, not code — but it must be precise enough that two people could implement interoperable ends from it.

**Size:** 1–2 hours.
