import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand.dart';
import '../../core/theme.dart';

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthBackground()),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Row(
                    children: [
                      const Expanded(flex: 5, child: _AuthHeroPanel()),
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 32,
                              ),
                              child: _AuthFormCard(
                                eyebrow: eyebrow,
                                title: title,
                                subtitle: subtitle,
                                form: form,
                                footer: footer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          _GuzoBrand(),
                          Spacer(),
                          _BackHomeButton(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _MobileAuthHero(),
                      const SizedBox(height: 20),
                      _AuthFormCard(
                        eyebrow: eyebrow,
                        title: title,
                        subtitle: subtitle,
                        form: form,
                        footer: footer,
                      ),
                      const SizedBox(height: 22),
                      const _TrustNote(),
                    ],
                  ),
                );
              },
            ),
          ),

          // Back button on wide layouts
          if (MediaQuery.sizeOf(context).width >= 900)
            const Positioned(
              top: 20,
              left: 24,
              child: SafeArea(child: _BackHomeButton()),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Error message
// ─────────────────────────────────────────────────────────────
class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        border: Border.all(color: const Color(0xFFFFD5D2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 19,
            color: Color(0xFFB42318),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Form card
// ─────────────────────────────────────────────────────────────
class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    return Container(
      padding: EdgeInsets.all(compact ? 22 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EFF0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173344).withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: GuzoColors.green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: GuzoColors.green,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: GuzoColors.ink,
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: GuzoColors.muted.withValues(alpha: 0.95),
              fontSize: 13.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          form,
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFEDF2F1)),
          const SizedBox(height: 16),
          Center(child: footer),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Desktop hero panel
// ─────────────────────────────────────────────────────────────
class _AuthHeroPanel extends StatelessWidget {
  const _AuthHeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xFF0D667D),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D667D).withValues(alpha: 0.28),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1500&q=85',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D667D), Color(0xFF43B8AE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xE610303A),
                    Color(0x9A10303A),
                    Color(0xC810303A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GuzoBrand(onDark: true),
                const Spacer(),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Your next\nchapter starts\nsomewhere new.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Find a stay that feels like part of the journey.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 38),
                const _BenefitRow(
                  icon: Icons.hotel_rounded,
                  text: 'Handpicked places to stay',
                ),
                const SizedBox(height: 15),
                const _BenefitRow(
                  icon: Icons.lock_outline_rounded,
                  text: 'Simple, secure reservations',
                ),
                const Spacer(),
                const _TrustNote(onDark: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mobile hero
// ─────────────────────────────────────────────────────────────
class _MobileAuthHero extends StatelessWidget {
  const _MobileAuthHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0D667D),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D667D).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1000&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D667D), Color(0xFF43B8AE)],
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xB810303A),
                  Color(0x5510303A),
                  Color(0xD810303A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.travel_explore_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'GUZO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Find your place\nin Ethiopia.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stay somewhere worth remembering.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────
// Small parts
// ─────────────────────────────────────────────────────────────
class _GuzoBrand extends StatelessWidget {
  const _GuzoBrand({this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return GuzoLogo(onDark: onDark);
  }
}

class _BackHomeButton extends StatelessWidget {
  const _BackHomeButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.go('/'),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.arrow_back_rounded, size: 20),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 15,
          color: onDark ? Colors.white70 : GuzoColors.muted,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Your details stay private and secure',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onDark ? Colors.white70 : GuzoColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Painterly background
// ─────────────────────────────────────────────────────────────
class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF1F7F5),
                  Color(0xFFF6F9F8),
                  Color(0xFFEEF4F2),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -80,
            child: _Blob(
              size: 260,
              color: GuzoColors.green.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: -60,
            right: -90,
            child: _Blob(
              size: 220,
              color: const Color(0xFF4FB3A3).withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: _Blob(
              size: 300,
              color: GuzoColors.green.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
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
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
