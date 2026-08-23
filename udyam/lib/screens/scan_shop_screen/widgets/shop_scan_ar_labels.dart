import 'package:flutter/material.dart';

import '../models/detected_product.dart';

class ShopScanArLabels extends StatelessWidget {
  const ShopScanArLabels({
    super.key,
    required this.products,
    required this.visibleCount,
  });

  final List<DetectedProduct> products;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final product in products)
            if (product.appearAtSection <= visibleCount)
              Align(
                alignment: product.alignment,
                child: _ArProductLabel(product: product),
              ),
        ],
      ),
    );
  }
}

class _ArProductLabel extends StatelessWidget {
  const _ArProductLabel({required this.product});

  final DetectedProduct product;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: product.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: product.accent.withValues(alpha: 0.35),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            decoration: BoxDecoration(
              color: const Color(0xF2F7F3EB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: product.accent.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Color(0xFF171917),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '×${product.quantity}',
                  style: TextStyle(
                    color: product.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
