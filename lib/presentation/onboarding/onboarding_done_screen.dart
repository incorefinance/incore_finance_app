import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

/// Done screen - Final step of the onboarding flow.
/// Confirms setup completion and directs user to the dashboard.
class OnboardingDoneScreen extends StatelessWidget {
  final VoidCallback onGoToDashboard;

  const OnboardingDoneScreen({
    super.key,
    required this.onGoToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.screenHorizontalPadding,
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'check_circle',
                          size: 10.w,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "You're all set.",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'You can update your starting balance in Settings. Manage recurring expenses from the Dashboard.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onGoToDashboard,
                    child: const Text('Go to Dashboard'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
