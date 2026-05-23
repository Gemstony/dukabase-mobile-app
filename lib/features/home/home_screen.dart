import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shops/providers/shop_provider.dart';
import '../../core/models/shop_model.dart';
import '../../core/models/user_model.dart';
import '../auth/providers/auth_provider.dart';
import 'create_shop_screen.dart';
import 'shop_detail_screen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
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
              // Set current shop and navigate to shop detail
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
