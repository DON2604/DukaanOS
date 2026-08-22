import 'package:flutter/material.dart';

class WelcomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WelcomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 4,
      toolbarHeight: 72,
      title: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset("assets/logo.png", height: 60, fit: BoxFit.contain),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
