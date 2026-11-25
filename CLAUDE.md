# Project rules for Claude

This repository is a **reference Flutter project**. Its architecture, folders
and conventions are the template for building other applications (business
apps / ERP). Every new screen, feature or app must follow the rules below so
all projects stay consistent, testable and readable by junior developers.

The rules are mandatory. When a request conflicts with them, say so and ask
before deviating.

## Stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.50+, Dart 3.14+ (Material from `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`) |
| State | `flutter_bloc` **Cubit** only (one per screen) |
| HTTP | `dio`, only inside `lib/core/network/` |
| DI | `get_it` (`lib/app/dependency_injection.dart`) |
| Navigation | Flutter `Navigator` + named routes (`RouteNames`, `AppRoutes`) |
| Responsive | `sizer` through `AppDimensions` (clamped) + `LayoutBuilder` |
| Storage | `shared_preferences` (non-sensitive), `flutter_secure_storage` (sensitive), behind interfaces |
| Loader | `lottie` square loader (`SquareLoader`) |
| Tests | `flutter_test`, `bloc_test`, `mocktail`, offline `FakeBackend` |

Platforms: Android, iOS, Web, Windows, macOS, Linux.

## Commands

```bash
flutter pub get
flutter analyze          # must print "No issues found!"
flutter test             # must pass 100 %
dart format lib test
flutter run -d chrome    # demo login: demo@example.com / Demo@1234
```

Always finish a change with `dart format lib test`, `flutter analyze` and
`flutter test`, and report the real result.

## Folder structure

```
lib/
  main.dart
  app/        app.dart, app_config.dart, app_initializer.dart, app_routes.dart,
              app_theme.dart, app_bloc_observer.dart, dependency_injection.dart
  core/       constants/ errors/ network/ services/ state/ storage/ utils/ widgets/
  global/     cubits/ (theme only)  models/  repositories/  widgets/
  features/<feature>/
    widgets/                       widgets shared by screens of this feature
    screens/<screen>/
      <screen>_screen.dart
      cubit/<screen>_cubit.dart, cubit/<screen>_state.dart
      models/        (only if needed)
      repositories/  (only if needed: data used by this screen only)
      widgets/       one widget per file
test/  mirrors lib/ (+ helpers/, app/, widgets/, architecture_rules_test.dart)
```

Create folders only when they get files. Data used by more than one screen
goes to `global/models` + `global/repositories`; data used by one screen stays
in that screen's `models/` / `repositories/`.

## Non-negotiable rules

### State management
1. **One Cubit per screen**, extending `ScreenCubit<B>` (`core/state/screen_cubit.dart`).
   Never a global `AppCubit`; never share a screen Cubit between screens. The
   only global Cubit is `ThemeCubit` (needed above `MaterialApp`). Add a new
   global Cubit only for app-wide state that genuinely lives above all screens.
2. Screen state = `ScreenState<B>`: **BuildState** (`build`, what widgets draw)
   + **one-time effect** (`effect`) + `effectId`. Define
   `typedef <Screen>State = ScreenState<<Screen>BuildState>;`.
3. BuildState classes are `@immutable`, have only a `const` constructor with
   defaults, final fields and a `toString()`. **No `copyWith` anywhere in the
   project** (models, states, cubits, tests). The Cubit keeps its working data
   in private fields and builds a new state in a private `_render()` method.
4. Navigation, snackbars, dialogs, bottom sheets and progress are **effects**
   (`ScreenCubit.navigateTo`, `showErrorMessage`, `showSuccessMessage`,
   `showProgress`/`hideProgress`, `emitEffect(ShowConfirmationEffect(...))`,
   `PopEffect`, `ShowInfoSheetEffect`). They never go into BuildState and a
   Cubit never touches `BuildContext` / `Navigator`.
5. Every screen wraps its `Scaffold` in `ScreenEffectListener<C, B>`; every
   `BlocBuilder` uses `buildWhen: buildStateChanged`. Complex screens split
   BuildState into groups (e.g. `header` + `content`) rendered with
   `BlocSelector`.
6. Business logic (filtering, sorting, pagination, validation, calculations)
   lives in the Cubit, never in widgets.
7. `TextEditingController`s (and other disposables) are fields of the Cubit
   and are disposed in `close()` before `super.close()`.
8. **No `setState` for screen state, no `ChangeNotifier` state management, no
   GetX, no Equatable.** (`ScreenCubit` uses one private `ValueNotifier` for
   the busy flag; do not add others.)

### Data, network, cancellation
9. Widgets → Cubit → Repository → `ApiClient` → Dio. Widgets never call
   repositories; Cubits never import Dio; only `core/network/` and
   `app/dependency_injection.dart` import `package:dio`.
10. All paths live in `ApiEndpoints`; never hard-code URLs.
11. Every repository READ method accepts `RequestToken? requestToken` and
    passes it to `ApiClient`. Cubits get tokens from `newRequestToken(purpose)`
    (or `startBlockingRequest(purpose)` for the main load). A new token with
    the same purpose cancels the previous request; `close()` cancels all.
    In `catch`, `if (isCancellation(error)) return;` comes first.
12. WRITES (POST/PUT/PATCH/DELETE) are never cancellable.
13. Parallel requests use `Future.wait<void>(<Future<void>>[...])` with
    `late final` typed locals, **not** record `.wait` (it wraps errors in
    `ParallelWaitError` and hides the real message).
14. Errors shown to users go through `ErrorHandler.messageFor(error)`; API
    and business errors are shown with a snackbar effect. Never show stack
    traces.

