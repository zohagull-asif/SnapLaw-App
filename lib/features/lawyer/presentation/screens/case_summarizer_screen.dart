import 'dart:convert';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../../services/gemini_service.dart';

const _kSummarizerPrompt = '''You are an expert Pakistani legal analyst and case summarizer for SnapLaw, a legal platform used by lawyers in Pakistan.

A lawyer has provided a court judgment or legal document. Read the full text and produce a highly structured, accurate, and easy-to-understand summary.

Follow EXACTLY this format with all sections. If information is not found write "Not mentioned in document".

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 CASE SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**CASE TITLE:**
[Full case name]

**CASE NUMBER:**
[Case/Appeal/Writ number]

**COURT:**
[Which court]

**JUDGMENT DATE:**
[Date]

**JUDGE(S):**
[Name(s)]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ PARTIES INVOLVED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**COMPLAINANT / APPELLANT:**
[Who filed the case]

**DEFENDANT / RESPONDENT:**
[Who is defending]

**LAWYERS:**
[Advocate names if mentioned]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📖 WHAT THIS CASE IS ABOUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**CASE TYPE:**
[Criminal / Civil / Family / Property / Labor / Constitutional / etc.]

**BACKGROUND IN SIMPLE WORDS:**
[3-5 sentences explaining what happened]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗣️ ARGUMENTS MADE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**COMPLAINANT / APPELLANT ARGUED:**
- [Key argument 1]
- [Key argument 2]

**DEFENDANT / RESPONDENT ARGUED:**
- [Key argument 1]
- [Key argument 2]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 LAWS AND SECTIONS CITED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- [Law name + Section]: [What it covers]
- [Law name + Section]: [What it covers]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ COURT\'S DECISION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**VERDICT:**
[Guilty / Not Guilty / Appeal Allowed / Appeal Dismissed / Acquitted / Convicted]

**PUNISHMENT / ORDER:**
[Exact sentence or order given]

**WHO WON:**
[Complainant / Defendant]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 REASONING — WHY COURT DECIDED THIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[3-5 sentences explaining the court\'s reasoning]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 KEY LEGAL POINTS FOR LAWYERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- [Key legal principle 1]
- [Key legal principle 2]
- [Key legal principle 3]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 PAST CASES REFERENCED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- [Case name + year if available]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 CASE STRENGTH ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**EVIDENCE PRESENTED:**
[Was evidence strong or weak?]

**MISSING ELEMENTS:**
[What was missing from this case?]

**OVERALL CASE STRENGTH:** [Strong / Medium / Weak]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Document text to summarize:
{document_text}''';

class CaseSummarizerScreen extends StatefulWidget {
  const CaseSummarizerScreen({super.key});

  @override
  State<CaseSummarizerScreen> createState() => _CaseSummarizerScreenState();
}

