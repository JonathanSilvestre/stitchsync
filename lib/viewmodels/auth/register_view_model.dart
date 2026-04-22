import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../base_view_model.dart';

class RegisterActionResult {
  final bool success;
  final String? message;

  const RegisterActionResult({required this.success, this.message});
}

class RegisterViewModel extends BaseViewModel {
  RegisterViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String? _selectedCountry;

  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get acceptedTerms => _acceptedTerms;
  String? get selectedCountry => _selectedCountry;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void setAcceptedTerms(bool value) {
    if (_acceptedTerms == value) {
      return;
    }
    _acceptedTerms = value;
    notifyListeners();
  }

  void setSelectedCountry(String? value) {
    if (_selectedCountry == value) {
      return;
    }
    _selectedCountry = value;
    notifyListeners();
  }

  Future<RegisterActionResult> register({
    required String username,
    required String email,
    required String password,
    required int age,
  }) async {
    if (!_acceptedTerms) {
      const message = 'Debes aceptar los terminos para continuar.';
      setError(message);
      return const RegisterActionResult(success: false, message: message);
    }

    setLoading(true);
    clearError();

    try {
      final user = await _authService.register(
        username: username.trim(),
        email: email.trim(),
        password: password.trim(),
        age: age,
        country: _selectedCountry ?? '',
      );

      if (user == null) {
        const fallback = 'Could not complete sign up.';
        setError(fallback);
        return const RegisterActionResult(success: false, message: fallback);
      }

      return const RegisterActionResult(success: true);
    } on FirebaseAuthException catch (e) {
      final message = _authService.getReadableAuthError(e);
      setError(message);
      return RegisterActionResult(success: false, message: message);
    } catch (_) {
      const message = 'Could not complete sign up.';
      setError(message);
      return const RegisterActionResult(success: false, message: message);
    } finally {
      setLoading(false);
    }
  }
}
