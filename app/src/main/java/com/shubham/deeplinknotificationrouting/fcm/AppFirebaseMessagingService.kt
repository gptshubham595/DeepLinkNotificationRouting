package com.shubham.deeplinknotificationrouting.fcm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.shubham.deeplinknotificationrouting.MainActivity
import com.shubham.deeplinknotificationrouting.navigation.DeepLinks

class AppFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val CHANNEL_ID = "routing_channel"
        private const val TAG = "FCM"
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d("FCM_TOKEN", "Token generated: $token")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        val route = remoteMessage.data["route"] ?: "screenA"

        // "scheme" -> app://routing/...   (unverified deep link)
        // "applink" -> https://host/routing/... (verified App Link)
        // Same destination either way; the difference is who Android trusts
        // to own the URL. Defaults to scheme so old payloads keep working.
        val base = when (remoteMessage.data["linkType"]) {
            "applink" -> DeepLinks.APP_LINK_URI
            else -> DeepLinks.SCHEME_URI
        }
        val uri = Uri.parse("$base/$route")

        val title = remoteMessage.notification?.title
            ?: remoteMessage.data["title"] ?: "Notification Trigger"
        val body = remoteMessage.notification?.body
            ?: remoteMessage.data["body"] ?: "Tap to navigate"

        Log.d(TAG, "routing to $uri")
        sendNotification(title, body, uri)
    }

    private fun sendNotification(title: String, messageBody: String, uri: Uri) {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Channel must exist before notify() on O+, and creating it first
        // keeps the ordering obvious.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Routing Channel",
                    NotificationManager.IMPORTANCE_DEFAULT
                )
            )
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = uri
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }

        // Two bugs lived here. Every notification used requestCode 0, so the
        // system treated them as the same PendingIntent; combined with
        // FLAG_ONE_SHOT the second push reused the FIRST push's stale URI and
        // routed to the wrong screen. A per-notification requestCode plus
        // UPDATE_CURRENT keeps each notification carrying its own destination.
        val requestCode = uri.hashCode()

        val pendingIntent = PendingIntent.getActivity(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(messageBody)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }
}
