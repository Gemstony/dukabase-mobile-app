import 'package:dukabase/features/backup/screens/backup_screen.dart';
import 'package:dukabase/features/customers/screens/customer_list_screen.dart';
import 'package:dukabase/features/dashboard/screens/owner_dashboard_screen.dart';
import 'package:dukabase/features/dashboard/screens/staff_dashboard_screen.dart';
import 'package:dukabase/features/expenses/screens/expense_list_screen.dart';
import 'package:dukabase/features/invitations/screens/invitations_screen.dart';
import 'package:dukabase/features/invitations/screens/owner_invitations_screen.dart';
import 'package:dukabase/features/payment_methods/screens/payment_method_list_screen.dart';
import 'package:dukabase/features/profile/screens/profile_screen.dart';
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
import '../products/screens/product_list_screen.dart';
import '../suppliers/screens/supplier_list_screen.dart';
import '../purchases/screens/purchase_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _shopsRequested = false;
  bool _hasCheckedAutoRedirect = false;

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

    // Auto-redirect logic
    if (!_hasCheckedAutoRedirect &&
        shopProvider.currentShop != null &&
        currentUser != null) {
      _hasCheckedAutoRedirect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentUser.role == UserRole.owner) {
          _navigateToOwnerDashboard(context, shopProvider.currentShop);
        } else if (currentUser.role == UserRole.staff) {
          _navigateToStaffDashboard(context, shopProvider.currentShop);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DukaBase',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      currentUser?.name.isNotEmpty == true
                          ? currentUser!.name[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentUser?.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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

            if (authProvider.currentUser?.role == UserRole.owner)
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
            if (authProvider.currentUser?.role == UserRole.owner)
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('Sales Report'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToSalesReport(context, shopProvider.currentShop);
                },
              ),
            if (authProvider.currentUser?.role == UserRole.owner)
              ListTile(
                leading: const Icon(Icons.add_shopping_cart),
                title: const Text('Purchases Report'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPurchasesReport(context, shopProvider.currentShop);
                },
              ),
            if (authProvider.currentUser?.role == UserRole.owner)
              ListTile(
                leading: const Icon(Icons.receipt),
                title: const Text('Expenses Report'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToExpensesReport(context, shopProvider.currentShop);
                },
              ),
            if (authProvider.currentUser?.role == UserRole.owner)
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Product Report'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToProductReport(context, shopProvider.currentShop);
                },
              ),
            if (authProvider.currentUser?.role == UserRole.owner)
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Income Report'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToIncomeReport(context, shopProvider.currentShop);
                },
              ),

            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Invitations'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InvitationsScreen()),
                );
              },
            ),

            if (authProvider.currentUser?.role == UserRole.owner &&
                shopProvider.currentShop != null)
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Manage Invitations'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerInvitationsScreen(
                        shop: shopProvider.currentShop!,
                      ),
                    ),
                  );
                },
              ),
            if (authProvider.currentUser?.role == UserRole.owner)
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup & Restore'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToBackup(context, shopProvider.currentShop);
                },
              ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _showLogoutConfirmation(context, authProvider),
            ),
          ],
        ),
      ),
      body: shopProvider.isLoading && shopProvider.shops.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : shopProvider.shops.isEmpty
          ? _buildEmptyState(context)
          : Container(
              color: Colors.grey[50],
              child: _buildShopList(context, shopProvider.shops, currentUser!),
            ),
      floatingActionButton: (currentUser?.role == UserRole.owner)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('New Shop'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
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

  void _showLogoutConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // close drawer
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
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

  void _navigateToPurchasesReport(
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
        builder: (_) => PurchaseReportScreen(shop: currentShop),
      ),
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

  void _navigateToBackup(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BackupScreen(shop: currentShop)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              currentUser?.role == UserRole.owner
                  ? 'No Shops Created Yet'
                  : 'No Shops Assigned',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              currentUser?.role == UserRole.owner
                  ? 'Create your first shop to start managing your business.'
                  : 'You have not been assigned to any shop yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            if (currentUser?.role == UserRole.owner)
              ElevatedButton.icon(
                icon: const Icon(Icons.add_business),
                label: const Text('Create Your First Shop'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateShopScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopList(
    BuildContext context,
    List<ShopModel> shops,
    UserModel currentUser,
  ) {
    final currentShop = Provider.of<ShopProvider>(context).currentShop;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shops.length + 1, // +1 for the Active Shop header/card
      itemBuilder: (context, index) {
        if (index == 0) {
          // Active Shop Card
          if (currentShop != null) {
            return _buildActiveShopCard(context, currentShop, currentUser);
          } else {
            return const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Available Shops',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            );
          }
        }

        final shop = shops[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                Provider.of<ShopProvider>(
                  context,
                  listen: false,
                ).setCurrentShop(shop);
                final message = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopDetailScreen(shop: shop),
                  ),
                );
                if (!context.mounted || message == null) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.storefront,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shop.address ?? 'No address provided',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveShopCard(
    BuildContext context,
    ShopModel shop,
    UserModel currentUser,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (currentUser.role == UserRole.owner) {
              _navigateToOwnerDashboard(context, shop);
            } else if (currentUser.role == UserRole.staff) {
              _navigateToStaffDashboard(context, shop);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Shop',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
