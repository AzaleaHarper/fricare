package com.fricare.fricare

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.setViewTreeLifecycleOwner
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class AppLaunchDetectorService : Service() {
    companion object {
        const val TAG = "FricareDetector"
        const val CHANNEL_ID = "fricare_monitoring"
        const val NOTIFICATION_ID = 1
        const val POLL_INTERVAL_MS = 500L
        const val PREFS_NAME = "fricare_prefs"
        const val KEY_MONITORED_APPS = "monitored_apps"
        private const val KEY_FRICTION_RESULT_PREFIX = "friction_result_"
        private const val KEY_FRICTION_COMPLETED_AT_PREFIX = "friction_completed_at_"
        private const val RESULT_COMPLETED = "completed"
        private const val RESULT_CANCELLED = "cancelled"
        private const val OVERLAY_CHANNEL = "com.fricare/overlay"

        // Must match Dart FrictionKind enum order
        const val KIND_NONE = 0
        const val KIND_HOLD = 1
        const val KIND_PUZZLE = 2
        const val KIND_CONFIRM = 3
        const val KIND_MATH = 4

        var isRunning = false
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastForegroundPackage: String? = null
    private var monitoredApps = mutableMapOf<String, AppFrictionData>()
    private var wakeLock: PowerManager.WakeLock? = null

    // Pre-warmed engine — created once, reused for every overlay
    private lateinit var engineGroup: FlutterEngineGroup
    private var overlayEngine: FlutterEngine? = null
    private var overlayChannel: MethodChannel? = null

    // Overlay view state — only one overlay at a time
    private var overlayView: FrameLayout? = null
    private var currentOverlayPackage: String? = null

    data class AppFrictionData(
        val packageName: String,
        val appName: String,
        val kind: Int,
        val delaySeconds: Int,
        val confirmationSteps: Int,
        val puzzleTaps: Int,
        val mathProblems: Int,
        val chainStepsJson: String,
        val cooldownMinutes: Int,
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

        // Initialize Flutter engine group for lightweight child engines
        FlutterInjector.instance().flutterLoader().let { loader ->
            if (!loader.initialized()) {
                loader.startInitialization(applicationContext)
                loader.ensureInitializationComplete(applicationContext, null)
            }
        }
        engineGroup = FlutterEngineGroup(this)

        // Pre-warm the overlay engine so it's ready instantly when needed.
        // The Dart isolate starts now; overlayMain() runs and sets up its
        // MethodChannel handler. No engine startup delay when showing friction.
        val dartEntrypoint = DartExecutor.DartEntrypoint(
            FlutterInjector.instance().flutterLoader().findAppBundlePath(),
            "overlayMain"
        )
        overlayEngine = engineGroup.createAndRunEngine(this, dartEntrypoint)
        overlayChannel = MethodChannel(overlayEngine!!.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
        overlayChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "frictionComplete" -> {
                    val pkg = currentOverlayPackage
                    if (pkg != null) {
                        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
                            .putString("$KEY_FRICTION_RESULT_PREFIX$pkg", RESULT_COMPLETED)
                            .putLong("$KEY_FRICTION_COMPLETED_AT_PREFIX$pkg", System.currentTimeMillis())
                            .apply()
                    }
                    removeOverlay()
                    result.success(null)
                }
                "frictionCancelled" -> {
                    val pkg = currentOverlayPackage
                    if (pkg != null) {
                        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
                            .putString("$KEY_FRICTION_RESULT_PREFIX$pkg", RESULT_CANCELLED)
                            .apply()
                    }
                    removeOverlay()
                    navigateHome()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        loadMonitoredApps()
        isRunning = true
        handler.post(pollRunnable)
        Log.d(TAG, "Service started, monitoring ${monitoredApps.size} apps")
    }

    override fun onDestroy() {
        handler.removeCallbacks(pollRunnable)
        removeOverlay()
        overlayEngine?.destroy()
        overlayEngine = null
        overlayChannel = null
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

    // ── Foreground detection ──────────────────────────────────────────────────

    private fun checkForegroundApp() {
        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(now - 1000, now)
        val event = UsageEvents.Event()
        var latestPackage: String? = null
        var trackedAppPaused = false

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    latestPackage = event.packageName
                }
                UsageEvents.Event.ACTIVITY_PAUSED -> {
                    if (event.packageName == lastForegroundPackage) {
                        trackedAppPaused = true
                    }
                }
            }
        }

        // If the tracked app was paused but nothing new resumed (e.g. user
        // went to home screen), clear tracking so the next resume re-triggers.
        if (trackedAppPaused && latestPackage == null) {
            lastForegroundPackage = null
        }

        if (latestPackage != null && latestPackage != lastForegroundPackage) {
            lastForegroundPackage = latestPackage
            onAppForegrounded(latestPackage)
        }
    }

    private fun onAppForegrounded(packageName: String) {
        if (packageName == this.packageName) return
        val appData = monitoredApps[packageName] ?: return
        if (currentOverlayPackage != null) return

        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastResult = prefs.getString("$KEY_FRICTION_RESULT_PREFIX$packageName", null)
        val lastCompletedAt = prefs.getLong("$KEY_FRICTION_COMPLETED_AT_PREFIX$packageName", 0L)

        // Check cooldown: skip friction if user completed it within the grace window
        if (lastResult == RESULT_COMPLETED && appData.cooldownMinutes > 0) {
            val elapsedMs = System.currentTimeMillis() - lastCompletedAt
            val cooldownMs = appData.cooldownMinutes * 60_000L
            if (elapsedMs < cooldownMs) {
                Log.d(TAG, "$packageName within cooldown (${elapsedMs / 1000}s of ${appData.cooldownMinutes * 60}s)")
                return
            }
        }

        Log.d(TAG, "$packageName opened, showing friction kind=${appData.kind}")

        if (Settings.canDrawOverlays(this)) {
            showFrictionOverlay(appData, appData.kind, appData.delaySeconds)
        }
    }

    // ── Overlay management ────────────────────────────────────────────────────

    /** LifecycleOwner for the overlay view tree — FlutterView needs this to render. */
    private class OverlayLifecycleOwner : LifecycleOwner {
        val registry = LifecycleRegistry(this)
        override val lifecycle: Lifecycle get() = registry
    }

    private var overlayLifecycleOwner: OverlayLifecycleOwner? = null
    private var overlayFlutterView: FlutterView? = null
    private fun showFrictionOverlay(app: AppFrictionData, kind: Int, delay: Int) {
        if (overlayView != null) return
        val engine = overlayEngine ?: return

        // Read theme prefs so the overlay matches the user's chosen accent/AMOLED
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val accentColorIndex = prefs.getInt("accent_color_index", 0)
        val amoledDark = prefs.getBoolean("amoled_dark", false)

        // Push config to the pre-warmed Dart isolate
        overlayChannel?.invokeMethod("showFriction", mapOf(
            "kind" to kind,
            "delaySeconds" to delay,
            "confirmationSteps" to app.confirmationSteps,
            "puzzleTaps" to app.puzzleTaps,
            "mathProblems" to app.mathProblems,
            "appName" to app.appName,
            "packageName" to app.packageName,
            "chainStepsJson" to app.chainStepsJson,
            "accentColorIndex" to accentColorIndex,
            "amoledDark" to amoledDark
        ))

        // Lifecycle owner for the FlutterView — without this, Flutter won't render
        val lifecycleOwner = OverlayLifecycleOwner()

        // Container with lifecycle support
        val container = FrameLayout(this)
        container.setViewTreeLifecycleOwner(lifecycleOwner)

        // TextureView — SurfaceView creates a separate window layer incompatible
        // with TYPE_APPLICATION_OVERLAY (causes SurfaceSyncGroup timeouts).
        val flutterView = FlutterView(this, FlutterTextureView(this))
        flutterView.setBackgroundColor(android.graphics.Color.TRANSPARENT)
        flutterView.isFocusable = true
        flutterView.isFocusableInTouchMode = true
        flutterView.fitsSystemWindows = true
        container.addView(flutterView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        )
        params.softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE

        // Attach to pre-warmed engine and signal lifecycle
        flutterView.attachToFlutterEngine(engine)
        lifecycleOwner.registry.handleLifecycleEvent(Lifecycle.Event.ON_RESUME)
        engine.lifecycleChannel.appIsResumed()

        (getSystemService(Context.WINDOW_SERVICE) as WindowManager).addView(container, params)

        overlayView = container
        overlayFlutterView = flutterView
        overlayLifecycleOwner = lifecycleOwner
        currentOverlayPackage = app.packageName

    }

    private fun removeOverlay() {
        overlayLifecycleOwner?.registry?.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY)
        overlayFlutterView?.detachFromFlutterEngine()
        overlayView?.let { view ->
            try {
                (getSystemService(Context.WINDOW_SERVICE) as WindowManager).removeView(view)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to remove overlay view", e)
            }
        }
        // Engine persists — just signal it's paused (no view to render to)
        overlayEngine?.lifecycleChannel?.appIsPaused()

        overlayView = null
        overlayFlutterView = null
        overlayLifecycleOwner = null
        currentOverlayPackage = null
    }

    private fun navigateHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
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
                    cooldownMinutes = raw.optInt("cooldownMinutes", 0),
                )
            }
            Log.d(TAG, "Loaded ${monitoredApps.size} monitored apps")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load monitored apps", e)
        }
    }

    // ── Notification ──────────────────────────────────────────────────────────

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
