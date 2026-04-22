import 'package:flutter/material.dart';

class PetAvatarChoice {
  final String id;
  final String label;
  final String emoji;
  final String accentEmoji;
  final Color backgroundColor;
  final Color emojiBackgroundColor;
  final Color accentBackgroundColor;

  const PetAvatarChoice({
    required this.id,
    required this.label,
    required this.emoji,
    required this.accentEmoji,
    required this.backgroundColor,
    required this.emojiBackgroundColor,
    required this.accentBackgroundColor,
  });
}

const List<PetAvatarChoice> kPetAvatarChoices = [
  PetAvatarChoice(
    id: 'doggo-buddy',
    label: 'Doggo Buddy',
    emoji: '🐶',
    accentEmoji: '🐾',
    backgroundColor: Color(0xFF244C8F),
    emojiBackgroundColor: Color(0xFF122A56),
    accentBackgroundColor: Color(0xFF122A56),
  ),
  PetAvatarChoice(
    id: 'kitty-smile',
    label: 'Kitty Smile',
    emoji: '🐱',
    accentEmoji: '🐾',
    backgroundColor: Color(0xFF5A3C8E),
    emojiBackgroundColor: Color(0xFF39265E),
    accentBackgroundColor: Color(0xFF39265E),
  ),
  PetAvatarChoice(
    id: 'bone-mint',
    label: 'Bone Mint',
    emoji: '🦴',
    accentEmoji: '🐾',
    backgroundColor: Color(0xFF1F6B58),
    emojiBackgroundColor: Color(0xFF134236),
    accentBackgroundColor: Color(0xFF134236),
  ),
  PetAvatarChoice(
    id: 'paw-pop',
    label: 'Paw Pop',
    emoji: '🐾',
    accentEmoji: '💖',
    backgroundColor: Color(0xFF8A3E70),
    emojiBackgroundColor: Color(0xFF5A2749),
    accentBackgroundColor: Color(0xFF5A2749),
  ),
  PetAvatarChoice(
    id: 'fish-wave',
    label: 'Fish Wave',
    emoji: '🐟',
    accentEmoji: '💧',
    backgroundColor: Color(0xFF20345C),
    emojiBackgroundColor: Color(0xFF12203B),
    accentBackgroundColor: Color(0xFF12203B),
  ),
  PetAvatarChoice(
    id: 'dog-sunny',
    label: 'Dog Sunny',
    emoji: '🐕',
    accentEmoji: '☀️',
    backgroundColor: Color(0xFF9A5B18),
    emojiBackgroundColor: Color(0xFF6A3D0F),
    accentBackgroundColor: Color(0xFF6A3D0F),
  ),
  PetAvatarChoice(
    id: 'kitty-night',
    label: 'Kitty Night',
    emoji: '🐈',
    accentEmoji: '🌙',
    backgroundColor: Color(0xFF8A2A35),
    emojiBackgroundColor: Color(0xFF5B1B23),
    accentBackgroundColor: Color(0xFF5B1B23),
  ),
  PetAvatarChoice(
    id: 'fish-spark',
    label: 'Fish Spark',
    emoji: '🐠',
    accentEmoji: '✨',
    backgroundColor: Color(0xFF2E2D6B),
    emojiBackgroundColor: Color(0xFF1C1B45),
    accentBackgroundColor: Color(0xFF1C1B45),
  ),
];

PetAvatarChoice resolvePetAvatar(String? avatarId) {
  final normalized = (avatarId ?? '').trim();
  for (final avatar in kPetAvatarChoices) {
    if (avatar.id == normalized) {
      return avatar;
    }
  }
  return kPetAvatarChoices.first;
}

Widget buildPetAvatarVisual({
  required String? photoUrl,
  required String? avatarId,
  required double size,
  BorderRadius? borderRadius,
  double iconSize = 28,
  Color? placeholderBackground,
}) {
  final normalizedPhoto = (photoUrl ?? '').trim();
  final avatar = resolvePetAvatar(avatarId);
  final radius = borderRadius ?? BorderRadius.circular(16);

  if (normalizedPhoto.isNotEmpty) {
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        normalizedPhoto,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: placeholderBackground ?? avatar.backgroundColor,
              borderRadius: radius,
            ),
            child: Center(
              child: Container(
                width: size * 0.68,
                height: size * 0.68,
                decoration: BoxDecoration(
                  color: avatar.emojiBackgroundColor,
                  borderRadius: BorderRadius.circular(size * 0.28),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatar.emoji,
                  style: TextStyle(fontSize: iconSize),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: placeholderBackground ?? avatar.backgroundColor,
      borderRadius: radius,
    ),
    child: Stack(
      children: [
        Center(
          child: Container(
            width: size * 0.68,
            height: size * 0.68,
            decoration: BoxDecoration(
              color: avatar.emojiBackgroundColor,
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
            alignment: Alignment.center,
            child: Text(
              avatar.emoji,
              style: TextStyle(fontSize: iconSize),
            ),
          ),
        ),
        Positioned(
          right: size * 0.08,
          bottom: size * 0.08,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: avatar.accentBackgroundColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              avatar.accentEmoji,
              style: TextStyle(fontSize: size * 0.13),
            ),
          ),
        ),
      ],
    ),
  );
}