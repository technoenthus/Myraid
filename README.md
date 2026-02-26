# Myraid Tasks

A production-ready Flutter task management app built for the 24-hour technical assessment.

---

## Getting Started

### Prerequisites
- Flutter 3.10+ (`flutter --version`)
- Android Studio / VS Code with Flutter plugin

### Setup

```bash
git clone <your-repo-url>
cd myraid_tasks
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Demo Credentials (DummyJSON API)

| Field    | Value         |
|----------|---------------|
| Username | `emilys`      |
| Password | `emilyspass`  |

> Tap **"Use Demo Credentials"** on the login screen to auto-fill.

---

## Architecture

```
lib/
├── core/
│   ├── constants/       # API endpoints
│   ├── errors/          # AppException (typed error handling)
│   ├── theme/           # Material 3 light/dark ThemeData
│   └── utils/           # Input validators (pure functions)
├── data/
│   ├── models/          # TaskModel, UserModel
│   ├── services/        # ApiService (Dio), StorageService
│   └── repositories/    # AuthRepository, TaskRepository
├── providers/           # Riverpod StateNotifiers
├── router/              # GoRouter configuration
├── screens/             # splash, auth, home, task form
└── widgets/             # common + task-specific reusable widgets
```

### State Management — Riverpod

`flutter_riverpod` with `StateNotifier` was chosen because:
- Compile-safe provider references (no magic strings)
- Clean separation of business logic from UI
- Simple DI via `ref.read()` — no `BuildContext` required
- First-class support for provider overrides in tests

Key providers:

| Provider | Purpose |
|---|---|
| `authProvider` | Login / logout / session restore |
| `taskProvider` | CRUD + infinite scroll pagination |
| `filteredTasksProvider` | Derived filtered task list |
| `taskFilterProvider` | Selected filter chip state |
| `themeProvider` | Dark / light mode (persisted) |

---

## API Integration

**Backend:** [DummyJSON](https://dummyjson.com) — free hosted REST API with real JWT auth.

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/auth/login` | Authenticate, receive JWT |
| `GET` | `/auth/me` | Verify token / restore session |
| `GET` | `/todos/user/{id}?limit=10&skip=N` | Paginated task list |
| `POST` | `/todos/add` | Create task |
| `PUT` | `/todos/{id}` | Update task |
| `DELETE` | `/todos/{id}` | Delete task |

### Local-First Strategy

DummyJSON returns fake success responses but does not persist between sessions.
Every API response is cached in `SharedPreferences`. On relaunch the app loads
from cache instantly while refreshing from the API in the background. If the
network is unavailable, cached data is shown with no crash.

### Token Storage
- JWT → `FlutterSecureStorage` (Android Keystore / iOS Keychain)
- User profile → `SharedPreferences`

---

## Features

- Login with real JWT + session restore on relaunch
- Registration screen with full field validation
- Task list (Title, Description, Status, Due Date)
- Create / Edit / Delete tasks
- Filter by All / Pending / In Progress / Completed
- Pull-to-refresh
- Infinite scroll / pagination
- Shimmer loading skeleton
- Empty state illustration
- Error state with retry
- Swipe-to-delete with confirmation
- Dark mode (persisted preference)
- Entrance animations (flutter_animate)
- 23 unit tests covering CRUD, model logic, and validators

---

## Running Tests

```bash
flutter test
```

## Building APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Declarative named-route navigation |
| `dio` | HTTP client with interceptors |
| `flutter_secure_storage` | Secure JWT storage |
| `shared_preferences` | Local task cache |
| `google_fonts` | Poppins typography |
| `flutter_animate` | Declarative animations |
| `shimmer` | Loading skeleton |
| `intl` | Date formatting |
| `mockito` | Unit test mocking |

---

## Architecture Decisions

**Riverpod over BLoC / Provider** — Eliminates `BuildContext` dependency, provides
compile-time safety, and `StateNotifier` keeps business logic in pure Dart classes
that are trivially unit-testable without a widget tree.

**GoRouter** — Declarative URL-based routing with `extra` parameter passing and
deep-link support, with far less boilerplate than raw Navigator 2.0.

**Local-first caching** — `TaskRepository` writes every mutation to SharedPreferences
and reads on startup, giving persistence while still demonstrating real API integration
patterns (optimistic updates + sync).
