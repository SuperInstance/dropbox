# Cold-start proof: kill it and time the resurrection

**Dropbox task 013 · executed 2026-10-08 (AKDT) on Oracle (ubuntu@147.224.38.131) · scratch area only, live crabs untouched**

Thesis under test: #15, *brain-in-git-body-on-edge* — "the body is a rental, the brain is a repo."

## The headline number

**16.805 seconds** — measured from `kill -9` of the live body to the resurrected instance having completed every remaining work item and been verified indistinguishable from the dead one.

Decomposition of the 16.805 s (all timestamps `date +%s.%N` on Oracle, one clock):

| Segment | Duration |
|---|---|
| kill → post-kill audit done (`git status`, `git log`) | 0.315 s |
| fresh `git clone` of committed state only (same-disk) | 0.014 s |
| clone → resume start | 0.004 s |
| resume start → first resumed ledger commit (item-03) | 2.061 s |
| first resumed commit → all remaining items done | 14.412 s |
| **kill → indistinguishable (headline)** | **16.805 s** |

The sub-number that matters most for the thesis: **kill → first resumed ledger commit = 2.393 s**. That is the moment the new body provably continued the same ledger from the same cursor — everything after it is just the remaining work running at normal speed (8 items × ~2 s, including the re-processing of the killed item).

## What was built

A scratch redshirt at `/home/ubuntu/scratch/coldstart-20261009-044418/repo/` — a git repo (the "brain") containing:

- `TASK.md` — task `coldstart-proof-013`, claim rule, resume policy
- `STATE.json` — `{"task_id":"coldstart-proof-013","cursor":0,"debts":[],...}` (`cursor` = completed items = index of next item)
- `LEDGER/ledger.log` — append-only; one `claim` line at start, one `done <id> hash=<sha256> ts=<ns>` line per item
- `inbox.txt` — 10 deterministic items (`item-01` … `item-10`)
- `run.sh` — the "body": claims the task, then loops: read `cursor`, do a 2-second unit of work, append the ledger line, advance `cursor`, **commit**. Never skips, never duplicates; on start it reads `cursor` from `STATE.json` and continues.

The commit-after-every-item cadence is the whole resumability mechanism: the ledger position that survives death is exactly the last commit.

## The kill

- Victim (`run.sh`, pid **1906787**) started in `repo/` at `1791521199.152903`.
- An uninterrupted control run (pid 1906785, separate clone `control-run/`) started simultaneously as the baseline.
- Driver waited until the victim's ledger showed `done item-02`, slept 1.0 s, then at **`1791521204.331371`** issued `kill -9 1906787`. Death confirmed (`kill -0` failed).
- The kill landed **1.076 s into item-03's 2-second sleep** — genuinely mid-task. Victim log tail: `processing item-03`, no commit after it. Committed state at death: `cursor=2`, ledger = claim + `done item-01` + `done item-02`.

## The resurrection

1. Post-kill audit of the corpse: `git status --porcelain` → **empty** (clean worktree — nothing uncommitted left behind).
2. `git clone /home/ubuntu/scratch/coldstart-20261009-044418/repo /home/ubuntu/scratch/coldstart-20261009-044418/resurrect` — committed state only; the old workdir's memory, logs and PIDs were not copied and could not be.
3. Started `run.sh` in the fresh clone (pid **1907044**) at `1791521204.663550`.
4. Its **first action was `processing item-03`** — it continued exactly from the committed `cursor=2`. First resumed ledger commit at `1791521206.724477` (2.393 s after the kill).
5. It completed all remaining items at `1791521221.136184`. (Control finished 9 ms later — both did the full 10 items at the same per-item pace.)

## Verification (indistinguishability, concretely)

Compared the resurrected run against the uninterrupted control run:

- `done` ledger lines (item IDs + sha256 hashes, timestamps stripped): **identical, in order** (`diff` exit 0)
- Duplicate `done` lines in the resurrected ledger: **0** — no item double-processed
- Missing items: **none** — `item-01` … `item-10` all present exactly once
- Final `STATE.json`: **byte-identical** between control and resurrected (`cursor=10` both)
- `TASK.md`: **byte-identical**
- Claim lines (expected to differ): victim's `claim … pid=1906787` survives in the cloned history; the new body's `claim … pid=1907044` follows it. Same task claimed, new body holding it.
- Secret scan of the repo (`token|secret|password|api[_-]?key`, excluding `.git`): **clean**

