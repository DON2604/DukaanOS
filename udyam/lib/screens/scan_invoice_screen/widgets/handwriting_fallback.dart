import 'package:flutter/material.dart';

import '../handwriting_input_screen.dart';

class HandwritingFallback extends StatelessWidget {
  final ValueChanged<String> onHandwritingRecognized;

  const HandwritingFallback({super.key, required this.onHandwritingRecognized});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E8),
        border: Border.all(color: const Color(0xFFF0C9A9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Some details may be missing',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF71300E),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Write the unreadable number, date or total by hand and we will try a second recognizer.',
            style: TextStyle(color: Color(0xFF8B5A3B), height: 1.35),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final handwriting = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => const HandwritingInputScreen(),
                ),
              );
              if (handwriting != null && handwriting.trim().isNotEmpty) {
                onHandwritingRecognized(handwriting.trim());
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Try handwriting input'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB8490C),
            ),
          ),
        ],
      ),
    );
  }
}
