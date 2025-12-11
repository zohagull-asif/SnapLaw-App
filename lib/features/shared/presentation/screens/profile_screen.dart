import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: Save profile changes
                  setState(() {
                    _isEditing = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: Text(
                'Save',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: user?.avatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(
                                    user!.avatarUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: AppColors.textLight,
                                ),
                                onPressed: () {
                                  // TODO: Pick image
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name
                    if (_isEditing)
                      TextFormField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'Full Name',
                          border: InputBorder.none,
                        ),
                        style: AppStyles.heading3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      )
                    else
                      Text(
                        user?.fullName ?? 'User',
                        style: AppStyles.heading3,
                      ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      user?.email ?? '',
                      style: AppStyles.bodyText2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getRoleLabel(user?.role),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Profile Details
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _ProfileItem(
                      icon: Icons.phone_outlined,
                      label: 'Phone Number',
                      value: user?.phoneNumber ?? 'Not provided',
                      isEditing: _isEditing,
                      controller: _phoneController,
                    ),
                    const Divider(height: 1),
                    _ProfileItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member Since',
                      value: user?.createdAt != null
                          ? '${user!.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                          : 'N/A',
                      isEditing: false,
                    ),
                    const Divider(height: 1),
                    _ProfileItem(
                      icon: Icons.verified_outlined,
                      label: 'Account Status',
                      value: user?.isVerified == true ? 'Verified' : 'Unverified',
                      isEditing: false,
                      valueColor:
                          user?.isVerified == true ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _ActionItem(
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      onTap: () {
                        // TODO: Navigate to change password
                      },
                    ),
                    const Divider(height: 1),
                    _ActionItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => context.push('/settings'),
                    ),
                    const Divider(height: 1),
                    _ActionItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: () {
                        // TODO: Navigate to help
                      },
                    ),
                    const Divider(height: 1),
                    _ActionItem(
                      icon: Icons.logout,
                      label: 'Logout',
                      isDestructive: true,
                      onTap: _handleLogout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // App Version
              Text(
                'SnapLaw v1.0.0',
                style: AppStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleLabel(UserRole? role) {
    switch (role) {
      case UserRole.client:
        return 'Client';
      case UserRole.lawyer:
        return 'Lawyer';
      case UserRole.admin:
        return 'Administrator';
      default:
        return 'User';
    }
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEditing;
  final TextEditingController? controller;
  final Color? valueColor;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isEditing = false,
    this.controller,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                if (isEditing && controller != null)
                  TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    style: AppStyles.bodyText1,
                  )
                else
                  Text(
                    value,
                    style: AppStyles.bodyText1.copyWith(
                      color: valueColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppStyles.bodyText1.copyWith(
                  color: isDestructive ? AppColors.error : null,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