The one visible scar of the death, exactly as the design doc predicts: the ledger's `ts=` sequence shows a ~3.5 s gap between the victim's last commit and the new body's first — the ledger records when the heart stopped.

## The gap list — what did NOT survive (the real deliverable)

1. **In-memory progress.** Item-03 was 1.076 s into its 2 s unit of work when the body died. That partial work was destroyed outright — there was no partial result to salvage, because results are only recorded after the work completes. The new body re-processed item-03 wholesale (one extra ~2 s unit, inside the measured 16.805 s). No loss, no duplication — but the resumability unit is the *item*, and anything finer-grained than a committed item does not exist to the new body.
2. **Uncommitted state.** None existed to lose: post-kill `git status` was clean. This is a property of the commit-after-every-item cadence, not of git magic. Anything the body had not committed — staged or not — would have died with the workdir, invisible to the clone. The honest formulation: *the brain is the last commit, not the working tree.*
3. **The old body's logs.** `victim.log` (stderr, per-item timings) stayed in the dead workdir. Only committed ledger entries transferred. A fresh box cannot interrogate how the old body died beyond what the ledger shows.
4. **Credentials.** There were none in the repo (verified by scan) — by design, the brain holds no secrets. But re-establishing vault/secret access on a truly fresh box was **not exercised** in this test; it is a required step the measurement does not include.
5. **Clock continuity.** Commit timestamps and ledger `ts=` values are wall-clock; they differ between runs and show the death gap. There is no logical clock — ordering across the death relies on git history order, not on timestamps.
6. **PID/host-keyed state.** The claim line (`host=ok pid=1906787`) died with the body; the new body re-claimed as pid 1907044. Anything addressed to the old PID — signals, locks, temp files keyed on PID — would be orphaned.
7. **Unpushed commits.** The resurrection clone read the victim's *local* git objects. In a real deployment the body must push after every commit (the design doc's metabolism: "pull before each work cycle, push after each commit") — an unpushed commit is as dead as uncommitted state. The push leg was not exercised.
8. **Methodological bound.** This was a fresh *workdir*, not a fresh *box*: same machine, same-disk clone (0.014 s). A true fresh box adds network clone time and runtime installation (git, jq, bash) — none of that is in the 16.805 s. Treat the clone segment as a lower bound.

## What this defines

"Full state", as measured: **the last commit** — task file, cursor, ledger, inbox. Everything else (in-flight work, logs, PIDs, wall-clock continuity, secrets, the push) is body, and the body is rental. The thesis holds for the brain as defined; the gap list above is the precise boundary of that definition.

## Exact steps (the driver script)

The experiment was executed by a single driver script on Oracle (also saved alongside this report as `coldstart-driver.sh`). Verbatim:

