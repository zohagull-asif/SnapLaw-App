import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';

class SystemReportsScreen extends StatefulWidget {
  const SystemReportsScreen({super.key});

  @override
  State<SystemReportsScreen> createState() => _SystemReportsScreenState();
}

class _SystemReportsScreenState extends State<SystemReportsScreen> {
  bool _loading = true;

  int _totalCases = 0;
  int _openCases = 0;
  int _inProgressCases = 0;
  int _resolvedCases = 0;
  int _closedCases = 0;
  int _totalClients = 0;
  int _totalLawyers = 0;
  int _verifiedLawyers = 0;
  int _pendingLawyers = 0;

  List<Map<String, dynamic>> _allCases = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final db = Supabase.instance.client;

      final profileRows = await db
          .from('profiles')
          .select('id, full_name, role')
          .neq('role', 'admin');

      final profiles = profileRows as List;
      final nameMap = <String, String>{
        for (final p in profiles)
          p['id'] as String: p['full_name'] as String? ?? 'Unknown',
      };

      _totalClients = profiles.where((p) => p['role'] == 'client').length;
      _totalLawyers = profiles.where((p) => p['role'] == 'lawyer').length;

      final lawyerRows = await db
          .from('lawyer_profiles')
          .select('is_verified');
      _verifiedLawyers =
          (lawyerRows as List).where((l) => l['is_verified'] == true).length;
      _pendingLawyers =
          lawyerRows.where((l) => l['is_verified'] == false).length;

      final caseRows = await db
          .from('cases')
          .select('id, title, status, type, client_id, lawyer_id, created_at, updated_at')
          .order('created_at', ascending: false);

      final cases = caseRows as List;
      _totalCases = cases.length;
      _openCases = cases.where((c) => c['status'] == 'open').length;
      _inProgressCases = cases
          .where((c) =>
              c['status'] == 'in_progress' || c['status'] == 'assigned')
          .length;
      _resolvedCases = cases.where((c) => c['status'] == 'resolved').length;
      _closedCases = cases.where((c) => c['status'] == 'closed').length;

      _allCases = cases.map((c) {
        final cid = c['client_id'] as String? ?? '';
        final lid = c['lawyer_id'] as String? ?? '';
        return {
          ...Map<String, dynamic>.from(c as Map),
          'client_name': nameMap[cid] ?? 'Unknown',
          'lawyer_name': lid.isEmpty ? 'Unassigned' : nameMap[lid] ?? 'Unknown',
        };
      }).toList();

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: SnapLawColors.bgDark,
        title: const Text('System Reports',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadReports,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Users section
                      Text('Users', style: AppStyles.heading3),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _MiniStat(
                                label: 'Clients',
                                value: '$_totalClients',
                                color: AppColors.info,
                                icon: Icons.person_outline)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _MiniStat(
                                label: 'Lawyers',
                                value: '$_totalLawyers',
                                color: AppColors.secondary,
                                icon: Icons.gavel)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _MiniStat(
                                label: 'Verified',
                                value: '$_verifiedLawyers',
                                color: AppColors.success,
                                icon: Icons.verified_user_outlined)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _MiniStat(
                                label: 'Pending',
                                value: '$_pendingLawyers',
                                color: AppColors.warning,
                                icon: Icons.pending_actions)),
                      ]),
                      const SizedBox(height: 24),

                      // Cases section
                      Text('Cases Overview', style: AppStyles.heading3),
                      const SizedBox(height: 12),
                      _CaseStatusBar(
                        total: _totalCases,
                        open: _openCases,
                        inProgress: _inProgressCases,
                        resolved: _resolvedCases,
                        closed: _closedCases,
                      ),
                      const SizedBox(height: 24),

                      // All cases list
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('All Cases (${_allCases.length})',
                              style: AppStyles.heading3),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _allCases.isEmpty
                          ? _buildEmpty()
                          : Column(
                              children: _allCases
                                  .map((c) => _CaseRow(caseData: c, onRefresh: _loadReports))
                                  .toList()),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open,
                size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('No cases yet',
                style:
                    AppStyles.subtitle1.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style:
                  AppStyles.heading3.copyWith(color: color, fontSize: 22)),
          Text(label, style: AppStyles.caption),
        ]),
      ]),
    );
  }
}

class _CaseStatusBar extends StatelessWidget {
  final int total, open, inProgress, resolved, closed;

