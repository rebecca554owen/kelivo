package com.psyche.kelivo

import android.app.Activity
import android.app.ActivityManager
import android.content.Intent
import android.os.Bundle

class McpOAuthCallbackActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleCallback(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleCallback(intent)
    }

    private fun handleCallback(intent: Intent?) {
        val delivered = intent?.data?.let(McpOAuthHandler::handleCallback) == true
        val mainTask = if (delivered) findMainTask() else null
        finish()
        mainTask?.moveToFront()
    }

    private fun findMainTask(): ActivityManager.AppTask? {
        val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        return activityManager.appTasks.firstOrNull { task ->
            task.taskInfo.baseIntent.component?.className == MainActivity::class.java.name
        }
    }
}
