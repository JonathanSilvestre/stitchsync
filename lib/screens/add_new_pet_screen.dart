import 'package:flutter/material.dart';

import '../l10n/app_i18n.dart';
import '../services/event_service.dart';
import '../services/pet_service.dart';
import '../utils/pet_avatar_catalog.dart';
import 'home_screen.dart';

class AddNewPetScreen extends StatefulWidget {
  final String familyId;
  final String? petId;
  final Map<String, dynamic>? initialPetData;

  const AddNewPetScreen({
    super.key,
    required this.familyId,
    this.petId,
    this.initialPetData,
  });

  @override
  State<AddNewPetScreen> createState() => _AddNewPetScreenState();
}

class _AddNewPetScreenState extends State<AddNewPetScreen> {
  final PetService _petService = PetService();
  final EventService _eventService = EventService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final FocusNode _breedFocusNode = FocusNode();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  static const Color _bg = Color(0xFF060E20);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);
  static const Color _primary = Color(0xFF74B1FF);

  static const List<String> _dogBreeds = [
    'Affenpinscher',
    'Akita',
    'Alaskan Malamute',
    'American Bulldog',
    'American Pit Bull Terrier',
    'Australian Cattle Dog',
    'Australian Shepherd',
    'Basenji',
    'Basset Hound',
    'Beagle',
    'Bernese Mountain Dog',
    'Bichon Frise',
    'Bloodhound',
    'Border Collie',
    'Boston Terrier',
    'Boxer',
    'Brittany',
    'Bull Terrier',
    'Bulldog',
    'Cane Corso',
    'Cavalier King Charles Spaniel',
    'Chihuahua',
    'Chow Chow',
    'Cocker Spaniel',
    'Collie',
    'Dachshund',
    'Dalmatian',
    'Doberman Pinscher',
    'English Setter',
    'French Bulldog',
    'German Shepherd',
    'German Shorthaired Pointer',
    'Golden Retriever',
    'Great Dane',
    'Greyhound',
    'Havanese',
    'Irish Setter',
    'Jack Russell Terrier',
    'Labrador Retriever',
    'Lhasa Apso',
    'Maltese',
    'Miniature Pinscher',
    'Miniature Schnauzer',
    'Newfoundland',
    'Papillon',
    'Pekingese',
    'Pembroke Welsh Corgi',
    'Pomeranian',
    'Poodle',
    'Pug',
    'Rottweiler',
    'Saint Bernard',
    'Samoyed',
    'Scottish Terrier',
    'Shetland Sheepdog',
    'Shiba Inu',
    'Shih Tzu',
    'Siberian Husky',
    'Staffordshire Bull Terrier',
    'Weimaraner',
    'West Highland White Terrier',
    'Whippet',
    'Yorkshire Terrier',
    'Mixed Breed',
  ];

  bool _isMale = true;
  bool _isKg = true;
  bool _isSaving = false;
  DateTime? _birthDate;
  String _selectedAvatarId = kPetAvatarChoices.first.id;

  bool get _isEditMode => widget.petId != null && widget.petId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _hydrateFromInitialPetData();
    _breedController.addListener(_onBreedChanged);
  }

  void _onBreedChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  List<String> _matchingBreeds(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return const <String>[];
    }

    final startsWith = _dogBreeds
        .where((breed) => breed.toLowerCase().startsWith(q))
        .toList(growable: false);
    final contains = _dogBreeds
        .where((breed) => !breed.toLowerCase().startsWith(q))
        .where((breed) => breed.toLowerCase().contains(q))
        .toList(growable: false);

    return [...startsWith, ...contains].take(6).toList(growable: false);
  }

  void _hydrateFromInitialPetData() {
    final data = widget.initialPetData;
    if (data == null) {
      return;
    }

    _nameController.text = (data['name'] as String?) ?? '';
    _breedController.text = (data['breed'] as String?) ?? '';

    final avatarId = (data['avatar_id'] as String?)?.trim() ?? '';
    if (avatarId.isNotEmpty) {
      _selectedAvatarId = avatarId;
    }

    final notesRaw = ((data['notes'] as String?) ?? '').trim();
    if (notesRaw.isEmpty) {
      return;
    }

    final pieces = notesRaw
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final piece in pieces) {
      final lower = piece.toLowerCase();

      if (lower.startsWith('weight:')) {
        final raw = piece.substring(piece.indexOf(':') + 1).trim();
        final weightMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(raw);
        if (weightMatch != null) {
          _weightController.text = weightMatch.group(1)!;
        }
        _isKg = !raw.toLowerCase().contains('lb');
        continue;
      }

      if (lower.startsWith('gender:')) {
        final value = piece.substring(piece.indexOf(':') + 1).trim().toLowerCase();
        _isMale = value != 'female';
        continue;
      }

      if (lower.startsWith('dob:')) {
        final value = piece.substring(piece.indexOf(':') + 1).trim();
        final match = RegExp(r'^(\d{1,2})\/(\d{1,2})\/(\d{4})$').firstMatch(value);
        if (match != null) {
          final first = int.tryParse(match.group(1)!);
          final second = int.tryParse(match.group(2)!);
          final year = int.tryParse(match.group(3)!);
          if (first != null && second != null && year != null) {
            // Accept both legacy mm/dd/yyyy and new dd/mm/yyyy.
            final day = first > 12 ? first : second;
            final month = first > 12 ? second : first;
            _birthDate = DateTime(year, month, day);
          }
        }
        continue;
      }

      if (lower.startsWith('notes:')) {
        _notesController.text = piece.substring(piece.indexOf(':') + 1).trim();
      }
    }

    if (_notesController.text.isEmpty && !notesRaw.contains('|')) {
      _notesController.text = notesRaw;
    }
  }

  @override
  void dispose() {
    _breedController.removeListener(_onBreedChanged);
    _nameController.dispose();
    _breedController.dispose();
    _breedFocusNode.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 1),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );

    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  int _resolveAgeFromBirthDate() {
    if (_birthDate == null) {
      return 0;
    }

    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    final notHadBirthdayYet = now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day);
    if (notHadBirthdayYet) {
      age -= 1;
    }
    if (age < 0) {
      return 0;
    }
    return age;
  }

  Future<void> _openAvatarPicker() async {
    if (_isSaving) {
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: _surfaceHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  context.tr('Choose Avatar'),
                  style: const TextStyle(
                    color: _textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kPetAvatarChoices.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final avatar = kPetAvatarChoices[index];
                    final selectedAvatar = avatar.id == _selectedAvatarId;

                    return InkWell(
                      onTap: () => Navigator.pop(sheetContext, avatar.id),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedAvatar ? _primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: buildPetAvatarVisual(
                            photoUrl: null,
                            avatarId: avatar.id,
                            size: 56,
                            borderRadius: BorderRadius.circular(14),
                            iconSize: 30,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedAvatarId = selected;
    });
  }

  String _composeNotes() {
    final pieces = <String>[];
    final weight = _weightController.text.trim();
    if (weight.isNotEmpty) {
      pieces.add('Weight: $weight ${_isKg ? 'kg' : 'lb'}');
    }

    pieces.add('Gender: ${_isMale ? 'Male' : 'Female'}');

    if (_birthDate != null) {
      final dd = _birthDate!.day.toString().padLeft(2, '0');
      final mm = _birthDate!.month.toString().padLeft(2, '0');
      final yy = _birthDate!.year.toString();
      pieces.add('DOB: $dd/$mm/$yy');
    }

    final bio = _notesController.text.trim();
    if (bio.isNotEmpty) {
      pieces.add('Notes: $bio');
    }

    return pieces.join(' | ');
  }

  Future<void> _savePet() async {
    final name = _nameController.text.trim();
    final breed = _breedController.text.trim();

    if (name.isEmpty || breed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter pet name and breed.'))),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditMode) {
        await _petService.updatePet(
          familyId: widget.familyId,
          petId: widget.petId!,
          name: name,
          breed: breed,
          age: _resolveAgeFromBirthDate(),
          notes: _composeNotes(),
          avatarId: _selectedAvatarId,
        );

        await _eventService.upsertPetBirthdayAutoEvent(
          familyId: widget.familyId,
          petId: widget.petId!,
          petName: name,
          birthDate: _birthDate,
        );
      } else {
        final createdPetId = await _petService.addPet(
          familyId: widget.familyId,
          name: name,
          breed: breed,
          age: _resolveAgeFromBirthDate(),
          notes: _composeNotes(),
          avatarId: _selectedAvatarId,
        );

        await _eventService.upsertPetBirthdayAutoEvent(
          familyId: widget.familyId,
          petId: createdPetId,
          petName: name,
          birthDate: _birthDate,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? context.tr('Pet updated successfully.')
                : context.tr('Pet added successfully.'),
          ),
        ),
      );

      if (_isEditMode) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(initialTab: 2),
          ),
          (route) => false,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not save pet. Please try again.'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _navigateMainTab(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(initialTab: index)),
      (route) => false,
    );
  }

  String _birthDateLabel() {
    if (_birthDate == null) {
      return 'dd/mm/yyyy';
    }

    final dd = _birthDate!.day.toString().padLeft(2, '0');
    final mm = _birthDate!.month.toString().padLeft(2, '0');
    final yy = _birthDate!.year.toString();
    return '$dd/$mm/$yy';
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
                    const Color(0xFF0A1730),
                    _bg,
                    const Color(0xFF08142B),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  color: const Color(0xFF0A1730),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: _textMuted),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _isEditMode ? context.tr('Edit Pet') : context.tr('Add New Pet'),
                          style: const TextStyle(
                            color: Color(0xFF9DC7FF),
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _surfaceHigh,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: _primary, size: 22),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      children: [
                        Center(
                          child: InkWell(
                            onTap: _openAvatarPicker,
                            borderRadius: BorderRadius.circular(30),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF2D3A52), Color(0xFF192540)],
                                    ),
                                  ),
                                  child: Center(
                                    child: buildPetAvatarVisual(
                                      photoUrl: null,
                                      avatarId: _selectedAvatarId,
                                      size: 120,
                                      borderRadius: BorderRadius.circular(26),
                                      iconSize: 64,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -8,
                                  bottom: -8,
                                  child: Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D66D8),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${context.tr('Avatar')}: ${resolvePetAvatar(_selectedAvatarId).label}',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FieldCard(
                          label: context.tr('PET NAME'),
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(color: _textMain, fontSize: 18),
                            decoration: InputDecoration(
                              hintText: context.tr('e.g. Luna'),
                              hintStyle: TextStyle(color: Color(0xFF4D5F82), fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FieldCard(
                          label: context.tr('BREED'),
                          child: Column(
                            children: [
                              TextField(
                                controller: _breedController,
                                focusNode: _breedFocusNode,
                                style: const TextStyle(color: _textMain, fontSize: 18),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search, color: _primary),
                                  hintText: context.tr('Search breed...'),
                                  hintStyle: TextStyle(color: Color(0xFF4D5F82), fontSize: 18),
                                ),
                              ),
                              if (_breedFocusNode.hasFocus &&
                                  _matchingBreeds(_breedController.text).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 190),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF09142A),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _primary.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    shrinkWrap: true,
                                    itemCount: _matchingBreeds(_breedController.text).length,
                                    separatorBuilder: (context, index) => Divider(
                                      height: 1,
                                      color: _primary.withValues(alpha: 0.10),
                                    ),
                                    itemBuilder: (context, index) {
                                      final suggestion = _matchingBreeds(_breedController.text)[index];
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          suggestion,
                                          style: const TextStyle(
                                            color: _textMain,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        onTap: () {
                                          _breedController.text = suggestion;
                                          _breedController.selection = TextSelection.fromPosition(
                                            TextPosition(offset: suggestion.length),
                                          );
                                          _breedFocusNode.unfocus();
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FieldCard(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00091D),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isMale = true),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _isMale ? const Color(0xFF2D66D8) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        context.tr('Male'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _isMale ? Colors.white : _textMuted,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isMale = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: !_isMale ? const Color(0xFF2D66D8) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        context.tr('Female'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: !_isMale ? Colors.white : _textMuted,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FieldCard(
                          label: context.tr('DATE OF BIRTH'),
                          child: InkWell(
                            onTap: _pickBirthDate,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, color: _primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    _birthDateLabel(),
                                    style: const TextStyle(color: _textMain, fontSize: 17),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.calendar_today_outlined,
                                      color: Color(0xFFD7DFF3), size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FieldCard(
                          label: context.tr('WEIGHT'),
                          trailing: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00091D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _UnitChip(
                                  label: 'KG',
                                  selected: _isKg,
                                  onTap: () => setState(() => _isKg = true),
                                ),
                                _UnitChip(
                                  label: 'LB',
                                  selected: !_isKg,
                                  onTap: () => setState(() => _isKg = false),
                                ),
                              ],
                            ),
                          ),
                          child: TextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: _textMain, fontSize: 18),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.monitor_weight_outlined, color: _primary),
                              hintText: '0.0',
                              hintStyle: TextStyle(color: Color(0xFF4D5F82), fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FieldCard(
                          label: context.tr('BIO & MEDICAL NOTES'),
                          child: TextField(
                            controller: _notesController,
                            minLines: 4,
                            maxLines: 5,
                            style: const TextStyle(color: _textMain, fontSize: 17),
                            decoration: InputDecoration(
                              hintText: context.tr('Tell us about your pet\'s favorites, allergies, or habits...'),
                              hintStyle: TextStyle(color: Color(0xFF4D5F82), fontSize: 17),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF74B1FF), Color(0xFF5FA3F6)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(95, 163, 246, 0.30),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _savePet,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(66),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.pets),
                            label: Text(
                              _isSaving
                                  ? context.tr('Saving...')
                                  : (_isEditMode ? context.tr('Update Pet') : context.tr('Add Pet')),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr('By adding a pet, you can start sharing care schedules with your family members.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _textMuted, fontSize: 14, height: 1.45),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                _BottomTabs(onTap: _navigateMainTab, selectedIndex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String? label;
  final Widget child;
  final Widget? trailing;

  const _FieldCard({
    this.label,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A34),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null || trailing != null)
            Row(
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: const TextStyle(
                      color: Color(0xFF8091B1),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                const Spacer(),
                ?trailing,
              ],
            ),
          if (label != null || trailing != null) const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D66D8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF8091B1),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  final ValueChanged<int> onTap;
  final int selectedIndex;

  const _BottomTabs({
    required this.onTap,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1930),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _NavTab(
            icon: Icons.home_filled,
            label: context.tr('HOME'),
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavTab(
            icon: Icons.calendar_today,
            label: context.tr('CALENDAR'),
            selected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavTab(
            icon: Icons.groups,
            label: context.tr('FAMILY'),
            selected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavTab(
            icon: Icons.person,
            label: context.tr('PROFILE'),
            selected: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? const Color(0xFFA3C8FF) : const Color(0xFFA3AAC4);
    final bg = selected ? const Color(0xFF192F5F) : Colors.transparent;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
