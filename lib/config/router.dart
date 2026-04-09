import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/client/presentation/screens/client_dashboard_screen.dart';
import '../features/client/presentation/screens/client_cases_screen.dart';
import '../features/client/presentation/screens/find_lawyers_screen.dart';
import '../features/client/presentation/screens/create_case_screen.dart';
import '../features/client/presentation/screens/select_lawyer_screen.dart';
import '../features/client/presentation/screens/client_appointments_screen.dart';
import '../features/client/presentation/screens/contract_risk_radar_screen.dart';
import '../features/client/presentation/screens/policy_upload_screen.dart';
import '../features/client/presentation/screens/case_progress_tracker_screen.dart';
import '../features/client/presentation/screens/lawyer_booking_screen.dart';
import '../features/client/presentation/screens/messages_inbox_screen.dart';
import '../features/client/presentation/screens/evidence_scanner_screen.dart';
import '../features/client/presentation/screens/privacy_vault_screen.dart';
import '../features/client/presentation/screens/rate_lawyer_screen.dart';
import '../features/client/presentation/screens/lawyer_profile_screen.dart';
import '../features/client/presentation/screens/client_chat_screen.dart';
import '../features/client/presentation/providers/lawyers_provider.dart';
import '../features/client/data/models/case_model.dart';
import '../features/lawyer/presentation/screens/lawyer_dashboard_screen.dart';
import '../features/lawyer/presentation/screens/lawyer_cases_screen.dart';
import '../features/lawyer/presentation/screens/lawyer_appointments_screen.dart';
import '../features/lawyer/presentation/screens/legal_precedent_finder_screen.dart';
import '../features/lawyer/presentation/screens/case_detail_screen.dart';
import '../features/lawyer/presentation/screens/message_client_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/user_management_screen.dart';
import '../features/admin/presentation/screens/lawyer_verification_screen.dart';
import '../features/lawbot/presentation/screens/lawbot_hub_screen.dart';
import '../features/lawbot/presentation/screens/legal_qa_screen.dart';
import '../features/lawbot/presentation/screens/simplifier_screen.dart';
import '../features/lawbot/presentation/screens/bias_checker_screen.dart';
import '../features/lawbot/presentation/screens/safespace_screen.dart';
import '../features/shared/presentation/screens/profile_screen.dart';
import '../features/shared/presentation/screens/notifications_screen.dart';
import '../features/shared/presentation/screens/settings_screen.dart';
import '../features/shared/presentation/screens/splash_screen.dart';
import '../features/shared/presentation/screens/portal_selection_screen.dart';
import '../features/citizen/presentation/screens/citizen_portal_screen.dart';
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
          state.matchedLocation == '/verify-otp' ||
          state.matchedLocation == '/portal-select' ||
          state.matchedLocation == '/citizen' ||
          state.matchedLocation == '/' ||
          state.matchedLocation.startsWith('/citizen');

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

      // Portal Selection (no login required)
      GoRoute(
        path: '/portal-select',
        builder: (context, state) => const PortalSelectionScreen(),
      ),

      // Citizen Portal (no login required)
      GoRoute(
        path: '/citizen',
        builder: (context, state) => const CitizenPortalScreen(),
      ),
      GoRoute(
        path: '/citizen/lawbot',
        builder: (context, state) => const CitizenPortalScreen(initialTab: 4),
      ),
      GoRoute(
        path: '/citizen/safespeak',
        builder: (context, state) => const CitizenPortalScreen(initialTab: 5),
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
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => const OtpVerificationScreen(),
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
          GoRoute(
            path: 'appointments',
            builder: (context, state) => const ClientAppointmentsScreen(),
          ),
          GoRoute(
            path: 'contract-risk-radar',
            builder: (context, state) => const ContractRiskRadarScreen(),
          ),
          GoRoute(
            path: 'evidence-scanner',
            builder: (context, state) => const EvidenceScannerScreen(),
          ),
          GoRoute(
            path: 'privacy-vault',
            builder: (context, state) => const PrivacyVaultScreen(),
          ),
          GoRoute(
            path: 'rate-lawyer/:lawyerId',
            builder: (context, state) {
              final lawyerId = state.pathParameters['lawyerId']!;
              final lawyerName = state.uri.queryParameters['name'] ?? 'Lawyer';
              final caseId = state.uri.queryParameters['caseId'];
              final caseTitle = state.uri.queryParameters['caseTitle'];
              return RateLawyerScreen(
                lawyerId: lawyerId,
                lawyerName: lawyerName,
                caseId: caseId,
                caseTitle: caseTitle,
              );
            },
          ),
          GoRoute(
            path: 'lawyer-profile/:lawyerId',
            builder: (context, state) {
              final lawyerId = state.pathParameters['lawyerId']!;
              final lawyerName = state.uri.queryParameters['name'] ?? 'Lawyer';
              return LawyerProfileScreen(lawyerId: lawyerId, lawyerName: lawyerName);
            },
          ),
          GoRoute(
            path: 'policies',
            builder: (context, state) => const PolicyUploadScreen(),
          ),
          GoRoute(
            path: 'case-progress/:caseId',
            builder: (context, state) {
              final caseId = state.pathParameters['caseId']!;
              final caseTitle = state.uri.queryParameters['title'] ?? 'Case Details';
              return CaseProgressTrackerScreen(
                caseId: caseId,
                caseTitle: caseTitle,
              );
            },
          ),
          GoRoute(
            path: 'book-lawyer/:lawyerId',
            builder: (context, state) {
              final lawyerId = state.pathParameters['lawyerId']!;
              final lawyerName = state.uri.queryParameters['name'] ?? 'Lawyer';
              return LawyerBookingScreen(
                lawyerId: lawyerId,
                lawyerName: lawyerName,
              );
            },
          ),
          GoRoute(
            path: 'messages',
            builder: (context, state) => const MessagesInboxScreen(),
          ),
          GoRoute(
            path: 'messages/:caseId',
            builder: (context, state) {
              final caseId = state.pathParameters['caseId']!;
              return ClientChatScreen(caseId: caseId);
            },
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
          GoRoute(
            path: 'precedent-finder',
            builder: (context, state) => const LegalPrecedentFinderScreen(),
          ),
          GoRoute(
            path: 'clients',
            builder: (context, state) => const LawyerCasesScreen(), // Placeholder
          ),
          GoRoute(
            path: 'documents',
            builder: (context, state) => const LawyerCasesScreen(), // Placeholder
          ),
          GoRoute(
            path: 'tasks',
            builder: (context, state) => const LawyerCasesScreen(), // Placeholder
          ),
          GoRoute(
            path: 'case-detail',
            builder: (context, state) {
              final caseModel = state.extra as CaseModel;
              return CaseDetailScreen(caseModel: caseModel);
            },
          ),
          GoRoute(
            path: 'message-client/:clientId',
            builder: (context, state) {
              final clientId = state.pathParameters['clientId']!;
              final caseModel = state.extra as CaseModel?;
              return MessageClientScreen(clientId: clientId, caseModel: caseModel);
            },
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
        builder: (context, state) => const LawBotHubScreen(),
        routes: [
          GoRoute(
            path: 'qa',
            builder: (context, state) => const LegalQAScreen(),
          ),
          GoRoute(
            path: 'simplify',
            builder: (context, state) => const SimplifierScreen(),
          ),
          GoRoute(
            path: 'bias',
            builder: (context, state) => const BiasCheckerScreen(),
          ),
          GoRoute(
            path: 'safespace',
            builder: (context, state) => const SafeSpaceScreen(),
          ),
        ],
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
