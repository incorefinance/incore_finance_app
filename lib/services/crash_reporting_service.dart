import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// PII-safe crash reporting wrapper.
///
/// NEVER pass user IDs, transaction amounts, descriptions, categories,
/// or raw Supabase error messages through any method on this class.
/// Only generic labels and safe context keys are allowed.
class CrashReportingService {
  CrashReportingService._();
  static final instance = CrashReportingService._();

  /// Cached collection state. Mirrors Crashlytics collection setting.
  /// Checked by AppLogger.e() and all public methods before forwarding.
  bool _collectionEnabled = false;

  /// Whether crash reporting is currently active.
  bool get enabled => kReleaseMode && _collectionEnabled;

  /// Call once during app startup after setCrashlyticsCollectionEnabled.
  void initialize({required bool collectionEnabled}) {
    _collectionEnabled = collectionEnabled;
  }

  /// Runtime toggle for a future "Share crash reports" user setting.
  Future<void> setCollectionEnabled(bool value) async {
    _collectionEnabled = value;
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(value);
  }

  /// Forward a safe log message to the Crashlytics log buffer.
  /// Called by AppLogger.e() — message must contain NO PII.
  void log(String message) {
    if (!enabled) return;
    FirebaseCrashlytics.instance.log(message);
  }

  /// Set safe-only context keys. No user IDs, amounts, or descriptions.
  Future<void> setSafeContext({
    required String localeCode,
    required bool isAuthenticated,
  }) async {
    if (!enabled) return;
    await FirebaseCrashlytics.instance.setCustomKey('locale', localeCode);
    await FirebaseCrashlytics.instance.setCustomKey('auth', isAuthenticated);
  }

  /// Set the build stage (dev / internal / prod).
  /// Read from --dart-define=APP_STAGE at build time.
  Future<void> setStage(String stage) async {
    if (!enabled) return;
    await FirebaseCrashlytics.instance.setCustomKey('stage', stage);
  }

  /// Set current screen name (generic label, not route params).
  Future<void> setScreen(String screenName) async {
    if (!enabled) return;
    await FirebaseCrashlytics.instance.setCustomKey('screen', screenName);
  }

  /// Record a non-fatal error for bugs that should not happen.
  ///
  /// NEVER pass PII in [hint]. Keep it generic:
  ///   Good: "Unexpected null in transaction list"
  ///   Bad:  "User abc123 had null amount $500"
  Future<void> recordNonFatal(
    Object error,
    StackTrace stack, {
    String? hint,
  }) async {
    if (!enabled) return;
    if (hint != null) {
      await FirebaseCrashlytics.instance.log(hint);
    }
    await FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
  }
}
