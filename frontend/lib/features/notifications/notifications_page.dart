import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

class NotificationsBellButton extends StatefulWidget {
  const NotificationsBellButton({
    this.backgroundColor = const Color(0xE6FFFFFF),
    super.key,
  });

  final Color backgroundColor;

  @override
  State<NotificationsBellButton> createState() =>
      _NotificationsBellButtonState();
}

class _NotificationsBellButtonState extends State<NotificationsBellButton> {
  int _unreadCount = 0;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadUnreadCount(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final notifications = await ApiClient.instance.getList('/notifications');
      if (!mounted) return;
      setState(() {
        _unreadCount = notifications.where((item) {
          return item is Map && item['readAt'] == null;
        }).length;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _openNotifications() async {
    await context.push('/notifications');
    if (!mounted) return;
    await _loadUnreadCount();
    if (!mounted) return;
    if (_error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh notifications: $_error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Notifications${_unreadCount > 0 ? ' ($_unreadCount new)' : ''}',
      child: Material(
        color: widget.backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _openNotifications,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 18,
                  color: GuzoColors.ink,
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC05746),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<HotelPostNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiClient.instance.getList('/notifications');
      if (!mounted) return;
      setState(() {
        _notifications = result
            .map((item) => HotelPostNotification.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openNotification(
    HotelPostNotification notification,
  ) async {
    if (!notification.isRead) {
      try {
        await ApiClient.instance.patch(
          '/notifications/${notification.id}/read',
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update notification: $error')),
        );
        return;
      }
    }
    if (mounted) context.push('/hotels/${notification.hotelId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: _content(),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: GuzoColors.green),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notifications could not be loaded: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: GuzoColors.muted),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: GuzoColors.green,
              ),
              SizedBox(height: 12),
              Text(
                'You’re all caught up',
                style: TextStyle(
                  color: GuzoColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'New hotel listings from local hosts will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GuzoColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: GuzoColors.green,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Material(
            color: notification.isRead ? Colors.white : const Color(0xFFEFF8F4),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openNotification(notification),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _image(notification.imageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              color: GuzoColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: const TextStyle(
                              color: GuzoColors.muted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('MMM d, y · h:mm a')
                                .format(notification.createdAt.toLocal()),
                            style: const TextStyle(
                              color: GuzoColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.circle,
                        color: GuzoColors.green,
                        size: 9,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _image(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFE7EFED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.hotel_rounded, color: GuzoColors.green),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 64,
          height: 64,
          color: const Color(0xFFE7EFED),
          child: const Icon(Icons.hotel_rounded, color: GuzoColors.green),
        ),
      ),
    );
  }
}
