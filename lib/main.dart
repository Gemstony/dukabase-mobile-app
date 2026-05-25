import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/shops/providers/shop_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/home_screen.dart';
import 'admin/admin_home.dart';
import 'features/products/providers/product_provider.dart';
import 'features/suppliers/providers/supplier_provider.dart';
import 'features/purchases/providers/purchase_provider.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/sales/providers/sale_provider.dart';
import 'features/payments/providers/payment_provider.dart';
import 'features/payment_methods/providers/payment_method_provider.dart';
import 'features/expenses/providers/expense_provider.dart';
import 'features/stock_adjustments/providers/stock_adjustment_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';

import 'features/reports/providers/sales_report_provider.dart';
import 'features/reports/providers/purchase_report_provider.dart';
import 'features/reports/providers/product_report_provider.dart';
import 'features/reports/providers/income_report_provider.dart';
import 'features/reports/providers/expense_report_provider.dart';

import 'features/staff/providers/staff_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const DukaBaseApp());
}

class DukaBaseApp extends StatelessWidget {
  const DukaBaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => PaymentMethodProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => StockAdjustmentProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),

        ChangeNotifierProvider(create: (_) => SalesReportProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseReportProvider()),
        ChangeNotifierProvider(create: (_) => ProductReportProvider()),
        ChangeNotifierProvider(create: (_) => IncomeReportProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseReportProvider()),

        ChangeNotifierProvider(create: (_) => StaffProvider()),
      ],
      child: MaterialApp(
        title: 'DukaBase',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.grey[50],
          primaryColor: Colors.deepPurple,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/admin': (context) => const AdminHome(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!authProvider.isLoggedIn) {
      return const LoginScreen();
    }
    // Logged in – go to home (mobile) or admin (web) later
    return const HomeScreen();
  }
}
