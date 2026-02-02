// lib/domain/entitlements/entitlement_service.dart
//
// Pure business logic for checking user entitlements based on their plan.
// Has NO dependencies on Flutter or Supabase for easy testing.

import 'entitlement_config.dart';
import 'plan_type.dart';

/// EntitlementService provides pure business logic for checking
/// what features and limits a user has based on their subscription plan.
///
/// This service has NO dependencies on Flutter or Supabase.
/// All methods are deterministic and easily unit tested.
///
/// Usage:
/// ```dart
/// final service = EntitlementService();
/// if (service.canAccessAnalytics(PlanType.free)) {
///   // Show analytics
/// }
/// ```
///
/// For testing with custom limits:
/// ```dart
/// final testConfig = EntitlementConfig(
///   freeMaxSpendEntries: 10,
///   freeMaxRecurringExpenses: 2,
///   freeMaxIncomeEvents: 1,
/// );
/// final service = EntitlementService(config: testConfig);
/// ```
class EntitlementService {
  final EntitlementConfig _config;

  /// Construct with optional config.
  ///
  /// If no config is provided, uses [EntitlementConfig.defaults] for
  /// production values.
  EntitlementService({EntitlementConfig? config})
      : _config = config ?? EntitlementConfig.defaults();

  /// Check if user can access the analytics dashboard.
  ///
  /// Returns true for premium users.
  /// Returns [EntitlementConfig.freeCanAccessAnalytics] for free users.
  bool canAccessAnalytics(PlanType plan) {
    return _config.canAccessAnalytics(plan);
  }

  /// Check if user can view historical data (beyond current month).
  ///
  /// Returns true for premium users.
  /// Returns [EntitlementConfig.freeCanViewHistoricalData] for free users.
  bool canViewHistoricalData(PlanType plan) {
    return _config.canViewHistoricalData(plan);
  }

  /// Check if user can export data to CSV/PDF.
  ///
  /// Returns true for premium users.
  /// Returns [EntitlementConfig.freeCanExportData] for free users.
  bool canExportData(PlanType plan) {
    return _config.canExportData(plan);
  }

  /// Check if user can add more spend entries (transactions).
  ///
  /// Returns true if:
  /// - Plan is premium (no limits), OR
  /// - Current count is below the free plan limit
  bool canAddMoreSpendEntries({
    required PlanType plan,
    required int currentCount,
  }) {
    if (plan == PlanType.premium) return true;
    return currentCount < _config.freeMaxSpendEntries;
  }

  /// Check if user can add more recurring expenses.
  ///
  /// Returns true if:
  /// - Plan is premium (no limits), OR
  /// - Current count is below the free plan limit
  bool canAddMoreRecurringExpenses({
    required PlanType plan,
    required int currentCount,
  }) {
    if (plan == PlanType.premium) return true;
    return currentCount < _config.freeMaxRecurringExpenses;
  }

  /// Check if user can add more income events.
  ///
  /// Returns true if:
  /// - Plan is premium (no limits), OR
  /// - Current count is below the free plan limit
  bool canAddMoreIncomeEvents({
    required PlanType plan,
    required int currentCount,
  }) {
    if (plan == PlanType.premium) return true;
    return currentCount < _config.freeMaxIncomeEvents;
  }

  /// Get the limit value for a given metric type.
  ///
  /// Used by [UsageLimitMonitor] to check if limits are exceeded.
  ///
  /// Metric types:
  /// - `spend_entries_count`
  /// - `recurring_expenses_count`
  /// - `income_events_count`
  int getLimitForMetric(String metricType) {
    switch (metricType) {
      case 'spend_entries_count':
        return _config.freeMaxSpendEntries;
      case 'recurring_expenses_count':
        return _config.freeMaxRecurringExpenses;
      case 'income_events_count':
        return _config.freeMaxIncomeEvents;
      default:
        return 0;
    }
  }

  /// Get the current configuration.
  ///
  /// Useful for debugging or displaying limits to users.
  EntitlementConfig get config => _config;
}
