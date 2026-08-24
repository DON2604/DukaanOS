import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyam/screens/khata_screen/models/khata_models.dart';
import 'package:udyam/screens/khata_screen/services/khata_service.dart';
import 'package:udyam/screens/pos_screen/models/cart_item.dart';
import 'package:udyam/screens/pos_screen/models/product.dart';
import 'package:udyam/screens/pos_screen/services/checkout_service.dart';
import 'package:udyam/services/foreground_speech_service.dart';
import 'package:udyam/services/transcript_queue.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
  });

  test('dashboard parser accepts nested summary and flexible arrays', () {
    final dashboard = KhataDashboard.fromJson({
      'summary': {
        'revenue': 1200,
        'purchases': '500.5',
        'gain': 699.5,
        'items_sold': 12,
        'stock_value': 4000,
        'receivables': 300,
      },
      'insights': [
        {
          'language': 'en',
          'insights': ['Sales are rising'],
          'unresolved': [
            {'person': 'Ravi', 'type': 'promise', 'amount': 500},
          ],
        },
      ],
      'customer_balances': [
        {
          'customer': {'id': 1, 'name': 'Asha'},
          'balance': 300,
        },
      ],
      'recent_entries': [
        {'id': 'e1', 'entry_type': 'sale', 'total': 250},
      ],
    });

    expect(dashboard.summary.totalSales, 1200);
    expect(dashboard.summary.totalPurchases, 500.5);
    expect(dashboard.insights.first.message, 'Sales are rising');
    expect(
      dashboard.insights.any((item) => item.message.contains('Ravi')),
      isTrue,
    );
    expect(dashboard.customers.single.name, 'Asha');
    expect(dashboard.recentEntries.single.id, 'e1');
  });

  test('evolving transcript debounces duplicates and merges overlap', () {
    final transcript = EvolvingTranscript();

    expect(transcript.add('sold two'), isTrue);
    expect(transcript.add('sold two'), isFalse);
    expect(transcript.add('sold two soaps'), isTrue);
    expect(transcript.add('soaps for fifty rupees'), isTrue);
    expect(transcript.take(), 'sold two soaps for fifty rupees');
    expect(transcript.isEmpty, isTrue);
  });

  test('Khata service sends bearer auth and parses dashboard', () async {
    final service = KhataService(
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer test-token');
        expect(request.url.path, '/api/khata/dashboard');
        return http.Response(
          jsonEncode({'total_sales': 10, 'recent_entries': []}),
          200,
        );
      }),
    );

    final dashboard = await service.fetchDashboard();
    expect(dashboard.summary.totalSales, 10);
  });

  test('checkout sends contract payload including credit customer', () async {
    late Map<String, dynamic> payload;
    final service = CheckoutService(
      client: MockClient((request) async {
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{}', 201);
      }),
    );
    const product = Product(
      barcode: '1',
      inventoryItemId: 'inventory-1',
      name: 'Soap',
      description: '',
      price: 25,
      imageUrl: '',
    );

    await service.checkout(
      items: [CartItem(product: product, quantity: 2)],
      discount: 5,
      paymentType: PaymentType.credit,
      customerName: ' Asha ',
    );

    expect(payload['payment_type'], 'credit');
    expect((payload['customer'] as Map)['name'], 'Asha');
    expect(payload['discount'], 5);
    expect(payload['checkout_id'], isNotEmpty);
    expect(
      (payload['items'] as List).single['inventory_item_id'],
      'inventory-1',
    );
  });

  test('transcript queue deletes a batch only after HTTP success', () async {
    final queue = _MemoryQueue();
    await queue.enqueue(
      TranscriptBatch(
        batchId: 'batch-1',
        transcript: 'sold soap',
        startedAt: DateTime.utc(2026),
        endedAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
      ),
    );
    final failing = ForegroundSpeechService(
      queue: queue,
      client: MockClient((_) async => http.Response('no', 500)),
    );
    await failing.retryPending();
    expect(await queue.pending(), hasLength(1));

    final succeeding = ForegroundSpeechService(
      queue: queue,
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await succeeding.retryPending();
    expect(await queue.pending(), isEmpty);
  });
}

class _MemoryQueue implements TranscriptQueue {
  final List<TranscriptBatch> batches = [];

  @override
  Future<void> clear() async => batches.clear();

  @override
  Future<void> close() async {}

  @override
  Future<void> delete(String batchId) async {
    batches.removeWhere((batch) => batch.batchId == batchId);
  }

  @override
  Future<void> enqueue(TranscriptBatch batch) async => batches.add(batch);

  @override
  Future<List<TranscriptBatch>> pending() async => List.of(batches);
}
