import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme/app_spacing.dart';
import '../../theme.dart';
import '../../widgets.dart';

class NumberedRuleListItem {
  const NumberedRuleListItem({required this.number, required this.text});

  final String number;
  final String text;
}

class NumberedRuleList extends StatelessWidget {
  const NumberedRuleList({
    required this.items,
    super.key,
  });

  final List<NumberedRuleListItem> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index <= items.length; index++) ...[
        const Rule(margin: EdgeInsets.zero),
        if (index < items.length) _NumberedRuleListRow(
          item: items[index],
          position: index + 1,
          total: items.length,
        ),
      ],
    ],
  );
}

class _NumberedRuleListRow extends StatelessWidget {
  const _NumberedRuleListRow({
    required this.item,
    required this.position,
    required this.total,
  });

  final NumberedRuleListItem item;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: AppStrings.onboardingTipSemantics(position, total, item.text),
    child: ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpace.onboardingChecklistRowMinHeight,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: AppSpace.onboardingChecklistNumberColumnWidth,
              child: Text(
                item.number,
                style: AppTheme.serif(
                  AppSpace.onboardingChecklistNumberSize,
                  weight: FontWeight.w600,
                ).copyWith(color: AppColors.inkMuted),
              ),
            ),
            Expanded(
              child: Text(
                item.text,
                style: AppTheme.body(
                  size: AppSpace.onboardingChecklistTextSize,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
