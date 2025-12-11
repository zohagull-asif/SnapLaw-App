enum UserRole { client, lawyer, admin }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final UserRole role;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    required this.role,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.client,
      ),
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': role.name,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    UserRole? role,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LawyerProfile {
  final String id;
  final String userId;
  final String? barNumber;
  final String? specialization;
  final int yearsOfExperience;
  final String? bio;
  final double hourlyRate;
  final double rating;
  final int totalCases;
  final bool isAvailable;
  final List<String>? certifications;
  final String? officeAddress;
  final bool isVerified;
  final DateTime createdAt;

  LawyerProfile({
    required this.id,
    required this.userId,
    this.barNumber,
    this.specialization,
    this.yearsOfExperience = 0,
    this.bio,
    this.hourlyRate = 0,
    this.rating = 0,
    this.totalCases = 0,
    this.isAvailable = true,
    this.certifications,
    this.officeAddress,
    this.isVerified = false,
    required this.createdAt,
  });

  factory LawyerProfile.fromJson(Map<String, dynamic> json) {
    return LawyerProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      barNumber: json['bar_number'] as String?,
      specialization: json['specialization'] as String?,
      yearsOfExperience: json['years_of_experience'] as int? ?? 0,
      bio: json['bio'] as String?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalCases: json['total_cases'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'] as List)
          : null,
      officeAddress: json['office_address'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bar_number': barNumber,
      'specialization': specialization,
      'years_of_experience': yearsOfExperience,
      'bio': bio,
      'hourly_rate': hourlyRate,
      'rating': rating,
      'total_cases': totalCases,
      'is_available': isAvailable,
      'certifications': certifications,
      'office_address': officeAddress,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
