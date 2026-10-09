# 008 — Kill switch as first-class machinery

**Thesis:** #12 installation-is-permission ("The kill switch as first-class")

**The work:** The timebox is currently a promise the redshirt keeps — which means a compromised redshirt can break the promise. Move the clock outside the redshirt: a dead-man's switch held by the installer. Simplest form wins — candidates: a process supervisor on the installing machine, a wrapper that SIGKILLs past the deadline regardless of what the shirt is doing, or a remote (off-machine) watchdog. Revocation must not depend on the cooperation of the thing being revoked.

**Done looks like:** A redshirt that ignores its own timebox (simulate by patching the loop to never exit) still gets killed at the deadline by the external switch. Demonstrate the kill, document the mechanism, commit to `SuperInstance/redshirt`. Note the residual risk honestly: what the switch itself costs and what happens if the switch dies first.

**Size:** 1–2 hours.
