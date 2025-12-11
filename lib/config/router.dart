import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/client/presentation/screens/client_dashboard_screen.dart';
import '../features/client/presentation/screens/client_cases_screen.dart';
import '../features/client/presentation/screens/find_lawyers_screen.dart';
import '../features/client/presentation/screens/create_case_screen.dart';
import '../features/client/presentation/screens/select_lawyer_screen.dart';
import '../features/client/presentation/providers/lawyers_provider.dart';
import '../features/lawyer/presentation/screens/lawyer_dashboard_screen.dart';
import '../features/lawyer/presentation/screens/lawyer_cases_screen.dart';
import '../features/lawyer/presentation/screens/lawyer_appointments_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/user_management_screen.dart';
import '../features/admin/presentation/screens/lawyer_verification_screen.dart';
import '../features/lawbot/presentation/screens/lawbot_chat_screen.dart';
import '../features/shared/presentation/screens/profile_screen.dart';
import '../features/shared/presentation/screens/notifications_screen.dart';
import '../features/shared/presentation/screens/settings_screen.dart';
import '../features/shared/presentation/screens/splash_screen.dart';
import '../services/supabase_service.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = SupabaseService.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Client routes
      GoRoute(
        path: '/client',
        builder: (context, state) => const ClientDashboardScreen(),
        routes: [
          GoRoute(
            path: 'cases',
            builder: (context, state) => const ClientCasesScreen(),
          ),
          GoRoute(
            path: 'cases/select-lawyer',
            builder: (context, state) => const SelectLawyerScreen(),
          ),
          GoRoute(
            path: 'cases/create',
            builder: (context, state) {
              final lawyer = state.extra as LawyerModel?;
              return CreateCaseScreen(selectedLawyer: lawyer);
            },
          ),
          GoRoute(
            path: 'find-lawyers',
            builder: (context, state) => const FindLawyersScreen(),
          ),
        ],
      ),

      // Lawyer routes
      GoRoute(
        path: '/lawyer',
        builder: (context, state) => const LawyerDashboardScreen(),
        routes: [
          GoRoute(
            path: 'cases',
            builder: (context, state) => const LawyerCasesScreen(),
          ),
          GoRoute(
            path: 'appointments',
            builder: (context, state) => const LawyerAppointmentsScreen(),
          ),
        ],
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: 'verify-lawyers',
            builder: (context, state) => const LawyerVerificationScreen(),
          ),
        ],
      ),

      // LawBot
      GoRoute(
        path: '/lawbot',
        builder: (context, state) => const LawBotChatScreen(),
      ),

      // Shared routes
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
}
