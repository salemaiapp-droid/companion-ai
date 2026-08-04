import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/ai_service.dart';
import '../services/tts_service.dart';
import '../services/ai/voice_director.dart';
import '../theme/brand_tokens.dart';
import '../widgets/orb.dart';

class VoiceHomeScreen extends StatefulWidget {
  const VoiceHomeScreen({super.key, required this.userName});

  final String userName;

  @override
  State<VoiceHomeScreen> createState() => _VoiceHomeScreenState();
}

class _VoiceHomeScreenState extends State<VoiceHomeScreen> {
  final AiService _ai = AiService();
  final TtsService _tts = TtsService();
  final VoiceDirector _voice = VoiceDirector();
  final AudioPlayer _player = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();

  OrbState _orb = OrbState.idle;
  String _shownLine = '';
  String? _error;
  bool _speechReady = false;
  bool _busy = false;

  final List<Map<String, String>> _history = [];

  static const _silenceTimeout = Duration(seconds: 2);
  Timer? _silenceTimer;

  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speech.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _speechReady = await _speech.initialize(
      onError: (_) {},
      onStatus: _onSpeechStatus,
    );
    if (!mounted) return;
    if (!_speechReady) {
      setState(() {
        _error = 'يحتاج المتصفّح إذن الميكروفون. اسمح بالوصول ثم أعد تحميل الصفحة.';
      });
    }
    await _openConversation();
  }

  Future<void> _openConversation() async {
    setState(() {
      _orb = OrbState.thinking;
      _error = null;
    });
    try {
      final hour = DateTime.now().hour;
      final greeting = (hour >= 4 && hour < 12) ? 'صباح الخير' : 'مساء الخير';
      final line = await _ai.openConversation(timeGreeting: greeting);
      if (!mounted) return;
      await _speak(line);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر بدء المحادثة. تحقّق من الاتصال أو المفتاح.';
        _orb = OrbState.idle;
      });
    }
  }

  /// Mic stays OFF for the whole time TAVO's audio is playing. This isn't
  /// about acoustic echo (confirmed false — headphones + silence still
  /// produced noise) — it's the browser's mic-capture and audio-playback
  /// subsystems genuinely contending for resources when both run at once,
  /// which shows up as static/glitching. Mic turns back on the instant
  /// playback ends, so the user can jump in freely in that gap.
  Future<void> _speak(String rawText) async {
    final text = _voice.prepare(rawText);

    _silenceTimer?.cancel();
    _speech.stop();
    setState(() {
      _orb = OrbState.speaking;
      _shownLine = text;
    });

    Duration estimate = Duration(milliseconds: (text.length * 55).clamp(1200, 30000));
    bool audioOk = false;
    try {
      final bytes = await _tts.synthesize(text);
      if (!mounted) return;
      await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
      audioOk = true;
    } catch (_) {}

    bool completed = false;
    StreamSubscription? sub;
    if (audioOk) {
      sub = _player.onPlayerComplete.listen((_) => completed = true);
    }

    final deadline = DateTime.now().add(estimate + const Duration(seconds: 4));
    while (mounted && !completed && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    await sub?.cancel();
    if (!mounted) return;

    _history.add({'role': 'assistant', 'content': text});
    setState(() => _orb = OrbState.listening);
    _startListening(); // mic turns on only NOW, after audio has fully stopped
    _armSilenceTimer();
  }

  void _armSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(_silenceTimeout, _continueOnSilence);
  }

  Future<void> _continueOnSilence() async {
    if (!mounted || _busy) return;
    _busy = true;
    setState(() => _orb = OrbState.thinking);
    try {
      final line = await _ai.continueTalking(history: _history);
      if (!mounted) return;
      _busy = false;
      await _speak(line);
    } catch (e) {
      _busy = false;
      if (!mounted) return;
      _armSilenceTimer();
    }
  }

  void _startListening() {
    if (!_speechReady || _speech.isListening || _busy) return;
    try {
      _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 55),
        pauseFor: const Duration(seconds: 2),
        localeId: 'ar-SA',
        partialResults: true,
        cancelOnError: true,
      );
    } catch (_) {}
  }

  void _onSpeechResult(dynamic result) {
    final words = (result.recognizedWords as String).trim();
    if (words.isNotEmpty) _lastWords = words;

    if (result.finalResult == true && words.isNotEmpty) {
      _silenceTimer?.cancel();
      final captured = _lastWords;
      _lastWords = '';
      _onFinalSpeech(captured);
    }
  }

  void _onSpeechStatus(String status) {
    if ((status != 'done' && status != 'notListening') || _busy || !mounted) {
      return;
    }
    final captured = _lastWords.trim();
    if (captured.isNotEmpty) {
      _lastWords = '';
      _silenceTimer?.cancel();
      _onFinalSpeech(captured);
    } else {
      if (_orb == OrbState.listening) {
        Future.delayed(const Duration(milliseconds: 300), _startListening);
      }
    }
  }

  Future<void> _onFinalSpeech(String text) async {
    if (_busy) return;
    _busy = true;
    _speech.stop();

    setState(() {
      _orb = OrbState.thinking;
      _error = null;
    });

    try {
      final reply = await _ai.reply(text, history: _history);
      _history.add({'role': 'user', 'content': text});
      if (!mounted) return;
      _busy = false;
      await _speak(reply);
    } catch (e) {
      _busy = false;
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الوصول إلى TAVO الآن.';
        _orb = OrbState.idle;
      });
      _armSilenceTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TavoColors.voidBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TavoOrb(state: _orb, size: 200),
                        const SizedBox(height: 56),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _error ?? _shownLine,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: TavoType.arabic,
                              fontSize: 20,
                              height: 1.6,
                              color: _error != null ? Colors.redAccent : TavoColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}