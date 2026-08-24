import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:google_mlkit_genai_speech_recognition/google_mlkit_genai_speech_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import 'session_store.dart';
import 'transcript_queue.dart';

enum VoiceCaptureStatus {
  disabled,
  paused,
  checking,
  listening,
  unavailable,
  permissionDenied,
  error,
}

class ForegroundSpeechService extends ChangeNotifier {
  ForegroundSpeechService({
    TranscriptQueue? queue,
    http.Client? client,
    SpeechRecognizer? recognizer,
    SpeechToText? fallbackRecognizer,
  }) : _queue = queue ?? SqliteTranscriptQueue(),
       _client = client ?? http.Client(),
       _recognizer = recognizer ?? SpeechRecognizer(),
       _fallbackRecognizer = fallbackRecognizer ?? SpeechToText();

  static final ForegroundSpeechService instance = ForegroundSpeechService();
  static const _consentKey = 'khata_voice_consent';

  final TranscriptQueue _queue;
  final http.Client _client;
  final SpeechRecognizer _recognizer;
  final SpeechToText _fallbackRecognizer;
  final EvolvingTranscript _buffer = EvolvingTranscript();

  StreamSubscription<String>? _subscription;
  Timer? _sealTimer;
  DateTime? _startedAt;
  bool _foreground = true;
  bool _onKhata = false;
  bool _manualPause = false;
  bool _initialized = false;
  bool _starting = false;
  bool _sending = false;
  bool _fallbackInitialized = false;
  bool _usingFallback = false;
  bool consentGranted = false;
  VoiceCaptureStatus status = VoiceCaptureStatus.disabled;
  String? statusDetail;

