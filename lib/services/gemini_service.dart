import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static bool get isConfigured => _apiKey.isNotEmpty;

  static Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? systemPrompt,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY not configured in .env file');
    }

    final messages = <Map<String, dynamic>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    if (conversationHistory != null) {
      for (final msg in conversationHistory) {
        messages.add({
          'role': msg['role'] == 'assistant' ? 'assistant' : 'user',
          'content': msg['content'] ?? '',
        });
      }
    }

    messages.add({'role': 'user', 'content': message});

    final body = {
      'model': 'llama-3.3-70b-versatile',
      'messages': messages,
      'max_tokens': 2048,
      'temperature': 0.7,
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('Request timed out. Check internet connection.'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else if (response.statusCode == 401) {
      throw Exception('Invalid Groq API key. Check GROQ_API_KEY in .env');
    } else if (response.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 3));
      final retry = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));
      if (retry.statusCode == 200) {
        final data = jsonDecode(retry.body);
        return data['choices'][0]['message']['content'] as String;
      }
      throw Exception('Rate limit hit. Please wait a moment.');
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Groq API error: ${error['error']?['message'] ?? response.statusCode}');
    }
  }

  static Future<String> sendJsonMessage({
    required String prompt,
    int maxTokens = 2000,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY not configured in .env file');
    }

    final body = {
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': maxTokens,
      'temperature': 0.3,
      'response_format': {'type': 'json_object'},
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Groq API error: ${error['error']?['message'] ?? response.statusCode}');
    }
  }

  static String get legalDisclaimer =>
      'This information is for general educational purposes only and does not constitute legal advice.';
}
