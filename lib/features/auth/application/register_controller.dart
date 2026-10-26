import 'package:flutter/foundation.dart';

import '../../../core/strings.dart';
import '../../../data/repositories/auth_repository.dart';

enum RegisterResult {
  success,
  invalid,
  emailTaken,
  clinicCodeInvalid,
  serverError,
}

final class RegisterController extends ChangeNotifier {
  RegisterController(this._authRepository);

  final AuthRepository _authRepository;

  String? nameError;
  String? ageError;
  String? emailError;
  String? passwordError;
  String? clinicCodeError;
  bool isLoading = false;

  bool get isPasswordValid =>
      _passwordHasLength && _passwordHasLetter && _passwordHasNumber;
  String get passwordRuleHint =>
      _passwordHasLength || _passwordHasLetter || _passwordHasNumber
      ? '${AppStrings.registerRuleLength}: ${_passwordHasLength ? AppStrings.registerRuleMet : AppStrings.registerRuleNeeded} · '
            '${AppStrings.registerRuleLetter}: ${_passwordHasLetter ? AppStrings.registerRuleMet : AppStrings.registerRuleNeeded} · '
            '${AppStrings.registerRuleNumber}: ${_passwordHasNumber ? AppStrings.registerRuleMet : AppStrings.registerRuleNeeded}'
      : AppStrings.registerPasswordRule;

  bool _passwordHasLength = false;
  bool _passwordHasLetter = false;
  bool _passwordHasNumber = false;

  void validateName(String value) {
    nameError = value.trim().isEmpty ? AppStrings.registerNameRequired : null;
    notifyListeners();
  }

  void validateAge(String value) {
    final parsed = int.tryParse(value.trim());
    ageError = value.trim().isEmpty
        ? AppStrings.registerAgeRequired
        : parsed == null
        ? AppStrings.registerAgeMustBeNumber
        : parsed < 1 || parsed > 120
        ? AppStrings.registerAgeInvalid
        : null;
    notifyListeners();
  }

  void validateEmail(String value) {
    emailError = value.trim().isEmpty
        ? AppStrings.registerEmailRequired
        : _emailPattern.hasMatch(value.trim())
        ? null
        : AppStrings.registerEmailInvalid;
    notifyListeners();
  }

  void validatePassword(String value) {
    _passwordHasLength = value.length >= 8;
    _passwordHasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    _passwordHasNumber = RegExp(r'\d').hasMatch(value);
    passwordError = value.isEmpty
        ? AppStrings.registerPasswordRequired
        : isPasswordValid
        ? null
        : AppStrings.registerPasswordInvalid;
    notifyListeners();
  }

  void validateClinicCode(String value) {
    clinicCodeError = value.trim().isEmpty
        ? AppStrings.registerClinicCodeRequired
        : null;
    notifyListeners();
  }

  Future<bool> checkEmailAvailability(String email) async {
    validateEmail(email);
    if (emailError != null) return true;
    try {
      if (!await _authRepository.isEmailAvailable(email.trim())) {
        emailError = AppStrings.registerEmailTaken;
        notifyListeners();
      }
      return true;
    } on AuthNetworkException {
      return false;
    }
  }

  Future<bool> checkClinicCode(String clinicCode) async {
    validateClinicCode(clinicCode);
    if (clinicCodeError != null) return true;
    try {
      if (!await _authRepository.isClinicCodeValid(clinicCode.trim())) {
        clinicCodeError = AppStrings.registerClinicCodeInvalid;
        notifyListeners();
      }
      return true;
    } on AuthNetworkException {
      return false;
    }
  }

  Future<RegisterResult> submit({
    required String fullName,
    required String age,
    required String email,
    required String password,
    required String clinicCode,
  }) async {
    validateName(fullName);
    validateAge(age);
    validateEmail(email);
    validatePassword(password);
    validateClinicCode(clinicCode);
    if ([
      nameError,
      ageError,
      emailError,
      passwordError,
      clinicCodeError,
    ].any((error) => error != null)) {
      return RegisterResult.invalid;
    }

    isLoading = true;
    notifyListeners();
    try {
      await _authRepository.register(
        fullName: fullName.trim(),
        age: int.parse(age.trim()),
        email: email.trim(),
        password: password,
        clinicCode: clinicCode.trim(),
      );
      return RegisterResult.success;
    } on AuthEmailTakenException {
      emailError = AppStrings.registerEmailTaken;
      return RegisterResult.emailTaken;
    } on AuthClinicCodeException {
      clinicCodeError = AppStrings.registerClinicCodeInvalid;
      return RegisterResult.clinicCodeInvalid;
    } on AuthNetworkException {
      return RegisterResult.serverError;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
