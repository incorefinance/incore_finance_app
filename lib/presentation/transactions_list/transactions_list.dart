import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/transactions_repository.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet.dart';
import './widgets/transaction_card.dart';

class TransactionsList extends StatefulWidget {
  const TransactionsList({super.key});

  @override
  State<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> {
  final TextEditingController _searchController = TextEditingController();
  final TransactionsRepository _repository = TransactionsRepository();

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedDateRange;
  String? _selectedPaymentMethod;
  bool _showFilters = false;

  bool _isLoading = true;
  List<TransactionRecord> _allTransactions = [];
  String? _errorMessage;

  @override
  void initState() {
    // DEBUG — detect if initState is being re-called
    // ignore: avoid_print
    print('[DEBUG initState] TransactionsList.initState() called - widget initialized');
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTransactions();

    // Optional: pre select category from route args (e.g. from dashboard)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null && args['categoryId'] != null) {
        setState(() {
          _selectedCategory = args['categoryId'] as String?;
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
      final transactions =
          await _repository.getTransactionsForCurrentUserTyped();

      if (!mounted) return;

      setState(() {
        _allTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading transactions: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load transactions';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load transactions. Please try again.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white),
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
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<TransactionRecord> get _filteredTransactions {
    // DEBUG — track state values when getter is called
    // ignore: avoid_print
    print('[DEBUG _filteredTransactions] Getter called - Current filter state:');
    // ignore: avoid_print
    print('  _selectedCategory: $_selectedCategory');
    // ignore: avoid_print
    print('  _selectedDateRange: $_selectedDateRange');
    // ignore: avoid_print
    print('  _selectedPaymentMethod: $_selectedPaymentMethod');
    // ignore: avoid_print
    print('  _searchQuery: "$_searchQuery"');
    // ignore: avoid_print
    print('  Total transactions: ${_allTransactions.length}');
    
    // DEBUG — sample first few transactions
    for (var i = 0; i < _allTransactions.length && i < 5; i++) {
      final t = _allTransactions[i];
      // ignore: avoid_print
      print('Transaction $i -> paymentMethod=${t.paymentMethod}, category=${t.category}, date=${t.date}');
    }

    final filtered = _allTransactions.where((transaction) {
      // DEBUG — active filters before checking this transaction
      // ignore: avoid_print
      print('Filter check -> category=$_selectedCategory, dateRange=$_selectedDateRange, payment=$_selectedPaymentMethod');

      final query = _searchQuery;

      final matchesSearch = query.isEmpty ||
          transaction.description.toLowerCase().contains(query) ||
          (transaction.client?.toLowerCase().contains(query) ?? false);

      final matchesCategory =
          _selectedCategory == null ||
          transaction.category == _selectedCategory;

      final matchesDateRange =
          _selectedDateRange == null ||
          _isInDateRange(transaction.date, _selectedDateRange!);

      final matchesPaymentMethod =
          _selectedPaymentMethod == null ||
          transaction.paymentMethod == _selectedPaymentMethod;

      return matchesSearch &&
          matchesCategory &&
          matchesDateRange &&
          matchesPaymentMethod;
        }).toList();

    // DEBUG — result size after filtering
    // ignore: avoid_print
    print('Filtered transactions count: ${filtered.length}');

    // Sort by date DESC (most recent first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;

  }

  Map<String, List<TransactionRecord>> get _transactionsByMonth {
    final grouped = <String, List<TransactionRecord>>{};

    for (final transaction in _filteredTransactions) {
      final d = transaction.date;
      final key = '${_getMonthName(d.month)} ${d.year}';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(transaction);
    }

    return grouped;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  bool _isInDateRange(DateTime date, String range) {
    final now = DateTime.now();

    switch (range) {
      case 'today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'week':
        return date.isAfter(now.subtract(const Duration(days: 7)));
      case 'month':
        return date.year == now.year && date.month == now.month;
      case 'year':
        return date.year == now.year;
      default:
        return true;
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDateRange = null;
      _selectedPaymentMethod = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Future<void> _handleAddTransaction() async {
    // Use the route name that actually exists in your app
    final result =
        await Navigator.pushNamed(context, AppRoutes.addTransaction);

    if (result == true) {
      await _loadTransactions();
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
          'categoryId': _selectedCategory,
          'dateRange': _selectedDateRange,
          'paymentMethod': _selectedPaymentMethod,
          'client': null,
          'startDate': null,
          'endDate': null,
        },
        onApplyFilters: (filters) {
          // ignore: avoid_print
          print('FilterBottomSheet -> returned filters: $filters');
          // ✅ DO NOT pop here anymore. The bottom sheet pops itself now.
        },
      );
    },
  );

  if (result != null && mounted) {
    // ignore: avoid_print
    print(
      '[DEBUG _showFilterBottomSheet] Bottom sheet returned result, applying filters...',
    );

    setState(() {
      _selectedCategory = result['categoryId'] as String?;
      _selectedDateRange = result['dateRange'] as String?;
      final pm = result['paymentMethod'];
      _selectedPaymentMethod = pm is String && pm.isNotEmpty ? pm : null;

      // ignore: avoid_print
      print(
        '[DEBUG _showFilterBottomSheet] AFTER setState - New filter state:',
      );
      // ignore: avoid_print
      print('  _selectedCategory: $_selectedCategory');
      // ignore: avoid_print
      print('  _selectedDateRange: $_selectedDateRange');
      // ignore: avoid_print
      print('  _selectedPaymentMethod: $_selectedPaymentMethod');
    });

    // ignore: avoid_print
    print(
      '[DEBUG _showFilterBottomSheet] setState completed - checking state again:',
    );
    // ignore: avoid_print
    print('  _selectedCategory: $_selectedCategory');
    // ignore: avoid_print
    print('  _selectedDateRange: $_selectedDateRange');
    // ignore: avoid_print
    print('  _selectedPaymentMethod: $_selectedPaymentMethod');
  }
}
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactionsByMonth = _transactionsByMonth;
    final hasActiveFilters =
        _selectedCategory != null ||
        _selectedDateRange != null ||
        _selectedPaymentMethod != null ||
        _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: EdgeInsets.all(4.w),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search by description or client',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ),

            // Filter chips row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                        if (_showFilters) {
                          _showFilterBottomSheet();
                        }
                      },
                      child: Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.filter_alt,
                              size: 18,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              hasActiveFilters ? 'Filters applied' : 'Filters',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: hasActiveFilters
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (hasActiveFilters) ...[
                              SizedBox(width: 1.w),
                              GestureDetector(
                                onTap: _clearFilters,
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        backgroundColor: hasActiveFilters
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
                    ),
                  ),
                  SizedBox(width: 2.w),
                  // Quick date filters (Today / Last 7 days / etc.)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.date_range),
                    onSelected: (value) {
                      setState(() {
                        _selectedDateRange = value == 'all' ? null : value;
                      });
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'all',
                        child: Text('All time'),
                      ),
                      PopupMenuItem(
                        value: 'today',
                        child: Text('Today'),
                      ),
                      PopupMenuItem(
                        value: 'week',
                        child: Text('Last 7 days'),
                      ),
                      PopupMenuItem(
                        value: 'month',
                        child: Text('This month'),
                      ),
                      PopupMenuItem(
                        value: 'year',
                        child: Text('This year'),
                      ),
                    ],
                  ),
                ],
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
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          )
                        : transactionsByMonth.isEmpty
                             ? EmptyStateWidget(
                                onAddTransaction: _handleAddTransaction,
                                )
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  left: 4.w,
                                  right: 4.w,
                                  top: 2.h,
                                  bottom: 12.h,
                                ),
                                itemCount: transactionsByMonth.length,
                                itemBuilder: (context, index) {
                                  final monthKey =
                                      transactionsByMonth.keys.elementAt(index);
                                  final monthTransactions =
                                      transactionsByMonth[monthKey]!;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 1.h,
                                        ),
                                        child: Text(
                                          monthKey,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      ...monthTransactions.map(
                                        (transaction) => Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 0.5.h,
                                          ),
                                          child: TransactionCard(
                                            transaction: transaction,
                                            onEdit: () {
                                              // TODO: implement edit
                                            },
                                            onDuplicate: () {
                                              // TODO: implement duplicate
                                            },
                                            onDelete: () {
                                              // TODO: implement delete
                                            },
                                            onAddNote: () {
                                              // TODO: implement add note
                                            },
                                            onMarkBusiness: () {
                                              // TODO: implement mark business
                                            },
                                            onShare: () {
                                              // TODO: implement share
                                            },
                                            onCategoryChange: (category) {
                                              // TODO: implement category change
                                            },
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
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddTransaction,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomBottomBar(
        currentItem: BottomBarItem.transactions,
        onItemSelected: (item) {
          // Navigation handled centrally
        },
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
