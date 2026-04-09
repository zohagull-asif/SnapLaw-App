import 'package:flutter/material.dart';
import '../../../../services/lawbot_api_service.dart';

class CitizenSafeSpeakScreen extends StatefulWidget {
  const CitizenSafeSpeakScreen({super.key});

  @override
  State<CitizenSafeSpeakScreen> createState() => _CitizenSafeSpeakScreenState();
}

class _CitizenSafeSpeakScreenState extends State<CitizenSafeSpeakScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  LawBotResponse? _result;
  String? _error;
  int _activeDetector = 0; // 0=SafeSpeak, 1=Abuse Detection

  static const _quickTopics = [
    'I am being harassed at work',
    'Domestic violence — need help',
    'Online blackmail / threats',
    'Cyberbullying and stalking',
    'Sexual harassment at college',
    'Child abuse — how to report',
  ];

  static const _abuseDetectorTopics = [
    'My employer withholds my salary',
    'Landlord locked me out illegally',
    'Police refusing to file my FIR',
    'Forced marriage pressure from family',
    'Employer fired me without notice',
    'Cheated in a property deal',
  ];

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() { _isLoading = true; _error = null; _result = null; });
    try {
      final response = await LawBotApiService.sendRequest(
        type: _activeDetector == 0 ? 'guidance' : 'qa',
        text: _activeDetector == 0
            ? text
            : 'Analyze this situation for legal rights violations and abuse of power. Provide step-by-step guidance: $text',
      );
      setState(() { _result = response; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
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
          Row(
            children: [
              Expanded(child: _TabBtn(label: '🛡️ SafeSpeak', active: _activeDetector == 0, onTap: () => setState(() { _activeDetector = 0; _result = null; _error = null; _controller.clear(); }))),
              const SizedBox(width: 10),
              Expanded(child: _TabBtn(label: '🔍 Abuse Detector', active: _activeDetector == 1, onTap: () => setState(() { _activeDetector = 1; _result = null; _error = null; _controller.clear(); }))),
            ],
          ),
          const SizedBox(height: 16),

          // Description card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(_activeDetector == 0 ? Icons.shield : Icons.search, color: const Color(0xFFE91E63), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _activeDetector == 0 ? 'SafeSpeak — Abuse & Harassment Guidance' : 'Abuse Detector — Rights Violation Analysis',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  _activeDetector == 0
                      ? 'Describe your situation confidentially. Get guidance, relevant Pakistani laws, and helpline numbers.'
                      : 'Describe a situation where you feel your rights were violated. Get analysis and legal remedies.',
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Emergency banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.25)),
            ),
            child: const Row(children: [
              Icon(Icons.phone, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Emergency: Call 15 (Police) | 1099 (Women) | 1121 (Child)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red))),
            ]),
          ),
          const SizedBox(height: 16),

          // Quick chips
          const Text('Quick Topics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: (_activeDetector == 0 ? _quickTopics : _abuseDetectorTopics).map((t) => GestureDetector(
              onTap: () { _controller.text = t; setState(() {}); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.2)),
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
            decoration: InputDecoration(
              hintText: _activeDetector == 0
                  ? 'Tell us what you\'re going through...'
                  : 'Describe the situation where your rights may have been violated...',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.shield, size: 18),
              label: Text(_isLoading ? 'Analyzing...' : (_activeDetector == 0 ? 'Get Guidance' : 'Detect Rights Violations')),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: Colors.red))),
              ]),
            ),
          ],

          // Result
          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.shield, color: Color(0xFFE91E63), size: 20),
                    const SizedBox(width: 8),
                    Text(_activeDetector == 0 ? 'Guidance & Resources' : 'Rights Violation Analysis', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ]),
                  const Divider(height: 20),
                  Text(_result!.response, style: const TextStyle(fontSize: 14, height: 1.7)),
                  if (_result!.sources.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Relevant Laws', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ..._result!.sources.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.gavel, size: 14, color: Color(0xFFE91E63)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                      ]),
                    )),
                  ],
                ],
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
          color: active ? const Color(0xFFE91E63) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFFE91E63) : Colors.grey.shade300),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: active ? Colors.white : Colors.black87)),
      ),
    );
  }
}
