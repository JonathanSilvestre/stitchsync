import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/event_service.dart';
import '../../services/family_service.dart';
import '../base_view_model.dart';

class FamilyViewModel extends BaseViewModel {
  final FamilyService familyService;
  final EventService eventService;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FamilyViewModel({
    FamilyService? familyService,
    EventService? eventService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : familyService = familyService ?? FamilyService(),
        eventService = eventService ?? EventService(),
        firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Future<void> syncMembershipIndex() {
    return familyService.syncCurrentUserFamilyIds();
  }

  Future<void> joinFamilyByInviteCode(String code) {
    return familyService.joinFamilyByInviteCode(inviteCode: code);
  }

  Future<bool> joinFamilyByInviteCodeWithFeedback({
    required String code,
    required String successMessage,
    required String fallbackErrorMessage,
  }) async {
    startLoading();
    clearError();
    try {
      await familyService.joinFamilyByInviteCode(inviteCode: code);
      setSuccess(successMessage);
      return true;
    } on FirebaseAuthException catch (e) {
      setFailure(familyService.getReadableError(e));
    } on FirebaseException catch (e) {
      setFailure(e.message ?? fallbackErrorMessage);
    } catch (_) {
      setFailure(fallbackErrorMessage);
    } finally {
      if (!isError) {
        setIdle();
      }
    }
    return false;
  }

  Future<void> promoteMemberToAdmin({
    required String familyId,
    required String memberUid,
  }) {
    return familyService.promoteMemberToAdmin(
      familyId: familyId,
      memberUid: memberUid,
    );
  }

  Future<bool> promoteMemberToAdminWithFeedback({
    required String familyId,
    required String memberUid,
    required String successMessage,
  }) async {
    startLoading();
    clearError();
    try {
      await promoteMemberToAdmin(familyId: familyId, memberUid: memberUid);
      setSuccess(successMessage);
      return true;
    } on FirebaseAuthException catch (e) {
      setFailure(familyService.getReadableError(e));
    } finally {
      if (!isError) {
        setIdle();
      }
    }
    return false;
  }

  Future<void> removeMemberFromFamily({
    required String familyId,
    required String memberUid,
  }) {
    return familyService.removeMemberFromFamily(
      familyId: familyId,
      memberUid: memberUid,
    );
  }

  Future<bool> removeMemberFromFamilyWithFeedback({
    required String familyId,
    required String memberUid,
    required String successMessage,
  }) async {
    startLoading();
    clearError();
    try {
      await removeMemberFromFamily(familyId: familyId, memberUid: memberUid);
      setSuccess(successMessage);
      return true;
    } on FirebaseAuthException catch (e) {
      setFailure(familyService.getReadableError(e));
    } finally {
      if (!isError) {
        setIdle();
      }
    }
    return false;
  }

  Future<void> leaveFamily(String familyId) {
    return familyService.leaveFamily(familyId: familyId);
  }

  Future<bool> leaveFamilyWithFeedback({
    required String familyId,
    required String successMessage,
  }) async {
    startLoading();
    clearError();
    try {
      await leaveFamily(familyId);
      setSuccess(successMessage);
      return true;
    } on FirebaseAuthException catch (e) {
      setFailure(familyService.getReadableError(e));
    } finally {
      if (!isError) {
        setIdle();
      }
    }
    return false;
  }

  String readableFamilyError(FirebaseAuthException error) {
    return familyService.getReadableError(error);
  }

  Future<List<Map<String, dynamic>>> loadMemberProfiles(
    List<dynamic> memberUids,
  ) async {
    final docs = await Future.wait(
      memberUids.map(
        (uid) => firestore.collection('users').doc(uid as String).get(),
      ),
    );

    return docs
        .map((doc) => {
              'uid': doc.id,
              'data': doc.data() ?? <String, dynamic>{},
            })
        .toList(growable: false);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamFamiliesForCurrentUser() {
    return familyService.streamFamiliesForCurrentUser();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileSelectionStream(String uid) {
    return firestore.collection('users').doc(uid).snapshots();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamTodayEvents({
    required String familyId,
    required String petId,
  }) {
    return eventService.streamTodayEvents(
      familyId: familyId,
      petId: petId,
    );
  }
}
