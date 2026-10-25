import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../models/models.dart';

class AuthState extends ChangeNotifier {
  User? user;
  String? token;
  bool loading = false;
  bool initialized = false;
  bool walkthroughPending = false;

  bool get isLoggedIn => token != null && user != null;
  bool get isAdmin => user?.role == 'ADMIN';
  bool get isOwner => user?.role == 'OWNER';
  bool get isTraveler => user?.role == 'TRAVELER';
  bool get isDemoSession => user?.email == 'traveler@guzo.demo';

  String? get _walkthroughPreferenceKey =>
      user == null ? null : 'walkthrough_completed_${user!.id}';

  Future<void> _loadWalkthroughStatus(SharedPreferences prefs) async {
    final key = _walkthroughPreferenceKey;
    walkthroughPending = key != null && !(prefs.getBool(key) ?? false);
  }

  // ── Bootstrap on app start ────────────────────────────────
  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
      if (token != null) {
        ApiClient.instance.setToken(token);
        try {
          final data = await ApiClient.instance.get('/auth/me');
          user = User.fromJson(data['user'] as Map<String, dynamic>);
          await _loadWalkthroughStatus(prefs);
        } catch (_) {
          // Token invalid/expired → clear and force re-login
          await logout();
        }
      }
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      final data = await ApiClient.instance.post('/auth/login', body: {
        'email': email,
        'password': password,
      }) as Map<String, dynamic>;

      final tok = data['token'] as String?;
      final u = data['user'] as Map<String, dynamic>?;
      if (tok == null || u == null) {
        throw ApiException(500, 'Login response was missing user or token');
      }

      token = tok;
      user = User.fromJson(u);
      ApiClient.instance.setToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token!);
      await _loadWalkthroughStatus(prefs);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ── Register ─────────────────────────────────────────────
  Future<void> register({
    required String email,
    required String password,
    String? fullName,
    String? phone,
    String role = 'TRAVELER',
    String? hotelName,
    String? businessAddress,
  }) async {
    loading = true;
    notifyListeners();
    try {
      final data = await ApiClient.instance.post('/auth/register', body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'role': role.toUpperCase(),
        'hotelName': hotelName,
        'businessAddress': businessAddress,
      }) as Map<String, dynamic>;

      final u = data['user'] as Map<String, dynamic>?;
      if (u == null || u['id'] == null || u['email'] == null) {
        throw ApiException(500, 'Register response was missing user details');
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateFullName(String fullName) async {
    if (token == null || user == null) {
      throw StateError('You must be signed in to update your profile.');
    }

    final data = await ApiClient.instance.patch(
      '/auth/me',
      body: {'fullName': fullName},
    );
    if (data is! Map<String, dynamic> ||
        data['user'] is! Map<String, dynamic>) {
      throw ApiException(
          500, 'Profile update response was missing user details');
    }

    user = User.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> completeWalkthrough() async {
    final key = _walkthroughPreferenceKey;
    if (key == null) {
      throw StateError(
          'Cannot complete the walkthrough without a signed-in user.');
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setBool(key, true);
    if (!saved) {
      throw StateError('Unable to save walkthrough completion.');
    }
    walkthroughPending = false;
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    user = null;
    walkthroughPending = false;
    ApiClient.instance.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
