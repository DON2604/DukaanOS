import 'package:flutter/material.dart';

import 'models/inventory_item.dart';
import 'services/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryItem> _items = const [];
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await InventoryService().fetchItems();
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  String _money(double? value) {
    return value == null ? 'Not set' : '₹${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EB),
        foregroundColor: const Color(0xFF2C2926),
        elevation: 0,
        title: const Text(
          'Inventory',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadItems,
            tooltip: 'Refresh inventory',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadItems, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB8490C)),
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.cloud_off_outlined, size: 56),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadItems, child: const Text('Try again')),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF8B817A)),
          SizedBox(height: 16),
          Text(
            'Your inventory is empty',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Scan a supplier invoice and add its items here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6C625C)),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final pagePad = wide ? 24.0 : 16.0;
        final innerWidth = constraints.maxWidth - pagePad * 2;
        final expiring = _items
            .where((item) => (item.daysUntilExpiry ?? 99) <= 5)
            .length;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pagePad, 8, pagePad, 28),
          children: [
            if (expiring > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$expiring item${expiring == 1 ? '' : 's'} auto-detected as near expiry',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB8490C),
                  ),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _items
                  .map(
                    (item) => SizedBox(
                      width: wide ? (innerWidth - 12) / 2 : innerWidth,
                      child: _inventoryCard(item),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _inventoryCard(InventoryItem item) {
    final days = item.daysUntilExpiry;
    Color? badgeColor;
    String? badge;
    if (days != null) {
      if (days < 0) {
        badge = 'Expired';
        badgeColor = const Color(0xFFC62828);
      } else if (days <= 2) {
        badge = 'Expires in $days d';
        badgeColor = const Color(0xFFC62828);
      } else if (days <= 7) {
        badge = 'Expires in $days d';
        badgeColor = const Color(0xFFE65100);
      }
    }
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor!.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_number(item.quantity)} ${item.unit} in stock',
              style: const TextStyle(
                color: Color(0xFF2F6D3A),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (item.category != null) ...[
              const SizedBox(height: 4),
              Text(
                '${item.category}${item.shelfLifeDays == null ? '' : ' · ${item.shelfLifeDays} day shelf life'}',
                style: const TextStyle(color: Color(0xFF6C625C), fontSize: 12),
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Purchase: ${_money(item.purchaseUnitPrice)}')),
                Flexible(child: Text('Selling: ${_money(item.sellingPrice)}')),
              ],
            ),
            if (item.supplierName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Supplier: ${item.supplierName}',
                style: const TextStyle(color: Color(0xFF6C625C)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
