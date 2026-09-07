#!/usr/bin/env bash
# Confirms the hosted assetlinks.json is reachable AND that Google's Digital
# Asset Links API can parse it. Android's verifier uses that same API, so if
# this passes, on-device verification will too.
set -euo pipefail
source "$(dirname "$0")/_config.sh"
have curl

URL="https://${APP_LINK_HOST}/.well-known/assetlinks.json"

echo ">> 1. Raw fetch: $URL"
CODE=$(curl -sS -o /tmp/al.json -w '%{http_code}' "$URL") || die "fetch failed"
CT=$(curl -sSI "$URL" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-type"{print $2}')
echo "   HTTP $CODE   Content-Type: ${CT:-<none>}"
[ "$CODE" = "200" ] || die "expected HTTP 200, got $CODE"
case "$CT" in
  application/json*) ;;
  *) echo "   WARN: Content-Type should be application/json" ;;
esac
python3 -m json.tool /tmp/al.json

echo
echo ">> 2. Google Digital Asset Links API (what Android actually calls)"
curl -sS -G 'https://digitalassetlinks.googleapis.com/v1/statements:list' \
  --data-urlencode "source.web.site=https://${APP_LINK_HOST}" \
  --data-urlencode 'relation=delegate_permission/common.handle_all_urls' \
  | python3 -m json.tool

echo
echo "A 'statements' array containing package_name ${PACKAGE} means verification will pass."
echo "An empty array or debugString error means it will NOT."
