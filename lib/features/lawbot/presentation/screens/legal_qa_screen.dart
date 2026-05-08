import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../../services/gemini_service.dart';

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

const _kLawyerLawBotSystem = '''You are LawBot, the official AI legal assistant for SnapLaw — a Pakistani legal platform used by professional lawyers.

You are an expert in Pakistani law, assisting qualified lawyers with legal research, case analysis, and law citations.

YOUR RULES:
1. Only answer questions related to Pakistani law.
2. Always cite specific law names, section numbers, and punishments where applicable.
3. Be precise and thorough — your users are qualified lawyers, so you can use proper legal terminology.
4. If a question involves multiple legal areas, cover all of them comprehensively.
5. Always mention relevant precedents or landmark cases when applicable.
6. If you are not sure about something, say so honestly.

YOUR KNOWLEDGE COVERS:
- Pakistan Penal Code (PPC) 1860, Code of Criminal Procedure (CrPC) 1898, Code of Civil Procedure (CPC) 1908
- Constitution of Pakistan 1973 and all fundamental rights
- Family Laws: Muslim Family Laws Ordinance 1961, Khula, Divorce, Custody, Maintenance, Mehr
- Property Laws: Transfer of Property Act 1882, Registration Act 1908, Land Revenue Act
- Labor Laws: Industrial Relations Act, Payment of Wages Act, Factories Act, EOBI
- Contract Act 1872, Sale of Goods Act 1930, Partnership Act 1932
- Prevention of Electronic Crimes Act (PECA) 2016
- Anti-Terrorism Act 1997, National Accountability Bureau (NAB) Ordinance 1999
- Companies Act 2017, Securities Act 2015
- Negotiable Instruments Act 1881 (Cheque Bounce), Qanun-e-Shahadat Order 1984
- Juvenile Justice System Act 2018, Zainab Alert Act 2020
- All provincial laws (Punjab, Sindh, KP, Balochistan)
- Islamic law principles as applied in Pakistani courts (Hudood, Qisas, Diyat)

RESPONSE FORMAT:
- Provide comprehensive, structured legal answers
- Cite specific sections with precise wording
- Reference landmark Pakistani case law when relevant
- Give practical legal strategies and next steps''';

