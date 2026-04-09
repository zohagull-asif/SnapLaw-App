import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/lawbot_api_service.dart';

class SimplifierScreen extends StatefulWidget {
  const SimplifierScreen({super.key});

  @override
  State<SimplifierScreen> createState() => _SimplifierScreenState();
}

class _SimplifierScreenState extends State<SimplifierScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  LawBotResponse? _result;
  String? _error;
  bool _showUrdu = false;

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
      _showUrdu = false;
    });

    try {
      final response = await LawBotApiService.sendRequest(
        type: 'simplify',
        text: text,
        language: 'urdu',
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
        title: const Text('Contract Simplifier'),
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
                color: const Color(0xFF4CAF50).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.article_outlined, color: Color(0xFF4CAF50), size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Paste contract text below and we\'ll convert complex legal jargon into simple, easy-to-understand language. You can also translate it to Urdu.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input
            const Text('Contract Text', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Paste your contract clause or legal text here...\n\ne.g., "The party hereinafter referred to as the Lessee shall notwithstanding any provisions..."',
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
                  borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_fix_high),
                label: Text(_isLoading ? 'Simplifying...' : 'Simplify Text'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
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
              // Summary badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _result!.summary.isNotEmpty ? _result!.summary : '${_result!.totalChanges} terms simplified',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Language Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showUrdu = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_showUrdu ? const Color(0xFF4CAF50) : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.language, size: 18, color: !_showUrdu ? Colors.white : Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                'English',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: !_showUrdu ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_result!.urduText.isNotEmpty) {
                            setState(() => _showUrdu = true);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showUrdu ? const Color(0xFF1565C0) : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.translate, size: 18, color: _showUrdu ? Colors.white : Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                'اردو',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: _showUrdu ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Simplified / Urdu text
              Text(
                _showUrdu ? 'اردو ترجمہ' : 'Simplified Version',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showUrdu
                        ? const Color(0xFF1565C0).withOpacity(0.3)
                        : const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                ),
                child: SelectableText(
                  _showUrdu ? _result!.urduText : _result!.response,
                  textDirection: _showUrdu ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(
                    fontSize: _showUrdu ? 16 : 14,
                    height: 1.8,
                    fontFamily: _showUrdu ? 'Noto Naskh Arabic' : null,
                  ),
                ),
              ),

              // Changes made (only show in English mode)
              if (!_showUrdu && _result!.changesMade.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Changes Made', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: _result!.changesMade.asMap().entries.map((entry) {
                      final change = entry.value;
                      final isLast = entry.key == _result!.changesMade.length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey[100]!)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${change['original']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.error,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                            ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${change['simplified']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
