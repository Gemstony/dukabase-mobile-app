import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/models/shop_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shops/providers/shop_provider.dart';

class BackupScreen extends StatefulWidget {
  final ShopModel shop;
  const BackupScreen({super.key, required this.shop});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isExporting = false;
  String? _error;

  Future<void> _exportToJson() async {
    setState(() {
      _isExporting = true;
      _error = null;
    });
    final success = await _backupService.exportToJson(widget.shop.id);
    setState(() {
      _isExporting = false;
      if (!success) {
        _error = 'Export failed. Please check your connection.';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export successful! Sharing file...'), backgroundColor: Colors.green),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Backup - ${widget.shop.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Export Shop Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Create a complete backup of your shop data (products, sales, purchases, expenses, customers, suppliers, etc.) in JSON format. The file will be shared via your device\'s sharing options.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportToJson,
                      icon: _isExporting ? const CircularProgressIndicator() : const Icon(Icons.backup),
                      label: const Text('Export to JSON'),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Restore', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Restore from a previous backup is currently under development.'),
                    const SizedBox(height: 8),
                    const Text('Coming soon...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}