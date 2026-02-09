import 'package:flutter_test/flutter_test.dart';
import 'package:incore_finance/domain/guidance/rules/expense_spike_rules.dart';

void main() {
  group('ExpenseSpikeRules', () {
    test('returns isSpike true when all thresholds met', () {
      // prior=100, recent=175 => absolute=75, percent=75%
      final result = ExpenseSpikeRules.evaluate(
        recentExpenseTotal: 175.0,
        priorExpenseTotal: 100.0,
      );
      expect(result.isSpike, isTrue);
      expect(result.absoluteIncrease, equals(75.0));
      expect(result.percentIncrease, equals(75.0));
    });

    test('returns isSpike false when prior below threshold', () {
      final result = ExpenseSpikeRules.evaluate(
        recentExpenseTotal: 200.0,
        priorExpenseTotal: 99.0,
      );
      expect(result.isSpike, isFalse);
    });

    test('returns isSpike false when recent below threshold', () {
      final result = ExpenseSpikeRules.evaluate(
        recentExpenseTotal: 149.0,
        priorExpenseTotal: 100.0,
      );
      expect(result.isSpike, isFalse);
    });

    test('returns isSpike false when absolute increase below threshold', () {
      final result = ExpenseSpikeRules.evaluate(
        recentExpenseTotal: 174.0,
        priorExpenseTotal: 100.0,
      );
      expect(result.isSpike, isFalse);
    });

    test('returns isSpike false when percent increase below threshold', () {
      // prior=200, recent=269 => percent=34.5%
      final result = ExpenseSpikeRules.evaluate(
        recentExpenseTotal: 269.0,
        priorExpenseTotal: 200.0,
      );
      expect(result.isSpike, isFalse);
    });

    test('treats NaN recent as 0', () {
      final result = ExpenseSpikeRules.evaluate(
        recentExpenseTotal: double.nan,
        priorExpenseTotal: 100.0,
      );
      expect(result.recentExpenseTotal, equals(0.0));
      expect(result.isSpike, isFalse);
    });

    test('treats NaN prior as 0', () {
      final result = ExpenseSpikeRules.evaluate(
        recentExpenseTotal: 200.0,
        priorExpenseTotal: double.nan,
      );
      expect(result.priorExpenseTotal, equals(0.0));
      expect(result.isSpike, isFalse);
    });

    test('handles zero prior expenses', () {
      final result = ExpenseSpikeRules.evaluate(
        recentExpenseTotal: 200.0,
        priorExpenseTotal: 0.0,
      );
      expect(result.isSpike, isFalse);
      expect(result.percentIncrease, equals(0.0));
    });
  });
}
