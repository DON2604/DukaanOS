import 'package:flutter/material.dart';

import '../models/product.dart';

Future<Product?> showAddCustomItemDialog(BuildContext context) {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  return showDialog<Product>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFFF7F3EB),
        title: const Text(
          'Add Custom Item',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2926),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                labelStyle: TextStyle(color: Color(0xFF6C625C)),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFB8490C)),
                ),
              ),
            ),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                labelStyle: TextStyle(color: Color(0xFF6C625C)),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFB8490C)),
                ),
              ),
            ),
          ],
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
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              if (name.isNotEmpty && price > 0) {
                Navigator.pop(
                  context,
                  Product(
                    barcode: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    description: 'Custom Item',
                    price: price,
                    imageUrl: '',
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}
