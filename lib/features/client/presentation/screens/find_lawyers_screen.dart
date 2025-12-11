import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_styles.dart';
import '../../data/models/case_model.dart';
import '../providers/lawyers_provider.dart';

class FindLawyersScreen extends ConsumerStatefulWidget {
  const FindLawyersScreen({super.key});

  @override
  ConsumerState<FindLawyersScreen> createState() => _FindLawyersScreenState();
}

class _FindLawyersScreenState extends ConsumerState<FindLawyersScreen> {
  final _searchController = TextEditingController();
  CaseType? _selectedSpecialization;
  bool _onlyVerified = false;
  bool _onlyAvailable = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(lawyersProvider.notifier).filterLawyers(
      specialization: _selectedSpecialization?.name,
      onlyVerified: _onlyVerified,
      onlyAvailable: _onlyAvailable,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lawyersState = ref.watch(lawyersProvider);
    final lawyers = lawyersState.lawyers;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.findLawyers),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: TextField(
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
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Available',
                    isSelected: _onlyAvailable,
                    onSelected: (value) {
                      setState(() {
                        _onlyAvailable = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Verified',
                    isSelected: _onlyVerified,
                    onSelected: (value) {
                      setState(() {
                        _onlyVerified = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  if (_selectedSpecialization != null)
                    _FilterChip(
                      label: _getSpecializationName(_selectedSpecialization!),
                      isSelected: true,
                      onSelected: (_) {
                        setState(() {
                          _selectedSpecialization = null;
                        });
                      },
                      showClose: true,
                    ),
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
                          return _LawyerCard(lawyer: lawyer);
                        },
                      ),
          ),
        ],
      ),
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
            'Try adjusting your filters or search terms',
            style: AppStyles.bodyText2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Lawyers',
                        style: AppStyles.heading3,
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedSpecialization = null;
                            _onlyVerified = false;
                            _onlyAvailable = true;
                          });
                          setState(() {});
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Specialization
                  const Text(
                    'Specialization',
                    style: AppStyles.subtitle1,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CaseType.values.map((type) {
                      final isSelected = _selectedSpecialization == type;
                      return FilterChip(
                        label: Text(_getSpecializationName(type)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedSpecialization = selected ? type : null;
                          });
                          setState(() {});
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      style: AppStyles.primaryButtonStyle,
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;
  final bool showClose;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.showClose = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (showClose) ...[
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 16),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final LawyerModel lawyer;

  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to lawyer profile
        },
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
            ],
          ),
        ),
      ),
    );
  }
}
