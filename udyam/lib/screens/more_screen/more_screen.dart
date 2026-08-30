import 'package:flutter/material.dart';

import '../khata_screen/models/khata_models.dart';
import '../khata_screen/services/khata_service.dart';
import '../voice_test_screen.dart';
import 'widgets/more_placeholder.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final KhataService _service = KhataService();
  bool _loading = true;
  List<VendorRecommendation> _vendors = const [];

  @override
  void initState() {
    super.initState();
    _loadVendorRecommendations();
  }

  Future<void> _loadVendorRecommendations() async {
    try {
      final dashboard = await _service.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _vendors = dashboard.vendorRecommendations;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: Color(0xFF1B5E20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Vendor recommendations',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_vendors.isEmpty)
                    const Text(
                      'No low-stock vendor suggestions right now.',
                      style: TextStyle(color: Color(0xFF6C625C)),
                    )
                  else ...[
                    ..._vendors.take(3).map(
                      (vendor) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '#${vendor.rank} ${vendor.vendorName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${vendor.discountPct.toStringAsFixed(0)}% off',
                                  style: const TextStyle(
                                    color: Color(0xFF1B5E20),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${vendor.requiredQuantity.toStringAsFixed(0)} ${vendor.unit} needed • ₹${vendor.finalTotal.toStringAsFixed(2)} total',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6C625C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${vendor.quotedPricePerUnit.toStringAsFixed(2)}/${vendor.unit} • ${vendor.leadTimeDays}-day lead time • ${vendor.rating.toStringAsFixed(1)}/5',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6C625C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const MorePlaceholder(),
        ],
      ),
    );
  }
}
