import 'package:flutter/foundation.dart';

import '../../../core/strings.dart';
import '../../../data/repositories/auth_repository.dart';

enum LoginResult { success, invalid, credentialsIncorrect, noConnection }

final class LoginController extends ChangeNotifier {
  LoginController(this._authRepository);

  final AuthRepository _authRepository;

  String? emailError;
  String? passwordError;
  bool isLoading = false;

  void validateEmail(String value) {
    emailError = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
        ? null
        : AppStrings.loginEmailInvalid;
    notifyListeners();
  }

  void validatePassword(String value) {
    passwordError = value.isNotEmpty ? null : AppStrings.loginPasswordRequired;
    notifyListeners();
  }

  Future<LoginResult> submit(String email, String password) async {
    validateEmail(email);
    validatePassword(password);
    if (emailError != null || passwordError != null) {
      return LoginResult.invalid;
    }

    isLoading = true;
    notifyListeners();
    try {
      await _authRepository.signIn(email.trim(), password);
      return LoginResult.success;
    } on AuthCredentialsException {
      passwordError = AppStrings.loginCredentialsIncorrect;
      return LoginResult.credentialsIncorrect;
    } on AuthNetworkException {
      return LoginResult.noConnection;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
