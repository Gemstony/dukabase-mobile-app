import 'package:flutter/material.dart';
import '../../core/models/shop_model.dart';

class ShopDetailScreen extends StatelessWidget {
  final ShopModel shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shop.name)),
      body: Center(
        child: Text('Shop dashboard – coming in Phase 2'),
      ),
    );
  }
}