import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../state/auth_state.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _stats;
  List<dynamic> _hotels = [];
  List<dynamic> _users = [];
  bool _loading = true;
  bool _creatingHotel = false;
  bool _gateChecked = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndLoad());
  }

  Future<void> _checkAndLoad() async {
    final auth = context.read<AuthState>();
    if (!auth.isAdmin) {
      context.go('/login?redirectTo=/admin');
      return;
    }
    setState(() => _gateChecked = true);
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final errors = <String>[];
    Map<String, dynamic>? stats;
    List<dynamic>? hotels;
    List<dynamic>? users;

    try {
      stats = await ApiClient.instance.get('/admin/stats');
    } catch (error) {
      errors.add('Dashboard statistics: $error');
    }
    try {
      hotels = await ApiClient.instance.getList('/admin/hotels');
    } catch (error) {
      errors.add('Hotel submissions: $error');
    }
    try {
      users = await ApiClient.instance.getList('/admin/users');
    } catch (error) {
      errors.add('Registered users: $error');
    }

    if (!mounted) return;
    setState(() {
      if (stats != null) _stats = stats;
      if (hotels != null) _hotels = hotels;
      if (users != null) _users = users;
      _loadError = errors.isEmpty ? null : errors.join('\n');
      _loading = false;
    });
  }

  Future<void> _act(String id, String action) async {
    try {
      await ApiClient.instance.patch('/admin/hotels/$id/$action');
      await _load();
    } catch (_) {}
  }

  Future<void> _setOwnerStatus(String id, String action) async {
    try {
      await ApiClient.instance.patch('/admin/users/$id/$action');
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Hotel owner accepted and activated.'
                : 'Hotel owner banned and deactivated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update hotel owner: $error')),
      );
    }
  }

  Future<void> _addHotel() async {
    final hotel = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _CreateHotelDialog(),
    );
    if (hotel == null || !mounted) return;

    setState(() => _creatingHotel = true);
    try {
      await ApiClient.instance.post('/hotels', body: hotel);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: GuzoColors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Hotel published successfully.',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC05746),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text('Could not add hotel: $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _creatingHotel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_gateChecked) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F8),
        body: Center(child: CircularProgressIndicator(color: GuzoColors.green)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      extendBody: true,
      body: Stack(children: [
        const Positioned.fill(child: _AdminBackground()),
        SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: GuzoColors.green))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: GuzoColors.green,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
                    children: [
                      _topBar(context),
                      const SizedBox(height: 22),
                      _heroBanner(),
                      if (_loadError != null) ...[
                        const SizedBox(height: 16),
                        _loadErrorCard(_loadError!),
                      ],
                      const SizedBox(height: 22),
                      _statsRow(),
                      const SizedBox(height: 22),
                      _addHotelCard(),
                      const SizedBox(height: 26),

                      // Registered users
                      _sectionHeading('Registered Users',
                          subtitle: _users.isEmpty
                              ? 'No registrations yet'
                              : '${_users.length} ${_users.length == 1 ? 'account' : 'accounts'}'),
                      const SizedBox(height: 14),
                      if (_users.isEmpty)
                        _emptyCard(
                          icon: Icons.person_add_alt_rounded,
                          title: 'No registered users yet',
                          message:
                              'Accounts created via the app will show up here, with email and role.',
                        )
                      else
                        ..._users.map<Widget>((u) => _userCard(u)),

                      const SizedBox(height: 26),

                      // Hotel submissions
                      _sectionHeading('Hotel Submissions',
                          subtitle: _hotels.isEmpty
                              ? 'Nothing to review yet'
                              : '${_hotels.length} ${_hotels.length == 1 ? 'listing' : 'listings'}'),
                      const SizedBox(height: 14),
                      if (_hotels.isEmpty)
                        _emptyCard(
                          icon: Icons.inbox_rounded,
                          title: 'No hotel submissions yet',
                          message:
                              'New listings from owners will appear here for review.',
                        )
                      else
                        ..._hotels.map<Widget>((h) => _hotelCard(h)),
                    ],
                  ),
                ),
        ),
      ]),
      bottomNavigationBar: const _AdminBottomBar(currentPath: '/admin'),
    );
  }

  // ── Top bar ────────────────────────────────────────────────
  Widget _topBar(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85), width: 1),
              boxShadow: [
                BoxShadow(
                    color: GuzoColors.ink.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Row(children: [
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.go('/'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.6),
                      border: Border.all(color: const Color(0xFFE5ECEA)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: GuzoColors.ink),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GuzoColors.green,
                      GuzoColors.green.withValues(alpha: 0.75)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: GuzoColors.ink)),
                    Text('Control center',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: GuzoColors.muted)),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    await context.read<AuthState>().logout();
                    if (context.mounted) context.go('/login');
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.6),
                      border: Border.all(color: const Color(0xFFE5ECEA)),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        size: 18, color: GuzoColors.ink),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );

  // ── Hero ──────────────────────────────────────────────────
  Widget _heroBanner() => ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 190,
          child: Stack(fit: StackFit.expand, children: [
            Image.network(
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1400&q=85',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B5260), Color(0xFF1B4E46)],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Spacer(),
                  Text('Good to see you.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1.1)),
                  SizedBox(height: 6),
                  Text('Review activity and keep the community thriving.',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ]),
        ),
      );

  // ── Stats ─────────────────────────────────────────────────
  Widget _statsRow() {
    final items = [
      (
        label: 'Users',
        value: '${_stats?['users'] ?? 0}',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF2E86AB)
      ),
      (
        label: 'Hotels',
        value: '${_stats?['hotels'] ?? 0}',
        icon: Icons.hotel_rounded,
        color: GuzoColors.green
      ),
      (
        label: 'Bookings',
        value: '${_stats?['bookings'] ?? 0}',
        icon: Icons.book_online_rounded,
        color: const Color(0xFF8E6BBF)
      ),
    ];
    return Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            label: items[i].label,
            value: items[i].value,
            icon: items[i].icon,
            color: items[i].color,
          ),
        ),
      ],
    ]);
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE6ECEB)),
          boxShadow: [
            BoxShadow(
                color: GuzoColors.ink.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: GuzoColors.ink)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: GuzoColors.muted)),
        ]),
      );

  // ── Add hotel ─────────────────────────────────────────────
  Widget _addHotelCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GuzoColors.green,
              GuzoColors.green.withValues(alpha: 0.78)
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: GuzoColors.green.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add_business_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add a hotel',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        letterSpacing: -0.3)),
                SizedBox(height: 3),
                Text('Create and publish a new stay listing.',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: _creatingHotel ? null : _addHotel,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: GuzoColors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              icon: _creatingHotel
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: GuzoColors.green))
                  : const Icon(Icons.add_rounded, size: 18),
              label: Text(_creatingHotel ? 'Saving' : 'Add'),
            ),
          ),
        ]),
      );

  // ── Section heading ───────────────────────────────────────
  Widget _sectionHeading(String title, {String? subtitle}) => Row(children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: GuzoColors.green, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: GuzoColors.ink)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GuzoColors.muted)),
            ],
          ]),
        ),
      ]);

  // ── Empty card ────────────────────────────────────────────
  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) =>
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE6ECEB)),
          boxShadow: [
            BoxShadow(
                color: GuzoColors.ink.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: GuzoColors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: GuzoColors.green),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: GuzoColors.ink)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, color: GuzoColors.muted, height: 1.4)),
        ]),
      );

  Widget _loadErrorCard(String message) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2EF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6B6AB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFC05746)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFF74372D), fontSize: 12, height: 1.35)),
            ),
            IconButton(
              tooltip: 'Retry loading dashboard',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      );

  // ── User card ─────────────────────────────────────────────
  Widget _userCard(dynamic u) {
    final email = u['email']?.toString() ?? '—';
    final fullName = u['full_name']?.toString() ?? '';
    final phone = u['phone']?.toString() ?? '';
    final hotelName = u['hotel_name']?.toString() ?? '';
    final businessAddress = u['business_address']?.toString() ?? '';
    final role = (u['role']?.toString() ?? 'TRAVELER').toUpperCase();
    final active = u['is_active'] == true;
    final ownerStatus =
        (u['owner_status']?.toString() ?? (active ? 'APPROVED' : 'PENDING'))
            .toUpperCase();
    final createdAt = DateTime.tryParse(u['created_at']?.toString() ?? '');

    final roleColor = switch (role) {
      'ADMIN' => const Color(0xFF8E6BBF),
      'OWNER' => const Color(0xFFD49B25),
      _ => const Color(0xFF2E86AB),
    };

    String fmt(DateTime? d) => d == null
        ? ''
        : '${d.day.toString().padLeft(2, '0')}/'
            '${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECEB)),
        boxShadow: [
          BoxShadow(
              color: GuzoColors.ink.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.person_rounded, color: roleColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(fullName.isEmpty ? 'Unnamed user' : fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: GuzoColors.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(role,
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: roleColor)),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.alternate_email_rounded,
                  size: 13, color: GuzoColors.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GuzoColors.muted)),
              ),
            ]),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.phone_outlined,
                    size: 13, color: GuzoColors.muted),
                const SizedBox(width: 4),
                Text(phone,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GuzoColors.muted)),
              ]),
            ],
            if (hotelName.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text('Hotel: $hotelName',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: GuzoColors.ink)),
            ],
            if (businessAddress.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(businessAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, color: GuzoColors.muted, height: 1.3)),
            ],
            const SizedBox(height: 6),
            Row(children: [
              Icon(
                ownerStatus == 'BANNED'
                    ? Icons.block_rounded
                    : ownerStatus == 'PENDING'
                        ? Icons.hourglass_top_rounded
                        : active
                            ? Icons.check_circle_rounded
                            : Icons.pause_circle_filled_rounded,
                size: 12,
                color: ownerStatus == 'APPROVED' && active
                    ? GuzoColors.green
                    : ownerStatus == 'PENDING'
                        ? const Color(0xFFD49B25)
                        : const Color(0xFFC05746),
              ),
              const SizedBox(width: 4),
              Text(
                  role == 'OWNER'
                      ? switch (ownerStatus) {
                          'PENDING' => 'Pending review',
                          'BANNED' => 'Banned',
                          _ => active ? 'Approved · Active' : 'Inactive',
                        }
                      : active
                          ? 'Active'
                          : 'Inactive',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: ownerStatus == 'APPROVED' && active
                          ? GuzoColors.green
                          : ownerStatus == 'PENDING'
                              ? const Color(0xFFD49B25)
                              : const Color(0xFFC05746))),
              if (createdAt != null) ...[
                const SizedBox(width: 12),
                Text('Joined ${fmt(createdAt)}',
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: GuzoColors.muted)),
              ],
            ]),
            if (role == 'OWNER') ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (ownerStatus != 'APPROVED' || !active)
                    FilledButton.icon(
                      onPressed: () =>
                          _setOwnerStatus(u['id'].toString(), 'approve'),
                      icon: const Icon(Icons.verified_rounded, size: 17),
                      label: Text(ownerStatus == 'BANNED'
                          ? 'Reactivate owner'
                          : 'Accept owner'),
                      style: FilledButton.styleFrom(
                        backgroundColor: GuzoColors.green,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (ownerStatus != 'BANNED')
                    OutlinedButton.icon(
                      onPressed: () =>
                          _setOwnerStatus(u['id'].toString(), 'ban'),
                      icon: const Icon(Icons.block_rounded, size: 17),
                      label: const Text('Ban owner'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC05746),
                        side: const BorderSide(color: Color(0xFFE6B6AB)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  // ── Hotel card ────────────────────────────────────────────
  Widget _hotelCard(dynamic h) {
    final name = h['name']?.toString() ?? 'Hotel';
    final city = h['city']?.toString() ?? '';
    final status = (h['status']?.toString() ?? 'PENDING').toUpperCase();
    final coverImage = (h['coverImage']?.toString().isNotEmpty == true)
        ? h['coverImage'].toString()
        : (h['cover_image']?.toString().isNotEmpty == true)
            ? h['cover_image'].toString()
            : (h['images'] is List && (h['images'] as List).isNotEmpty
                ? ((h['images'] as List).first is Map
                    ? (h['images'] as List).first['url']?.toString()
                    : (h['images'] as List).first?.toString())
                : null);

    final statusColor = switch (status) {
      'APPROVED' => GuzoColors.green,
      'SUSPENDED' => const Color(0xFFC05746),
      'REJECTED' => const Color(0xFFC05746),
      _ => const Color(0xFFD49B25),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6ECEB)),
        boxShadow: [
          BoxShadow(
              color: GuzoColors.ink.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Stack(children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: coverImage != null && coverImage.isNotEmpty
                  ? Image.network(coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback())
                  : _imageFallback(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45)
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0)),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 8)])),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: GuzoColors.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: GuzoColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              if (status != 'APPROVED')
                Expanded(
                  child: _actionButton(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Approve',
                    color: GuzoColors.green,
                    onTap: () => _act(h['id'].toString(), 'approve'),
                  ),
                ),
              if (status != 'APPROVED') const SizedBox(width: 8),
              if (status != 'SUSPENDED')
                Expanded(
                  child: _actionButton(
                    icon: Icons.block_rounded,
                    label: 'Suspend',
                    color: const Color(0xFFC05746),
                    onTap: () => _act(h['id'].toString(), 'suspend'),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );

  Widget _imageFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE7EFED), Color(0xFFD8E5E2)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.hotel_rounded, size: 42, color: Color(0xFF9BAEAA)),
        ),
      );
}

