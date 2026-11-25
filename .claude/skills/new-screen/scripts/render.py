#!/usr/bin/env python3
"""Render the new-screen templates into a Flutter project.

Usage (run from the project root):

  python3 .claude/skills/new-screen/scripts/render.py \
      --package my_app --feature notes --kind data \
      --item Note --items Notes --endpoint-path /notes

  python3 .claude/skills/new-screen/scripts/render.py \
      --package my_app --feature notes --kind list --screen NoteList \
      --item Note --items Notes --endpoint-path /notes

  python3 .claude/skills/new-screen/scripts/render.py \
      --package my_app --feature notes --kind form --screen NoteForm \
      --item Note --items Notes --endpoint-path /notes

Kinds:
  data  model + shared repository (lib/global/...)
  list  list screen (state, cubit, screen, view, item) + cubit and widget tests
  form  "create" form screen (state, cubit, screen, fields) + cubit test

Existing files are never overwritten unless --force is given. After rendering,
the script prints the manual wiring steps (endpoint, strings, route, DI).
"""

import argparse
import os
import re
import sys

TEMPLATES = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'templates')


def snake(name: str) -> str:
    """PascalCase -> snake_case (NoteList -> note_list)."""
    return re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()


def lower_first(name: str) -> str:
    """PascalCase -> camelCase (NoteList -> noteList)."""
    return name[:1].lower() + name[1:]


def outputs(kind: str, v: dict) -> list:
    """(template, destination) pairs for one kind."""
    feature_dir = f"lib/features/{v['feature']}/screens/{v['screen']}"
    test_dir = f"test/features/{v['feature']}"
    if kind == 'data':
        return [
            ('model.dart.tmpl', f"lib/global/models/{v['item_snake']}_model.dart"),
            ('repository.dart.tmpl', f"lib/global/repositories/{v['item_snake']}_repository.dart"),
        ]
    if kind == 'list':
        return [
            ('list/state.dart.tmpl', f"{feature_dir}/cubit/{v['screen']}_state.dart"),
            ('list/cubit.dart.tmpl', f"{feature_dir}/cubit/{v['screen']}_cubit.dart"),
            ('list/screen.dart.tmpl', f"{feature_dir}/{v['screen']}_screen.dart"),
            ('list/widgets/view.dart.tmpl', f"{feature_dir}/widgets/{v['screen']}_view.dart"),
            ('list/widgets/item.dart.tmpl', f"{feature_dir}/widgets/{v['item_snake']}_list_item.dart"),
            ('test/list_cubit_test.dart.tmpl', f"{test_dir}/{v['screen']}_cubit_test.dart"),
            ('test/list_screen_test.dart.tmpl', f"{test_dir}/{v['screen']}_screen_test.dart"),
        ]
    if kind == 'form':
        return [
            ('form/state.dart.tmpl', f"{feature_dir}/cubit/{v['screen']}_state.dart"),
            ('form/cubit.dart.tmpl', f"{feature_dir}/cubit/{v['screen']}_cubit.dart"),
            ('form/screen.dart.tmpl', f"{feature_dir}/{v['screen']}_screen.dart"),
            ('form/widgets/fields.dart.tmpl', f"{feature_dir}/widgets/{v['screen']}_fields.dart"),
            ('test/form_cubit_test.dart.tmpl', f"{test_dir}/{v['screen']}_cubit_test.dart"),
        ]
    raise ValueError(kind)


def render(text: str, v: dict) -> str:
    """Replace every {{placeholder}}; fail on unknown ones."""
    def repl(match: re.Match) -> str:
        key = match.group(1)
        if key not in v:
            raise KeyError(f'unknown placeholder {{{{{key}}}}}')
        return v[key]
    return re.sub(r'\{\{(\w+)\}\}', repl, text)


