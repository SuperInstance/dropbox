# Report: 018 — parking entitlement

## What was done
Wrote a short design doc on who gets to park a clone and committed it to
SuperInstance/muse-workspace under `ideas/` as `PARKING-ENTITLEMENT.md`.

## Design decisions
- **Entitlement rule**: park rights are granted *per responsibility, not per
  agent* — a scoped, revocable, ledger-recorded parking grant (system, max
  parked clones, retention). Default: nobody has park rights. A park is
  *stored* on the proposer's signature but *trusted* only with a witness
  countersignature; witnesses are drawn per-park from a pool, never fixed.
- **Anti-poisoning** (four layers): quarantine before trust
  (`parked-unverified` → thaw test in sandbox + witness countersignature →
  `parked-trusted`); mandatory `not_verified` field naming what was *not*
  checked; provenance chain (ledger height + snapshot ref, replayable);
  revocation propagates as `parked-suspect`, inherited by derivatives.
- **Signature format** (exact fields): `kind`, `clone_id`, `system`,
  `parked_at`, `ledger_height`, `snapshot_ref`, `parked_by`, `park_grant`,
  `witnessed_by`, `status` (forward-only: unverified → trusted → suspect),
  `verified[]`, `not_verified[]` (mandatory — a park claiming everything was
  verified should be refused countersignature), `thaw_test`, and dual
  signatures with the witness covering the parker's.
- **Adversarial case** (bad actor *with* park rights — addressed directly):
  agreed it is worse than no checkpoints; answered in layers — the thaw test is
  behavioural (poison must beat the tests, not the paperwork), per-park
  witnesses raise the price of collusion, `not_verified` bounds the blast
  radius, the swap-back is a separate signed decision (a parked clone never
  deploys itself), and thesis #1's throat: the parker's identity is on the
  claim forever in the ledger — a signed confession that survives the attack.

## Links
- https://github.com/SuperInstance/muse-workspace/blob/main/ideas/PARKING-ENTITLEMENT.md
- Commit: https://github.com/SuperInstance/muse-workspace/commit/1327eb953bf0563dd8e7c44d57919495cb6658c8
