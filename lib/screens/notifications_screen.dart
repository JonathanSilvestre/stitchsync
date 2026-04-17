import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF0F1930);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _primary = Color(0xFF74B1FF);
  static const Color _secondary = Color(0xFF6D9CFE);
  static const Color _title = Color(0xFFDEE5FF);
  static const Color _muted = Color(0xFFA3AAC4);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService.instance;

  bool _pushEnabled = true;
  bool _feedWater = true;
  bool _walksExercise = true;
  bool _medicationVet = true;
  bool _familyUpdates = false;

  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  bool _isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPreferences = false;
      });
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? <String, dynamic>{};
      final prefsRaw = data['notification_preferences'];
      final prefs = prefsRaw is Map<String, dynamic>
          ? prefsRaw
          : <String, dynamic>{};

      if (!mounted) {
        return;
      }

      setState(() {
        _pushEnabled = (prefs['push_enabled'] as bool?) ?? _pushEnabled;
        _feedWater = (prefs['feed_water'] as bool?) ?? _feedWater;
        _walksExercise = (prefs['walks_exercise'] as bool?) ?? _walksExercise;
        _medicationVet = (prefs['medication_vet'] as bool?) ?? _medicationVet;
        _familyUpdates = (prefs['family_updates'] as bool?) ?? _familyUpdates;
        _quietHoursEnabled =
            (prefs['quiet_hours_enabled'] as bool?) ?? _quietHoursEnabled;
        _quietStart = _timeFromString(prefs['quiet_hours_start'] as String?) ??
            _quietStart;
        _quietEnd =
            _timeFromString(prefs['quiet_hours_end'] as String?) ?? _quietEnd;
        _isLoadingPreferences = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPreferences = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load notification settings.')),
      );
    }
  }

  TimeOfDay? _timeFromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
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

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeToStorage(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDisplayTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _savePreferences(Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No active user');
    }

    final payload = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
    };

    for (final entry in updates.entries) {
      payload['notification_preferences.${entry.key}'] = entry.value;
    }

    await _firestore.collection('users').doc(user.uid).set(
          payload,
          SetOptions(merge: true),
        );

    await _notificationService.syncUpcomingEventReminders();
  }

  Future<void> _toggleWithRollback({
    required bool oldValue,
    required ValueChanged<bool> localSet,
    required String storageKey,
    required bool newValue,
  }) async {
    localSet(newValue);

    try {
      await _savePreferences({storageKey: newValue});
    } catch (_) {
      if (!mounted) {
        return;
      }
      localSet(oldValue);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save notification setting.')),
      );
    }
  }

  Future<void> _configureQuietHours() async {
    final pickedStart = await showTimePicker(
      context: context,
      initialTime: _quietStart,
      helpText: 'Select quiet hours start',
    );
    if (pickedStart == null || !mounted) {
      return;
    }

    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: _quietEnd,
      helpText: 'Select quiet hours end',
    );
    if (pickedEnd == null || !mounted) {
      return;
    }

    final oldStart = _quietStart;
    final oldEnd = _quietEnd;
    final oldEnabled = _quietHoursEnabled;

    setState(() {
      _quietStart = pickedStart;
      _quietEnd = pickedEnd;
      _quietHoursEnabled = true;
    });

    try {
      await _savePreferences({
        'quiet_hours_enabled': true,
        'quiet_hours_start': _timeToStorage(pickedStart),
        'quiet_hours_end': _timeToStorage(pickedEnd),
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _quietStart = oldStart;
        _quietEnd = oldEnd;
        _quietHoursEnabled = oldEnabled;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save quiet hours.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF08142A),
                    _bg,
                    const Color(0xFF030A17),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -140,
            right: -90,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _secondary.withValues(alpha: 0.18),
                    _secondary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: _isLoadingPreferences
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPushHeader(),
                              const SizedBox(height: 16),
                              _buildPushCard(),
                              const SizedBox(height: 24),
                              _buildQuietHoursCard(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          color: _surfaceHigh.withValues(alpha: 0.60),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: _primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'Notifications',
                style: TextStyle(
                  color: _title,
                  fontSize: 33,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPushHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Push Notifications',
                style: TextStyle(
                  color: _title,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Stay updated in real-time about your pets',
                style: TextStyle(
                  color: _muted,
                  fontSize: 18,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: _pushEnabled,
          onChanged: (value) {
            final oldPush = _pushEnabled;
            final oldFeedWater = _feedWater;
            final oldWalksExercise = _walksExercise;
            final oldMedicationVet = _medicationVet;
            final oldFamilyUpdates = _familyUpdates;

            setState(() {
              _pushEnabled = value;
              if (!value) {
                _feedWater = false;
                _walksExercise = false;
                _medicationVet = false;
                _familyUpdates = false;
              }
            });

            _savePreferences({
              'push_enabled': value,
              if (!value) 'feed_water': false,
              if (!value) 'walks_exercise': false,
              if (!value) 'medication_vet': false,
              if (!value) 'family_updates': false,
            }).catchError((_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _pushEnabled = oldPush;
                _feedWater = oldFeedWater;
                _walksExercise = oldWalksExercise;
                _medicationVet = oldMedicationVet;
                _familyUpdates = oldFamilyUpdates;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not save notification setting.')),
              );
            });
          },
          activeThumbColor: const Color(0xFFD9ECFF),
          activeTrackColor: _primary,
          inactiveThumbColor: const Color(0xFFB5BED2),
          inactiveTrackColor: _surfaceHigh,
        ),
      ],
    );
  }

  Widget _buildPushCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _PushCategoryTile(
            icon: Icons.restaurant,
            iconColor: _secondary,
            iconBg: const Color(0xFF172A4C),
            title: 'Feeding & Water',
            value: _feedWater,
            onChanged: !_pushEnabled
                ? null
                : (value) => _toggleWithRollback(
                      oldValue: _feedWater,
                      localSet: (v) => setState(() => _feedWater = v),
                      storageKey: 'feed_water',
                      newValue: value,
                    ),
          ),
          const SizedBox(height: 12),
          _PushCategoryTile(
            icon: Icons.directions_walk,
            iconColor: const Color(0xFFA6D9C2),
            iconBg: const Color(0xFF193035),
            title: 'Walks & Exercise',
            value: _walksExercise,
            onChanged: !_pushEnabled
                ? null
                : (value) => _toggleWithRollback(
                      oldValue: _walksExercise,
                      localSet: (v) => setState(() => _walksExercise = v),
                      storageKey: 'walks_exercise',
                      newValue: value,
                    ),
          ),
          const SizedBox(height: 12),
          _PushCategoryTile(
            icon: Icons.medical_services_outlined,
            iconColor: const Color(0xFFFF8E9A),
            iconBg: const Color(0xFF3A1B2D),
            title: 'Medication & Vet',
            value: _medicationVet,
            onChanged: !_pushEnabled
                ? null
                : (value) => _toggleWithRollback(
                      oldValue: _medicationVet,
                      localSet: (v) => setState(() => _medicationVet = v),
                      storageKey: 'medication_vet',
                      newValue: value,
                    ),
          ),
          const SizedBox(height: 12),
          _PushCategoryTile(
            icon: Icons.group,
            iconColor: const Color(0xFFFFC077),
            iconBg: const Color(0xFF30261A),
            title: 'Family Updates',
            value: _familyUpdates,
            onChanged: !_pushEnabled
                ? null
                : (value) => _toggleWithRollback(
                      oldValue: _familyUpdates,
                      localSet: (v) => setState(() => _familyUpdates = v),
                      storageKey: 'family_updates',
                      newValue: value,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1D40),
            Color(0xFF121F4A),
            Color(0xFF16203A),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 12, 30, 0.40),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            bottom: -4,
            child: Icon(
              Icons.pets,
              size: 100,
              color: _title.withValues(alpha: 0.13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Quiet Hours',
                      style: TextStyle(
                        color: _title,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _quietHoursEnabled,
                    onChanged: (value) {
                      final oldValue = _quietHoursEnabled;
                      setState(() {
                        _quietHoursEnabled = value;
                      });

                      _savePreferences({'quiet_hours_enabled': value}).catchError((_) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _quietHoursEnabled = oldValue;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not save quiet hours.')),
                        );
                      });
                    },
                    activeThumbColor: const Color(0xFFD9ECFF),
                    activeTrackColor: _primary,
                    inactiveThumbColor: const Color(0xFFB5BED2),
                    inactiveTrackColor: _surfaceHigh,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Automatically silence notifications during your sleep schedule.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Current: ${_formatDisplayTime(_quietStart)} - ${_formatDisplayTime(_quietEnd)}',
                style: const TextStyle(
                  color: _title,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF74B1FF), Color(0xFF5FA3F6)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _configureQuietHours,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: const Color(0xFF0E2C52),
                    minimumSize: const Size(140, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Configure'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PushCategoryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _PushCategoryTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1530),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFDEE5FF),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged == null ? null : (newValue) => onChanged!(newValue ?? false),
            activeColor: const Color(0xFF2D8BE3),
            checkColor: Colors.white,
            side: BorderSide(
              color: const Color(0xFF8A94A8).withValues(alpha: 0.35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

