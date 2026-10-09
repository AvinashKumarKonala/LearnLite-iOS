# LearnLite — iOS Technical Assignment

A SwiftUI learning dashboard: log in, browse courses, complete lessons, watch progress update, and keep working offline.

**Demo account:** `demo@learnlite.com` / `password` (pre-filled on the login screen)
**Requirements:** Xcode 15+, iOS 17+, no third-party dependencies.

## Running it

1. Open `LearnLite.xcodeproj`, choose an iPhone simulator, press **Run** (`⌘R`).
2. Run the tests with `⌘U` (scheme: `LearnLite`).

## Features

| Area | What it does |
|---|---|
| Login | Validation, inline errors, keyboard flow (Next / Go), Keychain-backed session that survives relaunch |
| Dashboard | Overall progress, per-course progress, lesson counts and duration, **Start / Continue / Review** action |
| Course details | Lesson list, tap to complete, live progress, "Up next" marker, completion message, haptic feedback |
| Offline | Cached courses with a "saved data · updated X ago" banner; **Offline demo** toggle in the toolbar |
| Errors | Retry in empty state and inline when a refresh fails; cancellation is never shown as an error |
| Accessibility | VoiceOver labels/values/hints, Dynamic Type friendly, icon-only controls have labels |

## 1. Architecture

Lightweight **Clean Architecture + MVVM**, chosen for clear separation without over-engineering a small app:

```text
SwiftUI View → ViewModel → Use Case → Repository → API + Local Cache
```

```text
LearnLite/
├── App/            Entry point and RootView (auth switch)
├── Core/           AppContainer (composition root), AppError
├── Domain/         Models, repository protocols, use cases (no UIKit/SwiftUI/persistence)
├── Data/           Mock API, UserDefaults cache/progress, Keychain token store, repositories
└── Presentation/   Views + @MainActor view models (Root, Login, Courses, CourseDetails, Components)
LearnLiteTests/     Unit tests + test doubles
```

- **Dependency injection:** `AppContainer` builds the graph once and exposes view-model factories. Views never construct dependencies; protocols make every data source replaceable in tests.
- **View models are created once per screen** (`@StateObject` with lazy autoclosure), not on every SwiftUI re-render.
- **Value-based navigation** (`NavigationLink(value:)` + `navigationDestination`), so detail screens are built only when opened.
- **`Loaded<T>` / `DataSource`:** repositories report whether data came from the network or the cache, so the UI banner reflects what actually happened rather than guessing from a flag.

## 2. Offline Support

Courses are cached after every successful load, inside a **versioned envelope** (`schemaVersion` + `savedAt`). An incompatible or corrupt cache is discarded instead of crashing.

- The repository is **remote-first** and falls back to the cache on any failure.
- Task cancellation (e.g. leaving the screen) is propagated, never answered with stale cache.
- Opening a single course refreshes its cache entry but **never creates a partial cache**, so the offline course list can't silently shrink to one course.
- Lesson completion is stored locally and is immediately visible on the dashboard when you go back.

The **Offline demo** switch makes the whole fallback path demonstrable without touching device connectivity. In production this would be driven by `NWPathMonitor`.

## 3. Security

- The session token is stored in the **iOS Keychain** (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`), never in `UserDefaults`. Logging out deletes it.
- Keychain items survive app deletion, so the first launch after (re)install clears any stale token.
- Credentials and tokens are never logged.
- The login in this project is a mock. For production: TLS with certificate validation, short-lived access tokens with refresh-token rotation, server-side revocation on logout, and biometric re-auth for sensitive actions.

## 4. Scale — 1M users / hundreds of courses

1. Cursor/page-based pagination and incremental loading.
2. Replace `UserDefaults` with SwiftData/SQLite, with per-record versioning and expiry.
3. Sync lesson progress to the backend (idempotent writes, conflict resolution, offline queue).
4. Real authentication, token refresh and authorization.
5. Observability: crash reporting, structured logging, metrics and API latency monitoring.
6. CI/CD with automated tests, linting and release automation.

## 5. Android Implementation

The same responsibilities in **Kotlin + Jetpack Compose**:

```text
Compose UI → ViewModel/StateFlow → Use Case → Repository → Retrofit + Room
```

Coroutines handle async work, Retrofit/OkHttp the API, Room offline persistence, Hilt dependency injection, and EncryptedSharedPreferences/Keystore the session token. The UI and platform APIs change; the domain and repository boundaries stay the same.

## 6. Testing

Unit tests cover the full stack below the views, using in-memory doubles and isolated `UserDefaults` suites:

- **Domain:** progress toggling, percentages/rounding, next lesson, finished course, codable round-trip.
- **Cache:** round-trip, corrupt data, schema-version mismatch, partial-update protection.
- **Repository:** remote success, offline fallback, fallback on any error, no-cache error, error mapping, cancellation, per-course fetch.
- **Auth:** login success/failure, case-insensitive email, secure-storage failure, logout, session restore, Keychain round-trip.
- **View models:** loading states, retry, refresh failure keeps data, offline toggle, overall stats, lesson toggling, haptic counter.

## 7. Scope / Trade-offs

No backend, third-party DI framework, or real authentication — the focus is working functionality and engineering quality. The mock API simulates latency and offline mode; the repository and use-case boundaries are where a real network layer would plug in.

## 8. Demo video — 90–120 seconds

1. Launch and log in (note: relaunching keeps you signed in).
2. Show the dashboard: overall progress, per-course %, lesson counts, **Start / Continue**.
3. Open a course, complete a lesson, watch progress and "Up next" update.
4. Go back — the dashboard reflects the new progress immediately.
5. Turn on **Offline demo** — the banner appears and cached courses remain.
6. Open the course again offline — progress is still there.
7. Log out.
