import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_config.dart';

enum EmergencyStopState { ready, sending, stopped, failed }

final class EmergencyStopController extends Notifier<EmergencyStopState> {
  bool forceFailure = false;
  int _requestId = 0;

  @override
  EmergencyStopState build() => EmergencyStopState.ready;

  Future<void> stop() async {
    final requestId = ++_requestId;
    state = EmergencyStopState.sending;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (requestId != _requestId) return;
    state = forceFailure
        ? EmergencyStopState.failed
        : EmergencyStopState.stopped;
  }

  Future<void> resume() async {
    final requestId = ++_requestId;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (requestId == _requestId && AppConfig.resumeRestoresPreviousState) {
      // TODO: Confirm whether Resume should restore the pre-stop gesture state.
      state = EmergencyStopState.ready;
    }
  }
}
