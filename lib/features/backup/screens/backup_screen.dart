import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/models/shop_model.dart';
import 'dart:io';

class BackupScreen extends StatefulWidget {
  final ShopModel shop;
  const BackupScreen({super.key, required this.shop});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isExporting = false;
  bool _isRestoring = false;
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

  Future<void> _restoreFromJson() async {
    setState(() {
      _isRestoring = true;
      _error = null;
    });
    try {
      // Pick JSON file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) {
        setState(() => _isRestoring = false);
        return; // user canceled
      }
      final file = File(result.files.single.path!);
      final restoreResult = await _backupService.restoreFromJson(widget.shop.id, file);
      if (restoreResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore completed successfully!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _error = restoreResult.error ?? 'Restore failed');
      }
    } catch (e) {
      setState(() => _error = 'Restore error: $e');
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Backup & Restore - ${widget.shop.name}')),
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
                    const Text('Create a complete backup of your shop data in JSON format. The file will be shared via your device\'s sharing options.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportToJson,
                      icon: _isExporting ? const CircularProgressIndicator() : const Icon(Icons.backup),
                      label: const Text('Export to JSON'),
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
                    const Text('Restore from Backup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Import a previously exported JSON backup file. This will replace ALL existing data in your shop.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isRestoring ? null : _restoreFromJson,
                      icon: _isRestoring ? const CircularProgressIndicator() : const Icon(Icons.restore),
                      label: const Text('Restore from JSON'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
          ],
        ),
      ),
    );
  }
}