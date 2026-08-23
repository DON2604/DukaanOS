import 'package:flutter/material.dart';

import 'widgets/khata_placeholder.dart';

class KhataScreen extends StatelessWidget {
  const KhataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EB),
        foregroundColor: const Color(0xFF2C2926),
        elevation: 0,
        title: const Text(
          'Khata',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
      ),
      body: const KhataPlaceholder(),
    );
  }
}
