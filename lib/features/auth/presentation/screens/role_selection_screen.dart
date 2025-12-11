import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_styles.dart';
import '../../data/models/user_model.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.balance,
                    size: 48,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to SnapLaw',
                style: AppStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.selectRole,
                style: AppStyles.subtitle2.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Role Cards
              Expanded(
                child: Column(
                  children: [
                    _RoleSelectionCard(
                      role: UserRole.client,
                      title: AppStrings.client,
                      description: 'Find lawyers, manage cases, and get legal assistance',
                      icon: Icons.person_outline,
                      onTap: () => context.go('/client'),
                    ),
                    const SizedBox(height: 16),
                    _RoleSelectionCard(
                      role: UserRole.lawyer,
                      title: AppStrings.lawyer,
                      description: 'Manage clients, cases, and grow your practice',
                      icon: Icons.gavel,
                      onTap: () => context.go('/lawyer'),
                    ),
                    const SizedBox(height: 16),
                    _RoleSelectionCard(
                      role: UserRole.admin,
                      title: AppStrings.admin,
                      description: 'Oversee platform, verify lawyers, and manage users',
                      icon: Icons.admin_panel_settings_outlined,
                      onTap: () => context.go('/admin'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final UserRole role;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.subtitle1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppStyles.bodyText2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
