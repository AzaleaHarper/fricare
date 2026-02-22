# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Flutter binary is at /opt/flutter/bin/flutter
/opt/flutter/bin/flutter pub get          # Install dependencies
/opt/flutter/bin/flutter analyze          # Static analysis (must pass clean)
/opt/flutter/bin/flutter test             # Run all tests (83 tests)
/opt/flutter/bin/flutter test test/domain/friction_config_test.dart  # Single file
/opt/flutter/bin/flutter build apk --debug   # Debug APK
/opt/flutter/bin/flutter build apk --release # Release APK (needs android/key.properties)
```

Pre-commit hooks (`.githooks/pre-commit`) run format check, analyze, and test.

## Architecture

Fricare is a Flutter + Kotlin Android app that adds "friction" (hold buttons, puzzles, math challenges, confirmations) before opening selected apps to reduce impulsive usage.

### Layers (DDD)

- **`lib/domain/`** — Pure models and repository interfaces. No Flutter imports. Key models: `FrictionApp`, `FrictionConfig`, `FrictionKind`, `ChainStep`, `FrictionSettings`.
- **`lib/infrastructure/`** — Hive persistence (`HiveFrictionAppRepository`), MethodChannel bridge (`method_channels.dart`), and services (`AppSyncService`, `InstalledAppsService`).
- **`lib/presentation/`** — Riverpod providers, screens, widgets, theme. State managed via `NotifierProvider` (`FrictionAppsNotifier`, `SettingsNotifier`).
- **`lib/overlay/`** — Separate Flutter entry point (`overlayMain`) for the friction overlay UI. Runs in its own Dart isolate within the foreground service.

### Kotlin Native (`android/.../com/fricare/fricare/`)

- **`MainActivity.kt`** — MethodChannel handlers for `com.fricare/friction` (permissions, service control) and `com.fricare/sync` (push app configs + theme to SharedPreferences).
- **`AppLaunchDetectorService.kt`** — Foreground service polling `UsageStatsManager` every 500ms. Pre-warms a `FlutterEngineGroup` child engine on startup. Pushes friction config to overlay via `com.fricare/overlay` channel.
- **`BootReceiver.kt`** — Restarts the service after device reboot.

### Overlay System (Pre-warmed Engine, Push-based)

The overlay is architecturally distinct from the main app:

1. **Service startup** → creates `FlutterEngineGroup`, spawns child engine running `overlayMain` entry point. Engine stays warm.
2. **App detected** → `showFrictionOverlay()` pushes config via `invokeMethod('showFriction', {...})` to the already-running Dart isolate.
3. **Dart side** → `OverlayScreen` receives config in `setMethodCallHandler`, does `setState` to render friction widget.
4. **Completion/cancel** → Dart calls `frictionComplete` or `frictionCancelled` back to Kotlin. Service records result, removes overlay view, navigates home on cancel.
5. **Engine persists** — only the `FlutterView` + `FrameLayout` are torn down; the engine is reused for the next overlay.

Critical: Uses `FlutterTextureView` (not `SurfaceView`) to avoid `SurfaceSyncGroup` conflicts with `TYPE_APPLICATION_OVERLAY`.

### Data Flow: Dart → Kotlin

Friction configs stored in Hive (Dart) are synced to SharedPreferences (Kotlin) via `AppSyncService.syncToNative()` through the `com.fricare/sync` MethodChannel. The service reads SharedPreferences to know which apps to monitor and what friction to show.

### Enum Index Parity

`FrictionKind` enum indices must match between Dart (`friction_type.dart`) and Kotlin (`AppLaunchDetectorService.kt` companion object constants `KIND_NONE=0`, `KIND_HOLD=1`, `KIND_PUZZLE=2`, etc.). If you add/reorder enum values, update both sides.

## Test Helpers

- `test/helpers/fake_repository.dart` — In-memory `FrictionAppRepository` for tests.
- `test/helpers/test_setup.dart` — `setupMethodChannelMocks()`, `createTestContainer()`, `sampleApp()`, `sampleConfig()`.
- Overlay tests use `StandardMethodCodec().encodeMethodCall()` + `handlePlatformMessage()` to simulate Kotlin pushing config.

## Hive Code Generation

Models with `@HiveType` use generated adapters (`*.g.dart`). After changing Hive-annotated fields, run:

```bash
/opt/flutter/bin/dart run build_runner build --delete-conflicting-outputs
```
