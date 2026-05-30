import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dukabase/core/widgets/transaction_form_ui.dart';
import 'package:dukabase/features/purchases/screens/purchase_screen.dart';
import '../../../core/models/product_model.dart';

class AddPurchaseFromScanScreen extends StatefulWidget {
  final ProductModel product;
  final String scannedBatchCode;
  final double? existingSellingPrice;

  const AddPurchaseFromScanScreen({
    super.key,
    required this.product,
    required this.scannedBatchCode,
    this.existingSellingPrice,
  });

  @override
  State<AddPurchaseFromScanScreen> createState() => _AddPurchaseFromScanScreenState();
}

class _AddPurchaseFromScanScreenState extends State<AddPurchaseFromScanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingSellingPrice != null) {
      _sellingPriceController.text = widget.existingSellingPrice!.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.parse(_quantityController.text);
    final costPrice = double.parse(_costPriceController.text);
    final sellingPrice = double.parse(_sellingPriceController.text);

    Navigator.pop(
      context,
      PurchaseItem(
        productId: widget.product.id,
        productName: widget.product.name,
        batchCode: widget.scannedBatchCode,
        quantity: quantity,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        expiryDate: _expiryDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Scanned Item'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product info card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.qr_code, size: 16, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Text(
                              'Batch: ${widget.scannedBatchCode}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Quantity
                TextFormField(
                  controller: _quantityController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Quantity *',
                    prefixIcon: Icons.numbers_outlined,
                    hint: 'Enter stock quantity',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final qty = double.tryParse(v);
                    if (qty == null || qty <= 0) return 'Invalid quantity';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cost price & Selling price row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        decoration: TransactionFormUi.fieldDecoration(
                          context,
                          label: 'Cost Price *',
                          prefixIcon: Icons.arrow_downward,
                          hint: 'Purchase price',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        decoration: TransactionFormUi.fieldDecoration(
                          context,
                          label: 'Sell Price *',
                          prefixIcon: Icons.arrow_upward,
                          hint: 'Selling price',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Expiry date picker
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setState(() => _expiryDate = date);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, color: Colors.deepPurple[300]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _expiryDate == null
                                ? 'Tap to set expiry date (optional)'
                                : 'Expiry: ${DateFormat('MMM dd, yyyy').format(_expiryDate!)}',
                            style: TextStyle(
                              color: _expiryDate == null ? Colors.grey[600] : Colors.deepPurple,
                              fontWeight: _expiryDate != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit button
                TransactionFormUi.primaryButton(
                  onPressed: _submit,
                  label: 'Add to Purchase',
                  icon: Icons.add_shopping_cart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}