#!/usr/bin/env bash
# Fires the VERIFIED APP LINK:  https://<host>/routing/<route>
#
# Usage: ./trigger_applink.sh [route]           default: screenB/true
#        ./trigger_applink.sh screenB/true --browser   (simulate a real web tap)
set -euo pipefail
source "$(dirname "$0")/_config.sh"
have adb

ROUTE="${1:-screenB/true}"
URI="${APP_LINK_URI}/${ROUTE}"

if [ "${2:-}" = "--browser" ]; then
  # Routed through Chrome, which is the realistic path: a user taps an
  # https link in Gmail/WhatsApp/Chrome. If verification passed, Android
  # hands it to the app with no chooser. If not, Chrome loads the web page.
  echo ">> Via Chrome (real-world path): $URI"
  adb shell am start -a android.intent.action.VIEW \
    -c android.intent.category.BROWSABLE \
    -d "$URI" com.android.chrome
else
  echo ">> Resolving (no package pinned): $URI"
  adb shell am start -W -a android.intent.action.VIEW \
    -c android.intent.category.BROWSABLE -d "$URI"
fi
