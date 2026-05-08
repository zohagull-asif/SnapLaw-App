import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LawyerPendingScreen extends ConsumerWidget {
  const LawyerPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      body: AppBackground(
        overlayOpacity: 0.60,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with glow
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: SnapLawColors.warning.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: SnapLawColors.warning.withOpacity(0.40), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: SnapLawColors.warning.withOpacity(0.25),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.pending_actions,
                      size: 48, color: SnapLawColors.warning),
                ),
                const SizedBox(height: 28),

                // Title
                const Text(
                  'Account Pending Approval',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Hello ${user?.fullName ?? 'Counsel'},\n\nYour lawyer account has been created and is awaiting verification by our admin team. You will be able to access the platform once your credentials have been reviewed and approved.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 14,
                      height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Status pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: SnapLawColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: SnapLawColors.warning.withOpacity(0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: SnapLawColors.warning, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text('Verification In Progress',
                        style: TextStyle(
                            color: SnapLawColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 40),

                // What happens next
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What happens next?',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _Step(
                          number: '1',
                          text: 'Admin reviews your application'),
                      const SizedBox(height: 8),
                      _Step(
                          number: '2',
                          text:
                              'Your credentials are verified'),
                      const SizedBox(height: 8),
                      _Step(
                          number: '3',
                          text:
                              'You receive access to the Lawyer Dashboard'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Logout button
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).signOut();
                    context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: SnapLawColors.lawyerPurple.withOpacity(0.25),
          shape: BoxShape.circle,
          border: Border.all(
              color: SnapLawColors.lawyerPurple.withOpacity(0.50)),
        ),
        child: Center(
          child: Text(number,
              style: const TextStyle(
                  color: SnapLawColors.lawyerPurple,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: TextStyle(
                color: Colors.white.withOpacity(0.65), fontSize: 13)),
      ),
    ]);
  }
}
