import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../screens/khata_screen/models/khata_models.dart';

class RestockNotificationService {
  RestockNotificationService._();

  static final RestockNotificationService instance =
      RestockNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _notifiedThisSession = false;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
    _ready = true;
  }

  Future<void> notifyRestockAlerts(List<RestockAlert> alerts) async {
    if (!_ready || _notifiedThisSession || alerts.isEmpty) return;

    final urgent = alerts
        .where(
          (alert) => alert.severity == 'critical' || alert.severity == 'warning',
        )
        .toList();
    if (urgent.isEmpty) return;

    final status = await Permission.notification.request();
    if (!status.isGranted) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'restock_alerts',
        'Restock alerts',
        channelDescription: 'Alerts when shop items are running out',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final names = urgent.map((alert) => alert.itemName).join(', ');
    final expiryCount = urgent.where((alert) => alert.isExpiry).length;
    await _plugin.show(
      9001,
      expiryCount > 0
          ? '${urgent.length} stock & expiry alerts'
          : '${urgent.length} items running out',
      '$names — open AI Insights for trends.',
      details,
    );

    for (var index = 0; index < urgent.length; index++) {
      final alert = urgent[index];
      await _plugin.show(
        9100 + index,
        alert.isExpiry
            ? 'Expiry ${alert.itemName}'
            : 'Restock ${alert.itemName}',
        alert.isExpiry
            ? (alert.daysUntilExpiry != null && alert.daysUntilExpiry! < 0
                  ? 'This item has expired. Remove it from sale.'
                  : 'Expires in ${alert.daysUntilExpiry ?? 0} days. ${alert.currentStock.toStringAsFixed(0)} ${alert.unit} left.')
            : '${alert.currentStock.toStringAsFixed(0)} ${alert.unit} left. '
                  'Stockout in ${alert.daysUntilStockout} days — '
                  'order ${alert.suggestedRestockQty.toStringAsFixed(0)} ${alert.unit}.',
        details,
      );
    }

    _notifiedThisSession = true;
  }
}
