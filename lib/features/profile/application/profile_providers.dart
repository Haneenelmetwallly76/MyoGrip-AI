import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/usage_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => FakeProfileRepository(),
);

final usageRepositoryProvider = Provider<UsageRepository>(
  (ref) => FakeUsageRepository(),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => FakeReportRepository(),
);
