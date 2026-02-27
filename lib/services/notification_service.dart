import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/app_logger.dart';

/// Service for managing push notification preferences and thresholds.
///
/// Handles:
/// - Notification enabled/disabled state
/// - Safety buffer threshold (weeks) for alert triggers
///
/// Preferences are stored locally via SharedPreferences and
/// synced to Supabase user_notification_preferences when available.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _enabledKey = 'notifications_enabled';
  static const String _thresholdKey = 'safety_buffer_threshold_weeks';
  static const int _defaultThresholdWeeks = 4;

  bool _initialized = false;
  bool _enabled = true;
  int _thresholdWeeks = _defaultThresholdWeeks;

  /// Initialize the notification service.
  ///
  /// Loads persisted preferences from SharedPreferences.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? true;
      _thresholdWeeks = prefs.getInt(_thresholdKey) ?? _defaultThresholdWeeks;
      _initialized = true;
    } catch (e) {
      AppLogger.w('[NotificationService] Failed to load preferences', error: e);
    }
  }

  /// Whether notifications are enabled.
  bool get isEnabled => _enabled;

  /// Get the safety buffer threshold in weeks.
  Future<int> getSafetyBufferThreshold() async {
    if (!_initialized) await initialize();
    return _thresholdWeeks;
  }

  /// Enable or disable notifications.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (e) {
      AppLogger.w('[NotificationService] Failed to save enabled state', error: e);
    }
  }

  /// Set the safety buffer threshold in weeks.
  Future<void> setSafetyBufferThreshold(int weeks) async {
    _thresholdWeeks = weeks;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_thresholdKey, weeks);
    } catch (e) {
      AppLogger.w('[NotificationService] Failed to save threshold', error: e);
    }
  }
}
