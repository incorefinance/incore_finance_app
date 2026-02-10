import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_colors.dart';

/// Welcome screen - First step of the onboarding flow.
/// Introduces the user to the setup process with a friendly message.
class OnboardingWelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingWelcomeScreen({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.canvasFrostedLight,
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
                          iconName: 'rocket_launch',
                          size: 10.w,
                          color: AppColors.blue600,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Let's set up the basics so the app reflects your real situation.",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'This will only take a moment.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.slate500,
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
                    onPressed: onContinue,
                    child: const Text('Continue'),
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
