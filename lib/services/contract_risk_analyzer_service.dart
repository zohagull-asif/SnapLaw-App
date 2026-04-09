import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service for analyzing contract documents and assessing risk
/// Uses OpenAI GPT for document validation and risk assessment
class ContractRiskAnalyzerService {
  final String apiKey;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  ContractRiskAnalyzerService({required this.apiKey});

  /// Validates if a document is a valid legal/case document
  Future<DocumentValidationResult> validateDocument(String documentText) async {
    try {
      final prompt = '''
You are a legal document validator for Pakistani law.

Analyze the following document and determine if it is a valid legal case document.

Valid legal documents include:
- Contracts (sale agreements, lease agreements, employment contracts)
- Legal notices
- Court petitions
- Affidavits
- Powers of attorney
- Wills and testaments
- Partnership deeds
- Memorandum of understanding (MOU)
- Non-disclosure agreements (NDA)
- Service agreements
- Any document with legal clauses and obligations

Invalid documents:
- Random text
- Shopping lists
- Personal notes
- Non-legal content
- Gibberish

Document Text:
"""
${documentText.length > 3000 ? documentText.substring(0, 3000) + '...' : documentText}
"""

Respond ONLY in this JSON format:
{
  "isValid": true/false,
  "documentType": "Contract/Notice/Petition/etc" or "Invalid",
  "reason": "Brief explanation of why it is valid or invalid",
  "confidence": 0-100
}
''';

      final response = await _makeOpenAIRequest(prompt);
      return DocumentValidationResult.fromJson(jsonDecode(response));
    } catch (e) {
      print('❌ Error validating document: $e');
      return DocumentValidationResult(
        isValid: false,
        documentType: 'Error',
        reason: 'Error analyzing document: ${e.toString()}',
        confidence: 0,
      );
    }
  }

  /// Analyzes contract risk based on Pakistani law
  Future<ContractRiskAnalysis> analyzeContractRisk(String documentText) async {
    try {
      final prompt = '''
You are a Contract Risk Radar AI system specialized in Pakistani law.

Your purpose is to perform STRUCTURED CONTRACT RISK ASSESSMENT based on Pakistani legal standards and common contract risks in Pakistan.

You are NOT a lawyer and you do NOT provide legal advice.
You ONLY analyze and classify risk based on learned patterns.

IMPORTANT CONTEXT:
- Analyze contracts according to Pakistani Contract Act 1872
- Consider Pakistani legal standards and precedents
- Identify risks common in Pakistani business and legal environment
- Consider cultural and regional business practices

ANALYSIS PROCESS:

Step 1: Parse the contract
- Identify key clauses (liability, termination, payment, indemnity, governing law, compliance)
- Look for vague language, one-sided obligations, missing safeguards

Step 2: Identify risk categories
For each risk, classify as:
- Legal (contract enforceability, jurisdiction issues)
- Financial (payment terms, penalties, unlimited liability)
- Operational (delivery obligations, service level agreements)
- Compliance (regulatory requirements, tax implications)

Step 3: Assign overall risk level
- LOW: Balanced obligations, clear protections, standard Pakistani contract terms
- MEDIUM: Some risky clauses, partial ambiguity, needs attention
- HIGH: One-sided obligations, unlimited liability, missing critical clauses

Step 4: Pakistan-specific considerations
- Check compliance with Pakistani laws (Contract Act, Sale of Goods Act, etc.)
- Verify jurisdiction clauses mention Pakistani courts
- Check for stamp duty requirements
- Verify notarization requirements

OUTPUT FORMAT (JSON):
{
  "overallRiskLevel": "Low/Medium/High",
  "confidenceScore": 0-100,
  "riskSummary": "Concise explanation of overall risk",
  "detectedRisks": [
    {
      "clause": "Quote or describe the clause",
      "riskType": "Legal/Financial/Compliance/Operational",
      "riskLevel": "Low/Medium/High",
      "explanation": "Why this is risky"
    }
  ],
  "pakistaniLawCompliance": {
    "isCompliant": true/false,
    "issues": ["List of compliance issues if any"],
    "recommendations": ["Recommendations for compliance"]
  },
  "keyFindings": [
    "Key finding 1",
    "Key finding 2",
    "Key finding 3"
  ]
}

Contract Document:
"""
${documentText.length > 4000 ? documentText.substring(0, 4000) + '...' : documentText}
"""

Analyze this contract and respond ONLY with the JSON format above.
''';

      final response = await _makeOpenAIRequest(prompt, maxTokens: 2000);
      return ContractRiskAnalysis.fromJson(jsonDecode(response));
    } catch (e) {
      print('❌ Error analyzing contract risk: $e');
      return ContractRiskAnalysis.error(e.toString());
    }
  }

