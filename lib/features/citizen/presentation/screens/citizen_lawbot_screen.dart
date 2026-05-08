import 'dart:ui';
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
  String _sessionId = 'citizen_${DateTime.now().millisecondsSinceEpoch}';
  bool _isLoading = false;

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
      final response = await LawBotApiService.sendChatMessage(
        message: msg,
        sessionId: _sessionId,
      );
      setState(() {
        _messages.add(_ChatMsg(text: response.response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMsg(
          text: 'Connection error: ${e.toString().replaceAll('Exception: ', '')}',
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
            gradient: LinearGradient(colors: [Color(0xFF0F1535), Color(0xFF2E5A8F)]),
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
                    setState(() {
                      _messages.clear();
                      _sessionId = 'citizen_${DateTime.now().millisecondsSinceEpoch}';
                    });
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
          const Text('Ask Me Anything About Pakistani Law',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Free legal guidance in English, Urdu, or Roman Urdu',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
            textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Try asking:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white.withOpacity(0.80))),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _suggestions.map((s) => GestureDetector(
              onTap: () => _send(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: Text(s, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.35)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'LawBot provides general legal information, not legal advice. For specific cases, consult a qualified lawyer.',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.80)),
                  )),
                ]),
              ),
            ),
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
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0F1535),
                radius: 16,
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Thinking...', style: TextStyle(color: Colors.white.withOpacity(0.55), fontStyle: FontStyle.italic)),
            ]),
          );
        }
        final m = _messages[i];
        return Align(
          alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: m.isUser
                        ? const Color(0xFF0F1535).withOpacity(0.85)
                        : Colors.white.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: m.isUser
                          ? Colors.white.withOpacity(0.15)
                          : Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1, maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Ask a legal question...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.40)),
                    filled: true,
                    fillColor: const Color(0xFF0F1535).withOpacity(0.07),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.white.withOpacity(0.35))),
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
                    color: _isLoading ? Colors.white24 : const Color(0xFF0F1535),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.20)),
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
