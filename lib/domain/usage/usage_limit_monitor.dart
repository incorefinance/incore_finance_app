// lib/domain/usage/usage_limit_monitor.dart
//
// Monitors usage and logs when free plan limits are crossed.
// IMPORTANT: This class is PURE domain logic - NO paywall triggers here.

import '../../core/logging/app_logger.dart';
import '../../data/usage/usage_metrics_repository.dart';
import '../entitlements/entitlement_service.dart';
import '../entitlements/plan_type.dart';

/// Monitors usage and logs when free plan limits are crossed.
///
/// This class is PURE domain logic:
/// - Checks if a limit is exceeded
/// - Marks the crossing timestamp in the database
/// - Logs the event
///
/// **IMPORTANT:** This class does NOT trigger paywalls.
/// Paywall orchestration is the responsibility of
/// [SubscriptionService.handleLimitCrossed].
///
/// Usage:
/// ```dart
/// final monitor = UsageLimitMonitor();
/// final crossed = await monitor.checkAndMarkIfCrossed(
///   metricType: UsageMetricsRepository.spendEntriesCount,
///   plan: currentPlan,
///   currentCount: newCount,
/// );
/// if (crossed) {
///   // Caller decides to trigger paywall via SubscriptionService
///   await SubscriptionService().handleLimitCrossed(metricType);
/// }
/// ```
class UsageLimitMonitor {
  final EntitlementService _entitlementService;
  final UsageMetricsRepository _usageMetricsRepository;

  /// Creates a UsageLimitMonitor with optional dependency injection.
  ///
  /// If not provided, creates default instances of dependencies.
  UsageLimitMonitor({
    EntitlementService? entitlementService,
    UsageMetricsRepository? usageMetricsRepository,
  })  : _entitlementService = entitlementService ?? EntitlementService(),
        _usageMetricsRepository =
            usageMetricsRepository ?? UsageMetricsRepository();

  /// Check if limit is crossed and mark if so.
  ///
  /// Returns `true` if limit was crossed for the first time.
  /// Returns `false` if:
  /// - Plan is premium (no limits)
  /// - Count is below limit
  /// - Already marked as crossed (prevents duplicate logging/triggers)
  ///
  /// When this returns `true`, the caller should trigger a paywall
  /// via [SubscriptionService.handleLimitCrossed].
  Future<bool> checkAndMarkIfCrossed({
    required String metricType,
    required PlanType plan,
    required int currentCount,
  }) async {
    // Premium users have no limits
    if (plan == PlanType.premium) return false;

    // Check if over limit
    final limit = _entitlementService.getLimitForMetric(metricType);
    if (currentCount < limit) return false;

    // Check if already marked
    final lastCrossed =
        await _usageMetricsRepository.getLastCrossed(metricType);
    if (lastCrossed != null) {
      // Already marked as crossed, don't log again
      return false;
    }

    // Mark as crossed and log
    await _usageMetricsRepository.markCrossed(metricType);
    AppLogger.i(
      'Usage limit crossed: $metricType at count $currentCount (limit: $limit)',
    );

    return true;
  }

  /// Check if a metric is currently over the limit (without marking).
  ///
  /// Useful for UI to show warnings or disable buttons.
  /// Does not modify any state.
  bool isOverLimit({
    required String metricType,
    required PlanType plan,
    required int currentCount,
  }) {
    if (plan == PlanType.premium) return false;
    final limit = _entitlementService.getLimitForMetric(metricType);
    return currentCount >= limit;
  }

  /// Get how many more items the user can add before hitting the limit.
  ///
  /// Returns:
  /// - `-1` for premium users (unlimited)
  /// - `0` if at or over limit
  /// - Positive number if under limit
  int getRemainingCapacity({
    required String metricType,
    required PlanType plan,
    required int currentCount,
  }) {
    if (plan == PlanType.premium) return -1; // Unlimited

    final limit = _entitlementService.getLimitForMetric(metricType);
    final remaining = limit - currentCount;
    return remaining > 0 ? remaining : 0;
  }
}
