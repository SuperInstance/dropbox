# REDTEAM-CLOUD — the cloud is compromised

*Dropbox task 015. Thesis #13 next-thought #4: "The compromised-cloud red-team exercise: assume the attacker owns the cloud completely."*
*Written 2026-10-09 (UTC). Grounded in `SuperInstance/muse-workspace` design docs and the live Oracle system. Prose in en-GB; identifiers, paths, URLs, and filenames verbatim.*

## Assumptions (the threat model)

- The attacker has **complete read+write control of the cloud**: the ledger store, the git remotes the cloud hosts, anything served over the pull interface, and the cloud's half of every protocol. The attacker is not a passive eavesdropper; they are the publisher.
- The attacker does **not** control the edge devices, their local disks, their local keys, or their local state (cursors, clones, quarantine stores). Edge compromise is out of scope for this exercise.
- The interface is **ledger-only**: the cloud can append/serve ledger entries and git objects; it has no push channel, no inbound connection to the edge (thesis #13). The question is what a ledger-only attacker can still achieve.

## What the design actually says today (grounding)

Before the attack list, the honest baseline — what exists in the docs versus what the docs merely gesture at:

1. **"The edge verifies signatures" is an IOU, not a mechanism.** Thesis #13's red-team note says: *"Poison the ledger (answer: the edge verifies signatures, thesis #7's territory)."* I read thesis #7 (`truthfulness-as-architecture.md`) in full. It defines **utterance evidence tags** (`observed` / `inferred` / `delegated` / `unknown`) attested by the harness — a constraint on what the edge's *own model* may claim. It specifies **no signature scheme, no keys, no key distribution, no verification procedure, no algorithm, no revocation**. Thesis #1 (`agreements-all-the-way-down.md`) treats signature as a *social performative* (the fish ticket, PGP web-of-trust and Satoshi's chains cited as related work, not as adopted machinery). The closest thing to an integrity mechanism anywhere in the design is the judgement-log **triple-hash key** ("a hash binds what was said, by whom, and when", `ledger-vs-log.md`) — which binds *content*, not *authorship*: anyone, attacker included, can compute a hash. There is no key anywhere in the design whose compromise we can reason about, because no key is specified. **The defence the design leans on hardest does not exist yet.**
2. **The watermark lives on the edge.** Thesis #13: the edge asks for "everything since entry N", applies it, "advances its watermark"; sync is idempotent via "applied through entry N". Live on Oracle: each crab's `STATE.json` carries `"cursor": 747` (heartbeat-01; others at 0), and `LEDGER/tokens.log` records `wtok-… WATCHER GO cursor=746`. The cursor is local state, written by the edge, never by the cloud. This is the single strongest structural fact in the attacker's way.
3. **Silence is ambiguous by design.** Thesis #13, verbatim: *"The cloud's absence is indistinguishable from a quiet ledger."* And: *"An edge that never pulls is simply an edge the ledger outgrows."* Withholding is therefore not detectable *as malice* — only as staleness, via gates (thesis #2; thesis #13's "decompose-assumptions" connection: "policy not older than X", "control ledger within Y minutes").
4. **Disagreement is specified for peers, not for the cloud.** Thesis #3 (`ledger-vs-log.md`) handles two *agents'* ledgers disagreeing: surface the fork (CRDT-style), never silently pick a winner; if mechanism can't decide, the party that pays for failure decides. But the cloud is not a peer with a counterparty holding a copy — under pull-only, **edges never compare ledger views with each other**. There is no specified procedure for an edge that reads a cloud ledger entry it judges wrong. No refusal protocol exists in the docs. The orphan policy (thesis #13 next-thought #1) is unwritten.
5. **The repo is a command channel, and the design admits it.** Thesis #9 (`redshirt-disposable-appendage.md`), verbatim: *"Whoever can commit a task file to that inbox folder can run anything on that box — git write access IS command authority, laundered through a markdown file."* The `run:` directive executes arbitrary shell as the installing user. "The cloud never commands the node, true — but the repo does, and the repo is a public square with a guest list."

---

## 1. Attacker capability list

**A1. Read the entire ledger and its history.** Full visibility into tasks, policies, question-trees, coordination intents, staleness of every edge.

**A2. Append forged entries.** Fabricate control entries (policy changes, stop orders, task directives), backdated or current, in any name.

**A3. Reorder entries.** Present entries in an order different from the order they were committed.

**A4. Rewrite or delete history.** Serve a ledger whose past differs from what an edge previously read (history revision).

**A5. Replay old entries.** Re-present previously valid entries — e.g. a genuine stop-order from last month — as if new.

**A6. Forge the watermark forward (attempt).** Try to make the edge skip entries: serve a ledger that jumps from N to N+k, omitting entries, or claim "nothing since N" while appending elsewhere.

**A7. Withhold entries (freeze).** Serve a stale or empty "nothing new" response indefinitely; or serve new entries to the world while freezing one target edge at an old height.

**A8. Equivocate (split-view).** Serve ledger X to edge-1 and a different ledger Y to edge-2 — divergent histories, divergent "latest" entries, with neither edge able to tell.

**A9. Poison the bootstrap.** A new or wiped edge "starts with a watermark at genesis and pulls everything from the beginning" (thesis #13). Serve it a fabricated genesis-to-now history. The design's own recovery story — *"reimage, pull, resume"* — becomes the attacker's onboarding flow.

**A10. Poison the git layer beneath the ledger.** Where the ledger rides on git (inboxes, tasks, brains-in-git), push malicious commits: a `run:` task file in a redshirt inbox, a doctored policy file, a trojaned question-tree leaf. This is A2 wearing the repo's clothes.

---

## 2. Defence for each (EXISTING vs PROPOSED — labelled honestly)

**A1 — Read the ledger.** EXISTING, by design: the ledger is public-readable; the brain is publishable. Thesis #15: *"The brain holds the names of the secrets, never the secrets"*; README law: *"No secrets, ever"* in the repo. The defence is not secrecy but **secret placement** — the vault/wallet holds credentials; the ledger holds only names. An attacker reading the ledger learns structure and intent, never keys. (Residual: traffic analysis and intent-reading are accepted costs; the design names no countermeasure. PROPOSED: none in docs.)

**A2 — Append forged entries.** CLAIMED defence: "the edge verifies signatures". HONEST STATUS: **the verification mechanism does not exist** (see grounding §1 above). What *does* exist:
- EXISTING (weak): pull-only means a forged entry is inert data until the edge chooses to apply it — the edge, not the cloud, decides what becomes action (thesis #13). The harness evidence-tag regime (thesis #7) constrains the edge's own claims, not the cloud's appends.
- EXISTING (weak): staleness/urgency gates (thesis #2 via #13) bound *when* the edge must have fresh policy, but say nothing about *authenticity*.
- PROPOSED (not in design): per-entry cryptographic signatures; verification keys pinned on the edge at install/provisioning time (out of cloud reach); reject-on-bad-signature before the cursor advances. Until this is specified, A2 is defended only by the edge's discretion — which is to say, barely.

**A3 — Reorder entries.** EXISTING (partial): the ledger-vs-log ordering primitive ("who claimed it first", thesis #1) and triple-hash keys that bind an entry to its position in a sequence — but the hash scheme is described for the judgement log, and nothing in the pull protocol requires the edge to check positional binding. PROPOSED: hash-chained entries (each entry commits to the previous entry's hash); the edge verifies the chain from its cursor forward and refuses a pull whose chain does not continue its own last-verified hash.

**A4 — Rewrite/delete history.** EXISTING (partial): the edge keeps its own copy — local clone, applied entries, cursor at N. A rewrite contradicting already-applied history is *visible* to an edge that kept it, but the design specifies no check ("compare served history against local applied-history hash") and no response. PROPOSED: the edge retains a hash of the ledger prefix through its cursor and aborts the pull if the cloud's served prefix diverges — history revision becomes a hard verification failure, not a judgement call.

**A5 — Replay old entries.** EXISTING (partial): the cursor. The edge applies only entries past its watermark, and application is idempotent ("applied through entry N"), so a replay served at its *original* position is harmless. UNDEFENDED remainder: nothing binds an entry to its position, so a replayed entry re-sequenced as *new* (new position, same content/signature) is indistinguishable from a fresh entry. PROPOSED: signatures over (content + sequence + ledger-generation); the edge rejects any entry whose sequence number it has already consumed or that breaks the hash chain.

**A6 — Forge the watermark forward.** Largely a **non-attack as framed**, and the design gets this right: the cursor is edge-local state (`STATE.json`), never cloud-writable. The cloud cannot move it. What the attacker *can* do is adjacent: (a) serve a ledger with a **gap** — entries N+1..N+k omitted, presented as N+1..N+j — the edge advances its cursor over a hole it cannot see; (b) claim "nothing since N" while the true ledger advances (this is A7). Defence against (a): EXISTING none; PROPOSED: continuity proof — sequence numbers must be gapless from the cursor, hash-chained, else the pull is rejected as incomplete. Defence against (b): none possible by design admission (silence ≡ quiet ledger).

**A7 — Withhold (freeze).** EXISTING (detection of *staleness*, not of *attack*): gates — "control ledger within Y minutes" — let the edge bound how stale it may get before degrading risky behaviour (thesis #2/#13). The design is explicit that the edge **cannot distinguish** a compromised-freezing cloud from a quiet or unreachable one, and treats that as acceptable: headless operation is "a defined operating mode, not a crash" (thesis #15). So the defence is not detection but **graceful degradation** — the edge must be safe while arbitrarily stale. Whether it *is* safe while stale is a per-policy question the design leaves to gates. PROPOSED (not in design): out-of-band freshness beacons or cross-edge gossip to distinguish freeze from quiet — which would itself need a trust model the design does not have.

**A8 — Equivocate (split-view).** **NO DEFENCE EXISTS.** See §4 (headline finding).

**A9 — Poison the bootstrap.** **NO DEFENCE EXISTS.** A fresh edge has no local cursor, no applied-history hash, no pinned keys (none are specified) — nothing to check the served history against. Thesis #13: *"Bootstrap is the same loop, not a special case… the edge arrives, reads the ledger, and becomes current by its own effort."* Under a compromised cloud, "its own effort" ingests the attacker's history wholesale. The design's resilience story (survive your own cloud going down) assumes a *down* cloud, not a *lying* one. PROPOSED (not in design): genesis pinning — the edge ships with a pinned genesis hash and a pinned keyring installed out-of-band (thesis #12's "installation-is-permission" moment is the natural place: the human who runs the installer also plants the trust roots); bootstrap verifies the chain from the pinned genesis before applying anything.

**A10 — Poison the git layer.** EXISTING (admitted, undefended for redshirts): thesis #9 states plainly that git write access is command authority for `run:`-capable nodes. If the attacker controls the git remote the redshirt pulls from, A10 yields **arbitrary shell execution on the edge** — the "no command channel" guarantee fails exactly where the design confesses it: *"the repo does [command the node]"*. EXISTING (partial): thesis #12 — installation is permission, revoke by killing the node; thesis #9 next-thought #3 — "narrower blinders" (scope the shirt to one directory, allowlisted commands, no network) is PROPOSED, not implemented. PROPOSED: treat inbox task files as ledger entries subject to the same signature verification as §2/A2 (signed task files, edge-side allowlist, `run:` disabled or sandboxed by default); separate the *code/task* channel from the *data* channel so a ledger compromise does not imply a shell compromise.

---

## 3. The refusal protocol (numbered procedure)

STATUS: **PROPOSED.** No refusal protocol exists in the design docs. Thesis #13 asked for this exercise; the orphan policy is unwritten; thesis #3's fork-surfacing covers peer disagreement, not cloud-ledger verification failure. What follows is derived from the design's own primitives — cursor, pull-only, headless mode, gates, the party-that-pays-for-failure rule — with each step's grounding labelled.

Definitions first. A pull is **verified** iff, for every entry past the local cursor: (V1) its claimed author is entitled to append (PROPOSED: signature verifies against the edge-pinned keyring); (V2) its sequence continues the chain gaplessly from the cursor (PROPOSED: hash chain from last-verified hash); (V3) the served prefix through the cursor matches the edge's retained applied-history (PROPOSED: prefix hash); (V4) it parses under the entry schema the edge enforces. Today only V4 and part of V2 (cursor comparison) exist; V1 and the chain parts of V2/V3 are proposed because the design specifies no signature or hash-chain scheme.

**The procedure — what the edge does when the cloud's ledger fails verification:**

1. **Detect, per entry, before applying anything.** On each pull, fetch the candidate entries since the cursor into a scratch area. Verify V1–V4 in order. Classify the failure precisely: bad/unknown signature, chain break, sequence gap, prefix rewrite, schema violation, or semantic refusal (entry verifies cryptographically but violates a local gate — e.g. a policy entry the edge's gates reject). Record the classification; different failures imply different recovery, and "verification failed" without a reason is a log with delusions.
2. **Quarantine, do not apply.** Move the suspect entries to a local quarantine store — the edge's own log, never its ledger. Do not merge them into applied state, do not execute any directive they carry (especially `run:`-class task content — see A10), do not forward them to any other edge. Quarantine is a cell, not a waiting room.
3. **Freeze the cursor.** The watermark advances only over verified entries. If entry N+1 fails, the cursor stays at N — even if entries N+2..N+k verify. (PROPOSED: no skipping over a failed entry; a gap is itself a failure per V2. This is the precise point where "lie about what's new" dies: the attacker cannot smuggle entries past the cursor, because the cursor is edge-local and moves only on verification.)
4. **Commit the refusal locally.** Write a refusal entry to the edge's own ledger/log: what was pulled, which entries failed, which checks failed, the cursor value held, timestamp from the edge's own clock. The refusal is itself a signed, witnessed event — the witness chain (thesis #7) demands the disagreement be legible, not silent. A refusal nobody can audit is a shrug.
5. **Alert up the chain that exists.** The live system already has the shape: sentinel-01 is the watcher-of-watchers that raises unacked ESCALATEs, and the Oracle bridge (`check.py`) surfaces new escalations to the main chat. The edge raises an ESCALATE-class alert carrying the refusal record (step 4). PROPOSED wiring: define a `LEDGER-UNTRUSTED` escalation kind distinct from routine watcher traffic, with acknowledgement semantics — the alert is not cleared by the next successful pull, only by step 8.
6. **Enter degraded mode (defined below, §5).** The edge keeps running on its last verified state. It MAY keep pulling on its normal cadence — pulling is safe; *applying* is what verification gates — so continued pulling also serves as ongoing evidence collection (is the cloud still serving the bad entries? did the view change? — note any change for the split-view evidence file). It MUST NOT act on quarantined entries, MUST NOT advance the cursor past them, MUST NOT push quarantined content onward as its own claims.
7. **Bound the staleness.** The gates from thesis #2 now do their real work: "policy not older than X", "control ledger within Y minutes". As staleness grows past each gate, the edge sheds capability in the order its policy specifies — e.g. stop accepting new high-stakes tasks, then stop autonomous action entirely, while never stopping the heartbeat/ledger-keeping that proves it is alive and honest. The gate thresholds are the pre-committed answer to "how stale is too stale", made when the cloud was trusted.
8. **Recover only on out-of-band trust.** Trust is re-established by exactly one of: (a) the party that pays for failure (Casey) inspects the refusal record and signs a resume — human witness, per thesis #1's rule that the chain terminates in somebody present; (b) an independent, uncompromised source (a second cloud, a pinned snapshot, a peer edge's ledger view — all PROPOSED, none in the design) corroborates the cloud's current view and the edge verifies the chain from its frozen cursor to the corroborated head; (c) the cloud is replaced — new genesis pinned out-of-band (see A9), edge re-bootstraps against the new trust roots. What does NOT re-establish trust: the cloud subsequently serving "good-looking" entries — a compromised cloud can always behave for a while. On recovery, resume from the frozen cursor: re-pull, verify V1–V4, advance.
9. **Post-mortem as ledger entries.** Once recovered, the refusal record, the quarantine contents, the alert, and the recovery authorisation are committed as ordinary ledger entries (they are now history all parties can hold). The compromised interval stays in the record — superseded, never erased (thesis #14's rule: the broken branch stays in the ledger; the ledger stops standing on it).

What the edge does about an entry it **disagrees with semantically** (verifies fine, but the edge's judgement says no): the design's answer, honestly, is thesis #3's — surface the fork, don't fake agreement — plus thesis #13's — the edge decides what to apply. Concretely in this protocol: a semantic refusal follows steps 2–5 identically (quarantine, freeze, commit, alert), but the recovery condition differs: it needs a judgement the edge trusts (its own gates, a newer superseding entry, or the human), not a cryptographic fix. The design is silent on who adjudicates edge-vs-cloud semantic disagreement; per thesis #1, where mechanism can't decide, the party that pays for failure decides. Until that adjudication path is built, semantic refusal defaults to: don't apply, keep running, escalate.

---

## 4. "Keep running" without a trusted cloud — defined

"Keep running" is not a slogan; thesis #15 already defines the mode: *"The body keeps working on its last pull, and it keeps writing: turns go into the local clone as commits, queued. When the connection comes back, it pushes… Headless is a defined operating mode, not a crash."* Under a *distrusted* (not merely absent) cloud, the mode sharpens:

- **The local ledger continues.** The edge commits its own rounds, heartbeats, refusal records, and queued work to its local clone exactly as before. The ledger outlives the cloud's trustworthiness; thesis #3's petri-dish property ("the ledger outlives the agent") holds a fortiori for the cloud.
- **Cloud entries are quarantined, never applied-unverified.** Pulling may continue (evidence + liveness), but the cursor does not move and no cloud content becomes action.
- **Degraded behaviours, in gate order:** (i) routine work continues on last verified policy; (ii) as staleness crosses gates, shed high-stakes autonomy first; (iii) coordination intents (thesis #13's "I will be at X doing Y") are suspended — the edge will not rendezvous against a ledger it cannot trust, and will not publish intents into a ledger the attacker reads and can selectively deliver (A7/A8 make selective delivery invisible); (iv) the heartbeat/ledger-keeping never stops — an edge that goes quiet looks dead, and liveness evidence is what the human needs to adjudicate.
- **What the edge will NOT do:** execute instructions from unverified entries (the A10 rule — no `run:`, no policy application, no task acceptance); advance its watermark past unverified entries; treat prolonged cloud silence as consent or as recovery; delete or overwrite its local copy of the disputed history (that copy is the evidence); push quarantined cloud content onward signed as its own.
- **How trust is re-established:** only via step 8 above — human witness, independent corroboration, or cloud replacement. There is no automatic re-trust timer. A cloud that "starts behaving" is indistinguishable from a cloud laying a trap, and the protocol treats it as such.

---

## 5. Attack the current design does NOT defend against

### Headline: split-view equivocation — the cloud tells each edge a different story, and nothing in the design can catch it

**The attack, plainly.** The attacker owns the cloud and serves edge-1 a ledger in which policy P was revoked at entry 812, and edge-2 a ledger in which policy P is still in force at entry 812 — or serves both edges the same entry numbers with different contents, or advances one edge's view while freezing the other's (A7+A8 combined). Each edge pulls, sees a well-formed, gapless, internally consistent ledger, advances its own cursor, and acts. The edges now operate under contradictory instructions, each confident it is current. If the edges coordinate through the ledger (thesis #13's answer to multi-edge coordination — "an edge publishes its intent as a ledger entry; other edges read it"), the attacker can additionally deliver each edge a view of the *other* edge's intents that never existed. The fleet disagrees with itself and cannot know it.

**Why nothing in the design stops it.** Walk the defences:
- *Signatures* (thesis #1/#7): even the PROPOSED signature scheme would not help — the attacker serves genuinely-signed entries, just different sets to different edges. Signatures authenticate authorship, not uniqueness of view.
- *Watermarks/cursors*: each edge's cursor is consistent with the view it was served. The cursor detects gaps *within* a view, never divergence *between* views.
- *Thesis #3's fork-surfacing*: applies to two agents comparing ledgers as counterparties. Under pull-only, edges never exchange ledger views — there is no comparison step, no gossip, no cross-check. The counterparty mechanism the thesis depends on ("the other party is holding a copy and has already steered by it") has no instantiation between edges.
- *The human adjudicator* (the party that pays for failure): can only adjudicate a fork it can see. Nothing in the design surfaces "edge-1 and edge-2 hold divergent ledger heads" to anyone.

**What would be needed (PROPOSED, not in design):** a mechanism that binds the cloud to a single committed history — the classic answers are hash-chained entries plus periodic signed checkpoints (consistency proofs, in the Certificate Transparency shape: the cloud periodically publishes a signed tree head; edges gossip heads out-of-band or the edge rejects a head that doesn't extend the last head it accepted), or edge-to-edge gossip of ledger heads over a channel the cloud doesn't control. The design has none of these. Its coordination story *routes through the compromised party*, which is precisely the shape equivocation exploits.

**Do not soften this:** under the current design, a fully compromised cloud can partition the fleet's reality at will, indefinitely, with each edge's local verification passing green. The pull-only architecture — the design's great strength against *command* injection — is orthogonal to *view* injection. Pulling on your own schedule from a liar just means you get lied to on your own schedule.

### Also undefended, stated plainly

- **The signature scheme is vapour.** "The edge verifies signatures" is the load-bearing defence against ledger poisoning and it is unspecified: no algorithm, no keys, no distribution, no pinning, no rotation, no revocation. A red team cannot verify a defence that has no shape. Until specified, every defence downstream of signatures (A2, and the signature parts of A3–A5) should be read as PROPOSED.
- **Bootstrap poisoning (A9).** A fresh edge trusts the served genesis-to-now history completely. The design's recovery story is the attacker's onboarding flow.
- **Freeze attacks are undetectable as attacks (A7).** By explicit design admission, malice is indistinguishable from quiet. Gates bound the damage; nothing identifies the cause.
- **Git write access is command authority (A10).** For redshirt-class edges, the ledger-only interface still yields remote shell via inbox task files — the design confesses this itself. "No command channel into the edge" is true of the *cloud-to-edge* direction and false of the *repo-to-edge* direction, and the attacker owns the repo side.
- **Key rotation and revocation are unaddressed.** There is no key lifecycle in the design at all — which follows from the signature scheme being unspecified, but it deserves its own line: even once signatures exist, a compromised *signing* key (as opposed to a compromised cloud) has no defined recovery.

---

## 6. Sources

Design docs (all in `SuperInstance/muse-workspace`, read 2026-10-09 from a fresh Oracle clone):
- `ideas/pull-to-sync-not-push.md` (thesis #13) — pull-only sync, watermark mechanics, red-team next-thought #4, "the cloud's absence is indistinguishable from a quiet ledger"
- `ideas/truthfulness-as-architecture.md` (thesis #7) — evidence tags; read in full: contains no signature scheme
- `ideas/agreements-all-the-way-down.md` (thesis #1) — signature as performative; PGP/Satoshi as related work
- `ideas/ledger-vs-log.md` (thesis #3) — fork-surfacing, counterparty commitment, triple-hash keys
- `ideas/brain-in-git-body-on-edge.md` (thesis #15) — headless mode, vault/secret boundary
- `ideas/redshirt-disposable-appendage.md` (thesis #9) — "git write access IS command authority"
- `ideas/clone-as-data-full-state.md` (thesis #10), `ideas/clones-as-checkpoints.md` (thesis #14) — checkpoint/swap semantics, broken branch retained
- `ideas/GRAPH.md` — the sixteen theses as one machine
- `conversations/PROTOCOL.md`, `fleet/PREFLIGHT.md`, `README.md` — operating context

Live system (Oracle, read-only, 2026-10-09): `~/crabs/*/STATE.json` (`"cursor": 747` on heartbeat-01, 0 elsewhere), `~/crabs/heartbeat-01/LEDGER/tokens.log` (`tok-… TALLY`, `wtok-… WATCHER GO cursor=746` line formats), sentinel-01's unacked-ESCALATE watcher role. Nothing under `~/crabs/` was modified.

## 7. Open questions for the design (not attacks — work items)

1. Specify the entry signature scheme: algorithm, key generation, distribution, edge-side pinning, rotation, revocation. (Blocks A2's defence from PROPOSED to EXISTING.)
2. Specify entry hash-chaining and the edge's continuity/prefix checks. (Blocks A3–A6.)
3. Specify an equivocation-detection mechanism (signed checkpoints, head gossip, or an explicit decision that split-view is accepted risk). (Blocks A8.)
4. Specify genesis pinning / trust roots at install time. (Blocks A9.)
5. Specify the refusal protocol as an adopted procedure (this document's §3 is a draft, not a decision) and the `LEDGER-UNTRUSTED` escalation kind.
6. Decide the redshirt `run:` question: signed task files, sandboxing, or accept that repo-write = shell. (Blocks A10.)
