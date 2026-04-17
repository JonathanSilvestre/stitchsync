import 'package:flutter/material.dart';

class UserAvatarChoice {
  final String id;
  final String label;
  final String emoji;
  final String accentEmoji;
  final Color backgroundColor;
  final Color emojiBackgroundColor;
  final Color accentBackgroundColor;

  const UserAvatarChoice({
    required this.id,
    required this.label,
    required this.emoji,
    required this.accentEmoji,
    required this.backgroundColor,
    required this.emojiBackgroundColor,
    required this.accentBackgroundColor,
  });
}

const List<UserAvatarChoice> kUserAvatarChoices = [
  UserAvatarChoice(
    id: 'spark-smile',
    label: 'Spark Smile',
    emoji: '😀',
    accentEmoji: '✨',
    backgroundColor: Color(0xFF2A4D8E),
    emojiBackgroundColor: Color(0xFF18305E),
    accentBackgroundColor: Color(0xFF18305E),
  ),
  UserAvatarChoice(
    id: 'tech-mood',
    label: 'Tech Mood',
    emoji: '🧑‍💻',
    accentEmoji: '💡',
    backgroundColor: Color(0xFF1F6B58),
    emojiBackgroundColor: Color(0xFF134236),
    accentBackgroundColor: Color(0xFF134236),
  ),
  UserAvatarChoice(
    id: 'creative-vibe',
    label: 'Creative Vibe',
    emoji: '🧑‍🎨',
    accentEmoji: '🎨',
    backgroundColor: Color(0xFF6A3D8E),
    emojiBackgroundColor: Color(0xFF42275A),
    accentBackgroundColor: Color(0xFF42275A),
  ),
  UserAvatarChoice(
    id: 'chef-pop',
    label: 'Chef Pop',
    emoji: '🧑‍🍳',
    accentEmoji: '🍽️',
    backgroundColor: Color(0xFF8D4B1F),
    emojiBackgroundColor: Color(0xFF5A3013),
    accentBackgroundColor: Color(0xFF5A3013),
  ),
  UserAvatarChoice(
    id: 'space-dream',
    label: 'Space Dream',
    emoji: '🧑‍🚀',
    accentEmoji: '🚀',
    backgroundColor: Color(0xFF2E2D6B),
    emojiBackgroundColor: Color(0xFF1C1B45),
    accentBackgroundColor: Color(0xFF1C1B45),
  ),
  UserAvatarChoice(
    id: 'study-star',
    label: 'Study Star',
    emoji: '🧑‍🎓',
    accentEmoji: '📘',
    backgroundColor: Color(0xFF365A8A),
    emojiBackgroundColor: Color(0xFF223A5B),
    accentBackgroundColor: Color(0xFF223A5B),
  ),
  UserAvatarChoice(
    id: 'zen-flow',
    label: 'Zen Flow',
    emoji: '🧘',
    accentEmoji: '🌿',
    backgroundColor: Color(0xFF2A6D62),
    emojiBackgroundColor: Color(0xFF19463F),
    accentBackgroundColor: Color(0xFF19463F),
  ),
  UserAvatarChoice(
    id: 'party-beat',
    label: 'Party Beat',
    emoji: '🕺',
    accentEmoji: '🎵',
    backgroundColor: Color(0xFF8A2A55),
    emojiBackgroundColor: Color(0xFF5B1B38),
    accentBackgroundColor: Color(0xFF5B1B38),
  ),
];

UserAvatarChoice resolveUserAvatar(String? avatarId) {
  final normalized = (avatarId ?? '').trim();
  for (final avatar in kUserAvatarChoices) {
    if (avatar.id == normalized) {
      return avatar;
    }
  }
  return kUserAvatarChoices.first;
}

Widget buildUserAvatarVisual({
  required String? avatarId,
  required double size,
  BorderRadius? borderRadius,
  double emojiSize = 28,
}) {
  final avatar = resolveUserAvatar(avatarId);
  final radius = borderRadius ?? BorderRadius.circular(16);

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: avatar.backgroundColor,
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
              style: TextStyle(fontSize: emojiSize),
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