class _CaseSummarizerScreenState extends State<CaseSummarizerScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;
  String? _summary;
  String? _error;

  // Upload mode state
  bool _uploadMode = false;
  PlatformFile? _selectedFile;
  String? _uploadedFileName;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ── TEXT MODE ──────────────────────────────────────────────────────────────

  Future<void> _summarizeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Please paste your case document or judgment text above.');
      return;
    }
    if (text.length < 100) {
      setState(() => _error = 'Please provide more text — at least a few paragraphs for an accurate summary.');
      return;
    }

    setState(() { _isLoading = true; _error = null; _summary = null; });

    try {
      final truncated = text.length > 15000 ? text.substring(0, 15000) : text;
      final prompt = _kSummarizerPrompt.replaceFirst('{document_text}', truncated);
      final result = await GeminiService.sendMessage(
        message: prompt,
        systemPrompt: 'You are an expert Pakistani legal analyst. Follow the exact format requested.',
      );
      setState(() { _summary = result; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ── UPLOAD MODE ────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.single;
        _error = null;
      });
    }
  }

  Future<void> _summarizeFile() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      setState(() => _error = 'Please select a file first.');
      return;
    }

    setState(() { _isLoading = true; _error = null; _summary = null; });

    try {
      final mimeType = _getMimeType(_selectedFile!.extension);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/api/summarize'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _selectedFile!.bytes!,
        filename: _selectedFile!.name,
        contentType: MediaType.parse(mimeType),
      ));

      final streamed = await request.send().timeout(const Duration(seconds: 120));
      final responseBody = await http.Response.fromStream(streamed);

      if (responseBody.statusCode == 200) {
        final data = jsonDecode(responseBody.body) as Map<String, dynamic>;
        setState(() {
          _summary = data['summary'] as String;
          _uploadedFileName = _selectedFile!.name;
          _isLoading = false;
        });
      } else {
        Map<String, dynamic> data = {};
        try { data = jsonDecode(responseBody.body) as Map<String, dynamic>; } catch (_) {}
        setState(() {
          _error = (data['detail'] as String?) ?? 'Failed to process document (status ${responseBody.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Upload failed: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  String _getMimeType(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      default: return 'application/octet-stream';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _reset() {
    setState(() {
      _summary = null;
      _error = null;
      _selectedFile = null;
      _uploadedFileName = null;
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: SnapLawColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.summarize, size: 22, color: Color(0xFFF4A324)),
            SizedBox(width: 8),
            Text('Case Summarizer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (_summary != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: 'New Summary',
              onPressed: _reset,
            ),
        ],
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: _summary != null ? _buildResult() : _buildInput(),
      ),
    );
  }

  Widget _buildInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A324).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF4A324).withOpacity(0.30)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: SnapLawGradients.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.summarize, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Case Summarizer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 3),
                        Text('Upload a PDF/image or paste text.\nGroq AI generates a structured legal summary.',
                          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4)),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Mode toggle
          Row(children: [
            Expanded(child: _ModeBtn(
              label: '📝 Paste Text',
              active: !_uploadMode,
              onTap: () => setState(() { _uploadMode = false; _error = null; }),
            )),
            const SizedBox(width: 10),
            Expanded(child: _ModeBtn(
              label: '📎 Upload Document',
              active: _uploadMode,
              onTap: () => setState(() { _uploadMode = true; _error = null; }),
            )),
          ]),
          const SizedBox(height: 20),

          if (_uploadMode) ...[
            _buildUploadSection(),
          ] else ...[
            _buildTextSection(),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SnapLawColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SnapLawColors.danger.withOpacity(0.30)),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: SnapLawColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: TextStyle(color: SnapLawColors.danger, fontSize: 13))),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : (_uploadMode ? _summarizeFile : _summarizeText),
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 20),
              label: Text(_isLoading ? 'Generating Summary...' : 'Generate AI Summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4A324),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paste Case Document / Judgment Text',
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: TextField(
              controller: _textController,
              maxLines: 14,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Paste the full text of the court judgment, case file, FIR, legal notice, or any legal document here...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F1535).withOpacity(0.07),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF4A324), width: 1.5)),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('Minimum 100 characters. For best results, paste the full document (up to 15,000 characters).',
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload Document',
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),

        // Drop zone / pick button
        GestureDetector(
          onTap: _pickFile,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: _selectedFile != null
                      ? const Color(0xFFF4A324).withOpacity(0.10)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null
                        ? const Color(0xFFF4A324).withOpacity(0.50)
                        : Colors.white.withOpacity(0.18),
                    width: _selectedFile != null ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.description : Icons.upload_file,
                      color: _selectedFile != null ? const Color(0xFFF4A324) : Colors.white38,
                      size: 48,
                    ),
                    const SizedBox(height: 14),
                    if (_selectedFile != null) ...[
                      Text(
                        _selectedFile!.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatBytes(_selectedFile!.size),
                        style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Change File'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF4A324),
                          side: const BorderSide(color: Color(0xFFF4A324)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Tap to select a document',
                        style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Supports PDF, JPG, PNG (max 20 MB)',
                        style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Info notice about backend
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'File upload requires the SnapLaw backend running on port 8000.\nRun: python main.py in the backend folder.',
                  style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 11, height: 1.4),
                )),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTipsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡 Works best with:', style: TextStyle(color: Colors.white.withOpacity(0.80), fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 6),
              ...[
                'Court judgments (Supreme Court, High Court, Sessions Court)',
                'FIR documents and police reports',
                'Legal notices and agreements',
                'Case files and charge sheets',
              ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(children: [
                  Icon(Icons.check_circle_outline, size: 13, color: SnapLawColors.lawyerPurple),
                  const SizedBox(width: 6),
                  Expanded(child: Text(t, style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 12))),
                ]),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Column(
      children: [
        // Top info bar
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4A324).withOpacity(0.10),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Color(0xFF00C896), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _uploadedFileName != null
                      ? 'Summary of: $_uploadedFileName'
                      : 'Summary generated successfully',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                )),
                TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF4A324),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ]),
            ),
          ),
        ),
        // Summary content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: _buildFormattedSummary(_summary!),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormattedSummary(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('━')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(color: Colors.white.withOpacity(0.15), height: 1),
        ));
      } else if (line.contains('📋') || line.contains('⚖️') || line.contains('📖') || line.contains('🗣️') || line.contains('📜') || line.contains('🧠') || line.contains('📌') || line.contains('🔍') || line.contains('📊')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(line, style: const TextStyle(color: Color(0xFFF4A324), fontWeight: FontWeight.bold, fontSize: 14)),
        ));
      } else if (line.startsWith('**') && line.endsWith('**')) {
        final clean = line.replaceAll('**', '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Text(clean, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('•  ', style: TextStyle(color: SnapLawColors.lawyerPurple, fontWeight: FontWeight.bold, fontSize: 14)),
            Expanded(child: Text(line.substring(2), style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 13, height: 1.45))),
          ]),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 4));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(line, style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 13, height: 1.45)),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF4A324) : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFFF4A324) : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: active ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
