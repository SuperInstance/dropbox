# Report: 017 — promotion ladder

## What was done
Wrote `PROMOTION.md` — stages, gates, authority, provisioning, demotion path —
and committed it to SuperInstance/muse-workspace under `ideas/`.

## Design decisions
- **Stages**: shirt (disposable, signs nothing) → long-lived shirt (accumulated
  judgment, *de facto* influence, *de jure* no authority — the dangerous middle)
  → clone (signing authority, a throat to choke). The stage test: whose
  signature counts?
- **Gate A (shirt → long-lived shirt)**: *recognition*, not promotion — tripped by
  redeployment count (≥5), costly-to-lose local state, or reliance on its
  judgment. Nominated by anyone (harness, zero agent, watcher, the shirt
  itself); starts a 7-day promote-or-kill clock.
- **Gate B (→ clone)**: all three required — a named responsibility exists, evidence
  of judgment reviewed, and the promotion is wanted by someone with standing.
  **Authority**: the human principal, delegable to the zero agent bounded by a
  written promotion policy (delegation itself a ledger entry, revocable).
- **Provisioned at crossing**: name + ledger identity, fresh signing keys,
  re-issued credentials (never copied), the full clone ceremony, and a promotion
  ledger entry naming the authoriser, responsibility, and evidence.
- **Demotion path**: yes, a clone can go back — but demotion is revocation, not
  erasure. Keys/credentials revoked immediately, demotion recorded in the ledger
  (claims history retained and still attributable), entity lands at Stage 2
  with its memory intact; re-promotion goes through Gate B with no fast lane.
  Emergency demotion: revoke first, write the ledger entry second — but it must
  be written, or the throat-to-choke chain breaks.

## Links
- https://github.com/SuperInstance/muse-workspace/blob/main/ideas/PROMOTION.md
- Commit: https://github.com/SuperInstance/muse-workspace/commit/1327eb953bf0563dd8e7c44d57919495cb6658c8