def manual_steps(kind: str, v: dict) -> str:
    """Wiring the script does not do automatically (edits shared files)."""
    steps = []
    if kind == 'data':
        steps.append(f"""lib/core/network/api_endpoints.dart:
  /// Every {v['item']} (also the target of "create {v['item']}").
  static const String {v['items']} = '{v['endpointPath']}';""")
        steps.append(f"""lib/app/dependency_injection.dart (_registerSharedRepositories):
  ..registerLazySingleton<{v['Item']}Repository>(
    () => {v['Item']}Repository(getIt<ApiClient>()),
  )""")
    if kind == 'list':
        steps.append(f"""lib/core/constants/app_strings.dart:
  /// Title of the {v['item']} list.
  static const String {v['items']}Title = '{v['Items']}';
  /// Shown when no {v['item']} matches.
  static const String no{v['Items']} = 'No {v['items']} found';
  /// Floating button and form title.
  static const String new{v['Item']} = 'New {v['item']}';
  /// Snackbar after a successful save.
  static const String {v['item']}Saved = '{v['Item']} saved';""")
        steps.append(f"""lib/core/constants/route_names.dart:
  /// List of all {v['items']}.
  static const String {v['items']} = '/{v['items']}';""")
        steps.append(f"""lib/app/dependency_injection.dart (feature section):
  getIt.registerFactory<{v['Screen']}Cubit>(
    () => {v['Screen']}Cubit({v['item']}Repository: getIt<{v['Item']}Repository>()),
  );""")
        steps.append(f"""lib/app/app_routes.dart (switch in onGenerateRoute):
  case RouteNames.{v['items']}:
    // Provides a {v['Screen']}Cubit and starts loading at once.
    page = BlocProvider<{v['Screen']}Cubit>(
      create: (BuildContext _) => getIt<{v['Screen']}Cubit>()..load(),
      child: const {v['Screen']}Screen(),
    );""")
    if kind == 'form':
        steps.append(f"""lib/core/constants/app_strings.dart:
  /// Label of the title field of the {v['item']} form.
  static const String {v['item']}TitleLabel = 'Title';""")
        steps.append(f"""lib/core/constants/route_names.dart:
  /// "New {v['item']}" form; no argument.
  static const String {v['item']}Form = '/{v['items']}/form';""")
        steps.append(f"""lib/app/dependency_injection.dart (feature section):
  getIt.registerFactory<{v['Screen']}Cubit>(
    () => {v['Screen']}Cubit({v['item']}Repository: getIt<{v['Item']}Repository>()),
  );""")
        steps.append(f"""lib/app/app_routes.dart (switch in onGenerateRoute):
  case RouteNames.{v['item']}Form:
    // Provides a {v['Screen']}Cubit for the "new {v['item']}" form.
    page = BlocProvider<{v['Screen']}Cubit>(
      create: (BuildContext _) => getIt<{v['Screen']}Cubit>(),
      child: const {v['Screen']}Screen(),
    );""")
    return '\n\n'.join(steps)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--package', required=True, help='Dart package name (pubspec "name")')
    parser.add_argument('--feature', required=True, help='feature folder, snake_case (e.g. notes)')
    parser.add_argument('--kind', required=True, choices=['data', 'list', 'form'])
    parser.add_argument('--screen', help='screen name in PascalCase (e.g. NoteList); required for list/form')
    parser.add_argument('--item', required=True, help='model name in PascalCase, singular (e.g. Note)')
    parser.add_argument('--items', required=True, help='PascalCase plural (e.g. Notes)')
    parser.add_argument('--endpoint-path', required=True, help='API path (e.g. /notes)')
    parser.add_argument('--root', default='.', help='project root (default: current directory)')
    parser.add_argument('--force', action='store_true', help='overwrite existing files')
    args = parser.parse_args()

    if args.kind in ('list', 'form') and not args.screen:
        parser.error('--screen is required for list and form')

    screen = args.screen or args.item
    v = {
        'package': args.package,
        'feature': args.feature,
        'Screen': screen,
        'screen': snake(screen),
        'Item': args.item,
        'item': lower_first(args.item),
        'item_snake': snake(args.item),
        'Items': args.items,
        'items': lower_first(args.items),
        'endpointPath': args.endpoint_path,
        'testHelpers': '../../helpers',
    }

    written = []
    for template, destination in outputs(args.kind, v):
        target = os.path.join(args.root, destination)
        if os.path.exists(target) and not args.force:
            print(f'SKIP (exists): {destination}', file=sys.stderr)
            continue
        with open(os.path.join(TEMPLATES, template), encoding='utf-8') as handle:
            content = render(handle.read(), v)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, 'w', encoding='utf-8') as handle:
            handle.write(content)
        written.append(destination)

    print('Written:')
    for path in written:
        print(f'  {path}')
    print('\nManual wiring still needed:\n')
    print(manual_steps(args.kind, v))
    return 0


if __name__ == '__main__':
    sys.exit(main())
