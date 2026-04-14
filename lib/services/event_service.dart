import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _eventsCollection(String familyId) {
    return _firestore.collection('families').doc(familyId).collection('events');
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamTodayEvents({
    required String familyId,
    String? petId,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return _eventsCollection(familyId)
        .where('scheduled_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduled_at', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduled_at')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      if (petId == null || petId.isEmpty) {
        return docs;
      }

      return docs.where((doc) {
        final data = doc.data();
        final eventPetId = (data['pet_id'] as String?) ?? '';
        return eventPetId == petId;
      }).toList(growable: false);
    });
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamEventsInRange({
    required String familyId,
    required DateTime start,
    required DateTime end,
    String? petId,
  }) {
    return _eventsCollection(familyId)
        .where('scheduled_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduled_at', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduled_at')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      if (petId == null || petId.isEmpty) {
        return docs;
      }

      return docs.where((doc) {
        final data = doc.data();
        final eventPetId = (data['pet_id'] as String?) ?? '';
        return eventPetId == petId;
      }).toList(growable: false);
    });
  }

  List<DateTime> _generateOccurrences({
    required DateTime anchor,
    required String recurrence,
    required int recurrenceIntervalDays,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    if (recurrence == 'none') {
      return [anchor];
    }

    final dates = <DateTime>[];
    DateTime cursor = anchor;
    final dayStep = recurrence == 'custom_days'
        ? (recurrenceIntervalDays < 1 ? 1 : recurrenceIntervalDays)
        : 1;

    DateTime goPrev(DateTime dt) {
      if (recurrence == 'daily' || recurrence == 'custom_days') {
        return dt.subtract(Duration(days: dayStep));
      }
      if (recurrence == 'monthly') {
        final year = dt.month == 1 ? dt.year - 1 : dt.year;
        final month = dt.month == 1 ? 12 : dt.month - 1;
        final maxDay = DateTime(year, month + 1, 0).day;
        final day = dt.day > maxDay ? maxDay : dt.day;
        return DateTime(year, month, day, dt.hour, dt.minute);
      }

      final year = dt.year - 1;
      final maxDay = DateTime(year, dt.month + 1, 0).day;
      final day = dt.day > maxDay ? maxDay : dt.day;
      return DateTime(year, dt.month, day, dt.hour, dt.minute);
    }

    DateTime goNext(DateTime dt) {
      if (recurrence == 'daily' || recurrence == 'custom_days') {
        return dt.add(Duration(days: dayStep));
      }
      if (recurrence == 'monthly') {
        final year = dt.month == 12 ? dt.year + 1 : dt.year;
        final month = dt.month == 12 ? 1 : dt.month + 1;
        final maxDay = DateTime(year, month + 1, 0).day;
        final day = dt.day > maxDay ? maxDay : dt.day;
        return DateTime(year, month, day, dt.hour, dt.minute);
      }

      final year = dt.year + 1;
      final maxDay = DateTime(year, dt.month + 1, 0).day;
      final day = dt.day > maxDay ? maxDay : dt.day;
      return DateTime(year, dt.month, day, dt.hour, dt.minute);
    }

    while (cursor.isAfter(rangeStart)) {
      final prev = goPrev(cursor);
      if (!prev.isBefore(rangeStart)) {
        dates.add(prev);
      }
      cursor = prev;
    }

    dates.add(anchor);

    cursor = anchor;
    while (cursor.isBefore(rangeEnd)) {
      final next = goNext(cursor);
      if (!next.isAfter(rangeEnd)) {
        dates.add(next);
      }
      cursor = next;
    }

    dates.sort();
    return dates;
  }

  Map<String, dynamic> _eventPayload({
    required String familyId,
    required String petId,
    required String title,
    required DateTime scheduledAt,
    required String note,
    required String category,
    required String recurrence,
    int? recurrenceIntervalDays,
    required DateTime anchorDate,
    required String seriesId,
    required String? uid,
  }) {
    return {
      'family_id': familyId,
      'pet_id': petId,
      'title': title,
      'note': note,
      'category': category,
      'scheduled_at': Timestamp.fromDate(scheduledAt),
      'recurrence': recurrence,
      // ignore: use_null_aware_elements
      if (recurrenceIntervalDays != null)
        'recurrence_interval_days': recurrenceIntervalDays,
      'recurrence_anchor_at': Timestamp.fromDate(anchorDate),
      'series_id': seriesId,
      'created_by_uid': uid,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
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
  }) async {
    final uid = _auth.currentUser?.uid;
    final cleanRecurrence = recurrence.trim().toLowerCase();
    if (cleanRecurrence != 'none' &&
        cleanRecurrence != 'daily' &&
        cleanRecurrence != 'monthly' &&
        cleanRecurrence != 'yearly' &&
        cleanRecurrence != 'custom_days') {
      throw ArgumentError('Recurrence no soportada: $recurrence');
    }
    if (recurrenceIntervalDays < 1) {
      throw ArgumentError('recurrenceIntervalDays debe ser >= 1');
    }

    final cleanFamilyId = familyId.trim();
    final cleanPetId = petId.trim();
    if (cleanFamilyId.isEmpty) {
      throw ArgumentError('FamilyId requerido');
    }
    if (cleanPetId.isEmpty) {
      throw ArgumentError('PetId requerido');
    }

    final cleanTitle = title.trim();
    final cleanNote = note.trim();
    final cleanCategory = category.trim();

    final rangeStart = DateTime(DateTime.now().year, DateTime.now().month - 6, 1);
    final rangeEnd = DateTime(DateTime.now().year, DateTime.now().month + 13, 0, 23, 59);

    final occurrences = _generateOccurrences(
      anchor: scheduledAt,
      recurrence: cleanRecurrence,
      recurrenceIntervalDays: recurrenceIntervalDays,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    final seriesId = _eventsCollection(cleanFamilyId).doc().id;
    final chunks = <List<DateTime>>[];
    // Keep batches small to stay compatible with strict Firestore rule-evaluation limits.
    for (var i = 0; i < occurrences.length; i += 10) {
      final end = (i + 10) > occurrences.length ? occurrences.length : i + 10;
      chunks.add(occurrences.sublist(i, end));
    }

    for (final chunk in chunks) {
      final batch = _firestore.batch();
      for (final date in chunk) {
        final docRef = _eventsCollection(cleanFamilyId).doc();
        batch.set(
          docRef,
          _eventPayload(
            familyId: cleanFamilyId,
            petId: cleanPetId,
            title: cleanTitle,
            scheduledAt: date,
            note: cleanNote,
            category: cleanCategory,
            recurrence: cleanRecurrence,
            recurrenceIntervalDays: cleanRecurrence == 'custom_days'
                ? recurrenceIntervalDays
                : (cleanRecurrence == 'daily' ? 1 : null),
            anchorDate: scheduledAt,
            seriesId: seriesId,
            uid: uid,
          ),
        );
      }
      await batch.commit();
    }
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
  }) async {
    final cleanRecurrence = recurrence.trim().toLowerCase();
    if (cleanRecurrence != 'none' &&
        cleanRecurrence != 'daily' &&
        cleanRecurrence != 'monthly' &&
        cleanRecurrence != 'yearly' &&
        cleanRecurrence != 'custom_days') {
      throw ArgumentError('Recurrence no soportada: $recurrence');
    }

    await _eventsCollection(familyId).doc(eventId).update({
      'pet_id': petId.trim(),
      'title': title.trim(),
      'note': note.trim(),
      'category': category.trim(),
      'scheduled_at': Timestamp.fromDate(scheduledAt),
      'recurrence': cleanRecurrence,
      if (cleanRecurrence == 'custom_days')
        'recurrence_interval_days': recurrenceIntervalDays,
      if (cleanRecurrence != 'custom_days') 'recurrence_interval_days': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEvent({
    required String familyId,
    required String eventId,
  }) async {
    await _eventsCollection(familyId).doc(eventId).delete();
  }

  Future<void> deleteSeries({
    required String familyId,
    required String seriesId,
  }) async {
    final query = await _eventsCollection(familyId)
        .where('series_id', isEqualTo: seriesId)
        .get();

    if (query.docs.isEmpty) {
      return;
    }

    for (var i = 0; i < query.docs.length; i += 100) {
      final end = (i + 100) > query.docs.length ? query.docs.length : i + 100;
      final batch = _firestore.batch();
      for (final doc in query.docs.sublist(i, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
