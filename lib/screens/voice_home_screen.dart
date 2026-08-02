import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';
import '../widgets/orb.dart';

/// TAVO — Voice Home.
///
/// The screen the user actually lives in after onboarding. No dashboard, no
/// buttons, no message list — the orb sits at the center and TAVO opens the
/// conversation itself, exactly like [WelcomeScreen] but this is the ongoing
/// home, not a one-time flow.
///
/// Voice is simulated for now (same approach as onboarding): TAVO's lines
/// type out on a timer, and the user replies by tapping the mic pill (which
/// just cycles the orb through listening → thinking → speaking with a canned
/// reply). The real mic/STT/TTS hook plugs into [TavoOrb]'s `amplitude`
/// parameter and the `_sendReply` method below — nothing else here needs to
/// change when that lands.
class VoiceHomeScreen extends StatefulWidget {
  const VoiceHomeScreen({super.key, required this.userName});

  final String userName;

  @override
  State<VoiceHomeScreen> createState() => _VoiceHomeScreenState();
}

class _VoiceHomeScreenState extends State<VoiceHomeScreen> {
  OrbState _orb = OrbState.idle;
  String _shownLine = '';
  bool _canTalk = false;

  int _replyIndex = 0;
  late final List<String> _replies = [
    'أخبرني أكثر… أنا أستمع.',
    'هذا مثير للاهتمام. كيف تشعر حيال ذلك؟',
    'فهمت. هل تريد أن نتحدّث عن شيء آخر؟',
    'أنا هنا دائماً، خذ وقتك.',
  ];

  @override
  void initState() {
    super.initState();
    _speak(_openingLine());
  }

  String _openingLine() {
    final name = widget.userName.trim();
    return name.isEmpty
        ? 'سعيد بلقائك مجدداً. أخبرني عن نفسك.'
        : 'أهلاً $name. أخبرني عن نفسك.';
  }

  Future<void> _speak(String text) async {
    setState(() {
      _canTalk = false;
      _orb = OrbState.thinking;
      _shownLine = '';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _orb = OrbState.speaking);

    for (int i = 1; i <= text.length; i++) {
      if (!mounted) return;
      setState(() => _shownLine = text.substring(0, i));
      await Future.delayed(const Duration(milliseconds: 28));
    }
    if (!mounted) return;

    setState(() {
      _orb = OrbState.listening;
      _canTalk = true;
    });
  }

  Future<void> _sendReply() async {
    if (!_canTalk) return;
    setState(() => _canTalk = false);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final reply = _replies[_replyIndex % _replies.length];
    _replyIndex++;
    await _speak(reply);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TavoColors.voidBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            TavoOrb(state: _orb, size: 180),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    _shownLine,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: TavoType.arabic,
                      fontSize: 20,
                      height: 1.5,
                      color: TavoColors.text,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 3),
            _MicPill(enabled: _canTalk, onTap: _sendReply),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _MicPill extends StatelessWidget {
  const _MicPill({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: enabled ? TavoGradients.signature : null,
            color: enabled ? null : TavoColors.surface,
          ),
          child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}