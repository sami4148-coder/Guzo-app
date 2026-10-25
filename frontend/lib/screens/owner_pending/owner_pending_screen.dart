import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand.dart';
import '../../core/theme.dart';

class OwnerPendingScreen extends StatefulWidget {
  const OwnerPendingScreen({this.email, super.key});

  final String? email;

  @override
  State<OwnerPendingScreen> createState() => _OwnerPendingScreenState();
}

class _OwnerPendingScreenState extends State<OwnerPendingScreen> {
  static const _reviewWindow = Duration(minutes: 5);
  late Duration _remaining = _reviewWindow;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= const Duration(seconds: 1)) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _clock {
    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final timerComplete = _remaining == Duration.zero;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: Color(0xFFE3ECE9)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const GuzoLogo(),
                      const SizedBox(height: 28),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: GuzoColors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          size: 42,
                          color: GuzoColors.green,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Your owner account is under review',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GuzoColors.ink,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.email == null
                            ? 'We’ll enable owner sign-in after an administrator approves your business.'
                            : 'We’ve received the owner application for ${widget.email}. An administrator must approve it before you can sign in.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GuzoColors.muted,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F7F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              timerComplete
                                  ? 'Review reminder complete'
                                  : 'Review reminder',
                              style: const TextStyle(
                                color: GuzoColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timerComplete ? 'Still pending' : _clock,
                              style: const TextStyle(
                                color: GuzoColors.green,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              timerComplete
                                  ? 'The countdown does not approve the account. Admin approval is required.'
                                  : 'Your account remains pending until an admin approves it.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: GuzoColors.muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Go to sign in'),
                          style: FilledButton.styleFrom(
                            backgroundColor: GuzoColors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/welcome'),
                        child: const Text('Back to welcome'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
