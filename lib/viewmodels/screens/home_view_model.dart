import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/family_service.dart';
import '../../services/pet_service.dart';
import '../base_view_model.dart';

class HomeViewModel extends BaseViewModel {
  final FirebaseFirestore firestore;
  final AuthService authService;
  final FamilyService familyService;
  final PetService petService;
  final EventService eventService;

  HomeViewModel({
    FirebaseFirestore? firestore,
    AuthService? authService,
    FamilyService? familyService,
    PetService? petService,
    EventService? eventService,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        authService = authService ?? AuthService(),
        familyService = familyService ?? FamilyService(),
        petService = petService ?? PetService(),
        eventService = eventService ?? EventService();

  Future<({String username, String? familyId, String? petId})>
      loadHomeSelection() async {
    Map<String, dynamic>? profile;
    try {
      profile = await authService.getCurrentUserProfile();
    } catch (_) {
      profile = null;
    }

    final profileUsername = (profile?['username'] as String?)?.trim();
    final activeFamilyId = (profile?['active_family_id'] as String?)?.trim();
    final activePetId = (profile?['active_pet_id'] as String?)?.trim();

    String? fallbackEmailName;
    final email = authService.currentUser?.email?.trim();
    if (email != null && email.contains('@')) {
      fallbackEmailName = email.split('@').first;
    }

    final resolvedName = (profileUsername != null && profileUsername.isNotEmpty)
        ? profileUsername
        : (fallbackEmailName != null && fallbackEmailName.isNotEmpty)
            ? fallbackEmailName
            : 'Sarah';

    return (
      username: resolvedName,
      familyId:
          activeFamilyId != null && activeFamilyId.isNotEmpty ? activeFamilyId : null,
      petId: activePetId != null && activePetId.isNotEmpty ? activePetId : null,
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileSelectionStream(String uid) {
    return firestore.collection('users').doc(uid).snapshots();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamFamiliesForCurrentUser() {
    return familyService.streamFamiliesForCurrentUser();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamPets(String familyId) {
    return petService.streamPets(familyId);
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

  Future<void> persistActivePetSelection({
    required String familyId,
    required String petId,
    String? errorMessage,
  }) async {
    try {
      await authService.saveActivePetSelection(
        familyId: familyId,
        petId: petId,
      );
      setSuccess();
      setIdle();
    } catch (_) {
      setFailure(errorMessage ?? 'Could not save active pet.');
    }
  }

  Future<void> setEventCompleted({
    required String familyId,
    required String eventId,
    required bool completed,
    required String completedMessage,
    required String pendingMessage,
    required String errorMessage,
  }) async {
    startLoading();
    try {
      await eventService.setEventCompleted(
        familyId: familyId,
        eventId: eventId,
        completed: completed,
      );
      setSuccess(completed ? completedMessage : pendingMessage);
    } catch (_) {
      setFailure(errorMessage);
    } finally {
      if (!isError) {
        setIdle();
      }
    }
  }

  Future<void> deleteEvent({
    required String familyId,
    required String eventId,
    required String successMessage,
    required String errorMessage,
  }) async {
    startLoading();
    try {
      await eventService.deleteEvent(familyId: familyId, eventId: eventId);
      setSuccess(successMessage);
    } catch (_) {
      setFailure(errorMessage);
    } finally {
      if (!isError) {
        setIdle();
      }
    }
  }

  Future<void> deleteSeries({
    required String familyId,
    required String seriesId,
    required String successMessage,
    required String errorMessage,
  }) async {
    startLoading();
    try {
      await eventService.deleteSeries(familyId: familyId, seriesId: seriesId);
      setSuccess(successMessage);
    } catch (_) {
      setFailure(errorMessage);
    } finally {
      if (!isError) {
        setIdle();
      }
    }
  }
}
