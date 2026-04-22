import '../../services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../base_view_model.dart';

class CalendarViewModel extends BaseViewModel {
  final EventService eventService;

  CalendarViewModel({EventService? eventService})
      : eventService = eventService ?? EventService();

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamEventsInRange({
    required String familyId,
    required DateTime start,
    required DateTime end,
    String? petId,
  }) {
    return eventService.streamEventsInRange(
      familyId: familyId,
      start: start,
      end: end,
      petId: petId,
    );
  }

  Future<void> setEventCompletedWithFeedback({
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

  Future<void> deleteEventWithFeedback({
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

  Future<void> deleteSeriesWithFeedback({
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
