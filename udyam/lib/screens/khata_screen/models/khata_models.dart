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

class StockTrendPoint {
  const StockTrendPoint({required this.day, required this.quantity});

  final String day;
  final double quantity;

  factory StockTrendPoint.fromJson(Map<String, dynamic> json) =>
      StockTrendPoint(
        day: (json['day'] ?? '').toString(),
        quantity: _number(json['quantity']),
      );
}

class RestockAlert {
  const RestockAlert({
    required this.itemName,
    required this.unit,
    required this.currentStock,
    required this.daysUntilStockout,
    required this.suggestedRestockQty,
    required this.severity,
    required this.message,
    required this.trend,
    this.itemId,
    this.category = 'general',
    this.alertType = 'restock',
    this.daysUntilExpiry,
    this.expiryDate,
    this.perishable = false,
    this.dailySalesRate = 0,
  });

  final String itemName;
  final String unit;
  final double currentStock;
  final int daysUntilStockout;
  final double suggestedRestockQty;
  final String severity;
  final String message;
  final List<StockTrendPoint> trend;
  final String? itemId;
  final String category;
  final String alertType;
  final int? daysUntilExpiry;
  final DateTime? expiryDate;
  final bool perishable;
  final double dailySalesRate;

  bool get isExpiry => alertType == 'expiry';

  factory RestockAlert.fromJson(Map<String, dynamic> json) => RestockAlert(
    itemName: (json['item_name'] ?? json['name'] ?? 'Item').toString(),
    unit: (json['unit'] ?? 'units').toString(),
    currentStock: _number(json['current_stock']),
    daysUntilStockout: (json['days_until_stockout'] is num
        ? (json['days_until_stockout'] as num).toInt()
        : int.tryParse('${json['days_until_stockout']}') ?? 0),
    suggestedRestockQty: _number(json['suggested_restock_qty']),
    severity: (json['severity'] ?? 'watch').toString().toLowerCase(),
    message: (json['message'] ?? '').toString(),
    trend: _maps(json['trend']).map(StockTrendPoint.fromJson).toList(),
    itemId: json['item_id']?.toString(),
    category: (json['category'] ?? 'general').toString(),
    alertType: (json['alert_type'] ?? 'restock').toString().toLowerCase(),
    daysUntilExpiry: json['days_until_expiry'] == null
        ? null
        : (json['days_until_expiry'] is num
              ? (json['days_until_expiry'] as num).toInt()
              : int.tryParse('${json['days_until_expiry']}')),
    expiryDate: DateTime.tryParse((json['expiry_date'] ?? '').toString()),
    perishable: json['perishable'] == true,
    dailySalesRate: _number(json['daily_sales_rate']),
  );
}

class VendorRecommendation {
  const VendorRecommendation({
    required this.vendorName,
    required this.quotedPricePerUnit,
    required this.discountPct,
    required this.finalTotal,
    required this.leadTimeDays,
    required this.rating,
    required this.rank,
    required this.requiredQuantity,
    this.unit = 'kg',
    this.notes = '',
    this.contactNumber = '',
  });

  final String vendorName;
  final double quotedPricePerUnit;
  final double discountPct;
  final double finalTotal;
  final int leadTimeDays;
  final double rating;
  final int rank;
  final double requiredQuantity;
  final String unit;
  final String notes;
  final String contactNumber;

  factory VendorRecommendation.fromJson(Map<String, dynamic> json) =>
      VendorRecommendation(
        vendorName: (json['vendor_name'] ?? 'Vendor').toString(),
        quotedPricePerUnit: _number(json['quoted_price_per_unit']),
        discountPct: _number(json['discount_pct']),
        finalTotal: _number(json['final_total']),
        leadTimeDays: (json['lead_time_days'] is num
            ? (json['lead_time_days'] as num).toInt()
            : int.tryParse('${json['lead_time_days']}') ?? 1),
        rating: _number(json['rating']),
        rank: (json['rank'] is num
            ? (json['rank'] as num).toInt()
            : int.tryParse('${json['rank']}') ?? 1),
        requiredQuantity: _number(json['required_quantity']),
        unit: (json['unit'] ?? 'kg').toString(),
        notes: (json['notes'] ?? '').toString(),
        contactNumber: (json['contact_number'] ?? '').toString(),
      );
}

