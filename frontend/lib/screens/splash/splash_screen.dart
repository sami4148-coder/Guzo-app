import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/brand.dart';
import '../../core/theme.dart';
import '../../state/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _loaderFade;
  late final Animation<double> _pulse;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();

    // Main intro timeline
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    // Pulse for the loader dots
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Slow rotation for ambient orbs
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeIn),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _loaderFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _continueAfterSplash();
  }

  Future<void> _continueAfterSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final auth = context.read<AuthState>();
    while (mounted && !auth.initialized) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;

    if (auth.isLoggedIn) {
      final destination = auth.isAdmin
          ? '/admin'
          : auth.isOwner
              ? '/explore'
              : '/user';
      context.go(destination);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      context.go(prefs.getBool('hasSeenOnboarding') == true
          ? '/welcome'
          : '/onboarding');
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07110F),
      body: Stack(
        children: [
          // Deep gradient backdrop
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF07110F),
                    Color(0xFF0B1A17),
                    Color(0xFF07110F),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Rotating ambient orbs
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rotate,
              builder: (context, _) {
                return Transform.rotate(
                  angle: _rotate.value,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -120,
                        right: -120,
                        child: _Blob(
                          size: 420,
                          color:
                              GuzoColors.green.withValues(alpha: 0.28),
                        ),
                      ),
                      Positioned(
                        bottom: -160,
                        left: -120,
                        child: _Blob(
                          size: 420,
                          color: const Color(0xFFE0A458)
                              .withValues(alpha: 0.18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Fine dot grid for depth
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DotPainter()),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const GuzoLogo(onDark: true),
                  ),
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                GuzoColors.green.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'DISCOVER ETHIOPIA',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom loader
          Positioned(
            left: 0,
            right: 0,
            bottom: 64,
            child: FadeTransition(
              opacity: _loaderFade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDots(pulse: _pulse),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          GuzoColors.green.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer tag
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: FadeTransition(
              opacity: _loaderFade,
              child: Text(
                'v1.0 · Made in Addis',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDots extends StatelessWidget {
  final Animation<double> pulse;
  const _PulsingDots({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger phase per dot
            final phase = (pulse.value + i * 0.25) % 1.0;
            final wave = (math.sin(phase * 2 * math.pi) + 1) / 2;
            final opacity = 0.35 + wave * 0.65;
            final scale = 0.85 + wave * 0.3;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: i == 1 ? 8 : 0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: GuzoColors.green.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: GuzoColors.green
                            .withValues(alpha: opacity * 0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const radius = 1.0;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}