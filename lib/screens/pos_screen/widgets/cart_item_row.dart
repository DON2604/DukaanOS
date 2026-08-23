import 'package:flutter/material.dart';

import '../models/cart_item.dart';

class CartItemRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemRow({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DFC9)),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.product.imageUrl.isNotEmpty
                ? Image.network(
                    item.product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFB8490C),
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFFB8490C),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF2C2926),
                  ),
                ),
                Text(
                  item.product.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C625C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2C2926),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF2C2926),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      size: 20,
                      color: Color(0xFF6C625C),
                    ),
                    onPressed: onDecrement,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: Color(0xFFB8490C),
                    ),
                    onPressed: onIncrement,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    onPressed: onRemove,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
