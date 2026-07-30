import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';
import '../widgets/orb.dart';

/// TAVO — Splash screen.
///
/// The first 15 seconds must feel alive. Sequence:
///   1. Pure black. A small point of light appears at center.
///   2. The orb breathes and scales up gently (idle state).
///   3. A single pulse (thinking state) marks it coming to life.
///   4. The wordmark "TAVO" fades up beneath it, then the tagline.
///   5. After a beat, [onComplete] fires to move into the app.
///
/// [onComplete] is supplied by the caller so the splash never hard-codes the
/// next screen — point it at the welcome/onboarding flow once that exists.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
    this.showTagline = true,
  });

  final VoidCallback onComplete;
  final bool showTagline;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Master timeline (0 -> 1 across the whole intro).
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  // Orb scales in from a tiny point of light.
  late final Animation<double> _orbScale = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
  );

  // Wordmark fades + rises.
  late final Animation<double> _nameFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
  );

  // Tagline follows the name.
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.72, 0.95, curve: Curves.easeOut),
  );

  // A single "coming to life" pulse near the middle of the timeline.
  OrbState _orbState = OrbState.idle;

  @override
  void initState() {
    super.initState();

    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Hold a beat on the finished frame, then hand off.
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) widget.onComplete();
        });
      }
    });

    // Fire the pulse mid-way, then settle back to breathing.
    _c.addListener(() {
      if (_c.value >= 0.5 && _orbState == OrbState.idle) {
        setState(() => _orbState = OrbState.thinking);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _orbState = OrbState.idle);
        });
      }
    });

    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TavoColors.voidBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The orb, scaling in from a point of light.
            AnimatedBuilder(
              animation: _orbScale,
              builder: (context, child) {
                final s = 0.12 + _orbScale.value * 0.88; // point -> full
                return Opacity(
                  opacity: (_orbScale.value * 1.4).clamp(0.0, 1.0),
                  child: Transform.scale(scale: s, child: child),
                );
              },
              child: TavoOrb(state: _orbState, size: 180),
            ),

            const SizedBox(height: 40),

            // Wordmark.
            FadeTransition(
              opacity: _nameFade,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(_nameFade),
                child: Text(
                  'TAVO',
                  style: TextStyle(
                    fontFamily: TavoType.latin,
                    fontSize: 40,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 14,
                    color: TavoColors.text,
                  ),
                ),
              ),
            ),

            if (widget.showTagline) ...[
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  TavoBrand.taglineAr,
                  style: const TextStyle(
                    fontFamily: TavoType.arabic,
                    fontSize: 14,
                    color: TavoColors.muted,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
