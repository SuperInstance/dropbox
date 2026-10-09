# 002 — Wake the redshirt without reach

**Thesis:** #9 redshirt-disposable-appendage ("Wake without reach")

**The work:** The redshirt polls every 60 seconds — latency nobody needs, churn nobody wants. Keep the pull posture but kill the nap: add a tiny local trigger that says "something landed" without giving the cloud any path into the box. Candidates: a webhook the node subscribes to (outbound-only subscription), or a long-poll against the repo API. The shirt still fetches; it just stops napping between fetches.

**Done looks like:** A working trigger wired into `redshirt.sh` — task lands in the repo, shirt starts within ~5 seconds instead of ~60. Document which mechanism was chosen and why, plus the failure mode (what happens when the trigger channel dies — it must degrade back to polling, never to silence). Push to `SuperInstance/redshirt`.

**Size:** 1–2 hours.
