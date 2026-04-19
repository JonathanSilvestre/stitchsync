import '../../services/event_service.dart';
import '../../services/family_service.dart';
import '../../services/pet_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../base_view_model.dart';

class NewEventViewModel extends BaseViewModel {
  final EventService eventService;
  final FamilyService familyService;
  final PetService petService;

  NewEventViewModel({
    EventService? eventService,
    FamilyService? familyService,
    PetService? petService,
  })  : eventService = eventService ?? EventService(),
        familyService = familyService ?? FamilyService(),
        petService = petService ?? PetService();

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> loadFamiliesForCurrentUser() {
    return familyService.streamFamiliesForCurrentUser().first;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> loadPets(String familyId) {
    return petService.streamPets(familyId).first;
  }

  Future<void> addEvent({
    required String familyId,
    required String petId,
    required String title,
    required DateTime scheduledAt,
    String note = '',
    String category = 'general',
    String recurrence = 'none',
    int recurrenceIntervalDays = 1,
  }) {
    return eventService.addEvent(
      familyId: familyId,
      petId: petId,
      title: title,
      scheduledAt: scheduledAt,
      category: category,
      note: note,
      recurrence: recurrence,
      recurrenceIntervalDays: recurrenceIntervalDays,
    );
  }

  Future<void> updateEvent({
    required String familyId,
    required String eventId,
    required String petId,
    required String title,
    required DateTime scheduledAt,
    String note = '',
    String category = 'general',
    String recurrence = 'none',
    int recurrenceIntervalDays = 1,
  }) {
    return eventService.updateEvent(
      familyId: familyId,
      eventId: eventId,
      petId: petId,
      title: title,
      scheduledAt: scheduledAt,
      category: category,
      note: note,
      recurrence: recurrence,
      recurrenceIntervalDays: recurrenceIntervalDays,
    );
  }
}
