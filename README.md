# Fricare - Friction Designer

Fricare introduces intentional friction before opening apps you find yourself compulsively reaching for. Configure delays, puzzles, math challenges, confirmation prompts, or chain multiple friction types together to build mindful habits around app usage.

**Android only. No root required.**

## Features

- **Hold to Open** - Press and hold for a configurable duration before the app opens
- **Tap Puzzle** - Tap highlighted tiles in the correct sequence
- **Math Challenge** - Solve arithmetic problems (like those alarm clock apps)
- **Confirmation Prompts** - Multi-step "Are you sure?" screens
- **Challenge Chaining** - Combine multiple friction types in sequence (e.g. Math then Confirmation)
- **Dynamic Friction Modes**
  - *Always* - Friction on every open
  - *After N Opens* - Free opens per day, then friction kicks in
  - *Escalating* - Friction intensifies with each successive open
- **Configurable Parameters** - Adjust delay duration, number of puzzle taps, math problems, confirmation steps, and randomization
- **Per-App Configuration** - Different friction types and intensity for each app
- **Starts on Boot** - Friction service auto-restarts when your device reboots
- **No Internet Required** - Everything runs locally on your device

## How It Works

1. Select apps you want to add friction to from your installed apps
2. Configure the friction type, intensity, and trigger mode for each app
3. Enable the friction toggle
4. When you open a protected app, Fricare intercepts and shows the friction challenge
5. Complete the challenge to proceed, or go back

Fricare uses Android's `UsageStatsManager` to detect foreground app changes and displays a Flutter-based overlay challenge. No accessibility service or root access needed.

## Building from Source

### Prerequisites

- Flutter >= 3.29.0
- Dart SDK >= 3.7.0
- Android SDK with API 35+
- Java 17

### Build

```bash
# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK (requires signing config)
flutter build apk --release
```

### Pre-commit Hooks

```bash
# Activate formatting, analysis, and test checks before each commit
bash .githooks/setup.sh
```

This runs `dart format`, `flutter analyze`, and `flutter test` on every commit, matching the CI pipeline.

### Release Signing

Create `android/key.properties` (gitignored):

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=your-key-alias
storeFile=/path/to/your-keystore.jks
```

## Architecture

Fricare follows Domain-Driven Design (DDD):

```
lib/
├── domain/          # Models, repository interfaces
├── infrastructure/  # Hive persistence, platform services
├── presentation/    # Screens, widgets, Riverpod providers
└── overlay/         # Separate Flutter entrypoint for friction overlay
```

**Key technologies:** Flutter, Riverpod, Hive, Kotlin (native Android service)

## Permissions

| Permission | Purpose |
|---|---|
| `PACKAGE_USAGE_STATS` | Detect which app is in the foreground |
| `SYSTEM_ALERT_WINDOW` | Display friction overlay on top of apps |
| `FOREGROUND_SERVICE` | Run background monitoring service |
| `RECEIVE_BOOT_COMPLETED` | Restart service after device reboot |
| `QUERY_ALL_PACKAGES` | List installed apps for selection |

## Downloads

APK releases are available on the [Releases](../../releases) page.

## License

This project is proprietary software. All rights reserved.
