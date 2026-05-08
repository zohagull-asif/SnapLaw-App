import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../shared/presentation/providers/messages_provider.dart';

class MessagesInboxScreen extends ConsumerStatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  ConsumerState<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends ConsumerState<MessagesInboxScreen> {
  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(allMessagesProvider);

    // Group messages by case
    final groupedMessages = <String, List<dynamic>>{};
    for (var message in messagesState.messages) {
      if (!groupedMessages.containsKey(message.caseId)) {
        groupedMessages[message.caseId] = [];
      }
      groupedMessages[message.caseId]!.add(message);
    }

    // Get the latest message for each case
    final caseConversations = groupedMessages.entries.map((entry) {
      final messages = entry.value;
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return {
        'caseId': entry.key,
        'latestMessage': messages.first,
        'unreadCount': messages.where((m) => !m.isRead && m.senderRole == 'lawyer').length,
        'allMessages': messages,
      };
    }).toList();

    caseConversations.sort((a, b) =>
      (b['latestMessage'] as dynamic).createdAt.compareTo(
        (a['latestMessage'] as dynamic).createdAt
      )
    );

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1130),
        title: const Text('Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (messagesState.unreadCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${messagesState.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(allMessagesProvider.notifier).refreshMessages();
            },
          ),
        ],
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: messagesState.isLoading && messagesState.messages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : messagesState.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(messagesState.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(allMessagesProvider.notifier).refreshMessages();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : messagesState.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: AppStyles.subtitle1.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Messages from your lawyers will appear here',
                            style: AppStyles.bodyText2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(allMessagesProvider.notifier).refreshMessages(),
                      child: ListView.builder(
                        itemCount: caseConversations.length,
                        itemBuilder: (context, index) {
                          final conversation = caseConversations[index];
                          final latestMessage = conversation['latestMessage'];
                          final unreadCount = conversation['unreadCount'] as int;

                          return _ConversationCard(
                            caseId: conversation['caseId'] as String,
                            latestMessage: latestMessage,
                            unreadCount: unreadCount,
                          );
                        },
                      ),
                    ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final String caseId;
  final dynamic latestMessage;
  final int unreadCount;

  const _ConversationCard({
    required this.caseId,
    required this.latestMessage,
    required this.unreadCount,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isUnread
            ? Colors.white.withOpacity(0.10)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread
              ? SnapLawColors.clientBlue.withOpacity(0.40)
              : Colors.white.withOpacity(0.10),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: SnapLawColors.clientBlue.withOpacity(0.30),
          radius: 28,
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                latestMessage.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTime(latestMessage.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: isUnread ? SnapLawColors.clientBlue : Colors.white54,
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Case: ${caseId.substring(0, 8)}...',
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            ),
            const SizedBox(height: 4),
            Text(
              latestMessage.content,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                color: isUnread ? Colors.white : Colors.white60,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: unreadCount > 0
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () {
          context.push('/client/messages/$caseId');
        },
      ),
    );
  }
}
