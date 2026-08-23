import 'package:flutter/material.dart';

class CheckoutButtons extends StatelessWidget {
  final double total;
  final bool isEmpty;
  final VoidCallback onSaveDraft;
  final VoidCallback onCheckout;

  const CheckoutButtons({
    super.key,
    required this.total,
    required this.isEmpty,
    required this.onSaveDraft,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB8490C),
              side: const BorderSide(color: Color(0xFFB8490C)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isEmpty ? null : onSaveDraft,
            child: const Text('Save as draft'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB8490C),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isEmpty ? null : onCheckout,
            child: Text('Collect ₹${total.toStringAsFixed(2)}'),
          ),
        ),
      ],
    );
  }
}
