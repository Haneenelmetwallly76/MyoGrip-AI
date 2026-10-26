class DailyUsageHours {
  const DailyUsageHours({
    required this.value,
    required this.dayLabel,
    required this.isToday,
    this.tooltipLabel,
  });

  final double value;
  final String dayLabel;
  final bool isToday;
  final String? tooltipLabel;
}

class UsageData {
  const UsageData({
    required this.weeklyHours,
    required this.monthlyHours,
    required this.gripTrend30d,
    required this.lastSyncedAt,
  });

  final List<DailyUsageHours> weeklyHours;
  final List<DailyUsageHours> monthlyHours;
  final List<double> gripTrend30d;
  final DateTime lastSyncedAt;

  bool get hasUsage => weeklyHours.isNotEmpty || monthlyHours.isNotEmpty;
}
