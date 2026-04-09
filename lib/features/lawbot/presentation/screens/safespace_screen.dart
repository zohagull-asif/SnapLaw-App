import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/lawbot_api_service.dart';

class SafeSpaceScreen extends StatefulWidget {
  const SafeSpaceScreen({super.key});

  @override
  State<SafeSpaceScreen> createState() => _SafeSpaceScreenState();
}

class _SafeSpaceScreenState extends State<SafeSpaceScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  LawBotResponse? _result;
  String? _error;

  final List<String> _quickTopics = [
    'I am being harassed at work',
    'Domestic violence help',
    'Online blackmail and threats',
    'Child abuse reporting',
    'Sexual harassment at workplace',
    'Cyberbullying and online abuse',
  ];

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final response = await LawBotApiService.sendRequest(
        type: 'guidance',
        text: text,
      );
      setState(() {
        _result = response;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SafeSpace'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Color(0xFFE91E63), size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'SafeSpace - Abuse & Harassment Guidance',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Describe your situation and get step-by-step guidance, relevant Pakistani laws, and helpline numbers. Your privacy matters.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Emergency banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                        children: const [
                          TextSpan(
                            text: 'In immediate danger? ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: 'Call '),
                          TextSpan(
                            text: '15 (Police)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                          ),
                          TextSpan(text: ' or '),
                          TextSpan(
                            text: '1122 (Rescue)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input
            const Text('Describe Your Situation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Tell us what you\'re going through...\nWe\'ll provide relevant guidance and resources.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick topics
            if (_result == null && !_isLoading) ...[
              const Text('Or select a topic:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTopics.map((topic) => ActionChip(
                  label: Text(topic, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: const Color(0xFFE91E63).withOpacity(0.3)),
                  onPressed: () {
                    _controller.text = topic;
                    _submit();
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Submit
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.shield),
                label: Text(_isLoading ? 'Getting Guidance...' : 'Get Guidance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ],
                ),
              ),

            // Result
            if (_result != null) ...[
              // Title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Color(0xFFE91E63), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _result!.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Steps
              if (_result!.steps.isNotEmpty) ...[
                const Text('What You Should Do', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: _result!.steps.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final step = entry.value;
                      final isLast = idx == _result!.steps.length - 1;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey[100]!)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E63).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE91E63),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(step, style: const TextStyle(fontSize: 14, height: 1.5)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Laws
              if (_result!.laws.isNotEmpty) ...[
                const Text('Relevant Laws', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: _result!.laws.map((law) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.gavel, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(law, style: const TextStyle(fontSize: 13, height: 1.4))),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Helplines
              if (_result!.helplines.isNotEmpty) ...[
                const Text('Helplines & Resources', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: _result!.helplines.map((helpline) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              helpline,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Encouragement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite, size: 20, color: Color(0xFF9C27B0)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Remember: You are not alone. Seeking help is a sign of strength, not weakness. If you are in immediate danger, call 15 (Police) or 1122 (Rescue) right away.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
