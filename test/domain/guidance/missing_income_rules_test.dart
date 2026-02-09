import 'package:flutter_test/flutter_test.dart';
import 'package:incore_finance/domain/guidance/rules/missing_income_rules.dart';
import 'package:incore_finance/domain/guidance/insight_severity.dart';
import 'package:incore_finance/domain/onboarding/income_type.dart';

void main() {
  group('MissingIncomeRules', () {
    test('returns isMissing true with risk severity for fixed income type', () {
      final result = MissingIncomeRules.evaluate(
        incomeType: IncomeType.fixed,
        recentIncomeTotal: 0.0,
        priorIncomeTotal: 100.0,
      );
      expect(result.isMissing, isTrue);
      expect(result.severity, equals(InsightSeverity.risk));
    });

    test('returns isMissing true with risk severity for mixed income type', () {
      final result = MissingIncomeRules.evaluate(
        incomeType: IncomeType.mixed,
        recentIncomeTotal: 0.0,
        priorIncomeTotal: 150.0,
      );
      expect(result.isMissing, isTrue);
      expect(result.severity, equals(InsightSeverity.risk));
    });

    test('returns isMissing true with watch severity for variable income type', () {
      final result = MissingIncomeRules.evaluate(
        incomeType: IncomeType.variable,
        recentIncomeTotal: 0.0,
        priorIncomeTotal: 200.0,
      );
      expect(result.isMissing, isTrue);
      expect(result.severity, equals(InsightSeverity.watch));
    });

    test('returns isMissing true with risk severity for null income type', () {
      final result = MissingIncomeRules.evaluate(
        incomeType: null,
        recentIncomeTotal: 0.0,
        priorIncomeTotal: 100.0,
      );
      expect(result.isMissing, isTrue);
      expect(result.severity, equals(InsightSeverity.risk));
    });

    test('returns isMissing false when prior below threshold', () {
      final result = MissingIncomeRules.evaluate(
        incomeType: IncomeType.fixed,
        recentIncomeTotal: 0.0,
        priorIncomeTotal: 99.0,
      );
      expect(result.isMissing, isFalse);
      expect(result.severity, isNull);
    });

    test('returns isMissing false when recent > 0', () {
      final result = MissingIncomeRules.evaluate(
        incomeType: IncomeType.fixed,
        recentIncomeTotal: 50.0,
        priorIncomeTotal: 200.0,
      );
      expect(result.isMissing, isFalse);
      expect(result.severity, isNull);
    });

    test('treats NaN recent as 0', () {
      final result = MissingIncomeRules.evaluate(
        incomeType: IncomeType.fixed,
        recentIncomeTotal: double.nan,
        priorIncomeTotal: 100.0,
      );
      expect(result.recentIncomeTotal, equals(0.0));
      expect(result.isMissing, isTrue);
    });

    test('treats NaN prior as 0', () {
      final result = MissingIncomeRules.evaluate(
        incomeType: IncomeType.fixed,
        recentIncomeTotal: 0.0,
        priorIncomeTotal: double.nan,
      );
      expect(result.priorIncomeTotal, equals(0.0));
      expect(result.isMissing, isFalse);
    });
  });
}
