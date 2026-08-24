import 'package:flutter/material.dart';

import '../inventory_screen/inventory_screen.dart';
import '../inventory_screen/services/inventory_service.dart';
import 'models/invoice.dart';
import 'services/invoice_service.dart';

class InvoiceOcrResultScreen extends StatefulWidget {
  final String text;
  final String? imagePath;

  const InvoiceOcrResultScreen({
    super.key,
    required this.text,
    required this.imagePath,
  });

  @override
  State<InvoiceOcrResultScreen> createState() => _InvoiceOcrResultScreenState();
}

class _InvoiceOcrResultScreenState extends State<InvoiceOcrResultScreen> {
  late final String _text = widget.text;
  Invoice? _invoice;
  String? _error;
  bool _isAnalyzing = true;
  bool _isAdding = false;
  bool _wasAdded = false;

  @override
  void initState() {
    super.initState();
    _analyzeInvoice();
  }

  Future<void> _analyzeInvoice() async {
    final imagePath = widget.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      setState(() {
        _isAnalyzing = false;
        _error = 'The invoice photo is unavailable. Please scan it again.';
      });
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    try {
      final invoice = await InvoiceService().analyzeImage(imagePath);
      if (!mounted) return;
      setState(() => _invoice = invoice);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _addToInventory() async {
    final invoice = _invoice;
    if (invoice == null || _isAdding) return;
    setState(() => _isAdding = true);
    try {
      await InventoryService().addInvoiceItems(invoice);
      if (!mounted) return;
      setState(() => _wasAdded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${invoice.items.length} items added to inventory.'),
        ),
      );
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const InventoryScreen()));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  String _money(double? value) {
    return value == null ? '—' : '₹${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F5EE),
        foregroundColor: const Color(0xFF2C2926),
        elevation: 0,
        title: const Text('Invoice details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'Extracted text',
            style: TextStyle(
              color: Color(0xFF2C2926),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ML Kit read the text below. Gemini is analyzing the invoice photo for structured items.',
            style: TextStyle(color: Color(0xFF6C625C), fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE3D9D0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _text.isEmpty ? 'No text detected.' : _text,
              style: const TextStyle(
                color: Color(0xFF2C2926),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isAnalyzing ? 'Gemini is analyzing' : 'Invoice items',
            style: const TextStyle(
              color: Color(0xFF2C2926),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (_isAnalyzing)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Expanded(child: Text('Reading products and totals…')),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Card(
              color: const Color(0xFFFFF2E8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_error!, style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _analyzeInvoice,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          else if (_invoice != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _invoice!.supplier.name ?? 'Supplier not detected',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (_invoice!.invoiceNumber != null)
                          'Invoice ${_invoice!.invoiceNumber}',
                        if (_invoice!.date != null) _invoice!.date!,
                      ].join(' • '),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand total'),
                        Text(
                          _money(_invoice!.grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ..._invoice!.items.map(
              (item) => Card(
                margin: const EdgeInsets.only(top: 10),
                child: ListTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${item.quantity ?? 1} ${item.unit ?? 'unit'} × ${_money(item.unitPrice)}',
                  ),
                  trailing: Text(
                    _money(item.total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _isAdding || _wasAdded ? null : _addToInventory,
              icon: _isAdding
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _wasAdded
                          ? Icons.check_circle_outline
                          : Icons.inventory_2_outlined,
                    ),
              label: Text(
                _isAdding
                    ? 'Adding items…'
                    : _wasAdded
                    ? 'Items added'
                    : 'Add items to inventory',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB8490C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Scan another invoice'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB8490C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
