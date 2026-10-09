# Done: 001 — Scope the redshirt (narrower blinders)

## What was done
`sandbox.sh` is new: every task command now runs inside a layered sandbox,
wired into the rewritten `redshirt.sh` (both `run:` and `claude:` paths).

- **One writable directory.** The task runs with cwd/`HOME`/`TMPDIR` inside
  its own task dir, so `~` never means the installer's home. On kernels with
  unprivileged user namespaces a mount namespace additionally remounts
  everything read-only except that directory.
- **Allowlisted command set.** The task sees a shim `PATH` with symlinks only
  to allowlisted commands (configurable per install via
  `--allowlist "git curl python3"`, default `git curl python3 claude`; `sh`
  always present since the harness runs `run:` lines through it). Anything
  else fails with "command not found" (exit 127), and the failure lands in
  the outbox result file.
- **No network unless flagged.** Default `--no-net`: with namespaces the task
  gets a network namespace (loopback only); without them `curl`/`wget`/`ssh`/
  `scp`/`nc` resolve to stubs that exit 126 with "network access is DISABLED".
  `--net` at install time allows it.
- The active layer stack is announced on stderr for every task and captured
  into the outbox result (`shim+env+mountns+netns` vs degraded `shim+env`).

The installer shows the chosen scope on the install-ceremony page, and the
config records `ALLOWLIST`/`NET_OK`.

## Outcome
Committed and pushed to `SuperInstance/redshirt`:
- `e5a5d27` — 001: sandbox.sh, `docs/sandbox.md`, `tests/test-sandbox.sh`
- `c3d4c2f` — 008 (integration commit): wires the sandbox into
  `redshirt.sh`/`install.sh`/README alongside the other three tasks.

Verified: `tests/test-sandbox.sh` 8/8 on a userns-capable kernel
(`rm -rf ~` refused, `curl` stubbed with `NET_OK=0`, real curl works with
`--net`, `/etc` read-only in ns mode, python sockets blocked by netns);
6/6 + 1 self-skip on Oracle (namespaces blocked there — degraded `shim+env`
mode still enforces the allowlist and network stubs). Full-loop
`tests/test-poller-e2e.sh` 7/7 on both machines, including hostile tasks
whose failures land in the outbox.

## Worst case (documented in `docs/sandbox.md`)
A compromised redshirt task can only touch its own task folder — on a
userns-capable kernel.

## Honest gaps
- **Degraded mode (e.g. Oracle):** without namespaces the sandbox cannot stop
  an allowlisted interpreter writing to world-writable paths
  (`python3 -c 'open("/tmp/x","w")'` succeeds). Stated in the docs and
  announced loudly at runtime; full containment needs a userns-capable kernel.
- The sibling task-007 install-ceremony work landed first; this change merges
  with it (ceremony page now shows the task scope) rather than replacing it.
