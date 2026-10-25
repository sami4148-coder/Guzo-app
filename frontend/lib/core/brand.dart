import 'package:flutter/material.dart';

import 'theme.dart';

class GuzoLogo extends StatelessWidget {
  const GuzoLogo({this.onDark = false, this.compact = false, super.key});

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 40.0;
    final foreground = onDark ? Colors.white : GuzoColors.ink;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF147D9B), Color(0xFF07566D)],
            ),
            borderRadius: BorderRadius.circular(compact ? 11 : 14),
            boxShadow: [
              BoxShadow(
                color: GuzoColors.green.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Colors.white.withValues(alpha: 0.96),
                size: compact ? 24 : 28,
              ),
              Positioned(
                bottom: compact ? 8 : 10,
                child: Container(
                  width: compact ? 5 : 6,
                  height: compact ? 5 : 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD166),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Text(
            'GUZO',
            style: TextStyle(
              color: foreground,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
            ),
          ),
        ],
      ],
    );
  }
}
