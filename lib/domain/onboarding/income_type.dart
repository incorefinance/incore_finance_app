/// Represents the user's income pattern type.
/// Used during onboarding to categorize income stability.
enum IncomeType {
  /// Consistent monthly income (salary, retainer).
  fixed,

  /// Income varies month to month (freelance, commissions).
  variable,

  /// Combination of fixed base with variable components.
  mixed,
}

/// Extension for IncomeType string conversion (for DB storage).
extension IncomeTypeExtension on IncomeType {
  String toDbValue() => name;

  static IncomeType? fromDbValue(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'fixed':
        return IncomeType.fixed;
      case 'variable':
        return IncomeType.variable;
      case 'mixed':
        return IncomeType.mixed;
      default:
        return null;
    }
  }
}
