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
