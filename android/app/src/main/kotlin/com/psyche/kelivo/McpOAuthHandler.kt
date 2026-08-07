package com.psyche.kelivo

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal object McpOAuthHandler {
    private const val CHANNEL_NAME = "app.mcp_oauth"
    private const val CALLBACK_SCHEME = "psyche.kelivo"
    private const val CALLBACK_HOST = "mcp-oauth-callback"

    private var pendingResult: MethodChannel.Result? = null
    private var expectedRedirectUri: Uri? = null

    fun configure(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "authenticate" -> authenticate(activity, call, result)
                "cancel" -> cancel(result)
                else -> result.notImplemented()
            }
        }
    }

    fun handleCallback(uri: Uri): Boolean {
        val expected = expectedRedirectUri ?: return false
        val result = pendingResult ?: return false
        if (!sameRedirectTarget(uri, expected)) return false

        pendingResult = null
        expectedRedirectUri = null
        result.success(uri.toString())
        return true
    }

    private fun authenticate(
        activity: Activity,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (pendingResult != null) {
            result.error(
                "authorization_in_progress",
                "An authorization session is already in progress.",
                null,
            )
            return
        }

        val arguments = call.arguments as? Map<*, *>
        val authorizationUri = arguments?.get("url")?.toString()?.let(Uri::parse)
        val redirectUri = arguments?.get("redirectUri")?.toString()?.let(Uri::parse)
        if (authorizationUri?.scheme != "https" || !validRedirectUri(redirectUri)) {
            result.error(
                "invalid_arguments",
                "A valid HTTPS authorization URL and Kelivo callback URI are required.",
                null,
            )
            return
        }

        pendingResult = result
        expectedRedirectUri = redirectUri
        try {
            val customTab = CustomTabsIntent.Builder()
                .setShowTitle(true)
                .build()
            customTab.intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            customTab.launchUrl(activity, authorizationUri)
        } catch (error: ActivityNotFoundException) {
            pendingResult = null
            expectedRedirectUri = null
            result.error(
                "authorization_failed",
                "No browser is available to open the authorization page.",
                null,
            )
        }
    }

    private fun cancel(result: MethodChannel.Result) {
        val authorizationResult = pendingResult
        pendingResult = null
        expectedRedirectUri = null
        authorizationResult?.error(
            "authorization_cancelled",
            "Authorization was cancelled.",
            null,
        )
        result.success(null)
    }

    private fun validRedirectUri(uri: Uri?): Boolean =
        uri != null &&
            uri.scheme.equals(CALLBACK_SCHEME, ignoreCase = true) &&
            uri.host.equals(CALLBACK_HOST, ignoreCase = true) &&
            uri.pathSegments.size == 1 &&
            uri.pathSegments.first().isNotEmpty() &&
            uri.query == null &&
            uri.fragment == null

    private fun sameRedirectTarget(actual: Uri, expected: Uri): Boolean =
        actual.scheme.equals(expected.scheme, ignoreCase = true) &&
            actual.host.equals(expected.host, ignoreCase = true) &&
            actual.port == expected.port &&
            actual.path == expected.path &&
            actual.fragment == null
}
