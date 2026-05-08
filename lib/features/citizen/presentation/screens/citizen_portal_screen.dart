import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import 'citizen_guidance_screen.dart';
import 'citizen_justice_screen.dart';
import 'citizen_quiz_screen.dart';
import 'citizen_faq_screen.dart';
import 'citizen_lawbot_screen.dart';
import 'citizen_safespeak_screen.dart';

class CitizenPortalScreen extends StatefulWidget {
  final int initialTab;
  const CitizenPortalScreen({super.key, this.initialTab = 0});

  @override
  State<CitizenPortalScreen> createState() => _CitizenPortalScreenState();
}

class _CitizenPortalScreenState extends State<CitizenPortalScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  static const List<Widget> _screens = [
    CitizenGuidanceScreen(),
    CitizenJusticeScreen(),
    CitizenQuizScreen(),
    CitizenFaqScreen(),
    CitizenLawBotScreen(),
    CitizenSafeSpeakScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.menu_book, label: 'My Rights'),
    _NavItem(icon: Icons.bar_chart, label: 'Justice'),
    _NavItem(icon: Icons.quiz, label: 'Quiz'),
    _NavItem(icon: Icons.help_outline, label: 'FAQs'),
    _NavItem(icon: Icons.smart_toy, label: 'LawBot AI'),
    _NavItem(icon: Icons.shield, label: 'SafeSpeak'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF012018), Color(0xFF064E3B)],
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.20)),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: SnapLawColors.citizenGreen.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: SnapLawColors.citizenGreen.withOpacity(0.40)),
                      ),
                      child: Icon(Icons.balance, color: SnapLawColors.citizenGreen, size: 18),
                    ),
                    const SizedBox(width: 10),
                    RichText(text: const TextSpan(children: [
                      TextSpan(text: 'SnapLaw ', style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      TextSpan(text: 'Citizen Portal', style: TextStyle(
                        color: Color(0xFF00C896), fontSize: 16, fontWeight: FontWeight.w600)),
                    ])),
                    const Spacer(),
                    // Active tab indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SnapLawColors.citizenGreen.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SnapLawColors.citizenGreen.withOpacity(0.35)),
                      ),
                      child: Text(_navItems[_selectedIndex].label,
                        style: TextStyle(
                          color: SnapLawColors.citizenGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: _GlassBottomNav(
        selectedIndex: _selectedIndex,
        items: _navItems,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _GlassBottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 70 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF012018), Color(0xFF064E3B)],
            ),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final isSelected = i == selectedIndex;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? SnapLawColors.citizenGreen.withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: SnapLawColors.citizenGreen.withOpacity(0.40))
                            : null,
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(items[i].icon,
                          color: isSelected ? SnapLawColors.citizenGreen : Colors.white38,
                          size: 22),
                        const SizedBox(height: 3),
                        Text(items[i].label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? SnapLawColors.citizenGreen : Colors.white38,
                          )),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
