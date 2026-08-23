import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import 'cart_item_row.dart';
import 'checkout_buttons.dart';
import 'checkout_summary.dart';

class CartColumn extends StatelessWidget {
  final List<CartItem> cart;
  final double discount;
  final double subtotal;
  final double total;
  final VoidCallback onAddCustomItem;
  final VoidCallback onAddDiscount;
  final VoidCallback onSaveDraft;
  final VoidCallback onCheckout;
  final ValueChanged<int> onIncrement;
  final ValueChanged<int> onDecrement;
  final ValueChanged<int> onRemove;

  const CartColumn({
    super.key,
    required this.cart,
    required this.discount,
    required this.subtotal,
    required this.total,
    required this.onAddCustomItem,
    required this.onAddDiscount,
    required this.onSaveDraft,
    required this.onCheckout,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Current Bill',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2926),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6F4DF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cart.length}',
                  style: const TextStyle(
                    color: Color(0xFF263B2B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text(
                      'No items in bill.\nScan a product or search to add.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6C625C), fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    itemCount: cart.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFE5DFC9)),
                    itemBuilder: (context, index) {
                      return CartItemRow(
                        item: cart[index],
                        onIncrement: () => onIncrement(index),
                        onDecrement: () => onDecrement(index),
                        onRemove: () => onRemove(index),
                      );
                    },
                  ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB8490C),
              side: const BorderSide(color: Color(0xFFB8490C)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add custom item'),
            onPressed: onAddCustomItem,
          ),
          const SizedBox(height: 12),
          CheckoutSummary(
            subtotal: subtotal,
            discount: discount,
            total: total,
            onAddDiscount: onAddDiscount,
          ),
          const SizedBox(height: 12),
          CheckoutButtons(
            total: total,
            isEmpty: cart.isEmpty,
            onSaveDraft: onSaveDraft,
            onCheckout: onCheckout,
          ),
        ],
      ),
    );
  }
}
