// lib/domain/entitlements/entitlement_config.dart
//
// Immutable configuration for entitlement limits and feature flags.
// Injected into EntitlementService for testability.

import 'plan_type.dart';

/// Immutable configuration for entitlement limits and feature flags.
///
/// This class defines:
/// - Numeric limits for free plan users (window-based, not lifetime)
/// - Boolean feature flags for analytics, historical data, and export
///
/// Window semantics:
/// - [freeMaxSpendEntries]: per calendar month
/// - [freeMaxRecurringExpenses]: active at same time
/// - [freeMaxIncomeEvents]: per calendar month
///
/// Designed to be injected into [EntitlementService] for easy testing
/// with custom configurations. Use [EntitlementConfig.defaults] for
/// production values.
class EntitlementConfig {
  /// Maximum spend entries (transactions) for free plan per calendar month.
  final int freeMaxSpendEntries;

  /// Maximum active recurring expenses for free plan at same time.
  final int freeMaxRecurringExpenses;

  /// Maximum income events for free plan per calendar month.
  final int freeMaxIncomeEvents;

  /// Whether free plan users can access the analytics dashboard.
  final bool freeCanAccessAnalytics;

  /// Whether free plan users can view historical data (beyond current month).
  final bool freeCanViewHistoricalData;

  /// Whether free plan users can export data to CSV/PDF.
  final bool freeCanExportData;

  /// Creates a new configuration with the specified limits and flags.
  const EntitlementConfig({
    required this.freeMaxSpendEntries,
    required this.freeMaxRecurringExpenses,
    required this.freeMaxIncomeEvents,
    this.freeCanAccessAnalytics = false,
    this.freeCanViewHistoricalData = false,
    this.freeCanExportData = false,
  });

  /// Production defaults for the Incore Finance app.
  ///
  /// Free plan limits (window-based):
  /// - 20 spend entries per calendar month
  /// - 3 active recurring expenses at same time
  /// - 3 income events per calendar month
  ///
  /// Premium-only features:
  /// - Analytics dashboard access
  /// - Historical data viewing
  /// - Data export
  factory EntitlementConfig.defaults() => const EntitlementConfig(
        freeMaxSpendEntries: 20,
        freeMaxRecurringExpenses: 3,
        freeMaxIncomeEvents: 3,
        freeCanAccessAnalytics: false,
        freeCanViewHistoricalData: false,
        freeCanExportData: false,
      );

  /// Check if a plan can access analytics based on this config.
  bool canAccessAnalytics(PlanType plan) {
    if (plan == PlanType.premium) return true;
    return freeCanAccessAnalytics;
  }

  /// Check if a plan can view historical data based on this config.
  bool canViewHistoricalData(PlanType plan) {
    if (plan == PlanType.premium) return true;
    return freeCanViewHistoricalData;
  }

  /// Check if a plan can export data based on this config.
  bool canExportData(PlanType plan) {
    if (plan == PlanType.premium) return true;
    return freeCanExportData;
  }
}
