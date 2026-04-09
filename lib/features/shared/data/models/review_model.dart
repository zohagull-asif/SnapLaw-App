class ReviewModel {
  final String id;
  final String clientId;
  final String lawyerId;
  final String? caseId;
  final int rating;
  final String? reviewText;
  final String caseType;
  final String clientName;
  final bool isAnonymous;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.clientId,
    required this.lawyerId,
    this.caseId,
    required this.rating,
    this.reviewText,
    this.caseType = 'General',
    this.clientName = 'Anonymous',
    this.isAnonymous = false,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      lawyerId: json['lawyer_id'] as String,
      caseId: json['case_id'] as String?,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      caseType: json['case_type'] as String? ?? 'General',
      clientName: json['client_name'] as String? ?? 'Anonymous',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'lawyer_id': lawyerId,
        if (caseId != null) 'case_id': caseId,
        'rating': rating,
        if (reviewText != null) 'review_text': reviewText,
        'case_type': caseType,
        'client_name': isAnonymous ? 'Anonymous' : clientName,
        'is_anonymous': isAnonymous,
      };

  String get displayName => isAnonymous ? 'Anonymous' : clientName;

  String get starsDisplay => '⭐' * rating;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return 'Just now';
  }
}

class LawyerRatingSummary {
  final String lawyerId;
  final int reviewCount;
  final double averageRating;
  final int fiveStar;
  final int fourStar;
  final int threeStar;
  final int twoStar;
  final int oneStar;

  const LawyerRatingSummary({
    required this.lawyerId,
    required this.reviewCount,
    required this.averageRating,
    this.fiveStar = 0,
    this.fourStar = 0,
    this.threeStar = 0,
    this.twoStar = 0,
    this.oneStar = 0,
  });

  factory LawyerRatingSummary.empty(String lawyerId) => LawyerRatingSummary(
        lawyerId: lawyerId,
        reviewCount: 0,
        averageRating: 0.0,
      );

  double get percentage5 => reviewCount == 0 ? 0 : fiveStar / reviewCount;
  double get percentage4 => reviewCount == 0 ? 0 : fourStar / reviewCount;
  double get percentage3 => reviewCount == 0 ? 0 : threeStar / reviewCount;
  double get percentage2 => reviewCount == 0 ? 0 : twoStar / reviewCount;
  double get percentage1 => reviewCount == 0 ? 0 : oneStar / reviewCount;
}
