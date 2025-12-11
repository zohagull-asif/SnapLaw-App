import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Missing Supabase credentials in .env file');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _client = Supabase.instance.client;
  }

  // Auth methods
  static User? get currentUser => client.auth.currentUser;

  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // OTP methods for email verification
  static Future<void> sendOtp(String email) async {
    await client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  }

  static Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  static Future<void> resendOtp(String email) async {
    await client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  // Database methods
  static SupabaseQueryBuilder from(String table) {
    return client.from(table);
  }

  // Storage methods
  static SupabaseStorageClient get storage => client.storage;

  // Realtime methods
  static RealtimeChannel channel(String name) {
    return client.channel(name);
  }
}
