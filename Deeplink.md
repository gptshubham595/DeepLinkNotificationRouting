# Deep Links vs App Links vs Dynamic Links

This repo implements **both** link types against the same nav graph so you can
fire each one and watch Android treat them differently.

---

## 1. The distinction

| | Deep Link | App Link | Dynamic Link |
|---|---|---|---|
| URI | `app://routing/screenB/true` | `https://deeplink-routing.web.app/routing/screenB/true` | `https://xxx.page.link/abc` |
| Manifest | `<data android:scheme="app" android:host="routing"/>` | same + `android:autoVerify="true"` on the filter | SDK-managed |
| Proof of ownership | **none** | `assetlinks.json` served over HTTPS from the host | Firebase-managed |
| Another app can claim it | **yes** | no | no |
| Chooser dialog | yes, if 2+ apps claim the scheme | never | never |
| App not installed | nothing happens | the web page loads | Play Store, then deferred routing |
| Survives install | no | no | **yes** (its one unique feature) |
| Status | works, unverifiable | current standard | **shut down 25 Aug 2025** |

The one-line answer to *"how do I make sure only my app opens this?"*:
**you cannot with `app://`.** Scheme names are unowned. Any APK can declare
`scheme="app" host="routing"` and Android will offer it as a candidate.

App Links fix this by anchoring trust in **domain ownership**. Google's verifier
fetches `https://<host>/.well-known/assetlinks.json` and checks that your
package name and signing certificate SHA-256 are listed there. Only then does
your app get exclusive ownership of those URLs.

### On Dynamic Links

Firebase Dynamic Links shut down on **25 August 2025**. It solved *deferred*
deep linking: user taps a link with the app not installed, goes to Play Store,
and after first launch still lands on the intended screen. Nothing replaces it
one-for-one. The migration path is App Links for the installed case, plus the
Play Install Referrer API (or Branch/AppsFlyer) if you genuinely need the
deferred case.

---

## 2. What is wired up here

**Manifest** (`app/src/main/AndroidManifest.xml`) — two `VIEW` intent filters
on `MainActivity`: the unverified `app://routing` one, and an
`autoVerify="true"` filter for `https://deeplink-routing.web.app/routing`.

**Nav graph** (`navigation/AppNavigation.kt`) — every destination registers both
URI patterns via `DeepLinks.patternsFor(path)`, so one `NavHost` serves both.

**Hosting** (`firebase-hosting/`) — serves `.well-known/assetlinks.json` plus a
fallback page at `/routing/**` that renders when the app is not installed.

**Push** (`fcm/AppFirebaseMessagingService.kt`) — data-only FCM messages carry
`route` and `linkType` (`scheme` | `applink`); the service builds the matching
URI into the notification's `PendingIntent`.

---

## 3. Deploy

Already done for this project, but the sequence is:

```bash
./script/00_setup_hosting.sh      # create the deeplink-routing site, bind target
./script/01_deploy_hosting.sh     # publish assetlinks.json + fallback page
./script/02_verify_assetlinks.sh  # confirm Google's API can read it
```

`00` creates a **dedicated** Hosting site rather than reusing
`movieapp-cdb85.web.app`, which already serves a different app. `firebase.json`
pins `"target": "deeplink"` so a stray `firebase deploy` cannot overwrite it.

---

## 4. Test

```bash
./script/get_sha256.sh                    # fingerprints that must be in assetlinks.json
./script/03_verify_applink_device.sh      # is the domain verified on this device?
./script/compare_links.sh                 # side-by-side resolver output
```

Fire the links:

```bash
./script/tigger_deeplink.sh screenB/true          # forced to our package
./script/tigger_deeplink.sh screenB/true --open   # let Android resolve -> chooser risk
./script/trigger_applink.sh screenB/true          # verified https
./script/trigger_applink.sh screenB/true --browser # via Chrome, the real path
```

Push notifications:

```bash
./script/get_fcm_token.sh              # scrape token from logcat
./script/send_push.sh scheme  screenB/true
./script/send_push.sh applink screenB/true
```

**The `--open` / `--browser` variants are the whole demo.** Pinning the package
name makes both links behave identically, which hides the difference. Drop the
package and Android has to decide for itself — that is where verified ownership
shows up.

---

## 5. Gotchas that will bite you

**Verification runs at install time.** If the app was installed before
`assetlinks.json` went live, the state stays unverified permanently. Reinstall,
or run `./script/03_verify_applink_device.sh` to force a re-verify.

**Debug and release are signed with different keys.** A debug build fails
verification against a release-only `assetlinks.json`. Currently only the debug
fingerprint is listed. Before shipping, add the **Play App Signing** SHA-256
from Play Console (Play re-signs your upload, so its key is the one that
matters), and drop the debug fingerprint from production.

**`pathPrefix="/routing"` is deliberately narrow.** Widening it to the whole
domain means your app intercepts every URL on that host, including pages you
want to stay in the browser.

**An emulator with no DNS fails both features identically.** App Link
verification reports `none` and FCM token fetch throws `SERVICE_NOT_AVAILABLE`
— neither error mentions networking, so it reads like a config problem. Check
`adb shell ping -c 1 google.com` first. Host VPNs are the usual cause; cold boot
the AVD or relaunch with `-dns-server 8.8.8.8`.

To test App Link routing while offline, force-approve the domain:

```bash
adb shell pm set-app-links --package com.shubham.deeplinknotificationrouting 1 deeplink-routing.web.app
adb shell pm set-app-links-user-selection --user 0 \
  --package com.shubham.deeplinknotificationrouting true deeplink-routing.web.app
```

This skips the network check and proves the manifest and nav graph are correct
independently of connectivity.

**`app://routing/screenA` used to do nothing.** `screenA` had no `navDeepLink`,
so any push defaulting to that route produced a URI the graph could not consume.
Both destinations register patterns now.

---

## 6. Files

```
app/src/main/AndroidManifest.xml                  both intent filters
app/src/main/java/.../navigation/DeepLinks.kt     URI constants, single source of truth
app/src/main/java/.../navigation/AppNavigation.kt navDeepLink registration
app/src/main/java/.../fcm/AppFirebaseMessagingService.kt  push -> URI -> PendingIntent
app/src/main/java/.../MainActivity.kt             cold/warm start intent handling
firebase-hosting/public/.well-known/assetlinks.json
firebase-hosting/firebase.json                    target-pinned hosting config
fcm-backend/send.js                               FCM sender
script/                                           setup, deploy, verify, trigger
```
