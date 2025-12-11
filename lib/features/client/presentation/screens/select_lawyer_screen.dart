import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../data/models/case_model.dart';
import '../providers/lawyers_provider.dart';

class SelectLawyerScreen extends ConsumerStatefulWidget {
  const SelectLawyerScreen({super.key});

  @override
  ConsumerState<SelectLawyerScreen> createState() => _SelectLawyerScreenState();
}

class _SelectLawyerScreenState extends ConsumerState<SelectLawyerScreen> {
  final _searchController = TextEditingController();
  CaseType? _selectedSpecialization;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lawyersState = ref.watch(lawyersProvider);
    final lawyers = lawyersState.lawyers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Lawyer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a lawyer to submit your case',
                  style: AppStyles.bodyText2.copyWith(
                    color: AppColors.textLight.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(lawyersProvider.notifier).searchLawyers(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name or specialization...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(lawyersProvider.notifier).loadLawyers();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Specialization Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', _selectedSpecialization == null, () {
                    setState(() => _selectedSpecialization = null);
                    ref.read(lawyersProvider.notifier).loadLawyers();
                  }),
                  const SizedBox(width: 8),
                  ...CaseType.values.take(5).map((type) {
                    final isSelected = _selectedSpecialization == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        _getSpecializationName(type),
                        isSelected,
                        () {
                          setState(() => _selectedSpecialization = type);
                          ref.read(lawyersProvider.notifier).filterLawyers(
                                specialization: type.name,
                              );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Lawyers List
          Expanded(
            child: lawyersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : lawyers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: lawyers.length,
                        itemBuilder: (context, index) {
                          final lawyer = lawyers[index];
                          return _LawyerSelectionCard(
                            lawyer: lawyer,
                            onSelect: () => _onLawyerSelected(lawyer),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No lawyers found',
            style: AppStyles.subtitle1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: AppStyles.bodyText2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _onLawyerSelected(LawyerModel lawyer) {
    // Navigate to create case screen with selected lawyer
    context.push('/client/cases/create', extra: lawyer);
  }

  String _getSpecializationName(CaseType type) {
    switch (type) {
      case CaseType.criminal:
        return 'Criminal';
      case CaseType.civil:
        return 'Civil';
      case CaseType.family:
        return 'Family';
      case CaseType.corporate:
        return 'Corporate';
      case CaseType.immigration:
        return 'Immigration';
      case CaseType.realEstate:
        return 'Real Estate';
      case CaseType.intellectualProperty:
        return 'IP';
      case CaseType.labor:
        return 'Labor';
      case CaseType.tax:
        return 'Tax';
      case CaseType.other:
        return 'Other';
    }
  }
}

class _LawyerSelectionCard extends StatelessWidget {
  final LawyerModel lawyer;
  final VoidCallback onSelect;

  const _LawyerSelectionCard({
    required this.lawyer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: lawyer.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          lawyer.avatarUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 32,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lawyer.name,
                            style: AppStyles.subtitle1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lawyer.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lawyer.specialization ?? 'General Practice',
                      style: AppStyles.bodyText2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Rating
                        Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lawyer.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Experience
                        Icon(
                          Icons.work_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lawyer.experienceYears} yrs',
                          style: AppStyles.caption,
                        ),
                        const Spacer(),

                        // Rate
                        Text(
                          '\$${lawyer.hourlyRate.toStringAsFixed(0)}/hr',
                          style: AppStyles.subtitle2.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Select Arrow
              const SizedBox(width: 8),
              Icon(
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
