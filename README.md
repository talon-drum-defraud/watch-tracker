# WatchTracker

A personal Android app for tracking the accuracy of mechanical watches against atomic time via NTP servers.

---

## Features

### Core
- **Record Reading** — tap the button, then set what your watch shows (HH:MM:SS). The app captures NTP time instantly at the tap moment and calculates the offset
- **Live offset preview** — see the offset update in real time as you adjust the time spinners
- **±1s nudge buttons** — fine-tune seconds precisely without scrolling
- **Last reading hint** — tappable suggestion based on your previous offset
- **Offset colour coding** — grey (±2s excellent), amber (fast), green (slow)

### Series
- Every watch starts on **Series 1** automatically
- **Start New Series** after setting or servicing a watch — previous series is archived, graphs start fresh
- Add an optional name and note when starting a new series (e.g. "After service", "Post regulation")
- **Series Archive** — browse all past series, each with its own full stats and graphs

### Stats & Graphs
- **History tab** — full reading log with colour-coded icons, swipe left to delete
- **Stats tab** — three graphs and summary cards:
  - *Offset over time* — absolute accuracy at each reading, colour-coded dots
  - *Daily drift rate* — seconds gained/lost per day between readings (3+ readings needed)
  - *Projection* — dashed line showing where your watch will be in 7 days at current drift rate
- Summary cards: total readings, average drift rate, best reading

### NTP Time Source
- Queries NTP servers directly for ±10–50ms accuracy
- **9 servers available:** IIT Bombay, NTP Pool India, NTP Pool Asia, Google, Cloudflare, Apple, Microsoft, Meta, NTP Pool Global
- **Speed test** — benchmarks all servers simultaneously, shows latency in ms, auto-selects the fastest
- Automatic fallback chain: preferred NTP → 2 other NTP servers → WorldTimeAPI (HTTP) → device clock
- Every reading stores which source was used

### Per-watch settings
- **Reminders** — optional, configurable per watch: Off / 12h / Daily / 2 days / 3 days / Weekly
- **Mark Set / Mark Wound** — timestamp when you last set or wound each watch
- Store name, brand, and movement per watch (up to 5 watches)

### App settings
- **Appearance** — Light / Dark / System theme
- **NTP server picker** with speed test
- Theme and server preference persist across restarts

---

## How to use

### Recording a reading
1. Open a watch → tap **Record Reading**
2. The app fetches NTP time immediately — you'll see the reference time appear
3. Adjust the HH:MM:SS spinners to match exactly what your watch shows
4. The offset calculates live — tap **Save**

### Starting a new series
After setting or regulating your watch:
1. Open the watch → History tab
2. Tap **Start New Series** in the series banner
3. Optionally name it (e.g. "After regulation") and add a note
4. All future readings belong to the new series — old data is archived, not deleted

### Viewing past series
Tap **"X archived"** in the series banner → browse each past series with its own graphs

---

## Building from source

### Prerequisites
- Flutter SDK 3.x stable channel
- Android Studio or VS Code with Flutter/Dart extensions
- Java 17+
- Android device or emulator (API 31+ / Android 12+)

### Run locally
```bash
git clone <your-repo-url>
cd watch_tracker
flutter pub get
flutter run
```

### Build via GitHub Actions (recommended)
Push to `main` or `master` — the workflow builds a signed release APK automatically.

**Required GitHub Secrets:**
| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | Base64-encoded keystore file |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | `watch_tracker` |
| `KEY_PASSWORD` | Key password |

Download the APK from the **Actions** tab → latest run → **Artifacts** section.

### Install on device
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```
Or transfer the APK to your phone and tap to install (enable "Install unknown apps" first).

---

## Project structure

```
lib/
  main.dart
  models/
    watch.dart              # Watch with notification prefs
    time_reading.dart       # Offset reading with series link
    series.dart             # Series (a run of readings)
  providers/
    watch_provider.dart     # All state + series management
    theme_provider.dart     # Light/Dark/System theme
  services/
    database_helper.dart    # SQLite (schema v3 with migrations)
    time_service.dart       # NTP + HTTP fallback + benchmarking
    notification_service.dart # Configurable per-watch reminders
    prefs_service.dart      # Persistent preferences
  screens/
    home_screen.dart        # Watch list with status dots
    watch_detail_screen.dart # History + Stats tabs
    series_archive_screen.dart # Browse archived series
    add_watch_screen.dart   # Add / edit watch
    settings_screen.dart    # Theme + NTP speed test
  widgets/
    record_reading_button.dart # Tap-to-record with NTP dialog
    stats_tab.dart          # Three graphs + summary cards
    watch_card.dart         # Home screen card with status dot
  theme/
    app_theme.dart          # Light + Dark Material 3 themes
android/
  app/build.gradle          # Signing config via env vars
.github/workflows/build.yml # CI: build + sign + upload APK
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `sqflite` | SQLite local storage |
| `ntp` | Direct NTP time queries |
| `http` | HTTP fallback time sources |
| `fl_chart` | Offset, drift rate, projection graphs |
| `flutter_local_notifications` | Per-watch reminders |
| `timezone` | Timezone support for notifications |
| `provider` | State management |
| `uuid` | Unique IDs |
| `intl` | Date/time formatting |
| `path` | File path utilities |

---

## Permissions

| Permission | Reason |
|---|---|
| `INTERNET` | NTP + HTTP time fetching |
| `POST_NOTIFICATIONS` | Watch reminders (Android 13+) |
| `SCHEDULE_EXACT_ALARM` | Precise notification scheduling |
| `RECEIVE_BOOT_COMPLETED` | Reschedule notifications after reboot |
| `VIBRATE` | Haptic feedback |
