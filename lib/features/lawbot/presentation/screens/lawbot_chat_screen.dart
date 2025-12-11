import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_styles.dart';

class LawBotChatScreen extends ConsumerStatefulWidget {
  const LawBotChatScreen({super.key});

  @override
  ConsumerState<LawBotChatScreen> createState() => _LawBotChatScreenState();
}

class _LawBotChatScreenState extends ConsumerState<LawBotChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add initial bot greeting
    _messages.add(_ChatMessage(
      text: AppStrings.lawBotGreeting,
      isBot: true,
      timestamp: DateTime.now(),
    ));
  }

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

    // Add user message
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isBot: false,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate bot response (TODO: Replace with actual API call)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: _generateMockResponse(text),
          isBot: true,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  String _generateMockResponse(String userMessage) {
    // Mock responses for demonstration
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('divorce') || lowerMessage.contains('marriage')) {
      return "I understand you're asking about family law matters. Divorce proceedings typically involve several steps:\n\n1. Filing a petition for divorce\n2. Serving your spouse\n3. Negotiating terms (property division, custody, etc.)\n4. Court proceedings if necessary\n\nWould you like me to explain any of these steps in more detail, or would you prefer to connect with a family law specialist?";
    } else if (lowerMessage.contains('contract') || lowerMessage.contains('agreement')) {
      return "Contract law is an important area. Here are some key points to remember:\n\n• A valid contract requires offer, acceptance, consideration, and intention to create legal relations\n• Always read contracts thoroughly before signing\n• Keep copies of all signed agreements\n\nWould you like to discuss a specific contract issue or connect with a contract law specialist?";
    } else if (lowerMessage.contains('lawyer') || lowerMessage.contains('attorney')) {
      return "I can help you find the right lawyer! To give you the best recommendations, could you tell me:\n\n1. What type of legal issue do you have?\n2. What's your location?\n3. Do you have a budget in mind?\n\nAlternatively, you can use our 'Find Lawyers' feature to browse verified attorneys by specialization.";
    } else if (lowerMessage.contains('help') || lowerMessage.contains('what can you do')) {
      return "I'm LawBot, your AI legal assistant! Here's how I can help:\n\n• Answer general legal questions\n• Explain legal concepts and procedures\n• Help you understand your rights\n• Guide you to the right type of lawyer\n• Provide information about legal processes\n\nNote: I provide general information only. For specific legal advice, please consult with a qualified attorney.";
    } else {
      return "Thank you for your question. While I can provide general legal information, please note that:\n\n• This is not legal advice\n• Each situation is unique\n• Consulting a licensed attorney is recommended for specific matters\n\nCould you provide more details about your situation, or would you like me to help you find a qualified lawyer in our network?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LawBot',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  _isTyping ? 'Typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => _buildOptionsSheet(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer Banner
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.info.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'LawBot provides general information only. For legal advice, consult a licensed attorney.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const _TypingIndicator();
                }
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),

          // Quick Suggestions
          if (_messages.length <= 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickSuggestion(
                      text: 'What can you help with?',
                      onTap: () {
                        _messageController.text = 'What can you help with?';
                        _sendMessage();
                      },
                    ),
                    _QuickSuggestion(
                      text: 'Find a lawyer',
                      onTap: () {
                        _messageController.text = 'Help me find a lawyer';
                        _sendMessage();
                      },
                    ),
                    _QuickSuggestion(
                      text: 'Contract help',
                      onTap: () {
                        _messageController.text =
                            'I have a question about contracts';
                        _sendMessage();
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: AppStrings.typeMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: AppColors.textLight),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Chat'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _messages.add(_ChatMessage(
                  text: AppStrings.lawBotGreeting,
                  isBot: true,
                  timestamp: DateTime.now(),
                ));
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About LawBot'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About LawBot'),
                  content: const Text(
                    'LawBot is an AI-powered legal assistant that provides general legal information and guidance. It can help answer common legal questions and direct you to appropriate resources.\n\nNote: LawBot does not provide legal advice. Always consult with a qualified attorney for specific legal matters.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isBot ? AppColors.surface : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      message.isBot ? Radius.zero : const Radius.circular(16),
                  bottomRight:
                      message.isBot ? const Radius.circular(16) : Radius.zero,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color:
                      message.isBot ? AppColors.textPrimary : AppColors.textLight,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (!message.isBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: AppColors.secondary,
              ),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        );
      },
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
