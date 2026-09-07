#!/usr/bin/env bash
# Inspects and repairs App Link domain verification ON THE DEVICE.
#
# Verification runs once at install time. If the app was installed before
# assetlinks.json went live, the state stays "not verified" forever until you
# reinstall or force a re-verify. That is the single most common reason an
# App Link "silently stops working".
set -euo pipefail
source "$(dirname "$0")/_config.sh"
have adb
require_device_network || true

SDK=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
echo ">> Device API level: $SDK"
echo

echo ">> Current verification state for $PACKAGE:"
if [ "$SDK" -ge 31 ]; then
  adb shell pm get-app-links "$PACKAGE" || true
  echo
  echo ">> Forcing re-verification (Android 12+)..."
  adb shell pm verify-app-links --re-verify "$PACKAGE" || true
  sleep 3
  adb shell pm get-app-links "$PACKAGE" || true
  echo
  echo "Look for: ${APP_LINK_HOST}: verified"
  echo "If it says 'none' or '1024' (unverified), assetlinks.json is not"
  echo "reachable or the SHA-256 does not match this build's signing cert."
  echo
  echo "Manual override for local testing (bypasses verification):"
  echo "  adb shell pm set-app-links --package $PACKAGE 1 ${APP_LINK_HOST}"
else
  adb shell dumpsys package domain-preferred-apps | grep -A3 "$PACKAGE" || true
  echo "(Android 11 and below: verification state lives in domain-preferred-apps)"
fi
