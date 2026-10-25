import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/theme.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});
  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  List<dynamic> _hotels = [];
  List<dynamic> _bookings = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Timer? _bookingRefreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _bookingRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(showLoading: false),
    );
  }

  @override
  void dispose() {
    _bookingRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final h = await ApiClient.instance.getList('/hotels/mine');
      final b = await ApiClient.instance.getList('/owner/bookings');
      if (!mounted) return;
      setState(() {
        _hotels = h;
        _bookings = b;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _refreshing = false;
      if (mounted && showLoading) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
        locale: 'en_ET', symbol: 'ETB ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Owner Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: DashboardBackground(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: GuzoColors.green),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: GuzoColors.green,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                      children: [
                        const DashboardWelcomeCard(
                          eyebrow: 'Your hosting space',
                          title: 'Welcome back',
                          subtitle:
                              'Keep your stays and guest reservations in view.',
                          icon: Icons.apartment_rounded,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: DashboardStatCard(
                                label: 'Your hotels',
                                value: '${_hotels.length}',
                                icon: Icons.hotel_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DashboardStatCard(
                                label: 'Reservations',
                                value: '${_bookings.length}',
                                icon: Icons.book_online_rounded,
                                accentColor: GuzoColors.gold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'My Hotels',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_hotels.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Text('No hotels yet.'),
                            ),
                          ),
                        ..._hotels.map<Widget>(
                          (h) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 5,
                              ),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE7F3F3),
                                child: Icon(
                                  Icons.hotel_rounded,
                                  color: GuzoColors.green,
                                ),
                              ),
                              title: Text(
                                h['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text('${h['city']} • ${h['status']}'),
                              trailing: Text(
                                currency.format(h['basePrice']),
                                style: const TextStyle(
                                  color: GuzoColors.green,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Recent Reservations',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_bookings.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Text('No bookings yet.'),
                            ),
                          ),
                        ..._bookings.map<Widget>(
                          (b) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 5,
                              ),
                              isThreeLine: true,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE7F3F3),
                                child: Icon(
                                  Icons.luggage_rounded,
                                  color: GuzoColors.green,
                                ),
                              ),
                              title: Text(
                                '${b['hotel']?['name']} — ${b['reference']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Guest: ${b['user']?['fullName'] ?? 'Traveler'}',
                                  ),
                                  Text(
                                    'Phone: ${b['user']?['phone'] ?? 'Not provided'}',
                                  ),
                                  if ((b['user']?['email'] as String?)
                                          ?.isNotEmpty ??
                                      false)
                                    Text('Email: ${b['user']?['email']}'),
                                  Text(
                                    '${b['guests']} guests • ${b['nights']} nights • '
                                    '${b['checkIn']} to ${b['checkOut']}',
                                  ),
                                  Text(
                                    '${currency.format(b['totalPrice'] ?? 0)} • '
                                    '${b['status']}',
                                  ),
                                ],
                              ),
                              trailing: b['status'] == 'PENDING'
                                  ? IconButton(
                                      tooltip: 'Confirm reservation',
                                      icon: const Icon(
                                        Icons.check_circle_rounded,
                                        color: GuzoColors.green,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await ApiClient.instance.patch(
                                            '/owner/bookings/${b['id']}/confirm',
                                          );
                                          await _load();
                                        } catch (error) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Could not confirm booking: $error',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
