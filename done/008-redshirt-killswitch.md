# Done: 008 — Kill switch as first-class machinery

## What was done
The clock now lives outside the redshirt. `killswitch.sh` is new, started by
`install.sh` in its **own** process group (so it can never kill itself with
the poller):

1. The poller starts via `setsid` in its own process group (pgid recorded in
   `~/.redshirt/poller.pgid`; the wake daemon is the poller's child, so it
   shares the group).
2. The supervisor sleeps until `STARTED + HOURS*3600`, then SIGTERMs the
   poller's process group (polite path — the shirt's EXIT trap buries itself),
   waits 10s, and SIGKILLs the group if anything is still alive (the
   guarantee — SIGKILL can't be caught or ignored, even by a loop patched to
   never exit). Then it buries the node (`rm -rf ~/.redshirt`) in case the
   EXIT trap never ran, and disarms.
3. Revocation does not depend on the cooperation of the thing being revoked.
   `--no-killswitch` disables it, with a loud warning that the timebox is
   then just a promise again.

## Outcome
Committed and pushed to `SuperInstance/redshirt`:
- `c3d4c2f` — 008: killswitch.sh, `docs/killswitch.md`,
  `tests/demo-killswitch.sh`, plus the integration wiring for all four tasks
  into `redshirt.sh`/`install.sh`/README (lib.sh, merged with the sibling
  task-007 install-ceremony work: the ceremony page now shows the task scope).

Verified: `tests/demo-killswitch.sh` passes on both machines — a rogue shirt
that traps SIGTERM and ignores its timebox is SIGKILLed at the deadline and
the node directory is gone afterwards. Killswitch log captured in the test
output.

## Residual risk (documented honestly in `docs/killswitch.md`)
- **If the switch dies first, the promise is back.** One sleeping process:
  reboot, OOM-killer, or the installing user killing it all disarm it
  silently. Mitigated by `setsid` detachment; reboot persistence (`@reboot`
  re-arm from the on-disk config) is the obvious next step, not yet built.
- **Same-UID kill.** Supervisor and shirt run as the installing user, so a
  shirt that *escaped* the task sandbox could kill the supervisor before the
  deadline. The sandbox (001) is what makes that hard; the switch defends
  against a shirt that merely *ignores* its timebox, not a sandbox escape.
  A different-UID/root supervisor is documented as the hardening option.
- **Off-machine watchdogs can't SIGKILL** — they can only revoke git access
  and raise the alarm. Complementary, not a substitute.
- Cost: one sleeping process per node. Negligible.
