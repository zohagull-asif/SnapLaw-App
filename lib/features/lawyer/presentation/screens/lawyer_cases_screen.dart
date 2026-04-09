import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_styles.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
      appBar: AppBar(
        title: const Text(AppStrings.caseManagement),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withOpacity(0.6),
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Open'),
            Tab(text: 'In Progress'),
            Tab(text: 'Closed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(lawyerCasesProvider.notifier).refreshCases();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: casesState.isLoading && casesState.cases.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : casesState.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        casesState.errorMessage!,
                        style: AppStyles.subtitle1.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(lawyerCasesProvider.notifier).refreshCases();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCasesList(null, casesState.cases),
                    _buildCasesList(CaseStatus.open, casesState.cases),
                    _buildCasesList(CaseStatus.inProgress, casesState.cases),
                    _buildCasesList(CaseStatus.closed, casesState.cases),
                  ],
                ),
    );
  }

  Widget _buildCasesList(CaseStatus? status, List<CaseModel> allCases) {
    final filteredCases = status == null
        ? allCases
        : allCases.where((c) => c.status == status).toList();

    if (filteredCases.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(lawyerCasesProvider.notifier).refreshCases(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredCases.length,
        itemBuilder: (context, index) {
          final caseItem = filteredCases[index];
          return _LawyerCaseCard(caseItem: caseItem);
        },
      ),
    );
  }

  Widget _buildEmptyState(CaseStatus? status) {
    String message;
    switch (status) {
      case CaseStatus.open:
        message = 'No open cases';
        break;
      case CaseStatus.inProgress:
        message = 'No cases in progress';
        break;
      case CaseStatus.pending:
        message = 'No pending reviews';
        break;
      case CaseStatus.closed:
        message = 'No closed cases';
        break;
      default:
        message = 'No cases assigned';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppStyles.subtitle1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cases assigned to you will appear here',
            style: AppStyles.bodyText2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LawyerCaseCard extends StatelessWidget {
  final CaseModel caseItem;

  const _LawyerCaseCard({required this.caseItem});

  Color _getStatusColor() {
    switch (caseItem.status) {
      case CaseStatus.open:
        return AppColors.statusOpen;
      case CaseStatus.inProgress:
        return AppColors.statusInProgress;
      case CaseStatus.closed:
        return AppColors.statusClosed;
      case CaseStatus.pending:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to case details
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caseItem.title,
                          style: AppStyles.subtitle1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Client: John Doe', // TODO: Get actual client name
                          style: AppStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      caseItem.statusDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                caseItem.description,
                style: AppStyles.bodyText2.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      caseItem.typeDisplayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (caseItem.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 12,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Urgent',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.visibility_outlined,
                    label: 'View',
                    onTap: () {
                      context.push('/lawyer/case-detail', extra: caseItem);
                    },
                  ),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Update',
                    onTap: () {
                      context.push('/lawyer/case-detail', extra: caseItem);
                    },
                  ),
                  _ActionButton(
                    icon: Icons.chat_outlined,
                    label: 'Message',
                    onTap: () {
                      context.push('/lawyer/message-client/${caseItem.clientId}',
                          extra: caseItem);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
