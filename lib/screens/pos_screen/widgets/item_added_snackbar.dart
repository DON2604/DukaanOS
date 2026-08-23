import 'package:flutter/material.dart';

import '../models/product.dart';

void showItemAddedSnackBar(
  BuildContext context, {
  required Product product,
  required int quantity,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  final itemTotal = (product.price * quantity).toStringAsFixed(2);
  final countLabel = quantity == 1
      ? 'Added 1st time'
      : 'Added again (${quantity}x in bill)';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      backgroundColor: const Color(0xFF2C2926),
      duration: const Duration(milliseconds: 2200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: quantity > 1
                  ? const Color(0xFFB8490C)
                  : const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              quantity > 1
                  ? Icons.plus_one_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$countLabel • ₹$itemTotal',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE5DFC9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: quantity > 1
                  ? const Color(0xFFB8490C).withValues(alpha: 0.4)
                  : Colors.white24,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: quantity > 1
                    ? const Color(0xFFB8490C)
                    : Colors.white38,
              ),
            ),
            child: Text(
              '${quantity}x',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
