import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../base_view_model.dart';

class ManageAccountViewModel extends BaseViewModel {
  final AuthService authService;
  final FirebaseFirestore firestore;

  ManageAccountViewModel({
    AuthService? authService,
    FirebaseFirestore? firestore,
  })  : authService = authService ?? AuthService(),
        firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> loadProfileWithState() async {
    startLoading();
    try {
      final profile = await authService.getCurrentUserProfile();
      setSuccess();
      setIdle();
      return profile;
    } catch (_) {
      setFailure('Could not load profile.');
      return null;
    }
  }

  Future<String> loadLanguageWithState({required String fallback}) async {
    final user = authService.currentUser;
    if (user == null) {
      return fallback;
    }

    startLoading();
    try {
      final doc = await firestore.collection('users').doc(user.uid).get();
      final language = (doc.data()?['language'] as String?) ?? fallback;
      setSuccess();
      setIdle();
      return language;
    } catch (_) {
      setFailure('Could not load language preference.');
      return fallback;
    }
  }

  Future<bool> saveLanguageWithState({
    required String language,
    required String errorMessage,
  }) async {
    final user = authService.currentUser;
    if (user == null) {
      setFailure(errorMessage);
      return false;
    }

    startLoading();
    try {
      await firestore.collection('users').doc(user.uid).set(
            {'language': language},
            SetOptions(merge: true),
          );
      setSuccess();
      setIdle();
      return true;
    } catch (_) {
      setFailure(errorMessage);
      return false;
    }
  }

  Future<bool> saveAccountWithState({
    required String newUsername,
    required String currentPassword,
    String? newPassword,
  }) async {
    startLoading();
    clearError();
    try {
      await authService.updateAccount(
        newUsername: newUsername,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      setSuccess('Account updated successfully.');
      setIdle();
      return true;
    } on FirebaseAuthException catch (e) {
      setFailure(authService.getReadableAuthError(e));
      return false;
    }
  }
}
