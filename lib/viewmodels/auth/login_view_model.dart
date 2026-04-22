import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../base_view_model.dart';

class LoginActionResult {
  final bool success;
  final String? message;

  const LoginActionResult({required this.success, this.message});
}

class LoginViewModel extends BaseViewModel {
  LoginViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool _obscurePassword = true;

  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<LoginActionResult> login({
    required String identifier,
    required String password,
  }) async {
    setLoading(true);
    clearError();

    try {
      final user = await _authService.login(identifier.trim(), password);

      if (user == null) {
        const fallback = 'Could not sign in.';
        setError(fallback);
        return const LoginActionResult(success: false, message: fallback);
      }

      return const LoginActionResult(success: true);
    } on FirebaseAuthException catch (e) {
      final message = _authService.getReadableAuthError(e);
      setError(message);
      return LoginActionResult(success: false, message: message);
    } catch (e) {
      const message = 'Ocurrió un error de autenticación.';
      setError(message);
      return LoginActionResult(success: false, message: message);
    } finally {
      setLoading(false);
    }
  }

  Future<LoginActionResult> sendPasswordReset(String identifier) async {
    try {
      await _authService.sendPasswordReset(identifier.trim());
      return const LoginActionResult(success: true);
    } on FirebaseAuthException catch (e) {
      final message = _authService.getReadableAuthError(e);
      setError(message);
      return LoginActionResult(success: false, message: message);
    } catch (e) {
      const message = 'Ocurrió un error de autenticación.';
      setError(message);
      return LoginActionResult(success: false, message: message);
    }
  }
}
