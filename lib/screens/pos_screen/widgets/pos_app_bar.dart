import 'package:flutter/material.dart';

class PosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isFlashOn;
  final VoidCallback onToggleFlash;

  const PosAppBar({
    super.key,
    required this.isFlashOn,
    required this.onToggleFlash,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF7F3EB),
      foregroundColor: const Color(0xFF2C2926),
      elevation: 0,
      leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Sale',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF2C2926),
            ),
          ),
          Text(
            'Scan barcode to add products',
            style: TextStyle(fontSize: 12, color: Color(0xFF6C625C)),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            isFlashOn ? Icons.flash_on : Icons.flash_off,
            color: const Color(0xFFB8490C),
          ),
          tooltip: 'Flash',
          onPressed: onToggleFlash,
        ),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
