import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme/app_spacing.dart';
import '../../theme.dart';

class StoppedNotice extends StatelessWidget {
  const StoppedNotice({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: AppStrings.homeStoppedAnnouncement,
    excludeSemantics: true,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpace.homeStoppedNoticeHeight,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: AppSpace.homeStoppedNoticeBarWidth,
              color: AppColors.stop,
            ),
            const SizedBox(width: AppSpace.homeStoppedNoticeGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.homeStopped,
                    style: AppTheme.body(
                      size: AppSpace.homeStoppedTitleSize,
                      color: AppColors.stop,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    AppStrings.homeStoppedDetail,
                    style: AppTheme.body(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
