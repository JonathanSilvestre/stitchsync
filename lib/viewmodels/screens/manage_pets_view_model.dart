import '../../services/family_service.dart';
import '../../services/pet_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../base_view_model.dart';

class ManagePetsViewModel extends BaseViewModel {
  final FamilyService familyService;
  final PetService petService;

  ManagePetsViewModel({
    FamilyService? familyService,
    PetService? petService,
  })  : familyService = familyService ?? FamilyService(),
        petService = petService ?? PetService();

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamFamiliesForCurrentUser() {
    return familyService.streamFamiliesForCurrentUser();
  }

  Future<bool> isCurrentUserFamilyAdmin({required String familyId}) {
    return familyService.isCurrentUserFamilyAdmin(familyId: familyId);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamPets(String familyId) {
    return petService.streamPets(familyId);
  }

  Future<bool> deletePetWithFeedback({
    required String familyId,
    required String petId,
    required String errorMessage,
  }) async {
    startLoading();
    try {
      await petService.deletePet(familyId: familyId, petId: petId);
      setSuccess();
      setIdle();
      return true;
    } catch (_) {
      setFailure(errorMessage);
      return false;
    }
  }
}
