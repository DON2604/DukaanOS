import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';

import '../inventory_screen/inventory_screen.dart';
import '../khata_screen/khata_screen.dart';
import '../more_screen/more_screen.dart';
import '../pos_screen/pos_screen.dart';
import '../scan_invoice_screen/scan_invoice_screen.dart';

/// Central shell that owns the [CurvedNavigationBar] and switches between
/// tab pages. Pages are built/destroyed on demand (no IndexedStack) so the
/// camera in [ScanInvoiceScreen] is only active while that tab is selected.
class MainShell extends StatefulWidget {
  /// Optionally open on a specific tab at start (defaults to 0 = POS).
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex;
  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();

  // ---------------------------------------------------------------------------
  // Nav-bar styling — warm DukaanOS palette
  // ---------------------------------------------------------------------------
  static const _navBarColor = Color(0xFF2C2926); // dark bar
  static const _navBarBg = Color(0xFFF7F3EB); // matches scaffold bg
  static const _activeIconColor = Color(0xFFB8490C); // brand orange
  static const _inactiveIconColor = Color(0xFFBFB5AE);
  static const _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // ---------------------------------------------------------------------------
  // Build the active page — camera screen is only in the tree on index 1
  // ---------------------------------------------------------------------------
  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const PosScreen();
      case 1:
        return const ScanInvoiceScreen();
      case 2:
        return const InventoryScreen();
      case 3:
        return const KhataScreen();
      case 4:
      default:
        return const MoreScreen();
    }
  }

  // ---------------------------------------------------------------------------
  // Nav items
  // ---------------------------------------------------------------------------
  List<CurvedNavigationBarItem> get _items => [
    CurvedNavigationBarItem(
      child: Icon(
        _selectedIndex == 0
            ? Icons.point_of_sale
            : Icons.point_of_sale_outlined,
        color: _selectedIndex == 0 ? _activeIconColor : _inactiveIconColor,
      ),
      label: 'POS',
      labelStyle: _labelStyle,
    ),
    CurvedNavigationBarItem(
      child: Icon(
        _selectedIndex == 1
            ? Icons.document_scanner
            : Icons.document_scanner_outlined,
        color: _selectedIndex == 1 ? _activeIconColor : _inactiveIconColor,
      ),
      label: 'Sales',
      labelStyle: _labelStyle,
    ),
    CurvedNavigationBarItem(
      child: Icon(
        _selectedIndex == 2 ? Icons.inventory_2 : Icons.inventory_2_outlined,
        color: _selectedIndex == 2 ? _activeIconColor : _inactiveIconColor,
      ),
      label: 'Inventory',
      labelStyle: _labelStyle,
    ),
    CurvedNavigationBarItem(
      child: Icon(
        _selectedIndex == 3
            ? Icons.account_balance_wallet
            : Icons.account_balance_wallet_outlined,
        color: _selectedIndex == 3 ? _activeIconColor : _inactiveIconColor,
      ),
      label: 'Khata',
      labelStyle: _labelStyle,
    ),
    CurvedNavigationBarItem(
      child: Icon(
        _selectedIndex == 4 ? Icons.menu : Icons.menu_outlined,
        color: _selectedIndex == 4 ? _activeIconColor : _inactiveIconColor,
      ),
      label: 'More',
      labelStyle: _labelStyle,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navBarBg,
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: CurvedNavigationBar(
        key: _navKey,
        index: _selectedIndex,
        items: _items,
        color: _navBarColor,
        backgroundColor: _navBarBg,
        buttonBackgroundColor: _navBarColor,
        height: 65,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 350),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
