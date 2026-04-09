import 'package:flutter/material.dart';
import 'dart:math';
import '../../data/citizen_data.dart';

class CitizenQuizScreen extends StatefulWidget {
  const CitizenQuizScreen({super.key});

  @override
  State<CitizenQuizScreen> createState() => _CitizenQuizScreenState();
}

class _CitizenQuizScreenState extends State<CitizenQuizScreen> {
  // Quiz state
  int? _activeLevel; // null = level picker
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _quizDone = false;

  // Persistent progress (in-memory for this session)
  int _totalPoints = 0;
  int _streak = 0;
  Set<int> _completedLevels = {};

  static const _levelNames = ['Beginner', 'Easy', 'Medium', 'Hard', 'Expert'];
  static const _levelColors = [0xFF27ae60, 0xFFf1c40f, 0xFFe67e22, 0xFFe74c3c, 0xFF9b59b6];
  static const _levelEmojis = ['🟢', '🟡', '🟠', '🔴', '🟣'];

  void _startLevel(int level) {
    final qs = kQuizQuestions.where((q) => q.level == level).toList()..shuffle(Random());
    setState(() {
      _activeLevel = level;
      _questions = qs;
      _currentIndex = 0;
      _selectedAnswer = null;
      _answered = false;
      _score = 0;
      _quizDone = false;
    });
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    final correct = _questions[_currentIndex].correctAnswer == answer;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (correct) {
        _score++;
        _totalPoints += 10;
        _streak++;
      } else {
        _streak = 0;
      }
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      // Quiz done
      final passed = _score >= 7;
      if (passed) {
        _totalPoints += 50;
        _completedLevels.add(_activeLevel!);
      }
      setState(() => _quizDone = true);
    }
  }

  void _exitQuiz() {
    setState(() {
      _activeLevel = null;
      _quizDone = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeLevel == null) return _buildLevelPicker();
    if (_quizDone) return _buildResult();
    return _buildQuestion();
  }

  Widget _buildLevelPicker() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A3A5C), Color(0xFF2E5A8F)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatPill(icon: '⭐', label: 'Points', value: '$_totalPoints'),
              _StatPill(icon: '🔥', label: 'Streak', value: '$_streak'),
              _StatPill(icon: '🏆', label: 'Levels', value: '${_completedLevels.length}/5'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Choose a Level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...List.generate(5, (i) {
          final level = i + 1;
          final color = Color(_levelColors[i]);
          final done = _completedLevels.contains(level);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _startLevel(level),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: done ? color.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(done ? 0.5 : 0.2), width: done ? 2 : 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Text(_levelEmojis[i], style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('Level $level — ${_levelNames[i]}', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
                          if (done) ...[const SizedBox(width: 8), Icon(Icons.check_circle, color: color, size: 16)],
                        ]),
                        Text('${kQuizQuestions.where((q) => q.level == level).length} questions • Pass: 7/10', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    )),
                    Icon(Icons.play_arrow_rounded, color: color, size: 28),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentIndex];
    final color = Color(_levelColors[(_activeLevel! - 1)]);
    final options = [
      ('a', q.optionA), ('b', q.optionB), ('c', q.optionC), ('d', q.optionD),
    ];

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: color.withOpacity(0.08),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.close), onPressed: _exitQuiz, iconSize: 20),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level $_activeLevel — ${_levelNames[_activeLevel! - 1]}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / _questions.length,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Text('${_currentIndex + 1}/${_questions.length}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text('Score: $_score', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(q.question, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.4)),
                const SizedBox(height: 24),
                ...options.map((opt) {
                  final (key, text) = opt;
                  Color? bgColor;
                  Color? borderColor;
                  if (_answered) {
                    if (key == q.correctAnswer) {
                      bgColor = const Color(0xFF27ae60).withOpacity(0.1);
                      borderColor = const Color(0xFF27ae60);
                    } else if (key == _selectedAnswer) {
                      bgColor = const Color(0xFFe74c3c).withOpacity(0.1);
                      borderColor = const Color(0xFFe74c3c);
                    }
                  } else if (key == _selectedAnswer) {
                    bgColor = color.withOpacity(0.1);
                    borderColor = color;
                  }
                  return GestureDetector(
                    onTap: () => _selectAnswer(key),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor ?? Colors.grey.shade300, width: borderColor != null ? 2 : 1),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: borderColor?.withOpacity(0.15) ?? Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Text(key.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: borderColor ?? Colors.grey))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
                          if (_answered && key == q.correctAnswer) const Icon(Icons.check_circle, color: Color(0xFF27ae60), size: 20),
                          if (_answered && key == _selectedAnswer && key != q.correctAnswer) const Icon(Icons.cancel, color: Color(0xFFe74c3c), size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                if (_answered) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (_selectedAnswer == q.correctAnswer ? const Color(0xFF27ae60) : const Color(0xFFe74c3c)).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (_selectedAnswer == q.correctAnswer ? const Color(0xFF27ae60) : const Color(0xFFe74c3c)).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAnswer == q.correctAnswer ? '✅ Correct! +10 points' : '❌ Incorrect',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _selectedAnswer == q.correctAnswer ? const Color(0xFF27ae60) : const Color(0xFFe74c3c)),
                        ),
                        const SizedBox(height: 6),
                        Text(q.explanation, style: const TextStyle(fontSize: 13, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: Text(_currentIndex < _questions.length - 1 ? 'Next Question →' : 'See Results', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final passed = _score >= 7;
    final color = passed ? const Color(0xFF27ae60) : const Color(0xFFe74c3c);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(passed ? '🎉' : '😔', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(passed ? 'Level Passed!' : 'Keep Trying!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            Text('$_score / ${_questions.length} correct', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            if (passed) ...[
              const SizedBox(height: 8),
              Text('+50 bonus points!', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 8),
            Text('Total points: $_totalPoints', style: const TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _startLevel(_activeLevel!),
                    child: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _exitQuiz,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C)),
                    child: const Text('Back to Levels', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatPill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}
