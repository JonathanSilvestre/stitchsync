import '../../services/auth_service.dart';
import '../../services/family_service.dart';
import '../base_view_model.dart';

class CreateFamilyViewModel extends BaseViewModel {
  final FamilyService familyService;
  final AuthService authService;

  CreateFamilyViewModel({
    FamilyService? familyService,
    AuthService? authService,
  })  : familyService = familyService ?? FamilyService(),
        authService = authService ?? AuthService();

  Future<String?> createFamilyWithState({
    required String familyName,
    String? errorMessage,
  }) async {
    startLoading();
    try {
      final familyId = await familyService.createFamily(familyName);
      await authService.saveActivePetSelection(
        familyId: familyId,
        petId: '',
      );
      setSuccess('Family created');
      return familyId;
    } catch (_) {
      setFailure(errorMessage ?? 'Could not create family.');
      return null;
    } finally {
      stopLoading();
    }
  }
}
