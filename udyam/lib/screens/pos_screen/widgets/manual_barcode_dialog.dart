import 'package:flutter/material.dart';

Future<String?> showManualBarcodeDialog(BuildContext context) {
  final barcodeController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFFF7F3EB),
        title: const Text(
          'Enter Barcode Manually',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2926),
          ),
        ),
        content: TextField(
          controller: barcodeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Barcode Number',
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
              final barcode = barcodeController.text.trim();
              if (barcode.isNotEmpty) {
                Navigator.pop(context, barcode);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      );
    },
  );
}
