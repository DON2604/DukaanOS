import 'package:flutter/material.dart';

class ShopScanHeader extends StatelessWidget {
  const ShopScanHeader({
    super.key,
    required this.isFlashOn,
    required this.canToggleFlash,
    required this.onBack,
    required this.onToggleFlash,
  });

  final bool isFlashOn;
  final bool canToggleFlash;
  final VoidCallback? onBack;
  final VoidCallback onToggleFlash;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Show us your shop',
                style: TextStyle(
                  color: Color(0xFFF7F3EB),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Walk the shelves. We’ll start the stock book.',
                style: TextStyle(
                  color: Color(0xCCF7F3EB),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _RoundIconButton(
          icon: isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          onPressed: canToggleFlash ? onToggleFlash : null,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6F7F3EB),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null
                ? const Color(0xFFB4B7B2)
                : const Color(0xFF171917),
          ),
        ),
      ),
    );
  }
}
