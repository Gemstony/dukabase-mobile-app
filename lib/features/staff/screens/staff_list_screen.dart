import 'package:flutter/material.dart';
import '../../../core/models/shop_model.dart';

class StaffListScreen extends StatelessWidget {
  final ShopModel shop;
  const StaffListScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Staff - ${shop.name}')),
      body: Center(
        child: Text('Staff management coming soon...'),
      ),
    );
  }
}