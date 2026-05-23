import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shops/providers/shop_provider.dart';
import '../../core/models/shop_model.dart';
import '../../core/models/user_model.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/models/shop_model.dart';
import 'create_shop_screen.dart';
import 'shop_detail_screen.dart';
import '../products/screens/product_list_screen.dart';     // to be created
import '../suppliers/screens/supplier_list_screen.dart';   // to be created
import '../purchases/screens/purchase_screen.dart';        // to be created

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    // Force a refresh of shops (the stream will also update, but this is safe)
    if (currentUser != null) {
      shopProvider.loadUserShops(authProvider.currentUser!.id);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('DukaBase'),
      ),
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

  void _navigateToProducts(BuildContext context, ShopModel? currentShop) {
    if (currentShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(shop: currentShop),
      ),
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
      MaterialPageRoute(
        builder: (_) => SupplierListScreen(shop: currentShop),
      ),
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
      MaterialPageRoute(
        builder: (_) => PurchaseScreen(shop: currentShop),
      ),
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

  Widget _buildShopList(BuildContext context, List<ShopModel> shops, UserModel currentUser) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.store, size: 40),
            title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(shop.address ?? 'No address'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Provider.of<ShopProvider>(context, listen: false).setCurrentShop(shop);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopDetailScreen(shop: shop),
                ),
              );
            },
          ),
        );
      },
    );
  }
}