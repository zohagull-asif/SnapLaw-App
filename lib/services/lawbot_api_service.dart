import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service for communicating with the LawBot backend engine.
/// Handles Legal Q&A, Contract Simplifier, Bias Checker, and SafeSpace.
class LawBotApiService {
  static String get _baseUrl =>
      dotenv.env['RAG_BACKEND_URL'] ?? 'http://localhost:8000';

  /// Send a request to the LawBot backend.
  static Future<LawBotResponse> sendRequest({
    required String type,
    required String text,
    String language = 'en',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/lawbot'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'text': text,
        'language': language,
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LawBotResponse.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'LawBot request failed');
    }
  }

  /// Send a chat message to LawBot (Gemini-powered Pakistani law chatbot).
  static Future<LawBotChatResponse> sendChatMessage({
    required String message,
    String sessionId = 'default',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/lawbot-chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'session_id': sessionId,
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LawBotChatResponse.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'LawBot chat failed');
    }
  }

  /// Clear a LawBot chat session.
  static Future<void> clearChatSession({String sessionId = 'default'}) async {
    await http.post(
      Uri.parse('$_baseUrl/api/lawbot-chat/clear'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': '', 'session_id': sessionId}),
    ).timeout(const Duration(seconds: 10));
  }

  /// Send abuse detection request to the dedicated endpoint.
  static Future<AbuseDetectionResponse> detectAbuse({
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/detect-abuse'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AbuseDetectionResponse.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Abuse detection failed');
    }
  }

  /// Check if the backend is available.
  static Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ─── Response Model ───

class LawBotResponse {
  final String type;
  final String response;

  // Q&A specific
  final List<String> sources;
  final double confidence;
  final String category;
  final String categoryLabel;
  final List<String> sections;

  // Simplifier specific
  final List<Map<String, dynamic>> changesMade;
  final int totalChanges;
  final String summary;
  final String urduText;

  // Bias checker specific
  final String overallAssessment;
  final int totalIssues;
  final List<Map<String, dynamic>> findings;

  // SafeSpace specific
  final String title;
  final List<String> detectedCategories;
  final List<String> steps;
  final List<String> laws;
  final List<String> helplines;

  LawBotResponse({
    required this.type,
    required this.response,
    this.sources = const [],
    this.confidence = 0,
    this.category = '',
    this.categoryLabel = '',
    this.sections = const [],
    this.changesMade = const [],
    this.totalChanges = 0,
    this.summary = '',
    this.urduText = '',
    this.overallAssessment = '',
    this.totalIssues = 0,
    this.findings = const [],
    this.title = '',
    this.detectedCategories = const [],
    this.steps = const [],
    this.laws = const [],
    this.helplines = const [],
  });

  factory LawBotResponse.fromJson(Map<String, dynamic> json) {
    return LawBotResponse(
      type: json['type'] ?? '',
      response: json['response'] ?? '',
      sources: List<String>.from(json['sources'] ?? []),
      confidence: (json['confidence'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      categoryLabel: json['category_label'] ?? '',
      sections: List<String>.from(json['sections'] ?? []),
      changesMade: List<Map<String, dynamic>>.from(json['changes_made'] ?? []),
      totalChanges: json['total_changes'] ?? 0,
      summary: json['summary'] ?? '',
      urduText: json['urdu_text'] ?? '',
      overallAssessment: json['overall_assessment'] ?? '',
      totalIssues: json['total_issues'] ?? 0,
      findings: List<Map<String, dynamic>>.from(json['findings'] ?? []),
      title: json['title'] ?? '',
      detectedCategories: List<String>.from(json['detected_categories'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      laws: List<String>.from(json['laws'] ?? []),
      helplines: List<String>.from(json['helplines'] ?? []),
    );
  }
}

// ─── Abuse Detection Response Model ───

class AbuseDetectionResponse {
  final bool isAbusive;
  final String result;

  AbuseDetectionResponse({
    required this.isAbusive,
    required this.result,
  });

  factory AbuseDetectionResponse.fromJson(Map<String, dynamic> json) {
    return AbuseDetectionResponse(
      isAbusive: json['is_abusive'] ?? false,
      result: json['result'] ?? '',
    );
  }
}

// ─── LawBot Chat Response Model ───

class LawBotChatResponse {
  final String response;
  final String sessionId;

  LawBotChatResponse({
    required this.response,
    required this.sessionId,
  });

  factory LawBotChatResponse.fromJson(Map<String, dynamic> json) {
    return LawBotChatResponse(
      response: json['response'] ?? '',
      sessionId: json['session_id'] ?? 'default',
    );
  }
}
