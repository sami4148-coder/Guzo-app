import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_state.dart';

Future<void> showFirstLoginGuide(BuildContext context) async {
  final exploreWhenDone = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _FirstLoginGuideDialog(),
  );
  if (exploreWhenDone == true && context.mounted) {
    context.go('/explore');
  }
}

class _GuideStep {
  const _GuideStep({
    required this.title,
    required this.description,
    required this.hint,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final String hint;
  final IconData icon;
  final Color accent;
}

class _FirstLoginGuideDialog extends StatefulWidget {
  const _FirstLoginGuideDialog();

  @override
  State<_FirstLoginGuideDialog> createState() => _FirstLoginGuideDialogState();
}

class _FirstLoginGuideDialogState extends State<_FirstLoginGuideDialog>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    _GuideStep(
      title: 'Choose your water',
      description:
          'Browse bottled water, family refills, premium picks, and bulk packs from the home screen.',
      hint: 'Home',
      icon: Icons.search_rounded,
      accent: Color(0xFF2E86AB),
    ),
    _GuideStep(
      title: 'Find the right fit',
      description:
          'Search by name or brand, or filter the catalogue by the kind of water you need.',
      hint: 'Shop',
      icon: Icons.water_drop_outlined,
      accent: Color(0xFF2E7D6F),
    ),
    _GuideStep(
      title: 'Check the details',
      description:
          'Open a product to compare its pack size, price, and description before adding it to your basket.',
      hint: 'Product details',
      icon: Icons.info_outline_rounded,
      accent: Color(0xFF8E6BBF),
    ),
    _GuideStep(
      title: 'Build your basket',
      description:
          'Add products, adjust quantities, and review your subtotal and delivery area in your basket.',
      hint: 'Basket',
      icon: Icons.shopping_bag_outlined,
      accent: Color(0xFFD49B25),
    ),
    _GuideStep(
      title: 'You’re ready to shop',
      description:
          'Checkout is a preview for now. Order placement and delivery will be available once the service is connected.',
      hint: 'Checkout',
      icon: Icons.local_shipping_outlined,
      accent: Color(0xFFC05746),
    ),
  ];

  int _stepIndex = 0;
  bool _saving = false;
  String? _error;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    setState(() {
      _stepIndex = index;
      _error = null;
    });
    _animController
      ..reset()
      ..forward();
  }

  Future<void> _finish({required bool explore}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AuthState>().completeWalkthrough();
      if (mounted) Navigator.of(context).pop(explore);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your progress: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final isLastStep = _stepIndex == _steps.length - 1;
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * 0.9;

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(
              color: Colors.white,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Gradient hero header ──
                    _heroHeader(step),

                    // ── Body content ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step hint chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: step.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: step.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      step.hint.toUpperCase(),
                                      style: TextStyle(
                                        color: step.accent,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                step.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  height: 1.2,
                                  fontWeight: FontWeight.w900,
                                  color: GuzoColors.ink,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                step.description,
                                style: TextStyle(
                                  height: 1.5,
                                  fontSize: 13.5,
                                  color:
                                      GuzoColors.ink.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDECEC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFF5B5B5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        size: 16,
                                        color: Color(0xFFC05746),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Color(0xFFC05746),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Dot progress indicators ──
                    _stepDots(step.accent),

                    const SizedBox(height: 20),

                    // ── Action buttons ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => _finish(explore: false),
                            style: TextButton.styleFrom(
                              foregroundColor: GuzoColors.muted,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            child: const Text('Skip'),
                          ),
                          const Spacer(),
                          if (_stepIndex > 0)
                            _circleButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: _saving
                                  ? null
                                  : () => _goToStep(_stepIndex - 1),
                            ),
                          if (_stepIndex > 0) const SizedBox(width: 10),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saving
                                  ? null
                                  : isLastStep
                                      ? () => _finish(explore: true)
                                      : () => _goToStep(_stepIndex + 1),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: step.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isLastStep
                                              ? 'Start exploring'
                                              : 'Next',
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 17,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Gradient hero header with big icon
  // ─────────────────────────────────────────────────────────────
  Widget _heroHeader(_GuideStep step) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            step.accent,
            Color.lerp(step.accent, Colors.black, 0.28)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 24,
            child: Row(
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
                  child: const Text(
                    'WELCOME TO AQUAMARKET',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Big centered icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                step.icon,
                size: 46,
                color: Colors.white,
              ),
            ),
          ),
          // Step counter chip in bottom-right
          Positioned(
            bottom: 20,
            right: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${_stepIndex + 1} / ${_steps.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Dot progress indicators
  // ─────────────────────────────────────────────────────────────
  Widget _stepDots(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          for (int i = 0; i < _steps.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 6),
              height: 6,
              width: i == _stepIndex ? 24 : 8,
              decoration: BoxDecoration(
                color: i == _stepIndex
                    ? accent
                    : accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Circular back button
  // ─────────────────────────────────────────────────────────────
  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: const Color(0xFFF1F5F4),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            icon,
            size: 20,
            color: GuzoColors.ink.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}