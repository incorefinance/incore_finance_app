import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Empty state widget for when no transactions are found
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onAddTransaction;

  const EmptyStateWidget({
    super.key,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImageWidget(
              imageUrl:
                  'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=400&h=400&fit=crop',
              width: 50.w,
              height: 50.w,
              fit: BoxFit.contain,
              semanticLabel:
                  'Empty wallet illustration with coins and bills floating around a minimalist wallet icon',
            ),
            SizedBox(height: 3.h),
            Text(
              'No Transactions Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Start tracking your finances by adding your first transaction',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: onAddTransaction,
              icon: CustomIconWidget(
                iconName: 'add',
                size: 24,
                color: Colors.white,
              ),
              label: const Text('Add Your First Transaction'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
