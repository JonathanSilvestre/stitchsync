import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'calendar_screen.dart';
import 'family_screen.dart';
import 'new_event_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  String _username = 'Sarah';
  int _currentIndex = 0;

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF0F1930);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, 3);
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final profile = await _auth.getCurrentUserProfile();
    final profileUsername = (profile?['username'] as String?)?.trim();

    String? fallbackEmailName;
    final email = _auth.currentUser?.email?.trim();
    if (email != null && email.contains('@')) {
      fallbackEmailName = email.split('@').first;
    }

    final resolvedName = (profileUsername != null && profileUsername.isNotEmpty)
        ? profileUsername
        : (fallbackEmailName != null && fallbackEmailName.isNotEmpty)
            ? fallbackEmailName
            : 'Sarah';

    if (!mounted) {
      return;
    }

    setState(() {
      _username = resolvedName;
    });
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
        body: CalendarTabContent(
          onNewEvent: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NewEventScreen(),
              ),
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
                          'Good morning, $_username',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Everything\'s ready for\nFido today.',
                          style: TextStyle(
                            color: _textMain,
                            fontSize: 48,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _DogHeroCard(),
                        const SizedBox(height: 30),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Today\'s Schedule',
                              style: TextStyle(
                                color: _textMain,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'See all',
                              style: TextStyle(
                                color: Color(0xFFA3AAC4),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          clipBehavior: Clip.none,
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(bottom: 54),
                              child: Column(
                                children: [
                                  _ScheduleItem(
                                    icon: Icons.directions_walk,
                                    iconBg: Color(0xFF1F3258),
                                    iconColor: Color(0xFF74B1FF),
                                    title: 'Walk at 2 PM',
                                    subtitle: 'Assigned to: Marcus',
                                  ),
                                  SizedBox(height: 14),
                                  _ScheduleItem(
                                    icon: Icons.restaurant,
                                    iconBg: Color(0xFF3B2F23),
                                    iconColor: Color(0xFFF0C686),
                                    title: 'Feeding at 5 PM',
                                    subtitle: 'Evening Meal • Kibble + Topper',
                                  ),
                                  SizedBox(height: 14),
                                  _ScheduleItem(
                                    icon: Icons.medication,
                                    iconBg: Color(0xFF263D35),
                                    iconColor: Color(0xFF95DEBA),
                                    title: 'Medication at 8 PM',
                                    subtitle: 'Monthly flea prevention',
                                    highlighted: true,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 0,
                              child: _FloatingAddButton(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          const Icon(Icons.notifications, color: Color(0xFFA3AAC4), size: 26),
        ],
      ),
    );
  }
}

class _DogHeroCard extends StatelessWidget {
  const _DogHeroCard();

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
                    child: Opacity(
                      opacity: 0.88,
                      child: Image.asset(
                        'assets/icon/StitchSyncIcon.png',
                        width: 140,
                        height: 140,
                      ),
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
                      child: const Text(
                        'AT HOME',
                        style: TextStyle(
                          color: Color(0xFF24553F),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    bottom: 20,
                    child: Text(
                      'Current Dog: Stitch',
                      style: TextStyle(
                        color: Color(0xFFDEE5FF),
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AvatarCircle(
                color: const Color(0xFF213458),
                icon: Icons.person,
                iconColor: const Color(0xFF74B1FF),
              ),
              const SizedBox(width: 6),
              _AvatarCircle(
                color: const Color(0xFF2B3343),
                icon: Icons.person,
                iconColor: const Color(0xFFA3AAC4),
              ),
              const SizedBox(width: 6),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF273247),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '+2',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDEE5FF),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'View Details',
                style: TextStyle(
                  color: Color(0xFF74B1FF),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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

class _AvatarCircle extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;

  const _AvatarCircle({
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool highlighted;

  const _ScheduleItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _HomeScreenState._surfaceHigh,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFDEE5FF),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
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
          const Icon(Icons.more_vert, color: Color(0xFF6E7890)),
        ],
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
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
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: Color(0xFF0A1C38), size: 44),
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
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.calendar_month,
            label: 'Calendar',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.groups,
            label: 'Family',
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.person,
            label: 'Profile',
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
                  label,
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
