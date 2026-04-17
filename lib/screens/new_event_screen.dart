import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_i18n.dart';
import '../services/event_service.dart';
import '../services/family_service.dart';
import '../services/pet_service.dart';
import 'home_screen.dart';

class NewEventScreen extends StatefulWidget {
  final String? familyId;
  final String? petId;
  final String? eventId;
  final Map<String, dynamic>? initialEventData;

  const NewEventScreen({
    super.key,
    this.familyId,
    this.petId,
    this.eventId,
    this.initialEventData,
  });

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  final EventService _eventService = EventService();
  final FamilyService _familyService = FamilyService();
  final PetService _petService = PetService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedCategory = 1;
  int _selectedRecurrence = 0;
  final TextEditingController _customDaysController = TextEditingController(text: '2');
  bool _isSaving = false;

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF192540);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);
  static const Color _primary = Color(0xFF74B1FF);

  final List<_CategoryItem> _categories = const [
    _CategoryItem(Icons.medical_services_rounded, 'Vet', Color(0xFFE8AAFF)),
    _CategoryItem(Icons.vaccines_rounded, 'Vaccines', Color(0xFFE8AAFF)),
    _CategoryItem(Icons.directions_walk_rounded, 'Walk', Color(0xFF74B1FF)),
    _CategoryItem(Icons.content_cut_rounded, 'Grooming', Color(0xFF82C2FF)),
    _CategoryItem(Icons.restaurant_rounded, 'Food', Color(0xFF74B1FF)),
    _CategoryItem(Icons.medication_rounded, 'Flea Pipette', Color(0xFFFF7D7D)),
    _CategoryItem(Icons.local_pharmacy_rounded, 'Medications', Color(0xFF95DEBA)),
    _CategoryItem(Icons.inventory_2_rounded, 'Food\nOpening', Color(0xFFE8AAFF)),
    _CategoryItem(Icons.cookie_rounded, 'Treats', Color(0xFF74B1FF)),
    _CategoryItem(Icons.shopping_bag_rounded, 'Bag\nOpening', Color(0xFF8DB6FF)),
    _CategoryItem(Icons.cleaning_services_rounded, 'Wet Wipes', Color(0xFF74B1FF)),
  ];

  static const List<_RecurrenceItem> _recurrenceOptions = [
    _RecurrenceItem('No Repeat', 'none'),
    _RecurrenceItem('Day by Day', 'daily'),
    _RecurrenceItem('Month by Month', 'monthly'),
    _RecurrenceItem('Year by Year', 'yearly'),
    _RecurrenceItem('Custom (Days)', 'custom_days'),
  ];

  bool get _isEditing => widget.eventId != null && widget.eventId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _hydrateInitialValues();
  }

  void _hydrateInitialValues() {
    final data = widget.initialEventData;
    if (data == null) {
      return;
    }

    final title = (data['title'] as String?)?.trim();
    if (title != null && title.isNotEmpty) {
      _titleController.text = title;
    }

    final note = (data['note'] as String?)?.trim();
    if (note != null && note.isNotEmpty) {
      _noteController.text = note;
    }

    final ts = data['scheduled_at'];
    if (ts is Timestamp) {
      final dt = ts.toDate();
      _selectedDate = DateTime(dt.year, dt.month, dt.day);
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }

    final category = ((data['category'] as String?) ?? '').trim().toLowerCase();
    if (category.isNotEmpty) {
      final idx = _categories.indexWhere(
        (item) => item.label.replaceAll('\n', ' ').toLowerCase() == category,
      );
      if (idx >= 0) {
        _selectedCategory = idx;
      }
    }

    final recurrence = ((data['recurrence'] as String?) ?? 'none').trim().toLowerCase();
    final recurrenceIndex = _recurrenceOptions.indexWhere((item) => item.value == recurrence);
    if (recurrenceIndex >= 0) {
      _selectedRecurrence = recurrenceIndex;
    }

    final interval = data['recurrence_interval_days'];
    if (interval is int && interval > 0) {
      _customDaysController.text = interval.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (date != null && mounted) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null && mounted) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _navigateToMainTab(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(initialTab: index),
      ),
      (route) => false,
    );
  }

  Future<String?> _resolveFamilyId() async {
    if (widget.familyId != null && widget.familyId!.trim().isNotEmpty) {
      return widget.familyId!.trim();
    }

    final families = await _familyService.streamFamiliesForCurrentUser().first;
    if (families.isEmpty) {
      return null;
    }

    return families.first.id;
  }

  Future<String?> _resolvePetId(String familyId) async {
    final initialPetId = (widget.initialEventData?['pet_id'] as String?)?.trim();
    if (initialPetId != null && initialPetId.isNotEmpty) {
      return initialPetId;
    }

    if (widget.petId != null && widget.petId!.trim().isNotEmpty) {
      return widget.petId!.trim();
    }

    final pets = await _petService.streamPets(familyId).first;
    if (pets.isEmpty) {
      return null;
    }

    return pets.first.id;
  }

  Future<void> _saveEvent() async {
    if (_isSaving) return;

    final messenger = ScaffoldMessenger.of(context);
    final customRecurrenceError = context.tr('For custom recurrence, enter a number greater than 0.');

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('Enter a title for the event.'))),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('Select event date and time.'))),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final familyId = await _resolveFamilyId();
      if (familyId == null) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr('First create a family to save events.'))),
        );
        return;
      }

      final petId = await _resolvePetId(familyId);
      if (petId == null) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr('You need at least one pet to create events.'))),
        );
        return;
      }

      final date = _selectedDate!;
      final time = _selectedTime!;
      final scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final category = _categories[_selectedCategory].label.replaceAll('\n', ' ').toLowerCase();
      final recurrence = _recurrenceOptions[_selectedRecurrence].value;
      final recurrenceIntervalDays = recurrence == 'custom_days'
          ? int.tryParse(_customDaysController.text.trim()) ?? 0
          : 1;

      if (recurrence == 'custom_days' && recurrenceIntervalDays < 1) {
        setState(() {
          _isSaving = false;
        });
        messenger.showSnackBar(
          SnackBar(content: Text(customRecurrenceError)),
        );
        return;
      }

      if (_isEditing) {
        await _eventService.updateEvent(
          familyId: familyId,
          eventId: widget.eventId!.trim(),
          petId: petId,
          title: title,
          scheduledAt: scheduledAt,
          note: _noteController.text.trim(),
          category: category,
          recurrence: recurrence,
          recurrenceIntervalDays: recurrenceIntervalDays,
        );
      } else {
        await _eventService.addEvent(
          familyId: familyId,
          petId: petId,
          title: title,
          scheduledAt: scheduledAt,
          note: _noteController.text.trim(),
          category: category,
          recurrence: recurrence,
          recurrenceIntervalDays: recurrenceIntervalDays,
        );
      }

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? context.tr('Changes saved successfully')
                : context.tr('Event saved successfully.'),
          ),
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      if (e.code == 'permission-denied') {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.tr('You do not have permission to write events in this family. Check Firestore rules and membership.'),
            ),
          ),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('${context.tr('Could not save event:')} ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('${context.tr('Could not save event:')} $e')),
      );
    }
  }

  String _dateLabel() {
    if (_selectedDate == null) {
      return 'mm/dd/yyyy';
    }

    final d = _selectedDate!;
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  String _timeLabel() {
    if (_selectedTime == null) {
      return '--:-- --';
    }

    final hour = _selectedTime!.hourOfPeriod == 0 ? 12 : _selectedTime!.hourOfPeriod;
    final minute = _selectedTime!.minute.toString().padLeft(2, '0');
    final period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
                  colors: [const Color(0xFF08142B), _bg, const Color(0xFF020915)],
                  stops: const [0, 0.56, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(116, 177, 255, 0.10),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const _TopHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? context.tr('Edit Event') : context.tr('Add Event'),
                          style: TextStyle(
                            color: _textMain,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('Schedule a new activity for your furry companion.'),
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FieldLabel(context.tr('EVENT TITLE')),
                        const SizedBox(height: 8),
                        _InputField(
                          controller: _titleController,
                          hint: context.tr('e.g. Morning Promenade'),
                          focused: true,
                        ),
                        const SizedBox(height: 18),
                        _FieldLabel(context.tr('DATE')),
                        const SizedBox(height: 8),
                        _ActionField(
                          label: _dateLabel(),
                          icon: Icons.calendar_today_outlined,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 18),
                        _FieldLabel(context.tr('TIME')),
                        const SizedBox(height: 8),
                        _ActionField(
                          label: _timeLabel(),
                          icon: Icons.schedule,
                          onTap: _pickTime,
                        ),
                        const SizedBox(height: 18),
                        _FieldLabel(context.tr('REPEAT')),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_recurrenceOptions.length, (index) {
                            final item = _recurrenceOptions[index];
                            final selected = _selectedRecurrence == index;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedRecurrence = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF27446E) : _surface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: selected
                                      ? Border.all(color: const Color(0xFF74B1FF), width: 1)
                                      : null,
                                ),
                                child: Text(
                                  context.tr(item.label),
                                  style: TextStyle(
                                    color:
                                        selected ? const Color(0xFFDEE5FF) : const Color(0xFFBAC7E0),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        if (_recurrenceOptions[_selectedRecurrence].value == 'custom_days') ...[
                          const SizedBox(height: 10),
                          _InputField(
                            controller: _customDaysController,
                            hint: context.tr('Every how many days? (e.g. 3)'),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                        const SizedBox(height: 20),
                        _FieldLabel(context.tr('CATEGORY')),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _categories.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.92,
                          ),
                          itemBuilder: (context, index) {
                            final item = _categories[index];
                            final selected = _selectedCategory == index;

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  _selectedCategory = index;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: selected
                                      ? Border.all(color: const Color(0xFF4E78B3), width: 1.2)
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(item.icon, color: item.color, size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.tr(item.label),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFC5CEE2),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF11264A), Color(0xFF091C37), Color(0xFF123D74)],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -28,
                                top: -18,
                                child: Icon(
                                  Icons.blur_circular,
                                  size: 120,
                                  color: _primary.withValues(alpha: 0.10),
                                ),
                              ),
                              const Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 76,
                                  color: Color(0xFF9FD0FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('Note for Co-Owners'),
                                style: const TextStyle(
                                  color: _textMain,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _noteController,
                                maxLines: 2,
                                style: const TextStyle(color: Color(0xFFCED7EC)),
                                decoration: InputDecoration(
                                  hintText: context.tr('Any specific instructions for this event?'),
                                  hintStyle: TextStyle(color: Color(0xFF5E6D8B)),
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Color(0xFFE8AAFF),
                                    child: Text(
                                      'JD',
                                      style: TextStyle(
                                        color: Color(0xFF243754),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.tr('CREATED BY YOU'),
                                    style: const TextStyle(
                                      color: Color(0xFF6A7894),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF74B1FF), Color(0xFF5FA3F6)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(95, 163, 246, 0.28),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: const Color(0xFF0A2550),
                              minimumSize: const Size.fromHeight(58),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Color(0xFF0A2550),
                                    ),
                                  )
                                : Text(_isEditing ? context.tr('Save Changes') : context.tr('Save Event')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _NewEventBottomBar(onTap: _navigateToMainTab),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
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
                fontSize: 35,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const Icon(Icons.notifications, color: Color(0xFFA3AAC4), size: 23),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String value;

  const _FieldLabel(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFF8AA8D8),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool focused;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    this.focused = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF192540),
        borderRadius: BorderRadius.circular(14),
        boxShadow: focused
            ? const [
                BoxShadow(
                  color: Color.fromRGBO(116, 177, 255, 0.20),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFFCED7EC), fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF6F7E9B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        ),
      ),
    );
  }
}

class _ActionField extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionField({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF192540),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFCED7EC),
                  fontSize: 16,
                ),
              ),
            ),
            Icon(icon, color: const Color(0xFF8E9CB8), size: 18),
          ],
        ),
      ),
    );
  }
}

class _NewEventBottomBar extends StatelessWidget {
  final ValueChanged<int> onTap;

  const _NewEventBottomBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1930),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: context.tr('HOME'),
            selected: false,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.calendar_today_rounded,
            label: context.tr('CALENDAR'),
            selected: true,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.groups_rounded,
            label: context.tr('FAMILY'),
            selected: false,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: context.tr('PROFILE'),
            selected: false,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF192540) : Colors.transparent;
    final fg = selected ? const Color(0xFF74B1FF) : const Color(0xFF8B98AE);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(height: 4),
              Text(
                  context.tr(label),
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String label;
  final Color color;

  const _CategoryItem(this.icon, this.label, this.color);
}

class _RecurrenceItem {
  final String label;
  final String value;

  const _RecurrenceItem(this.label, this.value);
}