  bool get shouldListen =>
      consentGranted && _foreground && !_onKhata && !_manualPause;
  bool get isPaused => _manualPause;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final preferences = await SharedPreferences.getInstance();
    consentGranted = preferences.getBool(_consentKey) ?? false;
    status = consentGranted
        ? VoiceCaptureStatus.paused
        : VoiceCaptureStatus.disabled;
    notifyListeners();
    await _reconcile();
  }

  Future<void> setConsent(bool granted) async {
    consentGranted = granted;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_consentKey, granted);
    if (!granted) {
      await pause(seal: true);
      await clear();
      status = VoiceCaptureStatus.disabled;
    } else {
      _manualPause = false;
      await _reconcile();
    }
    notifyListeners();
  }

  Future<void> setManualPause(bool paused) async {
    _manualPause = paused;
    if (paused) {
      await pause(seal: true);
    } else {
      await _reconcile();
    }
    notifyListeners();
  }

  Future<void> setKhataActive(bool active) async {
    _onKhata = active;
    if (active) {
      await pause(seal: true);
      await retryPending();
    } else {
      await _reconcile();
    }
  }

  Future<void> setLifecycleState(AppLifecycleState state) async {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      await pause(seal: true);
    } else {
      await _reconcile();
    }
  }

  Future<void> _reconcile() async {
    if (shouldListen) {
      await start();
    } else if (status != VoiceCaptureStatus.disabled) {
      status = VoiceCaptureStatus.paused;
      notifyListeners();
    }
  }

  Future<void> start() async {
    if (!shouldListen || _subscription != null || _starting) return;
    _starting = true;
    status = VoiceCaptureStatus.checking;
    statusDetail = null;
    notifyListeners();
    try {
      if (!Platform.isAndroid) {
        status = VoiceCaptureStatus.unavailable;
        statusDetail = 'Voice intelligence currently requires Android.';
        return;
      }
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        status = VoiceCaptureStatus.permissionDenied;
        statusDetail = 'Microphone permission is required.';
        return;
      }
      final feature = await _recognizer.checkStatus();
      if (!feature.toString().endsWith('.available')) {
        await _startFallback();
        return;
      }
      _startedAt = DateTime.now().toUtc();
      _subscription = _recognizer.startRecognition().listen(
        _onPartial,
        onError: (Object error, StackTrace stack) {
          _subscription = null;
          unawaited(_startFallback(error));
        },
        onDone: () {
          _subscription = null;
          if (shouldListen) unawaited(_reconcile());
        },
      );
      status = VoiceCaptureStatus.listening;
    } catch (error) {
      await _startFallback(error);
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  Future<void> _startFallback([Object? mlKitError]) async {
    if (!shouldListen) return;
    _usingFallback = true;
    if (!_fallbackInitialized) {
      _fallbackInitialized = await _fallbackRecognizer.initialize(
        onStatus: (value) {
          if ((value == SpeechToText.doneStatus ||
                  value == SpeechToText.notListeningStatus) &&
              shouldListen &&
              _usingFallback) {
            Future<void>.delayed(
              const Duration(milliseconds: 300),
              _startFallback,
            );
          }
        },
        onError: (error) {
          status = VoiceCaptureStatus.error;
          statusDetail = 'On-device speech error: ${error.errorMsg}';
          notifyListeners();
        },
      );
    }
    if (!_fallbackInitialized) {
      status = VoiceCaptureStatus.unavailable;
      statusDetail = 'On-device speech recognition is not available.';
      notifyListeners();
      return;
    }
    if (_fallbackRecognizer.isListening) return;
    final locale = await _fallbackRecognizer.systemLocale();
    await _fallbackRecognizer.listen(
      onResult: (result) => _onPartial(result.recognizedWords),
      listenOptions: SpeechListenOptions(
        localeId: locale?.localeId,
        partialResults: true,
        onDevice: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(minutes: 5),
      ),
    );
    status = VoiceCaptureStatus.listening;
    statusDetail = mlKitError == null
        ? 'Using Android on-device speech recognition.'
        : 'ML Kit alpha is unavailable; using the on-device fallback.';
    notifyListeners();
  }

  void _onPartial(String partial) {
    if (!_buffer.add(partial)) return;
    _startedAt ??= DateTime.now().toUtc();
    _sealTimer?.cancel();
    _sealTimer = Timer(const Duration(milliseconds: 1400), seal);
  }

  Future<void> pause({required bool seal}) async {
    _sealTimer?.cancel();
    _sealTimer = null;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    try {
      await _recognizer.stopRecognition();
    } catch (_) {
      // Stopping an inactive/unsupported recognizer is harmless.
    }
    if (_usingFallback) {
      await _fallbackRecognizer.stop();
      _usingFallback = false;
    }
    if (seal) await this.seal();
    if (consentGranted) status = VoiceCaptureStatus.paused;
    notifyListeners();
  }

  Future<void> seal() async {
    if (_buffer.isEmpty) return;
    final endedAt = DateTime.now().toUtc();
    final transcript = _buffer.take();
    final startedAt = _startedAt ?? endedAt;
    _startedAt = null;
    const maxBatchCharacters = 19000;
    for (
      var offset = 0;
      offset < transcript.length;
      offset += maxBatchCharacters
    ) {
      final candidateEnd = offset + maxBatchCharacters;
      final end = candidateEnd < transcript.length
          ? candidateEnd
          : transcript.length;
      await _queue.enqueue(
        TranscriptBatch(
          batchId: const Uuid().v4(),
          transcript: transcript.substring(offset, end),
          startedAt: startedAt,
          endedAt: endedAt,
        ),
      );
    }
  }

  Future<void> retryPending() async {
    if (_sending) return;
    _sending = true;
    try {
      final token = await SessionStore.getAccessToken();
      if (token == null || token.isEmpty) return;
      for (final batch in await _queue.pending()) {
        try {
          final response = await _client
              .post(
                _uri(AppConstants.khataTranscriptAnalyze),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode(batch.toApiJson()),
              )
              .timeout(const Duration(seconds: 20));
          if (response.statusCode < 200 || response.statusCode >= 300) return;
          await _queue.delete(batch.batchId);
        } catch (_) {
          return;
        }
      }
    } finally {
      _sending = false;
    }
  }

  Future<void> clear() async {
    _sealTimer?.cancel();
    _buffer.take();
    _startedAt = null;
    await _queue.clear();
    notifyListeners();
  }

  Uri _uri(String path) {
    final base = AppConstants.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  @override
  void dispose() {
    _sealTimer?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_recognizer.close());
    unawaited(_fallbackRecognizer.cancel());
    unawaited(_queue.close());
    _client.close();
    super.dispose();
  }
}
