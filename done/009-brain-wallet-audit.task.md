# 009 — The wallet audit: prove the brain is safe to publish

**Thesis:** #15 brain-in-git-body-on-edge ("The wallet audit")

**The work:** The brain lives in git; git is public by default. Formalize the secret boundary as a test: clone the brain repo to a fresh public fork (or a scratch dir treated as public), then attempt — as an attacker with only that clone — to spend money, read mail, or impersonate the user. Enumerate every credential-shaped thing found in the clone and classify each: needed-at-boot (must come from a vault, never the repo) vs safe. If the test passes, the brain is safe to publish. If it fails, the failures are the fix list.

**Done looks like:** A `wallet-audit.sh` (or documented manual procedure) plus a written report: what was found, what was classified, what failed. The report goes to `SuperInstance/muse-workspace`. The standard is binary: either nothing in the clone can spend/read/impersonate, or the audit lists exactly what must move to the vault. No "probably fine."

**Size:** 1–2 hours.
