import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../data/models/case_model.dart';
import '../providers/cases_provider.dart';

class ClientCasesScreen extends ConsumerStatefulWidget {
  const ClientCasesScreen({super.key});

  @override
  ConsumerState<ClientCasesScreen> createState() => _ClientCasesScreenState();
}

class _ClientCasesScreenState extends ConsumerState<ClientCasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final casesState = ref.watch(casesProvider);
    final cases = casesState.cases;

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1130),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Cases',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF0D1130),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: SnapLawColors.clientBlue,
              unselectedLabelColor: Colors.white54,
              indicatorColor: SnapLawColors.clientBlue,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Open'),
                Tab(text: 'In Progress'),
                Tab(text: 'Closed'),
                Tab(text: 'Restricted'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/client/cases/select-lawyer'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Case', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: SnapLawColors.clientBlue,
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: RefreshIndicator(
          onRefresh: () => ref.read(casesProvider.notifier).refreshCases(),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCasesList(null, cases, casesState.isLoading),
              _buildCasesList(CaseStatus.open, cases, casesState.isLoading),
              _buildCasesList(CaseStatus.inProgress, cases, casesState.isLoading),
              _buildCasesList(CaseStatus.closed, cases, casesState.isLoading),
              _buildCasesList(CaseStatus.restricted, cases, casesState.isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCasesList(CaseStatus? status, List<CaseModel> cases, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }

    final filtered = status == null
        // "All" tab hides restricted — they appear only in the Restricted tab
        ? cases.where((c) => c.status != CaseStatus.restricted).toList()
        : cases.where((c) => c.status == status).toList();

    if (filtered.isEmpty) return _buildEmptyState(status);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _CaseCard(caseItem: filtered[index]),
    );
  }

  Widget _buildEmptyState(CaseStatus? status) {
    String message;
    switch (status) {
      case CaseStatus.open: message = 'No open cases'; break;
      case CaseStatus.inProgress: message = 'No cases in progress'; break;
      case CaseStatus.closed: message = 'No closed cases'; break;
      case CaseStatus.restricted: message = 'No restricted cases'; break;
      default: message = 'No cases yet';
    }
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.folder_open_outlined, size: 64, color: Colors.white24),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Tap the + button to create a new case',
          style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 13)),
      ]),
    );
  }
}

class _CaseCard extends ConsumerWidget {
  final CaseModel caseItem;
  const _CaseCard({required this.caseItem});

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
    final success = await ref.read(casesProvider.notifier).deleteCase(caseItem.id);
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
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
            ),
            child: InkWell(
              onTap: caseItem.status == CaseStatus.restricted
                  ? null
                  : () => context.push(
                      '/client/case-progress/${caseItem.id}?title=${Uri.encodeComponent(caseItem.title)}'),
              borderRadius: BorderRadius.circular(14),
              child: IntrinsicHeight(
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(13),
                        bottomLeft: Radius.circular(13),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            Expanded(
                              child: Text(caseItem.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 10),
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
                                color: SnapLawColors.clientBlue.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: SnapLawColors.clientBlue.withOpacity(0.30)),
                              ),
                              child: Text(caseItem.typeDisplayName,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: SnapLawColors.clientBlue)),
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
                            GestureDetector(
                              onTap: () => _confirmDelete(context, ref),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.withOpacity(0.30)),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.delete_outline, size: 13, color: Colors.red.shade400),
                                  const SizedBox(width: 3),
                                  Text('Delete', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red.shade400)),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withOpacity(0.35)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
