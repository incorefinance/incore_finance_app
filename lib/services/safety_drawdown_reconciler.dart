// lib/services/safety_drawdown_reconciler.dart
//
// Reconciler for safety buffer drawdowns when overspending occurs.
// Idempotent by data state, not session state.

import '../core/logging/app_logger.dart';
import 'protection_ledger_repository.dart';

/// Reconciles safety buffer drawdowns when safe_to_spend goes negative.
///
/// Idempotency: Uses recent debit matching to prevent duplicate drawdowns.
/// Tax is NEVER auto-decreased - only safety buffer is drawn down.
///
/// NOTE: Current idempotency is a soft guard using time-window + amount matching.
/// This is temporary and will be hardened in Phase 5 with proper unique constraints.
class SafetyDrawdownReconciler {
  final ProtectionLedgerRepository _repository;

  /// Window for detecting duplicate debits (prevents runaway duplicates).
  /// This is a temporary soft guard - Phase 5 will add proper idempotency.
  static const _deduplicationWindow = Duration(minutes: 10);

  SafetyDrawdownReconciler({
    ProtectionLedgerRepository? repository,
  }) : _repository = repository ?? ProtectionLedgerRepository();

  /// Reconcile safety drawdown if overspending has occurred.
  ///
  /// Algorithm:
  /// 1. Get current snapshot
  /// 2. If safe_to_spend >= 0, no action needed
  /// 3. Calculate deficit and available safety
  /// 4. Draw from safety (up to available)
  /// 5. Check for recent duplicate before inserting (soft idempotency)
  /// 6. If deficit remains after safety exhausted, log tax risk warning
  ///
  /// This method is idempotent and safe to call multiple times.
  Future<void> reconcileIfNeeded() async {
    try {
      // 1. Get current protection state
      final snapshot = await _repository.getProtectionSnapshot();

      // 2. No overspend - nothing to do
      if (snapshot.safeToSpend >= 0) {
        return;
      }

      // 3. Calculate deficit and available safety
      final deficit = snapshot.safeToSpend.abs();
      final availableSafety = snapshot.safetyProtected;

      // 4. Calculate draw amount (capped at available safety)
      final drawAmount = deficit < availableSafety ? deficit : availableSafety;

      if (drawAmount <= 0) {
        // No safety to draw, but deficit exists - log tax risk
        if (deficit > 0) {
          AppLogger.w(
            '[SafetyDrawdownReconciler] Tax risk: deficit of $deficit '
            'with no safety buffer available',
          );
        }
        return;
      }

      // 5. Check for recent duplicate debit (soft idempotency guard)
      // NOTE: This is temporary. Phase 5 will add proper unique constraints.
      final hasDuplicate = await _repository.hasRecentMatchingSafetyDebit(
        amount: drawAmount,
        window: _deduplicationWindow,
      );

      if (hasDuplicate) {
        AppLogger.d(
          '[SafetyDrawdownReconciler] Skipping - recent matching debit exists',
        );
        return;
      }

      // 6. Insert safety debit (userId injected by repository from auth)
      await _repository.insertSafetyDebit(amount: drawAmount);

      AppLogger.d(
        '[SafetyDrawdownReconciler] Created safety debit of $drawAmount '
        '(deficit: $deficit, available: $availableSafety)',
      );

      // 7. Log tax risk if deficit exceeds available safety
      if (deficit > availableSafety) {
        final remainingDeficit = deficit - availableSafety;
        AppLogger.w(
          '[SafetyDrawdownReconciler] Tax risk: remaining deficit of '
          '$remainingDeficit after safety exhausted (tax not touched)',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[SafetyDrawdownReconciler] Failed to reconcile',
        error: e,
        stackTrace: stackTrace,
      );
      // Non-blocking: log and continue
    }
  }
}
