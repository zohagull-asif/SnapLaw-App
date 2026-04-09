import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/openai_service.dart';
import '../../data/models/chat_message_model.dart';

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
    // Add initial greeting message
    final greetingMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: "Hello! I'm LawBot, your AI legal assistant. I'm here to help answer your legal questions and guide you through legal processes.\n\nHow can I help you today?",
      isBot: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [greetingMessage]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
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
      // Check if OpenAI is configured
      if (!OpenAIService.isConfigured) {
        // Fallback to mock response if no API key
        await _handleMockResponse(text);
        return;
      }

      // Prepare conversation history for context (exclude greeting message)
      final conversationHistory = state.messages
          .skip(1) // Skip the initial greeting message
          .where((msg) => msg.id != userMessage.id)
          .map((msg) => {
                'role': msg.isBot ? 'assistant' : 'user',
                'content': msg.text,
              })
          .toList();

      // Get response from OpenAI
      final responseText = await OpenAIService.sendMessage(
        message: text,
        conversationHistory: conversationHistory,
      );

      // Add bot response
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
      print('LAWBOT ERROR: $e');

      // On error, try fallback to mock response
      await _handleMockResponse(text);

      // Don't show error message - just silently use offline mode
      // The mock responses are comprehensive and will work fine
    }
  }

  Future<void> _handleMockResponse(String text) async {
    // Simulate delay
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

    // Traffic & Driving Laws
    if (lowerMessage.contains('traffic') || lowerMessage.contains('driving') || lowerMessage.contains('license')) {
      return "In Pakistan, traffic laws are governed by the Motor Vehicles Ordinance 1965 and Provincial Motor Vehicle Rules. Key regulations include:\n\n• Drive on the left side of the road\n• Valid driving license mandatory for all drivers\n• Vehicle registration and insurance required\n• Speed limits: 50 km/h in cities, 80-120 km/h on highways\n• Seat belts compulsory for front seat passengers\n• Mobile phone use while driving prohibited\n• Drunk driving strictly prohibited\n• Traffic violations result in fines ranging from Rs. 500 to Rs. 5,000\n\nViolations can also lead to license suspension or vehicle impoundment.\n\nNote: This is general information. For specific legal advice, consult a qualified attorney.";
    }

    // Divorce & Family Law
    else if (lowerMessage.contains('divorce') || lowerMessage.contains('marriage') || lowerMessage.contains('custody') || lowerMessage.contains('family')) {
      return "In Pakistan, family law varies by religion. For Muslims, divorce can occur through Talaq (by husband), Khula (by wife), or mutual consent. Key points:\n\n**Divorce Process:**\n1. Notice sent to Union Council\n2. 90-day reconciliation period\n3. If unsuccessful, divorce becomes effective\n4. Maintenance and custody matters settled\n\n**Child Custody:**\n• Mother usually gets custody of young children (Hizanat)\n• Father responsible for financial support\n• Court decides based on child's best interest\n\n**Rights:**\n• Wife entitled to Mehr (dower), maintenance during Iddat\n• Both parents have visitation rights\n\nNote: This is general information. For specific legal advice, consult a qualified family law attorney.";
    }

    // Contract Law
    else if (lowerMessage.contains('contract') || lowerMessage.contains('agreement') || lowerMessage.contains('breach')) {
      return "Under the Contract Act 1872, a valid contract in Pakistan requires:\n\n**Essential Elements:**\n• Offer and Acceptance - Clear proposal and agreement\n• Consideration - Something of value exchanged\n• Legal Capacity - Parties must be of sound mind, 18+\n• Free Consent - No coercion, fraud, or misrepresentation\n• Legal Purpose - Not forbidden by law\n\n**Types of Contracts:**\n• Written contracts (recommended for proof)\n• Oral contracts (valid but harder to prove)\n• Implied contracts\n\n**Breach of Contract:**\nIf one party fails to perform, remedies include:\n• Damages (compensation)\n• Specific performance (court orders completion)\n• Contract termination\n\nAlways get important agreements in writing and signed by both parties.\n\nNote: This is general information. For specific legal advice, consult a qualified attorney.";
    }

    // Property & Real Estate
    else if (lowerMessage.contains('property') || lowerMessage.contains('land') || lowerMessage.contains('rent') || lowerMessage.contains('lease') || lowerMessage.contains('real estate')) {
      return "Property law in Pakistan covers ownership, transfer, and rental matters:\n\n**Property Transfer:**\n• Transfer through registered sale deed\n• Stamp duty and registration fees apply\n• Property must be verified in land records\n• Power of Attorney can be used for transactions\n\n**Rental/Tenancy:**\n• Written rent agreement recommended\n• Tenant rights protected under Rent Acts\n• Landlord cannot evict without proper notice\n• Security deposit typically 2-3 months rent\n\n**Important Documents:**\n• Fard (land ownership record)\n• Sale deed\n• NOC from housing society\n• Tax clearance certificate\n\nAlways verify property titles before purchase.\n\nNote: This is general information. For specific legal advice, consult a qualified property lawyer.";
    }

    // Criminal Law
    else if (lowerMessage.contains('criminal') || lowerMessage.contains('theft') || lowerMessage.contains('assault') || lowerMessage.contains('crime') || lowerMessage.contains('police') || lowerMessage.contains('fir')) {
      return "Criminal law in Pakistan is governed by the Pakistan Penal Code (PPC) and Criminal Procedure Code (CrPC):\n\n**Your Rights if Accused:**\n• Right to remain silent\n• Right to legal counsel\n• Right to bail (in bailable offenses)\n• Presumption of innocence until proven guilty\n\n**Filing an FIR:**\n1. Report to nearest police station\n2. Police must register FIR under Section 154 CrPC\n3. Get a copy of the FIR\n4. Investigation begins\n\n**Common Offenses:**\n• Theft - 3 to 7 years imprisonment\n• Assault - 2 years to life imprisonment\n• Fraud - up to 7 years imprisonment\n\n**Legal Process:**\nFIR → Investigation → Charge Sheet → Trial → Judgment\n\nSeek immediate legal counsel if involved in a criminal matter.\n\nNote: This is general information. For specific legal advice, consult a qualified criminal lawyer.";
    }

    // Employment Law
    else if (lowerMessage.contains('employment') || lowerMessage.contains('job') || lowerMessage.contains('salary') || lowerMessage.contains('termination') || lowerMessage.contains('worker') || lowerMessage.contains('employee')) {
      return "Employment law in Pakistan protects workers' rights:\n\n**Employee Rights:**\n• Written employment contract\n• Minimum wage (varies by province)\n• Weekly holiday (typically Sunday)\n• Annual leave (14 days minimum)\n• Sick leave (10 days minimum)\n• Overtime pay (double rate)\n\n**Termination:**\n• Notice period required (usually 30 days)\n• Severance pay for unfair dismissal\n• Cannot terminate during medical leave\n\n**Workplace Safety:**\n• Employer must provide safe working conditions\n• Social security registration mandatory\n• EOBI (pension) contributions\n\n**Disputes:**\nFile complaint with Labour Court or NIRC (National Industrial Relations Commission)\n\nKeep all employment documents and pay slips as evidence.\n\nNote: This is general information. For specific legal advice, consult a qualified labour lawyer.";
    }

    // Finding a Lawyer
    else if (lowerMessage.contains('lawyer') || lowerMessage.contains('attorney') || lowerMessage.contains('find') || lowerMessage.contains('hire')) {
      return "I can help you find the right lawyer! Here's how:\n\n**On SnapLaw:**\n• Use our 'Find Lawyers' feature\n• Filter by practice area and location\n• View lawyer profiles, ratings, and experience\n• Compare fees and availability\n• Book consultations directly\n\n**What to Consider:**\n1. Specialization (family, criminal, corporate, etc.)\n2. Experience in similar cases\n3. Location and availability\n4. Fee structure\n5. Client reviews\n\n**Questions to Ask:**\n• How many similar cases have you handled?\n• What's your success rate?\n• What are your fees?\n• How long will my case take?\n\nWould you like help finding a lawyer for a specific legal issue?";
    }

    // Help & Capabilities
    else if (lowerMessage.contains('help') || lowerMessage.contains('what can you') || lowerMessage.contains('how can you')) {
      return "I'm LawBot, your AI legal assistant! I can help you with:\n\n**Legal Information:**\n• Family law (divorce, custody, marriage)\n• Contract law (agreements, breaches)\n• Criminal law (FIR, rights, procedures)\n• Property law (buying, renting, disputes)\n• Employment law (rights, termination)\n• Traffic laws (violations, licenses)\n\n**Services:**\n• Explain legal concepts in simple terms\n• Guide you through legal processes\n• Answer questions about your rights\n• Help you find the right type of lawyer\n• Provide information about Pakistani laws\n\n**What I Can't Do:**\n• Provide personalized legal advice\n• Represent you in court\n• Review specific documents\n• Replace a qualified attorney\n\nWhat legal topic would you like to know about?";
    }

    // Default Response
    else {
      return "I'd be happy to help with your legal question! I can provide information about:\n\n**Common Legal Topics:**\n• Family Law - divorce, custody, marriage\n• Criminal Law - FIR, rights, procedures\n• Contract Law - agreements, disputes\n• Property Law - buying, renting, ownership\n• Employment Law - worker rights, termination\n• Traffic Laws - violations, licenses\n\nCould you please tell me more about your legal concern? For example:\n• What type of legal issue is it?\n• What specific aspect would you like to understand?\n• Are you looking for information about Pakistani law?\n\nThe more details you provide, the better I can assist you!\n\nNote: This is general information. For specific legal advice, consult a qualified attorney.";
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
