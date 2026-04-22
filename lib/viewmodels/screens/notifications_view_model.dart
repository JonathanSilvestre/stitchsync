import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/notification_service.dart';
import '../base_view_model.dart';

class NotificationsViewModel extends BaseViewModel {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final NotificationService notificationService;

  NotificationsViewModel({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance,
        notificationService = notificationService ?? NotificationService.instance;

  Future<void> initializeNotifications() async {
    await notificationService.initialize();
    await notificationService.requestPermissions();
  }

  Future<User?> getCurrentUserOrWait() async {
    final current = auth.currentUser;
    if (current != null) {
      return current;
    }

    return auth
        .authStateChanges()
        .firstWhere((u) => u != null)
        .timeout(const Duration(seconds: 2), onTimeout: () => null);
  }

  Future<Map<String, dynamic>?> loadPreferencesWithState({
    String? errorMessage,
  }) async {
    startLoading();
    try {
      final user = await getCurrentUserOrWait();
      if (user == null) {
        setSuccess();
        return null;
      }

      final doc = await firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? <String, dynamic>{};
      final rawPrefs = data['notification_preferences'];
      final prefs = rawPrefs is Map
          ? Map<String, dynamic>.from(rawPrefs)
          : <String, dynamic>{};

      setSuccess();
      return prefs;
    } catch (e) {
      setFailure(errorMessage ?? 'Could not load notification settings.');
      return null;
    } finally {
      stopLoading();
    }
  }

  Future<bool> savePreferencesWithState({
    required Map<String, dynamic> updates,
    String? errorMessage,
  }) async {
    startLoading();
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('No active user');
      }

      final payload = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      for (final entry in updates.entries) {
        payload['notification_preferences.${entry.key}'] = entry.value;
      }

      await firestore.collection('users').doc(user.uid).set(
            payload,
            SetOptions(merge: true),
          );

      await notificationService.syncUpcomingEventReminders();
      setSuccess();
      return true;
    } catch (e) {
      setFailure(errorMessage ?? 'Could not save notification setting.');
      return false;
    } finally {
      stopLoading();
    }
  }
}
