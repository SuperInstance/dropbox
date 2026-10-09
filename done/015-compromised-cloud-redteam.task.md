# 015 — Red team: the cloud is compromised

**Thesis:** #13 pull-to-sync-not-push ("The compromised-cloud red-team exercise")

**The work:** Assume the attacker owns the cloud completely. What can they do through a ledger-only interface? Work through each: poison the ledger (the edge verifies signatures — whose? what happens on a bad sig?), lie about what's new (watermarks and sequence numbers — can they be forged forward?), and the sharpest question — what does the edge do about a ledger entry it disagrees with? Refuse, flag, keep running? Write the refusal protocol: the exact steps an edge takes when the cloud's ledger fails verification, and what "keep running" means without a trusted cloud.

**Done looks like:** A `REDTEAM-CLOUD.md` in `SuperInstance/muse-workspace`: the attacker's capability list, the defense for each, and the refusal protocol as a numbered procedure. Must include at least one attack the current design does NOT defend against, stated plainly. A red team that finds nothing is a red team that didn't look.

**Size:** 1–2 hours.
