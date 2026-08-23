import 'package:flutter/material.dart';

class InvoiceCapturePanel extends StatelessWidget {
  final VoidCallback onCapture;

  const InvoiceCapturePanel({super.key, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF151716),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: GestureDetector(
          onTap: onCapture,
          child: Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7D847E), width: 2),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