```bash
#!/bin/bash
# Cold-start proof driver — runs ON Oracle.
# Builds a scratch redshirt repo, runs it, kill -9s it mid-task,
# resurrects from a fresh clone of committed state only, times everything,
# and verifies the resurrected run against an uninterrupted control run.
set -u
D=/home/ubuntu/scratch/coldstart-20261009-044418
mkdir -p "$D"; cd "$D"

# ---------- 1. build the redshirt repo (the "brain") ----------
git init -q -b main repo
cd repo
git config user.name redshirt
git config user.email redshirt@scratch.local

cat > TASK.md <<'EOF1'
# TASK coldstart-proof-013

Task ID: coldstart-proof-013
Claim rule: the body whose `claim` line is newest in LEDGER/ledger.log owns it.
Work: process every item in inbox.txt in order. For each item: perform the
2-second unit of work, append a `done` line to LEDGER/ledger.log, advance
`cursor` in STATE.json, commit. Never skip an item, never process one twice.
Resume policy: on start, read `cursor` from STATE.json and continue from there.
The repo is the whole brain: a fresh clone must be able to resume from
committed state alone.
EOF1

cat > STATE.json <<'EOF1'
{"task_id":"coldstart-proof-013","cursor":0,"debts":[],"note":"cursor = completed items = index of next item"}
EOF1

mkdir -p LEDGER
touch LEDGER/ledger.log

: > inbox.txt
for i in $(seq -w 1 10); do
  echo "item-$i: deterministic payload for unit of work number $i" >> inbox.txt
done

cat > run.sh <<'RUNEOF'
#!/bin/bash
# Redshirt body: reads the brain (repo), does the work, commits after every item.
set -uo pipefail
cd "$(dirname "$0")"
HOST=$(hostname); PID=$$
log(){ echo "[$(date +%s.%N) $HOST:$PID] $*" >&2; }
TASK_ID=$(jq -r .task_id STATE.json)
echo "claim task=$TASK_ID host=$HOST pid=$PID ts=$(date +%s.%N)" >> LEDGER/ledger.log
git add LEDGER/ledger.log >/dev/null 2>&1 && git commit -qm "claim $HOST:$PID" || true
log "claimed $TASK_ID"
CURSOR=$(jq -r .cursor STATE.json)
TOTAL=$(grep -c . inbox.txt)
while [ "$CURSOR" -lt "$TOTAL" ]; do
  LINE=$(sed -n "$((CURSOR+1))p" inbox.txt)
  ID=${LINE%%:*}; PAYLOAD=${LINE#*: }
  log "processing $ID"
  sleep 2  # <-- the unit of work; the kill -9 lands inside this sleep
  HASH=$(printf '%s' "$PAYLOAD" | sha256sum | cut -d' ' -f1)
  echo "done $ID hash=$HASH ts=$(date +%s.%N)" >> LEDGER/ledger.log
  CURSOR=$((CURSOR+1))
  jq --argjson c "$CURSOR" '.cursor=$c' STATE.json > STATE.json.tmp && mv STATE.json.tmp STATE.json
  git add LEDGER/ledger.log STATE.json >/dev/null 2>&1 && git commit -qm "item $ID cursor=$CURSOR" || true
  log "committed $ID cursor=$CURSOR"
done
log "COMPLETE cursor=$CURSOR"
RUNEOF
chmod +x run.sh

git add -A && git commit -qm "genesis: cold-start proof task"
cd "$D"

# ---------- 2. control clone (the run that never dies) ----------
git clone -q repo control-run

T0=$(date +%s.%N)
( cd "$D/control-run"; nohup ./run.sh > "$D/control.log" 2>&1 & echo $! > "$D/control.pid" )
( cd "$D/repo"; nohup ./run.sh > "$D/victim.log" 2>&1 & echo $! > "$D/victim.pid" )
sleep 0.5
CPID=$(cat "$D/control.pid"); VPID=$(cat "$D/victim.pid")
[ -n "$CPID" ] && [ -n "$VPID" ] || { echo "FAIL: pid capture failed"; exit 1; }
kill -0 $CPID 2>/dev/null || { echo "FAIL: control not running"; exit 1; }
kill -0 $VPID 2>/dev/null || { echo "FAIL: victim not running"; exit 1; }
echo "victim_pid=$VPID control_pid=$CPID start=$T0" > PIDS.txt

# ---------- 4. wait until the victim is mid-task, then kill -9 ----------
# item-01 done ~t+2.5s, item-02 done ~t+4.8s; kill 1s later => inside item-03's sleep
for i in $(seq 1 300); do
  grep -q '^done item-02 ' repo/LEDGER/ledger.log 2>/dev/null && break
  sleep 0.1
done
grep -q '^done item-02 ' repo/LEDGER/ledger.log || { echo "FAIL: victim never reached item-02"; exit 1; }
sleep 1.0
T_KILL=$(date +%s.%N)
kill -9 $VPID
sleep 0.3
if kill -0 $VPID 2>/dev/null; then echo "FAIL: victim still alive after kill -9"; exit 1; fi
echo "kill_issued=$T_KILL victim_dead_confirmed=yes" >> PIDS.txt
# what did the corpse leave behind? (uncommitted state audit)
(cd repo && git status --porcelain > ../victim-postkill-status.txt; git log --oneline -6 > ../victim-postkill-log.txt; git rev-parse HEAD > ../victim-postkill-head.txt)

# ---------- 5. resurrect: fresh clone, committed state ONLY ----------
T_CLONE0=$(date +%s.%N)
git clone -q repo resurrect
T_CLONE1=$(date +%s.%N)

# ---------- 6. resume the run in the fresh clone ----------
T_RES0=$(date +%s.%N)
( cd "$D/resurrect"; nohup ./run.sh > "$D/resurrect.log" 2>&1 & echo $! > "$D/resurrect.pid" )
sleep 0.5
RPID=$(cat "$D/resurrect.pid")
[ -n "$RPID" ] || { echo "FAIL: resurrect pid capture failed"; exit 1; }
kill -0 $RPID 2>/dev/null || { echo "FAIL: resurrect not running"; exit 1; }

for i in $(seq 1 600); do
  grep -q 'COMPLETE' resurrect.log 2>/dev/null && break
  sleep 0.2
done
T_DONE=$(date +%s.%N)
grep -q 'COMPLETE' resurrect.log || { echo "FAIL: resurrect never completed"; exit 1; }

for i in $(seq 1 600); do
  grep -q 'COMPLETE' control.log 2>/dev/null && break
  sleep 0.2
done
T_CTRL=$(date +%s.%N)
grep -q 'COMPLETE' control.log || { echo "FAIL: control never completed"; exit 1; }

# ---------- 7. verification ----------
strip_ts(){ sed -E 's/ ts=[0-9.]+//'; }
: > VERIFY.txt
diff <(grep '^done ' control-run/LEDGER/ledger.log | strip_ts) \
     <(grep '^done ' resurrect/LEDGER/ledger.log | strip_ts) > done-diff.txt
echo "done_lines_diff_exit=$? (0 means identical item/hash sequence)" >> VERIFY.txt
grep '^done ' resurrect/LEDGER/ledger.log | awk '{print $2}' | sort | uniq -d > dups.txt
echo "duplicate_done_lines=$(wc -l < dups.txt)" >> VERIFY.txt
diff control-run/STATE.json resurrect/STATE.json > state-diff.txt
echo "state_json_diff_exit=$? (0 means identical)" >> VERIFY.txt
diff control-run/TASK.md resurrect/TASK.md > task-diff.txt
echo "task_md_diff_exit=$? (0 means identical)" >> VERIFY.txt
echo "resurrect_first_item=$(grep -m1 'processing' resurrect.log | grep -o 'item-[0-9]*')" >> VERIFY.txt
echo "resurrect_done_count=$(grep -c '^done ' resurrect/LEDGER/ledger.log)" >> VERIFY.txt
echo "control_done_count=$(grep -c '^done ' control-run/LEDGER/ledger.log)" >> VERIFY.txt
grep -riE 'token|secret|password|api[_-]?key' repo --exclude-dir=.git > secret-scan.txt \
  && echo "secret_scan_hits=$(wc -l < secret-scan.txt)" >> VERIFY.txt \
  || echo "secret_scan_clean=yes" >> VERIFY.txt
FIRST_COMMIT_TS=$(grep -m1 'committed item-03' resurrect.log | sed -E 's/^\[([0-9.]+).*/\1/')
FIRST_PROC_TS=$(grep -m1 'processing item-03' resurrect.log | sed -E 's/^\[([0-9.]+).*/\1/')

cat > TIMINGS.txt <<EOF2
victim_start=$T0
kill=$T_KILL
clone_start=$T_CLONE0
clone_done=$T_CLONE1
resume_start=$T_RES0
first_resumed_processing_item03=$FIRST_PROC_TS
first_resumed_commit_item03=$FIRST_COMMIT_TS
resurrect_complete=$T_DONE
control_complete=$T_CTRL
victim_pid=$VPID
resurrect_pid=$RPID
control_pid=$CPID
EOF2
echo "DRIVER DONE"
```

Raw timestamps (Oracle clock, `date +%s.%N`): kill `1791521204.331370549`, first resumed commit `1791521206.724477186`, resurrected run complete `1791521221.136183978`, control complete `1791521221.145509076`.

## Notes on the run itself

- The first attempt at the driver had a shell grouping bug (`&` vs `&&` precedence wrote pid files to the wrong directory); it was caught by the driver's own pid-capture guard before any kill, all stray processes were killed, the scratch area was wiped, and the experiment re-ran clean. No live crabs were touched at any point.
- Scratch area `/home/ubuntu/scratch/coldstart-20261009-044418/` on Oracle was removed after the run, per instructions.

---
*The body is a rental. The brain is a repo. Measured: 16.805 s from bullet to indistinguishable — 2.393 s of which is the actual resurrection, the rest is the remaining work running at normal speed.*
