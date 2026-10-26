import 'package:flutter/foundation.dart';

import '../models/usage_data.dart';

abstract interface class UsageRepository {
  Future<UsageData> getUsage();
}

final class FakeUsageRepository implements UsageRepository {
  FakeUsageRepository({
    this.matchMockup = true,
    this.empty = false,
    this.forceFailure = false,
    this.latency = const Duration(milliseconds: 300),
    DateTime? now,
  }) : _now = now ?? DateTime.now();

  /// TODO: Set this from actual device date data when the API is available.
  final bool matchMockup;
  final bool empty;
  bool forceFailure;
  final Duration latency;
  final DateTime _now;

  @override
  Future<UsageData> getUsage() async {
    await Future<void>.delayed(latency);
    if (forceFailure) throw StateError('Could not load usage data');
    final weekValues = const [2.5, 3.8, 3.1, 4.6, 2.2, 1.4, 3.9];
    final todayIndex = matchMockup ? 3 : (_now.weekday - 1);
    final weekly = List<DailyUsageHours>.generate(
      7,
      (index) => DailyUsageHours(
        value: weekValues[index],
        dayLabel: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
        isToday: index == todayIndex,
        tooltipLabel: const [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ][index],
      ),
    );
    final monthly = List<DailyUsageHours>.generate(
      30,
      (index) => DailyUsageHours(
        value: 1.1 + ((index * 17) % 39) / 10,
        dayLabel: '${index + 1}',
        isToday: index == 29,
        tooltipLabel: 'Day ${index + 1}',
      ),
    );
    final trend = List<double>.generate(
      30,
      (index) => 2.1 + index * .045 + ((index * 7) % 9) * .035,
    );
    return UsageData(
      weeklyHours: empty ? const [] : weekly,
      monthlyHours: empty ? const [] : monthly,
      gripTrend30d: empty ? const [] : trend,
      lastSyncedAt: DateTime(_now.year, _now.month, _now.day, 9, 40),
    );
  }

  @visibleForTesting
  static const mockupHighlightTodayIndex = 3;
}
