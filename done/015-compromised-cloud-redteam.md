# Done report — 015 compromised-cloud red team

**Task:** Red team the pull-to-sync design (thesis #13) under full cloud compromise. Deliverable: `REDTEAM-CLOUD.md` for `SuperInstance/muse-workspace`.

**What I did:**
- Cloned `SuperInstance/muse-workspace` fresh on Oracle (read-only use) and read the assigned docs in full: `ideas/pull-to-sync-not-push.md` (#13), `ideas/truthfulness-as-architecture.md` (#7), `ideas/agreements-all-the-way-down.md` (#1), `ideas/ledger-vs-log.md` (#3), `ideas/brain-in-git-body-on-edge.md` (#15), `ideas/redshirt-disposable-appendage.md` (#9), `ideas/clone-as-data-full-state.md` (#10), `ideas/clones-as-checkpoints.md` (#14), `ideas/GRAPH.md`, plus `conversations/PROTOCOL.md`, `fleet/PREFLIGHT.md`, `README.md`.
- Grounded the watermark claims in live state (read-only): `~/crabs/*/STATE.json` (`"cursor": 747` on heartbeat-01, 0 on the others) and `~/crabs/heartbeat-01/LEDGER/tokens.log` (`tok-… TALLY`, `wtok-… WATCHER GO cursor=…` formats). Nothing under `~/crabs/` modified.
- Wrote `~/workspace/dropbox/batch-d/015/REDTEAM-CLOUD.md` (~28 KB): 10-attack capability list (A1–A10), per-attack defence analysis with EXISTING vs PROPOSED honestly labelled, a 9-step numbered refusal protocol (marked PROPOSED — none exists in the design), a definition of "keep running" (headless mode + gates + never-do list), and the required undefended-attack section.
- Cleaned up the Oracle clone (`/tmp/redteam-*` removed).

**Outcome:** Delivered. Per the task's honesty rule ("a red team that finds nothing didn't look"), the document names defences that do NOT exist rather than inventing them. Key honest findings:
1. "The edge verifies signatures" — the defence thesis #13 leans on — is unspecified. Thesis #7 contains evidence tags for utterances, not a ledger signature scheme. No keys, algorithms, pinning, or revocation anywhere in the design.
2. The watermark/cursor genuinely is edge-local and unforgeable-by-cloud — the strongest real defence found.
3. Withholding/freeze is undetectable *as malice* by explicit design admission ("the cloud's absence is indistinguishable from a quiet ledger"); gates bound damage, not detection.

**Headline undefended attack (in its own section, §5): split-view equivocation.** A compromised cloud serves different ledgers to different edges; signatures wouldn't catch it (genuine entries, divergent views), cursors wouldn't catch it (each consistent within its view), thesis #3's fork-surfacing never fires (edges never compare views under pull-only), and no human sees the fork. Pull-only defeats command injection but is orthogonal to view injection. Also stated plainly: bootstrap poisoning (fresh edge trusts served history wholesale), git-write-as-command-authority for redshirts (the design's own admission — "git write access IS command authority, laundered through a markdown file"), and no key lifecycle at all.

**Honest gaps / what I did not do:**
- I did not verify every thesis file in the repo (16 theses; I read the 9 assigned plus GRAPH/PROTOCOL/PREFLIGHT/README). A signature or checkpoint scheme could theoretically be sketched in an unread thesis, but the assigned set is the complete dependency neighbourhood of #13 per GRAPH.md, so this is unlikely.
- The refusal protocol (§3) is my derivation from the design's primitives, not an adopted procedure — labelled PROPOSED throughout. Adopting it is a design decision for Casey.
- I did not push anything to GitHub and did not touch `~/workspace/dropbox` bookkeeping beyond writing the two deliverable files, per the hard rules.
