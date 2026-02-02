import 'package:flutter/material.dart';
import '../presentation/settings/settings.dart';
import '../presentation/settings/subscription_screen.dart';
import '../presentation/analytics_dashboard/analytics_dashboard.dart';
import '../presentation/analytics_dashboard/analytics_gate_screen.dart';
import '../presentation/transactions_list/transactions_list.dart';
import '../presentation/add_transaction/add_transaction.dart';
import '../presentation/dashboard_home/dashboard_home.dart';
import '../presentation/recurring_expenses/recurring_expenses.dart';
import '../presentation/onboarding/onboarding_flow.dart';
import '../presentation/startup/startup_screen.dart';
import '../presentation/auth/auth_screen.dart';
import '../presentation/auth/email_verification_screen.dart';
import '../presentation/auth/forgot_password_screen.dart';
import '../presentation/auth/reset_password_screen.dart';
import '../presentation/auth/auth_guard_error_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String settings = '/settings';
  static const String subscriptionScreen = '/subscription';
  static const String analyticsDashboard = '/analytics-dashboard';
  static const String analyticsGate = '/analytics-gate';
  static const String transactionsList = '/transactions-list';
  static const String addTransaction = '/add-transaction';
  static const String dashboardHome = '/dashboard-home';
  static const String recurringExpenses = '/recurring-expenses';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String authGuardError = '/auth-guard-error';

  static Map<String, WidgetBuilder> get routes {
    return {
      initial: (context) => const StartupScreen(),
      settings: (context) => const Settings(),
      subscriptionScreen: (context) => const SubscriptionScreen(),
      analyticsDashboard: (context) => const AnalyticsDashboard(),
      analyticsGate: (context) => const AnalyticsGateScreen(),
      transactionsList: (context) => const TransactionsList(),
      addTransaction: (context) => const AddTransaction(),
      dashboardHome: (context) => const DashboardHome(),
      recurringExpenses: (context) => const RecurringExpenses(),
      onboarding: (context) => const OnboardingFlow(),
      auth: (context) => const AuthScreen(),
      emailVerification: (context) => const EmailVerificationScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      resetPassword: (context) => const ResetPasswordScreen(),
      authGuardError: (context) => const AuthGuardErrorScreen(),
    };
  }
}
