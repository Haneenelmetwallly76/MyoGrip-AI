import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../theme.dart';
import '../../../widgets.dart';

class SendReportSheet extends StatefulWidget {
  const SendReportSheet({
    required this.clinicianName,
    required this.repository,
    required this.onSent,
    super.key,
  });

  final String clinicianName;
  final ReportRepository repository;
  final VoidCallback onSent;

  @override
  State<SendReportSheet> createState() => _SendReportSheetState();
}

class _SendReportSheetState extends State<SendReportSheet> {
  bool _sending = false;
  String? _error;

  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.repository.sendReport(
        clinicianName: widget.clinicianName,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSent();
    } on Object catch (error, stackTrace) {
      debugPrint('Could not send report: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _sending = false;
          _error = AppStrings.profileReportFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    label: AppStrings.profileReportTitle,
    title: AppStrings.profileReportTitle,
    primaryLabel: AppStrings.profileReportConfirm,
    onPrimary: _send,
    primaryBusy: _sending,
    primaryEnabled: !_sending,
    secondaryLabel: AppStrings.profileReportCancel,
    secondaryAsLink: true,
    onSecondary: () => Navigator.of(context).pop(),
    content: Padding(
      padding: const EdgeInsets.only(top: AppSpace.appSheetContentGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.profileReportClinician}: ${widget.clinicianName}',
            style: AppTheme.body(),
          ),
          const SizedBox(height: AppSpace.s8),
          Text(AppStrings.profileReportPeriod, style: AppTheme.caption),
          const SizedBox(height: AppSpace.s16),
          for (final item in const [
            AppStrings.profileReportUsageHours,
            AppStrings.profileReportGripTrend,
            AppStrings.profileReportErrors,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s8),
              child: Text(item, style: AppTheme.body()),
            ),
          if (_error != null) ...[
            const SizedBox(height: AppSpace.s8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: AppTheme.body(
                      size: AppSpace.profileCaptionSize,
                      color: AppColors.clay,
                    ),
                  ),
                ),
                AppLink(AppStrings.loginRetry, onTap: _send),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