// ── Background ──────────────────────────────────────────────
class _AdminBackground extends StatelessWidget {
  const _AdminBackground();
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Stack(children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF1F7F5),
                  Color(0xFFF6F9F8),
                  Color(0xFFEEF4F2)
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -80,
            child: _Blob(
                size: 240, color: GuzoColors.green.withValues(alpha: 0.16)),
          ),
          Positioned(
            top: -60,
            right: -90,
            child: _Blob(
                size: 200,
                color: const Color(0xFF4FB3A3).withValues(alpha: 0.14)),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: _Blob(
                size: 280, color: GuzoColors.green.withValues(alpha: 0.14)),
          ),
        ]),
      );
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}

// ── Bottom bar ──────────────────────────────────────────────
class _AdminBottomBar extends StatelessWidget {
  final String currentPath;
  const _AdminBottomBar({required this.currentPath});
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset * 0.4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85), width: 1),
              boxShadow: [
                BoxShadow(
                    color: GuzoColors.ink.withValues(alpha: 0.10),
                    blurRadius: 26,
                    offset: const Offset(0, 12)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavBtn(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    active: currentPath == '/',
                    onTap: () => context.go('/')),
                _NavBtn(
                    icon: Icons.explore_outlined,
                    label: 'Explore',
                    active: currentPath == '/explore',
                    onTap: () => context.go('/explore')),
                _CenterAction(onTap: () => context.go('/explore')),
                _NavBtn(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin',
                    active: currentPath == '/admin',
                    onTap: () => context.go('/admin')),
                _NavBtn(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    active: currentPath == '/user',
                    onTap: () => context.go('/user')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: active
                    ? GuzoColors.green.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    size: 22,
                    color: active ? GuzoColors.green : GuzoColors.muted),
                const SizedBox(height: 3),
                Text(label,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active ? GuzoColors.green : GuzoColors.muted)),
              ]),
            ),
          ),
        ),
      );
}