  /// Makes a request to OpenAI API
  Future<String> _makeOpenAIRequest(String prompt, {int maxTokens = 500}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a legal document analysis expert specializing in Pakistani law. Always respond with valid JSON only.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': maxTokens,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ OpenAI request failed: $e');
      rethrow;
    }
  }
}

/// Result of document validation
class DocumentValidationResult {
  final bool isValid;
  final String documentType;
  final String reason;
  final int confidence;

  DocumentValidationResult({
    required this.isValid,
    required this.documentType,
    required this.reason,
    required this.confidence,
  });

  factory DocumentValidationResult.fromJson(Map<String, dynamic> json) {
    return DocumentValidationResult(
      isValid: json['isValid'] as bool? ?? false,
      documentType: json['documentType'] as String? ?? 'Unknown',
      reason: json['reason'] as String? ?? 'No reason provided',
      confidence: json['confidence'] as int? ?? 0,
    );
  }
}

/// Contract risk analysis result
class ContractRiskAnalysis {
  final String overallRiskLevel;
  final int confidenceScore;
  final String riskSummary;
  final List<DetectedRisk> detectedRisks;
  final PakistaniLawCompliance? pakistaniLawCompliance;
  final List<String> keyFindings;
  final String? error;

  ContractRiskAnalysis({
    required this.overallRiskLevel,
    required this.confidenceScore,
    required this.riskSummary,
    required this.detectedRisks,
    this.pakistaniLawCompliance,
    required this.keyFindings,
    this.error,
  });

  factory ContractRiskAnalysis.fromJson(Map<String, dynamic> json) {
    return ContractRiskAnalysis(
      overallRiskLevel: json['overallRiskLevel'] as String? ?? 'Unknown',
      confidenceScore: json['confidenceScore'] as int? ?? 0,
      riskSummary: json['riskSummary'] as String? ?? 'No summary available',
      detectedRisks: (json['detectedRisks'] as List<dynamic>?)
              ?.map((e) => DetectedRisk.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pakistaniLawCompliance: json['pakistaniLawCompliance'] != null
          ? PakistaniLawCompliance.fromJson(
              json['pakistaniLawCompliance'] as Map<String, dynamic>)
          : null,
      keyFindings: (json['keyFindings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  factory ContractRiskAnalysis.error(String errorMessage) {
    return ContractRiskAnalysis(
      overallRiskLevel: 'Error',
      confidenceScore: 0,
      riskSummary: 'Error analyzing contract',
      detectedRisks: [],
      keyFindings: [],
      error: errorMessage,
    );
  }

  bool get hasError => error != null;

  Color get riskColor {
    switch (overallRiskLevel.toLowerCase()) {
      case 'low':
        return const Color(0xFF4CAF50); // Green
      case 'medium':
        return const Color(0xFFFFA726); // Orange
      case 'high':
        return const Color(0xFFE53935); // Red
      default:
        return const Color(0xFF9E9E9E); // Gray
    }
  }
}

/// Detected risk in the contract
class DetectedRisk {
  final String clause;
  final String riskType;
  final String riskLevel;
  final String explanation;

  DetectedRisk({
    required this.clause,
    required this.riskType,
    required this.riskLevel,
    required this.explanation,
  });

  factory DetectedRisk.fromJson(Map<String, dynamic> json) {
    return DetectedRisk(
      clause: json['clause'] as String? ?? 'Unknown clause',
      riskType: json['riskType'] as String? ?? 'Unknown',
      riskLevel: json['riskLevel'] as String? ?? 'Unknown',
      explanation: json['explanation'] as String? ?? 'No explanation',
    );
  }

  Color get riskColor {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFFFA726);
      case 'high':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Pakistani law compliance check
class PakistaniLawCompliance {
  final bool isCompliant;
  final List<String> issues;
  final List<String> recommendations;

  PakistaniLawCompliance({
    required this.isCompliant,
    required this.issues,
    required this.recommendations,
  });

  factory PakistaniLawCompliance.fromJson(Map<String, dynamic> json) {
    return PakistaniLawCompliance(
      isCompliant: json['isCompliant'] as bool? ?? false,
      issues: (json['issues'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
