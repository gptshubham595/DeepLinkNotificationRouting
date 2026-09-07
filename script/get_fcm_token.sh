#!/usr/bin/env bash
# Pulls the current FCM token out of logcat and saves it for send_push.sh.
set -euo pipefail
source "$(dirname "$0")/_config.sh"
have adb

TOKEN=$(adb logcat -d -s FCM_TOKEN 2>/dev/null \
  | grep -oE '[A-Za-z0-9_-]{20,}:APA91[A-Za-z0-9_-]+' | tail -1 || true)

[ -n "$TOKEN" ] || die "No token in logcat. Launch the app, then re-run.
(logcat is a ring buffer; the token may have scrolled out. Copy it from Screen A instead.)"

echo "$TOKEN" > "${REPO_ROOT}/fcm-backend/token.txt"
echo "Saved to fcm-backend/token.txt"
echo "${TOKEN:0:12}...${TOKEN: -6}"
