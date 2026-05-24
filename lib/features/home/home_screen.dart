import 'package:dukabase/features/customers/screens/customer_list_screen.dart';
import 'package:dukabase/features/dashboard/screens/owner_dashboard_screen.dart';
import 'package:dukabase/features/dashboard/screens/staff_dashboard_screen.dart';
import 'package:dukabase/features/expenses/screens/expense_list_screen.dart';
import 'package:dukabase/features/payment_methods/screens/payment_method_list_screen.dart';
import 'package:dukabase/features/reports/screens/expense_report_screen.dart';
import 'package:dukabase/features/reports/screens/income_report_screen.dart';
import 'package:dukabase/features/reports/screens/product_report_screen.dart';
import 'package:dukabase/features/reports/screens/purchase_report_screen.dart';
import 'package:dukabase/features/reports/screens/sales_report_screen.dart';
import 'package:dukabase/features/sales/screens/new_sale_screen.dart';
import 'package:dukabase/features/stock_adjustments/screens/stock_adjustment_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shops/providers/shop_provider.dart';
import '../../core/models/shop_model.dart';
import '../../core/models/user_model.dart';
import '../auth/providers/auth_provider.dart';
import 'create_shop_screen.dart';
import 'shop_detail_screen.dart';
import '../products/screens/product_list_screen.dart'; // to be created
import '../suppliers/screens/supplier_list_screen.dart'; // to be created
import '../purchases/screens/purchase_screen.dart'; // to be created

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _shopsRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      if (!_shopsRequested && currentUser != null) {
        _shopsRequested = true;
        shopProvider.loadUserShops(currentUser.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('DukaBase')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    currentUser?.name ?? 'User',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (authProvider.currentUser?.role == UserRole.owner)
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Owner Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToOwnerDashboard(context, shopProvider.currentShop);
                },
              ),
            if (authProvider.currentUser?.role == UserRole.staff)
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Staff Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToStaffDashboard(context, shopProvider.currentShop);
                },
              ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('My Shops'),
              onTap: () {
                Navigator.pop(context); // close drawer
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Products'),
              onTap: () {
                Navigator.pop(context);
                _navigateToProducts(context, shopProvider.currentShop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Suppliers'),
              onTap: () {
                Navigator.pop(context);
                _navigateToSuppliers(context, shopProvider.currentShop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Purchases'),
              onTap: () {
                Navigator.pop(context);
                _navigateToPurchases(context, shopProvider.currentShop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sell),
              title: const Text('New Sale'),
              onTap: () {
                Navigator.pop(context);
                _navigateToNewSale(context, shopProvider.currentShop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Customers'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCustomers(context, shopProvider.currentShop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payment Methods'),
              onTap: () {
                Navigator.pop(context);
                _navigateToPaymentMethods(context, shopProvider.currentShop);
              },
            ),

            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Expenses'),
              onTap: () {
                Navigator.pop(context);
                _navigateToExpenses(context, shopProvider.currentShop);
              },
            ),

            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Stock Adjustments'),
              onTap: () {
                Navigator.pop(context);
                _navigateToStockAdjustments(context, shopProvider.currentShop);
              },
            ),

            // Reports section header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'REPORTS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Sales Report'),
              onTap: () {
                Navigator.pop(context);
                _navigateToSalesReport(context, shopProvider.currentShop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart),
              title: const Text('Purchases Report'),
              onTap: () {
                Navigator.pop(context);
                _navigateToPurchasesReport(context, shopProvider.currentShop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Expenses Report'),
              onTap: () {
                Navigator.pop(context);
                _navigateToExpensesReport(context, shopProvider.currentShop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Product Report'),
              onTap: () {
                Navigator.pop(context);
                _navigateToProductReport(context, shopProvider.currentShop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Income Report'),
              onTap: () {
                Navigator.pop(context);
                _navigateToIncomeReport(context, shopProvider.currentShop);
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
      body: shopProvider.isLoading && shopProvider.shops.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : shopProvider.shops.isEmpty
          ? _buildEmptyState(context)
          : _buildShopList(context, shopProvider.shops, currentUser!),
      floatingActionButton: (currentUser?.role == UserRole.owner)
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateShopScreen()),
                );
              },
            )
          : null,
    );
  }

  void _navigateToOwnerDashboard(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerDashboardScreen(shop: currentShop),
      ),
    );
  }

  void _navigateToStaffDashboard(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffDashboardScreen(shop: currentShop),
      ),
    );
  }

  void _navigateToProducts(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductListScreen(shop: currentShop)),
    );
  }

  void _navigateToSuppliers(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierListScreen(shop: currentShop)),
    );
  }

  void _navigateToPurchases(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PurchaseScreen(shop: currentShop)),
    );
  }

  void _navigateToNewSale(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewSaleScreen(shop: currentShop)),
    );
  }

  void _navigateToCustomers(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerListScreen(shop: currentShop)),
    );
  }

  void _navigateToPaymentMethods(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodListScreen(shop: currentShop),
      ),
    );
  }

  void _navigateToExpenses(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseListScreen(shop: currentShop)),
    );
  }

  void _navigateToStockAdjustments(
    BuildContext context,
    ShopModel? currentShop,
  ) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockAdjustmentListScreen(shop: currentShop),
      ),
    );
  }

void _navigateToSalesReport(BuildContext context, ShopModel? currentShop) {
  if (currentShop == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a shop first')),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SalesReportScreen(shop: currentShop)),
  );
}

void _navigateToPurchasesReport(BuildContext context, ShopModel? currentShop) {
  if (currentShop == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a shop first')),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PurchaseReportScreen(shop: currentShop)),
  );
}

void _navigateToExpensesReport(BuildContext context, ShopModel? currentShop) {
  if (currentShop == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a shop first')),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ExpenseReportScreen(shop: currentShop)),
  );
}

void _navigateToProductReport(BuildContext context, ShopModel? currentShop) {
  if (currentShop == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a shop first')),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProductReportScreen(shop: currentShop)),
  );
}

void _navigateToIncomeReport(BuildContext context, ShopModel? currentShop) {
  if (currentShop == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a shop first')),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => IncomeReportScreen(shop: currentShop)),
  );
}

  Widget _buildEmptyState(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            currentUser?.role == UserRole.owner
                ? 'You haven\'t created any shop yet'
                : 'No shops assigned yet',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (currentUser?.role == UserRole.owner)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateShopScreen()),
                );
              },
              child: const Text('Create Your First Shop'),
            ),
        ],
      ),
    );
  }

  Widget _buildShopList(
    BuildContext context,
    List<ShopModel> shops,
    UserModel currentUser,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.store, size: 40),
            title: Text(
              shop.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(shop.address ?? 'No address'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Provider.of<ShopProvider>(
                context,
                listen: false,
              ).setCurrentShop(shop);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
              );
            },
          ),
        );
      },
    );
  }
}
