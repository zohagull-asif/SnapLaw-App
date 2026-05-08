import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../client/data/models/case_model.dart';
import '../../../shared/data/models/message_model.dart';
import '../../../shared/presentation/providers/messages_provider.dart';

class _Conversation {
  final String caseId;
  final String clientId;
  final String clientName;
  final MessageModel lastMessage;
  final int unreadCount;

  _Conversation({
    required this.caseId,
    required this.clientId,
    required this.clientName,
    required this.lastMessage,
    required this.unreadCount,
  });
}

class LawyerMessagesScreen extends ConsumerWidget {
  const LawyerMessagesScreen({super.key});

  List<_Conversation> _buildConversations(
    List<MessageModel> messages,
    String? currentUserId,
  ) {
    // Group by case_id
    final Map<String, List<MessageModel>> grouped = {};
    for (final msg in messages) {
      grouped.putIfAbsent(msg.caseId, () => []).add(msg);
    }

    final conversations = <_Conversation>[];

    for (final entry in grouped.entries) {
      final msgs = entry.value;
      // Sort: most recent first
      msgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final lastMsg = msgs.first;

      // Find the client in this conversation (role == 'client')
      String clientId = '';
      String clientName = 'Client';

      final clientMsg = msgs.firstWhere(
        (m) => m.senderRole == 'client',
        orElse: () => msgs.firstWhere(
          (m) => m.senderId != currentUserId,
          orElse: () => msgs.first,
        ),
      );

      if (clientMsg.senderRole == 'client') {
        clientId = clientMsg.senderId;
        clientName = clientMsg.senderName;
      } else {
        // client is the receiver
        clientId = clientMsg.receiverId;
        // try to find a message where client sent to get their name
        final fromClient = msgs.where((m) => m.senderId == clientId);
        clientName = fromClient.isNotEmpty ? fromClient.first.senderName : 'Client';
      }

      final unread = msgs.where((m) =>
        m.receiverId == currentUserId && !m.isRead,
      ).length;

      conversations.add(_Conversation(
        caseId: entry.key,
        clientId: clientId,
        clientName: clientName,
        lastMessage: lastMsg,
        unreadCount: unread,
      ));
    }

    // Sort conversations: most recent first
    conversations.sort((a, b) =>
      b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt));

    return conversations;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('dd/MM/yy').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesState = ref.watch(allMessagesProvider);
    final currentUser = ref.watch(authProvider).user;
    final conversations = _buildConversations(
      messagesState.messages,
      currentUser?.id,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: SnapLawColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: SnapLawColors.lawyerPurple.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.message, color: SnapLawColors.lawyerPurple, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (messagesState.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: SnapLawColors.lawyerPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${messagesState.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            onPressed: () => ref.read(allMessagesProvider.notifier).refreshMessages(),
          ),
        ],
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: messagesState.isLoading && messagesState.messages.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : messagesState.errorMessage != null
                ? _buildError(context, ref, messagesState.errorMessage!)
                : conversations.isEmpty
                    ? _buildEmpty()
                    : _buildList(context, conversations),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<_Conversation> conversations) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final isMe = conv.lastMessage.senderRole == 'lawyer';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              // Build minimal CaseModel to pass to MessageClientScreen
              final caseModel = CaseModel(
                id: conv.caseId,
                clientId: conv.clientId,
                title: 'Chat with ${conv.clientName}',
                description: '',
                type: CaseType.other,
                createdAt: conv.lastMessage.createdAt,
              );
              context.push(
                '/lawyer/message-client/${conv.clientId}',
                extra: caseModel,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: conv.unreadCount > 0
                        ? SnapLawColors.lawyerPurple.withOpacity(0.10)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: conv.unreadCount > 0
                          ? SnapLawColors.lawyerPurple.withOpacity(0.35)
                          : Colors.white.withOpacity(0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: SnapLawColors.lawyerPurple.withOpacity(0.25),
                        child: Text(
                          conv.clientName.isNotEmpty
                              ? conv.clientName[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            color: SnapLawColors.lawyerPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(
                                  conv.clientName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: conv.unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(conv.lastMessage.createdAt),
                                style: TextStyle(
                                  color: conv.unreadCount > 0
                                      ? SnapLawColors.lawyerPurple
                                      : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: conv.unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              if (isMe)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.done_all,
                                    size: 14,
                                    color: Colors.white38,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  conv.lastMessage.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: conv.unreadCount > 0
                                        ? Colors.white70
                                        : Colors.white38,
                                    fontSize: 12,
                                    fontWeight: conv.unreadCount > 0
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (conv.unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: SnapLawColors.lawyerPurple,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${conv.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No Messages Yet',
            style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Client messages will appear here',
            style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: SnapLawColors.danger),
          const SizedBox(height: 16),
          Text(error,
            style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 13),
            textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(allMessagesProvider.notifier).refreshMessages(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SnapLawColors.lawyerPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
