import 'dart:ui';

import 'package:flutter/material.dart';

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

  bool _pushEnabled = true;
  bool _feedWater = true;
  bool _walksExercise = true;
  bool _medicationVet = true;
  bool _familyUpdates = false;

  bool _emailDigest = true;
  bool _tipsOffers = false;

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPushHeader(),
                        const SizedBox(height: 16),
                        _buildPushCard(),
                        const SizedBox(height: 28),
                        const Text(
                          'Email Notifications',
                          style: TextStyle(
                            color: _title,
                            fontSize: 39,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.55,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildEmailCard(),
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
            setState(() {
              _pushEnabled = value;
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
            onChanged: (value) {
              setState(() {
                _feedWater = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _PushCategoryTile(
            icon: Icons.directions_walk,
            iconColor: const Color(0xFFA6D9C2),
            iconBg: const Color(0xFF193035),
            title: 'Walks & Exercise',
            value: _walksExercise,
            onChanged: (value) {
              setState(() {
                _walksExercise = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _PushCategoryTile(
            icon: Icons.medical_services_outlined,
            iconColor: const Color(0xFFFF8E9A),
            iconBg: const Color(0xFF3A1B2D),
            title: 'Medication & Vet',
            value: _medicationVet,
            onChanged: (value) {
              setState(() {
                _medicationVet = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _PushCategoryTile(
            icon: Icons.group,
            iconColor: const Color(0xFFFFC077),
            iconBg: const Color(0xFF30261A),
            title: 'Family Updates',
            value: _familyUpdates,
            onChanged: (value) {
              setState(() {
                _familyUpdates = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _EmailTile(
            icon: Icons.email_outlined,
            title: 'Weekly Health Digest',
            subtitle: 'Summary of all pets activity and logs',
            value: _emailDigest,
            onChanged: (value) {
              setState(() {
                _emailDigest = value;
              });
            },
          ),
          const SizedBox(height: 8),
          _EmailTile(
            icon: Icons.campaign_outlined,
            title: 'Tips & Offers',
            subtitle: 'Pet care advice and partner discounts',
            value: _tipsOffers,
            onChanged: (value) {
              setState(() {
                _tipsOffers = value;
              });
            },
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
              const Text(
                'Quiet Hours',
                style: TextStyle(
                  color: _title,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
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
                  onPressed: () {},
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
  final ValueChanged<bool> onChanged;

  const _PushCategoryTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.onChanged,
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
            onChanged: (newValue) => onChanged(newValue ?? false),
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

class _EmailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _EmailTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF20304E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: const Color(0xFFA8B7CE), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFDEE5FF),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFA3AAC4),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
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
