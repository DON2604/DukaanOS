import 'package:flutter/material.dart';

class ShopScanHint extends StatefulWidget {
  const ShopScanHint({super.key, required this.isScanning});

  final bool isScanning;

  @override
  State<ShopScanHint> createState() => _ShopScanHintState();
}

class _ShopScanHintState extends State<ShopScanHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isScanning
        ? 'Keep moving along the shelf'
        : 'Move slowly';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xF2F7F3EB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCDD0C8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF171917),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_controller.value * 6, 0),
                child: child,
              );
            },
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Color(0xFFB8490C),
            ),
          ),
        ],
      ),
    );
  }
}
