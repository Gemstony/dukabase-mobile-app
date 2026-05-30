import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A full-screen barcode / QR code scanner.
///
/// Returns the raw scanned string value when a code is detected.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value == null || value.isEmpty) return;

    _hasScanned = true;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            tooltip: 'Toggle flash',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_outlined),
            tooltip: 'Flip camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Scanner overlay guide
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point at a QR code',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom info
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Scan a batch QR code to add it to the cart',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
