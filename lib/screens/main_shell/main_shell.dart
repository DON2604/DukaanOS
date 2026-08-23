import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import '../inventory_screen/inventory_screen.dart';
import '../khata_screen/khata_screen.dart';
import '../more_screen/more_screen.dart';
import '../pos_screen/pos_screen.dart';
import '../scan_invoice_screen/scan_invoice_screen.dart';
import 'widgets/main_bottom_nav.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: MainBottomNav(
        navKey: _navKey,
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
