import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

/// Service for analyzing contract documents and assessing risk
/// Uses Gemini AI for document validation and risk assessment
class ContractRiskAnalyzerService {
  ContractRiskAnalyzerService();

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
  "isValid": true,
  "documentType": "Contract",
  "reason": "Brief explanation",
  "confidence": 85
}
''';

      final response = await GeminiService.sendJsonMessage(prompt: prompt, maxTokens: 500);
      return DocumentValidationResult.fromJson(jsonDecode(response));
    } catch (e) {
      print('Error validating document: $e');
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

Your purpose is to perform STRUCTURED CONTRACT RISK ASSESSMENT based on Pakistani legal standards.

You are NOT a lawyer and do NOT provide legal advice.
You ONLY analyze and classify risk based on learned patterns.

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
- Check compliance with Pakistani laws (Contract Act 1872, Sale of Goods Act, etc.)
- Verify jurisdiction clauses mention Pakistani courts
- Check for stamp duty requirements

OUTPUT FORMAT (JSON only, no markdown):
{
  "overallRiskLevel": "Low",
  "confidenceScore": 75,
  "riskSummary": "Concise explanation of overall risk",
  "detectedRisks": [
    {
      "clause": "Quote or describe the clause",
      "riskType": "Legal",
      "riskLevel": "Medium",
      "explanation": "Why this is risky"
    }
  ],
  "pakistaniLawCompliance": {
    "isCompliant": true,
    "issues": [],
    "recommendations": ["Recommendation 1"]
  },
  "keyFindings": [
    "Key finding 1",
    "Key finding 2"
  ]
}

Contract Document:
"""
${documentText.length > 4000 ? documentText.substring(0, 4000) + '...' : documentText}
"""

Analyze this contract and respond ONLY with the JSON format above.
''';

      final response = await GeminiService.sendJsonMessage(prompt: prompt, maxTokens: 2000);
      return ContractRiskAnalysis.fromJson(jsonDecode(response));
    } catch (e) {
      print('Error analyzing contract risk: $e');
      return ContractRiskAnalysis.error(e.toString());
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
      confidence: (json['confidence'] as num?)?.toInt() ?? 0,
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
      confidenceScore: (json['confidenceScore'] as num?)?.toInt() ?? 0,
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
