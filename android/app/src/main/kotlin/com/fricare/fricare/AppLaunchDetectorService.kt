package com.fricare.fricare

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AppLaunchDetectorService : Service() {
    companion object {
        const val TAG = "FricareDetector"
        const val CHANNEL_ID = "fricare_monitoring"
        const val NOTIFICATION_ID = 1
        const val POLL_INTERVAL_MS = 500L
        const val PREFS_NAME = "fricare_prefs"
        const val KEY_MONITORED_APPS = "monitored_apps"
        private const val KEY_OPEN_COUNT_PREFIX = "open_count_"
        private const val KEY_OPEN_DATE_PREFIX = "open_date_"

        // Must match Dart FrictionMode enum order
        private const val MODE_ALWAYS = 0
        private const val MODE_AFTER_OPENS = 1
        private const val MODE_ESCALATING = 2

        // Must match Dart FrictionKind enum order
        const val KIND_HOLD = 0
        const val KIND_PUZZLE = 1
        const val KIND_CONFIRM = 2
        const val KIND_NONE = 3
        const val KIND_MATH = 4

        var isRunning = false
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastForegroundPackage: String? = null
    private var monitoredApps = mutableMapOf<String, AppFrictionData>()
    private val activeOverlays = mutableSetOf<String>()
    private var wakeLock: PowerManager.WakeLock? = null

    data class EscalationStepData(
        val fromOpen: Int,
        val kind: Int,
        val delaySeconds: Int,
    )

    data class AppFrictionData(
        val packageName: String,
        val appName: String,
        val kind: Int,
        val delaySeconds: Int,
        val confirmationSteps: Int,
        val puzzleTaps: Int,
        val mathProblems: Int,
        val chainStepsJson: String,
        val mode: Int,
        val openThreshold: Int,
        val escalationSteps: List<EscalationStepData>,
    )

    private val pollRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        acquireWakeLock()
        loadMonitoredApps()
        isRunning = true
        handler.post(pollRunnable)
        Log.d(TAG, "Service started, monitoring ${monitoredApps.size} apps")
    }

    override fun onDestroy() {
        handler.removeCallbacks(pollRunnable)
        releaseWakeLock()
        isRunning = false
        Log.d(TAG, "Service stopped")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        loadMonitoredApps()
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Re-deliver the service when the user swipes the app from recents
        Log.d(TAG, "Task removed, scheduling service restart")
        val restartIntent = Intent(this, AppLaunchDetectorService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(restartIntent)
        } else {
            startService(restartIntent)
        }
        super.onTaskRemoved(rootIntent)
    }

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "fricare:monitoring"
        ).apply { acquire() }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
    }

    private fun checkForegroundApp() {
        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(now - 1000, now)
        val event = UsageEvents.Event()
        var latestPackage: String? = null

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                latestPackage = event.packageName
            }
        }

        if (latestPackage != null && latestPackage != lastForegroundPackage) {
            lastForegroundPackage = latestPackage
            onAppForegrounded(latestPackage)
        }
    }

    private fun onAppForegrounded(packageName: String) {
        if (packageName == this.packageName) return
        val appData = monitoredApps[packageName] ?: return
        if (activeOverlays.contains(packageName)) return

        val openCount = incrementOpenCount(packageName)
        Log.d(TAG, "$packageName opened today: #$openCount  mode=${appData.mode}")

        val result = resolveEffectiveFriction(appData, openCount) ?: return

        activeOverlays.add(packageName)
        if (Settings.canDrawOverlays(this)) {
            showFrictionOverlay(appData, result.first, result.second)
        }
        handler.postDelayed({ activeOverlays.remove(packageName) }, 30_000)
    }

    /** Returns (frictionKind, delaySeconds) to show, or null to skip friction. */
    private fun resolveEffectiveFriction(
        app: AppFrictionData,
        openCount: Int,
    ): Pair<Int, Int>? = when (app.mode) {
        MODE_ALWAYS ->
            Pair(app.kind, app.delaySeconds)

        MODE_AFTER_OPENS ->
            if (openCount > app.openThreshold) Pair(app.kind, app.delaySeconds)
            else null

        MODE_ESCALATING -> {
            // Find the highest tier whose fromOpen <= current count
            val step = app.escalationSteps
                .filter { it.fromOpen <= openCount }
                .maxByOrNull { it.fromOpen }
            when {
                step == null -> null
                step.kind == KIND_NONE -> null
                else -> Pair(step.kind, step.delaySeconds)
            }
        }

        else -> Pair(app.kind, app.delaySeconds)
    }

    private fun showFrictionOverlay(app: AppFrictionData, kind: Int, delay: Int) {
        val intent = Intent(this, OverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("kind", kind)
            putExtra("delaySeconds", delay)
            putExtra("confirmationSteps", app.confirmationSteps)
            putExtra("puzzleTaps", app.puzzleTaps)
            putExtra("mathProblems", app.mathProblems)
            putExtra("chainStepsJson", app.chainStepsJson)
            putExtra("appName", app.appName)
            putExtra("packageName", app.packageName)
        }
        startActivity(intent)
    }

    // ── Daily open-count tracking ─────────────────────────────────────────────

    private fun todayKey(): String =
        SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(Date())

    private fun incrementOpenCount(packageName: String): Int {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val today = todayKey()
        val dateKey = "$KEY_OPEN_DATE_PREFIX$packageName"
        val countKey = "$KEY_OPEN_COUNT_PREFIX$packageName"

        val storedDate = prefs.getString(dateKey, null)
        val count = if (storedDate == today) prefs.getInt(countKey, 0) + 1 else 1

        prefs.edit()
            .putString(dateKey, today)
            .putInt(countKey, count)
            .apply()

        return count
    }

    private fun loadMonitoredApps() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(KEY_MONITORED_APPS, null) ?: return
        try {
            val rawList = JSONArray(json)
            monitoredApps.clear()
            for (i in 0 until rawList.length()) {
                val raw = rawList.getJSONObject(i)
                val pkg = raw.optString("packageName", "")
                if (pkg.isEmpty()) continue

                val stepsArray = raw.optJSONArray("escalationSteps") ?: JSONArray()
                val steps = (0 until stepsArray.length()).mapNotNull { j ->
                    val s = stepsArray.optJSONObject(j) ?: return@mapNotNull null
                    EscalationStepData(
                        fromOpen = s.optInt("fromOpen", 1),
                        kind = s.optInt("kind", KIND_NONE),
                        delaySeconds = s.optInt("delaySeconds", 0),
                    )
                }

                val chainArray = raw.optJSONArray("chainSteps") ?: JSONArray()
                val chainJson = chainArray.toString()

                monitoredApps[pkg] = AppFrictionData(
                    packageName = pkg,
                    appName = raw.optString("appName", pkg),
                    kind = raw.optInt("kind", KIND_HOLD),
                    delaySeconds = raw.optInt("delaySeconds", 3),
                    confirmationSteps = raw.optInt("confirmationSteps", 2),
                    puzzleTaps = raw.optInt("puzzleTaps", 5),
                    mathProblems = raw.optInt("mathProblems", 3),
                    chainStepsJson = chainJson,
                    mode = raw.optInt("mode", MODE_ALWAYS),
                    openThreshold = raw.optInt("openThreshold", 3),
                    escalationSteps = steps,
                )
            }
            Log.d(TAG, "Loaded ${monitoredApps.size} monitored apps")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load monitored apps", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Fricare Monitoring",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Monitors app launches to apply friction"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Fricare is active")
            .setContentText("Monitoring app launches")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
}
