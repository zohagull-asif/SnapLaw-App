import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/message_model.dart';

class MessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? errorMessage;
  final int unreadCount;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.unreadCount = 0,
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
    int? unreadCount,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final Ref ref;
  final String? caseId;

  MessagesNotifier(this.ref, {this.caseId}) : super(const MessagesState()) {
    if (caseId != null) {
      loadMessagesForCase(caseId!);
    } else {
      loadAllMessages();
    }
  }

  Future<void> loadMessagesForCase(String caseId) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      print('📨 Loading messages for case: $caseId');

      final response = await SupabaseService.from('messages')
          .select()
          .eq('case_id', caseId)
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      print('✅ Loaded ${messages.length} messages');

      // Count unread messages
      final unread = messages.where((m) =>
        m.receiverId == user.id && !m.isRead
      ).length;

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        unreadCount: unread,
      );
    } on PostgrestException catch (e) {
      print('❌ Error loading messages: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load messages: ${e.message}',
      );
    } catch (e) {
      print('❌ Unexpected error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<void> loadAllMessages() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      print('📨 Loading all messages for user: ${user.id}');

      // Get messages where user is sender or receiver
      final response = await SupabaseService.from('messages')
          .select()
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .order('created_at', ascending: false);

      final messages = (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      print('✅ Loaded ${messages.length} messages');

      // Count unread messages
      final unread = messages.where((m) =>
        m.receiverId == user.id && !m.isRead
      ).length;

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        unreadCount: unread,
      );
    } on PostgrestException catch (e) {
      print('❌ Error loading messages: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load messages: ${e.message}',
      );
    } catch (e) {
      print('❌ Unexpected error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<bool> sendMessage({
    required String caseId,
    required String receiverId,
    required String content,
  }) async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      print('❌ No user logged in');
      return false;
    }

    try {
      final now = DateTime.now().toIso8601String();
      const uuid = Uuid();

      final messageData = {
        'id': uuid.v4(),
        'case_id': caseId,
        'sender_id': user.id,
        'receiver_id': receiverId,
        'sender_name': user.fullName,
        'sender_role': user.role.name,
        'content': content,
        'is_read': false,
        'created_at': now,
      };

      print('📤 Sending message: ${messageData['content']}');

      final response = await SupabaseService.from('messages')
          .insert(messageData)
          .select()
          .single();

      final newMessage = MessageModel.fromJson(response);

      print('✅ Message sent successfully');

      // Add to state
      state = state.copyWith(
        messages: [...state.messages, newMessage],
      );

      return true;
    } on PostgrestException catch (e) {
      print('❌ Error sending message: ${e.message}');
      state = state.copyWith(
        errorMessage: 'Failed to send message: ${e.message}',
      );
      return false;
    } catch (e) {
      print('❌ Unexpected error: $e');
      state = state.copyWith(
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await SupabaseService.from('messages')
          .update({'is_read': true})
          .eq('id', messageId);

      // Update local state
      final updatedMessages = state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(isRead: true);
        }
        return m;
      }).toList();

      final unread = updatedMessages.where((m) {
        final user = ref.read(authProvider).user;
        return m.receiverId == user?.id && !m.isRead;
      }).length;

      state = state.copyWith(
        messages: updatedMessages,
        unreadCount: unread,
      );
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  Future<void> markAllAsRead(String caseId) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      await SupabaseService.from('messages')
          .update({'is_read': true})
          .eq('case_id', caseId)
          .eq('receiver_id', user.id);

      // Reload messages
      if (this.caseId != null) {
        await loadMessagesForCase(this.caseId!);
      } else {
        await loadAllMessages();
      }
    } catch (e) {
      print('❌ Error marking all messages as read: $e');
    }
  }

  Future<void> refreshMessages() async {
    if (caseId != null) {
      await loadMessagesForCase(caseId!);
    } else {
      await loadAllMessages();
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider for messages in a specific case
final messagesProvider = StateNotifierProviderFamily<MessagesNotifier, MessagesState, String?>(
  (ref, caseId) => MessagesNotifier(ref, caseId: caseId),
);

// Provider for all messages
final allMessagesProvider = StateNotifierProvider<MessagesNotifier, MessagesState>(
  (ref) => MessagesNotifier(ref),
);
