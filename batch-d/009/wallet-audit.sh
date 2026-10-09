#!/usr/bin/env bash
# wallet-audit.sh — the brain-wallet audit (dropbox task 009, thesis #15
# "brain-in-git-body-on-edge", next-thought #4).
#
# Formalises the secret boundary as a test: given a repo directory treated as
# a PUBLIC attacker artifact (full git history included), enumerate every
# credential-shaped thing and classify it.
#
# Standard (binary): either nothing in the clone can spend money, read mail,
# or impersonate the user — or the audit lists exactly what must move to the
# vault. No "probably fine."
#
# Usage:
#   wallet-audit.sh <repo-dir>
#
# Exit 0: PASS — nothing found that could spend / read / impersonate.
# Exit 1: FAIL — findings above; the failures are the fix list.
#
# Notes:
# - Run against a FRESH clone treated as public, never against a live working
#   repo with local untracked files (untracked files are not in a clone).
# - Scans all refs the clone carries, not just the checked-out branch:
#   an attacker gets the whole history.

set -u
FAIL=0

if [ $# -ne 1 ]; then
  echo "usage: $0 <repo-dir>" >&2
  exit 2
fi
REPO="$1"
if [ ! -d "$REPO/.git" ]; then
  echo "FAIL: $REPO is not a git working tree" >&2
  exit 2
fi
cd "$REPO" || exit 2

REVS="$(git rev-list --all)"
NCOMMITS="$(echo "$REVS" | wc -l)"
HEAD_SHA="$(git rev-parse --short HEAD)"
echo "=== wallet-audit ==="
echo "repo:      $REPO"
echo "head:      $HEAD_SHA ($(git log -1 --format='%ad %s' --date=short))"
echo "commits:   $NCOMMITS across refs: $(git for-each-ref --format='%(refname:short)' | tr '\n' ' ')"
echo "tracked:   $(git ls-files | wc -l) files"
echo

section() { echo; echo "### $1"; }

# 1. Suspicious filenames — ever committed, on any ref
section "1. secret-shaped filenames in history"
SECRET_FILES="$(git log --all --diff-filter=A --name-only --pretty=format: | sort -u \
  | grep -iE 'secret|credential|token|\.pem$|\.key$|\.p12$|\.pfx$|\.jks$|(^|/)\.env($|\.)|private|password|authkey' || true)"
if [ -n "$SECRET_FILES" ]; then
  echo "FINDINGS (filenames that look secret-shaped):"
  echo "$SECRET_FILES"
  FAIL=1
else
  echo "clean — no secret-shaped filename ever committed"
fi

# 2. Files added then deleted (a removed secret file still lives in history;
#    section 1 catches the name; the content scan below catches the value)
section "2. files deleted in history (review names for anything secret-adjacent)"
DELETED="$(git log --all --diff-filter=D --name-only --pretty=format:'%h %ad %s' --date=short | head -40 || true)"
if [ -n "$DELETED" ]; then
  echo "$DELETED"
else
  echo "clean — no file ever deleted"
fi

# 3. Hard credential patterns across every revision
section "3. hard credential patterns across all revisions"
HARD='AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|gho_[A-Za-z0-9]{20,}|ghu_[A-Za-z0-9]{20,}|xox[bap]-[A-Za-z0-9-]{10,}|-----BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY|sk_live_[A-Za-z0-9]{16,}|sk-ant-[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{35}|ssh-rsa AAAA[0-9A-Za-z+/]+|ssh-ed25519 AAAA[0-9A-Za-z+/]+|-----BEGIN CERTIFICATE'
HARD_HITS="$(git grep -nE "$HARD" $REVS -- . 2>/dev/null || true)"
if [ -n "$HARD_HITS" ]; then
  echo "FINDINGS (values shaped like live credentials):"
  echo "$HARD_HITS" | cut -c1-200
  FAIL=1
else
  echo "clean — no AWS keys, GitHub tokens, Slack tokens, private keys, Stripe live keys, Anthropic keys, Google API keys, SSH public keys, certificates"
fi

# 4. Credentialed URLs (https://user:pass@host)
section "4. URLs with embedded credentials"
URL_HITS="$(git grep -nE 'https?://[^ /"'"'"'<]*:[^ /"'"'"'<]*@' $REVS -- . 2>/dev/null || true)"
if [ -n "$URL_HITS" ]; then
  echo "FINDINGS:"
  echo "$URL_HITS" | cut -c1-200
  FAIL=1
else
  echo "clean — no user:password@ URLs"
fi

# 5. Soft keyword sweep (case-insensitive): every mention that needs a human
#    classification decision
section "5. soft keyword mentions across all revisions (classify each)"
SOFT='\b(api[_-]?key|apikey|password|passwd|bearer|credential|client[_-]?secret|access[_-]?token|secret[_-]?key)\b'
SOFT_HITS="$(git grep -inE "$SOFT" $REVS -- . 2>/dev/null | sed -E 's/^([0-9a-f]{40}):([^:]+):([0-9]+):(.*)$/\2 @ \1: \4/' | cut -c1-160 || true)"
if [ -n "$SOFT_HITS" ]; then
  echo "MENTIONS (classify: needed-at-boot / safe):"
  echo "$SOFT_HITS"
else
  echo "clean — no keyword mentions at all"
fi

# 6. High-entropy strings: heuristic token hunt (review by eye)
section "6. high-entropy strings (>=32 alnum chars, unique) — review by eye"
git grep -hoE '[A-Za-z0-9+/=_-]{32,}' $REVS -- . 2>/dev/null | sort -u | head -50
echo "(end of heuristic list; anything above that is not a URL slug or path needs classifying)"

# 7. .git/config remote URLs (embedded tokens in the clone's own config)
section "7. remote URLs in .git/config"
git remote -v
if git config --get-regexp 'remote\..*\.url' | grep -qE '://[^/]*:[^/]*@'; then
  echo "FINDING: credential embedded in a remote URL"
  FAIL=1
else
  echo "clean — no credentials in remote URLs"
fi

# 8. Newest commits — eyeball the latest changes
section "8. newest commits (latest 5, with file stats)"
git log -5 --stat --format='%h %ad %s' --date=short | head -60

# Verdict
echo
echo "================ VERDICT ================"
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: nothing in this clone can spend money, read mail, or impersonate"
  echo "the user. The brain is safe to publish."
else
  echo "FAIL: findings above. Each is a fix-list item: move the value to the"
  echo "vault, rotate it (it has been in git), and re-run this audit."
fi
echo "========================================="
echo
echo "Classification guide for any finding above:"
echo "  needed-at-boot — a live value an attacker could use as-is. Must come"
echo "      from a vault at runtime, never the repo. Rotate it; grep history."
echo "  safe           — public key, placeholder, redacted marker"
echo "      (<redacted>, [credential:...], YOUR_KEY_HERE), expired/revoked"
echo "      value, or design prose *about* secrets with no value present."
exit "$FAIL"
