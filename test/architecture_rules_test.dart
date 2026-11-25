import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the project rules so they cannot regress silently.
///
/// These tests read the source files as plain text and fail when a
/// forbidden word or pattern shows up in `lib/` (or `test/`).
void main() {
  // Every Dart file of the app and of the tests.
  final List<File> dartFiles = <FileSystemEntity>[
    ...Directory('lib').listSync(recursive: true),
    ...Directory('test').listSync(recursive: true),
  ].whereType<File>().where((File f) => f.path.endsWith('.dart')).toList();

  // This file mentions the forbidden words on purpose.
  final String self = 'test/architecture_rules_test.dart';
  final List<File> checked = dartFiles
      .where((File f) => !f.path.endsWith(self))
      .toList();

  /// Paths of the checked files under [root] whose text contains [pattern].
  /// An empty [root] means "every folder".
  List<String> filesContaining(Pattern pattern, {String root = 'lib'}) =>
      <String>[
        for (final File file in checked)
          if (file.path.startsWith(root) &&
              file.readAsStringSync().contains(pattern))
            file.path,
      ];

  test('copyWith is not used anywhere', () {
    expect(filesContaining('copyWith', root: ''), isEmpty);
  });

  test('Equatable is not used and not a dependency', () {
    expect(filesContaining(RegExp('quatable'), root: ''), isEmpty);
    expect(
      File('pubspec.yaml').readAsStringSync().toLowerCase(),
      isNot(contains('equatable')),
    );
  });

  test('no setState and no ChangeNotifier in lib', () {
    // Only comments may mention setState: the regex skips lines where `//`
    // comes before `setState(`.
    final List<String> offenders = <String>[
      for (final File file in checked)
        if (file.path.startsWith('lib') &&
            RegExp(
              r'^[^/\n]*\bsetState\(',
              multiLine: true,
            ).hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty);
    expect(filesContaining('ChangeNotifier'), isEmpty);
  });

  test('widgets and cubits never touch Dio directly', () {
    // Only the network layer and the DI setup may import Dio.
    final Set<String> allowed = <String>{
      'lib/core/network/api_client.dart',
      'lib/core/network/api_exception.dart',
      'lib/core/network/dio_interceptors.dart',
      'lib/core/network/request_token.dart',
      'lib/app/dependency_injection.dart',
    };
    final List<String> offenders = filesContaining('package:dio/')
        .where((String path) => !allowed.contains(path))
        .toList();
    expect(offenders, isEmpty);
  });

  test('every model overrides toString', () {
    final Iterable<File> models = checked.where(
      (File f) =>
          f.path.startsWith('lib') &&
          f.path.contains('/models/') &&
          f.path.endsWith('_model.dart'),
    );
    expect(models, isNotEmpty);
    for (final File model in models) {
      expect(
        model.readAsStringSync(),
        contains('String toString()'),
        reason: model.path,
      );
    }
  });

  test('screens have a doc comment on their class', () {
    final Iterable<File> screens = checked.where(
      (File f) => f.path.endsWith('_screen.dart'),
    );
    expect(screens, isNotEmpty);
    for (final File screen in screens) {
      // The line right above `class ...` must be a `///` doc comment.
      final List<String> lines = screen.readAsStringSync().split('\n');
      final int index = lines.indexWhere((String l) => l.startsWith('class '));
      expect(lines[index - 1].startsWith('///'), isTrue, reason: screen.path);
    }
  });
}
