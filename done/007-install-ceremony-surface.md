# 007 — The install ceremony: show the grant — DONE

**Thesis:** #12 installation-is-permission ("The install ceremony")

## What was built

`install.sh` in `SuperInstance/redshirt` now opens with the install
ceremony instead of installing blind. Before anything is written or
started it probes the actual machine (all probes read-only, best-effort,
each wrapped so a failed probe reports "unknown" rather than guessing):

- **Network** — TCP reachability of `github.com:443`, fetchability of the
  installer source itself, DNS resolution, proxy env vars (names only),
  local and public IP.
- **Filesystem scope** — home dir writability, free space, whether running
  as root. The install itself only ever touches `~/.redshirt/`.
- **Credentials visible** — `~/.ssh` key filenames, secret-like env var
  *names* (values never printed), git identity, `gh` login state, `claude`
  CLI presence.
- **Spend authority** — AWS caller identity (if the CLI has working creds),
  gcloud/az sign-in state, paid API keys present in the environment (names
  only). Plus an honest caveat: absence of evidence is not evidence of
  absence — anything added to the machine later is inherited too.

The summary prints as one page in plain words, then the witnessed yes:
with a terminal, the installer must type the node name to proceed (a
wrong answer aborts, nothing installed); without a terminal the script
refuses unless `REDSHIRT_ASSUME_YES=1` is set — setting it is itself the
recorded grant. Every grant writes a receipt to
`~/.redshirt/grant-receipt.md` (timestamp, host, timebox).

Also in this push: `redshirt.sh` now writes `tasks/<name>/heartbeat.md`
with machine-readable frontmatter (node, last, started, hours, task) so
the captain's board (task 004) can compute timebox remaining; the README
documents the ceremony and the board.

## Verification

- `bash -n` clean on both scripts.
- Ceremony section dry-run locally: the page rendered correctly with real
  probe output (network, filesystem, credential names, spend).
- Pushed to `SuperInstance/redshirt` main as `86c371a`, `969ac06`,
  `44d7d96` (a mangled README append from shell backtick expansion was
  caught and repaired in the third commit — the lesson: ship text to
  Oracle as files via scp, never through nested shell quoting).

## Honest gaps

- No live install was performed end-to-end (starting a real node would
  have committed test heartbeats to the repo). The probes and the grant
  gate were exercised; the clone/poller path is unchanged from before.
- Spend detection is heuristic — cloud spend via browser sessions, billing
  accounts, or credentials added after install cannot be probed.
