// test/domain/usage/month_window_test.dart
//
// Unit tests for month window helpers.

import 'package:flutter_test/flutter_test.dart';
import 'package:incore_finance/domain/usage/month_window.dart';

void main() {
  group('MonthWindowMode', () {
    test('has dateOnly and timestamptz modes', () {
      expect(MonthWindowMode.values, contains(MonthWindowMode.dateOnly));
      expect(MonthWindowMode.values, contains(MonthWindowMode.timestamptz));
    });
  });

  group('getMonthStart', () {
    test('returns first day of month for dateOnly mode', () {
      final date = DateTime(2026, 3, 15, 14, 30, 45);
      final start = getMonthStart(date, MonthWindowMode.dateOnly);

      expect(start.year, equals(2026));
      expect(start.month, equals(3));
      expect(start.day, equals(1));
      expect(start.hour, equals(0));
      expect(start.minute, equals(0));
      expect(start.second, equals(0));
      expect(start.isUtc, isFalse);
    });

    test('returns first day of month in UTC for timestamptz mode', () {
      final date = DateTime(2026, 3, 15, 14, 30, 45);
      final start = getMonthStart(date, MonthWindowMode.timestamptz);

      expect(start.day, equals(1));
      expect(start.hour, equals(0));
      expect(start.minute, equals(0));
      expect(start.isUtc, isTrue);
    });
  });

  group('getNextMonthStart', () {
    test('returns first day of next month for dateOnly mode', () {
      final date = DateTime(2026, 3, 15);
      final nextStart = getNextMonthStart(date, MonthWindowMode.dateOnly);

      expect(nextStart.year, equals(2026));
      expect(nextStart.month, equals(4));
      expect(nextStart.day, equals(1));
      expect(nextStart.isUtc, isFalse);
    });

    test('handles December to January transition', () {
      final december = DateTime(2025, 12, 15);
      final nextStart = getNextMonthStart(december, MonthWindowMode.dateOnly);

      expect(nextStart.year, equals(2026));
      expect(nextStart.month, equals(1));
      expect(nextStart.day, equals(1));
    });

    test('returns UTC for timestamptz mode', () {
      final date = DateTime(2026, 3, 15);
      final nextStart = getNextMonthStart(date, MonthWindowMode.timestamptz);

      expect(nextStart.month, equals(4));
      expect(nextStart.isUtc, isTrue);
    });
  });

  group('getCurrentMonthBoundaries', () {
    test('returns tuple of monthStart and nextMonthStart', () {
      final (monthStart, nextMonthStart) =
          getCurrentMonthBoundaries(MonthWindowMode.dateOnly);

      expect(monthStart.day, equals(1));
      expect(nextMonthStart.day, equals(1));
      expect(nextMonthStart.isAfter(monthStart), isTrue);
    });

    test('boundaries are UTC for timestamptz mode', () {
      final (monthStart, nextMonthStart) =
          getCurrentMonthBoundaries(MonthWindowMode.timestamptz);

      expect(monthStart.isUtc, isTrue);
      expect(nextMonthStart.isUtc, isTrue);
    });
  });
}
