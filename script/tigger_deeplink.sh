#!/usr/bin/env bash
# Fires the CUSTOM SCHEME deep link:  app://routing/<route>
#
# Usage: ./tigger_deeplink.sh [route]          default: screenB/true
#        ./tigger_deeplink.sh screenB/true --open   (no package = let Android resolve)
set -euo pipefail
source "$(dirname "$0")/_config.sh"
have adb

ROUTE="${1:-screenB/true}"
URI="${SCHEME_URI}/${ROUTE}"

if [ "${2:-}" = "--open" ]; then
  # No package argument. Android must decide who handles app:// itself.
  # If another installed app also claims scheme="app" host="routing",
  # you get the "Open with..." chooser here. That is the whole weakness
  # of custom schemes: ownership is unverifiable.
  echo ">> Resolving (no package pinned): $URI"
  adb shell am start -W -a android.intent.action.VIEW -d "$URI"
else
  echo ">> Forcing package $PACKAGE: $URI"
  adb shell am start -W -a android.intent.action.VIEW -d "$URI" "$PACKAGE"
fi
