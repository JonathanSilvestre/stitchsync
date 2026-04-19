import '../../services/event_service.dart';
import '../../services/pet_service.dart';
import '../base_view_model.dart';

class AddNewPetViewModel extends BaseViewModel {
  final PetService petService;
  final EventService eventService;

  AddNewPetViewModel({
    PetService? petService,
    EventService? eventService,
  })  : petService = petService ?? PetService(),
        eventService = eventService ?? EventService();

  Future<String?> savePetWithState({
    required String familyId,
    required String? petId,
    required String name,
    required String breed,
    required int age,
    required String notes,
    required String avatarId,
    required DateTime? birthDate,
    String? successMessage,
    String? errorMessage,
  }) async {
    startLoading();
    try {
      final effectivePetId = petId != null && petId.isNotEmpty
          ? petId
          : await petService.addPet(
              familyId: familyId,
              name: name,
              breed: breed,
              age: age,
              notes: notes,
              avatarId: avatarId,
            );

      if (petId != null && petId.isNotEmpty) {
        await petService.updatePet(
          familyId: familyId,
          petId: petId,
          name: name,
          breed: breed,
          age: age,
          notes: notes,
          avatarId: avatarId,
        );
      }

      await eventService.upsertPetBirthdayAutoEvent(
        familyId: familyId,
        petId: effectivePetId,
        petName: name,
        birthDate: birthDate,
      );

      setSuccess(successMessage ?? 'Pet saved successfully.');
      return effectivePetId;
    } catch (_) {
      setFailure(errorMessage ?? 'Could not save pet. Please try again.');
      return null;
    } finally {
      stopLoading();
    }
  }
}
