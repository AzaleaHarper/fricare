package com.fricare.fricare

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        Log.d("FricareBootReceiver", "Boot completed, starting monitoring service")

        // Check if the user had the service enabled
        val prefs = context.getSharedPreferences(
            AppLaunchDetectorService.PREFS_NAME,
            Context.MODE_PRIVATE
        )
        val hasApps = prefs.getString(AppLaunchDetectorService.KEY_MONITORED_APPS, null) != null

        if (hasApps) {
            val serviceIntent = Intent(context, AppLaunchDetectorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}
