import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/presentation/providers/reviews_provider.dart';
import '../../../shared/data/models/review_model.dart';
import '../providers/lawyers_provider.dart';

class LawyerProfileScreen extends ConsumerWidget {
  final String lawyerId;
  final String lawyerName;

  const LawyerProfileScreen({
    super.key,
    required this.lawyerId,
    required this.lawyerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(lawyerReviewsProvider(lawyerId));
    final summaryAsync = ref.watch(lawyerRatingSummaryProvider(lawyerId));
    final lawyersState = ref.watch(lawyersProvider);

    // Find this lawyer's full profile
    final lawyer = lawyersState.lawyers.where((l) => l.id == lawyerId).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ─── Hero header ───
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A5F), Color(0xFF2A5298)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          child: Text(
                            lawyerName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(lawyerName,
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              if (lawyer != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  lawyer.specialization ?? 'Lawyer',
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (lawyer.isVerified)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified, color: Colors.white, size: 12),
                                            SizedBox(width: 4),
                                            Text('Verified', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${lawyer.experienceYears} yrs experience',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Rating summary card ───
                  summaryAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const SizedBox(),
                    data: (summary) => _RatingSummaryCard(summary: summary),
                  ),
                  const SizedBox(height: 16),

                  // ─── Stats row ───
                  if (lawyer != null) _buildStatsRow(lawyer),
                  const SizedBox(height: 16),

                  // ─── Bio ───
                  if (lawyer?.bio != null && lawyer!.bio!.isNotEmpty)
                    _buildBioCard(lawyer.bio!),

                  // ─── Book button ───
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Book Consultation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => context.push(
                        '/client/book-lawyer/$lawyerId?name=${Uri.encodeComponent(lawyerName)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Reviews section ───
                  reviewsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Failed to load reviews: $e'),
                    data: (reviews) => _ReviewsSection(reviews: reviews, lawyerId: lawyerId, lawyerName: lawyerName),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(LawyerModel lawyer) {
    return Row(
      children: [
        Expanded(child: _StatChip(icon: Icons.work, label: 'Experience', value: '${lawyer.experienceYears} yrs')),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(icon: Icons.attach_money, label: 'Hourly Rate', value: 'PKR ${lawyer.hourlyRate.toStringAsFixed(0)}')),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(
          icon: lawyer.isAvailable ? Icons.circle : Icons.circle_outlined,
          label: 'Status',
          value: lawyer.isAvailable ? 'Available' : 'Busy',
          valueColor: lawyer.isAvailable ? Colors.green : Colors.orange,
        )),
      ],
    );
  }

  Widget _buildBioCard(String bio) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A5F))),
          const SizedBox(height: 8),
          Text(bio, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

// ── Rating Summary Card ──
class _RatingSummaryCard extends StatelessWidget {
  final LawyerRatingSummary summary;
  const _RatingSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Big rating number
          Column(
            children: [
              Text(
                summary.reviewCount == 0 ? '—' : summary.averageRating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < (summary.averageRating.round()) ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 20,
                )),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.reviewCount} review${summary.reviewCount == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 24),

          // Bar breakdown
          Expanded(
            child: Column(
              children: [
                _RatingBar(stars: 5, percentage: summary.percentage5),
                _RatingBar(stars: 4, percentage: summary.percentage4),
                _RatingBar(stars: 3, percentage: summary.percentage3),
                _RatingBar(stars: 2, percentage: summary.percentage2),
                _RatingBar(stars: 1, percentage: summary.percentage1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final int stars;
  final double percentage;
  const _RatingBar({required this.stars, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 32,
            child: Text('${(percentage * 100).round()}%',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ──
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _StatChip({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor ?? const Color(0xFF1E3A5F))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// ── Reviews Section ──
class _ReviewsSection extends StatelessWidget {
  final List<ReviewModel> reviews;
  final String lawyerId;
  final String lawyerName;

  const _ReviewsSection({required this.reviews, required this.lawyerId, required this.lawyerName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Client Reviews', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
            TextButton.icon(
              icon: const Icon(Icons.rate_review, size: 16),
              label: const Text('Write Review'),
              onPressed: () => context.push(
                '/client/rate-lawyer/$lawyerId?name=${Uri.encodeComponent(lawyerName)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No reviews yet', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                const SizedBox(height: 4),
                Text('Be the first to review this lawyer', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          )
        else
          ...reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  review.displayName.substring(0, 1).toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(review.caseType, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(5, (i) => Icon(
                      i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber, size: 16,
                    )),
                  ),
                  const SizedBox(height: 2),
                  Text(review.timeAgo, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ],
          ),
          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${review.reviewText}"',
                style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
