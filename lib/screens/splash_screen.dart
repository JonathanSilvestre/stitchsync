import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_i18n.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _progressController.forward();
    _navigateToApp();
  }

  Future<void> _navigateToApp() async {
    await Future<void>.delayed(const Duration(milliseconds: 3400));
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final heightScale = (mediaSize.height / 900).clamp(0.78, 1.0);

    const Color background = Color(0xFF060E20);
    const Color card = Color(0xFF192540);
    const Color brandBlue = Color(0xFF74B1FF);
    const Color subtitle = Color(0xFFA3AAC4);
    const Color track = Color(0xFF2A3347);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF101E37),
                    Color(0xFF060E20),
                    Color(0xFF040A17),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF74B1FF).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -170,
            left: -80,
            right: -80,
            child: Container(
              height: 340,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 1.3,
                  colors: [
                    const Color(0xFF0D5F52).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(height: 28 * heightScale),
                        Column(
                          children: [
                            Container(
                              width: 186 * heightScale,
                              height: 186 * heightScale,
                              decoration: BoxDecoration(
                                color: card.withValues(alpha: 0.76),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 12, 30, 0.40),
                                    blurRadius: 44,
                                    offset: Offset(0, 24),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(20 * heightScale),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/icon/StitchSyncIcon.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(78 * heightScale, -24 * heightScale),
                              child: Container(
                                width: 66 * heightScale,
                                height: 66 * heightScale,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF0E76CA), Color(0xFF005DA7)],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(22, 113, 209, 0.42),
                                      blurRadius: 28,
                                      offset: Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.pets_rounded,
                                  color: const Color(0xFFA4CCFF),
                                  size: 30 * heightScale,
                                ),
                              ),
                            ),
                            SizedBox(height: 8 * heightScale),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFAED0FF), Color(0xFF6B9CE8)],
                              ).createShader(bounds),
                              child: SizedBox(
                                width: double.infinity,
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'StitchSync',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 72,
                                      height: 0.95,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 6 * heightScale),
                            Text(
                              'LIVING HEARTH MIDNIGHT',
                              style: TextStyle(
                                color: subtitle,
                                fontSize: 16 * heightScale,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 16 * heightScale),
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      minHeight: 9 * heightScale,
                                      value: _progressAnimation.value,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(brandBlue),
                                      backgroundColor: track,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 30 * heightScale),
                              Text(
                                context.tr('Syncing your pet\'s world...'),
                                style: TextStyle(
                                  color: const Color(0xFF8E9AB2),
                                  fontSize: 22 * heightScale,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 18 * heightScale),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Opacity(
                                  opacity: 0.55,
                                  child: Container(
                                    width: 58 * heightScale,
                                    height: 58 * heightScale,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.pets,
                                      color: const Color(0xFF95A0B8),
                                      size: 30 * heightScale,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
