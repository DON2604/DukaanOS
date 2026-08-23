import 'package:flutter/material.dart';

import 'models/invoice_parse_result.dart';
import 'services/invoice_ai_parser.dart';
import 'widgets/conversion_result_card.dart';

class InvoiceOcrResultScreen extends StatefulWidget {
  final String text;

  const InvoiceOcrResultScreen({super.key, required this.text});

  @override
  State<InvoiceOcrResultScreen> createState() => _InvoiceOcrResultScreenState();
}

class _InvoiceOcrResultScreenState extends State<InvoiceOcrResultScreen> {
  late final String _text = widget.text;
  InvoiceParseResult? _result;
  bool _isConverting = true;

  @override
  void initState() {
    super.initState();
    _convertToInvoiceJson();
  }

  Future<void> _convertToInvoiceJson() async {
    final result = await InvoiceAiParser.instance.parse(widget.text);
    if (!mounted) return;
    setState(() {
      _result = result;
      _isConverting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

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
            'SmolLM is checking whether this text is an invoice and converting it to JSON.',
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
            _isConverting
                ? 'Converting to JSON'
                : result!.isInvoice
                ? 'Invoice JSON'
                : 'Not an invoice',
            style: const TextStyle(
              color: Color(0xFF2C2926),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ConversionResultCard(result: result, isConverting: _isConverting),
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
