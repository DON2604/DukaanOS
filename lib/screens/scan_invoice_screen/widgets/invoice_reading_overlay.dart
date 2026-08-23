import 'package:flutter/material.dart';

class InvoiceReadingOverlay extends StatelessWidget {
  const InvoiceReadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xCC000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF8AFFC8)),
              const SizedBox(height: 18),
              const Text(
                'Reading invoice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Extracting items, dates and totals',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
