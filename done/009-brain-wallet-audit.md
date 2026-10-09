# Done — 009 brain-wallet audit

**Task:** 009-brain-wallet-audit.md — prove the brain (SuperInstance/muse-workspace) is safe to publish.
**Outcome:** PASS. Binary standard met — nothing in the clone can spend money, read mail, or impersonate the user. Fix list: empty.

## What I did

1. **Fresh attacker-artifact clone on Oracle** (`gh repo clone SuperInstance/muse-workspace`
   via `~/workspace/ssh/osh.sh`, gh authed as SuperInstance). HEAD `681021c`,
   26 tracked files, 11 commits, single branch `main`. Read
   `ideas/brain-in-git-body-on-edge.md` and `README.md` to ground the audit in
   the design's own secret boundary ("the brain holds the *names* of the
   secrets, never the secrets"; README law: "No secrets, ever").
2. **Working-tree scan:** hard credential patterns (AWS, GitHub, Slack, Stripe,
   Anthropic, Google, SSH keys, certificates) — 0 hits; secret-shaped
   filenames — 0; soft keyword sweep — prose only.
3. **Full-history scan** (`git grep` across all 11 commits on all refs, not just
   the checkout): hard patterns — 0; secret-shaped filenames ever committed —
   0; files ever deleted — none; credentialed URLs — 0; high-entropy strings —
   all URL slugs/paths, 0 tokens; `.git/config` — clean https remote.
4. **Classified every credential-shaped finding** (13 items, all safe): design
   prose about the vault/secret boundary, LLM-"token" wording, a stock git
   sample hook, and `bin/decompose` (imports a local MiniMax helper; no keys
   in repo). None are live values; none are needed-at-boot.
5. **Wrote `wallet-audit.sh`** — a concrete, runnable bash procedure (takes a
   repo dir, scans tree + history, prints findings, exits 0 PASS / 1 FAIL with
   a classification guide). Tested logic against the real clone's result set.
6. **Wrote the audit report** `009-wallet-audit-report.md` (what was found,
   classification table, pass/fail, empty fix list, honest gaps).
7. **Cleaned up** `/tmp/wallet-audit-*` on Oracle — verified gone.

## Deliverables

- [009/wallet-audit.sh](sandbox://workspace/dropbox/batch-d/009/wallet-audit.sh) — reusable audit procedure (executable)
- [009/009-wallet-audit-report.md](sandbox://workspace/dropbox/batch-d/009/009-wallet-audit-report.md) — the audit report
- This file — the dropbox done report

## Notes for the coordinator

- The task says "The report goes to SuperInstance/muse-workspace." I did **not**
  push it (hard rule) — the report notes it is staged for publication pending
  coordinator bookkeeping.
- **Not pushed to GitHub by me:** nothing. No commits, no branches, no PRs.
- **One adjacent flag (not a failure):** `ideas/redshirt-disposable-appendage.md`
  warns that in redshirt-style repos a `run:` directive printing a secret
  publishes it — worth remembering when auditing the other fleet repos; the
  script is reusable for them.
- **Honest gaps:** pattern coverage is common providers (exotic formats could
  evade; entropy heuristic + human review is the backstop); cannot detect
  steganography or line-split secrets; only `main` exists today — re-run the
  script if branches/tags appear, and before any public flip.

## One correction made along the way

An early scan command's variable escaping failed and listed Oracle's home
directory instead of the clone (surfacing home-dir files like
`.canary-vault-token`). I caught it, re-ran with correct quoting against the
real clone, and **none of those home-dir files are part of this audit** — the
report covers the repo clone only.
