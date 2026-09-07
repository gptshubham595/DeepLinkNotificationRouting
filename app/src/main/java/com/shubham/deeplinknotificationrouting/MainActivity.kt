package com.shubham.deeplinknotificationrouting

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.navigation.compose.rememberNavController
import com.google.firebase.messaging.FirebaseMessaging
import com.shubham.deeplinknotificationrouting.navigation.AppNavigation
import com.shubham.deeplinknotificationrouting.ui.theme.DeepLinkNotificationRoutingTheme
import kotlinx.coroutines.flow.MutableSharedFlow

class MainActivity : ComponentActivity() {

    private val fcmTokenState = mutableStateOf("Loading Token...")

    /**
     * Warm-start deep links arrive on onNewIntent, which can fire before or
     * after composition. Buffering them in a replay flow means the NavHost
     * consumes whatever is pending as soon as it exists, instead of the old
     * `::navController.isInitialized` guard silently dropping the intent.
     *
     * Cold-start links need no handling here: NavHost.setGraph inspects the
     * launching Activity intent itself.
     */
    private val newIntents = MutableSharedFlow<Intent>(replay = 1, extraBufferCapacity = 4)

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) Log.d("PERMISSIONS", "Notification permission active.")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        askNotificationPermission()
        logFcmToken()

        Log.d("DEEPLINK", "onCreate intent data = ${intent?.data}")

        setContent {
            DeepLinkNotificationRoutingTheme {
                val navController = rememberNavController()

                LaunchedEffect(navController) {
                    newIntents.collect { pending ->
                        Log.d("DEEPLINK", "onNewIntent data = ${pending.data}")
                        navController.handleDeepLink(pending)
                    }
                }

                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Box(modifier = Modifier.padding(innerPadding)) {
                        AppNavigation(
                            navController = navController,
                            fcmToken = fcmTokenState.value
                        )
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.data != null) newIntents.tryEmit(intent)
    }

    private fun askNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    private fun logFcmToken() {
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (!task.isSuccessful) {
                Log.w("FCM_TOKEN", "Fetching FCM registration token failed", task.exception)
                fcmTokenState.value = "Failed to fetch token"
                return@addOnCompleteListener
            }
            val token = task.result
            Log.d("FCM_TOKEN", "Current active token: $token")
            fcmTokenState.value = token ?: "Token is null"
        }
    }
}
