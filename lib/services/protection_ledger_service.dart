// lib/services/protection_ledger_service.dart
//
// Service for managing protection ledger allocations.
// Handles income-based credits for tax and safety reserves.

import '../core/logging/app_logger.dart';
import '../models/transaction_record.dart';
import '../services/user_settings_service.dart';
import 'protection_ledger_repository.dart';

/// Service for allocating tax and safety credits from income transactions.
///
/// Responsibilities:
/// - Create credits when income is added
/// - Reallocate credits when income is updated
/// - Remove credits when income is deleted
///
/// IMPORTANT: Uses UserSettingsService for settings (centralized).
/// IMPORTANT: Does NOT pass userId to repository - auth injection handles it.
class ProtectionLedgerService {
  final ProtectionLedgerRepository _repository;
  final UserSettingsService _settingsService;

  ProtectionLedgerService({
    ProtectionLedgerRepository? repository,
    UserSettingsService? settingsService,
  })  : _repository = repository ?? ProtectionLedgerRepository(),
        _settingsService = settingsService ?? UserSettingsService();

  /// Allocate tax and safety credits for a newly created income transaction.
  ///
  /// Does nothing if transaction is not income type.
  /// Logs and continues if allocation fails (non-blocking).
  Future<void> allocateOnIncomeCreated(TransactionRecord income) async {
    if (income.type != 'income') return;

    try {
      final transactionId = int.tryParse(income.id);
      if (transactionId == null) {
        AppLogger.w(
          '[ProtectionLedgerService] Cannot parse transaction ID: ${income.id}',
        );
        return;
      }

      final taxPercent = await _settingsService.getTaxShieldPercent();
      final safetyPercent = await _settingsService.getSafetyBufferPercent();

      final taxAmount = income.amount * taxPercent;
      final safetyAmount = income.amount * safetyPercent;

      if (taxAmount <= 0 && safetyAmount <= 0) {
        AppLogger.d('[ProtectionLedgerService] No credits to allocate (0% rates)');
        return;
      }

      await _repository.insertCreditEntries(
        sourceTransactionId: transactionId,
        taxAmount: taxAmount,
        taxPercent: taxPercent,
        safetyAmount: safetyAmount,
        safetyPercent: safetyPercent,
      );

      AppLogger.d(
        '[ProtectionLedgerService] Allocated credits for income ${income.id} '
        '(tax: $taxAmount, safety: $safetyAmount)',
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        '[ProtectionLedgerService] Failed to allocate on income created',
        error: e,
        stackTrace: stackTrace,
      );
      // Non-blocking: log and continue
    }
  }

  /// Reallocate credits when an income transaction is updated.
  ///
  /// Strategy: Delete existing credits, then insert fresh ones.
  /// Does nothing if transaction is not income type.
  Future<void> reallocateOnIncomeUpdated(TransactionRecord income) async {
    if (income.type != 'income') return;

    try {
      final transactionId = int.tryParse(income.id);
      if (transactionId == null) {
        AppLogger.w(
          '[ProtectionLedgerService] Cannot parse transaction ID: ${income.id}',
        );
        return;
      }

      // Delete existing credits for this income
      await _repository.deleteBySourceTransactionId(transactionId);

      // Allocate fresh credits
      final taxPercent = await _settingsService.getTaxShieldPercent();
      final safetyPercent = await _settingsService.getSafetyBufferPercent();

      final taxAmount = income.amount * taxPercent;
      final safetyAmount = income.amount * safetyPercent;

      if (taxAmount > 0 || safetyAmount > 0) {
        await _repository.insertCreditEntries(
          sourceTransactionId: transactionId,
          taxAmount: taxAmount,
          taxPercent: taxPercent,
          safetyAmount: safetyAmount,
          safetyPercent: safetyPercent,
        );
      }

      AppLogger.d(
        '[ProtectionLedgerService] Reallocated credits for income ${income.id}',
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        '[ProtectionLedgerService] Failed to reallocate on income updated',
        error: e,
        stackTrace: stackTrace,
      );
      // Non-blocking: log and continue
    }
  }

  /// Remove all credits linked to a deleted income transaction.
  Future<void> removeAllocationsOnIncomeDeleted(int transactionId) async {
    try {
      await _repository.deleteBySourceTransactionId(transactionId);
      AppLogger.d(
        '[ProtectionLedgerService] Removed credits for deleted income $transactionId',
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        '[ProtectionLedgerService] Failed to remove allocations on income deleted',
        error: e,
        stackTrace: stackTrace,
      );
      // Non-blocking: log and continue
    }
  }
}
