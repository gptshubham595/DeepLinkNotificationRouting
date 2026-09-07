#!/usr/bin/env bash
# Sends an FCM push that deep-links into the app.
#
# Usage:
#   ./send_push.sh                        # scheme link -> screenB/true
#   ./send_push.sh applink                # app link  -> screenB/true
#   ./send_push.sh applink screenA        # app link  -> screenA
#
# Token comes from fcm-backend/token.txt, $FCM_TOKEN, or --token.
# Grab it from Screen A's text field, or:
#   adb logcat -d -s FCM_TOKEN
set -euo pipefail
source "$(dirname "$0")/_config.sh"
have node

LINK="${1:-scheme}"
ROUTE="${2:-screenB/true}"

cd "${REPO_ROOT}/fcm-backend"
[ -d node_modules ] || { echo ">> installing deps..."; npm install; }
[ -f serviceAccountKey.json ] || die "fcm-backend/serviceAccountKey.json missing"

node send.js --link "$LINK" --route "$ROUTE"
