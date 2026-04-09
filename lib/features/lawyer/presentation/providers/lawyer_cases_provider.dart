import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../client/data/models/case_model.dart';

class LawyerCasesState {
  final List<CaseModel> cases;
  final bool isLoading;
  final String? errorMessage;

  const LawyerCasesState({
    this.cases = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LawyerCasesState copyWith({
    List<CaseModel>? cases,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LawyerCasesState(
      cases: cases ?? this.cases,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class LawyerCasesNotifier extends StateNotifier<LawyerCasesState> {
  final Ref ref;
  Timer? _refreshTimer;
  StreamSubscription? _casesSubscription;

  LawyerCasesNotifier(this.ref) : super(const LawyerCasesState()) {
    loadCases();
    _startAutoRefresh();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _casesSubscription?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh cases every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      print('🔄 Auto-refreshing lawyer cases...');
      loadCases();
    });
  }

  void _subscribeToChanges() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Subscribe to real-time changes in the cases table
    _casesSubscription = SupabaseService
        .from('cases')
        .stream(primaryKey: ['id'])
        .eq('lawyer_id', user.id)
        .listen((data) {
          print('📡 Real-time update received: ${data.length} cases');
          final cases = data.map((json) => CaseModel.fromJson(json)).toList();
          state = state.copyWith(cases: cases, isLoading: false);
        });
  }

  Future<void> loadCases() async {
    final user = ref.read(authProvider).user;

    print('🔍 LawyerCasesProvider: Loading cases...');
    print('👤 Current user ID: ${user?.id}');

    if (user == null) {
      print('❌ No user logged in');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      print('📡 Querying cases table for lawyer_id: ${user.id}');

      // Fetch cases where the logged-in lawyer is assigned
      final response = await SupabaseService.from('cases')
          .select()
          .eq('lawyer_id', user.id)
          .order('created_at', ascending: false);

      print('📦 Response received: ${response.toString()}');
      print('📊 Number of cases found: ${(response as List).length}');

      final cases = (response as List)
          .map((json) {
            print('🔄 Parsing case: ${json['title']}');
            return CaseModel.fromJson(json);
          })
          .toList();

      print('✅ Successfully loaded ${cases.length} cases');
      state = state.copyWith(cases: cases, isLoading: false);
    } on PostgrestException catch (e) {
      print('❌ PostgrestException: ${e.message}');
      print('📋 Details: ${e.details}');
      print('💡 Hint: ${e.hint}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load cases: ${e.message}',
      );
    } catch (e) {
      print('❌ Unexpected error: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<bool> updateCaseStatus({
    required String caseId,
    required CaseStatus newStatus,
  }) async {
    print('🔄 [LawyerCasesProvider] Starting status update...');
    print('📋 Case ID: $caseId');
    print('🎯 New Status: ${newStatus.name}');

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final now = DateTime.now().toIso8601String();

      final updateData = {
        'status': newStatus.dbValue,
        'updated_at': now,
      };

      print('💾 Updating with data: $updateData');

      final response = await SupabaseService.from('cases')
          .update(updateData)
          .eq('id', caseId)
          .select();

      print('✅ Update response: $response');
      print('📊 Response type: ${response.runtimeType}');

      // Reload cases after update
      await loadCases();

      print('✅ Status update completed successfully');
      return true;
    } on PostgrestException catch (e) {
      print('❌ PostgrestException during status update:');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');
      print('   Hint: ${e.hint}');
      print('   Code: ${e.code}');

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update case: ${e.message}',
      );
      return false;
    } catch (e) {
      print('❌ Unexpected error during status update: ${e.toString()}');
      print('   Stack trace: ${StackTrace.current}');

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> refreshCases() async {
    await loadCases();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final lawyerCasesProvider =
    StateNotifierProvider<LawyerCasesNotifier, LawyerCasesState>((ref) {
  return LawyerCasesNotifier(ref);
});
