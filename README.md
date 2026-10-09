# Dropbox

Shared folder for the fleet. Git-backed, pull-based.

- `inbox/` — tasks for nodes to pick up. One file per task.
- `outbox/` — results from nodes. One file per result.
- `shared/` — files everyone needs (context, configs, etc.).

Nodes pull. Nobody pushes commands. The workspace is the source of truth.
