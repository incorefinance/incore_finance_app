import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/logging/app_logger.dart';
import '../routes/app_routes.dart';

/// Centralized auth state checker for routing decisions.
/// Detects unrecoverable auth states and provides routing to error screen.
class AuthGuard {
  /// Check if current auth state is valid for authenticated routes.
  /// Returns null if valid, or an error reason string if invalid.
  static String? checkAuthState() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final session = supabase.auth.currentSession;

    if (user == null) {
      return 'No authenticated user';
    }

    if (session == null) {
      return 'No active session';
    }

    // Check if session is expired based on expiresAt timestamp
    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      if (DateTime.now().isAfter(expiryTime)) {
        return 'Session expired';
      }
    }

    return null; // Auth state is valid
  }

  /// Route to auth error screen if auth state is invalid.
  /// Returns true if routed to error screen, false if auth is valid.
  static bool routeToErrorIfInvalid(BuildContext context, {String? reason}) {
    final checkResult = reason ?? checkAuthState();
    if (checkResult != null) {
      AppLogger.d('AuthGuard: Routing to error screen - $checkResult');
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.authGuardError,
        (route) => false,
        arguments: checkResult,
      );
      return true;
    }
    return false;
  }

  /// Check if an error is an auth-related error that requires re-login.
  /// Uses structured error type checks first, falls back to string matching.
  static bool isAuthError(dynamic error) {
    // Structured check: AuthException from Supabase
    if (error is AuthException) {
      final statusCode = error.statusCode;
      // 401 Unauthorized, 403 Forbidden are auth errors
      if (statusCode == '401' || statusCode == '403') {
        return true;
      }
      // Check for specific auth error messages from Supabase
      final message = error.message.toLowerCase();
      if (message.contains('invalid') ||
          message.contains('expired') ||
          message.contains('refresh')) {
        return true;
      }
      return true; // Any AuthException is an auth error
    }

    // Structured check: PostgrestException with auth-related status codes
    if (error is PostgrestException) {
      final code = error.code;
      // PGRST301 = JWT expired, PGRST302 = JWT invalid
      if (code == 'PGRST301' || code == 'PGRST302' || code == '42501') {
        return true;
      }
    }

    // Fallback: String matching for edge cases
    final message = error.toString().toLowerCase();
    return message.contains('jwt expired') ||
        message.contains('jwt invalid') ||
        message.contains('token is expired') ||
        message.contains('invalid token') ||
        message.contains('unauthorized') ||
        message.contains('unauthenticated');
  }
}