  const _CaseStatusBar({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.resolved,
    required this.closed,
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
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total Cases',
                style: AppStyles.subtitle1),
            Text('$total',
                style: AppStyles.heading3.copyWith(color: AppColors.primary)),
          ]),
          const SizedBox(height: 14),
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(children: [
                  if (open > 0)
                    Flexible(
                        flex: open,
                        child: Container(color: AppColors.warning)),
                  if (inProgress > 0)
                    Flexible(
                        flex: inProgress,
                        child: Container(color: AppColors.primary)),
                  if (resolved > 0)
                    Flexible(
                        flex: resolved,
                        child: Container(color: AppColors.success)),
                  if (closed > 0)
                    Flexible(
                        flex: closed,
                        child:
                            Container(color: AppColors.textSecondary)),
                  // fill remainder if all zero
                  if (open == 0 && inProgress == 0 && resolved == 0 && closed == 0)
                    Flexible(flex: 1, child: Container(color: AppColors.border)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              _Legend('Open', AppColors.warning, open),
              const SizedBox(width: 12),
              _Legend('In Progress', AppColors.primary, inProgress),
              const SizedBox(width: 12),
              _Legend('Resolved', AppColors.success, resolved),
              const SizedBox(width: 12),
              _Legend('Closed', AppColors.textSecondary, closed),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _Legend(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$label ($count)',
          style: AppStyles.caption
              .copyWith(color: AppColors.textSecondary, fontSize: 10)),
    ]);
  }
}

class _CaseRow extends StatelessWidget {
  final Map<String, dynamic> caseData;
  final VoidCallback onRefresh;
  const _CaseRow({required this.caseData, required this.onRefresh});

  Color _statusColor(String s) {
    switch (s) {
      case 'open': return AppColors.warning;
      case 'assigned': return AppColors.info;
      case 'in_progress': return AppColors.primary;
      case 'resolved': return AppColors.success;
      case 'closed': return AppColors.textSecondary;
      case 'stopped': return Colors.red;
      case 'restricted': return Colors.red;
      default: return AppColors.textSecondary;
    }
  }

  String _timeAgo(String dt) {
    final diff = DateTime.now().difference(DateTime.parse(dt));
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showCaseDetail(BuildContext context) {
    final status = caseData['status'] as String? ?? 'open';
    final isStopped = status == 'stopped' || status == 'restricted';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1535),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.folder_open, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(
              caseData['title'] as String? ?? 'Untitled',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            )),
          ]),
          const SizedBox(height: 16),
          _DetailRow(label: 'Client', value: caseData['client_name'] as String? ?? 'Unknown'),
          _DetailRow(label: 'Lawyer', value: caseData['lawyer_name'] as String? ?? 'Unassigned'),
          _DetailRow(label: 'Type', value: (caseData['type'] as String? ?? 'other').replaceAll('_', ' ')),
          _DetailRow(label: 'Status', value: status.replaceAll('_', ' ').toUpperCase()),
          _DetailRow(label: 'Created', value: _timeAgo(caseData['created_at'] as String)),
          const SizedBox(height: 20),
          const Text('Admin Actions', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final newStatus = isStopped ? 'open' : 'restricted';
                  try {
                    await Supabase.instance.client
                        .from('cases')
                        .update({
                          'status': newStatus,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', caseData['id'] as String);
                    onRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isStopped ? 'Case reopened.' : 'Case restricted by admin.'),
                      backgroundColor: isStopped ? AppColors.success : Colors.red.shade700,
                    ));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to update case: $e'),
                      backgroundColor: Colors.red,
                    ));
                  }
                },
                icon: Icon(isStopped ? Icons.restart_alt : Icons.block, size: 16),
                label: Text(isStopped ? 'Reopen Case' : 'Restrict Case'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isStopped ? AppColors.success : Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Dismiss'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = caseData['status'] as String? ?? 'open';
    final sc = _statusColor(status);
    return GestureDetector(
      onTap: () => _showCaseDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                caseData['title'] as String? ?? 'Untitled',
                style: AppStyles.subtitle1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sc.withOpacity(0.3)),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sc),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(caseData['client_name'] as String? ?? '',
                style: AppStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            const Icon(Icons.gavel, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(caseData['lawyer_name'] as String? ?? '',
                  style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Text(_timeAgo(caseData['created_at'] as String),
                style: AppStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary.withOpacity(0.5)),
          ]),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13))),
      ]),
    );
  }
}
