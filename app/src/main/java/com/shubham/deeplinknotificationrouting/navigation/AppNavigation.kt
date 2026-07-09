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
        composable("screenA") {
            ScreenA(
                fcmToken = fcmToken,
                onNavigateToB = { navController.navigate("screenB/false") }
            )
        }
        composable(
            route = "screenB/{showSheet}",
            arguments = listOf(navArgument("showSheet") { type = NavType.StringType }),
            deepLinks = listOf(navDeepLink { uriPattern = "app://routing/screenB/{showSheet}" })
        ) { backStackEntry ->
            val showSheetArg = backStackEntry.arguments?.getString("showSheet") ?: "false"
            ScreenB(initialSheetState = showSheetArg.toBoolean())
        }
    }
}