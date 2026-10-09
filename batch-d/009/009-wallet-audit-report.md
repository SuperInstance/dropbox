# Wallet audit report — SuperInstance/muse-workspace (task 009)

**Date:** 2026-10-09 (audit run on Oracle, ~04:43 UTC; 2026-10-08 20:43 AKDT)
**Auditor:** Muse (worker subagent, dropbox task 009)
**Method:** Fresh `gh repo clone SuperInstance/muse-workspace` to a scratch dir on
Oracle, treated as a public attacker artifact. Scanned the working tree **and**
the full git history (all refs), per the thesis: an attacker gets the history,
not just the checkout.
**HEAD audited:** `681021c` — "ideas: theses 9-16 (redshirt/clone architecture) + GRAPH.md for all 16"
**Scope:** 26 tracked files, 11 commits, single branch `main`, no tags, no stashes.
**Procedure:** `wallet-audit.sh` (companion file in this folder); re-runnable.

> **Status of this report:** written for publication to `SuperInstance/muse-workspace`
> per the task. Not pushed by the auditor — awaiting coordinator bookkeeping.

## Verdict: PASS

The binary standard is met: **nothing in the clone can spend money, read mail,
or impersonate the user.** The fix list is empty — there is nothing that must
move to the vault, because nothing secret-shaped with a live value exists in
the repo or its history. The brain is safe to publish.

## What was checked (all clean)

| Check | Result |
|---|---|
| Hard credential patterns across all 11 commits (`AKIA…`, `ghp_`/`github_pat_`/`gho_`, `xox[bap]-`, `BEGIN … PRIVATE KEY`, `sk_live_`, `sk-ant-`, `AIza…`, `ssh-rsa`/`ssh-ed25519 AAAA`, `BEGIN CERTIFICATE`) | **0 hits** |
| Secret-shaped filenames ever committed (`*secret*`, `*credential*`, `*token*`, `*.pem`, `*.key`, `.env*`, `*private*`) | **0 hits** |
| Files deleted in history (a removed secret still lives in history) | **none ever deleted** |
| URLs with embedded credentials (`https://user:pass@…`) | **0 hits** |
| High-entropy strings (≥32 alnum chars, heuristic token hunt) | all URL slugs and file paths — **0 tokens** |
| `.git/config` remote URLs | plain `https://github.com/SuperInstance/muse-workspace.git` — **no embedded userinfo** |
| Soft keyword sweep (`password`, `bearer`, `credential`, `client_secret`, `access_token`, …) | prose only — enumerated below |

## Classification of every credential-shaped finding

All of the following are **safe** — design prose *about* secrets, with no value
present. Each was read in context, not just pattern-matched.

| # | Location | Finding | Attacker use? | Classification |
|---|---|---|---|---|
| 1 | `ideas/brain-in-git-body-on-edge.md:25` | "In the vault (the wallet): OAuth tokens, API keys, the actual secrets. The brain holds the *names* of the secrets, never the secrets." | No — states the boundary; holds no value | **safe** (design prose) |
| 2 | `ideas/brain-in-git-body-on-edge.md:41` | "A secret in git is not an edge case, it is a bug — rotate it, grep the history." | No — policy statement | **safe** (design prose) |
| 3 | `ideas/brain-in-git-body-on-edge.md:66` | "The wallet audit" — the spec for this very test | No | **safe** |
| 4 | `ideas/redshirt-disposable-appendage.md:40` | Warns that in *redshirt* repos, a `run:` directive printing a secret would publish it | No value here — a warning about a different pattern | **safe** (see note A) |
| 5 | `ideas/redshirt-disposable-appendage.md:48` | "there is no separate auth step, no token ceremony" | No — prose | **safe** |
| 6 | `ideas/pull-to-sync-not-push.md:35` | "A credential revocation, a stop on a runaway loop" — argument for push immediacy | No value | **safe** |
| 7 | `ideas/installation-is-permission.md:15` | "You don't hand it a token." | No — prose | **safe** |
| 8 | `ideas/clone-as-data-full-state.md:31` | "A clone with the vault keys is a second captain with the same bridge codes." | No value — discusses the vault-keys edge | **safe** |
| 9 | `ideas/agent-as-pattern-not-server.md:67` | "The seed-vault problem. Credentials and secrets are the part of the pattern that cannot be cloned casually." | No value | **safe** |
| 10 | `README.md:19` | "No secrets, ever. No credentials, keys, tokens, private email content, or personal data. Those live in the vault/secure storage." | No — the repo's own law | **safe** |
| 11 | `README.md:7`, `fleet/PREFLIGHT.md:4`, `questions/memory/QUESTION.md:3`, `ideas/truthfulness-as-architecture.md:54` | "token cleanliness", "every token the model emitted" — LLM tokens, not auth tokens | No | **safe** |
| 12 | `.git/hooks/fsmonitor-watchman.sample:11–13` | "update token" — stock git sample-hook terminology | No | **safe** |
| 13 | `bin/decompose` | Python helper importing a local MiniMax chat helper (`~/workspace/skills/minimax/bin`); no keys in the repo — key material lives in the skill install, not here | No | **safe** |

**Needed-at-boot (must come from a vault, never the repo):** none found.
The design's boundary ("the brain holds the *names* of the secrets, never the
secrets") is honoured in practice — the repo currently holds not even names of
live secrets, only the concept.

## The attacker test, concretely

- **Spend money?** No payment keys, no cloud API keys, no Stripe keys, no
  provider credentials of any kind. Nothing to spend with.
- **Read mail?** No OAuth tokens, no mailbox passwords, no session cookies.
  Nothing to read with.
- **Impersonate the user?** No private keys, no identity documents, no session
  tokens. The prose mentions Casey by name (public design writing), which
  confers no authentication capability.

## Notes (not failures)

- **A.** The redshirt warning (finding 4) is load-bearing for *other* repos in
  the fleet: any repo whose automation executes committed directives must treat
  a printed secret as published. It is correctly absent here, but the
  `wallet-audit.sh` procedure is the reusable guard for those repos too.
- **B.** The newest commits (the theses 9–16 batch, `681021c` and `3b9ca1e`)
  were included in the history scan — all prose, all clean.

## Honest gaps

1. Pattern coverage is the common providers (AWS, GitHub, Slack, Stripe,
   Anthropic, Google, SSH). An exotic provider with an unusual token format
   could evade the regexes; the high-entropy heuristic plus human review is
   the backstop.
2. Cannot detect steganography, secrets split across lines, or values hidden
   in binary blobs (there are no binary blobs in this repo).
3. Only `main` exists today. If branches or tags are added, re-run
   `wallet-audit.sh` — it scans all refs the clone carries.
4. This audit proves the repo as cloned. It does not prove future commits stay
   clean. Recommendation: run `wallet-audit.sh` before any public flip, and
   consider a periodic run — the discipline is the boundary, the script is
   the check.

## Fix list

None. No rotation, no vault moves, no history rewrites required.
