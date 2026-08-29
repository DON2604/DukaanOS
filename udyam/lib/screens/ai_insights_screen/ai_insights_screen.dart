import 'package:flutter/material.dart';

import '../khata_screen/models/khata_models.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({
    super.key,
    required this.insights,
    this.restockAlerts = const [],
  });

  final List<KhataInsight> insights;
  final List<RestockAlert> restockAlerts;

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<KhataInsight> _filteredInsights = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _filteredInsights = widget.insights;
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final categories = ['All', 'Sales', 'Inventory', 'Customers', 'Finance'];
    _selectedCategory = categories[_tabController.index];
    _filterInsights();
  }

  void _filterInsights() {
    setState(() {
      if (_selectedCategory == 'All') {
        _filteredInsights = widget.insights;
      } else {
        _filteredInsights = widget.insights.where((insight) {
          final title = insight.title.toLowerCase();
          final message = insight.message.toLowerCase();
          switch (_selectedCategory) {
            case 'Sales':
              return title.contains('sales') ||
                  title.contains('revenue') ||
                  message.contains('sales') ||
                  message.contains('revenue');
            case 'Inventory':
              return title.contains('stock') ||
                  title.contains('inventory') ||
                  title.contains('restock') ||
                  title.contains('expir') ||
                  message.contains('stock') ||
                  message.contains('inventory') ||
                  message.contains('restock') ||
                  message.contains('expir');
            case 'Customers':
              return title.contains('customer') ||
                  title.contains('payment') ||
                  message.contains('customer') ||
                  message.contains('payment');
            case 'Finance':
              return title.contains('profit') ||
                  title.contains('loss') ||
                  title.contains('finance') ||
                  message.contains('profit') ||
                  message.contains('loss') ||
                  message.contains('finance');
            default:
              return true;
          }
        }).toList();
      }

      _filteredInsights.sort((a, b) => a.title.compareTo(b.title));
    });
  }

  bool get _showRestockGraphs =>
      _selectedCategory == 'All' || _selectedCategory == 'Inventory';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EB),
        foregroundColor: const Color(0xFF2C2926),
        elevation: 0,
        title: const Text(
          'AI Insights',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFB8490C),
          unselectedLabelColor: const Color(0xFF6C625C),
          indicatorColor: const Color(0xFFB8490C),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Sales'),
            Tab(text: 'Inventory'),
            Tab(text: 'Customers'),
            Tab(text: 'Finance'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFB8490C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFB8490C).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFB8490C)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_filteredInsights.length} ${_selectedCategory.toLowerCase()} insights',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFFB8490C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.restockAlerts.isEmpty
                            ? 'AI-powered business recommendations'
                            : _headerSubtitle(widget.restockAlerts),
                        style: const TextStyle(
                          color: Color(0xFF6C625C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8490C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _selectedCategory,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredInsights.isEmpty && widget.restockAlerts.isEmpty
                ? _buildEmptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 720;
                      final pagePad = wide ? 24.0 : 16.0;
                      final innerWidth = constraints.maxWidth - pagePad * 2;
                      final alerts = _showRestockGraphs
                          ? widget.restockAlerts
                          : const <RestockAlert>[];
                      return ListView(
                        padding: EdgeInsets.symmetric(horizontal: pagePad),
                        children: [
                          if (alerts.isNotEmpty)
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: alerts
                                  .map(
                                    (alert) => SizedBox(
                                      width: wide
                                          ? (innerWidth - 12) / 2
                                          : innerWidth,
                                      child: _RestockTrendCard(alert: alert),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ..._filteredInsights.asMap().entries.map(
                            (entry) => _InsightCard(
                              insight: entry.value,
                              index: entry.key,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _headerSubtitle(List<RestockAlert> alerts) {
    final expiring = alerts.where((alert) => alert.isExpiry).length;
    final restock = alerts.where((alert) => !alert.isExpiry).length;
    final parts = <String>[];
    if (restock > 0) parts.add('$restock restock');
    if (expiring > 0) parts.add('$expiring expiry');
    return '${parts.join(' · ')} alerts saved from live stock intelligence';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: const Color(0xFFB8490C).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedCategory.toLowerCase()} insights yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C625C),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep using DukaanOS to generate personalized insights',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6C625C), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _RestockTrendCard extends StatelessWidget {
  const _RestockTrendCard({required this.alert});

  final RestockAlert alert;

  Color get _severityColor {
    switch (alert.severity) {
      case 'critical':
        return const Color(0xFFC62828);
      case 'warning':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  alert.isExpiry
                      ? Icons.event_busy
                      : Icons.trending_down,
                  color: _severityColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF2C2926),
                        ),
                      ),
                      Text(
                        alert.isExpiry
                            ? '${alert.category} · auto expiry'
                            : '${alert.category} · restock trend',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C625C),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert.severity.toUpperCase(),
                    style: TextStyle(
                      color: _severityColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.message,
              style: const TextStyle(
                color: Color(0xFF6C625C),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: _StockTrendPainter(
                  points: alert.trend.map((p) => p.quantity).toList(),
                  color: _severityColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Text(
                  '14-day stock trend',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6C625C)),
                ),
                Spacer(),
                Text(
                  'Today',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6C625C)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'Left',
                  value:
                      '${alert.currentStock.toStringAsFixed(0)} ${alert.unit}',
                ),
                _MetricChip(
                  label: alert.isExpiry ? 'Expires' : 'Stockout',
                  value: alert.isExpiry
                      ? (alert.daysUntilExpiry == null
                            ? 'Unknown'
                            : alert.daysUntilExpiry! < 0
                            ? 'Expired'
                            : '${alert.daysUntilExpiry} days')
                      : '${alert.daysUntilStockout} days',
                ),
                _MetricChip(
                  label: 'Restock',
                  value:
                      '${alert.suggestedRestockQty.toStringAsFixed(0)} ${alert.unit}',
                ),
                if (alert.perishable)
                  const _MetricChip(label: 'Type', value: 'Perishable'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6C625C)),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2926),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockTrendPainter extends CustomPainter {
  _StockTrendPainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minY = points.reduce((a, b) => a < b ? a : b);
    final maxY = points.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs() < 0.001 ? 1.0 : maxY - minY;
    final dx = size.width / (points.length - 1);

    Offset toOffset(int index) {
      final x = dx * index;
      final y = size.height - ((points[index] - minY) / range) * size.height;
      return Offset(x, y.clamp(0, size.height));
    }

    final path = Path()..moveTo(toOffset(0).dx, toOffset(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(toOffset(i).dx, toOffset(i).dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final last = toOffset(points.length - 1);
    canvas.drawCircle(last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StockTrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.index});

  final KhataInsight insight;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getInsightColor(insight.title).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getInsightIcon(insight.title),
                    color: _getInsightColor(insight.title),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF2C2926),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        insight.message,
                        style: const TextStyle(
                          color: Color(0xFF6C625C),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(index).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPriorityText(index),
                    style: TextStyle(
                      color: _getPriorityColor(index),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showInsightDetails(context, insight),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB8490C),
                      side: const BorderSide(color: Color(0xFFB8490C)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _takeAction(context, insight),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Take Action'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB8490C),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getInsightIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('sales') || lowerTitle.contains('revenue')) {
      return Icons.trending_up;
    } else if (lowerTitle.contains('expir')) {
      return Icons.event_busy;
    } else if (lowerTitle.contains('stock') ||
        lowerTitle.contains('inventory') ||
        lowerTitle.contains('restock')) {
      return Icons.inventory_2;
    } else if (lowerTitle.contains('customer') ||
        lowerTitle.contains('payment')) {
      return Icons.people;
    } else if (lowerTitle.contains('profit') || lowerTitle.contains('loss')) {
      return Icons.account_balance_wallet;
    }
    return Icons.lightbulb;
  }

  Color _getInsightColor(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('sales') || lowerTitle.contains('revenue')) {
      return const Color(0xFF4CAF50);
    } else if (lowerTitle.contains('expir')) {
      return const Color(0xFFC62828);
    } else if (lowerTitle.contains('stock') ||
        lowerTitle.contains('inventory') ||
        lowerTitle.contains('restock')) {
      return const Color(0xFF2196F3);
    } else if (lowerTitle.contains('customer') ||
        lowerTitle.contains('payment')) {
      return const Color(0xFF9C27B0);
    } else if (lowerTitle.contains('profit') || lowerTitle.contains('loss')) {
      return const Color(0xFFFF9800);
    }
    return const Color(0xFFB8490C);
  }

  Color _getPriorityColor(int index) {
    if (index < 2) return const Color(0xFFFF5722);
    if (index < 5) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  String _getPriorityText(int index) {
    if (index < 2) return 'HIGH';
    if (index < 5) return 'MEDIUM';
    return 'LOW';
  }

  void _showInsightDetails(BuildContext context, KhataInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getInsightIcon(insight.title),
              color: _getInsightColor(insight.title),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(insight.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(insight.message),
            const SizedBox(height: 16),
            const Text(
              'Recommendation:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_getRecommendation(insight.title)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _takeAction(context, insight);
            },
            child: const Text('Take Action'),
          ),
        ],
      ),
    );
  }

  void _takeAction(BuildContext context, KhataInsight insight) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked "${insight.title}" for restock follow-up'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getRecommendation(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('sales')) {
      return '• Focus on promoting high-margin products\n• Implement upselling strategies\n• Track conversion rates';
    } else if (lowerTitle.contains('expir')) {
      return '• Sell or discount before the expiry date\n• Do not restock the old lot\n• Check fridge and supplier freshness';
    } else if (lowerTitle.contains('inventory') ||
        lowerTitle.contains('restock') ||
        lowerTitle.contains('stock')) {
      return '• Reorder low-stock items now\n• Review supplier lead times\n• Keep a 7-day buffer on fast movers';
    } else if (lowerTitle.contains('customer')) {
      return '• Follow up with overdue customers\n• Implement payment reminders\n• Offer payment plans';
    } else if (lowerTitle.contains('profit')) {
      return '• Review pricing strategy\n• Reduce operational costs\n• Optimize product mix';
    }
    return 'Review the insight and take appropriate action based on your business needs.';
  }
}
