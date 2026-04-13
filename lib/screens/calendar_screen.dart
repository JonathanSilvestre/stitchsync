import 'package:flutter/material.dart';

class CalendarTabContent extends StatelessWidget {
  final VoidCallback onNewEvent;

  const CalendarTabContent({
    super.key,
    required this.onNewEvent,
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
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'October 2024',
                          style: TextStyle(
                            color: _textMain,
                            fontSize: 38,
                            letterSpacing: -0.7,
                            height: 0.95,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    _MonthButton(icon: Icons.chevron_left),
                    const SizedBox(width: 10),
                    _MonthButton(icon: Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 22),
                const _CalendarPanel(),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(
                      child: _MiniInsightCard(
                        icon: Icons.cake_outlined,
                        iconBg: Color(0xFF3A2E60),
                        iconColor: Color(0xFFE8AAFF),
                        title: 'UPCOMING\nMILESTONE',
                        detail: 'Fido\'s 2nd\nBirthday',
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _MiniInsightCard(
                        icon: Icons.medical_services_outlined,
                        iconBg: Color(0xFF0B2A5D),
                        iconColor: Color(0xFF74B1FF),
                        title: 'REMINDER',
                        detail: 'Rabies\nBooster\nShot',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final shouldWrap = constraints.maxWidth < 360;
                    final title = const Text(
                      'Events for Oct 3',
                      style: TextStyle(
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
                const _EventCard(
                  accent: Color(0xFF74B1FF),
                  timeTop: '08:00',
                  timeBottom: 'AM',
                  title: 'Fido\'s Morning Walk',
                  location: 'Central Park, West Trail',
                  note: null,
                  chip: null,
                  avatars: true,
                ),
                const SizedBox(height: 14),
                const _EventCard(
                  accent: Color(0xFFE8AAFF),
                  timeTop: '11:30',
                  timeBottom: 'AM',
                  title: 'Vet Checkup',
                  location: 'Paws & Claws Veterinary\nClinic',
                  note: null,
                  chip: 'HEALTH',
                  avatars: false,
                ),
                const SizedBox(height: 14),
                const _EventCard(
                  accent: Color(0xFF74B1FF),
                  timeTop: '06:00',
                  timeBottom: 'PM',
                  title: 'Evening Feeding',
                  location: 'Home, Kitchen Area',
                  note: 'Add organic kibble mix + salmon oil',
                  chip: null,
                  avatars: false,
                ),
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
                        'Keeping a consistent schedule for Fido\'s meals and walks helps reduce anxiety and improves digestive health.',
                        style: TextStyle(
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

  const _MonthButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF192540),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: const Color(0xFFC1CAE0), size: 32),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel();

  @override
  Widget build(BuildContext context) {
    const cells = [
      '30', '1', '2', '3', '4', '5', '6',
      '7', '8', '9', '10', '11', '12', '13',
      '14', '15', '16', '17', '18', '19', '20',
      '21', '22', '23', '24', '25', '26', '27',
      '28', '29', '30', '31', '', '', '',
    ];

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
          for (int row = 0; row < 5; row++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  for (int col = 0; col < 7; col++)
                    _DayCell(
                      label: cells[row * 7 + col],
                      isSelected: cells[row * 7 + col] == '3',
                      isMuted: row == 0 && col == 0,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String label;
  final bool isHeader;
  final bool isSelected;
  final bool isMuted;

  const _DayCell({
    required this.label,
    this.isHeader = false,
    this.isSelected = false,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isHeader
        ? const Color(0xFF6F7E9B)
        : isMuted
            ? const Color(0xFF3D4A67)
            : const Color(0xFFE3E9FA);

    return Expanded(
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF27446E),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: isHeader ? 13 : 18,
            fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
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

  const _EventCard({
    required this.accent,
    required this.timeTop,
    required this.timeBottom,
    required this.title,
    required this.location,
    required this.note,
    required this.chip,
    required this.avatars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1930), Color(0xFF132445)],
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
                          style: const TextStyle(
                            color: Color(0xFFE7ECFB),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
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
                  const Icon(Icons.more_vert, color: Color(0xFF8F9BB6), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
