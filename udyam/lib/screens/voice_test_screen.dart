import 'package:flutter/material.dart';
import '../services/foreground_speech_service.dart';

class VoiceTestScreen extends StatefulWidget {
  const VoiceTestScreen({super.key});

  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  final ForegroundSpeechService _voice = ForegroundSpeechService.instance;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _voice.addListener(_onVoiceUpdate);
    _log('Voice test screen initialized');
  }

  @override
  void dispose() {
    _voice.removeListener(_onVoiceUpdate);
    super.dispose();
  }

  void _onVoiceUpdate() {
    if (mounted) {
      setState(() {});
      _log('Voice status changed: ${_voice.status} - ${_voice.statusDetail ?? "No details"}');
    }
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString().split('.').first;
    setState(() {
      _logs.add('[$timestamp] $message');
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Status: ${_voice.status}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Consent Granted: ${_voice.consentGranted}'),
                    Text('Is Paused: ${_voice.isPaused}'),
                    if (_voice.statusDetail != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Details: ${_voice.statusDetail}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            _log('Enabling voice consent...');
                            await _voice.setConsent(true);
                          },
                          child: const Text('Enable Voice'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            _log('Disabling voice consent...');
                            await _voice.setConsent(false);
                          },
                          child: const Text('Disable Voice'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            _log('Initializing voice service...');
                            await _voice.initialize();
                          },
                          child: const Text('Initialize'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Debug Logs:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}