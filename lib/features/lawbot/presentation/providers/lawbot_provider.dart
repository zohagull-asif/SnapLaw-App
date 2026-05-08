import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/gemini_service.dart';
import '../../data/models/chat_message_model.dart';

const _kLawBotSystem = '''You are LawBot, an expert AI legal assistant for SnapLaw, specializing in Pakistani law.

Your role:
- Answer ANY legal question about Pakistani law comprehensively
- Provide accurate information about laws, procedures, rights, and regulations in Pakistan
- Explain legal concepts in simple, understandable language
- Give practical guidance and step-by-step instructions when relevant
- Reference specific Pakistani laws, acts, and ordinances when applicable
- Be helpful, informative, and direct

Coverage areas (Pakistan-specific):
- Constitution of Pakistan 1973
- Pakistan Penal Code (PPC)
- Criminal Procedure Code (CrPC)
- Civil Procedure Code (CPC)
- Contract Act 1872
- Family laws (Muslim Family Laws Ordinance 1961, etc.)
- Property laws (Transfer of Property Act 1882, Land Revenue Acts)
- Motor Vehicles Ordinance 1965
- Labor laws and employment rights
- Business and company law
- Tax laws (Income Tax Ordinance, Sales Tax)
- And ALL other Pakistani legal topics

Response style:
- Answer questions directly and comprehensively
- Use bullet points and clear formatting
- Provide specific details, procedures, and requirements
- Include relevant legal citations when helpful
- Give practical examples from Pakistani context
- Keep responses 3-6 paragraphs (detailed but readable)
- Only add brief disclaimer at the end if needed

Remember: You are an expert on Pakistani law helping users understand their legal rights and options.''';

class LawBotState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? errorMessage;

  const LawBotState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LawBotState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LawBotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class LawBotNotifier extends StateNotifier<LawBotState> {
  LawBotNotifier() : super(const LawBotState()) {
    _initializeChat();
  }

  void _initializeChat() {
    final greetingMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: "Hello! I'm LawBot, your AI legal assistant powered by Gemini. I'm here to help answer your legal questions and guide you through Pakistani legal processes.\n\nHow can I help you today?",
      isBot: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [greetingMessage]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isBot: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final conversationHistory = state.messages
          .skip(1)
          .where((msg) => msg.id != userMessage.id)
          .map((msg) => {
                'role': msg.isBot ? 'assistant' : 'user',
                'content': msg.text,
              })
          .toList();

      final responseText = await GeminiService.sendMessage(
        message: text,
        conversationHistory: conversationHistory,
        systemPrompt: _kLawBotSystem,
      );

      final botMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: responseText,
        isBot: true,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
      );
    } catch (e) {
      final errorMsg = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Sorry, I could not connect to the AI service. Error: ${e.toString()}\n\nPlease check that GROQ_API_KEY is correctly set in your .env file.',
        isBot: true,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
      );
    }
  }

  Future<void> _handleMockResponse(String text) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final response = _generateMockResponse(text);
    final botMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: response,
      isBot: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, botMessage],
      isLoading: false,
    );
  }

  String _generateMockResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('traffic') || lowerMessage.contains('driving') || lowerMessage.contains('license')) {
      return "In Pakistan, traffic laws are governed by the Motor Vehicles Ordinance 1965 and Provincial Motor Vehicle Rules. Key regulations include:\n\n• Drive on the left side of the road\n• Valid driving license mandatory for all drivers\n• Vehicle registration and insurance required\n• Speed limits: 50 km/h in cities, 80-120 km/h on highways\n• Seat belts compulsory for front seat passengers\n• Mobile phone use while driving prohibited\n• Drunk driving strictly prohibited\n• Traffic violations result in fines ranging from Rs. 500 to Rs. 5,000\n\nNote: This is general information. For specific legal advice, consult a qualified attorney.";
    } else if (lowerMessage.contains('divorce') || lowerMessage.contains('marriage') || lowerMessage.contains('custody') || lowerMessage.contains('family')) {
      return "In Pakistan, family law varies by religion. For Muslims, divorce can occur through Talaq (by husband), Khula (by wife), or mutual consent.\n\n**Divorce Process:**\n1. Notice sent to Union Council\n2. 90-day reconciliation period\n3. If unsuccessful, divorce becomes effective\n\n**Child Custody:**\n• Mother usually gets custody of young children\n• Father responsible for financial support\n• Court decides based on child's best interest\n\nNote: This is general information. For specific legal advice, consult a qualified family law attorney.";
    } else if (lowerMessage.contains('contract') || lowerMessage.contains('agreement') || lowerMessage.contains('breach')) {
      return "Under the Contract Act 1872, a valid contract in Pakistan requires:\n\n**Essential Elements:**\n• Offer and Acceptance\n• Consideration (something of value exchanged)\n• Legal Capacity (parties must be 18+, sound mind)\n• Free Consent (no coercion or fraud)\n• Legal Purpose\n\n**Breach of Contract Remedies:**\n• Damages (compensation)\n• Specific performance\n• Contract termination\n\nNote: This is general information. Consult a qualified attorney for specific advice.";
    } else if (lowerMessage.contains('property') || lowerMessage.contains('land') || lowerMessage.contains('rent') || lowerMessage.contains('lease')) {
      return "Property law in Pakistan covers ownership, transfer, and rental matters:\n\n**Property Transfer:**\n• Transfer through registered sale deed\n• Stamp duty and registration fees apply\n• Verify property in land records (Fard)\n\n**Rental/Tenancy:**\n• Written rent agreement recommended\n• Tenant rights protected under Rent Acts\n• Landlord cannot evict without proper notice\n\nNote: This is general information. Consult a qualified property lawyer.";
    } else if (lowerMessage.contains('criminal') || lowerMessage.contains('theft') || lowerMessage.contains('assault') || lowerMessage.contains('fir')) {
      return "Criminal law in Pakistan is governed by the Pakistan Penal Code (PPC) and Criminal Procedure Code (CrPC):\n\n**Your Rights if Accused:**\n• Right to remain silent\n• Right to legal counsel\n• Right to bail (in bailable offenses)\n• Presumption of innocence until proven guilty\n\n**Filing an FIR:**\n1. Report to nearest police station\n2. Police must register FIR under Section 154 CrPC\n3. Get a copy of the FIR\n\nSeek immediate legal counsel if involved in a criminal matter.";
    } else if (lowerMessage.contains('employment') || lowerMessage.contains('job') || lowerMessage.contains('salary') || lowerMessage.contains('worker')) {
      return "Employment law in Pakistan protects workers' rights:\n\n**Employee Rights:**\n• Written employment contract\n• Minimum wage (varies by province)\n• Annual leave (14 days minimum)\n• Sick leave (10 days minimum)\n• Overtime pay (double rate)\n\n**Termination:**\n• Notice period required (usually 30 days)\n• Severance pay for unfair dismissal\n\nNote: This is general information. Consult a qualified labour lawyer.";
    } else {
      return "I'd be happy to help with your legal question! I can provide information about:\n\n**Common Legal Topics:**\n• Family Law - divorce, custody, marriage\n• Criminal Law - FIR, rights, procedures\n• Contract Law - agreements, disputes\n• Property Law - buying, renting, ownership\n• Employment Law - worker rights, termination\n• Traffic Laws - violations, licenses\n\nCould you please tell me more about your legal concern?\n\nNote: This is general information. For specific legal advice, consult a qualified attorney.";
    }
  }

  void clearChat() {
    state = const LawBotState();
    _initializeChat();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final lawBotProvider = StateNotifierProvider<LawBotNotifier, LawBotState>((ref) {
  return LawBotNotifier();
});
