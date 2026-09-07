package com.shubham.deeplinknotificationrouting.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import androidx.navigation.navDeepLink
import com.shubham.deeplinknotificationrouting.screens.ScreenA
import com.shubham.deeplinknotificationrouting.screens.ScreenB

@Composable
fun AppNavigation(navController: NavHostController, fcmToken: String) {
    NavHost(navController = navController, startDestination = "screenA") {

        // screenA previously had no deepLinks, so an FCM push carrying the
        // default route "screenA" produced a URI nothing could consume and the
        // tap silently did nothing. Both patterns are registered now.
        composable(
            route = "screenA",
            deepLinks = DeepLinks.patternsFor("screenA").map { navDeepLink { uriPattern = it } }
        ) {
            ScreenA(
                fcmToken = fcmToken,
                onNavigateToB = { navController.navigate("screenB/false") }
            )
        }

        composable(
            route = "screenB/{showSheet}",
            arguments = listOf(navArgument("showSheet") { type = NavType.StringType }),
            deepLinks = DeepLinks.patternsFor("screenB/{showSheet}")
                .map { navDeepLink { uriPattern = it } }
        ) { backStackEntry ->
            val showSheetArg = backStackEntry.arguments?.getString("showSheet") ?: "false"
            ScreenB(initialSheetState = showSheetArg.toBoolean())
        }
    }
}
