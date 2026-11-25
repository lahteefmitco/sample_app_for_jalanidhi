---
name: new-screen
description: Scaffold a new Flutter screen in this architecture (screen Cubit + BuildState + effects, BusyGuard, square loader, request cancellation, DI, route, tests) from verified templates. Use when the user asks to add a screen, page, list, form, CRUD feature or new data type (model + repository).
---

# New screen

Creates a screen that follows `CLAUDE.md` exactly, starting from templates
that were verified to compile and pass their tests. Read `CLAUDE.md` and
`docs/claude/architecture.md` first if they are not already in context.

## 1. Gather the inputs

Ask only for what you cannot infer from the request or the codebase:

| Input | Example | Notes |
|---|---|---|
| package | `sample_app_for_jalanidhi` | `name:` in `pubspec.yaml` |
| feature | `notes` | snake_case folder under `lib/features/` (existing or new) |
| item / items | `Note` / `Notes` | PascalCase model name, singular and plural |
| endpoint path | `/notes` | API path relative to the base URL |
| kind | `list`, `form`, `data` | what to generate (see below) |
| screen | `NoteList`, `NoteForm` | PascalCase screen name for list/form |

Kinds:
- `data` – `<Item>Model` + shared `<Item>Repository` (GET with cancellation
  token, POST create). Skip if the model/repository already exist.
- `list` – list screen: load (blocking + cancellable), search, pull-to-refresh,
  retry, details bottom sheet, "new" button, refresh + success snackbar when
  the form returns `'saved'`. Includes cubit + widget tests.
- `form` – "create" form: validation, POST with square loader, screen locked
  while saving, double tap ignored, closes with `'saved'`. Includes cubit test.

A typical CRUD feature = `data` + `list` + `form`.

## 2. Render the templates

From the project root:

```bash
python3 .claude/skills/new-screen/scripts/render.py --package <package> --feature <feature> --kind data --item <Item> --items <Items> --endpoint-path <path>
```

```bash
python3 .claude/skills/new-screen/scripts/render.py --package <package> --feature <feature> --kind list --screen <Item>List --item <Item> --items <Items> --endpoint-path <path>
```

```bash
python3 .claude/skills/new-screen/scripts/render.py --package <package> --feature <feature> --kind form --screen <Item>Form --item <Item> --items <Items> --endpoint-path <path>
```

The script never overwrites existing files (unless `--force`) and prints the
exact snippets for the manual wiring.

## 3. Wire it up (shared files, edit by hand)

Apply the snippets the script printed:

1. `lib/core/network/api_endpoints.dart` – endpoint constant (`data`).
2. `lib/core/constants/app_strings.dart` – titles, empty text, labels,
   success message (`list`, `form`).
3. `lib/core/constants/route_names.dart` – route name with a doc comment
   stating the expected argument type.
4. `lib/app/dependency_injection.dart` – repository = lazy singleton, screen
   Cubit = factory (`registerFactoryParam` when the screen needs an argument).
5. `lib/app/app_routes.dart` – a `case` that wraps the screen in
   `BlocProvider<XCubit>(create: (BuildContext _) => getIt<XCubit>()..load(), ...)`
   (no `..load()` for a plain create form) and the imports.
6. Link to the new screen from an existing screen through its Cubit
   (`navigateTo(RouteNames.x)`), e.g. a `HomeCubit.menuItems` entry.

## 4. Adapt to the real data

The templates use a model with `id` and `title`. Extend them, keeping the
rules:

- Model fields: typed, `final`, in `fromJson`/`toJson`/`toString`; no
  `copyWith`.
- New form fields: controller in the Cubit (disposed in `close()`), error
  field in the BuildState + private working field, validation in `submit()`
  via `Validators`, `CommonTextField` in `widgets/<screen>_fields.dart`.
- Edit mode for a form: pass the id as a route argument
  (`registerFactoryParam<XCubit, int?, void>`), load the item in `load()` with
  `startBlockingRequest`, fill the controllers, and call an update (PUT)
  repository method in `submit()`. See `features/posts/screens/post_form/`.
- Delete: `ShowConfirmationEffect(..., isDestructive: true)` +
  `onConfirmed` → write action with `if (isBusy) return;`, `showProgress()`,
  `hideProgress()`. See `features/posts/screens/post_details/`.
- Complex list screens (sort, filters, pagination): split the BuildState into
  `header` + `content` groups. See `features/users/screens/user_list/` and
  `features/posts/screens/post_list/`.
- Add every new user-facing text to `AppStrings`; sizes from `AppDimensions`.
- Document every new class, field and method (private too) and comment each
  Bloc widget; explicit types everywhere.

## 5. Verify

```bash
dart format lib test
```

```bash
flutter analyze
```

```bash
flutter test
```

All three must be clean. Fix the code (not the tests) when a generated test
fails because of your adaptations, and update the tests when you change
behaviour on purpose. Report the real results.
