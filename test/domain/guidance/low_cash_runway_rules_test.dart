import 'package:flutter_test/flutter_test.dart';
import 'package:incore_finance/domain/guidance/rules/low_cash_runway_rules.dart';
import 'package:incore_finance/domain/guidance/insight_severity.dart';

void main() {
  group('LowCashRunwayRules', () {
    test('returns risk severity when runway < 30 days', () {
      // cash=500, monthly=600 => dailyBurn=20, runway=25 days
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 500.0,
        avgMonthlyExpense: 600.0,
      );
      expect(result.isTriggered, isTrue);
      expect(result.severity, equals(InsightSeverity.risk));
      expect(result.runwayDays, equals(25.0));
    });

    test('returns watch severity when runway >= 30 and < 60 days', () {
      // cash=1200, monthly=600 => dailyBurn=20, runway=60 days - still watch at boundary
      // Let's use cash=1100 => runway=55 days
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 1100.0,
        avgMonthlyExpense: 600.0,
      );
      expect(result.isTriggered, isTrue);
      expect(result.severity, equals(InsightSeverity.watch));
      expect(result.runwayDays, equals(55.0));
    });

    test('returns not triggered when runway >= 60 days', () {
      // cash=1200, monthly=600 => dailyBurn=20, runway=60 days (boundary)
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 1200.0,
        avgMonthlyExpense: 600.0,
      );
      expect(result.isTriggered, isFalse);
      expect(result.severity, isNull);
      expect(result.runwayDays, equals(60.0));
    });

    test('returns not triggered when cash is zero', () {
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 0.0,
        avgMonthlyExpense: 600.0,
      );
      expect(result.isTriggered, isFalse);
      expect(result.severity, isNull);
    });

    test('returns not triggered when cash is negative', () {
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: -100.0,
        avgMonthlyExpense: 600.0,
      );
      expect(result.isTriggered, isFalse);
      expect(result.severity, isNull);
    });

    test('returns not triggered when monthly expense is zero', () {
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 1000.0,
        avgMonthlyExpense: 0.0,
      );
      expect(result.isTriggered, isFalse);
      expect(result.severity, isNull);
    });

    test('returns not triggered when monthly expense is negative', () {
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 1000.0,
        avgMonthlyExpense: -100.0,
      );
      expect(result.isTriggered, isFalse);
      expect(result.severity, isNull);
    });

    test('treats NaN cash as 0', () {
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: double.nan,
        avgMonthlyExpense: 600.0,
      );
      expect(result.latestCashBalance, equals(0.0));
      expect(result.isTriggered, isFalse);
    });

    test('treats NaN monthly expense as 0', () {
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 1000.0,
        avgMonthlyExpense: double.nan,
      );
      expect(result.avgMonthlyExpense, equals(0.0));
      expect(result.isTriggered, isFalse);
    });

    test('boundary: exactly 30 days runway is watch not risk', () {
      // cash=600, monthly=600 => dailyBurn=20, runway=30 days exactly
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 600.0,
        avgMonthlyExpense: 600.0,
      );
      expect(result.isTriggered, isTrue);
      expect(result.severity, equals(InsightSeverity.watch));
      expect(result.runwayDays, equals(30.0));
    });

    test('boundary: just under 30 days is risk', () {
      // cash=590, monthly=600 => dailyBurn=20, runway=29.5 days
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 590.0,
        avgMonthlyExpense: 600.0,
      );
      expect(result.isTriggered, isTrue);
      expect(result.severity, equals(InsightSeverity.risk));
      expect(result.runwayDays, equals(29.5));
    });

    test('boundary: just under 60 days is watch', () {
      // cash=1180, monthly=600 => dailyBurn=20, runway=59 days
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 1180.0,
        avgMonthlyExpense: 600.0,
      );
      expect(result.isTriggered, isTrue);
      expect(result.severity, equals(InsightSeverity.watch));
      expect(result.runwayDays, equals(59.0));
    });

    test('high cash balance with moderate expenses is not triggered', () {
      // cash=5000, monthly=600 => dailyBurn=20, runway=250 days
      final result = LowCashRunwayRules.evaluate(
        latestCashBalance: 5000.0,
        avgMonthlyExpense: 600.0,
      );
      expect(result.isTriggered, isFalse);
      expect(result.runwayDays, equals(250.0));
    });
  });
}
