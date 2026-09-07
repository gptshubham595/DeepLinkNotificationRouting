#!/usr/bin/env bash
# One-time: create the dedicated Hosting site and bind it to the deploy target.
# Safe to re-run; both steps are idempotent.
set -euo pipefail
source "$(dirname "$0")/_config.sh"
have firebase

cd "$HOSTING_DIR"

echo ">> Existing sites in $FIREBASE_PROJECT:"
firebase hosting:sites:list --project "$FIREBASE_PROJECT" || true

if firebase hosting:sites:list --project "$FIREBASE_PROJECT" 2>/dev/null \
     | grep -q "\b${HOSTING_SITE}\b"; then
  echo ">> Site '$HOSTING_SITE' already exists, skipping create."
else
  echo ">> Creating site '$HOSTING_SITE'..."
  firebase hosting:sites:create "$HOSTING_SITE" --project "$FIREBASE_PROJECT"
fi

echo ">> Binding target '$HOSTING_TARGET' -> site '$HOSTING_SITE'..."
firebase target:apply hosting "$HOSTING_TARGET" "$HOSTING_SITE" \
  --project "$FIREBASE_PROJECT"

echo
echo "Done. Site URL: https://${APP_LINK_HOST}"
echo "Next: ./script/01_deploy_hosting.sh"
