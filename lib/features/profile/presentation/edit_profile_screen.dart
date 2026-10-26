import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/profile.dart';
import '../../../theme.dart';
import '../../../widgets.dart';
import '../application/profile_controller.dart';
import '../application/profile_providers.dart';

enum EditProfileState { loading, view, editing, saving, error }

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _email = TextEditingController();
  final _clinicCode = TextEditingController();
  EditProfileState _state = EditProfileState.loading;
  String? _nameError;
  String? _ageError;
  String? _emailError;
  String? _saveError;
  Profile? _profile;
  bool _initialized = false;

  bool get _editing =>
      _state == EditProfileState.editing || _state == EditProfileState.error;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _email.dispose();
    _clinicCode.dispose();
    super.dispose();
  }

  void _loadIfNeeded(Profile? profile) {
    if (profile == null || _initialized) return;
    _initialized = true;
    _profile = profile;
    _name.text = profile.name;
    _age.text = '${profile.age}';
    _email.text = profile.email;
    _clinicCode.text = profile.clinicCode ?? '—';
    _state = EditProfileState.view;
  }

  void _validateName() => setState(
    () => _nameError = _name.text.trim().isEmpty
        ? AppStrings.registerNameRequired
        : null,
  );

  void _validateAge() {
    final value = _age.text.trim();
    final parsed = int.tryParse(value);
    setState(() {
      _ageError = value.isEmpty
          ? AppStrings.registerAgeRequired
          : parsed == null
          ? AppStrings.registerAgeMustBeNumber
          : parsed < 1 || parsed > 120
          ? AppStrings.registerAgeInvalid
          : null;
    });
  }

  void _validateEmail() {
    final value = _email.text.trim();
    setState(() {
      _emailError = value.isEmpty
          ? AppStrings.registerEmailRequired
          : _emailPattern.hasMatch(value)
          ? null
          : AppStrings.registerEmailInvalid;
    });
  }

  Future<void> _save() async {
    _validateName();
    _validateAge();
    _validateEmail();
    if (_nameError != null || _ageError != null || _emailError != null) {
      return;
    }
    final current = _profile;
    if (current == null) return;
    setState(() {
      _state = EditProfileState.saving;
      _saveError = null;
    });
    try {
      final available = await ref
          .read(profileRepositoryProvider)
          .isEmailAvailable(_email.text.trim());
      if (!mounted) return;
      if (!available) {
        setState(() {
          _emailError = AppStrings.registerEmailTaken;
          _state = EditProfileState.editing;
        });
        return;
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Could not validate profile email: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _state = EditProfileState.error;
          _saveError = AppStrings.editProfileSaveError;
        });
      }
      return;
    }
    final updated = current.copyWith(
      name: _name.text.trim(),
      age: int.parse(_age.text.trim()),
      email: _email.text.trim(),
    );
    try {
      await ref.read(profileRepositoryProvider).updateProfile(updated);
      if (mounted) context.pop(true);
    } on Object catch (error, stackTrace) {
      debugPrint('Could not save profile: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _state = EditProfileState.error;
          _saveError = AppStrings.editProfileSaveError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileController = ref.watch(profileControllerProvider);
    final controllerProfile = profileController.profile;
    _loadIfNeeded(controllerProfile);
    final busy = _state == EditProfileState.saving;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screenH,
                  AppSpace.plainFormTopInset,
                  AppSpace.screenH,
                  AppSpace.s24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLink(
                      AppStrings.editProfileBack,
                      onTap: () => context.pop(false),
                    ),
                    const SizedBox(height: AppSpace.plainFormTitleGap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.editProfileTitle,
                            style: AppTheme.serif(AppSpace.loginTitleSize),
                          ),
                        ),
                        if (_state == EditProfileState.view)
                          AppLink(
                            AppStrings.editProfileEdit,
                            onTap: () => setState(
                              () => _state = EditProfileState.editing,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s24),
                    if (_state == EditProfileState.loading &&
                        profileController.state == ProfileLoadState.failed) ...[
                      Text(
                        AppStrings.editProfileLoadError,
                        style: AppTheme.body(
                          size: AppSpace.profileCaptionSize,
                          color: AppColors.clay,
                        ),
                      ),
                      AppLink(
                        AppStrings.profileRetry,
                        onTap: () => unawaited(profileController.load()),
                      ),
                    ] else if (_state == EditProfileState.loading)
                      const LinearProgressIndicator(
                        minHeight: AppSpace.hairline,
                        color: AppColors.forest,
                        backgroundColor: AppColors.rule,
                      )
                    else ...[
                      UnderlineField(
                        label: AppStrings.editProfileName,
                        controller: _name,
                        error: _nameError,
                        readOnly: !_editing,
                        enabled: !busy,
                        textCapitalization: TextCapitalization.words,
                        onBlur: _validateName,
                      ),
                      UnderlineField(
                        label: AppStrings.editProfileAge,
                        controller: _age,
                        error: _ageError,
                        readOnly: !_editing,
                        enabled: !busy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onBlur: _validateAge,
                      ),
                      UnderlineField(
                        label: AppStrings.editProfileEmail,
                        controller: _email,
                        error: _emailError,
                        readOnly: !_editing,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        onBlur: _validateEmail,
                      ),
                      UnderlineField(
                        label: AppStrings.editProfileClinicCode,
                        controller: _clinicCode,
                        readOnly: true,
                        textColor: AppColors.inkMuted,
                        helperText: AppStrings.editProfileClinicCodeCaption,
                      ),
                      if (_saveError != null) ...[
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          _saveError!,
                          style: AppTheme.body(
                            size: AppSpace.profileCaptionSize,
                            color: AppColors.clay,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenH,
                AppSpace.plainFormButtonInset,
                AppSpace.screenH,
                AppSpace.plainFormBottomInset,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: AppStrings.editProfileCancel,
                      onPressed: busy ? null : () => context.pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: PrimaryButton(
                      label: AppStrings.editProfileSave,
                      onPressed: _state == EditProfileState.view
                          ? () => setState(
                              () => _state = EditProfileState.editing,
                            )
                          : _state == EditProfileState.loading || busy
                          ? null
                          : _save,
                      busy: busy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
