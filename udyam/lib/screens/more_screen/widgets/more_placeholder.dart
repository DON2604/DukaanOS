import 'package:flutter/material.dart';

class MorePlaceholder extends StatelessWidget {
  const MorePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_outlined, size: 64, color: Color(0xFFB8490C)),
          SizedBox(height: 16),
          Text(
            'More',
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
    );
  }
}
