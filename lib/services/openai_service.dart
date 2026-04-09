import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  /// Send a chat message to OpenAI GPT and get a response
  static Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      print('🤖 LawBot: Starting ChatGPT request...');
      print('📊 API Key configured: ${_apiKey.isNotEmpty}');
      print('💬 User message: $message');

      if (_apiKey.isEmpty) {
        print('⚠️ No API key - using offline mode');
        throw Exception('OpenAI API key not configured');
      }

      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': '''You are LawBot, an expert AI legal assistant for SnapLaw, specializing in Pakistani law.

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
✅ Answer questions directly and comprehensively
✅ Use bullet points and clear formatting
✅ Provide specific details, procedures, and requirements
✅ Include relevant legal citations when helpful
✅ Give practical examples from Pakistani context
✅ Keep responses 3-6 paragraphs (detailed but readable)
❌ Don't refuse to answer legal questions
❌ Don't give overly cautious generic responses
❌ Only add brief disclaimer at the end if needed

Remember: You're an expert on Pakistani law helping users understand their legal rights and options.'''
        },
      ];

      // Add conversation history if provided
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        messages.addAll(conversationHistory);
      }

      // Add current user message
      messages.add({
        'role': 'user',
        'content': message,
      });

      print('📡 Sending request to ChatGPT API...');
      print('🔧 Model: gpt-3.5-turbo');

      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': messages,
        'temperature': 0.8, // More creative responses
        'max_tokens': 1000, // Longer, more detailed responses
        'top_p': 0.95,
        'frequency_penalty': 0.3, // Reduce repetition
        'presence_penalty': 0.2, // Encourage diverse topics
      };

      print('✅ Request prepared with ${messages.length} messages');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          print('⏱️ Request timed out after 45 seconds');
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('📨 Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final tokensUsed = data['usage']['total_tokens'];
        print('✅ ChatGPT response received successfully!');
        print('📊 Tokens used: $tokensUsed');
        print('📝 Response length: ${content.length} characters');
        return content.trim();
      } else if (response.statusCode == 401) {
        print('❌ Invalid API key error');
        throw Exception('Invalid OpenAI API key. Please check your .env file.');
      } else if (response.statusCode == 429) {
        print('⚠️ Rate limit exceeded');
        throw Exception('API rate limit exceeded. Please try again in a few moments.');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        print('❌ Bad request: ${error['error']['message']}');
        throw Exception('API error: ${error['error']['message']}');
      } else {
        print('❌ API error - Status: ${response.statusCode}');
        print('📄 Response: ${response.body}');
        try {
          final error = jsonDecode(response.body);
          throw Exception('API error: ${error['error']['message'] ?? 'Unknown error'}');
        } catch (e) {
          throw Exception('API error: Status ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Exception caught: $e');
      print('🔍 Exception type: ${e.runtimeType}');

      // Re-throw known errors
      if (e.toString().contains('API') ||
          e.toString().contains('timeout') ||
          e.toString().contains('Invalid') ||
          e.toString().contains('rate limit') ||
          e.toString().contains('not configured')) {
        rethrow;
      }

      // Generic network error
      throw Exception('Network error. Please check your internet connection.');
    }
  }

  /// Get a streaming response from OpenAI (for future implementation)
  static Stream<String> sendMessageStream({
    required String message,
    List<Map<String, String>>? conversationHistory,
  }) async* {
    // This can be implemented later for real-time streaming responses
    final response = await sendMessage(
      message: message,
      conversationHistory: conversationHistory,
    );
    yield response;
  }

  /// Check if OpenAI API key is configured
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Get a legal disclaimer message
  static String get legalDisclaimer =>
      'This information is for general educational purposes only and does not constitute legal advice. For specific legal guidance, please consult with a licensed attorney.';
}
