// lib/domain/entitlements/plan_type.dart
//
// Subscription plan types for the Incore Finance app.
// Used by EntitlementService to determine feature access and limits.

/// Subscription plan types for the app.
///
/// [free] - Default plan with usage limits and restricted features.
/// [premium] - Paid plan with full access to all features.
enum PlanType {
  /// Free plan with usage limits.
  /// - Limited spend entries (50)
  /// - Limited recurring expenses (5)
  /// - Limited income events (3)
  /// - No analytics access
  /// - No historical data access
  /// - No export functionality
  free,

  /// Premium plan with full access.
  /// - Unlimited spend entries
  /// - Unlimited recurring expenses
  /// - Unlimited income events
  /// - Full analytics access
  /// - Historical data access
  /// - Export functionality
  premium,
}