class _CenterAction extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterAction({required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GuzoColors.green,
                    GuzoColors.green.withValues(alpha: 0.75)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: GuzoColors.green.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.search_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
        ),
      );
}

// ── Create hotel dialog (unchanged from your original) ─────
class _CreateHotelDialog extends StatefulWidget {
  const _CreateHotelDialog();
  @override
  State<_CreateHotelDialog> createState() => _CreateHotelDialogState();
}

class _CreateHotelDialogState extends State<_CreateHotelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _basePrice = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _imageUrl = TextEditingController();
  final _amenities = TextEditingController();
  String _category = 'luxury';
  final List<String> _photos = [];

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    _description.dispose();
    _basePrice.dispose();
    _phone.dispose();
    _email.dispose();
    _imageUrl.dispose();
    _amenities.dispose();
    super.dispose();
  }

  void _addPhoto() {
    final url = _imageUrl.text.trim();
    if (url.isEmpty) return;
    final parsed = Uri.tryParse(url);
    if (parsed == null ||
        !parsed.hasScheme ||
        (parsed.scheme != 'http' && parsed.scheme != 'https') ||
        parsed.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid image URL first.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() {
      _photos.add(url);
      _imageUrl.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    Navigator.of(context).pop({
      'name': _name.text.trim(),
      'city': _city.text.trim(),
      'address': _address.text.trim(),
      'description': _description.text.trim(),
      'category': _category,
      'basePrice': int.parse(_basePrice.text.trim()),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (email.isNotEmpty) 'email': email,
      if (_photos.isNotEmpty) 'images': _photos,
      if (_amenities.text.trim().isNotEmpty)
        'amenities': _amenities.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList(),
    });
  }

  String? _required(String? v, int min) => (v == null || v.trim().length < min)
      ? 'Enter at least $min characters'
      : null;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: 520, maxHeight: size.height * 0.9),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Material(
            color: Colors.white,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 16, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GuzoColors.green,
                      GuzoColors.green.withValues(alpha: 0.78)
                    ],
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_business_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add a hotel',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4)),
                        SizedBox(height: 3),
                        Text('Publish a new stay listing',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18)),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Basics'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'Hotel name',
                              prefixIcon: Icon(Icons.hotel_outlined)),
                          validator: (v) => _required(v, 2),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _city,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon: Icon(Icons.location_city_rounded)),
                          validator: (v) => _required(v, 2),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _address,
                          decoration: const InputDecoration(
                              labelText: 'Street address',
                              prefixIcon: Icon(Icons.location_on_outlined)),
                          validator: (v) => _required(v, 3),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _description,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                              labelText: 'Description',
                              alignLabelWithHint: true,
                              prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 52),
                                  child: Icon(Icons.notes_rounded))),
                          validator: (v) => _required(v, 10),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined)),
                          items: const [
                            DropdownMenuItem(
                                value: 'luxury', child: Text('Luxury')),
                            DropdownMenuItem(
                                value: 'budget', child: Text('Budget')),
                            DropdownMenuItem(
                                value: 'resort', child: Text('Resort')),
                            DropdownMenuItem(
                                value: 'guesthouse', child: Text('Guesthouse')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _category = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _basePrice,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Price per night (ETB)',
                              prefixIcon: Icon(Icons.payments_outlined)),
                          validator: (v) {
                            final p = int.tryParse(v?.trim() ?? '');
                            if (p == null || p <= 0) {
                              return 'Enter a whole price greater than zero';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        _sectionLabel('Photos'),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _imageUrl,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                  hintText: 'https://example.com/photo.jpg',
                                  labelText: 'Image URL',
                                  prefixIcon: Icon(Icons.image_outlined)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: FilledButton(
                              onPressed: _addPhoto,
                              style: FilledButton.styleFrom(
                                backgroundColor: GuzoColors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 22),
                            ),
                          ),
                        ]),
                        if (_photos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F4),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFE6ECEB)),
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (int i = 0; i < _photos.length; i++)
                                  SizedBox(
                                    width: 92,
                                    height: 92,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(_photos[i],
                                              width: 92,
                                              height: 92,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    color:
                                                        const Color(0xFFE7EFED),
                                                    child: const Icon(
                                                        Icons
                                                            .broken_image_outlined,
                                                        color:
                                                            Color(0xFF9BAEAA)),
                                                  )),
                                        ),
                                        Positioned(
                                          top: -6,
                                          right: -6,
                                          child: Material(
                                            color: const Color(0xFFC05746),
                                            shape: const CircleBorder(),
                                            child: InkWell(
                                              customBorder:
                                                  const CircleBorder(),
                                              onTap: () => setState(
                                                  () => _photos.removeAt(i)),
                                              child: const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: Icon(Icons.close_rounded,
                                                    size: 14,
                                                    color: Colors.white),
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
                        ],
                        const SizedBox(height: 22),
                        _sectionLabel('Contact'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                              labelText: 'Phone (optional)',
                              prefixIcon: Icon(Icons.phone_outlined)),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Contact email (optional)',
                              prefixIcon: Icon(Icons.alternate_email_rounded)),
                          validator: (v) {
                            final e = v?.trim() ?? '';
                            if (e.isNotEmpty &&
                                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(e)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        _sectionLabel('Amenities'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _amenities,
                          decoration: const InputDecoration(
                              labelText: 'Comma separated',
                              hintText: 'WiFi, Pool, Breakfast',
                              prefixIcon: Icon(Icons.checklist_rounded)),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Colors.black.withValues(alpha: 0.06)))),
                child: SafeArea(
                  top: false,
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          foregroundColor: GuzoColors.muted,
                          side: const BorderSide(color: Color(0xFFE5ECEA)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: GuzoColors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.publish_rounded, size: 18),
                        label: const Text('Publish hotel'),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Row(children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
              color: GuzoColors.green, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text.toUpperCase(),
            style: const TextStyle(
                color: GuzoColors.ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2)),
      ]);
}
