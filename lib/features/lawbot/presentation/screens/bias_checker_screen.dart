import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/lawbot_api_service.dart';

class BiasCheckerScreen extends StatefulWidget {
  const BiasCheckerScreen({super.key});

  @override
  State<BiasCheckerScreen> createState() => _BiasCheckerScreenState();
}

class _BiasCheckerScreenState extends State<BiasCheckerScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  AbuseDetectionResponse? _result;
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
      final response = await LawBotApiService.detectAbuse(text: text);
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
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B4A),
        foregroundColor: Colors.white,
        title: const Text('Abuse Detector'),
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
            // Subtitle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B4A).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Paste any text to check for abuse, hate speech, threats, or harassment.',
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF1A2B4A)),
              ),
            ),
            const SizedBox(height: 20),

            // Input section
            const Text(
              'Text to Analyze',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 8,
              maxLength: 5000,
              decoration: InputDecoration(
                hintText: 'Paste any message, complaint, statement, or text here...\n\nWorks with English, Urdu, and Roman Urdu',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                  borderSide: const BorderSide(color: Color(0xFF1A2B4A), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isLoading ? 'Analyzing...' : 'Check for Abuse',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Something went wrong. Please try again.\n$_error',
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
              ),

            // Result
            if (_result != null) _buildResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final isAbusive = _result!.isAbusive;
    final resultText = _result!.result;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isAbusive ? Colors.red[600] : Colors.green[600],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAbusive ? Icons.warning_amber_rounded : Icons.check_circle,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isAbusive ? 'Issue Detected' : 'No Issues Found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Result content
          Padding(
            padding: const EdgeInsets.all(16),
            child: isAbusive
                ? _buildFormattedAbusiveResult(resultText)
                : Text(
                    resultText,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.6),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedAbusiveResult(String text) {
    // Parse the AI response into structured sections
    final lines = text.split('\n');
    List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip the "ABUSE DETECTED" header line (already shown in banner)
      if (line == 'ABUSE DETECTED' || line == '---') continue;

      // Section headers
      if (line == 'WHAT WAS FOUND:' ||
          line == 'APPLICABLE PAKISTANI LAW:' ||
          line == 'WHAT YOU SHOULD DO NOW:') {
        widgets.add(const SizedBox(height: 16));
        widgets.add(
          Text(
            line,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B4A),
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Law lines (blue bold)
      if (line.startsWith('Law:')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
                height: 1.5,
              ),
            ),
          ),
        );
        continue;
      }

      // "What it says:" line
      if (line.startsWith('What it says:')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
            ),
          ),
        );
        continue;
      }

      // Punishment lines (red)
      if (line.startsWith('Punishment:')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                height: 1.5,
              ),
            ),
          ),
        );
        continue;
      }

      // Numbered steps
      if (RegExp(r'^\d+\.').hasMatch(line)) {
        final stepNum = line.substring(0, line.indexOf('.'));
        final stepText = line.substring(line.indexOf('.') + 1).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1565C0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stepNum,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      stepText,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Category findings (text with colon that's not a known prefix)
      if (line.contains(':') &&
          !line.startsWith('Law:') &&
          !line.startsWith('What it says:') &&
          !line.startsWith('Punishment:') &&
          i > 0 &&
          lines.take(i).any((l) => l.trim() == 'WHAT WAS FOUND:')) {
        final colonIdx = line.indexOf(':');
        final category = line.substring(0, colonIdx);
        final description = line.substring(colonIdx + 1).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$category: ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      height: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        continue;
      }

      // Default text
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
