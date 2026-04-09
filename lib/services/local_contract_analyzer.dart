import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'contract_risk_analyzer_service.dart';

/// Local contract analyzer using Kaggle dataset
/// No API calls, completely offline
class LocalContractAnalyzer {
  static List<ContractPattern>? _patterns;
  static bool _isLoaded = false;

  /// Load patterns from CSV dataset
  static Future<void> loadDataset() async {
    if (_isLoaded) return;

    try {
      print('📂 Loading contract patterns dataset...');
      final csvData = await rootBundle.loadString('assets/data/contracts_dataset.csv');

      final lines = csvData.split('\n');
      _patterns = [];

      // Skip header row
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;

        try {
          final parts = _parseCsvLine(lines[i]);
          if (parts.length >= 4) {
            _patterns!.add(ContractPattern(
              text: parts[0].trim(),
              riskLevel: parts[1].trim(),
              riskType: parts[2].trim(),
              explanation: parts[3].trim(),
            ));
          }
        } catch (e) {
          print('⚠️ Error parsing line $i: $e');
        }
      }

      _isLoaded = true;
      print('✅ Loaded ${_patterns!.length} contract patterns');
    } catch (e) {
      print('❌ Error loading dataset: $e');
      // If dataset not found, use built-in patterns
      _loadBuiltInPatterns();
    }
  }

  /// Parse CSV line handling quotes and commas
  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  /// Load built-in patterns if CSV not available
  static void _loadBuiltInPatterns() {
    print('📚 Loading built-in Pakistani law patterns...');
    _patterns = [
      // Termination Clauses
      ContractPattern(
        text: 'terminate at any time without notice',
        riskLevel: 'High',
        riskType: 'Legal',
        explanation: 'No notice period violates Pakistani employment norms (30-60 days required)',
      ),
      ContractPattern(
        text: 'terminate immediately',
        riskLevel: 'High',
        riskType: 'Legal',
        explanation: 'Immediate termination without cause is unfair under Pakistani Contract Act',
      ),
      ContractPattern(
        text: '30 days notice',
        riskLevel: 'Low',
        riskType: 'Legal',
        explanation: 'Standard notice period compliant with Pakistani labor laws',
      ),

      // Payment Clauses
      ContractPattern(
        text: 'payment to be decided',
        riskLevel: 'High',
        riskType: 'Financial',
        explanation: 'Vague payment terms are unenforceable under Pakistani Contract Act 1872',
      ),
      ContractPattern(
        text: 'as agreed later',
        riskLevel: 'High',
        riskType: 'Financial',
        explanation: 'Deferred terms create disputes, must be specified',
      ),
      ContractPattern(
        text: 'PKR',
        riskLevel: 'Low',
        riskType: 'Financial',
        explanation: 'Payment in Pakistani currency is appropriate',
      ),

      // Liability Clauses
      ContractPattern(
        text: 'unlimited liability',
        riskLevel: 'High',
        riskType: 'Financial',
        explanation: 'Unlimited liability is unfair and may not be enforceable in Pakistan',
      ),
      ContractPattern(
        text: 'liable for all damages',
        riskLevel: 'High',
        riskType: 'Financial',
        explanation: 'Overly broad liability creates excessive risk',
      ),
      ContractPattern(
        text: 'limited liability',
        riskLevel: 'Low',
        riskType: 'Legal',
        explanation: 'Reasonable limitation of liability is fair',
      ),

      // Jurisdiction Clauses
      ContractPattern(
        text: 'laws of pakistan',
        riskLevel: 'Low',
        riskType: 'Compliance',
        explanation: 'Proper jurisdiction for contracts executed in Pakistan',
      ),
      ContractPattern(
        text: 'pakistani courts',
        riskLevel: 'Low',
        riskType: 'Compliance',
        explanation: 'Appropriate forum for dispute resolution',
      ),
      ContractPattern(
        text: 'foreign jurisdiction',
        riskLevel: 'Medium',
        riskType: 'Compliance',
        explanation: 'Foreign courts may not be accessible for Pakistani parties',
      ),

      // Compliance
      ContractPattern(
        text: 'stamp duty',
        riskLevel: 'Low',
        riskType: 'Compliance',
        explanation: 'Mentions stamp duty requirements for Pakistani contracts',
      ),
      ContractPattern(
        text: 'contract act 1872',
        riskLevel: 'Low',
        riskType: 'Compliance',
        explanation: 'References fundamental Pakistani contract law',
      ),

      // Duration
      ContractPattern(
        text: 'indefinite period',
        riskLevel: 'Medium',
        riskType: 'Legal',
        explanation: 'No fixed duration may create uncertainty',
      ),
      ContractPattern(
        text: 'fixed term',
        riskLevel: 'Low',
        riskType: 'Legal',
        explanation: 'Clear duration provides certainty',
      ),
    ];

    _isLoaded = true;
    print('✅ Loaded ${_patterns!.length} built-in patterns');
  }

  /// Validate if document is a legal contract
  static Future<DocumentValidationResult> validateDocument(String text) async {
    await loadDataset();

    final lowerText = text.toLowerCase();

    // Check for legal keywords
    final legalKeywords = [
      'agreement', 'contract', 'party', 'parties', 'whereas',
      'terms', 'conditions', 'obligations', 'rights', 'shall',
      'herein', 'hereby', 'execute', 'witness', 'signed'
    ];

    int keywordCount = 0;
    for (final keyword in legalKeywords) {
      if (lowerText.contains(keyword)) keywordCount++;
    }

    final isValid = keywordCount >= 3;
    final confidence = ((keywordCount / legalKeywords.length) * 100).round();

    String documentType = 'Unknown';
    if (lowerText.contains('employment') || lowerText.contains('employee')) {
      documentType = 'Employment Contract';
    } else if (lowerText.contains('sale') || lowerText.contains('purchase')) {
      documentType = 'Sale Agreement';
    } else if (lowerText.contains('lease') || lowerText.contains('rent')) {
      documentType = 'Lease Agreement';
    } else if (lowerText.contains('service')) {
      documentType = 'Service Agreement';
    } else if (isValid) {
      documentType = 'Legal Contract';
    }

    return DocumentValidationResult(
      isValid: isValid,
      documentType: documentType,
      reason: isValid
          ? 'Document contains legal terminology and structure'
          : 'Document lacks legal contract characteristics',
      confidence: confidence,
    );
  }

  /// Analyze contract risk using local dataset
  static Future<ContractRiskAnalysis> analyzeContract(String documentText) async {
    await loadDataset();

    print('🔍 Analyzing contract with ${_patterns!.length} patterns...');

    final lowerText = documentText.toLowerCase();
    final detectedRisks = <DetectedRisk>[];
    int highRiskCount = 0;
    int mediumRiskCount = 0;
    int lowRiskCount = 0;

    // Match patterns against document
    for (final pattern in _patterns!) {
      if (lowerText.contains(pattern.text.toLowerCase())) {
        // Find the actual clause text
        final matchIndex = lowerText.indexOf(pattern.text.toLowerCase());
        final clauseStart = (matchIndex - 50).clamp(0, documentText.length);
        final clauseEnd = (matchIndex + pattern.text.length + 50).clamp(0, documentText.length);
        final clause = documentText.substring(clauseStart, clauseEnd).trim();

        detectedRisks.add(DetectedRisk(
          clause: clause.length > 100 ? clause.substring(0, 100) + '...' : clause,
          riskType: pattern.riskType,
          riskLevel: pattern.riskLevel,
          explanation: pattern.explanation,
        ));

        // Count risk levels
        switch (pattern.riskLevel.toLowerCase()) {
          case 'high':
            highRiskCount++;
            break;
          case 'medium':
            mediumRiskCount++;
            break;
          case 'low':
            lowRiskCount++;
            break;
        }
      }
    }

    // Determine overall risk level
    String overallRisk;
    int confidence;

    if (highRiskCount >= 3) {
      overallRisk = 'High';
      confidence = 85 + (highRiskCount * 2).clamp(0, 15);
    } else if (highRiskCount >= 1 || mediumRiskCount >= 3) {
      overallRisk = 'Medium';
      confidence = 70 + (mediumRiskCount * 3).clamp(0, 25);
    } else {
      overallRisk = 'Low';
      confidence = 60 + (lowRiskCount * 5).clamp(0, 35);
    }

    // Check Pakistani law compliance
    final compliance = _checkPakistaniCompliance(lowerText);

    // Generate risk summary
    final summary = _generateRiskSummary(
      highRiskCount,
      mediumRiskCount,
      lowRiskCount,
      detectedRisks.length,
    );

    // Generate key findings
    final findings = _generateKeyFindings(detectedRisks, compliance);

    print('✅ Analysis complete: $overallRisk risk with $confidence% confidence');
    print('📊 Found ${detectedRisks.length} risk factors');

    return ContractRiskAnalysis(
      overallRiskLevel: overallRisk,
      confidenceScore: confidence,
      riskSummary: summary,
      detectedRisks: detectedRisks,
      pakistaniLawCompliance: compliance,
      keyFindings: findings,
    );
  }

  /// Check Pakistani law compliance
  static PakistaniLawCompliance _checkPakistaniCompliance(String text) {
    final issues = <String>[];
    final recommendations = <String>[];

    // Check for Pakistani jurisdiction
    if (!text.contains('pakistan') && !text.contains('pakistani')) {
      issues.add('No reference to Pakistani jurisdiction');
      recommendations.add('Add clause: "This agreement is governed by the laws of Pakistan"');
    }

    // Check for stamp duty
    if (!text.contains('stamp') && !text.contains('duty')) {
      issues.add('No mention of stamp duty requirements');
      recommendations.add('Include stamp duty clause as per Stamp Act 1899');
    }

    // Check for dispute resolution
    if (!text.contains('arbitration') && !text.contains('dispute') && !text.contains('court')) {
      issues.add('No dispute resolution mechanism specified');
      recommendations.add('Add arbitration or court jurisdiction clause');
    }

    // Check for Pakistani Contract Act reference
    if (!text.contains('contract act')) {
      recommendations.add('Consider referencing Contract Act 1872');
    }

    final isCompliant = issues.isEmpty;

    return PakistaniLawCompliance(
      isCompliant: isCompliant,
      issues: issues,
      recommendations: recommendations,
    );
  }

  /// Generate risk summary text
  static String _generateRiskSummary(int high, int medium, int low, int total) {
    if (high >= 3) {
      return 'This contract contains multiple high-risk clauses ($high identified) that could lead to serious legal or financial problems. Immediate legal review recommended.';
    } else if (high >= 1) {
      return 'Contract has $high high-risk clause(s) and $medium medium-risk clause(s). These issues should be addressed before signing.';
    } else if (medium >= 2) {
      return 'Contract has $medium medium-risk issues that need attention. Consider legal consultation to address these concerns.';
    } else if (total > 0) {
      return 'Contract appears relatively balanced with $low favorable clauses identified. Minor improvements may still be beneficial.';
    } else {
      return 'Limited analysis possible. Contract may need more specific legal clauses for comprehensive review.';
    }
  }

  /// Generate key findings
  static List<String> _generateKeyFindings(
    List<DetectedRisk> risks,
    PakistaniLawCompliance compliance,
  ) {
    final findings = <String>[];

    // High-risk findings
    final highRisks = risks.where((r) => r.riskLevel.toLowerCase() == 'high').toList();
    if (highRisks.isNotEmpty) {
      findings.add('${highRisks.length} high-risk clause(s) identified requiring immediate attention');
    }

    // Compliance findings
    if (!compliance.isCompliant) {
      findings.add('${compliance.issues.length} Pakistani law compliance issue(s) detected');
    } else {
      findings.add('Contract appears compliant with basic Pakistani legal requirements');
    }

    // Risk type distribution
    final riskTypes = risks.map((r) => r.riskType).toSet();
    if (riskTypes.isNotEmpty) {
      findings.add('Risks identified across ${riskTypes.length} categories: ${riskTypes.join(", ")}');
    }

    // Recommendations count
    if (compliance.recommendations.isNotEmpty) {
      findings.add('${compliance.recommendations.length} improvement(s) recommended');
    }

    return findings;
  }
}

/// Pattern from dataset
class ContractPattern {
  final String text;
  final String riskLevel;
  final String riskType;
  final String explanation;

  ContractPattern({
    required this.text,
    required this.riskLevel,
    required this.riskType,
    required this.explanation,
  });
}
