import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/presentation/providers/reviews_provider.dart';

class RateLawyerScreen extends ConsumerStatefulWidget {
  final String lawyerId;
  final String lawyerName;
  final String? caseId;
  final String? caseTitle;
  final String caseType;

  const RateLawyerScreen({
    super.key,
    required this.lawyerId,
    required this.lawyerName,
    this.caseId,
    this.caseTitle,
    this.caseType = 'General',
  });

  @override
  ConsumerState<RateLawyerScreen> createState() => _RateLawyerScreenState();
}

class _RateLawyerScreenState extends ConsumerState<RateLawyerScreen> {
  int _selectedRating = 0;
  int _hoveredRating = 0;
  final _reviewController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final List<String> _ratingLabels = [
    '',
    'Poor',
    'Fair',
    'Good',
    'Very Good',
    'Excellent',
  ];

  final List<Color> _ratingColors = [
    Colors.transparent,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.lightGreen,
    Colors.green,
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref.read(reviewsNotifierProvider.notifier).submitReview(
          lawyerId: widget.lawyerId,
          lawyerName: widget.lawyerName,
          rating: _selectedRating,
          reviewText: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
          caseId: widget.caseId,
          caseType: widget.caseType,
          isAnonymous: _isAnonymous,
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit review. You may have already reviewed this lawyer.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Review Submitted!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Thank you for rating ${widget.lawyerName}. Your review helps other clients make better decisions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: List.generate(5, (i) => Expanded(
                child: Icon(
                  Icons.star,
                  color: i < _selectedRating ? Colors.amber : Colors.grey[300],
                  size: 32,
                ),
              )),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRating = _hoveredRating > 0 ? _hoveredRating : _selectedRating;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Rate Your Lawyer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Lawyer card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.lawyerName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.lawyerName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    widget.caseTitle != null ? 'Case: ${widget.caseTitle}' : 'Rate your experience',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rating card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('How would you rate this lawyer?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                  const SizedBox(height: 20),

                  // Star row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRating = star),
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoveredRating = star),
                          onExit: (_) => setState(() => _hoveredRating = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Icon(
                              star <= activeRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 52,
                              color: star <= activeRating ? Colors.amber : Colors.grey[300],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Rating label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: activeRating > 0
                        ? Container(
                            key: ValueKey(activeRating),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: _ratingColors[activeRating].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _ratingColors[activeRating].withOpacity(0.4)),
                            ),
                            child: Text(
                              _ratingLabels[activeRating],
                              style: TextStyle(
                                color: _ratingColors[activeRating],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : const Text('Tap a star to rate', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Review text card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Write a Review', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                  const SizedBox(height: 4),
                  Text('Optional — help others with your experience', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'e.g. Very professional, explained everything clearly...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Anonymous toggle
                  Row(
                    children: [
                      Switch(
                        value: _isAnonymous,
                        onChanged: (v) => setState(() => _isAnonymous = v),
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Post anonymously', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          Text('Your name will not be shown', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedRating > 0 ? AppColors.primary : Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: _selectedRating > 0 ? 2 : 0,
                ),
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _selectedRating > 0 ? 'Submit $_selectedRating-Star Review' : 'Select a Rating First',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Skip for now', style: TextStyle(color: Colors.grey[500])),
            ),
          ],
        ),
      ),
    );
  }
}
