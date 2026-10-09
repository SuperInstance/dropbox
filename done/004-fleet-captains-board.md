# 004 — The captain's board: render the fleet — DONE

**Thesis:** #9 redshirt-disposable-appendage ("The captain's board")

## What was built

`fleet-board/` in `SuperInstance/muse-workspace` (commit `51f2811`):

- **`generate-board.py`** — clones (or takes a local path to) the redshirt
  repo, reads `heartbeat <name>` commits newest-first, parses each node's
  latest `tasks/<name>/heartbeat.md` (frontmatter: node, last, started,
  hours, task; tolerates the old plain `timestamp alive` format), and
  renders **`BOARD.md`**: node | current task | timebox remaining |
  heartbeat age | status (alive / stale / expired / no heartbeat).
- **`README.md`** — notes the 5-minute cron invocation.
- **`BOARD.md`** — the current board, committed alongside the generator.

## Verification

- **Synthetic test:** built a scratch repo with two fake heartbeat
  commits — one fresh node with rich frontmatter, one 40-minute-old
  legacy-format node. The board rendered `alpha | haul-nets | 4.0h |
  9s | alive` and `beta | unknown | unknown | 40m | stale`. Correct.
- **Real repo:** ran against `SuperInstance/redshirt` — the board
  truthfully reports the fleet is empty: **no heartbeat commits exist in
  the repo yet**. That is the true state, not a gap in the script; the
  moment a node beats, the next board run will show it.

## Honest gaps

- The board reflects repo state, so it lags reality by one poll/push
  cycle and by however stale the last heartbeat commit is. The `stale`
  threshold (default 15 min) is the honest signal for that.
- "Current task" comes from the heartbeat frontmatter the new poller
  writes; nodes installed before task 007's poller change only report
  `unknown` until they upgrade.
- The 5-minute regeneration cron is documented, not installed — wiring
  it up is one line in the README when Casey wants it live.
