# 001 — Scope the redshirt: narrower blinders

**Thesis:** #9 redshirt-disposable-appendage ("Narrower blinders")

**The work:** Today `redshirt.sh` runs with the whole shell as the installing user. Scope it down:
- One working directory the redshirt can touch; everything else read-only or invisible.
- An allowlisted command set (configurable per install, e.g. `git, curl, python3, claude`).
- No network access unless the task explicitly needs it (flag at install time).

**Done looks like:** `redshirt.sh` (or a wrapper) enforces the scope — a task that tries to `rm -rf ~` or `curl evil.com` fails loudly and the failure lands in the outbox. Document the worst case: "a compromised redshirt can only touch its own folder." Push the change to `SuperInstance/redshirt`.

**Size:** 1–2 hours.
