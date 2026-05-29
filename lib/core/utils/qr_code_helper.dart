import 'package:printing/printing.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'currency_formatter.dart';

class QRCodeHelper {
  /// Generates the QR data string for a product batch.
  ///
  /// Format: "shopId|productId|batchCode"
  /// This can be extended later to be a JSON or URL based.
  static String encodeBatchData({
    required String shopId,
    required String productId,
    required String batchCode,
  }) {
    return '$shopId|$productId|$batchCode';
  }

  /// Decodes the QR data string back to components.
  static ({String shopId, String productId, String batchCode})? decodeBatchData(
    String data,
  ) {
    final parts = data.split('|');
    if (parts.length != 3) return null;
    return (shopId: parts[0], productId: parts[1], batchCode: parts[2]);
  }

  /// Generates a QrImageView widget for a given data string.
  static Widget generateQrWidget({required String data, double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF6C63FF),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  /// Captures the QR code as an image (PNG bytes) using QrPainter.
  static Future<Uint8List> captureQrToImage({
    required String data,
    double size = 400,
  }) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF6C63FF),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF1A1A2E),
      ),
    );

    final image = await painter.toImage(size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Prints a QR code label for a batch.
  static Future<void> printBatchQrLabel({
    required String productName,
    required String batchCode,
    required String sku,
    required double sellingPrice,
    required String currency,
    required String qrData,
  }) async {
    final qrImage = await captureQrToImage(data: qrData);

    await Printing.layoutPdf(
      onLayout: (format) async {
        return _generateLabelPdf(
          format: format,
          productName: productName,
          batchCode: batchCode,
          sku: sku,
          sellingPrice: sellingPrice,
          currency: currency,
          qrImage: qrImage,
        );
      },
    );
  }

  static Future<Uint8List> _generateLabelPdf({
    required pw_pdf.PdfPageFormat format,
    required String productName,
    required String batchCode,
    required String sku,
    required double sellingPrice,
    required String currency,
    required Uint8List qrImage,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  productName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('SKU: $sku', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Batch: $batchCode',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Price: ${CurrencyFormatter.format(sellingPrice, currency)}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 16),
                pw.Image(pw.MemoryImage(qrImage), width: 180, height: 180),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Scan to add to sale',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: pw_pdf.PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final saved = await doc.save();
    return Uint8List.fromList(saved);
  }
}
