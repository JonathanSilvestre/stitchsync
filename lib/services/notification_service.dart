import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  static const String _channelId = 'event_reminders';
  static const String _channelName = 'Event Reminders';
  static const String _channelDescription =
      'Reminders sent 5 minutes before pet events';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: settings);
    await requestPermissions();

    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<Map<String, dynamic>> _loadPreferences() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return <String, dynamic>{};
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    final raw = data['notification_preferences'];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    return <String, dynamic>{};
  }

  bool _isCategoryEnabled(Map<String, dynamic> prefs, String category, String title) {
    final pushEnabled = (prefs['push_enabled'] as bool?) ?? true;
    if (!pushEnabled) {
      return false;
    }

    final lookup = '${category.toLowerCase()} ${title.toLowerCase()}';

    if (lookup.contains('feed') ||
        lookup.contains('water') ||
        lookup.contains('food') ||
        lookup.contains('meal')) {
      return (prefs['feed_water'] as bool?) ?? true;
    }

    if (lookup.contains('walk') || lookup.contains('exercise')) {
      return (prefs['walks_exercise'] as bool?) ?? true;
    }

    if (lookup.contains('med') ||
        lookup.contains('vet') ||
        lookup.contains('vaccine') ||
        lookup.contains('pill')) {
      return (prefs['medication_vet'] as bool?) ?? true;
    }

    if (lookup.contains('family') || lookup.contains('update')) {
      return (prefs['family_updates'] as bool?) ?? true;
    }

    return true;
  }

  TimeOfDayPair? _quietHours(Map<String, dynamic> prefs) {
    final enabled = (prefs['quiet_hours_enabled'] as bool?) ?? false;
    if (!enabled) {
      return null;
    }

    final start = _parseHourMinute((prefs['quiet_hours_start'] as String?) ?? '');
    final end = _parseHourMinute((prefs['quiet_hours_end'] as String?) ?? '');
    if (start == null || end == null) {
      return null;
    }

    return TimeOfDayPair(start: start, end: end);
  }

  ({int hour, int minute})? _parseHourMinute(String raw) {
    final value = raw.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return (hour: hour, minute: minute);
  }

  bool _isWithinQuietHours(DateTime dateTime, TimeOfDayPair quiet) {
    final minutes = dateTime.hour * 60 + dateTime.minute;
    final startMinutes = quiet.start.hour * 60 + quiet.start.minute;
    final endMinutes = quiet.end.hour * 60 + quiet.end.minute;

    if (startMinutes == endMinutes) {
      return true;
    }

    if (startMinutes < endMinutes) {
      return minutes >= startMinutes && minutes < endMinutes;
    }

    return minutes >= startMinutes || minutes < endMinutes;
  }

  int _notificationId(String familyId, String eventId) {
    return Object.hash(familyId, eventId).abs() & 0x7fffffff;
  }

  Future<void> scheduleEventReminder({
    required String familyId,
    required String eventId,
    required String title,
    required DateTime scheduledAt,
    required String category,
  }) async {
    await initialize();

    final reminderAt = scheduledAt.subtract(const Duration(minutes: 5));
    if (scheduledAt.isBefore(DateTime.now())) {
      await cancelEventReminder(familyId: familyId, eventId: eventId);
      return;
    }

    final prefs = await _loadPreferences();
    if (!_isCategoryEnabled(prefs, category, title)) {
      await cancelEventReminder(familyId: familyId, eventId: eventId);
      return;
    }

    final quiet = _quietHours(prefs);
    if (quiet != null && _isWithinQuietHours(reminderAt, quiet)) {
      await cancelEventReminder(familyId: familyId, eventId: eventId);
      return;
    }

    final scheduleDate = reminderAt.isAfter(DateTime.now())
        ? reminderAt
        : DateTime.now().add(const Duration(seconds: 2));

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );

    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id: _notificationId(familyId, eventId),
      title: 'Upcoming event',
      body: '$title starts in 5 minutes.',
      scheduledDate: tz.TZDateTime.from(scheduleDate, tz.local),
      notificationDetails:
          NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$familyId|$eventId',
    );
  }

  Future<void> cancelEventReminder({
    required String familyId,
    required String eventId,
  }) async {
    await initialize();
    await _plugin.cancel(id: _notificationId(familyId, eventId));
  }

  Future<void> showTestNotificationNow() async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      id: 999999,
      title: 'StitchSync notifications ready',
      body: 'Local reminders are active on this device.',
      notificationDetails:
          NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> syncUpcomingEventReminders() async {
    await initialize();

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final now = DateTime.now();
    final until = now.add(const Duration(days: 120));

    final families = await _firestore
        .collection('families')
        .where('member_uids', arrayContains: uid)
        .get();

    for (final familyDoc in families.docs) {
      final familyId = familyDoc.id;
      final events = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('events')
          .where('scheduled_at', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('scheduled_at', isLessThanOrEqualTo: Timestamp.fromDate(until))
          .limit(300)
          .get();

      for (final eventDoc in events.docs) {
        final data = eventDoc.data();
        if ((data['completed'] as bool?) ?? false) {
          await cancelEventReminder(familyId: familyId, eventId: eventDoc.id);
          continue;
        }

        final scheduledTs = data['scheduled_at'];
        if (scheduledTs is! Timestamp) {
          continue;
        }

        final title = (data['title'] as String?)?.trim();
        final category = (data['category'] as String?)?.trim() ?? 'general';
        if (title == null || title.isEmpty) {
          continue;
        }

        await scheduleEventReminder(
          familyId: familyId,
          eventId: eventDoc.id,
          title: title,
          scheduledAt: scheduledTs.toDate(),
          category: category,
        );
      }
    }
  }
}

class TimeOfDayPair {
  final ({int hour, int minute}) start;
  final ({int hour, int minute}) end;

  const TimeOfDayPair({
    required this.start,
    required this.end,
  });
}
