import 'package:flutter/material.dart';

class PetDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> petData;
  final int familyMemberCount;

  const PetDetailsScreen({
    super.key,
    required this.petData,
    required this.familyMemberCount,
  });

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF0F1930);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _primary = Color(0xFF74B1FF);
  static const Color _title = Color(0xFFDEE5FF);
  static const Color _muted = Color(0xFFA3AAC4);

  @override
  Widget build(BuildContext context) {
    final name = (petData['name'] as String?)?.trim().isNotEmpty == true
        ? (petData['name'] as String).trim()
        : 'Pet';
    final breed = (petData['breed'] as String?)?.trim().isNotEmpty == true
        ? (petData['breed'] as String).trim()
        : 'Unknown breed';
    final age = petData['age'];
    final ageLabel = age is num ? '${age.toInt()} years' : 'Not specified';
    final notes = (petData['notes'] as String?)?.trim().isNotEmpty == true
        ? (petData['notes'] as String).trim()
        : 'No additional notes for this companion yet.';
    final photoUrl = (petData['photo_url'] as String?) ?? '';

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
                    const Color(0xFF050A17),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -140,
            right: -110,
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(116, 177, 255, 0.10),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        'Pet Details',
                        style: TextStyle(
                          color: _title,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            height: 220,
                            width: double.infinity,
                            child: photoUrl.isNotEmpty
                                ? Image.network(photoUrl, fit: BoxFit.cover)
                                : Container(
                                    color: _surfaceHigh,
                                    child: const Center(
                                      child: Icon(
                                        Icons.pets,
                                        size: 84,
                                        color: _primary,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          style: const TextStyle(
                            color: _title,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          breed,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.cake_outlined,
                              text: ageLabel,
                            ),
                            const SizedBox(width: 10),
                            _InfoChip(
                              icon: Icons.group_outlined,
                              text: '$familyMemberCount family members',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes',
                          style: TextStyle(
                            color: _title,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notes,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 15,
                            height: 1.45,
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
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF192540),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF74B1FF)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFDEE5FF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
