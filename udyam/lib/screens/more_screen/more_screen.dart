import 'package:flutter/material.dart';

import 'widgets/more_placeholder.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EB),
        foregroundColor: const Color(0xFF2C2926),
        elevation: 0,
        title: const Text(
          'More',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
      ),
      body: const MorePlaceholder(),
    );
  }
}
