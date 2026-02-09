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
}
