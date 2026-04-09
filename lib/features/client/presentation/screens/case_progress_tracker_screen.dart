import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_colors.dart';
import '../../data/models/case_update_model.dart';
import '../providers/case_updates_provider.dart';

class CaseProgressTrackerScreen extends ConsumerWidget {
  final String caseId;
  final String caseTitle;

  const CaseProgressTrackerScreen({
    super.key,
    required this.caseId,
    required this.caseTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(caseUpdatesProviderFamily(caseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(caseUpdatesProviderFamily(caseId).notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCaseHeader(state.updates),
          Expanded(
            child: state.isLoading && state.updates.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null && state.updates.isEmpty
                    ? _buildErrorView(context, ref, state.errorMessage!)
                    : state.updates.isEmpty
                        ? _buildEmptyView()
                        : _buildTimelineView(context, state.updates),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseHeader(List<CaseUpdateModel> updates) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caseTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Case ID: ${caseId.length > 8 ? caseId.substring(0, 8) : caseId}...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                Icons.update,
                '${updates.length}',
                'Updates',
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                Icons.calendar_today,
                _getNextHearingText(updates),
                'Next Hearing',
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                Icons.pending_actions,
                _getPendingActionsCount(updates).toString(),
                'Pending',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNextHearingText(List<CaseUpdateModel> updates) {
    final nextHearing = updates
        .where((u) => u.nextHearingDate != null)
        .map((u) => u.nextHearingDate!)
        .where((date) => date.isAfter(DateTime.now()))
        .toList()
      ..sort();

    if (nextHearing.isEmpty) return 'Not Set';
    return DateFormat('MMM dd').format(nextHearing.first);
  }

  int _getPendingActionsCount(List<CaseUpdateModel> updates) {
    return updates.where((u) => u.nextAction != null).length;
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(caseUpdatesProviderFamily(caseId).notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No updates yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your lawyer will post updates here as your case progresses.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView(BuildContext context, List<CaseUpdateModel> updates) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final update = updates[index];
        final isLast = index == updates.length - 1;
        return _buildTimelineItem(context, update, isLast);
      },
    );
  }

  Widget _buildTimelineItem(BuildContext context, CaseUpdateModel update, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getUpdateTypeColor(update.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getUpdateTypeColor(update.type),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getUpdateTypeIcon(update.type),
                  color: _getUpdateTypeColor(update.type),
                  size: 20,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getUpdateTypeColor(update.type),
                          _getUpdateTypeColor(update.type).withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Update content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: _buildUpdateCard(context, update),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(BuildContext context, CaseUpdateModel update) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getUpdateTypeColor(update.type).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  update.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getUpdateTypeColor(update.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  update.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getUpdateTypeColor(update.type),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            update.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (update.lawyerName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  update.lawyerName!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (update.nextHearingDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hearing: ${DateFormat('EEEE, MMM dd, yyyy').format(update.nextHearingDate!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (update.nextAction != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.task_alt,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      update.nextAction!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (update.attachments != null && update.attachments!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: update.attachments!
                  .map((attachment) => _buildAttachmentChip(attachment))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            timeago.format(update.timestamp),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentChip(String filename) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.attach_file,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            filename,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUpdateTypeColor(UpdateType type) {
    switch (type) {
      case UpdateType.hearing:
        return Colors.blue;
      case UpdateType.document:
        return Colors.green;
      case UpdateType.evidence:
        return Colors.orange;
      case UpdateType.status:
        return AppColors.primary;
      case UpdateType.deadline:
        return Colors.red;
      case UpdateType.general:
        return Colors.grey;
    }
  }

  IconData _getUpdateTypeIcon(UpdateType type) {
    switch (type) {
      case UpdateType.hearing:
        return Icons.gavel;
      case UpdateType.document:
        return Icons.description;
      case UpdateType.evidence:
        return Icons.folder_open;
      case UpdateType.status:
        return Icons.info;
      case UpdateType.deadline:
        return Icons.alarm;
      case UpdateType.general:
        return Icons.notifications;
    }
  }
}
