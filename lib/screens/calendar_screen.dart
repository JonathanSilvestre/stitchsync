import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/event_service.dart';
import 'new_event_screen.dart';

class CalendarTabContent extends StatefulWidget {
  final VoidCallback onNewEvent;
  final String? familyId;
  final String? petId;
  final String? selectedPetName;

  const CalendarTabContent({
    super.key,
    required this.onNewEvent,
    this.familyId,
    this.petId,
    this.selectedPetName,
  });

  @override
  State<CalendarTabContent> createState() => _CalendarTabContentState();
}

class _CalendarTabContentState extends State<CalendarTabContent> {
  final EventService _eventService = EventService();
  late final String _randomProTip;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _proTips = [
    'If a task takes less than two minutes, add it right away to keep momentum.',
    'Group similar pet tasks together to reduce stress for your dog.',
    'Set medical reminders earlier in the day to avoid missing the clinic schedule.',
    'Attach a short note to each event so family members know the exact expectation.',
    'Use recurring events for routines and one-time events for exceptions.',
    'After completing a task, mark it as done immediately so everyone sees the latest status.',
    'For grooming or vet appointments, prepare supplies the night before.',
  ];

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    _randomProTip = _proTips[Random().nextInt(_proTips.length)];
  }

  DateTime get _minMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 6, 1);
  }

  DateTime get _maxMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 12, 1);
  }

  String get _selectedPetName {
    final name = widget.selectedPetName?.trim();
    return name != null && name.isNotEmpty ? name : 'Pet';
  }

  String _monthLabel(DateTime month) {
    return '${_monthNames[month.month - 1]} ${month.year}';
  }

  String _monthShort(DateTime month) {
    return _monthNames[month.month - 1].substring(0, 3);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _sameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  void _changeMonth(int delta) {
    final candidate = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    if (candidate.isBefore(_minMonth) || candidate.isAfter(_maxMonth)) {
      return;
    }

    setState(() {
      _visibleMonth = candidate;
      if (!_sameMonth(_selectedDay, _visibleMonth)) {
        _selectedDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      }
    });
  }

  String _eventTimeTop(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  String _eventTimeBottom(DateTime dt) {
    return dt.hour >= 12 ? 'PM' : 'AM';
  }

  String _eventLocation(Map<String, dynamic> data) {
    final category = (data['category'] as String?)?.trim();
    if (category != null && category.isNotEmpty) {
      return 'Category: ${category[0].toUpperCase()}${category.substring(1)}';
    }
    return 'Scheduled activity';
  }

  String _detailLines(String text) {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.isEmpty) {
      return 'No data';
    }

    final words = normalized.split(RegExp(r'\s+'));
    if (words.length <= 2) {
      return normalized;
    }

    final first = words.take(2).join(' ');
    final rest = words.skip(2).take(2).join(' ');
    return rest.isEmpty ? first : '$first\n$rest';
  }

  bool _isReminderCategory(String category) {
    final c = category.toLowerCase();
    return c.contains('vet') ||
        c.contains('vaccine') ||
        c.contains('vacuna') ||
        c.contains('medication') ||
        c.contains('medicine') ||
        c.contains('med') ||
        c.contains('flea') ||
        c.contains('groom') ||
        c.contains('booster') ||
        c.contains('rabies') ||
        c.contains('health');
  }

  IconData _eventIcon({required String category, required String title}) {
    final lookup = '${category.toLowerCase()} ${title.toLowerCase()}';

    if (lookup.contains('flea')) {
      return Icons.medication_rounded;
    }
    if (lookup.contains('vet')) {
      return Icons.medical_services_rounded;
    }
    if (lookup.contains('medications') ||
        lookup.contains('medication') ||
        lookup.contains('medicine') ||
        lookup.contains('pill')) {
      return Icons.local_pharmacy_rounded;
    }

    if (lookup.contains('vaccine') ||
        lookup.contains('vacuna') ||
        lookup.contains('booster') ||
        lookup.contains('rabies')) {
      return Icons.vaccines_rounded;
    }
    if (lookup.contains('med') || lookup.contains('health')) {
      return Icons.medical_services_outlined;
    }
    if (lookup.contains('groom')) {
      return Icons.content_cut_rounded;
    }
    if (lookup.contains('walk')) {
      return Icons.directions_walk;
    }
    if (lookup.contains('food') || lookup.contains('feed') || lookup.contains('meal')) {
      return Icons.restaurant;
    }
    if (lookup.contains('treat')) {
      return Icons.cookie_rounded;
    }
    return Icons.event;
  }

  ({Color bg, Color fg}) _iconPalette(IconData icon) {
    if (icon == Icons.vaccines_rounded ||
        icon == Icons.medical_services_outlined ||
        icon == Icons.medical_services_rounded) {
      return (bg: const Color(0xFF3A2E60), fg: const Color(0xFFE8AAFF));
    }
    if (icon == Icons.medication_rounded) {
      return (bg: const Color(0xFF3A2E60), fg: const Color(0xFFFF7D7D));
    }
    if (icon == Icons.local_pharmacy_rounded) {
      return (bg: const Color(0xFF263D35), fg: const Color(0xFF95DEBA));
    }
    if (icon == Icons.content_cut_rounded) {
      return (bg: const Color(0xFF0B2A5D), fg: const Color(0xFF82C2FF));
    }
    if (icon == Icons.directions_walk) {
      return (bg: const Color(0xFF1F3258), fg: const Color(0xFF74B1FF));
    }
    if (icon == Icons.restaurant || icon == Icons.cookie_rounded) {
      return (bg: const Color(0xFF3B2F23), fg: const Color(0xFFF0C686));
    }
    return (bg: const Color(0xFF0B2A5D), fg: const Color(0xFF74B1FF));
  }

  Future<bool> _confirmDelete({
    required String title,
    required String actionLabel,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1930),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA3AAC4).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDEE5FF),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFF8E8E)),
                    label: Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Color(0xFFFF8E8E),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFFA3AAC4),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _deleteEvent({
    required String familyId,
    required String eventId,
    required String title,
  }) async {
    final shouldDelete = await _confirmDelete(
      title: title,
      actionLabel: 'Delete Event',
    );

    if (!shouldDelete) return;

    try {
      await _eventService.deleteEvent(familyId: familyId, eventId: eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete event.')),
      );
    }
  }

  Future<void> _deleteSeries({
    required String familyId,
    required String seriesId,
    required String title,
  }) async {
    final shouldDelete = await _confirmDelete(
      title: title,
      actionLabel: 'Delete Full Series',
    );

    if (!shouldDelete) return;

    try {
      await _eventService.deleteSeries(familyId: familyId, seriesId: seriesId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serie eliminada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete series.')),
      );
    }
  }

  Future<void> _setEventCompleted({
    required String familyId,
    required String eventId,
    required bool completed,
  }) async {
    try {
      await _eventService.setEventCompleted(
        familyId: familyId,
        eventId: eventId,
        completed: completed,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            completed ? 'Evento marcado como realizado.' : 'Evento marcado como pendiente.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update event status.')),
      );
    }
  }

  Future<void> _openEventActions({
    required String familyId,
    required QueryDocumentSnapshot<Map<String, dynamic>> eventDoc,
    required String title,
  }) async {
    final data = eventDoc.data();
    final seriesId = (data['series_id'] as String?)?.trim();
    final hasSeries = seriesId != null && seriesId.isNotEmpty;
    final isCompleted = (data['completed'] as bool?) ?? false;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1930),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA3AAC4).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, 'edit'),
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF74B1FF)),
                    label: const Text(
                      'Edit Event',
                      style: TextStyle(
                        color: Color(0xFFDEE5FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, 'toggle_complete'),
                    icon: Icon(
                      isCompleted
                          ? Icons.radio_button_unchecked_rounded
                          : Icons.check_circle_outline_rounded,
                      color: const Color(0xFF95DEBA),
                    ),
                    label: Text(
                      isCompleted ? 'Mark as Pending' : 'Complete Event',
                      style: const TextStyle(
                        color: Color(0xFF95DEBA),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, 'delete_one'),
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFF8E8E)),
                    label: const Text(
                      'Delete Event',
                      style: TextStyle(
                        color: Color(0xFFFF8E8E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (hasSeries)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(sheetContext, 'delete_series'),
                      icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFFF8E8E)),
                      label: const Text(
                        'Delete Full Series',
                        style: TextStyle(
                          color: Color(0xFFFF8E8E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null || !mounted) return;

    if (action == 'edit') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NewEventScreen(
            familyId: familyId,
            petId: (data['pet_id'] as String?)?.trim(),
            eventId: eventDoc.id,
            initialEventData: data,
          ),
        ),
      );
      return;
    }

    if (action == 'delete_one') {
      await _deleteEvent(
        familyId: familyId,
        eventId: eventDoc.id,
        title: title,
      );
      return;
    }

    if (action == 'toggle_complete') {
      await _setEventCompleted(
        familyId: familyId,
        eventId: eventDoc.id,
        completed: !isCompleted,
      );
      return;
    }

    if (action == 'delete_series' && hasSeries) {
      await _deleteSeries(
        familyId: familyId,
        seriesId: seriesId,
        title: title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyId = widget.familyId;

    if (familyId == null || familyId.trim().isEmpty) {
      return _CalendarContent(
        monthLabel: _monthLabel(_visibleMonth),
        eventsTitle: 'Events for ${_monthShort(_selectedDay)} ${_selectedDay.day}',
        canGoPrev: false,
        canGoNext: false,
        onPrevMonth: null,
        onNextMonth: null,
        onNewEvent: widget.onNewEvent,
        daysWithEvents: const <int>{},
        visibleMonth: _visibleMonth,
        selectedDay: _selectedDay,
        onDayTap: (day) {
          setState(() {
            _selectedDay = day;
          });
        },
        upcomingDetail: 'No upcoming\nevents',
        reminderDetail: 'No\nreminders',
        upcomingIcon: Icons.event,
        upcomingIconBg: const Color(0xFF0B2A5D),
        upcomingIconColor: const Color(0xFF74B1FF),
        reminderIcon: Icons.notifications_none_rounded,
        reminderIconBg: const Color(0xFF0B2A5D),
        reminderIconColor: const Color(0xFF74B1FF),
        proTipText: _randomProTip,
        eventCards: const [
          _EventCard(
            accent: Color(0xFF74B1FF),
            timeTop: '--:--',
            timeBottom: '--',
            title: 'No events yet',
            location: 'Create your first event',
            note: null,
            chip: null,
            avatars: false,
          ),
        ],
      );
    }

    final rangeStart = DateTime(_visibleMonth.year, _visibleMonth.month - 6, 1);
    final rangeEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 2, 1);

    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _eventService.streamEventsInRange(
        familyId: familyId,
        start: rangeStart,
        end: rangeEnd,
        petId: widget.petId,
      ),
      builder: (context, snapshot) {
        final docs = snapshot.data ?? const [];

        final allEvents = docs
            .map((doc) {
              final data = doc.data();
              final ts = data['scheduled_at'];
              if (ts is! Timestamp) {
                return null;
              }
              return (doc: doc, when: ts.toDate());
            })
            .whereType<({QueryDocumentSnapshot<Map<String, dynamic>> doc, DateTime when})>()
            .toList(growable: false);

        final daysWithEvents = allEvents
            .where((item) => _sameMonth(item.when, _visibleMonth))
            .map((item) => item.when.day)
            .toSet();

        final selectedEvents = allEvents
            .where((item) => _sameDay(item.when, _selectedDay))
            .toList(growable: false)
          ..sort((a, b) => a.when.compareTo(b.when));

        final now = DateTime.now();
        final upcoming = allEvents
            .where((item) => item.when.isAfter(now))
            .toList(growable: false)
          ..sort((a, b) => a.when.compareTo(b.when));

        final upcomingEvent = upcoming.isNotEmpty ? upcoming.first : null;
        final todayImportant = allEvents
            .where((item) => _sameDay(item.when, now))
            .where((item) {
              final category = (item.doc.data()['category'] as String?) ?? '';
              return _isReminderCategory(category);
            })
            .toList(growable: false)
          ..sort((a, b) => a.when.compareTo(b.when));

        final reminderEvent = todayImportant.isNotEmpty ? todayImportant.first : null;

        final upcomingTitle = upcomingEvent != null
            ? (upcomingEvent.doc.data()['title'] as String?)?.trim() ?? 'Next event'
            : 'No upcoming events';

        final upcomingCategory =
            upcomingEvent != null ? ((upcomingEvent.doc.data()['category'] as String?) ?? '') : '';
        final upcomingIcon = _eventIcon(
          category: upcomingCategory,
          title: upcomingTitle,
        );
        final upcomingPalette = _iconPalette(upcomingIcon);

        final reminderTitle = reminderEvent != null
            ? (reminderEvent.doc.data()['title'] as String?)?.trim() ?? 'No important event today'
            : 'No important event today';

        IconData reminderIcon = Icons.notifications_none_rounded;
        ({Color bg, Color fg}) reminderPalette =
            (bg: const Color(0xFF0B2A5D), fg: const Color(0xFF74B1FF));
        if (reminderEvent != null) {
          final category = (reminderEvent.doc.data()['category'] as String?) ?? '';
          reminderIcon = _eventIcon(category: category, title: reminderTitle);
          reminderPalette = _iconPalette(reminderIcon);
        }

        final eventCards = selectedEvents.isEmpty
            ? const <Widget>[
                _EventCard(
                  accent: Color(0xFF74B1FF),
                  timeTop: '--:--',
                  timeBottom: '--',
                  title: 'No events for this day',
                  location: 'Pick another date or create a new event',
                  note: null,
                  chip: null,
                  avatars: false,
                ),
              ]
            : selectedEvents.map((item) {
                final data = item.doc.data();
                final title = (data['title'] as String?)?.trim().isNotEmpty == true
                    ? '${(data['title'] as String).trim()} • $_selectedPetName'
                    : 'Event • $_selectedPetName';
                final note = (data['note'] as String?)?.trim();
                final category = (data['category'] as String?)?.trim();
                final completed = (data['completed'] as bool?) ?? false;
                final completedBy = (data['completed_by_username'] as String?)?.trim();
                final chip =
                  completed
                    ? 'DONE'
                    : (category != null && category.isNotEmpty ? category.toUpperCase() : null);

                final baseNote = note != null && note.isNotEmpty ? note : null;
                final completionNote = completed
                  ? 'Completed by ${completedBy?.isNotEmpty == true ? completedBy : 'a family member'}'
                  : null;
                final combinedNote = baseNote != null && completionNote != null
                  ? '$baseNote\n$completionNote'
                  : (completionNote ?? baseNote);

                return _EventCard(
                  accent: const Color(0xFF74B1FF),
                  timeTop: _eventTimeTop(item.when),
                  timeBottom: _eventTimeBottom(item.when),
                  title: completed ? 'Completed: $title' : title,
                  location: _eventLocation(data),
                  note: combinedNote,
                  chip: chip,
                  avatars: false,
                  completed: completed,
                  onMoreTap: () => _openEventActions(
                    familyId: familyId,
                    eventDoc: item.doc,
                    title: title,
                  ),
                );
              }).toList(growable: false);

        return _CalendarContent(
          monthLabel: _monthLabel(_visibleMonth),
          eventsTitle: 'Events for ${_monthShort(_selectedDay)} ${_selectedDay.day}',
          canGoPrev: !_sameMonth(_visibleMonth, _minMonth),
          canGoNext: !_sameMonth(_visibleMonth, _maxMonth),
          onPrevMonth: () => _changeMonth(-1),
          onNextMonth: () => _changeMonth(1),
          onNewEvent: widget.onNewEvent,
          daysWithEvents: daysWithEvents,
          visibleMonth: _visibleMonth,
          selectedDay: _selectedDay,
          onDayTap: (day) {
            setState(() {
              _selectedDay = day;
            });
          },
          upcomingDetail: _detailLines(upcomingTitle),
          reminderDetail: _detailLines(reminderTitle),
          upcomingIcon: upcomingIcon,
          upcomingIconBg: upcomingPalette.bg,
          upcomingIconColor: upcomingPalette.fg,
          reminderIcon: reminderIcon,
          reminderIconBg: reminderPalette.bg,
          reminderIconColor: reminderPalette.fg,
          proTipText: _randomProTip,
          eventCards: eventCards,
        );
      },
    );
  }
}

