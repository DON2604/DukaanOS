import 'package:flutter/material.dart';

import '../models/invoice_fields.dart';
import 'invoice_summary_row.dart';

class InvoiceSummaryCard extends StatelessWidget {
  final InvoiceFields fields;

  const InvoiceSummaryCard({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InvoiceSummaryRow(label: 'Invoice number', value: fields.number),
          InvoiceSummaryRow(label: 'Date', value: fields.date),
          InvoiceSummaryRow(label: 'Total', value: fields.total),
        ],
      ),
    );
  }
}
