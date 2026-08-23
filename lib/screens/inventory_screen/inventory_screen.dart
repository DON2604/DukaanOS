import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EB),
        foregroundColor: const Color(0xFF2C2926),
        elevation: 0,
        title: const Text(
          'Inventory',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFB8490C)),
            SizedBox(height: 16),
            Text(
              'Inventory',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2926),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(fontSize: 15, color: Color(0xFF6C625C)),
            ),
          ],
        ),
      ),
    );
  }
}
