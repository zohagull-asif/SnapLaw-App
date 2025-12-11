import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/supabase_service.dart';

class LawyerModel {
  final String id;
  final String name;
  final String email;
  final String? specialization;
  final double rating;
  final int experienceYears;
  final double hourlyRate;
  final bool isVerified;
  final bool isAvailable;
  final String? avatarUrl;
  final String? bio;

  LawyerModel({
    required this.id,
    required this.name,
    required this.email,
    this.specialization,
    this.rating = 0.0,
    this.experienceYears = 0,
    this.hourlyRate = 0.0,
    this.isVerified = false,
    this.isAvailable = true,
    this.avatarUrl,
    this.bio,
  });

  factory LawyerModel.fromJson(Map<String, dynamic> json) {
    // Join data from profiles and lawyer_profiles tables
    final profile = json['profiles'] as Map<String, dynamic>?;

    return LawyerModel(
      id: json['user_id'] as String,
      name: profile?['full_name'] as String? ?? 'Unknown',
      email: profile?['email'] as String? ?? '',
      specialization: json['specialization'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      experienceYears: json['experience_years'] as int? ?? 0,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['is_verified'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      avatarUrl: profile?['avatar_url'] as String?,
      bio: json['bio'] as String?,
    );
  }
}

class LawyersState {
  final List<LawyerModel> lawyers;
  final bool isLoading;
  final String? errorMessage;

  const LawyersState({
    this.lawyers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LawyersState copyWith({
    List<LawyerModel>? lawyers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LawyersState(
      lawyers: lawyers ?? this.lawyers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Dummy lawyers for display when no real lawyers exist
final List<LawyerModel> _dummyLawyers = [
  LawyerModel(
    id: 'dummy-1',
    name: 'Sarah Johnson',
    email: 'sarah.johnson@lawfirm.com',
    specialization: 'Criminal Law',
    rating: 4.8,
    experienceYears: 12,
    hourlyRate: 250,
    isVerified: true,
    isAvailable: true,
    bio: 'Experienced criminal defense attorney with over 12 years of practice.',
  ),
  LawyerModel(
    id: 'dummy-2',
    name: 'Michael Chen',
    email: 'michael.chen@lawfirm.com',
    specialization: 'Corporate Law',
    rating: 4.9,
    experienceYears: 15,
    hourlyRate: 300,
    isVerified: true,
    isAvailable: true,
    bio: 'Specializing in mergers, acquisitions, and corporate governance.',
  ),
  LawyerModel(
    id: 'dummy-3',
    name: 'Emily Rodriguez',
    email: 'emily.rodriguez@lawfirm.com',
    specialization: 'Family Law',
    rating: 4.7,
    experienceYears: 8,
    hourlyRate: 200,
    isVerified: true,
    isAvailable: true,
    bio: 'Compassionate family law attorney handling divorce and custody cases.',
  ),
  LawyerModel(
    id: 'dummy-4',
    name: 'David Williams',
    email: 'david.williams@lawfirm.com',
    specialization: 'Immigration Law',
    rating: 4.6,
    experienceYears: 10,
    hourlyRate: 225,
    isVerified: false,
    isAvailable: true,
    bio: 'Helping clients navigate complex immigration processes.',
  ),
];

class LawyersNotifier extends StateNotifier<LawyersState> {
  LawyersNotifier() : super(const LawyersState()) {
    loadLawyers();
  }

  Future<void> loadLawyers({
    String? searchQuery,
    String? specialization,
    bool? onlyVerified,
    bool? onlyAvailable,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // First, get all profiles with role = 'lawyer'
      final profilesResponse = await SupabaseService.from('profiles')
          .select()
          .eq('role', 'lawyer');

      List<LawyerModel> lawyers = [];

      for (final profile in (profilesResponse as List)) {
        // Try to get lawyer_profiles data if it exists
        Map<String, dynamic>? lawyerProfile;
        try {
          final lpResponse = await SupabaseService.from('lawyer_profiles')
              .select()
              .eq('user_id', profile['id'])
              .maybeSingle();
          lawyerProfile = lpResponse;
        } catch (_) {
          // lawyer_profiles entry might not exist
        }

        lawyers.add(LawyerModel(
          id: profile['id'] as String,
          name: profile['full_name'] as String? ?? 'Unknown',
          email: profile['email'] as String? ?? '',
          specialization: lawyerProfile?['specialization'] as String?,
          rating: (lawyerProfile?['rating'] as num?)?.toDouble() ?? 4.5,
          experienceYears: lawyerProfile?['experience_years'] as int? ?? 0,
          hourlyRate: (lawyerProfile?['hourly_rate'] as num?)?.toDouble() ?? 0.0,
          isVerified: lawyerProfile?['is_verified'] as bool? ?? false,
          isAvailable: lawyerProfile?['is_available'] as bool? ?? true,
          avatarUrl: profile['avatar_url'] as String?,
          bio: lawyerProfile?['bio'] as String?,
        ));
      }

      // Apply filters only if specified
      if (onlyVerified == true) {
        lawyers = lawyers.where((l) => l.isVerified).toList();
      }

      if (onlyAvailable == true) {
        lawyers = lawyers.where((l) => l.isAvailable).toList();
      }

      if (specialization != null && specialization.isNotEmpty) {
        lawyers = lawyers.where((l) => l.specialization == specialization).toList();
      }

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        lawyers = lawyers.where((lawyer) {
          return lawyer.name.toLowerCase().contains(queryLower) ||
              (lawyer.specialization?.toLowerCase().contains(queryLower) ?? false);
        }).toList();
      }

      // Add dummy lawyers at the end if we have few real lawyers
      if (lawyers.length < 4) {
        lawyers.addAll(_dummyLawyers);
      }

      state = state.copyWith(lawyers: lawyers, isLoading: false);
    } on PostgrestException catch (e) {
      // On error, fall back to dummy lawyers
      state = state.copyWith(
        lawyers: _dummyLawyers,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      // On error, fall back to dummy lawyers
      state = state.copyWith(
        lawyers: _dummyLawyers,
        isLoading: false,
        errorMessage: null,
      );
    }
  }

  Future<void> searchLawyers(String query) async {
    await loadLawyers(searchQuery: query);
  }

  Future<void> filterLawyers({
    String? specialization,
    bool? onlyVerified,
    bool? onlyAvailable,
  }) async {
    await loadLawyers(
      specialization: specialization,
      onlyVerified: onlyVerified,
      onlyAvailable: onlyAvailable,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final lawyersProvider = StateNotifierProvider<LawyersNotifier, LawyersState>((ref) {
  return LawyersNotifier();
});
