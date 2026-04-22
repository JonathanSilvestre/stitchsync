import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/family_service.dart';
import '../base_view_model.dart';

class ManageFamiliesViewModel extends BaseViewModel {
  final FamilyService familyService;
  final FirebaseAuth auth;

  ManageFamiliesViewModel({
    FamilyService? familyService,
    FirebaseAuth? auth,
  })  : familyService = familyService ?? FamilyService(),
        auth = auth ?? FirebaseAuth.instance;

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamFamiliesForCurrentUser() {
    return familyService.streamFamiliesForCurrentUser();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamPendingInvitationsForCurrentUser() {
    return familyService.streamPendingInvitationsForCurrentUser();
  }

  Future<bool> saveFamilyWithFeedback({
    required String value,
    String? familyId,
  }) async {
    startLoading();
    clearError();
    try {
      if (familyId == null) {
        await familyService.createFamily(value);
      } else {
        await familyService.updateFamilyName(
          familyId: familyId,
          familyName: value,
        );
      }
      setSuccess();
      setIdle();
      return true;
    } on FirebaseAuthException catch (e) {
      setFailure(familyService.getReadableError(e));
      return false;
    }
  }

  Future<bool> inviteByEmailWithFeedback({
    required String familyId,
    required String familyName,
    required String email,
    required String successMessage,
  }) async {
    startLoading();
    clearError();
    try {
      await familyService.inviteByEmail(
        familyId: familyId,
        familyName: familyName,
        email: email,
      );
      setSuccess(successMessage);
      setIdle();
      return true;
    } on FirebaseAuthException catch (e) {
      setFailure(familyService.getReadableError(e));
      return false;
    }
  }

  Future<bool> deleteFamilyWithFeedback({
    required String familyId,
    required String errorMessage,
  }) async {
    startLoading();
    clearError();
    try {
      await familyService.deleteFamily(familyId);
      setSuccess();
      setIdle();
      return true;
    } catch (_) {
      setFailure(errorMessage);
      return false;
    }
  }

  Future<bool> respondToInvitationWithFeedback({
    required String invitationId,
    required bool accept,
  }) async {
    startLoading();
    clearError();
    try {
      if (accept) {
        await familyService.acceptInvitation(invitationId: invitationId);
      } else {
        await familyService.rejectInvitation(invitationId: invitationId);
      }
      setSuccess();
      setIdle();
      return true;
    } on FirebaseAuthException catch (e) {
      setFailure(familyService.getReadableError(e));
      return false;
    }
  }
}
