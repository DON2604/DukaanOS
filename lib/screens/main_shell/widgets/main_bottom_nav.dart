import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';

class MainBottomNav extends StatelessWidget {
  final GlobalKey<CurvedNavigationBarState> navKey;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const MainBottomNav({
    super.key,
    required this.navKey,
    required this.selectedIndex,
    required this.onTap,
  });

  static const _navBarColor = Color(0xFF2C2926);
  static const _navBarBg = Color(0xFFF7F3EB);
  static const _activeIconColor = Color(0xFFB8490C);
  static const _inactiveIconColor = Color(0xFFBFB5AE);
  static const _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  List<CurvedNavigationBarItem> get _items => [
    CurvedNavigationBarItem(
      child: Icon(
        selectedIndex == 0
            ? Icons.point_of_sale
            : Icons.point_of_sale_outlined,
        color: selectedIndex == 0 ? _activeIconColor : _inactiveIconColor,
      ),
      label: 'POS',
      labelStyle: _labelStyle,
    ),
    CurvedNavigationBarItem(
      child: Icon(
        selectedIndex == 1
            ? Icons.document_scanner
            : Icons.document_scanner_outlined,
        color: selectedIndex == 1 ? _activeIconColor : _inactiveIconColor,
      ),
      label: 'Sales',
      labelStyle: _labelStyle,
    ),
    CurvedNavigationBarItem(
      child: Icon(
        selectedIndex == 2 ? Icons.inventory_2 : Icons.inventory_2_outlined,
        color: selectedIndex == 2 ? _activeIconColor : _inactiveIconColor,
      ),
      label: 'Inventory',
      labelStyle: _labelStyle,
    ),
    CurvedNavigationBarItem(
      child: Icon(
        selectedIndex == 3
            ? Icons.account_balance_wallet
            : Icons.account_balance_wallet_outlined,
        color: selectedIndex == 3 ? _activeIconColor : _inactiveIconColor,
      ),
      label: 'Khata',
      labelStyle: _labelStyle,
    ),
    CurvedNavigationBarItem(
      child: Icon(
        selectedIndex == 4 ? Icons.menu : Icons.menu_outlined,
        color: selectedIndex == 4 ? _activeIconColor : _inactiveIconColor,
      ),
      label: 'More',
      labelStyle: _labelStyle,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      key: navKey,
      index: selectedIndex,
      items: _items,
      color: _navBarColor,
      backgroundColor: _navBarBg,
      buttonBackgroundColor: _navBarColor,
      height: 65,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 350),
      onTap: onTap,
    );
  }
}
