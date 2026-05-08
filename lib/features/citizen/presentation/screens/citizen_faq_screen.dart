import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/citizen_data.dart';
import '../../../../theme/snaplaw_theme.dart';

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
            gradient: const LinearGradient(colors: [Color(0xFF0F1535), Color(0xFF2E5A8F)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
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
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search questions...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.55)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.55)),
                    onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.35))),
            filled: true,
            fillColor: const Color(0xFF0F1535).withOpacity(0.07),
          ),
          onChanged: (v) => setState(() { _searchQuery = v; _expandedIndex = null; }),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('No results found', style: TextStyle(color: Colors.white.withOpacity(0.5)))))
        else
          ...List.generate(filtered.length, (i) {
            final faq = filtered[i];
            final isExpanded = _expandedIndex == i;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? Colors.white.withOpacity(0.11)
                          : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isExpanded
                            ? SnapLawColors.clientBlue.withOpacity(0.45)
                            : Colors.white.withOpacity(0.12),
                        width: isExpanded ? 1.5 : 1,
                      ),
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
                                    color: SnapLawColors.clientBlue.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.help_outline, color: SnapLawColors.clientBlue, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(faq.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3, color: Colors.white)),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: SnapLawColors.clientBlue.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                                      child: Text(faq.category, style: TextStyle(fontSize: 10, color: SnapLawColors.clientBlue, fontWeight: FontWeight.w500)),
                                    ),
                                  ],
                                )),
                                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.white54),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          Divider(height: 1, color: Colors.white.withOpacity(0.10)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Text(faq.answer, style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white.withOpacity(0.80))),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 24),

        // Emergency contacts
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SnapLawColors.danger.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SnapLawColors.danger.withOpacity(0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.phone_in_talk, color: SnapLawColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Text('Emergency Legal Contacts', style: TextStyle(fontWeight: FontWeight.bold, color: SnapLawColors.danger)),
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
                        Text(e.$1, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.80))),
                        Text(e.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SnapLawColors.danger)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
