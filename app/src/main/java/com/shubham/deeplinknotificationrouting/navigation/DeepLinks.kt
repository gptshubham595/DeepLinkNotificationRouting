package com.shubham.deeplinknotificationrouting.navigation

/**
 * Single source of truth for both link flavours.
 *
 * SCHEME_URI  -> custom scheme deep link. Unverified, unowned, device-local.
 * APP_LINK_URI -> https App Link. Verified against assetlinks.json hosted on
 *                 APP_LINK_HOST, therefore exclusively owned by this package.
 *
 * Both resolve to the same NavHost destinations, so you can fire either one
 * and watch the difference in how Android routes it.
 */
object DeepLinks {

    const val SCHEME_URI = "app://routing"

    const val APP_LINK_HOST = "deeplink-routing.web.app"
    const val APP_LINK_URI = "https://$APP_LINK_HOST/routing"

    /** Builds both URI patterns for a given nav path, e.g. "screenB/{showSheet}". */
    fun patternsFor(path: String) = listOf("$SCHEME_URI/$path", "$APP_LINK_URI/$path")
}
