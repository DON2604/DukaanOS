import 'package:flutter/material.dart';

class ShopScanLine extends StatelessWidget {
  const ShopScanLine({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, -0.85 + (animation.value * 1.7)),
          child: child,
        );
      },
      child: IgnorePointer(
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: const Color(0xCCB8490C),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB8490C).withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
