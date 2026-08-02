import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/ai_service.dart';
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
  final stt.SpeechToText _speech = stt.SpeechToText();

  OrbState _orb = OrbState.idle;
  String _shownLine = '';
  String? _error;
  bool _speechReady = false;
  bool _busy = false;

  final List<Map<String, String>> _history = [];

  static const _silenceTimeout = Duration(seconds: 9);
  Timer? _silenceTimer;

  bool _userInterrupted = false;
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
      final line = await _ai.openConversation();
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

  Future<void> _speak(String text) async {
    _silenceTimer?.cancel();
    _userInterrupted = false;
    setState(() {
      _orb = OrbState.speaking;
      _shownLine = '';
    });

    _startListening();

    for (int i = 1; i <= text.length; i++) {
      if (!mounted || _userInterrupted) break;
      setState(() => _shownLine = text.substring(0, i));
      await Future.delayed(const Duration(milliseconds: 24));
    }
    if (!mounted) return;

    if (!_userInterrupted) {
      _history.add({'role': 'assistant', 'content': text});
      setState(() => _orb = OrbState.listening);
      _armSilenceTimer();
    }
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
        pauseFor: const Duration(seconds: 2, milliseconds: 500),
        localeId: 'ar-SA',
        partialResults: true,
        cancelOnError: true,
      );
    } catch (_) {}
  }

  // Tracks whether the utterance we're about to send actually cut TAVO off
  // mid-sentence — that's what makes it a real interruption, not just a
  // normal reply given during idle listening.
  bool _pendingIsInterruption = false;

  void _onSpeechResult(dynamic result) {
    final words = (result.recognizedWords as String).trim();
    if (words.isNotEmpty) _lastWords = words;

    if (_orb == OrbState.speaking && words.length > 2) {
      if (!_userInterrupted) _pendingIsInterruption = true;
      _userInterrupted = true;
    }

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
      Future.delayed(const Duration(milliseconds: 300), _startListening);
    }
  }

  Future<void> _onFinalSpeech(String text) async {
    if (_busy) return;
    _busy = true;
    _speech.stop();

    final wasInterruption = _pendingIsInterruption;
    _pendingIsInterruption = false;

    setState(() {
      _orb = OrbState.thinking;
      _error = null;
    });

    try {
      final reply = await _ai.reply(
        text,
        history: _history,
        wasInterruption: wasInterruption,
      );
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