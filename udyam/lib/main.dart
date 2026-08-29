import 'package:flutter/material.dart';

import 'screens/app_startup/app_startup_screen.dart';
import 'services/restock_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RestockNotificationService.instance.init();
  runApp(const UdyamApp());
}

class UdyamApp extends StatelessWidget {
  const UdyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DukaanOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F3EB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB8490C),
          brightness: Brightness.light,
        ),
      ),
      home: const AppStartupScreen(),
    );
  }
}
