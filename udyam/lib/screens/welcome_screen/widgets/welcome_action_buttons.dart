import 'package:flutter/material.dart';

class WelcomeActionButtons extends StatelessWidget {
  final VoidCallback? onSetupShopPressed;
  final VoidCallback? onSignInPressed;

  const WelcomeActionButtons({
    super.key,
    this.onSetupShopPressed,
    this.onSignInPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onSetupShopPressed,
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
                  'Set up my shop',
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: onSignInPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0x99FFFFFF),
              foregroundColor: const Color(0xFF171917),
              side: const BorderSide(color: Color(0xFFCDD0C8), width: 1.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Sign in',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
