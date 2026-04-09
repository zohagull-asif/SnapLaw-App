import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/case_model.dart';

class CasesState {
  final List<CaseModel> cases;
  final bool isLoading;
  final String? errorMessage;

  const CasesState({
    this.cases = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CasesState copyWith({
    List<CaseModel>? cases,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CasesState(
      cases: cases ?? this.cases,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CasesNotifier extends StateNotifier<CasesState> {
  final Ref ref;

  CasesNotifier(this.ref) : super(const CasesState()) {
    loadCases();
  }

  Future<void> loadCases() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await SupabaseService.from('cases')
          .select()
          .eq('client_id', user.id)
          .order('created_at', ascending: false);

      final cases = (response as List)
          .map((json) => CaseModel.fromJson(json))
          .toList();

      state = state.copyWith(cases: cases, isLoading: false);
    } on PostgrestException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load cases: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  Future<bool> createCase({
    required String title,
    required String description,
    required CaseType type,
    required String lawyerId,
    bool isUrgent = false,
    List<String>? documentUrls,
  }) async {
    final user = ref.read(authProvider).user;

    print('📝 Creating case...');
    print('👤 Client ID: ${user?.id}');
    print('👨‍⚖️ Lawyer ID: $lawyerId');
    print('📋 Title: $title');

    if (user == null) {
      print('❌ User not authenticated');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'User not authenticated',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final now = DateTime.now().toIso8601String();

      final caseData = {
        'client_id': user.id,
        'lawyer_id': lawyerId,
        'title': title,
        'description': description,
        'type': type.name,
        'status': 'open',
        'is_urgent': isUrgent,
        'created_at': now,
        'updated_at': now,
        if (documentUrls != null && documentUrls.isNotEmpty)
          'document_urls': documentUrls,
      };

      print('💾 Inserting case with data: $caseData');

      final response = await SupabaseService.from('cases')
          .insert(caseData)
          .select()
          .single();

      print('✅ Case created successfully: ${response['id']}');
      print('📦 Full response: $response');

      final newCase = CaseModel.fromJson(response);
      state = state.copyWith(
        cases: [newCase, ...state.cases],
        isLoading: false,
      );
      return true;
    } on PostgrestException catch (e) {
      print('❌ PostgrestException: ${e.message}');
      print('📋 Details: ${e.details}');
      print('💡 Hint: ${e.hint}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create case: ${e.message}',
      );
      return false;
    } catch (e) {
      print('❌ Unexpected error: ${e.toString()}');
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

final casesProvider = StateNotifierProvider<CasesNotifier, CasesState>((ref) {
  return CasesNotifier(ref);
});
