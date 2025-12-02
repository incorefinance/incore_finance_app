import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/transactions_repository.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet.dart';
import './widgets/transaction_card.dart';

/// Transactions List Screen
/// Filterable view of all financial transactions with search and date filtering
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

  // State for loading and data
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTransactions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTransactions();

    // Check if category filter was passed from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null && args['categoryId'] != null) {
        setState(() {
          _selectedCategory = args['categoryId'];
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
      final transactions = await _repository.getTransactionsForCurrentUser();

      // Convert date strings to DateTime objects
      final processedTransactions = transactions.map((transaction) {
        return {
          ...transaction,
          'date': transaction['date'] is String
              ? DateTime.parse(transaction['date'])
              : transaction['date'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allTransactions = processedTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load transactions';
        });

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load transactions. Please try again.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    // Apply filters first
    final filtered = _allTransactions.where((transaction) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          transaction['description'].toString().toLowerCase().contains(
                _searchQuery,
              ) ||
          (transaction['client']?.toString().toLowerCase().contains(
                    _searchQuery,
                  ) ??
              false);

      // Category filter
      final matchesCategory = _selectedCategory == null ||
          transaction['category'] == _selectedCategory;

      // Date range filter
      final matchesDateRange = _selectedDateRange == null ||
          _isInDateRange(transaction['date'], _selectedDateRange!);

      return matchesSearch && matchesCategory && matchesDateRange;
    }).toList();

    // Sort by date descending (most recent first)
    filtered.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  Map<String, List<Map<String, dynamic>>> get _transactionsByMonth {
    final groupedTransactions = <String, List<Map<String, dynamic>>>{};

    for (final transaction in _filteredTransactions) {
      final date = transaction['date'] as DateTime;
      final monthYear = '${_getMonthName(date.month)} ${date.year}';

      if (!groupedTransactions.containsKey(monthYear)) {
        groupedTransactions[monthYear] = [];
      }
      groupedTransactions[monthYear]!.add(transaction);
    }

    return groupedTransactions;
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
        return date.month == now.month && date.year == now.year;
      case 'year':
        return date.year == now.year;
      default:
        return true;
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilters: {
          'category': _selectedCategory,
          'dateRange': _selectedDateRange,
        },
        onApplyFilters: (filters) {
          setState(() {
            _selectedCategory = filters['category'];
            _selectedDateRange = filters['dateRange'];
          });
        },
      ),
    );
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
    // Navigate to Add Transaction screen and wait for result
    final result = await Navigator.pushNamed(context, AppRoutes.addTransaction);

    // If transaction was added successfully, reload the transactions list
    if (result == true) {
      await _loadTransactions();
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
            // Search Bar
            Padding(
              padding: EdgeInsets.all(4.w),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'close',
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ),

            // Filter Chips
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showFilterBottomSheet,
                    child: Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'filter_list',
                            size: 16,
                            color: hasActiveFilters
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                          SizedBox(width: 1.w),
                          Text('Filters'),
                        ],
                      ),
                      backgroundColor: hasActiveFilters
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
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
                            Text('Clear'),
                          ],
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 2.h),

            // Transaction List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accentGold,
                        ),
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
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
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
                              onAddTransaction: () {
                                // Handle add transaction
                              },
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
                                      // Month header
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
                                      // Transactions for this month
                                      ...transactions
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final transaction = entry.value;
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: entry.key ==
                                                    transactions.length - 1
                                                ? 0
                                                : 2.h,
                                          ),
                                          child: TransactionCard(
                                            transaction: transaction,
                                            onEdit: () {
                                              // Handle edit
                                            },
                                            onDuplicate: () {
                                              // Handle duplicate
                                            },
                                            onDelete: () {
                                              // Handle delete
                                            },
                                            onAddNote: () {
                                              // Handle add note
                                            },
                                            onMarkBusiness: () {
                                              // Handle mark business
                                            },
                                            onShare: () {
                                              // Handle share
                                            },
                                            onCategoryChange: (category) {
                                              // Handle category change
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
        foregroundColor: AppTheme.primaryNavyLight,
        elevation: 4.0,
        icon: CustomIconWidget(
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
          // Navigation handled by CustomBottomBar internally
        },
      ),
    );
  }
}
