import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/lawbot_api_service.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({required this.text, required this.isUser})
      : timestamp = DateTime.now();
}

class LegalQAScreen extends StatefulWidget {
  const LegalQAScreen({super.key});

  @override
  State<LegalQAScreen> createState() => _LegalQAScreenState();
}

class _LegalQAScreenState extends State<LegalQAScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  final String _sessionId = 'lawbot_${DateTime.now().millisecondsSinceEpoch}';

  final List<String> _suggestions = [
    'What are tenant rights in Pakistan?',
    'How to file an FIR?',
    'What is Khula process?',
    'Cheque bounce penalty?',
    'Property registration process?',
    'Cyber crime laws in Pakistan?',
  ];

  Future<void> _sendMessage([String? text]) async {
    final msg = (text ?? _controller.text).trim();
    if (msg.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: msg, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await LawBotApiService.sendChatMessage(
        message: msg,
        sessionId: _sessionId,
      );
      setState(() {
        _messages.add(_ChatMessage(text: response.response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Sorry, something went wrong. Please try again.\n\n${e.toString().replaceAll('Exception: ', '')}',
          isUser: false,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    LawBotApiService.clearChatSession(sessionId: _sessionId);
    setState(() {
      _messages.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B4A),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.smart_toy, size: 22),
            SizedBox(width: 8),
            Text('LawBot Chat'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Chat',
              onPressed: _clearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: _messages.isEmpty ? _buildWelcome() : _buildChatList(),
          ),

          // Input area
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B4A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, size: 40, color: Color(0xFF1A2B4A)),
          ),
          const SizedBox(height: 16),
          const Text(
            'LawBot',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2B4A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI-powered Pakistani law assistant.\nAsk any legal question in English, Urdu, or Roman Urdu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 30),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A2B4A)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) => InkWell(
              onTap: () => _sendMessage(s),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1A2B4A).withOpacity(0.15)),
                ),
                child: Text(s, style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A))),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 40 : 0,
          right: isUser ? 0 : 40,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Label
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUser ? Icons.person : Icons.smart_toy,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isUser ? 'You' : 'LawBot',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            // Bubble
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1A2B4A) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    )
                  : _buildFormattedResponse(message.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedResponse(String text) {
    // Parse the response and format sections
    final lines = text.split('\n');
    List<InlineSpan> spans = [];

    for (int i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      final line = lines[i];

      // Bold headers (lines ending with : or starting with **)
      if ((line.trimRight().endsWith(':') && line.trim().length < 60 && !line.contains('http')) ||
          line.startsWith('**')) {
        final cleanLine = line.replaceAll('**', '');
        spans.add(TextSpan(
          text: cleanLine,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2B4A), fontSize: 14, height: 1.6),
        ));
      }
      // Law references (PPC, PECA, Section, Act)
      else if (RegExp(r'(PPC|PECA|Section \d|Act \d|Ordinance|CrPC|CPC)', caseSensitive: false).hasMatch(line)) {
        spans.add(TextSpan(
          text: line,
          style: const TextStyle(color: Color(0xFF1565C0), fontSize: 14, height: 1.6),
        ));
      }
      // Numbered steps
      else if (RegExp(r'^\d+\.').hasMatch(line.trim())) {
        spans.add(TextSpan(
          text: line,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ));
      }
      // Disclaimer (usually italic)
      else if (line.contains('Disclaimer') || line.contains('not legal advice') || line.contains('consult a')) {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600], fontSize: 13, height: 1.6),
        ));
      }
      // Normal text
      else {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.6),
        ));
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A2B4A)),
            ),
            const SizedBox(width: 10),
            Text(
              'LawBot is thinking...',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask any legal question...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF0F4F8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A2B4A),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _isLoading ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
