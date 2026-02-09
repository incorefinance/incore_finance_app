import 'insight_id.dart';
import 'insight_severity.dart';
import 'insight_action.dart';

/// Immutable model representing a guidance insight.
/// Domain-only - no localization dependencies.
class Insight {
  /// Unique identifier for this insight type.
  final InsightId id;

  /// Severity level of the insight.
  final InsightSeverity severity;

  /// Optional suggested action.
  final InsightAction? action;

  const Insight({
    required this.id,
    required this.severity,
    this.action,
  });
}
