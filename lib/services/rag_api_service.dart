import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

/// Service for communicating with the SnapLaw RAG Python backend.
/// Handles policy upload, contract analysis, and precedent search.
class RagApiService {
  static String get _baseUrl =>
      dotenv.env['RAG_BACKEND_URL'] ?? 'http://localhost:8000';

  // ==================== POLICY ENDPOINTS ====================

  /// Upload a company policy document for embedding and indexing.
  static Future<Map<String, dynamic>> uploadPolicy({
    required String userId,
    required String policyName,
    required PlatformFile file,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/policies/upload');
    final request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = userId;
    request.fields['policy_name'] = policyName;

    if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));
    } else if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: file.name,
      ));
    } else {
      throw Exception('File has no content');
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Policy upload failed');
    }
  }

  /// Get all policies for a user.
  static Future<List<Map<String, dynamic>>> getUserPolicies(
      String userId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/policies/$userId'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['policies'] ?? []);
    } else {
      throw Exception('Failed to fetch policies');
    }
  }

  /// Delete a policy.
  static Future<void> deletePolicy(String policyId, String userId) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/api/policies/$policyId?user_id=$userId'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete policy');
    }
  }

  /// Load user's policy index into FAISS (call on login or before analysis).
  static Future<void> loadUserIndex(String userId) async {
    await http
        .post(Uri.parse('$_baseUrl/api/policies/load-index/$userId'))
        .timeout(const Duration(seconds: 30));
  }

  // ==================== CONTRACT ANALYSIS ENDPOINTS ====================

  /// Analyze a contract document against Pakistani law using RAG.
  static Future<ContractAnalysisResponse> analyzeContract({
    required PlatformFile file,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/contracts/analyze');
    final request = http.MultipartRequest('POST', uri);

    if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));
    } else if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: file.name,
      ));
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 180), // RAG takes time
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ContractAnalysisResponse.fromJson(data['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Contract analysis failed');
    }
  }

  /// Analyze contract text directly (paste mode).
  static Future<ContractAnalysisResponse> analyzeContractText({
    required String contractText,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/contracts/analyze-text'),
      body: {
        'contract_text': contractText,
      },
    ).timeout(const Duration(seconds: 180));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ContractAnalysisResponse.fromJson(data['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Contract analysis failed');
    }
  }

  // ==================== PRECEDENT SEARCH ENDPOINTS ====================

  /// Search legal precedents using semantic similarity.
  static Future<PrecedentSearchResponse> searchPrecedents({
    required String query,
    int topK = 5,
    String? courtFilter,
    String? yearFilter,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/precedents/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'top_k': topK,
        'court_filter': courtFilter,
        'year_filter': yearFilter,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PrecedentSearchResponse.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Precedent search failed');
    }
  }

  /// Get all available cases.
  static Future<List<Map<String, dynamic>>> getAllCases() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/precedents/cases'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['cases'] ?? []);
    } else {
      throw Exception('Failed to fetch cases');
    }
  }

  // ==================== HEALTH CHECK ====================

  /// Check if the RAG backend is running.
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

// ==================== RESPONSE MODELS ====================

class ContractAnalysisResponse {
  final String overallRisk;
  final int riskScore;
  final String complianceSummary;
  final int totalClauses;
  final List<ClauseAnalysis> clauses;
  final String? contractTextPreview;

  ContractAnalysisResponse({
    required this.overallRisk,
    required this.riskScore,
    required this.complianceSummary,
    required this.totalClauses,
    required this.clauses,
    this.contractTextPreview,
  });

  factory ContractAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return ContractAnalysisResponse(
      overallRisk: json['overall_risk'] ?? 'Unknown',
      riskScore: json['risk_score'] ?? 0,
      complianceSummary: json['compliance_summary'] ?? '',
      totalClauses: json['total_clauses'] ?? 0,
      clauses: (json['clauses'] as List<dynamic>?)
              ?.map((c) => ClauseAnalysis.fromJson(c))
              .toList() ??
          [],
      contractTextPreview: json['contract_text_preview'],
    );
  }
}

