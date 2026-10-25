import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../state/auth_state.dart';

class BookingPage extends StatefulWidget {
  final String hotelId;
  const BookingPage({super.key, required this.hotelId});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _guestName = TextEditingController();
  final _phone = TextEditingController();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _defaultCheckIn() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  static DateTime _defaultCheckOut() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 2));
  }

  late DateTime _checkIn = _defaultCheckIn();
  late DateTime _checkOut = _defaultCheckOut();
  int _guests = 2;
  Map<String, dynamic>? _availability;
  Map<String, dynamic>? _hotel;
  bool _checking = false;
  bool _submitting = false;
  String? _error;
  String? _confirmation;

  static final _apiDateFormat = DateFormat('yyyy-MM-dd');

  Future<void> _pick(bool checkIn) async {
    final today = _dateOnly(DateTime.now());
    final initialDate = checkIn
        ? (_checkIn.isBefore(today) ? today : _checkIn)
        : (_checkOut.isBefore(_checkIn.add(const Duration(days: 1)))
            ? _checkIn.add(const Duration(days: 1))
            : _checkOut);

    final firstDate = checkIn ? today : _checkIn.add(const Duration(days: 1));
    final lastDate = today.add(const Duration(days: 730));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate)
          ? lastDate
          : (initialDate.isBefore(firstDate) ? firstDate : initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    final normalized = _dateOnly(picked);
    setState(() {
      if (checkIn) {
        _checkIn = normalized;
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else {
        _checkOut = normalized;
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      }
    });
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance
          .get('/hotels/${widget.hotelId}/availability', query: {
        'checkIn': _apiDateFormat.format(_checkIn),
        'checkOut': _apiDateFormat.format(_checkOut),
      });
      setState(() => _availability = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _checking = false);
    }
  }

  Future<void> _loadHotel() async {
    try {
      final data = await ApiClient.instance.get('/hotels/${widget.hotelId}');
      if (mounted) {
        setState(() => _hotel = data);
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    final guestName = _guestName.text.trim();
    final phone = _phone.text.trim();
    if (guestName.length < 2 || guestName.length > 120) {
      setState(() {
        _error = 'Enter your name so the hotel owner knows who booked.';
      });
      return;
    }
    if (!RegExp(r'^[+()\d\s.-]{7,30}$').hasMatch(phone)) {
      setState(() {
        _error = 'Enter a valid phone number for the hotel owner.';
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.post('/bookings', body: {
        'hotelId': widget.hotelId,
        'checkIn': _apiDateFormat.format(_checkIn),
        'checkOut': _apiDateFormat.format(_checkOut),
        'guests': _guests,
        'guestName': guestName,
        'phone': phone,
      });
      setState(() => _confirmation = data['reference']);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthState>().user;
    _guestName.text = user?.fullName ?? '';
    _phone.text = user?.phone ?? '';
    _loadHotel();
    _check();
  }

  @override
  void dispose() {
    _guestName.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final currency = NumberFormat.currency(
      locale: 'en_ET',
      symbol: 'ETB ',
      decimalDigits: 0,
    );
    final nights = _checkOut.difference(_checkIn).inDays.clamp(1, 999);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Material(
            color: Colors.white.withValues(alpha: 0.9),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.pop(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_rounded, size: 20),
              ),
            ),
          ),
        ),
        title: const Text(
          'Complete Booking',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _BookingBackground()),
          if (_confirmation != null)
            _confirmedView(currency)
          else
            RefreshIndicator(
              onRefresh: () async {
                await Future.wait([_loadHotel(), _check()]);
              },
              color: GuzoColors.green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroCard(nights, currency),
                        const SizedBox(height: 24),
                        _sectionLabel('Dates & guests'),
                        const SizedBox(height: 10),
                        _dateGuestsCard(fmt),
                        const SizedBox(height: 18),
                        _sectionLabel('Your contact details'),
                        const SizedBox(height: 10),
                        _guestContactCard(),
                        const SizedBox(height: 24),
                        _sectionLabel('Your stay'),
                        const SizedBox(height: 10),
                        _availabilityCard(currency, nights),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          _errorBanner(_error!),
                        ],
                        const SizedBox(height: 24),
                        _ctaBlock(),
                        const SizedBox(height: 14),
                        _policyNote(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const _BookingBottomBar(currentPath: '/book/room'),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Cinematic hero card with image
  // ─────────────────────────────────────────────────────────────
  Widget _defaultHeroImage() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GuzoColors.green, Color(0xFF1B4E46)],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.hotel_rounded,
            size: 64,
            color: Colors.white24,
          ),
        ),
      );

  Widget _heroCard(int nights, NumberFormat currency) {
    final price = _availability?['pricePerNight'] ?? _hotel?['basePrice'];
    final hotelName = _hotel?['name']?.toString();
    final hotelImage = _hotel?['coverImage']?.toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: (hotelImage != null && hotelImage.isNotEmpty)
                ? Image.network(
                    hotelImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultHeroImage(),
                  )
                : Image.network(
                    'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultHeroImage(),
                  ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        Icons.verified_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'INSTANT CONFIRM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  hotelName != null && hotelName.isNotEmpty
                      ? hotelName
                      : 'Your reservation',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$nights ${nights == 1 ? 'night' : 'nights'} · '
                  '$_guests ${_guests == 1 ? 'guest' : 'guests'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${DateFormat('MMM d').format(_checkIn)} → '
                            '${DateFormat('MMM d').format(_checkOut)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (price != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currency.format(price),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const Text(
                            'per night',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Dates + guests card
  // ─────────────────────────────────────────────────────────────
  Widget _dateGuestsCard(DateFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6ECEB)),
        boxShadow: [
          BoxShadow(
            color: GuzoColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'Check-in',
                  date: fmt.format(_checkIn),
                  onTap: () => _pick(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateField(
                  label: 'Check-out',
                  date: fmt.format(_checkOut),
                  onTap: () => _pick(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _guests,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Guests',
              prefixIcon: const Icon(Icons.people_outline_rounded),
              filled: true,
              fillColor: const Color(0xFFF5F8F7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5ECEE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: GuzoColors.green.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
            items: List.generate(8, (i) => i + 1)
                .map(
                  (n) => DropdownMenuItem(
                    value: n,
                    child: Text('$n guest${n > 1 ? 's' : ''}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _guests = v ?? 2),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5ECEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: GuzoColors.muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: GuzoColors.green,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: GuzoColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6ECEB)),
        boxShadow: [
          BoxShadow(
            color: GuzoColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the name and phone number you want to share with the hotel.',
            style: TextStyle(
              color: GuzoColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _guestName,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(
              labelText: 'Your name',
              hintText: 'Full name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              filled: true,
              fillColor: const Color(0xFFF5F8F7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5ECEE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: GuzoColors.green.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(
              labelText: 'Your phone number',
              hintText: '+251 9XX XXX XXX',
              prefixIcon: const Icon(Icons.phone_outlined),
              filled: true,
              fillColor: const Color(0xFFF5F8F7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5ECEE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: GuzoColors.green.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Availability card
  // ─────────────────────────────────────────────────────────────
  Widget _availabilityCard(NumberFormat currency, int nights) {
    if (_checking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE6ECEB)),
          boxShadow: [
            BoxShadow(
              color: GuzoColors.ink.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: GuzoColors.green,
            ),
          ),
        ),
      );
    }

    if (_availability == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE6ECEB)),
          boxShadow: [
            BoxShadow(
              color: GuzoColors.ink.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: GuzoColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.event_available_outlined,
                color: GuzoColors.green,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Select your dates to check availability.',
                style: TextStyle(
                  color: GuzoColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final avail = _availability!;
    final availableRooms = avail['availableRooms'] ?? 0;
    final pricePerNight = avail['pricePerNight'] ?? _hotel?['basePrice'] ?? 0;
    final total = avail['totalPrice'] ?? (pricePerNight * nights);
    final computedNights = (avail['nights'] as num?)?.toInt() ?? nights;
    final isAvailable = availableRooms > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6ECEB)),
        boxShadow: [
          BoxShadow(
            color: GuzoColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: isAvailable
                  ? GuzoColors.green.withValues(alpha: 0.08)
                  : const Color(0xFFFDECEC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? GuzoColors.green.withValues(alpha: 0.18)
                        : const Color(0xFFC05746).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAvailable
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 18,
                    color: isAvailable
                        ? GuzoColors.green
                        : const Color(0xFFC05746),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    isAvailable
                        ? '$availableRooms ${availableRooms == 1 ? 'room' : 'rooms'} available'
                        : 'No rooms available for these dates',
                    style: TextStyle(
                      color: isAvailable
                          ? GuzoColors.green
                          : const Color(0xFFC05746),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _summaryRow(
                  'Nights',
                  '$computedNights ${computedNights == 1 ? 'night' : 'nights'}',
                ),
                const SizedBox(height: 11),
                _summaryRow(
                  'Guests',
                  '$_guests ${_guests == 1 ? 'guest' : 'guests'}',
                ),
                const SizedBox(height: 11),
                _summaryRow(
                  'Price per night',
                  currency.format(pricePerNight),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFE8EEED)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: GuzoColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (computedNights > 1) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${currency.format(pricePerNight)} × $computedNights nights',
                            style: const TextStyle(
                              color: GuzoColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      currency.format(total),
                      style: const TextStyle(
                        color: GuzoColors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: const TextStyle(
              color: GuzoColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            v,
            style: const TextStyle(
              color: GuzoColors.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );

  // ─────────────────────────────────────────────────────────────
  // CTA block
  // ─────────────────────────────────────────────────────────────
  Widget _ctaBlock() {
    final canSubmit = !_submitting &&
        _availability != null &&
        ((_availability!['availableRooms'] ?? 0) >= 1);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: canSubmit ? _submit : null,
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.lock_rounded, size: 18),
        label: Text(
          _submitting ? 'Reserving…' : 'Confirm Reservation',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: GuzoColors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: GuzoColors.green.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _policyNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5ECEA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: GuzoColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Payment is not required for this demo. Booking will be PENDING until the hotel confirms.',
              style: TextStyle(
                color: GuzoColors.muted.withValues(alpha: 0.95),
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: GuzoColors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: GuzoColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      );

  Widget _errorBanner(String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF5B5B5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: Color(0xFFC05746),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Color(0xFFC05746),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────
  // Confirmed view
  // ─────────────────────────────────────────────────────────────
  Widget _confirmedView(NumberFormat currency) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            children: [
              // Success badge with concentric rings
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GuzoColors.green.withValues(alpha: 0.07),
                      ),
                    ),
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GuzoColors.green.withValues(alpha: 0.14),
                      ),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            GuzoColors.green,
                            GuzoColors.green.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GuzoColors.green.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Booking Requested',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: GuzoColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll notify you as soon as the hotel confirms.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GuzoColors.muted.withValues(alpha: 0.9),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6ECEB)),
                  boxShadow: [
                    BoxShadow(
                      color: GuzoColors.ink.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'REFERENCE',
                      style: TextStyle(
                        color: GuzoColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _confirmation ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: GuzoColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text(
                    'View My Bookings',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GuzoColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.go('/explore'),
                icon: const Icon(Icons.explore_outlined, size: 16),
                label: const Text('Keep exploring'),
                style: TextButton.styleFrom(
                  foregroundColor: GuzoColors.green,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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

// ─────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────
class _BookingBackground extends StatelessWidget {
  const _BookingBackground();

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
              size: 240,
              color: GuzoColors.green.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: -60,
            right: -90,
            child: _Blob(
              size: 200,
              color: const Color(0xFF4FB3A3).withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: _Blob(
              size: 280,
              color: GuzoColors.green.withValues(alpha: 0.14),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
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

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GuzoColors.ink.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    const spacing = 26.0;
    const radius = 1.1;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// Floating glassy bottom bar
// ─────────────────────────────────────────────────────────────
class _BookingBottomBar extends StatelessWidget {
  final String currentPath;
  const _BookingBottomBar({required this.currentPath});

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
                color: Colors.white.withValues(alpha: 0.85),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: GuzoColors.ink.withValues(alpha: 0.10),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
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
                  onTap: () => context.go('/'),
                ),
                _NavBtn(
                  icon: Icons.explore_outlined,
                  label: 'Explore',
                  active: currentPath == '/explore',
                  onTap: () => context.go('/explore'),
                ),
                _CenterAction(onTap: () => context.go('/explore')),
                _NavBtn(
                  icon: Icons.receipt_long_outlined,
                  label: 'Trips',
                  active: currentPath == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),
                _NavBtn(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  active: currentPath == '/user',
                  onTap: () => context.go('/user'),
                ),
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
  Widget build(BuildContext context) {
    return Expanded(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: active ? GuzoColors.green : GuzoColors.muted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? GuzoColors.green : GuzoColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  GuzoColors.green.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: GuzoColors.green.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
