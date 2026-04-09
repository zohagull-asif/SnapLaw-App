class ContractAnalysisModel {
  final String id;
  final String contractName;
  final String uploadedAt;
  final RiskLevel overallRisk;
  final List<RiskClause> riskyFields;
  final double riskScore;
  final String summary;

  const ContractAnalysisModel({
    required this.id,
    required this.contractName,
    required this.uploadedAt,
    required this.overallRisk,
    required this.riskyFields,
    required this.riskScore,
    required this.summary,
  });

  factory ContractAnalysisModel.fromJson(Map<String, dynamic> json) {
    return ContractAnalysisModel(
      id: json['id'] as String,
      contractName: json['contract_name'] as String,
      uploadedAt: json['uploaded_at'] as String,
      overallRisk: RiskLevel.values.firstWhere(
        (e) => e.name == json['overall_risk'],
        orElse: () => RiskLevel.medium,
      ),
      riskyFields: (json['risky_fields'] as List<dynamic>)
          .map((e) => RiskClause.fromJson(e as Map<String, dynamic>))
          .toList(),
      riskScore: (json['risk_score'] as num).toDouble(),
      summary: json['summary'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_name': contractName,
      'uploaded_at': uploadedAt,
      'overall_risk': overallRisk.name,
      'risky_fields': riskyFields.map((e) => e.toJson()).toList(),
      'risk_score': riskScore,
      'summary': summary,
    };
  }
}

class RiskClause {
  final String clauseType;
  final String description;
  final RiskLevel riskLevel;
  final String recommendation;
  final String? extractedText;

  const RiskClause({
    required this.clauseType,
    required this.description,
    required this.riskLevel,
    required this.recommendation,
    this.extractedText,
  });

  factory RiskClause.fromJson(Map<String, dynamic> json) {
    return RiskClause(
      clauseType: json['clause_type'] as String,
      description: json['description'] as String,
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['risk_level'],
        orElse: () => RiskLevel.medium,
      ),
      recommendation: json['recommendation'] as String,
      extractedText: json['extracted_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clause_type': clauseType,
      'description': description,
      'risk_level': riskLevel.name,
      'recommendation': recommendation,
      'extracted_text': extractedText,
    };
  }
}

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}
