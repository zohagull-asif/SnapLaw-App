import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../providers/lawbot_provider.dart';
import '../../data/models/chat_message_model.dart';

class LawBotChatScreen extends ConsumerStatefulWidget {
  const LawBotChatScreen({super.key});

  @override
  ConsumerState<LawBotChatScreen> createState() => _LawBotChatScreenState();
}

class _LawBotChatScreenState extends ConsumerState<LawBotChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await ref.read(lawBotProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final lawBotState = ref.watch(lawBotProvider);
    final messages = lawBotState.messages;
    final isLoading = lawBotState.isLoading;

    ref.listen<LawBotState>(lawBotProvider, (previous, next) {
      // Errors are shown as bot chat bubbles — no snackbar needed
      if (previous?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isNotEmpty) _scrollToBottom();
    });

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
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: SnapLawGradients.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(
                color: SnapLawColors.primary.withOpacity(0.40),
                blurRadius: 8, offset: const Offset(0, 2),
              )],
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('LawBot', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(
              isLoading ? 'Typing...' : 'Online',
              style: TextStyle(
                fontSize: 11,
                color: isLoading ? SnapLawColors.warning : SnapLawColors.success,
              )),
          ]),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.70)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF0D1130),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => _buildOptionsSheet(),
              );
            },
          ),
        ],
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: Column(
        children: [
          // Disclaimer Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: SnapLawColors.info.withOpacity(0.10),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: SnapLawColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LawBot provides general information only. Consult a licensed attorney for advice.',
                  style: TextStyle(fontSize: 11, color: SnapLawColors.info.withOpacity(0.85)),
                )),
            ]),
          ),

          // Chat Messages
          Expanded(
            child: Container(
              color: SnapLawColors.bgDeep,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isLoading && index == messages.length) {
                    return const _TypingIndicator();
                  }
                  return _ChatBubble(message: messages[index]);
                },
              ),
            ),
          ),

          // Quick Suggestions
          if (messages.length <= 2)
            Container(
              color: SnapLawColors.bgDark,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _QuickSuggestion(text: 'What can you help with?',
                    onTap: () { _messageController.text = 'What can you help with?'; _sendMessage(); }),
                  _QuickSuggestion(text: 'Find a lawyer',
                    onTap: () { _messageController.text = 'Help me find a lawyer'; _sendMessage(); }),
                  _QuickSuggestion(text: 'Contract help',
                    onTap: () { _messageController.text = 'I have a question about contracts'; _sendMessage(); }),
                ]),
              ),
            ),

          // Input Field
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                decoration: BoxDecoration(
                  color: SnapLawColors.bgDark.withOpacity(0.90),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
                ),
                child: SafeArea(
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: null,
                          enabled: !isLoading,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: AppStrings.typeMessage,
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: isLoading ? null : _sendMessage,
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: isLoading ? null : SnapLawGradients.primary,
                          color: isLoading ? Colors.white12 : null,
                          shape: BoxShape.circle,
                          boxShadow: isLoading ? null : [BoxShadow(
                            color: SnapLawColors.primary.withOpacity(0.40),
                            blurRadius: 8, offset: const Offset(0, 2),
                          )],
                        ),
                        child: Icon(Icons.send, color: isLoading ? Colors.white30 : Colors.white, size: 20),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildOptionsSheet() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          )),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.white70),
          title: const Text('Clear Chat', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            ref.read(lawBotProvider.notifier).clearChat();
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: Colors.white70),
          title: const Text('About LawBot', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF0D1130),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('About LawBot', style: TextStyle(color: Colors.white)),
                content: Text(
                  'LawBot is an AI-powered legal assistant powered by Gemini AI that provides general legal information and guidance. It can help answer common legal questions and direct you to appropriate resources.\n\nNote: LawBot does not provide legal advice. Always consult with a qualified attorney for specific legal matters.',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK', style: TextStyle(color: SnapLawColors.primary)),
                  ),
                ],
              ),
            );
          },
        ),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: SnapLawGradients.primary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isBot
                    ? Colors.white.withOpacity(0.09)
                    : SnapLawColors.primary.withOpacity(0.85),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: message.isBot ? Radius.zero : const Radius.circular(16),
                  bottomRight: message.isBot ? const Radius.circular(16) : Radius.zero,
                ),
                border: Border.all(
                  color: message.isBot
                      ? Colors.white.withOpacity(0.12)
                      : SnapLawColors.primary.withOpacity(0.30),
                  width: 1,
                ),
              ),
              child: Text(message.text,
                style: TextStyle(
                  color: message.isBot ? Colors.white.withOpacity(0.88) : Colors.white,
                  fontSize: 13, height: 1.45,
                )),
            ),
          ),
          if (!message.isBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.80)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: SnapLawGradients.primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _buildDot(0), const SizedBox(width: 4),
            _buildDot(1), const SizedBox(width: 4),
            _buildDot(2),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.45 + value * 0.40),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QuickSuggestion extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _QuickSuggestion({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: SnapLawColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SnapLawColors.primary.withOpacity(0.40)),
          ),
          child: Text(text, style: TextStyle(
            color: SnapLawColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
