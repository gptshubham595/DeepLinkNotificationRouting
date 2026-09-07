# Notification Routing

FCM push -> notification tap -> deep link URI -> NavHost destination.

```bash
./script/get_fcm_token.sh                    # scrape token from logcat into fcm-backend/token.txt
./script/send_push.sh scheme  screenB/true   # app://routing/screenB/true
./script/send_push.sh applink screenB/true   # https://deeplink-routing.web.app/routing/screenB/true
```

Or directly:

```bash
cd fcm-backend && FCM_TOKEN=<token> node send.js --link applink --route screenB/true
```

Messages are **data-only** on purpose. A payload with a `notification` block
gets handled by the system tray while the app is backgrounded, which bypasses
`onMessageReceived` and therefore bypasses the routing code entirely. Data-only
guarantees our `PendingIntent` is always the one that gets built.

See [Deeplink.md](Deeplink.md) for the deep link vs App Link difference.
