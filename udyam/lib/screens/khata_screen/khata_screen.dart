import 'package:flutter/material.dart';

import '../../services/foreground_speech_service.dart';
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
      if (mounted) setState(() => _dashboard = dashboard);
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
        const _SectionTitle('AI insights'),
        const SizedBox(height: 8),
        if (dashboard.insights.isEmpty)
          const _EmptyCard(
            'No insights yet. Keep using DukaanOS to build them.',
          )
        else
          ...dashboard.insights.map(
            (insight) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFB8490C),
                ),
                title: Text(insight.title),
                subtitle: Text(insight.message),
              ),
            ),
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
