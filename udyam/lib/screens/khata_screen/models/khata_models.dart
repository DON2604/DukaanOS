double _number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : const [];

class KhataSummary {
  const KhataSummary({
    required this.totalSales,
    required this.totalPurchases,
    required this.totalGain,
    required this.itemsSold,
    required this.stockValue,
    required this.totalReceivables,
  });

  final double totalSales;
  final double totalPurchases;
  final double totalGain;
  final double itemsSold;
  final double stockValue;
  final double totalReceivables;

  factory KhataSummary.fromJson(Map<String, dynamic> json) => KhataSummary(
    totalSales: _number(json['total_sales'] ?? json['revenue']),
    totalPurchases: _number(json['total_purchases'] ?? json['purchases']),
    totalGain: _number(json['total_gain'] ?? json['gain']),
    itemsSold: _number(json['items_sold']),
    stockValue: _number(json['stock_value']),
    totalReceivables: _number(json['total_receivables'] ?? json['receivables']),
  );
}

class KhataInsight {
  const KhataInsight({required this.title, required this.message});

  final String title;
  final String message;

  factory KhataInsight.fromJson(Map<String, dynamic> json) => KhataInsight(
    title: (json['title'] ?? json['type'] ?? 'Insight').toString(),
    message: (json['message'] ?? json['text'] ?? json['description'] ?? '')
        .toString(),
  );
}

class KhataCustomer {
  const KhataCustomer({
    required this.id,
    required this.name,
    required this.balance,
  });

  final String id;
  final String name;
  final double balance;

  factory KhataCustomer.fromJson(Map<String, dynamic> json) => KhataCustomer(
    id:
        ((json['customer'] is Map ? (json['customer'] as Map)['id'] : null) ??
                json['id'] ??
                '')
            .toString(),
    name:
        ((json['customer'] is Map ? (json['customer'] as Map)['name'] : null) ??
                json['name'] ??
                json['customer_name'] ??
                'Customer')
            .toString(),
    balance: _number(
      json['balance'] ?? json['amount_due'] ?? json['receivable'],
    ),
  );
}

class KhataEntry {
  const KhataEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    this.customerName,
    this.occurredAt,
  });

  final String id;
  final String type;
  final String description;
  final double amount;
  final String? customerName;
  final DateTime? occurredAt;

  factory KhataEntry.fromJson(Map<String, dynamic> json) => KhataEntry(
    id: (json['id'] ?? '').toString(),
    type: (json['type'] ?? json['entry_type'] ?? 'entry').toString(),
    description: (json['description'] ?? json['name'] ?? json['note'] ?? '')
        .toString(),
    amount: _number(json['amount'] ?? json['total']),
    customerName: (json['customer_name'] ?? json['customer'])?.toString(),
    occurredAt: DateTime.tryParse(
      (json['occurred_at'] ?? json['created_at'] ?? json['date'] ?? '')
          .toString(),
    ),
  );

  KhataEntry copyWith({String? description, double? amount}) => KhataEntry(
    id: id,
    type: type,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    customerName: customerName,
    occurredAt: occurredAt,
  );
}

class KhataDashboard {
  const KhataDashboard({
    required this.summary,
    required this.insights,
    required this.customers,
    required this.recentEntries,
  });

  final KhataSummary summary;
  final List<KhataInsight> insights;
  final List<KhataCustomer> customers;
  final List<KhataEntry> recentEntries;

  factory KhataDashboard.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : json;
    final insightBatches = _maps(json['insights']);
    final insights = <KhataInsight>[];
    for (final batch in insightBatches) {
      final messages = batch['insights'];
      if (messages is List) {
        for (final message in messages) {
          if (message.toString().trim().isNotEmpty) {
            insights.add(
              KhataInsight(
                title: batch['language']?.toString() ?? 'Voice insight',
                message: message.toString(),
              ),
            );
          }
        }
      } else {
        insights.add(KhataInsight.fromJson(batch));
      }
      final unresolved = batch['unresolved'];
      if (unresolved is List) {
        for (final raw in unresolved.whereType<Map>()) {
          final person = raw['person']?.toString() ?? 'Customer';
          final type = raw['type']?.toString() ?? 'obligation';
          final amount = raw['amount'];
          final item = raw['item']?.toString();
          final detail = amount != null
              ? '₹$amount'
              : (item?.isNotEmpty == true ? item! : 'amount not confirmed');
          insights.add(
            KhataInsight(
              title: 'Needs review',
              message: '$person: $type — $detail',
            ),
          );
        }
      }
    }
    return KhataDashboard(
      summary: KhataSummary.fromJson(summary),
      insights: insights,
      customers: _maps(json['customer_balances'] ?? json['customers'])
          .map(KhataCustomer.fromJson)
          .toList(),
      recentEntries: _maps(json['recent_entries'])
          .map(KhataEntry.fromJson)
          .toList(),
    );
  }
}
