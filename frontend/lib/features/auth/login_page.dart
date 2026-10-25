import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/brand.dart';
import '../../core/theme.dart';
import '../../state/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    this.redirectTo,
    this.registrationCompleted = false,
    super.key,
  });
  final String? redirectTo;
  final bool registrationCompleted;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  String? _error;
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _signIn(_email.text.trim(), _password.text);
  }

  Future<void> _signInDemo() async {
    _email.text = 'traveler@guzo.demo';
    _password.text = 'Password123!';
    await _signIn(_email.text, _password.text);
  }

  Future<void> _signIn(String email, String password) async {
    setState(() => _error = null);
    try {
      final auth = context.read<AuthState>();
      await auth.login(email, password);
      if (!mounted) return;
      context.go(_destinationAfterLogin(auth));
    } catch (e) {
      if (mounted) setState(() => _error = _cleanError(e));
    }
  }

  String _cleanError(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  String _destinationAfterLogin(AuthState auth) {
    // Admins go straight to their dashboard
    if (auth.isAdmin) return '/admin';
    if (auth.isOwner) return '/explore';

    final destination = widget.redirectTo;
    if (destination == null ||
        !destination.startsWith('/') ||
        destination.startsWith('//')) {
      return '/user';
    }
    final path = Uri.tryParse(destination)?.path;
    if (path == '/login' || path == '/register' || path == '/auth-loading') {
      return '/user';
    }
    return destination;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF07110F),
      body: Stack(
        children: [
          const Positioned.fill(child: _Backdrop()),
          Positioned(
            top: -140,
            right: -120,
            child: _Blob(
                size: 400, color: GuzoColors.green.withValues(alpha: 0.30)),
          ),
          Positioned(
            bottom: -180,
            left: -140,
            child: _Blob(
                size: 420,
                color: const Color(0xFFE0A458).withValues(alpha: 0.22)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: isWide
                          ? _buildWide(context, auth)
                          : _buildNarrow(context, auth),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context, AuthState auth) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.14), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 60,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(flex: 5, child: _brandPanel()),
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.white.withValues(alpha: 0.04),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: _authForm(context, auth),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNarrow(BuildContext context, AuthState auth) {
    return Column(
      children: [
        Align(alignment: Alignment.centerLeft, child: _backButton(context)),
        const SizedBox(height: 20),
        const GuzoLogo(onDark: true),
        const SizedBox(height: 26),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: _authForm(context, auth),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _footer(),
      ],
    );
  }

  Widget _brandPanel() => Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GuzoColors.green.withValues(alpha: 0.22),
              const Color(0xFF0D3B36).withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const GuzoLogo(onDark: true),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(30),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 12, color: Color(0xFFE0A458)),
                      SizedBox(width: 6),
                      Text('CURATED STAYS IN ETHIOPIA',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Discover places\nthat feel like home.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                        height: 1.1)),
                const SizedBox(height: 16),
                Text(
                    'Handpicked hotels, lodges, and guesthouses '
                    'across Ethiopia — book in seconds, stay with confidence.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 28),
                const Wrap(spacing: 10, runSpacing: 10, children: [
                  _StatChip(icon: Icons.hotel_rounded, label: '2,400+ stays'),
                  _StatChip(
                      icon: Icons.people_alt_rounded, label: '120k travelers'),
                  _StatChip(icon: Icons.star_rounded, label: '4.9 avg rating'),
                ]),
              ],
            ),
            Text('GUZO · Where Ethiopia welcomes you',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6)),
          ],
        ),
      );

  Widget _authForm(BuildContext context, AuthState auth) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Welcome back',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.1)),
            const SizedBox(height: 8),
            Text('Sign in to continue your journey',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4)),
            const SizedBox(height: 26),
            _fieldLabel('Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: _validateEmail,
              decoration: _inputDecoration(
                  hint: 'name@example.com',
                  icon: Icons.alternate_email_rounded),
            ),
            const SizedBox(height: 16),
            _fieldLabel('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5),
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
              decoration: _inputDecoration(
                hint: 'Your password',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: 20,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor:
                      const Color(0xFFE0A458).withValues(alpha: 0.95),
                ),
                child: const Text('Forgot password?',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _glassError(_error!),
            ],
            if (widget.registrationCompleted) ...[
              const SizedBox(height: 12),
              _glassSuccess(
                  'Account created. Sign in with your email and password.'),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0A458), Color(0xFFF2C078)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE0A458).withValues(alpha: 0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: const Color(0xFF1A1208),
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: auth.loading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Color(0xFF1A1208)))
                        : const Row(
                            key: ValueKey('label'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Sign in',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 0.3)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child: Container(
                      height: 1, color: Colors.white.withValues(alpha: 0.14))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
              ),
              Expanded(
                  child: Container(
                      height: 1, color: Colors.white.withValues(alpha: 0.14))),
            ]),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: auth.loading ? null : _signInDemo,
                icon: const Icon(Icons.travel_explore_rounded, size: 19),
                label: const Text('Continue as demo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.28), width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _footer() => Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('New to GUZO? ',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              TextButton(
                onPressed: () => context.go('/register'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFFE0A458),
                ),
                child: const Text('Create an account',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.2)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.verified_user_outlined,
                size: 14, color: Colors.white.withValues(alpha: 0.45)),
            const SizedBox(width: 6),
            Text('Your details stay private and secure',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500)),
          ]),
        ],
      );

  Widget _backButton(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.go('/'),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 20, color: Colors.white),
          ),
        ),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3)),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixIcon:
            Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
        suffixIcon: suffix,
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13.5,
            fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.16), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0A458), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 1.6),
        ),
        errorStyle: const TextStyle(
            color: Color(0xFFFFB4AB),
            fontSize: 11.5,
            fontWeight: FontWeight.w600),
      );

  Widget _glassError(String message) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4A1D1A).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFFFB4AB).withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 17, color: Color(0xFFFFB4AB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFFFFDAD6),
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _glassSuccess(String message) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF173C32).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF80D6AD).withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 17, color: Color(0xFF80D6AD)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFFD4F5E4),
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }
}

// ── backdrop ──
class _Backdrop extends StatelessWidget {
  const _Backdrop();
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1F1C), Color(0xFF0D3B36), Color(0xFF113A33)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.7, -0.8),
                  radius: 1.4,
                  colors: [
                    GuzoColors.green.withValues(alpha: 0.30),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.9, 1.0),
                  radius: 1.3,
                  colors: [
                    const Color(0xFFE0A458).withValues(alpha: 0.18),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
        ]),
      );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: const Color(0xFFE0A458)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
        ]),
      );
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      );
}
