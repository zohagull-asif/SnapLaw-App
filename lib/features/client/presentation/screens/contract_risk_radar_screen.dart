import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/rag_api_service.dart';

class ContractRiskRadarScreen extends ConsumerStatefulWidget {
  const ContractRiskRadarScreen({super.key});

  @override
  ConsumerState<ContractRiskRadarScreen> createState() =>
      _ContractRiskRadarScreenState();
}

class _ContractRiskRadarScreenState
    extends ConsumerState<ContractRiskRadarScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  bool _checkingBackend = true;
  bool _backendAvailable = false;
  ContractAnalysisResponse? _analysis;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _checkBackend();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    final available = await RagApiService.isBackendAvailable();
    setState(() {
      _backendAvailable = available;
      _checkingBackend = false;
    });
  }

  Future<void> _pickAndAnalyzeContract() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _isAnalyzing = true;
        _errorMessage = null;
      });
      _animationController.repeat();

      try {
        // Analyze contract via RAG backend (uses preloaded Pakistani law knowledge base)
        final analysis = await RagApiService.analyzeContract(
          file: result.files.first,
        );

        setState(() {
          _isAnalyzing = false;
          _analysis = analysis;
        });
      } catch (e) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
      _animationController.stop();
    }
  }

  String _sanitizeText(String text) {
    return text
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2026', '...');
  }

  Future<void> _downloadReport() async {
    if (_analysis == null) return;

    final pdf = pw.Document();
    final analysis = _analysis!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('SnapLaw - Contract Risk Analysis Report',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      'Generated on: ${DateTime.now().toString().substring(0, 19)}',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Risk Score Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Overall Risk',
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text(analysis.overallRisk.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: analysis.overallRisk == 'High'
                                  ? PdfColors.red
                                  : analysis.overallRisk == 'Medium'
                                      ? PdfColors.orange
                                      : PdfColors.green)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Risk Score',
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('${analysis.riskScore}/100',
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Compliance Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Compliance Summary',
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(_sanitizeText(analysis.complianceSummary),
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('${analysis.totalClauses} clauses analyzed',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Clause Analysis Header
            pw.Text('Clause-by-Clause Analysis',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // Each clause
            ...analysis.clauses.asMap().entries.map((entry) {
              final i = entry.key;
              final clause = entry.value;
              final isViolation = clause.status == 'Violation';
              final isRisky = clause.status == 'Risky';

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: isViolation
                        ? PdfColors.red300
                        : isRisky
                            ? PdfColors.orange300
                            : PdfColors.green300,
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Clause header
                    pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            'Clause ${i + 1}: ${clause.clauseType}',
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold)),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: isViolation
                                ? PdfColors.red100
                                : isRisky
                                    ? PdfColors.orange100
                                    : PdfColors.green100,
                            borderRadius:
                                pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                              '${clause.status} | ${clause.riskLevel}',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: isViolation
                                      ? PdfColors.red
                                      : isRisky
                                          ? PdfColors.orange
                                          : PdfColors.green)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),

                    // Clause text
                    pw.Text('Clause Text:',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700)),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(_sanitizeText(clause.clauseText),
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey800)),
                    ),
                    pw.SizedBox(height: 6),

                    // Legal concern
                    if (clause.legalConcern.isNotEmpty &&
                        clause.legalConcern != 'No significant legal concerns identified.') ...[
                      pw.Text('Legal Concern:',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red)),
                      pw.Text(_sanitizeText(clause.legalConcern),
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                    ],

                    // Relevant law
                    if (clause.relevantLaw.isNotEmpty &&
                        clause.relevantLaw != 'None') ...[
                      pw.Text('Relevant Law:',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.purple)),
                      pw.Text(_sanitizeText(clause.relevantLaw),
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                    ],

                    // Suggested fix
                    if (clause.suggestedFix.isNotEmpty &&
                        clause.suggestedFix != 'No change needed') ...[
                      pw.Text('Suggested Fix:',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green)),
                      pw.Text(_sanitizeText(clause.suggestedFix),
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontStyle: pw.FontStyle.italic)),
                    ],
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'This report was generated by SnapLaw using LegalBERT + FAISS RAG pipeline. '
              'It is for informational purposes only and does not constitute legal advice.',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey500),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'SnapLaw_Risk_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Risk Radar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: const [],
      ),
      body: _checkingBackend
          ? const Center(child: CircularProgressIndicator())
          : !_backendAvailable
              ? _buildBackendUnavailable()
              : _analysis == null
                  ? _buildUploadSection()
                  : _buildAnalysisResults(),
    );
  }

  Widget _buildBackendUnavailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'RAG Backend Unavailable',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The AI analysis server is not running. Please start the Python backend server.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _checkingBackend = true);
                _checkBackend();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: _isAnalyzing
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLottieOrFallback(
                          'assets/lottie/ai_analyzing.json',
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                          width: 200,
                          height: 200,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Analyzing with LegalBERT + RAG...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : _buildLottieOrFallback(
                      'assets/lottie/document_upload.json',
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                      width: 200,
                      height: 200,
                    ),
            ),
            const SizedBox(height: 32),
            const Text(
              'RAG-Powered Contract Analysis',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload your contract and our AI will analyze it against Pakistani law using LegalBERT embeddings and RAG',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            _buildFeaturesList(),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _pickAndAnalyzeContract,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Contract'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supports: PDF, TXT',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureItem(
            Icons.gavel,
            'Pakistani Law Compliance',
            'Check against Contract Act, Labour Laws & more',
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Icons.warning_amber_rounded,
            'Clause Detection',
            'Penalties, confidentiality, obligations',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Icons.psychology,
            'LegalBERT + RAG',
            'Transformer-based analysis pipeline',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Icons.insights,
            'Risk Scoring',
            'Per-clause and overall risk assessment',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisResults() {
    final analysis = _analysis!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRiskScoreCard(analysis),
          const SizedBox(height: 16),
          _buildComplianceSummaryCard(analysis),
          const SizedBox(height: 20),
          const Text(
            'Clause-by-Clause Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...analysis.clauses.asMap().entries.map(
                (entry) => _buildClauseCard(entry.value, entry.key),
              ),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildRiskScoreCard(ContractAnalysisResponse analysis) {
    final riskColor = _getRiskColorFromString(analysis.overallRisk);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [riskColor, riskColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Risk Score',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${analysis.riskScore}/100',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  analysis.overallRisk.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: analysis.riskScore / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceSummaryCard(ContractAnalysisResponse analysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Compliance Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis.complianceSummary,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '${analysis.totalClauses} clauses analyzed',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildClauseCard(ClauseAnalysis clause, int index) {
    final statusColor = _getStatusColor(clause.status);
    final riskColor = _getRiskColorFromString(clause.riskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getStatusIcon(clause.status), color: statusColor, size: 20),
          ),
          title: Text(
            clause.clauseType,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  clause.status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  clause.riskLevel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clause text
                  const Text('Clause Text:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      clause.clauseText,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Matching policy
                  if (clause.relevantPolicy.isNotEmpty && clause.relevantPolicy != 'None') ...[
                    const Text('Matching Policy:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Text(
                        clause.relevantPolicy,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Explanation
                  const Text('Explanation:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(clause.explanation, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),

                  // Relevant Law
                  if (clause.relevantLaw.isNotEmpty && clause.relevantLaw != 'None') ...[
                    const Text('Relevant Pakistani Law:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gavel, size: 14, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              clause.relevantLaw,
                              style: const TextStyle(fontSize: 12, color: Colors.deepPurple),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Legal Concern
                  if (clause.legalConcern.isNotEmpty && clause.legalConcern != 'Unable to analyze') ...[
                    const Text('Legal Concern:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                    const SizedBox(height: 4),
                    Text(clause.legalConcern, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                  ],

                  // Recommendation
                  const Text('Recommendation:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(clause.recommendation, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),

                  // Suggested Fix
                  if (clause.suggestedFix.isNotEmpty && clause.suggestedFix != 'No change needed') ...[
                    const SizedBox(height: 12),
                    const Text('Suggested Fix:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Text(
                        clause.suggestedFix,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],

                  // Legal Precedents
                  if (clause.precedents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.gavel, size: 16, color: const Color(0xFF1E3A5F)),
                        const SizedBox(width: 6),
                        const Text(
                          'Similar Legal Precedents',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...clause.precedents.map((precedent) => _buildPrecedentCard(precedent)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrecedentCard(ClausePrecedent precedent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F).withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E3A5F).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case title and similarity score
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  precedent.caseTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPrecedentScoreColor(precedent.similarityScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${precedent.similarityScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPrecedentScoreColor(precedent.similarityScore),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Court and year
          Text(
            '${precedent.court} - ${precedent.year}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          // Reason
          if (precedent.reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              precedent.reason,
              style: TextStyle(fontSize: 11, color: Colors.teal[700], fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 6),
          // Decision
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Court Decision:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 3),
                Text(
                  precedent.decision.length > 200
                      ? '${precedent.decision.substring(0, 200)}...'
                      : precedent.decision,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPrecedentScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _analysis = null;
                _errorMessage = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Analyze Another'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _downloadReport(),
            icon: const Icon(Icons.download),
            label: const Text('Download Report'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRiskColorFromString(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'compliant':
        return Colors.green;
      case 'violation':
        return Colors.red;
      case 'risky':
        return Colors.orange;
      case 'not covered':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'compliant':
        return Icons.check_circle;
      case 'violation':
        return Icons.dangerous;
      case 'risky':
        return Icons.warning_amber;
      case 'not covered':
        return Icons.help_outline;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildLottieOrFallback(
    String assetPath,
    Widget fallback, {
    double? width,
    double? height,
  }) {
    try {
      return Lottie.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } catch (e) {
      return fallback;
    }
  }
}
