import 'package:flutter/material.dart';

Future<void> showCheckoutCompleteDialog(
  BuildContext context, {
  required double total,
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFFF7F3EB),
      title: const Text('Checkout Complete'),
      content: Text('Collected ₹${total.toStringAsFixed(2)} successfully!'),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB8490C),
          ),
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
