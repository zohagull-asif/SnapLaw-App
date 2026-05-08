import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../services/gemini_service.dart';

class CitizenSafeSpeakScreen extends StatefulWidget {
  const CitizenSafeSpeakScreen({super.key});

  @override
  State<CitizenSafeSpeakScreen> createState() => _CitizenSafeSpeakScreenState();
}

class _CitizenSafeSpeakScreenState extends State<CitizenSafeSpeakScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _result;
  String? _error;
  int _activeTab = 0;

  static const _safeTopics = [
    'I am being harassed at work',
    'Domestic violence — need help',
    'Online blackmail / threats',
    'Cyberbullying and stalking',
    'Sexual harassment at college',
    'Child abuse — how to report',
  ];

  static const _abuseTopics = [
    '"Get out of our country you dirty minority"',
    '"Women should stay home and not work"',
    '"I will kill you if you report this"',
    '"You are worthless, nobody will believe you"',
    '"Send me money or I\'ll share your photos"',
    '"Your kind deserves to suffer"',
  ];

  static const _kSafeSpeakPrompt =
      'You are a compassionate legal advisor for SnapLaw, a Pakistani legal platform. '
      'A user is describing a situation involving harassment, domestic violence, abuse, or a rights violation. '
      'Your job is to:\n'
      '1. Acknowledge their situation with empathy\n'
      '2. Identify the type of abuse/violation\n'
      '3. Give clear step-by-step actions they should take immediately\n'
      '4. Cite the exact Pakistani laws that apply (law name + section number)\n'
      '5. List all relevant helplines with numbers\n'
      '6. Remind them they are not alone and help is available\n\n'
      'Format your response clearly with sections: '
      'Situation Analysis, Immediate Steps, Applicable Laws, Helplines & Support.\n'
      'Always include: Police 15, Rescue 1122, Women\'s Helpline 1099, Madadgaar 0800-22444.\n'
      'Be warm, supportive, and practical. Users may write in English, Urdu, or Roman Urdu — respond in the same language.';

  static const _kAbuseDetectPrompt =
      'You are an expert in detecting hate speech, discrimination, harassment, and abusive language '
      'for SnapLaw, a Pakistani legal platform. '
      'Analyze the given text and determine if it contains:\n'
      '- Hate speech (against religion, ethnicity, gender, caste, sect)\n'
      '- Threats (direct or indirect violence)\n'
      '- Harassment or intimidation\n'
      '- Discriminatory or abusive language\n'
      '- Sexual abuse or blackmail language\n\n'
      'Structure your response as:\n'
      '🔍 ANALYSIS RESULT: [ABUSIVE / CLEAN]\n\n'
      'If abusive:\n'
      '⚠️ What Was Found: [describe the issue and quote the problematic part]\n'
      '📋 Category: [hate speech / threat / harassment / discrimination / etc]\n'
      '⚖️ Pakistani Law Violated:\n'
      '  - [Law name and section]\n'
      '  - Punishment: [exact penalty]\n\n'
      '🚨 What To Do:\n'
      '  1. [Step 1]\n'
      '  2. [Step 2]\n'
      '  3. [Step 3]\n\n'
      '📞 Report To:\n'
      '  - Police: 15\n'
      '  - FIA Cyber Crime: 9911\n'
      '  - Women\'s Helpline: 1099\n\n'
      'If clean:\n'
      '✅ No abusive, hateful, or threatening content detected.\n'
      '[Brief explanation of why it is clean]\n\n'
      'Be precise and cite exact Pakistani laws (PPC, PECA 2016, etc.).';

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() { _isLoading = true; _error = null; _result = null; });
    try {
      final reply = await GeminiService.sendMessage(
        message: _activeTab == 0
            ? 'Please help me with this situation: $text'
            : 'Analyze this text for abuse/hate speech: "$text"',
        systemPrompt: _activeTab == 0 ? _kSafeSpeakPrompt : _kAbuseDetectPrompt,
      );
      setState(() { _result = reply; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab switcher
          Row(children: [
            Expanded(child: _TabBtn(
              label: '🛡️ SafeSpeak',
              active: _activeTab == 0,
              onTap: () => setState(() { _activeTab = 0; _result = null; _error = null; _controller.clear(); }),
            )),
            const SizedBox(width: 10),
            Expanded(child: _TabBtn(
              label: '🔍 Abuse Detector',
              active: _activeTab == 1,
              onTap: () => setState(() { _activeTab = 1; _result = null; _error = null; _controller.clear(); }),
            )),
          ]),
          const SizedBox(height: 16),

          // Description card
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(_activeTab == 0 ? Icons.shield : Icons.search,
                          color: const Color(0xFFE91E63), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        _activeTab == 0
                            ? 'SafeSpeak — Abuse & Harassment Guidance'
                            : 'Abuse Detector — Hate Speech & Discrimination Analysis',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      )),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      _activeTab == 0
                          ? 'Describe your situation confidentially. Get AI-powered guidance, Pakistani laws, and helpline numbers.'
                          : 'Paste any text to detect hate speech, threats, harassment, or discriminatory language.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: Colors.white.withOpacity(0.70)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Emergency banner
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.30)),
                ),
                child: const Row(children: [
                  Icon(Icons.phone, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Emergency: Call 15 (Police) | 1099 (Women) | 1121 (Child) | 1122 (Rescue)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red),
                  )),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick chips
          Text('Quick Topics',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white.withOpacity(0.80))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: (_activeTab == 0 ? _safeTopics : _abuseTopics).map((t) => GestureDetector(
              onTap: () { _controller.text = t; setState(() {}); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.28)),
                ),
                child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFFE91E63))),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),

          // Input field
          TextField(
            controller: _controller,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: _activeTab == 0
                  ? 'Describe your situation confidentially...'
                  : 'Paste the text you want to analyze for hate speech or abuse...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0F1535).withOpacity(0.07),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFFE91E63).withOpacity(0.50))),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_activeTab == 0 ? Icons.shield : Icons.search, size: 18),
              label: Text(_isLoading
                  ? 'Analyzing with AI...'
                  : (_activeTab == 0 ? 'Get Guidance' : 'Detect Abuse')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(fontSize: 13, color: Colors.red))),
                  ]),
                ),
              ),
            ),
          ],

          // Result
          if (_result != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(_activeTab == 0 ? Icons.shield : Icons.search,
                            color: const Color(0xFFE91E63), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _activeTab == 0 ? 'Guidance & Legal Help' : 'Abuse Detection Result',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                      ]),
                      Divider(height: 20, color: Colors.white.withOpacity(0.12)),
                      SelectableText(
                        _result!,
                        style: TextStyle(fontSize: 14, height: 1.7,
                            color: Colors.white.withOpacity(0.88)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE91E63) : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? const Color(0xFFE91E63) : Colors.white.withOpacity(0.15)),
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: active ? Colors.white : Colors.white70)),
      ),
    );
  }
}