class ClauseAnalysis {
  final String clauseText;
  final String clauseType;
  final String status; // Compliant, Violation, Risky, Not Covered
  final String riskLevel;
  final String explanation;
  final String relevantPolicy;
  final String recommendation;
  final String relevantLaw;
  final String legalConcern;
  final String suggestedFix;
  final double similarityScore;
  final List<ClausePrecedent> precedents;

  ClauseAnalysis({
    required this.clauseText,
    required this.clauseType,
    required this.status,
    required this.riskLevel,
    required this.explanation,
    required this.relevantPolicy,
    required this.recommendation,
    this.relevantLaw = '',
    this.legalConcern = '',
    this.suggestedFix = '',
    required this.similarityScore,
    this.precedents = const [],
  });

  factory ClauseAnalysis.fromJson(Map<String, dynamic> json) {
    return ClauseAnalysis(
      clauseText: json['clause_text'] ?? '',
      clauseType: json['clause_type'] ?? 'General',
      status: json['status'] ?? 'Unknown',
      riskLevel: json['risk_level'] ?? 'Unknown',
      explanation: json['explanation'] ?? '',
      relevantPolicy: json['relevant_policy'] ?? '',
      recommendation: json['recommendation'] ?? '',
      relevantLaw: json['relevant_law'] ?? '',
      legalConcern: json['legal_concern'] ?? '',
      suggestedFix: json['suggested_fix'] ?? '',
      similarityScore: (json['similarity_score'] ?? 0).toDouble(),
      precedents: (json['precedents'] as List<dynamic>?)
              ?.map((p) => ClausePrecedent.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class ClausePrecedent {
  final String caseTitle;
  final String court;
  final String year;
  final String summary;
  final String decision;
  final List<String> keywords;
  final String category;
  final String caseNumber;
  final double similarityScore;
  final String reason;

  ClausePrecedent({
    required this.caseTitle,
    required this.court,
    required this.year,
    required this.summary,
    required this.decision,
    required this.keywords,
    required this.category,
    required this.caseNumber,
    required this.similarityScore,
    this.reason = '',
  });

  factory ClausePrecedent.fromJson(Map<String, dynamic> json) {
    return ClausePrecedent(
      caseTitle: json['case_title'] ?? '',
      court: json['court'] ?? '',
      year: json['year'] ?? '',
      summary: json['summary'] ?? '',
      decision: json['decision'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
      category: json['category'] ?? '',
      caseNumber: json['case_number'] ?? '',
      similarityScore: (json['similarity_score'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
    );
  }
}

class PrecedentSearchResponse {
  final String query;
  final int resultCount;
  final List<PrecedentResult> results;

  PrecedentSearchResponse({
    required this.query,
    required this.resultCount,
    required this.results,
  });

  factory PrecedentSearchResponse.fromJson(Map<String, dynamic> json) {
    return PrecedentSearchResponse(
      query: json['query'] ?? '',
      resultCount: json['result_count'] ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((r) => PrecedentResult.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class PrecedentResult {
  final String id;
  final String title;
  final String caseNumber;
  final String court;
  final String year;
  final String summary;
  final String judgment;
  final String decision;
  final List<String> keywords;
  final String category;
  final double relevanceScore;
  final String reason;

  PrecedentResult({
    required this.id,
    required this.title,
    required this.caseNumber,
    required this.court,
    required this.year,
    required this.summary,
    required this.judgment,
    required this.decision,
    required this.keywords,
    required this.category,
    required this.relevanceScore,
    this.reason = '',
  });

  factory PrecedentResult.fromJson(Map<String, dynamic> json) {
    return PrecedentResult(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      caseNumber: json['case_number'] ?? '',
      court: json['court'] ?? '',
      year: json['year'] ?? '',
      summary: json['summary'] ?? '',
      judgment: json['judgment'] ?? json['decision'] ?? '',
      decision: json['decision'] ?? json['judgment'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
      category: json['category'] ?? '',
      relevanceScore: (json['relevance_score'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
    );
  }
}
