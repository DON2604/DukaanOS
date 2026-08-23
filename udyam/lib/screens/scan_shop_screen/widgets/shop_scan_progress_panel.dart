import 'package:flutter/material.dart';

class ShopScanProgressPanel extends StatelessWidget {
  const ShopScanProgressPanel({
    super.key,
    required this.completedSections,
    required this.totalSections,
    required this.isScanning,
    required this.onPrimaryPressed,
    required this.onSkipPressed,
  });

  final int completedSections;
  final int totalSections;
  final bool isScanning;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSkipPressed;

  @override
  Widget build(BuildContext context) {
    final progress = completedSections / totalSections;
    final primaryLabel = switch ((isScanning, completedSections > 0)) {
      (false, false) => 'Start scan',
      (true, _) => 'Finish scan',
      (false, true) => 'See inventory',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCDD0C8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'SCAN PROGRESS',
                style: TextStyle(
                  color: Color(0xFF60645F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
              const Spacer(),
              Text(
                '$completedSections of $totalSections shelves',
                style: const TextStyle(
                  color: Color(0xFFB8490C),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFFE2E4DE)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: const ColoredBox(color: Color(0xFFB8490C)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isScanning
                ? 'Move your phone slowly across your shelves.'
                : 'We’ll create your starting inventory from what we see.',
            style: const TextStyle(
              color: Color(0xFF60645F),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: onPrimaryPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8490C),
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: const Color(0xFFB8490C).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isScanning
                        ? Icons.check_rounded
                        : Icons.document_scanner_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    primaryLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onSkipPressed,
            child: const Text(
              'Skip for now',
              style: TextStyle(
                color: Color(0xFF60645F),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
