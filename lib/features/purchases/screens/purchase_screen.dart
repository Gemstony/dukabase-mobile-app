import 'package:dukabase/core/utils/currency_formatter.dart';
import 'package:dukabase/core/widgets/transaction_form_ui.dart';
import 'package:dukabase/features/payment_methods/providers/payment_method_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_provider.dart';
import '../../suppliers/providers/supplier_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/supplier_model.dart';
import '../../../core/models/product_model.dart';
import 'purchases_list_screen.dart';

class PurchaseScreen extends StatefulWidget {
  final ShopModel shop;
  const PurchaseScreen({super.key, required this.shop});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPaymentMethodId;
  SupplierModel? _selectedSupplier;
  double _paidAmount = 0;

  final List<PurchaseItem> _items = [];
  final TextEditingController _paidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load suppliers and products
    Provider.of<SupplierProvider>(
      context,
      listen: false,
    ).loadSuppliers(widget.shop.id);
    Provider.of<ProductProvider>(
      context,
      listen: false,
    ).loadProducts(widget.shop.id);

    Provider.of<PaymentMethodProvider>(
      context,
      listen: false,
    ).loadPaymentMethods(widget.shop.id);
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _addItem() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    if (productProvider.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products available. Create a product first.'),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddPurchaseItemScreen(products: productProvider.products),
      ),
    );
    if (result != null && result is PurchaseItem) {
      setState(() {
        _items.add(result);
      });
    }
  }

  Future<void> _savePurchase() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final purchaseProvider = Provider.of<PurchaseProvider>(
      context,
      listen: false,
    );
    final result = await purchaseProvider.recordPurchase(
      shopId: widget.shop.id,
      supplierId: _selectedSupplier!.id,
      supplierName: _selectedSupplier!.name,
      totalAmount: _totalAmount,
      paidAmount: _paidAmount,
      paymentMethodId: _selectedPaymentMethodId!,
      items: _items
          .map(
            (item) => (
              productId: item.productId,
              productName: item.productName,
              batchCode: item.batchCode,
              quantity: item.quantity,
              costPrice: item.costPrice,
              sellingPrice: item.sellingPrice,
              expiryDate: item.expiryDate,
            ),
          )
          .toList(),
    );

    if (!mounted) return;

    if (result.success) {
      final message = result.pendingSync
          ? 'Purchase saved offline — will sync when you\'re back online'
          : 'Purchase recorded successfully';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PurchasesListScreen(
            shop: widget.shop,
            successMessage: message,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseProvider.error ?? 'Failed'),
          backgroundColor: Colors.red,
        ),
      );
      purchaseProvider.clearError();
    }
  }

  String _formatAmount(double amount) =>
      CurrencyFormatter.format(amount, widget.shop.currency);

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final paymentProvider = Provider.of<PaymentMethodProvider>(context);
    final balance = _totalAmount - _paidAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase'),
        actions: [
          if (_items.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_items.length} item${_items.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  TransactionFormUi.sectionHeader(
                    icon: Icons.local_shipping_outlined,
                    title: 'Supplier & payment',
                    subtitle: 'Who you bought from and how you paid',
                  ),
                  TransactionFormUi.formCard(
                    children: [
                      DropdownButtonFormField<SupplierModel>(
                        decoration: TransactionFormUi.fieldDecoration(
                          context,
                          label: 'Supplier *',
                          prefixIcon: Icons.store_outlined,
                        ),
                        items: supplierProvider.suppliers.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s.name));
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedSupplier = value),
                        validator: (v) => v == null ? 'Select supplier' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        decoration: TransactionFormUi.fieldDecoration(
                          context,
                          label: 'Payment Method *',
                          prefixIcon: Icons.account_balance_wallet_outlined,
                        ),
                        initialValue: _selectedPaymentMethodId,
                        items: paymentProvider.methods.map((method) {
                          return DropdownMenuItem(
                            value: method.id,
                            child: Text(
                              '${method.name} · ${_formatAmount(method.currentBalance)}',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPaymentMethodId = val),
                        validator: (v) =>
                            v == null ? 'Select payment method' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TransactionFormUi.sectionHeader(
                    icon: Icons.shopping_basket_outlined,
                    title: 'Purchase items',
                    subtitle: productProvider.products.isEmpty
                        ? 'Add products to your shop first'
                        : 'Tap Add Item below to include stock',
                  ),
                  if (_items.isEmpty)
                    TransactionFormUi.emptyItemsState(
                      message: 'No items yet.\nTap "Add Item" to add products to this purchase.',
                      icon: Icons.add_shopping_cart_outlined,
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return TransactionFormUi.lineItemCard(
                        title: item.productName,
                        trailingAmount: _formatAmount(item.subtotal),
                        chips: [
                          'Batch ${item.batchCode}',
                          'Qty ${item.quantity}',
                          'Cost ${_formatAmount(item.costPrice)}',
                          'Sell ${_formatAmount(item.sellingPrice)}',
                        ],
                        onRemove: () => setState(() => _items.removeAt(idx)),
                      );
                    }),
                  const SizedBox(height: 20),
                  TransactionFormUi.sectionHeader(
                    icon: Icons.payments_outlined,
                    title: 'Payment details',
                  ),
                  TransactionFormUi.paymentSummaryCard(
                    totalLabel: 'Total amount',
                    totalValue: _formatAmount(_totalAmount),
                    secondaryLabel: balance > 0 ? 'Outstanding balance' : 'Fully paid',
                    secondaryValue: _formatAmount(balance.abs()),
                    secondaryColor: balance > 0
                        ? Colors.orange.shade200
                        : Colors.greenAccent.shade100,
                  ),
                  const SizedBox(height: 14),
                  TransactionFormUi.formCard(
                    children: [
                      TextFormField(
                        controller: _paidController,
                        decoration: TransactionFormUi.fieldDecoration(
                          context,
                          label: 'Amount Paid *',
                          prefixIcon: Icons.paid_outlined,
                          hint: 'Enter amount paid now',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          _paidAmount = double.tryParse(value) ?? 0;
                          setState(() {});
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TransactionFormUi.bottomActionBar(
              secondaryButton: TransactionFormUi.secondaryButton(
                onPressed: _addItem,
                label: 'Add Item',
                icon: Icons.add,
              ),
              primaryButton: TransactionFormUi.primaryButton(
                onPressed: _savePurchase,
                label: 'Save Purchase',
                icon: Icons.save_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to hold temporary purchase item data
class PurchaseItem {
  final String productId;
  final String productName;
  final String batchCode;
  final double quantity;
  final double costPrice;
  final double sellingPrice;
  final DateTime? expiryDate;
  double get subtotal => quantity * costPrice;

  PurchaseItem({
    required this.productId,
    required this.productName,
    required this.batchCode,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    this.expiryDate,
  });
}

// Screen to add a single purchase item (batch)
class AddPurchaseItemScreen extends StatefulWidget {
  final List<ProductModel> products;
  const AddPurchaseItemScreen({super.key, required this.products});

  @override
  State<AddPurchaseItemScreen> createState() => _AddPurchaseItemScreenState();
}

class _AddPurchaseItemScreenState extends State<AddPurchaseItemScreen> {
  ProductModel? _selectedProduct;
  final _batchCodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  DateTime? _expiryDate;

  @override
  void dispose() {
    _batchCodeController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_selectedProduct == null) return;
    final quantity = double.tryParse(_quantityController.text);
    final costPrice = double.tryParse(_costPriceController.text);
    final sellingPrice = double.tryParse(_sellingPriceController.text);
    if (quantity == null || costPrice == null || sellingPrice == null) return;
    if (_batchCodeController.text.isEmpty) return;

    Navigator.pop(
      context,
      PurchaseItem(
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        batchCode: _batchCodeController.text,
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
      appBar: AppBar(title: const Text('Add Item')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransactionFormUi.sectionHeader(
                icon: Icons.inventory_2_outlined,
                title: 'Product details',
                subtitle: 'Select product and batch information',
              ),
              TransactionFormUi.formCard(
                children: [
                  DropdownButtonFormField<ProductModel>(
                    decoration: TransactionFormUi.fieldDecoration(
                      context,
                      label: 'Product *',
                      prefixIcon: Icons.category_outlined,
                    ),
                    items: widget.products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedProduct = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _batchCodeController,
                    decoration: TransactionFormUi.fieldDecoration(
                      context,
                      label: 'Batch Code *',
                      prefixIcon: Icons.qr_code_2_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TransactionFormUi.sectionHeader(
                icon: Icons.calculate_outlined,
                title: 'Quantity & pricing',
              ),
              TransactionFormUi.formCard(
                children: [
                  TextFormField(
                    controller: _quantityController,
                    decoration: TransactionFormUi.fieldDecoration(
                      context,
                      label: 'Quantity *',
                      prefixIcon: Icons.numbers_outlined,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          decoration: TransactionFormUi.fieldDecoration(
                            context,
                            label: 'Cost Price *',
                            prefixIcon: Icons.arrow_downward,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TransactionFormUi.sectionHeader(
                icon: Icons.event_outlined,
                title: 'Expiry (optional)',
              ),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(
                      const Duration(days: 365 * 5),
                    ),
                  );
                  if (date != null) {
                    setState(() => _expiryDate = date);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: TransactionFormUi.formCard(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.deepPurple.shade300,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Expiry date',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _expiryDate == null
                                    ? 'Tap to set expiry date'
                                    : _expiryDate!
                                          .toLocal()
                                          .toString()
                                          .split(' ')
                                          .first,
                                style: TextStyle(
                                  color: _expiryDate == null
                                      ? Colors.grey.shade600
                                      : Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TransactionFormUi.primaryButton(
                onPressed: _save,
                label: 'Add to Purchase',
                icon: Icons.add_shopping_cart,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
