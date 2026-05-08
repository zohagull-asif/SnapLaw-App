import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/presentation/providers/appointments_provider.dart';

class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ConsumerState<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen> {
  String _selectedMenu = 'Dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF020818),
        drawer: Drawer(
          width: 258,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: _buildSidebar(user?.fullName ?? 'User'),
        ),
        body: AppBackground(
          overlayOpacity: 0.55,
          child: Column(
            children: [
              _buildTopBar(user, scaffoldKey: _scaffoldKey),
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: Row(
          children: [
            _buildSidebar(user?.fullName ?? 'User'),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(user),
                  Expanded(child: _buildMainContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(String userName) {
    return GlassSidebar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: SnapLawGradients.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.balance, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Snap', style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                TextSpan(text: 'Law', style: TextStyle(
                  color: Color(0xFFF4A324), fontSize: 18, fontWeight: FontWeight.w800)),
              ])),
            ]),
          ),
          Divider(color: Colors.white.withOpacity(0.10), height: 1),
          const SizedBox(height: 12),

          // Client badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SnapLawColors.clientBlue.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SnapLawColors.clientBlue.withOpacity(0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_outline, color: SnapLawColors.clientBlue, size: 13),
                const SizedBox(width: 5),
                Text('Client Portal', style: TextStyle(
                  color: SnapLawColors.clientBlue, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 8),

          // Menu items — scrollable so they never overflow
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                _DashMenuItem(icon: Icons.dashboard, title: 'Dashboard', menuKey: 'Dashboard', selectedMenu: _selectedMenu, accentColor: SnapLawColors.clientBlue, onTap: () => _onMenuTap('Dashboard')),
                _DashMenuItem(icon: Icons.folder_outlined, title: 'My Cases', menuKey: 'My Cases', selectedMenu: _selectedMenu, accentColor: SnapLawColors.clientBlue, onTap: () => _onMenuTap('My Cases')),
                _DashMenuItem(icon: Icons.timeline, title: 'Case Progress', menuKey: 'Case Progress', selectedMenu: _selectedMenu, accentColor: SnapLawColors.clientBlue, onTap: () => _onMenuTap('Case Progress')),
                _DashMenuItem(icon: Icons.calendar_today, title: 'Booking & Calendar', menuKey: 'Booking & Calendar', selectedMenu: _selectedMenu, accentColor: SnapLawColors.clientBlue, onTap: () => _onMenuTap('Booking & Calendar')),
                _DashMenuItem(icon: Icons.shield_outlined, title: 'Contract Risk Radar', menuKey: 'Contract Risk Radar', selectedMenu: _selectedMenu, accentColor: SnapLawColors.clientBlue, onTap: () => _onMenuTap('Contract Risk Radar')),
                _DashMenuItem(icon: Icons.search, title: 'Find Lawyers', menuKey: 'Find Lawyers', selectedMenu: _selectedMenu, accentColor: SnapLawColors.clientBlue, onTap: () => _onMenuTap('Find Lawyers')),
                _DashMenuItem(icon: Icons.message, title: 'Messages', menuKey: 'Messages', selectedMenu: _selectedMenu, accentColor: SnapLawColors.clientBlue, onTap: () => _onMenuTap('Messages')),
                _DashMenuItem(icon: Icons.smart_toy_outlined, title: 'LawBot AI', menuKey: 'LawBot AI', selectedMenu: _selectedMenu, accentColor: SnapLawColors.clientBlue, onTap: () => _onMenuTap('LawBot AI')),
                _DashMenuItem(icon: Icons.document_scanner, title: 'Evidence Scanner', menuKey: 'Evidence Scanner', selectedMenu: _selectedMenu, accentColor: SnapLawColors.clientBlue, onTap: () => _onMenuTap('Evidence Scanner')),
                _DashMenuItem(icon: Icons.lock_outline, title: 'Privacy Vault', menuKey: 'Privacy Vault', selectedMenu: _selectedMenu, accentColor: SnapLawColors.clientBlue, onTap: () => _onMenuTap('Privacy Vault')),
              ]),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.10), height: 1),

          // User profile
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: SnapLawColors.clientBlue.withOpacity(0.30),
                child: Text(userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text('Client', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ])),
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white.withOpacity(0.5), size: 18),
                onPressed: () => _showLogoutDialog(context, userName),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _onMenuTap(String menuKey) {
    setState(() => _selectedMenu = menuKey);
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
    switch (menuKey) {
      case 'My Cases': context.push('/client/cases'); break;
      case 'Case Progress': context.push('/client/cases'); break;
      case 'Booking & Calendar': context.push('/client/appointments'); break;
      case 'Contract Risk Radar': context.push('/client/contract-risk-radar'); break;
      case 'Find Lawyers': context.push('/client/find-lawyers'); break;
      case 'Messages': context.push('/client/messages'); break;
      case 'LawBot AI': context.push('/lawbot'); break;
      case 'Evidence Scanner': context.push('/client/evidence-scanner'); break;
      case 'Privacy Vault': context.push('/client/privacy-vault'); break;
    }
  }

  Widget _buildTopBar(user, {GlobalKey<ScaffoldState>? scaffoldKey}) {
    return GlassTopBar(
      title: 'Client Dashboard',
      leading: scaffoldKey != null
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 22),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.white.withOpacity(0.7), size: 20),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.white.withOpacity(0.7), size: 20),
          onPressed: () => context.push('/notifications'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Welcome back 👋',
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          FadeSlideIn(
            delay: const Duration(milliseconds: 150),
            child: const Text('Your Legal Overview',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),

          // Stats row (responsive)
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 700 ? 4 : (w >= 440 ? 2 : 1);
            final cardW = (w - 14.0 * (cols - 1)) / cols;
            final apptState = ref.watch(appointmentsProvider);
            final count = apptState.upcoming.length;
            return Wrap(spacing: 14, runSpacing: 14, children: [
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 200),
                child: StatCard(title: 'Total Cases', value: '10', icon: Icons.folder,
                  accentColor: SnapLawColors.clientBlue, subtitle: '+2 this month', trendIcon: Icons.trending_up))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 320),
                child: StatCard(title: 'Active Cases', value: '7', icon: Icons.pending_actions,
                  accentColor: SnapLawColors.warning, subtitle: '3 need attention'))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 440),
                child: StatCard(title: 'Appointments', value: '$count', icon: Icons.calendar_today,
                  accentColor: SnapLawColors.success,
                  subtitle: count > 0 ? 'Upcoming' : 'None scheduled'))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 560),
                child: StatCard(title: 'Success Rate', value: '85%', icon: Icons.trending_up,
                  accentColor: const Color(0xFF7B61FF), subtitle: '12 cases won', trendIcon: Icons.star))),
            ]);
          }),
          const SizedBox(height: 32),

          // Quick Actions
          FadeSlideIn(delay: const Duration(milliseconds: 600),
            child: const Text('Quick Actions',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 580 ? 3 : (w >= 360 ? 2 : 1);
            final cardW = (w - 14.0 * (cols - 1)) / cols;
            return Wrap(spacing: 14, runSpacing: 14, children: [
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 650),
                child: _buildActionCard('Case Progress Tracker',
                  'Track hearing dates, status updates, and next steps',
                  Icons.timeline, SnapLawColors.clientBlue, () => context.push('/client/cases')))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 750),
                child: _buildActionCard('Book Consultation',
                  'Schedule appointments with lawyers instantly',
                  Icons.calendar_month, SnapLawColors.success, () => context.push('/client/find-lawyers')))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 850),
                child: _buildActionCard('Contract Risk Radar',
                  'AI-powered contract analysis and risk detection',
                  Icons.shield, const Color(0xFF7B61FF), () => context.push('/client/contract-risk-radar')))),
            ]);
          }),
          const SizedBox(height: 32),

          // Recent Activity
          FadeSlideIn(delay: const Duration(milliseconds: 900),
            child: const Text('Recent Activity',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
          const SizedBox(height: 14),
          FadeSlideIn(delay: const Duration(milliseconds: 950),
            child: _buildActivityCard('Case Update',
              'Hearing scheduled for Contract Dispute case',
              '2 hours ago', Icons.event, SnapLawColors.clientBlue)),
          FadeSlideIn(delay: const Duration(milliseconds: 1000),
            child: _buildActivityCard('Document Submitted',
              'Evidence documents uploaded by Adv. Ahmed Khan',
              '5 hours ago', Icons.description, SnapLawColors.success)),
          FadeSlideIn(delay: const Duration(milliseconds: 1050),
            child: _buildActivityCard('Appointment Reminder',
              'Consultation tomorrow at 10:00 AM',
              '1 day ago', Icons.notifications, SnapLawColors.warning)),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String description, IconData icon, Color accentColor, VoidCallback onTap) {
    return _HoverCard(
      onTap: onTap,
      accentColor: accentColor,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderColor: accentColor.withOpacity(0.25),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.25)),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(description, style: TextStyle(
            color: Colors.white.withOpacity(0.60), fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Row(children: [
            Text('Open', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward, size: 14, color: accentColor),
          ]),
        ]),
      ),
    );
  }

  Widget _buildActivityCard(String title, String description, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderColor: color.withOpacity(0.20),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(description, style: TextStyle(
              color: Colors.white.withOpacity(0.60), fontSize: 12)),
          ])),
          Text(time, style: TextStyle(
            color: Colors.white.withOpacity(0.40), fontSize: 11)),
        ]),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D1130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.logout, color: AppColors.primary),
          const SizedBox(width: 12),
          const Text('Logout', style: TextStyle(color: Colors.white)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Are you sure you want to logout?',
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.80))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: SnapLawColors.clientBlue,
                radius: 18,
                child: Text(userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Client', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
              ])),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.55))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authProvider.notifier).signOut();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SnapLawColors.clientBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sidebar menu item helper that accepts selectedMenu
