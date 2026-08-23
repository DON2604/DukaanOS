import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/invoice_parse_result.dart';

class ConversionResultCard extends StatelessWidget {
  final InvoiceParseResult? result;
  final bool isConverting;

  const ConversionResultCard({
    super.key,
    required this.result,
    required this.isConverting,
  });

  @override
  Widget build(BuildContext context) {
    if (isConverting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('SmolLM is converting the extracted text to JSON...'),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result!.isInvoice ? Colors.white : const Color(0xFFFFF2E8),
        border: Border.all(
          color: result!.isInvoice
              ? const Color(0xFFE3D9D0)
              : const Color(0xFFF0C9A9),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        result!.isInvoice
            ? const JsonEncoder.withIndent('  ').convert(result!.invoice)
            : 'Text is not from an invoice.',
        style: const TextStyle(
          color: Color(0xFF2C2926),
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }
}
