import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../services/family_service.dart';
import '../../services/pet_service.dart';
import '../base_view_model.dart';

class ProfileViewModel extends BaseViewModel {
  final FirebaseFirestore firestore;
  final AuthService authService;
  final FamilyService familyService;
  final PetService petService;

  ProfileViewModel({
    FirebaseFirestore? firestore,
    AuthService? authService,
    FamilyService? familyService,
    PetService? petService,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        authService = authService ?? AuthService(),
        familyService = familyService ?? FamilyService(),
        petService = petService ?? PetService();

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamFamiliesForCurrentUser() {
    return familyService.streamFamiliesForCurrentUser();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() {
    return authService.getCurrentUserProfile();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfileWithLoading() async {
    startLoading();
    try {
      final profile = await getCurrentUserProfile();
      setSuccess();
      setIdle();
      return profile;
    } catch (_) {
      setFailure('Error loading profile');
      rethrow;
    } finally {
      if (!isError) {
        setIdle();
      }
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getCurrentUserFamilies() async {
    return familyService.streamFamiliesForCurrentUser().first;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getFamilyPets(String familyId) async {
    return petService.streamPets(familyId).first;
  }

  Future<void> saveActivePetSelection({
    required String familyId,
    required String petId,
  }) {
    return authService.saveActivePetSelection(
      familyId: familyId,
      petId: petId,
    );
  }

  Future<void> saveActivePetSelectionWithFeedback({
    required String familyId,
    required String petId,
    required String errorMessage,
  }) async {
    try {
      await saveActivePetSelection(familyId: familyId, petId: petId);
      setSuccess();
      setIdle();
    } catch (_) {
      setFailure(errorMessage);
    }
  }

  Future<({String roleName, String roleLabel})> getCurrentUserRole({
    String? activeFamilyId,
    required String noFamilyName,
    required String noFamilyLabel,
    required String ownerName,
    required String ownerLabel,
    required String adminName,
    required String adminLabel,
    required String memberName,
    required String memberLabel,
  }) async {
    try {
      final families = await getCurrentUserFamilies();
      if (families.isEmpty) {
        return (roleName: noFamilyName, roleLabel: noFamilyLabel);
      }

      late QueryDocumentSnapshot<Map<String, dynamic>> selectedFamily;
      try {
        selectedFamily = families.firstWhere((family) => family.id == activeFamilyId);
      } catch (_) {
        selectedFamily = families.first;
      }

      final familyData = selectedFamily.data();
      final currentUid = authService.currentUser?.uid ?? '';
      final ownerUid = (familyData['owner_uid'] as String?) ?? '';
      final adminUids = (familyData['admin_uids'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toSet();

      if (currentUid == ownerUid) {
        return (roleName: ownerName, roleLabel: ownerLabel);
      }
      if (adminUids.contains(currentUid)) {
        return (roleName: adminName, roleLabel: adminLabel);
      }
      return (roleName: memberName, roleLabel: memberLabel);
    } catch (_) {
      return (roleName: memberName, roleLabel: memberLabel);
    }
  }
}