### Busy state, loader, dialogs, navigation animation
15. Main load: `final RequestToken token = startBlockingRequest('load');` …
    `finally { endBlockingRequest(token); }`.
16. Every write action starts with `if (isBusy) { return; }`, then
    `showProgress()`, and calls `hideProgress()` on success AND failure.
17. Wrap every screen `body` (plus FABs and app-bar action buttons that trigger
    requests) in `BusyGuard<C, B>`. Never guard the back button.
18. Progress is shown only with the square loader: `CommonLoader` inside a
    screen, `ProgressDialog` (via `showProgress`) above it. **Never use
    `CircularProgressIndicator`.**
19. Dialogs go through `AppDialog` (`ShowConfirmationEffect`, with
    `isDestructive: true` for deletes); bottom sheets through
    `ShowInfoSheetEffect`. Never call `showDialog` directly in screens.
20. Page transitions come from `AppTheme.pageTransitionsTheme` (forward
    right-to-left, back left-to-right). Routes use plain `MaterialPageRoute`
    in `AppRoutes`; never create per-screen custom routes.

### DI, routing
21. Register in `dependency_injection.dart`: Dio/storage/config = singleton;
    `ApiClient`, repositories, global Cubits = lazy singleton; **screen Cubits
    = factory** (`registerFactoryParam` when the screen has an argument). Use
    explicit generics: `getIt<UserRepository>()`.
22. Constructor injection with private named parameters:
    `UserListCubit({required this._userRepository})`.
23. Add the route name to `RouteNames` (no imports in that file) and a `case`
    in `AppRoutes.onGenerateRoute` that creates
    `BlocProvider<XCubit>(create: (BuildContext _) => getIt<XCubit>()..load(), child: const XScreen())`.

### Models
24. One model per file, immutable, `const` constructor, `factory fromJson`,
    `toJson` when sent to the API, and a meaningful `toString()` (never print
    secrets). A changed model is created with its constructor.

### UI
25. Texts in `AppStrings`, colors from `Theme.of(context).colorScheme` (or
    `AppColors` for status colors), sizes from `AppDimensions` (clamped Sizer
    values). No magic numbers for spacing/fonts in feature code.
26. Responsive: `MaxWidthContainer` caps content width, lists use
    `ResponsiveListGrid`, detail screens switch to two columns at ≥ 800 px via
    `LayoutBuilder`. No `RenderFlex` overflow at 320 px width.
27. Split screens into small widgets (one per file in `widgets/`); app-wide
    widgets go to `core/widgets/`, feature-wide ones to `features/<f>/widgets/`.

### Code style (enforced by `analysis_options.yaml`)
28. Explicit types everywhere: `final List<UserModel> users = <UserModel>[];`
    never `final users = [];` or `var`. Typed closure parameters, including
    unused ones: `(BuildContext _) => …`. Explicit generics:
    `BlocBuilder<XCubit, XState>(`, `MapEntry<String, String>(`, `<Widget>[`.
29. Every function, method and getter declares its return type.
30. `///` doc comments on every class, constructor, field, getter, method and
    top-level function, **private ones included**. Inside `build`, a `//`
    comment above each meaningful section and on every `BlocProvider`,
    `BlocBuilder`, `BlocSelector`, `BlocListener`, `ScreenEffectListener` and
    `BusyGuard` explaining what it provides/rebuilds/listens to and why.
    Cubit methods say which user action triggers them and what they emit.
    Write for junior developers: explain *why*, keep it short.
31. Logging only through `core/utils/app_logger.dart` (`screenLog`, `cubitLog`,
    `repositoryLog`, `errorLog`, `generalLog`, keep the `funtionName`
    parameter name). Never log passwords, tokens or personal data.
32. Do not add a package unless the feature needs it; never add one just to
    name a type.

### Testing
33. Every Cubit gets unit tests; screens with logic get widget tests. Tests
    never call the live API: use `test/helpers/fake_backend.dart`,
    `in_memory_storage.dart`, `pump_app.dart` (wraps `Sizer`), `effects.dart`
    (`collectEffects`), `sample_data.dart`, or mocktail mocks
    (`registerFallbackValue(RequestToken())` when matching `requestToken`).
34. `test/architecture_rules_test.dart` enforces several rules above; keep it
    passing and extend it when you add a rule that can be checked.

## Definition of done

- [ ] Rules above followed (state, effects, busy, cancellation, DI, routing).
- [ ] Docs/comments on everything new; explicit types; no `copyWith`.
- [ ] Strings/dimensions/colors centralised; works at 320 px and on desktop.
- [ ] Cubit tests (+ widget tests when there is UI logic) added.
- [ ] `dart format lib test`, `flutter analyze` (no issues), `flutter test`
      (all green) run, and results reported honestly.
- [ ] README updated when architecture or dependencies change.

## Detailed guides (read when the task touches the topic)

- `docs/claude/architecture.md` – state, effects, data flow, cancellation, busy flag, with code patterns.
- `docs/claude/ui-guidelines.md` – screens, widgets, loader, dialogs, responsive layout, theme.
- `docs/claude/code-style.md` – typing, documentation and logging rules with examples.
- `docs/claude/testing.md` – test helpers and test patterns.

## Skills

- `/new-screen` – scaffold a screen (list or form) with Cubit, state,
  widgets, DI, route and tests from the verified templates.
- `/new-app-from-template` – turn a copy of this project into a new app.
