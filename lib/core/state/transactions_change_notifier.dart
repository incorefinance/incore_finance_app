// lib/core/state/transactions_change_notifier.dart
//
// Lightweight singleton notifier for transaction data changes.
// Used to trigger analytics refresh when transactions are mutated.
//
// Usage:
//   TransactionsChangeNotifier.instance.markChanged()  // after mutation
//   TransactionsChangeNotifier.instance.version        // listen for changes

import 'package:flutter/foundation.dart';

class TransactionsChangeNotifier {
  TransactionsChangeNotifier._();

  static final TransactionsChangeNotifier instance =
      TransactionsChangeNotifier._();

  /// Version counter that increments on each mutation.
  /// Listen to this to detect when transactions have changed.
  final ValueNotifier<int> version = ValueNotifier<int>(0);

  /// Call this after a successful transaction mutation (insert, update, delete).
  void markChanged() {
    version.value++;
    // ignore: avoid_print
    print('=== TransactionsChangeNotifier.markChanged() -> version: ${version.value}');
  }
}
