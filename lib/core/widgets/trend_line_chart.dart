import 'package:flutter/material.dart';

import '../../theme.dart';
import '../theme/app_spacing.dart';

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({required this.values, super.key});

  final List<double> values;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSpace.profileTrendChartHeight,
    width: double.infinity,
    child: CustomPaint(painter: _TrendLinePainter(values)),
  );
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);
    final range = maximum - minimum;
    final points = <Offset>[
      for (var index = 0; index < values.length; index++)
        Offset(
          values.length == 1 ? size.width / 2 : size.width * index / (values.length - 1),
          range == 0
              ? size.height / 2
              : size.height - (values[index] - minimum) / range * size.height,
        ),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.forest
        ..strokeWidth = AppSpace.profileTrendLineWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      points.last,
      AppSpace.profileTrendEndDotRadius,
      Paint()..color = AppColors.forest,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      oldDelegate.values != values;
}
