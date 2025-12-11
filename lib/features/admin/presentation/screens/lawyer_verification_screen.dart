import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_styles.dart';

class LawyerVerificationScreen extends ConsumerStatefulWidget {
  const LawyerVerificationScreen({super.key});

  @override
  ConsumerState<LawyerVerificationScreen> createState() =>
      _LawyerVerificationScreenState();
}

class _LawyerVerificationScreenState
    extends ConsumerState<LawyerVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<_PendingLawyer> _pendingLawyers = [];
  final List<_PendingLawyer> _verifiedLawyers = [];
  final List<_PendingLawyer> _rejectedLawyers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.verifyLawyers),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withOpacity(0.6),
          indicatorColor: AppColors.secondary,
          tabs: [
            Tab(text: 'Pending (${_pendingLawyers.length})'),
            Tab(text: 'Verified (${_verifiedLawyers.length})'),
            Tab(text: 'Rejected (${_rejectedLawyers.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLawyersList(_pendingLawyers, isPending: true),
          _buildLawyersList(_verifiedLawyers),
          _buildLawyersList(_rejectedLawyers, isRejected: true),
        ],
      ),
    );
  }

  Widget _buildLawyersList(
    List<_PendingLawyer> lawyers, {
    bool isPending = false,
    bool isRejected = false,
  }) {
    if (lawyers.isEmpty) {
      return _buildEmptyState(isPending, isRejected);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lawyers.length,
      itemBuilder: (context, index) {
        return _LawyerVerificationCard(
          lawyer: lawyers[index],
          isPending: isPending,
          isRejected: isRejected,
          onVerify: () => _handleVerify(lawyers[index]),
          onReject: () => _handleReject(lawyers[index]),
          onViewDetails: () => _showLawyerDetails(lawyers[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isPending, bool isRejected) {
    String title;
    String subtitle;

    if (isPending) {
      title = 'No pending verifications';
      subtitle = 'All lawyer applications have been processed';
    } else if (isRejected) {
      title = 'No rejected applications';
      subtitle = 'Rejected lawyer applications will appear here';
    } else {
      title = 'No verified lawyers';
      subtitle = 'Approved lawyers will appear here';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending
                ? Icons.pending_actions
                : isRejected
                    ? Icons.cancel_outlined
                    : Icons.verified_user_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppStyles.subtitle1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppStyles.bodyText2.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleVerify(_PendingLawyer lawyer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Lawyer'),
        content: Text(
          'Are you sure you want to verify ${lawyer.name}? They will be able to accept clients after verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement verification logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lawyer verified successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _handleReject(_PendingLawyer lawyer) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide a reason for rejecting ${lawyer.name}:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement rejection logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application rejected'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showLawyerDetails(_PendingLawyer lawyer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lawyer.name,
                            style: AppStyles.heading3,
                          ),
                          Text(
                            lawyer.email,
                            style: AppStyles.bodyText2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Details
                _DetailRow(label: 'Bar Number', value: lawyer.barNumber ?? 'N/A'),
                _DetailRow(
                    label: 'Specialization', value: lawyer.specialization ?? 'N/A'),
                _DetailRow(
                    label: 'Experience',
                    value: '${lawyer.yearsOfExperience} years'),
                _DetailRow(
                    label: 'Office Address', value: lawyer.officeAddress ?? 'N/A'),
                _DetailRow(
                    label: 'Applied On',
                    value: lawyer.appliedOn.toString().split(' ')[0]),

                const SizedBox(height: 24),

                // Documents Section
                Text(
                  'Submitted Documents',
                  style: AppStyles.subtitle1,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _DocumentItem(
                        name: 'Bar Certificate',
                        status: 'Uploaded',
                      ),
                      const Divider(),
                      _DocumentItem(
                        name: 'ID Verification',
                        status: 'Uploaded',
                      ),
                      const Divider(),
                      _DocumentItem(
                        name: 'Professional License',
                        status: 'Pending',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendingLawyer {
  final String id;
  final String name;
  final String email;
  final String? barNumber;
  final String? specialization;
  final int yearsOfExperience;
  final String? officeAddress;
  final DateTime appliedOn;

  _PendingLawyer({
    required this.id,
    required this.name,
    required this.email,
    this.barNumber,
    this.specialization,
    this.yearsOfExperience = 0,
    this.officeAddress,
    required this.appliedOn,
  });
}

class _LawyerVerificationCard extends StatelessWidget {
  final _PendingLawyer lawyer;
  final bool isPending;
  final bool isRejected;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  const _LawyerVerificationCard({
    required this.lawyer,
    required this.isPending,
    required this.isRejected,
    required this.onVerify,
    required this.onReject,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer.name,
                        style: AppStyles.subtitle1,
                      ),
                      Text(
                        lawyer.specialization ?? 'General Practice',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text('View'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Bar: ${lawyer.barNumber ?? "N/A"}',
                  style: AppStyles.caption,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.work_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${lawyer.yearsOfExperience} years exp.',
                  style: AppStyles.caption,
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: const Text('Verify'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyText1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentItem extends StatelessWidget {
  final String name;
  final String status;

  const _DocumentItem({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Uploaded'
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color:
                    status == 'Uploaded' ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
