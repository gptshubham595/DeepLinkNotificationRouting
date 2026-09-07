#!/usr/bin/env bash
# Prints the SHA-256 signing fingerprints that must appear in assetlinks.json.
#
# App Link verification matches the fingerprint of the certificate that signed
# the INSTALLED apk. Debug and release builds are signed differently, so a
# debug build will fail verification against a release-only assetlinks.json.
# List every fingerprint you ship with.
set -euo pipefail
source "$(dirname "$0")/_config.sh"
have keytool

echo "=== DEBUG keystore (~/.android/debug.keystore) ==="
if [ -f "$HOME/.android/debug.keystore" ]; then
  keytool -list -v \
    -keystore "$HOME/.android/debug.keystore" \
    -alias androiddebugkey -storepass android -keypass android 2>/dev/null \
    | grep "SHA256:" | sed 's/^[[:space:]]*//'
else
  echo "  not found"
fi

echo
echo "=== RELEASE / Play App Signing ==="
echo "  Play Console -> your app -> Test and release -> Setup -> App signing"
echo "  Copy the 'App signing key certificate' SHA-256 and add it to:"
echo "  $ASSETLINKS"
echo
echo "  Play re-signs your upload with its own key, so the fingerprint that"
echo "  matters in production is Play's, NOT your upload keystore's."
