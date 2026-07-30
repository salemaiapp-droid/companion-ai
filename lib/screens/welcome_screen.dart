import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';
import '../widgets/orb.dart';

/// TAVO — Welcome / onboarding.
///
/// Not a form with pages — a conversation. TAVO speaks first, then asks for
/// the name, language, and preferred tone, one step at a time. The orb drives
/// the emotion: it *thinks* between prompts, *speaks* while a line appears, and
/// *listens* while waiting for the user.
///
/// Voice is simulated for now: TAVO's lines type out on a timer, and the user
/// answers by typing (name) or tapping (language, tone). The mic/STT/TTS hook
/// comes later without reshaping this flow — [OrbState] transitions and the
/// step machine below are already the real structure.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onComplete});

  /// Called with the collected answers once onboarding finishes.
  final void Function(OnboardingResult result) onComplete;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

/// What onboarding collects.
class OnboardingResult {
  const OnboardingResult({
    required this.name,
    required this.language,
    required this.tone,
  });

  final String name;
  final TavoLanguage language;
  final TavoTone tone;
}

enum TavoLanguage { arabic, english }

enum TavoTone { formal, friend, coach }

enum _Step { greeting, askName, askLanguage, askTone, farewell }

class _WelcomeScreenState extends State<WelcomeScreen> {
  _Step _step = _Step.greeting;
  OrbState _orb = OrbState.idle;

  // TAVO's current spoken line (types out char by char).
  String _fullLine = '';
  String _shownLine = '';

  // Collected answers.
  String _name = '';
  TavoLanguage? _language;
  TavoTone? _tone;

  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _run(_Step.greeting);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Drive a step: TAVO thinks briefly, then speaks its line.
  Future<void> _run(_Step step) async {
    setState(() {
      _step = step;
      _orb = OrbState.thinking;
      _shownLine = '';
      _fullLine = _lineFor(step);
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _orb = OrbState.speaking);
    await _type(_fullLine);
    if (!mounted) return;

    // After speaking, wait for the user (listen), except on farewell.
    setState(() => _orb = step == _Step.farewell ? OrbState.idle : OrbState.listening);

    if (step == _Step.farewell) {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      widget.onComplete(OnboardingResult(
        name: _name,
        language: _language ?? TavoLanguage.arabic,
        tone: _tone ?? TavoTone.friend,
      ));
    }
  }

  String _lineFor(_Step step) {
    switch (step) {
      case _Step.greeting:
        return 'سعيد بلقائك. أنا TAVO.';
      case _Step.askName:
        return 'قبل أن نبدأ… بماذا أناديك؟';
      case _Step.askLanguage:
        return 'بأي لغة تفضّل أن نتحدّث؟';
      case _Step.askTone:
        return 'وكيف تحب أن أحدّثك؟';
      case _Step.farewell:
        final n = _name.isEmpty ? '' : ' يا $_name';
        return 'سعدتُ بك$n. لنبدأ.';
    }
  }

  /// Type a line out, char by char, ~28ms each.
  Future<void> _type(String text) async {
    for (int i = 1; i <= text.length; i++) {
      if (!mounted) return;
      setState(() => _shownLine = text.substring(0, i));
      await Future.delayed(const Duration(milliseconds: 28));
    }
  }

  void _submitName() {
    final value = _nameCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() => _name = value);
    FocusScope.of(context).unfocus();
    _run(_Step.askLanguage);
  }

  void _pickLanguage(TavoLanguage lang) {
    setState(() => _language = lang);
    _run(_Step.askTone);
  }

  void _pickTone(TavoTone tone) {
    setState(() => _tone = tone);
    _run(_Step.farewell);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TavoColors.voidBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              TavoOrb(state: _orb, size: 160),
              const SizedBox(height: 48),
              // TAVO's spoken line.
              SizedBox(
                height: 72,
                child: Center(
                  child: Text(
                    _shownLine,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: TavoType.arabic,
                      fontSize: 22,
                      height: 1.5,
                      color: TavoColors.text,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // The response control for the current step.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildResponse(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponse() {
    // Only show a control once TAVO has finished speaking the current prompt.
    final ready = _shownLine == _fullLine;
    if (!ready) return const SizedBox.shrink(key: ValueKey('empty'));

    switch (_step) {
      case _Step.askName:
        return Column(
          key: const ValueKey('name'),
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              textAlign: TextAlign.center,
              autofocus: true,
              onSubmitted: (_) => _submitName(),
              decoration: const InputDecoration(hintText: 'اكتب اسمك'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TavoGradientButton(label: 'متابعة', onPressed: _submitName),
            ),
          ],
        );

      case _Step.askLanguage:
        return Row(
          key: const ValueKey('lang'),
          children: [
            Expanded(
              child: _ChoiceButton(
                label: 'العربية',
                onTap: () => _pickLanguage(TavoLanguage.arabic),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceButton(
                label: 'English',
                onTap: () => _pickLanguage(TavoLanguage.english),
              ),
            ),
          ],
        );

      case _Step.askTone:
        return Column(
          key: const ValueKey('tone'),
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChoiceButton(label: 'رسمي', onTap: () => _pickTone(TavoTone.formal)),
            const SizedBox(height: 12),
            _ChoiceButton(label: 'صديق', onTap: () => _pickTone(TavoTone.friend)),
            const SizedBox(height: 12),
            _ChoiceButton(label: 'مدرّب', onTap: () => _pickTone(TavoTone.coach)),
          ],
        );

      case _Step.greeting:
      case _Step.farewell:
        return const SizedBox.shrink(key: ValueKey('none'));
    }
  }
}

/// A calm, full-width choice pill used for language and tone.
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(fontFamily: TavoType.arabic, fontSize: 16),
        ),
      ),
    );
  }
}
