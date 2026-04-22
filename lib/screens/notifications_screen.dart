import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_i18n.dart';
import '../viewmodels/screens/notifications_view_model.dart';

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

  final NotificationsViewModel _viewModel = NotificationsViewModel();

  bool _pushEnabled = true;
  bool _feedWater = true;
  bool _walksExercise = true;
  bool _medicationVet = true;
  bool _familyUpdates = false;

  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  bool _isLoadingPreferences = true;
  final Set<Future<void>> _pendingSaves = <Future<void>>{};

  static const String _prefPushEnabled = 'notifications.push_enabled';
  static const String _prefFeedWater = 'notifications.feed_water';
  static const String _prefWalksExercise = 'notifications.walks_exercise';
  static const String _prefMedicationVet = 'notifications.medication_vet';
  static const String _prefFamilyUpdates = 'notifications.family_updates';
  static const String _prefQuietHoursEnabled = 'notifications.quiet_hours_enabled';
  static const String _prefQuietHoursStart = 'notifications.quiet_hours_start';
  static const String _prefQuietHoursEnd = 'notifications.quiet_hours_end';

  void _onViewModelChanged() {
    if (!mounted) {
      return;
    }
    final message = _viewModel.uiMessage;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(message))),
      );
      _viewModel.clearUiMessage();
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _viewModel.initializeNotifications();
    await _loadPreferencesFromLocal();
    await _loadPreferences();
  }

  Future<void> _loadPreferencesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _pushEnabled = prefs.getBool(_prefPushEnabled) ?? _pushEnabled;
      _feedWater = prefs.getBool(_prefFeedWater) ?? _feedWater;
      _walksExercise = prefs.getBool(_prefWalksExercise) ?? _walksExercise;
      _medicationVet = prefs.getBool(_prefMedicationVet) ?? _medicationVet;
      _familyUpdates = prefs.getBool(_prefFamilyUpdates) ?? _familyUpdates;
      _quietHoursEnabled =
          prefs.getBool(_prefQuietHoursEnabled) ?? _quietHoursEnabled;
      _quietStart =
          _timeFromString(prefs.getString(_prefQuietHoursStart)) ?? _quietStart;
      _quietEnd = _timeFromString(prefs.getString(_prefQuietHoursEnd)) ?? _quietEnd;
    });
  }

  Future<void> _savePreferencesToLocal(Map<String, dynamic> updates) async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in updates.entries) {
      switch (entry.key) {
        case 'push_enabled':
          await prefs.setBool(_prefPushEnabled, _boolFromDynamic(entry.value, _pushEnabled));
          break;
        case 'feed_water':
          await prefs.setBool(_prefFeedWater, _boolFromDynamic(entry.value, _feedWater));
          break;
        case 'walks_exercise':
          await prefs.setBool(
            _prefWalksExercise,
            _boolFromDynamic(entry.value, _walksExercise),
          );
          break;
        case 'medication_vet':
          await prefs.setBool(
            _prefMedicationVet,
            _boolFromDynamic(entry.value, _medicationVet),
          );
          break;
        case 'family_updates':
          await prefs.setBool(
            _prefFamilyUpdates,
            _boolFromDynamic(entry.value, _familyUpdates),
          );
          break;
        case 'quiet_hours_enabled':
          await prefs.setBool(
            _prefQuietHoursEnabled,
            _boolFromDynamic(entry.value, _quietHoursEnabled),
          );
          break;
        case 'quiet_hours_start':
          await prefs.setString(_prefQuietHoursStart, entry.value.toString());
          break;
        case 'quiet_hours_end':
          await prefs.setString(_prefQuietHoursEnd, entry.value.toString());
          break;
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await _viewModel.loadPreferencesWithState(
      errorMessage: 'Could not load notification settings.',
    );

    if (!mounted) {
      return;
    }

    if (prefs == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPreferences = false;
      });
      return;
    }

    setState(() {
      _pushEnabled = _boolFromDynamic(prefs['push_enabled'], _pushEnabled);
      _feedWater = _boolFromDynamic(prefs['feed_water'], _feedWater);
      _walksExercise = _boolFromDynamic(
        prefs['walks_exercise'],
        _walksExercise,
      );
      _medicationVet = _boolFromDynamic(prefs['medication_vet'], _medicationVet);
      _familyUpdates = _boolFromDynamic(prefs['family_updates'], _familyUpdates);
      _quietHoursEnabled = _boolFromDynamic(
        prefs['quiet_hours_enabled'],
        _quietHoursEnabled,
      );
      _quietStart = _timeFromString(prefs['quiet_hours_start']?.toString()) ??
          _quietStart;
      _quietEnd = _timeFromString(prefs['quiet_hours_end']?.toString()) ?? _quietEnd;
      _isLoadingPreferences = false;
    });
  }

  bool _boolFromDynamic(dynamic value, bool fallback) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
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
    await _savePreferencesToLocal(updates);
    final ok = await _viewModel.savePreferencesWithState(
      updates: updates,
      errorMessage: 'Could not save notification setting.',
    );
    if (!ok) {
      throw Exception('Cloud save failed');
    }
  }

  void _trackSave(Future<void> op) {
    _pendingSaves.add(op);
    op.whenComplete(() {
      _pendingSaves.remove(op);
    });
  }

  Future<void> _flushPendingSaves() async {
    if (_pendingSaves.isEmpty) {
      return;
    }
    await Future.wait(_pendingSaves.toList(growable: false));
  }

  Future<void> _toggleWithRollback({
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('Could not save notification setting.')} (cloud)')),
      );
    }
  }

  Future<void> _configureQuietHours() async {
    final pickedStart = await showTimePicker(
      context: context,
      initialTime: _quietStart,
      helpText: context.tr('Select quiet hours start'),
    );
    if (pickedStart == null || !mounted) {
      return;
    }

    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: _quietEnd,
      helpText: context.tr('Select quiet hours end'),
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
        SnackBar(content: Text(context.tr('Could not save quiet hours.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _flushPendingSaves().then((_) {
          if (!mounted) {
            return;
          }
          Navigator.of(this.context).pop();
        });
      },
      child: Scaffold(
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
                onPressed: () async {
                  final navigator = Navigator.of(this.context);
                  await _flushPendingSaves();
                  if (!mounted) {
                    return;
                  }
                  navigator.pop();
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: _primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                context.tr('Notifications'),
                style: const TextStyle(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Push Notifications'),
                style: const TextStyle(
                  color: _title,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('Stay updated in real-time about your pets'),
                style: const TextStyle(
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
            setState(() {
              _pushEnabled = value;
              if (!value) {
                _feedWater = false;
                _walksExercise = false;
                _medicationVet = false;
                _familyUpdates = false;
              }
            });

            _trackSave(_savePreferences({
              'push_enabled': value,
              if (!value) 'feed_water': false,
              if (!value) 'walks_exercise': false,
              if (!value) 'medication_vet': false,
              if (!value) 'family_updates': false,
            }).catchError((_) {
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${context.tr('Could not save notification setting.')} (cloud)')),
              );
            }).then((_) {}));
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
            title: context.tr('Feeding & Water'),
            value: _feedWater,
            onChanged: !_pushEnabled
                ? null
                : (value) => _trackSave(_toggleWithRollback(
                      localSet: (v) => setState(() => _feedWater = v),
                      storageKey: 'feed_water',
                      newValue: value,
                    )),
          ),
          const SizedBox(height: 12),
          _PushCategoryTile(
            icon: Icons.directions_walk,
            iconColor: const Color(0xFFA6D9C2),
            iconBg: const Color(0xFF193035),
            title: context.tr('Walks & Exercise'),
            value: _walksExercise,
            onChanged: !_pushEnabled
                ? null
                : (value) => _trackSave(_toggleWithRollback(
                      localSet: (v) => setState(() => _walksExercise = v),
                      storageKey: 'walks_exercise',
                      newValue: value,
                    )),
          ),
          const SizedBox(height: 12),
          _PushCategoryTile(
            icon: Icons.medical_services_outlined,
            iconColor: const Color(0xFFFF8E9A),
            iconBg: const Color(0xFF3A1B2D),
            title: context.tr('Medication & Vet'),
            value: _medicationVet,
            onChanged: !_pushEnabled
                ? null
                : (value) => _trackSave(_toggleWithRollback(
                      localSet: (v) => setState(() => _medicationVet = v),
                      storageKey: 'medication_vet',
                      newValue: value,
                    )),
          ),
          const SizedBox(height: 12),
          _PushCategoryTile(
            icon: Icons.group,
            iconColor: const Color(0xFFFFC077),
            iconBg: const Color(0xFF30261A),
            title: context.tr('Family Updates'),
            value: _familyUpdates,
            onChanged: !_pushEnabled
                ? null
                : (value) => _trackSave(_toggleWithRollback(
                      localSet: (v) => setState(() => _familyUpdates = v),
                      storageKey: 'family_updates',
                      newValue: value,
                    )),
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
                  Expanded(
                    child: Text(
                      context.tr('Quiet Hours'),
                      style: const TextStyle(
                        color: _title,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _quietHoursEnabled,
                    onChanged: (value) {
                      setState(() {
                        _quietHoursEnabled = value;
                      });

                      _trackSave(_savePreferences({'quiet_hours_enabled': value}).catchError((_) {
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${context.tr('Could not save quiet hours.')} (cloud)')),
                        );
                      }).then((_) {}));
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
                  child: Text(context.tr('Configure')),
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

