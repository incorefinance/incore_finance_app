import '../interpretation/category_breakdown_interpretation.dart';
import '../rules/category_breakdown_rules.dart';

/// Interprets Category Breakdown data (Income or Expense).
class CategoryBreakdownInterpreter {
  const CategoryBreakdownInterpreter();

  /// Generate interpretation for category breakdown data.
  /// Returns null if no meaningful categories exist.
  /// Returns domain-only interpretation (no localization).
  /// UI should map the reason to localized label + explanation.
  CategoryBreakdownInterpretation? interpret({
    required List<Map<String, dynamic>> categories,
  }) {
    return CategoryBreakdownRules.evaluate(categories: categories);
  }
}
