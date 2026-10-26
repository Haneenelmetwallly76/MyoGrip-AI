import 'dart:math' as math;

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/strings.dart';
import 'core/theme/app_radius.dart';
import 'core/theme/app_spacing.dart';
import 'theme.dart';

class Rule extends StatelessWidget {
  const Rule({
    super.key,
    this.margin = const EdgeInsets.symmetric(vertical: 18),
  });
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: const Divider(height: 1, thickness: 1, color: AppColors.rule),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.semanticsLabel,
    this.height = AppSpace.buttonHeight,
    this.busy = false,
    this.background = AppColors.forest,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? semanticsLabel;
  final double height;
  final bool busy;
  final Color background;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticsLabel ?? label,
    onTap: onPressed,
    enabled: onPressed != null,
    excludeSemantics: true,
    child: SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: background.withValues(alpha: .65),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              height == AppSpace.homeStopHeight
                  ? AppRadius.stopButton
                  : AppRadius.medium,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: busy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      child: SizedBox(width: 20, height: 20, child: icon),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                        size: height == AppSpace.homeStopHeight ? 18 : 16,
                        color: AppColors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.busy = false,
    this.height = AppSpace.buttonHeight,
    this.fontSize = 16,
    this.horizontalPadding,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final double height;
  final double fontSize;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    onTap: onPressed,
    enabled: onPressed != null,
    excludeSemantics: true,
    child: SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          side: const BorderSide(color: AppColors.forest, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          padding: horizontalPadding == null
              ? null
              : EdgeInsets.symmetric(horizontal: horizontalPadding!),
        ),
        child: busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.forest,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: AppTheme.body(
                  size: fontSize,
                  color: AppColors.forest,
                  weight: FontWeight.w700,
                ),
              ),
      ),
    ),
  );
}

class AppLink extends StatelessWidget {
  const AppLink(
    this.label, {
    required this.onTap,
    super.key,
    this.semanticsLabel,
  });
  final String label;
  final VoidCallback onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticsLabel ?? label,
    onTap: onTap,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      excludeFromSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          style: AppTheme.body(
            color: AppColors.forest,
            weight: FontWeight.w600,
          ).copyWith(decoration: TextDecoration.underline),
        ),
      ),
    ),
  );
}

class UnderlineField extends StatefulWidget {
  const UnderlineField({
    required this.label,
    required this.controller,
    super.key,
    this.error,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.readOnly = false,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
    this.onBlur,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.helperText,
    this.bottomSpacing = 14,
    this.textColor = AppColors.ink,
  });
  final String label;
  final TextEditingController controller;
  final String? error;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool readOnly;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onBlur;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? helperText;
  final double bottomSpacing;
  final Color textColor;

  @override
  State<UnderlineField> createState() => _UnderlineFieldState();
}

class _UnderlineFieldState extends State<UnderlineField> {
  bool _showPassword = false;
  bool _focused = false;

