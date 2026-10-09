# Report: 010 — sync watermark protocol

## What was done
Wrote `SYNC-PROTOCOL.md` — a design doc precise enough for two people to
implement interoperable ends — and committed it to SuperInstance/muse-workspace
under `procedures/`.

## Design decisions (the hard parts, answered)
- **Watermark format** (exact fields): `kind`, `ledger`, `edge_id`,
  `applied_through` (highest *contiguous* sequence applied — no sparse
  watermarks), `applied_at` (edge clock, informational only), `ledger_head_at_pull`,
  `signed_by`, `signature`. Edge-signed; the cloud can never write or forge one.
  Watermarks are entries of kind `watermark` in the same ordered log — one
  sequence space, no side channels.
- **Compaction rule**: the cloud may delete entries `0..C` only after committing
  a snapshot entry covering them *in the ledger*, and only when
  `C < min(applied_through)` over edges heard from within the staleness window
  `W` (default 30 days). Edges silent past `W` are orphans; their resume point
  is no longer protected.
- **Resume guarantee**: an edge publishing its watermark at least once per `W`
  never finds its resume point compacted. Slow is safe; silent past `W` is not —
  and orphan return is a defined path (fetch latest snapshot, pull forward),
  the same code path as bootstrap.
- **Visibility vs control**: the test is whether the cloud's action gives the
  edge new *information* (allowed — e.g. the staleness dashboard, worked example
  included) or a new *obligation* (forbidden — e.g. rewriting a watermark,
  addressed commands; worked examples included for both sides).
- Known limits documented: omission by a compromised cloud (mitigation: peer
  gossip on heads), watermark spam (rate-limit, safe to drop), `W` as
  per-ledger policy recorded in genesis.

## Links
- https://github.com/SuperInstance/muse-workspace/blob/main/procedures/SYNC-PROTOCOL.md
- Commit: https://github.com/SuperInstance/muse-workspace/commit/1327eb953bf0563dd8e7c44d57919495cb6658c8
