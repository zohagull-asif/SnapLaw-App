import 'package:flutter/material.dart';
import '../../data/citizen_data.dart';

class CitizenFaqScreen extends StatefulWidget {
  const CitizenFaqScreen({super.key});

  @override
  State<CitizenFaqScreen> createState() => _CitizenFaqScreenState();
}

class _CitizenFaqScreenState extends State<CitizenFaqScreen> {
  int? _expandedIndex;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kFaqs.where((f) {
      final q = _searchQuery.toLowerCase();
      return f.question.toLowerCase().contains(q) || f.answer.toLowerCase().contains(q) || f.category.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A3A5C), Color(0xFF2E5A8F)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Frequently Asked Questions', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Common legal questions answered in plain language', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search questions...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          onChanged: (v) => setState(() { _searchQuery = v; _expandedIndex = null; }),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No results found', style: TextStyle(color: Colors.grey))))
        else
          ...List.generate(filtered.length, (i) {
            final faq = filtered[i];
            final isExpanded = _expandedIndex == i;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                border: isExpanded ? Border.all(color: const Color(0xFF1A3A5C).withOpacity(0.3), width: 1.5) : null,
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A3A5C).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.help_outline, color: Color(0xFF1A3A5C), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(faq.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3)),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF1A3A5C).withOpacity(0.07), borderRadius: BorderRadius.circular(20)),
                                child: Text(faq.category, style: const TextStyle(fontSize: 10, color: Color(0xFF1A3A5C), fontWeight: FontWeight.w500)),
                              ),
                            ],
                          )),
                          Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    Divider(height: 1, color: Colors.grey.shade200),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Text(faq.answer, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
                    ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 24),

        // Emergency contacts
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFe74c3c).withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFe74c3c).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.phone_in_talk, color: Color(0xFFe74c3c), size: 18),
                SizedBox(width: 8),
                Text('Emergency Legal Contacts', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFe74c3c))),
              ]),
              const SizedBox(height: 12),
              ...[
                ('Police Emergency', '15'),
                ('FIA Cyber Crime', '9911'),
                ('Legal Aid (Islamabad)', '051-9201734'),
                ('Women Helpline', '1099'),
                ('Child Protection', '1121'),
              ].map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.$1, style: const TextStyle(fontSize: 13)),
                    Text(e.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
