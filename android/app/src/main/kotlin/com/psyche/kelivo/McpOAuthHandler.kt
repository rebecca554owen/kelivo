package com.psyche.kelivo

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.browser.auth.AuthTabIntent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal object McpOAuthHandler {
    private const val CHANNEL_NAME = "app.mcp_oauth"
    private const val CALLBACK_SCHEME = "psyche.kelivo"
    private const val CALLBACK_HOST = "mcp-oauth-callback"
    private const val FIRST_AUTH_REQUEST_CODE = 4200
    private const val LAST_AUTH_REQUEST_CODE = 0xfffe
    private const val FALLBACK_CALLBACK_GRACE_MS = 500L

    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingResult: MethodChannel.Result? = null
    private var expectedRedirectUri: Uri? = null
    private var expectedState: String? = null
    private var pendingRequestCode: Int? = null
    private var nextRequestCode = FIRST_AUTH_REQUEST_CODE

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
        val state = expectedState ?: return false
        val result = pendingResult ?: return false
        if (!sameRedirectTarget(uri, expected) || !sameState(uri, state)) return false

        clearPending()
        result.success(uri.toString())
        return true
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode !in FIRST_AUTH_REQUEST_CODE..LAST_AUTH_REQUEST_CODE) return false
        if (pendingRequestCode != requestCode) return true

        if (resultCode == AuthTabIntent.RESULT_OK) {
            val uri = data?.data
            if (uri != null && handleCallback(uri)) return true
            failPending(
                "authorization_failed",
                "Authorization callback did not match the active session.",
            )
        } else if (resultCode == AuthTabIntent.RESULT_CANCELED) {
            mainHandler.postDelayed(
                {
                    if (pendingRequestCode == requestCode) {
                        failPending(
                            "authorization_cancelled",
                            "Authorization was cancelled.",
                        )
                    }
                },
                FALLBACK_CALLBACK_GRACE_MS,
            )
        } else {
            failPending(
                "authorization_failed",
                "Authorization browser returned result code $resultCode.",
            )
        }
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
        val state = authorizationUri?.getQueryParameters("state")?.singleOrNull()
        if (
            authorizationUri?.scheme != "https" ||
            !validRedirectUri(redirectUri) ||
            state.isNullOrEmpty()
        ) {
            result.error(
                "invalid_arguments",
                "A valid HTTPS authorization URL, state, and Kelivo callback URI are required.",
                null,
            )
            return
        }

        val requestCode = allocateRequestCode()
        pendingResult = result
        expectedRedirectUri = redirectUri
        expectedState = state
        pendingRequestCode = requestCode
        try {
            val authTab = AuthTabIntent.Builder().build()
            authTab.intent
                .setData(authorizationUri)
                .putExtra(AuthTabIntent.EXTRA_REDIRECT_SCHEME, CALLBACK_SCHEME)
            activity.startActivityForResult(authTab.intent, requestCode)
        } catch (error: ActivityNotFoundException) {
            clearPending()
            result.error(
                "authorization_failed",
                "No browser is available to open the authorization page.",
                null,
            )
        }
    }

    private fun cancel(result: MethodChannel.Result) {
        failPending(
            "authorization_cancelled",
            "Authorization was cancelled.",
        )
        result.success(null)
    }

    private fun failPending(code: String, message: String) {
        val result = pendingResult ?: return
        clearPending()
        result.error(code, message, null)
    }

    private fun clearPending() {
        pendingResult = null
        expectedRedirectUri = null
        expectedState = null
        pendingRequestCode = null
    }

    private fun allocateRequestCode(): Int {
        val requestCode = nextRequestCode
        nextRequestCode = if (requestCode == LAST_AUTH_REQUEST_CODE) {
            FIRST_AUTH_REQUEST_CODE
        } else {
            requestCode + 1
        }
        return requestCode
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

    private fun sameState(actual: Uri, expected: String): Boolean =
        actual.getQueryParameters("state").let { states ->
            states.size == 1 && states.first() == expected
        }
}
