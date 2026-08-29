import 'package:flutter/material.dart';

import '../../services/foreground_speech_service.dart';
import '../../services/restock_notification_service.dart';
import '../ai_insights_screen/ai_insights_screen.dart';
import 'models/khata_models.dart';
import 'services/khata_service.dart';

class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key, this.service});

  final KhataService? service;

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  late final KhataService _service = widget.service ?? KhataService();
  final _voice = ForegroundSpeechService.instance;
  KhataDashboard? _dashboard;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _voice.addListener(_voiceChanged);
    _load();
  }

  @override
  void dispose() {
    _voice.removeListener(_voiceChanged);
    super.dispose();
  }

  void _voiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashboard = await _service.fetchDashboard();
      if (mounted) {
        setState(() => _dashboard = dashboard);
        await RestockNotificationService.instance.notifyRestockAlerts(
          dashboard.restockAlerts,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
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
          'Khata',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Khata',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    if (_loading && _dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 160),
          const Icon(Icons.cloud_off, size: 52, color: Color(0xFFB8490C)),
          const SizedBox(height: 12),
          Text(
            _error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6C625C)),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(onPressed: _load, child: const Text('Retry')),
          ),
        ],
      );
    }

    final dashboard = _dashboard!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _VoiceControlCard(voice: _voice),
        const SizedBox(height: 16),
        const _SectionTitle('Business summary'),
        const SizedBox(height: 8),
        _SummaryGrid(summary: dashboard.summary),
        const SizedBox(height: 20),
        const _SectionTitle('Customer risk overview'),
        const SizedBox(height: 8),
        _CustomerRiskOverview(customers: dashboard.customers),
        const SizedBox(height: 20),
        _AiInsightsTabSection(
          insights: dashboard.insights,
          restockAlerts: dashboard.restockAlerts,
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Customer balances'),
        const SizedBox(height: 8),
        if (dashboard.customers.isEmpty)
          const _EmptyCard('No customer balances.')
        else
          Card(
            child: Column(
              children: dashboard.customers
                  .map(
                    (customer) => ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(customer.name),
                      trailing: Text(
                        '₹${customer.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: customer.balance > 0
                              ? const Color(0xFFB8490C)
                              : const Color(0xFF287A46),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 20),
        const _SectionTitle('Recent entries'),
        const SizedBox(height: 8),
        if (dashboard.recentEntries.isEmpty)
          const _EmptyCard('No Khata entries yet.')
        else
          ...dashboard.recentEntries.map(_entryCard),
      ],
    );
  }

  Widget _entryCard(KhataEntry entry) {
    return Card(
      key: ValueKey(entry.id),
      child: ListTile(
        leading: Icon(
          entry.type.toLowerCase().contains('purchase')
              ? Icons.shopping_bag_outlined
              : Icons.receipt_long_outlined,
          color: const Color(0xFFB8490C),
        ),
        title: Text(
          entry.description.isEmpty ? entry.type : entry.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            if (entry.customerName?.isNotEmpty == true) entry.customerName!,
            if (entry.occurredAt != null)
              '${entry.occurredAt!.day}/${entry.occurredAt!.month}/${entry.occurredAt!.year}',
          ].join(' • '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${entry.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') _editEntry(entry);
                if (action == 'delete') _stageDelete(entry);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Correct entry')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editEntry(KhataEntry entry) async {
    final description = TextEditingController(text: entry.description);
    final amount = TextEditingController(text: entry.amount.toStringAsFixed(2));
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Correct entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save != true || !mounted) return;
    final value = double.tryParse(amount.text);
    if (description.text.trim().isEmpty || value == null || value <= 0) {
      _message('Enter a valid description and amount.');
      return;
    }
    try {
      await _service.updateEntry(
        entry.id,
        description: description.text.trim(),
        amount: value,
      );
      await _load();
    } catch (error) {
      _message(error.toString());
    }
  }

  void _stageDelete(KhataEntry entry) {
    final entries = _dashboard!.recentEntries;
    final index = entries.indexWhere((item) => item.id == entry.id);
    if (index < 0) return;
    setState(() => entries.removeAt(index));
    var undone = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Entry deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            undone = true;
            if (mounted) setState(() => entries.insert(index, entry));
          },
        ),
      ),
    );
    Future<void>.delayed(const Duration(seconds: 4), () async {
      if (undone) return;
      try {
        await _service.deleteEntry(entry.id);
      } catch (error) {
        if (!mounted) return;
        setState(() => entries.insert(index.clamp(0, entries.length), entry));
        _message(error.toString());
      }
    });
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _VoiceControlCard extends StatelessWidget {
  const _VoiceControlCard({required this.voice});
  final ForegroundSpeechService voice;

  @override
  Widget build(BuildContext context) {
    final label = switch (voice.status) {
      VoiceCaptureStatus.disabled => 'Voice intelligence is off',
      VoiceCaptureStatus.paused => 'Paused while Khata is open',
      VoiceCaptureStatus.checking => 'Checking speech support…',
      VoiceCaptureStatus.listening => 'Listening on other tabs',
      VoiceCaptureStatus.unavailable => 'Speech recognition unavailable',
      VoiceCaptureStatus.permissionDenied => 'Microphone permission denied',
      VoiceCaptureStatus.error => 'Voice capture needs attention',
    };

    final bool hasError =
        voice.status == VoiceCaptureStatus.error ||
        voice.status == VoiceCaptureStatus.unavailable ||
        voice.status == VoiceCaptureStatus.permissionDenied;

    return Card(
      color: const Color(0xFFFFF0E6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  voice.consentGranted ? Icons.mic : Icons.mic_off,
                  color: hasError ? Colors.red : const Color(0xFFB8490C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: hasError ? Colors.red : null,
                    ),
                  ),
                ),
                Switch(
                  value: voice.consentGranted,
                  onChanged: voice.setConsent,
                ),
              ],
            ),
            Text(
              voice.statusDetail ?? 'With consent, speech is transcribed on-device while DukaanOS is foregrounded. Saved text is sent to Gemini only when you open Khata, and explicit debts may be added automatically.',
              style: const TextStyle(color: Color(0xFF6C625C), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (hasError && voice.consentGranted)
                  TextButton.icon(
                    onPressed: () => _retryVoice(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                TextButton.icon(
                  onPressed: voice.consentGranted
                      ? () => voice.setManualPause(!voice.isPaused)
                      : null,
                  icon: Icon(voice.isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(voice.isPaused ? 'Resume' : 'Pause'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmClear(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear queued audio text'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryVoice(BuildContext context) async {
    // Force reinitialize the speech service
    await voice.setConsent(false);
    await Future.delayed(const Duration(milliseconds: 500));
    await voice.setConsent(true);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retrying voice initialization...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear queued transcripts?'),
        content: const Text(
          'Unsent transcript batches will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear == true) await voice.clear();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(text, style: const TextStyle(color: Color(0xFF6C625C))),
      ),
    ),
  );
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});
  final KhataSummary summary;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('Sales', summary.totalSales, true),
      ('Purchases', summary.totalPurchases, true),
      ('Gain', summary.totalGain, true),
      ('Items sold', summary.itemsSold, false),
      ('Stock value', summary.stockValue, true),
      ('Receivables', summary.totalReceivables, true),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 1.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: values.length,
      itemBuilder: (_, index) {
        final item = values[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.$1, style: const TextStyle(color: Color(0xFF6C625C))),
                const SizedBox(height: 4),
                Text(
                  '${item.$3 ? '₹' : ''}${item.$2.toStringAsFixed(item.$3 ? 2 : 0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CustomerRiskOverview extends StatelessWidget {
  const _CustomerRiskOverview({required this.customers});
  final List<KhataCustomer> customers;

  @override
  Widget build(BuildContext context) {
    // Segregate customers based on backend scoring category
    final goodCustomers = <KhataCustomer>[];
    final moderateCustomers = <KhataCustomer>[];
    final badCustomers = <KhataCustomer>[];

    for (final customer in customers) {
      if (customer.category == 'good') {
        goodCustomers.add(customer);
      } else if (customer.category == 'bad') {
        badCustomers.add(customer);
      } else {
        moderateCustomers.add(customer);
      }
    }

    // Sort customers by score descending, then balance descending
    goodCustomers.sort((a, b) {
      final s = b.score.compareTo(a.score);
      return s != 0 ? s : b.balance.compareTo(a.balance);
    });
    moderateCustomers.sort((a, b) {
      final s = b.score.compareTo(a.score);
      return s != 0 ? s : b.balance.compareTo(a.balance);
    });
    badCustomers.sort((a, b) {
      final s = a.score.compareTo(b.score); // Lowest score first for bad
      return s != 0 ? s : b.balance.compareTo(a.balance);
    });

    return Column(
      children: [
        _CustomerRiskSection(
          title: 'Good (Trusted)',
          subtitle: 'High probability to repay',
          riskLevel: 'Low Risk • Score 75–100',
          customers: goodCustomers,
          color: const Color(0xFF1B873F),
          backgroundColor: const Color(0xFFE8F5E9),
        ),
        const SizedBox(height: 12),
        _CustomerRiskSection(
          title: 'Moderate (Average)',
          subtitle: 'Fair repayment record',
          riskLevel: 'Medium Risk • Score 50–74',
          customers: moderateCustomers,
          color: const Color(0xFFD97706),
          backgroundColor: const Color(0xFFFFFBEB),
        ),
        const SizedBox(height: 12),
        _CustomerRiskSection(
          title: 'High Risk (Poor)',
          subtitle: 'Overdue or low repayment',
          riskLevel: 'High Risk • Score < 50',
          customers: badCustomers,
          color: const Color(0xFFDC2626),
          backgroundColor: const Color(0xFFFEF2F2),
        ),
      ],
    );
  }
}

class _CustomerRiskSection extends StatelessWidget {
  const _CustomerRiskSection({
    required this.title,
    required this.subtitle,
    required this.riskLevel,
    required this.customers,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final String subtitle;
  final String riskLevel;
  final List<KhataCustomer> customers;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return Card(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    title.substring(0, 1),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No customers in this category',
                      style: const TextStyle(
                        color: Color(0xFF6C625C),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with category info
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      title.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        riskLevel,
                        style: const TextStyle(
                          color: Color(0xFF6C625C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${customers.length} customer${customers.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Customer list
            ...customers.map(
              (customer) => _CustomerListItem(
                customer: customer,
                subtitle: subtitle,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerListItem extends StatelessWidget {
  const _CustomerListItem({
    required this.customer,
    required this.subtitle,
    required this.color,
  });

  final KhataCustomer customer;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCustomerScoreDialog(context, customer),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: color.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer avatar with score badge
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : 'C',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${customer.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Customer info & scoring details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${customer.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: customer.balance > 0
                              ? const Color(0xFFB8490C)
                              : const Color(0xFF1B873F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    customer.creditCount > 0
                        ? 'Paid ${customer.paymentCount} of ${customer.creditCount} times (${customer.repaymentRate.toStringAsFixed(0)}% repaid)'
                        : 'No prior credit history',
                    style: const TextStyle(
                      color: Color(0xFF4A443F),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        customer.score >= 75
                            ? Icons.check_circle_outline
                            : (customer.score >= 50
                                ? Icons.schedule
                                : Icons.warning_amber_rounded),
                        size: 13,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Repayment chance: ${customer.paymentProbabilityLabel}',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showActionDialog(
                          context,
                          'Give Credit',
                          customer,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'Give Credit',
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showActionDialog(
                          context,
                          'Record Payment',
                          customer,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'Record Payment',
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showCustomerScoreDialog(
                          context,
                          customer,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFCCC4BC),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insights,
                                size: 11,
                                color: Color(0xFF6C625C),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Score Details',
                                style: TextStyle(
                                  color: Color(0xFF6C625C),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerScoreDialog(
    BuildContext context,
    KhataCustomer customer,
  ) {
    final backgroundColor = color.withValues(alpha: 0.1);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.analytics_outlined, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    customer.trustLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trust & Credit Score',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6C625C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${customer.score} / 100',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Repayment Likelihood',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6C625C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.paymentProbabilityLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Debt & Repayment History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _MetricRow(
                      label: 'Current Balance',
                      value: '₹${customer.balance.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                    const Divider(height: 12),
                    _MetricRow(
                      label: 'Total Credit Taken',
                      value: '₹${customer.totalCredit.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 4),
                    _MetricRow(
                      label: 'Total Debt Repaid',
                      value: '₹${customer.totalPaid.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 4),
                    _MetricRow(
                      label: 'Debt Repaid Frequency',
                      value: '${customer.paymentCount} payments / ${customer.creditCount} credits',
                    ),
                    const SizedBox(height: 4),
                    _MetricRow(
                      label: 'Repayment Clearance Rate',
                      value: '${customer.repaymentRate.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
              if (customer.creditRecommendation.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Credit Recommendation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    customer.creditRecommendation,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (customer.reasons.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Scoring Factors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                ...customer.reasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            reason,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4A443F),
                            ),
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
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showActionDialog(
    BuildContext context,
    String action,
    KhataCustomer customer,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action for ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current balance: ₹${customer.balance.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            Text(
              'Trust Tier: ${customer.trustLabel} (${customer.score}/100)',
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              'Repayment Likelihood: ${customer.paymentProbabilityLabel}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C625C)),
            ),
            const SizedBox(height: 14),
            if (action == 'Give Credit') ...[
              const Text(
                'Credit recommendation:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                customer.creditRecommendation.isNotEmpty
                    ? customer.creditRecommendation
                    : (customer.score >= 75
                        ? '• Maximum credit: ₹5,000\n• Payment terms: 30 days\n• Auto-approval recommended'
                        : (customer.score >= 50
                            ? '• Maximum credit: ₹1,500\n• Payment terms: 15 days\n• Requires shopkeeper review'
                            : '• High risk - cash only or micro-credit max ₹300')),
                style: const TextStyle(fontSize: 13),
              ),
            ] else ...[
              const Text(
                'Payment options:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                '• Full payment\n• Partial payment\n• Set payment reminder',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF6C625C),
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AiInsightsTabSection extends StatelessWidget {
  const _AiInsightsTabSection({
    required this.insights,
    this.restockAlerts = const [],
  });
  final List<KhataInsight> insights;
  final List<RestockAlert> restockAlerts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFB8490C),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Insights',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8490C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${insights.length}',
                    style: const TextStyle(
                      color: Color(0xFFB8490C),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (restockAlerts.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFB8490C),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          '${restockAlerts.where((a) => !a.isExpiry).length} need restock',
                          '${restockAlerts.where((a) => a.isExpiry).length} near expiry',
                        ].where((part) => !part.startsWith('0 ')).join(' · '),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFFB8490C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (insights.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'No insights yet. Keep using DukaanOS to build them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6C625C)),
                ),
              )
            else ...[
              // Show preview of first 2 insights
              ...insights
                  .take(2)
                  .map(
                    (insight) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F3EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _getInsightIcon(insight.title),
                            color: const Color(0xFFB8490C),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  insight.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  insight.message,
                                  style: const TextStyle(
                                    color: Color(0xFF6C625C),
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (insights.length > 2)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${insights.length - 2} more insights',
                    style: const TextStyle(
                      color: Color(0xFF6C625C),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _navigateToInsightsScreen(context),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View All Insights'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB8490C),
                  side: const BorderSide(color: Color(0xFFB8490C)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getInsightIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('sales') || lowerTitle.contains('revenue')) {
      return Icons.trending_up;
    } else if (lowerTitle.contains('stock') ||
        lowerTitle.contains('inventory')) {
      return Icons.inventory;
    } else if (lowerTitle.contains('customer') ||
        lowerTitle.contains('payment')) {
      return Icons.people;
    } else if (lowerTitle.contains('profit') || lowerTitle.contains('loss')) {
      return Icons.account_balance;
    }
    return Icons.lightbulb;
  }

  void _navigateToInsightsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiInsightsScreen(
          insights: insights,
          restockAlerts: restockAlerts,
        ),
      ),
    );
  }
}
