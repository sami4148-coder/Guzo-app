import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/booking/booking_page.dart';
import '../features/dashboard/admin_dashboard.dart';
import '../features/dashboard/owner_dashboard.dart';
import '../features/dashboard/traveler_dashboard.dart';
import '../features/explore/explore_page.dart';
import '../features/home_page.dart';
import '../features/hotel/hotel_details_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/user_page.dart';
import '../screens/help/help_center_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/owner_pending/owner_pending_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../state/auth_state.dart';

GoRouter createGuzoRouter(AuthState auth) => GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final location = state.matchedLocation;
        if (!auth.initialized) {
          return location == '/splash' ? null : '/splash';
        }

        if (location == '/splash') return null;

        String landingPage() {
          if (auth.isAdmin) return '/admin';
          if (auth.isOwner) return '/explore';
          return '/user';
        }

        if (auth.isLoggedIn &&
            (location == '/onboarding' ||
                location == '/welcome' ||
                location == '/owner-pending' ||
                location == '/login' ||
                location == '/register' ||
                location == '/auth-loading')) {
          return landingPage();
        }

        if (!auth.isLoggedIn) {
          if (location == '/onboarding' ||
              location == '/welcome' ||
              location == '/owner-pending' ||
              location == '/help' ||
              location == '/login' ||
              location == '/register') {
            return null;
          }
          return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (_, __) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/owner-pending',
          builder: (_, state) => OwnerPendingScreen(
            email: state.extra is String ? state.extra! as String : null,
          ),
        ),
        GoRoute(
          path: '/auth-loading',
          builder: (_, __) => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(
          path: '/explore',
          builder: (_, state) => ExplorePage(
            initial: {
              'city': state.uri.queryParameters['city'] ?? '',
              'guests': state.uri.queryParameters['guests'] ?? '',
              'category': state.uri.queryParameters['category'] ?? '',
            },
          ),
        ),
        GoRoute(
          path: '/hotels/:id',
          builder: (_, state) =>
              HotelDetailsPage(hotelId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/help',
          builder: (_, __) => const HelpCenterScreen(),
        ),
        GoRoute(
          path: '/book/:id',
          builder: (_, state) =>
              BookingPage(hotelId: state.pathParameters['id']!),
        ),
        GoRoute(
            path: '/dashboard', builder: (_, __) => const TravelerDashboard()),
        GoRoute(path: '/user', builder: (_, __) => const UserPage()),
        GoRoute(path: '/owner', builder: (_, __) => const OwnerDashboard()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
        GoRoute(
          path: '/login',
          builder: (_, state) => LoginPage(
            redirectTo: state.uri.queryParameters['from'],
            registrationCompleted:
                state.uri.queryParameters['registered'] == '1',
          ),
        ),
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      ],
    );
