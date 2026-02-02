import 'package:flutter/material.dart';

import '../../services/onboarding_service.dart';
import '../../services/subscription/subscription_service.dart';
import '../../routes/app_routes.dart';
import 'onboarding_welcome_screen.dart';
import 'onboarding_currency_screen.dart';
import 'income_setup_screen.dart';
import 'onboarding_starting_balance_screen.dart';
import 'onboarding_recurring_expenses_screen.dart';
import 'onboarding_done_screen.dart';

/// Onboarding step enumeration for linear flow control.
enum OnboardingStep {
  welcome,
  currency,
  income,
  startingBalance,
  recurringExpenses,
  done,
}

/// OnboardingFlow manages the linear progression through all onboarding screens.
/// It ensures users complete required steps (currency) and can skip optional ones.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final OnboardingService _onboardingService = OnboardingService();
  OnboardingStep _currentStep = OnboardingStep.welcome;

  void _goToStep(OnboardingStep step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _nextStep() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        _goToStep(OnboardingStep.currency);
        break;
      case OnboardingStep.currency:
        _goToStep(OnboardingStep.income);
        break;
      case OnboardingStep.income:
        _goToStep(OnboardingStep.startingBalance);
        break;
      case OnboardingStep.startingBalance:
        _goToStep(OnboardingStep.recurringExpenses);
        break;
      case OnboardingStep.recurringExpenses:
        _goToStep(OnboardingStep.done);
        break;
      case OnboardingStep.done:
        _completeOnboarding();
        break;
    }
  }

  Future<void> _completeOnboarding() async {
    await _onboardingService.setOnboardingComplete();

    // Trigger post-onboarding paywall (respects cooldown)
    await SubscriptionService().presentPaywall('post_onboarding');

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboardHome,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_currentStep) {
      OnboardingStep.welcome => OnboardingWelcomeScreen(
          onContinue: _nextStep,
        ),
      OnboardingStep.currency => OnboardingCurrencyScreen(
          onContinue: _nextStep,
        ),
      OnboardingStep.income => IncomeSetupScreen(
          onContinue: _nextStep,
        ),
      OnboardingStep.startingBalance => OnboardingStartingBalanceScreen(
          onContinue: _nextStep,
          onSkip: _nextStep,
        ),
      OnboardingStep.recurringExpenses => OnboardingRecurringExpensesScreen(
          onDone: _nextStep,
          onSkip: _nextStep,
        ),
      OnboardingStep.done => OnboardingDoneScreen(
          onGoToDashboard: _completeOnboarding,
        ),
    };
  }
}