class _CalendarContent extends StatelessWidget {
  final String monthLabel;
  final String eventsTitle;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback onNewEvent;
  final Set<int> daysWithEvents;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDayTap;
  final String upcomingDetail;
  final String reminderDetail;
  final IconData upcomingIcon;
  final Color upcomingIconBg;
  final Color upcomingIconColor;
  final IconData reminderIcon;
  final Color reminderIconBg;
  final Color reminderIconColor;
  final String proTipText;
  final List<Widget> eventCards;

  const _CalendarContent({
    required this.monthLabel,
    required this.eventsTitle,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onNewEvent,
    required this.daysWithEvents,
    required this.visibleMonth,
    required this.selectedDay,
    required this.onDayTap,
    required this.upcomingDetail,
    required this.reminderDetail,
    required this.upcomingIcon,
    required this.upcomingIconBg,
    required this.upcomingIconColor,
    required this.reminderIcon,
    required this.reminderIconBg,
    required this.reminderIconColor,
    required this.proTipText,
    required this.eventCards,
  });

  static const Color _bg = Color(0xFF060E20);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF08132A),
                  _bg,
                  const Color(0xFF030916),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -70,
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(109, 156, 254, 0.12),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CalendarTopBar(),
                const SizedBox(height: 26),
                const Text(
                  'YOUR SCHEDULE',
                  style: TextStyle(
                    color: Color(0xFF8AA8D8),
                    fontSize: 14,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          monthLabel,
                          style: const TextStyle(
                            color: _textMain,
                            fontSize: 38,
                            letterSpacing: -0.7,
                            height: 0.95,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    _MonthButton(
                      icon: Icons.chevron_left,
                      enabled: canGoPrev,
                      onTap: onPrevMonth,
                    ),
                    const SizedBox(width: 10),
                    _MonthButton(
                      icon: Icons.chevron_right,
                      enabled: canGoNext,
                      onTap: onNextMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _CalendarPanel(
                  visibleMonth: visibleMonth,
                  selectedDay: selectedDay,
                  daysWithEvents: daysWithEvents,
                  onDayTap: onDayTap,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MiniInsightCard(
                        icon: upcomingIcon,
                        iconBg: upcomingIconBg,
                        iconColor: upcomingIconColor,
                        title: 'UPCOMING\nMILESTONE',
                        detail: upcomingDetail,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MiniInsightCard(
                        icon: reminderIcon,
                        iconBg: reminderIconBg,
                        iconColor: reminderIconColor,
                        title: 'REMINDER',
                        detail: reminderDetail,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final shouldWrap = constraints.maxWidth < 360;
                    final title = Text(
                      eventsTitle,
                      style: const TextStyle(
                        color: _textMain,
                        fontSize: 32,
                        letterSpacing: -0.6,
                        fontWeight: FontWeight.w700,
                      ),
                    );

                    final button = DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF74B1FF), Color(0xFF5FA3F6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onNewEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: const Color(0xFF0A2550),
                          minimumSize: const Size(132, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('New Event'),
                      ),
                    );

                    if (shouldWrap) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: button,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 10),
                        button,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                ..._withSpacing(eventCards),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF192540), Color(0xFF1B2B49)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pro Tip',
                        style: TextStyle(
                          color: _textMain,
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        proTipText,
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 17,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _withSpacing(List<Widget> children) {
    if (children.isEmpty) return const [];
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(const SizedBox(height: 14));
      }
    }
    return items;
  }
}

class _CalendarTopBar extends StatelessWidget {
  const _CalendarTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: Image.asset(
            'assets/icon/StitchSyncIcon.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'StitchSync',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF74B1FF),
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const Icon(Icons.notifications_none_rounded, color: Color(0xFFA3AAC4), size: 30),
      ],
    );
  }
}

