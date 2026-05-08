import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../client/data/models/case_model.dart';
import '../providers/lawyer_cases_provider.dart';

class LawyerCasesScreen extends ConsumerStatefulWidget {
  const LawyerCasesScreen({super.key});

  @override
  ConsumerState<LawyerCasesScreen> createState() => _LawyerCasesScreenState();
}

class _LawyerCasesScreenState extends ConsumerState<LawyerCasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // All, Open, In Progress, Restricted
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final casesState = ref.watch(lawyerCasesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1130),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Case Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF0D1130),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: SnapLawColors.lawyerPurple,
              unselectedLabelColor: Colors.white54,
              indicatorColor: SnapLawColors.lawyerPurple,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Open'),
                Tab(text: 'In Progress'),
                Tab(text: 'Restricted'),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => ref.read(lawyerCasesProvider.notifier).refreshCases(),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: casesState.isLoading && casesState.cases.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF)))
          : casesState.errorMessage != null
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline, size: 64, color: SnapLawColors.danger.withOpacity(0.7)),
                  const SizedBox(height: 16),
                  Text(casesState.errorMessage!,
                    style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 15),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(lawyerCasesProvider.notifier).refreshCases(),
                    style: ElevatedButton.styleFrom(backgroundColor: SnapLawColors.lawyerPurple),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ]),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildCasesList(null, casesState.cases),
                  _buildCasesList(CaseStatus.open, casesState.cases),
                  _buildCasesList(CaseStatus.inProgress, casesState.cases),
                  _buildCasesList(CaseStatus.restricted, casesState.cases),
                ],
              ),
      ),
    );
  }

  Widget _buildCasesList(CaseStatus? status, List<CaseModel> allCases) {
    final filtered = status == null
        // "All" tab hides restricted — they appear only in the Restricted tab
        ? allCases.where((c) => c.status != CaseStatus.restricted).toList()
        : allCases.where((c) => c.status == status).toList();

    if (filtered.isEmpty) return _buildEmptyState(status);

    return RefreshIndicator(
      onRefresh: () => ref.read(lawyerCasesProvider.notifier).refreshCases(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _LawyerCaseCard(caseItem: filtered[index]),
      ),
    );
  }

  Widget _buildEmptyState(CaseStatus? status) {
    String message;
    switch (status) {
      case CaseStatus.open: message = 'No open cases'; break;
      case CaseStatus.inProgress: message = 'No cases in progress'; break;
      case CaseStatus.pending: message = 'No pending reviews'; break;
      case CaseStatus.closed: message = 'No closed cases'; break;
      case CaseStatus.restricted: message = 'No restricted cases'; break;
      default: message = 'No cases assigned';
    }
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.folder_open_outlined, size: 64, color: Colors.white24),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Cases assigned to you will appear here',
          style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 13)),
      ]),
    );
  }
}

class _LawyerCaseCard extends ConsumerWidget {
  final CaseModel caseItem;
  const _LawyerCaseCard({required this.caseItem});

  Color _getStatusColor() {
    switch (caseItem.status) {
      case CaseStatus.open: return SnapLawColors.clientBlue;
      case CaseStatus.inProgress: return SnapLawColors.warning;
      case CaseStatus.closed: return SnapLawColors.success;
      case CaseStatus.pending: return const Color(0xFF7B61FF);
      case CaseStatus.restricted: return Colors.red;
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Case', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${caseItem.title}"? This cannot be undone.',
            style: TextStyle(color: Colors.white.withOpacity(0.75))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.55)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await ref.read(lawyerCasesProvider.notifier).deleteCase(caseItem.id);
    if (context.mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete case'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(width: 3, decoration: BoxDecoration(color: statusColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)))),
                Expanded(child: InkWell(
              onTap: caseItem.status == CaseStatus.restricted
                  ? null
                  : () => context.push('/lawyer/case-detail', extra: caseItem),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (caseItem.status == CaseStatus.restricted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.40)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.block, size: 14, color: Colors.red),
                        const SizedBox(width: 6),
                        const Expanded(child: Text(
                          'Due to violation, this case has been restricted by admin.',
                          style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                        )),
                      ]),
                    ),
                  ],
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(caseItem.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Client: ${caseItem.clientId}',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.50))),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.40)),
                      ),
                      child: Text(caseItem.statusDisplayName,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(caseItem.description,
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.60), height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: SnapLawColors.lawyerPurple.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: SnapLawColors.lawyerPurple.withOpacity(0.30)),
                      ),
                      child: Text(caseItem.typeDisplayName,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: SnapLawColors.lawyerPurple)),
                    ),
                    if (caseItem.isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: SnapLawColors.danger.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.priority_high, size: 11, color: SnapLawColors.danger),
                          const SizedBox(width: 2),
                          Text('Urgent', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SnapLawColors.danger)),
                        ]),
                      ),
                    ],
                    const Spacer(),
                    _ActionBtn(icon: Icons.visibility_outlined, label: 'View', color: SnapLawColors.lawyerPurple,
                      onTap: () => context.push('/lawyer/case-detail', extra: caseItem)),
                    const SizedBox(width: 4),
                    _ActionBtn(icon: Icons.chat_outlined, label: 'Message', color: SnapLawColors.clientBlue,
                      onTap: () => context.push('/lawyer/message-client/${caseItem.clientId}', extra: caseItem)),
                    const SizedBox(width: 4),
                    _ActionBtn(icon: Icons.delete_outline, label: 'Delete', color: SnapLawColors.danger,
                      onTap: () => _confirmDelete(context, ref)),
                  ]),
                ]),
              ),
            ),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
