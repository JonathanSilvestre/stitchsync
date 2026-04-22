import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/family_service.dart';
import '../base_view_model.dart';

class ManageFamilyViewModel extends BaseViewModel {
  final FamilyService familyService;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ManageFamilyViewModel({
    FamilyService? familyService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : familyService = familyService ?? FamilyService(),
        firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamFamiliesForCurrentUser() {
    return familyService.streamFamiliesForCurrentUser();
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

  Future<bool> deleteFamilyWithFeedback({
    required String familyId,
    required String successMessage,
    required String errorMessage,
  }) async {
    startLoading();
    try {
      await familyService.deleteFamily(familyId);
      setSuccess(successMessage);
      setIdle();
      return true;
    } catch (_) {
      setFailure(errorMessage);
      return false;
    }
  }
}
