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
  bool _showFilters = false;

  bool _isLoading = true;
  List<TransactionRecord> _allTransactions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTransactions();

    // Optional: pre select category from route args
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
    final filtered = _allTransactions.where((transaction) {
      final query = _searchQuery;

      final matchesSearch = query.isEmpty ||
          transaction.description.toLowerCase().contains(query) ||
          (transaction.client?.toLowerCase().contains(query) ?? false);

      final matchesCategory = _selectedCategory == null ||
          transaction.category == _selectedCategory;

      final matchesDateRange = _selectedDateRange == null ||
          _isInDateRange(transaction.date, _selectedDateRange!);

      return matchesSearch && matchesCategory && matchesDateRange;
    }).toList();

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
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Future<void> _handleAddTransaction() async {
    // Replace with your actual route if different
    final result = await Navigator.pushNamed(context, AppRoutes.addTransaction);

    if (result == true) {
      await _loadTransactions();
    }
  }

  Future<void> _showFilterBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FilterBottomSheet(
          // This matches the new API: currentFilters + onApplyFilters
          currentFilters: {
            'categoryId': _selectedCategory,
            'dateRange': _selectedDateRange,
          },
          onApplyFilters: (filters) {
            // Bubble the filters back up via Navigator.pop
            Navigator.of(context).pop(filters);
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedCategory = result['categoryId'];
        _selectedDateRange = result['dateRange'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactionsByMonth = _transactionsByMonth;
    final hasActiveFilters = _selectedCategory != null ||
        _selectedDateRange != null ||
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            // Filters row
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
                            CustomIconWidget(
                              iconName: hasActiveFilters ? 'tune' : 'filter_alt',
                              size: 18,
                              color: hasActiveFilters
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              hasActiveFilters ? 'Filters applied' : 'Filters',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: hasActiveFilters
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: hasActiveFilters
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  if (hasActiveFilters) ...[
                    SizedBox(width: 2.w),
                    GestureDetector(
                      onTap: _clearFilters,
                      child: Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'close',
                              size: 16,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            const Text('Clear'),
                          ],
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 1.h),
            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentGold,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color:
                                      colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              ElevatedButton(
                                onPressed: _loadTransactions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : transactionsByMonth.isEmpty
                          ? EmptyStateWidget(
                              onAddTransaction: _handleAddTransaction,
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTransactions,
                              color: AppTheme.accentGold,
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 2.h,
                                ),
                                itemCount: transactionsByMonth.length,
                                itemBuilder: (context, monthIndex) {
                                  final monthYear = transactionsByMonth.keys
                                      .elementAt(monthIndex);
                                  final transactions =
                                      transactionsByMonth[monthYear]!;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: monthIndex == 0 ? 0 : 2.h,
                                          bottom: 1.5.h,
                                        ),
                                        child: Text(
                                          monthYear,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      ...transactions
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final transaction = entry.value;
                                        final isLast = entry.key ==
                                            transactions.length - 1;

                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: isLast ? 0 : 2.h,
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
                                        );
                                      }).toList(),
                                    ],
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddTransaction,
        backgroundColor: AppTheme.accentGold,
        icon: const CustomIconWidget(
          iconName: 'add',
          color: AppTheme.primaryNavyLight,
          size: 24,
        ),
        label: Text(
          'Add Transaction',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.primaryNavyLight,
            fontWeight: FontWeight.w600,
          ),
        ),
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
