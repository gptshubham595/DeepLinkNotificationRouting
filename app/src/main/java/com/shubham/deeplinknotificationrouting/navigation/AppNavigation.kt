package com.shubham.deeplinknotificationrouting.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navDeepLink

@Composable
fun AppNavigation(navController: NavHostController) {
    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(text = "Home Screen")
            }
        }
        composable(
            route = "details/{id}",
            deepLinks = listOf(navDeepLink { uriPattern = "app://routing/details/{id}" })
        ) { backStackEntry ->
            val id = backStackEntry.arguments?.getString("id") ?: "No ID"
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(text = "Details Screen, ID: $id")
            }
        }
    }
}