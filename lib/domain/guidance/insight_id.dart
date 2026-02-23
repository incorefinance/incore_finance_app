/// Unique identifiers for insights.
enum InsightId {
  /// Cash balance is low or trending down.
  lowCashBuffer,

  /// Cash runway is short relative to expense burn.
  lowCashRunway,

  /// No income recorded when prior period had income.
  missingIncome,

  /// Expenses have spiked compared to prior period.
  expenseSpike,

  /// Current month spending exceeds budget allocation (>150% of expected).
  budgetOverspend,

  /// Spending is trending over budget allocation (120%+ of expected).
  budgetPacing,

  /// Income has high volatility (coefficient of variation > 0.4).
  volatileIncome,

  /// Budget is tight after reserves (<20% of income spendable).
  tightBudget,
}
