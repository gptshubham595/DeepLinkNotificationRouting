#!/usr/bin/env bash
# Side-by-side demo of what actually differs between the two link types.
#
# Reads the resolver's own answer instead of asserting anything: `pm resolve`
# style output via `am start` shows which component Android picked, and
# `pm get-app-links` shows whether the https host is verified.
set -euo pipefail
source "$(dirname "$0")/_config.sh"
have adb
require_device_network || true

ROUTE="${1:-screenB/true}"

echo "==============================================="
echo " 1. DEEP LINK  ${SCHEME_URI}/${ROUTE}"
echo "==============================================="
echo "Who claims this scheme?"
adb shell "cmd package query-activities -a android.intent.action.VIEW \
  -c android.intent.category.BROWSABLE -d '${SCHEME_URI}/${ROUTE}'" 2>/dev/null \
  | grep -E "packageName|name=" | sed 's/^/  /' || echo "  (query-activities unavailable on this API level)"
echo
echo "No verification exists for custom schemes. Any app declaring"
echo "scheme=\"app\" host=\"routing\" appears in that list and can take the tap."
echo

echo "==============================================="
echo " 2. APP LINK   ${APP_LINK_URI}/${ROUTE}"
echo "==============================================="
SDK=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
if [ "$SDK" -ge 31 ]; then
  adb shell pm get-app-links "$PACKAGE" 2>/dev/null | sed 's/^/  /' || true
else
  adb shell dumpsys package domain-preferred-apps 2>/dev/null | grep -A3 "$PACKAGE" | sed 's/^/  /' || true
fi
echo
echo "'${APP_LINK_HOST}: verified' means Android fetched"
echo "https://${APP_LINK_HOST}/.well-known/assetlinks.json, matched this"
echo "package + signing SHA-256, and granted EXCLUSIVE ownership."
echo "No other app can intercept it. No chooser is ever shown."
