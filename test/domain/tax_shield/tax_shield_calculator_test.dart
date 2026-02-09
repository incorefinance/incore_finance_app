import 'package:flutter_test/flutter_test.dart';
import 'package:incore_finance/domain/tax_shield/tax_shield_calculator.dart';
import 'package:incore_finance/models/transaction_record.dart';

/// Helper to build a minimal TransactionRecord for testing.
TransactionRecord _tx({
  required String type,
  required double amount,
  required DateTime date,
}) {
  return TransactionRecord(
    id: 'test',
    userId: 'u1',
    amount: amount,
    description: '',
    category: 'general',
    type: type,
    date: date,
  );
}

void main() {
  const calculator = TaxShieldCalculator();

  // Fixed reference date: 2025-03-15
  // thisMonthStart  = 2025-03-01
  // recentMonth     = 2025-02-01 .. 2025-03-01  (I1)
  // priorMonth      = 2025-01-01 .. 2025-02-01  (I2)
  final now = DateTime(2025, 3, 15);

  group('TaxShieldCalculator', () {
    test('single month income sets usedTwoMonths false', () {
      final result = calculator.compute(
        now: now,
        latestBalance: 10000,
        insightTransactions: [
          _tx(type: 'income', amount: 3000, date: DateTime(2025, 2, 10)),
        ],
        taxShieldPercent: 0.25,
      );

      expect(result.usedTwoMonths, isFalse);
      expect(result.monthlyInflow, equals(3000));
    });

    test('two months income averages and sets usedTwoMonths true', () {
      final result = calculator.compute(
        now: now,
        latestBalance: 10000,
        insightTransactions: [
          _tx(type: 'income', amount: 3000, date: DateTime(2025, 2, 10)),
          _tx(type: 'income', amount: 5000, date: DateTime(2025, 1, 15)),
        ],
        taxShieldPercent: 0.25,
      );

      expect(result.usedTwoMonths, isTrue);
      expect(result.monthlyInflow, equals(4000)); // (3000 + 5000) / 2
    });

    test('computes taxShieldReserved as monthlyInflow * percent', () {
      final result = calculator.compute(
        now: now,
        latestBalance: 10000,
        insightTransactions: [
          _tx(type: 'income', amount: 8000, date: DateTime(2025, 2, 5)),
        ],
        taxShieldPercent: 0.25,
      );

      expect(result.taxShieldReserved, equals(2000)); // 8000 * 0.25
      expect(result.availableAfterTax, equals(8000)); // max(0, 10000 - 2000)
    });

    test('availableAfterTax floors at 0 when reserve exceeds balance', () {
      final result = calculator.compute(
        now: now,
        latestBalance: 1000,
        insightTransactions: [
          _tx(type: 'income', amount: 5000, date: DateTime(2025, 2, 5)),
        ],
        taxShieldPercent: 0.25,
      );

      expect(result.taxShieldReserved, equals(1250)); // 5000 * 0.25
      expect(result.availableAfterTax, equals(0)); // max(0, 1000 - 1250)
    });

    test('NaN inputs sanitized to 0', () {
      final result = calculator.compute(
        now: now,
        latestBalance: double.nan,
        insightTransactions: [],
        taxShieldPercent: double.nan,
      );

      expect(result.balance, equals(0.0));
      expect(result.taxShieldPercent, equals(0.0));
      expect(result.monthlyInflow, equals(0.0));
      expect(result.taxShieldReserved, equals(0.0));
      expect(result.availableAfterTax, equals(0.0));
    });

    test('taxShieldPercent clamped to 0-1 range', () {
      // Percent > 1 should clamp to 1.0
      final resultHigh = calculator.compute(
        now: now,
        latestBalance: 10000,
        insightTransactions: [
          _tx(type: 'income', amount: 4000, date: DateTime(2025, 2, 5)),
        ],
        taxShieldPercent: 1.5,
      );

      expect(resultHigh.taxShieldPercent, equals(1.0));
      expect(resultHigh.taxShieldReserved, equals(4000)); // 4000 * 1.0

      // Negative percent should clamp to 0.0
      final resultLow = calculator.compute(
        now: now,
        latestBalance: 10000,
        insightTransactions: [
          _tx(type: 'income', amount: 4000, date: DateTime(2025, 2, 5)),
        ],
        taxShieldPercent: -0.5,
      );

      expect(resultLow.taxShieldPercent, equals(0.0));
      expect(resultLow.taxShieldReserved, equals(0.0)); // 4000 * 0.0
    });
  });
}
