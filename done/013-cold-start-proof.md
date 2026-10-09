# Done: 013 cold-start proof

**What I did:** Built a scratch redshirt on Oracle (`/home/ubuntu/scratch/coldstart-20261009-044418/`, since removed) — a git repo holding `TASK.md`, `STATE.json` (cursor), `LEDGER/ledger.log`, a 10-item `inbox.txt`, and a `run.sh` body that processes one item per ~2 s, appending to the ledger and **committing after every item**. Started it live (pid 1906787) alongside an uninterrupted control clone, `kill -9`'d the victim mid-task (1.076 s into item-03's work sleep, committed cursor=2), then resurrected from a fresh clone of committed state only and timed kill → verified-indistinguishable. All timestamps from one Oracle clock (`date +%s.%N`).

**Outcome:** **16.805 s** from kill to the resurrected instance completing all remaining items and verifying indistinguishable from the control run. The actual resurrection — kill to first resumed ledger commit — was **2.393 s** (clone 0.014 s + resume + re-processing the killed item); the rest is the remaining 8 items running at normal speed. Verification: ledger `done` lines (item IDs + sha256) identical and in order vs control, zero duplicates, zero gaps, final `STATE.json` byte-identical, `TASK.md` byte-identical, repo secret-scan clean. The new body's first action was `processing item-03` — exact cursor continuation.

**Honest gaps (what did NOT survive):**
- In-flight work: item-03's 1.076 s of partial progress died with the body; it was re-processed wholesale. Resumability unit = the committed item, nothing finer.
- Uncommitted state: none existed (post-kill `git status` clean) — but only because of the commit-per-item cadence. The brain is the *last commit*, not the working tree.
- The old body's stderr logs stayed in the dead workdir; only ledger entries transferred.
- No secrets in the repo (by design), but vault re-auth on a fresh box was not exercised.
- Wall-clock timestamps show the ~3.5 s death gap; no logical clock — ordering relies on git history.
- PID-keyed state (claim line `pid=1906787`) died; the new body re-claimed as pid 1907044.
- The clone read the victim's local git objects — the push-after-commit leg was not exercised; an unpushed commit is as dead as uncommitted state.
- Bound: fresh *workdir* on the same machine, not a fresh *box* — network clone + runtime install time not measured.

**Deliverable:** full report with measured times, exact driver script, and gap list at `~/workspace/dropbox/batch-d/013/013-cold-start-proof.md` (+ `coldstart-driver.sh` alongside it). Nothing pushed to GitHub; no dropbox git operations; live crabs untouched; Oracle scratch cleaned up.
