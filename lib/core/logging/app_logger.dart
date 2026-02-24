import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../services/crash_reporting_service.dart';

final Logger _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
  level: kReleaseMode ? Level.error : Level.debug,
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
    if (!kReleaseMode) _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// NEVER pass PII (user IDs, amounts, descriptions) in [message].
  /// In release this message is forwarded to the Crashlytics log buffer.
  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode) {
      // Release: log the event label only — no error object, no stack trace,
      // no user IDs, no amounts, nothing that could leak PII.
      _logger.e(message);
      CrashReportingService.instance.log(message);
    } else {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}
