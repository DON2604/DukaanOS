import 'package:flutter/material.dart';

class CheckoutSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double total;
  final VoidCallback onAddDiscount;

  const CheckoutSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.onAddDiscount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DFC9)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(color: Color(0xFF6C625C)),
              ),
              Text(
                '₹${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discount',
                style: TextStyle(color: Color(0xFF6C625C)),
              ),
              GestureDetector(
                onTap: onAddDiscount,
                child: Text(
                  discount > 0 ? '-₹${discount.toStringAsFixed(2)}' : 'Add',
                  style: const TextStyle(
                    color: Color(0xFFB8490C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFE5DFC9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFB8490C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