class _MonthButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _MonthButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF192540),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFFC1CAE0) : const Color(0xFF55607A),
          size: 32,
        ),
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final Set<int> daysWithEvents;
  final ValueChanged<DateTime> onDayTap;

  const _CalendarPanel({
    required this.visibleMonth,
    required this.selectedDay,
    required this.daysWithEvents,
    required this.onDayTap,
  });

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(visibleMonth.year, visibleMonth.month);
    final firstWeekday = firstDay.weekday % 7;
    final prevMonthDays = DateUtils.getDaysInMonth(
      DateTime(visibleMonth.year, visibleMonth.month - 1).year,
      DateTime(visibleMonth.year, visibleMonth.month - 1).month,
    );

    final totalCells = firstWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    final cells = List.generate(rowCount * 7, (index) {
      final dayNumber = index - firstWeekday + 1;
      if (dayNumber < 1) {
        final value = prevMonthDays + dayNumber;
        final date = DateTime(visibleMonth.year, visibleMonth.month - 1, value);
        return _CalendarCell(date: date, label: '$value', isMuted: true);
      }
      if (dayNumber > daysInMonth) {
        final value = dayNumber - daysInMonth;
        final date = DateTime(visibleMonth.year, visibleMonth.month + 1, value);
        return _CalendarCell(date: date, label: '$value', isMuted: true);
      }
      final date = DateTime(visibleMonth.year, visibleMonth.month, dayNumber);
      return _CalendarCell(
        date: date,
        label: '$dayNumber',
        isMuted: false,
        hasEvent: daysWithEvents.contains(dayNumber),
      );
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1930),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              _DayCell(label: 'S', isHeader: true),
              _DayCell(label: 'M', isHeader: true),
              _DayCell(label: 'T', isHeader: true),
              _DayCell(label: 'W', isHeader: true),
              _DayCell(label: 'T', isHeader: true),
              _DayCell(label: 'F', isHeader: true),
              _DayCell(label: 'S', isHeader: true),
            ],
          ),
          const SizedBox(height: 8),
          for (int row = 0; row < rowCount; row++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  for (int col = 0; col < 7; col++)
                    _DayCell(
                      label: cells[row * 7 + col].label,
                      isMuted: cells[row * 7 + col].isMuted,
                      isSelected: _sameDay(cells[row * 7 + col].date, selectedDay),
                      hasEvent: cells[row * 7 + col].hasEvent,
                      onTap: () => onDayTap(cells[row * 7 + col].date),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarCell {
  final DateTime date;
  final String label;
  final bool isMuted;
  final bool hasEvent;

  _CalendarCell({
    required this.date,
    required this.label,
    required this.isMuted,
    this.hasEvent = false,
  });
}

class _DayCell extends StatelessWidget {
  final String label;
  final bool isHeader;
  final bool isSelected;
  final bool isMuted;
  final bool hasEvent;
  final VoidCallback? onTap;

  const _DayCell({
    required this.label,
    this.isHeader = false,
    this.isSelected = false,
    this.isMuted = false,
    this.hasEvent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isHeader
        ? const Color(0xFF6F7E9B)
        : isMuted
            ? const Color(0xFF3D4A67)
            : const Color(0xFFE3E9FA);

    return Expanded(
      child: InkWell(
        onTap: isHeader ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: isSelected
              ? BoxDecoration(
                  color: const Color(0xFF27446E),
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: isHeader ? 13 : 18,
                  fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (!isHeader && hasEvent && !isMuted)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF74B1FF),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String detail;

  const _MiniInsightCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1930),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFAAB4CB),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFE4EAFB),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Color accent;
  final String timeTop;
  final String timeBottom;
  final String title;
  final String location;
  final String? note;
  final String? chip;
  final bool avatars;
  final bool completed;
  final VoidCallback? onMoreTap;

  const _EventCard({
    required this.accent,
    required this.timeTop,
    required this.timeBottom,
    required this.title,
    required this.location,
    required this.note,
    required this.chip,
    required this.avatars,
    this.completed = false,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: completed
              ? const [Color(0xFF0C1528), Color(0xFF0E1B33)]
              : const [Color(0xFF0F1930), Color(0xFF132445)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
              child: Opacity(
                opacity: completed ? 0.72 : 1.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  SizedBox(
                    width: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeTop,
                          style: const TextStyle(
                            color: Color(0xFFC6CFE4),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          timeBottom,
                          style: const TextStyle(
                            color: Color(0xFF6D7A97),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: const Color(0xFFE7ECFB),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: Color(0xFF8793AB),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(
                                  color: Color(0xFFACB5CA),
                                  fontSize: 14,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (chip != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A3A78),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              chip!,
                              style: const TextStyle(
                                color: Color(0xFFE8AAFF),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        if (note != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            note!,
                            style: const TextStyle(
                              color: Color(0xFF7FB2FF),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (avatars) ...[
                          const SizedBox(height: 10),
                          const Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFF2E3952),
                                child: Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Color(0xFFC7D2EA),
                                ),
                              ),
                              SizedBox(width: 6),
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFF253A5F),
                                child: Icon(
                                  Icons.pets,
                                  size: 14,
                                  color: Color(0xFF9CC4FF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onMoreTap,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.more_vert, color: Color(0xFF8F9BB6), size: 20),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
