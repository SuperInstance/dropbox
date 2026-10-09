# Dropbox

The minimal git agent harness. Git-backed, pull-based.

## Lifecycle

1. A task file lands in `inbox/`.
2. An agent picks it up, does the work.
3. The agent writes its report and moves the task to `done/`.
4. Repeat until `inbox/` is empty.

Like email: inbox → sent. Todos → done, with reports.

## Folders

- `inbox/` — todo. One file per task.
- `done/` — completed. Task file + report of what was done.
- `shared/` — files everyone needs (context, configs, etc.).

## Rules

- Nodes pull. Nobody pushes commands.
- A task is done when its report is in `done/`.
- The workspace is the source of truth.
