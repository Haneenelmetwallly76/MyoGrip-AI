import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../data/models/arm_status.dart';
import '../../../data/repositories/arm_repository.dart';
import '../../../theme.dart';
import '../../../widgets.dart';

class ConnectionSheet extends StatefulWidget {
  const ConnectionSheet({
    required this.repository,
    required this.status,
    super.key,
  });

  final ArmRepository repository;
  final ArmStatus? status;

  @override
  State<ConnectionSheet> createState() => _ConnectionSheetState();
}

class _ConnectionSheetState extends State<ConnectionSheet> {
  bool _armBusy = false;
  bool _armbandBusy = false;

  Future<void> _reconnect({required bool armband}) async {
    final isBusy = armband ? _armbandBusy : _armBusy;
    if (isBusy) return;
    setState(() {
      if (armband) {
        _armbandBusy = true;
      } else {
        _armBusy = true;
      }
    });
    try {
      final repository = widget.repository;
      if (repository case final ReconnectableArmRepository reconnectable) {
        await reconnectable.reconnect(armband: armband);
      } else {
        throw UnsupportedError(AppStrings.homeReconnectUnsupported);
      }
      if (!mounted) return;
    } on Object catch (error, stackTrace) {
      debugPrint('Could not reconnect device: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error is UnsupportedError
                    ? AppStrings.homeReconnectUnsupported
                    : AppStrings.homeReconnectFailed,
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (armband) {
            _armbandBusy = false;
          } else {
            _armBusy = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    label: AppStrings.homeConnectionsTitle,
    title: AppStrings.homeConnectionsTitle,
    content: Padding(
      padding: const EdgeInsets.only(top: AppSpace.appSheetContentGap),
      child: Column(
        children: [
          _ConnectionRow(
            name: AppStrings.homeArmController,
            network: AppStrings.homeWifi,
            status: _armBusy
                ? AppStrings.homeConnecting
                : AppStrings.connectionArmStatus,
            signal: _armBusy ? null : AppStrings.connectionSignalStrong,
            busy: _armBusy,
            onReconnect: () => _reconnect(armband: false),
          ),
          const Rule(margin: EdgeInsets.symmetric(vertical: AppSpace.s8)),
          _ConnectionRow(
            name: AppStrings.homeArmbandConnection,
            network: AppStrings.homeWifiDirect,
            status: _armbandBusy
                ? AppStrings.homeConnecting
                : AppStrings.connectionArmbandStatus,
            signal: _armbandBusy ? null : AppStrings.connectionSignalStrong,
            busy: _armbandBusy,
            onReconnect: () => _reconnect(armband: true),
          ),
        ],
      ),
    ),
  );
}

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({
    required this.name,
    required this.network,
    required this.status,
    required this.signal,
    required this.busy,
    required this.onReconnect,
  });

  final String name;
  final String network;
  final String status;
  final String? signal;
  final bool busy;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: AppSpace.connectionRowMinHeight),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTheme.body(weight: FontWeight.w600)),
              Text(network, style: AppTheme.caption),
              Text(status, style: AppTheme.caption),
              if (signal != null) Text(signal!, style: AppTheme.caption),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.connectionRowGap),
        Semantics(
          button: true,
          label: AppStrings.homeReconnect,
          enabled: !busy,
          onTap: busy ? null : onReconnect,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: busy ? null : onReconnect,
            child: SizedBox(
              width: AppSpace.connectionActionWidth,
              height: AppSpace.minTouchTarget,
              child: Center(
                child: SizedBox(
                  height: 36,
                  child: IgnorePointer(
                    child: SecondaryButton(
                      label: AppStrings.homeReconnect,
                      onPressed: () {},
                      height: 36,
                      fontSize: AppSpace.connectionActionFontSize,
                      horizontalPadding:
                          AppSpace.connectionActionHorizontalPadding,
                      busy: busy,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
