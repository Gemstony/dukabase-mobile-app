import 'package:printing/printing.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'currency_formatter.dart';
import '../models/product_model.dart';
import '../models/batch_model.dart';

/// Standard QR code image resolution for printing — high enough for clear scanning.
const double _qrPrintImageSize = 500;

/// Display size of the QR code on a single-label PDF page.
const double _qrPdfDisplaySize = 180;

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
  /// Uses a high resolution ([_qrPrintImageSize]) to ensure clear printing at any scale.
  static Future<Uint8List> captureQrToImage({
    required String data,
    double size = _qrPrintImageSize,
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
    final qrImage = await captureQrToImage(
      data: qrData,
      size: _qrPrintImageSize,
    );

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
                pw.Image(
                  pw.MemoryImage(qrImage),
                  width: _qrPdfDisplaySize,
                  height: _qrPdfDisplaySize,
                ),
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

  // ─────────────────────────────────────────────────────────────
  // BULK PRINT — all products & their batches in a grid layout
  // ─────────────────────────────────────────────────────────────

  /// Prints a multi-page PDF with QR codes for all products and their batches.
  ///
  /// Each batch gets its own label card with product name, batch code, SKU,
  /// selling price, and a QR code large enough to be scanned by any phone.
  /// Cards are arranged in a 3×4 grid (12 per page).
  static Future<void> printAllBatchQrCodes({
    required String shopId,
    required String currency,
    required List<({ProductModel product, List<BatchModel> batches})>
    productBatches,
  }) async {
    // Pre-capture all QR images in parallel for performance
    final List<
      ({
        Uint8List image,
        String productName,
        String batchCode,
        String sku,
        double sellingPrice,
      })
    >
    labelData = [];

    for (final entry in productBatches) {
      for (final batch in entry.batches) {
        if (batch.quantity <= 0) continue; // skip empty batches
        final qrData = encodeBatchData(
          shopId: shopId,
          productId: entry.product.id,
          batchCode: batch.batchCode,
        );
        final image = await captureQrToImage(data: qrData);
        labelData.add((
          image: image,
          productName: entry.product.name,
          batchCode: batch.batchCode,
          sku: entry.product.sku,
          sellingPrice: batch.sellingPrice,
        ));
      }
    }

    if (labelData.isEmpty) return;

    await Printing.layoutPdf(
      onLayout: (format) async {
        return _generateBulkLabelPdf(
          format: format,
          labelData: labelData,
          currency: currency,
        );
      },
    );
  }

  /// Generates a multi-page PDF with label cards arranged in a tight grid.
  /// Each card shows: product name, batch code + SKU, price, and a scan‑ready QR code.
  static Future<Uint8List> _generateBulkLabelPdf({
    required pw_pdf.PdfPageFormat format,
    required List<
      ({
        Uint8List image,
        String productName,
        String batchCode,
        String sku,
        double sellingPrice,
      })
    >
    labelData,
    required String currency,
  }) async {
    const int columns = 3;
    const int rowsPerPage = 4;
    const int labelsPerPage = columns * rowsPerPage; // 12 per page

    const double margin = 24;
    const double cardGap = 10;

    final double pageWidth = format.width - (margin * 2);
    final double pageHeight = format.height - (margin * 2);

    final double cardWidth = (pageWidth - (cardGap * (columns - 1))) / columns;
    final double cardHeight =
        (pageHeight - (cardGap * (rowsPerPage - 1))) / rowsPerPage;

    // QR size inside each card — large enough for easy phone scanning
    final double qrSize =
        ((cardWidth < cardHeight ? cardWidth : cardHeight) * 0.50).clamp(
          110,
          200,
        );

    final doc = pw.Document();

    for (
      int pageIndex = 0;
      pageIndex * labelsPerPage < labelData.length;
      pageIndex++
    ) {
      final pageLabels = labelData
          .skip(pageIndex * labelsPerPage)
          .take(labelsPerPage)
          .toList();

      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.all(margin),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Page header
                pw.Center(
                  child: pw.Text(
                    'Product Batch QR Codes',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: pw_pdf.PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                // Grid rows
                ...List.generate(rowsPerPage, (rowIndex) {
                  final rowStart = rowIndex * columns;
                  if (rowStart >= pageLabels.length) {
                    return pw.SizedBox.shrink();
                  }
                  final rowLabels = pageLabels
                      .skip(rowStart)
                      .take(columns)
                      .toList();

                  return pw.Padding(
                    padding: pw.EdgeInsets.only(
                      bottom: rowIndex < rowsPerPage - 1 ? cardGap : 0,
                    ),
                    child: pw.SizedBox(
                      height: cardHeight,
                      child: pw.Row(
                        children: List.generate(columns, (colIndex) {
                          if (colIndex >= rowLabels.length) {
                            return pw.SizedBox.shrink();
                          }
                          final label = rowLabels[colIndex];
                          return pw.Padding(
                            padding: pw.EdgeInsets.only(
                              right: colIndex < columns - 1 ? cardGap : 0,
                            ),
                            child: pw.Container(
                              width: cardWidth,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                  color: pw_pdf.PdfColors.grey400,
                                  width: 0.5,
                                ),
                                borderRadius: pw.BorderRadius.all(
                                  pw.Radius.circular(4),
                                ),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  // Product name
                                  pw.Text(
                                    label.productName,
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                    maxLines: 1,
                                    overflow: pw.TextOverflow.clip,
                                  ),
                                  pw.SizedBox(height: 2),
                                  // Batch code & SKU
                                  pw.Text(
                                    '${label.batchCode}  |  ${label.sku}',
                                    style: const pw.TextStyle(fontSize: 6),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.SizedBox(height: 2),
                                  // Price
                                  pw.Text(
                                    CurrencyFormatter.format(
                                      label.sellingPrice,
                                      currency,
                                    ),
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: pw.FontWeight.bold,
                                      color: pw_pdf.PdfColors.blue700,
                                    ),
                                  ),
                                  pw.SizedBox(height: 4),
                                  // QR Code — large enough for scanning
                                  pw.Image(
                                    pw.MemoryImage(label.image),
                                    width: qrSize,
                                    height: qrSize,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );
    }

    final saved = await doc.save();
    return Uint8List.fromList(saved);
  }
}
