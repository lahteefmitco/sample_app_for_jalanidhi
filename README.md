# Jalanidhi Sample – feature-based Flutter architecture

A demonstration app (Android, iOS, Windows, Web, macOS, Linux) built on
[JSONPlaceholder](https://jsonplaceholder.typicode.com/) with a strict,
scalable architecture: **Cubit per screen**, **feature folders**, **GetIt**
dependency injection, **Dio** networking and **Sizer** responsive sizing.

## Using this project as a template (Claude rules)

- `CLAUDE.md` – the mandatory rules Claude follows in this repository
  (architecture, state, effects, busy/cancellation, DI, routing, UI, code
  style, testing, definition of done).
- `docs/claude/` – detailed guides: `architecture.md`, `ui-guidelines.md`,
  `code-style.md`, `testing.md`.
- `.claude/skills/new-screen/` – `/new-screen`: generates a list or form
  screen (+ model/repository and tests) from verified templates
  (`scripts/render.py`).
- `.claude/skills/new-app-from-template/` – `/new-app-from-template`: starts a
  new app (own package name and bundle ids) with this architecture and without
  the demo features.

## Run

```bash
flutter pub get
flutter run -d chrome        # or macos / windows / linux / an emulator
flutter analyze
flutter test
```

Demo login (created on first launch, stored locally): `demo@example.com` /
`Demo@1234`. JSONPlaceholder has **no authentication**, so login/register are a
local simulation: accounts live in secure storage as a salted SHA-256 hash.
JSONPlaceholder also **does not persist writes**; created/edited/deleted posts
and toggled todos are kept in a memory-only overlay for the running session.

## Folder structure

```
lib/
├── main.dart
├── app/                     app shell
│   ├── app.dart             Sizer + MaterialApp
│   ├── app_config.dart
│   ├── app_initializer.dart bootstrap (DI, observer, initial route)
│   ├── app_routes.dart      route table, creates one Cubit per route
│   ├── app_theme.dart / app_bloc_observer.dart
│   └── dependency_injection.dart   GetIt registrations
├── core/                    app-wide, feature-agnostic code
│   ├── constants/           strings, colors, dimensions (Sizer), route names, keys
│   ├── network/             ApiClient (the only Dio user), endpoints, interceptors, exceptions
│   ├── storage/             LocalStorageService (SharedPreferences), SecureStorageService
│   ├── services/            firebase_service.dart (optional, no-op by default)
│   ├── state/               ScreenState, ScreenCubit, UiEffect  (see below)
│   ├── errors/ utils/       exceptions, logger, validators, platform capabilities
│   └── widgets/             loader, button, text field, error/empty view,
│                            ScreenEffectListener, ProgressDialog, AppSnackbar,
│                            ResponsiveListGrid, MaxWidthContainer
├── global/                  data shared by several features
│   ├── models/              User, Post, Comment, Todo, Album, AuthUser …
│   └── repositories/        User, Post, Comment, Todo, Album, Auth
└── features/<feature>/
    ├── widgets/             feature-level shared widgets (e.g. auth_header)
    └── screens/<screen>/
        ├── <screen>_screen.dart
        ├── cubit/           <screen>_cubit.dart, <screen>_state.dart
        ├── models/          screen-specific models (only when needed)
        ├── repositories/    screen-specific repository (only when needed)
        └── widgets/         one widget per file
```

Features: `authentication` (login, register), `home` (dashboard + menu),
`users` (list, details), `posts` (list, details, form), `comments` (list),
`todos` (list), `albums` (list, details).

## State management

Every screen has its **own Cubit**; there is no `AppCubit` and no global Cubit
at all (shared data lives in the shared repositories in `global/`).

A screen state is `ScreenState<B>` = **BuildState + ListenerState + effectId**:

| Part | Purpose | Consumed by |
|---|---|---|
| `build` (`B`, per-screen immutable class) | what widgets render: status, lists, query, selections, form errors … | `BlocBuilder` / `BlocSelector` |
| `effect` (`UiEffect?`) | one-time actions: progress, snackbar, navigation, confirm dialog, bottom sheet | `ScreenEffectListener` (a `BlocListener`) |
| `effectId` | increases for every effect, so an old effect can never replay | `listenWhen` |

`ScreenCubit<B>` exposes `emitBuild(...)` (new build state, clears the effect)
and `emitEffect(...)` (new effect + new id, **same build instance**, so
builders — which use `buildWhen: buildStateChanged` — do not rebuild).
Cubits never touch `BuildContext`, navigate, or show UI; they only emit effects.

Complex screens (user list, post list) split the build state into groups
(`header` + `content`) and use `BlocSelector`, so e.g. typing in the search box
does not rebuild the list shell.

**No `copyWith` anywhere.** A Cubit keeps its working data in private fields
(`_status`, `_query`, `_users` …) and builds a brand-new immutable state from
them with a small `_render()` method. Models are plain immutable classes; a
changed model is created with its constructor (e.g. `PostModel(...)` in
`PostFormCubit`). `test/architecture_rules_test.dart` fails if `copyWith` (or
Equatable, `setState`, `ChangeNotifier`, Dio outside `core/network`) appears.

Other rules in force: `TextEditingController`s live in the Cubit and are
disposed in `close()`; no `setState` anywhere; no `Equatable`, `ChangeNotifier`
or GetX; every model overrides `toString()`.

## Theme (System / Day / Night)

The default is the **system** theme. `ThemeModeButton` (app bar of the login
and home screens) lets the user choose *System default*, *Day (light)* or
*Night (dark)*. The choice is held by `ThemeCubit` (`global/cubits/theme/`,
the app's only global Cubit, because `MaterialApp` needs it above every
screen), persisted in shared preferences and applied through
`MaterialApp.themeMode` in `app/app.dart`.

## Data flow

`Widget → Cubit → Repository → ApiClient (Dio) → JSONPlaceholder`

* Widgets never call Dio or repositories. Cubits never call Dio.
* `ApiClient` is the only Dio user: base URL, timeouts, request/response/error
  interceptors (headers redacted, no bodies logged), typed `ApiResponse<T>` and
  `ApiException` (network / timeout / bad response / invalid response).
* Shared repositories are injected into the screen Cubits that need them; each
  Cubit copies what it needs into its own build state.

## Request cancellation

Read requests can be cancelled through a `RequestToken`
(`core/network/request_token.dart`, a thin wrapper so Cubits never import Dio):

* Every screen Cubit gets tokens from `ScreenCubit.newRequestToken(purpose)`.
  Asking for a new token with the same purpose (e.g. `'load'`) **cancels the
  previous request**, so pull-to-refresh or "Retry" while a load is running
  can never let an older answer overwrite a newer one.
* `ScreenCubit.close()` **cancels every running request** of the screen, so
  leaving a screen mid-load stops the download.
* A cancelled request fails with `ApiErrorType.cancelled`; Cubits check
  `isCancellation(error)` and stay silent (no error view, no snackbar).
* Writes (create / update / delete post, toggle todo) are deliberately **not**
  cancellable: the server may already have applied them and the user expects
  them to finish.

Parallel loads use `Future.wait`, which rethrows the first error unchanged,
so the user sees the real reason (e.g. "No internet connection").

## Progress: square loader and locked screens

* **Square loader** (`core/widgets/square_loader.dart`, a Lottie animation taken
  from the OditBiz ERP app, `assets/animation/`) replaces every Material
  `CircularProgressIndicator`: `ProgressDialog` shows it above the screen
  while a write request runs, `CommonLoader` shows it inside a screen while its
  data loads. White squares in dark mode, dark squares in light mode.
* **Busy flag.** `ScreenCubit.isBusy` is `true` while a request is running
  (`showProgress()` / `hideProgress()` for writes, `startBlockingRequest()` /
  `endBlockingRequest()` for the main load). It lives in a `ValueNotifier`, not
  in the build state, so toggling it never rebuilds or re-emits the screen.
* **`BusyGuard`** (`core/widgets/busy_guard.dart`) wraps each screen body (and
  the app-bar actions / floating buttons) and, while busy, ignores taps,
  removes keyboard focus and dims the content. The back button is never
  guarded, so leaving a screen (which cancels its reads) always works.
* **Writes are single-shot.** Every POST / PUT / PATCH / DELETE action
  (`login`, `register`, post save, post delete, todo toggle) starts with
  `if (isBusy) return;`, so a second tap or Enter key cannot send it twice.

## Navigation and dialog animations

* **Screen changes** (`core/widgets/page_transitions.dart`): going forward, the
  new page slides in from the right towards the left (the page below drifts a
  little to the left); going back is the exact reverse, the page slides out
  towards the right. It is registered once in `AppTheme.pageTransitionsTheme`
  for every platform, so all `AppRoutes` pages use it. (The iOS edge-swipe
  back gesture of the Cupertino transition is not included.)
* **Dialogs** (`core/widgets/app_dialog.dart`): every dialog fades in, pops in
  with a small overshoot and rises slightly over a dimmed background; closing
  plays it backwards. `AppDialog.confirm` shows `AppConfirmDialog`, a rounded
  card with an icon badge, title, message and Cancel / Confirm buttons. Actions
  that cannot be undone (`ShowConfirmationEffect.isDestructive`, used for
  deleting posts) get a red icon and a red confirm button. The square loader
  (`ProgressDialog`) uses the same animation.
* **Bottom sheets** (details of a comment, todo or photo) have rounded top
  corners, a drag handle and a smooth slide-up.

## Code style

`analysis_options.yaml` enforces, on `lib/` and `test/`:

* `always_specify_types` – every variable, closure parameter and generic has
  an explicit type (`final List<UserModel> users = <UserModel>[];`, never
  `final users = [];`),
* `always_declare_return_types` – every function declares what it returns,
* `public_member_api_docs` – every public class, member and function has a
  `///` doc comment (private members, Bloc widgets and screen sections are
  commented by convention too),
* strict casts, strict inference and strict raw types.

## Dependency injection (`app/dependency_injection.dart`)

| Component | Registration |
|---|---|
| Config, storage services, Dio | singleton |
| `ApiClient`, repositories | lazy singleton |
| Screen Cubits | **factory** (new instance per screen) |

`AppRoutes` creates each Cubit inside a `BlocProvider`, which closes it when the
route leaves the stack, so Cubit lifetime = navigation lifetime. Cubits that need
an argument use `registerFactoryParam` (user id, post id, album).

## Navigation

Plain `Navigator` with named routes (`core/constants/route_names.dart`,
`app/app_routes.dart`). Cubits emit `NavigateEffect`/`PopEffect`;
`ScreenEffectListener` performs them and calls `cubit.onNavigationReturn(result)`
when a pushed page returns (used to refresh lists after create/edit/delete).

## Responsiveness

`Sizer` wraps the app. Sizer's `%` units are relative to the whole window, so
`AppDimensions` clamps every Sizer value to a sane range (a `4.w` padding is
never 77 px on a desktop). Layouts: one column on phones, grids on tablets and
desktops (`ResponsiveListGrid`, based on `LayoutBuilder`), two-pane detail
screens ≥ 800 px, content capped at 1100 px (`MaxWidthContainer`).

## Logging

`core/utils/app_logger.dart` (`screenLog`, `cubitLog`, `repositoryLog`,
`errorLog`, `generalLog`) — debug builds only. Screens log init/dispose, Cubits
log creation, every state change (via `AppBlocObserver`) and close, repositories
and the API interceptors log operations. Passwords, tokens and sensitive headers
are never logged.

## Platform notes

* `PlatformCapabilities` (no `dart:io`) gates platform-specific features.
* Firebase is optional and **not** a dependency: see
  `core/services/firebase_service.dart` for how to plug it in.
* Android: `INTERNET` permission added to the main manifest.
* macOS: `com.apple.security.network.client` entitlement added; secure storage
  uses the legacy keychain (no provisioning profile needed).

## Tests (`flutter test`)

* `test/architecture_rules_test.dart` – guards the project rules (see above).
* `test/widgets` – `ScreenEffectListener`: snackbars, duplicate-safe progress,
  confirmation dialog, info sheet, navigation result, no effect replay.
* `test/core/request_cancellation_test.dart` – cancelled requests, token
  replacement, cancellation on close, silent handling in Cubits, and the
  dashboard showing the real network error.
* `test/core` – validators, ApiClient (success, query params, 404, malformed
  payload, timeouts), `ScreenCubit` effect semantics.
* `test/global` – models, `PostRepository` (cache, overlay create/edit/delete),
  `AuthRepository` (hashing, login/register rules).
* `test/global` also covers `ThemeCubit` and `ThemeModeButton`;
  `test/app/theme_app_test.dart` checks System/Day/Night inside the real app.
* `test/features` – Cubit tests for every screen (login, register, users,
  posts incl. form/details, comments, todos, albums, home) and widget tests
  (login, register, user list incl. responsive layout, todos, post form).
* `test/app/app_flow_test.dart` – whole-app workflows with the real router, DI,
  Cubits and repositories over a fake HTTP backend (login → dashboard → users →
  details → logout; post create/delete).

No test touches the live API: `test/helpers/fake_backend.dart` is an offline
Dio adapter.

## Dependencies

`flutter_bloc`, `dio`, `get_it`, `sizer`, `shared_preferences`,
`flutter_secure_storage`, `crypto` (password hashing for the local auth
simulation); dev: `bloc_test`, `mocktail`. The project also keeps the
template's `material_ui` package, so Material widgets are imported from
`package:material_ui/material_ui.dart`.

## Not implemented / known limits

* No real integration test on a device (`integration_test`); the app-flow
  widget test covers the same workflows headlessly.
* Photo thumbnails come from `via.placeholder.com`, which is frequently
  unreachable; tiles fall back to the color encoded in the URL.
* Posts/todos changes are session-only (JSONPlaceholder does not persist).
* Only the web build was run visually; Android/iOS/desktop were not launched.
