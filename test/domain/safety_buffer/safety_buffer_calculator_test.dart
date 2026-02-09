import 'package:flutter_test/flutter_test.dart';
import 'package:incore_finance/domain/safety_buffer/safety_buffer_calculator.dart';
import 'package:incore_finance/domain/tax_shield/tax_shield_snapshot.dart';
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

/// Helper to compute a TaxShieldSnapshot for SafetyBufferCalculator tests.
///
/// Mirrors the previous test setup where SafetyBufferCalculator internally
/// computed income and tax shield from transactions.
TaxShieldSnapshot _taxShield({
  required DateTime now,
  required double latestBalance,
  required List<TransactionRecord> insightTransactions,
  required double taxShieldPercent,
}) {
  const calculator = TaxShieldCalculator();
  return calculator.compute(
    now: now,
    latestBalance: latestBalance,
    insightTransactions: insightTransactions,
    taxShieldPercent: taxShieldPercent,
  );
}

void main() {
  const calculator = SafetyBufferCalculator();

  // Fixed reference date: 2025-03-15
  // thisMonthStart  = 2025-03-01
  // recentMonth     = 2025-02-01 .. 2025-03-01  (I1)
  // priorMonth      = 2025-01-01 .. 2025-02-01  (I2)
  final now = DateTime(2025, 3, 15);

  group('SafetyBufferCalculator', () {
    test('returns null bufferDays when monthlyFixedOutflow is 0', () {
      final taxShield = _taxShield(
        now: now,
        latestBalance: 5000,
        insightTransactions: [
          _tx(type: 'income', amount: 3000, date: DateTime(2025, 2, 10)),
        ],
        taxShieldPercent: 0.25,
      );
      final result = calculator.compute(
        taxShield: taxShield,
        monthlyFixedOutflow: 0,
      );

      expect(result.bufferDays, isNull);
      expect(result.bufferWeeks, isNull);
    });

    test('uses two months average when both months have income', () {
      final taxShield = _taxShield(
        now: now,
        latestBalance: 10000,
        insightTransactions: [
          _tx(type: 'income', amount: 3000, date: DateTime(2025, 2, 10)),
          _tx(type: 'income', amount: 5000, date: DateTime(2025, 1, 15)),
        ],
        taxShieldPercent: 0.25,
      );
      final result = calculator.compute(
        taxShield: taxShield,
        monthlyFixedOutflow: 1000,
      );

      expect(result.usedTwoMonths, isTrue);
      expect(result.monthlyInflow, equals(4000)); // (3000 + 5000) / 2
    });

    test('uses recent month only when prior month is 0', () {
      final taxShield = _taxShield(
        now: now,
        latestBalance: 10000,
        insightTransactions: [
          _tx(type: 'income', amount: 3000, date: DateTime(2025, 2, 10)),
        ],
        taxShieldPercent: 0.25,
      );
      final result = calculator.compute(
        taxShield: taxShield,
        monthlyFixedOutflow: 1000,
      );

      expect(result.usedTwoMonths, isFalse);
      expect(result.monthlyInflow, equals(3000));
    });

    test('applies tax shield and reduces available', () {
      final taxShield = _taxShield(
        now: now,
        latestBalance: 10000,
        insightTransactions: [
          _tx(type: 'income', amount: 8000, date: DateTime(2025, 2, 5)),
        ],
        taxShieldPercent: 0.25,
      );
      final result = calculator.compute(
        taxShield: taxShield,
        monthlyFixedOutflow: 1000,
      );

      expect(result.taxShieldReserved, equals(2000)); // 8000 * 0.25
      expect(result.available, equals(8000)); // max(0, 10000 - 2000)
    });

    test('caps to 180 days when dailyNet >= 0', () {
      // dailyInflow = 6000/30 = 200, dailyFixedOutflow = 3000/30 = 100
      // dailyNet = 100 (>= 0) → cap at 180
      final taxShield = _taxShield(
        now: now,
        latestBalance: 5000,
        insightTransactions: [
          _tx(type: 'income', amount: 6000, date: DateTime(2025, 2, 5)),
        ],
        taxShieldPercent: 0.25,
      );
      final result = calculator.compute(
        taxShield: taxShield,
        monthlyFixedOutflow: 3000,
      );

      expect(result.bufferDays, equals(180));
    });

    test('computes floor of available / abs(dailyNet) when dailyNet < 0', () {
      // monthlyInflow = 3000 (I1 only), taxShield = 750
      // available = max(0, 10000 - 750) = 9250
      // dailyInflow = 100, dailyFixedOutflow = 200, dailyNet = -100
      // bufferDays = floor(9250 / 100) = 92
      final taxShield = _taxShield(
        now: now,
        latestBalance: 10000,
        insightTransactions: [
          _tx(type: 'income', amount: 3000, date: DateTime(2025, 2, 5)),
        ],
        taxShieldPercent: 0.25,
      );
      final result = calculator.compute(
        taxShield: taxShield,
        monthlyFixedOutflow: 6000,
      );

      expect(result.bufferDays, equals(92));
      expect(result.bufferWeeks, equals(13.1)); // 92 / 7 ≈ 13.1
    });

    test('returns 0 days when available is 0', () {
      // monthlyInflow = 5000, taxShield = 1250
      // available = max(0, 1000 - 1250) = 0
      final taxShield = _taxShield(
        now: now,
        latestBalance: 1000,
        insightTransactions: [
          _tx(type: 'income', amount: 5000, date: DateTime(2025, 2, 5)),
        ],
        taxShieldPercent: 0.25,
      );
      final result = calculator.compute(
        taxShield: taxShield,
        monthlyFixedOutflow: 1000,
      );

      expect(result.bufferDays, equals(0));
      expect(result.bufferWeeks, equals(0.0));
    });

    test('NaN monthlyFixedOutflow treated as 0', () {
      final taxShield = _taxShield(
        now: now,
        latestBalance: double.nan,
        insightTransactions: [],
        taxShieldPercent: double.nan,
      );
      final result = calculator.compute(
        taxShield: taxShield,
        monthlyFixedOutflow: double.nan,
      );

      expect(result.balance, equals(0.0));
      expect(result.monthlyFixedOutflow, equals(0.0));
      // dailyFixedOutflow == 0 → bufferDays is null
      expect(result.bufferDays, isNull);
    });
  });
}
