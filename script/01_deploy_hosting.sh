#!/usr/bin/env bash
# Deploys assetlinks.json + the fallback page to the dedicated site.
#
# The --only hosting:<target> form is important. A bare `firebase deploy`
# in a multi-site project can publish to the wrong site.
set -euo pipefail
source "$(dirname "$0")/_config.sh"
have firebase

[ -f "$ASSETLINKS" ] || die "missing $ASSETLINKS"
python3 -m json.tool "$ASSETLINKS" >/dev/null || die "assetlinks.json is not valid JSON"

cd "$HOSTING_DIR"
echo ">> Deploying to site '$HOSTING_SITE' (target '$HOSTING_TARGET')..."
firebase deploy --only "hosting:${HOSTING_TARGET}" --project "$FIREBASE_PROJECT"

echo
echo "Deployed. Now run: ./script/02_verify_assetlinks.sh"
