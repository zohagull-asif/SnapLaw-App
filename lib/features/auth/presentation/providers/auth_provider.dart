import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../../../services/supabase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error, pendingVerification }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? pendingEmail;
  final Map<String, dynamic>? pendingUserData;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.pendingEmail,
    this.pendingUserData,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? pendingEmail,
    Map<String, dynamic>? pendingUserData,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      pendingUserData: pendingUserData ?? this.pendingUserData,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    SupabaseService.authStateChanges.listen((data) {
      final session = data.session;
      if (session != null) {
        _fetchUserProfile(session.user.id);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });

    // Check current session
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      _fetchUserProfile(currentUser.id);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final response = await SupabaseService.from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final user = UserModel.fromJson(response);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      // If profile doesn't exist yet, user needs to complete registration
      state = AuthState(
        status: AuthStatus.authenticated,
        user: null,
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    required UserRole role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'role': role.name,
        },
      );

      // Store pending user data for after OTP verification
      final pendingData = {
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': role.name,
        'user_id': response.user?.id,
      };

      // Supabase will send OTP email automatically on signup when email confirmation is enabled
      // Set state to pending verification
      state = state.copyWith(
        status: AuthStatus.pendingVerification,
        pendingEmail: email,
        pendingUserData: pendingData,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (state.pendingEmail == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'No pending verification found',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await SupabaseService.verifyOtp(
        email: state.pendingEmail!,
        token: otp,
      );

      if (response.user != null) {
        // OTP verified successfully, now create profile
        final pendingData = state.pendingUserData;
        if (pendingData != null) {
          try {
            // Create profile in profiles table
            await SupabaseService.from('profiles').insert({
              'id': response.user!.id,
              'email': pendingData['email'],
              'full_name': pendingData['full_name'],
              'phone_number': pendingData['phone_number'],
              'role': pendingData['role'],
              'is_verified': true,
              'created_at': DateTime.now().toIso8601String(),
            });

            // If lawyer, create lawyer_profiles entry
            if (pendingData['role'] == 'lawyer') {
              await SupabaseService.from('lawyer_profiles').insert({
                'user_id': response.user!.id,
                'is_verified': false,
                'is_available': true,
                'created_at': DateTime.now().toIso8601String(),
              });
            }
          } on PostgrestException catch (e) {
            // Profile might already exist, continue anyway
            if (!e.message.contains('duplicate')) {
              state = state.copyWith(
                status: AuthStatus.error,
                errorMessage: 'Failed to create profile: ${e.message}',
              );
              return false;
            }
          }
        }

        await _fetchUserProfile(response.user!.id);
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Verification failed. Please try again.',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.pendingVerification,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.pendingVerification,
        errorMessage: 'Invalid OTP. Please try again.',
      );
      return false;
    }
  }

  Future<bool> resendOtp() async {
    if (state.pendingEmail == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'No pending verification found',
      );
      return false;
    }

    try {
      await SupabaseService.resendOtp(state.pendingEmail!);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to resend OTP',
      );
      return false;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _fetchUserProfile(response.user!.id);
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      await SupabaseService.resetPassword(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(errorMessage: null);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
