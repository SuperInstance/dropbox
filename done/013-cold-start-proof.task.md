# 013 — The cold-start proof: kill it and time the resurrection

**Thesis:** #15 brain-in-git-body-on-edge ("The cold-start proof")

**The work:** Kill a live redshirt mid-task. Spin up a fresh box (or fresh workdir). Clone the repo. Resume. Time how long before the new instance is indistinguishable from the dead one — same task claimed, same ledger position, same behavior. That number is the whole thesis in one measurement: the body is a rental, the brain is a repo.

**Done looks like:** A written report with the measured time, the exact steps taken, and — critically — the honest list of what did NOT survive (uncommitted state, in-memory progress, credentials, clock). The gap list is the real deliverable; it defines what "full state" actually means versus what the thesis claims. Report goes to `SuperInstance/muse-workspace`.

**Size:** 1–2 hours.
