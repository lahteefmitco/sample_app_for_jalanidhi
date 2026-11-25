import 'dart:developer';

import 'package:flutter/foundation.dart';

/// ANSI escape code that turns console text red (used for errors).
const String red = '\x1B[31m';

/// ANSI escape code that turns console text green (used by repositories).
const String green = '\x1B[32m';

/// ANSI escape code that turns console text yellow (general messages).
const String yellow = '\x1B[33m';

/// ANSI escape code that turns console text blue.
const String blue = '\x1B[34m';

/// ANSI escape code that turns console text magenta (used by Cubits).
const String magenta = '\x1B[35m';

/// ANSI escape code that restores the default console color.
const String reset = '\x1B[0m';

/// ANSI escape code that turns console text white (used by screens).
const String white = '\x1B[37m';

/// Default value of the `funtionName` argument (the spelling is kept for
/// compatibility with the original logging contract).
const String _defaultFunctionName = 'GENERAL';

/// Default `funtionName` of [screenLog]; like the one above it adds no prefix.
const String _defaultScreenFunctionName = 'SCREEN';

/// Prefixes [message] with `[funtionName]` unless it is a default marker.
String _compose(dynamic message, String funtionName) {
  if (funtionName.isEmpty ||
      funtionName == _defaultFunctionName ||
      funtionName == _defaultScreenFunctionName) {
    return '$message';
  }
  return '[$funtionName] $message';
}

/// Logs errors. Never pass passwords, tokens or other sensitive data.
///
/// Like every function in this file it only prints in debug builds.
void errorLog(
  dynamic message, {
  String name = 'ERROR',
  String funtionName = 'GENERAL',
}) {
  if (kDebugMode) {
    log('$red${_compose(message, funtionName)}$reset', name: name);
  }
}

/// Logs general app events (start-up, configuration, services).
void generalLog(
  dynamic message, {
  String name = 'GENERAL',
  String funtionName = 'GENERAL',
}) {
  if (kDebugMode) {
    log('$yellow${_compose(message, funtionName)}$reset', name: name);
  }
}

/// Logs screen and navigation events (e.g. which route was opened).
void screenLog(
  dynamic message, {
  String name = 'SCREEN',
  String funtionName = 'SCREEN',
}) {
  if (kDebugMode) {
    log('$white${_compose(message, funtionName)}$reset', name: name);
  }
}

/// Logs Cubit events (created, state changed, closed).
void cubitLog(
  dynamic message, {
  String name = 'CUBIT',
  String funtionName = 'GENERAL',
}) {
  if (kDebugMode) {
    log('$magenta${_compose(message, funtionName)}$reset', name: name);
  }
}

/// Logs repository events (network calls, cache hits, local changes).
void repositoryLog(
  dynamic message, {
  String name = 'REPOSITORY',
  String funtionName = 'GENERAL',
}) {
  if (kDebugMode) {
    log('$green${_compose(message, funtionName)}$reset', name: name);
  }
}