  void _togglePassword() {
    setState(() => _showPassword = !_showPassword);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpace.fieldMinHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Text(
                    widget.label,
                    style: AppTheme.body(size: 12, color: AppColors.inkMuted),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Focus(
                        onFocusChange: (value) {
                          setState(() => _focused = value);
                          if (!value) widget.onBlur?.call();
                        },
                        child: Semantics(
                          label: widget.label,
                          textField: true,
                          child: TextField(
                            controller: widget.controller,
                            readOnly: widget.readOnly,
                            enabled: widget.enabled,
                            keyboardType: widget.keyboardType,
                            textInputAction: widget.textInputAction,
                            textCapitalization: widget.textCapitalization,
                            inputFormatters: widget.inputFormatters,
                            onSubmitted: widget.onSubmitted,
                            obscureText: widget.obscure && !_showPassword,
                            style: AppTheme.body(
                              size: 16,
                              color: widget.textColor,
                            ),
                            cursorColor: AppColors.forest,
                            decoration: InputDecoration(
                              hintText: widget.hint,
                              hintStyle: AppTheme.body(
                                size: 16,
                                color: AppColors.inkMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.obscure)
                      TextButton(
                        onPressed: widget.enabled ? _togglePassword : null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          _showPassword
                              ? AppStrings.loginHidePassword
                              : AppStrings.loginShowPassword,
                        ),
                      ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: SizedBox(
                    height: hasError || _focused ? 2 : 1,
                    child: ColoredBox(
                      color: hasError
                          ? AppColors.clay
                          : _focused
                          ? AppColors.forest
                          : AppColors.rule,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Text(
              widget.error!,
              style: AppTheme.body(size: 13, color: AppColors.clay),
            ),
          ],
          if (widget.helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.helperText!,
              style: AppTheme.body(
                size: AppSpace.onboardingCaptionSize,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SquareSwitch extends StatelessWidget {
  const SquareSwitch({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
    this.enabled = true,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: label,
    onTap: enabled ? () => onChanged(!value) : null,
    enabled: enabled,
    child: ExcludeSemantics(
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: enabled ? () => onChanged(!value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpace.minTouchTarget,
            minHeight: AppSpace.minTouchTarget,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Opacity(
              opacity: enabled ? 1 : .5,
              child: SizedBox(
              width: AppSpace.switchWidth,
              height: AppSpace.switchHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: value ? AppColors.forest : AppColors.rule,
                  borderRadius: BorderRadius.circular(AppSpace.switchRadius),
                ),
                child: AnimatedAlign(
                  duration: const Duration(
                    milliseconds: AppSpace.switchAnimationDurationMs,
                  ),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: AppSpace.switchThumb,
                    height: AppSpace.switchThumb,
                    margin: const EdgeInsets.all(AppSpace.switchInset),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.rule.withValues(alpha: .7),
                        width: .5,
                      ),
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class SegmentedThree extends StatelessWidget {
  const SegmentedThree({
    required this.value,
    required this.onChanged,
    super.key,
    this.options = const [
      AppStrings.settingsLow,
      AppStrings.settingsMedium,
      AppStrings.settingsHigh,
    ],
  });
  final int value;
  final ValueChanged<int> onChanged;
  final List<String> options;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: AppStrings.settingsSensitivity,
    child: SizedBox(
      height: AppSpace.minTouchTarget,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: AppSpace.segmentHeight,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.forest, width: 1.2),
              borderRadius: BorderRadius.circular(AppRadius.compactButton),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                children: List.generate(options.length, (index) {
                  final selected = value == index;
                  return Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.forest : AppColors.paper,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Text(
                        options[index],
                        style: AppTheme.body(
                          size: 15,
                          color: selected ? AppColors.white : AppColors.forest,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Row(
            children: List.generate(
              options.length,
              (index) => Expanded(
                child: Semantics(
                  selected: value == index,
                  checked: value == index,
                  inMutuallyExclusiveGroup: true,
                  label: options[index],
                  onTap: () => onChanged(index),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(index),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class StepBars extends StatelessWidget {
  const StepBars({required this.current, super.key});
  final int current;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      3,
      (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i == 2 ? 0 : AppSpace.s8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: ColoredBox(
              color: i < current ? AppColors.forest : AppColors.rule,
              child: const SizedBox(height: AppSpace.progressHeight),
            ),
          ),
        ),
      ),
    ),
  );
}

class MeterRow extends StatelessWidget {
  const MeterRow({required this.label, required this.value, super.key});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final color = value < 20 ? AppColors.clay : AppColors.forest;
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(label, style: AppTheme.body(size: 15))),
              Text('$value%', style: AppTheme.serif(24)),
            ],
          ),
          const SizedBox(height: 5),
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(height: 4, color: AppColors.rule),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    height: 4,
                    width: constraints.maxWidth * (value / 100).clamp(0, 1),
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BottomTabBar extends StatefulWidget {
  const BottomTabBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  State<BottomTabBar> createState() => _BottomTabBarState();
}

class _BottomTabBarState extends State<BottomTabBar> {
  late final NotchBottomBarController _controller;

  static const _labels = ['Home', 'Settings', 'Profile'];
  static const _icons = [
    (Icons.home_outlined, Icons.home_rounded),
    (Icons.tune_outlined, Icons.tune_rounded),
    (Icons.person_outline, Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _controller = NotchBottomBarController(index: widget.selected);
  }

  @override
  void didUpdateWidget(covariant BottomTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _controller.jumpTo(widget.selected);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    child: Stack(
      children: [
        AnimatedNotchBottomBar(
          notchBottomBarController: _controller,
          bottomBarItems: List.generate(
            _labels.length,
            (index) => BottomBarItem(
              inActiveItem: ExcludeSemantics(
                child: Icon(
                  _icons[index].$1,
                  color: AppColors.ink.withValues(alpha: .62),
                ),
              ),
              activeItem: ExcludeSemantics(
                child: Icon(
                  _icons[index].$2,
                  color: AppColors.white,
                ),
              ),
              itemLabel: _labels[index],
            ),
          ),
          onTap: widget.onSelected,
          color: const Color(0xFFFBF8F1),
          notchColor: AppColors.forest,
          showLabel: false,
          itemLabelStyle: AppTheme.body(
            size: 12,
            color: AppColors.ink,
            weight: FontWeight.w600,
          ),
          showShadow: false,
          elevation: 0,
          shadowElevation: 0,
          removeMargins: true,
          bottomBarWidth: 500,
          bottomBarHeight: AppSpace.tabBarHeight,
          durationInMilliSeconds: 250,
          kBottomRadius: 24,
          kIconSize: 24,
          textOverflow: TextOverflow.visible,
          maxLine: 1,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: Row(
            children: List.generate(_labels.length, (index) {
              final isSelected = index == widget.selected;
              final label =
                  '${_labels[index]} tab${isSelected ? ', selected' : ''}';
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: label,
                  onTap: () => widget.onSelected(index),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onSelected(index),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: ExcludeSemantics(
                          child: Text(
                            _labels[index],
                            style: AppTheme.body(
                              size: 12,
                              color: isSelected
                                  ? AppColors.ink
                                  : AppColors.ink.withValues(alpha: .62),
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    ),
  );
}

class HandDiagram extends StatelessWidget {
  const HandDiagram({super.key, required this.activeFingers});
  final List<bool> activeFingers;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(110, 170),
    painter: _HandPainter(activeFingers),
  );
}

class _HandPainter extends CustomPainter {
  _HandPainter(this.active);
  final List<bool> active;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 110;
    final sy = size.height / 170;
    canvas.save();
    canvas.scale(sx, sy);
    final outline = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final palmFill = Paint()
      ..color = AppColors.handFill
      ..style = PaintingStyle.fill;
    final fingerPaths = <Path>[
      Path()
        ..moveTo(33, 72)
        ..lineTo(28, 34)
        ..quadraticBezierTo(27, 27, 31, 27)
        ..quadraticBezierTo(36, 27, 37, 34)
        ..lineTo(43, 72)
        ..close(),
      Path()
        ..moveTo(43, 67)
        ..lineTo(41, 17)
        ..quadraticBezierTo(41, 9, 46, 9)
        ..quadraticBezierTo(51, 9, 51, 17)
        ..lineTo(53, 67)
        ..close(),
      Path()
        ..moveTo(53, 66)
        ..lineTo(54, 12)
        ..quadraticBezierTo(54, 4, 59, 4)
        ..quadraticBezierTo(64, 4, 64, 12)
        ..lineTo(64, 66)
        ..close(),
      Path()
        ..moveTo(64, 68)
        ..lineTo(67, 21)
        ..quadraticBezierTo(67, 14, 72, 14)
        ..quadraticBezierTo(77, 15, 76, 23)
        ..lineTo(73, 74)
        ..close(),
      Path()
        ..moveTo(33, 83)
        ..lineTo(20, 66)
        ..quadraticBezierTo(15, 60, 19, 56)
        ..quadraticBezierTo(23, 53, 27, 59)
        ..lineTo(42, 75)
        ..close(),
    ];
    final palm = Path()
      ..moveTo(34, 68)
      ..lineTo(72, 69)
      ..quadraticBezierTo(82, 70, 82, 81)
      ..lineTo(80, 114)
      ..quadraticBezierTo(79, 132, 63, 136)
      ..lineTo(41, 136)
      ..quadraticBezierTo(26, 133, 26, 117)
      ..lineTo(26, 85)
      ..quadraticBezierTo(26, 73, 34, 68)
      ..close();
    for (var i = 0; i < fingerPaths.length; i++) {
      canvas.drawPath(
        fingerPaths[i],
        Paint()
          ..color = i < active.length && active[i]
              ? AppColors.forest
              : AppColors.handFill,
      );
      canvas.drawPath(fingerPaths[i], outline);
      final joints = switch (i) {
        0 => [39.0, 44.0],
        1 => [47.0, 36.0],
        2 => [59.0, 32.0],
        3 => [71.0, 43.0],
        _ => [24.0, 65.0],
      };
      final jointPaint = Paint()
        ..color = AppColors.ink.withValues(alpha: .7)
        ..strokeWidth = 1;
      if (i < 4) {
        canvas.drawLine(
          Offset(joints[0] - 2, joints[1]),
          Offset(joints[0] + 3, joints[1]),
          jointPaint,
        );
        canvas.drawLine(
          Offset(joints[0] - 1, joints[1] + 13),
          Offset(joints[0] + 4, joints[1] + 13),
          jointPaint,
        );
      }
    }
    canvas.drawPath(palm, palmFill);
    canvas.drawPath(palm, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 134, 38, 9),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.forest,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 145, 34, 8),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.ink,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) =>
      !listEquals(oldDelegate.active, active);
}

class ImageOrPlaceholder extends StatelessWidget {
  const ImageOrPlaceholder({
    required this.asset,
    super.key,
    this.width,
    this.height,
    this.circular = false,
    this.blendWithPaper = false,
    this.fit = BoxFit.cover,
  });
  final String asset;
  final double? width;
  final double? height;
  final bool circular;
  final bool blendWithPaper;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = width == null || width!.isFinite
            ? width
            : constraints.maxWidth;
        final imageHeight = height == null || height!.isFinite
            ? height
            : constraints.maxHeight;
        Widget image = Image.asset(
          asset,
          width: imageWidth,
          height: imageHeight,
          fit: fit,
          errorBuilder: (_, _, _) => Container(
            width: imageWidth,
            height: imageHeight,
            color: AppColors.handFill,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.ink,
              size: 24,
            ),
          ),
        );
        if (blendWithPaper) {
          image = ColorFiltered(
            colorFilter: const ColorFilter.mode(
              AppColors.paper,
              BlendMode.multiply,
            ),
            child: image,
          );
        }
        if (circular) image = ClipOval(child: image);
        if (!circular) {
          image = ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: image,
          );
        }
        return image;
      },
    );
  }
}

class FadeAbove extends StatelessWidget {
  const FadeAbove({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      height: AppSpace.settingsFadeHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.paper, Color(0x00F5F1E8)],
        ),
      ),
    ),
  );
}

class GripChartPainter extends CustomPainter {
  GripChartPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.reduce(math.max);
    final usableHeight = size.height - 25;
    final gap = size.width / values.length;
    final barWidth = values.length > 10 ? math.max(2.0, gap * .55) : 22.0;
    final baseline = usableHeight;
    for (var i = 0; i < values.length; i++) {
      final height = usableHeight * values[i] / (maxValue * 1.18);
      final x = gap * i + (gap - barWidth) / 2;
      final color = values.length == 7 && i == 3
          ? AppColors.forest
          : AppColors.forest.withValues(alpha: .35);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, baseline - height, barWidth, height),
          topLeft: const Radius.circular(AppRadius.small / 2),
          topRight: const Radius.circular(AppRadius.small / 2),
        ),
        Paint()..color = color,
      );
      if (values.length == 7) {
        final text = TextPainter(
          text: TextSpan(
            text: values[i].toStringAsFixed(1),
            style: AppTheme.body(size: 11, color: AppColors.inkMuted),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(
          canvas,
          Offset(x + (barWidth - text.width) / 2, baseline - height - 16),
        );
        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        final day = TextPainter(
          text: TextSpan(
            text: days[i],
            style: AppTheme.body(size: 12, color: AppColors.inkMuted),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        day.paint(
          canvas,
          Offset(gap * i + (gap - day.width) / 2, baseline + 5),
        );
      }
    }
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()
        ..color = AppColors.rule
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant GripChartPainter oldDelegate) =>
      !listEquals(oldDelegate.values, values);
}

class StrengthChartPainter extends CustomPainter {
  const StrengthChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const count = 30;
    final points = List<Offset>.generate(count, (index) {
      final x = size.width * index / (count - 1);
      final progress = index / (count - 1);
      final wiggle = math.sin(index * .85) * 2.2 + math.sin(index * .27) * 1.4;
      final y = size.height * (.7 - .48 * progress) + wiggle;
      return Offset(x, y);
    });
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.forest
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(points.last, 3, Paint()..color = AppColors.forest);
  }

  @override
  bool shouldRepaint(covariant StrengthChartPainter oldDelegate) => false;
}
