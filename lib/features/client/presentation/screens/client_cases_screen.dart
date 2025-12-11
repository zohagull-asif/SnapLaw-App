import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_styles.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
      appBar: AppBar(
        title: const Text(AppStrings.myCases),
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
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(casesProvider.notifier).refreshCases(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCasesList(null, cases, casesState.isLoading),
            _buildCasesList(CaseStatus.open, cases, casesState.isLoading),
            _buildCasesList(CaseStatus.inProgress, cases, casesState.isLoading),
            _buildCasesList(CaseStatus.closed, cases, casesState.isLoading),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/client/cases/select-lawyer'),
        icon: const Icon(Icons.add),
        label: const Text('New Case'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCasesList(CaseStatus? status, List<CaseModel> cases, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredCases = status == null
        ? cases
        : cases.where((c) => c.status == status).toList();

    if (filteredCases.isEmpty) {
      return _buildEmptyState(status);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCases.length,
      itemBuilder: (context, index) {
        final caseItem = filteredCases[index];
        return _CaseCard(caseItem: caseItem);
      },
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
      case CaseStatus.closed:
        message = 'No closed cases';
        break;
      default:
        message = 'No cases yet';
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
            'Tap the + button to create a new case',
            style: AppStyles.bodyText2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final CaseModel caseItem;

  const _CaseCard({required this.caseItem});

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
                    child: Text(
                      caseItem.title,
                      style: AppStyles.subtitle1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textSecondary,
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
