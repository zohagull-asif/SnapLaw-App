import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/citizen_data.dart';

class CitizenJusticeScreen extends StatelessWidget {
  const CitizenJusticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final totalPending = kCourtStats.fold(0, (s, c) => s + c.totalPendingCases);
    final totalResolved = kCourtStats.fold(0, (s, c) => s + c.casesResolvedThisMonth);
    final avgDays = (kCourtStats.fold(0, (s, c) => s + c.avgResolutionDays) / kCourtStats.length).round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F1535), Color(0xFF2E5A8F)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pakistan Justice Tracker', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Court backlog & resolution statistics', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Summary stats
        Row(
          children: [
            _StatCard(label: 'Total Pending', value: _fmt(totalPending), color: const Color(0xFFFF4757), icon: Icons.pending_actions),
            const SizedBox(width: 10),
            _StatCard(label: 'Avg Resolution', value: '$avgDays days', color: const Color(0xFFF4A324), icon: Icons.timer_outlined),
            const SizedBox(width: 10),
            _StatCard(label: 'Resolved/Month', value: _fmt(totalResolved), color: const Color(0xFF00C896), icon: Icons.check_circle_outline),
          ],
        ),
        const SizedBox(height: 20),

        Text('Court Statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.90))),
        const SizedBox(height: 12),

        ...kCourtStats.map((c) => _CourtCard(court: c)),
        const SizedBox(height: 20),

        Text('Average Time to Resolve by Case Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.90))),
        const SizedBox(height: 12),

        ...kCaseTypeStats.map((t) => _CaseTypeBar(stat: t)),
        const SizedBox(height: 24),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.30)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.55)), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  final CourtStat court;
  const _CourtCard({required this.court});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(court.statusColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(court.courtType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        Text(court.city, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.40)),
                      ),
                      child: Text(court.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniStat(label: 'Pending', value: _fmt(court.totalPendingCases), color: const Color(0xFFFF4757)),
                    _MiniStat(label: 'Avg Days', value: '${court.avgResolutionDays}d', color: const Color(0xFFF4A324)),
                    _MiniStat(label: 'Resolved/Mo', value: _fmt(court.casesResolvedThisMonth), color: const Color(0xFF00C896)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.50))),
      ],
    ));
  }
}

class _CaseTypeBar extends StatelessWidget {
  final CaseTypeStat stat;
  const _CaseTypeBar({required this.stat});

  @override
  Widget build(BuildContext context) {
    const maxDays = 1000;
    final pct = (stat.avgDaysToResolve / maxDays).clamp(0.0, 1.0);
    final barColor = stat.avgDaysToResolve < 365
        ? const Color(0xFF00C896)
        : stat.avgDaysToResolve < 730
            ? const Color(0xFFF4A324)
            : const Color(0xFFFF4757);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(stat.caseType, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white))),
                    Text('${stat.avgDaysToResolve} days', style: TextStyle(color: barColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: barColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Success rate: ${stat.successRatePercent}%', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.50))),
                    Text('${_fmtK(stat.totalCases2023)} cases (2023)', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.50))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtK(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(0)}K' : n.toString();
}
