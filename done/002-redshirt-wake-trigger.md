# Done: 002 — Wake the redshirt without reach

## What was done
`wake.sh` is new: an outbound-only wake trigger, started by `redshirt.sh` as
a child (same process group, so the killswitch reaps it too).

- **Mechanism chosen:** ETag conditional long-poll of the repo's commits API
  (`GET /repos/<owner>/<repo>/commits?path=tasks/<name>/inbox&per_page=1`,
  every 5s). Pure client-initiated HTTPS — no inbound port, no webhook
  receiver, no new path from the cloud into the box. GitHub offers no true
  server-push for repo content, and a relay would violate the no-inbound-path
  constraint, so conditional polling it is.
- On a 200 (inbox path changed) the daemon touches `$WORKDIR/.wake`; the
  poller's sleep loop notices within ~2s and starts the cycle immediately.
  Task lands → shirt starts within **~5s** instead of ~60s.
- **Rate-limit safe:** 304 responses to conditional requests don't count
  against the GitHub API limit, so 5s polling is sustainable unauthenticated.
  `GITHUB_TOKEN` is honoured for private repos.
- **Failure mode:** API unreachable → log, retry every 5s; after 12
  consecutive failures back off to 60s between attempts while the poller keeps
  its plain 60s cycle. If the daemon itself dies, the poller simply never sees
  `.wake` and sleeps the full interval. **Degrades to polling, never to
  silence.** Disable with `--no-wake`.

## Outcome
Committed and pushed to `SuperInstance/redshirt`:
- `adff388` — 002: wake.sh, `docs/wake-trigger.md`, `tests/test-wake.sh`
- `c3d4c2f` — 008 (integration commit): wires the trigger into
  `redshirt.sh`/`install.sh`/README.

Verified: `tests/test-wake.sh` 5/5 against a mock commits API (quiet on 304s,
fires within ~7s of a simulated inbox change, survives the API dying and logs
the degradation) on both the local VM and Oracle.

## Honest gaps
- **Not yet proven against the live GitHub API.** The daemon logic is tested
  against a mock with real ETag semantics; the first live run against
  api.github.com will be the true proof (latency, 304 behaviour, path-filter
  correctness). The `WAKE_API_URL` override exists precisely for this kind of
  testing.
- Wake latency assumes the commits API reflects a push within a few seconds;
  GitHub-side indexing delay could add a little.
