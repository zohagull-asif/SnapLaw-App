import 'package:flutter/material.dart';
import '../../data/citizen_data.dart';

class CitizenGuidanceScreen extends StatefulWidget {
  const CitizenGuidanceScreen({super.key});

  @override
  State<CitizenGuidanceScreen> createState() => _CitizenGuidanceScreenState();
}

class _CitizenGuidanceScreenState extends State<CitizenGuidanceScreen> {
  int _selectedCatIndex = 0;
  GuidanceArticle? _selectedArticle;

  @override
  Widget build(BuildContext context) {
    if (_selectedArticle != null) {
      final cat = kGuidanceCategories[_selectedCatIndex];
      return _ArticleDetail(
        article: _selectedArticle!,
        catColor: Color(cat.color),
        onBack: () => setState(() => _selectedArticle = null),
      );
    }

    final cat = kGuidanceCategories[_selectedCatIndex];
    return Column(
      children: [
        // Hero header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A3A5C), Color(0xFF2E5A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.menu_book, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Text('KNOW YOUR RIGHTS', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.5)),
              ]),
              const SizedBox(height: 6),
              const Text("Pakistan's Legal Rights Guide", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${kGuidanceCategories.fold(0, (s, c) => s + c.articles.length)} articles across ${kGuidanceCategories.length} categories', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),

        // Category pills — horizontal scroll
        Container(
          color: const Color(0xFF1A3A5C),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: List.generate(kGuidanceCategories.length, (i) {
                final c = kGuidanceCategories[i];
                final selected = i == _selectedCatIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCatIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Color(c.color) : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: selected ? null : Border.all(color: Colors.white24),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(c.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(c.label, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),

        // Articles list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: cat.articles.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                // Category header
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(cat.color).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Color(cat.color).withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Text(cat.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.label, style: TextStyle(color: Color(cat.color), fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('${cat.articles.length} articles about your rights', style: TextStyle(color: Color(cat.color).withOpacity(0.7), fontSize: 12)),
                      ],
                    )),
                  ]),
                );
              }
              final article = cat.articles[i - 1];
              return _ArticleCard(
                article: article,
                index: i,
                color: Color(cat.color),
                onTap: () => setState(() => _selectedArticle = article),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final GuidanceArticle article;
  final int index;
  final Color color;
  final VoidCallback onTap;
  const _ArticleCard({required this.article, required this.index, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color stripe + number
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$index', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Icon(Icons.article_outlined, color: color.withOpacity(0.6), size: 16),
              ]),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.3)),
                    const SizedBox(height: 6),
                    Text(article.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.gavel, size: 11, color: color),
                        const SizedBox(width: 4),
                        Flexible(child: Text(article.relevantLaw.split('|').first.trim(), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 18),
              child: Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleDetail extends StatelessWidget {
  final GuidanceArticle article;
  final Color catColor;
  final VoidCallback onBack;
  const _ArticleDetail({required this.article, required this.catColor, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
          color: catColor.withOpacity(0.06),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
            Expanded(child: Text(article.title, style: TextStyle(fontWeight: FontWeight.bold, color: catColor, fontSize: 14), maxLines: 2)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.content, style: const TextStyle(fontSize: 15, height: 1.75, color: Colors.black87)),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: catColor.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.gavel, color: catColor, size: 18),
                        const SizedBox(width: 8),
                        Text('Relevant Laws', style: TextStyle(fontWeight: FontWeight.bold, color: catColor, fontSize: 13)),
                      ]),
                      const SizedBox(height: 10),
                      ...article.relevantLaw.split('|').map((law) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.circle, size: 6, color: catColor),
                          const SizedBox(width: 8),
                          Expanded(child: Text(law.trim(), style: TextStyle(fontSize: 13, color: catColor.withOpacity(0.85)))),
                        ]),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text('This is general legal information for educational purposes. For your specific situation, consult a qualified lawyer.', style: TextStyle(fontSize: 12, height: 1.4))),
                  ]),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
