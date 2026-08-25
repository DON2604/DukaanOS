import 'package:flutter/material.dart';

import '../voice_test_screen.dart';
import 'widgets/more_placeholder.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EB),
        foregroundColor: const Color(0xFF2C2926),
        elevation: 0,
        title: const Text(
          'More',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.mic, color: Color(0xFFB8490C)),
              title: const Text('Voice Test'),
              subtitle: const Text('Test microphone and speech recognition'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VoiceTestScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const MorePlaceholder(),
        ],
      ),
    );
  }
}
