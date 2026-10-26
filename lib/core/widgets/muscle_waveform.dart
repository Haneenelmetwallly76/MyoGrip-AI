import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme.dart';

class MuscleWaveform extends StatefulWidget {
  const MuscleWaveform({
    required this.active,
    this.paused = false,
    this.seed = 1,
    super.key,
  });

  final bool active;
  final bool paused;
  final int seed;

  @override
  State<MuscleWaveform> createState() => _MuscleWaveformState();
}

class _MuscleWaveformState extends State<MuscleWaveform>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  Duration _lastPaint = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (elapsed - _lastPaint < const Duration(milliseconds: 33)) return;
      _lastPaint = elapsed;
      setState(() => _elapsed = elapsed);
    });
    _updateTicker();
  }

  @override
  void didUpdateWidget(covariant MuscleWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTicker();
  }

  void _updateTicker() {
    if (widget.paused) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: widget.paused
        ? 'Muscle signal waveform, paused'
        : 'Live muscle signal waveform',
    child: SizedBox(
      height: 90,
      width: double.infinity,
      child: CustomPaint(
        painter: _MuscleWavePainter(
          phase: _elapsed.inMicroseconds / Duration.microsecondsPerSecond,
          active: widget.active,
          seed: widget.seed,
          paused: widget.paused,
        ),
      ),
    ),
  );
}

class _MuscleWavePainter extends CustomPainter {
  const _MuscleWavePainter({
    required this.phase,
    required this.active,
    required this.seed,
    required this.paused,
  });

  final double phase;
  final bool active;
  final int seed;
  final bool paused;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height / 2;
    final alpha = paused ? .4 : 1.0;
    final baselinePaint = Paint()
      ..color = AppColors.rule.withValues(alpha: alpha)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      baselinePaint,
    );

    final path = Path();
    const samples = 180;
    for (var index = 0; index <= samples; index++) {
      final x = size.width * index / samples;
      final t = index / samples * math.pi * 16;
      final noise = math.sin(t * 1.73 + seed * 2.3) * .45 +
          math.sin(t * 3.11 + seed * 4.1) * .3 +
          math.sin(t * 5.9 + seed) * .15;
      final burst = active ? .72 + .28 * math.sin(t * .24 + phase * 2) : .18;
      final y =
          baseline -
          math.sin(t + phase * (paused ? 0 : 7) + seed) *
              (size.height * .38 * burst * noise);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.forest.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MuscleWavePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.active != active ||
      oldDelegate.seed != seed ||
      oldDelegate.paused != paused;
}
