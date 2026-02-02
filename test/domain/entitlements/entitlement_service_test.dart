// test/domain/entitlements/entitlement_service_test.dart
//
// Unit tests for EntitlementService.
// Tests cover all methods for free and premium plans, including boundary conditions.

import 'package:flutter_test/flutter_test.dart';
import 'package:incore_finance/domain/entitlements/entitlement_config.dart';
import 'package:incore_finance/domain/entitlements/entitlement_service.dart';
import 'package:incore_finance/domain/entitlements/plan_type.dart';

void main() {
  group('EntitlementService with default config', () {
    late EntitlementService service;

    setUp(() {
      service = EntitlementService();
    });

    group('canAccessAnalytics', () {
      test('returns true for premium plan', () {
        expect(service.canAccessAnalytics(PlanType.premium), isTrue);
      });

      test('returns false for free plan', () {
        expect(service.canAccessAnalytics(PlanType.free), isFalse);
      });
    });

    group('canViewHistoricalData', () {
      test('returns true for premium plan', () {
        expect(service.canViewHistoricalData(PlanType.premium), isTrue);
      });

      test('returns false for free plan', () {
        expect(service.canViewHistoricalData(PlanType.free), isFalse);
      });
    });

    group('canExportData', () {
      test('returns true for premium plan', () {
        expect(service.canExportData(PlanType.premium), isTrue);
      });

      test('returns false for free plan', () {
        expect(service.canExportData(PlanType.free), isFalse);
      });
    });

    group('canAddMoreSpendEntries', () {
      test('returns true for premium plan regardless of count', () {
        expect(
          service.canAddMoreSpendEntries(
            plan: PlanType.premium,
            currentCount: 0,
          ),
          isTrue,
        );
        expect(
          service.canAddMoreSpendEntries(
            plan: PlanType.premium,
            currentCount: 1000,
          ),
          isTrue,
        );
      });

      test('returns true for free plan when below limit (19)', () {
        expect(
          service.canAddMoreSpendEntries(
            plan: PlanType.free,
            currentCount: 19,
          ),
          isTrue,
        );
      });

      test('returns false for free plan at limit (20)', () {
        expect(
          service.canAddMoreSpendEntries(
            plan: PlanType.free,
            currentCount: 20,
          ),
          isFalse,
        );
      });

      test('returns false for free plan above limit (21)', () {
        expect(
          service.canAddMoreSpendEntries(
            plan: PlanType.free,
            currentCount: 21,
          ),
          isFalse,
        );
      });

      test('returns true for free plan at zero count', () {
        expect(
          service.canAddMoreSpendEntries(
            plan: PlanType.free,
            currentCount: 0,
          ),
          isTrue,
        );
      });
    });

    group('canAddMoreRecurringExpenses', () {
      test('returns true for premium plan regardless of count', () {
        expect(
          service.canAddMoreRecurringExpenses(
            plan: PlanType.premium,
            currentCount: 0,
          ),
          isTrue,
        );
        expect(
          service.canAddMoreRecurringExpenses(
            plan: PlanType.premium,
            currentCount: 100,
          ),
          isTrue,
        );
      });

      test('returns true for free plan when below limit (2)', () {
        expect(
          service.canAddMoreRecurringExpenses(
            plan: PlanType.free,
            currentCount: 2,
          ),
          isTrue,
        );
      });

      test('returns false for free plan at limit (3)', () {
        expect(
          service.canAddMoreRecurringExpenses(
            plan: PlanType.free,
            currentCount: 3,
          ),
          isFalse,
        );
      });

      test('returns false for free plan above limit (4)', () {
        expect(
          service.canAddMoreRecurringExpenses(
            plan: PlanType.free,
            currentCount: 4,
          ),
          isFalse,
        );
      });
    });

    group('canAddMoreIncomeEvents', () {
      test('returns true for premium plan regardless of count', () {
        expect(
          service.canAddMoreIncomeEvents(
            plan: PlanType.premium,
            currentCount: 0,
          ),
          isTrue,
        );
        expect(
          service.canAddMoreIncomeEvents(
            plan: PlanType.premium,
            currentCount: 100,
          ),
          isTrue,
        );
      });

      test('returns true for free plan when below limit (2)', () {
        expect(
          service.canAddMoreIncomeEvents(
            plan: PlanType.free,
            currentCount: 2,
          ),
          isTrue,
        );
      });

      test('returns false for free plan at limit (3)', () {
        expect(
          service.canAddMoreIncomeEvents(
            plan: PlanType.free,
            currentCount: 3,
          ),
          isFalse,
        );
      });

      test('returns false for free plan above limit (4)', () {
        expect(
          service.canAddMoreIncomeEvents(
            plan: PlanType.free,
            currentCount: 4,
          ),
          isFalse,
        );
      });
    });

    group('getLimitForMetric', () {
      test('returns 20 for spend_entries_count', () {
        expect(service.getLimitForMetric('spend_entries_count'), equals(20));
      });

      test('returns 3 for recurring_expenses_count', () {
        expect(
          service.getLimitForMetric('recurring_expenses_count'),
          equals(3),
        );
      });

      test('returns 3 for income_events_count', () {
        expect(service.getLimitForMetric('income_events_count'), equals(3));
      });

      test('returns 0 for unknown metric type', () {
        expect(service.getLimitForMetric('unknown_metric'), equals(0));
      });
    });
  });

  group('EntitlementService with custom config', () {
    test('respects custom spend entries limit', () {
      final customConfig = EntitlementConfig(
        freeMaxSpendEntries: 10,
        freeMaxRecurringExpenses: 2,
        freeMaxIncomeEvents: 1,
      );
      final service = EntitlementService(config: customConfig);

      expect(
        service.canAddMoreSpendEntries(
          plan: PlanType.free,
          currentCount: 9,
        ),
        isTrue,
      );
      expect(
        service.canAddMoreSpendEntries(
          plan: PlanType.free,
          currentCount: 10,
        ),
        isFalse,
      );
    });

    test('respects custom recurring expenses limit', () {
      final customConfig = EntitlementConfig(
        freeMaxSpendEntries: 10,
        freeMaxRecurringExpenses: 2,
        freeMaxIncomeEvents: 1,
      );
      final service = EntitlementService(config: customConfig);

      expect(
        service.canAddMoreRecurringExpenses(
          plan: PlanType.free,
          currentCount: 1,
        ),
        isTrue,
      );
      expect(
        service.canAddMoreRecurringExpenses(
          plan: PlanType.free,
          currentCount: 2,
        ),
        isFalse,
      );
    });

    test('respects custom income events limit', () {
      final customConfig = EntitlementConfig(
        freeMaxSpendEntries: 10,
        freeMaxRecurringExpenses: 2,
        freeMaxIncomeEvents: 1,
      );
      final service = EntitlementService(config: customConfig);

      expect(
        service.canAddMoreIncomeEvents(
          plan: PlanType.free,
          currentCount: 0,
        ),
        isTrue,
      );
      expect(
        service.canAddMoreIncomeEvents(
          plan: PlanType.free,
          currentCount: 1,
        ),
        isFalse,
      );
    });

    test('custom config with analytics access for free', () {
      final customConfig = EntitlementConfig(
        freeMaxSpendEntries: 10,
        freeMaxRecurringExpenses: 2,
        freeMaxIncomeEvents: 1,
        freeCanAccessAnalytics: true,
      );
      final service = EntitlementService(config: customConfig);

      expect(service.canAccessAnalytics(PlanType.free), isTrue);
      expect(service.canAccessAnalytics(PlanType.premium), isTrue);
    });

    test('getLimitForMetric returns custom limits', () {
      final customConfig = EntitlementConfig(
        freeMaxSpendEntries: 10,
        freeMaxRecurringExpenses: 2,
        freeMaxIncomeEvents: 1,
      );
      final service = EntitlementService(config: customConfig);

      expect(service.getLimitForMetric('spend_entries_count'), equals(10));
      expect(service.getLimitForMetric('recurring_expenses_count'), equals(2));
      expect(service.getLimitForMetric('income_events_count'), equals(1));
    });
  });

  group('EntitlementConfig', () {
    test('defaults factory creates expected values', () {
      final config = EntitlementConfig.defaults();

      expect(config.freeMaxSpendEntries, equals(20));
      expect(config.freeMaxRecurringExpenses, equals(3));
      expect(config.freeMaxIncomeEvents, equals(3));
      expect(config.freeCanAccessAnalytics, isFalse);
      expect(config.freeCanViewHistoricalData, isFalse);
      expect(config.freeCanExportData, isFalse);
    });

    test('canAccessAnalytics returns correct values', () {
      final config = EntitlementConfig.defaults();

      expect(config.canAccessAnalytics(PlanType.premium), isTrue);
      expect(config.canAccessAnalytics(PlanType.free), isFalse);
    });

    test('canViewHistoricalData returns correct values', () {
      final config = EntitlementConfig.defaults();

      expect(config.canViewHistoricalData(PlanType.premium), isTrue);
      expect(config.canViewHistoricalData(PlanType.free), isFalse);
    });

    test('canExportData returns correct values', () {
      final config = EntitlementConfig.defaults();

      expect(config.canExportData(PlanType.premium), isTrue);
      expect(config.canExportData(PlanType.free), isFalse);
    });
  });
}
