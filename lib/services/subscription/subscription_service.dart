// lib/services/subscription/subscription_service.dart
//
// Service for managing subscriptions and paywall presentation.
// Wraps Superwall and provides subscription state to the app.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entitlements/plan_type.dart';

/// Whether Superwall SDK is available on this platform.
/// Superwall only works on iOS and Android native apps.
bool get superwallSupportedPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// SubscriptionService wraps Superwall and provides subscription state.
///
/// Responsibilities:
/// - Expose current plan as stream
/// - Present paywalls by trigger ID
/// - Handle purchase restoration
/// - Enforce paywall cooldowns (persisted in SharedPreferences)
/// - Orchestrate limit-crossed paywall triggers
///
/// Usage:
/// ```dart
/// final service = SubscriptionService();
/// final plan = await service.getCurrentPlan();
/// if (plan == PlanType.free) {
///   await service.presentPaywall('feature_gate');
/// }
/// ```
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();

  /// Singleton instance.
  factory SubscriptionService() => _instance;

  SubscriptionService._();

  final _planController = StreamController<PlanType>.broadcast();

  /// Stream of plan changes.
  ///
  /// Listen to this stream to react to subscription status changes.
  Stream<PlanType> get planStream => _planController.stream;

  // =========================================================================
  // Cooldown Configuration
  // =========================================================================

  /// Duration between showing the same paywall (for marketing triggers).
  static const Duration _paywallCooldown = Duration(days: 7);

  /// Prefix for cooldown keys in SharedPreferences.
  static const String _cooldownPrefix = 'paywall_cooldown_';

  /// Key for tracking if post_onboarding paywall was ever shown.
  static const String _postOnboardingShownKey = 'paywall_post_onboarding_shown';

  /// Triggers that never have cooldowns.
  /// Access gates and limit gates must always present paywall.
  static const Set<String> _noCooldownTriggers = {
    'analytics_gate',
    'limit_crossed_spend_entries_count',
    'limit_crossed_recurring_expenses_count',
    'limit_crossed_income_events_count',
  };

  // =========================================================================
  // Plan Status
  // =========================================================================

  /// Get current subscription plan.
  ///
  /// Returns [PlanType.premium] if user has an active subscription,
  /// [PlanType.free] otherwise.
  ///
  /// On unsupported platforms (desktop/web), returns [PlanType.free] without
  /// calling Superwall to avoid PlatformException spam.
  Future<PlanType> getCurrentPlan() async {
    if (!superwallSupportedPlatform) {
      return PlanType.free;
    }

    try {
      final status = await Superwall.shared.getSubscriptionStatus();
      if (status.isActive) {
        return PlanType.premium;
      }
    } catch (e) {
      AppLogger.w('Failed to get subscription status', error: e);
    }

    // Default to free plan
    return PlanType.free;
  }

  // =========================================================================
  // Paywall Presentation
  // =========================================================================

  /// Present paywall if not on cooldown.
  ///
  /// Cooldown behavior:
  /// - Access gates (analytics_gate) and limit gates: NO cooldown, always show
  /// - post_onboarding: "once ever" - only shows once per user lifetime
  /// - Other marketing triggers: 7-day cooldown
  ///
  /// Returns true if paywall was presented, false if blocked by cooldown.
  /// Returns false on unsupported platforms (desktop/web) without calling Superwall.
  ///
  /// Trigger IDs:
  /// - `post_onboarding` - After completing onboarding (once ever)
  /// - `analytics_gate` - When tapping Analytics without premium
  /// - `limit_crossed_spend_entries_count` - Spend entries limit crossed
  /// - `limit_crossed_recurring_expenses_count` - Recurring expenses limit crossed
  /// - `limit_crossed_income_events_count` - Income events limit crossed
  Future<bool> presentPaywall(String triggerId) async {
    if (!superwallSupportedPlatform) {
      AppLogger.d('Superwall not supported on this platform, skipping paywall');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();

    // post_onboarding is "once ever" - check if already shown
    final isPostOnboarding = triggerId == 'post_onboarding';
    if (isPostOnboarding) {
      final alreadyShown = prefs.getBool(_postOnboardingShownKey) ?? false;
      if (alreadyShown) {
        AppLogger.d('post_onboarding paywall already shown once');
        return false;
      }
      // DO NOT mark as shown yet - wait until presentation succeeds
    }

    // Access gates and limit gates: no cooldown, always show
    final isNoCooldownTrigger = _noCooldownTriggers.contains(triggerId);

    // For any remaining triggers (excluding post_onboarding), apply time-based cooldown
    if (!isNoCooldownTrigger && !isPostOnboarding) {
      final cooldownKey = '$_cooldownPrefix$triggerId';
      final lastShownMs = prefs.getInt(cooldownKey);

      if (lastShownMs != null) {
        final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMs);
        final elapsed = DateTime.now().difference(lastShown);

        if (elapsed < _paywallCooldown) {
          AppLogger.d(
            'Paywall cooldown active for $triggerId '
            '(${_paywallCooldown.inDays - elapsed.inDays} days remaining)',
          );
          return false;
        }
      }
    }

    // Present via Superwall
    AppLogger.i('Presenting paywall placement: $triggerId');
    try {
      Superwall.shared.registerPlacement(triggerId);
    } catch (e, st) {
      AppLogger.e('Failed to register Superwall placement', error: e, stackTrace: st);
      return false;
    }

    // Mark post_onboarding as shown AFTER successful presentation
    if (isPostOnboarding) {
      await prefs.setBool(_postOnboardingShownKey, true);
    }

    // Record cooldown for triggers that have it (after presentation)
    if (!isNoCooldownTrigger && !isPostOnboarding) {
      final cooldownKey = '$_cooldownPrefix$triggerId';
      await prefs.setInt(cooldownKey, DateTime.now().millisecondsSinceEpoch);
    }

    return true;
  }

  /// Handle limit crossed event from repositories.
  ///
  /// This is the ONLY place where limit-crossed paywalls are triggered.
  /// Called by repositories after UsageLimitMonitor detects a crossing.
  ///
  /// Example:
  /// ```dart
  /// final crossed = await monitor.checkAndMarkIfCrossed(...);
  /// if (crossed) {
  ///   await SubscriptionService().handleLimitCrossed(metricType);
  /// }
  /// ```
  Future<void> handleLimitCrossed(String metricType) async {
    final triggerId = 'limit_crossed_$metricType';
    await presentPaywall(triggerId);
  }

  // =========================================================================
  // Purchase Management
  // =========================================================================

  /// Restore purchases from App Store / Play Store.
  ///
  /// Re-checks subscription status after restoration and emits new plan.
  /// Does nothing on unsupported platforms (desktop/web).
  Future<void> restorePurchases() async {
    if (!superwallSupportedPlatform) {
      AppLogger.d('Superwall not supported on this platform, skipping restore');
      return;
    }

    AppLogger.i('Restoring purchases');
    try {
      await Superwall.shared.restorePurchases();
    } catch (e) {
      AppLogger.e('Failed to restore purchases', error: e);
      rethrow;
    }

    // Re-check plan and emit
    final plan = await getCurrentPlan();
    _planController.add(plan);
  }

  // =========================================================================
  // Debug / Testing
  // =========================================================================

  /// Clear all paywall cooldowns.
  ///
  /// Used for testing and debugging only.
  /// Allows paywalls to be shown again immediately.
  Future<void> clearCooldowns() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_cooldownPrefix)).toList();

    for (final key in keys) {
      await prefs.remove(key);
    }

    AppLogger.d('Cleared ${keys.length} paywall cooldowns');
  }

  /// Dispose of resources.
  ///
  /// Call this when the service is no longer needed.
  void dispose() {
    _planController.close();
  }
}
