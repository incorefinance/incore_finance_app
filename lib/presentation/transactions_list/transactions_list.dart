import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:incore_finance/core/logging/app_logger.dart';
import 'package:incore_finance/models/payment_method.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/transactions_repository.dart';
import 'package:incore_finance/presentation/add_transaction/add_transaction.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet.dart';
import './widgets/transaction_card.dart';

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

class _TransactionsListState extends State<TransactionsList> {
  final TextEditingController _searchController = TextEditingController();
  final TransactionsRepository _repository = TransactionsRepository();

  TransactionFilters _filters = const TransactionFilters();

  bool _isLoading = true;
  List<TransactionRecord> _allTransactions = [];
  String? _errorMessage;

  @override
  void initState() {
    AppLogger.d('[Transactions] initState → loading transactions');
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
    super.dispose();
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

  List<TransactionRecord> get _filteredTransactions {
  final filtered = _allTransactions.where((transaction) {
    final matchesSearch = _filters.query.isEmpty ||
        (transaction.description?.toLowerCase().contains(_filters.query) ??
            false) ||
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

    for (final transaction in _filteredTransactions) {
      final d = transaction.date;
      final key = '${_getMonthName(d.month)} ${d.year}';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(transaction);

      monthStartByKey.putIfAbsent(key, () => DateTime(d.year, d.month));
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => monthStartByKey[b]!.compareTo(monthStartByKey[a]!));

    final sorted = LinkedHashMap<String, List<TransactionRecord>>();
    for (final key in sortedKeys) {
      sorted[key] = grouped[key]!;
    }

    return sorted;
  }

  String _getMonthName(int month) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return months[month - 1];
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

  void _clearFilters() {
    setState(() {
      _filters = const TransactionFilters();
      _searchController.clear();
    });
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
        padding: EdgeInsets.symmetric(horizontal: 8.w),
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

  Future<void> _handleDeleteTransaction(TransactionRecord transaction) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Optimistic UI update
    setState(() {
      _allTransactions.removeWhere((t) => t.id == transaction.id);
    });

    SnackBar _snack(String text, {SnackBarAction? action}) {
  // CustomBottomBar is visually ~70–80px tall in your UI.
  // Use a fixed margin that reliably places the SnackBar just above it on web + mobile.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SnackBar(
      content: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0A1B2C), // navy
          fontWeight: FontWeight.w600,
        ),
      ),
      action: action == null
          ? null
          : SnackBarAction(
              label: action.label,
              onPressed: action.onPressed,
              textColor: const Color(0xFF0A1B2C), // navy
            ),
      backgroundColor: const Color(0xFFF4F4F4), // off white
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5), // <-- ensures it disappears
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        // Fixed offset tuned for your bottom bar + FAB overlap.
        bottom: bottomInset + 96,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 2,
    );
  }

    try {
      await _repository.deleteTransaction(
        transactionId: transaction.id,
      );

      final messenger = ScaffoldMessenger.of(context);

      // Always clear any existing snackbars first
      messenger.clearSnackBars();

      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Transaction deleted',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom + 12,
          ),
          backgroundColor: const Color(0xFF1C1C1E), // neutral dark (system-like)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFFE5E5EA), // subtle light gray
            onPressed: () {
              _undoDeleteTransaction(transaction);
            },
          ),
        ),
      );

    } catch (e, st) {
      // Rollback UI on failure
      setState(() {
        _allTransactions.add(transaction);
        _allTransactions.sort((a, b) => b.date.compareTo(a.date));
      });

      AppLogger.e(
        '[Transactions] Failed to delete transaction id=${transaction.id}',
        error: e,
        stackTrace: st,
      );

      scaffoldMessenger.showSnackBar(
        _snack('Failed to delete transaction'),
      );
    }
  }

  Future<void> _undoDeleteTransaction(TransactionRecord transaction) async {
    try {
      await _repository.restoreTransaction(
        transactionId: transaction.id,
      );

      setState(() {
        _allTransactions.add(transaction);
        _allTransactions.sort((a, b) => b.date.compareTo(a.date));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to restore transaction'),
        ),
      );
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
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
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
              padding: EdgeInsets.symmetric(horizontal: 4.w),
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
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                              ),
                            ),
                          )
                        : transactionsByMonth.isEmpty
                            ? (_allTransactions.isEmpty
                                ? EmptyStateWidget(onAddTransaction: _handleAddTransaction)
                                : _buildNoResultsState(theme, colorScheme))
                            : ListView.builder(
                                padding: EdgeInsets.only(left: 4.w, right: 4.w, top: 2.h, bottom: 12.h),
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
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      ...monthTransactions.map(
                                        (transaction) => Padding(
                                          padding: EdgeInsets.symmetric(vertical: 0.5.h),
                                          child: TransactionCard(
                                            transaction: transaction,
                                            onEdit: () => _handleEditTransaction(transaction),
                                            onDelete: () => _confirmAndDeleteTransaction(transaction),
                                          ),
                                        ),
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
