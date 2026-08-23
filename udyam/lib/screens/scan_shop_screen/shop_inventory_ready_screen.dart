import 'package:flutter/material.dart';

import '../main_shell/main_shell.dart';
import 'models/detected_product.dart';

class ShopInventoryReadyScreen extends StatelessWidget {
  const ShopInventoryReadyScreen({
    super.key,
    required this.products,
    required this.shelvesScanned,
  });

  final List<DetectedProduct> products;
  final int shelvesScanned;

  int get _itemCount =>
      products.fold<int>(0, (sum, product) => sum + product.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Your inventory is ready',
                style: TextStyle(
                  color: Color(0xFF171917),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We counted what we could see on the shelves. Review it any time.',
                style: TextStyle(
                  color: Color(0xFF60645F),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Products',
                      value: '$_itemCount',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Stock value',
                      value: '₹74,420',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Shelves',
                      value: '$shelvesScanned',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Detected on this pass',
                style: TextStyle(
                  color: Color(0xFF171917),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E4DE)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: Color(0xFFE2E4DE),
                    ),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: product.accent.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: product.accent,
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            color: Color(0xFF171917),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          product.detail,
                          style: const TextStyle(
                            color: Color(0xFF8A8E88),
                            fontSize: 13,
                          ),
                        ),
                        trailing: Text(
                          '${product.quantity}',
                          style: const TextStyle(
                            color: Color(0xFF171917),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const MainShell(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8490C),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFFB8490C).withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Go to my shop',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E4DE)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF171917),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A8E88),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
