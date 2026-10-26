import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../theme.dart';

class StepProgress extends StatelessWidget {
  const StepProgress({
    required this.total,
    required this.current,
    super.key,
  }) : assert(total > 0),
       assert(current > 0 && current <= total);

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      total,
      (index) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: index == total - 1 ? 0 : AppSpace.s8,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: ColoredBox(
              color: index < current ? AppColors.forest : AppColors.rule,
              child: const SizedBox(height: AppSpace.progressHeight),
            ),
          ),
        ),
      ),
    ),
  );
}
