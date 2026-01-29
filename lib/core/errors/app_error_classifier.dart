import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_guard.dart';
import '../logging/app_logger.dart';
import 'app_error.dart';

/// Classifies exceptions into AppError categories using structured checks first,
/// then falling back to string pattern matching for edge cases.
///
/// Important: This classifier does NOT include localized strings in the result.
/// The widget resolves localized text via AppLocalizations in build().
class AppErrorClassifier {
  AppErrorClassifier._();

  /// Classifies an error and returns a structured AppError.
  ///
  /// [error] - The exception or error object
  /// [stackTrace] - Optional stack trace for debugging
  static AppError classify(Object error, {StackTrace? stackTrace}) {
    // Log the error for debugging
    AppLogger.e(
      'AppErrorClassifier: Classifying error',
      error: error,
      stackTrace: stackTrace,
    );

    // 1. Network error checks (structured)
    if (isNetworkError(error)) {
      return AppError.network(
        debugReason: 'Network: ${error.runtimeType}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 2. Auth error checks (reuses AuthGuard.isAuthError)
    if (AuthGuard.isAuthError(error)) {
      return AppError.auth(
        debugReason: 'Auth: ${error.runtimeType}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 3. Default to unknown
    return AppError.unknown(
      debugReason: '${error.runtimeType}: $error',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Check if error is network-related.
  static bool isNetworkError(Object error) {
    // Structured checks for common network exceptions
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) return true;

    // Check for HandshakeException (SSL/TLS errors)
    final typeName = error.runtimeType.toString();
    if (typeName.contains('HandshakeException')) return true;
    if (typeName.contains('TlsException')) return true;

    // Supabase/Postgrest network errors
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('network') ||
          message.contains('connection') ||
          message.contains('timeout') ||
          message.contains('unreachable') ||
          message.contains('failed host lookup')) {
        return true;
      }
    }

    // ClientException from http package
    final errorTypeName = error.runtimeType.toString();
    if (errorTypeName == 'ClientException') {
      return true;
    }

    // String fallback for edge cases
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no internet') ||
        errorString.contains('connection timed out') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection reset') ||
        errorString.contains('connection closed');
  }
}
