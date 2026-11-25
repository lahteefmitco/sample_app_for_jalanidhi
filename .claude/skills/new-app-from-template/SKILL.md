---
name: new-app-from-template
description: Start a new Flutter application from this reference project - creates a fresh project with the user's name/org, copies the architecture (core, app shell, auth, home, theme, loader, rules, tests), removes the JSONPlaceholder demo features and points it at the new backend. Use when the user wants to build a new app based on this sample.
---

# New app from this template

Goal: a new project with its own package name and bundle ids that keeps this
project's architecture, rules (`CLAUDE.md`, `docs/claude/`, `.claude/skills/`)
and quality gates, without the demo features.

Creating a fresh project with `flutter create` (instead of renaming this one)
gives correct Android/iOS/macOS/Windows/Linux/Web identifiers for free.

## 1. Ask the user

- App display name (e.g. "Oditbiz Sales") and Dart package name
  (snake_case, e.g. `oditbiz_sales`).
- Organisation id (e.g. `com.oditbiz`).
- Target folder (must not exist yet).
- Backend base URL, and whether authentication is real (API) or still
  simulated.
- Which demo features to keep as examples (default: none).
- Theme seed color (default: keep `0xFF0B7A9E`).

Confirm before writing outside this repository.

## 2. Create the project

```bash
flutter create --org <org> --project-name <package> --platforms android,ios,web,windows,macos,linux <target>
```

## 3. Copy the architecture

From this repository into `<target>` (overwrite the generated files):

- `lib/` (all), `test/` (all), `assets/`
- `analysis_options.yaml`, `CLAUDE.md`, `docs/claude/`, `.claude/skills/`
- `README.md` (rewrite the intro afterwards)

Never copy `build/`, `.dart_tool/`, `.idea/`, `*.iml`, `pubspec.lock` or the
platform folders.

Then:

1. In `<target>/pubspec.yaml`, copy the `dependencies` / `dev_dependencies`
   of this project (and the `assets:` block under `flutter:`), and keep the
   new `name:`. Run `flutter pub get`.
2. Replace the package name in every Dart import:
   `package:sample_app_for_jalanidhi/` → `package:<package>/` (in `lib/` and
   `test/`).
3. Platform settings the app needs:
   - `android/app/src/main/AndroidManifest.xml`: add
     `<uses-permission android:name="android.permission.INTERNET"/>` before
     `<application`.
   - `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:
     add `com.apple.security.network.client` = `true`.

## 4. Configure

- `lib/core/network/api_endpoints.dart`: `baseUrl` and the real endpoints.
- `lib/core/constants/app_constants.dart`: `appName`, page size, timeouts.
- `lib/core/constants/app_colors.dart`: brand `seed` color.
- `lib/core/constants/app_strings.dart`: app texts.
- `web/index.html` / `web/manifest.json`: title and description.
- Authentication:
  - Real backend: replace the local simulation inside
    `global/repositories/auth_repository.dart` with API calls (keep the
    public methods `login`, `register`, `logout`, `isLoggedIn`,
    `currentUser`), store tokens only through `SecureStorageService`, and add
    an auth interceptor in `core/network/dio_interceptors.dart` that adds the
    token (never log it).
  - Remove the demo account (`AppConstants.demo*`,
    `AuthRepository.ensureDemoAccount`, its call in `AppInitializer`, the demo
    hint on the login screen) unless the user wants it.

## 5. Remove the demo features (unless kept)

For each of `users`, `posts`, `comments`, `todos`, `albums`:

1. Delete `lib/features/<feature>/` and `test/features/<feature>/`.
2. Delete its models/repositories in `lib/global/` when no other code uses
   them (`user`, `address`, `company`, `post`, `comment`, `todo`, `album`).
3. Remove its registrations from `app/dependency_injection.dart`, its cases
   and imports from `app/app_routes.dart`, its names from
   `core/constants/route_names.dart`, its texts from `app_strings.dart`, its
   endpoints from `api_endpoints.dart`.
4. Home dashboard: remove the related `HomeCubit.menuItems`, the summary
   numbers in `HomeSummary`/`HomeCubit.load` and their tests.
5. Delete or adapt tests that used them (`test/app/app_flow_test.dart`,
   `test/core/request_cancellation_test.dart` user-list/home cases,
   `test/features/write_actions_busy_test.dart`, `test/helpers/sample_data.dart`).
   Keep `test/helpers/*`, `architecture_rules_test.dart`, core, theme,
   loader, dialog, transition and auth tests.

Keep everything in `core/`, `app/`, `global/cubits/theme`,
`global/widgets`, `features/authentication`, `features/home`.

## 6. First real feature

Use the `/new-screen` skill (kinds `data`, `list`, `form`) for the first
business entity, then link it from the home menu.

## 7. Verify and report

```bash
dart format lib test
```

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter run -d chrome
```

All checks must be clean. Report what was created, configured and removed,
and anything left for the user (e.g. signing, Firebase, real auth endpoints).
