import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/app_i18n.dart';
import '../utils/pet_avatar_catalog.dart';
import '../utils/user_avatar_catalog.dart';
import '../viewmodels/screens/home_view_model.dart';
import 'calendar_screen.dart';
import 'family_screen.dart';
import 'new_event_screen.dart';
import 'pet_details_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeViewModel _viewModel = HomeViewModel();
  FirebaseFirestore get _firestore => _viewModel.firestore;

  String _username = 'Sarah';
  int _currentIndex = 0;
  String? _selectedFamilyId;
  String? _selectedPetId;
  bool _profileLoaded = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSelectionSubscription;

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF0F1930);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);
  static const Color _primary = Color(0xFF74B1FF);

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
    _currentIndex = widget.initialTab.clamp(0, 3);
    _loadUsername();
    _startProfileSelectionSync();
  }

  void _startProfileSelectionSync() {
    final uid = _viewModel.authService.currentUser?.uid;
    if (uid == null) {
      return;
    }

    _profileSelectionSubscription?.cancel();
    _profileSelectionSubscription = _viewModel
        .profileSelectionStream(uid)
        .listen((userSnapshot) {
      final userData = userSnapshot.data();
      final activeFamilyId = (userData?['active_family_id'] as String?)?.trim();
      final activePetId = (userData?['active_pet_id'] as String?)?.trim();

      final normalizedFamilyId =
          (activeFamilyId != null && activeFamilyId.isNotEmpty) ? activeFamilyId : null;
      final normalizedPetId =
          (activePetId != null && activePetId.isNotEmpty) ? activePetId : null;

      if (!mounted) {
        return;
      }

      if (_selectedFamilyId == normalizedFamilyId && _selectedPetId == normalizedPetId) {
        return;
      }

      setState(() {
        _selectedFamilyId = normalizedFamilyId;
        _selectedPetId = normalizedPetId;
        _profileLoaded = true;
      });
    });
  }

  Future<void> _loadUsername() async {
    final selection = await _viewModel.loadHomeSelection();

    if (!mounted) return;

    setState(() {
      _username = selection.username;
      _selectedFamilyId = selection.familyId;
      _selectedPetId = selection.petId;
      _profileLoaded = true;
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _profileSelectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _persistActivePetSelection({
    required String familyId,
    required String petId,
  }) async {
    try {
      await _viewModel.persistActivePetSelection(
        familyId: familyId,
        petId: petId,
        errorMessage: 'Could not save active pet.',
      );
    } catch (_) {}
  }

  Future<void> _openQuickActions({
    required String familyId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> pets,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: _surface,
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
                    color: _textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                _QuickActionTile(
                  icon: Icons.event_rounded,
                  title: context.tr('Add Event'),
                  subtitle: context.tr('Create a new schedule item'),
                  onTap: () => Navigator.pop(sheetContext, 'add_event'),
                ),
                const SizedBox(height: 10),
                _QuickActionTile(
                  icon: Icons.pets_rounded,
                  title: context.tr('Change Pet'),
                  subtitle: context.tr('Switch the active companion'),
                  onTap: () => Navigator.pop(sheetContext, 'change_pet'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'add_event') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NewEventScreen(
            familyId: familyId,
            petId: _selectedPetId,
          ),
        ),
      );
      return;
    }

    if (action == 'change_pet') {
      await _openChangePetSheet(familyId: familyId, pets: pets);
    }
  }

  Future<void> _openChangePetSheet({
    required String familyId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> pets,
  }) async {
    if (pets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('No pets available yet'))),
      );
      return;
    }

    final selectedPetId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('Change Pet'),
                        style: const TextStyle(
                          color: _textMain,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close, color: _textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('Pick your active pet for the home dashboard.'),
                  style: const TextStyle(color: _textMuted),
                ),
                const SizedBox(height: 14),
                ...pets.map((petDoc) {
                  final petData = petDoc.data();
                  final name = (petData['name'] as String?) ?? context.tr('Pet');
                  final breed = (petData['breed'] as String?) ?? context.tr('Unknown');
                  final photoUrl = (petData['photo_url'] as String?) ?? '';
                  final avatarId = (petData['avatar_id'] as String?) ?? '';
                  final isSelected = petDoc.id == _selectedPetId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => Navigator.pop(sheetContext, petDoc.id),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? _surfaceHigh : _bg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _surfaceHigh,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: buildPetAvatarVisual(
                                photoUrl: photoUrl,
                                avatarId: avatarId,
                                size: 52,
                                borderRadius: BorderRadius.circular(14),
                                iconSize: 24,
                                placeholderBackground: _surfaceHigh,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: _textMain,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    breed,
                                    style: const TextStyle(
                                      color: _textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: _primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedPetId == null) return;

    setState(() {
      _selectedFamilyId = familyId;
      _selectedPetId = selectedPetId;
    });

    _persistActivePetSelection(
      familyId: familyId,
      petId: selectedPetId,
    );
  }

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  IconData _eventIcon(String category, String title) {
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
    if (lookup.contains('groom') || lookup.contains('bath') || lookup.contains('hair')) {
      return Icons.content_cut_rounded;
    }
    if (lookup.contains('walk') || lookup.contains('exercise')) {
      return Icons.directions_walk;
    }
    if (lookup.contains('treat')) {
      return Icons.cookie_rounded;
    }
    if (lookup.contains('bag opening') || lookup.contains('bag')) {
      return Icons.shopping_bag_rounded;
    }
    if (lookup.contains('wet wipe') || lookup.contains('clean')) {
      return Icons.cleaning_services_rounded;
    }
    if (lookup.contains('feed') || lookup.contains('food') || lookup.contains('meal')) {
      return Icons.restaurant;
    }
    return Icons.event;
  }

  ({Color bg, Color fg}) _eventPalette(IconData icon) {
    if (icon == Icons.directions_walk) {
      return (bg: const Color(0xFF1F3258), fg: const Color(0xFF74B1FF));
    }
    if (icon == Icons.restaurant) {
      return (bg: const Color(0xFF3B2F23), fg: const Color(0xFFF0C686));
    }
    if (icon == Icons.vaccines_rounded || icon == Icons.content_cut_rounded) {
      return (bg: const Color(0xFF3A2E60), fg: const Color(0xFFE8AAFF));
    }
    if (icon == Icons.medication_rounded) {
      return (bg: const Color(0xFF3A2E60), fg: const Color(0xFFFF7D7D));
    }
    if (icon == Icons.medical_services_rounded || icon == Icons.local_pharmacy_rounded) {
      return (bg: const Color(0xFF263D35), fg: const Color(0xFF95DEBA));
    }
    if (icon == Icons.cookie_rounded) {
      return (bg: const Color(0xFF3B2F23), fg: const Color(0xFFF0C686));
    }
    if (icon == Icons.shopping_bag_rounded || icon == Icons.cleaning_services_rounded) {
      return (bg: const Color(0xFF0B2A5D), fg: const Color(0xFF82C2FF));
    }
    return (bg: const Color(0xFF2A3045), fg: const Color(0xFF9FB0D1));
  }

  void _openPetDetails({
    required Map<String, dynamic> petData,
    required int familyMemberCount,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetDetailsScreen(
          petData: petData,
          familyMemberCount: familyMemberCount,
        ),
      ),
    );
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
            color: _surface,
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
                    color: _textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textMain,
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
                        color: _textMuted,
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

  Future<void> _setEventCompleted({
    required String familyId,
    required String eventId,
    required bool completed,
  }) async {
    await _viewModel.setEventCompleted(
      familyId: familyId,
      eventId: eventId,
      completed: completed,
      completedMessage: 'Event marked as completed.',
      pendingMessage: 'Event marked as pending.',
      errorMessage: 'Could not update event status.',
    );
  }

  Future<void> _deleteEvent({
    required String familyId,
    required String eventId,
    required String title,
  }) async {
    final shouldDelete = await _confirmDelete(
      title: title,
      actionLabel: context.tr('Delete Event'),
    );
    if (!shouldDelete) return;

    await _viewModel.deleteEvent(
      familyId: familyId,
      eventId: eventId,
      successMessage: 'Event deleted.',
      errorMessage: 'Could not delete event.',
    );
  }

  Future<void> _deleteSeries({
    required String familyId,
    required String seriesId,
    required String title,
  }) async {
    final shouldDelete = await _confirmDelete(
      title: title,
      actionLabel: context.tr('Delete Full Series'),
    );
    if (!shouldDelete) return;

    await _viewModel.deleteSeries(
      familyId: familyId,
      seriesId: seriesId,
      successMessage: 'Series deleted.',
      errorMessage: 'Could not delete series.',
    );
  }

  Future<void> _openHomeEventActions({
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
            color: _surface,
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
                    color: _textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, 'edit'),
                    icon: const Icon(Icons.edit_outlined, color: _primary),
                    label: Text(
                      context.tr('Edit Event'),
                      style: const TextStyle(
                        color: _textMain,
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
                      isCompleted
                          ? context.tr('Mark as Pending')
                          : context.tr('Complete Event'),
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
                    label: Text(
                      context.tr('Delete Event'),
                      style: const TextStyle(
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
                      label: Text(
                        context.tr('Delete Full Series'),
                        style: const TextStyle(
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

    if (action == 'toggle_complete') {
      await _setEventCompleted(
        familyId: familyId,
        eventId: eventDoc.id,
        completed: !isCompleted,
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

    if (action == 'delete_series' && hasSeries) {
      await _deleteSeries(
        familyId: familyId,
        seriesId: seriesId,
        title: title,
      );
    }
  }

  Widget _buildHomeBody({
    required String familyId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> pets,
    required int familyMemberCount,
    required List<String> familyMemberAvatarIds,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> todayEvents,
  }) {
    QueryDocumentSnapshot<Map<String, dynamic>>? selectedPet;
    if (pets.isNotEmpty) {
      final selectedIndex = pets.indexWhere((pet) => pet.id == _selectedPetId);
      selectedPet = selectedIndex >= 0 ? pets[selectedIndex] : pets.first;
    }

    final selectedData = selectedPet?.data() ?? const <String, dynamic>{};
    final hasPets = pets.isNotEmpty;
    final selectedName = hasPets
      ? ((selectedData['name'] as String?)?.trim().isNotEmpty == true
        ? (selectedData['name'] as String).trim()
        : context.tr('Your pet'))
      : context.tr('No pets yet');
    final selectedBreed = hasPets
      ? ((selectedData['breed'] as String?)?.trim().isNotEmpty == true
        ? (selectedData['breed'] as String).trim()
        : context.tr('Unknown breed'))
      : context.tr('This family has no pets yet');
    final selectedPhoto = hasPets ? (selectedData['photo_url'] as String?) ?? '' : '';
    final selectedAvatarId = hasPets ? (selectedData['avatar_id'] as String?) ?? '' : '';

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A1730),
                  _bg,
                  const Color(0xFF050A17),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -100,
          child: Container(
            width: 380,
            height: 380,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(116, 177, 255, 0.10),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const _HomeTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('Good morning')}, $_username',
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('Everything\'s ready for your companion today.'),
                        style: const TextStyle(
                          color: _textMain,
                          fontSize: 48,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _DogHeroCard(
                        petName: selectedName,
                        breed: selectedBreed,
                        photoUrl: selectedPhoto,
                        avatarId: selectedAvatarId,
                        familyMemberCount: familyMemberCount,
                        familyMemberAvatarIds: familyMemberAvatarIds,
                        onViewDetails: () => _openPetDetails(
                          petData: selectedData,
                          familyMemberCount: familyMemberCount,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('Today\'s Schedule'),
                            style: const TextStyle(
                              color: _textMain,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentIndex = 1;
                              });
                            },
                            child: Text(
                              context.tr('See all'),
                              style: const TextStyle(
                                color: Color(0xFFA3AAC4),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (todayEvents.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _surfaceHigh,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available, color: _primary, size: 30),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  context.tr('No events for today yet.'),
                                  style: const TextStyle(
                                    color: _textMain,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Builder(
                          builder: (_) {
                            final sortedTodayEvents = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                              todayEvents,
                            )
                              ..sort((a, b) {
                                final aData = a.data();
                                final bData = b.data();

                                final aCompleted = (aData['completed'] as bool?) ?? false;
                                final bCompleted = (bData['completed'] as bool?) ?? false;
                                final completedOrder =
                                    (aCompleted ? 1 : 0).compareTo(bCompleted ? 1 : 0);
                                if (completedOrder != 0) {
                                  return completedOrder;
                                }

                                final aTimestamp = aData['scheduled_at'];
                                final bTimestamp = bData['scheduled_at'];
                                final aDate = aTimestamp is Timestamp
                                    ? aTimestamp.toDate()
                                    : DateTime.fromMillisecondsSinceEpoch(0);
                                final bDate = bTimestamp is Timestamp
                                    ? bTimestamp.toDate()
                                    : DateTime.fromMillisecondsSinceEpoch(0);
                                return aDate.compareTo(bDate);
                              });

                            return Column(
                              children: sortedTodayEvents.take(5).map((eventDoc) {
                            final data = eventDoc.data();
                            final title = (data['title'] as String?)?.trim().isNotEmpty == true
                                ? (data['title'] as String).trim()
                              : context.tr('Untitled event');
                            final note = (data['note'] as String?)?.trim() ?? '';
                            final completed = (data['completed'] as bool?) ?? false;
                            final completedByUsername =
                                (data['completed_by_username'] as String?)?.trim();
                            final category = (data['category'] as String?)?.trim() ?? '';
                            final scheduledAt = data['scheduled_at'];
                            final timestamp =
                                scheduledAt is Timestamp ? scheduledAt.toDate() : DateTime.now();
                            final icon = _eventIcon(category, title);
                            final palette = _eventPalette(icon);

                            final baseSubtitle = note.isNotEmpty
                                ? '${_formatTimeLabel(timestamp)} • $note'
                              : '${context.tr('Today at')} ${_formatTimeLabel(timestamp)}';

                            final subtitle = completed
                              ? '$baseSubtitle\n${context.tr('Completed by')} ${completedByUsername?.isNotEmpty == true ? completedByUsername : context.tr('a family member')}'
                                : baseSubtitle;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ScheduleItem(
                                icon: icon,
                                iconBg: palette.bg,
                                iconColor: palette.fg,
                                title: completed ? '${context.tr('Completed')}: $title' : title,
                                subtitle: subtitle,
                                completed: completed,
                                onMoreTap: () => _openHomeEventActions(
                                  familyId: familyId,
                                  eventDoc: eventDoc,
                                  title: title,
                                ),
                              ),
                            );
                          }).toList(growable: false),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 22,
          bottom: 26,
          child: _FloatingAddButton(
            onPressed: () => _openQuickActions(
              familyId: familyId,
              pets: pets,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 3) {
      return ProfileScreen(
        onGoHome: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      );
    }

    if (_currentIndex == 1) {
      return Scaffold(
        backgroundColor: _bg,
        body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _viewModel.streamFamiliesForCurrentUser(),
          builder: (context, familySnapshot) {
            final families = familySnapshot.data ?? const [];

            if (familySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (families.isEmpty) {
              return CalendarTabContent(
                familyId: null,
                petId: null,
                selectedPetName: null,
                onNewEvent: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewEventScreen(),
                    ),
                  );
                },
              );
            }

            final familyId = _selectedFamilyId != null &&
                    families.any((family) => family.id == _selectedFamilyId)
                ? _selectedFamilyId!
                : families.first.id;

            if (_profileLoaded && _selectedFamilyId != familyId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedFamilyId = familyId;
                });
              });
            }

            return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: _viewModel.streamPets(familyId),
              builder: (context, petSnapshot) {
                final pets = petSnapshot.data ?? const [];

                if (petSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                String? selectedPetId = _selectedPetId;
                String? selectedPetName;

                if (pets.isNotEmpty) {
                  final selectedIndex = pets.indexWhere((pet) => pet.id == _selectedPetId);
                  final selectedPet = selectedIndex >= 0 ? pets[selectedIndex] : pets.first;
                  selectedPetId = selectedPet.id;
                  selectedPetName = (selectedPet.data()['name'] as String?)?.trim();

                  if (_profileLoaded && _selectedPetId != selectedPetId) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _selectedFamilyId = familyId;
                        _selectedPetId = selectedPetId;
                      });
                      _persistActivePetSelection(
                        familyId: familyId,
                        petId: selectedPetId!,
                      );
                    });
                  }
                }

                return CalendarTabContent(
                  familyId: familyId,
                  petId: selectedPetId,
                  selectedPetName: selectedPetName,
                  onNewEvent: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewEventScreen(
                          familyId: familyId,
                          petId: selectedPetId,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      );
    }

    if (_currentIndex == 2) {
      return Scaffold(
        backgroundColor: _bg,
        body: const FamilyTabContent(),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _viewModel.streamFamiliesForCurrentUser(),
        builder: (context, familySnapshot) {
          final families = familySnapshot.data ?? const [];

          if (familySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (families.isEmpty) {
            return Center(
              child: Text(
                context.tr('Create a family to start managing pets'),
                style: TextStyle(color: _textMuted.withValues(alpha: 0.9)),
              ),
            );
          }

          final familyId = _selectedFamilyId != null &&
                  families.any((family) => family.id == _selectedFamilyId)
              ? _selectedFamilyId!
              : families.first.id;

            final selectedFamily = families.firstWhere((family) => family.id == familyId);
            final selectedFamilyData = selectedFamily.data();
            final memberUids = (selectedFamilyData['member_uids'] as List<dynamic>?) ?? const [];
            final familyMemberCount = memberUids.length;
            final orderedMemberUids = memberUids
              .map((uid) => uid.toString().trim())
              .where((uid) => uid.isNotEmpty)
              .toList(growable: false);
            final queryMemberUids = orderedMemberUids.take(10).toList(growable: false);

          if (_profileLoaded && _selectedFamilyId != familyId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _selectedFamilyId = familyId;
              });
            });
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: queryMemberUids.isEmpty
                ? const Stream.empty()
                : _firestore
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: queryMemberUids)
                    .snapshots(),
            builder: (context, memberSnapshot) {
              final memberDocs = memberSnapshot.data?.docs ?? const [];
              final avatarsByUid = <String, String>{
                for (final doc in memberDocs)
                  doc.id: ((doc.data()['profile_avatar_id'] as String?)?.trim() ?? ''),
              };
              final familyMemberAvatarIds = orderedMemberUids
                  .take(3)
                  .map((uid) => avatarsByUid[uid] ?? '')
                  .toList(growable: false);

              return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                stream: _viewModel.streamPets(familyId),
                builder: (context, petSnapshot) {
                  final pets = petSnapshot.data ?? const [];

                  if (petSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_profileLoaded && pets.isNotEmpty) {
                    final validPet = _selectedPetId != null &&
                        pets.any((pet) => pet.id == _selectedPetId);
                    if (!validPet) {
                      final nextPetId = pets.first.id;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          _selectedFamilyId = familyId;
                          _selectedPetId = nextPetId;
                        });
                        _persistActivePetSelection(
                          familyId: familyId,
                          petId: nextPetId,
                        );
                      });
                    }
                  }

                  return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                    stream: _viewModel.streamTodayEvents(
                      familyId: familyId,
                      petId: _selectedPetId ?? '',
                    ),
                    builder: (context, eventSnapshot) {
                      final todayEvents = eventSnapshot.data ?? const [];

                      return _buildHomeBody(
                        familyId: familyId,
                        pets: pets,
                        familyMemberCount: familyMemberCount,
                        familyMemberAvatarIds: familyMemberAvatarIds,
                        todayEvents: todayEvents,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _HomeScreenState._surfaceHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _HomeScreenState._bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _HomeScreenState._primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _HomeScreenState._textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _HomeScreenState._textMuted,
                      fontSize: 13,
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
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(25, 37, 64, 0.60),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF1D2A48),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(7),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/StitchSyncIcon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'StitchSync',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF74B1FF),
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const Icon(Icons.pets_rounded, color: Color(0xFFA3AAC4), size: 26),
        ],
      ),
    );
  }
}

class _DogHeroCard extends StatelessWidget {
  final String petName;
  final String breed;
  final String photoUrl;
  final String avatarId;
  final int familyMemberCount;
  final List<String> familyMemberAvatarIds;
  final VoidCallback onViewDetails;

  const _DogHeroCard({
    required this.petName,
    required this.breed,
    required this.photoUrl,
    required this.avatarId,
    required this.familyMemberCount,
    required this.familyMemberAvatarIds,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _HomeScreenState._surface,
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF5A4025),
                          Color(0xFF342316),
                          Color(0xFF221810),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: buildPetAvatarVisual(
                      photoUrl: photoUrl,
                      avatarId: avatarId,
                      size: 140,
                      borderRadius: BorderRadius.circular(70),
                      iconSize: 70,
                      placeholderBackground: const Color(0xFF2A3550),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 66,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBAECCB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        context.tr('AT HOME'),
                        style: const TextStyle(
                          color: Color(0xFF24553F),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.tr('Current Pet')}: $petName',
                          style: const TextStyle(
                            color: Color(0xFFDEE5FF),
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          breed,
                          style: const TextStyle(
                            color: Color(0xFFA3AAC4),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...List.generate(
                familyMemberAvatarIds.length,
                (index) => Padding(
                  padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF213458),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: buildUserAvatarVisual(
                        avatarId: familyMemberAvatarIds[index],
                        size: 40,
                        borderRadius: BorderRadius.circular(20),
                        emojiSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              if (familyMemberAvatarIds.isEmpty)
                ...List.generate(
                  familyMemberCount > 3 ? 3 : familyMemberCount,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF213458),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF74B1FF),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              if (familyMemberCount > 3) ...[
                const SizedBox(width: 6),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF273247),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '+${familyMemberCount - 3}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDEE5FF),
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: onViewDetails,
                child: Text(
                  context.tr('View Details'),
                  style: const TextStyle(
                    color: Color(0xFF74B1FF),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.pets, color: Color(0xFF6F7C97), size: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool completed;
  final VoidCallback? onMoreTap;

  const _ScheduleItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.completed = false,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFF131D34)
            : _HomeScreenState._surfaceHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Opacity(
              opacity: completed ? 0.72 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFFDEE5FF),
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      decoration:
                          completed ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFA3AAC4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onMoreTap,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.more_vert, color: Color(0xFF6E7890)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FloatingAddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 68,
        height: 68,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF74B1FF), Color(0xFF5FA3F6)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(95, 163, 246, 0.35),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Color(0xFF0A1C38), size: 34),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1930),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home,
            label: context.tr('HOME'),
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.calendar_month,
            label: context.tr('CALENDAR'),
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.groups,
            label: context.tr('FAMILY'),
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.person,
            label: context.tr('PROFILE'),
            selected: currentIndex == 3,
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
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF192540) : Colors.transparent;
    final fg = selected ? const Color(0xFF74B1FF) : const Color(0xFF8B98AE);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: fg, size: 24),
                const SizedBox(height: 4),
                Text(
                  context.tr(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

