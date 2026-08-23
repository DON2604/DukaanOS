import 'package:flutter/material.dart';

class KhataPlaceholder extends StatelessWidget {
  const KhataPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Color(0xFFB8490C),
          ),
          SizedBox(height: 16),
          Text(
            'Khata',
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
