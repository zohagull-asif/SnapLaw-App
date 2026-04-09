import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/review_model.dart';
import '../../../../services/supabase_service.dart';

// Reviews for a specific lawyer
final lawyerReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, lawyerId) async {
  final data = await SupabaseService.from('reviews')
      .select()
      .eq('lawyer_id', lawyerId)
      .order('created_at', ascending: false)
      .limit(50);
  return (data as List).map((e) => ReviewModel.fromJson(e)).toList();
});

// Rating summary for a specific lawyer
final lawyerRatingSummaryProvider =
    FutureProvider.family<LawyerRatingSummary, String>((ref, lawyerId) async {
  final data = await SupabaseService.from('reviews')
      .select('rating')
      .eq('lawyer_id', lawyerId);

  final list = data as List;
  if (list.isEmpty) return LawyerRatingSummary.empty(lawyerId);

  final ratings = list.map((e) => e['rating'] as int).toList();
  final avg = ratings.fold(0, (a, b) => a + b) / ratings.length;

  return LawyerRatingSummary(
    lawyerId: lawyerId,
    reviewCount: ratings.length,
    averageRating: double.parse(avg.toStringAsFixed(1)),
    fiveStar: ratings.where((r) => r == 5).length,
    fourStar: ratings.where((r) => r == 4).length,
    threeStar: ratings.where((r) => r == 3).length,
    twoStar: ratings.where((r) => r == 2).length,
    oneStar: ratings.where((r) => r == 1).length,
  );
});

// Check if current client already reviewed this lawyer for a case
final hasReviewedProvider =
    FutureProvider.family<bool, ({String lawyerId, String? caseId})>(
        (ref, args) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return false;

  var query = SupabaseService.from('reviews')
      .select('id')
      .eq('client_id', userId)
      .eq('lawyer_id', args.lawyerId);

  if (args.caseId != null) {
    query = query.eq('case_id', args.caseId!);
  }

  final data = await query.limit(1);
  return (data as List).isNotEmpty;
});

// Submit a review
class ReviewsNotifier extends StateNotifier<AsyncValue<void>> {
  ReviewsNotifier() : super(const AsyncValue.data(null));

  Future<bool> submitReview({
    required String lawyerId,
    required String lawyerName,
    required int rating,
    String? reviewText,
    String? caseId,
    String caseType = 'General',
    bool isAnonymous = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Get client name from profile
      final profileData = await SupabaseService.from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      final clientName = profileData?['full_name'] as String? ?? 'Client';

      final review = ReviewModel(
        id: '',
        clientId: user.id,
        lawyerId: lawyerId,
        caseId: caseId,
        rating: rating,
        reviewText: reviewText,
        caseType: caseType,
        clientName: clientName,
        isAnonymous: isAnonymous,
        createdAt: DateTime.now(),
      );

      await SupabaseService.from('reviews').insert(review.toJson());

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final reviewsNotifierProvider =
    StateNotifierProvider<ReviewsNotifier, AsyncValue<void>>(
  (ref) => ReviewsNotifier(),
);
