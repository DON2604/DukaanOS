import 'package:flutter/material.dart';

class DetectedProduct {
  const DetectedProduct({
    required this.name,
    required this.detail,
    required this.quantity,
    required this.alignment,
    required this.accent,
    required this.appearAtSection,
  });

  final String name;
  final String detail;
  final int quantity;
  final Alignment alignment;
  final Color accent;
  final int appearAtSection;
}

const List<DetectedProduct> kDemoShelfProducts = [
  DetectedProduct(
    name: 'Maggi Masala',
    detail: '70g pack',
    quantity: 14,
    alignment: Alignment(-0.55, -0.25),
    accent: Color(0xFFB8490C),
    appearAtSection: 1,
  ),
  DetectedProduct(
    name: 'Parle-G',
    detail: '₹10 pack',
    quantity: 22,
    alignment: Alignment(0.62, -0.02),
    accent: Color(0xFF1F6F46),
    appearAtSection: 2,
  ),
  DetectedProduct(
    name: 'Coca-Cola',
    detail: '750ml',
    quantity: 6,
    alignment: Alignment(-0.28, 0.38),
    accent: Color(0xFF2B5B84),
    appearAtSection: 3,
  ),
  DetectedProduct(
    name: 'Tata Salt',
    detail: '1kg',
    quantity: 7,
    alignment: Alignment(0.42, 0.22),
    accent: Color(0xFF8C4A00),
    appearAtSection: 4,
  ),
];
