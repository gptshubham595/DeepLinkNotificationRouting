#!/usr/bin/env bash
# Shared config sourced by every script in this folder.
# Keep these in sync with:
#   app/src/main/AndroidManifest.xml
#   app/src/main/java/.../navigation/DeepLinks.kt
#   firebase-hosting/.firebaserc

PACKAGE="com.shubham.deeplinknotificationrouting"
FIREBASE_PROJECT="movieapp-cdb85"

# Dedicated Hosting site. Deliberately NOT movieapp-cdb85, which already
# serves a different app; deploying over it would wipe that site.
HOSTING_SITE="deeplink-routing"
HOSTING_TARGET="deeplink"
APP_LINK_HOST="${HOSTING_SITE}.web.app"

SCHEME_URI="app://routing"
APP_LINK_URI="https://${APP_LINK_HOST}/routing"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOSTING_DIR="${REPO_ROOT}/firebase-hosting"
ASSETLINKS="${HOSTING_DIR}/public/.well-known/assetlinks.json"

die() { echo "ERROR: $*" >&2; exit 1; }

# adb usually lives in the SDK rather than on PATH, so resolve it here instead
# of assuming the caller's shell has it.
: "${ANDROID_HOME:=${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
for _d in "$ANDROID_HOME/platform-tools" "$HOME/Android/Sdk/platform-tools"; do
  [ -x "$_d/adb" ] && case ":$PATH:" in *":$_d:"*) ;; *) PATH="$_d:$PATH" ;; esac
done
export PATH

have() { command -v "$1" >/dev/null 2>&1 || die "'$1' not found on PATH"; }

# Emulators frequently lose DNS (host VPN, stale network state). Both App Link
# verification and FCM registration fail silently when that happens, so check
# it before blaming the config.
require_device_network() {
  adb shell 'ping -c 1 -W 2 google.com' >/dev/null 2>&1 && return 0
  echo "WARN: device cannot resolve DNS." >&2
  echo "      App Link verification and FCM token fetch will BOTH fail." >&2
  echo "      Fix: cold boot the AVD, or relaunch with -dns-server 8.8.8.8," >&2
  echo "      or disconnect any host VPN and restart the emulator." >&2
  return 1
}
