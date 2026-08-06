package com.finbrief

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    /**
     * Creates the channel FCM messages are delivered on.
     *
     * Without this — and the matching default_notification_channel_id in the
     * manifest — Firebase logs "Missing Default Notification Channel metadata"
     * and drops every push into an unnamed fallback channel. That channel
     * appears as "Miscellaneous" in the user's notification settings, so they
     * have no way to keep market alerts while muting anything else, and some
     * OEM builds treat it as low priority.
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Market alerts",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Breaking financial news and your daily market briefs."
            enableVibration(true)
        }

        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    companion object {
        // Must match default_notification_channel_id in AndroidManifest.xml.
        private const val CHANNEL_ID = "finbrief_alerts"
    }
}
