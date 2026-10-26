import 'package:flutter/material.dart';

import '../../data/models/usage_data.dart';
import '../../theme.dart';
import '../strings.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class HoursBarChart extends StatefulWidget {
  const HoursBarChart({
    required this.values,
    required this.showThirtyDays,
    super.key,
    this.onValueSelected,
  });

  final List<DailyUsageHours> values;
  final bool showThirtyDays;
  final ValueChanged<String>? onValueSelected;

  @override
  State<HoursBarChart> createState() => _HoursBarChartState();
}

class _HoursBarChartState extends State<HoursBarChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant HoursBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) _selectedIndex = null;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppStrings.profileHoursChartDescription,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedIndex case final index?)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s4),
            child: Semantics(
              liveRegion: true,
              label: _tooltipText(widget.values[index]),
              child: Text(
                _tooltipText(widget.values[index]),
                style: AppTheme.body(
                  size: AppSpace.profileChartCaptionSize,
                  color: AppColors.ink,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ),
        TweenAnimationBuilder<double>(
          key: ValueKey(widget.showThirtyDays),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(
            milliseconds: AppSpace.profileBarSwitchDurationMs,
          ),
          builder: (context, animationValue, child) => SizedBox(
            height: AppSpace.profileBarChartHeight,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  if (widget.values.isEmpty) return;
                  final index = _indexAt(
                    details.localPosition.dx,
                    constraints.maxWidth,
                  );
                  setState(() => _selectedIndex = index);
                  final tooltip = _tooltipText(widget.values[index]);
                  widget.onValueSelected?.call(tooltip);
                },
                child: CustomPaint(
                  painter: _HoursBarPainter(
                    values: widget.values,
                    showThirtyDays: widget.showThirtyDays,
                    selectedIndex: _selectedIndex,
                    animationValue: animationValue,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  int _indexAt(double dx, double width) {
    if (widget.showThirtyDays) {
      return (dx / width * widget.values.length)
          .floor()
          .clamp(0, widget.values.length - 1);
    }
    final slotWidth = AppSpace.profileWeeklyBarWidth +
        AppSpace.profileWeeklyBarGap;
    final chartWidth =
        slotWidth * widget.values.length - AppSpace.profileWeeklyBarGap;
    final leftInset = (width - chartWidth) / 2;
    return ((dx - leftInset) / slotWidth)
        .floor()
        .clamp(0, widget.values.length - 1);
  }

  String _tooltipText(DailyUsageHours usage) =>
      '${usage.tooltipLabel ?? usage.dayLabel}: '
      '${usage.value.toStringAsFixed(1)} h';
}

class _HoursBarPainter extends CustomPainter {
  const _HoursBarPainter({
    required this.values,
    required this.showThirtyDays,
    required this.selectedIndex,
    required this.animationValue,
  });

  final List<DailyUsageHours> values;
  final bool showThirtyDays;
  final int? selectedIndex;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final captionStyle = AppTheme.body(
      size: AppSpace.profileChartCaptionSize,
      color: AppColors.inkMuted,
    );
    final todayStyle = AppTheme.body(
      size: AppSpace.profileChartCaptionSize,
      color: AppColors.ink,
      weight: FontWeight.w700,
    );
    final maxValue = values.fold<double>(
      1,
      (maximum, item) => item.value > maximum ? item.value : maximum,
    );
    final labelHeight = AppSpace.profileChartLabelHeight;
    final dayLabelHeight = AppSpace.profileDayLabelHeight;
    final baseline = size.height - dayLabelHeight;
    final chartTop = labelHeight;
    final availableBarHeight = baseline - chartTop;
    final slotWidth = showThirtyDays
        ? size.width / values.length
        : AppSpace.profileWeeklyBarWidth + AppSpace.profileWeeklyBarGap;
    final weeklyWidth = slotWidth * values.length -
        AppSpace.profileWeeklyBarGap;
    final leftInset = showThirtyDays ? 0 : (size.width - weeklyWidth) / 2;
    final barWidth = showThirtyDays
        ? (slotWidth * AppSpace.profileMonthlyBarWidthFraction)
        : AppSpace.profileWeeklyBarWidth;
    final baselinePaint = Paint()
      ..color = AppColors.rule
      ..strokeWidth = AppSpace.hairline;
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      baselinePaint,
    );
    for (var index = 0; index < values.length; index++) {
      final usage = values[index];
      final centerX = showThirtyDays
          ? slotWidth * (index + .5)
          : leftInset + slotWidth * index + AppSpace.profileWeeklyBarWidth / 2;
      final barHeight = availableBarHeight * usage.value / maxValue * animationValue;
      final barTop = baseline - barHeight;
      final barPaint = Paint()
        ..color = usage.isToday ? AppColors.forest : AppColors.forestTint;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(centerX - barWidth / 2, barTop, barWidth, barHeight),
          topLeft: const Radius.circular(AppRadius.small / 2),
          topRight: const Radius.circular(AppRadius.small / 2),
        ),
        barPaint,
      );

      final showValue = !showThirtyDays || index % 5 == 4 || usage.isToday;
      if (showValue) {
        _drawCenteredText(
          canvas,
          usage.value.toStringAsFixed(1),
          usage.isToday ? todayStyle : captionStyle,
          Offset(centerX, (barTop - AppSpace.profileValueLabelGap).clamp(0, baseline)),
        );
      }
      if (!showThirtyDays) {
        _drawCenteredText(
          canvas,
          usage.dayLabel,
          captionStyle,
          Offset(centerX, baseline + AppSpace.profileDayLabelGap),
        );
      } else if (index % 5 == 4 || index == values.length - 1) {
        _drawCenteredText(
          canvas,
          usage.dayLabel,
          captionStyle,
          Offset(centerX, baseline + AppSpace.profileDayLabelGap),
        );
      }
      if (selectedIndex == index) {
        final selectionPaint = Paint()
          ..color = AppColors.ink
          ..strokeWidth = AppSpace.hairline;
        canvas.drawLine(
          Offset(centerX, chartTop),
          Offset(centerX, baseline),
          selectionPaint,
        );
      }
    }
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset center,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _HoursBarPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.showThirtyDays != showThirtyDays ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.animationValue != animationValue;
}
