import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/arm_repository.dart';
import 'emergency_stop_controller.dart';

final armRepositoryProvider = Provider<ArmRepository>(
  (ref) => FakeArmRepository(),
);

final currentDateProvider = Provider<DateTime>((ref) => DateTime.now());

final emergencyStopControllerProvider =
    NotifierProvider<EmergencyStopController, EmergencyStopState>(
      EmergencyStopController.new,
    );
