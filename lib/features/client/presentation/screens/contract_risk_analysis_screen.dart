import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../services/contract_risk_analyzer_service.dart';

class ContractRiskAnalysisScreen extends StatelessWidget {
  final ContractRiskAnalysis analysis;
  final String documentName;

  const ContractRiskAnalysisScreen({
    super.key,
    required this.analysis,
    required this.documentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Risk Analysis'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Name
            _buildDocumentHeader(),
            const SizedBox(height: 24),

            // Overall Risk Level Card
            _buildOverallRiskCard(),
            const SizedBox(height: 24),

            // Risk Summary
            _buildRiskSummary(),
            const SizedBox(height: 24),

            // Pakistani Law Compliance
            if (analysis.pakistaniLawCompliance != null) ...[
              _buildComplianceSection(),
              const SizedBox(height: 24),
            ],

            // Detected Risks
            if (analysis.detectedRisks.isNotEmpty) ...[
              _buildDetectedRisksSection(),
              const SizedBox(height: 24),
            ],

            // Key Findings
            if (analysis.keyFindings.isNotEmpty) ...[
              _buildKeyFindingsSection(),
              const SizedBox(height: 24),
            ],

            // Disclaimer
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: AppColors.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Analyzed',
                  style: AppStyles.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  documentName,
                  style: AppStyles.subtitle1,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRiskCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            analysis.riskColor,
            analysis.riskColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: analysis.riskColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Risk Level',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            analysis.overallRiskLevel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Confidence: ${analysis.confidenceScore}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSummary() {
    return _buildSection(
      title: 'Risk Summary',
      icon: Icons.summarize,
      child: Text(
        analysis.riskSummary,
        style: AppStyles.bodyText1,
      ),
    );
  }

  Widget _buildComplianceSection() {
    final compliance = analysis.pakistaniLawCompliance!;

    return _buildSection(
      title: 'Pakistani Law Compliance',
      icon: Icons.gavel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compliance Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: compliance.isCompliant
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: compliance.isCompliant ? AppColors.success : AppColors.error,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  compliance.isCompliant ? Icons.check_circle : Icons.warning,
                  color: compliance.isCompliant ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    compliance.isCompliant
                        ? 'Compliant with Pakistani Law'
                        : 'Compliance Issues Detected',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: compliance.isCompliant ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Issues
          if (compliance.issues.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Issues:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...compliance.issues.map((issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(issue, style: AppStyles.bodyText2)),
                    ],
                  ),
                )),
          ],

          // Recommendations
          if (compliance.recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...compliance.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec, style: AppStyles.bodyText2)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildDetectedRisksSection() {
    return _buildSection(
      title: 'Detected Risks',
      icon: Icons.warning_amber,
      child: Column(
        children: analysis.detectedRisks.map((risk) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: risk.riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: risk.riskColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Risk Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: risk.riskColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        risk.riskLevel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        risk.riskType,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Clause
                const Text(
                  'Clause:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  risk.clause,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),

                // Explanation
                const Text(
                  'Risk Explanation:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  risk.explanation,
                  style: AppStyles.bodyText2,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyFindingsSection() {
    return _buildSection(
      title: 'Key Findings',
      icon: Icons.insights,
      child: Column(
        children: analysis.keyFindings.map((finding) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(finding, style: AppStyles.bodyText1),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disclaimer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This analysis is for informational purposes only and does NOT constitute legal advice. '
                  'Please consult with a qualified legal professional in Pakistan for proper legal guidance.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
