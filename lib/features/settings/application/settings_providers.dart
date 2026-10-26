import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => FakeSettingsRepository(),
);
