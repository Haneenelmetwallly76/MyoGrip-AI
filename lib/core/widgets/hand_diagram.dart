import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../data/gesture_map.dart';

class HandDiagram extends StatelessWidget {
  const HandDiagram({
    required this.activeFingers,
    this.dimmed = false,
    this.gestureIndex,
    super.key,
  });

  final Set<Finger> activeFingers;
  final bool dimmed;
  final int? gestureIndex;

  Set<int> get _activeIndices => {
    for (final finger in activeFingers)
      switch (finger) {
        Finger.thumb => 0,
        Finger.indexFinger => 1,
        Finger.middle => 2,
        Finger.ring => 3,
        Finger.little => 4,
      },
  };

  String get _semanticsLabel {
    final gesture = gestureIndex == null
        ? AppStrings.homeResting
        : '${AppStrings.homeGesture} $gestureIndex';
    final active = activeFingers.map(GestureMap.fingerLabel).toList();
    final fingers = active.isEmpty
        ? 'no fingers'
        : active.length == 1
        ? active.single
        : '${active.take(active.length - 1).join(', ')} and ${active.last}';
    return '${AppStrings.homeLiveGesture}: $gesture, fingers $fingers active';
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: _semanticsLabel,
    child: ExcludeSemantics(
      child: Opacity(
        opacity: dimmed ? .4 : 1,
        child: SizedBox(
          width: 110,
          height: 165,
          child: CustomPaint(painter: _HandPainter(_activeIndices)),
        ),
      ),
    ),
  );
}

class _HandPainter extends CustomPainter {
  const _HandPainter(this.active);

  final Set<int> active;
  static const _ink = Color(0xFF1E2421);
  static const _forest = Color(0xFF2E5B4E);
  static const _fill = Color(0xFFEDE5D0);

  @override
  void paint(Canvas c, Size s) {
    final k = math.min(s.width / 120, s.height / 180);
    c.translate((s.width - 120 * k) / 2, (s.height - 180 * k) / 2);
    c.scale(k);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _ink
      ..strokeJoin = StrokeJoin.round;

    void seg(Rect r, bool on, {double? radius}) {
      final rr = RRect.fromRectAndRadius(
        r,
        Radius.circular(radius ?? math.min(r.width / 2, 7)),
      );
      c.drawRRect(rr, Paint()..color = on ? _forest : _fill);
      c.drawRRect(rr, stroke);
    }

    c.save();
    c.translate(34, 126);
    c.rotate(-0.5);
    final thumbOn = active.contains(0);
    seg(const Rect.fromLTWH(-8.5, -24, 17, 24), thumbOn);
    seg(const Rect.fromLTWH(-8.5, -24 - 3 - 20, 17, 20), thumbOn);
    c.restore();

    const xs = [26.0, 43.7, 61.3, 79.0];
    const tops = [24.0, 16.0, 22.0, 34.0];
    const width = 15.0;
    for (var i = 0; i < 4; i++) {
      final on = active.contains(i + 1);
      final u = (80 - tops[i] - 6) / 10;
      var y = 80.0;
      for (final length in [u * 4.2, u * 3.0, u * 2.8]) {
        seg(Rect.fromLTWH(xs[i], y - length, width, length), on);
        y -= length + 3;
      }
    }

    seg(const Rect.fromLTWH(26, 84, 68, 56), false, radius: 16);
    seg(const Rect.fromLTWH(34, 148, 52, 10), false, radius: 3);
    seg(const Rect.fromLTWH(34, 162, 52, 10), false, radius: 3);
  }

  @override
  bool shouldRepaint(covariant _HandPainter old) =>
      old.active.length != active.length || !old.active.containsAll(active);
}
