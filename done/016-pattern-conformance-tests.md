# Report: 016 — Pattern conformance: LAN instance vs cloud instance

**Status:** done. One real run completed, **OVERALL: PASS**.

## What was built

- `conformance/conformance.sh` — single-file conformance script. Two
  isolated instances (separate local clones of the dropbox repo at
  `/tmp/conformance/{lan,cloud}`; cloning is read-only, the real dropbox
  state was never touched) run the **identical** scripted sequence —
  claim → do → report → sync — parameterised only by `AGENT_MODE`.
  The cloud instance pushes to a bare repo on Oracle; the LAN clone has no
  remote configured at all, and a guard fails loudly if one ever appears.
- `conformance/CONFORMANCE.md` — the pattern definition, the pass/fail
  definitions (**frozen before the run**), the test design, the run record,
  the full difference list with verdicts, and the honest gaps.
- `conformance/fixtures/fixture-claim-001.md` — the synthetic fixture task
  (deterministic SHA-256 work, self-checked at report time).
- `conformance/logs/run-20261008-akdt.diff.log` — the full diff of the run.

All committed to `SuperInstance/muse-workspace` under `conformance/`:
commit `68b5e585e79014bfba7e823924acba72cd3c162f` (pushed to `main`).

## Outcome

Nine checks, all passing: masked reports byte-identical; artefacts
byte-identical (digest `b2571cce…bd87` in both); commit sequences identical
after normalisation; final tree file sets identical; no lost tasks
(inbox empty, claimed cleared, done/ holds report + task + artefact on both
sides); LAN airgap intact (no remote configured, zero LAN-authored commits
on the shared remote); cloud sync complete (remote tip == cloud tip
`3d55aa7…`); sync markers correct per mode.

The difference list, every entry classified:

| Difference | Verdict |
|---|---|
| Report `mode:` line and timestamps | Acceptable (pre-defined §2.1) |
| Commit hashes (differ via timestamps only) | Acceptable (pre-defined §2.1) |
| Sync entry: `DEFERRED_SYNC` (lan) vs `PUSHED` (cloud) | **Designed** (§2.2) — the test working as intended |
| Commit subject mode suffixes | Acceptable (normalised in check) |
| Sequence duration (0 s vs 3 s) | Acceptable (pre-defined §2.1) |

**Failure list: empty.** No divergent ledger entries, no lost tasks, no
phantom sync, no missing sync, no non-determinism, no silent deferral.
The LAN instance, refused its push, recorded an explicit `DEFERRED_SYNC`
marker with pending commits and resume instructions — the work is complete
locally and nothing is lost or falsely claimed as pushed.

## Honest gaps

No real LAN-only machine exists in this run — `AGENT_MODE=lan` refuses the
push in code (a stub, not an airgap); both instances shared one VM, clock,
and filesystem. Single fixture, single round: no concurrent-claim race, no
crash-mid-sequence, and the deferred-sync **rejoin** path (LAN regaining WAN
and pushing its deferred commits) is untested. Those three are the natural
follow-ups and each is a small extension of `conformance.sh`.
