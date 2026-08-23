import 'package:flutter/material.dart';

class InvoiceSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const InvoiceSummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF55705D)),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF263B2B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