// ─────────────────────────────────────────────
class _DashMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String menuKey;
  final String selectedMenu;
  final VoidCallback onTap;
  final Color accentColor;

  const _DashMenuItem({
    required this.icon,
    required this.title,
    required this.menuKey,
    required this.selectedMenu,
    required this.onTap,
    required this.accentColor,
  });

  @override
  State<_DashMenuItem> createState() => _DashMenuItemState();
}

class _DashMenuItemState extends State<_DashMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedMenu == widget.menuKey;
    final active = isSelected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.accentColor.withOpacity(0.22)
                : (_hovered ? Colors.white.withOpacity(0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: widget.accentColor.withOpacity(0.55), width: 1.5)
                : (_hovered ? Border.all(color: Colors.white.withOpacity(0.10)) : null),
            boxShadow: isSelected ? [BoxShadow(
              color: widget.accentColor.withOpacity(0.15),
              blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Row(children: [
            Icon(widget.icon,
              color: isSelected ? widget.accentColor : Colors.white.withOpacity(active ? 0.80 : 0.50),
              size: 18),
            const SizedBox(width: 11),
            Text(widget.title, style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(active ? 0.85 : 0.58),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hover effect wrapper for action cards
// ─────────────────────────────────────────────
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color accentColor;

  const _HoverCard({required this.child, required this.onTap, required this.accentColor});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: widget.child,
        ),
      ),
    );
  }
}