class _LegalQAScreenState extends State<LegalQAScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  final List<Map<String, String>> _history = [];

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
      final reply = await GeminiService.sendMessage(
        message: msg,
        conversationHistory: List.from(_history),
        systemPrompt: _kLawyerLawBotSystem,
      );
      _history.add({'role': 'user', 'content': msg});
      _history.add({'role': 'assistant', 'content': reply});
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _history.clear();
    });
  }

  String _mockResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('tenant') || q.contains('rent') || q.contains('landlord')) {
      return "**Tenancy Law in Pakistan**\n\nTenant rights are governed by provincial Rent Restriction Acts.\n\n**Key Provisions:**\n• Landlord cannot evict without a court order\n• Rent increase requires proper notice (usually 30 days)\n• Tenant entitled to receipt for every payment\n• Written tenancy agreement strongly recommended\n\n**Relevant Laws:** Rent Restriction Ordinance (province-specific), Transfer of Property Act 1882\n\n*Consult a qualified lawyer for case-specific advice.*";
    } else if (q.contains('fir') || q.contains('criminal') || q.contains('police') || q.contains('arrest')) {
      return "**FIR & Criminal Procedure (CrPC)**\n\nUnder Section 154 CrPC, police are legally bound to register an FIR for cognizable offences.\n\n**Process:**\n1. Report to SHO of concerned police station\n2. FIR must be registered immediately\n3. Free copy of FIR must be provided to complainant\n4. If refused, approach DSP/SSP or Judicial Magistrate under Section 22-A CrPC\n\n**Rights of Accused:** Right to bail (bailable offences), right to counsel, right to remain silent.";
    } else if (q.contains('khula') || q.contains('divorce') || q.contains('talaq') || q.contains('family')) {
      return "**Family Law – Khula & Divorce (MFLO 1961)**\n\nUnder the Muslim Family Laws Ordinance 1961:\n\n**Talaq (by husband):** Written notice to Union Council → 90-day reconciliation period → divorce effective\n\n**Khula (by wife):** Filed in Family Court → wife returns Mehr → court may decree Khula\n\n**Maintenance:** Father liable under Section 369 PPC for failure to maintain\n\n**Custody:** Mother gets hizanat of minor children; father has guardianship rights";
    } else if (q.contains('cheque') || q.contains('bounce') || q.contains('dishonour')) {
      return "**Dishonoured Cheque – Section 489-F PPC**\n\nIssuance of a cheque knowing insufficient funds is punishable under Section 489-F PPC.\n\n**Punishment:** Up to 3 years imprisonment, or fine, or both\n\n**Civil Remedy:** Summary suit under Order XXXVII CPC for recovery\n\n**Process:**\n1. Send legal notice within 30 days of dishonour\n2. File complaint under 489-F PPC if not paid\n3. File civil suit for recovery simultaneously";
    } else if (q.contains('property') || q.contains('registration') || q.contains('transfer')) {
      return "**Property Law – Transfer & Registration**\n\nGoverned by Transfer of Property Act 1882 and Registration Act 1908.\n\n**Sale Deed Requirements:**\n• Must be registered with Sub-Registrar\n• Stamp duty applicable (varies by province)\n• Fard (ownership record) verification mandatory\n• NOC from relevant authority if applicable\n\n**Section 17 Registration Act:** Compulsory registration for immovable property transfers above Rs. 100";
    } else if (q.contains('cyber') || q.contains('peca') || q.contains('online') || q.contains('internet')) {
      return "**Cyber Crime – PECA 2016**\n\nPrevention of Electronic Crimes Act 2016 covers:\n\n• **Section 10:** Cyber stalking – up to 3 years + fine\n• **Section 17:** Malicious code – up to 7 years\n• **Section 20:** Online defamation – up to 3 years\n• **Section 21:** Spoofing – up to 3 years\n\n**Reporting:** FIA Cyber Crime Wing (complaint.fia.gov.pk)\n\n**Jurisdiction:** Federal Investigation Agency (FIA) handles PECA offences";
    } else {
      return "I can assist with questions on Pakistani law including:\n\n• **Criminal Law** – PPC, CrPC, FIR, bail\n• **Family Law** – divorce, khula, custody, maintenance\n• **Property Law** – transfer, registration, tenancy\n• **Contract Law** – breach, remedies, enforcement\n• **Cyber Law** – PECA 2016, FIA complaints\n• **Corporate Law** – Companies Act 2017\n• **Labour Law** – employment rights, termination\n\nPlease rephrase your question with more detail for a comprehensive legal answer.";
    }
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
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: SnapLawColors.bgDark,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.smart_toy, size: 22, color: Colors.white),
            SizedBox(width: 8),
            Text('LawBot Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
      body: AppBackground(
        overlayOpacity: 0.55,
        child: Column(
          children: [
            // Chat messages area
            Expanded(
              child: _messages.isEmpty ? _buildWelcome() : _buildChatList(),
            ),

            // Input area
            _buildInputBar(),
          ],
        ),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF7B61FF), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.4), blurRadius: 20, spreadRadius: 4)],
            ),
            child: const Icon(Icons.smart_toy, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'LawBot',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI-powered Pakistani law assistant.\nAsk any legal question in English, Urdu, or Roman Urdu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.5),
          ),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white.withOpacity(0.8)),
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
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(s, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
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
                    color: const Color(0xFF8892B0),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isUser ? 'You' : 'LawBot',
                    style: TextStyle(fontSize: 11, color: const Color(0xFF8892B0), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            // Bubble
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? SnapLawColors.primary.withOpacity(0.85) : Colors.white.withOpacity(0.09),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.12)),
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
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14, height: 1.6),
        ));
      }
      // Law references (PPC, PECA, Section, Act)
      else if (RegExp(r'(PPC|PECA|Section \d|Act \d|Ordinance|CrPC|CPC)', caseSensitive: false).hasMatch(line)) {
        spans.add(TextSpan(
          text: line,
          style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 14, height: 1.6),
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
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.6),
        ));
      }
      // Normal text
      else {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, height: 1.6),
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
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7B61FF)),
            ),
            const SizedBox(width: 10),
            Text(
              'LawBot is thinking...',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
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
        color: SnapLawColors.bgDark,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ask any legal question...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: const Color(0xFF0F1535).withOpacity(0.08),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B61FF), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
