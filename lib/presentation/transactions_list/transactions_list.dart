import 'package:flutter/material.dart';
import 'dart:collection';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:incore_finance/core/logging/app_logger.dart';
import 'package:incore_finance/core/navigation/route_observer.dart';
import 'package:incore_finance/core/state/transactions_change_notifier.dart';
import 'package:incore_finance/models/payment_method.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/transactions_repository.dart';
import 'package:incore_finance/presentation/add_transaction/add_transaction.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../theme/app_colors.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet.dart';
import './widgets/transaction_card.dart';

class _PendingDelete {
  final TransactionRecord transaction;
  final String monthKey;
  final int indexInMonth;
  final int indexInAllTransactions;
  Timer? timer;

  _PendingDelete({
    required this.transaction,
    required this.monthKey,
    required this.indexInMonth,
    required this.indexInAllTransactions,
  });
}

enum DateRangeFilter { today, week, month, year }

class TransactionFilters {
  final String query;
  final String? categoryId;
  final DateRangeFilter? dateRange;
  final PaymentMethod? paymentMethod;

  const TransactionFilters({
    this.query = '',
    this.categoryId,
    this.dateRange,
    this.paymentMethod,
  });

  TransactionFilters copyWith({
    String? query,
    String? categoryId,
    DateRangeFilter? dateRange,
    PaymentMethod? paymentMethod,
  }) {
    return TransactionFilters(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      dateRange: dateRange ?? this.dateRange,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      categoryId != null ||
      dateRange != null ||
      paymentMethod != null;
}

class TransactionsList extends StatefulWidget {
  const TransactionsList({super.key});

  @override
  State<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final TransactionsRepository _repository = TransactionsRepository();

  TransactionFilters _filters = const TransactionFilters();

  bool _isLoading = true;
  List<TransactionRecord> _allTransactions = [];
  String? _errorMessage;
  final Map<String, _PendingDelete> _pendingDeletesById = {};
  bool _isRouteObserverSubscribed = false;

  @override
  void initState() {
    AppLogger.d('[Transactions] initState → loading transactions');
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Listen to transaction changes and reload
    TransactionsChangeNotifier.instance.version.addListener(_onTransactionsChanged);
    
    _loadTransactions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null && args['categoryId'] != null) {
        setState(() {
          _filters = _filters.copyWith(categoryId: args['categoryId'] as String?);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    
    // Remove listener to change notifier
    TransactionsChangeNotifier.instance.version.removeListener(_onTransactionsChanged);
    
    // Commit any pending deletes before disposing
    _flushPendingDeletes();
    
    // Clean up timers
    for (final pending in _pendingDeletesById.values) {
      pending.timer?.cancel();
    }
    _pendingDeletesById.clear();
    
    // Unsubscribe from route observer
    AppRouteObserver.instance.unsubscribe(this);
    _isRouteObserverSubscribed = false;

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Guard against null route and prevent duplicate subscriptions
    if (!_isRouteObserverSubscribed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        AppRouteObserver.instance.subscribe(this, route);
        _isRouteObserverSubscribed = true;
      }
    }
  }

  @override
  void didPopNext() {
    AppLogger.d('[Transactions] didPopNext called, reloading transactions for stale state');
    _loadTransactions();
  }

  @override
  void didPushNext() {
    AppLogger.d('[Transactions] didPushNext called, flushing pending deletes before leaving screen');
    _flushPendingDeletes();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await _repository.getTransactionsForCurrentUserTyped();
      if (!mounted) return;

      setState(() {
        _allTransactions = List<TransactionRecord>.from(transactions);
        _isLoading = false;
      });
    } catch (e, st) {
      AppLogger.e('Error loading transactions', error: e, stackTrace: st);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load transactions';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load transactions. Please try again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadTransactions,
          ),
        ),
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _filters = _filters.copyWith(query: _searchController.text.toLowerCase());
      });
      _logFiltersChanged();
  }

void _logFiltersChanged() {
  AppLogger.d(
    '[Transactions] Filters changed: '
    'category=${_filters.categoryId} '
    'dateRange=${_filters.dateRange?.name} '
    'payment=${_filters.paymentMethod} '
    'query="${_filters.query}"',
  );
}

