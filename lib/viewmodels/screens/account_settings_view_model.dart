import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../base_view_model.dart';

class AccountSettingsViewModel extends BaseViewModel {
  final AuthService authService;
  final FirebaseFirestore firestore;

  AccountSettingsViewModel({
    AuthService? authService,
    FirebaseFirestore? firestore,
  })  : authService = authService ?? AuthService(),
        firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> loadProfileWithState({
    String? errorMessage,
  }) async {
    startLoading();
    try {
      final profile = await authService.getCurrentUserProfile();
      setSuccess();
      return profile;
    } catch (_) {
      setFailure(errorMessage ?? 'Error loading profile');
      return null;
    } finally {
      stopLoading();
    }
  }

  Future<bool> saveProfileWithState({
    required String username,
    required String currentPassword,
    required String newPassword,
    required String language,
    required String avatarId,
    required String initialUsername,
    required String initialLanguage,
    required String initialAvatarId,
    String? noChangesMessage,
    String? successMessage,
    String? errorMessage,
  }) async {
    startLoading();
    try {
      final usernameChanged = username != initialUsername;
      final languageChanged = language != initialLanguage;
      final avatarChanged = avatarId != initialAvatarId;
      final wantsPasswordChange = newPassword.isNotEmpty;

      if (username.isEmpty) {
        throw Exception('Username cannot be empty');
      }

      if (newPassword.isNotEmpty && currentPassword.isEmpty) {
        throw Exception('Current password is required to change password');
      }

      if (!usernameChanged && !wantsPasswordChange && !languageChanged && !avatarChanged) {
        setSuccess(noChangesMessage ?? 'No changes to save.');
        return true;
      }

      if (usernameChanged || wantsPasswordChange) {
        await authService.updateAccount(
          newUsername: username,
          currentPassword: currentPassword.isEmpty ? null : currentPassword,
          newPassword: newPassword.isNotEmpty ? newPassword : null,
        );
      }

      final user = authService.currentUser;
      if (user != null) {
        final payload = <String, dynamic>{};
        if (languageChanged) {
          payload['language'] = language;
        }
        if (avatarChanged) {
          payload['profile_avatar_id'] = avatarId;
        }
        if (payload.isNotEmpty) {
          await firestore.collection('users').doc(user.uid).set(
                payload,
                SetOptions(merge: true),
              );
        }
      }

      setSuccess(successMessage ?? 'Changes saved successfully');
      return true;
    } catch (_) {
      setFailure(errorMessage ?? 'Error');
      return false;
    } finally {
      stopLoading();
    }
  }
}
