import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';

/// The four expressive states of the TAVO orb.
enum OrbState { idle, listening, thinking, speaking }

/// TAVO — the living orb.
///
/// A voice-first presence rendered with a [CustomPainter]: an open cyan ring
/// around a purple core, wrapped in a soft glow. It breathes when [OrbState.idle],
/// ripples when [OrbState.listening], pulses when [OrbState.thinking], and moves
/// gently when [OrbState.speaking]. Transitions between states are eased, never
/// snapped, honouring the motion rule (every transition under 300ms).
///
/// Colors come entirely from [TavoColors]; nothing is hard-coded here.
///
/// Audio hook:
/// [amplitude] (0..1) drives the listening/speaking motion. Leave it null to use
/// the built-in preset motion (works immediately, no mic). Later, feed real
/// microphone amplitude in — no rebuild of this widget is needed.
class TavoOrb extends StatefulWidget {
  const TavoOrb({
    super.key,
    this.state = OrbState.idle,
    this.amplitude,
    this.size = 240,
  });

  final OrbState state;
  final double? amplitude;
  final double size;

  @override
  State<TavoOrb> createState() => _TavoOrbState();
}

class _TavoOrbState extends State<TavoOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 120))
        ..repeat();

  final _OrbModel _model = _OrbModel();
  double _lastValue = 0;

  @override
  void initState() {
    super.initState();
    // Start already settled into the initial state.
    _model
      ..idle = widget.state == OrbState.idle ? 1 : 0
      ..listening = widget.state == OrbState.listening ? 1 : 0
      ..thinking = widget.state == OrbState.thinking ? 1 : 0
      ..speaking = widget.state == OrbState.speaking ? 1 : 0;
    _c.addListener(_tick);
  }

  void _tick() {
    // Continuous seconds clock derived from the repeating controller.
    double v = _c.value;
    double dt = v - _lastValue;
    if (dt < 0) dt += 1;
    _lastValue = v;
    _model.t += dt * 120;

    // Ease the state mix (~6% per frame ≈ a soft <300ms settle).
    const k = 0.08;
    _model.idle = _lerp(_model.idle, widget.state == OrbState.idle ? 1 : 0, k);
    _model.listening =
        _lerp(_model.listening, widget.state == OrbState.listening ? 1 : 0, k);
    _model.thinking =
        _lerp(_model.thinking, widget.state == OrbState.thinking ? 1 : 0, k);
    _model.speaking =
        _lerp(_model.speaking, widget.state == OrbState.speaking ? 1 : 0, k);

    _model.amplitude = widget.amplitude;
  }

  static double _lerp(double a, double b, double k) => a + (b - a) * k;

  @override
  void dispose() {
    _c.removeListener(_tick);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _OrbPainter(_model, repaint: _c),
      ),
    );
  }
}

/// Mutable state shared with the painter, updated once per frame.
class _OrbModel {
  double t = 0;
  double idle = 1, listening = 0, thinking = 0, speaking = 0;
  double? amplitude;
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.m, {required Listenable repaint}) : super(repaint: repaint);

  final _OrbModel m;

  // Cheap layered sine "noise" — stands in for audio when amplitude is null.
  double _noise(double s) =>
      (math.sin(s * 1.7) + math.sin(s * 2.9 + 1.3) + math.sin(s * 0.7 + 2.1)) /
      3;

  @override
  void paint(Canvas canvas, Size size) {
    final t = m.t;
    final cx = size.width / 2, cy = size.height / 2;
    final center = Offset(cx, cy);
    final R = math.min(size.width, size.height) * 0.30;

    final breath = 0.5 + 0.5 * math.sin(t * 0.9);
    final pulse = math.pow(0.5 + 0.5 * math.sin(t * 3.4), 3).toDouble();
    final audio = m.amplitude; // 0..1 when driven by real mic
    final speak = audio ?? (0.5 + 0.5 * _noise(t * 3.0));
    final listen = audio ?? (0.5 + 0.5 * _noise(t * 6.0));

    final glowScale = 1 +
        m.idle * 0.06 * breath +
        m.thinking * 0.10 * pulse +
        m.speaking * 0.07 * speak +
        m.listening * 0.05 * listen;

    // ---- outer glow ----
    final glowR = R * 2.4 * glowScale;
    final glowExtra =
        m.thinking * 0.10 * pulse + m.speaking * 0.05 * speak;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          TavoColors.cyan.withValues(alpha: 0.10 + glowExtra),
          TavoColors.purple.withValues(alpha: 0.06 + glowExtra * 0.5),
          TavoColors.cyan.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowR));
    canvas.drawCircle(center, glowR, glowPaint);

    // ---- listening waveform ring ----
    if (m.listening > 0.01) {
      final path = Path();
      const n = 96;
      for (int i = 0; i <= n; i++) {
        final a = (i / n) * math.pi * 2;
        final wob = 1 + 0.18 * _noise(t * 6 + i * 0.5) * listen;
        final rr = R * 1.02 * wob;
        final x = cx + math.cos(a) * rr, y = cy + math.sin(a) * rr;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = TavoColors.cyan.withValues(alpha: 0.9 * m.listening),
      );
    }

    // ---- main open ring (gradient arc) ----
    final ringR = R * (1 + m.speaking * 0.04 * speak + m.idle * 0.02 * breath);
    final rot = t * 0.25 + m.thinking * t * 0.6;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rot);
    final arcRect = Rect.fromCircle(center: Offset.zero, radius: ringR);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.14
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [TavoColors.cyan, TavoColors.purple],
      ).createShader(arcRect);
    // Open arc with a gap (start 0.55 rad, sweep most of the circle).
    canvas.drawArc(arcRect, 0.55, math.pi * 2 - 0.7, false, ringPaint);
    canvas.restore();

    // ---- core ----
    final coreBase = R * 0.34;
    final core = coreBase *
        (1 +
            m.idle * 0.10 * breath +
            m.thinking * 0.28 * pulse +
            m.speaking * 0.18 * speak +
            m.listening * 0.10 * listen);
    canvas.drawCircle(
        center, core, Paint()..color = TavoColors.purple.withValues(alpha: 0.9));
    canvas.drawCircle(center, core * 0.55,
        Paint()..color = TavoColors.cyan.withValues(alpha: 0.95));
    canvas.drawCircle(
      center.translate(-core * 0.2, -core * 0.2),
      core * 0.18,
      Paint()..color = TavoColors.text.withValues(alpha: 0.9),
    );

    // ---- thinking: expanding concentric ring ----
    if (m.thinking > 0.01) {
      final p = (t * 0.8) % 1;
      canvas.drawCircle(
        center,
        R * 0.6 + p * R * 1.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = TavoColors.cyan.withValues(alpha: m.thinking * (1 - p) * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => true;
}
