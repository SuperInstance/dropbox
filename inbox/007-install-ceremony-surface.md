# 007 — The install ceremony: show the grant

**Thesis:** #12 installation-is-permission ("The install ceremony")

**The work:** Installation IS the permission grant, but right now the installer says yes blind. SSH shows a fingerprint before the yes — what's the one-page equivalent for a redshirt? Build the pre-install surface: "this machine can reach X, can read Y, can spend Z — proceed?" It should enumerate the actual capabilities the redshirt will inherit (network, filesystem scope, credentials visible, spend authority) in plain language, then require an explicit witnessed yes.

**Done looks like:** `install.sh` in `SuperInstance/redshirt` prints the capability summary and pauses for confirmation before proceeding. The summary must be generated from the actual machine (not hardcoded) — probe what's reachable. One page, plain words, no jargon. The witnessed yes deserves a designed surface.

**Size:** 1–2 hours.
