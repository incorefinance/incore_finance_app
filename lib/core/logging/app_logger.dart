import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: false,
  ),
  level: kReleaseMode ? Level.warning : Level.debug,
);

class AppLogger {
  const AppLogger._();

  static void d(String message) {
    if (!kReleaseMode) _logger.d(message);
  }

  static void i(String message) {
    if (!kReleaseMode) _logger.i(message);
  }

  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
