import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/supabase_service.dart';
import '../../data/models/case_update_model.dart';

class CaseUpdatesState {
  final List<CaseUpdateModel> updates;
  final bool isLoading;
  final String? errorMessage;

  const CaseUpdatesState({
    this.updates = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CaseUpdatesState copyWith({
    List<CaseUpdateModel>? updates,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CaseUpdatesState(
      updates: updates ?? this.updates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CaseUpdatesNotifier extends StateNotifier<CaseUpdatesState> {
  final String caseId;
  StreamSubscription? _subscription;

  CaseUpdatesNotifier(this.caseId) : super(const CaseUpdatesState()) {
    loadUpdates();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToUpdates() {
    _subscription = SupabaseService.from('case_updates')
        .stream(primaryKey: ['id'])
        .eq('case_id', caseId)
        .order('timestamp', ascending: true)
        .listen((data) {
      final updates = data.map((json) => CaseUpdateModel.fromJson(json)).toList();
      state = state.copyWith(updates: updates, isLoading: false);
    });
  }

  Future<void> loadUpdates() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await SupabaseService.from('case_updates')
          .select()
          .eq('case_id', caseId)
          .order('timestamp', ascending: true);

      final updates = (response as List)
          .map((json) => CaseUpdateModel.fromJson(json))
          .toList();

      state = state.copyWith(updates: updates, isLoading: false);
    } on PostgrestException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load updates: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }

  Future<bool> postUpdate({
    required String title,
    required String description,
    required UpdateType type,
    String? lawyerName,
    String? nextAction,
    DateTime? nextHearingDate,
    List<String>? attachments,
  }) async {
    try {
      final user = SupabaseService.client.auth.currentUser;

      await SupabaseService.from('case_updates').insert({
        'case_id': caseId,
        'title': title,
        'description': description,
        'type': type.name,
        'timestamp': DateTime.now().toIso8601String(),
        'lawyer_name': lawyerName,
        'next_action': nextAction,
        'next_hearing_date': nextHearingDate?.toIso8601String(),
        'attachments': attachments,
        'created_by': user?.id,
      });

      await loadUpdates();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to post update: ${e.toString()}');
      return false;
    }
  }

  Future<void> refresh() async {
    await loadUpdates();
  }
}

final caseUpdatesProviderFamily =
    StateNotifierProvider.family<CaseUpdatesNotifier, CaseUpdatesState, String>(
  (ref, caseId) => CaseUpdatesNotifier(caseId),
);
