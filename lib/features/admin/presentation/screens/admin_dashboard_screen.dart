import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';

// ─── Stats model ─────────────────────────────────────────────────────────────

class _DashboardStats {
  final int totalUsers;
  final int lawyers;
  final int clients;
  final int activeCases;
  final int pendingVerifications;
  final List<_RecentCase> recentCases;

  const _DashboardStats({
    this.totalUsers = 0,
    this.lawyers = 0,
    this.clients = 0,
    this.activeCases = 0,
    this.pendingVerifications = 0,
    this.recentCases = const [],
  });
}

class _RecentCase {
  final String id;
  final String title;
  final String status;
  final String type;
  final String clientName;
  final String lawyerName;
  final DateTime createdAt;

  const _RecentCase({
    required this.id,
    required this.title,
    required this.status,
    required this.type,
    required this.clientName,
    required this.lawyerName,
    required this.createdAt,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;
  _DashboardStats _stats = const _DashboardStats();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final db = Supabase.instance.client;

      // Fetch all non-admin profiles
      final profileRows = await db
          .from('profiles')
          .select('id, full_name, role')
          .neq('role', 'admin');

      final profiles = profileRows as List;
      final totalUsers = profiles.length;
      final lawyers = profiles.where((p) => p['role'] == 'lawyer').length;
      final clients = profiles.where((p) => p['role'] == 'client').length;

      // Build a name map for quick lookup
      final nameMap = <String, String>{
        for (final p in profiles)
          p['id'] as String: p['full_name'] as String? ?? 'Unknown',
      };

      // Active cases
      final caseRows = await db
          .from('cases')
          .select('id, title, status, type, client_id, lawyer_id, created_at')
          .order('created_at', ascending: false)
          .limit(20);

      final allCases = caseRows as List;
      final activeCases = allCases
          .where((c) =>
              c['status'] == 'open' ||
              c['status'] == 'assigned' ||
              c['status'] == 'in_progress')
          .length;

      // Pending lawyer verifications
      final pendingRows = await db
          .from('lawyer_profiles')
          .select('id')
          .eq('is_verified', false);
      final pendingVerifications = (pendingRows as List).length;

      // Build recent cases (latest 10)
      final recentCases = allCases.take(10).map((c) {
        final cid = c['client_id'] as String? ?? '';
        final lid = c['lawyer_id'] as String? ?? '';
        return _RecentCase(
          id: c['id'] as String,
          title: c['title'] as String? ?? 'Untitled',
          status: c['status'] as String? ?? 'open',
          type: c['type'] as String? ?? 'other',
          clientName: nameMap[cid] ?? 'Unknown Client',
          lawyerName: lid.isEmpty ? 'Unassigned' : nameMap[lid] ?? 'Unknown Lawyer',
          createdAt: DateTime.parse(c['created_at'] as String),
        );
      }).toList();

      setState(() {
        _stats = _DashboardStats(
          totalUsers: totalUsers,
          lawyers: lawyers,
          clients: clients,
          activeCases: activeCases,
          pendingVerifications: pendingVerifications,
          recentCases: recentCases,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user != null && user.role != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        backgroundColor: Color(0xFF0D1130),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        title: const Text('Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Refresh',
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sign Out',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome,',
                                    style: AppStyles.bodyText1.copyWith(
                                      color: AppColors.textLight.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.fullName ?? 'Admin',
                                    style: AppStyles.heading2.copyWith(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'System Administrator',
                                    style: AppStyles.bodyText2.copyWith(
                                      color: AppColors.textLight.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Platform Stats
                      Text('Platform Overview', style: AppStyles.heading3),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Users',
                              value: '${_stats.totalUsers}',
                              icon: Icons.people_outline,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Lawyers',
                              value: '${_stats.lawyers}',
                              icon: Icons.gavel,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Clients',
                              value: '${_stats.clients}',
                              icon: Icons.person_outline,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Active Cases',
                              value: '${_stats.activeCases}',
                              icon: Icons.folder_outlined,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Management
                      Text('Management', style: AppStyles.heading3),
                      const SizedBox(height: 16),
                      _ManagementCard(
                        title: AppStrings.verifyLawyers,
                        subtitle: _stats.pendingVerifications == 0
                            ? 'No pending verifications'
                            : '${_stats.pendingVerifications} pending verification${_stats.pendingVerifications > 1 ? 's' : ''}',
                        icon: Icons.verified_user_outlined,
                        color: _stats.pendingVerifications > 0
                            ? AppColors.warning
                            : AppColors.success,
                        onTap: () => context.push('/admin/verify-lawyers'),
                        badge: _stats.pendingVerifications > 0
                            ? '${_stats.pendingVerifications}'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _ManagementCard(
                        title: AppStrings.userManagement,
                        subtitle: 'Manage ${_stats.totalUsers} platform users',
                        icon: Icons.people_outline,
                        color: AppColors.primary,
                        onTap: () => context.push('/admin/users'),
                      ),
                      const SizedBox(height: 12),
                      _ManagementCard(
                        title: AppStrings.systemReports,
                        subtitle: '${_stats.activeCases} active cases across the platform',
                        icon: Icons.analytics_outlined,
                        color: AppColors.info,
                        onTap: () => context.push('/admin/reports'),
                      ),
                      const SizedBox(height: 24),

                      // Recent Cases
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Cases', style: AppStyles.heading3),
                          TextButton(
                            onPressed: () => context.push('/admin/reports'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _stats.recentCases.isEmpty
                          ? _buildEmptyCases()
                          : _buildCaseList(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: SnapLawColors.bgDark,
        selectedItemColor: SnapLawColors.accent,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/admin/users');
              break;
            case 2:
              context.push('/admin/verify-lawyers');
              break;
            case 3:
              context.push('/settings');
              break;
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: _stats.pendingVerifications > 0
                ? Badge(
                    label: Text('${_stats.pendingVerifications}'),
                    child: const Icon(Icons.verified_user_outlined),
                  )
                : const Icon(Icons.verified_user_outlined),
            activeIcon: const Icon(Icons.verified_user),
            label: 'Verify',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCases() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open,
              size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('No cases yet',
              style: AppStyles.subtitle1.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Cases submitted by clients will appear here',
              style: AppStyles.bodyText2.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCaseList() {
    return Column(
      children: _stats.recentCases
          .map((c) => _CaseActivityCard(recentCase: c))
          .toList(),
    );
  }
}

// ─── Case Activity Card ───────────────────────────────────────────────────────

class _CaseActivityCard extends StatelessWidget {
  final _RecentCase recentCase;
  const _CaseActivityCard({required this.recentCase});

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return AppColors.warning;
      case 'assigned': return AppColors.info;
      case 'in_progress': return AppColors.primary;
      case 'resolved': return AppColors.success;
      case 'closed': return AppColors.textSecondary;
      default: return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'assigned': return 'Assigned';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(recentCase.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recentCase.title,
                  style: AppStyles.subtitle1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  _statusLabel(recentCase.status),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(recentCase.clientName,
                  style: AppStyles.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              const Icon(Icons.gavel, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(recentCase.lawyerName,
                    style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(_timeAgo(recentCase.createdAt),
                  style: AppStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppStyles.heading2.copyWith(color: color)),
              Text(title, style: AppStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Management Card ──────────────────────────────────────────────────────────

class _ManagementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _ManagementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppStyles.subtitle1),
                    Text(subtitle,
                        style: AppStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
