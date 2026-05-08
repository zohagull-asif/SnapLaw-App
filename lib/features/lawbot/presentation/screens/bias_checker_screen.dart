import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../../services/gemini_service.dart';

class BiasCheckerScreen extends StatefulWidget {
  const BiasCheckerScreen({super.key});

  @override
  State<BiasCheckerScreen> createState() => _BiasCheckerScreenState();
}

class _BiasCheckerScreenState extends State<BiasCheckerScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  bool _isAbusive = false;
  String? _error;

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final jsonStr = await GeminiService.sendJsonMessage(
        prompt: '''You are an expert abuse and harassment detection system for SnapLaw, a Pakistani legal platform.

Analyze the following text carefully for ANY form of abuse, harassment, threats, hate speech, or harmful content:

TEXT TO ANALYZE:
"""
$text
"""

IMPORTANT: Be sensitive to ALL forms including:
- Direct threats ("I will hurt you")
- Subtle/implicit threats ("You should be careful")
- Sexual harassment or innuendo
- Hate speech (religion, ethnicity, gender, caste, sect)
- Emotional manipulation or gaslighting
- Blackmail or extortion
- Stalking indicators
- Discriminatory language
- Microaggressions
- ANY text that makes someone feel unsafe

If the text itself describes someone ELSE's abusive behavior, also flag it.

Respond ONLY with this exact JSON (no extra text):
{
  "is_abusive": true or false,
  "abuse_type": "harassment | threat | hate_speech | sexual_abuse | blackmail | stalking | discrimination | emotional_abuse | none",
  "severity": "high | medium | low | none",
  "what_was_found": ["specific element found", "another element"],
  "explanation": "Clear explanation of what was detected and why",
  "applicable_laws": [
    {
      "law": "Pakistan Penal Code (PPC) Section 509 - Insulting Modesty",
      "what_it_says": "Brief description",
      "punishment": "3 years imprisonment or fine or both"
    }
  ],
  "steps": [
    "Step 1: what the person should do now",
    "Step 2: next action",
    "Step 3: further action"
  ],
  "helplines": [
    "15 - Police Emergency",
    "1122 - Rescue",
    "0800-22227 - Umang Helpline for Women"
  ]
}''',
        maxTokens: 1500,
      );

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      setState(() {
        _result = data;
        _isAbusive = data['is_abusive'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: SnapLawColors.bgDark,
        foregroundColor: Colors.white,
        title: const Text('Abuse Detector',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Paste any text to check for abuse, hate speech, threats, or harassment.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 20),

              // Input
              const Text('Text to Analyze',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 8,
                maxLength: 5000,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'Paste any message, complaint, statement, or text here...\n\nWorks with English, Urdu, and Roman Urdu',
                  hintStyle:
                      const TextStyle(color: Color(0xFF8892B0), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFF0F1535),
                  counterStyle: const TextStyle(color: Color(0xFF8892B0)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0x33F4A324)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0x33F4A324)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFF4A324), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search),
                  label: Text(
                    _isLoading ? 'Analyzing...' : 'Check for Abuse',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F1535),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0x33F4A324)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Error
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Something went wrong: $_error',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              // Result
              if (_result != null) _buildResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final severity = _result!['severity'] as String? ?? 'none';
    final severityColor = _isAbusive
        ? (severity == 'high'
            ? Colors.red[700]!
            : severity == 'medium'
                ? Colors.orange[700]!
                : Colors.amber[700]!)
        : Colors.green[600]!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isAbusive
              ? Colors.red.withOpacity(0.40)
              : Colors.green.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: (_isAbusive ? Colors.red : Colors.green).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isAbusive
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _isAbusive
                      ? 'Issue Detected${severity != 'none' ? ' — ${severity[0].toUpperCase()}${severity.substring(1)} Severity' : ''}'
                      : 'No Issues Found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Explanation
                if ((_result!['explanation'] as String? ?? '').isNotEmpty) ...[
                  Text(
                    _result!['explanation'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_isAbusive) ...[
                  // What was found
                  _buildSection(
                    icon: Icons.search,
                    color: Colors.red,
                    title: 'WHAT WAS FOUND',
                    child: _buildBulletList(
                      _listOf(_result!['what_was_found']),
                      color: Colors.red.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Applicable laws
                  if ((_result!['applicable_laws'] as List?)?.isNotEmpty == true) ...[
                    _buildSection(
                      icon: Icons.gavel,
                      color: const Color(0xFF3B82F6),
                      title: 'APPLICABLE PAKISTANI LAW',
                      child: Column(
                        children: (_result!['applicable_laws'] as List)
                            .map((law) {
                          final l = law as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l['law'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B82F6),
                                    height: 1.4,
                                  ),
                                ),
                                if ((l['what_it_says'] as String? ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      l['what_it_says'] as String,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.55),
                                          height: 1.4),
                                    ),
                                  ),
                                if ((l['punishment'] as String? ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      'Punishment: ${l['punishment']}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Steps
                  if (_listOf(_result!['steps']).isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.checklist,
                      color: Colors.orange,
                      title: 'WHAT YOU SHOULD DO NOW',
                      child: _buildNumberedList(
                        _listOf(_result!['steps']),
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Helplines
                  if (_listOf(_result!['helplines']).isNotEmpty)
                    _buildSection(
                      icon: Icons.phone,
                      color: Colors.green,
                      title: 'HELPLINES',
                      child: _buildBulletList(
                        _listOf(_result!['helplines']),
                        color: Colors.green,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _listOf(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    return [];
  }

  Widget _buildSection({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildBulletList(List<String> items, {required Color color}) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(item,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.80),
                                height: 1.5))),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildNumberedList(List<String> items, {required Color color}) {
    return Column(
      children: items.asMap().entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 10),
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text('${e.key + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(e.value,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.85))),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
