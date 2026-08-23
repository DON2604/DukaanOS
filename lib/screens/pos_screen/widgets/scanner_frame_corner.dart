import 'package:flutter/material.dart';

class ScannerFrameCorner extends StatelessWidget {
  final Alignment alignment;

  const ScannerFrameCorner({super.key, required this.alignment});

  @override
  Widget build(BuildContext context) {
    const double length = 16.0;
    const double thickness = 3.0;
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: length,
        height: length,
        child: Stack(
          children: [
            Positioned(
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              left: 0,
              right: 0,
              child: Container(height: thickness, color: Colors.greenAccent),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              child: Container(width: thickness, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
    );
  }
}
