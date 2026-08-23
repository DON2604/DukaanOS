import 'package:flutter/material.dart';

Future<double?> showAddDiscountDialog(
  BuildContext context, {
  required double currentDiscount,
}) {
  final discountController = TextEditingController(
    text: currentDiscount.toStringAsFixed(0),
  );

  return showDialog<double>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFFF7F3EB),
        title: const Text(
          'Apply Discount',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2926),
          ),
        ),
        content: TextField(
          controller: discountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Discount (₹)',
            labelStyle: TextStyle(color: Color(0xFF6C625C)),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB8490C)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6C625C)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB8490C),
            ),
            onPressed: () {
              Navigator.pop(
                context,
                double.tryParse(discountController.text.trim()) ?? 0.0,
              );
            },
            child: const Text('Apply'),
          ),
        ],
      );
    },
  );
}
