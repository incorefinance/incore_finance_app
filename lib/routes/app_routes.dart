import 'package:flutter/material.dart';
import '../presentation/settings/settings.dart';
import '../presentation/analytics_dashboard/analytics_dashboard.dart';
import '../presentation/transactions_list/transactions_list.dart';
import '../presentation/add_transaction/add_transaction.dart';
import '../presentation/dashboard_home/dashboard_home.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String settings = '/settings';
  static const String analyticsDashboard = '/analytics-dashboard';
  static const String transactionsList = '/transactions-list';
  static const String addTransaction = '/add-transaction';
  static const String dashboardHome = '/dashboard-home';

  static Map<String, WidgetBuilder> get routes {
    return {
      initial: (context) => const DashboardHome(),
      settings: (context) => const Settings(),
      analyticsDashboard: (context) => const AnalyticsDashboard(),
      transactionsList: (context) => const TransactionsList(),
      addTransaction: (context) => const AddTransaction(),
      dashboardHome: (context) => const DashboardHome(),
      // TODO: Add your other routes here
    };
  }
}
