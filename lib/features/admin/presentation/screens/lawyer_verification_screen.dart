import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class _LawyerRecord {
  final String profileId;   // lawyer_profiles.id
  final String userId;      // lawyer_profiles.user_id
  final String name;
  final String email;
  final String? barNumber;
  final String? specialization;
  final int yearsOfExperience;
  final String? officeAddress;
  final bool isVerified;
  final bool isRejected;
  final DateTime appliedOn;

  _LawyerRecord({
    required this.profileId,
    required this.userId,
    required this.name,
    required this.email,
    this.barNumber,
    this.specialization,
    this.yearsOfExperience = 0,
    this.officeAddress,
    required this.isVerified,
    required this.isRejected,
    required this.appliedOn,
  });

  factory _LawyerRecord.fromRow(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    return _LawyerRecord(
      profileId: row['id'] as String,
      userId: row['user_id'] as String,
      name: profile?['full_name'] as String? ?? 'Unknown',
      email: profile?['email'] as String? ?? '',
      barNumber: row['bar_number'] as String?,
      specialization: row['specialization'] as String?,
      yearsOfExperience: row['years_of_experience'] as int? ?? 0,
      officeAddress: row['office_address'] as String?,
      isVerified: row['is_verified'] as bool? ?? false,
      isRejected: (row['is_rejected'] ?? false) as bool,
      appliedOn: DateTime.parse(row['created_at'] as String),
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

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

  List<_LawyerRecord> _pending = [];
  List<_LawyerRecord> _verified = [];
  List<_LawyerRecord> _rejected = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLawyers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLawyers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final db = Supabase.instance.client;

      // Fetch lawyer_profiles
      final lawyerRows = await db
          .from('lawyer_profiles')
          .select()
          .order('created_at', ascending: false);

      if ((lawyerRows as List).isEmpty) {
        setState(() { _pending = []; _verified = []; _rejected = []; _loading = false; });
        return;
      }

      // Fetch matching profiles separately (no FK needed)
      final userIds = lawyerRows.map((r) => r['user_id'] as String).toList();
      final profileRows = await db
          .from('profiles')
          .select('id, full_name, email')
          .inFilter('id', userIds);

      final profileMap = <String, Map<String, dynamic>>{
        for (final p in (profileRows as List))
          (p as Map<String, dynamic>)['id'] as String: p,
      };

      final all = lawyerRows.map((r) {
        final row = r as Map<String, dynamic>;
        return _LawyerRecord.fromRow({
          ...row,
          'profiles': profileMap[row['user_id'] as String],
        });
      }).toList();

      setState(() {
        _pending  = all.where((l) => !l.isVerified && !l.isRejected).toList();
        _verified = all.where((l) =>  l.isVerified).toList();
        _rejected = all.where((l) =>  l.isRejected && !l.isVerified).toList();
        _loading  = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _approveLawyer(_LawyerRecord lawyer) async {
    try {
      final db = Supabase.instance.client;
      // Update lawyer_profiles — set verified true
      final updateData = <String, dynamic>{'is_verified': true};
      try { updateData['is_rejected'] = false; } catch (_) {}
      await db.from('lawyer_profiles').update(updateData).eq('id', lawyer.profileId);
      // Update profiles so lawyer passes the login check
      await db.from('profiles').update({'is_verified': true}).eq('id', lawyer.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${lawyer.name} has been approved.'),
          backgroundColor: AppColors.success));
      _tabController.animateTo(1); // switch to Verified tab
      await _loadLawyers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _rejectLawyer(_LawyerRecord lawyer, String reason) async {
    try {
      final db = Supabase.instance.client;
      final updateData = <String, dynamic>{'is_verified': false};
      try { updateData['is_rejected'] = true; } catch (_) {}
      if (reason.isNotEmpty) {
        try { updateData['rejection_reason'] = reason; } catch (_) {}
      }
      await db.from('lawyer_profiles').update(updateData).eq('id', lawyer.profileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${lawyer.name} application rejected.'),
          backgroundColor: AppColors.error));
      _tabController.animateTo(2); // switch to Rejected tab
      await _loadLawyers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: SnapLawColors.bgDark,
        title: const Text('Lawyer Verification',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadLawyers,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicatorColor: SnapLawColors.warning,
          tabs: [
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'Verified (${_verified.length})'),
            Tab(text: 'Rejected (${_rejected.length})'),
          ],
        ),
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_pending, isPending: true),
                      _buildList(_verified),
                      _buildList(_rejected, isRejected: true),
                    ],
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(_error ?? 'Unknown error',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadLawyers,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ]),
      ),
    );
  }

  Widget _buildList(List<_LawyerRecord> lawyers,
      {bool isPending = false, bool isRejected = false}) {
    if (lawyers.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            isPending
                ? Icons.pending_actions
                : isRejected
                    ? Icons.cancel_outlined
                    : Icons.verified_user_outlined,
            size: 56,
            color: Colors.white24,
          ),
          const SizedBox(height: 12),
          Text(
            isPending
                ? 'No pending verifications'
                : isRejected
                    ? 'No rejected applications'
                    : 'No verified lawyers',
            style: const TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lawyers.length,
      itemBuilder: (context, index) {
        final lawyer = lawyers[index];
        return _LawyerCard(
          lawyer: lawyer,
          isPending: isPending,
          isRejected: isRejected,
          onVerify: () => _confirmVerify(lawyer),
          onReject: () => _confirmReject(lawyer),
          onViewDetails: () => _showDetails(lawyer),
        );
      },
    );
  }

  void _confirmVerify(_LawyerRecord lawyer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Verify Lawyer', style: TextStyle(color: Colors.white)),
        content: Text(
          'Approve ${lawyer.name}? They will gain full access to the Lawyer Dashboard.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _approveLawyer(lawyer); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _confirmReject(_LawyerRecord lawyer) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Reject Application', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Provide a reason for rejecting ${lawyer.name}:',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Reason for rejection...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF0F1535).withOpacity(0.07),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _rejectLawyer(lawyer, reasonCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showDetails(_LawyerRecord lawyer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1535),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(lawyer.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lawyer.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    Text(lawyer.email,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ])),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lawyer.isVerified
                      ? AppColors.success.withOpacity(0.15)
                      : lawyer.isRejected
                          ? AppColors.error.withOpacity(0.15)
                          : SnapLawColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: lawyer.isVerified
                        ? AppColors.success.withOpacity(0.4)
                        : lawyer.isRejected
                            ? AppColors.error.withOpacity(0.4)
                            : SnapLawColors.warning.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  lawyer.isVerified
                      ? 'Verified'
                      : lawyer.isRejected
                          ? 'Rejected'
                          : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: lawyer.isVerified
                        ? AppColors.success
                        : lawyer.isRejected
                            ? AppColors.error
                            : SnapLawColors.warning,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 12),
            _DetailRow('Bar Number', lawyer.barNumber ?? 'Not provided'),
            _DetailRow('Specialization', lawyer.specialization ?? 'General Practice'),
            _DetailRow('Experience', '${lawyer.yearsOfExperience} years'),
            _DetailRow('Office Address', lawyer.officeAddress ?? 'Not provided'),
            _DetailRow('Applied On', lawyer.appliedOn.toString().split(' ')[0]),
          ]),
        ),
      ),
    );
  }
}

// ─── Lawyer Card ─────────────────────────────────────────────────────────────

class _LawyerCard extends StatelessWidget {
  final _LawyerRecord lawyer;
  final bool isPending;
  final bool isRejected;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  const _LawyerCard({
    required this.lawyer,
    required this.isPending,
    required this.isRejected,
    required this.onVerify,
    required this.onReject,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(lawyer.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lawyer.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(lawyer.specialization ?? 'General Practice',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ])),
            TextButton(
              onPressed: onViewDetails,
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 12)),
              child: const Text('Details'),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.badge_outlined, size: 14, color: Colors.white38),
            const SizedBox(width: 4),
            Text('Bar: ${lawyer.barNumber ?? "N/A"}',
                style: AppStyles.caption),
            const SizedBox(width: 16),
            const Icon(Icons.work_outline, size: 14, color: Colors.white38),
            const SizedBox(width: 4),
            Text('${lawyer.yearsOfExperience} yrs exp.',
                style: AppStyles.caption),
          ]),
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ]),
    );
  }
}
