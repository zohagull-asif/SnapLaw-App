import 'package:flutter/material.dart';
import '../../../../services/lawbot_api_service.dart';

class _ChatMsg {
  final String text;
  final bool isUser;
  _ChatMsg({required this.text, required this.isUser});
}

class CitizenLawBotScreen extends StatefulWidget {
  const CitizenLawBotScreen({super.key});

  @override
  State<CitizenLawBotScreen> createState() => _CitizenLawBotScreenState();
}

class _CitizenLawBotScreenState extends State<CitizenLawBotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _isLoading = false;
  final String _sessionId = 'citizen_lawbot_${DateTime.now().millisecondsSinceEpoch}';

  static const _suggestions = [
    'What are tenant rights in Pakistan?',
    'How to file an FIR?',
    'What is Khula process?',
    'Workplace harassment law?',
    'Cyber crime laws in Pakistan?',
    'How to claim inheritance?',
  ];

  Future<void> _send([String? text]) async {
    final msg = (text ?? _controller.text).trim();
    if (msg.isEmpty || _isLoading) return;
    setState(() {
      _messages.add(_ChatMsg(text: msg, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    try {
      final r = await LawBotApiService.sendChatMessage(message: msg, sessionId: _sessionId);
      setState(() {
        _messages.add(_ChatMsg(text: r.response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMsg(text: 'Error: ${e.toString().replaceAll('Exception: ', '')}', isUser: false));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
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
    return Column(
      children: [
        // Header banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1A3A5C), Color(0xFF2E5A8F)]),
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LawBot AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Ask any legal question about Pakistan law', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              )),
              if (_messages.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                  onPressed: () {
                    LawBotApiService.clearChatSession(sessionId: _sessionId);
                    setState(() => _messages.clear());
                  },
                ),
            ],
          ),
        ),
        // Chat area
        Expanded(
          child: _messages.isEmpty ? _buildWelcome() : _buildChat(),
        ),
        // Input
        _buildInput(),
      ],
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('🤖', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Ask Me Anything About Pakistani Law', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Free legal guidance in English, Urdu, or Roman Urdu', style: TextStyle(color: Colors.grey[600], fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: Text('Try asking:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _suggestions.map((s) => GestureDetector(
              onTap: () => _send(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A5C).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1A3A5C).withOpacity(0.2)),
                ),
                child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF1A3A5C))),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('LawBot provides general legal information, not legal advice. For specific cases, consult a qualified lawyer.', style: TextStyle(fontSize: 11, color: Colors.black87))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(children: [
              CircleAvatar(backgroundColor: Color(0xFF1A3A5C), radius: 16, child: Icon(Icons.smart_toy, color: Colors.white, size: 16)),
              SizedBox(width: 8),
              Text('Thinking...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ]),
          );
        }
        final m = _messages[i];
        return Align(
          alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: m.isUser ? const Color(0xFF1A3A5C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
            ),
            child: Text(m.text, style: TextStyle(color: m.isUser ? Colors.white : Colors.black87, fontSize: 14, height: 1.5)),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1, maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Ask a legal question...',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true, fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : () => _send(),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey : const Color(0xFF1A3A5C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
