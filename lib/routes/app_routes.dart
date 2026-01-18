import 'package:flutter/material.dart';
import '../presentation/main_dashboard/main_dashboard.dart';
import '../presentation/product_management/product_management.dart';
import '../presentation/kitchen_board/kitchen_board.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/sales_screen/sales_screen.dart';
import '../presentation/customer_management/customer_management.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/reports_dashboard/reports_dashboard.dart';
import '../presentation/cash_register/cash_register.dart';
import '../presentation/inventory_management/inventory_management.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String mainDashboard = '/main-dashboard';
  static const String productManagement = '/product-management';
  static const String kitchenBoard = '/kitchen-board';
  static const String splash = '/splash-screen';
  static const String settings = '/settings-screen';
  static const String sales = '/sales-screen';
  static const String customerManagement = '/customer-management';
  static const String login = '/login-screen';
  static const String reportsDashboard = '/reports-dashboard';
  static const String cashRegister = '/cash-register';
  static const String inventoryManagement = '/inventory-management';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    mainDashboard: (context) => const MainDashboard(),
    productManagement: (context) => const ProductManagement(),
    kitchenBoard: (context) => const KitchenBoard(),
    splash: (context) => const SplashScreen(),
    settings: (context) => const SettingsScreen(),
    sales: (context) => const SalesScreen(),
    customerManagement: (context) => const CustomerManagement(),
    login: (context) => const LoginScreen(),
    reportsDashboard: (context) => const ReportsDashboard(),
    cashRegister: (context) => const CashRegister(),
    inventoryManagement: (context) => const InventoryManagement(),
    // TODO: Add your other routes here
  };
}