void _onTransactionsChanged() {
  AppLogger.d('[Transactions] Transaction change notifier triggered, reloading transactions');
  _loadTransactions();
}

  List<TransactionRecord> get _filteredTransactions {
  final filtered = _allTransactions.where((transaction) {
    final matchesSearch = _filters.query.isEmpty ||
        transaction.description.toLowerCase().contains(_filters.query) ||
        (transaction.client?.toLowerCase().contains(_filters.query) ?? false);

    final matchesCategory = _filters.categoryId == null ||
        transaction.category == _filters.categoryId;

    final matchesDateRange = _filters.dateRange == null ||
        _isInDateRange(transaction.date, _filters.dateRange!);

    final txPm = PaymentMethodParser.fromAny(transaction.paymentMethod);
    final matchesPaymentMethod =
        _filters.paymentMethod == null || txPm == _filters.paymentMethod;

    return matchesSearch &&
        matchesCategory &&
        matchesDateRange &&
        matchesPaymentMethod;
  }).toList();

  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
}

  Map<String, List<TransactionRecord>> get _transactionsByMonth {
    final grouped = <String, List<TransactionRecord>>{};
    final monthStartByKey = <String, DateTime>{};
    final uiLocale = Localizations.localeOf(context).toString();

    for (final transaction in _filteredTransactions) {
      final d = transaction.date;
      final monthDate = DateTime(d.year, d.month, 1);
      final key = DateFormat('MMMM yyyy', uiLocale).format(monthDate);

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(transaction);

      monthStartByKey.putIfAbsent(key, () => monthDate);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => monthStartByKey[b]!.compareTo(monthStartByKey[a]!));

    final sorted = LinkedHashMap<String, List<TransactionRecord>>();
    for (final key in sortedKeys) {
      sorted[key] = grouped[key]!;
    }

    return sorted;
  }

  DateRangeFilter? _parseDateRangeFilter(String? raw) {
    if (raw == null) return null;
    try {
      return DateRangeFilter.values.byName(raw);
    } catch (_) {
      return null;
    }
  }

  bool _isInDateRange(DateTime date, DateRangeFilter range) {
  final now = DateTime.now();
  switch (range) {
    case DateRangeFilter.today:
      return date.year == now.year && date.month == now.month && date.day == now.day;
    case DateRangeFilter.week:
      return date.isAfter(now.subtract(const Duration(days: 7)));
    case DateRangeFilter.month:
      return date.year == now.year && date.month == now.month;
    case DateRangeFilter.year:
      return date.year == now.year;
  }
}

  void _clearOnlyFilters() {
    setState(() {
      _filters = TransactionFilters(query: _filters.query);
    });

    _logFiltersChanged();
  }

  Widget _buildNoResultsState(ThemeData theme, ColorScheme colorScheme) {
    final hasNonQueryFilters =
        _filters.categoryId != null || _filters.dateRange != null || _filters.paymentMethod != null;

    final hasSearch = _filters.query.isNotEmpty;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.screenHorizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 1.2.h),
            Text(
              'No results found',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 0.6.h),
            Text(
              'Try adjusting your search or filters.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.6.h),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (hasNonQueryFilters)
                  TextButton(
                    onPressed: _clearOnlyFilters,
                    child: const Text('Clear filters'),
                  ),
                if (hasSearch)
                  TextButton(
                    onPressed: () {
                      _searchController.clear(); // listener will update _filters.query
                    },
                    child: const Text('Clear search'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMonthRows({
    required String monthKey,
    required List<TransactionRecord> monthTransactions,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final pendingForMonth = _pendingDeletesById.values
        .where((p) => p.monthKey == monthKey)
        .toList()
      ..sort((a, b) => a.indexInMonth.compareTo(b.indexInMonth));

    final widgets = <Widget>[];
    var txIndex = 0;
    var pendingIndex = 0;

    while (txIndex < monthTransactions.length || pendingIndex < pendingForMonth.length) {
      if (pendingIndex < pendingForMonth.length) {
        final pending = pendingForMonth[pendingIndex];
        final insertAt = pending.indexInMonth.clamp(0, monthTransactions.length);

        if (txIndex == insertAt) {
          widgets.add(
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.5.h),
              child: _DeletedInlineRow(
                message: 'Transaction deleted',
                actionLabel: 'Undo',
                onAction: () => _undoDeleteTransaction(pending.transaction.id),
                accentColor: colorScheme.primary,
              ),
            ),
          );
          pendingIndex++;
          continue;
        }
      }

      if (txIndex < monthTransactions.length) {
        final transaction = monthTransactions[txIndex];

        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 0.5.h),
            child: Dismissible(
              key: ValueKey('tx_${transaction.id}'),
              direction: DismissDirection.endToStart,
              dismissThresholds: const {
                DismissDirection.endToStart: 0.75,
              },
              confirmDismiss: (_) async {
                await _confirmAndDeleteTransaction(transaction);
                return false;
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 5.w),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: colorScheme.onError,
                ),
              ),
              child: TransactionCard(
                transaction: transaction,
                onEdit: () => _handleEditTransaction(transaction),
                onDelete: () => _confirmAndDeleteTransaction(transaction),
              ),
            ),
          ),
        );

        txIndex++;
        continue;
      }

      if (pendingIndex < pendingForMonth.length) {
        final pending = pendingForMonth[pendingIndex];
        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 0.5.h),
            child: _DeletedInlineRow(
              message: 'Transaction deleted',
              actionLabel: 'Undo',
              onAction: () => _undoDeleteTransaction(pending.transaction.id),
              accentColor: colorScheme.primary,
            ),
          ),
        );
        pendingIndex++;
      }
    }

    return widgets;
  }

  Future<void> _handleAddTransaction() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addTransaction);
    if (result == true) {
      await _loadTransactions();
    }
  }

  Future<void> _handleEditTransaction(TransactionRecord transaction) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => AddTransaction(initialTransaction: transaction),
    ),
  );

  if (result == true) {
    await _loadTransactions();
  }
}

  Future<void> _flushPendingDeletes() async {
    // Return early if no pending deletes
    if (_pendingDeletesById.isEmpty) {
      return;
    }

    AppLogger.d('[Transactions] Flushing ${_pendingDeletesById.length} pending deletes');

    // Copy pending ids to avoid concurrent modification
    final pendingIds = List<String>.from(_pendingDeletesById.keys);

    for (final id in pendingIds) {
      final pending = _pendingDeletesById[id];
      if (pending != null) {
        // Cancel timer if not null (we'll handle the delete ourselves)
        pending.timer?.cancel();
        
        // Commit the delete without awaiting (fire and forget)
        // This ensures the delete request is sent to Supabase immediately
        // even if we don't wait for the response
        unawaited(_repository.deleteTransaction(transactionId: id).then(
          (_) {
            AppLogger.d('[Transactions] Successfully flushed delete for transaction $id on navigation');
            // Remove from pending after delete succeeds
            _pendingDeletesById.remove(id);
          },
          onError: (e) {
            AppLogger.e('[Transactions] Error flushing delete for $id on navigation: $e');
            // Still remove from pending to avoid retry
            _pendingDeletesById.remove(id);
          },
        ));
      }
    }
  }

  Future<void> _handleDeleteTransaction(TransactionRecord transaction) async {
    if (!mounted) return;

    if (_pendingDeletesById.containsKey(transaction.id)) return;

    final d = transaction.date;
    final uiLocale = Localizations.localeOf(context).toString();
    final monthDate = DateTime(d.year, d.month, 1);
    final monthKey = DateFormat('MMMM yyyy', uiLocale).format(monthDate);

    final monthTransactions = _transactionsByMonth[monthKey] ?? const <TransactionRecord>[];
    final indexInMonth = monthTransactions.indexWhere((t) => t.id == transaction.id);
    final safeIndex = indexInMonth < 0 ? 0 : indexInMonth;

    // Capture the absolute position in _allTransactions before deletion
    final indexInAllTransactions = _allTransactions.indexWhere((t) => t.id == transaction.id);
    final safeIndexInAll = indexInAllTransactions < 0 ? 0 : indexInAllTransactions;

    final pending = _PendingDelete(
      transaction: transaction,
      monthKey: monthKey,
      indexInMonth: safeIndex,
      indexInAllTransactions: safeIndexInAll,
    );

    setState(() {
      _pendingDeletesById[transaction.id] = pending;
      _allTransactions.removeWhere((t) => t.id == transaction.id);
    });

    pending.timer = Timer(const Duration(seconds: 5), () async {
      await _commitPendingDelete(transaction.id);
    });
  }

  void _undoDeleteTransaction(String transactionId) {
    final pending = _pendingDeletesById.remove(transactionId);
    if (pending == null) return;

    pending.timer?.cancel();

    if (!mounted) return;
    setState(() {
      // Restore transaction at its exact original position
      final insertIndex = pending.indexInAllTransactions.clamp(0, _allTransactions.length);
      _allTransactions.insert(insertIndex, pending.transaction);
    });
  }

  Future<void> _commitPendingDelete(String transactionId) async {
    final pending = _pendingDeletesById.remove(transactionId);
    if (pending == null) return;

    AppLogger.d('[Transactions] Starting commit for pending delete, transaction id=$transactionId');

    if (mounted) {
      setState(() {});
    }

    try {
      await _repository.deleteTransaction(transactionId: transactionId);
      AppLogger.d('[Transactions] Successfully committed delete for transaction id=$transactionId');
    } catch (e, st) {
      AppLogger.e(
        '[Transactions] Failed to delete transaction id=$transactionId',
        error: e,
        stackTrace: st,
      );

      if (!mounted) return;
      setState(() {
        _allTransactions.add(pending.transaction);
        _allTransactions.sort((a, b) => b.date.compareTo(a.date));
      });
    }
  }

  Future<void> _confirmAndDeleteTransaction(TransactionRecord transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: const Text(
            'This transaction will be removed from your list. You can undo this action.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _handleDeleteTransaction(transaction);
    }
  }

  Future<void> _showFilterBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FilterBottomSheet(
          currentFilters: {
            'categoryId': _filters.categoryId,
            'dateRange': _filters.dateRange?.name,
            'paymentMethod': _filters.paymentMethod?.dbValue,
            'client': null,
            'startDate': null,
            'endDate': null,
          },
          onApplyFilters: (filters) {
            Navigator.of(context).pop(filters);
          },
        );
      },
    );

    AppLogger.d('[Transactions] FilterBottomSheet result applied');

    if (result != null && mounted) {
      setState(() {
        final categoryId = result['categoryId'] as String?;
        final dateRange = _parseDateRangeFilter(result['dateRange'] as String?);

        final pmRaw = result['paymentMethod'] as String?;
        final paymentMethod = PaymentMethodParser.fromAny(pmRaw);

        _filters = _filters.copyWith(
          categoryId: categoryId,
          dateRange: dateRange,
          paymentMethod: paymentMethod,
        );
      });
      _logFiltersChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactionsByMonth = _transactionsByMonth;

    final hasActiveFilters = _filters.hasActiveFilters;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.screenHorizontalPadding,
                AppTheme.screenTopPadding,
                AppTheme.screenHorizontalPadding,
                0,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search by description or client',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.screenHorizontalPadding),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    // Centered chip
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        decoration: ShapeDecoration(
                          color: hasActiveFilters
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : colorScheme.surfaceContainerHighest,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: hasActiveFilters
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _showFilterBottomSheet,
                              customBorder: const StadiumBorder(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.filter_alt, size: 18),
                                    SizedBox(width: 1.w),
                                    Text(
                                      hasActiveFilters ? 'Filters applied' : 'Filters',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: hasActiveFilters
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (hasActiveFilters)
                              IconButton(
                                onPressed: _clearOnlyFilters,
                                icon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                constraints: const BoxConstraints(),
                                tooltip: 'Clear filters',
                              ),
                          ],
                        ),
                      ),
                    ), 
                  ],
                ),
              ),
            ),

            SizedBox(height: 1.h),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTransactions,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.screenHorizontalPadding,
                              ),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.error),
                              ),
                            ),
                          )
                        : transactionsByMonth.isEmpty
                            ? (_allTransactions.isEmpty
                                ? EmptyStateWidget(onAddTransaction: _handleAddTransaction)
                                : _buildNoResultsState(theme, colorScheme))
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  left: AppTheme.screenHorizontalPadding,
                                  right: AppTheme.screenHorizontalPadding,
                                  top: 2.h,
                                  bottom: 12.h,
                                ),
                                itemCount: transactionsByMonth.length,
                                itemBuilder: (context, index) {
                                  final monthKey = transactionsByMonth.keys.elementAt(index);
                                  final monthTransactions = transactionsByMonth[monthKey]!;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(vertical: 1.h),
                                        child: Text(
                                          monthKey,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      ..._buildMonthRows(
                                        monthKey: monthKey,
                                        monthTransactions: monthTransactions,
                                      ),
                                    ],
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentItem: BottomBarItem.transactions,
        onItemSelected: (item) {},
        onAddTransaction: _handleAddTransaction,
      ),
    );
  }
}

class _DeletedInlineRow extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final Color accentColor;

  const _DeletedInlineRow({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
