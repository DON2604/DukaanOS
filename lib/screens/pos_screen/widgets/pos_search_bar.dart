import 'package:flutter/material.dart';

class PosSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const PosSearchBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      color: const Color(0xFFF7F3EB),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5DFC9)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF6C625C)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: onSubmitted,
                decoration: const InputDecoration(
                  hintText: 'Search or add item manually',
                  hintStyle: TextStyle(color: Color(0xFFBFB5AE), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Icon(Icons.mic, color: Color(0xFF6C625C)),
          ],
        ),
      ),
    );
  }
}
