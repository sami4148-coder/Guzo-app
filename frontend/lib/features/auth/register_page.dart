import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/brand.dart';
import '../../core/theme.dart';
import '../../state/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _businessAddress = TextEditingController();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String _role = 'TRAVELER';
  bool _obscurePassword = true;
  String? _error;
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _email.addListener(() => setState(() {}));
    _phone.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _businessAddress.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await context.read<AuthState>().register(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _role == 'OWNER'
                ? _name.text.trim().isEmpty
                    ? null
                    : _name.text.trim()
                : _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            role: _role,
            hotelName: _role == 'OWNER' ? _name.text.trim() : null,
            businessAddress:
                _role == 'OWNER' ? _businessAddress.text.trim() : null,
          );
      if (mounted && _role == 'OWNER') {
        context.go('/owner-pending', extra: _email.text.trim());
      } else if (mounted) {
        context.go('/login?registered=1');
      }
    } catch (e) {
      if (mounted) setState(() => _error = _cleanError(e));
    }
  }

  String _cleanError(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
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
                      constraints: const BoxConstraints(maxWidth: 1120),
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

  Widget _buildWide(BuildContext context, AuthState auth) => ClipRRect(
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
                    offset: const Offset(0, 30)),
              ],
            ),
            child: Row(children: [
              Expanded(flex: 5, child: _brandPanel()),
              Expanded(
                flex: 5,
                child: Container(
                  color: Colors.white.withValues(alpha: 0.04),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                  child: _registerForm(context, auth),
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _buildNarrow(BuildContext context, AuthState auth) => Column(
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
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 20)),
                  ],
                ),
                child: _registerForm(context, auth),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _footer(),
        ],
      );

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
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    Text('JOIN THE GUZO COMMUNITY',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Your journey\nstarts here.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.1)),
              const SizedBox(height: 16),
              Text(
                  'Create a free account to book unique stays, '
                  'manage reservations, and list your property '
                  'to travelers from around the world.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 28),
              const _BenefitRow(
                  icon: Icons.flash_on_rounded,
                  title: 'Book in seconds',
                  subtitle: 'Instant confirmation on most stays'),
              const SizedBox(height: 14),
              const _BenefitRow(
                  icon: Icons.shield_moon_rounded,
                  title: 'Secure by default',
                  subtitle: 'Bank-grade encryption on all data'),
              const SizedBox(height: 14),
              const _BenefitRow(
                  icon: Icons.support_agent_rounded,
                  title: '24/7 support',
                  subtitle: 'Real humans, always available'),
            ]),
            Text('GUZO · Where Ethiopia welcomes you',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6)),
          ],
        ),
      );

  Widget _registerForm(BuildContext context, AuthState auth) {
    final passwordLen = _password.text.length;

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Create your account',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.1)),
            const SizedBox(height: 8),
            Text('A few details now, then you are on your way.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4)),
            const SizedBox(height: 24),
            if (_role == 'TRAVELER') ...[
              _fieldLabel('Full name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5),
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                validator: (v) =>
                    _role == 'TRAVELER' && (v?.trim().length ?? 0) < 2
                        ? 'Enter your full name'
                        : null,
                decoration: _inputDecoration(
                    hint: 'Your name', icon: Icons.person_outline_rounded),
              ),
            ],
            const SizedBox(height: 14),
            _fieldLabel(_role == 'OWNER' ? 'Business email' : 'Email address'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5),
              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
              validator: _validateEmail,
              decoration: _inputDecoration(
                  hint: 'you@example.com', icon: Icons.alternate_email_rounded),
            ),
            const SizedBox(height: 14),
            _fieldLabel(_role == 'OWNER'
                ? 'Business phone number'
                : 'Phone number · Optional'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phone,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5),
              validator: (value) =>
                  _role == 'OWNER' && (value?.trim().isEmpty ?? true)
                      ? 'Enter your business phone number'
                      : null,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              decoration: _inputDecoration(
                  hint: '+251 9XX XXX XXX', icon: Icons.phone_outlined),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5),
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  (v?.length ?? 0) < 8 ? 'Use at least 8 characters' : null,
              decoration: _inputDecoration(
                hint: 'At least 8 characters',
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
            if (passwordLen > 0) ...[
              const SizedBox(height: 12),
              _PasswordStrengthBar(length: passwordLen),
            ],
            const SizedBox(height: 22),
            Row(children: [
              Container(
                width: 4,
                height: 15,
                decoration: BoxDecoration(
                    color: const Color(0xFFE0A458),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              const Text('I am joining as a',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.2)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _AccountTypeCard(
                  selected: _role == 'TRAVELER',
                  icon: Icons.luggage_outlined,
                  title: 'Traveler',
                  subtitle: 'Find a stay',
                  onTap: () => setState(() => _role = 'TRAVELER'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AccountTypeCard(
                  selected: _role == 'OWNER',
                  icon: Icons.apartment_rounded,
                  title: 'Hotel owner',
                  subtitle: 'Host guests',
                  onTap: () => setState(() => _role = 'OWNER'),
                ),
              ),
            ]),
            if (_role == 'OWNER') ...[
              const SizedBox(height: 16),
              _fieldLabel('Hotel name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5),
                validator: (value) =>
                    _role == 'OWNER' && (value?.trim().length ?? 0) < 2
                        ? 'Enter your hotel name'
                        : null,
                decoration: _inputDecoration(
                  hint: 'Your property name',
                  icon: Icons.hotel_rounded,
                ),
              ),
              const SizedBox(height: 14),
              _fieldLabel('Business address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessAddress,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 3,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5),
                validator: (value) =>
                    _role == 'OWNER' && (value?.trim().length ?? 0) < 5
                        ? 'Enter your business address'
                        : null,
                decoration: _inputDecoration(
                  hint: 'Street, city, region',
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'New hotel owner accounts need admin approval before sign-in.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              _glassError(_error!),
            ],
            const SizedBox(height: 20),
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
                              Text('Create account',
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
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_outline_rounded,
                  size: 13, color: Colors.white.withValues(alpha: 0.55)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                    'Your details help us manage your account and reservations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
            const SizedBox(height: 22),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _footer() => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Already have an account? ',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: const Color(0xFFE0A458),
            ),
            child: const Text('Sign in',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.2)),
          ),
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

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }
}

// ── supporting widgets ──────────────────────────────────────
class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFE0A458).withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: selected
                    ? const Color(0xFFE0A458)
                    : Colors.white.withValues(alpha: 0.16),
                width: selected ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color:
                              const Color(0xFFE0A458).withValues(alpha: 0.20),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ]
                  : null,
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE0A458).withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 17,
                    color: selected
                        ? const Color(0xFFF2C078)
                        : Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    size: 17, color: Color(0xFFE0A458)),
            ]),
          ),
        ),
      );
}

class _PasswordStrengthBar extends StatelessWidget {
  final int length;
  const _PasswordStrengthBar({required this.length});
  @override
  Widget build(BuildContext context) {
    final strength = length >= 12
        ? 3
        : length >= 10
            ? 2
            : length >= 8
                ? 1
                : 0;
    final labels = ['Too short', 'Good', 'Strong', 'Excellent'];
    final colors = [
      const Color(0xFFFFB4AB),
      const Color(0xFFE0A458),
      const Color(0xFF8CE6C4),
      const Color(0xFF82C8E8),
    ];
    return Row(children: [
      for (int i = 0; i < 4; i++)
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 4,
            margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
            decoration: BoxDecoration(
              color: i < strength
                  ? colors[strength]
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      const SizedBox(width: 10),
      Text(labels[strength],
          style: TextStyle(
              color: colors[strength],
              fontSize: 11,
              fontWeight: FontWeight.w800)),
    ]);
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE0A458).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFE0A458).withValues(alpha: 0.28)),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFE0A458)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      );
}

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
