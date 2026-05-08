import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LawyerDashboardScreen extends ConsumerStatefulWidget {
  const LawyerDashboardScreen({super.key});

  @override
  ConsumerState<LawyerDashboardScreen> createState() =>
      _LawyerDashboardScreenState();
}

class _LawyerDashboardScreenState extends ConsumerState<LawyerDashboardScreen> {
  String _selectedMenu = 'Dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onMenuTap(String menuKey) {
    setState(() => _selectedMenu = menuKey);
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
    switch (menuKey) {
      case 'My Cases': context.push('/lawyer/cases'); break;
      case 'Clients': context.push('/lawyer/clients'); break;
      case 'Messages': context.push('/lawyer/messages'); break;
      case 'Precedent Finder': context.push('/lawyer/precedent-finder'); break;
      case 'Calendar': context.push('/lawyer/appointments'); break;
      case 'LawBot AI': context.push('/lawbot/qa'); break;
      case 'Contract Simplifier': context.push('/lawbot/simplify'); break;
      case 'Case Summarizer':
        context.push('/lawyer/case-summarizer');
        break;
      case 'Documents': context.push('/lawyer/documents'); break;
      case 'Tasks': context.push('/lawyer/tasks'); break;
    }
  }

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
          child: _buildSidebar(user?.fullName ?? 'Lawyer'),
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
            _buildSidebar(user?.fullName ?? 'Lawyer'),
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
                child: const Icon(Icons.gavel, color: Colors.white, size: 22),
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

          // Lawyer badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SnapLawColors.lawyerPurple.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SnapLawColors.lawyerPurple.withOpacity(0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_outlined, color: SnapLawColors.lawyerPurple, size: 13),
                const SizedBox(width: 5),
                Text('Lawyer Portal', style: TextStyle(
                  color: SnapLawColors.lawyerPurple, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 8),

          // Menu items — scrollable so they never overflow
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                _DashMenuItem(icon: Icons.dashboard, title: 'Dashboard', menuKey: 'Dashboard', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('Dashboard')),
                _DashMenuItem(icon: Icons.folder_outlined, title: 'My Cases', menuKey: 'My Cases', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('My Cases')),
                _DashMenuItem(icon: Icons.people_outline, title: 'Clients', menuKey: 'Clients', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('Clients')),
                _DashMenuItem(icon: Icons.message_outlined, title: 'Messages', menuKey: 'Messages', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('Messages')),
                _DashMenuItem(icon: Icons.search, title: 'Precedent Finder', menuKey: 'Precedent Finder', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('Precedent Finder')),
                _DashMenuItem(icon: Icons.calendar_today, title: 'Calendar', menuKey: 'Calendar', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('Calendar')),
                _DashMenuItem(icon: Icons.description_outlined, title: 'Documents', menuKey: 'Documents', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('Documents')),
                _DashMenuItem(icon: Icons.task_alt, title: 'Tasks', menuKey: 'Tasks', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('Tasks')),
                _DashMenuItem(icon: Icons.auto_awesome, title: 'Case Summarizer', menuKey: 'Case Summarizer', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('Case Summarizer')),
                _DashMenuItem(icon: Icons.smart_toy_outlined, title: 'LawBot AI', menuKey: 'LawBot AI', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('LawBot AI')),
                _DashMenuItem(icon: Icons.article_outlined, title: 'Contract Simplifier', menuKey: 'Contract Simplifier', selectedMenu: _selectedMenu, accentColor: SnapLawColors.lawyerPurple, onTap: () => _onMenuTap('Contract Simplifier')),
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
                backgroundColor: SnapLawColors.lawyerPurple.withOpacity(0.30),
                child: Text(userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text('Lawyer', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
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

  Widget _buildTopBar(user, {GlobalKey<ScaffoldState>? scaffoldKey}) {
    return GlassTopBar(
      title: 'Lawyer Dashboard',
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
            child: Text('Welcome back, ${ref.watch(authProvider).user?.fullName ?? 'Counsel'}',
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
          ),
          const SizedBox(height: 4),
          FadeSlideIn(
            delay: const Duration(milliseconds: 150),
            child: const Text('Your Practice Overview',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),

          // Stats row (responsive)
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 700 ? 4 : (w >= 440 ? 2 : 1);
            final cardW = (w - 14.0 * (cols - 1)) / cols;
            return Wrap(spacing: 14, runSpacing: 14, children: [
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 200),
                child: StatCard(title: 'Total Cases', value: '24', icon: Icons.folder,
                  accentColor: SnapLawColors.lawyerPurple, subtitle: '+5 this month', trendIcon: Icons.trending_up))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 320),
                child: StatCard(title: 'Hearings Today', value: '3', icon: Icons.gavel,
                  accentColor: SnapLawColors.warning, subtitle: 'Next: 10:00 AM'))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 440),
                child: StatCard(title: 'Active Clients', value: '18', icon: Icons.people,
                  accentColor: SnapLawColors.clientBlue, subtitle: '3 new this week', trendIcon: Icons.trending_up))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 560),
                child: StatCard(title: 'Won Cases', value: '92%', icon: Icons.emoji_events,
                  accentColor: SnapLawColors.success, subtitle: '23/25 cases won', trendIcon: Icons.star))),
            ]);
          }),
          const SizedBox(height: 32),

          // Charts row (responsive)
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 580;
            final barChart = FadeSlideIn(
              delay: const Duration(milliseconds: 600),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SnapLawColors.lawyerPurple.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.bar_chart, color: SnapLawColors.lawyerPurple, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Case Statistics',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF0F1535),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                            BarTooltipItem('${rod.toY.toInt()}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                            if (value.toInt() < months.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(months[value.toInt()],
                                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
                              );
                            }
                            return const Text('');
                          },
                        )),
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) => Text(value.toInt().toString(),
                            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10)),
                        )),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white.withOpacity(0.07), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _barGroup(0, 6), _barGroup(1, 8), _barGroup(2, 5),
                        _barGroup(3, 9), _barGroup(4, 7), _barGroup(5, 4),
                      ],
                    )),
                  ),
                ]),
              ),
            );
            final pieChart = FadeSlideIn(
              delay: const Duration(milliseconds: 650),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SnapLawColors.lawyerPurple.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.pie_chart, color: SnapLawColors.lawyerPurple, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Case Types',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 160,
                    child: PieChart(PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 44,
                      sections: [
                        PieChartSectionData(color: const Color(0xFF7B61FF), value: 35, title: '35%', radius: 44,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        PieChartSectionData(color: const Color(0xFFF4A324), value: 25, title: '25%', radius: 44,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        PieChartSectionData(color: const Color(0xFF3B82F6), value: 20, title: '20%', radius: 44,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        PieChartSectionData(color: const Color(0xFF10B981), value: 20, title: '20%', radius: 44,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    )),
                  ),
                  const SizedBox(height: 16),
                  _legend('Family Law', '35%', const Color(0xFF7B61FF)),
                  const SizedBox(height: 6),
                  _legend('Criminal', '25%', const Color(0xFFF4A324)),
                  const SizedBox(height: 6),
                  _legend('Corporate', '20%', const Color(0xFF3B82F6)),
                  const SizedBox(height: 6),
                  _legend('Property', '20%', const Color(0xFF10B981)),
                ]),
              ),
            );
            return isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 2, child: barChart),
                  const SizedBox(width: 16),
                  Expanded(child: pieChart),
                ])
              : Column(children: [barChart, const SizedBox(height: 16), pieChart]);
          }),
          const SizedBox(height: 32),

          // Quick Actions
          FadeSlideIn(delay: const Duration(milliseconds: 700),
            child: const Text('Quick Actions',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 700 ? 4 : (w >= 440 ? 2 : 1);
            final cardW = (w - 14.0 * (cols - 1)) / cols;
            return Wrap(spacing: 14, runSpacing: 14, children: [
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 750),
                child: _buildActionCard('Manage Cases',
                  'View and manage all your cases',
                  Icons.folder_open, SnapLawColors.lawyerPurple,
                  () => context.push('/lawyer/cases')))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 820),
                child: _buildActionCard('Precedent Finder',
                  'Search past judgments & legal cases',
                  Icons.search, SnapLawColors.warning,
                  () => context.push('/lawyer/precedent-finder')))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 890),
                child: _buildActionCard('Client Management',
                  'Manage client information and profiles',
                  Icons.people, SnapLawColors.clientBlue,
                  () => context.push('/lawyer/clients')))),
              SizedBox(width: cardW, child: FadeSlideIn(delay: const Duration(milliseconds: 960),
                child: _buildActionCard('Case Summarizer',
                  'AI-powered court judgment summarizer',
                  Icons.auto_awesome, SnapLawColors.success,
                  () => context.push('/lawbot/qa')))),
            ]);
          }),
          const SizedBox(height: 32),

          // Upcoming Hearings
          FadeSlideIn(delay: const Duration(milliseconds: 1000),
            child: const Text('Upcoming Hearings',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
          const SizedBox(height: 14),
          FadeSlideIn(delay: const Duration(milliseconds: 1050),
            child: _buildHearingCard(
              'Property Dispute — Ahmed vs Khan',
              'Tomorrow, 10:00 AM', 'High Court', SnapLawColors.danger)),
          FadeSlideIn(delay: const Duration(milliseconds: 1100),
            child: _buildHearingCard(
              'Divorce Case — Client: Sara Ali',
              'Dec 18, 2:00 PM', 'Family Court', SnapLawColors.warning)),
          FadeSlideIn(delay: const Duration(milliseconds: 1150),
            child: _buildHearingCard(
              'Contract Dispute — Tech Corp',
              'Dec 20, 11:00 AM', 'Civil Court', SnapLawColors.clientBlue)),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(
        toY: y,
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Color(0xFF0D1130), Color(0xFF7B61FF)],
        ),
        width: 28,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6), topRight: Radius.circular(6)),
      )],
    );
  }

  Widget _legend(String label, String value, Color color) {
    return Row(children: [
      Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.70))),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600)),
    ]);
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

  Widget _buildHearingCard(String title, String datetime, String court, Color urgencyColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderColor: urgencyColor.withOpacity(0.35),
        child: Row(children: [
          // Left accent border
          Container(
            width: 4, height: 56,
            decoration: BoxDecoration(
              color: urgencyColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.gavel, color: urgencyColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.access_time, size: 12, color: Colors.white.withOpacity(0.55)),
              const SizedBox(width: 4),
              Text(datetime, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
              const SizedBox(width: 12),
              Icon(Icons.location_on_outlined, size: 12, color: Colors.white.withOpacity(0.55)),
              const SizedBox(width: 4),
              Text(court, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
            ]),
          ])),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withOpacity(0.35)),
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
          Icon(Icons.logout, color: SnapLawColors.lawyerPurple),
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
                backgroundColor: SnapLawColors.lawyerPurple,
                radius: 18,
                child: Text(userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Lawyer', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
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
              backgroundColor: SnapLawColors.lawyerPurple,
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
// Private sidebar menu item (lawyer-specific)
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
