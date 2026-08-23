import 'package:flutter/material.dart';

class InvoiceFrameCorner extends StatelessWidget {
  final Alignment alignment;

  const InvoiceFrameCorner({super.key, required this.alignment});

  @override
  Widget build(BuildContext context) {
    const cornerSize = 26.0;
    const stroke = 4.0;
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: cornerSize,
        height: cornerSize,
        child: Stack(
          children: [
            Positioned(
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              left: 0,
              right: 0,
              child: Container(height: stroke, color: const Color(0xFF8AFFC8)),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              child: Container(width: stroke, color: const Color(0xFF8AFFC8)),
            ),
          ],
        ),
      ),
    );
  }
}