class KhataCustomer {
  const KhataCustomer({
    required this.id,
    required this.name,
    required this.balance,
    this.score = 70,
    this.category = 'moderate',
    this.trustLabel = 'Moderate',
    this.paymentCount = 0,
    this.creditCount = 0,
    this.totalCredit = 0,
    this.totalPaid = 0,
    this.repaymentRate = 100,
    this.paymentProbabilityPct = 70,
    this.paymentProbabilityLabel = 'Moderate (70%)',
    this.creditRecommendation = '',
    this.reasons = const [],
  });

  final String id;
  final String name;
  final double balance;
  final int score;
  final String category;
  final String trustLabel;
  final int paymentCount;
  final int creditCount;
  final double totalCredit;
  final double totalPaid;
  final double repaymentRate;
  final int paymentProbabilityPct;
  final String paymentProbabilityLabel;
  final String creditRecommendation;
  final List<String> reasons;

  factory KhataCustomer.fromJson(Map<String, dynamic> json) {
    final rawReasons = json['reasons'];
    final reasonsList = rawReasons is List
        ? rawReasons.map((r) => r.toString()).toList()
        : const <String>[];

    return KhataCustomer(
      id: ((json['customer'] is Map ? (json['customer'] as Map)['id'] : null) ??
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
      score: (json['score'] is num
          ? (json['score'] as num).toInt()
          : int.tryParse('${json['score']}') ?? 70),
      category: (json['category'] ?? 'moderate').toString().toLowerCase(),
      trustLabel: (json['trust_label'] ?? json['risk_label'] ?? 'Moderate')
          .toString(),
      paymentCount: (json['payment_count'] is num
          ? (json['payment_count'] as num).toInt()
          : int.tryParse('${json['payment_count']}') ?? 0),
      creditCount: (json['credit_count'] is num
          ? (json['credit_count'] as num).toInt()
          : int.tryParse('${json['credit_count']}') ?? 0),
      totalCredit: _number(json['total_credit']),
      totalPaid: _number(json['total_paid']),
      repaymentRate: _number(json['repayment_rate'] ?? 100),
      paymentProbabilityPct: (json['payment_probability_pct'] is num
          ? (json['payment_probability_pct'] as num).toInt()
          : int.tryParse('${json['payment_probability_pct']}') ?? 70),
      paymentProbabilityLabel:
          (json['payment_probability_label'] ?? 'Moderate (70%)').toString(),
      creditRecommendation: (json['credit_recommendation'] ?? '').toString(),
      reasons: reasonsList,
    );
  }
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
    this.restockAlerts = const [],
    this.vendorRecommendations = const [],
  });

  final KhataSummary summary;
  final List<KhataInsight> insights;
  final List<KhataCustomer> customers;
  final List<KhataEntry> recentEntries;
  final List<RestockAlert> restockAlerts;
  final List<VendorRecommendation> vendorRecommendations;

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
    final restockAlerts = _maps(
      json['restock_alerts'],
    ).map(RestockAlert.fromJson).toList();
    final vendorRecommendations = _maps(
      json['vendor_recommendations'],
    ).map(VendorRecommendation.fromJson).toList();
    for (final alert in restockAlerts) {
      insights.add(
        KhataInsight(
          title: alert.isExpiry
              ? 'Expiry ${alert.itemName}'
              : 'Restock ${alert.itemName}',
          message: alert.message,
        ),
      );
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
      restockAlerts: restockAlerts,
      vendorRecommendations: vendorRecommendations,
    );
  }
}
