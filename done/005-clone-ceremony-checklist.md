# Report: 005 — clone ceremony checklist

## What was done
Wrote `CLONE-CEREMONY.md` (one page, checkable boxes) and committed it to
SuperInstance/muse-workspace under a new `procedures/` directory. Then performed
the ceremony for real: cloned the Oracle crab `health-01` → `health-clone-01`
following **only** the v1 checklist, recorded every failure, and fixed the
checklist from the notes. The committed doc is v2.

## Rehearsal outcome
The v1 checklist produced a broken clone. The woken clone's `feed-and-watch.sh`
still hardcoded the parent's path and its `STATE.json` still named the parent —
so the "clone" fed the original's inbox and wrote into the original's ledger.
A twin phoning home, not Data. Eleven gaps found in total (W1–W11), including:
no quiescence check, no pre-freeze record, "committed AND uncommitted" assumes
git (the crab isn't a repo), no self-reference rewrite step, ambiguous ledger
tip (two ledger files), no "no credentials" path, no wake-verification step,
unspecified fork-announcement destination, and no ceremony receipt. All are
fixed in v2, which grew from 6 boxes to 9.

The rehearsal clone was removed afterwards; the original's crontab was restored
exactly (verified by diff). Two honest ledger lines remain on Oracle
(a `fork-announce` in tokens.log, one watcher line in watch.log) — append-only,
left as-is deliberately.

Full rehearsal notes: `~/workspace/dropbox-work/batch-c/005-rehearsal-notes.md`
(scratch, not committed).

## Links
- https://github.com/SuperInstance/muse-workspace/blob/main/procedures/CLONE-CEREMONY.md
- Commit: https://github.com/SuperInstance/muse-workspace/commit/1327eb953bf0563dd8e7c44d57919495cb6658c8
