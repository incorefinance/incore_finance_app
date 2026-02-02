import 'package:flutter_test/flutter_test.dart';
import 'package:incore_finance/domain/onboarding/income_type.dart';

void main() {
  group('IncomeType', () {
    test('has three values: fixed, variable, mixed', () {
      expect(IncomeType.values.length, equals(3));
      expect(IncomeType.values, contains(IncomeType.fixed));
      expect(IncomeType.values, contains(IncomeType.variable));
      expect(IncomeType.values, contains(IncomeType.mixed));
    });
  });

  group('IncomeTypeExtension', () {
    test('toDbValue returns enum name', () {
      expect(IncomeType.fixed.toDbValue(), equals('fixed'));
      expect(IncomeType.variable.toDbValue(), equals('variable'));
      expect(IncomeType.mixed.toDbValue(), equals('mixed'));
    });

    test('fromDbValue parses valid strings', () {
      expect(IncomeTypeExtension.fromDbValue('fixed'), equals(IncomeType.fixed));
      expect(IncomeTypeExtension.fromDbValue('variable'), equals(IncomeType.variable));
      expect(IncomeTypeExtension.fromDbValue('mixed'), equals(IncomeType.mixed));
    });

    test('fromDbValue returns null for invalid input', () {
      expect(IncomeTypeExtension.fromDbValue(null), isNull);
      expect(IncomeTypeExtension.fromDbValue('invalid'), isNull);
      expect(IncomeTypeExtension.fromDbValue(''), isNull);
    });

    test('fromDbValue returns null for case-sensitive mismatch', () {
      expect(IncomeTypeExtension.fromDbValue('Fixed'), isNull);
      expect(IncomeTypeExtension.fromDbValue('VARIABLE'), isNull);
      expect(IncomeTypeExtension.fromDbValue('Mixed'), isNull);
    });
  });
}
